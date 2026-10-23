// Read-only UI formatting. Never resolves mappings, modifies the frozen ledger,
// grants an ability, or changes gameplay. Raw labels are escaped by callers.
class TNB_EffectPresentation extends TNB_Types;

static function string Signed(int Amount)
{
    return ((Amount > 0) ? "+" : "") $ Amount;
}

static function string StatLabel(name Target)
{
    switch (Target)
    {
        case 'eStat_HP': return "Health";
        case 'eStat_Offense': return "Aim";
        case 'eStat_Defense': return "Defense";
        case 'eStat_Will': return "Will";
        case 'eStat_Mobility': return "Mobility";
        case 'eStat_Dodge': return "Dodge";
        case 'eStat_Hacking': return "Hack";
        case 'eStat_CritChance': return "Critical chance";
        case 'eStat_ArmorMitigation': return "Armor";
        case 'eStat_SightRadius': return "Sight radius";
    }
    return string(Target);
}

static function string AbilityName(name Target)
{
    local X2AbilityTemplate Template;
    Template = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(Target);
    if (Template != none && Template.LocFriendlyName != "") return Template.LocFriendlyName;
    return string(Target);
}

static function string Percentage(int BasisPoints)
{
    local int AbsoluteValue, Whole, Fraction;
    local string Prefix, Decimals;
    AbsoluteValue = (BasisPoints < 0) ? -BasisPoints : BasisPoints;
    Prefix = (BasisPoints < 0) ? "-" : ((BasisPoints > 0) ? "+" : "");
    Whole = AbsoluteValue / 100; Fraction = AbsoluteValue % 100;
    if (Fraction == 0) return Prefix $ Whole $ "%";
    Decimals = (Fraction % 10 == 0) ? string(Fraction / 10) : ((Fraction < 10) ? "0" : "") $ Fraction;
    return Prefix $ Whole $ "." $ Decimals $ "%";
}

static function string Summary(ResolvedEffect Effect)
{
    if (Effect.EffectKind == 'Stat') return Signed(Effect.Magnitude) @ StatLabel(Effect.Target);
    if (Effect.EffectKind == 'Ability') return AbilityName(Effect.Target);
    if (Effect.EffectKind == 'ResourcePercent') return Percentage(Effect.Magnitude) @ string(Effect.Target);
    if (Effect.EffectKind == 'RecruitCostPercent') return Percentage(Effect.Magnitude) @ "recruit hiring cost";
    if (Effect.EffectKind == 'SupplyDropItem') return "1 item / monthly rollover";
    if (Effect.EffectKind == 'DetectionRange') return "Increased enemy detection range (" $ Percentage(Effect.Magnitude) $ " baseline)";
    if (Effect.EffectKind == 'RecoveryDuration') return Percentage(Effect.Magnitude) @ (Effect.Target == 'Will' ? "fatigue recovery duration" : "wound recovery duration");
    if (Effect.EffectKind == 'ResearchSpeed') return Percentage(Effect.Magnitude) @ "science-based research speed";
    if (Effect.EffectKind == 'CovertDurationOnce') return Percentage(Effect.Magnitude) @ "covert-action duration";
    if (Effect.EffectKind == 'ContactOnce') return Signed(Effect.Magnitude) @ "Resistance contact capacity";
    if (Effect.EffectKind == 'RosterIntelligenceOnce') return string(Effect.Magnitude) $ " barracks soldiers: +1 Combat Intelligence tier";
    if (Effect.EffectKind == 'ParticipantResource') return Percentage(Effect.Magnitude) @ string(Effect.Target) $ " from this soldier's missions/covert actions";
    if (Effect.EffectKind == 'CovertRisk') return Signed(Effect.Magnitude) $ " pp covert " $ RiskLabel(Effect.Target) $ " risk";
    return class'TNB_MappingResolver'.static.Describe(Effect);
}

static function string RiskLabel(name Target)
{
    if (Target == 'CovertActionRisk_Ambush') return "ambush";
    if (Target == 'CovertActionRisk_SoldierWounded') return "injury";
    if (Target == 'CovertActionRisk_SoldierCaptured') return "capture";
    return string(Target);
}

static function string StatusBadge(string Status, bool Committed)
{
    if (!Committed && Status == "resolved") return "preview";
    switch (Status)
    {
        case "available": return "granted";
        case "already_present": return "already owned";
        case "missing_template": return "unavailable";
        case "active": return "ongoing";
        case "no_eligible_change": return "no change";
        case "unmapped": return "unmapped";
    }
    return Repl(Status, "_", " ");
}

static function string StatusText(string Status, bool Committed)
{
    if (!Committed && Status == "resolved") return "Preview - not applied";
    switch (Status)
    {
        case "applied": return "Applied";
        case "active": return "Active ongoing modifier";
        case "no_eligible_change": return "No eligible change at connection - not deferred";
        case "available": return "Granted by this link";
        case "already_present": return "Already owned at linking - no duplicate";
        case "missing_template": return "Unavailable at linking - ability template missing";
        case "unmapped": return "No configured effect";
        case "disabled": return "Disabled in mapping configuration";
        case "skipped": return "Skipped - see explanation";
        case "already_at_cap": return "Already at maximum";
        case "resolved": return "Configured";
    }
    return Repl(Status, "_", " ");
}

// Pure checks only; run with the existing policy checks when templates load.
static function bool RunChecks()
{
    local ResolvedEffect Effect;
    if (Percentage(500) != "+5%" || Percentage(-1000) != "-10%" || Percentage(0) != "0%") return false;
    if (Percentage(125) != "+1.25%" || Percentage(-105) != "-1.05%" || Percentage(150) != "+1.5%" || Percentage(5) != "+0.05%") return false;
    Effect.EffectKind = 'Stat'; Effect.Target = 'eStat_Will'; Effect.Magnitude = -5;
    if (Summary(Effect) != "-5 Will" || StatLabel('eStat_SightRadius') != "Sight radius") return false;
    if (StatusText("available", true) != "Granted by this link" || StatusText("already_present", true) != "Already owned at linking - no duplicate") return false;
    if (StatusText("resolved", false) != "Preview - not applied" || InStr(StatusText("missing_template", true), "Unavailable") != 0) return false;
    if (StatusBadge("already_present", true) != "already owned" || StatusBadge("missing_template", true) != "unavailable" || StatusBadge("active", true) != "ongoing") return false;
    return InStr(TimingText('ResourceOnce', true), "already processed") != INDEX_NONE && InStr(TimingText('ResourcePercent', true), "not existing stock") != INDEX_NONE;
}

static function string TimingText(name EffectKind, bool Committed)
{
    switch (EffectKind)
    {
        case 'DetectionRange': return "Personal penalty set at tactical initialization. Other stealth effects stack normally, so the relative percentage afterward can vary. Not a fixed tile penalty; no ally bonus or sight-radius change.";
        case 'StaffOnce':
        case 'ResourceOnce':
        case 'AvatarOnce': return Committed ? "One-time reward: already processed at campaign connection; viewing never repeats it." : "One-time reward: processed when you confirm campaign connection.";
        case 'ContactOnce':
        case 'RosterIntelligenceOnce':
        case 'CovertDurationOnce': return Committed ? "Registered once at campaign connection; viewing never repeats it. See the saved application details." : "Registered once when you confirm campaign connection.";
        case 'RecoveryDuration': return "Ongoing recovery-duration adjustment. Opposing duration adjustments add before conversion to recovery speed; native hour rounding applies. Tactical damage is unchanged.";
        case 'CovertRisk': return "Ongoing adjustment to existing eligible covert-action risks only. Native protections and final 0-100% limits still apply.";
        case 'ResearchSpeed': return "Ongoing Science Score modifier, including Shadow Chamber research. Does not speed Proving Ground projects or breakthroughs that ignore Science Score. Native rounding applies; no scientists or prerequisite unlocks are granted.";
        case 'RecruitCostPercent': return "Ongoing Supplies cost adjustment for standard Recruit Soldiers purchases, after normal discounts and native rounding. Midnight Raids still applies. Free recruits stay free; reward recruits, delivery time and candidate count are unchanged.";
        case 'ResourcePercent': return "Ongoing modifier on supported positive resource gains, not existing stock. Whole-resource rounding applies.";
        case 'ParticipantResource': return "Only actual positive mission/covert-action rewards with this linked soldier on the retained deployment/assignment roster. Adds to eligible Commander percentages against the original reward; no reward means no change. Supplies cannot fall below zero.";
        case 'SupplyDropItem': return "Ongoing: one random common item at each monthly rollover, even with zero supply income. A dismissible popup identifies the item added to inventory.";
    }
    return "Saved link-time effect; viewing does not change or reapply it.";
}

static function string AbilityDetails(ResolvedEffect Effect, XComGameState_Unit Unit)
{
    local X2AbilityTemplate Template;
    local string Body;
    Template = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(Effect.Target);
    if (Template == none) return "Currently unavailable: the mapped ability template is not installed. Other bonuses are unaffected. No substitute is granted.";
    Body = "Installed ability: " $ class'TNB_Types'.static.EscapeUI(Template.LocFriendlyName != "" ? Template.LocFriendlyName : string(Effect.Target));
    Body $= "\nTactical visibility and use depend on the ability's normal requirements.";
    if (Template.HasLongDescription()) Body $= "\n\n" $ Template.GetMyLongDescription(, Unit);
    else if (Template.LocHelpText != "") Body $= "\n\n" $ Template.GetMyHelpText(, Unit);
    return Body;
}

static function string AbilityImage(name Target)
{
    local X2AbilityTemplate Template;
    Template = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(Target);
    return (Template != none && Template.IconImage != "") ? SafeImage(Template.IconImage) : class'UIUtilities_Image'.const.UnknownAbilityIcon;
}

// Treat absent/broken package paths as unavailable artwork, not a rainbow texture.
static function string SafeImage(string Path)
{
    Path = class'UIUtilities_Image'.static.ValidateImagePath(Path);
    if (Left(Path, 7) == "img:///" && DynamicLoadObject(Mid(Path, 7), class'Texture2D', true) != none) return Path;
    return class'UIUtilities_Image'.const.UnknownAbilityIcon;
}

static function string StatImage(name Target)
{
    // Native PCS/perk artwork; no dependency on another mod's icon package.
    switch (Target)
    {
        case 'eStat_HP': return "img:///UILibrary_Common.implants_health";
        case 'eStat_Offense': return "img:///UILibrary_Common.implants_offense";
        case 'eStat_Will': return "img:///UILibrary_Common.implants_will";
        case 'eStat_Mobility': return "img:///UILibrary_Common.implants_mobility";
        case 'eStat_Defense': return "img:///UILibrary_PerkIcons.UIPerk_aimcover";
        case 'eStat_Dodge': return "img:///UILibrary_PerkIcons.UIPerk_lightningreflexes";
        case 'eStat_Hacking': return "img:///UILibrary_PerkIcons.UIPerk_hack";
        case 'eStat_CritChance': return "img:///UILibrary_PerkIcons.UIPerk_aggression";
        case 'eStat_ArmorMitigation': return "img:///UILibrary_PerkIcons.UIPerk_extrapadding";
        case 'eStat_SightRadius': return "img:///UILibrary_PerkIcons.UIPerk_squadsight";
    }
    return class'UIUtilities_Image'.const.UnknownAbilityIcon;
}

static function string EffectImage(ResolvedEffect Effect)
{
    if (Effect.EffectKind == 'Ability') return AbilityImage(Effect.Target);
    if (Effect.EffectKind == 'Stat') return StatImage(Effect.Target);
    if (Effect.EffectKind == 'CombatIntelligence') return class'UIUtilities_Image'.const.EventQueue_Science;
    if (Effect.EffectKind == 'RosterIntelligenceOnce') return class'UIUtilities_Image'.const.EventQueue_Science;
    if (Effect.EffectKind == 'ResearchSpeed') return class'UIUtilities_Image'.const.EventQueue_Science;
    if (Effect.EffectKind == 'DetectionRange') return StatImage('eStat_SightRadius');
    if (Effect.EffectKind == 'RecoveryDuration') return StatImage(Effect.Target == 'Will' ? 'eStat_Will' : 'eStat_HP');
    if (Effect.EffectKind == 'CovertRisk' || Effect.EffectKind == 'CovertDurationOnce' || Effect.EffectKind == 'ContactOnce') return StatImage('eStat_SightRadius');
    if (Effect.EffectKind == 'ResourcePercent' || Effect.EffectKind == 'ResourceOnce' || Effect.EffectKind == 'ParticipantResource' || Effect.EffectKind == 'RecruitCostPercent')
    {
        if (Effect.Target == 'Supplies') return SafeImage("img:///UILibrary_XPACK_StrategyImages.Invx_Supplies");
        if (Effect.Target == 'Intel') return SafeImage("img:///UILibrary_XPACK_StrategyImages.Invx_Intel");
    }
    if (Effect.EffectKind == 'StaffOnce') return Effect.Target == 'Engineer' ? class'UIUtilities_Image'.const.AlertIcon_Engineering : class'UIUtilities_Image'.const.AlertIcon_Science;
    if (Effect.EffectKind == 'AvatarOnce') return class'UIUtilities_Image'.const.EventQueue_Alien;
    if (Effect.EffectKind == 'SupplyDropItem') return class'UIUtilities_Image'.const.LootIcon_Loot;
    return class'UIUtilities_Image'.const.UnknownAbilityIcon;
}

static function string CommittedSummary(ResolvedEffect Effect)
{
    if (Effect.EffectKind == 'Stat' && Effect.Status == "applied") return Signed(Effect.AppliedMagnitude) @ StatLabel(Effect.Target);
    if (Effect.Status == "applied" && IsOneTime(Effect.EffectKind)) Effect.Magnitude = Effect.AppliedMagnitude;
    return Summary(Effect);
}

static function bool IsOneTime(name Kind)
{
    return Kind == 'StaffOnce' || Kind == 'ResourceOnce' || Kind == 'AvatarOnce' || Kind == 'ContactOnce' || Kind == 'RosterIntelligenceOnce' || Kind == 'CovertDurationOnce';
}

static function string TimingBadge(name Kind)
{
    if (IsOneTime(Kind)) return "ONE-TIME";
    if (Kind == 'SupplyDropItem') return "MONTHLY";
    if (Kind == 'ResourcePercent' || Kind == 'RecoveryDuration' || Kind == 'CovertRisk' || Kind == 'ResearchSpeed' || Kind == 'ParticipantResource' || Kind == 'DetectionRange' || Kind == 'RecruitCostPercent') return "ONGOING";
    return "SAVED";
}

static function EUIState EffectColor(ResolvedEffect Effect)
{
    local int Amount;
    if (Effect.Status == "missing_template" || Effect.Status == "unmapped" || Effect.Status == "disabled" || Effect.Status == "skipped" || Effect.Status == "no_eligible_change") return eUIState_Warning;
    if (Effect.Status == "active" || Effect.Status == "applied")
    {
        Amount = Effect.Status == "active" ? Effect.Magnitude : Effect.AppliedMagnitude;
        if (Effect.EffectKind == 'AvatarOnce' || Effect.EffectKind == 'RecoveryDuration' || Effect.EffectKind == 'CovertRisk' || Effect.EffectKind == 'CovertDurationOnce' || Effect.EffectKind == 'DetectionRange' || Effect.EffectKind == 'RecruitCostPercent') Amount = -Amount;
        if (Amount < 0) return eUIState_Bad;
        return Amount > 0 ? eUIState_Good : eUIState_Normal;
    }
    if (Effect.Status == "available" || Effect.Status == "applied") return eUIState_Good;
    return eUIState_Normal;
}

static function string SoldierDetails(ResolvedEffect Effect, XComGameState_Unit Unit)
{
    local string Body;
    Body = EscapeUI(SoldierStatus(Effect));
    if (Effect.EffectKind == 'Stat' && Effect.Status == "applied")
    {
        Body $= "\nApplied: " $ EscapeUI(CommittedSummary(Effect)) $ ".";
        if (Effect.Magnitude != Effect.AppliedMagnitude) Body $= " Configured: " $ EscapeUI(Summary(Effect)) $ ".";
    }
    if (Effect.EffectKind == 'Ability') Body $= "\n" $ AbilityDetails(Effect, Unit);
    if (Effect.EffectKind == 'RecoveryDuration' || Effect.EffectKind == 'ParticipantResource' || Effect.EffectKind == 'DetectionRange') Body $= "\n" $ EscapeUI(TimingText(Effect.EffectKind, true));
    if (Effect.Note != "" && Effect.EffectKind != 'Ability') Body $= "\n" $ EscapeUI(Effect.Note);
    while (InStr(Body, "\n\n") != INDEX_NONE) Body = Repl(Body, "\n\n", "\n");
    return Body;
}

static function bool IsSavedAbilityGrant(ResolvedEffect Effect)
{
    return Effect.EffectKind == 'Ability' && (Effect.Status == "available" || Effect.Status == "missing_template" || Effect.Status == "already_present");
}

static function string CurrentAbilityLabel(string SavedStatus, bool Installed)
{
    if (!Installed) return "Currently unavailable - ability template not installed";
    return SavedStatus == "already_present" ? "Already owned - currently installed" : "Granted by saved link - currently installed";
}

static function string SoldierStatus(ResolvedEffect Effect)
{
    if (IsSavedAbilityGrant(Effect))
        return CurrentAbilityLabel(Effect.Status, class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(Effect.Target) != none);
    return StatusText(Effect.Status, true);
}

static function EUIState SoldierColor(ResolvedEffect Effect)
{
    if (IsSavedAbilityGrant(Effect))
        return class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(Effect.Target) != none ? eUIState_Good : eUIState_Warning;
    return EffectColor(Effect);
}

static function string MappingDetails(ResolvedEffect Effect, string Revision)
{
    return EscapeUI(string(Effect.SourceKind)) $ ": " $ EscapeUI(Effect.SourceName) $ "\nDefinition: " $ EscapeUI(Effect.SourceID) $ " v" $ Effect.SourceVersion $ "\nMapping: " $ EscapeUI(string(Effect.MappingKey)) $ "\nEffect: " $ EscapeUI(string(Effect.EffectKind)) $ " / " $ EscapeUI(string(Effect.Target)) $ "\nConfigured: " $ EscapeUI(Summary(Effect)) $ "\nSaved result: " $ EscapeUI(StatusText(Effect.Status, true)) $ "\nSaved note: " $ EscapeUI(Effect.Note) $ "\nActual applied delta: " $ Signed(Effect.AppliedMagnitude) $ "\nMapping revision: " $ EscapeUI(Revision) $ "\n\nSaved at linking. Viewing never refreshes or reapplies effects.";
}

static function string CommanderDetails(ResolvedEffect Effect)
{
    local string Body;
    Body = TimingBadge(Effect.EffectKind) $ " | " $ EscapeUI(StatusText(Effect.Status, true));
    Body $= "\n" $ TimingText(Effect.EffectKind, true);
    if (Effect.EffectKind == 'CovertDurationOnce') Body $= "\nRegistered duration adjustment: " $ Percentage(Effect.AppliedMagnitude) $ ".";
    else if (IsOneTime(Effect.EffectKind)) Body $= "\nActual committed delta: " $ Signed(Effect.AppliedMagnitude) $ ". Configured: " $ EscapeUI(Summary(Effect)) $ ".";
    if (Effect.Note != "") Body $= "\n" $ EscapeUI(Effect.Note);
    return Body;
}

static function string ReadableObservedAt(string Value)
{
    // Preserve UTC, but omit fractions/offset duplication in the visible label.
    if (Len(Value) >= 19) return Left(Value, 10) $ " " $ Mid(Value, 11, 8) $ " UTC";
    return "not yet retrieved";
}
