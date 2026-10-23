class TNB_CampaignService extends TNB_Types;

// Pure reminder policy; presentation readiness is supplied by the Avenger actor.
static function bool ShouldOfferReminder(bool Associated, bool Suppressed, bool OfferedThisSession, bool Quiet, bool CompanionReady)
{
    return !Associated && !Suppressed && !OfferedThisSession && Quiet && CompanionReady;
}

static function string CampaignID()
{
    local XComGameState_CampaignSettings Settings;
    Settings = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
    return (Settings == none) ? "" : Settings.BizAnalyticsCampaignID;
}

static function int PendingResource(XComGameState Change, XComGameState_HeadquartersXCom HQ, name Target)
{
    local StateObjectReference Ref;
    local XComGameState_Item Item;
    foreach HQ.Inventory(Ref)
    {
        Item = XComGameState_Item(Change.GetGameStateForObjectID(Ref.ObjectID));
        if (Item == none) Item = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
        if (Item != none && Item.GetMyTemplateName() == Target) return Item.Quantity;
    }
    return 0;
}

static function int PendingDoom(XComGameState Change, XComGameState_HeadquartersAlien Alien)
{
    local XComGameState_MissionSite Site, PendingSite;
    local int Total;
    Total = Alien.Doom;
    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_MissionSite', Site)
    {
        PendingSite = XComGameState_MissionSite(Change.GetGameStateForObjectID(Site.ObjectID));
        if (PendingSite == none) PendingSite = Site;
        if (!PendingSite.bRemoved && PendingSite.Available) Total += PendingSite.Doom;
    }
    return Total;
}

static function bool Associate(JourneyContext Journey, out string ErrorCode)
{
    local XComGameState Change;
    local XComGameState_TNBCampaignLink Link;
    local XComGameState_HeadquartersXCom HQ;
    local XComGameState_HeadquartersAlien Alien;
    local XComGameState_HeadquartersResistance Resistance;
    local XComGameState_Unit Staff;
    local XComGameState_MissionSite Site, ChosenSite;
    local array<TNB_Types.ResolvedEffect> Effects;
    local int Index, Count, Before, Actual;
    local name ItemName;
    local X2ItemTemplate Item;

    ErrorCode = "association_precondition_failed";
    if (`HQPRES == none || `HQGAME == none || CampaignID() == "" || Journey.JourneyStatus != "started" || !Journey.bCharacteristicsAvailable) return false;
    Link = class'XComGameState_TNBCampaignLink'.static.Get();
    if (Link != none) return Link.SchemaVersion == 1 && Link.CampaignID == CampaignID() && Link.Journey.JourneyID == Journey.JourneyID && Link.Journey.CommanderID == Journey.CommanderID && Link.bOneTimeEffectsCommitted;
    HQ = class'UIUtilities_Strategy'.static.GetXComHQ();
    if (HQ == none) return false;
    Effects = class'TNB_MappingResolver'.static.Resolve('Commander', Journey.Traits, Journey.Skills);
    if (Effects.Length > 512) return false;
    Change = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("The Name Beneath: associate campaign and apply one-time commander effects");
    Link = XComGameState_TNBCampaignLink(Change.CreateNewStateObject(class'XComGameState_TNBCampaignLink'));
    Link.SchemaVersion = 1; Link.CampaignID = CampaignID(); Link.Journey = Journey;
    Link.MappingRevision = class'TNB_MappingConfig'.default.MappingRevision;
    HQ = XComGameState_HeadquartersXCom(Change.ModifyStateObject(class'XComGameState_HeadquartersXCom', HQ.ObjectID));
    foreach class'TNB_MappingConfig'.default.ScroungerItems(ItemName)
    {
        Item = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(ItemName);
        if (Item != none && !Item.bInfiniteItem && Link.FrozenScroungerItems.Find(ItemName) == INDEX_NONE) Link.FrozenScroungerItems.AddItem(ItemName);
    }
    for (Index = 0; Index < Effects.Length; Index++)
    {
        if (Effects[Index].Status != "resolved") continue;
        if (Effects[Index].EffectKind == 'ResourcePercent' || Effects[Index].EffectKind == 'CovertRisk' || Effects[Index].EffectKind == 'RecoveryDuration' || Effects[Index].EffectKind == 'ResearchSpeed') Effects[Index].Status = "active";
        else if (Effects[Index].EffectKind == 'SupplyDropItem')
        {
            Effects[Index].Status = (Link.FrozenScroungerItems.Length > 0) ? "active" : "skipped";
            if (Link.FrozenScroungerItems.Length == 0) Effects[Index].Note = "No configured common-item templates are installed.";
        }
        else if (Effects[Index].EffectKind == 'ContactOnce')
        {
            HQ.BonusCommCapacity += Effects[Index].Magnitude;
            Effects[Index].AppliedMagnitude = Effects[Index].Magnitude;
            Effects[Index].Status = "applied";
        }
        else if (Effects[Index].EffectKind == 'RosterIntelligenceOnce')
            class'TNB_StrategyMappingService'.static.GrantRosterIntelligence(Change, HQ, Link, Effects[Index]);
        else if (Effects[Index].EffectKind == 'CovertDurationOnce')
        {
            Resistance = XComGameState_HeadquartersResistance(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance', true));
            if (Resistance == none) { `XCOMHISTORY.CleanupPendingGameState(Change); ErrorCode = "resistance_hq_missing"; return false; }
            Resistance = XComGameState_HeadquartersResistance(Change.ModifyStateObject(class'XComGameState_HeadquartersResistance', Resistance.ObjectID));
            Resistance.AddCovertActionModifier(Change, 1.0 + float(Effects[Index].Magnitude) / 10000.0);
            Effects[Index].AppliedMagnitude = Effects[Index].Magnitude;
            Effects[Index].Status = "applied";
        }
        else if (Effects[Index].EffectKind == 'ResourceOnce')
        {
            Before = PendingResource(Change, HQ, Effects[Index].Target);
            HQ.AddResource(Change, Effects[Index].Target, Effects[Index].Magnitude);
            Effects[Index].AppliedMagnitude = PendingResource(Change, HQ, Effects[Index].Target) - Before;
            Effects[Index].Status = "applied";
        }
        else if (Effects[Index].EffectKind == 'StaffOnce')
        {
            if (class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate(Effects[Index].Target) == none)
            {
                `XCOMHISTORY.CleanupPendingGameState(Change); ErrorCode = "staff_template_missing"; return false;
            }
            for (Count = 0; Count < Effects[Index].Magnitude; Count++)
            {
                Staff = class'X2StrategyElement_DefaultRewards'.static.CreatePersonnelUnit(Change, Effects[Index].Target, '');
                if (Staff == none) { `XCOMHISTORY.CleanupPendingGameState(Change); ErrorCode = "staff_creation_failed"; return false; }
                HQ.AddToCrew(Change, Staff);
            }
            Effects[Index].Status = "applied"; Effects[Index].AppliedMagnitude = Count;
        }
        else if (Effects[Index].EffectKind == 'AvatarOnce')
        {
            Alien = XComGameState_HeadquartersAlien(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien', true));
            if (Alien == none) { `XCOMHISTORY.CleanupPendingGameState(Change); ErrorCode = "alien_hq_missing"; return false; }
            Alien = XComGameState_HeadquartersAlien(Change.ModifyStateObject(class'XComGameState_HeadquartersAlien', Alien.ObjectID));
            Actual = 0;
            if (Effects[Index].Magnitude > 0)
            {
                Actual = Min(Effects[Index].Magnitude, Max(0, Alien.GetMaxDoom() - PendingDoom(Change, Alien)));
                Alien.ModifyDoom(Actual);
            }
            else if (Effects[Index].Magnitude < 0)
            {
                // Eligible pips: global progress first, then progress on available facilities only.
                Count = -Effects[Index].Magnitude;
                Before = Min(Count, Alien.Doom); Alien.ModifyDoom(-Before); Count -= Before; Actual -= Before;
                foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_MissionSite', Site)
                    if (Count > 0 && Site.Available && Site.Doom > 0)
                    {
                        ChosenSite = XComGameState_MissionSite(Change.ModifyStateObject(class'XComGameState_MissionSite', Site.ObjectID));
                        Before = Min(Count, ChosenSite.Doom); ChosenSite.Doom -= Before; Count -= Before; Actual -= Before;
                    }
            }
            Effects[Index].AppliedMagnitude = Actual;
            Effects[Index].Status = (Actual == 0) ? "no_eligible_change" : "applied";
            if (Actual != Effects[Index].Magnitude) Effects[Index].Note = "Actual Avatar change: " $ Actual $ "; clamped to eligible progress/capacity. Not deferred or repeated.";
        }
    }
    Link.Effects = Effects; Link.bOneTimeEffectsCommitted = true;
    class'TNB_StrategyMappingService'.static.RefreshAssociationProjects(Change, HQ, Link);
    // One existing association transaction, no UI timer or independent history write.
    if (class'TNB_StrategyMappingService'.static.ActiveTotal(Effects, 'CovertRisk', 'CovertActionRisk_Ambush') != 0 || class'TNB_StrategyMappingService'.static.ActiveTotal(Effects, 'CovertRisk', 'CovertActionRisk_SoldierWounded') != 0 || class'TNB_StrategyMappingService'.static.ActiveTotal(Effects, 'CovertRisk', 'CovertActionRisk_SoldierCaptured') != 0)
        class'TNB_StrategyMappingService'.static.RefreshRiskCache(Change);
    `XCOMGAME.GameRuleset.SubmitGameState(Change);
    Link = class'XComGameState_TNBCampaignLink'.static.Get();
    if (Link == none || !Link.bOneTimeEffectsCommitted) { ErrorCode = "association_commit_failed"; return false; }
    ErrorCode = "";
    return true;
}
