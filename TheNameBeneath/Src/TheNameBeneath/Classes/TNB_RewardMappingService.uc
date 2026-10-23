// Reward attribution uses the retained launch/assignment roster, never all barracks.
class TNB_RewardMappingService extends TNB_Types dependson(TNB_EventTypes, XComGameState_TNBCampaignLink);

static function bool RewardOwner(int RewardID, XComGameState Pending, out int OwnerID, out string Kind)
{
    local XComGameState_MissionSite Site, PendingSite;
    local XComGameState_CovertAction Action, PendingAction;
    local XComGameState_PointOfInterest POI;
    if (Pending == none || RewardID <= 0) return false;
    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_CovertAction', Action)
    {
        PendingAction = XComGameState_CovertAction(Pending.GetGameStateForObjectID(Action.ObjectID));
        if (PendingAction == none) PendingAction = Action;
        if (PendingAction.RewardRefs.Find('ObjectID', RewardID) != INDEX_NONE)
        { OwnerID = Action.ObjectID; Kind = "covert_action"; return true; }
    }
    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_MissionSite', Site)
    {
        PendingSite = XComGameState_MissionSite(Pending.GetGameStateForObjectID(Site.ObjectID));
        if (PendingSite == none) PendingSite = Site;
        if (PendingSite.Rewards.Find('ObjectID', RewardID) != INDEX_NONE)
        { OwnerID = Site.ObjectID; Kind = "tactical"; return true; }
    }
    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_PointOfInterest', POI)
        if (POI.RewardRefs.Find('ObjectID', RewardID) != INDEX_NONE)
        { OwnerID = POI.ObjectID; Kind = "poi"; return true; }
    return false;
}

static function int RosterIndex(array<TNB_EventTypes.MissionObservation> Missions, int OwnerID, string Kind)
{
    local int Index;
    if (OwnerID <= 0 || (Kind != "tactical" && Kind != "covert_action")) return INDEX_NONE;
    // Mission-site IDs can have several replay attempts; the latest retained one
    // owns the current reward. POIs/scans can never acquire soldier attribution.
    for (Index = Missions.Length - 1; Index >= 0; Index--)
        if (Missions[Index].ObjectID == OwnerID && Missions[Index].Kind == Kind && Missions[Index].bStarted) return Index;
    return INDEX_NONE;
}

static function int ParticipantPercent(XComGameState Pending, int OwnerID, string Kind, name Resource, out array<string> Sources)
{
    local XComGameState_TNBCampaignLink Campaign;
    local XComGameState_TNBEventLedger Ledger;
    local XComGameState_TNBSoldierLink Soldier;
    local array<int> Seen;
    local array<int> UnitIDs;
    local int Index, UnitID, Total;
    local ResolvedEffect Effect;
    Campaign = class'XComGameState_TNBCampaignLink'.static.Get(Pending);
    Ledger = class'XComGameState_TNBEventLedger'.static.Get(Pending);
    if (Campaign == none || Ledger == none || Ledger.CampaignID != Campaign.CampaignID || Ledger.JourneyID != Campaign.Journey.JourneyID) return 0;
    Index = RosterIndex(Ledger.Missions, OwnerID, Kind);
    if (Index == INDEX_NONE) return 0;
    UnitIDs = Ledger.Missions[Index].UnitIDs;
    foreach UnitIDs(UnitID)
    {
        if (Seen.Find(UnitID) != INDEX_NONE) continue;
        Seen.AddItem(UnitID);
        Soldier = class'TNB_StrategyMappingService'.static.SoldierLink(UnitID, Pending);
        if (!ParticipantMatches(Soldier, Campaign, Ledger.Missions[Index])) continue;
        foreach Soldier.Effects(Effect)
            if (Effect.Status == "active" && Effect.EffectKind == 'ParticipantResource' && Effect.Target == Resource)
            {
                Total += Effect.Magnitude;
                Sources.AddItem(Soldier.Snapshot.CharacterName $ ": " $ Effect.SourceName $ " " $ class'TNB_EffectPresentation'.static.Percentage(Effect.Magnitude));
            }
    }
    return Total;
}

static function bool ParticipantMatches(XComGameState_TNBSoldierLink Soldier, XComGameState_TNBCampaignLink Campaign, TNB_EventTypes.MissionObservation Mission)
{
    return Soldier != none && Campaign != none && Soldier.bEffectsCommitted && Soldier.CampaignID == Campaign.CampaignID && Soldier.Snapshot.JourneyID == Campaign.Journey.JourneyID && Mission.UnitIDs.Find(Soldier.UnitRef.ObjectID) != INDEX_NONE && Mission.Instances.Find(Soldier.Snapshot.InstanceID) != INDEX_NONE;
}

static function string SourceLabel(array<string> Sources)
{
    local string Source, Result;
    foreach Sources(Source)
    {
        if (Result != "") Result $= " / ";
        Result $= EscapeUI(SingleLine(Source));
    }
    return Result;
}

static function Record(XComGameState Pending, string Key, int RewardID, name Resource, int Original, int Adjustment, int BasisPoints, string Sources)
{
    local XComGameState_TNBCampaignLink Link;
    local XComGameState_TNBCampaignLink.ResourceAdjustment Receipt;
    Link = class'XComGameState_TNBCampaignLink'.static.Get(Pending);
    if (Link == none || Link.RewardAdjustments.Find('Key', Key) != INDEX_NONE) return;
    Link = XComGameState_TNBCampaignLink(Pending.ModifyStateObject(class'XComGameState_TNBCampaignLink', Link.ObjectID));
    if (Link.ResourceLedger.Find(Key) == INDEX_NONE) Link.ResourceLedger.AddItem(Key);
    Receipt.Key = Key; Receipt.RewardID = RewardID; Receipt.Resource = Resource;
    Receipt.Original = Original; Receipt.Adjustment = Adjustment; Receipt.BasisPoints = BasisPoints; Receipt.Sources = Sources;
    Link.RewardAdjustments.AddItem(Receipt);
}

static function string AdjustmentText(array<XComGameState_TNBCampaignLink.ResourceAdjustment> Receipts, int RewardID, string NativeText, string ResourceLabel)
{
    local XComGameState_TNBCampaignLink.ResourceAdjustment Receipt;
    local int Original, Adjustment;
    local string Sources;
    foreach Receipts(Receipt)
        if (Receipt.RewardID == RewardID)
        {
            Original += Receipt.Original; Adjustment += Receipt.Adjustment;
            if (Sources == "") Sources = Receipt.Sources;
        }
    if (Original <= 0) return NativeText;
    return string(Original + Adjustment) @ ResourceLabel $ " (base: " $ NativeText $ "; The Name Beneath: " $ class'TNB_EffectPresentation'.static.Signed(Adjustment) $ "; " $ Sources $ ")";
}

static function string RewardText(XComGameState_Reward Reward, string NativeText)
{
    local XComGameState_TNBCampaignLink Link;
    Link = class'XComGameState_TNBCampaignLink'.static.Get();
    if (Link == none) return NativeText;
    return AdjustmentText(Link.RewardAdjustments, Reward.ObjectID, NativeText, Reward.GetMyTemplate().DisplayName);
}
