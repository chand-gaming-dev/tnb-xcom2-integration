// Independent of the Journey/event-reporting subsystem, including external grants.
class X2EventListener_TNBDejaVu extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
    local CHEventListenerTemplate Template;
    local array<X2DataTemplate> Templates;
    `CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'TNB_DejaVuListeners');
    Template.RegisterInStrategy = true; Template.RegisterInTactical = true;
    // Observe final native awards after CI (99) and Requiem restrictions (40).
    // Never alter the shared assist value: that would reward unlinked squadmates.
    Template.AddCHEvent('OverrideKillXp', KillCredit, ELD_Immediate, 0);
    // Add our bank before Requiem's final promotion gate (40), not after it.
    Template.AddCHEvent('OverrideTotalNumKills', PromotionCredit, ELD_Immediate, 50);
    Template.AddCHEvent('CovertActionCompleted', CovertCompleted, ELD_Immediate);
    Template.AddCHEvent('UnitRankUp', BeforeRankReward, ELD_Immediate);
    Templates.AddItem(Template);
    return Templates;
}

static function EventListenerReturn PromotionCredit(Object EventData, Object EventSource, XComGameState Pending, name EventID, Object CallbackData)
{
    local XComLWTuple Tuple;
    local XComGameState_Unit Unit;
    Tuple = XComLWTuple(EventData); Unit = XComGameState_Unit(EventSource);
    if (Tuple == none || Unit == none || Tuple.Id != EventID || Tuple.Data.Length != 1 || Tuple.Data[0].kind != XComLWTVInt || class'X2ExperienceConfig'.default.bUseFullXpSystem) return ELR_NoInterrupt;
    // Bank is already earned, including when percentage is now zero or perk removed.
    Tuple.Data[0].i += class'TNB_DejaVuService'.static.Value(Unit, 'TNB_DV_Whole');
    return ELR_NoInterrupt;
}

static function EventListenerReturn KillCredit(Object EventData, Object EventSource, XComGameState Pending, name EventID, Object CallbackData)
{
    local XComLWTuple Tuple;
    local XComGameState_Unit Killer, Ally;
    local X2SoldierClassTemplate ClassTemplate;
    local float Credit;
    Tuple = XComLWTuple(EventData);
    if (Pending == none || Tuple == none || Tuple.Id != EventID || Tuple.Data.Length != 5 || Tuple.Data[0].kind != XComLWTVFloat || Tuple.Data[1].kind != XComLWTVFloat || Tuple.Data[2].kind != XComLWTVFloat || Tuple.Data[3].kind != XComLWTVInt || Tuple.Data[4].kind != XComLWTVObject) return ELR_NoInterrupt;
    Killer = XComGameState_Unit(Tuple.Data[4].o);
    if (Killer == none) return ELR_NoInterrupt;
    Credit = FMax(0, Tuple.Data[0].f) + FMax(0, Tuple.Data[1].f) + FMax(0, Tuple.Data[3].i * class'X2ExperienceConfig'.default.NumKillsBonus);
    class'TNB_DejaVuService'.static.Award(Pending, Killer, Credit);
    // Same recipients as the native assist loop, with each class's conversion rate.
    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Ally)
        if (Ally.ObjectID != Killer.ObjectID && Ally.ControllingPlayer.ObjectID == Killer.ControllingPlayer.ObjectID && Ally.CanEarnXp() && Ally.IsAlive() && Ally.IsSoldier())
        {
            ClassTemplate = Ally.GetSoldierClassTemplate();
            if (ClassTemplate != none && ClassTemplate.KillAssistsPerKill > 0)
                class'TNB_DejaVuService'.static.Award(Pending, Ally, class'TNB_DejaVuService'.static.AssistCredit(Ally.KillAssistsCount, Tuple.Data[2].f, ClassTemplate.KillAssistsPerKill));
        }
    return ELR_NoInterrupt;
}

static function EventListenerReturn CovertCompleted(Object EventData, Object EventSource, XComGameState Pending, name EventID, Object CallbackData)
{
    ProcessCovert(Pending, XComGameState_CovertAction(EventSource));
    return ELR_NoInterrupt;
}

// Native Reward_RankUp first gives ordinary covert XP, fires UnitRankUp, then
// resets NonTacticalKills to a rank threshold. Bank before that artificial top-up.
static function EventListenerReturn BeforeRankReward(Object EventData, Object EventSource, XComGameState Pending, name EventID, Object CallbackData)
{
    local XComGameState_CovertAction Action;
    local XComGameState_Unit Unit;
    if (Pending == none) return ELR_NoInterrupt;
    Unit = XComGameState_Unit(EventData);
    if (Unit == none) return ELR_NoInterrupt;
    foreach Pending.IterateByClassType(class'XComGameState_CovertAction', Action)
        ProcessCovert(Pending, Action, Unit);
    return ELR_NoInterrupt;
}

static function ProcessCovert(XComGameState Pending, XComGameState_CovertAction Action, optional XComGameState_Unit RankRewardUnit)
{
    local XComGameState_StaffSlot Slot;
    local XComGameState_Reward Reward;
    local XComGameState_Unit Unit, Old;
    local int Index;
    if (Pending == none || Action == none || class'X2ExperienceConfig'.default.bUseFullXpSystem) return;
    for (Index = 0; Index < Action.StaffSlots.Length; Index++)
    {
        Slot = Action.GetStaffSlot(Index);
        if (Slot == none || !Slot.IsSlotFilled()) continue;
        Unit = XComGameState_Unit(Pending.GetGameStateForObjectID(Slot.GetAssignedStaffRef().ObjectID));
        if (Unit == none || !Unit.IsSoldier() || !Unit.IsAlive() || Unit.bCaptured) continue;
        if (RankRewardUnit != none)
        {
            if (Unit.ObjectID != RankRewardUnit.ObjectID || Action.StaffSlots[Index].RewardRef.ObjectID == 0) continue;
            Reward = XComGameState_Reward(`XCOMHISTORY.GetGameStateForObjectID(Action.StaffSlots[Index].RewardRef.ObjectID));
            if (Reward == none || Reward.GetMyTemplateName() != 'Reward_RankUp') continue;
        }
        if (class'TNB_DejaVuService'.static.Value(Unit, 'TNB_DV_LastCovert') == Action.ObjectID) continue;
        Old = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Unit.ObjectID));
        if (Old == none || !class'TNB_DejaVuService'.static.Owns(Unit)) continue;
        class'TNB_DejaVuService'.static.Award(Pending, Unit, Max(0, Unit.NonTacticalKills - Old.NonTacticalKills));
        // Idempotent native callbacks, even with two staffed slots for one soldier.
        Unit.SetUnitFloatValue('TNB_DV_LastCovert', Action.ObjectID, eCleanup_Never);
    }
}
