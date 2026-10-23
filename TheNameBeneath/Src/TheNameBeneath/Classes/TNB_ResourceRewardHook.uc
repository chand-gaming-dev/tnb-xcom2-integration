class TNB_ResourceRewardHook extends Object dependson(TNB_Types);

var delegate<GiveSignature> Original;
var delegate<TextSignature> OriginalText;
var delegate<TextSignature> OriginalPreview;
struct ResourceOrigin
{
    var XComGameState Change;
    var string Key;
    var name Resource;
    var int Calls;
    var int RewardID;
    var int ParticipantBasisPoints;
    var int BasisPoints;
    var string Sources;
};
var array<ResourceOrigin> Origins;
delegate GiveSignature(XComGameState Change, XComGameState_Reward Reward, optional StateObjectReference AuxRef, optional bool bOrder = false, optional int OrderHours = -1);
delegate string TextSignature(XComGameState_Reward Reward);

function string RewardText(XComGameState_Reward Reward)
{
    local string Text;
    if (OriginalText != none) Text = OriginalText(Reward);
    return class'TNB_RewardMappingService'.static.RewardText(Reward, Text);
}

function string PreviewText(XComGameState_Reward Reward)
{
    local string Text;
    if (OriginalPreview != none) Text = OriginalPreview(Reward);
    return class'TNB_RewardMappingService'.static.RewardText(Reward, Text);
}

function Give(XComGameState Change, XComGameState_Reward Reward, optional StateObjectReference AuxRef, optional bool bOrder = false, optional int OrderHours = -1)
{
    local ResourceOrigin Origin;
    local Object Listener;
    local XComGameState_TNBCampaignLink Campaign;
    local int OwnerID;
    local string Kind;
    local array<string> Sources;
    local TNB_Types.ResolvedEffect Effect;
    Listener = self;
    Origin.Change = Change; Origin.Resource = Reward.GetMyTemplate().rewardObjectTemplateName;
    Origin.RewardID = Reward.ObjectID;
    Campaign = class'XComGameState_TNBCampaignLink'.static.Get(Change);
    if (Campaign != none && Campaign.bOneTimeEffectsCommitted && class'TNB_RewardMappingService'.static.RewardOwner(Reward.ObjectID, Change, OwnerID, Kind))
    {
        Origin.Key = "reward:" $ Reward.ObjectID;
        Origin.ParticipantBasisPoints = class'TNB_RewardMappingService'.static.ParticipantPercent(Change, OwnerID, Kind, Origin.Resource, Sources);
        Origin.BasisPoints = Clamp(Campaign.ResourcePercent(Origin.Resource) + Origin.ParticipantBasisPoints, -10000, 100000);
        foreach Campaign.Effects(Effect)
            if (Effect.Status == "active" && Effect.EffectKind == 'ResourcePercent' && Effect.Target == Origin.Resource && Effect.Magnitude != 0)
                Sources.AddItem("Commander: " $ Effect.SourceName $ " " $ class'TNB_EffectPresentation'.static.Percentage(Effect.Magnitude));
        if (Sources.Length > 0) Origin.Sources = class'TNB_RewardMappingService'.static.SourceLabel(Sources);
    }
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
    local XComGameState_TNBCampaignLink Campaign;
    local string Key;
    local int OriginalAmount, Adjustment;
    if (Origins.Length == 0) return ELR_NoInterrupt;
    Origin = Origins[Origins.Length - 1]; Item = XComGameState_Item(EventData);
    if (Item != none && Origin.Change == GameState && Origin.Key != "" && Item.GetMyTemplateName() == Origin.Resource)
    {
        Origins[Origins.Length - 1].Calls++;
        Key = Origin.Key $ ":" $ string(Origin.Resource) $ ":" $ Origins[Origins.Length - 1].Calls;
        Campaign = class'XComGameState_TNBCampaignLink'.static.Get(GameState);
        if (Campaign == none || Campaign.ResourceLedger.Find(Key) != INDEX_NONE || Item.LastQuantityChange <= 0) return ELR_NoInterrupt;
        OriginalAmount = Item.LastQuantityChange;
        Adjustment = class'TNB_CommanderBonusService'.static.ApplyResource(GameState, Item, Key, Origin.ParticipantBasisPoints);
        if (Origin.Sources != "") class'TNB_RewardMappingService'.static.Record(GameState, Key, Origin.RewardID, Origin.Resource, OriginalAmount, Adjustment, Origin.BasisPoints, Origin.Sources);
    }
    return ELR_NoInterrupt;
}
