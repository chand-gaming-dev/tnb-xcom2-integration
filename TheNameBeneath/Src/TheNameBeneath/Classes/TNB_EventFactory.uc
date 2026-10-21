class TNB_EventFactory extends Object;

static function string Pad(int Value, int Width)
{
    local string Text;
    Text = string(Value);
    while (Len(Text) < Width) Text = "0" $ Text;
    return Text;
}

static function string CaptureClock()
{
    local int Year, Month, DayOfWeek, Day, Hour, Minute, Second, Millisecond;
    local TNB_EventFactory Clock;
    Clock = new class'TNB_EventFactory';
    Clock.GetSystemTime(Year, Month, DayOfWeek, Day, Hour, Minute, Second, Millisecond);
    return Pad(Year, 4) $ "-" $ Pad(Month, 2) $ "-" $ Pad(Day, 2) $ "T" $ Pad(Hour, 2) $ ":" $ Pad(Minute, 2) $ ":" $ Pad(Second, 2) $ "." $ Pad(Millisecond, 3);
}

static function string ASCIIJson(JsonObject Value)
{
    local string Encoded, Result, Hex;
    local int Index, Code;
    Hex = "0123456789abcdef";
    Encoded = class'JsonObject'.static.EncodeJson(Value);
    for (Index = 0; Index < Len(Encoded); Index++)
    {
        Code = Asc(Mid(Encoded, Index, 1));
        // JsonObject already escapes controls inside strings; remove pretty-print whitespace only.
        if (Code == 13 || Code == 10 || Code == 9) continue;
        if (Code > 127)
            Result $= Chr(92) $ "u" $ Mid(Hex, (Code >> 12) & 15, 1) $ Mid(Hex, (Code >> 8) & 15, 1) $ Mid(Hex, (Code >> 4) & 15, 1) $ Mid(Hex, Code & 15, 1);
        else Result $= Chr(Code);
    }
    return Result;
}

static function string SafeText(string Text, optional int Maximum=480)
{
    Text = Repl(Repl(Repl(Text, Chr(10), " "), Chr(13), " "), Chr(9), " ");
    return Left(Text, Maximum);
}

// appSystemTimeString is separately verified against GetSystemTime at a live commit.
// Unknown formats never fall back to a delivery-time timestamp.
static function string FrameClock(string Text)
{
    if (Len(Text) >= 19 && Mid(Text,4,1) == "." && Mid(Text,7,1) == "." && Mid(Text,10,1) == "-")
        return Left(Text,4) $ "-" $ Mid(Text,5,2) $ "-" $ Mid(Text,8,2) $ "T" $ Mid(Text,11,2) $ ":" $ Mid(Text,14,2) $ ":" $ Mid(Text,17,2) $ ".000";
    if (Len(Text) >= 21 && Mid(Text,4,1) == "/" && Mid(Text,7,1) == "/" && Mid(Text,10,3) == " - ")
        return Left(Text,4) $ "-" $ Mid(Text,5,2) $ "-" $ Mid(Text,8,2) $ "T" $ Mid(Text,13,8) $ ".000";
    return "";
}

static function JsonObject Capture(string Key, string EventType, string Summary, JsonObject Facts, array<string> Instances, optional string MissionKey, optional JsonObject Details, optional string CapturedLocal)
{
    local JsonObject Result, Participants;
    local string Instance;
    Result = new class'JsonObject';
    Participants = new class'JsonObject';
    foreach Instances(Instance) Participants.ValueArray.AddItem(Instance);
    Result.SetStringValue("key", Key);
    Result.SetStringValue("event_type", EventType);
    Result.SetStringValue("summary", SafeText(Summary));
    Result.SetStringValue("captured_local", CapturedLocal == "" ? CaptureClock() : CapturedLocal);
    Result.SetObject("facts", Facts);
    Result.SetObject("participants", Participants);
    if (MissionKey != "") Result.SetStringValue("mission_key", MissionKey);
    if (Details != none) Result.SetObject("game_data", Details);
    return Result;
}

static function Queue(XComGameState Pending, XComGameState_TNBEventLedger Ledger, string Key, string EventType, string Summary, JsonObject Facts, array<string> Instances, optional string MissionKey, optional JsonObject Details, optional string CapturedLocal)
{
    local XComGameState_TNBEventOutbox Outbox;
    local JsonObject Report;
    if (Ledger == none || Ledger.SeenKeys.Find(Key) != INDEX_NONE) return;
    Outbox = class'XComGameState_TNBEventOutbox'.static.Edit(Pending);
    Report = Capture(Key, EventType, Summary, Facts, Instances, MissionKey, Details, CapturedLocal);
    Report.SetStringValue("clock_zone", Ledger.ClockZone);
    if (Outbox.Add(Key, Report)) Ledger.SeenKeys.AddItem(Key);
    else Ledger.Diagnostic = Outbox.Diagnostic;
}
