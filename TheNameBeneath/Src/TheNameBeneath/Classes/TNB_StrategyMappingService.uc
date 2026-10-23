// Frozen mapping policy. Query hooks change only their supplied tuple, never history.
class TNB_StrategyMappingService extends TNB_Types dependson(XComGameState_TNBCampaignLink, X2StrategyGameRulesetDataStructures);

// Only a short-lived listener during first association's synchronous project refresh.
// Not a saved state, actor, timer, persistent singleton or queued callback.
var private XComGameState_TNBCampaignLink AssociationScienceLink;

static function int ActiveTotal(array<ResolvedEffect> Effects, name Kind, name Target)
{
    local ResolvedEffect Effect;
    local int Total;
    foreach Effects(Effect)
        if (Effect.Status == "active" && Effect.EffectKind == Kind && Effect.Target == Target)
            Total += Effect.Magnitude;
    return Clamp(Total, -100000, 100000);
}

// Duration adjustments add, then convert to the native work-per-hour multiplier.
// The floor protects player overrides from zero/negative duration and division by zero.
static function float RecoveryRate(int DurationBasisPoints)
{
    return 10000.0 / float(Max(100, 10000 + DurationBasisPoints));
}

static function int ResearchScore(int Score, bool ProgressScore, int SpeedBasisPoints)
{
    if (!ProgressScore || Score <= 0) return Score;
    return Max(0, Round(float(Score) * (1.0 + float(Clamp(SpeedBasisPoints, -10000, 100000)) / 10000.0)));
}

static function ApplyScience(XComLWTuple Tuple, XComGameState_TNBCampaignLink Link)
{
    if (Tuple == none || Link == none || !Link.bOneTimeEffectsCommitted || Tuple.Id != 'OverrideScienceScore' || Tuple.Data.Length != 2 || Tuple.Data[0].kind != XComLWTVInt || Tuple.Data[1].kind != XComLWTVBool) return;
    Tuple.Data[0].i = ResearchScore(Tuple.Data[0].i, Tuple.Data[1].b, ActiveTotal(Link.Effects, 'ResearchSpeed', 'Science'));
}

function EventListenerReturn AssociationScience(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
    if (XComGameState_HeadquartersXCom(EventSource) != none) ApplyScience(XComLWTuple(EventData), AssociationScienceLink);
    return ELR_NoInterrupt;
}

static function RefreshAssociationProjects(XComGameState Pending, XComGameState_HeadquartersXCom HQ, XComGameState_TNBCampaignLink Link)
{
    local TNB_StrategyMappingService Scope;
    local Object Listener;
    // Native research reads HQ/score without passing Pending. During this first
    // association only, supply the not-yet-committed frozen score to that query.
    // The permanent listener sees no historical campaign link until commit.
    Scope = new class'TNB_StrategyMappingService';
    Scope.AssociationScienceLink = Link; Listener = Scope;
    `XEVENTMGR.RegisterForEvent(Listener, 'OverrideScienceScore', Scope.AssociationScience, ELD_Immediate, 0);
    HQ.HandlePowerOrStaffingChange(Pending);
    `XEVENTMGR.UnRegisterFromEvent(Listener, 'OverrideScienceScore');
    Scope.AssociationScienceLink = none;
}

static function bool RiskTarget(name Target)
{
    return Target == 'CovertActionRisk_Ambush' || Target == 'CovertActionRisk_SoldierWounded' || Target == 'CovertActionRisk_SoldierCaptured';
}

static function XComGameState_TNBSoldierLink SoldierLink(int UnitID, optional XComGameState Pending)
{
    local XComGameState_TNBSoldierLink Link;
    local XComGameState_Unit Unit;
    if (UnitID <= 0) return none;
    if (Pending != none)
        foreach Pending.IterateByClassType(class'XComGameState_TNBSoldierLink', Link)
            if (Link.UnitRef.ObjectID == UnitID && Link.SchemaVersion == 1 && Link.bEffectsCommitted) return Link;
    Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitID));
    return class'XComGameState_TNBSoldierLink'.static.ForUnit(Unit);
}

static function RefreshRiskCache(XComGameState Pending)
{
    local XComGameState_CovertAction Action;
    local array<int> IDs;
    local int ID;
    // Snapshot IDs before modifying the pending container during iteration.
    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_CovertAction', Action)
        if (!Action.bCompleted) IDs.AddItem(Action.ObjectID);
    foreach IDs(ID)
    {
        Action = XComGameState_CovertAction(Pending.ModifyStateObject(class'XComGameState_CovertAction', ID));
        Action.RecalculateRiskChanceToOccurModifiers();
    }
}

static function RefreshSoldierRecovery(XComGameState Pending, int UnitID)
{
    local XComGameState_HeadquartersProjectHealSoldier Project;
    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_HeadquartersProjectHealSoldier', Project)
        if (Project.ProjectFocus.ObjectID == UnitID)
        {
            Project = XComGameState_HeadquartersProjectHealSoldier(Pending.ModifyStateObject(Project.Class, Project.ObjectID));
            Project.OnPowerStateOrStaffingChange();
            return;
        }
}

static function int TakeRecipient(out array<int> Candidates, int Roll)
{
    local int ID, Index;
    if (Candidates.Length == 0) return 0;
    Index = Clamp(Roll, 0, Candidates.Length - 1);
    ID = Candidates[Index];
    Candidates.Remove(Index, 1);
    return ID;
}

static function int NextIntelligence(int Current)
{
    local ECombatIntelligence Cap;
    Cap = eComInt_Savant;
    return Clamp(Current + 1, 0, int(Cap));
}

static function GrantRosterIntelligence(XComGameState Pending, XComGameState_HeadquartersXCom HQ, XComGameState_TNBCampaignLink Link, out ResolvedEffect Effect)
{
    local StateObjectReference Ref;
    local array<StateObjectReference> Crew;
    local XComGameState_Unit Unit;
    local array<int> Candidates;
    local int ID;
    local XComGameState_TNBCampaignLink.IntelligenceGrant Receipt;
    local string Description;
    Crew = HQ.Crew;
    foreach Crew(Ref)
    {
        Unit = XComGameState_Unit(Pending.GetGameStateForObjectID(Ref.ObjectID));
        if (Unit == none) Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
        if (Unit != none && Unit.IsSoldier() && !Unit.IsDead() && !Unit.bCaptured && !Unit.IsOnCovertAction() && Unit.ComInt < eComInt_Savant && Candidates.Find(Unit.ObjectID) == INDEX_NONE) Candidates.AddItem(Unit.ObjectID);
    }
    while (Candidates.Length > 0 && Effect.AppliedMagnitude < Effect.Magnitude)
    {
        ID = TakeRecipient(Candidates, `SYNC_RAND_STATIC(Candidates.Length));
        Unit = XComGameState_Unit(Pending.ModifyStateObject(class'XComGameState_Unit', ID));
        Receipt.MappingKey = Effect.MappingKey; Receipt.UnitRef = Unit.GetReference();
        Receipt.SoldierName = Unit.GetName(eNameType_Full); Receipt.BeforeTier = int(Unit.ComInt);
        Description = Receipt.SoldierName $ ": " $ Unit.GetCombatIntelligenceLabel() $ " -> ";
        // Do not use ImproveCombatIntelligence: it awards retroactive AP.
        Unit.ComInt = ECombatIntelligence(NextIntelligence(int(Unit.ComInt)));
        Receipt.AfterTier = int(Unit.ComInt);
        Link.IntelligenceGrants.AddItem(Receipt);
        Effect.Note $= (Effect.AppliedMagnitude == 0 ? " Recipients: " : "; ") $ Description $ Unit.GetCombatIntelligenceLabel();
        Effect.AppliedMagnitude++;
    }
    Effect.Status = Effect.AppliedMagnitude > 0 ? "applied" : "no_eligible_change";
    if (Effect.AppliedMagnitude == 0) Effect.Note = "No eligible barracks soldiers below Savant. Not deferred; no replacement reward.";
}
