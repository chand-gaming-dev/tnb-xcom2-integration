# Player-owned balance mappings

Edit `TheNameBeneath/Config/XComTheNameBeneath.ini` in your local mod build (and deploy it to the installed mod when building). Keep a backup: mod updates can replace this file. Restart XCOM to reload configuration. Changes affect **future associations/links only**; existing saved effects do not refresh or reapply.

Approved rollback policy (0.4.1): a save from before a soldier link has none of that link's benefits, so a newly confirmed link may resolve current mappings once. The original The Name Beneath instance/snapshot is still reused. A save containing a committed link retains its already frozen mappings and cannot gain the bonuses again. Commander association policy is unchanged.

The section is `[TheNameBeneath.TNB_MappingConfig]`. Shipped rows are in `ShippedMappings`; put player changes in the separate `Overrides` array. The resolver matches canonical definition ID, Trait/Skill kind, Character/Commander context and the reviewed version range, not display names. Each effect has its own stable Key, so one characteristic may grant multiple effects.

For example, replace the Hardy HP effect for new links with +2 HP:

```ini
+Overrides=(Key="hardy_hp",Context=Character,SourceKind=Trait,SourceID="trait.hardy",MinVersion=1,MaxVersion=2,EffectKind=Stat,Target=eStat_HP,Magnitude=2,bEnabled=true)
```

Or explicitly suppress that effect:

```ini
+Overrides=(Key="hardy_hp",Context=Character,SourceKind=Trait,SourceID="trait.hardy",MinVersion=1,MaxVersion=2,bEnabled=false)
```

Use **one** of these examples, not both. Modify/remove your previous override row when replacing it. Unreal's `+` array syntax merges complete rows; it does not replace a row by Key. Our separate Overrides array supplies keyed replacement without requiring removal of the original shipped tuple. Keep overrides in one source to avoid stale/conflicting entries from multiple config mods. Conflicting equally ranked rows are visibly skipped rather than arbitrarily selected.

Precedence for each matching Key: player exact version, player range/wildcard, shipped exact version, shipped range. Priority breaks ties within a tier; equal-priority duplicates are rejected. `MinVersion=MaxVersion` is exact; `MaxVersion=0` explicitly accepts all later versions. Default ranges include only reviewed catalog versions: most starting Traits v1-2, Reckless v2-3 and commander Resourceful v2-3; Skills v1. Historical Resourceful v1 is not converted into a commander mapping.

Effect kinds:

| Context | Kind | Target / magnitude |
|---|---|---|
| Character | Stat | `eStat_HP`, `eStat_Will`, `eStat_Offense`, `eStat_Defense`, `eStat_CritChance`, `eStat_Hacking`, `eStat_SightRadius`, `eStat_Mobility`, `eStat_Dodge`; signed integer delta |
| Character | Ability | Runtime ability-template name, WeaponSlot and optional UtilityCategory; no extra mod dependency is created |
| Character | CombatIntelligence | Magnitude 1; tier increase capped at Savant, no retroactive AP |
| Character | DetectionRange | `Personal`; signed initial detection-range basis points, default 2000 = +20%. The resulting per-mission stat delta stacks natively afterward; not a fixed tile count or guaranteed post-stealth percentage |
| Character | ParticipantResource | Supplies/Intel mission/covert rewards for this linked participant only; basis points, so 1000 = +10%, -1000 = -10% |
| Character/Commander | RecoveryDuration | `Wound` (either context), `Will` (Commander); signed duration basis points. -1000 = 10% shorter, +2000 = 20% longer. Add durations, then use reciprocal work rate |
| Commander | CovertRisk | Existing `CovertActionRisk_Ambush`, `CovertActionRisk_SoldierWounded`, `CovertActionRisk_SoldierCaptured`; signed **percentage points**, so 5 = +5 pp, not 500 |
| Commander | ResearchSpeed | `Science`; speed basis points, 1000 = +10%; native Science Score progress scope |
| Commander | ContactOnce | +1 to +10 contact capacity at association; normal contact costs/research remain |
| Commander | RosterIntelligenceOnce | Number of distinct random eligible barracks recipients (default 2), +1 tier each, no retroactive AP/backfill |
| Commander | CovertDurationOnce | Negative duration basis points (default -1000): register native 0.90 duration multiplier once |
| Commander | ResourcePercent | Supplies/Intel; integer basis points, so 500 means 5% |
| Commander | ResourceOnce | Supplies/Intel; signed integer quantity |
| Commander | StaffOnce | Engineer/Scientist; integer quantity 1-10 |
| Commander | AvatarOnce | Signed pip delta, limited to eligible progress/capacity; no deferred award |
| Commander | SupplyDropItem | Magnitude 1; monthly rollover, including zero-income months |

Unknown/missing mappings, invalid rows, disabled effects, missing ability templates and already-present abilities are reported separately. A missing optional ability's frozen template name is retained; it can be supplied by the earned-ability hook if that template is installed again. The report records **link-time results**, not a promise that a removed ability mod is still present. Optional ability compatibility still needs tactical testing. See [the implementation checkpoint](ALPHA_MAPPING_IMPLEMENTATION.md) for approved acquired-Trait mappings, Character Conspicuous's accepted native stacking, and Commander Conspicuous which remains blocked, not excluded. The alpha mapping set is not complete or accepted for release.

## Ability provenance comments

Every `EffectKind=Ability` mapping must have adjacent INI comments identifying the exact internal template, whether it is core or optional, and (for an optional provider) the mod name, Workshop ID and direct Workshop link. Preserve the same comments when sharing an override. Display names alone are not template identifiers. These links document provenance; they are not new required dependencies or instructions to install an entire overhaul for one perk. Other packs may supply compatible templates, but their exact names and behavior must be checked.

| Identity Trait/Skill | Template / current status | Source |
|---|---|---|
| Evasive Maneuvers | `LightningReflexes` | Core XCOM 2/WOTC; `X2Ability_AdvancedWarfareCenter`; no ability mod needed |
| Cover Discipline | `LowProfile` | Long War perk pack; verified in installed [Long War of the Chosen, 2663990965](https://steamcommunity.com/sharedfiles/filedetails/?id=2663990965) |
| Weapon Handling | **`SingleReloadMrC`**, displayed as Chamber Round; corrected default in mapping revision `tnb-alpha-2026-10-19-r2` | [Modpocalypse Perk Pack, 2936550132](https://steamcommunity.com/sharedfiles/filedetails/?id=2936550132) |
| Leading Shots | `GrazingFire` | Verified in installed [Long War of the Chosen, 2663990965](https://steamcommunity.com/sharedfiles/filedetails/?id=2663990965) perk pack |
| Field Surgery | `FieldSurgeon` | Verified in installed [Long War of the Chosen, 2663990965](https://steamcommunity.com/sharedfiles/filedetails/?id=2663990965) perk pack |
| Independent Operator | `LoneWolf` | Verified in installed [Long War of the Chosen, 2663990965](https://steamcommunity.com/sharedfiles/filedetails/?id=2663990965) perk pack |
| Resourceful (Character) | `FullKit` | Verified installed [LWOTC, 2663990965](https://steamcommunity.com/sharedfiles/filedetails/?id=2663990965); qualifying utility grenades/Battle Scanners, not all consumables; stock-WOTC provider qualification remains open |
| Scientifically Minded (Character) | `F_QuickPatch` | [Extended Perk Pack, 1546482849](https://steamcommunity.com/sharedfiles/filedetails/?id=1546482849); normal charges and initial action affordability apply |
| Battle-Scarred (Character) | `MZUnshakableWill` | [Mitzruti's Perk Pack, 1561030099](https://steamcommunity.com/sharedfiles/filedetails/?id=1561030099); not universal mental immunity |
| Tactician (Character) | `ShadowOps_AbsolutelyCritical` | [Shadow Ops Perk Pack, 1519841231](https://steamcommunity.com/sharedfiles/filedetails/?id=1519841231); crit-capable attacks against flanked/uncovered targets |

Source check (2026-10-19): the installed LWOTC `LW_PerkPack_Integrated` registers `LowProfile`, `GrazingFire` and `LoneWolf` in `X2Ability_PerkPackAbilitySet.uc`, and `FieldSurgeon` in `X2Ability_PerkPackAbilitySet2.uc`. The base SDK includes an `X2Effect_LowProfile` effect and a distinct `ChosenLowProfile` ability, but does not register the mapped soldier `LowProfile` template. Do not label that mapped template as core merely because the underlying effect/name also occurs in the SDK. The standalone [WOTC LW2 Classes and Perks](https://steamcommunity.com/sharedfiles/filedetails/?id=1335226018) is a broader class/perk port, not an additional requirement for an existing LWOTC setup; evaluate provider compatibility before installing anything.

The Modpocalypse author's Workshop description confirms `SingleReloadMrC`: a free single-round primary-weapon reload, both action points available, two charges by default. The user approved correcting the target before starting XCOM on 2026-10-19; the source and deployed INI now use it, with a bumped mapping revision and updated optional-provider note. No other mapping is changed and no ability mod is installed. Test a fresh/pre-link timeline with the optional pack installed when ready. Existing links freeze the old template name, so installing the pack alone will not repair a saved `ChamberRound` target. Existing snapshots, effects and saves are not migrated. No script/companion rebuild or API change is needed for this INI-only correction.

Stat deltas are summed per target and applied once with the link. Healthy soldiers stay at full HP; existing HP damage is not healed. The saved report lists each source and net stat totals. Invalid combined minimum HP/Mobility/Sight is skipped and identified.

Commander percentages add together and are clamped to -100% through +1000%. For each supported positive gain, whole-resource fractions truncate toward zero symmetrically for bonuses and penalties. For example, +/-5% of 100 is +/-5; +/-5% of 15 is 0. Opposing default pairs cancel. There is no change to spending, refunds, starting grants or unidentified gains. See RESOURCE_COVERAGE.md.

`ScroungerItems` is the configurable pool. Valid installed, non-infinite templates are frozen at association, then checked again at award time. Shipped choices are basic weapon upgrades and Medikit; no PCS, advanced/superior/unique items. Starting with mod 0.8.4, one random item is awarded at monthly rollover even if income is zero or there is no cache to collect. Existing month guards are preserved; collection and partial scans do not grant additional items, and loading does not backfill earlier months. A dismissible native item popup names Scrounger and the actual item after the monthly report. Default template availability and actual in-game popup ordering/layout remain acceptance tests. See COMMANDER_MONTHLY_REWARDS_TESTING.md.
