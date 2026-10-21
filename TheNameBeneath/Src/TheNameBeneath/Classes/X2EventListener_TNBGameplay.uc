class X2EventListener_TNBGameplay extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
    local array<X2DataTemplate> Templates;
    local CHEventListenerTemplate Template;
    `CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'TNB_GameplayCapture');
    Template.RegisterInStrategy = true;
    Template.RegisterInTactical = true;
    Template.AddCHEvent('OnTacticalBeginPlay', OnGameplay, ELD_Immediate);
    Template.AddCHEvent('CleanupTacticalMission', OnGameplay, ELD_Immediate);
    Template.AddCHEvent('CovertActionStarted', OnGameplay, ELD_Immediate);
    Template.AddCHEvent('CovertActionCompleted', OnGameplay, ELD_Immediate);
    Template.AddCHEvent('UnitHealCompleted', OnGameplay, ELD_Immediate);
    Template.AddCHEvent('UnitRankUp', OnGameplay, ELD_Immediate);
    Template.AddCHEvent('BondCreated', OnGameplay, ELD_Immediate);
    Template.AddCHEvent('BondLevelUpComplete', OnGameplay, ELD_Immediate);
    Template.AddCHEvent('UnitCaptured', OnGameplay, ELD_Immediate);
    Templates.AddItem(Template);
    return Templates;
}

static function EventListenerReturn OnGameplay(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
    local XComGameState_Unit Soldier;
    if (GameState == none || class'XComGameState_TNBCampaignLink'.static.Get(GameState) == none) return ELR_NoInterrupt;
    switch (EventID)
    {
        case 'OnTacticalBeginPlay':
            class'TNB_ReportingSafety'.static.Trace("TACTICAL_BEGIN_PLAY_ENTER", GameState);
            class'TNB_EventCaptureService'.static.TacticalStarted(GameState);
            class'TNB_EventPump'.static.Ensure();
            class'TNB_ReportingSafety'.static.Trace("TACTICAL_BEGIN_PLAY_EXIT", GameState);
            break;
        case 'CleanupTacticalMission':
            class'TNB_ReportingSafety'.static.Trace("TACTICAL_CLEANUP_ENTER", GameState);
            class'TNB_EventCaptureService'.static.TacticalCleanup(GameState, XComGameState_BattleData(EventData));
            class'TNB_ReportingSafety'.static.Trace("TACTICAL_CLEANUP_EXIT", GameState);
            break;
        case 'CovertActionStarted': class'TNB_EventCaptureService'.static.Covert(GameState, XComGameState_CovertAction(EventSource), false); break;
        case 'CovertActionCompleted': class'TNB_EventCaptureService'.static.Covert(GameState, XComGameState_CovertAction(EventSource), true); break;
        case 'UnitRankUp': class'TNB_PromotionCaptureService'.static.Observe(GameState, XComGameState_Unit(EventData)); break;
        case 'UnitCaptured':
            Soldier = XComGameState_Unit(EventData);
            if (Soldier == none) break;
            Soldier = XComGameState_Unit(GameState.GetGameStateForObjectID(Soldier.ObjectID));
            class'TNB_CaptivityCaptureService'.static.ObserveNative(GameState, Soldier);
            break;
        case 'BondCreated':
        case 'BondLevelUpComplete': class'TNB_BondCaptureService'.static.Observe(GameState, XComGameState_Unit(EventData), XComGameState_Unit(EventSource), EventID); break;
        default:
            Soldier = XComGameState_Unit(EventData);
            if (Soldier == none) Soldier = XComGameState_Unit(EventSource);
            class'TNB_EventCaptureService'.static.ObservePendingUnit(GameState, Soldier);
            break;
    }
    return ELR_NoInterrupt;
}
