// Independent of promotion/officer mods. This screen never changes a unit or link.
class UITNBSoldierProfile extends UIScreen dependson(TNB_Types);

var UIArmory_MainMenu Armory;
var StateObjectReference UnitRef;
var XComGameState_TNBSoldierLink Link;
var UIList EffectList;
var UIIcon DetailIcon;
var UIText DetailHeading;
var UITextContainer DetailText;
var string Notice;
var int SelectedEffect;
var array<TNB_Types.ResolvedEffect> DisplayEffects;
var UIButton MappingButton;

static function Open(UIArmory_MainMenu Parent, StateObjectReference Soldier, optional string Message)
{
    local UITNBSoldierProfile Profile;
    if (Parent == none || Parent.bIsRemoved || Parent.Movie.Stack.IsInStack(class'UITNBSoldierProfile')) return;
    Profile = Parent.Spawn(class'UITNBSoldierProfile');
    Profile.Armory = Parent; Profile.UnitRef = Soldier; Profile.Notice = Message;
    Parent.Movie.Stack.Push(Profile);
}

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
    local XComGameState_Unit Unit;
    local XComGameState_TNBCampaignLink Campaign;
    local TNB_Types.ResolvedEffect Effect, Other;
    local array<name> Totals;
    local int Total, Index;
    local UIText Label;
    local UIIcon Icon;
    local UIListItem_TNBEffect Card;
    local UIButton Back;
    super.InitScreen(InitController, InitMovie, InitName);
    Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
    Link = class'XComGameState_TNBSoldierLink'.static.ForUnit(Unit);
    if (Armory == none || Armory.bIsRemoved || Link == none) { CloseScreen(); return; }
    Spawn(class'UIBGBox', self).InitBG('Backdrop', 65, 45, 1790, 965, eUIState_Faded);
    Label = Spawn(class'UIText', self).InitText('Title', "THE NAME BENEATH - TRAITS & ABILITIES", true);
    Label.SetPosition(95, 62); Label.SetSize(1715, 56);
    Label = Spawn(class'UIText', self).InitText('Identity');
    Label.SetPosition(95, 121); Label.SetSize(1715, 42);
    Label.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText(class'TNB_Types'.static.EscapeUI(class'TNB_Types'.static.SingleLine(Unit.GetFullName() $ " / " $ Link.Snapshot.CharacterName)), 28));
    Campaign = class'XComGameState_TNBCampaignLink'.static.Get();
    Label = Spawn(class'UIText', self).InitText('Journey');
    Label.SetPosition(95, 168); Label.SetSize(1715, 72);
    Label.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("Journey: " $ class'TNB_Types'.static.EscapeUI(class'TNB_Types'.static.DisplayTitle(class'XComGameState_TNBJourneyLabel'.static.Title(Campaign))), 20));
    Label = Spawn(class'UIText', self).InitText('TotalsCaption', "COMMITTED ATTRIBUTE BONUSES (NET DELTAS, NOT CURRENT STATS)");
    Label.SetPosition(95, 244); Label.SetSize(1715, 30);
    Index = 0;
    DisplayEffects = Link.Effects;
    if (class'TNB_DejaVuService'.static.Owns(Unit))
    {
        Effect.MappingKey = 'TNB_DejaVu'; Effect.SourceKind = 'Bonus';
        Effect.SourceName = "Deja Vu"; Effect.SourceID = ""; Effect.SourceVersion = 0;
        Effect.EffectKind = 'Ability'; Effect.Target = 'TNB_DejaVu'; Effect.Status = "available";
        DisplayEffects.AddItem(Effect);
    }
    foreach Link.Effects(Effect)
        if (Effect.EffectKind == 'Stat' && Effect.Status == "applied" && Totals.Find(Effect.Target) == INDEX_NONE)
        {
            Totals.AddItem(Effect.Target); Total = 0;
            foreach Link.Effects(Other) if (Other.EffectKind == 'Stat' && Other.Target == Effect.Target && Other.Status == "applied") Total += Other.AppliedMagnitude;
            Icon = Spawn(class'UIIcon', self).InitIcon('', class'TNB_EffectPresentation'.static.StatImage(Effect.Target), false, true, 36, Total < 0 ? eUIState_Bad : eUIState_Good);
            Icon.SetPosition(95 + (Index % 5) * 345, 279 + (Index / 5) * 45); Icon.DisableNavigation();
            Label = Spawn(class'UIText', self).InitText(); Label.SetPosition(139 + (Index % 5) * 345, 280 + (Index / 5) * 45); Label.SetSize(294, 38);
            Label.SetHTMLText(class'UIUtilities_Text'.static.GetColoredText(class'TNB_EffectPresentation'.static.Signed(Total) @ class'TNB_EffectPresentation'.static.StatLabel(Effect.Target), Total < 0 ? eUIState_Bad : eUIState_Good));
            Index++;
        }
    if (Index == 0)
    {
        Label = Spawn(class'UIText', self).InitText('', "No additive attribute changes. Ability mappings are shown below.");
        Label.SetPosition(95, 280); Label.SetSize(1600, 36);
    }
    Spawn(class'UIBGBox', self).InitBG('DetailsBackground', 980, 373, 835, 525, eUIState_Faded);
    DetailIcon = Spawn(class'UIIcon', self).InitIcon('DetailIcon', class'UIUtilities_Image'.const.UnknownAbilityIcon, false, true, 84);
    DetailIcon.SetPosition(1000, 391); DetailIcon.DisableNavigation();
    DetailHeading = Spawn(class'UIText', self).InitText('DetailHeading');
    DetailHeading.SetPosition(1102, 391); DetailHeading.SetSize(685, 86);
    DetailText = Spawn(class'UITextContainer', self).InitTextContainer('Details', "Select a trait or skill to inspect its saved mapping.", 1005, 490, 775, 385, true);
    EffectList = Spawn(class'UIList', self); EffectList.ItemPadding = 8;
    EffectList.bSelectFirstAvailable = false;
    EffectList.InitList('Effects', 95, 373, 840, 525);
    EffectList.OnSelectionChanged = Selected; EffectList.OnItemClicked = Selected;
    foreach DisplayEffects(Effect)
    {
        Card = UIListItem_TNBEffect(EffectList.CreateItem(class'UIListItem_TNBEffect'));
        Card.InitEffect(Effect);
    }
    if (DisplayEffects.Length > 0) { EffectList.SetSelectedIndex(0); Selected(EffectList, 0); }
    else DetailText.SetText("This identity link has no configured gameplay effects. The normal class tree is unchanged.");
    MappingButton = Spawn(class'UIButton', self).InitButton('MappingDetails', "Mapping details", MappingClicked);
    MappingButton.SetPosition(1005, 933); MappingButton.SetWidth(250); MappingButton.SetDisabled(Link.Effects.Length == 0);
    Label = Spawn(class'UIText', self).InitText('Notice'); Label.SetPosition(95, 912); Label.SetSize(825, 76);
    Label.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText(Notice != "" ? class'TNB_Types'.static.EscapeUI(Notice) : "Read-only mappings. Select a card for help; Page Up/Down or right stick scrolls details.\nGreen: bonus / red: penalty / amber: unavailable, disabled or unmapped. No class-tree changes.", 18));
    Back = Spawn(class'UIButton', self).InitButton('Back', class'UIUtilities_Text'.default.m_strGenericBack, BackClicked);
    Back.SetPosition(1635, 933); Back.SetWidth(160);
    Navigator.SetSelected(EffectList);
}

simulated function Selected(UIList ContainerList, int ItemIndex)
{
    local TNB_Types.ResolvedEffect Effect;
    local XComGameState_Unit Unit;
    if (Link == none || ItemIndex < 0 || ItemIndex >= DisplayEffects.Length) return;
    SelectedEffect = ItemIndex;
    Effect = DisplayEffects[ItemIndex];
    Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
    if (MappingButton != none) MappingButton.SetDisabled(ItemIndex >= Link.Effects.Length);
    if (Effect.MappingKey == 'TNB_DejaVu')
    {
        DetailIcon.LoadIcon(class'TNB_EffectPresentation'.static.AbilityImage('TNB_DejaVu'));
        DetailIcon.SetBGColorState(eUIState_Good);
        DetailHeading.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText("Deja Vu\nLocal XCOM bonus", 24));
        DetailText.SetHTMLText(class'UIUtilities_Text'.static.AddFontInfo(class'TNB_DejaVuService'.static.Description() $ "\n\nBanked bonus promotion credit: " $ class'TNB_DejaVuService'.static.CreditText(Unit) $ " (whole credits applied: " $ class'TNB_DejaVuService'.static.Value(Unit, 'TNB_DV_Whole') $ "). Percentage settings affect future earnings only. This is not a canonical trait or skill.", bIsIn3D, false, , 20));
        if (DetailText.Scrollbar != none) DetailText.Scrollbar.SetThumbAtPercent(0.0);
        return;
    }
    DetailIcon.LoadIcon(class'TNB_EffectPresentation'.static.EffectImage(Effect));
    DetailIcon.SetBGColorState(class'TNB_EffectPresentation'.static.SoldierColor(Effect));
    DetailHeading.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText(class'TNB_Types'.static.EscapeUI(class'TNB_Types'.static.SingleLine(Effect.SourceName)) $ "\n" $ class'TNB_Types'.static.EscapeUI(class'TNB_EffectPresentation'.static.CommittedSummary(Effect)), 24));
    DetailText.SetHTMLText(class'UIUtilities_Text'.static.AddFontInfo(class'TNB_EffectPresentation'.static.SoldierDetails(Effect, Unit), bIsIn3D, false, , 20));
    if (DetailText.Scrollbar != none) DetailText.Scrollbar.SetThumbAtPercent(0.0);
}

simulated function BackClicked(UIButton Button) { CloseScreen(); }

simulated function MappingClicked(UIButton Button)
{
    local UIDialogueBox.TDialogueBoxData Dialog;
    if (Link == none || SelectedEffect < 0 || SelectedEffect >= Link.Effects.Length) return;
    Dialog.eType = eDialog_Normal; Dialog.strTitle = "Saved mapping details";
    Dialog.strText = class'TNB_EffectPresentation'.static.MappingDetails(Link.Effects[SelectedEffect], Link.MappingRevision);
    Dialog.strAccept = class'UIUtilities_Text'.default.m_strGenericOK;
    Movie.Pres.UIRaiseDialog(Dialog);
}

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
    Link = none; Armory = none;
    super.OnRemoved();
}

defaultproperties
{
    InputState=eInputState_Consume
    bConsumeMouseEvents=true
    bHideOnLoseFocus=false
    bAnimateOnInit=false
}
