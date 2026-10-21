class XComGameState_TNBEventLedger extends XComGameState_BaseObject dependson(TNB_EventTypes);

var int SchemaVersion;
var string CampaignID;
var string JourneyID;
var array<TNB_EventTypes.SoldierObservation> Soldiers;
var array<TNB_EventTypes.MissionObservation> Missions;
var array<string> SeenKeys;
var array<TNB_EventTypes.BondOccurrence> Bonds;
var array<TNB_EventTypes.CaptivityObservation> Captivities;
var array<TNB_EventTypes.MissionInjurySnapshot> MissionInjuries;
var array<TNB_EventTypes.TacticalMissionAttempt> TacticalAttempts;
var string HistoryDiagnostic;
var int HistoryGapCount;
var string Diagnostic;
var string CurrentTacticalKey;
var int CurrentBattleMissionID;
var int LastObservedHistoryIndex;
var bool bFrameClockVerified;
var string ClockZone;

static function XComGameState_TNBEventLedger Get(optional XComGameState Pending)
{
    local XComGameState_TNBEventLedger Ledger;
    if (Pending != none)
        foreach Pending.IterateByClassType(class'XComGameState_TNBEventLedger', Ledger) return Ledger;
    return XComGameState_TNBEventLedger(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_TNBEventLedger', true));
}

static function XComGameState_TNBEventLedger Edit(XComGameState Pending)
{
    local XComGameState_TNBEventLedger Ledger;
    local XComGameState_TNBCampaignLink Link;
    Link = class'XComGameState_TNBCampaignLink'.static.Get(Pending);
    if (Link == none || !Link.bOneTimeEffectsCommitted || Link.CampaignID == "" || Link.CampaignID != class'TNB_CampaignService'.static.CampaignID()) return none;
    foreach Pending.IterateByClassType(class'XComGameState_TNBEventLedger', Ledger) return Ledger;
    Ledger = class'XComGameState_TNBEventLedger'.static.Get();
    if (Ledger != none)
    {
        if (Ledger.SchemaVersion != 1 || Ledger.CampaignID != Link.CampaignID || Ledger.JourneyID != Link.Journey.JourneyID) return none;
        return XComGameState_TNBEventLedger(Pending.ModifyStateObject(class'XComGameState_TNBEventLedger', Ledger.ObjectID));
    }
    Ledger = XComGameState_TNBEventLedger(Pending.CreateNewStateObject(class'XComGameState_TNBEventLedger'));
    Ledger.SchemaVersion = 1;
    Ledger.CampaignID = Link.CampaignID;
    Ledger.JourneyID = Link.Journey.JourneyID;
    Ledger.LastObservedHistoryIndex = `XCOMHISTORY.GetCurrentHistoryIndex();
    return Ledger;
}

defaultproperties
{
    bTacticalTransient=false
}
