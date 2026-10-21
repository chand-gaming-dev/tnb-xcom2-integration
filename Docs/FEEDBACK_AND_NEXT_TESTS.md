# Feedback and next tests

## Before official release

- Publish the tested, self-contained Windows x64 `TheNameBeneathCompanion.exe`
  as a GitHub Release asset and link it from the README and player setup guide.
  Players must not need to build from source. Keep binaries out of source commits.
  See [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md). This is a pending release
  requirement, not authorization to publish a release before acceptance/approval.

## Current test build: mod 0.9.0 / companion 0.10.2

- Public naming cleanup: project/executable TheNameBeneathCompanion, namespace
  TheNameBeneath.Companion, JourneyApi client and official branding throughout
  documentation. Persisted/API compatibility identifiers stay unchanged. No mod
  script, mapping, event payload, grant or saved-game migration changes.

- Header clipping follow-up: automatic stacked title/subtitle layout and wrapping;
  original favicon restored beside the title. Verify at the player's desktop scale.
  No XCOM/gameplay update; companion only. UI/regression tests pass.

- Capture/freedom and bond representation integration is implemented. Native/Portal
  gameplay acceptance remains open, especially two linked soldiers and a rescued
  objective soldier who must not count as deployed. Existing milestones/queues are
  unchanged. Relationship broken is not inferred without verified ending evidence.
- Ability-status cleanup is implemented: current provider availability drives the
  main card/detail label and color; historical results/notes stay in Mapping details.
- Companion UX cleanup: separate Journey, Gameplay reporting and Character Pools
  tabs, readable sections/counts and persistent feedback. Requested XCom 2 title.
- Next acceptance sequence: CAPTIVITY_RELATIONSHIPS_UX_TESTING.md. Full mapping
  catalog audit, remaining injury/condition/economy tests and release work remain open.

- Character Pools tab downloads the current credential-pinned Journey ZIP and
  offers original ZIP or independent standard/Appearance Manager pool merge saves. Preserve raw
  character data, skip byte-identical duplicates only, no automatic import or
  existing-file overwrite. Live download/XCOM import remain acceptance work.
- Merged Save As suggests `TNB-<journey name>.bin` (Windows-safe, length-bounded;
  fallback to short ID when no usable title). Player still selects folder/name.
- ExtraDatas merging now preserves alternate armor appearances/loadouts and their
  snapshot-based soldier associations. No installed-mod checks. Four local sample
  pools, including Marbs Chand.bin, round-trip 247 character records. Conflicting
  metadata, unmatched snapshots and genuinely unknown layouts remain explicitly
  ZIP-only, never silently stripped. Verify native XCOM import/armor looks manually;
  no active/original pool files were changed. See CHARACTER_POOL_DOWNLOAD_TESTING.md.
- Soldier card current-availability label cleanup is implemented; verify in game. Installing
  Modpocalypse resolved saved SingleReloadMrC without relinking; screenshots
  20261020193929_1.jpg and 20261020193933_1.jpg show Chamber Round in tactical list
  and action bar after ammo was spent. Hide-until-usable is native perk behavior,
  not a missing grant. This was not a completed mission/capture/rescue test.

- Scrounger popup uses in-character discovery text with the actual item name:
  "While rummaging around the Avenger, you uncover a forgotten Laser Sight.
  It has been added to your inventory." No supply-income/collection explanation.
  Text only; native item image, stacking, queue, monthly timing/guard and saved
  rewards are unchanged. See SCROUNGER_COPY_TESTING.md.
- Retail 0.8.6 failed Combat Preparedness reached the portal with failure and
  covert-action description. Successful actions also passed. Adding all eight
  configured items before the monthly award confirmed native stacking. On 0.8.7,
  user also obtained a natural duplicate: existing quantity 1 increased correctly.
  Scrounger stacking is accepted and CLOSED; no further targeted test is needed.
- Final wording decision: KEEP generic portal Mission succeeded/failed headings
  across games. Only XCOM-supplied summaries distinguish covert actions. Remove the
  API/contracts/portal title follow-up; no change in those repositories is needed.

## Pre-closeout review: complete Trait/Skill mapping catalog (OPEN)

Added by user on 2026-10-21. Review the full current canonical The Name Beneath Trait and
Skill catalog, not just definitions used by the alpha test roster. Each definition
must have an explicit reviewed disposition in each applicable soldier/commander
context: a default XCOM mapping, or intentional exclusion with a clear rationale.
Unreviewed/missing mappings must remain distinguishable from deliberate exclusions.

- Build a coverage matrix keyed by canonical definition ID, reviewed version/range,
  Trait/Skill kind and context. Include positive and negative definitions.
- For mappings, review effect, magnitude/sign, timing, stacking and balance; identify
  core/Highlander versus optional-mod requirements and exact ability templates.
  Optional providers need Workshop links/provenance comments, per existing policy.
- For exclusions, explain why there is no default XCOM effect (for example no
  suitable supported mechanic or an unsuitable game/context). Do not silently
  imply that the definition has been implemented, or treat a missing provider as
  an intentional catalog exclusion.
- Preserve configurable player overrides and the distinction between an intentional
  shipped exclusion and a player's disabled mapping. Review how those dispositions
  are represented in config and surfaced in the link/profile UX.
- Reconcile coverage against an identified catalog revision so newly added or
  changed definitions can be detected and reviewed instead of silently omitted.
- User review/approval is needed before changing default mappings or balance.
  This entry records the audit requirement only; no catalog or mappings changed.

## Character capture and rescue: implementation complete; gameplay acceptance OPEN

2026-10-21: new backend contracts are integrated in mod 0.9.0 / companion 0.10.0.
Historical review requirements below are superseded where they described absent
implementation. Actual capture/freedom, repeat/offline/reload, multi-character and
native transfer behaviour must still be verified. No claim of retail acceptance.

User requested review before mod closeout on 2026-10-20. Capture and later rescue
are important enough to appear as separate, visible experiences for the affected
linked character in the portal, not merely buried in mission metadata. This is
backlog/design review only; no implementation or event representation approved yet.

- Current coverage: completion metadata lists captured squad soldiers' XCOM IDs;
  there is no standalone capture/rescue transition. A rescue mission's ordinary
  result is not a separate experience for its rescued character.
- Review dedicated standard event types versus an appropriate existing event
  representation, portal wording, companion validation and XP policy explicitly.
  Do not label captivity as injury/death or promise XP implicitly.
- Preserve the original soldier/The Name Beneath instance and link across capture and
  return; do not relink, reactivate or reapply traits/stats as part of rescue.
- Use verified native capture and confirmed return facts, not mission title or
  success alone. Cover left-behind/Chosen/covert capture paths where feasible;
  do not count a rescued prisoner as deployed with the rescuing squad.
- Plan repeated capture episodes, reload/retry dedup, failed rescue and unknown
  state/history-gap behavior without changing earlier accepted events.
- User stopped the current tactical test to move to The Name Beneath work; mission was
  NOT completed. Do not claim capture/rescue acceptance or require finishing it now.

### Prior 0.8.6 notes

- Focused retail reload/no-duplicate, successful covert completion and offline
  capture/reconnect checks passed on 0.8.5. Steam and companion records match.
- 0.8.6 fixes future Scrounger grants bypassing native inventory stacking and
  handles explicit LWOTC failed-action risk results. Unknown reward overrides
  remain held. No existing stacks/reports are migrated. See
  COVERT_AND_INVENTORY_TESTING.md for targeted retail acceptance.
- New mod summaries distinguish covert actions. Proposed portal heading changes
  were subsequently declined; retain generic cross-game headings (decision above).
- Research-bay warning screenshot is a future invitation UX reference. Automatic
  campaign-Journey prompt remains disabled; no load-time prompt restoration here.

### Prior 0.8.5 notes

- 0.8.4 retail screenshots confirm readable supply receipt and clear monthly item
  popup, but native item markup displayed literally and the collection flyover
  retained the base amount. 0.8.5 normalizes item names and updates only the pending
  display amount to match the actual positive/negative gain. Recovery/loss flavor
  is added alongside the exact breakdown. The large month-end screen is left alone.
  Follow SUPPLY_DISPLAY_TESTING.md for current acceptance.
- Covert-action-specific portal titles are a separate follow-up; standard event
  types, XP and already accepted records must remain intact.
- The first Armory/Research/Engineering delay is now not reproducible in new
  saves/builds. Treat as unconfirmed cause, not a proven performance fix.

### Prior 0.8.4 notes

- Monthly Scrounger now awards independently of supply income and uses a native
  dismissible item popup. Existing per-month guard and saved rewards are retained.
- Supply collection adds a saved receipt to the existing completion/instant popup:
  base, actual rounded modifier and total. Test zero/positive income, duplicate
  prevention, popup ordering/layout and inventory counts using
  COMMANDER_MONTHLY_REWARDS_TESTING.md.
- Retail 0.8.3 mission success, portal promotion and distinct re-launch attempt
  were confirmed. Low Profile remained present. Injury/recovery, covert actions,
  negative conditions and bonds remain gameplay acceptance work.
- Separate performance feedback: first Research/Engineering entry after loading
  some linked saves delayed about ten seconds while UI remained responsive and
  navigation clicks queued. A newer post-mission save did not reproduce it. No
  proven cause and no speculative performance change in this build.
- Automatic Journey-link reminders remain disabled; optional final-review work.
- Replit development-token lifetime is a development-only limitation, explicitly
  out of scope for release-specific UX.

Older build notes below are historical where superseded.

**Current addition: mod/companion 0.8.0 bond milestones.** Initial formation and
completed level increases use `threadline.narrative.milestone_reached` with pair,
native level and linked-instance details. No canonical relationship mutation.
See [BOND_MILESTONES_TESTING.md](BOND_MILESTONES_TESTING.md) for native coverage,
console caveats and acceptance tests. Existing UI fixes and mission tests remain.

## Bond representation: implemented; native gameplay acceptance OPEN

New formations/upgrades now use relationship.formed/developed. Historical milestones
and durable outboxes remain unchanged. No canonical relationship mutation; new facts
award zero XP. Verify actual native confirmation/training completion and shared
one/two-linked participant projection. A broken relationship is not inferred from
missing data or death. See CAPTIVITY_RELATIONSHIPS_UX_TESTING.md.

**Current follow-up: mod UI patch 0.7.1 / companion 0.7.0 unchanged.** Soldier
details are condensed, saved commander effects have matching icon cards, and rainbow
fallback textures are replaced. The three October 19 screenshots establish initial
UI/title refresh evidence, not mission delivery. Follow
[COMMANDER_UX_AND_MISSION_SMOKE_TEST.md](COMMANDER_UX_AND_MISSION_SMOKE_TEST.md).
Older UI recommendations below are historical where superseded.

Current build is **0.7.0**: Journey names and the graphical soldier profile are
implemented. Use [JOURNEY_AND_SOLDIER_UX_TESTING.md](JOURNEY_AND_SOLDIER_UX_TESTING.md)
for UI/reload checks, then continue gameplay-reporting acceptance. Automatic Avenger
prompts remain disabled. The zero-counter reporting screenshot confirms the status
screen/clock handshake, not actual online mission acceptance. The older feedback,
confirmed user results and deferred items below are historical where superseded.

## Historical feedback build 0.5.1 - 2026-10-19

User approved combining the local UI/diagnostic fixes in one build to reduce XCOM startup cycles. This is not an isolated one-change experiment. The API-backed Journey-name display is explicitly deferred. There are no API/portal changes, live transitions, balance edits, new dependencies or save-schema changes in this batch.

**Subsequent approved INI correction (2026-10-19, before the next game launch):** Weapon Handling now targets `SingleReloadMrC` (Chamber Round), from optional Modpocalypse Perk Pack, Workshop 2936550132. Mapping revision is `tnb-alpha-2026-10-19-r2`; adjacent source/provenance comments are included. No mod is installed and other mappings/reward logic are unchanged. New links use the corrected name; old linked saves retain `ChamberRound` and must not be migrated/regranted. Until the optional pack is installed, the new target also reports unavailable safely. Current ability provenance, including the Long War provider for the exact `LowProfile` template, is documented in MAPPING_CUSTOMIZATION.md.

## Included

- Disable the automatic Avenger invitation completely: the screen listener owns no prompt/world references and never spawns the prompt actor. The strategy-load callback no longer discovers/resets prompts. MCM setup no longer touches prompts. Retain the dormant classes and saved opt-out records for compatibility; do not delete or rewrite saves. Remove the irrelevant MCM reminder checkbox and explain the MCM-only diagnostic mode.
- MCM has a permanent **View Commander & Bonuses** action for a connected campaign, or **Connect Campaign Journey** when unconnected. The action's right-side button is **Open**. Refresh/reopen MCM after linking to update the summary. Main-menu/tactical setup stays disabled.
- Commander rows show readable signed effects with explicit one-time/ongoing behavior, actual committed deltas, skipped/no-eligible changes, and frozen saved mappings. The report opens offline and never resolves mappings or regrants rewards.
- The linked Armory entry becomes **The Name Beneath - Traits & Abilities**. Improve the existing read-only report rather than add a class-tree row or an Officer-mod dependency. Show friendly stats and ability names, installed ability descriptions/icons, source Trait/Skill, immutable link-time result and current missing-template availability. Already-owned abilities are distinct from newly supplied mappings. No template fallback grants or stat changes occur while viewing.
- Correct companion closing guidance, contradictory Journey-start text, mislabelled game-name-as-Journey text, and remaining player-facing internal-codename wording in these screens. Technical binary/API/vault identifiers remain unchanged. Journey ID is retained; no Journey title is invented.

## User-confirmed on previous 0.5.0 build

- Explicit Upcoming Journey start/connection and already-Started reconnection worked.
- Commander gained +1 Engineer and additional Supplies; exact Supplies arithmetic was not independently captured.
- Character stat changes persisted in a post-link save loaded after a fresh game launch.
- Pre-link comparison confirmed Low Profile absent before linking, present afterward, and present after reload: Cover Discipline positive injection/persistence test passed in the Armory. Tactical behavior is still a separate check.
- Weapon Handling's old ChamberRound target was absent and skipped visibly without blocking the remaining link. This confirmed safe missing-template handling. Its name was subsequently corrected with explicit user approval to SingleReloadMrC; see the amendment above. User will install the optional provider later.
- Loading a second strategy save within a session repeatedly crashed, including pre-link -> pre-link. Post-link save loaded on a fresh process. Latest inspected crash logs show the Avenger world failing garbage-collection cleanup. No reference chain yet proves the exact responsible mod/object. Automatic prompt lifetime/timing is a hypothesis, not a confirmed cause.

## One-pass manual acceptance

1. Close XCOM and companion before installing. Use separate, non-Ironman pre-link and post-link slots. Do not overwrite the only campaign copy or delete recovery receipts.
2. Start companion 0.5.1 normally. Existing credential is retained. Confirm footer says XCOM continues running when companion closes.
3. Fresh launch -> pre-link save. Wait at the Avenger: **no automatic linking popup**. Reload this same save without using MCM. Repeat at least once. Record whether it still crashes and the time.
4. Fresh launch -> existing post-link save. Confirm saved bonuses/Low Profile; reload it, then load the pre-link save. A crash-free sequence implicates the removed automatic prompt path but does not prove dialog timing rather than actor lifetime. A repeat crash means further lifetime isolation is needed; no save repair should be guessed.
5. In a connected save, MCM > The Name Beneath > Campaign Journey > **View Commander & Bonuses / Open**. Verify commander, +1 Engineer/+15 Supplies one-time results, +5% Supplies ongoing, and Scrounger monthly first-collection behavior are clear. Repeated viewing must not add rewards.
6. Close companion; reopen MCM's saved commander report and Armory's **Traits & Abilities** report. Both remain readable; connection status can honestly report unavailable. Start companion again for new online linking.
7. Verify the linked soldier report shows +5 Will/+1 sight radius, Low Profile with the game's installed icon/description, and the unavailable optional ability with an explanation. Existing post-link saves show their frozen ChamberRound target; new links show SingleReloadMrC (or Chamber Round when its provider is installed). Already-owned mappings (when present on another test soldier) must say no duplicate. No fourth row or Officer mod is required. Long rows/description scrolling/layout still require native UI acceptance.
8. If testing new linking in a pre-link timeline, use the MCM-only connect action, cancel confirmation once (no rewards/start), then confirm. Existing Started Journey must not be started again. Save in a separate slot. Armory remains soldier-only. An Upcoming test Journey still requires explicit Start and connect; do not reopen/finish a real Journey as a test.
9. Separately test tactical Low Profile behavior and ongoing resource/Scrounger paths. Host tests and readable Armory entries do not prove tactical effects, supply-drop coverage or compatibility with every reward mod.

## Deferred separately

- Add actual Journey title to the game-credential context API/contracts, then companion and XCOM. Retain older-server compatibility and Journey IDs for binding. No API work in this batch.
- Test-pattern artwork and optional future Trait/Skill image APIs are finishing work, not part of this build.
- Gameplay event collection/outbox/delivery remains unimplemented and is a separate phase.
- Re-enable/redesign the automatic invitation only after the reload cause is established. The older opt-out preference remains saved but dormant.
