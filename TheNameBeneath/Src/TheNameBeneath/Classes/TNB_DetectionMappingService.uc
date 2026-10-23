// Personal detection-stat adapter, not a new ability or squad-wide stealth effect.
class TNB_DetectionMappingService extends TNB_Types;

static function float DetectionModifier(float CurrentModifier, int RangeBasisPoints)
{
    return 1.0 - (1.0 + float(Clamp(RangeBasisPoints, -9900, 100000)) / 10000.0) * (1.0 - CurrentModifier);
}

static function float DetectionDelta(float CurrentModifier, int RangeBasisPoints)
{
    return DetectionModifier(CurrentModifier, RangeBasisPoints) - CurrentModifier;
}

static function bool ShouldApply(bool AlreadyMarked, int RangeBasisPoints)
{
    return !AlreadyMarked && RangeBasisPoints != 0;
}

static function bool Marked(XComGameState_Unit Unit)
{
    local UnitValue Value;
    return Unit != none && Unit.GetUnitValue('TNB_DetectionApplied', Value) && Value.fValue != 0;
}

static function ClearForLaunch(XComGameState_Unit Unit)
{
    local UnitValue Delta;
    local float Current, Base;
    if (!Marked(Unit)) return;
    if (Unit.GetUnitValue('TNB_DetectionDelta', Delta))
    {
        Base = Unit.GetBaseStat(eStat_DetectionModifier);
        Current = Unit.GetCurrentStat(eStat_DetectionModifier);
        Unit.SetBaseMaxStat(eStat_DetectionModifier, Base - Delta.fValue);
        Unit.SetCurrentStat(eStat_DetectionModifier, Current - Delta.fValue);
    }
    Unit.ClearUnitValue('TNB_DetectionApplied');
    Unit.ClearUnitValue('TNB_DetectionDelta');
}

// Fresh launch/transfer callbacks run before native squad initialization resets
// this base stat. A tactical save reload does not run these callbacks.
static function PrepareLaunch(XComGameState Pending)
{
    local XComGameState_Unit Unit;
    if (Pending == none) return;
    foreach Pending.IterateByClassType(class'XComGameState_Unit', Unit)
        ClearForLaunch(Unit);
}

static function ApplyToUnit(XComGameState_Unit Unit, int RangeBasisPoints)
{
    local float Base, Current, Delta;
    if (Unit == none) return;
    if (!ShouldApply(Marked(Unit), RangeBasisPoints)) return;
    Base = Unit.GetBaseStat(eStat_DetectionModifier);
    Current = Unit.GetCurrentStat(eStat_DetectionModifier);
    Delta = DetectionDelta(Current, RangeBasisPoints);
    Unit.SetBaseMaxStat(eStat_DetectionModifier, Base + Delta);
    Unit.SetCurrentStat(eStat_DetectionModifier, Current + Delta);
    // Deliberately freeze this delta for the mission. Later stealth modifiers
    // stack natively: the relative percentage is not guaranteed to remain 20%.
    // Never-cleanup markers survive tactical reload's BeginTactical cleanup.
    Unit.SetUnitFloatValue('TNB_DetectionDelta', Delta, eCleanup_Never);
    Unit.SetUnitFloatValue('TNB_DetectionApplied', 1.0, eCleanup_Never);
}

static function BeginTactical(XComGameState Pending)
{
    local XComGameState_Unit Unit;
    local XComGameState_TNBSoldierLink Link;
    local XComGameState_TNBCampaignLink Campaign;
    if (Pending == none) return;
    Campaign = class'XComGameState_TNBCampaignLink'.static.Get(Pending);
    if (Campaign == none || !Campaign.bOneTimeEffectsCommitted) return;
    // Native BeginTacticalPlay already put every unit in this pending state.
    // Never create/submit another state or edit historical units here.
    foreach Pending.IterateByClassType(class'XComGameState_Unit', Unit)
        if (Unit.IsSoldier() && Unit.GetTeam() == eTeam_XCom && !Marked(Unit))
        {
            Link = class'TNB_StrategyMappingService'.static.SoldierLink(Unit.ObjectID, Pending);
            if (Link != none && Link.CampaignID == Campaign.CampaignID && Link.Snapshot.JourneyID == Campaign.Journey.JourneyID)
                ApplyToUnit(Unit, class'TNB_StrategyMappingService'.static.ActiveTotal(Link.Effects, 'DetectionRange', 'Personal'));
        }
}
