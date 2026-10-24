// Native UnitRankUp transaction only: never allocate/submit an independent state here.
class TNB_PromotionCaptureService extends TNB_EventTypes;

static function bool ValidTransition(int FromRank, int ToRank)
{
    return FromRank >= 0 && ToRank > FromRank;
}

static function int ObservedFromRank(int NativeBefore, int CapturedBefore)
{
    // Supports two real rank-ups in one pending transaction and ignores a reset
    // back to an already observed rank. The loaded save remains authoritative.
    return Max(NativeBefore, CapturedBefore);
}

static function string NormalizeOccurrenceID(string Value)
{
    local string Result;
    local int Index;
    if (Len(Value) > 38) return "";
    Result = Caps(Repl(Repl(Repl(Value, "-", ""), "{", ""), "}", ""));
    if (Len(Result) != 32 || Result == "00000000000000000000000000000000") return "";
    for (Index = 0; Index < Len(Result); Index++)
        if (InStr("0123456789ABCDEF", Mid(Result, Index, 1)) == INDEX_NONE) return "";
    return Result;
}

static function string Key(SoldierObservation Current, int FromRank, string OccurrenceID)
{
    local string ID;
    ID = NormalizeOccurrenceID(OccurrenceID);
    if (ID == "") return "";
    // New occurrence identity, not an XP achievement key. Never re-key old reports.
    return class'TNB_SoldierConditionObserver'.static.Identity(Current) $ ":rank:" $ FromRank $ ":" $ Current.Rank $ ":occurrence:" $ ID;
}

static function JsonObject Facts(int FromRank, int ToRank)
{
    local JsonObject Result;
    Result = new class'JsonObject';
    Result.SetStringValue("from_rank", string(FromRank));
    Result.SetStringValue("to_rank", string(ToRank));
    Result.SetStringValue("promotion_track", "xcom2_soldier_rank");
    return Result;
}

static function JsonObject Capture(SoldierObservation Current, int FromRank, string OccurrenceID)
{
    local array<string> Instances;
    if (Current.InstanceID == "" || !ValidTransition(FromRank, Current.Rank) || Key(Current, FromRank, OccurrenceID) == "") return none;
    Instances.AddItem(Current.InstanceID);
    return class'TNB_EventFactory'.static.Capture(Key(Current, FromRank, OccurrenceID), "threadline.character.promoted", "XCOM soldier promoted",
        Facts(FromRank, Current.Rank), Instances,,, Current.CapturedLocal);
}

static function bool CanRecord(XComGameState_TNBEventLedger Ledger, SoldierObservation Current, int FromRank)
{
    local int Index;
    if (Ledger == none || Current.InstanceID == "") return false;
    Index = Ledger.Soldiers.Find('UnitID', Current.UnitID);
    if (Index == INDEX_NONE || Ledger.Soldiers[Index].InstanceID != Current.InstanceID || Ledger.Soldiers[Index].LinkToken != Current.LinkToken) return false;
    return ValidTransition(ObservedFromRank(FromRank, Ledger.Soldiers[Index].Rank), Current.Rank);
}

// Production storage seam: plain saved objects only, also exercised by native probes.
// Updating the high-water mark in the SAME pending transaction prevents a history
// scan or second UnitRankUp callback from minting another occurrence for this rank.
static function bool Store(XComGameState_TNBEventLedger Ledger, XComGameState_TNBEventOutbox Outbox, SoldierObservation Current, int FromRank, string OccurrenceID)
{
    local JsonObject Report;
    local string EventKey;
    local int Index;
    if (Outbox == none || !CanRecord(Ledger, Current, FromRank)) return false;
    Index = Ledger.Soldiers.Find('UnitID', Current.UnitID);
    FromRank = ObservedFromRank(FromRank, Ledger.Soldiers[Index].Rank);
    Report = Capture(Current, FromRank, OccurrenceID);
    if (Report == none) return false;
    Report.SetStringValue("clock_zone", Ledger.ClockZone);
    EventKey = Report.GetStringValue("key");
    if (Ledger.SeenKeys.Find(EventKey) != INDEX_NONE || !Outbox.Add(EventKey, Report))
    { Ledger.Diagnostic = Outbox.Diagnostic; return false; }
    Ledger.SeenKeys.AddItem(EventKey);
    Ledger.Soldiers[Index].Rank = Current.Rank;
    return true;
}

// Repair only this known pre-handoff omission. Do not re-key reports, infer a new
// occurrence time, retry conflicts, or touch anything already handed off online.
static function bool RecoverClockZone(out PendingReport Saved, string VerifiedZone, optional string HoldReason)
{
    local JsonObject Report, Facts, Participants;
    local string FromRank, ToRank;
    if (VerifiedZone == "" || Saved.EventID != "" || (Saved.State != "held" && Saved.State != "captured")) return false;
    if (Saved.State == "held" && HoldReason != "event_invalid" && HoldReason != "event_clock_unverified") return false;
    Report = class'JsonObject'.static.DecodeJson(Saved.CaptureJSON);
    if (Report == none || Report.GetStringValue("event_type") != "threadline.character.promoted" || Report.GetStringValue("key") != Saved.Key || Report.GetStringValue("clock_zone") != "") return false;
    Facts = Report.GetObject("facts"); Participants = Report.GetObject("participants");
    if (Facts == none || Participants == none || Participants.ValueArray.Length != 1 || Facts.GetStringValue("promotion_track") != "xcom2_soldier_rank") return false;
    FromRank = Facts.GetStringValue("from_rank"); ToRank = Facts.GetStringValue("to_rank");
    if (FromRank != string(int(FromRank)) || ToRank != string(int(ToRank)) || !ValidTransition(int(FromRank), int(ToRank))) return false;
    // Retain the stored local time exactly; normal companion validation still applies.
    if (Len(Report.GetStringValue("captured_local")) != 23) return false;
    Report.SetStringValue("clock_zone", VerifiedZone);
    Saved.CaptureJSON = class'TNB_EventFactory'.static.ASCIIJson(Report);
    Saved.State = "captured";
    return true;
}

static function bool Queue(XComGameState Pending, XComGameState_TNBEventLedger Ledger, SoldierObservation Current, int FromRank, optional name Source='history')
{
    local XComGameState_TNBEventOutbox Outbox;
    local string OccurrenceID;
    local bool bQueued;
    if (Pending == none || !CanRecord(Ledger, Current, FromRank)) return false;
    // Platform GUID, not the campaign's gameplay random stream. Generated only
    // for a new observed transition, then frozen in the saved outbox. Delivery,
    // restart, post-promotion reload and authorization retries never call this.
    if (`FXSLIVE != none) OccurrenceID = NormalizeOccurrenceID(`FXSLIVE.GetGUID());
    if (OccurrenceID == "") { Ledger.Diagnostic = "promotion_occurrence_id_unavailable"; return false; }
    Outbox = class'XComGameState_TNBEventOutbox'.static.Edit(Pending);
    bQueued = Store(Ledger, Outbox, Current, FromRank, OccurrenceID);
    class'TNB_ReportingSafety'.static.Trace("PROMOTION source=" $ Source $ " from=" $ FromRank $ " to=" $ Current.Rank $ " captured=" $ bQueued, Pending);
    return bQueued;
}

static function Observe(XComGameState Pending, XComGameState_Unit Source)
{
    local XComGameState_Unit BeforeUnit, AfterUnit;
    local XComGameState_TNBCampaignLink Campaign;
    local XComGameState_TNBSoldierLink BeforeLink, AfterLink;
    local XComGameState_TNBEventLedger Ledger;
    local SoldierObservation Before, After;
    local int Index;
    if (Pending == none || Source == none) return;
    AfterUnit = XComGameState_Unit(Pending.GetGameStateForObjectID(Source.ObjectID));
    BeforeUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Source.ObjectID));
    // New/reward units, mere eligibility, ability purchases and link-time baseline ranks are not promotions.
    if (BeforeUnit == none || AfterUnit == none || !BeforeUnit.IsSoldier() || !AfterUnit.IsSoldier()) return;
    if (!ValidTransition(BeforeUnit.GetRank(), AfterUnit.GetRank())) return;
    Campaign = class'XComGameState_TNBCampaignLink'.static.Get(Pending);
    if (Campaign == none || !Campaign.bOneTimeEffectsCommitted || Campaign.CampaignID != class'TNB_CampaignService'.static.CampaignID()) return;
    BeforeLink = class'XComGameState_TNBSoldierLink'.static.ForUnit(BeforeUnit);
    AfterLink = class'XComGameState_TNBSoldierLink'.static.ForUnit(AfterUnit);
    if (BeforeLink == none || AfterLink == none || BeforeLink.ObjectID != AfterLink.ObjectID) return;
    if (AfterLink.CampaignID != Campaign.CampaignID || AfterLink.Snapshot.JourneyID != Campaign.Journey.JourneyID || AfterLink.Snapshot.CommanderID != Campaign.Journey.CommanderID) return;
    if (!class'TNB_SoldierConditionObserver'.static.Snapshot(BeforeUnit, Before, BeforeLink) || !class'TNB_SoldierConditionObserver'.static.Snapshot(AfterUnit, After, AfterLink)) return;
    Ledger = class'XComGameState_TNBEventLedger'.static.Edit(Pending);
    if (Ledger == none) return;
    Index = Ledger.Soldiers.Find('UnitID', After.UnitID);
    if (Index == INDEX_NONE)
    {
        class'TNB_SoldierConditionObserver'.static.Observe(Pending, Ledger, Before, true);
        Index = Ledger.Soldiers.Find('UnitID', After.UnitID);
    }
    if (Index == INDEX_NONE || Ledger.Soldiers[Index].InstanceID != After.InstanceID || Ledger.Soldiers[Index].LinkToken != After.LinkToken) return;
    Before.Rank = ObservedFromRank(Before.Rank, Ledger.Soldiers[Index].Rank);
    if (!ValidTransition(Before.Rank, After.Rank)) return;
    if (Queue(Pending, Ledger, After, Before.Rank, 'UnitRankUp'))
        Ledger.Soldiers[Index].Rank = Max(Ledger.Soldiers[Index].Rank, After.Rank);
}
