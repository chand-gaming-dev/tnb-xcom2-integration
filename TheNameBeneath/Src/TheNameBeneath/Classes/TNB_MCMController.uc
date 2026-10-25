// Status, diagnostics and settings only. Campaign linking lives under Command.
class TNB_MCMController extends Object;

var UIScreen ParentScreen;
var TNB_LoopbackClient Request;
var MCM_API_Label CompanionLabel;
var MCM_API_Label ServiceLabel;
var MCM_API_Label JourneyLabel;
var MCM_API_Label JourneyIdentityLabel, JourneyCommanderLabel;
var MCM_API_Checkbox StoredIndicator;
var MCM_API_Button RefreshButton;
var MCM_API_Button TestButton;
var MCM_API_Label CampaignLabel;
var string ReminderCampaignID;
var bool bCampaignMode;
var TNB_LoopbackClient ReportingRequest;
var MCM_API_Label ReportingLabel;
var MCM_API_Label ReportingQueueLabel, ReportingAcceptedLabel, ReportingClockLabel, ReportingDiagnosticLabel;
var MCM_API_Button ReportingRefresh, ReportingRetry;

var localized string ModName, PageTitle, ConnectionGroup;
var localized string CompanionChecking, CompanionConnected, CompanionUnavailable, CompanionTimeout, CompanionIncompatible, CompanionHelp;
var localized string ServiceChecking, ServiceVerified, ServiceUnverified, ServiceNotConfigured, ServiceUnableToVerify, ServiceInvalidCredential, ServiceScopeMissing, ServiceUnknown, ServiceHelp;
var localized string JourneyUnavailable, CommanderPrefix, JourneyPrefix, JourneyUpcoming, JourneyStarted, JourneyFinished, JourneyUnknown, JourneyHelp;
var localized string CredentialStored, CredentialChecking, CredentialUnavailable, CredentialHelp;
var localized string RefreshTitle, RefreshText, RefreshHelp, TestTitle, TestText, TestHelp;
var localized string CampaignGroup, CampaignDisconnected, CampaignUnavailable, CampaignHelp, CommandMenuHint, SuppressText, SuppressHelp;
var localized string RemindersDisabledText;

function BuildPage(MCM_API_Instance API, int GameMode)
{
    local MCM_API_SettingsPage Page;
    local MCM_API_SettingsGroup Group;

    Page = API.NewSettingsPage(ModName);
    Page.SetPageTitle(PageTitle);
    Group = Page.AddGroup('Connection', ConnectionGroup);
    CompanionLabel = Group.AddLabel('Companion', CompanionChecking, CompanionHelp);
    ServiceLabel = Group.AddLabel('JourneyConnection', ServiceChecking, ServiceHelp);
    JourneyLabel = Group.AddLabel('Journey', JourneyUnavailable, JourneyHelp);
    JourneyCommanderLabel = Group.AddLabel('JourneyCommander', JourneyUnavailable, "Commander and last-observed Journey state. Test connection fetches fresh service metadata; Refresh reads the companion cache.");
    JourneyIdentityLabel = Group.AddLabel('JourneyIdentity', JourneyUnavailable, "The title is a display label; Journey IDs remain the binding keys. View full names and saved commander bonuses under Avenger > Command > The Name Beneath.");
    StoredIndicator = Group.AddCheckbox('CredentialStored', CredentialChecking, CredentialHelp, false);
    StoredIndicator.SetEditable(false);
    RefreshButton = Group.AddButton('Refresh', RefreshTitle, RefreshHelp, RefreshText, RefreshClicked);
    TestButton = Group.AddButton('Test', TestTitle, TestHelp, TestText, TestClicked);
    bCampaignMode = GameMode == eGameMode_Strategy && class'UITNBCampaignJourney'.static.CanOpen(ParentScreen);
    Group = Page.AddGroup('Campaign', CampaignGroup);
    CampaignLabel = Group.AddLabel('CampaignState', CampaignUnavailable, CampaignHelp);
    Group.AddLabel('CampaignNavigation', CommandMenuHint, CampaignHelp);
    Group.AddLabel('AutomaticReminders', class'TNB_AvengerJourneyPrompt'.default.bEnableAutomaticInvitations ? "Automatic invitation: enabled on the idle Avenger" : RemindersDisabledText, CampaignHelp);
    if (bCampaignMode) ReminderCampaignID = class'TNB_CampaignService'.static.CampaignID();
    Group.AddCheckbox('SuppressReminder', SuppressText, SuppressHelp, bCampaignMode && class'XComGameState_TNBPromptPreference'.static.IsSuppressed(), ReminderSaved).SetEditable(bCampaignMode);
    Group = Page.AddGroup('LinkingBonuses', "Linking bonuses");
    if (class'X2ExperienceConfig'.default.bUseFullXpSystem)
        Group.AddLabel('DejaVuUnsupported', "Deja Vu inactive: this overhaul uses the full-XP system", "The local bonus supports WOTC kill-credit progression, not a replacement full-XP economy.");
    Group.AddSlider('DejaVuPercent', "Deja Vu bonus promotion XP (%)", "Default 5%. Set to 0% to disable future bonus XP for all holders. Changes affect future earnings only; links, the passive and previously earned credit are retained. No Ability Points or online XP.", 0, 100, 1, Clamp(class'TNB_DejaVuConfig'.default.BonusPercent, 0, 100), DejaVuPercentSaved);
    Group = Page.AddGroup('Reporting', "Gameplay reporting");
    ReportingLabel = Group.AddLabel('ReportingState', "Reading saved capture state...", "Captured in this save, durably queued in the companion, and accepted online are separate stages. Remote history and handed-off reports do not rewind with a save. No client-authored XP is reported.");
    ReportingQueueLabel = Group.AddLabel('ReportingQueue', "Companion queue: not checked", "Queue counts are scoped to the loaded campaign/Journey, not another campaign's reports.");
    ReportingAcceptedLabel = Group.AddLabel('ReportingAccepted', "Online acceptance: not checked", "Only validated API receipts count as accepted. A receipt does not contain an XP award amount.");
    ReportingClockLabel = Group.AddLabel('ReportingClock', "Capture clock: not initialized", "The companion verifies the local timezone. Native history transitions wait for a verified committed-frame clock sample.");
    ReportingDiagnosticLabel = Group.AddLabel('ReportingDiagnostic', "Reporting diagnostics: none", "Keep held/corrupt/conflicting records for diagnosis. Do not delete journals or mint replacement event IDs.");
    ReportingRefresh = Group.AddButton('ReportingRefresh', "Refresh reporting", "Read status for this loaded campaign and Journey.", "Refresh", ReportingRefreshClicked);
    ReportingRetry = Group.AddButton('ReportingRetry', "Retry eligible reports", "Retry network/credential/lifecycle-paused records after you resolve the cause. Conflicts and invalid reports remain held; this never starts/reopens a Journey.", "Retry eligible", ReportingRetryClicked);
    UpdateCampaignStatus();
    Page.ShowSettings();
    StartRequest("status");
    StartReporting("events_status");
}

function ReportingRefreshClicked(MCM_API_Setting Setting) { StartReporting("events_status"); }
function DejaVuPercentSaved(MCM_API_Setting Setting, float Percent)
{
    class'TNB_DejaVuConfig'.default.BonusPercent = Clamp(Round(Percent), 0, 100);
    class'TNB_DejaVuConfig'.static.StaticSaveConfig();
}
function ReportingRetryClicked(MCM_API_Setting Setting) { StartReporting("events_retry"); }

private function StartReporting(string Operation)
{
    local XComGameState_TNBCampaignLink Campaign;
    local XComGameState_TNBEventOutbox Outbox;
    local XComGameState_TNBEventLedger Ledger;
    local JsonObject Args;
    local string Text;
    if (ReportingRequest != none || ParentScreen == none) return;
    Campaign = class'XComGameState_TNBCampaignLink'.static.Get();
    if (Campaign == none)
    {
        ReportingLabel.SetLabel("Associate this campaign with a Journey to enable future gameplay reporting.");
        ReportingQueueLabel.SetLabel("Companion queue: no loaded campaign association");
        ReportingAcceptedLabel.SetLabel("Online acceptance: no loaded campaign association");
        ReportingClockLabel.SetLabel("Capture clock: not initialized");
        ReportingRetry.SetEditable(false); return;
    }
    Outbox = class'XComGameState_TNBEventOutbox'.static.Get();
    Ledger = class'XComGameState_TNBEventLedger'.static.Get();
    Text = "Captured in this save, not handed off: " $ (Outbox == none ? 0 : Outbox.Reports.Length);
    ReportingLabel.SetLabel(class'TNB_Types'.static.EscapeUI(Text));
    ReportingQueueLabel.SetLabel("Companion queue: checking...");
    if (Ledger != none) ReportingClockLabel.SetLabel("Capture clock zone: " $ (Ledger.ClockZone == "" ? "waiting for companion handshake" : Ledger.ClockZone));
    ReportingRefresh.SetEditable(false); ReportingRetry.SetEditable(false);
    Args = new class'JsonObject';
    Args.SetStringValue("expected_journey_id", Campaign.Journey.JourneyID);
    Args.SetStringValue("campaign_id", Campaign.CampaignID);
    ReportingRequest = ParentScreen.Spawn(class'TNB_LoopbackClient');
    if (ReportingRequest != none) ReportingRequest.BeginRequest(Operation, ReportingComplete, Args);
    else ReportingComplete(none, "companion_not_running");
}

function ReportingComplete(JsonObject Result, string ErrorCode)
{
    local XComGameState_TNBEventOutbox Outbox;
    local XComGameState_TNBEventLedger Ledger;
    local TNB_EventPump Pump;
    local string Text;
    ReportingRequest = none;
    if (ParentScreen == none) return;
    ReportingRefresh.SetEditable(true); ReportingRetry.SetEditable(true);
    Outbox = class'XComGameState_TNBEventOutbox'.static.Get();
    Text = "Captured in this save, not handed off: " $ (Outbox == none ? 0 : Outbox.Reports.Length);
    ReportingLabel.SetLabel(class'TNB_Types'.static.EscapeUI(Text));
    Text = "";
    if (ErrorCode != "" || Result == none)
    {
        ReportingQueueLabel.SetLabel("Companion queue unavailable: " $ ErrorCode);
        ReportingAcceptedLabel.SetLabel("Online acceptance: unavailable (not evidence of rejection)");
        Text = ErrorCode;
    }
    else
    {
        ReportingQueueLabel.SetLabel("Companion: " $ Result.GetIntValue("queued") $ " queued, " $ Result.GetIntValue("retrying") $ " retrying, " $ Result.GetIntValue("paused") $ " paused, " $ Result.GetIntValue("held") $ " held");
        ReportingAcceptedLabel.SetLabel("Accepted online: " $ Result.GetIntValue("accepted") $ "; last: " $ (Result.GetStringValue("last_accepted_at") == "" ? "none" : Result.GetStringValue("last_accepted_at")));
        Text = Result.GetStringValue("last_error");
        if (Result.GetIntValue("endpoint_damaged_files") > 0 || Result.GetIntValue("endpoint_replay_conflicts") > 0)
            Text $= " / Endpoint-wide: " $ Result.GetIntValue("endpoint_damaged_files") $ " damaged files; " $ Result.GetIntValue("endpoint_replay_conflicts") $ " replay conflicts";
    }
    if (Outbox != none && Outbox.Diagnostic != "") Text = Outbox.Diagnostic $ " / " $ Text;
    Ledger = class'XComGameState_TNBEventLedger'.static.Get();
    if (Ledger != none)
    {
        ReportingClockLabel.SetLabel("Clock zone: " $ (Ledger.ClockZone == "" ? "waiting for companion handshake" : Ledger.ClockZone) $ "; native transitions: " $ (Ledger.bFrameClockVerified ? "verified" : "waiting"));
        if (Ledger.Diagnostic != "") Text = Ledger.Diagnostic $ " / " $ Text;
        if (Ledger.HistoryDiagnostic != "") Text = Ledger.HistoryDiagnostic $ " / " $ Text;
    }
    Pump = class'TNB_EventPump'.static.Find();
    if (Text == "" && Pump != none) Text = Pump.StatusText;
    ReportingDiagnosticLabel.SetLabel("Reporting status: " $ class'TNB_Types'.static.EscapeUI(Text == "" ? "no errors reported" : Text));
}

function RefreshClicked(MCM_API_Setting Setting) { StartRequest("status"); }
function TestClicked(MCM_API_Setting Setting) { StartRequest("test"); }

// Runs only for an explicit MCM Save, never from the invitation/readiness path.
function ReminderSaved(MCM_API_Setting Setting, bool Suppress)
{
    if (!bCampaignMode || ParentScreen == none || ParentScreen.bIsRemoved || ReminderCampaignID == "") return;
    if (class'TNB_ReportingSafety'.static.BlockReason(class'WorldInfo'.static.GetWorldInfo(), `XCOMHISTORY) != "") return;
    if (ReminderCampaignID == class'TNB_CampaignService'.static.CampaignID()) class'XComGameState_TNBPromptPreference'.static.SetSuppressed(Suppress);
}

private function UpdateCampaignStatus()
{
    local XComGameState_TNBCampaignLink Link;
    if (!bCampaignMode) { CampaignLabel.SetLabel(CampaignUnavailable); return; }
    Link = class'XComGameState_TNBCampaignLink'.static.Get();
    if (Link == none)
    {
        CampaignLabel.SetLabel(CampaignDisconnected);
    }
    else
    {
        CampaignLabel.SetLabel("Campaign Journey: " $ class'TNB_Types'.static.EscapeUI(class'TNB_Types'.static.Compact(class'TNB_Types'.static.DisplayTitle(class'XComGameState_TNBJourneyLabel'.static.Title(Link)), 64)));
    }
    // Read-only status, refreshed on page rebuild/Refresh/Test.
}

private function StartRequest(string Operation)
{
    if (Request != none || ParentScreen == none) return;
    UpdateCampaignStatus();
    SetBusy(true);
    CompanionLabel.SetLabel(CompanionChecking);
    ServiceLabel.SetLabel(ServiceChecking);
    StoredIndicator.SetLabel(CredentialChecking);
    Request = ParentScreen.Spawn(class'TNB_LoopbackClient');
    if (Request == none)
    {
        Complete(none, "companion_client_unavailable");
        return;
    }
    Request.BeginRequest(Operation, Complete);
}

private function SetBusy(bool bBusy)
{
    RefreshButton.SetEditable(!bBusy);
    TestButton.SetEditable(!bBusy);
}

function Complete(JsonObject Result, string ErrorCode)
{
    Request = none;
    if (ParentScreen == none) return;
    SetBusy(false);
    if (Result == none)
    {
        // No companion response cannot establish vault or API state. Do not claim deletion.
        if (ErrorCode == "companion_timeout") CompanionLabel.SetLabel(CompanionTimeout);
        else if (ErrorCode == "companion_protocol_mismatch") CompanionLabel.SetLabel(CompanionIncompatible);
        else CompanionLabel.SetLabel(CompanionUnavailable);
        ServiceLabel.SetLabel(ServiceUnknown);
        JourneyLabel.SetLabel(JourneyUnavailable);
        JourneyCommanderLabel.SetLabel(JourneyUnavailable);
        JourneyIdentityLabel.SetLabel("Journey ID: unavailable");
        StoredIndicator.SetLabel(CredentialUnavailable);
        return;
    }

    // A valid error response still proves that the companion is reachable.
    CompanionLabel.SetLabel(CompanionConnected);
    StoredIndicator.SetLabel(CredentialStored);
    StoredIndicator.SetValue(Result.GetBoolValue("credential_stored"), true);
    if (ErrorCode != "" && Result.GetStringValue("connection") == "connected")
        ServiceLabel.SetLabel(ServiceUnableToVerify);
    else ServiceLabel.SetLabel(ServiceStateText(Result.GetStringValue("connection")));
    if (Result.GetStringValue("journey_id") == "") JourneyLabel.SetLabel(JourneyUnavailable);
    else JourneyLabel.SetLabel("Journey (last observed): " $ class'TNB_Types'.static.EscapeUI(class'TNB_Types'.static.Compact(class'TNB_Types'.static.DisplayTitle(Result.GetStringValue("journey_title")), 64)));
    JourneyCommanderLabel.SetLabel(CommanderPrefix $ class'TNB_Types'.static.EscapeUI(class'TNB_Types'.static.Compact(Result.GetStringValue("commander_name"), 48)) $ " / " $ JourneyStateText(Result.GetStringValue("journey_status")));
    JourneyIdentityLabel.SetLabel("Journey ID: " $ class'TNB_Types'.static.EscapeUI(Result.GetStringValue("journey_id")));
    if (bCampaignMode) class'XComGameState_TNBJourneyLabel'.static.Observe(Result);
    UpdateCampaignStatus();
}

private function string ServiceStateText(string State)
{
    switch (State)
    {
        case "connected": return ServiceVerified;
        case "unverified": return ServiceUnverified;
        case "not_configured": return ServiceNotConfigured;
        case "invalid_credential": return ServiceInvalidCredential;
        case "scope_missing": return ServiceScopeMissing;
        case "unable_to_verify": return ServiceUnableToVerify;
        default: return ServiceUnknown;
    }
}

private function string JourneyStateText(string State)
{
    switch (State)
    {
        case "upcoming": return JourneyUpcoming;
        case "started": return JourneyStarted;
        case "finished": return JourneyFinished;
        default: return JourneyUnknown;
    }
}

function Cleanup()
{
    ParentScreen = none;
    if (Request != none) Request.CancelRequest();
    Request = none;
    if (ReportingRequest != none) ReportingRequest.CancelRequest();
    ReportingRequest = none;
}
