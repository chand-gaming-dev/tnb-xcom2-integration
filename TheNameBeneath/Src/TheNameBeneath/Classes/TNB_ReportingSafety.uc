// Background reporting only. Native event hooks still edit their supplied transaction.
class TNB_ReportingSafety extends Object;

// Pure policy, exercised by the offline SDK commandlet. Fail closed outside live play.
static function string PhaseBlockReason(bool bStrategy, bool bTactical, name Phase, bool bInPlay, bool bLoading, bool bLatent, bool bStatesAllowed, bool bStartState)
{
    if (bLoading) return "processing_load";
    if (bLatent) return "latent_submission";
    if (bStartState) return "start_state_pending";
    if (bTactical)
    {
        // In-play alone is insufficient: LoadTacticalGame sets it before unlocking history.
        if (!bInPlay || Left(Caps(string(Phase)), 10) != "TURNPHASE_") return "tactical_initializing_or_ending";
    }
    else if (!bStrategy) return "unsupported_ruleset";
    if (!bStatesAllowed) return "ruleset_rejecting_states";
    return "";
}

static function bool NeedsBaselines(bool bLedgerMissing, int MissingSoldiers)
{
    return bLedgerMissing || MissingSoldiers > 0;
}

static function bool RunChecks()
{
    local array<name> BlockedPhases;
    local name Phase;
    if (PhaseBlockReason(true, false, '', false, false, false, true, false) != "") return false;
    if (PhaseBlockReason(false, true, 'TurnPhase_UnitActions', true, false, false, true, false) != "") return false;
    if (PhaseBlockReason(false, true, 'TurnPhase_Begin', true, false, false, true, false) != "") return false;
    if (PhaseBlockReason(false, true, 'TurnPhase_End', true, false, false, true, false) != "") return false;
    if (PhaseBlockReason(false, true, 'TurnPhase_StartTimer', true, false, false, true, false) != "") return false;
    if (PhaseBlockReason(false, true, 'TurnPhase_WaitForTutorialInput', true, false, false, true, false) != "") return false;
    BlockedPhases.AddItem('CreateTacticalGame');
    BlockedPhases.AddItem('LoadTacticalGame');
    BlockedPhases.AddItem('PostCreateTacticalGame');
    BlockedPhases.AddItem('CreateChallengeGame');
    BlockedPhases.AddItem('EndTacticalGame');
    BlockedPhases.AddItem('PerformingReplay');
    BlockedPhases.AddItem('UnknownFuturePhase');
    BlockedPhases.AddItem('');
    foreach BlockedPhases(Phase)
        if (PhaseBlockReason(false, true, Phase, true, false, false, true, false) != "tactical_initializing_or_ending") return false;
    if (PhaseBlockReason(false, true, 'TurnPhase_UnitActions', false, false, false, true, false) != "tactical_initializing_or_ending") return false;
    if (PhaseBlockReason(true, false, '', false, true, false, true, false) != "processing_load") return false;
    if (PhaseBlockReason(false, true, 'TurnPhase_UnitActions', true, true, false, true, false) != "processing_load") return false;
    if (PhaseBlockReason(true, false, '', false, false, true, true, false) != "latent_submission") return false;
    if (PhaseBlockReason(false, true, 'TurnPhase_UnitActions', true, false, true, true, false) != "latent_submission") return false;
    if (PhaseBlockReason(true, false, '', false, false, false, false, false) != "ruleset_rejecting_states") return false;
    if (PhaseBlockReason(false, true, 'TurnPhase_UnitActions', true, false, false, false, false) != "ruleset_rejecting_states") return false;
    if (PhaseBlockReason(true, false, '', false, false, false, true, true) != "start_state_pending") return false;
    if (PhaseBlockReason(false, true, 'TurnPhase_UnitActions', true, false, false, true, true) != "start_state_pending") return false;
    if (PhaseBlockReason(false, false, '', false, false, false, true, false) != "unsupported_ruleset") return false;
    if (!NeedsBaselines(true, 0) || !NeedsBaselines(true, 1) || !NeedsBaselines(false, 1) || NeedsBaselines(false, 0)) return false;
    return true;
}

static function string BlockReason(WorldInfo World, XComGameStateHistory ExpectedHistory)
{
    local XComGameInfo Game;
    local X2GameRuleset Rules;
    local X2TacticalGameRuleset Tactical;
    local bool bInPlay;
    local string Reason;
    if (World == none || World != class'WorldInfo'.static.GetWorldInfo()) return "world_unavailable";
    if (!World.bBegunPlay) return "world_not_started";
    if (World.NextURL != "" || World.IsInSeamlessTravel() || World.IsPreparingMapChange()) return "world_travel";
    if (ExpectedHistory == none || ExpectedHistory != `XCOMHISTORY) return "history_changed";
    Game = XComGameInfo(World.Game);
    if (Game == none || Game.GameRuleset == none) return "ruleset_unavailable";
    Rules = Game.GameRuleset;
    Tactical = X2TacticalGameRuleset(Rules);
    if (Tactical != none) bInPlay = Tactical.TacticalGameIsInPlay();
    // Do not call the tactical AddNewStatesAllowed override until its GRI exists.
    Reason = PhaseBlockReason(X2StrategyGameRuleset(Rules) != none, Tactical != none, Rules.GetStateName(), bInPlay,
        Rules.bProcessingLoad, Rules.BuildingLatentGameState || Rules.IsDoingLatentSubmission(), true, ExpectedHistory.GetStartState() != none);
    if (Reason != "") return Reason;
    if (Tactical != none && XComTacticalGRI(World.GRI) == none) return "tactical_gri_unavailable";
    if (!Rules.AddNewStatesAllowed()) return "ruleset_rejecting_states";
    return "";
}

// No credentials, Journey/character IDs, event bodies, soldier names or network payloads.
static function Trace(string Step, optional XComGameState Pending)
{
    local WorldInfo World;
    local XComGameInfo Game;
    local X2GameRuleset Rules;
    local X2TacticalGameRuleset Tactical;
    local string Context;
    World = class'WorldInfo'.static.GetWorldInfo();
    if (World != none)
    {
        Context = " world=" $ World.Name;
        Game = XComGameInfo(World.Game);
    }
    if (Game != none) Rules = Game.GameRuleset;
    if (Rules != none)
    {
        Context $= " rules=" $ Rules.Class.Name $ " phase=" $ Rules.GetStateName() $ " load=" $ Rules.bProcessingLoad $ " latent=" $ Rules.BuildingLatentGameState;
        Tactical = X2TacticalGameRuleset(Rules);
        if (Tactical != none) Context $= " in_play=" $ Tactical.TacticalGameIsInPlay();
    }
    if (`XCOMHISTORY != none) Context $= " history=" $ `XCOMHISTORY.GetCurrentHistoryIndex();
    if (Pending != none) Context $= " pending=" $ Pending.Name $ " objects=" $ Pending.GetNumGameStateObjects();
    `log("TNB_REPORT " $ Step $ Context,, 'TheNameBeneath');
}
