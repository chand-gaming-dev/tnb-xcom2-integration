class TNB_Types extends Object;

struct TraitRecord
{
    var string DefinitionID;
    var int DefinitionVersion;
    var string CatalogVersion;
    var string DisplayName;
    var string Polarity;
    var string AcquisitionKind;
    var string AcquisitionSource;
};

struct SkillRecord
{
    var string DefinitionID;
    var int DefinitionVersion;
    var string CatalogVersion;
    var string DisplayName;
    var bool bProvisional;
};

struct JourneyContext
{
    var string JourneyID;
    var string JourneyTitle;
    var string TitleObservedAt;
    var string GameName;
    var string JourneyStatus;
    var int JourneyVersion;
    var bool bCanManageJourney;
    var string CommanderID;
    var string CommanderName;
    var bool bCharacteristicsAvailable;
    var string ObservedAt;
    var array<TraitRecord> Traits;
    var array<SkillRecord> Skills;
};

struct ResolvedEffect
{
    var name MappingKey;
    var name SourceKind;
    var string SourceID;
    var int SourceVersion;
    var string SourceName;
    var name EffectKind;
    var name Target;
    var int Magnitude;
    var EInventorySlot WeaponSlot;
    var name UtilityCategory;
    var string Status;
    var string Note;
    var int AppliedMagnitude;
};

struct CharacterSnapshot
{
    var string JourneyID;
    var string CommanderID;
    var string CharacterID;
    var string RosterEntryID;
    var string CharacterName;
    var string InstanceID;
    var string SnapshotID;
    var int SnapshotVersion;
    var string IssuedAt;
    var string AuthorizationDecisionID;
    var array<TraitRecord> Traits;
    var array<SkillRecord> Skills;
};

static function bool ReadSnapshot(JsonObject Data, out CharacterSnapshot Result)
{
    local JourneyContext Characteristics;
    local CharacterSnapshot Empty;
    Result = Empty;
    if (Data == none || Data.GetIntValue("feature_version") != 1) return false;
    // A frozen character snapshot must not require a mutable Journey title.
    if (!ReadCharacteristics(Data, Characteristics)) return false;
    Result.JourneyID = Data.GetStringValue("journey_id");
    Result.CommanderID = Data.GetStringValue("commander_id");
    if (Result.JourneyID == "" || Result.CommanderID == "") return false;
    Result.Traits = Characteristics.Traits;
    Result.Skills = Characteristics.Skills;
    Result.CharacterID = Data.GetStringValue("character_id");
    Result.RosterEntryID = Data.GetStringValue("roster_entry_id");
    Result.CharacterName = Data.GetStringValue("character_name");
    Result.InstanceID = Data.GetStringValue("instance_id");
    Result.SnapshotID = Data.GetStringValue("snapshot_id");
    Result.SnapshotVersion = Data.GetIntValue("snapshot_version");
    Result.IssuedAt = Data.GetStringValue("issued_at");
    Result.AuthorizationDecisionID = Data.GetStringValue("authorization_decision_id");
    return Result.CharacterID != "" && Result.RosterEntryID != "" && Result.InstanceID != "" && Result.SnapshotID != "" && Result.AuthorizationDecisionID != "" && Result.SnapshotVersion > 0 && Result.SnapshotVersion <= 3;
}

static function bool ReadJourney(JsonObject Data, out JourneyContext Result)
{
    local JourneyContext Empty;

    Result = Empty;
    if (Data == none || Data.GetIntValue("feature_version") != 1) return false;
    Result.JourneyID = Data.GetStringValue("journey_id");
    Result.JourneyTitle = Data.GetStringValue("journey_title");
    Result.TitleObservedAt = Data.GetStringValue("title_observed_at");
    Result.GameName = Data.GetStringValue("game_name");
    Result.JourneyStatus = Data.GetStringValue("journey_status");
    Result.JourneyVersion = Data.GetIntValue("journey_version");
    Result.bCanManageJourney = Data.GetBoolValue("can_manage_journey");
    Result.CommanderID = Data.GetStringValue("commander_id");
    Result.CommanderName = Data.GetStringValue("commander_name");
    Result.bCharacteristicsAvailable = Data.GetBoolValue("characteristics_available");
    Result.ObservedAt = Data.GetStringValue("observed_at");
    if (Result.JourneyID == "" || Result.CommanderID == "" || !ValidTitle(Result.JourneyTitle)) return false;
    return ReadCharacteristics(Data, Result);
}

static function bool ValidTitle(string Value)
{
    local int Index, Count, Code;
    if (Len(Value) == 0 || Len(Value) > 320) return false;
    for (Index = 0; Index < Len(Value); Index++)
    {
        Code = Asc(Mid(Value, Index, 1));
        // Count Unicode scalar values, matching the API's 160-character limit.
        if (Code >= 55296 && Code <= 56319 && Index + 1 < Len(Value) && Asc(Mid(Value, Index + 1, 1)) >= 56320 && Asc(Mid(Value, Index + 1, 1)) <= 57343) Index++;
        Count++;
    }
    return Count <= 160;
}

static function bool ReadCharacteristics(JsonObject Data, out JourneyContext Result)
{
    local JsonObject Traits, Skills, Entry;
    local TraitRecord Trait;
    local SkillRecord Skill;
    Result.Traits.Length = 0; Result.Skills.Length = 0;
    if (Data == none) return false;
    Traits = Data.GetObject("traits");
    Skills = Data.GetObject("skills");
    if (Traits == none || Skills == none) return false;
    if (Traits.ObjectArray.Length > 128 || Skills.ObjectArray.Length > 128) return false;
    foreach Traits.ObjectArray(Entry)
    {
        if (Entry == none) return false;
        Trait.DefinitionID = Entry.GetStringValue("definition_id");
        Trait.DefinitionVersion = Entry.GetIntValue("definition_version");
        Trait.CatalogVersion = Entry.GetStringValue("catalog_version");
        Trait.DisplayName = Entry.GetStringValue("name");
        Trait.Polarity = Entry.GetStringValue("polarity");
        Trait.AcquisitionKind = Entry.GetStringValue("acquisition_kind");
        Trait.AcquisitionSource = Entry.GetStringValue("acquisition_source");
        if (Trait.DefinitionID == "" || Trait.DefinitionVersion < 1 || Result.Traits.Find('DefinitionID', Trait.DefinitionID) != INDEX_NONE) return false;
        Result.Traits.AddItem(Trait);
    }
    foreach Skills.ObjectArray(Entry)
    {
        if (Entry == none) return false;
        Skill.DefinitionID = Entry.GetStringValue("definition_id");
        Skill.DefinitionVersion = Entry.GetIntValue("definition_version");
        Skill.CatalogVersion = Entry.GetStringValue("catalog_version");
        Skill.DisplayName = Entry.GetStringValue("name");
        Skill.bProvisional = Entry.GetBoolValue("provisional");
        if (Skill.DefinitionID == "" || Skill.DefinitionVersion < 1 || Result.Skills.Find('DefinitionID', Skill.DefinitionID) != INDEX_NONE) return false;
        Result.Skills.AddItem(Skill);
    }
    return true;
}

static function string EscapeUI(string Value)
{
    Value = Repl(Value, "&", "&amp;");
    Value = Repl(Value, "<", "&lt;");
    Value = Repl(Value, ">", "&gt;");
    return Value;
}

static function string SingleLine(string Value)
{
    local int Index, Code;
    local string Result;
    for (Index = 0; Index < Len(Value); Index++)
    {
        Code = Asc(Mid(Value, Index, 1));
        Result $= (Code < 32 || (Code >= 127 && Code <= 159) || Code == 8232 || Code == 8233) ? " " : Mid(Value, Index, 1);
    }
    return Result;
}

static function string DisplayTitle(string Value)
{
    return Value == "" ? "Journey title unavailable (refresh to retrieve)" : SingleLine(Value);
}

static function string Compact(string Value, int Maximum)
{
    Value = SingleLine(Value);
    if (Len(Value) <= Maximum) return Value;
    if (Asc(Mid(Value, Maximum - 1, 1)) >= 55296 && Asc(Mid(Value, Maximum - 1, 1)) <= 56319) Maximum--;
    return Left(Value, Maximum) $ "...";
}
