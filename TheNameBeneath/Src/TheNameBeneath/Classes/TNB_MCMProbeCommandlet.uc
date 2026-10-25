// Pure status-presentation checks. No MCM widgets, world, sockets or history writes.
class TNB_MCMProbeCommandlet extends Commandlet;

event int Main(string Params)
{
    local TNB_MCMController Controller;
    local JsonObject Data;
    Controller = new class'TNB_MCMController';
    // Distinct test labels avoid relying on commandlet DLC localization loading.
    Controller.CompanionConnected = "companion-connected";
    Controller.CompanionUnavailable = "companion-unavailable";
    Controller.CompanionTimeout = "companion-timeout";
    Controller.CompanionIncompatible = "companion-incompatible";
    Controller.ServiceVerified = "journey-connected";
    Controller.ServiceUnverified = "journey-unverified";
    Controller.ServiceNotConfigured = "journey-not-configured";
    Controller.ServiceUnableToVerify = "journey-unable-to-verify";
    Controller.ServiceInvalidCredential = "journey-invalid-credential";
    Controller.ServiceScopeMissing = "journey-missing-scope";
    Controller.ServiceUnknown = "journey-unknown";

    if (Controller.CompanionStateText(true, "") != "companion-connected" ||
        Controller.CompanionStateText(true, "invalid_credential") != "companion-connected" ||
        Controller.CompanionStateText(false, "companion_timeout") != "companion-timeout" ||
        Controller.CompanionStateText(false, "companion_protocol_mismatch") != "companion-incompatible" ||
        Controller.CompanionStateText(false, "companion_not_running") != "companion-unavailable") return 1;
    if (Controller.JourneyConnectionText(none, "companion_timeout") != "journey-unknown") return 2;
    if (Controller.ServiceStateText("connected") != "journey-connected" ||
        Controller.ServiceStateText("unverified") != "journey-unverified" ||
        Controller.ServiceStateText("not_configured") != "journey-not-configured" ||
        Controller.ServiceStateText("invalid_credential") != "journey-invalid-credential" ||
        Controller.ServiceStateText("scope_missing") != "journey-missing-scope" ||
        Controller.ServiceStateText("unable_to_verify") != "journey-unable-to-verify" ||
        Controller.ServiceStateText("unknown-future-state") != "journey-unknown") return 3;
    Data = new class'JsonObject'; Data.SetStringValue("connection", "connected");
    if (Controller.JourneyConnectionText(Data, "") != "journey-connected" ||
        Controller.JourneyConnectionText(Data, "network_error") != "journey-unable-to-verify") return 4;
    Data.SetStringValue("connection", "invalid_credential");
    if (Controller.CompanionStateText(true, "invalid_credential") != "companion-connected" ||
        Controller.JourneyConnectionText(Data, "invalid_credential") != "journey-invalid-credential") return 5;
    Data.SetStringValue("connection", "unverified");
    if (Controller.JourneyConnectionText(Data, "") != "journey-unverified") return 6;
    Controller.Cleanup();
    `log("TNB_MCM_PASS: independent companion/Journey states, timeout/protocol/offline distinctions, cached/unverified status, credential rejection, unknown states and failed-test override. Native inline-row layout requires gameplay acceptance.");
    return 0;
}

defaultproperties
{
    IsClient=false
    IsServer=false
    IsEditor=true
    LogToConsole=true
}
