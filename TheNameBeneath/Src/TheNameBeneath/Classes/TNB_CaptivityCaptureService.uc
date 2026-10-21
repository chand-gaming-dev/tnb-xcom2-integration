// Evidence only. Never rescues, relinks, reapplies bonuses or submits game states.
class TNB_CaptivityCaptureService extends TNB_EventTypes;

static function string Transition(bool WasCaptured, bool IsCaptured, bool IsDead, bool InCrew)
{
    if (IsDead) return "";
    if (!WasCaptured && IsCaptured) return "captured";
    if (WasCaptured && !IsCaptured && InCrew) return "freed";
    return "";
}

static function JsonObject Capture(CaptivityObservation Record, string Change, string SoldierName, string CapturedLocal)
{
    local JsonObject Facts, Details;
    local array<string> Instances;
    local string Key;
    Facts = new class'JsonObject';
    Facts.SetStringValue("circumstances", class'TNB_EventFactory'.static.SafeText("XCOM soldier " $ SoldierName $ (Change == "captured" ? " was captured." : " returned from captivity to the Avenger.")));
    Details = new class'JsonObject'; Details.SetIntValue("unit_id", Record.UnitID);
    Details.SetIntValue("capture_sequence", Record.CaptureSequence); Details.SetIntValue("freedom_sequence", Record.FreedomSequence);
    Details.SetStringValue("evidence", "committed_soldier_capture_flag_and_roster");
    Instances.AddItem(Record.InstanceID);
    Key = "unit:" $ Record.UnitID $ ":" $ Record.InstanceID $ ":captivity:" $ Record.CaptureSequence $ ":" $ Change;
    if (Change == "freed") Key $= ":" $ Record.FreedomSequence;
    return class'TNB_EventFactory'.static.Capture(Key, "threadline.character." $ Change, "XCOM soldier " $ Change $ ": " $ SoldierName, Facts, Instances,, Details, CapturedLocal);
}

static function Observe(XComGameState Pending, XComGameState_TNBEventLedger Ledger, XComGameState_Unit Soldier, optional XComGameState Evidence, optional string CapturedLocal, optional bool Baseline, optional XComGameState_TNBSoldierLink PendingLink, optional bool FinalizedTransfer)
{
    local XComGameState_TNBCampaignLink Campaign;
    local XComGameState_HeadquartersXCom HQ;
    local CaptivityObservation Record;
    local JsonObject Report;
    local string Instance, Change;
    local int Index, FrameIndex;
    if (Pending == none || Ledger == none || Soldier == none || !Soldier.IsSoldier()) return;
    Campaign = class'XComGameState_TNBCampaignLink'.static.Get(Pending);
    if (Campaign == none || !Campaign.bOneTimeEffectsCommitted) return;
    Instance = class'TNB_BondCaptureService'.static.LinkedInstance(Soldier, Campaign);
    if (PendingLink != none && PendingLink.bEffectsCommitted && PendingLink.UnitRef.ObjectID == Soldier.ObjectID && PendingLink.CampaignID == Campaign.CampaignID && PendingLink.Snapshot.JourneyID == Campaign.Journey.JourneyID && PendingLink.Snapshot.CommanderID == Campaign.Journey.CommanderID) Instance = PendingLink.Snapshot.InstanceID;
    if (Instance == "") return;
    FrameIndex = `XCOMHISTORY.GetCurrentHistoryIndex() + 1;
    if (Evidence != none) FrameIndex = Evidence.HistoryIndex;
    Index = Ledger.Captivities.Find('UnitID', Soldier.ObjectID);
    if (Index != INDEX_NONE) Record = Ledger.Captivities[Index];
    if (Index == INDEX_NONE || Record.InstanceID != Instance || Baseline)
    {
        if (Index == INDEX_NONE && Ledger.Captivities.Length >= 4096) { Ledger.Diagnostic = "captivity_observation_capacity"; return; }
        // Loading/linking an existing prisoner is a baseline, not a past capture.
        if (Record.InstanceID != Instance) { Record.CaptureSequence = 0; Record.FreedomSequence = 0; }
        Record.UnitID = Soldier.ObjectID; Record.InstanceID = Instance;
        Record.bCaptured = Soldier.bCaptured; Record.ObservedHistoryIndex = FrameIndex;
        if (Index == INDEX_NONE) Ledger.Captivities.AddItem(Record); else Ledger.Captivities[Index] = Record;
        return;
    }
    // A verified tactical->strategy transfer can reset history numbering. Its
    // finalized flags/roster are direct evidence, not a guessed history-gap delta.
    if (FrameIndex <= Record.ObservedHistoryIndex && !FinalizedTransfer) return;
    if (Evidence != none)
        HQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetGameStateForObjectID(`XCOMHQ.ObjectID,, FrameIndex));
    else
    {
        HQ = XComGameState_HeadquartersXCom(Pending.GetGameStateForObjectID(`XCOMHQ.ObjectID));
        if (HQ == none) HQ = `XCOMHQ;
    }
    Change = Transition(Record.bCaptured, Soldier.bCaptured, Soldier.IsDead(), HQ != none && HQ.Crew.Find('ObjectID', Soldier.ObjectID) != INDEX_NONE);
    if (Change != "")
    {
        if (Change == "captured") Record.CaptureSequence++; else Record.FreedomSequence++;
        Report = Capture(Record, Change, Soldier.GetFullName(), CapturedLocal);
        class'TNB_EventFactory'.static.Queue(Pending, Ledger, Report.GetStringValue("key"), Report.GetStringValue("event_type"), Report.GetStringValue("summary"), Report.GetObject("facts"), class'TNB_BondCaptureService'.static.InstanceArray(Instance, ""),, Report.GetObject("game_data"), Report.GetStringValue("captured_local"));
        if (Ledger.SeenKeys.Find(Report.GetStringValue("key")) == INDEX_NONE) return;
        Record.bCaptured = Soldier.bCaptured;
        `log("TNB_REPORT CAPTIVITY transition=" $ Change $ " sequence=" $ Record.CaptureSequence $ " source_index=" $ FrameIndex,, 'TheNameBeneath');
    }
    // Retain captivity until both clearing the flag AND a confirmed crew return.
    if (Soldier.IsDead()) Record.bCaptured = Soldier.bCaptured;
    Record.ObservedHistoryIndex = FrameIndex;
    Ledger.Captivities[Index] = Record;
}

static function FinalizedReturn(XComGameState Pending, XComGameState_TNBEventLedger Ledger)
{
    local int Index;
    local XComGameState_Unit Soldier;
    // Includes the rescued objective soldier, NOT just deployed squad members.
    // Never adds prisoners to mission participation or reactivates their links.
    for (Index = 0; Index < Ledger.Captivities.Length; Index++)
    {
        Soldier = class'TNB_EventCaptureService'.static.Unit(Ledger.Captivities[Index].UnitID, Pending);
        Observe(Pending, Ledger, Soldier,,,,, true);
    }
}

static function ObserveFrame(XComGameState Pending, XComGameState_TNBEventLedger Ledger, XComGameState Frame, string CapturedLocal)
{
    local XComGameState_Unit Soldier;
    local XComGameState_HeadquartersXCom HQ;
    local int Index;
    foreach Frame.IterateByClassType(class'XComGameState_Unit', Soldier) Observe(Pending, Ledger, Soldier, Frame, CapturedLocal);
    // Some release mods add a unit to Crew after clearing its capture flag.
    // Observe a roster commit even when it does not modify the soldier again.
    foreach Frame.IterateByClassType(class'XComGameState_HeadquartersXCom', HQ)
        for (Index = 0; Index < Ledger.Captivities.Length; Index++)
        {
            Soldier = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ledger.Captivities[Index].UnitID,, Frame.HistoryIndex));
            Observe(Pending, Ledger, Soldier, Frame, CapturedLocal);
        }
}

static function ObserveNative(XComGameState Pending, XComGameState_Unit Soldier)
{
    local XComGameState_TNBEventLedger Ledger;
    local XComGameState_Unit Before;
    if (Pending == none || Soldier == none) return;
    Ledger = class'XComGameState_TNBEventLedger'.static.Edit(Pending);
    if (Ledger == none) return;
    if (Ledger.Captivities.Find('UnitID', Soldier.ObjectID) == INDEX_NONE)
    {
        Before = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Soldier.ObjectID));
        if (Before == none) return;
        Observe(Pending, Ledger, Before, `XCOMHISTORY.GetGameStateFromHistory(`XCOMHISTORY.GetCurrentHistoryIndex()),, true);
    }
    Observe(Pending, Ledger, Soldier);
}
