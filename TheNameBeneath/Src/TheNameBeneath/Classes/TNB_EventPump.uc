// One actor per loaded world, never cached by DLC templates or UI listeners.
class TNB_EventPump extends Actor dependson(TNB_EventTypes);

var private TNB_LoopbackClient Request;
var private XComGameStateHistory ObservedHistory;
var private bool bReady, bInitialized;
var private bool bBondMilestones;
var private bool bFactualEvents;
var private bool bHistoryDirty, bFrameClockVerified, bClockSampleLogged;
var private string PendingClockZone;
var private float NextAttempt;
var private string SendingKey;
var private JsonObject ReplyData;
var private string ReplyError;
var private bool bReplyPending;
var private string LastGateReason;
var private float NextGateLog;
var private bool bSubmittingReportingState;
var string StatusText;

static function TNB_EventPump Find()
{
    local WorldInfo World;
    local TNB_EventPump Pump;
    World = class'WorldInfo'.static.GetWorldInfo();
    if (World != none)
        foreach World.AllActors(class'TNB_EventPump', Pump) return Pump;
    return none;
}

static function Ensure()
{
    local WorldInfo World;
    if (Find() != none) return;
    World = class'WorldInfo'.static.GetWorldInfo();
    if (World != none && World.Game != none) World.Spawn(class'TNB_EventPump');
}

event PostBeginPlay()
{
    super.PostBeginPlay();
    ObservedHistory = `XCOMHISTORY;
    if (ObservedHistory != none) ObservedHistory.RegisterOnNewGameStateDelegate(OnCommittedState);
    bHistoryDirty = true;
    class'TNB_ReportingSafety'.static.Trace("PUMP_START build=0.9.2");
    SetTimer(1.0, true, 'Work');
}

private function bool BackgroundAllowed()
{
    local string Reason;
    Reason = class'TNB_ReportingSafety'.static.BlockReason(WorldInfo, ObservedHistory);
    if (Reason != LastGateReason || (Reason != "" && WorldInfo.TimeSeconds >= NextGateLog))
    {
        if (Reason == "") class'TNB_ReportingSafety'.static.Trace("PUMP_RESUMED");
        else class'TNB_ReportingSafety'.static.Trace("PUMP_DEFERRED reason=" $ Reason);
        LastGateReason = Reason;
        NextGateLog = WorldInfo.TimeSeconds + 30.0;
    }
    return Reason == "";
}

private function XComGameState CreateReportingChange(string Summary, name Operation)
{
    local XComGameState Pending;
    // Check before allocation too: even Create/CleanupPendingGameState is unsafe in a history lock.
    if (!BackgroundAllowed()) return none;
    class'TNB_ReportingSafety'.static.Trace("CREATE_BEGIN op=" $ Operation);
    Pending = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(Summary);
    class'TNB_ReportingSafety'.static.Trace("CREATE_END op=" $ Operation, Pending);
    return Pending;
}

private function bool SubmitReportingChange(XComGameState Pending, name Operation)
{
    local bool bAccepted;
    // Called synchronously after the gated allocation/edit, with no latent wait or socket work.
    class'TNB_ReportingSafety'.static.Trace("SUBMIT_BEGIN op=" $ Operation, Pending);
    bSubmittingReportingState = true;
    bAccepted = `XCOMGAME.GameRuleset.SubmitGameState(Pending);
    bSubmittingReportingState = false;
    class'TNB_ReportingSafety'.static.Trace("SUBMIT_END op=" $ Operation $ " accepted=" $ bAccepted);
    return bAccepted;
}

// Notification only. Saved native history is the recovery journal, including an immediate save.
function OnCommittedState(XComGameState NewGameState)
{
    local XComGameState_Unit Soldier;
    local XComGameState_HeadquartersXCom HQ;
    local string NativeClock, LocalClock;
    if (NewGameState == none) return;
    NativeClock = class'TNB_EventFactory'.static.FrameClock(NewGameState.TimeStamp);
    LocalClock = class'TNB_EventFactory'.static.CaptureClock();
    if (!bClockSampleLogged)
    {
        `log("TNB_REPORTING_CLOCK_SAMPLE native=" $ NewGameState.TimeStamp $ " local=" $ LocalClock,, 'TheNameBeneath');
        bClockSampleLogged = true;
    }
    if (NativeClock != "" && Left(NativeClock, 16) == Left(LocalClock, 16)) bFrameClockVerified = true;
    // Notifications may arrive while the native start state is being built. No state writes,
    // component lookups or history scans here until initialization is over.
    if (bSubmittingReportingState) return;
    if (class'TNB_ReportingSafety'.static.BlockReason(WorldInfo, ObservedHistory) != "")
    { bHistoryDirty = true; return; }
    foreach NewGameState.IterateByClassType(class'XComGameState_Unit', Soldier)
    {
        if (class'XComGameState_TNBSoldierLink'.static.ForUnit(Soldier) != none) { bHistoryDirty = true; break; }
    }
    foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', HQ) { bHistoryDirty = true; break; }
}

private function InitializeBaselines()
{
    local XComGameState_TNBSoldierLink Link;
    local XComGameState_TNBEventLedger Ledger;
    local XComGameState Pending;
    local TNB_EventTypes.SoldierObservation Observation;
    local int MissingSoldiers;
    if (class'XComGameState_TNBCampaignLink'.static.Get() == none) return;
    Ledger = class'XComGameState_TNBEventLedger'.static.Get();
    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_TNBSoldierLink', Link)
        if (Ledger == none || Ledger.Soldiers.Find('UnitID', Link.UnitRef.ObjectID) == INDEX_NONE || Ledger.Captivities.Find('UnitID', Link.UnitRef.ObjectID) == INDEX_NONE)
            if (class'TNB_SoldierConditionObserver'.static.Snapshot(class'TNB_EventCaptureService'.static.Unit(Link.UnitRef.ObjectID), Observation)) MissingSoldiers++;
    if (!class'TNB_ReportingSafety'.static.NeedsBaselines(Ledger == none, MissingSoldiers))
    {
        class'TNB_ReportingSafety'.static.Trace("BASELINES_UNCHANGED no_submission");
        bInitialized = true;
        return;
    }
    Pending = CreateReportingChange("The Name Beneath: initialize future-only reporting", 'baselines');
    if (Pending == none) return;
    Ledger = class'XComGameState_TNBEventLedger'.static.Edit(Pending);
    if (Ledger == none) { `XCOMHISTORY.CleanupPendingGameState(Pending); return; }
    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_TNBSoldierLink', Link)
    {
        if (Ledger.Soldiers.Find('UnitID', Link.UnitRef.ObjectID) == INDEX_NONE && class'TNB_SoldierConditionObserver'.static.Snapshot(class'TNB_EventCaptureService'.static.Unit(Link.UnitRef.ObjectID), Observation))
            class'TNB_SoldierConditionObserver'.static.Observe(Pending, Ledger, Observation, true);
        if (Ledger.Captivities.Find('UnitID', Link.UnitRef.ObjectID) == INDEX_NONE)
            class'TNB_CaptivityCaptureService'.static.Observe(Pending, Ledger, class'TNB_EventCaptureService'.static.Unit(Link.UnitRef.ObjectID),,, true);
    }
    bInitialized = SubmitReportingChange(Pending, 'baselines');
}

private function DrainObservations()
{
    local XComGameState Pending;
    local XComGameState_TNBEventLedger Ledger;
    local bool bMoreHistory;
    if (!bHistoryDirty) return;
    Pending = CreateReportingChange("The Name Beneath: committed soldier transitions", 'observations');
    if (Pending == none) return;
    Ledger = class'XComGameState_TNBEventLedger'.static.Edit(Pending);
    if (Ledger != none)
    {
        Ledger.bFrameClockVerified = Ledger.bFrameClockVerified || bFrameClockVerified;
        class'TNB_EventCaptureService'.static.ObserveHistory(Pending, Ledger);
        bMoreHistory = Ledger.bFrameClockVerified && Ledger.LastObservedHistoryIndex < `XCOMHISTORY.GetCurrentHistoryIndex();
        if (SubmitReportingChange(Pending, 'observations')) bHistoryDirty = bMoreHistory;
    }
    else `XCOMHISTORY.CleanupPendingGameState(Pending);
}

function Work()
{
    local XComGameState_TNBCampaignLink Campaign;
    local XComGameState_TNBEventOutbox Outbox;
    local JsonObject Args;
    local JsonObject Capture;
    local int Index;
    local bool bNeedsBondUpdate;
    // Must precede all history registration, allocation, edits, submission and networking.
    if (!BackgroundAllowed()) return;
    // History reset/travel may clear native registrations; keep exactly one, owned by this world.
    ObservedHistory.UnRegisterOnNewGameStateDelegate(OnCommittedState);
    ObservedHistory.RegisterOnNewGameStateDelegate(OnCommittedState);
    Campaign = class'XComGameState_TNBCampaignLink'.static.Get();
    if (Campaign == none) return;
    if (!bInitialized) InitializeBaselines();
    if (!bInitialized) return;
    if (PendingClockZone != "") SaveClockZone();
    DrainObservations();
    if (bReplyPending) AdoptReply();
    if (bReplyPending) return; // Keep the reply and replay key if a submission was refused.
    if (Request != none || WorldInfo.TimeSeconds < NextAttempt) return;
    NextAttempt = WorldInfo.TimeSeconds + 1.0;
    if (!bReady)
    {
        Request = Spawn(class'TNB_LoopbackClient');
        if (Request != none) Request.BeginRequest("ping", CapabilityReply);
        return;
    }
    Outbox = class'XComGameState_TNBEventOutbox'.static.Get();
    if (Outbox == none || Outbox.Reports.Length == 0) return;
    Index = 0;
    bNeedsBondUpdate = false;
    while (Index < Outbox.Reports.Length)
    {
        if (Outbox.Reports[Index].State == "held") { Index++; continue; }
        Capture = class'JsonObject'.static.DecodeJson(Outbox.Reports[Index].CaptureJSON);
        if (!bFactualEvents && Capture != none && (Left(Capture.GetStringValue("event_type"), 23) == "threadline.relationship" || Capture.GetStringValue("event_type") == "threadline.character.captured" || Capture.GetStringValue("event_type") == "threadline.character.freed"))
        { bNeedsBondUpdate = true; Index++; continue; }
        if (!bBondMilestones && Capture != none && Capture.GetStringValue("event_type") == "threadline.narrative.milestone_reached")
        { bNeedsBondUpdate = true; Index++; continue; }
        break;
    }
    if (bNeedsBondUpdate)
    {
        StatusText = "companion update required for relationship/captivity reports; reports retained";
        bReady = false; // Re-handshake after a companion upgrade; unrelated reports remain eligible.
        if (Index >= Outbox.Reports.Length) NextAttempt = WorldInfo.TimeSeconds + 30.0;
    }
    if (Index >= Outbox.Reports.Length) return;
    SendingKey = Outbox.Reports[Index].Key;
    Args = new class'JsonObject';
    Args.SetStringValue("expected_journey_id", Campaign.Journey.JourneyID);
    Args.SetStringValue("expected_commander_id", Campaign.Journey.CommanderID);
    Args.SetStringValue("campaign_id", Campaign.CampaignID);
    Args.SetStringValue("sender_local_now", class'TNB_EventFactory'.static.CaptureClock());
    Args.SetObject("capture", class'JsonObject'.static.DecodeJson(Outbox.Reports[Index].CaptureJSON));
    Request = Spawn(class'TNB_LoopbackClient');
    if (Request != none) Request.BeginRequest("events_enqueue", EnqueueReply, Args);
}

function CapabilityReply(JsonObject Result, string ErrorCode)
{
    Request = none;
    bReady = ErrorCode == "" && Result != none && Result.GetIntValue("gameplay_events_version") == 1;
    bBondMilestones = bReady && Result.GetIntValue("bond_milestones_version") >= 1;
    bFactualEvents = bReady && Result.GetIntValue("factual_events_version") >= 1;
    if (bReady && Left(Result.GetStringValue("local_clock"), 16) == Left(class'TNB_EventFactory'.static.CaptureClock(), 16)) PendingClockZone = Result.GetStringValue("clock_zone");
    StatusText = bReady ? "companion event handoff available" : (ErrorCode == "" ? "companion update required (gameplay events v1)" : ErrorCode);
}

private function SaveClockZone()
{
    local XComGameState Pending;
    local XComGameState_TNBEventLedger Ledger;
    Ledger = class'XComGameState_TNBEventLedger'.static.Get();
    if (Ledger == none) return;
    if (Ledger.ClockZone != PendingClockZone)
    {
        Pending = CreateReportingChange("The Name Beneath: verified companion clock zone", 'clock_zone');
        if (Pending == none) return;
        Ledger = class'XComGameState_TNBEventLedger'.static.Edit(Pending);
        if (Ledger != none)
        {
            if (Ledger.ClockZone == "") Ledger.ClockZone = PendingClockZone;
            else Ledger.Diagnostic = "event_clock_zone_changed: queued capture timezone requires review";
            if (!SubmitReportingChange(Pending, 'clock_zone')) return;
        }
        else `XCOMHISTORY.CleanupPendingGameState(Pending);
    }
    PendingClockZone = "";
}

function EnqueueReply(JsonObject Result, string ErrorCode)
{
    Request = none;
    ReplyData = Result; ReplyError = ErrorCode; bReplyPending = true;
    // No game-state commit from inside a socket event. Adopt it on the next safe work tick.
}

private function AdoptReply()
{
    local XComGameState Pending;
    local XComGameState_TNBEventOutbox Outbox;
    local int Index;
    StatusText = ReplyError;
    Outbox = class'XComGameState_TNBEventOutbox'.static.Get();
    if (Outbox == none) { bReplyPending = false; ReplyData = none; SendingKey = ""; return; }
    Index = Outbox.Reports.Find('Key', SendingKey);
    if (Index == INDEX_NONE) { bReplyPending = false; ReplyData = none; SendingKey = ""; return; }
    if (ReplyError == "" && ReplyData != none && ReplyData.GetBoolValue("durable") && ReplyData.GetStringValue("event_id") != "")
    {
        Pending = CreateReportingChange("The Name Beneath: acknowledge durable companion handoff", 'handoff_ack');
        if (Pending == none) return;
        Outbox = class'XComGameState_TNBEventOutbox'.static.Edit(Pending);
        Outbox.Reports.Remove(Index, 1);
        if (!SubmitReportingChange(Pending, 'handoff_ack')) return;
        StatusText = "durably queued in companion (online acceptance tracked separately)";
    }
    else if (ReplyError == "event_replay_conflict" || ReplyError == "event_invalid" || Left(ReplyError, 12) == "event_clock_" || ReplyError == "event_too_large")
    {
        Pending = CreateReportingChange("The Name Beneath: hold invalid or conflicting report", 'hold_report');
        if (Pending == none) return;
        Outbox = class'XComGameState_TNBEventOutbox'.static.Edit(Pending);
        Outbox.Reports[Index].State = "held";
        Outbox.Diagnostic = ReplyError;
        if (!SubmitReportingChange(Pending, 'hold_report')) return;
    }
    else { bReady = false; NextAttempt = WorldInfo.TimeSeconds + 30.0; }
    bReplyPending = false;
    ReplyData = none;
    SendingKey = "";
}

event Destroyed()
{
    class'TNB_ReportingSafety'.static.Trace("PUMP_DESTROY");
    ClearTimer('Work');
    if (ObservedHistory != none) ObservedHistory.UnRegisterOnNewGameStateDelegate(OnCommittedState);
    ObservedHistory = none;
    if (Request != none) Request.CancelRequest();
    Request = none; ReplyData = none;
    super.Destroyed();
}

defaultproperties
{
    bHidden=true
    bAlwaysTick=true
}
