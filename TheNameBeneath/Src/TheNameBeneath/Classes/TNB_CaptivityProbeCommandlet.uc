class TNB_CaptivityProbeCommandlet extends Commandlet dependson(TNB_EventTypes);

event int Main(string Params)
{
    local CaptivityObservation Record;
    local JsonObject Report;
    local string CapturedKey;
    if (class'TNB_CaptivityCaptureService'.static.Transition(false, true, false, false) != "captured") return 1;
    if (class'TNB_CaptivityCaptureService'.static.Transition(true, false, false, true) != "freed") return 2;
    if (class'TNB_CaptivityCaptureService'.static.Transition(true, false, false, false) != "") return 3;
    if (class'TNB_CaptivityCaptureService'.static.Transition(true, false, true, true) != "") return 4;
    if (class'TNB_CaptivityCaptureService'.static.Transition(false, false, false, true) != "") return 5;
    if (class'TNB_CaptivityCaptureService'.static.Transition(true, true, false, false) != "") return 6;
    Record.UnitID = 17; Record.InstanceID = "33333333-3333-4333-8333-333333333333"; Record.CaptureSequence = 1;
    Report = class'TNB_CaptivityCaptureService'.static.Capture(Record, "captured", "Ren" $ Chr(233), class'TNB_EventFactory'.static.CaptureClock());
    if (Report.GetObject("game_data").GetIntValue("unit_id") != 17 || Report.GetObject("game_data").GetIntValue("capture_sequence") != 1) return 7;
    CapturedKey = Report.GetStringValue("key");
    `log("TNB_NATIVE_CAPTIVITY_CAPTURE=" $ class'TNB_EventFactory'.static.ASCIIJson(Report));
    Record.CaptureSequence = 2;
    if (class'TNB_CaptivityCaptureService'.static.Capture(Record, "captured", "Test", class'TNB_EventFactory'.static.CaptureClock()).GetStringValue("key") == CapturedKey) return 8;
    Record.FreedomSequence = 1;
    Report = class'TNB_CaptivityCaptureService'.static.Capture(Record, "freed", "Snow " $ Chr(38634), class'TNB_EventFactory'.static.CaptureClock());
    `log("TNB_NATIVE_CAPTIVITY_CAPTURE=" $ class'TNB_EventFactory'.static.ASCIIJson(Report));
    `log("TNB_CAPTIVITY_PASS: capture, confirmed crew return, missing roster, death, no-change and native Unicode payloads.");
    return 0;
}

defaultproperties
{
    IsClient=false
    IsServer=false
    IsEditor=true
    LogToConsole=true
}
