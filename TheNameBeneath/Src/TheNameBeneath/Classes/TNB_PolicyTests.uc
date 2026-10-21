// Pure checks only: no game-state writes, API calls, or dependence on player balance overrides.
class TNB_PolicyTests extends TNB_Types dependson(TNB_MappingConfig);

static function bool Run()
{
    local array<TraitRecord> Traits;
    local array<SkillRecord> Skills;
    local TraitRecord Trait;
    local array<ResolvedEffect> Effects;
    local array<TNB_MappingConfig.MappingRow> Shipped, Overrides;
    local TNB_MappingConfig.MappingRow Row;
    local ECharStatType Stat;
    Skills.Length = 0; Overrides.Length = 0;
    if (!class'TNB_CampaignService'.static.ShouldOfferReminder(false, false, false, true, true)) return false;
    if (class'TNB_CampaignService'.static.ShouldOfferReminder(true, false, false, true, true)) return false;
    if (class'TNB_CampaignService'.static.ShouldOfferReminder(false, true, false, true, true)) return false;
    if (class'TNB_CampaignService'.static.ShouldOfferReminder(false, false, true, true, true)) return false;
    if (class'TNB_CampaignService'.static.ShouldOfferReminder(false, false, false, false, true)) return false;
    if (class'TNB_CampaignService'.static.ShouldOfferReminder(false, false, false, true, false)) return false;
    Trait.DefinitionID = "trait.synthetic"; Trait.DefinitionVersion = 2; Trait.DisplayName = "<Synthetic & Trait>";
    Traits.AddItem(Trait);
    Row.Key = 'synthetic_stat'; Row.Context = 'Character'; Row.SourceKind = 'Trait'; Row.SourceID = Trait.DefinitionID;
    Row.MinVersion = 1; Row.MaxVersion = 2; Row.bEnabled = true; Row.EffectKind = 'Stat'; Row.Target = 'eStat_Will'; Row.Magnitude = 5;
    Shipped.AddItem(Row);
    Effects = class'TNB_MappingResolver'.static.ResolveUsing('Character', Traits, Skills, Shipped, Overrides);
    if (Effects.Length != 1 || Effects[0].Magnitude != 5 || Effects[0].Status != "resolved") return false;
    Row.Magnitude = -2; Overrides.AddItem(Row);
    Effects = class'TNB_MappingResolver'.static.ResolveUsing('Character', Traits, Skills, Shipped, Overrides);
    if (Effects[0].Magnitude != -2) return false;
    Row.MinVersion = 2; Row.MaxVersion = 2; Row.Magnitude = 3; Overrides.AddItem(Row);
    Effects = class'TNB_MappingResolver'.static.ResolveUsing('Character', Traits, Skills, Shipped, Overrides);
    if (Effects[0].Magnitude != 3) return false;
    Overrides.AddItem(Row);
    Effects = class'TNB_MappingResolver'.static.ResolveUsing('Character', Traits, Skills, Shipped, Overrides);
    if (Effects[0].Status != "skipped") return false;
    Overrides.Remove(Overrides.Length - 1, 1); Overrides[Overrides.Length - 1].bEnabled = false;
    Effects = class'TNB_MappingResolver'.static.ResolveUsing('Character', Traits, Skills, Shipped, Overrides);
    if (Effects[0].Status != "disabled") return false;
    Effects = class'TNB_MappingResolver'.static.ResolveUsing('Commander', Traits, Skills, Shipped, Overrides);
    if (Effects[0].Status != "unmapped") return false;
    Row.Target = 'NotAStat';
    if (class'TNB_MappingResolver'.static.ValidRow(Row) || class'TNB_MappingResolver'.static.StatType('NotAStat', Stat)) return false;
    if (class'TNB_CommanderBonusService'.static.BonusAmount(15, 500) != 0 || class'TNB_CommanderBonusService'.static.BonusAmount(100, 500) != 5 || class'TNB_CommanderBonusService'.static.BonusAmount(100, -500) != -5) return false;
    if (class'TNB_CommanderBonusService'.static.BonusAmount(99, -1000) != -9 || class'TNB_CommanderBonusService'.static.BonusAmount(-100, 500) != 0 || class'TNB_CommanderBonusService'.static.BonusAmount(100, -10000) != -100) return false;
    if (class'TNB_SoldierEffectService'.static.CommitDecision(false, false, false, "", "instance") != "apply") return false;
    if (class'TNB_SoldierEffectService'.static.CommitDecision(true, true, false, "instance", "instance") != "unchanged") return false; // legacy 0.4.0 save, no marker
    if (class'TNB_SoldierEffectService'.static.CommitDecision(true, true, true, "instance", "instance") != "unchanged") return false;
    if (class'TNB_SoldierEffectService'.static.CommitDecision(true, true, true, "instance", "other") != "blocked") return false;
    if (class'TNB_SoldierEffectService'.static.CommitDecision(true, false, false, "", "instance") != "blocked") return false;
    if (class'TNB_SoldierEffectService'.static.CommitDecision(false, false, true, "", "instance") != "blocked") return false;
    return EscapeUI("<A & B>") == "&lt;A &amp; B&gt;";
}
