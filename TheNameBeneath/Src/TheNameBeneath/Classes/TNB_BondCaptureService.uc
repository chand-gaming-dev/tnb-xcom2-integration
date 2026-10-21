// Append to the native bond transaction. An abandoned transaction reports nothing.
// No network, game-state submission, canonical relationship mutation or XP math.
class TNB_BondCaptureService extends TNB_EventTypes;

static function string PairKey(int A, int B)
{
    return "bond:" $ Min(A, B) $ ":" $ Max(A, B);
}

static function bool ValidTransition(name Source, int BeforeA, int BeforeB, int AfterA, int AfterB)
{
    if (BeforeA != BeforeB || AfterA != AfterB || AfterA <= BeforeA || BeforeA < 0 || AfterA > 3) return false;
    if (Source == 'BondCreated') return BeforeA == 0 && AfterA == 1;
    return Source == 'BondLevelUpComplete' && BeforeA >= 1;
}

static function bool NextOccurrence(array<BondOccurrence> Existing, string Pair, int FromLevel, int ToLevel, int BaseIndex, out BondOccurrence Record, out string Key)
{
    local int Index;
    Index = Existing.Find('PairKey', Pair);
    if (Index == INDEX_NONE) { Record.PairKey = Pair; Record.Episode = 1; }
    else
    {
        Record = Existing[Index];
        if (Record.SourceHistoryIndex == BaseIndex && Record.FromLevel == FromLevel && Record.ToLevel == ToLevel) return false;
        if (FromLevel == 0 && ToLevel == 1) Record.Episode++;
        else if (FromLevel < Record.ToLevel) return false;
    }
    Record.SourceHistoryIndex = BaseIndex; Record.FromLevel = FromLevel; Record.ToLevel = ToLevel;
    Key = Pair $ ":episode:" $ Record.Episode $ ":level:" $ ToLevel;
    return true;
}

static function JsonObject Mate(int UnitID, string SoldierName, string InstanceID)
{
    local JsonObject Result;
    Result = new class'JsonObject'; Result.SetIntValue("unit_id", UnitID);
    Result.SetStringValue("soldier_name", class'TNB_EventFactory'.static.SafeText(SoldierName, 100));
    if (InstanceID != "") Result.SetStringValue("instance_id", InstanceID);
    return Result;
}

static function JsonObject Capture(string Key, name Source, int A, string NameA, string InstanceA, int B, string NameB, string InstanceB, int BeforeLevel, int NewLevel)
{
    local JsonObject Facts, Details, Mates, Locals, LocalMate;
    local array<string> Instances;
    local string Label, Change;
    if (A > B) return Capture(Key, Source, B, NameB, InstanceB, A, NameA, InstanceA, BeforeLevel, NewLevel);
    if (InstanceA != "") Instances.AddItem(InstanceA);
    if (InstanceB != "" && Instances.Find(InstanceB) == INDEX_NONE) Instances.AddItem(InstanceB);
    if (Instances.Length == 0) return none;
    Change = BeforeLevel == 0 ? "formed" : "developed";
    Label = BeforeLevel == 0 ? "Soldier bond formed" : "Soldier bond level increased";
    Facts = new class'JsonObject'; Facts.SetStringValue("relationship_type", "xcom2.soldier_bond");
    Facts.SetIntValue("level", NewLevel); Facts.SetStringValue("details", Label @ "(level" @ NewLevel $ ")");
    Locals = new class'JsonObject';
    if (InstanceA == "")
    {
        LocalMate = new class'JsonObject'; LocalMate.SetStringValue("local_ref", "xcom2-unit-" $ A);
        LocalMate.SetStringValue("display_name", class'TNB_EventFactory'.static.SafeText(NameA, 100)); Locals.ObjectArray.AddItem(LocalMate);
    }
    if (InstanceB == "")
    {
        LocalMate = new class'JsonObject'; LocalMate.SetStringValue("local_ref", "xcom2-unit-" $ B);
        LocalMate.SetStringValue("display_name", class'TNB_EventFactory'.static.SafeText(NameB, 100)); Locals.ObjectArray.AddItem(LocalMate);
    }
    if (Locals.ObjectArray.Length > 0) Facts.SetObject("game_local_participants", Locals);
    Details = new class'JsonObject'; Details.SetStringValue("bond_kind", "xcom2_soldier_bond");
    Details.SetStringValue("native_event", string(Source)); Details.SetIntValue("previous_level", BeforeLevel); Details.SetIntValue("bond_level", NewLevel);
    Mates = new class'JsonObject';
    // Stable ordering, even when callbacks identify the pair in reverse.
    if (A < B) { Mates.ObjectArray.AddItem(Mate(A, NameA, InstanceA)); Mates.ObjectArray.AddItem(Mate(B, NameB, InstanceB)); }
    else { Mates.ObjectArray.AddItem(Mate(B, NameB, InstanceB)); Mates.ObjectArray.AddItem(Mate(A, NameA, InstanceA)); }
    Details.SetObject("bondmates", Mates);
    return class'TNB_EventFactory'.static.Capture(Key, "threadline.relationship." $ Change, Label $ ": " $ class'TNB_EventFactory'.static.SafeText(NameA, 100) $ " & " $ class'TNB_EventFactory'.static.SafeText(NameB, 100) @ "(level" @ NewLevel $ ")", Facts, Instances, , Details);
}

static function string LinkedInstance(XComGameState_Unit Soldier, XComGameState_TNBCampaignLink Campaign)
{
    local XComGameState_TNBSoldierLink Link;
    Link = class'XComGameState_TNBSoldierLink'.static.ForUnit(Soldier);
    if (Link != none && Link.CampaignID == Campaign.CampaignID && Link.Snapshot.JourneyID == Campaign.Journey.JourneyID && Link.Snapshot.CommanderID == Campaign.Journey.CommanderID) return Link.Snapshot.InstanceID;
    return "";
}

static function Observe(XComGameState Pending, XComGameState_Unit SourceA, XComGameState_Unit SourceB, name Source)
{
    local XComGameState_Unit A, B, OldA, OldB, Swap;
    local SoldierBond BeforeA, BeforeB, AfterA, AfterB;
    local XComGameState_TNBCampaignLink Campaign;
    local XComGameState_TNBEventLedger Ledger;
    local BondOccurrence Record;
    local JsonObject Report;
    local string InstanceA, InstanceB, Key;
    local int Index;
    if (Pending == none || SourceA == none || SourceB == none || SourceA.ObjectID == SourceB.ObjectID || `HQGAME == none) return;
    Campaign = class'XComGameState_TNBCampaignLink'.static.Get(Pending);
    if (Campaign == none || !Campaign.bOneTimeEffectsCommitted || Campaign.CampaignID != class'TNB_CampaignService'.static.CampaignID()) return;
    A = XComGameState_Unit(Pending.GetGameStateForObjectID(SourceA.ObjectID));
    B = XComGameState_Unit(Pending.GetGameStateForObjectID(SourceB.ObjectID));
    if (A == none || B == none || !A.IsSoldier() || !B.IsSoldier()) return;
    if (A.ObjectID > B.ObjectID) { Swap = A; A = B; B = Swap; }
    if (!A.GetBondData(B.GetReference(), AfterA) || !B.GetBondData(A.GetReference(), AfterB)) return;
    OldA = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(A.ObjectID));
    OldB = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(B.ObjectID));
    if (OldA != none) OldA.GetBondData(B.GetReference(), BeforeA);
    if (OldB != none) OldB.GetBondData(A.GetReference(), BeforeB);
    if (!ValidTransition(Source, BeforeA.BondLevel, BeforeB.BondLevel, AfterA.BondLevel, AfterB.BondLevel)) return;
    InstanceA = LinkedInstance(A, Campaign); InstanceB = LinkedInstance(B, Campaign);
    if (InstanceA == "" && InstanceB == "") return;
    if (InstanceA != "" && InstanceA == InstanceB) return;
    Ledger = class'XComGameState_TNBEventLedger'.static.Edit(Pending);
    if (Ledger == none) return;
    if (!NextOccurrence(Ledger.Bonds, PairKey(A.ObjectID, B.ObjectID), BeforeA.BondLevel, AfterA.BondLevel, `XCOMHISTORY.GetCurrentHistoryIndex(), Record, Key)) return;
    Index = Ledger.Bonds.Find('PairKey', Record.PairKey);
    if (Index == INDEX_NONE && Ledger.Bonds.Length >= 4096) { Ledger.Diagnostic = "bond_observation_capacity: new transition not captured"; return; }
    Report = Capture(Key, Source, A.ObjectID, A.GetFullName(), InstanceA, B.ObjectID, B.GetFullName(), InstanceB, BeforeA.BondLevel, AfterA.BondLevel);
    class'TNB_EventFactory'.static.Queue(Pending, Ledger, Key, Report.GetStringValue("event_type"), Report.GetStringValue("summary"), Report.GetObject("facts"), InstanceArray(InstanceA, InstanceB), , Report.GetObject("game_data"), Report.GetStringValue("captured_local"));
    // Do not advance replay state if the durable save-side outbox rejected the report.
    if (Ledger.SeenKeys.Find(Key) == INDEX_NONE) return;
    if (Index == INDEX_NONE) Ledger.Bonds.AddItem(Record);
    else Ledger.Bonds[Index] = Record;
}

static function array<string> InstanceArray(string A, string B)
{
    local array<string> Result;
    if (A != "") Result.AddItem(A);
    if (B != "" && Result.Find(B) == INDEX_NONE) Result.AddItem(B);
    return Result;
}
