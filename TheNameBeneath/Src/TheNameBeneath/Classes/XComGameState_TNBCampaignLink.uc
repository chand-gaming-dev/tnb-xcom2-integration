class XComGameState_TNBCampaignLink extends XComGameState_BaseObject dependson(TNB_Types);

var int SchemaVersion;
var string CampaignID;
var TNB_Types.JourneyContext Journey;
var string MappingRevision;
var array<TNB_Types.ResolvedEffect> Effects;
var array<string> ResourceLedger;
var array<int> ScroungerMonths;
var array<name> FrozenScroungerItems;
var bool bOneTimeEffectsCommitted;
// In this loaded timeline, independent of component lifetime: dismissal/death do not free a character.
var array<string> ReservedCharacterIDs;
var array<int> ReservedUnitIDs;

static function XComGameState_TNBCampaignLink Get(optional XComGameState Pending)
{
    local XComGameState_TNBCampaignLink State;
    if (Pending != none)
        foreach Pending.IterateByClassType(class'XComGameState_TNBCampaignLink', State) return State;
    return XComGameState_TNBCampaignLink(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_TNBCampaignLink', true));
}

function int ResourcePercent(name Resource)
{
    local TNB_Types.ResolvedEffect Effect;
    local int Total;
    foreach Effects(Effect)
        if (Effect.EffectKind == 'ResourcePercent' && Effect.Target == Resource && Effect.Status == "active") Total += Effect.Magnitude;
    return Clamp(Total, -10000, 100000);
}

function bool HasScrounger()
{
    local TNB_Types.ResolvedEffect Effect;
    foreach Effects(Effect)
        if (Effect.EffectKind == 'SupplyDropItem' && Effect.Status == "active") return true;
    return false;
}
