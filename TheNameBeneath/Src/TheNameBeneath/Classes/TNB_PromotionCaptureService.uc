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

static function string Key(SoldierObservation Current, int FromRank)
{
    // Same occurrence identity as the existing observer; no new replay/award namespace.
    return class'TNB_SoldierConditionObserver'.static.Identity(Current) $ ":rank:" $ FromRank $ ":" $ Current.Rank;
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

static function JsonObject Capture(SoldierObservation Current, int FromRank)
{
    local array<string> Instances;
    if (Current.InstanceID == "" || !ValidTransition(FromRank, Current.Rank)) return none;
    Instances.AddItem(Current.InstanceID);
    return class'TNB_EventFactory'.static.Capture(Key(Current, FromRank), "threadline.character.promoted", "XCOM soldier promoted",
        Facts(FromRank, Current.Rank), Instances,,, Current.CapturedLocal);
}

static function bool Queue(XComGameState Pending, XComGameState_TNBEventLedger Ledger, SoldierObservation Current, int FromRank, optional name Source='history')
{
    local JsonObject Report;
    local array<string> Instances;
    local bool bQueued;
    if (Ledger == none) return false;
    Report = Capture(Current, FromRank);
    if (Report == none) return false;
    Instances.AddItem(Current.InstanceID);
    class'TNB_EventFactory'.static.Queue(Pending, Ledger, Key(Current, FromRank), "threadline.character.promoted", Report.GetStringValue("summary"), Report.GetObject("facts"), Instances,,, Current.CapturedLocal);
    bQueued = Ledger.SeenKeys.Find(Key(Current, FromRank)) != INDEX_NONE;
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
