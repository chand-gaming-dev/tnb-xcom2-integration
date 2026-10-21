// Keep shared types before the mapping struct in the SDK's class parse order.
// Configuration fields and mapping semantics are unchanged.
class TNB_MappingConfig extends TNB_Types config(TheNameBeneath);

struct MappingRow
{
    var name Key;
    var name Context;
    var name SourceKind;
    var string SourceID;
    var int MinVersion;
    var int MaxVersion; // zero = unbounded, explicitly chosen by the player
    var name EffectKind;
    var name Target;
    var int Magnitude;
    var EInventorySlot WeaponSlot;
    var name UtilityCategory;
    var int Priority;
    var bool bEnabled;
    var string Note;
};

var config array<MappingRow> ShippedMappings;
var config array<MappingRow> Overrides;
var config array<name> ScroungerItems;
var config string MappingRevision;
