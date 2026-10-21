class XComGameState_TNBSoldierLink extends XComGameState_BaseObject dependson(TNB_Types);

var int SchemaVersion;
var StateObjectReference UnitRef;
var string UnitToken;
var string CampaignID;
var string MappingRevision;
var TNB_Types.CharacterSnapshot Snapshot;
var array<TNB_Types.ResolvedEffect> Effects;
var bool bEffectsCommitted;

static function XComGameState_TNBSoldierLink ForUnit(XComGameState_Unit Unit)
{
    local XComGameState_TNBSoldierLink Link;
    if (Unit == none) return none;
    Link = XComGameState_TNBSoldierLink(Unit.FindComponentObject(class'XComGameState_TNBSoldierLink'));
    if (Link == none || Link.UnitRef.ObjectID != Unit.ObjectID || !Link.bEffectsCommitted || Link.SchemaVersion != 1) return none;
    return Link;
}
