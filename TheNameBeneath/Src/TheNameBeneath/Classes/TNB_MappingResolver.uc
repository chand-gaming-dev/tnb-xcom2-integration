class TNB_MappingResolver extends TNB_Types dependson(TNB_MappingConfig);

static function bool StatType(name Target, out ECharStatType Stat)
{
    switch (Target)
    {
        case 'eStat_HP': Stat = eStat_HP; return true;
        case 'eStat_Will': Stat = eStat_Will; return true;
        case 'eStat_Offense': Stat = eStat_Offense; return true;
        case 'eStat_Defense': Stat = eStat_Defense; return true;
        case 'eStat_CritChance': Stat = eStat_CritChance; return true;
        case 'eStat_Hacking': Stat = eStat_Hacking; return true;
        case 'eStat_SightRadius': Stat = eStat_SightRadius; return true;
        case 'eStat_Mobility': Stat = eStat_Mobility; return true;
        case 'eStat_Dodge': Stat = eStat_Dodge; return true;
    }
    return false;
}

static function bool ValidRow(TNB_MappingConfig.MappingRow Row)
{
    local ECharStatType Stat;
    if (Row.Key == '' || Row.MinVersion < 1 || (Row.MaxVersion != 0 && Row.MaxVersion < Row.MinVersion)) return false;
    if (Row.Context != 'Character' && Row.Context != 'Commander') return false;
    if (Row.SourceKind != 'Trait' && Row.SourceKind != 'Skill') return false;
    if (!Row.bEnabled) return true;
    if (Row.Context == 'Character')
    {
        if (Row.EffectKind == 'Stat') return StatType(Row.Target, Stat) && Abs(Row.Magnitude) <= 10000;
        if (Row.EffectKind == 'Ability') return Row.Target != '';
        if (Row.EffectKind == 'CombatIntelligence') return Row.Magnitude == 1;
        if (Row.EffectKind == 'RecoveryDuration') return Row.Target == 'Wound' && Row.Magnitude >= -9900 && Row.Magnitude <= 100000;
        if (Row.EffectKind == 'ParticipantResource') return (Row.Target == 'Supplies' || Row.Target == 'Intel') && Row.Magnitude >= -10000 && Row.Magnitude <= 100000;
        if (Row.EffectKind == 'DetectionRange') return Row.Target == 'Personal' && Row.Magnitude >= -9900 && Row.Magnitude <= 100000;
    }
    else
    {
        if (Row.EffectKind == 'ResourcePercent') return (Row.Target == 'Supplies' || Row.Target == 'Intel') && Row.Magnitude >= -10000 && Row.Magnitude <= 100000;
        if (Row.EffectKind == 'ResourceOnce') return (Row.Target == 'Supplies' || Row.Target == 'Intel') && Abs(Row.Magnitude) <= 100000;
        if (Row.EffectKind == 'StaffOnce') return (Row.Target == 'Engineer' || Row.Target == 'Scientist') && Row.Magnitude >= 1 && Row.Magnitude <= 10;
        if (Row.EffectKind == 'AvatarOnce') return Abs(Row.Magnitude) <= 12;
        if (Row.EffectKind == 'SupplyDropItem') return Row.Magnitude == 1;
        if (Row.EffectKind == 'ResearchSpeed') return Row.Target == 'Science' && Row.Magnitude >= -10000 && Row.Magnitude <= 100000;
        if (Row.EffectKind == 'ContactOnce') return Row.Magnitude >= 1 && Row.Magnitude <= 10;
        if (Row.EffectKind == 'RosterIntelligenceOnce') return Row.Magnitude >= 1 && Row.Magnitude <= 16;
        if (Row.EffectKind == 'CovertDurationOnce') return Row.Magnitude >= -9900 && Row.Magnitude < 0;
        if (Row.EffectKind == 'CovertRisk') return class'TNB_StrategyMappingService'.static.RiskTarget(Row.Target) && Abs(Row.Magnitude) <= 100;
        if (Row.EffectKind == 'RecoveryDuration') return (Row.Target == 'Will' || Row.Target == 'Wound') && Row.Magnitude >= -9900 && Row.Magnitude <= 100000;
    }
    return false;
}

static function array<ResolvedEffect> Resolve(name Context, array<TraitRecord> Traits, array<SkillRecord> Skills)
{
    return ResolveUsing(Context, Traits, Skills, class'TNB_MappingConfig'.default.ShippedMappings, class'TNB_MappingConfig'.default.Overrides);
}

static function array<ResolvedEffect> ResolveUsing(name Context, array<TraitRecord> Traits, array<SkillRecord> Skills, array<TNB_MappingConfig.MappingRow> Shipped, array<TNB_MappingConfig.MappingRow> Overrides)
{
    local array<TNB_Types.ResolvedEffect> Effects;
    local TNB_Types.TraitRecord Trait;
    local TNB_Types.SkillRecord Skill;
    if (Shipped.Length > 1024 || Overrides.Length > 1024) { Effects.Length = 513; return Effects; }
    foreach Traits(Trait)
    {
        ResolveSource(Context, 'Trait', Trait.DefinitionID, Trait.DefinitionVersion, Trait.DisplayName, Shipped, Overrides, Effects);
        if (Effects.Length > 512) return Effects;
    }
    foreach Skills(Skill)
    {
        ResolveSource(Context, 'Skill', Skill.DefinitionID, Skill.DefinitionVersion, Skill.DisplayName, Shipped, Overrides, Effects);
        if (Effects.Length > 512) return Effects;
    }
    return Effects;
}

static function ResolveSource(name Context, name Kind, string ID, int Version, string DisplayName, array<TNB_MappingConfig.MappingRow> Shipped, array<TNB_MappingConfig.MappingRow> Overrides, out array<ResolvedEffect> Effects)
{
    local array<name> Keys;
    local TNB_MappingConfig.MappingRow Row, Best;
    local TNB_Types.ResolvedEffect Effect;
    local name Key;
    local int Pass, Score, BestScore;
    local bool Found, Ambiguous;
    local array<TNB_MappingConfig.MappingRow> Rows;

    // Include override-only keys; exact-version overrides outrank ranged overrides and shipped rows.
    Rows = Shipped;
    for (Pass = 0; Pass < 2; Pass++)
    {
        if (Pass == 1) Rows = Overrides;
        foreach Rows(Row)
            if (Matches(Row, Context, Kind, ID, Version) && Keys.Find(Row.Key) == INDEX_NONE) Keys.AddItem(Row.Key);
    }
    if (Keys.Length == 0)
    {
        Effect.SourceKind = Kind; Effect.SourceID = ID; Effect.SourceVersion = Version; Effect.SourceName = DisplayName;
        Effect.Status = "unmapped"; Effect.Note = "No configured mapping for this definition/version.";
        Effects.AddItem(Effect);
        return;
    }
    foreach Keys(Key)
    {
        Found = false; Ambiguous = false; BestScore = -1;
        for (Pass = 0; Pass < 2; Pass++)
        {
            if (Pass == 0) Rows = Shipped;
            else Rows = Overrides;
            foreach Rows(Row)
            {
                if (Row.Key != Key || !Matches(Row, Context, Kind, ID, Version)) continue;
                Score = Pass * 2000000 + ((Row.MinVersion == Version && Row.MaxVersion == Version) ? 1000000 : 0) + Clamp(Row.Priority, -100000, 100000) + 100000;
                if (!Found || Score > BestScore) { Best = Row; BestScore = Score; Found = true; Ambiguous = false; }
                else if (Score == BestScore) Ambiguous = true;
            }
        }
        Effect.MappingKey = Key; Effect.SourceKind = Kind; Effect.SourceID = ID; Effect.SourceVersion = Version; Effect.SourceName = DisplayName;
        Effect.EffectKind = Best.EffectKind; Effect.Target = Best.Target; Effect.Magnitude = Best.Magnitude;
        Effect.WeaponSlot = Best.WeaponSlot; Effect.UtilityCategory = Best.UtilityCategory; Effect.Note = Best.Note;
        Effect.AppliedMagnitude = 0;
        if (Ambiguous) { Effect.Status = "skipped"; Effect.Note = "Conflicting equally ranked mapping rows."; }
        else if (!ValidRow(Best)) { Effect.Status = "skipped"; Effect.Note = "Invalid mapping configuration."; }
        else if (!Best.bEnabled) Effect.Status = "disabled";
        else Effect.Status = "resolved";
        Effects.AddItem(Effect);
    }
}

static function bool Matches(TNB_MappingConfig.MappingRow Row, name Context, name Kind, string ID, int Version)
{
    return Row.Context == Context && Row.SourceKind == Kind && Row.SourceID == ID && Version >= Row.MinVersion && (Row.MaxVersion == 0 || Version <= Row.MaxVersion);
}

static function string Describe(ResolvedEffect Effect)
{
    local string Amount;
    Amount = ((Effect.Magnitude > 0) ? "+" : "") $ string(Effect.Magnitude);
    if (Effect.EffectKind == 'Ability') return "Ability: " $ string(Effect.Target);
    if (Effect.EffectKind == 'ResourcePercent') return ((Effect.Magnitude > 0) ? "+" : "") $ string(float(Effect.Magnitude) / 100.0) $ "% " $ string(Effect.Target) $ " on qualifying gains";
    if (Effect.EffectKind == 'ParticipantResource') return ((Effect.Magnitude > 0) ? "+" : "") $ string(float(Effect.Magnitude) / 100.0) $ "% " $ string(Effect.Target) $ " rewards from missions/covert actions this soldier participates in";
    if (Effect.EffectKind == 'SupplyDropItem') return "1 random common item at each monthly rollover (even with no income)";
    if (Effect.EffectKind == 'DetectionRange') return "Increased enemy detection range (" $ class'TNB_EffectPresentation'.static.Percentage(Effect.Magnitude) $ " at initialization; native stealth stacking)";
    if (Effect.EffectKind == 'CovertRisk') return Amount $ " percentage points: " $ string(Effect.Target) $ " (eligible covert risks only)";
    if (Effect.EffectKind == 'RecoveryDuration') return ((Effect.Magnitude > 0) ? "+" : "") $ string(float(Effect.Magnitude) / 100.0) $ "% " $ string(Effect.Target) $ " recovery duration";
    if (Effect.EffectKind == 'CombatIntelligence') return "+1 Combat Intelligence tier (maximum Savant)";
    if (Effect.EffectKind == 'ContactOnce') return Amount $ " Resistance contact capacity (once; normal contact costs still apply)";
    if (Effect.EffectKind == 'RosterIntelligenceOnce') return string(Effect.Magnitude) $ " random eligible barracks soldiers: +1 Combat Intelligence tier each (once; no retroactive AP)";
    if (Effect.EffectKind == 'CovertDurationOnce') return string(float(-Effect.Magnitude) / 100.0) $ "% shorter covert actions (registered once)";
    if (Effect.EffectKind == 'ResearchSpeed') return ((Effect.Magnitude > 0) ? "+" : "") $ string(float(Effect.Magnitude) / 100.0) $ "% science-based research speed";
    if (Effect.EffectKind == 'AvatarOnce') return Amount $ " Avatar progress (once)";
    if (Effect.EffectKind == 'StaffOnce' || Effect.EffectKind == 'ResourceOnce') return Amount @ string(Effect.Target) $ " (once)";
    if (Effect.EffectKind == 'Stat') return Amount @ string(Effect.Target);
    return Effect.Note;
}

static function string Report(array<ResolvedEffect> Effects, bool bCommitted)
{
    local TNB_Types.ResolvedEffect Effect;
    local string Body;
    if (Effects.Length == 0) return "No Traits or Skills; no bonuses applied.";
    foreach Effects(Effect)
    {
        Body $= "\n" $ string(Effect.SourceKind) $ ": " $ class'TNB_Types'.static.EscapeUI(Effect.SourceName) $ " - ";
        Body $= class'TNB_Types'.static.EscapeUI(Describe(Effect));
        Body $= " [" $ (bCommitted ? Effect.Status : ((Effect.Status == "resolved") ? "proposed" : Effect.Status)) $ "]";
        if (Effect.Note != "") Body $= " " $ class'TNB_Types'.static.EscapeUI(Effect.Note);
    }
    return Body;
}
