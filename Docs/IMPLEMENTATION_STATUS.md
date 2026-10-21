# Implementation status

**Public naming: companion 0.10.2 / unchanged mod 0.9.0 (2026-10-21):**
The Name Beneath is the sole public product name. Project/executable renamed to
TheNameBeneathCompanion, namespace to TheNameBeneath.Companion and API client to
JourneyApi. Public prose, build helpers and source examples use the official name.
Established API event names, environment keys and vault/data locations remain
unchanged by explicit compatibility policy; see PUBLIC_NAMING.md. No saved-game,
event, credential or backend migration is performed. Earlier entries are history.

Updated: 2026-10-21. Implementation and the localhost companion EXE are approved. GitHub publication remains deferred until local integration works.

## Current milestone

**Responsive companion header: companion 0.10.1 / unchanged mod 0.9.0 (2026-10-21):**
Replaces fixed header height/text coordinates with automatic layout and wrapping.
Original embedded favicon is shown in the header beside the title; shell/window
icon unchanged. Tests cover minimum/default/wide sizes, doubled title font,
non-overlapping/unclipped bounds and exact favicon bitmap equality. Prior companion
regressions pass. Physical desktop scaling still needs user screenshot acceptance.
Only window UI/tests and version changed; all gameplay/integration code unchanged.

**Captivity, relationships and UX: mod 0.9.0 / companion 0.10.0 (2026-10-21):**
Verified origin/main 1b34eea event contract matches the current local contract.
New committed capture/freedom reports use character.captured/freed; native bond
formation/upgrades use relationship.formed/developed. One/two linked bondmates
share one event; unlinked partner descriptors remain factual local participants.
No inferred relationship.broken from missing records/death. New factual types
have canonical zero XP; legacy milestones/outboxes/IDs remain immutable.
Captivity evidence uses soldier flags plus confirmed crew return, not prisoner-list
removal or mission success. Guarded baselines/committed history and finalized-return
handling preserve repeat episodes, links and outboxes across transfer/reload.
Companion has three readable tabs/grouped sections, report counts and persistent
feedback; title explicitly identifies XCom 2. Ability card/detail status and colors
reflect installed providers, with historical status/notes in Mapping details only.
No mapping, stat, ability grant, credential-store, queue format or safety-guard change.
Build/probe/contract checks are offline; native campaign/Portal acceptance remains
pending. See CAPTIVITY_RELATIONSHIPS_UX_TESTING.md. GitHub work remains deferred.

**Journey-named pool exports companion 0.9.2 / unchanged mod 0.8.7 (2026-10-21):**
Merged Save As defaults to `TNB-<journey name>.bin`, using the cached Journey title,
safe Windows filename characters, Unicode-safe length bounds and short-ID fallback
for legacy/missing titles. User can choose any allowed folder/filename; existing-file
protection and original ZIP naming are unchanged. Filename/UI, pool, connection and
event regression suites pass. Merge codec and game mod are unchanged.

**Appearance Manager pool merge companion 0.9.1 / unchanged mod 0.8.7 (2026-10-21):**
Traced public mod source: ExtraDatas associates saved armor appearances/loadout
with a complete CharPoolData snapshot, not roster index or installed mod list.
Merger now combines this collection, preserves raw character/metadata content and
rebases runtime IDs. Duplicate identical metadata is retained once; conflicting
payloads for the same snapshot or unmatched snapshots are explained and ZIP-only.
No installed-mod checks, stripping or automatic import. Save As remains mandatory.
Four real sample exports, including Marbs Chand.bin, merged into 247 characters;
all record bytes and metadata associations/payloads round-trip. Native XCOM import
and live Journey download still need manual acceptance. Older 0.9.0 limitations
below are historical, superseded by this milestone. Game/mod/events unchanged.

**Character Pool downloads companion 0.9.0 / unchanged mod 0.8.7 (2026-10-21):**
Desktop Character Pools tab uses the current Journey credential's roster:read GET
endpoint. It offers original ZIP save and a separate merged standard pool, preserving
raw character records and removing byte-identical duplicates only. No automatic
import, activation, soldier mutation, extraction, overwrite or utility dependency.
Download is bounded/cancellable and does not hold the gameplay handoff gate. JSON
deadline remains 15 seconds. Existing linkage, event, lifecycle, credential storage,
socket protocol/allowlist and game package are unchanged.

Three real standard exports (143 + 2 + 101 records) merged and round-tripped without
changing any record bytes. Marbs Chand.bin has unmodelled ExtraDatas metadata:
original ZIP remains downloadable, but merging it is deliberately blocked. Full
extended-pool merge support is NOT implemented. Native game import and real Journey
download remain manual acceptance. See CHARACTER_POOL_DOWNLOAD_TESTING.md and
Validation/character-pools-validation.md. No live API or game data was modified.

**Open pre-closeout review (2026-10-21): full canonical Trait/Skill mapping audit.**
Every definition needs a reviewed default mapping or explicit reasoned exclusion
in each applicable soldier/commander context. Record canonical IDs/versions,
effects/balance/timing, optional-provider template names/links and intentional
exclusion versus unreviewed/missing/player-disabled distinctions. Preserve player
overrides; obtain approval before changing defaults. See FEEDBACK_AND_NEXT_TESTS.md.
This is a recorded audit requirement, not a completed catalog review or config edit.

**Capture/rescue integration implemented; retail acceptance OPEN (2026-10-21).**
New character.captured/freed types are integrated after the approved backend merge.
Frozen instances/links remain; capture/return and repeated/offline/reload behaviour
still need live campaign/Portal acceptance. No past tactical test is marked passed.
See CAPTIVITY_RELATIONSHIPS_UX_TESTING.md and FEEDBACK_AND_NEXT_TESTS.md.

**Scrounger flavor text mod 0.8.7 / unchanged companion 0.8.0 (2026-10-20):**
Native Scrounger popup says the commander discovers the named item while rummaging
around the Avenger. It substitutes the existing normalized/escaped item label once
and removes the technical supply-income/collection explanation. Only UI copy,
formatting and probes changed; rewards, native stacking, monthly guards, saved
structures, event reporting, popup lifecycle and loading safety are untouched.
See SCROUNGER_COPY_TESTING.md. No relink/credential/companion/API update is needed.

User confirmed 0.8.6 failed covert completion (Combat Preparedness) reached the
portal, successful action reporting still worked, and deterministic duplicate
inventory testing with all eight AddItem templates stacked correctly. Repeated
reloads continued working. On 0.8.7, user also confirmed a naturally awarded item
stacked correctly with an existing quantity of 1. Scrounger inventory stacking
acceptance is CLOSED (controlled and natural duplicate tests both passed).

Final user decision: generic portal Mission succeeded/failed headings stay for
cross-game consistency. XCOM descriptions distinguish covert actions. The proposed
API/contracts/portal heading cleanup is dropped; no external change is required.

**Covert outcomes/inventory mod 0.8.6 / unchanged companion 0.8.0 (2026-10-20):**
Scrounger uses native acquisition/stacking instead of unconditional inventory
append. No existing inventory normalization or regrant. Covert completion resolves
the three installed LWOTC failure risks from native risk results; unknown reward
withholding is still held rather than guessed. Completed callbacks return early.
New mod summaries distinguish covert actions; portal headings require separate
API/contracts/portal presentation work. Existing event identities/taxonomy/XP,
saved structures, frozen participant rosters, award guards, popup ordering, mapping
and all loading safeguards are preserved. No hard LW dependency, new timer or
own-transaction submission was added. See COVERT_AND_INVENTORY_TESTING.md.

Retail 0.8.5 supply UI, post-reward reload, successful covert completion and offline
capture/reconnect passed. Failed-action completion and duplicate inventory rows
were found during that testing and motivate this patch. Live 0.8.6 stacking/failure
delivery remain acceptance gates; offline tests are not retail execution proof.

**Supply display polish mod 0.8.5 / unchanged companion 0.8.0 (2026-10-20):**
retail 0.8.4 screenshots confirm a clear Scrounger item popup and readable exact
86 +4 =90 collection receipt. Native item color markup was over-escaped, and the
native floating collection message still displayed the pre-adjustment 86. This
build strips native item tags before escaping, corrects only the already-pending
cache display field to the actual signed-adjusted gain, and adds positive/negative
recovery flavor to the receipt popup. The large month-end report/base preview is
intentionally unchanged. No resource math, additional grant, monthly Scrounger
guard, saved structure, mapping, reporting identity or companion/API changes.
See SUPPLY_DISPLAY_TESTING.md and Validation/supply-display-validation.md. Final
Flash appearance and real negative-modifier flyover still require manual testing.
The earlier menu slowness is not reproducible in current builds/new saves; no
cause is claimed and no performance change is bundled. Covert-action portal titles
remain a separate display follow-up using the existing standard event taxonomy.

**Commander monthly rewards mod 0.8.4 / unchanged companion 0.8.0 (2026-10-20):**
Scrounger moves from positive cache collection to native PreEndOfMonth, including
zero-income months. Item, preserved month guard and native non-immediate popup
queue entry share the supplied month-end transaction. A native item-received
screen identifies the item after the monthly report, with no new timer or custom
history submission. Supply collection saves an additive mod-owned exact display
receipt; the existing completion/instant alert shows base, modifier and total.
Partial collections retain actual per-installment rounding. Missing/stale legacy
receipts do not fabricate amounts. Source allowlist, mappings, links, existing
saved structures, mission/promotion/condition/bond capture and companion are
unchanged. UI ordering/layout/inventory acceptance remains manual. See
COMMANDER_MONTHLY_REWARDS_TESTING.md and Validation/commander-rewards-validation.md.

Retail testing of 0.8.3 now confirms successful mission completion and actual
Rookie-to-Squaddie promotion reached the portal; Low Profile remained present.
A deliberate return to the strategic pre-launch save created a distinct launch
attempt. In-progress tactical-save identity continuity and wound/recovery paths
remain separate manual gates. The first-menu delay remains a separate feedback
item: UI responds and queues navigation, and a newer post-mission save did not
reproduce it. No speculative performance fix is included here.

**Mission-attempt reporting mod 0.8.3 / unchanged companion 0.8.0 (2026-10-20):**
approved policy changes tactical mission occurrence identity from mission site to
actual launch attempt. PrepareMission reads the native fresh tactical start-state
BizAnalyticsMissionID, normalizes it and saves an additive mod-owned attempt record
with the original site/source/timer/seed key for context. No mission-site or battle
data field is changed. New launches yield new start/deployment/completion event and
mission references, even for the same generated mission. Same-launch callbacks,
delivery retries, tactical reloads and multi-map transfer retain saved identity.
Legacy in-progress reports keep their old keys/payloads without migration. Genuine
replay can earn normal server-calculated XP; immutable same-attempt conflicts still
protect original facts. Existing soldier/covert/bond identities are unchanged.
The 0.8.1 loading guards and 0.8.2 promotion/wound/gap fixes are preserved. Retail
promotion, wound and attempt/save acceptance remain manual gates. See
MISSION_ATTEMPTS_TESTING.md; its policy supersedes older replay-conflict warnings.

**Promotion/mission-wound mod 0.8.2 / unchanged companion 0.8.0 (2026-10-20):**
user-confirmed commander-only and linked-rookie mission launch, ordinary tactical
play and Avenger return now pass on 0.8.1. Portal received start/deployment/failure.
Screenshots prove Chand's real Rookie-to-Squaddie promotion and persistent Low
Profile; MCM shows observation_history_unavailable and no pending/held report.
The unlinked Templar lost 1 HP but had no post-mission recovery time; native summary
shows one wound and the dead VIP, while all five squad soldiers returned Active.
0.8.2 captures actual UnitRankUp in its existing transaction, shares stable keys
with observer fallback, and keeps a rank high-water mark against older frames.
Missing/reset history silently rebaselines current scoped soldiers, preserving
episode counters and warning about omitted intervals instead of freezing capture.
Wound totals are frozen from native WasInjuredOnMission at CleanupTacticalMission
before transfer/recovery, independent of linking. Legacy unknown totals are omitted.
The 0.8.1 loading guards, mappings/grants, UI and companion remain unchanged.
No retroactive promotion or accepted mission rewrite occurs. See
PROMOTION_AND_MISSION_WOUNDS_TESTING.md for replay caveats and acceptance gates.

**Reporting load diagnostic mod 0.8.1 / unchanged companion 0.8.0 (2026-10-20):**
fresh-campaign mission launch also crashed with commander association alone, so
soldier rank/ability injection is not required. Background reporting now checks
world/travel/history, pending start state, native loading/latent/state admission
and live tactical phase before any allocation or other work. Existing baselines
skip empty initialization writes; submission failures retain retry state. Added
bounded defer/resume, create/submit and mission lifecycle logs without secrets or
event payloads. Native event transactions, gameplay grants, mapping r2, saved link/
report schemas, approved alpha UI, companion and API are unchanged. This fixes an
identified unsafe path but is not proof of the crash cause. Mission loading is
the current acceptance gate before event/XP smoke tests. See REPORTING_LOAD_DIAGNOSTIC.md.

**Bond milestone test build 0.8.0 (2026-10-19):** native BondCreated and
BondLevelUpComplete append one factual standard milestone to the same transaction
as the actual reciprocal bond change. Captures previous/new level, both local
soldiers and one/two current-Journey linked instances; no historical backfill,
availability/training-start events, autoactivation or canonical relationship edits.
Stable pair episodes and the existing outbox/companion retain duplicate/conflict
protection; older companions hold the new reports safely pending update. Companion
validation adds only this restricted milestone family. Existing grants/mappings,
UI, mission/condition capture, API and delivery journals are preserved. Both clients
must be updated. See BOND_MILESTONES_TESTING.md and Validation/bond-milestones-validation.md.
Retail formation/training, save/reload and online acceptance remain manual gates.
Final review will revisit a dedicated event type; capture itself is implemented now.

**Mod UI patch 0.7.1 / companion 0.7.0 unchanged (2026-10-19):** reviewed Steam
screenshots `20261019221352_1`, `20261019221451_1`, `20261019221506_1`. The saved
Journey title appears after explicit refresh, and soldier icons/stats/results render.
This patch condenses soldier body text and moves technical provenance into Mapping
details, adds the matching graphical saved commander report with real resource/staff
icons and one-time/ongoing/monthly badges, and replaces the invalid Insignia fallback
responsible for rainbow panels. SDK tests actually load all replacement textures.
No companion/API, mapping, grant, save-schema or event pipeline changes. Campaign
association confirmation/lifecycle logic is preserved; only the saved-report route
changes. Automatic Avenger prompts remain disabled. See COMMANDER_UX_AND_MISSION_SMOKE_TEST.md
and Validation/commander-ux-validation.md. Mission delivery/XP, new UI rendering and
in-session reload acceptance remain separate gates, not inferred from screenshots.

**Journey/title and graphical soldier UX 0.7.0 (2026-10-19):** uses the deployed
required `journey_title` on context/lifecycle responses in companion, MCM, campaign
setup/confirmation, commander report and linked Armory profile. IDs remain binding
keys; refreshed titles are cosmetic last-observed metadata, separate from frozen
commander/soldier effects. Existing saves/credentials remain usable without re-linking.
The Armory profile uses native ability/PCS/perk icon cards, net committed stat deltas,
positive/negative/skipped statuses and selectable mapping/help details, with no Officer
dependency. Core grant, resource, event-capture/delivery and security code are unchanged;
automatic Avenger prompts stay disabled. Latest main's inline SVG library was reviewed;
this build uses actual XCOM effect icons, not unconverted remote SVGs. See
JOURNEY_AND_SOLDIER_UX_TESTING.md and Validation/journey-soldier-ux-validation.md.
Native rendering, reload and real mission-delivery acceptance remain pending. Older
deferrals below are historical where superseded by this milestone.

**Gameplay reporting test build 0.6.0 (2026-10-19):** the approved capture/outbox/delivery pipeline is implemented against the existing v0.2 API, retaining protocol 2 and adding gameplay feature 1. Tactical/covert hooks, soldier observations (including native negative conditions), versioned plain-data save records, explicit launch/transfer copying, a world-owned notification/pump actor, immutable endpoint-scoped companion journals, strict receipt validation, retry/hold/credential isolation, and scoped MCM/desktop reporting status are present. The soldier-link commit adds only a reporting-baseline hook; its grants and existing save schemas are unchanged. Automatic Avenger invitations remain disabled. The user's preceding complete reload sequence passed on 0.5.1; the old crash narrative below is historical and the new observer needs its own reload acceptance. See EVENT_REPORTING_TESTING.md and Validation/event-reporting-validation.md for exact automated evidence and outstanding native-game gates. No live synthetic events, real credentials, XP grants or API/schema changes are part of this implementation. This is not completed v1 acceptance or a GitHub release.

**Feedback/diagnostic build 0.5.1 (2026-10-19; supersedes older UI instructions below):** campaign linking is MCM-only; the automatic Avenger prompt is completely disabled pending in-session reload diagnosis. MCM exposes View Commander & Bonuses, and the linked Armory entry exposes Traits & Abilities with readable frozen results and installed ability descriptions/icons. Closing the companion does not close XCOM. No API, mapping balance, reward/ability-grant service, save schema or credential-target change. Journey-name API work, artwork and gameplay event delivery remain deferred. User has now confirmed +1 Engineer/additional Supplies, saved character stat persistence, genuine Low Profile addition/persistence, and safe missing optional ChamberRound handling. In-session reload repeatedly crashes even before linking, while the post-link save loads after a fresh launch. See FEEDBACK_AND_NEXT_TESTS.md and Validation/feedback-build-validation.md for this build's evidence and remaining native-game gates. Older statements below about mandatory Avenger reminders or entirely untested skill injection are historical, not current results.

**Journey lifecycle management amendment (2026-10-19):** the approved API/portal branch is `feature/journey-management`. One optional `journey:manage` credential permission covers explicit start, finish and reopen. Portal issuance includes it automatically without scope selection; existing/rotated keys keep their recorded permissions. Companion 0.5.0 / protocol 2 / Armory feature 2 / management feature 1 adds only a confirmation-gated, exact-Journey/version `journey_start` localhost operation. Upcoming campaigns can review effects and confirm Start Journey and connect; Started Journeys retain Connect, and Finished requires explicit portal reopen. Existing saved associations/rewards are unchanged. Merely viewing/testing a connection never starts anything. Start success is remote and survives older XCOM saves; failed/changed-response paths require refresh/review before local bonuses. API forward migration 0014 preserves active periods and actor attribution so reopen does not reclassify closed-period history or duplicate XP/Traits. API/portal deployment and a newly issued credential are prerequisites for automatic Start. No live transition/deployment/migration was run by the agent. See Validation/journey-management-validation.md and the API repo's docs/journey-management-xcom-handoff.md.

**Campaign setup UX amendment (2026-10-19):** campaign/Journey association now has a dedicated campaign-only screen reached from a quiet Avenger reminder or MCM > The Name Beneath > Campaign Journey. Commander bonuses do not require any soldier links. The Armory only links/reports soldiers and redirects unconnected campaigns to setup. Not now defers the reminder until a later campaign load; a saved campaign-local MCM opt-out remains reversible. The prompt never associates automatically. Existing saved associations/rewards are retained and their offline report does not regrant effects. Companion 0.4.1 / protocol 2 / Armory feature 2 are unchanged; no new companion executable or API route is required. See CAMPAIGN_JOURNEY_TESTING.md and Validation/campaign-journey-validation.md for the new UI's outstanding actual-game checks.

**User test report (2026-10-19):** the user reports the preceding gameplay tests completed and everything tried worked. They explicitly did not have a character with purchased Skills, so ability injection remains unverified. Do not treat that report as exhaustive tactical/economy/crash/compatibility acceptance. Fresh commander/character/Journey skill testing is planned; no XP, purchases, remote activations or synthetic events have been created by this amendment.

Companion 0.4.1 / Armory feature 2 implements the user's revised soldier rollback policy: the **loaded save** owns local pairings. Loading a pre-link save does not automatically restore or lock a previous pairing. The player may leave the soldier unlinked, choose a different character, or assign the same Journey character to a different unlinked soldier. A new confirmed intent reauthorizes through the existing API, which reuses that character's original Journey instance/snapshot. Only an intent actually present in the loaded save can resume its exact receipt. Existing committed links remain immutable and their stats are never reapplied. A new unit-value application marker joins the detailed saved ledger as a duplicate-application guard; inconsistent/orphaned records block only linking with a clear warning, not campaign play. Commander association/rewards and the resource system are unchanged. See Validation/save-rollback-validation.md for automated evidence and outstanding in-game tests.

Companion 0.4.0 and the new mod code implement the first gameplay slice: Armory character picker with paging, explicit campaign/Journey association, frozen configurable mappings, one-time commander effects, permanent character activation with a durable recovery journal, atomic local soldier-link/stat commit, earned-ability injection, saved per-effect reports, and a restricted commander resource/Scrounger path. This is an experimental local build awaiting actual-game association/link/save-load/tactical/economy tests, not a release or a completed v1. No agent-driven live activation or gameplay mutation has been performed. Events/outbox delivery remain unimplemented. See Validation/armory-link-validation.md, MAPPING_CUSTOMIZATION.md, and RESOURCE_COVERAGE.md.

The user's two Steam screenshots from 2026-10-19 verify the preceding read-only Armory menu and populated preview in the real game. The new workflow replaces that preview; its confirmation screens and effects still require the separate manual-test-save procedure in COMPANION_SETUP.md.

Companion 0.3.1 is an icon-only patch over 0.3.0: the portal's original favicon is embedded as both the Windows executable icon and the desktop window/taskbar icon. The unmodified SVG source and generated multi-size ICO are included in the companion project. Source/published icon checks and the existing regression suite pass. No mod scripts, protocol, API behavior, credential target, or live credential changed. See Validation/companion-icon-validation.md.

Companion 0.3.0 added read-only Journey context and Journey-pinned roster reads. The preceding strategy-only Highlander Armory preview displayed commander/Journey context, Trait/Skill counts and up to five roster entries. That preview's actual-game hook/dialog check has now passed by screenshot inspection; it applied no effects. Earlier C# fake-API/socket and live GET checks passed. An intervening HTTP 404/non-JSON failure cleared after the user restarted the sleeping Replit app; the existing token remained valid. See Validation/armory-preview-validation.md.

The connection milestone now has a desktop UX: masked credential entry, Validate and save, Journey/commander confirmation, test/replace/remove controls, HTTPS/vault support, bounded localhost protocol 2, UnrealScript client, and MCM status page. The programmatic clipboard reader has been removed. Host-side and hidden desktop UI tests pass; the WOTC mod script build passes with zero errors and zero warnings (base SDK packages retain three pre-existing TLE duplicate-class warnings). The supplied Replit development API accepts the refreshed local protection token and Journey credential on the read-only context check, including required-scope validation.

**Basic in-game TCP/MCM verification passed in AML, reported by the user on 2026-10-18.** The inspected screenshot shows the stored credential and Chandalar / started context. The user confirmed Test stayed connected, closing the companion caused companion timeout on Test, and restarting the companion restored connectivity. This supersedes the earlier SDK-only runtime limitation. It does not establish every failure/security path or validate the newly implemented gameplay behavior. Event delivery is still unimplemented.

The subsequent simplified MCM page uses The Name Beneath branding, separates companion reachability from last-known Journey verification, retains a read-only credential indicator and Refresh/Test, and removes setup/version rows. Text is localized in Localization/TheNameBeneath.int. API routes, technical binary/config identifiers, and the companion credential vault are unchanged.

## Verified environment

- Game: D:/Steam/steamapps/common/XCOM 2/XCom2-WarOfTheChosen.
- SDK: D:/Steam/steamapps/common/XCOM 2 War of the Chosen SDK; executable version 8917, Fxs changelist 372475.
- User's AML Highlander baseline: 1.31.3. Workshop item 1796402257; DLC name X2WOTCCommunityHighlander.
- MCM: Workshop item 667104300; DLC name ModConfigMenu. Its API source is vendored with MIT attribution.
- Companion build: .NET SDK 10.0.401; self-contained win-x64, single-file, no custom external DLL.
- Historical native proof: MSVC 19.50.35727 and CMake/Ninja from Visual Studio 2026 Build Tools.

## Implemented

- Companion 0.4.1 retains activation_status/activate/activation_ack under protocol 2. The Armory requires armory_link_version=2 before offering mutations, preventing mixed 0.4.0/0.4.1 behavior. The remote POST still contains only character_id/onboarding_mode=bind_existing. No baseline snapshot is uploaded.
- A per-endpoint/Journey/campaign local journal is persisted before HTTP and retains pending/activated/acknowledged receipts, now keyed by confirmed intent token rather than permanent unit ownership. Schema-1 records remain readable; writes migrate to schema 2 without deleting historical receipts. No-token status returns no receipt, so old history does not automatically restore or constrain a pre-link save. Exact-intent mismatches still fail; a new intent performs current authorization rather than reusing a stale consent decision. Receipt metadata never reaches the remote POST.
- New campaign, soldier-link and local-intent game-state classes carry schema versions. Campaign association and commander one-time effects share one state submission; soldier stats and permanent local binding share another. Ability names are supplied by ModifyEarnedSoldierAbilities with deduplication and weapon-slot metadata, not a promotion-screen row.
- The Armory action becomes Link character / Resume character link / Linked character. The picker supports five-entry pages, confirmation, recovery, saved per-effect details and net stat totals. Existing-link reports work without contacting the companion. No secret is accepted by a game UI/console.
- Mappings match canonical ID/kind/context/reviewed versions; player Overrides are separate from shipped rows. Exact/ranged precedence and equal-rank conflict rejection are deterministic. Existing saved effects do not live-rebalance. Conspicuous remains intentionally unmapped pending an approved numerical target; missing optional ability templates are visible skips.
- Percentage resources use a positive, source-identified reward/cache allowlist, integer basis points, symmetric truncation and a save ledger. Scrounger grants at most one configured common item per collected monthly drop, identifies it in a post-commit banner, and does not bank missed/merged old deposits. Source inspection/compilation is not a runtime acceptance pass; see RESOURCE_COVERAGE.md.

- Original experiments preserved under Docs/Prototypes; one clean DLC entry point.
- Highlander/MCM dependency metadata, MCM API compile registration, and license attribution.
- Companion 0.2.0 / protocol 2, TCP restricted to IPv4 loopback, exclusive port, bounded frames/client count/deadlines, ASCII-safe JSON, no arbitrary URL forwarding or credential import/removal over the socket. A second desktop copy fails safely if the port is occupied.
- Normal TLS certificate validation, bounded HTTPS responses/deadlines, redirect rejection, redacted stable errors, development protection using the Vanguard configuration convention.
- Masked desktop entry with standard paste/type support validates format/context/scopes before replacement; Windows Credential Manager stores the secret under an endpoint/Journey-specific target. The field is cleared before validation and never repopulated from the vault.
- Atomic endpoint-specific nonsecret context persistence; restart reports unverified rather than claiming an online connection.
- Serialized import/test/remove mutations. Offline verification preserves the stored secret. Removal does not delete The Name Beneath data.
- Desktop test/replace/remove, with confirmation before replacement/removal. MCM shows a disabled vault-backed Credential stored checkbox and Refresh/Test; connection validity is separate. Closing the companion cancels its listener; minimizing keeps it running. UI-close cancellation and companion-unavailable handling remain in the UnrealScript client.
- TNBStatus and TNBProbeCompanion diagnostic commands; neither accepts a credential.
- Build/start scripts, standalone executable, and setup/testing instructions. No Windows service or game-binary DLL installation.

## Tests and evidence

- Companion tests pass: credential format/context/scopes; rejected replacement preserves existing secret; atomic context/restart; offline retention; status/save redaction; fragmented TCP; Unicode; protocol/browser/unknown-operation rejection; concurrent clients; cancellation/shutdown; isolated synthetic Windows vault write/read/delete.
- Companion publishes as one self-contained Win64 EXE. The published EXE is checked with the same tests and read-only development API check.
- Hidden WinForms tests cover masked entry, standard-paste configuration, invalid/valid validation, field clearing, resolved Journey/commander labels, rejected-replacement retention, offline status, redacted errors, removal, shared desktop/socket status, and window-close listener shutdown. A synthetic screenshot was inspected for layout; no real credential was entered into the GUI by the agent.
- Mod compiles successfully: 0 errors, 0 warnings. Script/config output staged to the game's local TheNameBeneath mod directory. Compilation is not an interactive launch test.
- Live API validation: GET /v1/game-journey only; no activation, event submission, real credential-vault import, clipboard read, or campaign mutation performed by these checks.
- SDK runtime probe exits with 'This executable must be run as the editor or a commandlet' before map gameplay starts. No transport result inferred.
- Current runtime evidence: Docs/Validation/in-game-connection-validation.md. Desktop build evidence: companion-ui-validation.md and connection-ui-mod-compiled.log. Earlier evidence remains in connection-mod-compiled.log and sdk-runtime-host-limitation.log.

## Why no DLL is installed

The WOTC compiler rejected DLLBind ('Missing semicolon in Class') and dllimport ('Unexpected dllimport') before any native loading could occur. Negative fixtures and logs remain under Docs/Prototypes and Docs/Validation. The earlier native x64 async/ABI proof passed host-side tests but cannot be called through that rejected interface.

The user-supplied Modern Multiplayer Mod delegates to Steamworks session APIs; it does not supply an arbitrary HTTPS client or DLL loader. See NETWORKING_INVESTIGATION.md. The user then accepted the companion architecture; the implementation plan now has a superseding transport amendment. The Native folder is historical proof code, not a runtime dependency.

## Next gates

Commander balance defaults and timing remain approved in COMMANDER_MAPPINGS.md. Their initial code paths and the committed per-Trait/Skill report are now implemented, but have not yet been exercised against a real campaign. The initial resource allowlist deliberately excludes unidentified gains and tactical loot. There is no claim of comprehensive economy-mod compatibility.

1. Basic AML transport/verification/companion-off/reconnect checks passed. Remaining hardening includes true API-offline behavior while the companion stays running, desktop removal reflected through Refresh, and UI-close edge cases. The simplified page layout should be checked on the next normal launch; the already-passed transport test need not be repeated solely for the label changes.
2. Read-only Armory preview passed by inspected screenshots. Test the NEW association/picker/confirmation/report UI on a separate manual save; verify one-time rewards, save/reload, duplicate selection, receipt recovery and Journey mismatch. Also test A->C, rewind before link, then B->C (same instance); A->C, rewind, then A->D; opting out after rewind; and reloading a post-link save without doubled stats. These are not yet actual-game acceptance passes. No agent-driven live activation is part of validation.
3. Verify applied stat deltas, HP no-heal behavior and ModifyEarnedSoldierAbilities across save/load and tactical transitions without a fourth promotion row. Optional templates/class interactions require representative gameplay tests.
4. Test the documented resource-origin allowlist, negative percentages, rounding, deduplication and Scrounger item/banner. Verify one-time Avatar countdown/capacity behavior and staff rewards. Expand coverage only after source verification. Copied/divergent saves and simultaneous independent game processes are not a release-validated use case.
5. Verify mission/character transition hooks and build the v0.2 event factory/durable outbox with fake-server tests before live event delivery.

Confirmed SDK hooks include ModifyEarnedSoldierAbilities, OnArmoryMainMenuUpdate, UnitRankUp, and AddResource. AddResource alone is not sufficient proof of resource-origin coverage. No blanket resource bonus is installed. The plan's later acceptance gates remain in force.
