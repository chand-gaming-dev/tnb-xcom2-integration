# Deja Vu - local linking passive

Feature branch: `feature/deja-vu-linking-perk`. Native acceptance is required
before merge/release. No backend, catalog or companion changes are required.

## Player behavior

New soldier links automatically grant **Deja Vu** by default:
"You can't quite shake the feeling you've been here before."

The passive banks 5% additional XCOM promotion credit from new personal kills,
native kill-assist promotion credits and ordinary covert-action XP. Fractions
accumulate until a whole bonus promotion credit is available. It does not change
actual kill statistics, Ability Points, Combat Intelligence, online XP, or rank
limits. Guaranteed rank-up rewards are not multiplied. It is not a canonical
trait/skill or an effect in the immutable snapshot mapping table.

MCM -> The Name Beneath -> Linking bonuses:

- Automatic grant: affects **future links** only. No retroactive grants to existing
  linked saves and no removal from already granted soldiers.
- Promotion XP percentage: 0-100, default 5. A new rate applies to subsequent
  earnings only. Zero stops accrual without removing earned bonus credit.

The perk and progress need no companion/network connection after linking.

The character picker lists only roster identities. The final link confirmation
mentions the bonus when automatic granting is enabled; the completed-link Traits
& Abilities result then displays the grant, configured percentage and icon card.
Its saved grant receipt drives this presentation immediately, without waiting for
a native ability query refresh. A cancelled/incomplete link has no grant result.

## External mod use

Ability template: `TNB_DejaVu`; provider: The Name Beneath. Explicit grants through
normal class progression, purchased soldier/AWC perks or character/item abilities
are recognized by `HasAbilityFromAnySource`. A Journey association is not required
for externally granted holders. The ability is not automatically eligible for
random AWC rolls. External mods should declare TNB as a dependency.

No initialization call is required: the award listener recognizes the holder at
the next qualifying award. No lifetime XP is retrospectively multiplied. Multiple
grants do not multiply the bonus. Unsupported custom XP paths that bypass native
Highlander hooks are not promised automatic coverage.

## Implementation and compatibility

- `X2Ability_TNBDejaVu`: passive template and icon.
- `TNB_DejaVuConfig`: MCM/INI preferences, separate from frozen mapping config.
- `TNB_DejaVuService`: split fixed-point bank in persistent soldier UnitValues
  (`TNB_DV_Whole` and `TNB_DV_Remainder`, precision one millionth of a credit).
  Existing native mission transfer/save machinery carries soldier UnitValues.
- `X2EventListener_TNBDejaVu`: observes final `OverrideKillXp` awards at priority
  0, without mutating shared kill/assist amounts. Assists are converted with the
  class's native rounded-assists/integer-division formula before awarding a bonus.
  `OverrideTotalNumKills` adds earned whole credit at priority 50 and is read-only.
- Covert callbacks consume positive changes to `NonTacticalKills` once per action.
  For a native `Reward_RankUp`, `UnitRankUp` observes ordinary XP before the native
  reward resets the counter to its rank threshold; completion cannot award twice.
- No polling, timers, new background workers, or nested history submissions. Bank
  changes occur only in the native caller's mutable award transaction; linking
  sets its grant marker in the existing atomic link transaction. MCM only saves
  local config. Existing linked snapshots and event identities are untouched.
- Covert Infiltration's priority-99 scaling and Requiem's priority-40 kill gates
  run before accrual. Requiem's priority-40 total-XP gate runs after our credit
  query, retaining its progression restrictions.
- Soldier Info Redux and Detailed Soldier Lists Redux call the same total-XP
  hook. Their custom full-number displays still require native acceptance.
- Full-XP-system overhauls (`bUseFullXpSystem=true`) are not supported: the
  listener declines to award/query bonus credit rather than changing their rules.
- Direct rank grants, console progression resets and custom PSI-credit awards
  are not additional Deja Vu XP sources. Existing earned bank is not rewritten
  by respecs or percentage changes.

## Artwork

The owner supplied the original SVG/green PNG under `Assets/DejaVu`. A white
SVG with identical geometry is rendered by `.scripts/Build-DejaVuIcon.mjs` to
PNG/TGA. `TheNameBeneath/Content/UILibrary_TNB.upk` contains only the imported
`Texture2D UILibrary_TNB.TNB_DejaVu` (512x512). It is an authored UI asset, not
an SDK dump. The template uses `img:///UILibrary_TNB.TNB_DejaVu`.

Reproduce the texture: render with the existing sharp dependency, import the TGA
in the WOTC editor as package `UILibrary_TNB`, texture `TNB_DejaVu`, preserve
alpha, no material creation, then save only this new package to the mod Content
folder. Never save modified SDK/base-game packages.

## Native acceptance checklist

1. On a pre-link save, check MCM defaults (automatic enabled, 5%). Link one soldier;
   inspect the local bonus card/icon and link report. Reload: no second grant.
2. Link a second soldier with automatic grant disabled. They receive normal mapped
   effects but not Deja Vu. Re-enable it: the earlier soldier is not backfilled.
3. Deploy a holder and non-holder. Check direct kills, assist conversion and class
   thresholds; only the holder banks bonus credit. At 5%, twenty ordinary promotion
   credits produce one bonus credit. Display and actual promotion eligibility agree.
4. Change percentage; only later earnings use it. At zero, previously earned credit
   remains. Save/reload before/after combat, including tactical/strategy transfer.
5. Complete ordinary and guaranteed-promotion covert actions. Ordinary XP earns
   its bonus once; the guaranteed rank threshold top-up does not. Exercise failure,
   ambush completion, multiple staffed soldiers and a non-holder.
6. Check an external class/AWC grant without a Journey. Repeated grants do not stack.
7. With CI/Requiem options active, check reduced/zero kill awards and promotion caps.
   Confirm actual kill counts and TNB reporting/online XP remain unchanged.

Offline commandlet tests are not a substitute for these checks.

## Automated verification / local test install (2026-10-23)

- All 12 offline SDK probes passed; compilation reported zero errors/warnings.
- The expanded Deja Vu probe exercises fractional and rate-change arithmetic,
  zero/negative awards, native assist conversion, personal UnitValue banking,
  non-stacking grant injection, repeat read-only queries, template metadata,
  fractional display, and native loading of the 512x512 texture asset.
- A clean build without the generated mapping fixture passed the focused Deja Vu
  and presentation probes. The mapping commandlet returned its expected missing-
  fixture result, confirming that test defaults are absent from the gameplay build.
- Local installed script SHA-256:
  `AB3A14DC4AB9741A467B132796EEDDBE47E98C42375EAF723F32FE7D77378AE3`.
- The script, authored icon and native localization were installed for acceptance.
  The original installed script/config/localization were backed up under ignored
  `Artifacts/InstallBackups/DejaVu-20261023`. All 48 shipped mapping rows and five
  local streamer-profile override rows were compared unchanged. Saves, pools,
  credentials, companion and AML profile were not modified.

These results do not exercise a native mission/covert-action lifecycle, tactical
save serialization, MCM save/restart behavior, or third-party XP UI rendering.
Those remain the acceptance gate above. No merge, publication or release.
