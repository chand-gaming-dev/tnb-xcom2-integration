// Synthetic mapping regression checks, not native campaign acceptance.
class TNB_MappingProbeCommandlet extends Commandlet dependson(TNB_Types, TNB_MappingConfig, X2StrategyGameRulesetDataStructures, TNB_EventTypes, XComGameState_TNBCampaignLink);

var array<TNB_MappingConfig.MappingRow> SourceRows;

static function bool CatalogCoverage(array<TNB_MappingConfig.MappingRow> Rows)
{
    local array<string> IDs;
    local string ID;
    local array<TNB_Types.TraitRecord> Traits;
    local TNB_Types.TraitRecord Trait;
    local array<TNB_Types.SkillRecord> Skills;
    local TNB_Types.SkillRecord Skill;
    local array<TNB_Types.ResolvedEffect> Effects;
    local TNB_Types.ResolvedEffect Effect;
    local array<TNB_MappingConfig.MappingRow> Overrides;
    local int Resolved;
    Overrides.Length = 0;
    ParseStringIntoArray("strong-willed,hardy,observant,analytical,quick-learner,reckless,unlucky,unperceptive,poor-stamina,conspicuous,resourceful,engineering-minded,scientifically-minded,inquisitive,extravagant,secretive,overconfident,battle-scarred,pioneer,tactician", IDs, ",", true);
    foreach IDs(ID)
    {
        Trait.DefinitionID = "trait." $ ID;
        Trait.DefinitionVersion = (ID == "reckless" || ID == "resourceful") ? 3 : 2;
        Traits.AddItem(Trait);
    }
    ParseStringIntoArray("evasive-maneuvers,cover-discipline,weapon-handling,leading-shots,field-surgery,independent-operator", IDs, ",", true);
    foreach IDs(ID)
    {
        Skill.DefinitionID = "skill." $ ID; Skill.DefinitionVersion = 1; Skills.AddItem(Skill);
    }
    Effects = class'TNB_MappingResolver'.static.ResolveUsing('Character', Traits, Skills, Rows, Overrides);
    if (Effects.Length != 26) return false;
    foreach Effects(Effect)
        if (Effect.Status == "resolved") Resolved++;
        else return false;
    if (Resolved != 26) return false;
    Skills.Length = 0; Resolved = 0;
    ParseStringIntoArray("quartermaster,counterintelligence,scrounger", IDs, ",", true);
    foreach IDs(ID)
    {
        Skill.DefinitionID = "skill." $ ID; Skill.DefinitionVersion = 1; Skills.AddItem(Skill);
    }
    Effects = class'TNB_MappingResolver'.static.ResolveUsing('Commander', Traits, Skills, Rows, Overrides);
    if (Effects.Length != 23) return false;
    foreach Effects(Effect)
        if (Effect.Status == "resolved") Resolved++;
        else if (Effect.Status != "unmapped" || (Effect.SourceID != "trait.conspicuous" && Effect.SourceID != "trait.battle-scarred")) return false;
    return Resolved == 21 && Rows.Length == 47;
}

static function bool DetectionChecks()
{
    local float Delta, Modified;
    // Pure policy only. Native unit stats require a running campaign history;
    // standalone editor commandlets cannot establish real reload/transfer safety.
    if (!class'TNB_DetectionMappingService'.static.ShouldApply(false, 2000) || class'TNB_DetectionMappingService'.static.ShouldApply(true, 2000) || class'TNB_DetectionMappingService'.static.ShouldApply(false, 0)) return false;
    Delta = class'TNB_DetectionMappingService'.static.DetectionDelta(0.0, 2000);
    if (Abs(Delta + 0.20) > 0.0001) return false;
    Modified = 0.50 + Delta;
    if (Abs(Modified - 0.30) > 0.0001 || Abs((Modified - Delta) - 0.50) > 0.0001) return false;
    if (Abs(class'TNB_DetectionMappingService'.static.DetectionModifier(0.50, 2000) - 0.40) > 0.0001 || Abs(class'TNB_DetectionMappingService'.static.DetectionModifier(1.0, 2000) - 1.0) > 0.0001) return false;
    return true;
}

event int Main(string Params)
{
    local array<TNB_Types.ResolvedEffect> Effects;
    local TNB_Types.ResolvedEffect Effect;
    local TNB_MappingConfig.MappingRow Row;
    local float Rate;
    local array<int> Candidates;
    local ECombatIntelligence Cap;
    local array<TNB_Types.TraitRecord> Traits;
    local array<TNB_Types.SkillRecord> Skills;
    local TNB_Types.TraitRecord Trait;
    local class<TNB_MappingProbeCommandlet> Fixture;
    local array<TNB_MappingConfig.MappingRow> Shipped, Overrides;
    local array<TNB_EventTypes.MissionObservation> Missions;
    local TNB_EventTypes.MissionObservation Mission;
    local XComGameState_TNBSoldierLink Soldier;
    local XComGameState_TNBCampaignLink Campaign;
    local array<XComGameState_TNBCampaignLink.ResourceAdjustment> Receipts;
    local XComGameState_TNBCampaignLink.ResourceAdjustment Receipt;
    local array<string> Sources;
    local XComLWTuple Tuple;
    Skills.Length = 0;
    Overrides.Length = 0;
    Fixture = class<TNB_MappingProbeCommandlet>(DynamicLoadObject("TheNameBeneath.TNB_MappingProbeDefaults", class'Class', true));
    if (Fixture == none) { `log("Use .scripts/Test-ModMappings.ps1 to create the SDK-only source INI fixture."); return 22; }
    Shipped = Fixture.default.SourceRows;
    if (Shipped.Length < 25) return 23;
    if (!CatalogCoverage(Shipped)) return 34;
    `log("TNB_MAPPING_CATALOG_COVERAGE_PASS: 26 Character and 21 Commander mappings; only blocked Commander Conspicuous and acquisition-inapplicable Commander Battle-Scarred remain unmatched.");
    if (!class'TNB_PolicyTests'.static.Run()) return 1;
    Effect.EffectKind = 'CovertRisk'; Effect.Target = 'CovertActionRisk_Ambush'; Effect.Magnitude = -5; Effect.Status = "active";
    Effects.AddItem(Effect);
    Effect.Magnitude = 5; Effects.AddItem(Effect);
    if (class'TNB_StrategyMappingService'.static.ActiveTotal(Effects, 'CovertRisk', 'CovertActionRisk_Ambush') != 0) return 2;
    Effects[0].Status = "disabled";
    if (class'TNB_StrategyMappingService'.static.ActiveTotal(Effects, 'CovertRisk', 'CovertActionRisk_Ambush') != 5) return 3;
    if (class'TNB_StrategyMappingService'.static.ActiveTotal(Effects, 'CovertRisk', 'CovertActionRisk_SoldierCaptured') != 0) return 4;
    if (class'TNB_StrategyMappingService'.static.RiskTarget('CovertActionRisk_Other')) return 5;
    Rate = class'TNB_StrategyMappingService'.static.RecoveryRate(0);
    if (Abs(Rate - 1.0) > 0.0001) return 6;
    if (Abs(class'TNB_StrategyMappingService'.static.RecoveryRate(-1000) - (1.0 / 0.90)) > 0.0001) return 7;
    if (Abs(class'TNB_StrategyMappingService'.static.RecoveryRate(2000) - (1.0 / 1.20)) > 0.0001) return 8;
    // Approved Hardy/Secretive policy: add durations, not multiply rates.
    if (Abs(class'TNB_StrategyMappingService'.static.RecoveryRate(2000 - 1000) - (1.0 / 1.10)) > 0.0001) return 9;
    // Preserve another mod's supplied rate and avoid any unit tactical HP change.
    if (Abs(2.0 * class'TNB_StrategyMappingService'.static.RecoveryRate(1000) - (2.0 / 1.10)) > 0.0001) return 10;
    foreach Shipped(Row)
        if (!class'TNB_MappingResolver'.static.ValidRow(Row)) { `log("Invalid shipped mapping:" @ Row.Key); return 11; }
    `log("TNB_MAPPING_RISK_RECOVERY_PASS: target isolation, additive opposing risks, active-only frozen effects, reciprocal duration rates, cancellation, approved Hardy/Secretive combination and shipped-row validation.");
    if (class'TNB_StrategyMappingService'.static.TakeRecipient(Candidates, 0) != 0) return 12;
    Candidates.AddItem(100); Candidates.AddItem(200);
    if (class'TNB_StrategyMappingService'.static.TakeRecipient(Candidates, 1) != 200 || Candidates.Length != 1 || class'TNB_StrategyMappingService'.static.TakeRecipient(Candidates, 0) != 100 || Candidates.Length != 0) return 13;
    Cap = eComInt_Savant;
    if (class'TNB_StrategyMappingService'.static.NextIntelligence(int(Cap)) != int(Cap) || class'TNB_StrategyMappingService'.static.NextIntelligence(int(Cap) - 1) != int(Cap)) return 14;
    if (!class'TNB_EffectPresentation'.static.IsOneTime('RosterIntelligenceOnce') || !class'TNB_EffectPresentation'.static.IsOneTime('CovertDurationOnce') || !class'TNB_EffectPresentation'.static.IsOneTime('ContactOnce')) return 15;
    `log("TNB_MAPPING_ASSOCIATION_PASS: distinct recipients without replacement, zero/one/two candidate policy, Savant cap and one-time presentation classification. Native association/save and bond-duration interactions require gameplay acceptance.");
    Trait.DefinitionID = "trait.reckless"; Trait.DefinitionVersion = 3; Traits.AddItem(Trait);
    Trait.DefinitionID = "trait.overconfident"; Trait.DefinitionVersion = 2; Traits.AddItem(Trait);
    Trait.DefinitionID = "trait.analytical"; Traits.AddItem(Trait);
    Trait.DefinitionID = "trait.engineering-minded"; Traits.AddItem(Trait);
    Trait.DefinitionID = "trait.strong-willed"; Traits.AddItem(Trait);
    Trait.DefinitionID = "trait.pioneer"; Traits.AddItem(Trait);
    Trait.DefinitionID = "trait.battle-scarred"; Traits.AddItem(Trait);
    Trait.DefinitionID = "trait.tactician"; Traits.AddItem(Trait);
    Trait.DefinitionID = "trait.scientifically-minded"; Traits.AddItem(Trait);
    Trait.DefinitionID = "trait.resourceful"; Trait.DefinitionVersion = 3; Traits.AddItem(Trait);
    Effects = class'TNB_MappingResolver'.static.ResolveUsing('Character', Traits, Skills, Shipped, Overrides);
    if (Effects.Length != 10) return 16;
    if (Effects[0].Target != 'eStat_Dodge' || Effects[0].Magnitude != -5 || Effects[1].Target != 'eStat_Defense' || Effects[1].Magnitude != -10) return 17;
    if (Effects[2].Target != 'eStat_Hacking' || Effects[3].Target != 'eStat_Hacking' || Effects[2].Magnitude + Effects[3].Magnitude != 20) return 18;
    if (Effects[4].Target != 'eStat_Will' || Effects[5].Target != 'eStat_Will' || Effects[4].Magnitude + Effects[5].Magnitude != 10) return 19;
    if (Effects[6].Target != 'MZUnshakableWill' || Effects[7].Target != 'ShadowOps_AbsolutelyCritical' || Effects[8].Target != 'F_QuickPatch' || Effects[9].Target != 'FullKit') return 20;
    Trait.DefinitionVersion = 4; Traits.Length = 0; Traits.AddItem(Trait);
    Effects = class'TNB_MappingResolver'.static.ResolveUsing('Character', Traits, Skills, Shipped, Overrides);
    if (Effects.Length != 1 || Effects[0].Status != "unmapped") return 21;
    `log("TNB_MAPPING_SOLDIER_PASS: revised negative targets, additive Hacking/Will specialization, all four new exact optional ability identifiers and rejection of unreviewed future versions. Tactical perk behavior remains a native acceptance gate.");
    if (class'TNB_StrategyMappingService'.static.ResearchScore(20, true, 1000) != 22 || class'TNB_StrategyMappingService'.static.ResearchScore(20, false, 1000) != 20 || class'TNB_StrategyMappingService'.static.ResearchScore(0, true, 1000) != 0) return 24;
    `log("TNB_MAPPING_RESEARCH_PASS: ten-percent progress score, unchanged prerequisite-query score, zero-score preservation. Native research/Shadow project timing and other-mod interaction need gameplay acceptance.");
    Campaign = new class'XComGameState_TNBCampaignLink'; Campaign.bOneTimeEffectsCommitted = true;
    Effect.EffectKind = 'ResearchSpeed'; Effect.Target = 'Science'; Effect.Magnitude = 1000; Effect.Status = "active"; Campaign.Effects.AddItem(Effect);
    Tuple = new class'XComLWTuple'; Tuple.Id = 'OverrideScienceScore'; Tuple.Data.Length = 2;
    Tuple.Data[0].kind = XComLWTVInt; Tuple.Data[0].i = 30;
    Tuple.Data[1].kind = XComLWTVBool; Tuple.Data[1].b = true;
    class'TNB_StrategyMappingService'.static.ApplyScience(Tuple, Campaign);
    if (Tuple.Data[0].i != 33 || !Tuple.Data[1].b) return 35;
    Tuple.Data[1].b = false;
    class'TNB_StrategyMappingService'.static.ApplyScience(Tuple, Campaign);
    if (Tuple.Data[0].i != 33) return 36;
    Mission.ObjectID = 10; Mission.Kind = "covert_action"; Mission.bStarted = true;
    Mission.UnitIDs.AddItem(1); Mission.UnitIDs.AddItem(2); Mission.Instances.AddItem("one"); Mission.Instances.AddItem("two");
    Missions.AddItem(Mission); Missions.AddItem(Mission);
    if (class'TNB_RewardMappingService'.static.RosterIndex(Missions, 10, "covert_action") != 1 || class'TNB_RewardMappingService'.static.RosterIndex(Missions, 10, "poi") != INDEX_NONE || class'TNB_RewardMappingService'.static.RosterIndex(Missions, 11, "covert_action") != INDEX_NONE) return 25;
    Campaign = new class'XComGameState_TNBCampaignLink'; Campaign.CampaignID = "campaign"; Campaign.Journey.JourneyID = "journey";
    Soldier = new class'XComGameState_TNBSoldierLink'; Soldier.bEffectsCommitted = true;
    Soldier.CampaignID = "campaign"; Soldier.Snapshot.JourneyID = "journey"; Soldier.UnitRef.ObjectID = 1; Soldier.Snapshot.InstanceID = "one";
    if (!class'TNB_RewardMappingService'.static.ParticipantMatches(Soldier, Campaign, Mission)) return 26;
    Soldier.UnitRef.ObjectID = 3;
    if (class'TNB_RewardMappingService'.static.ParticipantMatches(Soldier, Campaign, Mission)) return 27;
    Soldier.UnitRef.ObjectID = 2; Soldier.Snapshot.InstanceID = "not-linked-at-launch";
    if (class'TNB_RewardMappingService'.static.ParticipantMatches(Soldier, Campaign, Mission)) return 28;
    Soldier.Snapshot.InstanceID = "two"; Soldier.Snapshot.JourneyID = "other-journey";
    if (class'TNB_RewardMappingService'.static.ParticipantMatches(Soldier, Campaign, Mission)) return 29;
    if (class'TNB_CommanderBonusService'.static.BonusAmount(100, 1000 + 1000 + 1000) != 30 || class'TNB_CommanderBonusService'.static.BonusAmount(100, 500 - 1000 - 1000) != -15 || class'TNB_CommanderBonusService'.static.BonusAmount(100, -30000) != -100 || class'TNB_CommanderBonusService'.static.BonusAmount(0, 1000) != 0) return 30;
    Receipt.RewardID = 20; Receipt.Original = 100; Receipt.Adjustment = -15; Receipt.Sources = "Extravagant / Resourceful";
    Receipts.AddItem(Receipt);
    if (InStr(class'TNB_RewardMappingService'.static.AdjustmentText(Receipts, 20, "100 Supplies", "Supplies"), "85 Supplies") != 0 || class'TNB_RewardMappingService'.static.AdjustmentText(Receipts, 21, "Native", "Supplies") != "Native") return 31;
    Sources.AddItem("<Name> & Inquisitive");
    if (class'TNB_RewardMappingService'.static.SourceLabel(Sources) != "&lt;Name&gt; &amp; Inquisitive") return 32;
    `log("TNB_MAPPING_REWARDS_PASS: retained latest-attempt roster, no barracks/POI/late-link/wrong-Journey contribution, additive two-soldier/Commander percentages, zero rewards, zero-floor losses and escaped actual reward receipt text.");
    // Counterexample to the audited initialization-only detection approach:
    // base M=0 -> -0.20, then a later +0.50 stealth modifier -> M=0.30.
    // Relative detection becomes 0.70/0.50=1.40. The Product Owner accepted
    // this native stacking contract; don't claim a fixed 20% after other perks.
    if (Abs((1.0 - (-0.20 + 0.50)) / (1.0 - 0.50) - 1.40) > 0.0001) return 33;
    if (Abs(5.0 * (1.0 - class'TNB_DetectionMappingService'.static.DetectionModifier(0.0, 2000)) - 6.0) > 0.0001 || Abs(10.0 * (1.0 - class'TNB_DetectionMappingService'.static.DetectionModifier(0.0, 2000)) - 12.0) > 0.0001) return 37;
    if (!DetectionChecks()) return 38;
    `log("TNB_MAPPING_DETECTION_PASS: initial 20% scaling, not fixed tiles; accepted later-stealth stacking, pure application guard and own-delta reversal arithmetic. Native stat/marker, reload/transfer and campaign lifecycle acceptance is still required.");
    `log("TNB_MAPPING_ALL_CHECKS_PASSED");
    return 0;
}

defaultproperties
{
    IsClient=false
    IsServer=false
    IsEditor=true
    LogToConsole=true
}
