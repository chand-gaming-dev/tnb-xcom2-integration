class XComGameState_TNBEventOutbox extends XComGameState_BaseObject dependson(TNB_EventTypes);

var int SchemaVersion;
var array<TNB_EventTypes.PendingReport> Reports;
var string Diagnostic;

static function XComGameState_TNBEventOutbox Get(optional XComGameState Pending)
{
    local XComGameState_TNBEventOutbox Outbox;
    if (Pending != none)
        foreach Pending.IterateByClassType(class'XComGameState_TNBEventOutbox', Outbox) return Outbox;
    return XComGameState_TNBEventOutbox(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_TNBEventOutbox', true));
}

static function XComGameState_TNBEventOutbox Edit(XComGameState Pending)
{
    local XComGameState_TNBEventOutbox Outbox;
    foreach Pending.IterateByClassType(class'XComGameState_TNBEventOutbox', Outbox) return Outbox;
    Outbox = class'XComGameState_TNBEventOutbox'.static.Get();
    if (Outbox != none) return XComGameState_TNBEventOutbox(Pending.ModifyStateObject(class'XComGameState_TNBEventOutbox', Outbox.ObjectID));
    Outbox = XComGameState_TNBEventOutbox(Pending.CreateNewStateObject(class'XComGameState_TNBEventOutbox'));
    Outbox.SchemaVersion = 1;
    return Outbox;
}

function bool Add(string Key, JsonObject Capture)
{
    local TNB_EventTypes.PendingReport Report;
    local int Bytes;
    if (Reports.Find('Key', Key) != INDEX_NONE) return true;
    Report.CaptureJSON = class'TNB_EventFactory'.static.ASCIIJson(Capture);
    foreach Reports(Report) Bytes += Len(Report.CaptureJSON);
    if (Reports.Length >= 512 || Bytes + Len(class'TNB_EventFactory'.static.ASCIIJson(Capture)) > 8 * 1024 * 1024)
    {
        Diagnostic = "reporting_full: existing captures retained; new captures cannot be queued";
        return false;
    }
    Report.Key = Key;
    Report.CaptureJSON = class'TNB_EventFactory'.static.ASCIIJson(Capture);
    Report.EventID = "";
    Report.State = "captured";
    if (Len(Report.CaptureJSON) > 46000) { Diagnostic = "event_too_large"; return false; }
    Reports.AddItem(Report);
    return true;
}

defaultproperties
{
    bTacticalTransient=false
}
