class TNB_CommanderBonusService extends TNB_Types;

static function bool QualifyingReward(int RewardID)
{
    local XComGameState_MissionSite Mission;
    local XComGameState_PointOfInterest POI;
    local XComGameState_CovertAction Action;
    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_MissionSite', Mission)
        if (Mission.Rewards.Find('ObjectID', RewardID) != INDEX_NONE) return true;
    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_PointOfInterest', POI)
        if (POI.RewardRefs.Find('ObjectID', RewardID) != INDEX_NONE) return true;
    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_CovertAction', Action)
        if (Action.RewardRefs.Find('ObjectID', RewardID) != INDEX_NONE) return true;
    return false;
}

static function int BonusAmount(int Original, int BasisPoints)
{
    if (Original <= 0 || Original > 10000000) return 0;
    BasisPoints = Clamp(BasisPoints, -10000, 100000);
    // Symmetric truncation toward zero, without overflowing Original * BasisPoints.
    return (Original / 10000) * BasisPoints + ((Original % 10000) * BasisPoints) / 10000;
}

static function int ApplyResource(XComGameState Change, XComGameState_Item Item, string Key)
{
    local XComGameState_TNBCampaignLink Link;
    local int Amount;
    if (Change == none || Item == none || Key == "" || Item.LastQuantityChange <= 0) return 0;
    Link = class'XComGameState_TNBCampaignLink'.static.Get(Change);
    if (Link == none || !Link.bOneTimeEffectsCommitted || Link.ResourceLedger.Find(Key) != INDEX_NONE) return 0;
    Amount = BonusAmount(Item.LastQuantityChange, Link.ResourcePercent(Item.GetMyTemplateName()));
    if (Amount == 0) return 0;
    Link = XComGameState_TNBCampaignLink(Change.ModifyStateObject(class'XComGameState_TNBCampaignLink', Link.ObjectID));
    Link.ResourceLedger.AddItem(Key);
    Item = XComGameState_Item(Change.ModifyStateObject(class'XComGameState_Item', Item.ObjectID));
    // Mutate the original transaction directly; do not call AddResource recursively.
    Amount = Clamp(Amount, -Item.LastQuantityChange, Max(0, 2000000000 - Item.Quantity));
    Item.Quantity += Amount; Item.LastQuantityChange += Amount;
    return Amount;
}

static function EventListenerReturn OnSupplyCollected(Object EventData, Object EventSource, XComGameState GameState, name EventID, Object CallbackData)
{
    local XComGameState_ResourceCache Cache;
    local XComGameState_HeadquartersResistance Resistance;
    local XComGameState_Item Resource;
    local XComGameState_TNBCampaignLink Link;
    local XComGameState_TNBCommanderRewards Receipt;
    local int Month, Original, Adjustment, BasisPoints;
    local string Key, SourceLabel;
    local ResolvedEffect Effect;
    local array<string> SourceNames;
    if (GameState == none) return ELR_NoInterrupt;
    foreach GameState.IterateByClassType(class'XComGameState_ResourceCache', Cache) break;
    if (Cache == none) return ELR_NoInterrupt; // never infer supply drops from Supplies alone
    Resistance = XComGameState_HeadquartersResistance(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance', true));
    Link = class'XComGameState_TNBCampaignLink'.static.Get(GameState);
    if (Resistance == none || Link == none || !Link.bOneTimeEffectsCommitted) return ELR_NoInterrupt;
    Month = Resistance.NumMonths;
    Key = "cache:" $ Month $ ":" $ Cache.NumScansCompleted;
    Receipt = class'XComGameState_TNBCommanderRewards'.static.Get(GameState);
    // Preserve the existing award key, including saves made before receipts existed.
    if (Link.ResourceLedger.Find(Key) != INDEX_NONE || (Receipt != none && Receipt.HasCollection(Link.CampaignID, Cache.ObjectID, Month, Key))) return ELR_NoInterrupt;
    foreach GameState.IterateByClassType(class'XComGameState_Item', Resource)
        if (Resource.GetMyTemplateName() == 'Supplies') break;
    if (Resource == none || Resource.GetMyTemplateName() != 'Supplies' || Resource.LastQuantityChange <= 0) return ELR_NoInterrupt;
    Original = Resource.LastQuantityChange;
    BasisPoints = Link.ResourcePercent('Supplies');
    if (BasisPoints == 0) return ELR_NoInterrupt;
    foreach Link.Effects(Effect)
        if (Effect.EffectKind == 'ResourcePercent' && Effect.Target == 'Supplies' && Effect.Status == "active" && Effect.Magnitude != 0) SourceNames.AddItem(Effect.SourceName);
    SourceLabel = class'TNB_CommanderRewardPresentation'.static.ResourceSources(SourceNames);
    Adjustment = ApplyResource(GameState, Resource, Key);
    Receipt = class'XComGameState_TNBCommanderRewards'.static.Edit(GameState);
    Receipt.RecordCollection(Link.CampaignID, Cache.ObjectID, Month, Cache.NumScansCompleted, Key, Original, Adjustment, BasisPoints, SourceLabel);
    // Native Update() captured the BASE reward before ResourceCacheSupplies.
    // Correct only its pending display field, never the cache's future rewards.
    Cache.AmountForFlyoverPopup = class'TNB_CommanderRewardPresentation'.static.CollectionFlyoverAmount(Cache.AmountForFlyoverPopup, Original, Adjustment);
    `log("TNB_COMMANDER supplies base=" $ Original $ " adjustment=" $ Adjustment $ " total=" $ (Original + Adjustment),, 'TheNameBeneath');
    return ELR_NoInterrupt;
}

// NumMonths increments AFTER PreEndOfMonth. Use the incoming month number so the
// saved ScroungerMonths entries retain the old collection-time numbering.
static function int IncomingMonth(int CompletedMonths)
{
    return CompletedMonths + 1;
}

static function bool ScroungerDue(bool bCommitted, bool bHasScrounger, array<int> AwardedMonths, int Month)
{
    return bCommitted && bHasScrounger && Month > 0 && AwardedMonths.Find(Month) == INDEX_NONE;
}

static function EventListenerReturn OnMonthEnd(Object EventData, Object EventSource, XComGameState GameState, name EventID, Object CallbackData)
{
    local XComGameState_HeadquartersResistance Resistance, PendingResistance;
    local XComGameState_HeadquartersXCom HQ;
    local XComGameState_Item BonusItem;
    local XComGameState_TNBCampaignLink Link;
    local X2ItemTemplate Template;
    local array<name> AvailableItems;
    local name ItemName;
    local int Month;
    if (GameState == none) return ELR_NoInterrupt;
    Resistance = XComGameState_HeadquartersResistance(EventData);
    if (Resistance == none) return ELR_NoInterrupt;
    foreach GameState.IterateByClassType(class'XComGameState_HeadquartersResistance', PendingResistance)
        if (PendingResistance.ObjectID == Resistance.ObjectID) break;
    if (PendingResistance == none || PendingResistance.ObjectID != Resistance.ObjectID) return ELR_NoInterrupt;
    Month = IncomingMonth(PendingResistance.NumMonths);
    Link = class'XComGameState_TNBCampaignLink'.static.Get(GameState);
    if (Link == none) return ELR_NoInterrupt;
    if (!ScroungerDue(Link.bOneTimeEffectsCommitted, Link.HasScrounger(), Link.ScroungerMonths, Month)) return ELR_NoInterrupt;
    foreach Link.FrozenScroungerItems(ItemName)
    {
        Template = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(ItemName);
        if (Template != none && !Template.bInfiniteItem) AvailableItems.AddItem(ItemName);
    }
    if (AvailableItems.Length == 0)
    {
        `log("TNB_COMMANDER Scrounger skipped: no eligible configured item template; month=" $ Month,, 'TheNameBeneath');
        return ELR_NoInterrupt;
    }
    HQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
    if (HQ == none) return ELR_NoInterrupt;
    HQ = XComGameState_HeadquartersXCom(GameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', HQ.ObjectID));
    Template = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(AvailableItems[`SYNC_RAND_STATIC(AvailableItems.Length)]);
    BonusItem = Template.CreateInstanceFromTemplate(GameState);
    // Use the native acquisition path: merge matching unmodified items while
    // respecting unique/modified templates. The low-level AddItem call never stacks.
    HQ.PutItemInInventory(GameState, BonusItem);
    Link = XComGameState_TNBCampaignLink(GameState.ModifyStateObject(class'XComGameState_TNBCampaignLink', Link.ObjectID));
    Link.ScroungerMonths.AddItem(Month);
    class'TNB_CommanderRewardPresentation'.static.QueueScrounger(GameState, Template.DataName, Month);
    `log("TNB_COMMANDER Scrounger granted month=" $ Month $ " item=" $ Template.DataName,, 'TheNameBeneath');
    return ELR_NoInterrupt;
}

static function InstallRewardHooks()
{
    local X2RewardTemplate Template;
    local TNB_ResourceRewardHook Hook;
    local array<name> Names;
    local name TemplateName;
    Names.AddItem('Reward_Supplies'); Names.AddItem('Reward_Intel');
    foreach Names(TemplateName)
    {
        Template = X2RewardTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(TemplateName));
        if (Template == none || Template.GiveRewardFn == none) continue;
        Hook = new class'TNB_ResourceRewardHook';
        Hook.Original = Template.GiveRewardFn;
        Template.GiveRewardFn = Hook.Give;
    }
}
