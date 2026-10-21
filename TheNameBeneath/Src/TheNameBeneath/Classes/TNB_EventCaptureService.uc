class TNB_EventCaptureService extends TNB_EventTypes;

static function LinkedBaseline(XComGameState Pending, XComGameState_Unit Soldier, XComGameState_TNBSoldierLink Link)
{
    local XComGameState_TNBEventLedger Ledger;
    local SoldierObservation Observation;
    Ledger = class'XComGameState_TNBEventLedger'.static.Edit(Pending);
    if (Ledger != none && class'TNB_SoldierConditionObserver'.static.Snapshot(Soldier, Observation, Link))
        class'TNB_SoldierConditionObserver'.static.Observe(Pending, Ledger, Observation, true);
    class'TNB_CaptivityCaptureService'.static.Observe(Pending, Ledger, Soldier,,, true, Link);
}

static function CarryToStartState(XComGameState Pending)
{
    local XComGameState_TNBCampaignLink Campaign;
    local XComGameState_TNBSoldierLink SoldierLink;
    local XComGameState_TNBEventLedger Ledger;
    local XComGameState_TNBEventOutbox Outbox;
    Campaign = class'XComGameState_TNBCampaignLink'.static.Get();
    if (Campaign == none) return;
    if (Pending.GetGameStateForObjectID(Campaign.ObjectID) == none) Pending.ModifyStateObject(class'XComGameState_TNBCampaignLink', Campaign.ObjectID);
    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_TNBSoldierLink', SoldierLink)
        if (Pending.GetGameStateForObjectID(SoldierLink.ObjectID) == none) Pending.ModifyStateObject(class'XComGameState_TNBSoldierLink', SoldierLink.ObjectID);
    Ledger = class'XComGameState_TNBEventLedger'.static.Get();
    if (Ledger != none && Pending.GetGameStateForObjectID(Ledger.ObjectID) == none) Pending.ModifyStateObject(class'XComGameState_TNBEventLedger', Ledger.ObjectID);
    Outbox = class'XComGameState_TNBEventOutbox'.static.Get();
    if (Outbox != none && Pending.GetGameStateForObjectID(Outbox.ObjectID) == none) Pending.ModifyStateObject(class'XComGameState_TNBEventOutbox', Outbox.ObjectID);
}

static function XComGameState_Unit Unit(int UnitID, optional XComGameState Pending)
{
    local XComGameState_Unit Result;
    if (Pending != none) Result = XComGameState_Unit(Pending.GetGameStateForObjectID(UnitID));
    if (Result == none) Result = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitID));
    return Result;
}

static function string DateKey(TDateTime Value)
{
    return Value.m_iYear $ ":" $ Value.m_iMonth $ ":" $ Value.m_iDay $ ":" $ int(Value.m_fTime);
}

static function string TacticalKey(XComGameState_MissionSite Site)
{
    if (Site == none) return "";
    // Source + saved creation timer + level seed disambiguates reused ObjectIDs.
    return "tactical:" $ Site.ObjectID $ ":" $ Site.Source $ ":" $ DateKey(Site.TimerStartDateTime) $ ":seed:" $ Site.GeneratedMission.LevelSeed;
}

static function string CovertKey(XComGameState_CovertAction Action)
{
    return "covert:" $ Action.ObjectID $ ":" $ Action.GetMyTemplateName() $ ":" $ DateKey(Action.StartDateTime);
}

static function AddSoldier(out MissionObservation Mission, int UnitID, XComGameState Pending)
{
    local XComGameState_Unit Soldier;
    local XComGameState_TNBSoldierLink Link;
    local XComGameState_TNBCampaignLink Campaign;
    Soldier = Unit(UnitID, Pending);
    if (Soldier == none || !Soldier.IsSoldier() || Mission.UnitIDs.Find(UnitID) != INDEX_NONE) return;
    Mission.UnitIDs.AddItem(UnitID);
    Link = class'XComGameState_TNBSoldierLink'.static.ForUnit(Soldier);
    Campaign = class'XComGameState_TNBCampaignLink'.static.Get(Pending);
    if (Link != none && Campaign != none && Link.CampaignID == Campaign.CampaignID && Link.Snapshot.JourneyID == Campaign.Journey.JourneyID && Mission.Instances.Find(Link.Snapshot.InstanceID) == INDEX_NONE)
        Mission.Instances.AddItem(Link.Snapshot.InstanceID);
}

static function PrepareMission(XComGameState Pending, XComGameState_MissionSite Site)
{
    local XComGameState_TNBEventLedger Ledger;
    local XComGameState_HeadquartersXCom HQ;
    local XComGameState_CovertAction Action;
    local XComGameState_BattleData LaunchBattle;
    local XComGameStateContext_TacticalGameRule LaunchContext;
    local TacticalMissionAttempt Attempt;
    local MissionObservation Mission;
    local SoldierObservation Observation;
    local StateObjectReference Ref;
    local int Index, Count, ActionIndex, AttemptCreated;
    local bool bRosterMatches;
    Ledger = class'XComGameState_TNBEventLedger'.static.Edit(Pending);
    if (Ledger == none || Site == none) return;
    // Unsupported/invalid fresh launch must not inherit a previous attempt pointer.
    // Tactical reload/transfer never enters this function.
    Ledger.CurrentTacticalKey = "";
    Ledger.CurrentBattleMissionID = 0;
    // A fresh XCOM tactical start state already owns a newly generated launch GUID.
    // Read it once; never replace native mission data or derive identity from seeded Rand.
    LaunchContext = XComGameStateContext_TacticalGameRule(Pending.GetContext());
    if (LaunchContext == none || LaunchContext.GameRuleType != eGameRule_TacticalGameStart)
    { Ledger.Diagnostic = "mission_attempt_missing_launch_context"; return; }
    foreach Pending.IterateByClassType(class'XComGameState_BattleData', LaunchBattle) break;
    if (LaunchBattle == none)
    { Ledger.Diagnostic = "mission_attempt_missing_battle_data"; return; }
    if (!class'TNB_MissionAttemptService'.static.Resolve(Ledger.TacticalAttempts, TacticalKey(Site), LaunchBattle.BizAnalyticsMissionID, Attempt, AttemptCreated))
    { Ledger.Diagnostic = "mission_attempt_identity_unavailable: invalid launch GUID, conflicting context or capacity"; return; }
    if (InStr(Ledger.Diagnostic, "mission_attempt_") == 0) Ledger.Diagnostic = "";
    Mission.Key = Attempt.Key;
    class'TNB_ReportingSafety'.static.Trace("MISSION_ATTEMPT prepared new=" $ AttemptCreated $ " attempt=" $ Left(Attempt.AttemptID, 8), Pending);
    Index = Ledger.Missions.Find('Key', Mission.Key);
    Ledger.CurrentTacticalKey = Mission.Key;
    Ledger.CurrentBattleMissionID = Site.ObjectID;
    if (Index != INDEX_NONE) return;
    Mission.ObjectID = Site.ObjectID; Mission.Source = Site.Source; Mission.Kind = "tactical";
    Mission.Label = class'TNB_EventFactory'.static.SafeText(Site.GeneratedMission.BattleOpName);
    HQ = XComGameState_HeadquartersXCom(Pending.GetGameStateForObjectID(`XCOMHQ.ObjectID));
    if (HQ == none) HQ = `XCOMHQ;
    foreach HQ.Squad(Ref) AddSoldier(Mission, Ref.ObjectID, Pending);
    // A child ambush must match one actual parent AND its frozen assigned roster.
    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_CovertAction', Action)
    {
        if (!Action.bAmbushed || Action.AmbushMissionSource != Site.Source) continue;
        Count++;
        ActionIndex = Ledger.Missions.Find('Key', CovertKey(Action));
        bRosterMatches = ActionIndex != INDEX_NONE && Mission.UnitIDs.Length > 0;
        foreach Mission.UnitIDs(Index)
            if (ActionIndex == INDEX_NONE || Ledger.Missions[ActionIndex].UnitIDs.Find(Index) == INDEX_NONE) bRosterMatches = false;
        if (bRosterMatches) Mission.ParentKey = CovertKey(Action);
    }
    if (Count > 0 && (Count != 1 || Mission.ParentKey == ""))
    {
        Mission.Diagnostic = "ambush_parent_unresolved";
        Ledger.Diagnostic = Mission.Diagnostic;
    }
    // Native standard ambush with an absent parent must not become a second ordinary mission.
    if (InStr(Caps(string(Site.Source)), "AMBUSH") != INDEX_NONE && Mission.ParentKey == "")
    { Mission.Diagnostic = "ambush_parent_unresolved"; Ledger.Diagnostic = Mission.Diagnostic; }
    Ledger.Missions.AddItem(Mission);
    foreach Mission.UnitIDs(Index)
    {
        if (Ledger.Soldiers.Find('UnitID', Index) == INDEX_NONE && class'TNB_SoldierConditionObserver'.static.Snapshot(Unit(Index, Pending), Observation))
            class'TNB_SoldierConditionObserver'.static.Observe(Pending, Ledger, Observation, true);
        if (Ledger.Captivities.Find('UnitID', Index) == INDEX_NONE)
            class'TNB_CaptivityCaptureService'.static.Observe(Pending, Ledger, Unit(Index, Pending),,, true);
    }
}

static function JsonObject MissionDetails(MissionObservation Mission, optional XComGameState_TNBEventLedger Ledger)
{
    local JsonObject Details;
    Details = new class'JsonObject';
    Details.SetStringValue("mission_kind", Mission.Kind);
    Details.SetStringValue("mission_source", string(Mission.Source));
    if (Mission.AmbushResult != "") Details.SetStringValue("child_ambush_result", Mission.AmbushResult);
    class'TNB_MissionAttemptService'.static.AddDetails(Details, Ledger, Mission.Key);
    return Details;
}

static function string ActivitySummary(MissionObservation Mission, bool bComplete, optional string Result)
{
    local string Activity;
    Activity = Mission.Kind == "covert_action" ? "XCOM covert action" : "XCOM mission";
    if (bComplete) return Activity $ " completed:" @ Mission.Label @ "(" $ Result $ ")";
    return Activity $ " started:" @ Mission.Label;
}

static function Start(XComGameState Pending, XComGameState_TNBEventLedger Ledger, int Index)
{
    local MissionObservation Mission;
    local JsonObject Facts, Details;
    Mission = Ledger.Missions[Index];
    if (Mission.bStarted || Mission.bCompleted || Mission.ParentKey != "" || Mission.Diagnostic != "") return;
    Facts = new class'JsonObject';
    if (Mission.Label != "") Facts.SetStringValue("mission_name", Mission.Label);
    Details = MissionDetails(Mission, Ledger);
    class'TNB_EventFactory'.static.Queue(Pending, Ledger, Mission.Key $ ":start", "threadline.mission.started", ActivitySummary(Mission, false), Facts, Mission.Instances, Mission.Key, Details);
    if (Mission.Instances.Length > 0)
    {
        Facts = new class'JsonObject'; Facts.SetStringValue("deployment_kind", Mission.Kind);
        class'TNB_EventFactory'.static.Queue(Pending, Ledger, Mission.Key $ ":deployed", "threadline.mission.character_deployed", Mission.Kind == "covert_action" ? "Linked XCOM soldiers assigned to covert action" : "Linked XCOM soldiers deployed", Facts, Mission.Instances, Mission.Key, Details);
    }
    Ledger.Missions[Index].bStarted = true;
}

static function TacticalStarted(XComGameState Pending)
{
    local XComGameState_TNBEventLedger Ledger;
    local XComGameState_BattleData Battle;
    local int Index;
    Ledger = class'XComGameState_TNBEventLedger'.static.Edit(Pending);
    if (Ledger == none) return;
    foreach Pending.IterateByClassType(class'XComGameState_BattleData', Battle) break;
    if (Battle == none) Battle = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData', true));
    if (Battle != none) Ledger.CurrentBattleMissionID = Battle.m_iMissionID;
    Index = Ledger.Missions.Find('Key', Ledger.CurrentTacticalKey);
    // Loading an old in-progress mission does not fabricate a start or deployment.
    if (Index != INDEX_NONE) Start(Pending, Ledger, Index);
}

static function TacticalCleanup(XComGameState Pending, XComGameState_BattleData Battle)
{
    local XComGameState_TNBEventLedger Ledger;
    local int Index;
    Ledger = class'XComGameState_TNBEventLedger'.static.Edit(Pending);
    if (Ledger == none || Battle == none) return;
    Index = Ledger.Missions.Find('Key', Ledger.CurrentTacticalKey);
    if (Index == INDEX_NONE) { Ledger.Diagnostic = "mission_participation_unknown: no captured launch roster"; return; }
    Ledger.Missions[Index].bCleanup = true;
    Ledger.Missions[Index].bWon = Battle.bLocalPlayerWon;
    Ledger.Missions[Index].bAborted = Battle.bMissionAborted;
    Ledger.Missions[Index].CompletedLocal = class'TNB_EventFactory'.static.CaptureClock();
    // Must run before tactical-to-strategy wound reduction/recovery and HP bookkeeping.
    class'TNB_MissionInjuryCapture'.static.Record(Pending, Ledger, Index);
}

static function Complete(XComGameState Pending, XComGameState_TNBEventLedger Ledger, int Index)
{
    local MissionObservation Mission;
    local JsonObject Facts, Details, CapturedUnits;
    local XComGameState_Unit Soldier;
    local SoldierObservation Observation;
    local string Result;
    local int UnitID, Deaths, Injuries, SnapshotIndex;
    local bool bCasualtiesKnown, bInjuriesKnown;
    Mission = Ledger.Missions[Index];
    if (Mission.bCompleted || Mission.Diagnostic != "") return;
    Result = Mission.bWon ? "success" : "failure";
    if (Mission.ParentKey != "")
    {
        UnitID = Ledger.Missions.Find('Key', Mission.ParentKey);
        if (UnitID == INDEX_NONE) { Ledger.Diagnostic = "ambush_parent_unresolved"; return; }
        Ledger.Missions[UnitID].AmbushResult = Result;
        Ledger.Missions[Index].bCompleted = true;
        return;
    }
    bCasualtiesKnown = Mission.UnitIDs.Length > 0;
    CapturedUnits = new class'JsonObject';
    foreach Mission.UnitIDs(UnitID)
    {
        Soldier = Unit(UnitID, Pending);
        if (Soldier == none) { bCasualtiesKnown = false; continue; }
        if (Soldier.bCaptured && CapturedUnits.ValueArray.Length < 50) CapturedUnits.ValueArray.AddItem("xcom2_unit:" $ UnitID);
        if (Soldier.IsDead()) Deaths++;
        if (class'TNB_SoldierConditionObserver'.static.Snapshot(Soldier, Observation))
            class'TNB_SoldierConditionObserver'.static.Observe(Pending, Ledger, Observation, false, true, true, true, Mission.Key);
    }
    SnapshotIndex = Ledger.MissionInjuries.Find('MissionKey', Mission.Key);
    if (SnapshotIndex != INDEX_NONE && Ledger.MissionInjuries[SnapshotIndex].bKnown)
    { bInjuriesKnown = true; Injuries = Ledger.MissionInjuries[SnapshotIndex].Injuries; }
    // Missing/legacy snapshots and covert actions omit unknown totals, not invented zeros.
    Facts = class'TNB_MissionInjuryCapture'.static.CompletionFacts(Result, bCasualtiesKnown && Mission.Kind == "tactical", Deaths, bInjuriesKnown && Mission.Kind == "tactical", Injuries);
    Details = MissionDetails(Mission, Ledger);
    if (CapturedUnits.ValueArray.Length > 0) Details.SetObject("captured_soldiers", CapturedUnits);
    Details.SetBoolValue("mission_aborted", Mission.bAborted);
    class'TNB_EventFactory'.static.Queue(Pending, Ledger, Mission.Key $ ":complete", "threadline.mission.completed", ActivitySummary(Mission, true, Result), Facts, Mission.Instances, Mission.Key, Details, Mission.CompletedLocal);
    Ledger.Missions[Index].bCompleted = true;
}

static function PostMission()
{
    local XComGameState Pending;
    local XComGameState_TNBEventLedger Ledger;
    local XComGameState_BattleData Battle;
    local int Index;
    if (class'XComGameState_TNBCampaignLink'.static.Get() == none) return;
    Pending = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("The Name Beneath: finalized tactical reports");
    Ledger = class'XComGameState_TNBEventLedger'.static.Edit(Pending);
    if (Ledger != none)
    {
        Index = Ledger.Missions.Find('Key', Ledger.CurrentTacticalKey);
        Battle = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData', true));
        if (Index != INDEX_NONE && Ledger.Missions[Index].bCleanup && Battle != none && Battle.m_iMissionID == Ledger.CurrentBattleMissionID)
        {
            Ledger.Missions[Index].bWon = Battle.bLocalPlayerWon;
            Ledger.Missions[Index].bAborted = Battle.bMissionAborted;
            Complete(Pending, Ledger, Index);
        }
        else Ledger.Diagnostic = "mission_result_unknown: no captured cleanup";
        class'TNB_CaptivityCaptureService'.static.FinalizedReturn(Pending, Ledger);
        Ledger.CurrentTacticalKey = "";
        `XCOMGAME.GameRuleset.SubmitGameState(Pending);
    }
    else `XCOMHISTORY.CleanupPendingGameState(Pending);
}

static function Covert(XComGameState Pending, XComGameState_CovertAction Source, bool bComplete)
{
    local XComGameState_TNBEventLedger Ledger;
    local XComGameState_CovertAction Action;
    local XComGameState_StaffSlot Slot;
    local MissionObservation Mission;
    local int Index, SlotIndex;
    local string Result, PreviousDiagnostic;
    if (Source == none || Pending == none) return;
    Action = XComGameState_CovertAction(Pending.GetGameStateForObjectID(Source.ObjectID));
    if (Action == none) Action = Source;
    Ledger = class'XComGameState_TNBEventLedger'.static.Edit(Pending);
    if (Ledger == none) return;
    Mission.Key = CovertKey(Action);
    Index = Ledger.Missions.Find('Key', Mission.Key);
    if (!bComplete && Action.bStarted && Index == INDEX_NONE)
    {
        Mission.ObjectID = Action.ObjectID; Mission.Kind = "covert_action"; Mission.Source = Action.GetMyTemplateName();
        Mission.Label = class'TNB_EventFactory'.static.SafeText(Action.GetDisplayName());
        for (SlotIndex = 0; SlotIndex < Action.StaffSlots.Length; SlotIndex++)
        {
            Slot = XComGameState_StaffSlot(Pending.GetGameStateForObjectID(Action.StaffSlots[SlotIndex].StaffSlotRef.ObjectID));
            if (Slot == none) Slot = Action.GetStaffSlot(SlotIndex);
            if (Slot != none) AddSoldier(Mission, Slot.GetAssignedStaffRef().ObjectID, Pending);
        }
        Ledger.Missions.AddItem(Mission); Index = Ledger.Missions.Length - 1;
        Start(Pending, Ledger, Index);
    }
    if (bComplete)
    {
        if (Index == INDEX_NONE) { Ledger.Diagnostic = "covert_participation_unknown: action started before observation"; return; }
        if (Ledger.Missions[Index].bCompleted) return;
        Result = class'TNB_CovertActionOutcome'.static.Resolve(Action.Risks, Action.RewardsNotGivenOnCompletion, Ledger.Missions[Index].AmbushResult);
        if (Result == "") { Ledger.Missions[Index].Diagnostic = "covert_result_overridden: verification required"; Ledger.Diagnostic = Ledger.Missions[Index].Diagnostic; return; }
        // Clear only our own unknown-result diagnostic after explicit evidence.
        PreviousDiagnostic = Ledger.Missions[Index].Diagnostic;
        if (PreviousDiagnostic == "covert_result_overridden: verification required")
        {
            Ledger.Missions[Index].Diagnostic = "";
            if (Ledger.Diagnostic == PreviousDiagnostic) Ledger.Diagnostic = "";
        }
        Ledger.Missions[Index].bCleanup = true;
        Ledger.Missions[Index].bWon = Result == "success";
        Ledger.Missions[Index].CompletedLocal = class'TNB_EventFactory'.static.CaptureClock();
        Complete(Pending, Ledger, Index);
        `log("TNB_COVERT completion result=" $ Result $ " reported=" $ Ledger.Missions[Index].bCompleted,, 'TheNameBeneath');
    }
}
 
static function ObservePendingUnit(XComGameState Pending, XComGameState_Unit Source)
{
    local XComGameState_TNBEventLedger Ledger;
    local SoldierObservation Observation;
    if (Pending == none || Source == none || `HQGAME == none) return;
    if (!class'TNB_SoldierConditionObserver'.static.Snapshot(Unit(Source.ObjectID, Pending), Observation)) return;
    Ledger = class'XComGameState_TNBEventLedger'.static.Edit(Pending);
    if (Ledger != none) class'TNB_SoldierConditionObserver'.static.Observe(Pending, Ledger, Observation, false, true, true);
}

static function bool NeedsHistoryRebaseline(int Cursor, int Head, bool bNextFrameAvailable)
{
    return Cursor > Head || (Cursor < Head && !bNextFrameAvailable);
}

static function bool IsLegacyHistoryError(string Diagnostic)
{
    return Diagnostic == "observation_history_unavailable" || InStr(Diagnostic, "observation_history_session_reset:") == 0 || Diagnostic == "native_history_clock_format_unknown";
}

static function RebaselineHistoryGap(XComGameState Pending, XComGameState_TNBEventLedger Ledger, int Head, string Reason)
{
    local XComGameState_TNBSoldierLink Link;
    local SoldierObservation Current, Previous, Empty;
    local int Index, OldCursor;
    OldCursor = Ledger.LastObservedHistoryIndex;
    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_TNBSoldierLink', Link)
    {
        if (!class'TNB_SoldierConditionObserver'.static.Snapshot(Unit(Link.UnitRef.ObjectID), Current)) continue;
        Index = Ledger.Soldiers.Find('UnitID', Current.UnitID);
        Previous = Empty;
        if (Index != INDEX_NONE) Previous = Ledger.Soldiers[Index];
        Current = class'TNB_SoldierConditionObserver'.static.RebaselineAfterGap(Previous, Current);
        class'TNB_CaptivityCaptureService'.static.Observe(Pending, Ledger, Unit(Link.UnitRef.ObjectID),,, true);
        if (Index == INDEX_NONE) Ledger.Soldiers.AddItem(Current);
        else Ledger.Soldiers[Index] = Current;
    }
    // Current snapshots do not establish when missing transitions happened. No event is emitted.
    Ledger.LastObservedHistoryIndex = Head;
    Ledger.HistoryGapCount++;
    Ledger.HistoryDiagnostic = "observation_history_gap: rebaselined; missing interval not reconstructed (" $ Reason $ "); gaps=" $ Ledger.HistoryGapCount;
    if (IsLegacyHistoryError(Ledger.Diagnostic)) Ledger.Diagnostic = "";
    class'TNB_ReportingSafety'.static.Trace("HISTORY_GAP_REBASE reason=" $ Reason $ " old_cursor=" $ OldCursor $ " head=" $ Head $ " gaps=" $ Ledger.HistoryGapCount, Pending);
}

static function ObserveHistory(XComGameState Pending, XComGameState_TNBEventLedger Ledger)
{
    local XComGameState Frame;
    local XComGameState_Unit Soldier;
    local SoldierObservation Observation;
    local int Index, Last, Head;
    local string Captured;
    Head = `XCOMHISTORY.GetCurrentHistoryIndex();
    if (NeedsHistoryRebaseline(Ledger.LastObservedHistoryIndex, Head, true))
    { RebaselineHistoryGap(Pending, Ledger, Head, "session_reset"); return; }
    Last = Min(Head, Ledger.LastObservedHistoryIndex + 256);
    if (!Ledger.bFrameClockVerified) { Ledger.Diagnostic = "native_history_clock_unverified: waiting for a committed clock sample"; return; }
    for (Index = Ledger.LastObservedHistoryIndex + 1; Index <= Last; Index++)
    {
        Frame = `XCOMHISTORY.GetGameStateFromHistory(Index);
        if (NeedsHistoryRebaseline(Ledger.LastObservedHistoryIndex, Head, Frame != none))
        { RebaselineHistoryGap(Pending, Ledger, Head, "frame_unavailable"); return; }
        Captured = class'TNB_EventFactory'.static.FrameClock(Frame.TimeStamp);
        if (Captured == "") { RebaselineHistoryGap(Pending, Ledger, Head, "frame_clock_unknown"); return; }
        foreach Frame.IterateByClassType(class'XComGameState_Unit', Soldier)
        {
            if (class'TNB_SoldierConditionObserver'.static.Snapshot(Soldier, Observation))
            {
                Observation.CapturedLocal = Captured;
                class'TNB_SoldierConditionObserver'.static.Observe(Pending, Ledger, Observation, false, false, false, `HQGAME != none && !`XCOMHQ.bReturningFromMission);
            }
        }
        class'TNB_CaptivityCaptureService'.static.ObserveFrame(Pending, Ledger, Frame, Captured);
        Ledger.LastObservedHistoryIndex = Index;
    }
    if (Ledger.Diagnostic == "native_history_clock_unverified: waiting for a committed clock sample") Ledger.Diagnostic = "";
    if (IsLegacyHistoryError(Ledger.Diagnostic)) Ledger.Diagnostic = "";
}
