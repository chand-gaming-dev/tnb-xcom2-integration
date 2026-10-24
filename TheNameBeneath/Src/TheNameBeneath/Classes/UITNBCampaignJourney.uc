// Campaign-only setup/status. Never reads a soldier, fetches a roster, or activates a character.
class UITNBCampaignJourney extends UISimpleCommodityScreen dependson(TNB_Types, UIDialogueBox);

var TNB_LoopbackClient Request;
var UIScreen OriginScreen;
var TNB_Types.JourneyContext Journey;
var array<name> Actions;
var array<TNB_Types.ResolvedEffect> Preview;
var string OpenedCampaignID;
var string PreviewCharacteristics;
var bool bBusy, bAwaitingConfirmation;
var localized string LoadingText, ConnectText, DetailsText, RetryText, ConfirmationTitle, ConfirmationWarning, ConnectedText, SavedText, NotStartedText, FailedText;
var localized string StartConnectText, StartConfirmText, StartWarning, StartUnavailableText, FinishedText, ChangedCharacteristicsText;

static function bool CanOpen(UIScreen Parent)
{
    return Parent != none && !Parent.bIsRemoved && `HQPRES != none && `HQGAME != none && class'TNB_CampaignService'.static.CampaignID() != "";
}

static function Open(UIScreen Parent)
{
    local UITNBCampaignJourney Setup;
    if (!CanOpen(Parent) || Parent.Movie.Stack.IsInStack(class'UITNBCampaignJourney')) return;
    if (class'XComGameState_TNBCampaignLink'.static.Get() != none) { class'UITNBCommanderProfile'.static.Open(Parent); return; }
    Setup = Parent.Spawn(class'UITNBCampaignJourney'); Setup.OriginScreen = Parent;
    Parent.Movie.Stack.Push(Setup);
}

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
    super.InitScreen(InitController, InitMovie, InitName);
    OpenedCampaignID = class'TNB_CampaignService'.static.CampaignID();
    if (!StillOpen()) { CloseScreen(); return; }
    // Saved campaign status/effects must remain readable while the companion is offline.
    if (class'XComGameState_TNBCampaignLink'.static.Get() != none) ShowSaved();
    else CheckJourney();
}

simulated function GetItems() {}

private function bool StillOpen()
{
    return !bIsRemoved && `HQPRES != none && `HQGAME != none && OpenedCampaignID != "" && OpenedCampaignID == class'TNB_CampaignService'.static.CampaignID();
}

private function CheckJourney()
{
    if (!StillOpen() || Request != none) return;
    if (class'XComGameState_TNBCampaignLink'.static.Get() != none) { ShowSaved(); return; }
    bBusy = true; ClearRows(); AddRow('None', LoadingText, ""); PopulateData();
    Request = Spawn(class'TNB_LoopbackClient');
    if (Request == none) { Fail("companion_client_unavailable"); return; }
    Request.BeginRequest("journey_context", ContextComplete);
}

function ContextComplete(JsonObject Data, string ErrorCode)
{
    local TNB_Types.ResolvedEffect Effect;
    Request = none;
    if (!StillOpen()) return;
    if (class'XComGameState_TNBCampaignLink'.static.Get() != none) { ShowSaved(); return; }
    if (ErrorCode != "") { Fail(ErrorCode); return; }
    if (!class'TNB_Types'.static.ReadJourney(Data, Journey)) { Fail("journey_response_invalid"); return; }
    if (Journey.JourneyStatus == "finished") { Fail(FinishedText); return; }
    if (Journey.JourneyStatus != "started" && Journey.JourneyStatus != "upcoming") { Fail(NotStartedText); return; }
    if (Journey.JourneyStatus == "upcoming" && (!Journey.bCanManageJourney || Journey.JourneyVersion < 1)) { Fail(StartUnavailableText); return; }
    if (!Journey.bCharacteristicsAvailable) { Fail("commander_characteristics_unavailable"); return; }
    if (!class'TNB_PolicyTests'.static.Run()) { Fail("mapping_policy_self_test_failed"); return; }
    Preview = class'TNB_MappingResolver'.static.Resolve('Commander', Journey.Traits, Journey.Skills);
    PreviewCharacteristics = CharacteristicsKey(Data);
    if (Preview.Length > 512) { Fail("too_many_mapping_rows_or_effects"); return; }
    bBusy = false; ClearRows(); SetJourneyHeader(Journey);
    AddRow('Connect', (Journey.JourneyStatus == "upcoming") ? StartConnectText : ConnectText, ConfirmationWarning $ ((Journey.JourneyStatus == "upcoming") ? "\n\n" $ StartWarning : ""));
    AddRow('Details', "Journey & Commander", "Journey: " $ class'TNB_Types'.static.EscapeUI(class'TNB_Types'.static.DisplayTitle(Journey.JourneyTitle)) $ "\nCommander: " $ class'TNB_Types'.static.EscapeUI(Journey.CommanderName) $ "\nGame: " $ class'TNB_Types'.static.EscapeUI(Journey.GameName) $ "\nJourney ID: " $ class'TNB_Types'.static.EscapeUI(Journey.JourneyID));
    foreach Preview(Effect) AddEffectRow(Effect, false);
    PopulateData();
}

private function SetJourneyHeader(TNB_Types.JourneyContext Context)
{
    TitleHeader.SetText(m_strTitle, class'TNB_Types'.static.EscapeUI(class'TNB_Types'.static.Compact(class'TNB_Types'.static.DisplayTitle(Context.JourneyTitle), 64)));
}

private function ShowSaved()
{
    local XComGameState_TNBCampaignLink Link;
    local TNB_Types.ResolvedEffect Effect;
    local UIScreen ReturnScreen;
    Link = class'XComGameState_TNBCampaignLink'.static.Get();
    if (Link == none || Link.SchemaVersion != 1 || Link.CampaignID != OpenedCampaignID || !Link.bOneTimeEffectsCommitted) { Fail("saved_campaign_link_invalid_no_rewards_reapplied"); return; }
    if (OriginScreen != none && !OriginScreen.bIsRemoved)
    {
        ReturnScreen = OriginScreen;
        CloseScreen();
        class'UITNBCommanderProfile'.static.Open(ReturnScreen);
        return;
    }
    Journey = Link.Journey;
    Journey.JourneyTitle = class'XComGameState_TNBJourneyLabel'.static.Title(Link);
    bBusy = false; ClearRows(); SetJourneyHeader(Journey);
    AddRow('Details', ConnectedText, "Journey: " $ class'TNB_Types'.static.EscapeUI(class'TNB_Types'.static.DisplayTitle(Journey.JourneyTitle)) $ "\nCommander: " $ class'TNB_Types'.static.EscapeUI(Link.Journey.CommanderName) $ "\nGame: " $ class'TNB_Types'.static.EscapeUI(Link.Journey.GameName) $ "\nJourney ID: " $ class'TNB_Types'.static.EscapeUI(Link.Journey.JourneyID) $ "\nTitle last observed (UTC): " $ class'TNB_Types'.static.EscapeUI(class'XComGameState_TNBJourneyLabel'.static.SeenAt(Link)) $ "\n\n" $ SavedText $ "\nMapping revision: " $ class'TNB_Types'.static.EscapeUI(Link.MappingRevision));
    AddRow('RefreshTitle', "Refresh Journey name", "Read the latest Journey title from the service. Updates cosmetic metadata only, never saved bonuses, soldier links or reporting identity. The saved name remains readable offline.");
    foreach Link.Effects(Effect) AddEffectRow(Effect, true);
    PopulateData();
}

private function ClearRows() { Actions.Length = 0; arrItems.Length = 0; }

private function AddRow(name Action, string Caption, string Description)
{
    local Commodity Item;
    Item.Title = Caption; Item.Desc = Description; Item.Image = class'UIUtilities_Image'.const.AlertIcon_Engineering;
    Actions.AddItem(Action); arrItems.AddItem(Item);
}

private function AddEffectRow(TNB_Types.ResolvedEffect Effect, bool Committed)
{
    local string Description;
    Description = string(Effect.SourceKind) $ ": " $ class'TNB_Types'.static.EscapeUI(Effect.SourceName) $ "\n" $ class'TNB_Types'.static.EscapeUI(class'TNB_EffectPresentation'.static.Summary(Effect));
    Description $= "\nStatus: " $ class'TNB_EffectPresentation'.static.StatusText(Effect.Status, Committed);
    Description $= "\n" $ class'TNB_EffectPresentation'.static.TimingText(Effect.EffectKind, Committed);
    if (Effect.Note != "") Description $= "\n" $ class'TNB_Types'.static.EscapeUI(Effect.Note);
    Description $= "\nDefinition: " $ class'TNB_Types'.static.EscapeUI(Effect.SourceID) $ " v" $ Effect.SourceVersion $ "\nMapping: " $ string(Effect.MappingKey);
    if (Committed && (Effect.EffectKind == 'ResourceOnce' || Effect.EffectKind == 'AvatarOnce' || Effect.EffectKind == 'StaffOnce')) Description $= "\nActual applied delta: " $ ((Effect.AppliedMagnitude > 0) ? "+" : "") $ Effect.AppliedMagnitude;
    AddRow('Details', class'TNB_Types'.static.EscapeUI(Effect.SourceName) $ ": " $ class'TNB_Types'.static.EscapeUI(class'TNB_EffectPresentation'.static.Summary(Effect)) $ " [" $ class'TNB_EffectPresentation'.static.StatusBadge(Effect.Status, Committed) $ "]", Description);
    arrItems[arrItems.Length - 1].Image = class'TNB_EffectPresentation'.static.SafeImage(class'TNB_EffectPresentation'.static.EffectImage(Effect));
}

simulated function bool MeetsItemReqs(int Index) { return !bBusy && Index >= 0 && Index < Actions.Length && Actions[Index] != 'None'; }
simulated function bool CanAffordItem(int Index) { return MeetsItemReqs(Index); }
simulated function string GetButtonString(int Index)
{
    if (Index >= 0 && Index < Actions.Length)
    {
        if (Actions[Index] == 'Retry') return RetryText;
        if (Actions[Index] == 'Details') return DetailsText;
        if (Actions[Index] == 'RefreshTitle') return "Refresh name";
    }
    return (Journey.JourneyStatus == "upcoming") ? StartConfirmText : ConnectText;
}

simulated function OnPurchaseClicked(UIList ContainerList, int Index)
{
    local TDialogueBoxData Dialog;
    if (!StillOpen() || bAwaitingConfirmation || !CanAffordItem(Index)) return;
    if (Actions[Index] == 'Retry') { CheckJourney(); return; }
    if (Actions[Index] == 'RefreshTitle') { RefreshTitle(); return; }
    Dialog.strTitle = arrItems[Index].Title; Dialog.strText = arrItems[Index].Desc;
    Dialog.eType = eDialog_Normal; Dialog.strAccept = class'UIUtilities_Text'.default.m_strGenericOK;
    if (Actions[Index] == 'Connect')
    {
        // Another UI must never turn a stale preview into a second reward transaction.
        if (class'XComGameState_TNBCampaignLink'.static.Get() != none) { ShowSaved(); return; }
        Dialog.strTitle = ConfirmationTitle;
        Dialog.strText = "Journey: " $ class'TNB_Types'.static.EscapeUI(class'TNB_Types'.static.DisplayTitle(Journey.JourneyTitle)) $ "\nCommander: " $ class'TNB_Types'.static.EscapeUI(Journey.CommanderName) $ "\nGame: " $ class'TNB_Types'.static.EscapeUI(Journey.GameName) $ "\nJourney ID: " $ class'TNB_Types'.static.EscapeUI(Journey.JourneyID) $ "\n\n" $ ConfirmationWarning $ ((Journey.JourneyStatus == "upcoming") ? "\n\n" $ StartWarning : "");
        Dialog.eType = eDialog_Alert; Dialog.strAccept = (Journey.JourneyStatus == "upcoming") ? StartConfirmText : ConnectText;
        Dialog.strCancel = class'UIUtilities_Text'.default.m_strGenericCancel;
        Dialog.fnCallback = Confirmed; bAwaitingConfirmation = true;
    }
    Movie.Pres.UIRaiseDialog(Dialog);
}

private function RefreshTitle()
{
    local JsonObject Args;
    if (!StillOpen() || Request != none) return;
    Args = new class'JsonObject'; Args.SetStringValue("expected_journey_id", Journey.JourneyID);
    Request = Spawn(class'TNB_LoopbackClient');
    if (Request == none) return;
    bBusy = true;
    Request.BeginRequest("journey_context", TitleComplete, Args);
}

function TitleComplete(JsonObject Data, string ErrorCode)
{
    local TNB_Types.JourneyContext Updated;
    local UIDialogueBox.TDialogueBoxData Dialog;
    Request = none;
    if (!StillOpen()) return;
    if (ErrorCode == "" && class'TNB_Types'.static.ReadJourney(Data, Updated) && Updated.JourneyID == Journey.JourneyID && Updated.CommanderID == Journey.CommanderID)
        class'XComGameState_TNBJourneyLabel'.static.Observe(Data);
    else
    {
        Dialog.eType = eDialog_Normal; Dialog.strTitle = "Journey name not refreshed";
        Dialog.strText = "The saved title and bonuses have not changed. Check the companion and try again.\n" $ class'TNB_Types'.static.EscapeUI(ErrorCode);
        Dialog.strAccept = class'UIUtilities_Text'.default.m_strGenericOK;
        Movie.Pres.UIRaiseDialog(Dialog);
    }
    ShowSaved();
}

function Confirmed(name Action)
{
    local JsonObject Args;
    bAwaitingConfirmation = false;
    if (Action != 'eUIAction_Accept' || !StillOpen()) return;
    if (class'XComGameState_TNBCampaignLink'.static.Get() != none) { ShowSaved(); return; }
    if (Journey.JourneyStatus == "upcoming")
    {
        if (!Journey.bCanManageJourney || Journey.JourneyVersion < 1 || Request != none) { Fail(StartUnavailableText); return; }
        Args = new class'JsonObject'; Args.SetStringValue("expected_journey_id", Journey.JourneyID);
        Args.SetIntValue("expected_version", Journey.JourneyVersion); Args.SetBoolValue("confirmed", true);
        bBusy = true; ClearRows(); AddRow('None', LoadingText, ""); PopulateData();
        Request = Spawn(class'TNB_LoopbackClient');
        if (Request == none) { Fail("companion_client_unavailable"); return; }
        Request.BeginRequest("journey_start", StartComplete, Args);
        return;
    }
    CommitAssociation();
}

private function string CharacteristicsKey(JsonObject Data)
{
    // Compare the bounded projected characteristics, not changing observed-at timestamps.
    return class'JsonObject'.static.EncodeJson(Data.GetObject("traits")) $ class'JsonObject'.static.EncodeJson(Data.GetObject("skills"));
}

function StartComplete(JsonObject Data, string ErrorCode)
{
    local TNB_Types.JourneyContext Started;
    Request = none;
    if (!StillOpen()) return;
    if (ErrorCode != "") { Fail(ErrorCode); return; }
    if (!class'TNB_Types'.static.ReadJourney(Data, Started) || Started.JourneyID != Journey.JourneyID || Started.CommanderID != Journey.CommanderID || Started.JourneyStatus != "started" || !Started.bCharacteristicsAvailable) { Fail("started_journey_response_invalid"); return; }
    if (CharacteristicsKey(Data) != PreviewCharacteristics)
    {
        // Remote Start cannot be rolled back, but changed bonuses need a fresh review.
        ContextComplete(Data, "");
        arrItems[0].Desc = ChangedCharacteristicsText $ "\n\n" $ arrItems[0].Desc;
        PopulateData();
        return;
    }
    Journey = Started;
    CommitAssociation();
}

private function CommitAssociation()
{
    local string ErrorCode;
    local string Recipients;
    local TDialogueBoxData Dialog;
    if (!StillOpen()) return;
    if (!class'TNB_CampaignService'.static.Associate(Journey, ErrorCode)) { Fail(ErrorCode); return; }
    Recipients = class'TNB_StrategyMappingService'.static.IntelligenceReceiptText(class'XComGameState_TNBCampaignLink'.static.Get());
    ShowSaved();
    if (Recipients != "" && `HQPRES != none)
    {
        Dialog.eType = eDialog_Normal; Dialog.strTitle = "Quick Learner - Combat Intelligence improved";
        Dialog.strText = Recipients;
        Dialog.strAccept = class'UIUtilities_Text'.default.m_strGenericOK;
        `HQPRES.UIRaiseDialog(Dialog);
    }
}

private function Fail(string ErrorCode)
{
    bBusy = false; bAwaitingConfirmation = false; ClearRows();
    AddRow('Retry', RetryText, FailedText $ class'TNB_Types'.static.EscapeUI(Repl(ErrorCode, "_", " ")) $ "\nA remote Journey start may already have succeeded. Retry reads its state again; it does not undo a start or repeat committed commander rewards.");
    PopulateData();
}

simulated function OnRemoved()
{
    if (Request != none) Request.CancelRequest();
    Request = none;
    OriginScreen = none;
    super.OnRemoved();
}

defaultproperties
{
    InputState=eInputState_Consume
    bHideOnLoseFocus=false
    bConsumeMouseEvents=true
    bUseSimpleCard=true
}
