// SDK-only runtime probe. Never selected by campaign or multiplayer configuration.
class TNB_ProbeGameInfo extends GameInfo;

var TNB_LoopbackClient Probe;

event PostBeginPlay()
{
    super.PostBeginPlay();
    Probe = Spawn(class'TNB_LoopbackClient');
    if (Probe == none)
    {
        `log("TNB_RUNTIME_PROBE_FAILED: spawn",, 'TheNameBeneath');
        ConsoleCommand("exit");
        return;
    }
    Probe.CompanionPort = 27129;
    Probe.BeginRequest("ping", Complete);
}

function Complete(JsonObject Response, string ErrorCode)
{
    if (ErrorCode != "")
        `log("TNB_RUNTIME_PROBE_FAILED:" @ ErrorCode,, 'TheNameBeneath');
    else
        `log("TNB_RUNTIME_PROBE_PASSED:" @ Response.GetStringValue("companion_version"),, 'TheNameBeneath');
    ConsoleCommand("exit");
}
