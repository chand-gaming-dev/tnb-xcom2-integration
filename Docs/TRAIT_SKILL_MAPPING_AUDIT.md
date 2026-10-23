# The Name Beneath — XCOM 2 Trait and Skill Mapping Audit

**DRAFT FOR PRODUCT OWNER REVIEW — 2026-10-22. Design/audit only.**
Issue: [#18](https://github.com/chand-gaming-dev/project-threadline/issues/18).
No configuration, canonical catalog, code, gameplay state, assets, dependency installation,
Portal/API implementation or release has been changed by this audit. No combinations/
stacking balance review was conducted. **Unmapped entries below are proposed explicit
exclusions, not newly approved Product Owner decisions.**

## Approved review decision: Battle-Scarred (2026-10-22)

The Product Owner locked **Character Battle-Scarred -> Unshakable Will
(`MZUnshakableWill`)** from [Mitzruti's Perk Pack, Workshop 1561030099](https://steamcommunity.com/sharedfiles/filedetails/?id=1561030099).
This supersedes the earlier +10 Will proposal and the original Character acquired-
Trait exclusion below and in the companion CSV audit rows. Approved design only;
implementation remains pending.

- Uses effective maximum Will for defense and automatically passes standard panic
  checks. Mind control, disorientation and Mindspin panic remain possible.
- Personal benefit only: no tactical damage reduction, wound-recovery adjustment,
  squad aura or actual fatigue removal. Early-campaign value is intentional,
  including when an entire squad eventually possesses the Trait.
- Applies through an updated Character snapshot when linking in a future Journey.
  Existing frozen links and saves are not refreshed or retroactively granted it.
- Commander Battle-Scarred has no qualifying acquisition path; no Commander
  mapping is approved or required. Other acquired-Trait mappings remain in review.
- Verified locally in `MZUnspecific_AbilitySet.uc`, `MZ_Effect_UnshakableFaith.uc`,
  English localization and the pack's `PanicImmunityAbilities` configuration.
- No runtime configuration, canonical catalog, dependency installation or release
  is changed by this decision. Gameplay acceptance is still pending.

## Approved review decision: Tactician (2026-10-22)

The Product Owner approved **Character Tactician -> Absolutely Critical
(`ShadowOps_AbsolutelyCritical`)** from [Shadow Ops Perk Pack, Workshop 1519841231](https://steamcommunity.com/sharedfiles/filedetails/?id=1519841231).
This supersedes the original Character acquired-Trait exclusion below and in the
companion CSV audit rows. Approved design only; implementation remains pending.

- The installed provider's default is +15 percentage points of critical-hit chance
  against targets flanked by the attacking soldier or otherwise without cover,
  including enemies unable to take cover. Attacks must support critical hits.
- No accuracy bonus, guaranteed critical hit, extra action or squad aura. Each
  soldier benefits independently; tactical positioning is the intended reward.
- Resolve from an updated Character snapshot when linking in a future Journey;
  preserve existing frozen links and saves without live refresh or retroactive grant.
- Verified locally in `X2Ability_AWC.uc` (`AbsolutelyCritical`),
  `XComGameData_SoldierSkills.ini` (`AbsolutelyCriticalCritBonus=15`),
  `XMBCondition_CoverType.uc` and the installed English localization.
- This decision applies only to Characters. It does not approve a Commander
  effect, canonical catalog change, dependency installation or public dependency
  profile. Shadow Ops provider/package suitability remains a separate review.
- No runtime configuration or release changes. Gameplay acceptance remains pending.

The approved Battle-Scarred and Tactician decisions above take precedence over
earlier blanket acquired-Trait recommendations below. Character Pioneer is now
approved at +5 Will; see its separate approval and the Commander Pioneer decision.

## Approved review decision: Commander Pioneer (2026-10-22)

The Product Owner approved **Commander Pioneer -> +1 Resistance contact capacity**.
This supersedes the original Commander Pioneer exclusion below and in the companion
CSV audit rows. Approved design only; implementation remains pending.

- Allows contact with one additional region; does not automatically reveal, contact
  or grant a region. Normal Intel costs, scanning time, adjacency and research
  requirements remain in force. No scanning-speed bonus is approved.
- Apply once at the first explicit campaign/Journey association from the linked
  Commander's snapshot. Preserve the campaign's existing capacity sources and
  prevent repeated association or save reloads from accumulating extra capacity.
- Uses native contact-capacity mechanics (`BonusCommCapacity` in
  `XComGameState_HeadquartersXCom.GetPossibleResContacts`); no perk-pack dependency.
- This approval is Commander-only. Character Pioneer's +5 Will is separately
  approved below; recruitment options were not selected for Commander Tactician.
- No runtime configuration, canonical catalog, installed dependencies or release
  changes. Gameplay acceptance remains pending.

These approved review decisions supersede the corresponding earlier acquired-
Trait exclusion proposals. Other unapproved mappings remain under review.

## Approved review decision: Commander Tactician (2026-10-22)

The Product Owner selected **Commander Tactician -> 10% shorter covert-action
duration**, conditional on feasibility. Source review confirms native WOTC supports
this via `XComGameState_HeadquartersResistance.AddCovertActionModifier` with a
`0.90` duration multiplier. Approved design; not implemented or gameplay-tested.

- Native support updates existing unstarted actions and the remaining time of
  ongoing actions; newly generated actions use `CovertActionDurationModifier`.
  Example: ten days remaining becomes approximately nine days, subject to native
  hour rounding. The benefit changes duration, not risk or outcome probabilities.
- Register once from the Commander's frozen snapshot at explicit campaign/Journey
  association; preserve existing modifiers and prevent repeated associations or
  reloads from multiplying the benefit again. Do not modify history from a UI timer.
- Percentage-duration modifiers multiply rather than adding percentage points.
  Verify interactions with resistance orders, bondmate bonuses and the player's
  covert-action mods during implementation and gameplay acceptance.
- No new perk-pack dependency or custom soldier ability is required. Native helper
  and action timing paths were inspected; no matching overrides were found in the
  installed LWOTC source search. This is not full mod-list compatibility acceptance.
- Recruitment discount/extra-candidate and other earlier Commander Tactician ideas
  are not selected. The original Commander Tactician exclusions below and in the
  companion CSV audit rows are superseded by this decision.
- Runtime configuration, canonical catalog, dependencies, saves and release output
  remain unchanged. The Character Tactician mapping is a separate approval.

## Re-approved review decision: existing Character Chosen Traits (2026-10-22)

The Product Owner re-approved all nine currently configured Chosen Trait mappings
for Characters, retaining their existing effect targets, amounts and behavior:

| Trait | Re-approved Character effect |
| --- | --- |
| Strong-Willed | +5 Will |
| Hardy | +1 HP |
| Observant | +1 Sight Radius |
| Analytical | +10 Hacking |
| Quick Learner | +1 Combat Intelligence tier, capped at Savant; no retroactive Ability Points |
| Reckless | -5 Defense |
| Unlucky | -5 Critical Hit Chance |
| Unperceptive | -1 Sight Radius |
| Poor Stamina | -1 Mobility |

This re-approval does not approve mappings or exclusions for other Chosen Traits,
change version ranges, alter Commander effects, or refresh existing frozen links.
Conspicuous remains separately unresolved alongside the seven formerly Commander-
side Chosen Traits now being reviewed for Characters. This decision supersedes
the proposed-only approval labels for these nine rows in the companion CSV audit.
No gameplay configuration, canonical catalog, dependencies or release changes.

## Approved review decision: Character Conspicuous (2026-10-22)

The Product Owner accepted **Conspicuous -> enemies detect this concealed soldier
from 20% farther away**, conditional on feasibility. Native percentage-stat and
tactical lifecycle support provide a source-level implementation path without a
custom ability or new dependency. Approved design; not implemented/gameplay-tested.
This supersedes the earlier fixed one-tile direction: five tiles becomes six, but
ten becomes twelve rather than eleven. Native distance/grid rounding still applies.

- Personal penalty only: no ally stealth bonus, own sight/detection-radius increase,
  enemy accuracy bonus or cover-defense change. Do not grant Big Stompy Boots,
  which bundles an ally benefit and defaults to a different percentage.
- Source formula is detector radius multiplied by `(1 - detectee detection
  modifier)`. A 1.20 range multiplier at application corresponds to
  `newModifier = 1 - 1.20 * (1 - currentModifier)`, not a literal `-1` stat change.
- Mission initialization resets the base detection modifier. Freeze the approved
  mapping with the soldier link, then apply it at the correct tactical lifecycle
  point rather than relying on a strategic stat edit alone. The native
  `OnTacticalBeginPlay` event supplies the ongoing initialization transaction after
  squad/stat initialization; do not create another history frame or a UI timer.
- The resolver currently lacks detection/fractional-stat support. A scoped mapping
  extension, per-unit application guards and lifecycle handling are required;
  no runtime code or configuration is changed by this design approval.
- Acceptance must cover native detection warnings versus actual reveals, multiple
  linked soldiers, tactical save reloads, direct mission transfers, reinforcements
  if relevant, and stacking/order with Covert, Ghostwalker and Shadow. Do not claim
  exact compatibility with later-changing stealth effects without testing it.
- Supersedes unresolved-magnitude/exclusion statements above/below and in the
  companion CSV rows for Character Conspicuous only. Apply through future links;
  do not reinterpret already frozen links or alter Commander applicability.
- No gameplay configuration, code, canonical catalog, dependencies, saves or
  release output changed. Gameplay and full mod-list compatibility remain pending.

## Approved review decision: Character Engineering-Minded (2026-10-22)

The Product Owner approved **Character Engineering-Minded -> +10 Hacking** and
explicitly accepted additive stacking with Analytical (+10 Hacking), for **+20
Hacking total** when a linked Character has both Traits. Spending another Trait
selection to specialize is an intentional balance choice.

- Improves existing hacking checks; does not grant a GREMLIN or new hacking
  abilities. Uses the native Hacking stat; no new perk-pack dependency is needed.
- Preserve current additive stat resolution, link-time frozen snapshots and
  duplicate-application guards. Apply through future links, not a live refresh of
  existing linked soldiers.
- This supersedes the proposed Character Engineering-Minded exclusion below and
  in the companion CSV audit rows. Commander Engineering-Minded remains its
  existing one-time Engineer grant; no Commander change is approved here.
- Approved design only: no runtime configuration, code, canonical catalog, saved
  links, dependency installation or release changes have been made.

## Approved review decision: Character Resourceful (2026-10-22)

The Product Owner approved **Character Resourceful -> Full Kit (`FullKit`)**.
Its grenade benefit is accessible without a Grenadier class or grenade launcher.
Approved mechanic; implementation and public provider selection remain pending.

- The verified installed LWOTC implementation grants +1 use per qualifying grenade
  item equipped in a utility slot and explicitly includes Battle Scanners.
  It is not a universal +1 charge to every consumable, medikit or soldier ability,
  and does not apply to the dedicated grenade-pocket slot.
- Current source: `LW_PerkPack_Integrated.X2Ability_PerkPackAbilitySet2.AddFullKit`
  and `X2Effect_FullKit`; installed `FULL_KIT_BONUS=1`, included template
  `Battlescanner`, excluded grenade `GhostGrenade_LW`. Provider-specific eligibility,
  merged-item handling, specialty grenades and direct mission transfers need tests.
- Verified provider: [installed LWOTC, Workshop 2663990965](https://steamcommunity.com/sharedfiles/filedetails/?id=2663990965).
  Do not require a full overhaul solely for this perk or assume another pack's
  template/behavior is identical. Stock-WOTC dependency selection remains unresolved;
  this approval does not authorize a new dependency or changes to native perks.
- Resolve from updated Character snapshots at future soldier links. Preserve frozen
  existing links, duplicate-ability handling and per-mission charge application.
- Supersedes the proposed Character Resourceful exclusion below and in the companion
  CSV audit rows. Commander Resourceful retains its existing +5% Supplies mapping.
- No gameplay configuration, code, canonical catalog, installed dependencies, saves
  or release output changed by this approval. Gameplay acceptance remains pending.

## Approved review decision: Character Scientifically Minded (2026-10-22)

The Product Owner selected **Character Scientifically Minded -> Quick Patch
(`F_QuickPatch`)** from [Extended Perk Pack, Workshop 1546482849](https://steamcommunity.com/sharedfiles/filedetails/?id=1546482849).
Approved design only; implementation and gameplay acceptance remain pending.

- Refunds the action-point cost of the configured medikit actions. Verified default
  `QUICKPATCH_ABILITIES`: `MedikitHeal`, `NanoMedikitHeal`, `MedikitStabilize`,
  and `Sedate` where that separately provided action is available. Its absence
  does not authorize installing a new dependency just for that action.
- Normal medical charges, targeting/range and activation requirements still apply.
  The effect is a refund, not permission to activate with no remaining actions;
  no once-per-turn refund limit is configured. GREMLIN healing is not on the
  default ability list. Grants no medikit, healing multiplier or extra charges.
- Verified in `X2Ability_ExtendedPerkPack.QuickPatch`,
  `XMBEffect_AbilityCostRefund` and the installed `XComExtendedPerkPack.ini`.
- Resolve from updated Character snapshots on future soldier links; preserve
  existing frozen links and duplicate-ability handling. Public dependency packaging
  remains a separate review; no new pack is installed by this design approval.
- Supersedes the Character Scientifically Minded exclusion below and in the
  companion CSV audit rows. Anatomist, Butcher, Vitals Shot, Field Medic, Savior
  and Code Blue are not selected for this mapping. Commander Scientifically Minded
  retains its existing one-time Scientist grant.
- No gameplay configuration, code, canonical catalog, installed dependencies,
  saves or release output has changed by this approval.

## Approved review decision: Character Reckless and Overconfident (revised 2026-10-22)

The Product Owner revised the Character mappings to **Reckless -> -5 Dodge** and
**Overconfident -> -10 Defense**. This supersedes the earlier Reckless -5 Defense
re-approval and Overconfident -5 Defense approval. Taking both now applies the two
different stat penalties, not -15 Defense.

- Flat personal stat penalties; no conditional positioning rule, custom ability or
  new perk-pack dependency. Negative Traits are optional tradeoffs for additional
  positive selections; a meaningful downside is intentional.
- Leave negative-Dodge interpretation to the host game's combat rules; do not add
  custom conversion or impose a universal zero floor. The Product Owner accepts
  reduced effectiveness where Dodge cannot meaningfully fall below zero. The
  installed LWOTC enables `ALLOW_NEGATIVE_DODGE`, which converts negative Dodge
  into extra incoming critical-hit chance, not ordinary hit chance. Verify actual
  behavior in each supported gameplay profile before release and describe it
  accurately to players. No claim of identical stock-WOTC behavior is made here.
- Resolve through updated Character snapshots at future soldier links. Preserve
  existing frozen links and duplicate-application guards; do not retroactively
  change already linked soldiers.
- Supersedes the proposed Character Overconfident exclusion below and in the
  companion CSV audit rows. No Commander effect or canonical catalog change is
  approved by this decision. Character Extravagant is covered by its separate
  approval below; the earlier deployment Supplies expense was not selected.
- Approved design only: no gameplay configuration, code, dependencies, saves or
  release output changed. Implementation and gameplay acceptance remain pending.

## Approved review decision: Character Secretive (2026-10-22)

The Product Owner approved **Character Secretive -> 20% longer wound recovery**.
Flavor: reluctant to disclose injuries or admit their severity, this soldier takes
longer to recover. Approved design only; implementation and acceptance are pending.

- Personal post-mission wound-recovery penalty only. No additional tactical damage,
  squad-wide penalty, Will change, or bond-compatibility modification. Healthy
  soldiers do not acquire wounds from this Trait.
- Highlander v1.31.3 provides `WoundRecoveryTimeModifier` on
  `XComGameState_HeadquartersProjectHealSoldier`; its `ProjectFocus` identifies the
  recovering soldier. Use an immediate listener to adjust the supplied multiplier,
  not a timer that submits new history frames. No custom ability or new dependency.
- Despite the event's name/documentation, the inspected implementation multiplies
  healing work per hour. The intended 1.20 duration factor therefore requires a
  reciprocal rate multiplier (1 / 1.20), not 1.20 healing speed. Integer healing-rate
  and time rounding must be checked; describe the player-facing percentage as an
  intended duration penalty, not guaranteed exact timing in every configuration.
- Preserve other healing modifiers and verify native infirmary/staffing effects,
  supported overhaul behavior, UI estimates, save reloads and multiple linked
  soldiers. Do not repeatedly compound the penalty on recalculation.
- Freeze the selected effect through updated Character snapshots at future links;
  preserve already frozen links. No Commander change or canonical catalog change.
  Commander Secretive retains its existing -10% qualifying Intel-gain mapping.
- Supersedes the proposed Character Secretive exclusion below and in the companion
  CSV audit rows. Bonding and -5 Will suggestions were not selected.
- No gameplay configuration, code, dependencies, saves or release output changed.

## Approved review decision: Character Inquisitive (2026-10-22)

The Product Owner approved **Character Inquisitive -> +10% Intel awarded by a
tactical mission or covert action per participating Inquisitive soldier**.
Flavor: their curiosity uncovers useful details others overlook. Approved design
only; implementation and gameplay acceptance remain pending.

- Count the actual deployed tactical roster or assigned covert-action soldiers,
  not linked soldiers remaining on the Avenger. Add qualifying Character bonuses:
  two participating Inquisitive soldiers provide +20%. Count each soldier once.
- Increase only positive Intel actually awarded by that mission/action. No Intel
  reward means no bonus; do not invent a consolation award for a failed action or
  extend this Character effect to unrelated scans, POIs or other Intel sources.
- Combine eligible Character and Commander Intel percentages against the original
  award, without compounding one bonus on another. Commander Inquisitive remains
  +10% on its existing qualifying positive Intel gains. Character eligibility must
  not depend on possessing the Commander Trait.
- Present the adjusted reward and its contributing source(s) clearly to the player;
  test integer rounding, multiple participants and stacking with Commander effects.
- Existing `TNB_ResourceRewardHook` intercepts `Reward_Intel`, and
  `TNB_CommanderBonusService.QualifyingReward` identifies both mission and covert
  reward references. The reporting ledger already retains participating soldier
  IDs, including covert staff assignments. These provide a source-level path, not
  an already implemented Character bonus or full compatibility guarantee.
- Extend reward attribution to the correct mission/action and its retained roster;
  account for staff-slot cleanup and reward timing. Preserve other reward delegates,
  existing Commander behavior and save/reward duplicate-application protections.
  No new perk-pack dependency or custom soldier ability is required.
- Resolve the effect from updated Character snapshots at future links; preserve
  existing frozen links. No canonical catalog change is approved.
- Supersedes the proposed Character Inquisitive exclusion below and in the companion
  CSV audit rows. Recon-ability alternatives were not selected. No gameplay
  configuration, code, dependencies, saves or release output changed.

## Approved review decision: Character Extravagant (2026-10-22)

The Product Owner approved **Character Extravagant -> -10% Supplies awarded by a
tactical mission or covert action per participating Extravagant soldier**.
Flavor: their lavish use of equipment leaves fewer supplies to bring home.
Approved design only; implementation and gameplay acceptance remain pending.

- Use the actual deployed tactical roster or assigned covert-action soldiers,
  counting each soldier once. Penalties add: two participants with this Trait
  contribute -20%. Soldiers remaining on the Avenger do not contribute.
- Reduce only positive Supplies actually awarded by that mission/action. No Supplies
  reward means no penalty. No deployment fee, inventory deduction, monthly supply-
  drop penalty or effect on unrelated income is approved for this Character Trait.
- Combine eligible Character and Commander Supplies percentages against the
  original reward, without percentage-on-percentage compounding. Clamp the final
  award at zero rather than turning it into an inventory charge.
- Clearly show the adjusted reward, loss and contributing source(s). Test rounding,
  multiple participants, Commander stacking, retained rosters and reward timing,
  duplicate-application protection, save reloads and supported gameplay profiles.
- Follow the mission/action reward-attribution extension planned for Character
  Inquisitive. Existing interception of `Reward_Supplies` is a source-level
  foundation, not already implemented Character support. No custom ability or
  additional perk-pack dependency is required.
- Resolve from updated Character snapshots at future links; preserve existing
  frozen links. Commander Extravagant retains its existing -5% qualifying Supplies-
  gain mapping. No canonical catalog change is approved.
- Supersedes the proposed Character Extravagant exclusion below and in the companion
  CSV audit rows, and the earlier undecided status. The deployment-fee proposal
  remains unselected. No gameplay configuration, code, dependencies, saves or
  release output changed.

## Approved review decision: Character Pioneer (2026-10-22)

The Product Owner locked **Character Pioneer -> +5 Will**, replacing its earlier
provisional status. Personal native stat bonus only; no custom ability or additional
perk-pack dependency is required. The earlier Ever Vigilant proposal was not selected.

- Apply through updated Character snapshots at future soldier links; preserve
  existing frozen links and duplicate-application guards. Do not live-refresh or
  retroactively alter already linked soldiers.
- This bonus is additive with other distinct approved Will effects, including
  Strong-Willed (+5 Will), rather than replacing them.
- Supersedes the Character Pioneer exclusion below and in the companion CSV audit
  rows. Commander Pioneer retains its separate +1 Resistance contact-capacity effect.
- Approved design only: no gameplay configuration, code, canonical catalog,
  dependencies, saves or release output changed. Implementation/testing are pending.

## Approved review decision: Commander Strong-Willed (2026-10-22)

The Product Owner approved **Commander Strong-Willed -> 10% shorter soldier
fatigue (Will) recovery**. Flavor: the Commander's steady resolve helps soldiers
regain confidence after difficult operations. Approved design only; implementation
and gameplay acceptance remain pending.

- Campaign leadership benefit to soldiers undergoing normal Will recovery. No
  maximum-Will increase, tactical resistance, panic immunity, physical wound-healing
  bonus or instant fatigue removal is approved.
- Highlander v1.31.3 exposes `WillRecoveryTimeModifier` through
  `XComGameState_HeadquartersProjectRecoverWill`. An immediate listener can compose
  the approved campaign modifier with other recovery modifiers without a custom
  soldier ability, additional dependency or history-writing UI timer.
- The inspected code multiplies healing work per hour despite the event's
  duration-oriented documentation. Intended duration factor 0.90 therefore needs
  a reciprocal recovery-rate factor (1 / 0.90), not 0.90 recovery speed. Verify
  integer-rate/time rounding, displayed estimates and interactions with resistance
  orders, staffing/recovery effects and supported overhaul behavior.
- Freeze the effect at the first explicit campaign/Journey association from the
  Commander's snapshot. Prevent duplicate application or repeated compounding on
  recalculation/reload; preserve existing frozen links and campaign modifiers.
- Supersedes the proposed Commander Strong-Willed exclusion below and in the
  companion CSV audit rows. Character Strong-Willed remains +5 Will. No canonical
  catalog change or retroactive refresh of existing frozen links is approved.
- No gameplay configuration, code, dependencies, saves or release output changed.

## Approved review decision: Commander Analytical (revised 2026-10-22)

The Product Owner approved **Commander Analytical -> +10% research speed**, using
existing research-speed mechanics. This supersedes the flat one-day reduction,
zero-duration floor and special instant-completion proposal; do not implement
those. Approved design only; implementation and gameplay acceptance remain pending.

- Intended 1.10 research-rate multiplier, not 10% shorter duration. With unchanged
  staffing/modifiers this means approximately 9.1% shorter duration, subject to
  integer science-rate and time rounding. Preserve normal costs and prerequisites.
- Highlander v1.31.3 exposes `OverrideScienceScore` with an `AddLabBonus` flag that
  distinguishes research-output calculations from ordinary science-requirement
  checks. This provides an existing integration hook, not a flat-time adjustment.
  Preserve actual scientist counts and unlock/staffing requirements; inspect all
  relevant callers, including the facility UI's use of `GetScienceScore(true)`.
- Do not blindly overwrite native `ResearchEffectivenessPercentIncrease`: continent
  bonuses and resistance orders also assign that field. Compose with existing
  research modifiers and supported overhaul listeners, and prevent repeated
  compounding on recalculation or reload.
- Native science-score-independent projects may not benefit. Verify and document
  scope for breakthroughs, Shadow Chamber, repeatable and Proving Ground projects
  rather than inventing new timing machinery to force universal coverage. Match
  displayed estimates to actual progress and test staffing changes and active projects.
- Freeze at first explicit campaign/Journey association; preserve existing frozen
  links. No custom ability or additional dependency is selected.
- Supersedes the proposed Commander Analytical exclusion below and in the companion
  CSV audit rows. Character Analytical remains +10 Hacking. No canonical catalog,
  gameplay configuration, code, dependencies, saves or release output changed.

## Approved review decision: Commander Unperceptive (2026-10-22)

The Product Owner selected **Commander Unperceptive -> +5 percentage points of
covert-action ambush risk**, following the proposed amount (10% becomes 15%).
Flavor: the Commander overlooks warning signs. Approved design only; implementation
and gameplay acceptance remain pending.

- Modify only an existing, eligible ambush risk; do not create an ambush risk for
  actions without one or alter capture, injury, failure or other risk types.
  Preserve native risk-negation slots and protections that prevent ambushes.
- Verified in Highlander v1.31.3: `CovertActionRisk_AlterChanceModifier` supplies the
  risk template name and mutable additive chance modifier. Native risk resolution
  clamps the resulting percentage to 0..100 and honors `NegatedRisks`.
- Use the existing modifier rather than replacing it. Risks are cached: call
  `RecalculateRiskChanceToOccurModifiers` through a safe transaction when the
  campaign modifier becomes active, and preserve displayed risk consistency.
- Test existing/new actions, risk protections, Chosen/dark-event modifiers,
  supported overhaul listeners and save reloads. Prevent repeat compounding.
- Freeze at first explicit campaign/Journey association; preserve already frozen
  links. No new dependency, custom soldier ability or canonical catalog change.
- Supersedes the proposed Commander Unperceptive exclusion below and in the
  companion CSV audit rows. Research-duration and covert-duration penalties were
  not selected for this Trait. Character Unperceptive remains -1 Sight Radius.
- No gameplay configuration, code, dependencies, saves or release output changed.

## Approved review decision: Commander Observant (2026-10-22)

The Product Owner selected **Commander Observant -> -5 percentage points of
covert-action ambush risk**, the opposite of Commander Unperceptive. For example,
10% becomes 5%; final risk cannot fall below zero. Flavor: the Commander notices
warning signs and helps teams avoid ambushes. Approved design only; implementation
and gameplay acceptance remain pending.

- Use the same existing eligible ambush-risk scope as Unperceptive. No changes to
  capture, injury, failure or other risk types, and no creation of absent risks.
  Preserve native risk-negation slots and ambush protections.
- Compose the -5 point modifier with existing modifiers through Highlander
  v1.31.3's `CovertActionRisk_AlterChanceModifier`. If both approved Traits are
  present, their -5/+5 contributions cancel before final chance clamping.
- Refresh cached risks safely when activated, keep displayed risk consistent, and
  test existing/new actions, supported overhaul listeners and save reloads without
  repeated compounding. Follow the Unperceptive implementation/acceptance plan.
- Freeze at first explicit campaign/Journey association; preserve existing frozen
  links. No new dependency, custom soldier ability or canonical catalog change.
- Supersedes the proposed Commander Observant exclusion below and in the companion
  CSV audit rows. Character Observant remains +1 Sight Radius.
- No gameplay configuration, code, dependencies, saves or release output changed.

## Approved review decision: Commander Quick Learner (2026-10-22)

The Product Owner locked **Commander Quick Learner -> two random eligible barracks
soldiers each gain +1 Combat Intelligence tier**, once at the first explicit
campaign/Journey association. Flavor: the Commander helps others develop their
potential. Approved design only; implementation and gameplay acceptance are pending.

- Select two distinct player-owned barracks soldiers below Savant, not only linked
  Characters. Exclude dead, captured, non-soldier and otherwise ineligible units.
  If only one qualifies, improve that one; if none qualify, report that clearly.
  Do not silently invent a replacement reward or future-recruit backfill.
- Increase by exactly one native Combat Intelligence tier, capped at Savant. Grant
  no retroactive Ability Points, matching the existing Character Quick Learner
  policy. Do not interpret the stock Savant AP bonus of 7 as a tier index.
- Existing `TNB_SoldierEffectService` directly advances the native `ComInt` enum
  for the Character effect. Reuse that mechanic with new Commander recipient
  selection and one-time grant handling; no custom ability or new dependency.
- Save selected recipients and application results with the association transaction;
  reopening the flow or loading a post-association save must not reroll or repeat
  the award. A save from before association retains the normal rollback semantics.
- Clearly display recipient names and before/after tiers. Test zero/one/two eligible
  recipients, the Savant cap, future AP behavior, Character Quick Learner stacking
  and reload/reassociation guards. This is not a global roster learning multiplier.
- Resolve from the Commander's snapshot at future campaign associations; preserve
  existing frozen links. Character Quick Learner remains +1 tier, capped at Savant.
- Supersedes the proposed Commander Quick Learner exclusion below and in the
  companion CSV audit rows. No gameplay configuration, code, canonical catalog,
  dependencies, saves or release output changed.

## Approved review decision: Commander Reckless (2026-10-22)

The Product Owner confirmed **Commander Reckless -> +5 percentage points of
covert-action injury risk** (20% becomes 25%). Approved design only; implementation
and gameplay acceptance remain pending.

- Target the existing `CovertActionRisk_SoldierWounded` risk only. No increase to
  injury severity, capture, ambush or other risk types. Do not add wound risks to
  actions without one; preserve risk-negation slots and applicable protections.
- Use Highlander v1.31.3's `CovertActionRisk_AlterChanceModifier`, adding to existing
  modifiers and retaining native final 0..100 chance clamping. Follow the same
  cached-risk refresh, displayed-risk consistency and duplicate-application rules
  as Observant/Unperceptive. No custom soldier ability or additional dependency.
- Test existing/new actions, negated risks, Chosen/dark-event modifiers, supported
  overhaul listeners and save reloads without repeatedly compounding the penalty.
- Freeze at first explicit campaign/Journey association; preserve existing frozen
  links. Character Reckless retains its separately approved -5 Dodge effect.
- Supersedes the proposed Commander Reckless exclusion below and in the companion
  CSV audit rows. No gameplay configuration, code, canonical catalog, dependencies,
  saves or release output changed.

## Approved review decision: Commander Conspicuous (2026-10-22)

The Product Owner confirmed **Commander Conspicuous -> +25% Supplies cost for
standard Recruit Soldiers purchases**, with normal integer rounding. Flavor:
operating under a conspicuous Commander makes recruitment and transport more
expensive. Approved design only; implementation and gameplay acceptance are pending.

- Applies to standard recruit-screen hires, not rescued soldiers, mission rewards,
  existing barracks soldiers or other acquisition paths without an approved scope.
  No increase in recruit delivery time or reduction in candidate count is approved.
- Native `XComGameState_HeadquartersResistance.GetRecruitSupplyCost` calculates
  the price used by the hiring UI, affordability checks and `GiveRecruit` payment.
  Preserve that shared path so advertised and charged prices agree.
- The native formula combines difficulty-based cost, `RecruitCostModifier` and
  `RecruitScalar`. Continent/resistance bonuses and Dark Events assign those fields;
  do not blindly overwrite them or assume a one-time assignment survives updates.
  Compose the approved 1.25 price multiplier with normal pricing modifiers and
  verify rounding, bonus activation/removal and supported overhaul behavior.
- Source-level pricing support is verified; robust composition/reapplication still
  needs implementation validation. No custom soldier ability or new dependency.
- Freeze at first explicit campaign/Journey association; preserve existing frozen
  links and prevent repeated association/reload from compounding prices.
- Supersedes the proposed Commander Conspicuous exclusion below and in the companion
  CSV audit rows. Character Conspicuous retains its separately approved personal
  concealment-exposure effect. No gameplay configuration, code, canonical catalog,
  dependencies, saves or release output changed.

## Approved review decision: Commander Poor Stamina (2026-10-22)

The Product Owner carried forward **Commander Poor Stamina -> 10% longer soldier
fatigue (Will) recovery**, the opposite of Commander Strong-Willed, when closing
the remaining Commander choices. Approved design only; implementation and gameplay
acceptance remain pending.

- A strategic roster-recovery penalty, not a tactical Mobility/Will penalty or a
  physical wound-healing change. No instant fatigue or direct Will loss is approved.
- Use the same verified Highlander `WillRecoveryTimeModifier` path as Strong-Willed.
  Aggregate these opposing duration adjustments so Strong-Willed -10% and Poor
  Stamina +10% cancel if both are present, then translate duration into a reciprocal
  rate modifier. Preserve unrelated recovery modifiers and account for rounding.
- Freeze at first explicit campaign/Journey association; preserve existing frozen
  links and prevent compounding on recalculation/reload. Test displayed/actual
  recovery, both Traits together and supported overhaul interactions.
- Supersedes the proposed Commander Poor Stamina exclusion below and in the
  companion CSV audit rows. Character Poor Stamina remains -1 Mobility.
- No custom ability, new dependency, gameplay configuration, code, canonical
  catalog, saves or release output changed.

## Approved review decision: Commander Hardy (2026-10-22)

The Product Owner approved **Commander Hardy -> 10% shorter soldier wound
recovery**, conditional on the verified existing healing-hook implementation path.
Approved design only; implementation and gameplay acceptance remain pending.

- Physical post-mission wound recovery only. No tactical HP, damage reduction,
  fatigue recovery, wound prevention or immediate healing is approved.
- Highlander v1.31.3 exposes `WoundRecoveryTimeModifier` on the healing project.
  Follow the same safe immediate-listener path identified for Character Secretive.
  Intended duration factor 0.90 needs a reciprocal rate factor (1 / 0.90), since
  the native code multiplies healing work per hour. Verify integer/time rounding.
- Preserve infirmary, staffing and other healing effects. Define/test composition
  with Character Secretive's personal recovery penalty, displayed estimates,
  active/new healing projects, supported overhaul behavior and save reloads.
- Freeze at first explicit campaign/Journey association; preserve existing frozen
  links and prevent repeated compounding. No custom ability or new dependency.
- Supersedes the proposed Commander Hardy exclusion below and in the companion
  CSV audit rows. Character Hardy remains +1 HP. No gameplay configuration, code,
  canonical catalog, dependencies, saves or release output changed.

## Approved review decision: Commander Unlucky (2026-10-22)

The Product Owner approved **Commander Unlucky -> +5 percentage points of
covert-action capture risk**, conditional on the verified existing risk-modifier
path. Approved design only; implementation and gameplay acceptance remain pending.

- Target only existing eligible `CovertActionRisk_SoldierCaptured` risks. Do not
  add absent risks, increase injury/ambush chances or override capture-negation
  slots and applicable native protections. No tactical RNG changes are approved.
- Use Highlander v1.31.3's `CovertActionRisk_AlterChanceModifier`, composing with
  existing modifiers and retaining final 0..100 chance clamping. Follow the safe
  cached-risk refresh and UI-consistency plan for Reckless/Unperceptive/Observant.
- Capture is a harsher consequence than injury; include balance acceptance as well
  as tests for protected actions, eligible risks, Chosen availability, other risk
  modifiers, supported overhaul listeners and save reloads without compounding.
- Freeze at first explicit campaign/Journey association; preserve existing frozen
  links. No custom ability, new dependency or canonical catalog change.
- Supersedes the proposed Commander Unlucky exclusion below and in the companion
  CSV audit rows. Character Unlucky remains -5 Critical Hit Chance. No gameplay
  configuration, code, dependencies, saves or release output changed.

These Commander decisions complete the outstanding mapping-design choices from
this review. Approval addenda above supersede the original proposal matrices and
CSV rows; those artifacts still require consolidation. Design approval does not
mean runtime implementation, public provider/dependency qualification or in-game
acceptance has been completed.

## Executive recommendation

1. **Retain the original approved effects where still valid:** nine soldier stat/
   intelligence Traits, native Evasive Maneuvers, Modpocalypse Chamber Round, and the
   current ten Commander Trait/Skill effects. Do not revert Commander percentages or
   monthly Scrounger to the old campaign-start-only rewards.
2. **Retain the four other original soldier Skill mechanics**, but resolve a default
   provider profile explicitly. Recommend Modpocalypse plus the **class-free LW2
   perk library** for stock WOTC, subject to source/identifier/behavior verification.
   Existing LWOTC users should use its already-integrated versions instead.
   This is two ability packs in the proposed stock profile, not a growing pack list.
   It does not require a full class overhaul. See the qualification in §6.
3. **Explicitly exclude unsupported contexts rather than manufacture bonuses.**
   Do not apply a soldier's HP/Will to the whole squad, turn Secretive into a stealth
   advantage, duplicate unrelated campaign rewards, or grant a Specialist kit just
   because a Trait sounds technical.
4. Keep acquired Traits as identity/history markers with **No default XCOM 2 effect**.
   Retain the canonical Skill type restrictions and separate identity progression.
5. Preserve frozen snapshots, link-time application, saved ledgers and organizer
   overrides. The reference describes a shipped default, never a live customized
   campaign or automatic canonical-to-game synchronization.

There are **25 current configured mapping rows**. The proposal preserves their
effect direction/approved amounts and adds no arbitrary numerical Trait effects.
Four provider-dependent Skill rows are **Needs decision**, not verified drop-in
replacements. The remaining current-context gaps are intentional-exclusion proposals.

## 1. Exact baselines and source authority

- Primary repo: `chand-gaming-dev/tnb-xcom2-integration`, clean `main`
  `0995fb7458ed5c211502ae459829cd803a6d4ed4`, mod 0.9.2 / companion 0.10.3.
- Current mapping revision: `tnb-alpha-2026-10-19-r2`.
- Source INI SHA-256: `783806d6c65b6e65b85a1013c6a93c4fcbbc7431dd7e9fc0820a0f377c47d0d3`.
- Related local source inspected: `b66b303c5f03bc7d3eefde9671f1e2e2b102c4d1`;
  local remote-tracking main: `7efc948514a75f1dc1b155fe1db16b7739952183`.
  The production-enablement branch was not changed or treated as a new catalog.
- Canonical definitions read directly from [GitHub main](https://github.com/chand-gaming-dev/project-threadline/blob/main/apps/api/src/catalogs/definitions.ts)
  and verified against local Git blob **`5898da51a39b4235fa4be4b89f4cf99a28ca1d14`**.
  Traits use catalog revision **0.3**; current Skills remain **0.2**. Definition
  version, catalog revision and snapshot capture version are different concepts.
- This is a **source-catalog audit**, not a claim that a live database/Portal rollout
  was checked. Before release, reconcile the actual catalog API with this manifest.
  No account credentials, private player snapshots or production database were read.

### Source register

Paths are repository-relative unless marked LOCAL ARCHIVE. The two local archive
documents are deliberately excluded from the public source snapshot; cite their
provenance without republishing their content or unsafe prototype assumptions.

| Source | Exact location | Authority / use |
| --- | --- | --- |
| S0 | Related repo: `docs/xcom2-reference-integration.md`, especially §Trait and Skill mappings; primary repo LOCAL ARCHIVE `TheNameBeneath/xcom2_api_integration_guide.md` | Historical integration examples/prototype. Generic sample IDs and DLL/INI-token assumptions are not approved catalog mappings or current transport design. |
| S1 | Related repo: `docs/milestone-5-identity-growth-avatars.md`, §2 Character starting Traits / Commander starting Traits and §3 Level-one Skill catalog | Original approved matrix located and read before proposing changes. M5 accepted 2026-10-15; mechanic targets, not proof of template/dependency validation. Its original role split and later AP-row proposal are superseded as described below. |
| S2 | Related repo: `docs/decisions/DDR-001-identity-types-and-canonical-trait-model.md`; `docs/milestone-5.1-trait-unification-assessment.md`; `docs/milestone-5.1-closeout.md`; `packages/contracts/src/catalogs.ts` | Accepted M5.1: role-agnostic Chosen/Acquired Traits, separate identities, unchanged Skill applicability/acquisition criteria. No authorization to invent new XCOM effects. |
| S3 | Primary repo: `Docs/COMMANDER_MAPPINGS.md` | Explicit owner approval 2026-10-18 and Scrounger timing amendment 2026-10-20: current mixed one-time/ongoing Commander defaults. |
| S4 | Primary repo: `TheNameBeneath/Config/XComTheNameBeneath.ini`; `Docs/MAPPING_CUSTOMIZATION.md` | Actually shipped source defaults and keyed override precedence, corrected Chamber Round template/provider, definition-version ranges. |
| S5 | Primary repo LOCAL ARCHIVE: `TheNameBeneath/threadline_xcom2_v1_implementation_plan.md`, opening amendments and §§11–13; `Docs/IMPLEMENTATION_STATUS.md`; `Docs/FEEDBACK_AND_NEXT_TESTS.md` | Later owner decisions: automatic soldier effects without a fourth/AP row; save-authoritative rewinds; explicit campaign association; frozen effects; subsequent user acceptance. Archived plan filenames are historical source identifiers, not public branding. |
| S6 | Primary repo: `TheNameBeneath/Src/TheNameBeneath/Classes/TNB_MappingConfig.uc`; `TNB_MappingResolver.uc`; `TNB_SoldierEffectService.uc`; `TNB_CampaignService.uc` | Actual resolver/effect kinds, stat/Combat Intelligence implementation, saved grants/ability injection and one-time campaign association. |
| S7 | Primary repo: `Docs/RESOURCE_COVERAGE.md`; `TNB_CommanderBonusService.uc`; `TNB_ResourceRewardHook.uc`; `XComGameState_TNBCampaignLink.uc` under the same Classes directory | Actual qualifying percentage gains, exclusion allowlist, truncation, saved resource/month guards and frozen Commander mappings. |
| S8 | Primary repo: `Docs/COMMANDER_MONTHLY_REWARDS_TESTING.md`; `Docs/SUPPLY_DISPLAY_TESTING.md`; `Docs/COVERT_AND_INVENTORY_TESTING.md`; `Docs/SCROUNGER_COPY_TESTING.md`; `TNB_CommanderRewardPresentation.uc` | Monthly rollover independent of income/collection, native inventory stacking, visible item and signed supply-receipt UX; recorded acceptance, not claims that every resource origin was tested. |
| S9 | Related repo: `apps/api/src/catalogs/definitions.ts`; `seed.ts`; `repository.ts`; `trait-representation.ts`; `packages/contracts/src/catalogs.ts` | Current published built-in catalog, lifecycle/version preservation, role-agnostic API representation and acquired-Trait criteria. Current GitHub main definitions blob verified against local source. |
| S10 | Issue #18: https://github.com/chand-gaming-dev/project-threadline/issues/18 (read 2026-10-22; no comments) | Current audit mandate, two/three-pack ceiling, explicit exclusions, no combination-balance exercise, no implementation and separately approved static Portal reference. |
| S11 | Related repo: `apps/portal/src/assets/canonical-artwork.ts`; `canonical-glyph.tsx` and `canonical-definition-label.tsx` under `apps/portal/src/components/`; primary `TNB_EffectPresentation.uc`; `LICENSING.md` | Canonical SVG versus actual game ability art, dynamic wording and asset provenance/rights inventory. No export or packaging. |


### Resolution of superseded designs

- **M5 original matrix:** ten Character Traits (Conspicuous intentionally lacked a
  number), seven Commander Traits, six Character Skills and three Commander Skills.
- **M5.1 accepted refinement:** all 17 Chosen Traits may be selected by either identity;
  all three Acquired definitions are also role-agnostic. The original matrix is not
  a current eligibility table. This refinement did not create cross-context mechanics.
- **Commander approval 2026-10-18:** Resourceful/Inquisitive/Extravagant/Secretive become
  ongoing percentage modifiers. Engineer/Scientist/Avatar and Quartermaster/
  Counterintelligence stay one-time. Those explicit exceptions supersede any old
  blanket “all percentages” or “no starting rewards” assumptions.
- **Soldier integration approval 2026-10-18/19:** traits and purchased snapshot Skills
  apply automatically at linking through the earned-ability hook. The older M5
  Community Promotion Screen/AP purchase row is superseded. No new AP expense.
- **2026-10-19:** Weapon Handling resolves to `SingleReloadMrC` (Chamber Round),
  not the display-name-like `ChamberRound` identifier.
- **2026-10-20:** Scrounger triggers at monthly rollover, even with no income/cache,
  not at first pickup. Its dismissible discovery popup and correct inventory stacking
  have been user-tested.
- New occurrence/XP event work and the restored Avenger invitation do not refresh
  canonical characteristics, rebalance links or change these mapping rules.

## 2. Exhaustive catalog reconciliation

**29 published IDs:** 17 Chosen Traits + 3 Acquired Traits + 9 Skills.
Every published ID has both Character and Commander rows below: **58 current-context
decisions**, including **9 canonically inapplicable Skill contexts**.
A further **13 deprecated-only IDs** are classified for both contexts in §5.
Total: **42 distinct canonical IDs / 84 context dispositions**.

The seeded archive contains **64 distinct (ID, version) definitions**. The companion
[version coverage CSV](TRAIT_SKILL_MAPPING_AUDIT_VERSIONS.csv) explicitly checks all
**128 definition-version/context pairs** against existing ranges. No retired version
is silently repinned. No unknown INI source ID or current mapped version miss was found.

The [full mapping CSV](TRAIT_SKILL_MAPPING_AUDIT_MATRIX.csv) contains the canonical
name/definition, version, classification, applicability, original mapping, subsequent
decisions, current configured effect/key/range, proposed effect, provider, frequency,
rationale and status for every one of the 84 dispositions. This is **review data**,
not a runtime mapping manifest or an implementation of a new mapping engine.

Definitions below are concise canonical renderings, not new definitions. Pioneer
uses the public product name in this rendering; the source-copy discrepancy is
flagged separately in §8.

| Canonical ID @ current version | Name / classification | Canonical definition (concise rendering) | Canonical applicability |
| --- | --- | --- | --- |
| `trait.strong-willed@2` | Strong-Willed — positive Chosen | Maintains mental resolve under pressure. | Both (see acquired-path caveats) |
| `trait.hardy@2` | Hardy — positive Chosen | Has an inherently robust physical constitution. | Both (see acquired-path caveats) |
| `trait.observant@2` | Observant — positive Chosen | Notices details and activity in the surroundings. | Both (see acquired-path caveats) |
| `trait.analytical@2` | Analytical — positive Chosen | Has an aptitude for methodical reasoning about complex systems. | Both (see acquired-path caveats) |
| `trait.quick-learner@2` | Quick Learner — positive Chosen | Readily assimilates unfamiliar knowledge and experience. | Both (see acquired-path caveats) |
| `trait.reckless@3` | Reckless — negative Chosen | Takes unnecessary risks without considering consequences | Both (see acquired-path caveats) |
| `trait.unlucky@2` | Unlucky — negative Chosen | Has a persistent tendency toward unfavorable chance outcomes. | Both (see acquired-path caveats) |
| `trait.unperceptive@2` | Unperceptive — negative Chosen | Often overlooks details and activity in the surroundings. | Both (see acquired-path caveats) |
| `trait.poor-stamina@2` | Poor Stamina — negative Chosen | Has limited inherent capacity for sustained exertion. | Both (see acquired-path caveats) |
| `trait.conspicuous@2` | Conspicuous — negative Chosen | Naturally draws notice and has difficulty remaining unobtrusive. | Both (see acquired-path caveats) |
| `trait.resourceful@3` | Resourceful — positive Chosen | Finds creative solutions using limited resources. | Both (see acquired-path caveats) |
| `trait.engineering-minded@2` | Engineering-Minded — positive Chosen | Has an enduring aptitude for practical engineering problems. | Both (see acquired-path caveats) |
| `trait.scientifically-minded@2` | Scientifically Minded — positive Chosen | Naturally approaches problems through scientific inquiry. | Both (see acquired-path caveats) |
| `trait.inquisitive@2` | Inquisitive — positive Chosen | Persistently seeks information and investigates uncertainty. | Both (see acquired-path caveats) |
| `trait.extravagant@2` | Extravagant — negative Chosen | Tends toward excessive expenditure and consumption. | Both (see acquired-path caveats) |
| `trait.secretive@2` | Secretive — negative Chosen | Habitually withholds information and works discreetly. | Both (see acquired-path caveats) |
| `trait.overconfident@2` | Overconfident — negative Chosen | Overestimates readiness and underestimates threats. | Both (see acquired-path caveats) |
| `trait.battle-scarred@2` | Battle-Scarred — Acquired | Enduring marks of severe hardship. | Both (see acquired-path caveats) |
| `trait.pioneer@2` | Pioneer — Acquired | Participation in The Name Beneath's inaugural alpha. | Both (see acquired-path caveats) |
| `trait.tactician@2` | Tactician — Acquired | Demonstrated consistent mission-planning success. | Both (see acquired-path caveats) |
| `skill.evasive-maneuvers@1` | Evasive Maneuvers — Skill | Trained movement to evade hostile reactions. | character |
| `skill.cover-discipline@1` | Cover Discipline — Skill | Learned effective use of available cover. | character |
| `skill.weapon-handling@1` | Weapon Handling — Skill | Developed preparation and handling of weapons. | character |
| `skill.leading-shots@1` | Leading Shots — Skill | Trained anticipation of a moving target's path. | character |
| `skill.field-surgery@1` | Field Surgery — Skill | Learned emergency surgical care in field conditions. | character |
| `skill.independent-operator@1` | Independent Operator — Skill | Trained effectiveness when operating without close support. | character |
| `skill.quartermaster@1` | Quartermaster — Skill | Trained management and provisioning of supplies. | commander |
| `skill.counterintelligence@1` | Counterintelligence — Skill | Learned disruption of hostile intelligence operations. | commander |
| `skill.scrounger@1` | Scrounger — Skill | Developed ability to locate useful commonplace supplies. | commander |


### Acquired-path caveats

All three definitions are role-agnostic, but that is not automatic acquisition:

- Battle-Scarred currently has valid Character-subject injury/death evidence only;
  Commanders do not inherit their soldiers' hardship.
- Tactician currently qualifies the organizing Journey Commander at explicit finish,
  not participating Characters merely because the mission side won.
- Pioneer has identity-attributed paths for both; its server-controlled interval is
  disabled unless configured. A roster entry alone is not the grant.
- None requires a new XCOM mechanical perk, retroactive stat change or live refresh.

## 3. Character / soldier matrix

**Status legend:** Keep = retain the working/approved target; Needs decision =
mechanic retained but proposed provider profile not verified/approved; Unmapped =
explicit **No default XCOM 2 effect** proposal (or canonical Skill inapplicability).
No default mapping is not a missing-provider fallback: these are separate cases.

| ID @ version | Original approved target [S1] | Current configured behavior [S4] | Proposed shipped default | Provider / frequency | Rationale | Status |
| --- | --- | --- | --- | --- | --- | --- |
| `trait.strong-willed@2` | +5 Will | +5 Will | +5 Will | P0 (native mechanics via TNB); Resolved once at soldier link; stat/intelligence changes saved; abilities supplied through the earned-ability hook | Will is a direct native expression of mental resolve; retain the approved modest fixed delta. | Keep |
| `trait.hardy@2` | +1 HP | +1 HP | +1 HP | P0 (native mechanics via TNB); Resolved once at soldier link; stat/intelligence changes saved; abilities supplied through the earned-ability hook | Native HP expresses physical robustness without inventing an active ability. | Keep |
| `trait.observant@2` | +1 sight radius | +1 sight radius | +1 sight radius | P0 (native mechanics via TNB); Resolved once at soldier link; stat/intelligence changes saved; abilities supplied through the earned-ability hook | Sight radius directly expresses observation; retain the approved delta. | Keep |
| `trait.analytical@2` | +10 Hacking | +10 Hacking | +10 Hacking | P0 (native mechanics via TNB); Resolved once at soldier link; stat/intelligence changes saved; abilities supplied through the earned-ability hook | Native Hacking is the approved local expression of complex-system reasoning. | Keep |
| `trait.quick-learner@2` | +1 Combat Intelligence tier, capped at Savant | +1 Combat Intelligence tier (maximum Savant); no retroactive AP | +1 Combat Intelligence tier (maximum Savant); no retroactive AP | P0 (native mechanics via TNB); Resolved once at soldier link; stat/intelligence changes saved; abilities supplied through the earned-ability hook | Combat Intelligence expresses learning potential; retain the cap and no-retroactive-AP behavior rather than add XP multipliers. | Keep |
| `trait.reckless@3` | -5 Defense | -5 Defense | -5 Defense | P0 (native mechanics via TNB); Resolved once at soldier link; stat/intelligence changes saved; abilities supplied through the earned-ability hook | The approved Defense penalty expresses exposure from risky behavior; no redesign requested. | Keep |
| `trait.unlucky@2` | -5 critical chance | -5 critical chance | -5 critical chance | P0 (native mechanics via TNB); Resolved once at soldier link; stat/intelligence changes saved; abilities supplied through the earned-ability hook | Retain the approved critical-chance penalty; it is the existing local expression, not a universal definition of luck. | Keep |
| `trait.unperceptive@2` | -1 sight radius | -1 sight radius | -1 sight radius | P0 (native mechanics via TNB); Resolved once at soldier link; stat/intelligence changes saved; abilities supplied through the earned-ability hook | Native sight-radius reduction directly expresses reduced perception. | Keep |
| `trait.poor-stamina@2` | -1 Mobility | -1 Mobility | -1 Mobility | P0 (native mechanics via TNB); Resolved once at soldier link; stat/intelligence changes saved; abilities supplied through the earned-ability hook | Retain the approved Mobility penalty without introducing an unsupported stamina subsystem. | Keep |
| `trait.conspicuous@2` | Increased concealment detection exposure; magnitude deferred | No configured mapping in this context | No default XCOM 2 effect | None; None | Original target was never numerically approved; the resolver does not support detection-radius or concealment-exposure effects. Prefer an explicit exclusion over a fabricated stat. | Unmapped |
| `trait.resourceful@3` | No approved mapping for this context in M5 | No configured mapping in this context | No default XCOM 2 effect | None; None | No personal resource economy or faithful generic resource-efficiency effect is supported for a soldier. Do not turn this into free equipment or copy the commander's income bonus. | Unmapped |
| `trait.engineering-minded@2` | No approved mapping for this context in M5 | No configured mapping in this context | No default XCOM 2 effect | None; None | No separate engineering stat is supported. Hacking or a combat drone would substitute a different aptitude or Specialist training for this characteristic. | Unmapped |
| `trait.scientifically-minded@2` | No approved mapping for this context in M5 | No configured mapping in this context | No default XCOM 2 effect | None; None | Scientific inquiry is not automatically combat hacking or medical training; no individual research mechanic is supported. | Unmapped |
| `trait.inquisitive@2` | No approved mapping for this context in M5 | No configured mapping in this context | No default XCOM 2 effect | None; None | Seeking information is not the same as improved eyesight. No suitable general investigation mechanic exists in the supported resolver. | Unmapped |
| `trait.extravagant@2` | No approved mapping for this context in M5 | No configured mapping in this context | No default XCOM 2 effect | None; None | No personal spending/upkeep mechanic is supported. Arbitrary ammo or movement penalties would misrepresent excessive expenditure. | Unmapped |
| `trait.secretive@2` | No approved mapping for this context in M5 | No configured mapping in this context | No default XCOM 2 effect | None; None | Withholding information is not trained stealth. A concealment bonus would reverse this negative Trait rather than express its communication drawback. | Unmapped |
| `trait.overconfident@2` | No approved mapping for this context in M5 | No configured mapping in this context | No default XCOM 2 effect | None; None | No supported conditional overconfidence mechanic; do not invent an unrelated penalty or silently reuse Reckless's effect. | Unmapped |
| `trait.battle-scarred@2` | No mechanical mapping required (M5) | No configured mapping in this context | No default XCOM 2 effect | None; None | Retain the M5 decision: acquired identity markers have no default XCOM mechanical effect. No live snapshot refresh or retroactive grant; acquisition still follows identity-attributed canonical evidence. | Unmapped |
| `trait.pioneer@2` | No mechanical mapping required (M5) | No configured mapping in this context | No default XCOM 2 effect | None; None | Retain the M5 decision: acquired identity markers have no default XCOM mechanical effect. No live snapshot refresh or retroactive grant; acquisition still follows identity-attributed canonical evidence. | Unmapped |
| `trait.tactician@2` | No mechanical mapping required (M5) | No configured mapping in this context | No default XCOM 2 effect | None; None | Retain the M5 decision: acquired identity markers have no default XCOM mechanical effect. No live snapshot refresh or retroactive grant; acquisition still follows identity-attributed canonical evidence. | Unmapped |
| `skill.evasive-maneuvers@1` | Lightning Reflexes | Lightning Reflexes (native): first reaction shot against this soldier each turn misses [LightningReflexes] | Lightning Reflexes (native): first reaction shot against this soldier each turn misses [LightningReflexes] | P0 (native XCOM/WOTC); Resolved once at soldier link; stat/intelligence changes saved; abilities supplied through the earned-ability hook | The existing native perk fits reaction-fire evasion. Do not replace it with Shadowstep or the differently behaving LW2 Lightning Reflexes. | Keep |
| `skill.cover-discipline@1` | Low Profile | Low Profile: partial cover counts as full [LowProfile] | Low Profile: partial cover counts as full. Recommend the class-free P3 counterpart for stock WOTC after its exact template is verified; preserve LowProfile in the LWOTC profile. | P2 (installed LWOTC); P3 class-free alternative PROPOSED/unverified; Resolved once at soldier link; stat/intelligence changes saved; abilities supplied through the earned-ability hook | Low Profile directly expresses learned use of cover. Preserve the mechanic; resolve the stock-WOTC provider profile before implementation. | Needs decision |
| `skill.weapon-handling@1` | Chamber Round (display name only) | Chamber Round: free primary-weapon single-round reload, 2 AP required, 2 charges [SingleReloadMrC] | Chamber Round: free primary-weapon single-round reload, 2 AP required, 2 charges [SingleReloadMrC] | P1 (Modpocalypse); Resolved once at soldier link; stat/intelligence changes saved; abilities supplied through the earned-ability hook | The approved Chamber Round mechanic is working. Preserve the verified SingleReloadMrC target rather than revert to the historical display-name-as-template error. | Keep |
| `skill.leading-shots@1` | Grazing Fire | Grazing Attacks: missed weapon attacks may become grazes; installed provider base chance 50%, reduced by target Dodge [GrazingFire] | Grazing Fire counterpart: missed weapon shots can become grazes. P3 wording/weapon restrictions require verification; the LWOTC profile retains Grazing Attacks. | P2 (installed LWOTC); P3 class-free alternative PROPOSED/unverified; Resolved once at soldier link; stat/intelligence changes saved; abilities supplied through the earned-ability hook | Preserve the approved missed-shot-to-graze mechanic. The installed LWOTC display name is Grazing Attacks; do not promise a flat aim bonus. | Needs decision |
| `skill.field-surgery@1` | Field Surgeon | Field Surgeon: eligible squad wounds need 1 fewer HP healed after a mission; native provider conditions apply [FieldSurgeon] | Field Surgeon counterpart: reduce eligible post-mission wound recovery. Verify P3 amount, recipients and cleanup hook; preserve the verified LWOTC effect in that profile. | P2 (installed LWOTC); P3 class-free alternative PROPOSED/unverified; Resolved once at soldier link; stat/intelligence changes saved; abilities supplied through the earned-ability hook | Preserve the approved end-of-mission wound-recovery benefit, not a new active heal or medikit charge. | Needs decision |
| `skill.independent-operator@1` | Lone Wolf | Lone Wolf: distance-based Aim/Defense bonus; installed LWOTC caps at +12/+12, +0 Crit; not a fixed global bonus [LoneWolf] | Lone Wolf counterpart: conditional Aim/Defense while separated from allies. Verify P3 thresholds, values and any Crit component; do not import LWOTC's +12/+12 numbers into another provider. | P2 (installed LWOTC); P3 class-free alternative PROPOSED/unverified; Resolved once at soldier link; stat/intelligence changes saved; abilities supplied through the earned-ability hook | Preserve the approved distance-from-allies perk. Provider-specific bonus values/descriptions must not be treated as universally identical. | Needs decision |
| `skill.quartermaster@1` | No approved mapping for this context in M5 | No configured mapping in this context (canonically inapplicable Skill) | No default XCOM 2 effect | None; None | Canonical Skill eligibility excludes this identity type. A local override cannot make the Skill purchasable or authorize transferring it from another identity. | Unmapped |
| `skill.counterintelligence@1` | No approved mapping for this context in M5 | No configured mapping in this context (canonically inapplicable Skill) | No default XCOM 2 effect | None; None | Canonical Skill eligibility excludes this identity type. A local override cannot make the Skill purchasable or authorize transferring it from another identity. | Unmapped |
| `skill.scrounger@1` | No approved mapping for this context in M5 | No configured mapping in this context (canonically inapplicable Skill) | No default XCOM 2 effect | None; None | Canonical Skill eligibility excludes this identity type. A local override cannot make the Skill purchasable or authorize transferring it from another identity. | Unmapped |


## 4. Commander / campaign matrix

The Commander is a strategic identity, not a hidden tactical soldier. “One time”
means the first explicit association in the loaded campaign timeline, including a
late association, not necessarily New Game. Ongoing amounts are frozen then; they
do not grow automatically as TNB XP or Skill purchases change.

| ID @ version | Original approved target [S1] | Current configured behavior [S4] | Proposed shipped default | Provider / frequency | Rationale | Status |
| --- | --- | --- | --- | --- | --- | --- |
| `trait.strong-willed@2` | No approved mapping for this context in M5 | No configured mapping in this context | No default XCOM 2 effect | None; None | The campaign Commander is not a tactical unit with Will. No supported leadership-resolve mechanic justifies a global squad immunity or Avatar alteration. | Unmapped |
| `trait.hardy@2` | No approved mapping for this context in M5 | No configured mapping in this context | No default XCOM 2 effect | None; None | The campaign Commander has no tactical HP pool; do not give every soldier a physical characteristic belonging to a different identity. | Unmapped |
| `trait.observant@2` | No approved mapping for this context in M5 | No configured mapping in this context | No default XCOM 2 effect | None; None | No strategic perception stat is supported. Extra Intel is already an information-gathering interpretation of Inquisitive, not automatically eyesight. | Unmapped |
| `trait.analytical@2` | No approved mapping for this context in M5 | No configured mapping in this context | No default XCOM 2 effect | None; None | A research-efficiency interpretation is plausible but not supported by the existing commander effect kinds. No new facility/research interceptor is justified solely for coverage. | Unmapped |
| `trait.quick-learner@2` | No approved mapping for this context in M5 | No configured mapping in this context | No default XCOM 2 effect | None; None | No campaign Commander Combat Intelligence stat exists. Do not change canonical XP, Skill prices or all soldiers' learning to simulate it. | Unmapped |
| `trait.reckless@3` | No approved mapping for this context in M5 | No configured mapping in this context | No default XCOM 2 effect | None; None | No Commander Defense stat or verified risk-taking mechanic is supported. Do not silently duplicate Overconfident's Avatar grant. | Unmapped |
| `trait.unlucky@2` | No approved mapping for this context in M5 | No configured mapping in this context | No default XCOM 2 effect | None; None | No personal strategic luck statistic is supported. Global RNG manipulation would be a new subsystem and an arbitrary effect. | Unmapped |
| `trait.unperceptive@2` | No approved mapping for this context in M5 | No configured mapping in this context | No default XCOM 2 effect | None; None | No strategic sight statistic is supported. An Intel penalty would be an unapproved conflation with Secretive. | Unmapped |
| `trait.poor-stamina@2` | No approved mapping for this context in M5 | No configured mapping in this context | No default XCOM 2 effect | None; None | No physical campaign Commander Mobility/stamina statistic exists; Avenger travel or staff fatigue would affect unrelated entities. | Unmapped |
| `trait.conspicuous@2` | No approved mapping for this context in M5 | No configured mapping in this context | No default XCOM 2 effect | None; None | No campaign Commander concealment/detection mechanic is supported. Do not substitute an unrelated Avatar or Intel penalty. | Unmapped |
| `trait.resourceful@3` | +50 starting Supplies | +5% Supplies on qualifying positive gains | +5% Supplies on qualifying positive gains | P0 (native mechanics via TNB); Ongoing after association; allowlisted qualifying gains only | Keep the later approved recurring Supplies efficiency bonus; do not restore the superseded +50 starting reward. | Keep |
| `trait.engineering-minded@2` | +1 starting Engineer | +1 Engineer once at explicit campaign/Journey association | +1 Engineer once at explicit campaign/Journey association | P0 (native mechanics via TNB); Once at first explicit campaign/Journey association, not necessarily campaign start | Keep the explicit one-time staff benefit. A recurring engineering/research multiplier was not approved. | Keep |
| `trait.scientifically-minded@2` | +1 starting Scientist | +1 Scientist once at explicit campaign/Journey association | +1 Scientist once at explicit campaign/Journey association | P0 (native mechanics via TNB); Once at first explicit campaign/Journey association, not necessarily campaign start | Keep the explicit one-time staff benefit; do not infer recurring research speed from the other recurring Commander changes. | Keep |
| `trait.inquisitive@2` | +20 starting Intel | +10% Intel on qualifying positive gains | +10% Intel on qualifying positive gains | P0 (native mechanics via TNB); Ongoing after association; allowlisted qualifying gains only | Keep the later approved ongoing Intel bonus, not the superseded +20 starting grant. | Keep |
| `trait.extravagant@2` | -15 starting Supplies | -5% Supplies on qualifying positive gains | -5% Supplies on qualifying positive gains | P0 (native mechanics via TNB); Ongoing after association; allowlisted qualifying gains only | Keep the approved ongoing Supplies penalty, not the old -15 starting grant or periodic flat deduction. | Keep |
| `trait.secretive@2` | -10 starting Intel | -10% Intel on qualifying positive gains | -10% Intel on qualifying positive gains | P0 (native mechanics via TNB); Ongoing after association; allowlisted qualifying gains only | Keep the approved ongoing Intel penalty, not the old -10 starting grant. | Keep |
| `trait.overconfident@2` | +1 Avatar Project progress pip | +1 Avatar Project progress pip once at association; actual change can be zero | +1 Avatar Project progress pip once at association; actual change can be zero | P0 (native mechanics via TNB); Once at first explicit campaign/Journey association, not necessarily campaign start | Keep the explicit one-time Avatar liability; it was not converted into a monthly penalty. | Keep |
| `trait.battle-scarred@2` | No mechanical mapping required (M5) | No configured mapping in this context | No default XCOM 2 effect | None; None | Retain the M5 decision: acquired identity markers have no default XCOM mechanical effect. No live snapshot refresh or retroactive grant; acquisition still follows identity-attributed canonical evidence. | Unmapped |
| `trait.pioneer@2` | No mechanical mapping required (M5) | No configured mapping in this context | No default XCOM 2 effect | None; None | Retain the M5 decision: acquired identity markers have no default XCOM mechanical effect. No live snapshot refresh or retroactive grant; acquisition still follows identity-attributed canonical evidence. | Unmapped |
| `trait.tactician@2` | No mechanical mapping required (M5) | No configured mapping in this context | No default XCOM 2 effect | None; None | Retain the M5 decision: acquired identity markers have no default XCOM mechanical effect. No live snapshot refresh or retroactive grant; acquisition still follows identity-attributed canonical evidence. | Unmapped |
| `skill.evasive-maneuvers@1` | No approved mapping for this context in M5 | No configured mapping in this context (canonically inapplicable Skill) | No default XCOM 2 effect | None; None | Canonical Skill eligibility excludes this identity type. A local override cannot make the Skill purchasable or authorize transferring it from another identity. | Unmapped |
| `skill.cover-discipline@1` | No approved mapping for this context in M5 | No configured mapping in this context (canonically inapplicable Skill) | No default XCOM 2 effect | None; None | Canonical Skill eligibility excludes this identity type. A local override cannot make the Skill purchasable or authorize transferring it from another identity. | Unmapped |
| `skill.weapon-handling@1` | No approved mapping for this context in M5 | No configured mapping in this context (canonically inapplicable Skill) | No default XCOM 2 effect | None; None | Canonical Skill eligibility excludes this identity type. A local override cannot make the Skill purchasable or authorize transferring it from another identity. | Unmapped |
| `skill.leading-shots@1` | No approved mapping for this context in M5 | No configured mapping in this context (canonically inapplicable Skill) | No default XCOM 2 effect | None; None | Canonical Skill eligibility excludes this identity type. A local override cannot make the Skill purchasable or authorize transferring it from another identity. | Unmapped |
| `skill.field-surgery@1` | No approved mapping for this context in M5 | No configured mapping in this context (canonically inapplicable Skill) | No default XCOM 2 effect | None; None | Canonical Skill eligibility excludes this identity type. A local override cannot make the Skill purchasable or authorize transferring it from another identity. | Unmapped |
| `skill.independent-operator@1` | No approved mapping for this context in M5 | No configured mapping in this context (canonically inapplicable Skill) | No default XCOM 2 effect | None; None | Canonical Skill eligibility excludes this identity type. A local override cannot make the Skill purchasable or authorize transferring it from another identity. | Unmapped |
| `skill.quartermaster@1` | +15 starting Supplies | +15 Supplies once at explicit campaign/Journey association | +15 Supplies once at explicit campaign/Journey association | P0 (native mechanics via TNB); Once at first explicit campaign/Journey association, not necessarily campaign start | Keep the explicit +15 one-time association grant; do not convert it to a percentage or monthly award. | Keep |
| `skill.counterintelligence@1` | Remove 1 eligible Avatar Project progress pip | -1 eligible Avatar Project progress pip once at association; actual change can be zero | -1 eligible Avatar Project progress pip once at association; actual change can be zero | P0 (native mechanics via TNB); Once at first explicit campaign/Journey association, not necessarily campaign start | Keep the one-time eligible Avatar reduction, not a new recurring Avatar suppression mechanic. | Keep |
| `skill.scrounger@1` | 1 random common starting item | 1 random basic weapon upgrade or Medikit at monthly rollover, including zero-income months; visible item popup | 1 random basic weapon upgrade or Medikit at monthly rollover, including zero-income months; visible item popup | P0 (native mechanics via TNB); Once per monthly rollover after association; no missed-month backfill | Keep the later approved monthly-rollover reward and actual eight-item pool; do not restore a starting-only or first-collection trigger. | Keep |


### Commander frequency and implementation reconciliation

- **Resourceful +5% Supplies**, **Extravagant -5% Supplies**, **Inquisitive +10% Intel**,
  **Secretive -10% Intel**: change supported positive gains only. Mission, POI and
  covert resource rewards and supply-cache collection are allowlisted. Spending,
  refunds/conversions, debug grants, arbitrary loot/direct additions and unknown
  sources are not blanket-modified. Fractional resources truncate toward zero.
  These are not separate monthly grants or retroactive adjustments to inventory.
- **Engineering-Minded +1 Engineer**, **Scientifically Minded +1 Scientist**,
  **Quartermaster +15 Supplies**, **Overconfident +1 Avatar pip** and
  **Counterintelligence -1 eligible pip**: once at association. Avatar additions/
  reductions are limited to actual capacity/eligible global/facility progress.
  A zero eligible result is consumed once, not deferred until a convenient time.
- **Scrounger:** one common item at each monthly rollover independent of income or
  collection; no missed-month backfill. Current eight-template pool is the seven
  basic weapon upgrades `CritUpgrade_Bsc`, `AimUpgrade_Bsc`,
  `ClipSizeUpgrade_Bsc`, `FreeFireUpgrade_Bsc`, `ReloadUpgrade_Bsc`,
  `MissDamageUpgrade_Bsc`, `FreeKillUpgrade_Bsc`, plus `Medikit`.
  No default PCS, rare/advanced items or grenade entry is currently shipped.
- Active Commander traits/Skills are resolved and saved at association; soldier
  abilities come from the immutable Journey instance snapshot resolved at linking.
  Later canonical Skill purchases/acquired Traits/config edits do not refresh those
  saved effects. A future Journey/association can capture later characteristics.
  No new Commander progression system, research-speed subsystem or XP multiplier
  is proposed.
- A pre-link rewind may use current local mapping configuration for a new confirmed
  link, while reusing the original instance snapshot. A save already containing
  the link/association retains its frozen outcomes. Do not migrate old grants.

## 5. Deprecated-only catalog IDs

All rows below are archived catalog content, not current selection/purchase choices.
Proposed disposition is explicitly **No default XCOM 2 effect** in both contexts.
Earlier Brave/Mentor examples were illustrative, not approved numerical targets.
In particular, historical `trait.quartermaster` is not `skill.quartermaster`.

| Deprecated-only ID @ version | Name and definition | Character disposition | Commander disposition |
| --- | --- | --- | --- |
| `trait.brave@1` | Brave: Willing to face danger despite personal risk | No default XCOM 2 effect — Unmapped | No default XCOM 2 effect — Unmapped |
| `trait.loyal@1` | Loyal: Remains committed to allies and companions | No default XCOM 2 effect — Unmapped | No default XCOM 2 effect — Unmapped |
| `trait.quartermaster@1` | Quartermaster: Demonstrates effective stewardship of resources and supplies | No default XCOM 2 effect — Unmapped | No default XCOM 2 effect — Unmapped |
| `trait.cowardly@1` | Cowardly: Avoids danger even when action is warranted | No default XCOM 2 effect — Unmapped | No default XCOM 2 effect — Unmapped |
| `trait.selfish@1` | Selfish: Prioritizes personal interests at the expense of others | No default XCOM 2 effect — Unmapped | No default XCOM 2 effect — Unmapped |
| `trait.distrustful@1` | Distrustful: Tends to question others' intentions and struggles to place confidence in unfamiliar people. | No default XCOM 2 effect — Unmapped | No default XCOM 2 effect — Unmapped |
| `trait.mentor@1` | Mentor: Actively develops the abilities of others | No default XCOM 2 effect — Unmapped | No default XCOM 2 effect — Unmapped |
| `trait.innovative@1` | Innovative: Embraces experimentation, new ideas, and technological advancement | No default XCOM 2 effect — Unmapped | No default XCOM 2 effect — Unmapped |
| `trait.inspiring@1` | Inspiring: Motivates others to perform beyond their usual expectations | No default XCOM 2 effect — Unmapped | No default XCOM 2 effect — Unmapped |
| `trait.ruthless@1` | Ruthless: Willingly sacrifices others' welfare to achieve objectives | No default XCOM 2 effect — Unmapped | No default XCOM 2 effect — Unmapped |
| `trait.indecisive@1` | Indecisive: Struggles to make timely decisions when action is required | No default XCOM 2 effect — Unmapped | No default XCOM 2 effect — Unmapped |
| `trait.change-averse@1` | Change-Averse: Resists new approaches even when circumstances favor adaptation | No default XCOM 2 effect — Unmapped | No default XCOM 2 effect — Unmapped |
| `skill.provisional-fieldcraft@1` | Fieldcraft (Provisional): A provisional fixture for testing portable skill compatibility contracts. | No default XCOM 2 effect — Unmapped | No default XCOM 2 effect — Unmapped |


Published IDs also have deprecated older versions. Those are handled individually
in the version CSV, not omitted from the audit:

- Existing configured, reviewed version ranges remain as implemented.
- `trait.reckless@1` and `trait.resourceful@1` are **not** covered by the current
  soldier/Commander rows respectively; do not alias/upgrade them by name.
- Other preserved legacy snapshots keep their own classification/provenance and
  local frozen results. This proposal does not reinterpret any already committed
  link. Unknown future versions need review rather than a new wildcard range.
- The future player reference should show the current 29 IDs by default, with any
  legacy appendix clearly separated from available creation/purchase choices.

## 6. Provider/dependency proposal and limits

| Provider | Verified source / role | Recommendation |
| --- | --- | --- |
| P0: XCOM 2 + WOTC, with existing Highlander/MCM integration | Native stats, Combat Intelligence, Lightning Reflexes and strategic mechanics | Retain. Highlander baseline is 1.31.3. Highlander/MCM are infrastructure, not extra perk packs. |
| P1: [Modpocalypse Perk Pack, 2936550132](https://steamcommunity.com/sharedfiles/filedetails/?id=2936550132) | Installed source/English/icon container and Chamber Round defaults verified; user verified tactical use after expending ammo | Retain as optional/recommended full-mapping provider. No small new reload mod. |
| P2: [installed LWOTC experimental, 2663990965](https://steamcommunity.com/sharedfiles/filedetails/?id=2663990965) | Integrated perk library currently supplies four bare-name targets. Exact code/config/localization found locally. | Keep a documented **existing LWOTC profile**. Do not require players to install the full overhaul just for these perks. |
| P3: [[WOTC] LW2 Classes Perk Pack [FINAL], 1790938526](https://steamcommunity.com/sharedfiles/filedetails/?id=1790938526) | Creator documents a class-free library; actual package is not installed/source-verified here. | **Proposed** second pack for stock WOTC, after approval and verification. It has vanilla-ability changes/toggles; do not call it side-effect-free. Exact target IDs/effects remain a gate. |
| Rejected default: [[WOTC] LW2 Classes and Perks, 1335226018](https://steamcommunity.com/sharedfiles/filedetails/?id=1335226018) | Creator describes replacement classes and additional dependencies/mechanical changes | Do not recommend a class overhaul as a prerequisite merely to get four passive perks. |
| Additional packs | ABB standalone pack was considered, but no verified coverage gain justifies its extra asset dependencies; no third pack is needed now. | Do not add a collection of one-off mods or silently invent replacements. |

**Proposed profile, not a tested installation recipe:**

- Stock WOTC: P0 + P1 + P3, **two external perk packs total**, subject to the P3 gate.
- Existing LWOTC: P0 + P1 + its integrated P2 abilities; do not add P3 merely for
  duplicate functionality. The standalone creator warns against pairing it with
  the full LW2 class package; no blanket compatibility claim is made for overhauls.
- Four Skill target identifiers must be verified in P3. Do not assume its template
  spelling matches P2 or guess a `LW2WotC_...` prefix into shipped configuration.
  Effects/wording can differ (notably Grazing Fire weapon scope and Lone Wolf values).
- Until P3 is verified and approved, retain current P2 rows rather than claim a
  complete stock-WOTC six-Skill default. Without the relevant provider, those four
  mappings are **configured but unavailable**, not intentionally unmapped and not
  proof that the canonical Skill is unsupported everywhere.
- If the Product Owner declines P3 or its side effects cannot be acceptably disabled,
  the honest alternative is to keep conditional P2 support and explicitly state
  stock-WOTC limitations, or approve four stock-profile exclusions. Do not substitute
  superficially similar native/class-defining perks simply to claim full coverage.
- The resolver selects exact template targets; it has **no provider-aware fallback
  list**. Profile-specific organizer overrides preserve existing Keys and precedence.
  Two provider aliases under different Keys may both be granted; they are not a safe
  availability fallback. No automatic provider-selection engine is authorized here.

This keeps the two/three-pack ceiling while preserving the original six Skill
mechanics where a suitable verified provider exists. Approval is still needed for
the release's standard profile and provider-specific default differences.

## 7. Configuration, compatibility and deliberate-exclusion gaps

**Verified implementation:**

- Exact canonical ID + kind + Character/Commander context + immutable definition
  version drive resolution, not display names.
- Current mapped published versions all match their shipped ranges. Most mapped
  Traits accept v1–2; Reckless v2–3, Commander Resourceful v2–3; Skills v1.
- Keyed `Overrides` outrank shipped rows. Within those tiers, exact version outranks
  range; priority resolves other ties; equally ranked conflicts are skipped.
  Preserve override-only Keys, disabled player rows and current validation.
- Missing optional abilities are separately reported; restoring their exact frozen
  template can make them available. Already-owned abilities are not newly granted.
  Current matching does not silently retarget a saved historical `ChamberRound`
  mapping to `SingleReloadMrC`.
- Supported Character kinds are the whitelisted numeric stats, Ability and
  CombatIntelligence. Commander kinds are ResourcePercent (Supplies/Intel),
  ResourceOnce, StaffOnce, AvatarOnce and monthly SupplyDropItem.
- Detection radius, research/engineering duration, global squad trait auras,
  staff-XP multipliers and personal soldier resource upkeep are **not supported
  mapping kinds**. They are not simple INI values awaiting a number.

**Design gaps requiring a later approved implementation or documentation pass:**

1. No first-class distinction currently exists between a reviewed deliberate
   exclusion and an accidentally absent mapping. Both fall through to generic
   `unmapped` / “No configured mapping for this definition/version.”
   Do not misuse `bEnabled=false`: that would conflate a shipped exclusion with
   an organizer disabling a real effect.
2. Recommend retaining a small, version-pinned **review disposition** record for
   intentional exclusions (ID/kind/context/version/rationale), consulted only when
   no real mapping resolves. Organizer overrides must still be able to supply a
   mapping. This is a proposal for minimal local metadata, not a new canonical/API
   mapping system or a feature implemented by these audit CSVs.
3. `TNB_MappingResolver.Describe` still describes SupplyDropItem as first collection.
   `TNB_EffectPresentation`, actual reward code and approved current behavior use
   monthly rollover. Correct that stale generic/fallback wording in the later
   implementation; do not change the working reward timing.
4. Existing docs contain dated historical AP-row/permanence/collection instructions.
   The current approved source hierarchy above governs them. The final player
   guide must not suggest live Skill refresh, required AP spending, blanket income
   interception, replayed one-time grants or a compulsory full overhaul.
5. Freeze the approved public reference and dependency profiles to a release/config
   revision; detect new catalog IDs/versions by a later coverage check. Do not mark
   a new entry as an intentional exclusion merely because no row happens to exist.

No proposed exclusion changes canonical eligibility, Trait-point pricing or Skill
costs. An unmapped negative can still participate in the canonical creation economy;
an unmapped positive need not confer an XCOM bonus. Communicate this plainly rather
than trying to redesign the economy or optimize combinations within this assignment.

## 8. Decisions and catalog issues for Product Owner review

| Decision | Recommendation | Why approval is needed |
| --- | --- | --- |
| D1: Current mapped effects and timing | Retain the 25 configured effect directions/approved amounts, including mixed Commander one-time/ongoing and monthly Scrounger | Confirms the original intent plus later amendments are the default baseline; not a new balance sweep. |
| D2: Explicit cross-context and acquired exclusions | Approve all current Unmapped rows in the matrix, with canonical inapplicability kept distinct | All Traits are role-agnostic; silence is no longer an adequate context policy. These remain proposals until accepted. |
| D3: Stock-WOTC provider profile | Approve investigating P3 alongside Modpocalypse; preserve the P2 LWOTC profile | Four original Skills have no verified stock-WOTC provider in the current build. P3 identifiers, mechanics, toggle behavior and assets need verification before shipping. No dependency was installed. |
| D4: Missing-provider and exclusion UX | Keep “unavailable optional ability”, “No default XCOM 2 effect”, “disabled by organizer”, “unknown version” and “already present” distinct | Current code cannot encode every distinction. Minimal local disposition metadata is a later design/implementation approval, not silently added here. |
| D5: Public ability artwork | Inventory now; permission-cleared export/description rendering later, in a separate Portal assignment | In-game package availability does not establish browser redistribution permission. |
| D6: Canonical catalog copy | Refer the current Pioneer description and built-in attribution's retired internal branding to the catalog owner | This is a genuine public-copy mismatch, not an excuse to change gameplay definitions. Use approved future versioning; never mutate immutable published rows to fix an XCOM mapping. |

No conflicting canonical ID, changed Skill applicability or contradictory current
catalog publication was found. The important semantic change was **approved M5.1
role-agnostic Traits**, not a catalog bug. No global definition needs to be altered
to achieve this XCOM proposal.

## 9. Future player reference and validation handoff

See [icon/description inventory](TRAIT_SKILL_MAPPING_ASSET_INVENTORY.md) for exact
ability locations and public-reference constraints. The page must say **Default
XCOM 2 configuration**, show both identity contexts, use actual selected-provider
ability art/name and accurate rendered mechanics, and show **No default XCOM 2
effect** for accepted exclusions. It must not require readers to understand
template IDs, perk-pack names or INI syntax. Organizer-facing README/Workshop docs
carry dependencies, profile choice, supported versions, fallback and override details.

The static alpha Portal page is separately approved work; no new artwork API or
dynamic developer-managed mapping service is required by this audit. The current
canonical SVG library can identify a source Trait/Skill but is not a substitute
misrepresented as an actual XCOM ability icon.

### Checks performed

- Read the original approved M5 matrix before recommendations; compared accepted
  M5.1, later commander/timing/provider and automatic-grant decisions with code/INI.
- Matched the canonical definitions file to current GitHub main's blob.
- Classified all 29 published IDs in both contexts and all 13 deprecated-only IDs.
- Checked all 64 definition versions in both contexts (128 version/context pairs).
- Matched all 25 shipped rows to known, currently published IDs with correct kind,
  context and current reviewed version; checked exact range/key/target metadata.
- Verified current core/P1/P2 template definitions, English wording locations, config
  values and icon URIs through installed authoritative source. P3 is explicitly
  unverified; its linked sheet could not be accessed. Other mods' configs are not
  promoted to template-source proof.
- Source catalog and runtime configuration/code were not edited; no game build,
  event submission, account operation, asset export, mod subscription or deployment
  was run for this design review. No in-game acceptance is implied by static checks.

**Stop for Product Owner review.** Only after approval should the provider source
gate, local exclusion representation, profile configuration, reference artwork
permissions, small stale-copy fixes and gameplay acceptance be scheduled.

