// Offline production classifier/summary/JSON/outbox checks. No campaign or HTTP.
class TNB_CovertProbeCommandlet extends Commandlet dependson(TNB_EventTypes, XComGameState_CovertAction);

event int Main(string Params)
{
    local array<CovertActionRisk> Risks;
    local CovertActionRisk Risk;
    local array<name> FailureNames;
    local name RiskName;
    local MissionObservation Mission;
    local JsonObject Facts, Details, Capture;
    local XComGameState_TNBEventOutbox Outbox;
    local array<string> Instances;
    local string Summary;
    if (class'TNB_CovertActionOutcome'.static.Resolve(Risks, false) != "success") return 1;
    if (class'TNB_CovertActionOutcome'.static.Resolve(Risks, true) != "") return 2;
    FailureNames.AddItem('CovertActionRisk_Failure_Easy');
    FailureNames.AddItem('CovertActionRisk_Failure_Moderate');
    FailureNames.AddItem('CovertActionRisk_Failure_Hard');
    foreach FailureNames(RiskName)
    {
        Risk.RiskTemplateName = RiskName; Risk.bOccurs = false;
        Risks.Length = 0; Risks.AddItem(Risk);
        if (class'TNB_CovertActionOutcome'.static.Resolve(Risks, false) != "success" || class'TNB_CovertActionOutcome'.static.Resolve(Risks, true) != "") return 3;
        Risks[0].bOccurs = true;
        if (class'TNB_CovertActionOutcome'.static.Resolve(Risks, true) != "failure" || class'TNB_CovertActionOutcome'.static.Resolve(Risks, false) != "failure") return 4;
    }
    Risks[0].bOccurs = false;
    if (class'TNB_CovertActionOutcome'.static.Resolve(Risks, true, "failure") != "failure" || class'TNB_CovertActionOutcome'.static.Resolve(Risks, true, "success") != "") return 5;
    if (class'TNB_CovertActionOutcome'.static.Resolve(Risks, false, "failure") != "success") return 6;
    Risks[0].RiskTemplateName = 'OtherMod_Failure'; Risks[0].bOccurs = true;
    if (class'TNB_CovertActionOutcome'.static.Resolve(Risks, true, "failure") != "" || class'TNB_CovertActionOutcome'.static.Resolve(Risks, false) != "success") return 7;
    if (class'TNB_CovertActionOutcome'.static.IsLongWarFailureRisk('CovertActionRisk_Failure_Custom')) return 8;
    Risks[0].RiskTemplateName = 'CovertActionRisk_SoldierWounded';
    if (class'TNB_CovertActionOutcome'.static.Resolve(Risks, false) != "success") return 9;

    Instances.AddItem("33333333-3333-4333-8333-333333333333");
    Mission.Kind = "covert_action"; Mission.Source = 'CovertAction_Test'; Mission.Label = "Manufacture Upgrade";
    Mission.Key = "covert:17:CovertAction_Test:2026:10:20:0";
    Details = class'TNB_EventCaptureService'.static.MissionDetails(Mission);
    if (Details.GetStringValue("mission_kind") != "covert_action") return 10;
    Facts = new class'JsonObject'; Facts.SetStringValue("mission_name", Mission.Label);
    Summary = class'TNB_EventCaptureService'.static.ActivitySummary(Mission, false);
    if (Summary != "XCOM covert action started: Manufacture Upgrade") return 11;
    Capture = class'TNB_EventFactory'.static.Capture(Mission.Key $ ":start", "threadline.mission.started", Summary, Facts, Instances, Mission.Key, Details);
    `log("TNB_NATIVE_COVERT_CAPTURE=" $ class'TNB_EventFactory'.static.ASCIIJson(Capture));
    Facts = new class'JsonObject'; Facts.SetStringValue("deployment_kind", Mission.Kind);
    Capture = class'TNB_EventFactory'.static.Capture(Mission.Key $ ":deployed", "threadline.mission.character_deployed", "Linked XCOM soldiers assigned to covert action", Facts, Instances, Mission.Key, Details);
    `log("TNB_NATIVE_COVERT_CAPTURE=" $ class'TNB_EventFactory'.static.ASCIIJson(Capture));
    Facts = class'TNB_MissionInjuryCapture'.static.CompletionFacts("failure", false, 0, false, 0);
    Summary = class'TNB_EventCaptureService'.static.ActivitySummary(Mission, true, "failure");
    if (Summary != "XCOM covert action completed: Manufacture Upgrade (failure)") return 12;
    Capture = class'TNB_EventFactory'.static.Capture(Mission.Key $ ":complete", "threadline.mission.completed", Summary, Facts, Instances, Mission.Key, Details);
    if (InStr(class'TNB_EventFactory'.static.ASCIIJson(Capture), "squad_injuries") != INDEX_NONE || InStr(class'TNB_EventFactory'.static.ASCIIJson(Capture), "squad_deaths") != INDEX_NONE) return 13;
    Outbox = new class'XComGameState_TNBEventOutbox';
    if (!Outbox.Add(Mission.Key $ ":complete", Capture) || !Outbox.Add(Mission.Key $ ":complete", Capture) || Outbox.Reports.Length != 1) return 14;
    `log("TNB_NATIVE_COVERT_CAPTURE=" $ Outbox.Reports[0].CaptureJSON);
    Mission.Key = "covert:18:CovertAction_Test:2026:10:20:0";
    Facts = class'TNB_MissionInjuryCapture'.static.CompletionFacts("success", false, 0, false, 0);
    Capture = class'TNB_EventFactory'.static.Capture(Mission.Key $ ":complete", "threadline.mission.completed", class'TNB_EventCaptureService'.static.ActivitySummary(Mission, true, "success"), Facts, Instances, Mission.Key, Details);
    `log("TNB_NATIVE_COVERT_CAPTURE=" $ class'TNB_EventFactory'.static.ASCIIJson(Capture));
    Mission.Kind = "tactical";
    if (class'TNB_EventCaptureService'.static.ActivitySummary(Mission, false) != "XCOM mission started: Manufacture Upgrade" || class'TNB_EventCaptureService'.static.ActivitySummary(Mission, true, "success") != "XCOM mission completed: Manufacture Upgrade (success)") return 15;
    `log("TNB_COVERT_PASS: native success, all three LWOTC failure risks, unknown overrides held, associated failed ambush only with LW evidence, unrelated risks, unchanged tactical summaries, four production payloads and duplicate capture guard. Native callback/save/retail result still needs gameplay acceptance.");
    return 0;
}

defaultproperties
{
    IsClient=false
    IsServer=false
    IsEditor=true
    LogToConsole=true
}
