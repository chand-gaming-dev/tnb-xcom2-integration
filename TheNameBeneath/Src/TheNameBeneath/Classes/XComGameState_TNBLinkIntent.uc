// Local reservation only, never reported as a completed link or an applied bonus.
class XComGameState_TNBLinkIntent extends XComGameState_BaseObject;

var int SchemaVersion;
var StateObjectReference UnitRef;
var string CampaignID;
var string JourneyID;
var string UnitToken;
var string UnitFingerprint;
var string CharacterID;
var string RosterEntryID;
var string CharacterName;
var bool bCommitted;

static function XComGameState_TNBLinkIntent ForUnit(XComGameState_Unit Unit)
{
    if (Unit == none) return none;
    return XComGameState_TNBLinkIntent(Unit.FindComponentObject(class'XComGameState_TNBLinkIntent'));
}
