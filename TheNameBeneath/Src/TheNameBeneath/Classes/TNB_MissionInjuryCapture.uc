class TNB_MissionInjuryCapture extends TNB_EventTypes;

static function bool Counts(bool bDeployed, bool bSoldier, bool bGhost, bool bWasInjuredOnMission)
{
    // Deliberately independent of linking and of current strategy recovery time.
    return bDeployed && bSoldier && !bGhost && bWasInjuredOnMission;
}

static function Store(XComGameState_TNBEventLedger Ledger, MissionInjurySnapshot Snapshot)
{
    local int Index;
    Index = Ledger.MissionInjuries.Find('MissionKey', Snapshot.MissionKey);
    if (Index == INDEX_NONE) Ledger.MissionInjuries.AddItem(Snapshot);
    else Ledger.MissionInjuries[Index] = Snapshot;
}

static function Record(XComGameState Pending, XComGameState_TNBEventLedger Ledger, int MissionIndex)
{
    local MissionInjurySnapshot Snapshot;
    local XComGameState_Unit Soldier;
    local int UnitID;
    Snapshot.MissionKey = Ledger.Missions[MissionIndex].Key;
    Snapshot.RosterCount = Ledger.Missions[MissionIndex].UnitIDs.Length;
    Snapshot.bKnown = Snapshot.RosterCount > 0;
    foreach Ledger.Missions[MissionIndex].UnitIDs(UnitID)
    {
        Soldier = class'TNB_EventCaptureService'.static.Unit(UnitID, Pending);
        if (Soldier == none || !Soldier.IsSoldier()) { Snapshot.bKnown = false; continue; }
        if (Counts(true, Soldier.IsSoldier(), Soldier.kAppearance.bGhostPawn, Soldier.WasInjuredOnMission())) Snapshot.Injuries++;
    }
    Store(Ledger, Snapshot);
    class'TNB_ReportingSafety'.static.Trace("MISSION_INJURIES frozen=" $ Snapshot.bKnown $ " roster=" $ Snapshot.RosterCount $ " injured=" $ Snapshot.Injuries, Pending);
}

static function JsonObject CompletionFacts(string Result, bool bDeathsKnown, int Deaths, bool bInjuriesKnown, int Injuries)
{
    local JsonObject Facts;
    Facts = new class'JsonObject'; Facts.SetStringValue("result", Result);
    if (bDeathsKnown) Facts.SetIntValue("squad_deaths", Deaths);
    if (bInjuriesKnown) Facts.SetIntValue("squad_injuries", Injuries);
    return Facts;
}
