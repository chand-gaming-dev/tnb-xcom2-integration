// Offline SDK proof only. No HTTP, credentials, real campaign or game-save writes.
class TNB_EventProbeCommandlet extends Commandlet dependson(TNB_EventTypes);
event int Main(string Params)
{
    local int Year, Month, DayOfWeek, Day, Hour, Minute, Second, Millisecond;
    local JsonObject JSON;
    local JsonObject Facts, Capture;
    local array<string> Instances;
    local XComGameState_TNBEventOutbox Outbox;
    local TNB_EventTypes.SoldierObservation BeforeCondition, AfterCondition;
    if (!class'TNB_ReportingSafety'.static.RunChecks()) return 11;
    `log("TNB_REPORTING_SAFETY_CHECKS_PASSED");
    GetSystemTime(Year, Month, DayOfWeek, Day, Hour, Minute, Second, Millisecond);
    `log("TNB_NATIVE_CLOCK=" $ Year $ "-" $ Month $ "-" $ Day $ "T" $ Hour $ ":" $ Minute $ ":" $ Second $ "." $ Millisecond);
    `log("TNB_NATIVE_TIMESTAMP=" $ TimeStamp());
    JSON = new class'JsonObject'; JSON.SetStringValue("name", "Ren" $ Chr(233) $ " " $ Chr(38634)); JSON.SetObject("empty", new class'JsonObject');
    `log("TNB_ASCII_JSON=" $ class'TNB_EventFactory'.static.ASCIIJson(JSON));
    Facts = new class'JsonObject'; Facts.SetStringValue("result", "success");
    Instances.AddItem("33333333-3333-4333-8333-333333333333");
    Capture = class'TNB_EventFactory'.static.Capture("native:mission:complete", "threadline.mission.completed", "Ren" $ Chr(233) $ " " $ Chr(38634), Facts, Instances, "native:mission");
    Outbox = new class'XComGameState_TNBEventOutbox';
    if (!Outbox.Add("native:mission:complete", Capture) || Outbox.Reports.Length != 1 || !Outbox.Add("native:mission:complete", Capture) || Outbox.Reports.Length != 1) return 1;
    `log("TNB_NATIVE_CAPTURE=" $ Outbox.Reports[0].CaptureJSON);
    if (class'TNB_EventFactory'.static.FrameClock("2026.10.19-16.18.20") != "2026-10-19T16:18:20.000") return 2;
    if (class'TNB_EventFactory'.static.FrameClock("2026/10/19 - 16:18:20") != "2026-10-19T16:18:20.000") return 3;
    if (class'TNB_EventFactory'.static.FrameClock("unknown") != "") return 4;
    if (class'TNB_SoldierConditionObserver'.static.BecameActive(BeforeCondition, AfterCondition, 'FearOfFire')) return 5;
    AfterCondition.Negative.AddItem('FearOfFire');
    if (!class'TNB_SoldierConditionObserver'.static.BecameActive(BeforeCondition, AfterCondition, 'FearOfFire')) return 6;
    BeforeCondition = AfterCondition;
    if (class'TNB_SoldierConditionObserver'.static.BecameActive(BeforeCondition, AfterCondition, 'FearOfFire')) return 7;
    AfterCondition.Negative.Length = 0;
    if (class'TNB_SoldierConditionObserver'.static.WasCured(BeforeCondition, AfterCondition, 'FearOfFire')) return 8;
    AfterCondition.Cured.AddItem('FearOfFire');
    if (!class'TNB_SoldierConditionObserver'.static.WasCured(BeforeCondition, AfterCondition, 'FearOfFire')) return 9;
    BeforeCondition = AfterCondition;
    if (class'TNB_SoldierConditionObserver'.static.WasCured(BeforeCondition, AfterCondition, 'FearOfFire')) return 10;
    `log("TNB_NATIVE_EVENT_CHECKS_PASSED");
    return 0;
}

defaultproperties
{
    IsClient=false
    IsServer=false
    IsEditor=true
    LogToConsole=true
}
