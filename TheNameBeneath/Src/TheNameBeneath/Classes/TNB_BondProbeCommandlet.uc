// Pure native policy/shape checks. No live campaign, history or remote writes.
class TNB_BondProbeCommandlet extends Commandlet dependson(TNB_EventTypes);

event int Main(string Params)
{
    local array<BondOccurrence> Entries;
    local BondOccurrence Record;
    local string Key, FormedKey;
    local JsonObject Report, Reversed;
    Entries.Length = 0;
    if (class'TNB_BondCaptureService'.static.PairKey(17, 29) != class'TNB_BondCaptureService'.static.PairKey(29, 17)) return 1;
    if (!class'TNB_BondCaptureService'.static.ValidTransition('BondCreated', 0, 0, 1, 1)) return 2;
    if (class'TNB_BondCaptureService'.static.ValidTransition('OnBondAvailable', 0, 0, 1, 1)) return 3;
    if (class'TNB_BondCaptureService'.static.ValidTransition('BondCreated', 1, 1, 1, 1)) return 4;
    if (class'TNB_BondCaptureService'.static.ValidTransition('BondLevelUpComplete', 1, 1, 2, 1)) return 5;
    if (!class'TNB_BondCaptureService'.static.ValidTransition('BondLevelUpComplete', 1, 1, 2, 2)) return 6;
    if (class'TNB_BondCaptureService'.static.ValidTransition('BondLevelUpComplete', 2, 2, 1, 1)) return 7;
    if (!class'TNB_BondCaptureService'.static.NextOccurrence(Entries, "bond:17:29", 0, 1, 42, Record, Key)) return 8;
    FormedKey = Key; Entries.AddItem(Record);
    if (class'TNB_BondCaptureService'.static.NextOccurrence(Entries, "bond:17:29", 0, 1, 42, Record, Key)) return 9;
    if (!class'TNB_BondCaptureService'.static.NextOccurrence(Entries, "bond:17:29", 1, 2, 44, Record, Key) || Record.Episode != 1 || Key == FormedKey) return 10;
    Entries[0] = Record;
    if (!class'TNB_BondCaptureService'.static.NextOccurrence(Entries, "bond:17:29", 0, 1, 48, Record, Key) || Record.Episode != 2 || Key == FormedKey) return 11;
    Report = class'TNB_BondCaptureService'.static.Capture(FormedKey, 'BondCreated', 17, "Ren" $ Chr(233), "33333333-3333-4333-8333-333333333333", 29, "Snow " $ Chr(38634), "44444444-4444-4444-8444-444444444444", 0, 1);
    Reversed = class'TNB_BondCaptureService'.static.Capture(FormedKey, 'BondCreated', 29, "Snow " $ Chr(38634), "44444444-4444-4444-8444-444444444444", 17, "Ren" $ Chr(233), "33333333-3333-4333-8333-333333333333", 0, 1);
    if (Report.GetStringValue("event_type") != "threadline.relationship.formed") return 15;
    Report.SetStringValue("captured_local", "2000-01-01T00:00:00.000"); Reversed.SetStringValue("captured_local", "2000-01-01T00:00:00.000");
    if (class'TNB_EventFactory'.static.ASCIIJson(Report) != class'TNB_EventFactory'.static.ASCIIJson(Reversed)) return 12;
    Report.SetStringValue("captured_local", class'TNB_EventFactory'.static.CaptureClock());
    `log("TNB_NATIVE_BOND_CAPTURE=" $ class'TNB_EventFactory'.static.ASCIIJson(Report));
    Report = class'TNB_BondCaptureService'.static.Capture("bond:17:29:episode:1:level:2", 'BondLevelUpComplete', 17, "Ren" $ Chr(233), "33333333-3333-4333-8333-333333333333", 29, "Unlinked partner", "", 1, 2);
    if (Report.GetObject("participants").ValueArray.Length != 1) return 13;
    if (Report.GetStringValue("event_type") != "threadline.relationship.developed" || Report.GetObject("facts").GetObject("game_local_participants").ObjectArray.Length != 1) return 16;
    `log("TNB_NATIVE_BOND_CAPTURE=" $ class'TNB_EventFactory'.static.ASCIIJson(Report));
    if (class'TNB_BondCaptureService'.static.Capture("none", 'BondCreated', 17, "A", "", 29, "B", "", 0, 1) != none) return 14;
    `log("TNB_BONDS_PASS: native formation/level-up, reciprocal levels, future-only deltas, pair symmetry, duplicate suppression, re-bond episodes and linked/local partner shapes.");
    return 0;
}

defaultproperties
{
    IsClient=false
    IsServer=false
    IsEditor=true
    LogToConsole=true
}
