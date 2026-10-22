// Short-lived readiness work, owned by the currently focused facility grid.
// No Tick, history delegate, persistent listener reference to this actor, or state writes.
// The native dialog callback belongs to a stateless listener, NEVER to this world actor.
class TNB_AvengerJourneyPrompt extends Actor config(TheNameBeneath) dependson(UIDialogueBox);

var config bool bEnableAutomaticInvitations;
var private UIFacilityGrid Grid;
var private UIScreenListener_TNBAvenger Receiver;
var private TNB_LoopbackClient Request;
var private int Attempts, RequestGeneration;
var private string CampaignID;
var localized string PromptTitle, PromptText, ConnectNowText, NotNowText;

static function bool EpochMatches(int Expected, int Current)
{
    return Expected >= 0 && Current >= 0 && Expected == Current;
}

static function bool ReadyStatus(bool CredentialStored, string JourneyID, string JourneyStatus)
{
    return CredentialStored && JourneyID != "" && (JourneyStatus == "started" || JourneyStatus == "upcoming");
}

static function bool RetryQuiet(int AttemptCount)
{
    return AttemptCount >= 0 && AttemptCount < 20;
}

static function bool AnswerAllowed(name Action, string ExpectedCampaign, string CurrentCampaign, int ExpectedGeneration, int CurrentGeneration, bool Quiet, bool Associated)
{
    return Action == 'eUIAction_Accept' && ExpectedCampaign != "" && ExpectedCampaign == CurrentCampaign && EpochMatches(ExpectedGeneration, CurrentGeneration) && Quiet && !Associated;
}

static function bool LiveGrid(UIFacilityGrid Screen)
{
    local WorldInfo World;
    World = class'WorldInfo'.static.GetWorldInfo();
    return World != none && Screen != none && !Screen.bDeleteMe && !Screen.bIsRemoved && Screen.WorldInfo == World &&
        `HQPRES != none && `HQGAME != none && Screen.Movie != none && Screen.Movie == `HQPRES.Get2DMovie();
}

// Gate phase/world before any campaign, saved preference or tutorial history lookup.
static function bool QuietGrid(UIFacilityGrid Screen)
{
    if (!LiveGrid(Screen)) return false;
    if (class'TNB_ReportingSafety'.static.BlockReason(Screen.WorldInfo, `XCOMHISTORY) != "") return false;
    if (!Screen.bIsInited || !Screen.IsVisible() || Screen.Movie.Stack.GetCurrentScreen() != Screen || `HQPRES.IsBusy() || `HQPRES.UIIsShowingDialog()) return false;
    return !class'UIUtilities_Strategy'.static.IsInTutorial(true);
}

static function Schedule(UIFacilityGrid Screen, UIScreenListener_TNBAvenger Listener)
{
    local TNB_AvengerJourneyPrompt Worker;
    if (!default.bEnableAutomaticInvitations || !LiveGrid(Screen) || Listener == none) return;
    foreach Screen.WorldInfo.AllActors(class'TNB_AvengerJourneyPrompt', Worker)
        if (Worker.Grid == Screen && !Worker.bDeleteMe) return;
    Worker = Screen.Spawn(class'TNB_AvengerJourneyPrompt', Screen);
    if (Worker == none) return;
    Worker.Grid = Screen; Worker.Receiver = Listener;
    Worker.SetTimer(0.5, false, 'CheckReady');
    `log("TNB_PROMPT scheduled",, 'TheNameBeneath');
}

static function CancelFor(UIScreen Screen)
{
    local TNB_AvengerJourneyPrompt Worker;
    if (Screen == none || Screen.WorldInfo == none) return;
    foreach Screen.WorldInfo.AllActors(class'TNB_AvengerJourneyPrompt', Worker)
        if (Worker.Grid == Screen || Worker.Owner == Screen) Worker.Cancel('screen_left');
}

function CheckReady()
{
    local string CurrentCampaign;
    if (!default.bEnableAutomaticInvitations || !LiveGrid(Grid) || Receiver == none) { Cancel('context_gone'); return; }
    if (Grid.Movie.Stack.GetCurrentScreen() != Grid) { Cancel('not_top_screen'); return; }
    if (!QuietGrid(Grid))
    {
        Attempts++;
        if (RetryQuiet(Attempts)) SetTimer(0.5, false, 'CheckReady');
        else Cancel('quiet_wait_expired');
        return;
    }
    CurrentCampaign = class'TNB_CampaignService'.static.CampaignID();
    if (CurrentCampaign == "" || class'XComGameState_TNBCampaignLink'.static.Get() != none ||
        class'XComGameState_TNBPromptPreference'.static.IsSuppressed() || class'X2DLCInfo_TheNameBeneath'.static.ReminderOffered(CurrentCampaign))
    { Cancel('not_eligible'); return; }
    CampaignID = CurrentCampaign;
    RequestGeneration = class'X2DLCInfo_TheNameBeneath'.static.ReminderGeneration();
    if (RequestGeneration < 0) { Cancel('session_unavailable'); return; }
    Request = Spawn(class'TNB_LoopbackClient', self);
    if (Request == none) { Cancel('client_unavailable'); return; }
    `log("TNB_PROMPT checking_local_status",, 'TheNameBeneath');
    // Local cached readiness only. This never starts a Journey, activates a soldier,
    // submits a game state or applies bonuses. Review fetches fresh context later.
    Request.BeginRequest("status", StatusComplete);
}

function StatusComplete(JsonObject Data, string ErrorCode)
{
    Request = none;
    if (!EpochMatches(RequestGeneration, class'X2DLCInfo_TheNameBeneath'.static.ReminderGeneration())) { Cancel('stale_reply'); return; }
    if (ErrorCode != "" || Data == none) { Cancel('companion_unavailable'); return; }
    if (!ReadyStatus(Data.GetBoolValue("credential_stored"), Data.GetStringValue("journey_id"), Data.GetStringValue("journey_status"))) { Cancel('journey_not_ready'); return; }
    // Do not raise a screen inside a network callback. Revalidate on a short,
    // one-shot UI handoff; loss of focus/removal cancels this timer as well.
    SetTimer(0.1, false, 'Offer');
}

function Offer()
{
    local TDialogueBoxData Dialog;
    local TNB_AvengerPromptData CallbackData;
    local XComPresentationLayerBase Presentation;
    if (!default.bEnableAutomaticInvitations || !QuietGrid(Grid) || Receiver == none ||
        !EpochMatches(RequestGeneration, class'X2DLCInfo_TheNameBeneath'.static.ReminderGeneration())) { Cancel('offer_context_changed'); return; }
    if (CampaignID != class'TNB_CampaignService'.static.CampaignID() || class'XComGameState_TNBCampaignLink'.static.Get() != none ||
        class'XComGameState_TNBPromptPreference'.static.IsSuppressed() || class'X2DLCInfo_TheNameBeneath'.static.ReminderOffered(CampaignID))
    { Cancel('offer_no_longer_eligible'); return; }
    CallbackData = new class'TNB_AvengerPromptData';
    CallbackData.CampaignID = CampaignID; CallbackData.Generation = RequestGeneration;
    Dialog.eType = eDialog_Normal;
    Dialog.strTitle = PromptTitle != "" ? PromptTitle : "The Name Beneath - Connect a Journey?";
    Dialog.strText = PromptText != "" ? PromptText : "Connect this campaign to a Journey to review commander bonuses. Soldier linking is optional. Nothing is applied until you review and confirm.";
    Dialog.strAccept = ConnectNowText != "" ? ConnectNowText : "Review Journey";
    Dialog.strCancel = NotNowText != "" ? NotNowText : "Not now";
    Dialog.fnCallbackEx = Receiver.InvitationAnswered;
    Dialog.xUserData = CallbackData;
    Presentation = Grid.Movie.Pres;
    class'X2DLCInfo_TheNameBeneath'.static.MarkReminderOffered(CampaignID);
    // Release all screen-owning fields before raising the dialog. Focus loss
    // cannot leave DialogBox retaining this actor/old map via a delegate.
    ClearTimer('CheckReady'); ClearTimer('Offer');
    Grid = none; Receiver = none; SetOwner(none);
    `log("TNB_PROMPT offered_read_only",, 'TheNameBeneath');
    Presentation.UIRaiseDialog(Dialog);
    Destroy();
}

function Cancel(name Reason)
{
    if (bDeleteMe) return;
    `log("TNB_PROMPT stopped reason=" $ Reason,, 'TheNameBeneath');
    ClearTimer('CheckReady'); ClearTimer('Offer');
    if (Request != none) Request.CancelRequest();
    Request = none; Grid = none; Receiver = none; SetOwner(none);
    Destroy();
}

event Destroyed()
{
    ClearTimer('CheckReady'); ClearTimer('Offer');
    if (Request != none) Request.CancelRequest();
    Request = none; Grid = none; Receiver = none;
    super.Destroyed();
}

defaultproperties
{
    bAlwaysTick=false
}
