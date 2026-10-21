// Read-only result classification; no Long War package dependency or tracker creation.
class TNB_CovertActionOutcome extends Object dependson(XComGameState_CovertAction);

static function bool IsLongWarFailureRisk(name RiskName)
{
    // Verified against installed LWOTC's DefaultCovertActionRisks_LW and
    // Utilities_LW.DidCovertActionFail. Unknown future/custom names stay unknown.
    return RiskName == 'CovertActionRisk_Failure_Easy'
        || RiskName == 'CovertActionRisk_Failure_Moderate'
        || RiskName == 'CovertActionRisk_Failure_Hard';
}

static function string Resolve(array<CovertActionRisk> Risks, bool bRewardsWithheld, optional string ChildAmbushResult)
{
    local CovertActionRisk Risk;
    local bool bLongWarRisk;
    foreach Risks(Risk)
    {
        if (!IsLongWarFailureRisk(Risk.RiskTemplateName)) continue;
        bLongWarRisk = true;
        if (Risk.bOccurs) return "failure";
    }
    // Native/vanilla completion grants the strategic reward even after an ambush;
    // its child tactical result alone must not change that strategic outcome.
    if (!bRewardsWithheld) return "success";
    // LWOTC can also withhold rewards after a failed child ambush. Only use an
    // already-associated captured result, never its mutable global last-ambush tracker.
    if (bLongWarRisk && ChildAmbushResult == "failure") return "failure";
    return "";
}
