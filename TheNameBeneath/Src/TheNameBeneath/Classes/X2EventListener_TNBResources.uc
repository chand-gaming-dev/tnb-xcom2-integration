class X2EventListener_TNBResources extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
    local array<X2DataTemplate> Templates;
    local CHEventListenerTemplate Template;
    `CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'TNB_StrategyResources');
    Template.RegisterInStrategy = true;
    Template.RegisterInTactical = false;
    Template.AddCHEvent('ResourceCacheSupplies', class'TNB_CommanderBonusService'.static.OnSupplyCollected, ELD_Immediate);
    Template.AddCHEvent('PreEndOfMonth', class'TNB_CommanderBonusService'.static.OnMonthEnd, ELD_Immediate);
    Templates.AddItem(Template);
    return Templates;
}
