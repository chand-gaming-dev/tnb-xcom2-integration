// The Name Beneath: single DLC entry point.
// See Docs/IMPLEMENTATION_STATUS.md for the native bridge proof results.
class X2DLCInfo_TheNameBeneath extends X2DownloadableContentInfo dependson(X2StrategyGameRulesetDataStructures);

var TNB_LoopbackClient Probe;
// Runtime DLC-instance cache, not config or save data. Survives HUD/mission travel.
var transient array<string> PromptedCampaigns;
var transient int PromptGeneration;

static function bool DisplayQueuedDynamicPopup(DynamicPropertySet PropertySet)
{
    return class'TNB_CommanderRewardPresentation'.static.DisplayQueuedPopup(PropertySet);
}

static function X2DLCInfo_TheNameBeneath SessionState()
{
    local array<X2DownloadableContentInfo> Infos;
    local X2DownloadableContentInfo Info;
    if (`ONLINEEVENTMGR == none) return none;
    Infos = `ONLINEEVENTMGR.GetDLCInfos(false);
    foreach Infos(Info)
        if (X2DLCInfo_TheNameBeneath(Info) != none) return X2DLCInfo_TheNameBeneath(Info);
    return none;
}

static function int ReminderGeneration()
{
    local X2DLCInfo_TheNameBeneath Session;
    Session = SessionState();
    return Session == none ? -1 : Session.PromptGeneration;
}

static function InvalidateReminderCallbacks()
{
    local X2DLCInfo_TheNameBeneath Session;
    Session = SessionState();
    if (Session != none) Session.PromptGeneration++;
}

static function bool ReminderOffered(string CampaignID)
{
    local X2DLCInfo_TheNameBeneath Session;
    Session = SessionState();
    return Session != none && Session.PromptedCampaigns.Find(CampaignID) != INDEX_NONE;
}

static function MarkReminderOffered(string CampaignID)
{
    local X2DLCInfo_TheNameBeneath Session;
    Session = SessionState();
    if (Session != none && CampaignID != "" && Session.PromptedCampaigns.Find(CampaignID) == INDEX_NONE) Session.PromptedCampaigns.AddItem(CampaignID);
}

static event OnLoadedSavedGameToStrategy()
{
    class'TNB_ReportingSafety'.static.Trace("LOAD_STRATEGY build=0.9.2");
    // Primitive epoch only: invalidate stale answers without creating/caching
    // prompt actors in a load callback. Facility-grid focus owns scheduling.
    InvalidateReminderCallbacks();
    class'TNB_EventPump'.static.Ensure();
}

static event OnLoadedSavedGameToTactical()
{
    InvalidateReminderCallbacks();
    class'TNB_ReportingSafety'.static.Trace("LOAD_TACTICAL build=0.9.2");
    class'TNB_EventPump'.static.Ensure();
}

static event OnPreMission(XComGameState StartGameState, XComGameState_MissionSite MissionState)
{
    InvalidateReminderCallbacks();
    class'TNB_ReportingSafety'.static.Trace("PRE_MISSION_BEGIN build=0.9.2", StartGameState);
    class'TNB_DetectionMappingService'.static.PrepareLaunch(StartGameState);
    class'TNB_EventCaptureService'.static.CarryToStartState(StartGameState);
    class'TNB_ReportingSafety'.static.Trace("PRE_MISSION_CARRIED", StartGameState);
    class'TNB_EventCaptureService'.static.PrepareMission(StartGameState, MissionState);
    class'TNB_ReportingSafety'.static.Trace("PRE_MISSION_PREPARED", StartGameState);
}

static event OnPostMission()
{
    class'TNB_ReportingSafety'.static.Trace("POST_MISSION_BEGIN");
    class'TNB_EventCaptureService'.static.PostMission();
    class'TNB_EventPump'.static.Ensure();
    class'TNB_ReportingSafety'.static.Trace("POST_MISSION_END");
}

static event ModifyTacticalTransferStartState(XComGameState TransferStartState)
{
    local XComGameState_TNBEventLedger Ledger;
    local int Index;
    class'TNB_ReportingSafety'.static.Trace("TACTICAL_TRANSFER_BEGIN", TransferStartState);
    class'TNB_DetectionMappingService'.static.PrepareLaunch(TransferStartState);
    class'TNB_EventCaptureService'.static.CarryToStartState(TransferStartState);
    Ledger = class'XComGameState_TNBEventLedger'.static.Edit(TransferStartState);
    if (Ledger == none) return;
    Index = Ledger.Missions.Find('Key', Ledger.CurrentTacticalKey);
    if (Index != INDEX_NONE) Ledger.Missions[Index].bCleanup = false;
    class'TNB_ReportingSafety'.static.Trace("TACTICAL_TRANSFER_END", TransferStartState);
}

static event OnPostTemplatesCreated()
{
    if (class'TNB_PolicyTests'.static.Run()) `log("Pure mapping/rounding policy checks passed.",, 'TheNameBeneath');
    else `log("WARNING: pure mapping/rounding policy checks failed.",, 'TheNameBeneath');
    if (class'TNB_EffectPresentation'.static.RunChecks()) `log("Read-only effect presentation checks passed. Automatic Avenger prompt disabled (MCM-only diagnostic build).",, 'TheNameBeneath');
    else `log("WARNING: effect presentation checks failed.",, 'TheNameBeneath');
    class'TNB_CommanderBonusService'.static.InstallRewardHooks();
    class'TNB_RecruitCostService'.static.Install();
}

static function ModifyEarnedSoldierAbilities(out array<SoldierClassAbilityType> EarnedAbilities, XComGameState_Unit UnitState)
{
    class'TNB_SoldierEffectService'.static.AddAbilities(EarnedAbilities, UnitState);
}

exec function TNBStatus()
{
    `log("Implementation milestone: campaign Journey setup in Avenger/MCM; Armory soldier linking is independent. Skills and new UI runtime validation pending.",, 'TheNameBeneath');
    `log("Development baseline: WOTC Community Highlander 1.31.3.",, 'TheNameBeneath');
    `log("Companion protocol 2. Run TNBProbeCompanion to test localhost.",, 'TheNameBeneath');
}

exec function TNBProbeCompanion()
{
    local WorldInfo World;
    World = class'WorldInfo'.static.GetWorldInfo();
    if (World == none) return;
    if (Probe != none) Probe.CancelRequest();
    Probe = World.Spawn(class'TNB_LoopbackClient');
    if (Probe != none) Probe.BeginRequest("ping", ProbeComplete);
}

function ProbeComplete(JsonObject Response, string ErrorCode)
{
    Probe = none;
    if (ErrorCode != "")
        `log("Companion probe failed:" @ ErrorCode,, 'TheNameBeneath');
    else
        `log("Companion probe succeeded; version" @ Response.GetStringValue("companion_version"),, 'TheNameBeneath');
}
