# Factual captivity/relationships, ability labels and companion UX

2026-10-21. Mod 0.9.1 / companion 0.10.3. The new mod restores the automatic
Avenger invitation for controlled testing; see AVENGER_INVITATION_TESTING.md.
Capture/bond contracts and API/storage compatibility identifiers are unchanged.
No new credential, relink, character activation or mapping refresh is required.
Use separate non-Ironman test saves; preserve the only campaign copy and journals.

## Contract and migration boundaries

Confirmed `origin/main` 1b34eea; current contracts match the fetched main event file.
No branch switch or backend/Portal code edits. Envelope 0.2, definition version 1:

| Evidence | Future report | Linked subjects |
| --- | --- | --- |
| Soldier captured | threadline.character.captured | one, role captured |
| Capture flag cleared AND soldier back in Crew | threadline.character.freed | one, role freed |
| Native bond confirmed | threadline.relationship.formed | 1–2, role relationship_participant |
| Native bond training upgrade completed | threadline.relationship.developed | 1–2, same role |

Circumstances/details are public plain-text facts. Bonds use relationship_type
`xcom2.soldier_bond`, the native level and optional game_local_participants for an
unlinked partner (local_ref/display_name only). Native IDs and previous level remain
private game_data. No Commander is implicitly added; no fake partner identity.
All four new factual types have canonical zero XP and no acquired Trait effects.
The backend's relationship.broken type is not fabricated from missing data or a dead
partner: these native formation/upgrade callbacks do not prove a separate ending.

Legacy milestones and already captured save-side reports retain type, payload,
timestamp and occurrence IDs. Companion still accepts them. New native occurrences
use relationships, not dual milestone+relationship reports. A contradictory retry
under an old accepted key is held/conflicted rather than silently relabeled.
Native capability negotiation retains new types locally with an older companion.

## Native evidence and save safety

Capture uses the UnitCaptured transaction when present and committed-state fallback.
Mission transfer finalization observes saved, known soldiers—including a prisoner
rescued as an objective, not just deployed units. PostMission runs after native
ProcessMissionResults and SquadTacticalToStrategyTransfer. This handles reset history
numbering without treating a missing-history gap as proof of release.

The captured-prisoner list is NOT release evidence: native GenerateSoldierReward
removes entries while generating the future rescue reward. GiveSoldierReward only
clears bCaptured after returning the actual referenced soldier to Crew. Both flag
and Crew are checked. Later Crew-only commits are observed too. A dead soldier,
mission success, proxy VIP, new reward soldier, missing unit or mere flag clear
outside Crew does not prove freedom. No modification of recruitment/rewards occurs.

Saved captivity observations have separate capture/freedom counters and a history
cursor. Link/load/current prisoners establish a baseline, not historical captures.
Future freedom can be recorded even without a capture event. History gaps silently
rebaseline; an unknown interval is not reconstructed. Repeated capture episodes use
different keys. Source cursors suppress callbacks/older frames, not remote event IDs.
Queue failure does not advance an episode. Links/instances and frozen bonuses remain.

New observations append plain save data. Existing safe allocation/submission gates,
native transaction ownership, no-HTTP callbacks, observer lifecycle and disabled
Avenger prompt remain. No background writes during load/travel/latent mission states.

## First acceptance: UI and multi-character mission

1. Start TheNameBeneathCompanion.exe. Confirm title `The Name Beneath - XCom 2 Companion 0.10.3`.
   Journey tab shows named Journey/Commander, connection and masked credential field.
   Gameplay reporting shows queued/retrying/paused/held/accepted counts and scoped
   diagnostics separately. Character Pools retains explicit download, Save As,
   Journey-named filename and original ZIP/metadata-preserving merge.
2. Confirm action feedback stays visible without scrolling the setup tab. Resize
   the window and check reading/tab/keyboard order. Opening tabs does not call APIs.
3. Load a linked save. The recovered Chamber Round/SingleReloadMrC card and detail
   should show green/currently installed; Mapping details keeps original unavailable
   link-time status and note. Missing providers remain amber; disabled mappings stay
   disabled even if a template exists. No relink, stat stacking or new ability grant.
   Tactical visibility still depends on ammo/action requirements.
4. Save before a new mission. Deploy TWO differently linked soldiers plus an
   unlinked control if possible. Check the shared mission/start/deployment/outcome
   correctly includes both linked instances. An individual promotion/injury belongs
   only to the affected soldier. Save/reload: no duplicates or repeated bonuses.
5. A later mission/covert action with just one linked soldier should not attribute
   participation/completion to the linked soldier left behind.

## Capture/freedom acceptance

1. Use a disposable branch if deliberately allowing capture. Existing captured
   linked soldiers can test later freedom, but loading/linking does not invent a
   capture. No new synthetic live events or XP grants are part of this build.
2. Complete a genuine capture: one Character captured for that immutable instance;
   no death merely because absent, and unrelated/unlinked soldiers get no individual
   The Name Beneath event. Mission facts remain separate. Inspect MCM/logs if held.
3. Generating/viewing/launching a rescue mission must NOT report freed. Failed rescue
   must not either. On actual return, expect one Character freed on the SAME instance,
   with no reactivation/relink/reapplication. The rescued prisoner is not deployed
   with the rescue squad just because they were an objective.
4. Save/reload/retry: no duplicate capture/freedom. Later genuine recapture/freeing
   produces separate episodes. If companion is closed, save, restart it and check
   queued records arrive unchanged. Capture/freedom award zero canonical XP.

## Bond acceptance

1. Confirm a real level-1 bond in the native UI: one Relationship formed involving
   both linked instances, or one linked instance plus the unlinked partner in facts.
   Two unlinked soldiers produce no The Name Beneath event. Availability/cohesion alone
   is not formation. Existing bonds on load/link are not backfilled.
2. Start/cancel training: no upgrade event. Complete training: one Relationship
   developed with resulting level, native previous level retained in private data.
3. Save/reload/retry, including companion-offline capture, without duplicate reports.
   No milestone is emitted alongside the relationship; historical milestones remain.
4. SDK BondSoldiers directly sets levels and bypasses native confirmation callbacks;
   it is not proof of event capture. Prefer real UI. Do not guess console-name inputs.

## Still pending and deliberately unchanged

Retail native/Portal acceptance of these transitions, multi-soldier attribution,
injury/healing, negative-condition acquisition/cure, bonds and normal campaign play.
Complete Trait/Skill catalog mapping audit remains open. Automatic invitation reload
acceptance is a separate gate. Source is public; official release assets remain
pending acceptance/approval per RELEASE_CHECKLIST.md.

Offline compilation, pure commandlet probes and fake-network tests establish policy,
serialized shape, compatibility and queue invariants—not full retail history/save
behaviour or live server acceptance. Never delete journals/receipts to force a pass.
