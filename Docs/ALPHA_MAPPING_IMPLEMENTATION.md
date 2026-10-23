# Alpha mapping implementation checkpoint

Branch: `feature/alpha-trait-skill-mappings`, created from XCOM `origin/main`
`d2441003a0d37648992cf0eb8e63f3eed6c4faec` on 2026-10-22.
Authority: approval addenda in [the mapping audit](TRAIT_SKILL_MAPPING_AUDIT.md),
not its superseded original tables/CSV proposals or the old gameplay defaults.
Mapping revision: `tnb-alpha-2026-10-22-r5`.

**Implementation and offline verification complete; native gameplay acceptance pending.**
48 default rows cover all 48 applicable mapping pairs (26 Character, 22 Commander).
Commander Battle-Scarred remains N/A for its
approved acquisition-path reason. No catalog/backend/Production changes, new
dependency installation, save migration, retail install, release or merge.

## Implemented groups

| Group | Changes |
| --- | --- |
| Soldier stats/abilities | Reckless -5 Dodge; Overconfident -10 Defense; Engineering-Minded +10 Hacking; Pioneer +5 Will; exact `FullKit`, `F_QuickPatch`, `MZUnshakableWill`, `ShadowOps_AbsolutelyCritical` targets. Other retained stats/intelligence and six Skills unchanged. |
| Character detection | Conspicuous +20% baseline enemy detection distance at tactical initialization. Freeze the initial per-mission stat delta; later stealth effects stack natively and can change the relative percentage. Saved guards prevent duplicate application on reload; fresh launch/transfer preparation reverses only our old delta. |
| Covert risks | Observant -5 pp ambush; Unperceptive +5 pp ambush; Reckless +5 pp wound; Unlucky +5 pp capture. Native eligible risk queries/cache refresh, protections and final chance limits; no absent risks created. |
| Recovery | Commander Strong-Willed -10% fatigue duration, Poor Stamina +10%, Hardy -10% wound duration; Character Secretive +20% personal wound duration. Add durations, then convert to reciprocal work rate. No tactical damage change. |
| One-time association | Pioneer +1 contact capacity; Quick Learner two distinct random eligible barracks soldiers +1 Combat Intelligence tier, with saved names/before/after receipts, Savant cap, no retroactive AP/backfill; Tactician native 0.90 covert duration multiplier once. Existing staff/resource/Avatar grants retained. |
| Research | Analytical +10% Science Score for progress queries; zero score and ordinary prerequisite queries unchanged. Native scope includes Shadow Chamber, excludes Proving Ground and science-independent breakthroughs. |
| Recruitment | Commander Conspicuous +25% Supplies cost for standard Recruit Soldiers purchases. Freeze/register the native scalar factor once at association; preserve Midnight Raids activation/expiry callbacks. Normal discounts and native rounding remain. |
| Participant rewards | Inquisitive +10% Intel and Extravagant -10% Supplies per participating linked soldier. Retained launch/assignment roster and launch-linked instance membership, not barracks/current HQ squad. Add eligible Commander percentages against original positive reward; no compounding or inventory charge. |
| Reward display | Actual base/adjustment/source receipts saved with resource changes. Preserve original reward text/preview delegates; display never grants/recalculates. Cache/monthly/Scrounger paths unchanged. |

Implementation follow-up decisions approved by the Product Owner:

- Secretive +20% and Commander Hardy -10% **add to +10% wound duration**, not
  multiplicative +8%. Opposing Commander fatigue durations cancel.
- Analytical follows the native research scope above.
- Character Conspicuous uses the initialization penalty with native later-stealth
  stacking; a constant 20% multiplier after other effects is not required for alpha.
- Commander Conspicuous uses native recruitment pricing with preserved Midnight
  Raids callbacks; arbitrary third-party scalar overwrites are outside the guarantee.

Query callbacks never create/submit history states. Refreshes/grants use the
existing association/link transaction. A temporary science listener supplies the
pending frozen modifier only during synchronous first-association project refresh,
then unregisters before commit; no timer, actor or persistent singleton is added.

## Character Conspicuous: accepted alpha stacking contract

The approved initialization conversion is:
`Mnew = 1 - 1.20 * (1 - Mcurrent)`. But baking that delta into the base stat does
not preserve the ratio after later stealth-stat changes. Example: M=0 becomes
-0.20; a later +0.50 stealth modifier makes M=0.30. Detection is then 0.70 instead
of 0.50: **40% farther, not 20%**. The Product Owner accepted that native stacking
behavior. With a five-tile native radius, both examples add one tile; a ten-tile
radius instead adds two at initialization. Do not promise a fixed tile penalty.

The personal adapter is enabled for future frozen links containing the Trait.
It uses only native pending launch/transfer/begin-tactical transactions; no timer,
extra history submission, custom ability, Big Stompy Boots or ally bonus. Unit
markers survive tactical BeginTactical cleanup; a fresh launch/transfer reverses
only our previous delta before native initialization. Existing frozen links stay
unchanged. Reinforcement/transfer/stealth UI behavior remains a gameplay gate.

## Commander Conspicuous: approved native pricing adapter

Native `XComGameState_HeadquartersResistance.GetRecruitSupplyCost` supplies UI and
payment. On future explicit association, multiply the current `RecruitScalar` by
1.25 once and save its frozen registration/expected-scalar receipt. Existing links
return before resolution; no load-time application, migration or live refresh.
Native pricing is `Round((difficulty base + RecruitCostModifier) * RecruitScalar)`:
discounts stay in the base price, a free recruit stays free, and UI, affordability
and payment all use the same getter. Reward recruits are not affected.

Midnight Raids assigns an absolute scalar on activation and resets it on expiry.
The template adapter preserves both existing delegates and their arguments. Within
their supplied pending state, temporarily remove our known factor, run the original
callback, and reapply once to its result. Repeated activations/expiry and a known
multiplicative callback do not compound the factor. A shared nesting guard reconciles
only the outer call. Registration fails atomically if either wrapper is unavailable.
No timer, extra history submission, class override, hidden surcharge, changed
delivery time or candidate count is introduced. Read-only screens do not reapply it.

Native To Serve Mankind/Recruiting Centers change `RecruitCostModifier`, not the
scalar. Source inspection of the installed LWOTC recruitment screens found they
inherit the native price/payment path; this is not gameplay compatibility proof.
Mods replacing those callbacks afterward, directly rewriting the scalar elsewhere,
or implementing another recruitment system can bypass this adapter. An unexpected
scalar is logged and not blindly divided into guessed components; only the known
native reset path can reliably re-establish composition. No timer attempts repairs.
The public `1.0.0-alpha.1` reference package/catalog remain unchanged.

## Compatibility and verification

- Existing committed links return before resolution/grants and keep old frozen
  effects. Future captured snapshots/new links apply new mappings. No live refresh.
- Legacy `reckless_defense` Key is retained for override compatibility; new default
  target is Dodge. Existing player overrides still win. Host-game rules determine
  negative Dodge behavior; no invented floor or conversion.
- Exact missing optional abilities remain unavailable without substitutes. Full
  Kit and four retained Skills use the verified installed LWOTC provider; this
  does not qualify a stock-WOTC dependency profile or recommend an overhaul.
- Research staffing compatibility needs testing: native
  `UIChooseFacility.HasEnoughStaffing` also calls `GetScienceScore(true)` for mod-
  supplied staffing requirements, which the hook cannot distinguish from progress.
  No staff are created; ordinary `false` prerequisite queries are unchanged.

Offline runner (does **not** deploy to retail):

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\.scripts\Test-ModMappings.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\.scripts\Test-ModMappings.ps1 -All
```

Requires the already-prepared Highlander SDK base packages. SDK commandlets do
not run the game's DLC INI merge. The runner mechanically generates an SDK-only
non-config fixture from the exact source rows, exercises the production resolver,
then removes that fixture source. No player INI, credential, save or journal is
read/rewritten. **Source-row resolution is not retail INI merge acceptance.**
Never install the test-staged package as a release artifact.

After incremental groups, final SDK compilation completed with **zero errors and
warnings**, and all **eleven** offline probes passed: mapping, attempt/promotion,
Avenger invitation, bond, captivity, monthly rewards, covert, event, gameplay fixes,
presentation and recruitment. Ignored logs: `Artifacts/Mod/*ProbeCommandlet.log`.
Mapping checks cover signs/targets, specialization stacking, exact new ability IDs,
future-version rejection, active-only aggregation, opposing risks, reciprocal and
combined duration math, recipient uniqueness/cap, research query scope, retained
roster/latest attempt, barracks/late-link/wrong-Journey/POI exclusions, additive
two-soldier/Commander rewards, zero floor, actual receipt text/escaping and the
accepted Conspicuous stacking, pure application guard and own-delta reversal
arithmetic. Standalone editor commandlets lack a campaign history needed by native
soldier stat operations; those operations, saved markers and actual tactical
reload/transfer ordering must be tested in game, not claimed by offline probes.
Recruitment checks exercise production field helpers for once-only registration,
active-only additive percentages/cancellation, ordinary/discounted/free price
arithmetic, repeated Midnight Raids resets, association during an active scalar,
multiplicative callback composition, external-overwrite handling and old-link/
missing-state guards. They also test actual delegate installation/idempotence,
replacement detection, preserved arguments, nesting and ongoing penalty display.
Price arithmetic models the inspected native getter; no real HQ purchase, saved
history transaction or save/reload was exercised by these commandlets.
No live API events were submitted.

These are synthetic/source-policy checks, not proof of native association/save
transactions, RNG selection, project timing, provider mechanics or UI layout.

## Native acceptance gate: not yet run

Use fresh Journeys/updated snapshots and separate pre-association saves; preserve
old linked saves to confirm their old effects stay unchanged.

1. Existing/new/negated covert risks, opposing modifiers and displayed chances;
   Tactician active remaining time, unstarted/new actions, orders and bond bonuses.
2. Fatigue/wound times for each sign, cancellation and Hardy/Secretive +10% net;
   infirmary/mod bonuses, current-project refresh and unchanged tactical damage.
3. Contacts once; Quick Learner zero/one/two eligible recipients, saved names/tiers,
   no AP backfill, cap/stacking, reopening and post-association reload.
4. Ordinary/Shadow research speed, prerequisites/laboratory staffing; unchanged
   Proving Ground and science-independent breakthroughs.
5. Two linked soldiers in tactical/covert activities with Intel/Supplies rewards:
   actual balances/receipts, Commander stacking, small rewards and penalties;
   nonparticipants, scans and monthly drops must not gain Character modifiers.
   Exercise reward timing, retries/reloads and supported reward-mod delegates.
6. Each perk's real tactical costs/charges/eligibility, squad-wide ownership,
   absent/restored optional providers, no duplicate grants and safe transitions.
7. Monthly/Scrounger, invitation dismiss/link flow, Armory status/details,
   reporting, two-character attribution and saved-game compatibility regressions.
8. Character Conspicuous on two linked soldiers, fresh missions, tactical save
   reloads and direct transfers: no accumulated penalty; own/ally sight unchanged.
   Compare warnings and reveals, initial versus later stealth effects, and any
   relevant delayed/reinforcement soldiers. Accept native stacking, not exact 20%
   after all effects. No native lifecycle acceptance has been claimed by probes.
9. Commander Conspicuous: displayed Recruit Soldiers cost, disabled/unaffordable
   selection and actual Supplies charged; native discounts and free recruits;
   association with Midnight Raids already active, subsequent activation, repeated
   activation/reactivation and expiry. Reload/reopen must not multiply again;
   reward recruits, candidate count and delivery remain unchanged. Include other
   installed recruitment mods and report unsupported direct scalar overrides.

Native acceptance remains required before merge/publishing. Automated success
does not authorize a retail install, automatic merge or release.
