// Offline identity policy/plain-record/production-payload proof. No live-client construction,
// GUID generation, real campaign or HTTP. Retail supplies its already-generated launch ID.
class TNB_AttemptProbeCommandlet extends Commandlet dependson(TNB_EventTypes);

static function EmitAttempt(MissionObservation Mission, XComGameState_TNBEventLedger Ledger, bool bWon)
{
    local JsonObject Facts, Details, Report;
    local array<string> Instances;
    Instances.AddItem("33333333-3333-4333-8333-333333333333");
    Details = class'TNB_EventCaptureService'.static.MissionDetails(Mission, Ledger);
    Facts = new class'JsonObject'; Facts.SetStringValue("mission_name", Mission.Label);
    Report = class'TNB_EventFactory'.static.Capture(Mission.Key $ ":start", "threadline.mission.started", "Attempt test mission started", Facts, Instances, Mission.Key, Details);
    `log("TNB_NATIVE_ATTEMPT_CAPTURE=" $ class'TNB_EventFactory'.static.ASCIIJson(Report));
    Facts = new class'JsonObject'; Facts.SetStringValue("deployment_kind", "tactical");
    Report = class'TNB_EventFactory'.static.Capture(Mission.Key $ ":deployed", "threadline.mission.character_deployed", "Attempt test character deployed", Facts, Instances, Mission.Key, Details);
    `log("TNB_NATIVE_ATTEMPT_CAPTURE=" $ class'TNB_EventFactory'.static.ASCIIJson(Report));
    Facts = class'TNB_MissionInjuryCapture'.static.CompletionFacts(bWon ? "success" : "failure", true, 0, true, bWon ? 0 : 1);
    Report = class'TNB_EventFactory'.static.Capture(Mission.Key $ ":complete", "threadline.mission.completed", "Attempt test mission completed", Facts, Instances, Mission.Key, Details);
    `log("TNB_NATIVE_ATTEMPT_CAPTURE=" $ class'TNB_EventFactory'.static.ASCIIJson(Report));
}

event int Main(string Params)
{
    local string IDA, IDB, SourceKey, BeforeJSON;
    local int Created;
    local array<TacticalMissionAttempt> Attempts, SavedAttempts;
    local TacticalMissionAttempt A, B, Again;
    local MissionObservation Mission, Legacy;
    local XComGameState_TNBEventLedger Ledger;
    local JsonObject Details;
    IDA = "11111111-1111-4111-8111-111111111111";
    IDB = "22222222-2222-4222-8222-222222222222";
    if (class'TNB_MissionAttemptService'.static.NormalizeLaunchID(IDA) == "" || class'TNB_MissionAttemptService'.static.NormalizeLaunchID(IDB) == "" || IDA == IDB) return 1;
    if (class'TNB_MissionAttemptService'.static.NormalizeLaunchID("{01234567-89ab-cdef-0123-456789abcdef}") != "0123456789ABCDEF0123456789ABCDEF") return 2;
    SourceKey = "tactical:42:MissionSource_Test:2026:10:20:0:seed:123";
    if (!class'TNB_MissionAttemptService'.static.Resolve(Attempts, SourceKey, IDA, A, Created) || Created != 1 || Attempts.Length != 1) return 3;
    if (!class'TNB_MissionAttemptService'.static.Resolve(Attempts, SourceKey, IDA, Again, Created) || Created != 0 || Again.Key != A.Key || Attempts.Length != 1) return 4;
    SavedAttempts = Attempts;
    if (!class'TNB_MissionAttemptService'.static.Resolve(SavedAttempts, SourceKey, IDA, Again, Created) || Created != 0 || Again.Key != A.Key) return 5;
    if (!class'TNB_MissionAttemptService'.static.Resolve(Attempts, SourceKey, IDB, B, Created) || Created != 1 || B.Key == A.Key || Attempts.Length != 2) return 6;
    if (class'TNB_MissionAttemptService'.static.Resolve(Attempts, SourceKey, "", Again, Created)) return 7;
    if (class'TNB_MissionAttemptService'.static.Resolve(Attempts, SourceKey, "00000000000000000000000000000000", Again, Created)) return 8;
    if (class'TNB_MissionAttemptService'.static.Resolve(Attempts, SourceKey, "invalid-guid", Again, Created)) return 9;
    if (class'TNB_MissionAttemptService'.static.Resolve(Attempts, "different-site", IDA, Again, Created) || Attempts.Length != 2) return 10;
    Ledger = new class'XComGameState_TNBEventLedger'; Ledger.TacticalAttempts = Attempts;
    Legacy.Key = SourceKey; Legacy.Kind = "tactical"; Legacy.Source = 'MissionSource_Test';
    Details = class'TNB_EventCaptureService'.static.MissionDetails(Legacy);
    BeforeJSON = class'TNB_EventFactory'.static.ASCIIJson(Details);
    class'TNB_MissionAttemptService'.static.AddDetails(Details, Ledger, Legacy.Key);
    if (class'TNB_EventFactory'.static.ASCIIJson(Details) != BeforeJSON || Legacy.Key != SourceKey) return 11;
    Legacy.Kind = "covert_action"; Legacy.Key = "covert:17:Test:2026:10:20:0";
    Details = class'TNB_EventCaptureService'.static.MissionDetails(Legacy);
    BeforeJSON = class'TNB_EventFactory'.static.ASCIIJson(Details);
    class'TNB_MissionAttemptService'.static.AddDetails(Details, Ledger, Legacy.Key);
    if (class'TNB_EventFactory'.static.ASCIIJson(Details) != BeforeJSON) return 12;
    Mission.Kind = "tactical"; Mission.Source = 'MissionSource_Test'; Mission.Label = "Same generated mission, separate attempts";
    Mission.Key = A.Key;
    Details = class'TNB_EventCaptureService'.static.MissionDetails(Mission, Ledger);
    if (Details.GetStringValue("mission_attempt_id") != A.AttemptID || Details.GetStringValue("mission_source_key") != SourceKey) return 13;
    EmitAttempt(Mission, Ledger, false);
    Mission.Key = B.Key; EmitAttempt(Mission, Ledger, true);
    `log("TNB_ATTEMPTS_PASS: GUID normalization, stable same-launch/copy identity, distinct supplied launch IDs for the same native mission, invalid/conflicting identity rejection, legacy/covert payload preservation and six production event shapes. Actual GUID generation and save reload need retail acceptance.");
    return 0;
}

defaultproperties
{
    IsClient=false
    IsServer=false
    IsEditor=true
    LogToConsole=true
}
