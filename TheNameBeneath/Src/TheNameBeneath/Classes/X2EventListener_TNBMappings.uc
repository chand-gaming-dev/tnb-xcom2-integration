class X2EventListener_TNBMappings extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
    local array<X2DataTemplate> Templates;
    local CHEventListenerTemplate Template;
    `CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'TNB_StrategyMappings');
    Template.RegisterInStrategy = true;
    // Recovery projects may be initialized during tactical cleanup as well.
    // These are source-checked read-only query hooks in either layer.
    Template.RegisterInTactical = true;
    Template.AddCHEvent('CovertActionRisk_AlterChanceModifier', RiskModifier, ELD_Immediate);
    Template.AddCHEvent('WillRecoveryTimeModifier', RecoveryModifier, ELD_Immediate);
    Template.AddCHEvent('WoundRecoveryTimeModifier', RecoveryModifier, ELD_Immediate);
    Template.AddCHEvent('OverrideScienceScore', ScienceModifier, ELD_Immediate, 0);
    Templates.AddItem(Template);
    return Templates;
}

static function EventListenerReturn ScienceModifier(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
    if (XComGameState_HeadquartersXCom(EventSource) != none)
        class'TNB_StrategyMappingService'.static.ApplyScience(XComLWTuple(EventData), class'XComGameState_TNBCampaignLink'.static.Get());
    return ELR_NoInterrupt;
}

static function EventListenerReturn RiskModifier(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
    local XComLWTuple Tuple;
    local XComGameState_CovertAction Action;
    local XComGameState_TNBCampaignLink Link;
    Tuple = XComLWTuple(EventData);
    Action = XComGameState_CovertAction(EventSource);
    if (Tuple == none || Action == none || Tuple.Id != EventID || Tuple.Data.Length != 5 || Tuple.Data[0].kind != XComLWTVName || Tuple.Data[4].kind != XComLWTVInt) return ELR_NoInterrupt;
    if (!class'TNB_StrategyMappingService'.static.RiskTarget(Tuple.Data[0].n)) return ELR_NoInterrupt;
    // This event omits GameState. Its action owns the pending association container
    // when refreshing existing caches; ordinary queries fall back to committed history.
    Link = class'XComGameState_TNBCampaignLink'.static.Get(Action.GetParentGameState());
    if (Link != none && Link.bOneTimeEffectsCommitted)
        Tuple.Data[4].i += class'TNB_StrategyMappingService'.static.ActiveTotal(Link.Effects, 'CovertRisk', Tuple.Data[0].n);
    // Do not clamp the additive modifier: native resolution clamps the final chance,
    // honors NegatedRisks, and leaves absent/ineligible risks absent.
    return ELR_NoInterrupt;
}

static function EventListenerReturn RecoveryModifier(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
    local XComLWTuple Tuple;
    local XComGameState_HeadquartersProject Project;
    local XComGameState_TNBCampaignLink Campaign;
    local XComGameState_TNBSoldierLink Soldier;
    local name Target;
    local int Duration;
    Tuple = XComLWTuple(EventData);
    Project = XComGameState_HeadquartersProject(EventSource);
    if (Tuple == none || Project == none || Tuple.Id != EventID || Tuple.Data.Length != 2 || Tuple.Data[0].kind != XComLWTVFloat) return ELR_NoInterrupt;
    if (EventID == 'WillRecoveryTimeModifier' && XComGameState_HeadquartersProjectRecoverWill(Project) != none) Target = 'Will';
    else if (EventID == 'WoundRecoveryTimeModifier' && XComGameState_HeadquartersProjectHealSoldier(Project) != none) Target = 'Wound';
    else return ELR_NoInterrupt;
    // Native project refreshes sometimes omit StartState; the project still
    // belongs to the caller's pending container. Never submit a separate state.
    if (GameState == none) GameState = Project.GetParentGameState();
    Campaign = class'XComGameState_TNBCampaignLink'.static.Get(GameState);
    if (Campaign != none && Campaign.bOneTimeEffectsCommitted)
        Duration = class'TNB_StrategyMappingService'.static.ActiveTotal(Campaign.Effects, 'RecoveryDuration', Target);
    Soldier = class'TNB_StrategyMappingService'.static.SoldierLink(Project.ProjectFocus.ObjectID, GameState);
    if (Soldier != none) Duration += class'TNB_StrategyMappingService'.static.ActiveTotal(Soldier.Effects, 'RecoveryDuration', Target);
    Tuple.Data[0].f *= class'TNB_StrategyMappingService'.static.RecoveryRate(Duration);
    return ELR_NoInterrupt;
}
