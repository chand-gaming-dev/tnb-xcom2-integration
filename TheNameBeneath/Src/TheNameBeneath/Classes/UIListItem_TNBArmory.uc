class UIListItem_TNBArmory extends UIListItemString;

var UIArmory_MainMenu Armory;
var localized string MenuLabel, LinkedLabel, PendingLabel;
var localized string ConnectFirstTitle, ConnectFirstText;

function RefreshLabel()
{
    if (class'XComGameState_TNBSoldierLink'.static.ForUnit(Armory.GetUnit()) != none) SetText(LinkedLabel);
    else if (class'XComGameState_TNBLinkIntent'.static.ForUnit(Armory.GetUnit()) != none) SetText(PendingLabel);
    else SetText(MenuLabel);
}

function OpenLink(UIButton Button)
{
    local UITNBCharacterPicker Picker;
    local UIDialogueBox.TDialogueBoxData Dialog;
    if (Armory == none || Armory.bIsRemoved || Armory.Movie.Stack.IsInStack(class'UITNBCharacterPicker')) return;
    if (!class'TNB_SoldierEffectService'.static.Eligible(Armory.GetUnit())) return;
    if (class'XComGameState_TNBSoldierLink'.static.ForUnit(Armory.GetUnit()) != none)
    {
        class'UITNBSoldierProfile'.static.Open(Armory, Armory.UnitReference);
        return;
    }
    if (class'XComGameState_TNBCampaignLink'.static.Get() == none)
    {
        Dialog.eType = eDialog_Normal; Dialog.strTitle = ConnectFirstTitle; Dialog.strText = ConnectFirstText;
        Dialog.strAccept = class'UIUtilities_Text'.default.m_strGenericOK;
        Armory.Movie.Pres.UIRaiseDialog(Dialog);
        return;
    }
    Picker = Armory.Spawn(class'UITNBCharacterPicker');
    Picker.Armory = Armory; Picker.UnitRef = Armory.UnitReference;
    Armory.Movie.Stack.Push(Picker);
}
