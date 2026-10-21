// A read-only, navigable icon card. All children belong to this screen's world.
class UIListItem_TNBEffect extends UIPanel dependson(TNB_Types);

var UIBGBox Background;
var TNB_Types.ResolvedEffect Effect;

simulated function InitEffect(TNB_Types.ResolvedEffect Value, optional bool Commander)
{
    local UIIcon Icon;
    local UIText Label;
    Effect = Value;
    InitPanel();
    SetSize(840, 116);
    Background = Spawn(class'UIBGBox', self).InitBG('Card', 0, 0, 840, 112, eUIState_Faded);
    Background.ProcessMouseEvents(CardMouseEvent);
    Icon = Spawn(class'UIIcon', self).InitIcon('EffectIcon', class'TNB_EffectPresentation'.static.EffectImage(Effect), false, true, 70, Commander ? class'TNB_EffectPresentation'.static.EffectColor(Effect) : class'TNB_EffectPresentation'.static.SoldierColor(Effect));
    Icon.SetPosition(18, 20); Icon.DisableNavigation();
    Label = Spawn(class'UIText', self).InitText('Source');
    Label.SetPosition(108, 6); Label.SetSize(700, 32);
    Label.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText(class'TNB_Types'.static.EscapeUI(class'TNB_Types'.static.SingleLine(string(Effect.SourceKind) $ ": " $ Effect.SourceName)), 20));
    Label = Spawn(class'UIText', self).InitText('Benefit');
    Label.SetPosition(108, 37); Label.SetSize(700, 36);
    Label.SetHTMLText(class'UIUtilities_Text'.static.GetColoredText(class'UIUtilities_Text'.static.GetSizedText(class'TNB_Types'.static.EscapeUI(class'TNB_EffectPresentation'.static.CommittedSummary(Effect)), 26), Commander ? class'TNB_EffectPresentation'.static.EffectColor(Effect) : class'TNB_EffectPresentation'.static.SoldierColor(Effect)));
    Label = Spawn(class'UIText', self).InitText('Result');
    Label.SetPosition(108, 77); Label.SetSize(700, 30);
    Label.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText(Commander ? class'TNB_EffectPresentation'.static.TimingBadge(Effect.EffectKind) $ " | " $ class'TNB_Types'.static.EscapeUI(class'TNB_EffectPresentation'.static.StatusText(Effect.Status, true)) : class'TNB_Types'.static.EscapeUI(class'TNB_EffectPresentation'.static.SoldierStatus(Effect)), 18));
}

simulated function CardMouseEvent(UIPanel Panel, int Cmd)
{
    local UIList List;
    List = UIList(GetParent(class'UIList'));
    if (List != none) List.OnChildMouseEvent(self, Cmd);
}

simulated function OnReceiveFocus()
{
    super.OnReceiveFocus();
    if (Background != none) Background.SetHighlighed(true);
}

simulated function OnLoseFocus()
{
    super.OnLoseFocus();
    if (Background != none) Background.SetHighlighed(false);
}

defaultproperties
{
    Width=840
    Height=116
    bCascadeFocus=false
    bProcessesMouseEvents=true
    bAnimateOnInit=false
}
