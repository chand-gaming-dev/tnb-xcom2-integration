class X2EventListener_TNBArmory extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
    local array<X2DataTemplate> Templates;
    local CHEventListenerTemplate Template;
    `CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'TNB_ArmoryMenu');
    Template.RegisterInStrategy = true;
    Template.RegisterInTactical = false;
    Template.AddCHEvent('OnArmoryMainMenuUpdate', OnArmoryMenu, ELD_Immediate);
    Templates.AddItem(Template);
    return Templates;
}

static function EventListenerReturn OnArmoryMenu(Object EventData, Object EventSource, XComGameState GameState, name EventID, Object CallbackData)
{
    local UIArmory_MainMenu Armory;
    local UIList Menu;
    local UIListItem_TNBArmory Item;
    local int Index;

    Armory = UIArmory_MainMenu(EventSource);
    Menu = UIList(EventData);
    if (Armory == none || Menu == none || Armory.GetUnit() == none || !Armory.GetUnit().IsSoldier()) return ELR_NoInterrupt;
    for (Index = 0; Index < Menu.GetItemCount(); Index++)
        if (UIListItem_TNBArmory(Menu.GetItem(Index)) != none) { UIListItem_TNBArmory(Menu.GetItem(Index)).RefreshLabel(); return ELR_NoInterrupt; }
    Item = Armory.Spawn(class'UIListItem_TNBArmory', Menu.ItemContainer);
    Item.Armory = Armory;
    Item.InitListItem(class'UIListItem_TNBArmory'.default.MenuLabel);
    Item.RefreshLabel();
    Item.ButtonBG.OnClickedDelegate = Item.OpenLink;
    return ELR_NoInterrupt;
}
