// Transient strategy-world session state, not serialized into campaign saves.
// A HUD rebuild in the same world does not repeat an offered reminder.
class TNB_AvengerJourneyPrompt extends Actor dependson(UIDialogueBox);

var UIAvengerHUD HUD;
var TNB_LoopbackClient Request;
var bool bOffered, bReady;
var float NextCheck;
var string CampaignID;
var localized string PromptTitle, PromptText, ConnectNowText, NotNowText;

function AttachHUD(UIAvengerHUD Screen)
{
    HUD = Screen;
    if (CampaignID != class'TNB_CampaignService'.static.CampaignID())
    {
        if (Request != none) Request.CancelRequest();
        Request = none;
        CampaignID = class'TNB_CampaignService'.static.CampaignID();
        bOffered = class'X2DLCInfo_TheNameBeneath'.static.ReminderOffered(CampaignID); bReady = false;
    }
    NextCheck = WorldInfo.TimeSeconds + 5.0;
}

function ResetSession()
{
    if (Request != none) Request.CancelRequest();
    Request = none;
    CampaignID = class'TNB_CampaignService'.static.CampaignID();
    bOffered = false; bReady = false;
    NextCheck = WorldInfo.TimeSeconds + 5.0;
}

private function bool QuietAvenger()
{
    if (HUD == none || HUD.bIsRemoved || `HQPRES == none || `HQGAME == none || `HQPRES.IsBusy()) return false;
    if (class'UIUtilities_Strategy'.static.IsInTutorial(true)) return false;
    // The facility grid is the actual top-level Avenger screen; HUD sits beneath it.
    return UIFacilityGrid(HUD.Movie.Stack.GetCurrentScreen()) != none;
}

event Tick(float DeltaTime)
{
    local TDialogueBoxData Dialog;
    if (bOffered || HUD == none || HUD.bIsRemoved || CampaignID == "" || WorldInfo.TimeSeconds < NextCheck) return;
    // Do not traverse history/stack/DLC state every frame while waiting for a quiet screen.
    NextCheck = WorldInfo.TimeSeconds + 2.0;
    if (class'X2DLCInfo_TheNameBeneath'.static.ReminderOffered(CampaignID)) { bOffered = true; return; }
    if (CampaignID != class'TNB_CampaignService'.static.CampaignID()) return;
    if (class'XComGameState_TNBCampaignLink'.static.Get() != none || class'XComGameState_TNBPromptPreference'.static.IsSuppressed()) return;
    if (!QuietAvenger() || Request != none) return;
    NextCheck = WorldInfo.TimeSeconds + 60.0;
    if (!bReady)
    {
        // Cached local readiness only; online lifecycle/traits are verified on the review screen.
        Request = Spawn(class'TNB_LoopbackClient');
        if (Request != none) Request.BeginRequest("status", StatusComplete);
        return;
    }
    if (!class'TNB_CampaignService'.static.ShouldOfferReminder(false, false, bOffered, QuietAvenger(), bReady)) return;
    bOffered = true;
    class'X2DLCInfo_TheNameBeneath'.static.MarkReminderOffered(CampaignID);
    Dialog.eType = eDialog_Normal; Dialog.strTitle = PromptTitle; Dialog.strText = PromptText;
    Dialog.strAccept = ConnectNowText; Dialog.strCancel = NotNowText; Dialog.fnCallback = PromptAnswered;
    HUD.Movie.Pres.UIRaiseDialog(Dialog);
}

function StatusComplete(JsonObject Data, string ErrorCode)
{
    Request = none;
    bReady = ErrorCode == "" && Data != none;
    if (bReady) bReady = Data.GetBoolValue("credential_stored") && Data.GetStringValue("journey_id") != "";
    // Present only after the callback, on a quiet Tick, not over a newly opened screen.
    if (bReady) NextCheck = WorldInfo.TimeSeconds + 1.0;
}

function PromptAnswered(name Action)
{
    if (HUD == none || HUD.bIsRemoved || CampaignID != class'TNB_CampaignService'.static.CampaignID()) return;
    if (Action == 'eUIAction_Accept') { class'UITNBCampaignJourney'.static.Open(HUD); return; }
    // Cancel/Escape is Not now, never a permanent opt-out. The MCM checkbox
    // provides an explicit campaign-local Don't remind me choice without a second popup.
}

function DetachHUD(UIAvengerHUD Screen)
{
    if (HUD != Screen) return;
    HUD = none; bReady = false;
    if (Request != none) Request.CancelRequest();
    Request = none;
}

event Destroyed()
{
    if (Request != none) Request.CancelRequest();
    Request = none;
    super.Destroyed();
}

defaultproperties
{
    bAlwaysTick=true
}
