// Pure identity/metadata helpers. No random-stream changes, HTTP, native mission writes
// or independent state submissions. Called only while preparing a fresh launch state.
class TNB_MissionAttemptService extends TNB_EventTypes;

static function string NormalizeLaunchID(string NativeID)
{
    local string Result;
    local int Index;
    if (Len(NativeID) > 38) return "";
    Result = Caps(Repl(Repl(Repl(NativeID, "-", ""), "{", ""), "}", ""));
    if (Len(Result) != 32 || Result == "00000000000000000000000000000000") return "";
    for (Index = 0; Index < Len(Result); Index++)
        if (InStr("0123456789ABCDEF", Mid(Result, Index, 1)) == INDEX_NONE) return "";
    return Result;
}

static function string AttemptKey(string AttemptID)
{
    return "tactical-attempt:" $ AttemptID;
}

static function bool Resolve(out array<TacticalMissionAttempt> Existing, string SourceMissionKey, string NativeLaunchID, out TacticalMissionAttempt Attempt, out int Created)
{
    local string ID;
    local int Index;
    local TacticalMissionAttempt Empty;
    Attempt = Empty; Created = 0;
    ID = NormalizeLaunchID(NativeLaunchID);
    if (ID == "" || SourceMissionKey == "") return false;
    Index = Existing.Find('AttemptID', ID);
    if (Index != INDEX_NONE)
    {
        // Repeated hook for the same supplied launch transaction is idempotent.
        Attempt = Existing[Index];
        return Attempt.Key == AttemptKey(ID) && Attempt.SourceMissionKey == SourceMissionKey;
    }
    if (Existing.Length >= 4096) return false;
    Attempt.AttemptID = ID; Attempt.Key = AttemptKey(ID); Attempt.SourceMissionKey = SourceMissionKey;
    Existing.AddItem(Attempt); Created = 1;
    return true;
}

static function AddDetails(JsonObject Details, XComGameState_TNBEventLedger Ledger, string Key)
{
    local int Index;
    if (Details == none || Ledger == none) return;
    Index = Ledger.TacticalAttempts.Find('Key', Key);
    // No metadata changes at all to legacy/in-progress or covert reports.
    if (Index == INDEX_NONE) return;
    Details.SetStringValue("mission_attempt_id", Ledger.TacticalAttempts[Index].AttemptID);
    Details.SetStringValue("mission_source_key", Ledger.TacticalAttempts[Index].SourceMissionKey);
}
