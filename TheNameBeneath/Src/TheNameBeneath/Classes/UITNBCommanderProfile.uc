// Saved campaign presentation only. No roster activation, reward resolution or grants.
class UITNBCommanderProfile extends UIScreen dependson(TNB_Types);

var string OpenedCampaignID;
var XComGameState_TNBCampaignLink Link;
var UIList EffectList;
var UIIcon DetailIcon;
var UIText DetailHeading, JourneyHeading, RefreshStatus;
var UITextContainer DetailText;
var UIButton RefreshButton;
var TNB_LoopbackClient Request;
var int SelectedEffect;

static function Open(UIScreen Parent)
{
    if (!class'UITNBCampaignJourney'.static.CanOpen(Parent) || Parent.Movie.Stack.IsInStack(class'UITNBCommanderProfile')) return;
    Parent.Movie.Stack.Push(Parent.Spawn(class'UITNBCommanderProfile'));
}

private function bool StillOpen()
{
    return !bIsRemoved && Link != none && `HQGAME != none && `HQPRES != none && OpenedCampaignID == class'TNB_CampaignService'.static.CampaignID();
}

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
    local TNB_Types.ResolvedEffect Effect;
    local UIText Label;
    local UIListItem_TNBEffect Card;
    local UIButton Button;
    super.InitScreen(InitController, InitMovie, InitName);
    OpenedCampaignID = class'TNB_CampaignService'.static.CampaignID();
    Link = class'XComGameState_TNBCampaignLink'.static.Get();
    if (!StillOpen() || Link.CampaignID != OpenedCampaignID || Link.SchemaVersion != 1 || !Link.bOneTimeEffectsCommitted) { CloseScreen(); return; }
    Spawn(class'UIBGBox', self).InitBG('Backdrop', 65, 45, 1790, 965, eUIState_Faded);
    Label = Spawn(class'UIText', self).InitText('Title', "THE NAME BENEATH - COMMANDER & BONUSES", true);
    Label.SetPosition(95, 62); Label.SetSize(1715, 56);
    Label = Spawn(class'UIText', self).InitText('Identity'); Label.SetPosition(95, 121); Label.SetSize(1715, 42);
    Label.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText(class'TNB_Types'.static.EscapeUI(class'TNB_Types'.static.SingleLine(Link.Journey.CommanderName $ " / " $ Link.Journey.GameName)), 28));
    JourneyHeading = Spawn(class'UIText', self).InitText('Journey');
    JourneyHeading.SetPosition(95, 168); JourneyHeading.SetSize(1715, 72);
    Label = Spawn(class'UIText', self).InitText('SavedCaption', "SAVED CAMPAIGN EFFECTS");
    Label.SetPosition(95, 244); Label.SetSize(1715, 30);
    Label = Spawn(class'UIText', self).InitText('TimingHelp'); Label.SetPosition(95, 280); Label.SetSize(1340, 38);
    Label.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("One-time rewards: already processed. Ongoing/monthly effects: future eligible gains only.", 20));
    RefreshStatus = Spawn(class'UIText', self).InitText('RefreshStatus');
    RefreshStatus.SetPosition(95, 322); RefreshStatus.SetSize(1340, 34);
    RefreshButton = Spawn(class'UIButton', self).InitButton('RefreshName', "Refresh Journey name", RefreshClicked);
    RefreshButton.SetPosition(1515, 282); RefreshButton.SetWidth(280);
    UpdateJourneyLabel();
    Spawn(class'UIBGBox', self).InitBG('DetailsBackground', 980, 373, 835, 525, eUIState_Faded);
    DetailIcon = Spawn(class'UIIcon', self).InitIcon('DetailIcon', class'UIUtilities_Image'.const.UnknownAbilityIcon, false, true, 84);
    DetailIcon.SetPosition(1000, 391); DetailIcon.DisableNavigation();
    DetailHeading = Spawn(class'UIText', self).InitText('DetailHeading');
    DetailHeading.SetPosition(1102, 391); DetailHeading.SetSize(685, 86);
    DetailText = Spawn(class'UITextContainer', self).InitTextContainer('Details', "Select a saved commander effect.", 1005, 490, 775, 385, true);
    EffectList = Spawn(class'UIList', self); EffectList.ItemPadding = 8; EffectList.bSelectFirstAvailable = false;
    EffectList.InitList('Effects', 95, 373, 840, 525);
    EffectList.OnSelectionChanged = Selected; EffectList.OnItemClicked = Selected;
    foreach Link.Effects(Effect)
    {
        Card = UIListItem_TNBEffect(EffectList.CreateItem(class'UIListItem_TNBEffect'));
        Card.InitEffect(Effect, true);
    }
    if (Link.Effects.Length > 0) { EffectList.SetSelectedIndex(0); Selected(EffectList, 0); }
    else DetailText.SetHTMLText(class'UIUtilities_Text'.static.AddFontInfo("No configured commander effects were applied. The saved campaign association remains intact.", bIsIn3D, false, , 20));
    Label = Spawn(class'UIText', self).InitText('Notice'); Label.SetPosition(95, 912); Label.SetSize(825, 76);
    Label.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("Read-only saved effects. Viewing never repeats rewards or changes mappings.\nSelect a card; Page Up/Down or right stick scrolls its details.", 18));
    Button = Spawn(class'UIButton', self).InitButton('MappingDetails', "Mapping details", MappingClicked);
    Button.SetPosition(1005, 933); Button.SetWidth(250); Button.SetDisabled(Link.Effects.Length == 0);
    Button = Spawn(class'UIButton', self).InitButton('JourneyDetails', "Journey details", JourneyClicked);
    Button.SetPosition(1280, 933); Button.SetWidth(250);
    Button = Spawn(class'UIButton', self).InitButton('Back', class'UIUtilities_Text'.default.m_strGenericBack, BackClicked);
    Button.SetPosition(1635, 933); Button.SetWidth(160);
    Navigator.SetSelected(EffectList);
}

private function UpdateJourneyLabel()
{
    JourneyHeading.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("Journey: " $ class'TNB_Types'.static.EscapeUI(class'TNB_Types'.static.DisplayTitle(class'XComGameState_TNBJourneyLabel'.static.Title(Link))), 20));
    RefreshStatus.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("Title last checked: " $ class'TNB_EffectPresentation'.static.ReadableObservedAt(class'XComGameState_TNBJourneyLabel'.static.SeenAt(Link)) $ " (cached; refresh requires companion)", 18));
}

simulated function Selected(UIList ContainerList, int ItemIndex)
{
    local TNB_Types.ResolvedEffect Effect;
    if (!StillOpen() || ItemIndex < 0 || ItemIndex >= Link.Effects.Length) return;
    SelectedEffect = ItemIndex; Effect = Link.Effects[ItemIndex];
    DetailIcon.LoadIcon(class'TNB_EffectPresentation'.static.EffectImage(Effect));
    DetailIcon.SetBGColorState(class'TNB_EffectPresentation'.static.EffectColor(Effect));
    DetailHeading.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText(class'TNB_Types'.static.EscapeUI(class'TNB_Types'.static.SingleLine(Effect.SourceName)) $ "\n" $ class'TNB_Types'.static.EscapeUI(class'TNB_EffectPresentation'.static.CommittedSummary(Effect)), 24));
    DetailText.SetHTMLText(class'UIUtilities_Text'.static.AddFontInfo(class'TNB_EffectPresentation'.static.CommanderDetails(Effect), bIsIn3D, false, , 20));
    if (DetailText.Scrollbar != none) DetailText.Scrollbar.SetThumbAtPercent(0.0);
}

simulated function MappingClicked(UIButton Button)
{
    if (!StillOpen() || SelectedEffect < 0 || SelectedEffect >= Link.Effects.Length) return;
    Message("Saved commander mapping", class'TNB_EffectPresentation'.static.MappingDetails(Link.Effects[SelectedEffect], Link.MappingRevision));
}

simulated function JourneyClicked(UIButton Button)
{
    if (!StillOpen()) return;
    Message("Campaign Journey", "Journey: " $ class'TNB_Types'.static.EscapeUI(class'TNB_Types'.static.DisplayTitle(class'XComGameState_TNBJourneyLabel'.static.Title(Link))) $ "\nCommander: " $ class'TNB_Types'.static.EscapeUI(Link.Journey.CommanderName) $ "\nGame: " $ class'TNB_Types'.static.EscapeUI(Link.Journey.GameName) $ "\nJourney ID: " $ class'TNB_Types'.static.EscapeUI(Link.Journey.JourneyID) $ "\nMapping revision: " $ class'TNB_Types'.static.EscapeUI(Link.MappingRevision) $ "\n\nThis association belongs to the loaded save. Remote Journey history does not rewind when loading an older save. Refreshing a title changes no saved bonuses.");
}

simulated function RefreshClicked(UIButton Button)
{
    local JsonObject Args;
    if (!StillOpen() || Request != none) return;
    Args = new class'JsonObject'; Args.SetStringValue("expected_journey_id", Link.Journey.JourneyID);
    Request = Spawn(class'TNB_LoopbackClient');
    if (Request == none) { Message("Journey name", "Companion client unavailable. The saved title and bonuses are unchanged."); return; }
    RefreshButton.SetDisabled(true);
    Request.BeginRequest("journey_context", RefreshComplete, Args);
}

function RefreshComplete(JsonObject Data, string ErrorCode)
{
    local TNB_Types.JourneyContext Updated;
    Request = none;
    if (!StillOpen()) return;
    RefreshButton.SetDisabled(false);
    if (ErrorCode == "" && class'TNB_Types'.static.ReadJourney(Data, Updated) && Updated.JourneyID == Link.Journey.JourneyID && Updated.CommanderID == Link.Journey.CommanderID)
    {
        class'XComGameState_TNBJourneyLabel'.static.Observe(Data);
        UpdateJourneyLabel();
    }
    else Message("Journey name not refreshed", "The saved name and bonuses are unchanged. Check the companion and try again.\n" $ class'TNB_Types'.static.EscapeUI(ErrorCode));
}

private function Message(string Title, string Body)
{
    local UIDialogueBox.TDialogueBoxData Dialog;
    Dialog.eType = eDialog_Normal; Dialog.strTitle = Title; Dialog.strText = Body;
    Dialog.strAccept = class'UIUtilities_Text'.default.m_strGenericOK;
    Movie.Pres.UIRaiseDialog(Dialog);
}

simulated function BackClicked(UIButton Button) { CloseScreen(); }

simulated function bool OnUnrealCommand(int Cmd, int Arg)
{
    if (!CheckInputIsReleaseOrDirectionRepeat(Cmd, Arg)) return true;
    switch (Cmd)
    {
        case class'UIUtilities_Input'.const.FXS_KEY_PAGEUP:
        case class'UIUtilities_Input'.const.FXS_VIRTUAL_RSTICK_UP: ScrollDetails(-0.15); return true;
        case class'UIUtilities_Input'.const.FXS_KEY_PAGEDN:
        case class'UIUtilities_Input'.const.FXS_VIRTUAL_RSTICK_DOWN: ScrollDetails(0.15); return true;
        case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
        case class'UIUtilities_Input'.const.FXS_BUTTON_B:
        case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN: CloseScreen(); return true;
    }
    return super.OnUnrealCommand(Cmd, Arg);
}

simulated function ScrollDetails(float Amount)
{
    if (DetailText != none && DetailText.Scrollbar != none)
        DetailText.Scrollbar.SetThumbAtPercent(FClamp(DetailText.Scrollbar.Percent + Amount, 0.0, 1.0));
}

simulated function OnRemoved()
{
    if (Request != none) Request.CancelRequest();
    Request = none; Link = none;
    super.OnRemoved();
}

defaultproperties
{
    InputState=eInputState_Consume
    bConsumeMouseEvents=true
    bHideOnLoseFocus=false
    bAnimateOnInit=false
}
