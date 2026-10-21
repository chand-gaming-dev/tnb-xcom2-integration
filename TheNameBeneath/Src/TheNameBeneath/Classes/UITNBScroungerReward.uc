// Reuse the native dismissible item-received alert, including its image panel,
// input handling and normal popup lifecycle. All rewards are already committed.
class UITNBScroungerReward extends UIAlert;

simulated function BuildItemReceivedAlert()
{
    local TAlertAvailableInfo Info;
    local X2ItemTemplate Template;
    Template = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(
        class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'ItemTemplate'));
    Info.strTitle = class'TNB_CommanderRewardPresentation'.static.LocalizedText('ScroungerTitle');
    if (Template != none)
    {
        Info.strName = class'TNB_CommanderRewardPresentation'.static.ItemDisplayName(Template.GetItemFriendlyName(, false));
        if (Info.strName == "") Info.strName = class'TNB_Types'.static.EscapeUI(string(Template.DataName));
        Info.strImage = Template.strImage;
    }
    else
    {
        Info.strName = class'TNB_Types'.static.EscapeUI(string(class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'ItemTemplate')));
        Info.strImage = class'UIUtilities_Image'.const.LootIcon_Loot;
    }
    Info.strBody = class'TNB_CommanderRewardPresentation'.static.ScroungerRewardBody(Info.strName);
    Info.strConfirm = m_strAccept;
    Info.eColor = eUIState_Good;
    Info.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);
    Info = FillInShenAlertAvailable(Info);
    BuildAvailableAlert(Info);
}
