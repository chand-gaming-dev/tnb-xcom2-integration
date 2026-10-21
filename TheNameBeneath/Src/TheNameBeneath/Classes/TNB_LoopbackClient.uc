// One asynchronous, bounded JSON-line request to the companion on 127.0.0.1.
class TNB_LoopbackClient extends TcpLink config(TheNameBeneath);

var config int CompanionPort;
var string Outgoing;
var string Incoming;
var bool bFinished;
var float Elapsed;
var delegate<Reply> Completion;
delegate Reply(JsonObject Response, string ErrorCode);

function BeginRequest(string Operation, delegate<Reply> Callback, optional JsonObject Arguments)
{
    local IpAddr Address;
    local JsonObject Request;

    Completion = Callback;
    LinkMode = MODE_Text;
    ReceiveMode = RMODE_Event;
    Request = new class'JsonObject';
    Request.SetIntValue("protocol", 2);
    Request.SetIntValue("request_id", 1);
    Request.SetStringValue("op", Operation);
    if (Arguments != none) Request.SetObject("args", Arguments);
    Outgoing = class'TNB_EventFactory'.static.ASCIIJson(Request);
    // EncodeJson may pretty-print; frames use exactly one terminating newline.
    Outgoing = Repl(Repl(Outgoing, Chr(13), ""), Chr(10), "") $ Chr(10);
    if (Len(Outgoing) > 49152) { Finish(none, "event_too_large"); return; }
    if (CompanionPort < 1024 || CompanionPort > 65535 || !StringToIpAddr("127.0.0.1", Address))
    {
        Finish(none, "companion_configuration_invalid");
        return;
    }
    Address.Port = CompanionPort;
    if (BindPort() == 0 || !Open(Address))
        Finish(none, "companion_not_running");
}

event Tick(float DeltaTime)
{
    local int Sent;
    if (bFinished) return;
    Elapsed += DeltaTime;
    if (Elapsed > 23.0)
    {
        Finish(none, "companion_timeout");
        return;
    }
    if (IsConnected() && Len(Outgoing) > 0)
    {
        Sent = SendText(Left(Outgoing, 1024));
        if (Sent > 0) Outgoing = Mid(Outgoing, Sent);
    }
}

event ReceivedText(string Text)
{
    local int EndOfLine;
    local JsonObject Response;
    if (bFinished) return;
    Incoming $= Text;
    if (Len(Incoming) > 65536)
    {
        Finish(none, "companion_response_too_large");
        return;
    }
    EndOfLine = InStr(Incoming, Chr(10));
    if (EndOfLine < 0) return;
    Response = class'JsonObject'.static.DecodeJson(Left(Incoming, EndOfLine));
    if (Response == none || Response.GetIntValue("protocol") != 2 || Response.GetIntValue("request_id") != 1)
        Finish(none, "companion_protocol_mismatch");
    else if (!Response.GetBoolValue("ok"))
        Finish(Response.GetObject("data"), Response.GetStringValue("error"));
    else
    {
        if (Response.GetObject("data") == none) Finish(none, "companion_response_invalid");
        else Finish(Response.GetObject("data"), "");
    }
}

event Closed()
{
    if (!bFinished) Finish(none, "companion_disconnected");
}

function CancelRequest()
{
    Completion = none;
    bFinished = true;
    Close();
    Destroy();
}

private function Finish(JsonObject Response, string ErrorCode)
{
    if (bFinished) return;
    bFinished = true;
    Close();
    if (Completion != none) Completion(Response, ErrorCode);
    Completion = none;
    Destroy();
}

defaultproperties
{
    bAlwaysTick=true
}
