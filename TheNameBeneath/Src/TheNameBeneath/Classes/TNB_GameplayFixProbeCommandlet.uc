// Offline policy, plain saved records and production JSON helpers only. No campaign/HTTP.
class TNB_GameplayFixProbeCommandlet extends Commandlet dependson(TNB_EventTypes);

event int Main(string Params)
{
    local SoldierObservation Previous, Current, Rebased, RankUp;
    local ConditionEpisode Episode;
    local MissionInjurySnapshot InjurySnapshot;
    local XComGameState_TNBEventLedger Ledger, PromotionLedger, RewoundLedger;
    local XComGameState_TNBEventOutbox PromotionOutbox, RewoundOutbox;
    local JsonObject Report, Facts;
    local array<string> Instances;
    local string PromotionKey, LegacyKey, SavedCapture, OccurrenceA, OccurrenceB;
    if (!class'TNB_ReportingSafety'.static.RunChecks()) return 1;
    if (!class'TNB_PromotionCaptureService'.static.ValidTransition(0, 1) || !class'TNB_PromotionCaptureService'.static.ValidTransition(2, 4)) return 2;
    if (class'TNB_PromotionCaptureService'.static.ValidTransition(1, 1) || class'TNB_PromotionCaptureService'.static.ValidTransition(2, 1) || class'TNB_PromotionCaptureService'.static.ValidTransition(-1, 1)) return 3;
    if (class'TNB_PromotionCaptureService'.static.ObservedFromRank(0, 1) != 1 || class'TNB_PromotionCaptureService'.static.ObservedFromRank(2, 1) != 2 || class'TNB_PromotionCaptureService'.static.ValidTransition(class'TNB_PromotionCaptureService'.static.ObservedFromRank(1, 2), 2)) return 22;
    RankUp.UnitID = 17; RankUp.InstanceID = "33333333-3333-4333-8333-333333333333"; RankUp.LinkToken = "link-a"; RankUp.Rank = 1;
    OccurrenceA = "AAAAAAAA-BBBB-4CCC-8DDD-EEEEEEEEEEEE";
    OccurrenceB = "FFFFFFFF-BBBB-4CCC-8DDD-EEEEEEEEEEEE";
    LegacyKey = "unit:17:33333333-3333-4333-8333-333333333333:rank:0:1";
    PromotionKey = class'TNB_PromotionCaptureService'.static.Key(RankUp, 0, OccurrenceA);
    if (PromotionKey != (LegacyKey $ ":occurrence:AAAAAAAABBBB4CCC8DDDEEEEEEEEEEEE")) return 4;
    RankUp.LinkToken = "rewound-link-b";
    if (class'TNB_PromotionCaptureService'.static.Key(RankUp, 0, OccurrenceA) != PromotionKey) return 5;
    RankUp.CapturedLocal = class'TNB_EventFactory'.static.CaptureClock();
    Report = class'TNB_PromotionCaptureService'.static.Capture(RankUp, 0, OccurrenceA);
    if (Report == none || Report.GetObject("facts").GetStringValue("from_rank") != "0" || Report.GetObject("facts").GetStringValue("to_rank") != "1" || Report.GetObject("facts").GetStringValue("promotion_track") != "xcom2_soldier_rank") return 6;
    `log("TNB_NATIVE_PROMOTION_CAPTURE=" $ class'TNB_EventFactory'.static.ASCIIJson(Report));
    if (class'TNB_PromotionCaptureService'.static.Capture(RankUp, 1, OccurrenceA) != none) return 7;
    RankUp.InstanceID = "";
    if (class'TNB_PromotionCaptureService'.static.Capture(RankUp, 0, OccurrenceA) != none) return 8;
    RankUp.InstanceID = "33333333-3333-4333-8333-333333333333";
    if (class'TNB_PromotionCaptureService'.static.Capture(RankUp, 0, "") != none ||
        class'TNB_PromotionCaptureService'.static.NormalizeOccurrenceID("00000000-0000-0000-0000-000000000000") != "" ||
        class'TNB_PromotionCaptureService'.static.NormalizeOccurrenceID("not-an-occurrence") != "") return 23;
    PromotionLedger = new class'XComGameState_TNBEventLedger';
    PromotionOutbox = new class'XComGameState_TNBEventOutbox';
    Previous = RankUp; Previous.Rank = 0;
    PromotionLedger.Soldiers.AddItem(Previous);
    // An existing old-format report stays byte-for-byte intact; it is not re-keyed.
    Instances.AddItem(RankUp.InstanceID);
    Report = class'TNB_EventFactory'.static.Capture(LegacyKey, "threadline.character.promoted", "XCOM soldier promoted", class'TNB_PromotionCaptureService'.static.Facts(0, 1), Instances,,, RankUp.CapturedLocal);
    PromotionOutbox.Add(LegacyKey, Report); PromotionLedger.SeenKeys.AddItem(LegacyKey);
    SavedCapture = PromotionOutbox.Reports[0].CaptureJSON;
    if (class'TNB_PromotionCaptureService'.static.Store(PromotionLedger, PromotionOutbox, RankUp, 0, "") || PromotionLedger.Soldiers[0].Rank != 0 || PromotionOutbox.Reports.Length != 1) return 31;
    if (!class'TNB_PromotionCaptureService'.static.Store(PromotionLedger, PromotionOutbox, RankUp, 0, OccurrenceA)) return 24;
    if (PromotionOutbox.Reports.Length != 2 || PromotionOutbox.Reports[0].Key != LegacyKey || PromotionOutbox.Reports[0].CaptureJSON != SavedCapture || PromotionLedger.Soldiers[0].Rank != 1) return 25;
    // Duplicate native callback/history scan or a loaded post-promotion observation:
    // even a DIFFERENT proposed GUID cannot manufacture another occurrence.
    if (class'TNB_PromotionCaptureService'.static.Store(PromotionLedger, PromotionOutbox, RankUp, 0, OccurrenceB) || PromotionOutbox.Reports.Length != 2) return 26;
    `log("TNB_NATIVE_PROMOTION_OCCURRENCE=" $ PromotionOutbox.Reports[1].CaptureJSON);
    // Simulate independent saved-record branches from a pre-promotion baseline.
    RewoundLedger = new class'XComGameState_TNBEventLedger';
    RewoundOutbox = new class'XComGameState_TNBEventOutbox';
    RewoundLedger.Soldiers.AddItem(Previous);
    if (!class'TNB_PromotionCaptureService'.static.Store(RewoundLedger, RewoundOutbox, RankUp, 0, OccurrenceB) || RewoundOutbox.Reports[0].Key == PromotionKey) return 27;
    `log("TNB_NATIVE_PROMOTION_OCCURRENCE=" $ RewoundOutbox.Reports[0].CaptureJSON);
    RankUp.Rank = 2;
    if (!class'TNB_PromotionCaptureService'.static.Store(RewoundLedger, RewoundOutbox, RankUp, 1, OccurrenceA)) return 28;
    `log("TNB_NATIVE_PROMOTION_OCCURRENCE=" $ RewoundOutbox.Reports[1].CaptureJSON);
    RankUp.Rank = 1;
    if (class'TNB_PromotionCaptureService'.static.CanRecord(RewoundLedger, RankUp, 0)) return 29;
    RankUp.Rank = 2; RankUp.LinkToken = "different-link";
    if (class'TNB_PromotionCaptureService'.static.CanRecord(RewoundLedger, RankUp, 1)) return 30;
    PromotionLedger.Soldiers[0] = Previous;
    RankUp = Previous; RankUp.Rank = 1;
    PromotionOutbox.Reports.Length = 512;
    if (class'TNB_PromotionCaptureService'.static.Store(PromotionLedger, PromotionOutbox, RankUp, 0, OccurrenceB) || PromotionLedger.Soldiers[0].Rank != 0 || PromotionOutbox.Reports.Length != 512) return 32;
    RankUp.Rank = 8;
    Report = class'TNB_PromotionCaptureService'.static.Capture(RankUp, 0, OccurrenceB);
    if (Report == none || Report.GetObject("facts").GetStringValue("to_rank") != "8") return 33;
    Instances.Length = 0;

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
    `log("TNB_GAMEPLAY_FIX_PASS: promotion occurrence GUID shape, duplicate-hook/post-promotion high-water guards, rewound/new-rank occurrences, immutable legacy/outbox records, capacity failure without rank advance, factual extended ranks; no eligibility or rank reset event, gap/no-gap policy, counter-preserving silent rebaseline, all-squad mission wound snapshot, duplicate snapshot and unknown-total omission. Real GUID generation and save/load require retail acceptance.");
    return 0;
}

defaultproperties
{
    IsClient=false
    IsServer=false
    IsEditor=true
    LogToConsole=true
}
