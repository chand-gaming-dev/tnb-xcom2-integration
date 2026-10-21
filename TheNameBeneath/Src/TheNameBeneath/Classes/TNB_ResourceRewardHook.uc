class TNB_ResourceRewardHook extends Object;

var delegate<GiveSignature> Original;
struct ResourceOrigin
{
    var XComGameState Change;
    var string Key;
    var name Resource;
    var int Calls;
};
var array<ResourceOrigin> Origins;
delegate GiveSignature(XComGameState Change, XComGameState_Reward Reward, optional StateObjectReference AuxRef, optional bool bOrder = false, optional int OrderHours = -1);

function Give(XComGameState Change, XComGameState_Reward Reward, optional StateObjectReference AuxRef, optional bool bOrder = false, optional int OrderHours = -1)
{
    local ResourceOrigin Origin;
    local Object Listener;
    Listener = self;
    Origin.Change = Change; Origin.Resource = Reward.GetMyTemplate().rewardObjectTemplateName;
    if (class'TNB_CommanderBonusService'.static.QualifyingReward(Reward.ObjectID)) Origin.Key = "reward:" $ Reward.ObjectID;
    // Intercept AddResource only while the original, preserved reward delegate is executing.
    if (Origins.Length == 0) `XEVENTMGR.RegisterForEvent(Listener, 'AddResource', OnAddResource, ELD_Immediate);
    Origins.AddItem(Origin);
    Original(Change, Reward, AuxRef, bOrder, OrderHours);
    Origins.Remove(Origins.Length - 1, 1);
    if (Origins.Length == 0) `XEVENTMGR.UnRegisterFromEvent(Listener, 'AddResource');
}

function EventListenerReturn OnAddResource(Object EventData, Object EventSource, XComGameState GameState, name EventID, Object CallbackData)
{
    local ResourceOrigin Origin;
    local XComGameState_Item Item;
    if (Origins.Length == 0) return ELR_NoInterrupt;
    Origin = Origins[Origins.Length - 1]; Item = XComGameState_Item(EventData);
    if (Item != none && Origin.Change == GameState && Origin.Key != "" && Item.GetMyTemplateName() == Origin.Resource)
    {
        Origins[Origins.Length - 1].Calls++;
        class'TNB_CommanderBonusService'.static.ApplyResource(GameState, Item, Origin.Key $ ":" $ string(Origin.Resource) $ ":" $ Origins[Origins.Length - 1].Calls);
    }
    return ELR_NoInterrupt;
}
