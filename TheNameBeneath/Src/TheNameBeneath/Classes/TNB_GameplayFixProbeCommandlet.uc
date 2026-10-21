// Offline policy, plain saved records and production JSON helpers only. No campaign/HTTP.
class TNB_GameplayFixProbeCommandlet extends Commandlet dependson(TNB_EventTypes);

event int Main(string Params)
{
    local SoldierObservation Previous, Current, Rebased, RankUp;
    local ConditionEpisode Episode;
    local MissionInjurySnapshot InjurySnapshot;
    local XComGameState_TNBEventLedger Ledger;
    local JsonObject Report, Facts;
    local array<string> Instances;
    local string PromotionKey;
    if (!class'TNB_ReportingSafety'.static.RunChecks()) return 1;
    if (!class'TNB_PromotionCaptureService'.static.ValidTransition(0, 1) || !class'TNB_PromotionCaptureService'.static.ValidTransition(2, 4)) return 2;
    if (class'TNB_PromotionCaptureService'.static.ValidTransition(1, 1) || class'TNB_PromotionCaptureService'.static.ValidTransition(2, 1) || class'TNB_PromotionCaptureService'.static.ValidTransition(-1, 1)) return 3;
    if (class'TNB_PromotionCaptureService'.static.ObservedFromRank(0, 1) != 1 || class'TNB_PromotionCaptureService'.static.ObservedFromRank(2, 1) != 2 || class'TNB_PromotionCaptureService'.static.ValidTransition(class'TNB_PromotionCaptureService'.static.ObservedFromRank(1, 2), 2)) return 22;
    RankUp.UnitID = 17; RankUp.InstanceID = "33333333-3333-4333-8333-333333333333"; RankUp.LinkToken = "link-a"; RankUp.Rank = 1;
    PromotionKey = class'TNB_PromotionCaptureService'.static.Key(RankUp, 0);
    if (PromotionKey != "unit:17:33333333-3333-4333-8333-333333333333:rank:0:1") return 4;
    RankUp.LinkToken = "rewound-link-b";
    if (class'TNB_PromotionCaptureService'.static.Key(RankUp, 0) != PromotionKey) return 5;
    RankUp.CapturedLocal = class'TNB_EventFactory'.static.CaptureClock();
    Report = class'TNB_PromotionCaptureService'.static.Capture(RankUp, 0);
    if (Report == none || Report.GetObject("facts").GetStringValue("from_rank") != "0" || Report.GetObject("facts").GetStringValue("to_rank") != "1") return 6;
    `log("TNB_NATIVE_PROMOTION_CAPTURE=" $ class'TNB_EventFactory'.static.ASCIIJson(Report));
    if (class'TNB_PromotionCaptureService'.static.Capture(RankUp, 1) != none) return 7;
    RankUp.InstanceID = "";
    if (class'TNB_PromotionCaptureService'.static.Capture(RankUp, 0) != none) return 8;

    if (!class'TNB_EventCaptureService'.static.NeedsHistoryRebaseline(10, 20, false) || !class'TNB_EventCaptureService'.static.NeedsHistoryRebaseline(20, 10, true)) return 9;
    if (class'TNB_EventCaptureService'.static.NeedsHistoryRebaseline(10, 20, true) || class'TNB_EventCaptureService'.static.NeedsHistoryRebaseline(10, 10, false)) return 10;
    if (!class'TNB_EventCaptureService'.static.IsLegacyHistoryError("observation_history_session_reset: review required") || class'TNB_EventCaptureService'.static.IsLegacyHistoryError("reporting_full")) return 11;
    Previous.UnitID = 17; Previous.InstanceID = "instance"; Previous.LinkToken = "token"; Previous.Rank = 2;
    Previous.WoundSequence = 4; Previous.WoundKey = "previous-known-injury";
    Episode.TemplateName = 'FearOfFire'; Episode.Sequence = 3; Episode.Key = "old-known-episode"; Episode.bAcquisitionKnown = true; Episode.bClosed = false;
    Previous.Episodes.AddItem(Episode); Previous.Negative.AddItem('FearOfFire');
    Current.UnitID = 17; Current.InstanceID = "instance"; Current.LinkToken = "token"; Current.Rank = 1;
    Current.bWounded = true; Current.Negative.AddItem('FearOfFire'); Current.Negative.AddItem('FearOfPanic');
    Rebased = class'TNB_SoldierConditionObserver'.static.RebaselineAfterGap(Previous, Current);
    if (Rebased.Rank != 2 || Rebased.WoundSequence != 4 || Rebased.WoundKey != "" || !Rebased.bWounded) return 12;
    if (Rebased.Episodes.Length != 2 || Rebased.Episodes[0].Sequence != 3 || Rebased.Episodes[0].bAcquisitionKnown || Rebased.Episodes[0].Key != "" || Rebased.Episodes[0].bClosed) return 13;
    if (Previous.Episodes[0].Key != "old-known-episode" || Previous.WoundKey != "previous-known-injury") return 14;
    Current.Negative.Length = 0;
    Rebased = class'TNB_SoldierConditionObserver'.static.RebaselineAfterGap(Previous, Current);
    if (!Rebased.Episodes[0].bClosed || Rebased.Episodes[0].Sequence != 3) return 15;

    // One mission wound counts even when post-mission recovery duration is zero.
    if (!class'TNB_MissionInjuryCapture'.static.Counts(true, true, false, true)) return 16;
    if (class'TNB_MissionInjuryCapture'.static.Counts(false, true, false, true) || class'TNB_MissionInjuryCapture'.static.Counts(true, false, false, true) || class'TNB_MissionInjuryCapture'.static.Counts(true, true, true, true) || class'TNB_MissionInjuryCapture'.static.Counts(true, true, false, false)) return 17;
    Ledger = new class'XComGameState_TNBEventLedger';
    InjurySnapshot.MissionKey = "native:injury-mission"; InjurySnapshot.RosterCount = 5; InjurySnapshot.bKnown = true; InjurySnapshot.Injuries = 1;
    class'TNB_MissionInjuryCapture'.static.Store(Ledger, InjurySnapshot);
    class'TNB_MissionInjuryCapture'.static.Store(Ledger, InjurySnapshot);
    if (Ledger.MissionInjuries.Length != 1 || Ledger.MissionInjuries[0].Injuries != 1) return 18;
    Facts = class'TNB_MissionInjuryCapture'.static.CompletionFacts("success", true, 0, true, Ledger.MissionInjuries[0].Injuries);
    if (Facts.GetIntValue("squad_injuries") != 1 || Facts.GetIntValue("squad_deaths") != 0) return 19;
    Instances.AddItem("33333333-3333-4333-8333-333333333333");
    Report = class'TNB_EventFactory'.static.Capture("native:injury-mission:complete", "threadline.mission.completed", "Native mission wound regression", Facts, Instances, "native:injury-mission");
    `log("TNB_NATIVE_INJURY_MISSION_CAPTURE=" $ class'TNB_EventFactory'.static.ASCIIJson(Report));
    Facts = class'TNB_MissionInjuryCapture'.static.CompletionFacts("failure", true, 0, false, 0);
    if (InStr(class'TNB_EventFactory'.static.ASCIIJson(Facts), "squad_injuries") != INDEX_NONE) return 20;
    Facts = class'TNB_MissionInjuryCapture'.static.CompletionFacts("success", false, 0, false, 0);
    if (InStr(class'TNB_EventFactory'.static.ASCIIJson(Facts), "squad_deaths") != INDEX_NONE) return 21;
    `log("TNB_GAMEPLAY_FIX_PASS: native promotion shape/identity, no eligibility or rank reset event, gap/no-gap policy, counter-preserving silent rebaseline, all-squad mission wound snapshot, duplicate snapshot and unknown-total omission.");
    return 0;
}

defaultproperties
{
    IsClient=false
    IsServer=false
    IsEditor=true
    LogToConsole=true
}
