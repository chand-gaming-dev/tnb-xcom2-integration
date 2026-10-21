# The Name Beneath: v1 gameplay event submission

Date: 2026-10-19. **Implementation plan for user review, not implemented functionality.** No runtime code, installed mod, companion executable, API, credential or remote Journey is changed by preparing this plan.

## 1. Objective and agreed scope

Connect actual XCOM gameplay to the existing Threadline Event Contract v0.2 through the companion. Preserve normal campaign play during connection failures. Report facts, not inferred accomplishments, and make submission/retry state understandable.

Include tactical missions, covert actions as ordinary missions, and linked-character promotion/injury/recovery/death transitions, including acquiring and recovering from temporary negative XCOM soldier conditions. The user explicitly approved reporting these conditions as injuries with additional detail; they must not directly add/remove canonical Threadline Traits. Support a connected commander with no linked soldiers. Exclude individual attacks/hits/misses, invented baseline/backfill events, client-authored XP awards, and automatic Journey start/finish/reopen from the reporting path.

Current baseline: companion 0.5.1, protocol 2, Armory feature 2, Journey-management feature 1. The user reports the full linking and pre-/post-link reload sequence works with the automatic Avenger prompt disabled. Retain MCM-only campaign linking. The precise old prompt failure (timing versus retained world references) is not proven. Do not reintroduce it for event reporting.

No API/schema/migration change is expected for this slice. Journey-name API support, graphical finishing work, placeholder artwork replacement and optional automatic invitations remain separate cleanup. Resource interceptors and Scrounger are already implemented; their outstanding gameplay verification is not new event implementation.

## 2. Existing API contract

- Single event: `POST /v1/game-journey/events`, Journey bearer with `events:write`.
- Use this single-event route first; batch submission is unnecessary for v1. A later batch optimization must preserve independent receipt/error handling.
- Envelope: `contract_version: "0.2"`, stable `event_id`, pinned `journey_id`, real-world `occurred_at`, standard `event_type`/`type_version`, bounded plain-text `summary`, participants, and a stable `mission_ref` for mission events.
- `threadline.mission.completed` **type_version 2** supports result/turns/duration plus optional `squad_injuries`/`squad_deaths`. Its `outcome.status` must equal `facts.result`.
- Other events in this plan use type_version 1. Put XCOM-specific metadata in existing `game_data`/`context`, never undeclared fields inside strict `facts`.
- Character participants use the saved Journey **instance ID**, not the canonical character UUID or XCOM unit ID. Mission character participation is `subject` with role `deployed`. Transition roles are exactly `promoted`, `injured`, `recovered` or `deceased`.
- An explicit commander context participant, when useful, uses `source: "journey_commander"`, participation `context`, and a nonreserved role such as `commanding`; never give a commander the character-only `deployed` role. The backend also associates events/mission completion progression with the authenticated Journey commander when no characters participate.
- Validate against the actual TypeBox schemas and semantic validator, not only a handwritten C# approximation. Acceptance is 201/`accepted` or 200/`duplicate`, with matching event/Journey/commander IDs and a valid receipt. A generic HTTP 200 or malformed body is not success.
- Preserve the API's `source_confidence: operator_reported` and `gameplay_attested: false` meaning. Schema validation, a local mod and a bearer credential do not provide anti-cheat attestation or server-verified gameplay.
- The backend owns XP and acquired-Trait rules. Covert completions follow the existing mission rules, including commander mission history/qualification. Do not add milestone events just to manufacture XP. The current growth implementation awards local promotions according to its configured policy; an older catalog description saying promotion awards no canonical progression conflicts with that implementation. Test actual policy behavior and record this documentation discrepancy separately; do not silently change growth policy.

## 3. Event coverage and verified capture points

| Gameplay fact | Existing API representation | Installed source / capture strategy |
|---|---|---|
| Tactical mission begins | `threadline.mission.started` | `OnPreMission(StartGameState, MissionState)` prepares identity/roster observation in the supplied state. Establish actual tactical start once; a mere UI selection/cancel is not a start. `OnTacticalBeginPlay` is a verified candidate and must be guarded against save reloads. |
| Linked soldiers deploy | `threadline.mission.character_deployed` | One event for the actual deployed linked roster; capture instance IDs at launch/start, not from a later roster screen. No empty deployment event. |
| Tactical mission ends | `threadline.mission.completed` v2 | `CleanupTacticalMission` carries BattleData and a pending state, before recovery. Capture transient facts there; finalize after tactical-to-strategy processing through the verified DLC `OnPostMission`/committed transfer seam. Never use a mission-summary screen opening as an award trigger. |
| Covert action starts | Standard mission started/deployed | Verified `CovertActionStarted` event. Read the changed action from the supplied state (EventSource can be an earlier object), capture actual staffed soldiers and their saved instance IDs. Merely filling/editing a slot is not deployment. |
| Covert action completes | Standard mission completed v2 | Verified `CovertActionCompleted`; inspect committed action/risk/unit state. Its source code delays completion when an ambush is outstanding. Normal action completion is not automatically the same result as the ambush battle result. |
| Actual soldier rank changes | `threadline.character.promoted` | Verified `UnitRankUp`, which fires after rank/stat mutation. Compare old versus committed new rank. Do not use eligibility, rank-up messages or opening a promotion screen. Covert-action promotions use the same listener. |
| New mission/covert wounds | `threadline.character.injured` | Compare observation baseline and finalized strategic unit/healing state, with `SoldierTacticalToStrategy`/`PostMissionUpdateSoldierHealing` as verified seams. Risk or temporary tactical HP loss alone is not proof of a new strategic wound. |
| Full wound recovery | `threadline.character.recovered` | Verified `UnitHealCompleted`. EventData may contain the earlier UnitState; resolve the changed unit from the supplied transaction/committed history and verify recovery. Do not report every healing tick, fatigue recovery or a screen refresh as wound recovery. |
| Active negative soldier condition acquired | `threadline.character.injured` with game-local condition detail | Compare committed `AcquiredTraits`/`NegativeTraits` sets. `UnitTraitsChanged` is a useful notification, not proof of acquisition: it can fire while a trait is only pending, and some acquisition paths do not emit it. |
| Negative soldier condition cured | `threadline.character.recovered` with condition/episode reference | Verify actual condition removal/cure. Infirmary treatment uses `XComGameState_HeadquartersProjectRemoveTraits` -> `CompleteRemoveTraits` -> `RecoverFromAllTraits`, not the physical-wound `UnitHealCompleted` path. Also account for verified non-Infirmary recovery paths. |
| Final death | `threadline.character.died` | Verify final strategic `IsDead()` after return/risk resolution. `UnitDied` exists, but tactical death can be intercepted/reversed by mods, so it is an observation, not immediate irreversible submission. Nonmission deaths need equivalent committed before/after evidence, or remain unsupported with a diagnostic. |

Implementation gates: prove event registration deferrals, transaction ordering and transfer persistence in a minimal fixture before enabling capture. Use ELD_Immediate only for copying necessary facts into the existing pending state; dispatch network work only after commit. Do not submit recursively from an immediate game-state callback.

### Tactical fields: use what actually exists

Installed BattleData exposes `m_iMissionID`, `BizAnalyticsMissionID`, operation/location metadata, `bLocalPlayerWon`, `bMissionAborted`, objective helpers, and `TacticalTurnCount`. The strategy result processor uses `bLocalPlayerWon` for success/failure. Verify turn semantics against the actual summary before transmitting a turn count. Do not copy the earlier illustrative `m_eResult`, `m_iTurns`, `m_bIsObjectiveComplete` or `m_iDamageDealt` assumptions into implementation without finding them.

`Unit.GetNumKills()` returns `KilledUnits.Length`; that alone does not establish a mission-local count. Per-soldier kills may be included in bounded `game_data` only after proving a mission-start baseline/set difference or an authoritative mission-local counter. Damage dealt/highest shot are optional investigation items, not promises for the first slice. Omit unsupported values rather than send lifetime totals, guesses or false zeroes. No hit/miss listeners are needed.

Report captures/MIA/evacuation in mission participant results/game metadata when verified. There is no standard captured/rescued transition in this contract, so do not invent those event types, equate capture with death, or fabricate milestone awards. A future standalone status event can be reviewed separately.

### Temporary negative soldier conditions (approved addition)

These are XCOM's game-local negative soldier traits/psychological conditions, distinct from the Traits selected/acquired through Threadline. Recording the event must not directly mutate a canonical Trait, Skill, frozen activation snapshot, or the mod's saved link-time bonus mappings. The backend retains its existing event-progression rules; using an injury event means its normal configured injury rule applies, not a new milestone/XP grant.

- Acquisition: emit `threadline.character.injured` only when a condition becomes active in committed soldier state. Use `facts.injury_code: "xcom2_negative_trait"`; put the actual template, display name, `condition_kind: "negative_soldier_trait"`, and stable condition-episode key in `game_data`. Include a verified mission reference if attributable; do not guess a causal mission merely because an alert appeared there.
- Cure: emit `threadline.character.recovered`, `facts.recovery: "full"`, and `facts.injury_ref` pointing to the acquisition event/episode where known. "Full" refers to that particular condition, not a claim that all wounds, fatigue, or other psychological conditions are healed. Preserve the condition identity in `game_data` and record Infirmary treatment versus another verified recovery mechanism only when the source can be established.
- Treatment enrollment, elapsed treatment time, cancellation, a failed trait roll, a transient `PendingTraits` entry and a repeated popup are not acquisition/cure. A pending entry which never activates produces no injury event. A cure can remove several active conditions; report each actual condition/episode once rather than treat it as one unspecified wound heal.
- Snapshot `AcquiredTraits`, `NegativeTraits` and `CuredTraits` at the observation baseline; distinguish negative from positive templates using native state/template metadata, not a hardcoded English-name list. Newly enabled reporting or character linking does not backfill pre-existing conditions. A future verified cure of a baseline condition can be reported without fabricating its past acquisition; omit the acquisition reference if unknown and label that provenance honestly.
- An absent template after a mod is disabled is not automatically a cure. Prefer actual cured-set changes or a verified treatment/state transition. Unknown modded conditions retain their template identity and an explicit missing-label/source status instead of being silently classified or mapped to canonical Traits.
- Keep condition episodes distinct from physical-wound episodes. Do not count each negative template as an additional soldier in `squad_injuries` or manufacture a clean/no-injury squad total from unknown mental-condition data. Preserve the documented mission casualty semantics and use separate detailed condition events/metadata.
- The source's `RecoverFromTraits` can cure a condition through gameplay and may add an XCOM positive replacement. Record the actual recovery and any observed replacement as local detail; do not turn it into a canonical positive Threadline Trait or infer that every cure came from the Infirmary.

**Hook coverage requirement:** `AcquireTrait` emits `UnitTraitsChanged` even when it only fills `PendingTraits`; `AddAcquiredTrait` and `AcquirePendingTraits` do not reliably emit a distinct active-acquisition event. `RecoverFromAllTraits` removes negative conditions/adds cured entries without emitting `UnitTraitsChanged`. A sole listener on that event or on `UnitHealCompleted` would miss or misreport this feature.

Use the SDK's verified `XComGameStateHistory.RegisterOnNewGameStateDelegate` / `UnRegisterOnNewGameStateDelegate` interface as a committed-change notification where needed, filtered to modified linked units/relevant treatment context. Compare before/after native state and persisted observation data, then enqueue through the normal deferred capture transaction. Do not recursively submit a game state or contact the network from a history callback. Ignore the observer's own ledger-only frames, deduplicate against post-mission reconciliation, and initialize without historical emissions. Prove callback ordering, save-immediately-after-cure behavior, save reload/replay suppression and delegate teardown before enabling it. No listener may retain an old History/World/Actor/Screen through a process-lifetime singleton.

### Covert actions and ambushes

- Use the same mission event types/normal backend progression, labeled with `context.tags: ["xcom2", "covert_action"]` and `game_data.mission_kind: "covert_action"`. Ordinary tactical missions use `tactical`.
- Freeze staffed linked participants at actual start. Staff may be removed/captured before completion; do not reconstruct participation only from empty end-state slots.
- **One logical completion for a covert action, including its child ambush.** Record the ambush outcome/reference as supporting metadata on the parent; suppress separate child mission started/deployed/completed awards. Do not suppress distinct injury/death/promotion facts, but deduplicate them by actual transition/episode.
- Link child-to-parent using mission source, actual action/mission state and roster evidence. `GetMission(AmbushMissionSource)` exists, but its search-by-source can be ambiguous in heavily modded concurrent-action setups. Do not guess a parent from a matching name alone. Unresolvable related reports are held visibly rather than submitted as two unrelated completions.
- An action can complete while an ambush failed or soldiers were captured. Preserve the strategic action's actual completion/result and separate ambush/participant outcomes. Do not automatically turn an action's reward/completion into tactical victory.
- Omit tactical turns/duration when unavailable. Whole-squad casualties include actual assigned/deployed XCOM soldiers, linked or unlinked, not enemies or an unrelated roster. Unknown casualties are omitted, never set to zero to obtain no-deaths/flawless bonuses.

## 4. Save authority, stable identity and replay policy

These are deliberate proposed v1 rules for review:

1. Only a valid campaign association in the **loaded save** permits new capture. Only links actually present at the observed occurrence identify character participants. A companion receipt must not restore an old pairing or attach a newly linked character retroactively to past events.
2. Start tracking future gameplay when the reporting build is present. Initialize rank/wound/mission observations without emitting a baseline event, old promotions, historical mission victories or old wounds. A loaded in-progress mission can report a future completion only if its participation/result can be established; missing start/deployment events must not be invented.
3. Use the existing campaign identity (`BizAnalyticsCampaignID`) plus stable mission/covert occurrence identity. Do not generate new report IDs on every load, callback or retry. Prefer identifiers already saved before launch; verify mission IDs/seeds survive rewind. A site/action ObjectID alone is insufficient without creation/occurrence fingerprinting. Preserve group identity across direct multi-map mission transfers and finalize only once at the real end.
4. Derive short opaque `mission_ref`/`event_id` values from these logical keys (bounded to API limits), not display names, file-slot names, wall-clock timestamps or delivery attempts. Different real missions/actions must not collide. A replay of the same occurrence keeps the same identity, including if a save predates the first report capture.
5. Keep a save-side pending/seen ledger plus companion-side durable canonical records/receipts. An older save can lack local acknowledgement; the companion must recognize its prior report and return the existing result without re-awarding anything.
6. **First durable handoff fixes the report's factual payload.** Repeated capture of identical gameplay facts reuses the existing payload/occurrence timestamp, even if the later capture's local clock differs. A replay with changed outcome/participants is a visible conflict, not permission to mint another event ID or rewrite the original.
7. **Remote history is not rolled back with XCOM saves.** The first accepted completion remains authoritative for that mission in that Journey. A different replay outcome is held/conflicted, not submitted as another win. No automatic deletion, reversal, new instance or fresh Journey is used to evade this rule.
8. A durable companion handoff is the commitment to deliver that captured report. Closing XCOM or loading an older save does not silently retract its queued reports; already accepted submissions cannot be undone. Reports never handed off and absent from the restored save cannot be recovered magically. Explain this distinction in help/status text.
9. Copied campaign branches and concurrent XCOM processes are not independently awardable timelines in v1. Detect/preserve conflicts; do not claim general branch synchronization. Companion data loss/reinstallation can reduce local conflict diagnostics, but stable IDs plus backend uniqueness still prevent a second accepted completion. Never delete journals as an automatic repair.

Rank transitions are keyed by saved soldier/link identity and actual from/to rank/track, not the number of popup visits. Wounds and negative-condition acquisition/recovery have separate episode keys so another genuine future occurrence can be reported without duplicating a replay. New links establish observation baselines without reporting the link's own stat modifications or already-active native conditions as new injuries/recovery.

## 5. Capture -> durable queue -> API receipt

The pipeline has three distinct stages; none may be labelled as another:

1. **Captured in XCOM:** committed plain-data observation/pending record in a new versioned game-state object. It survives strategy/tactical transfer and save/load. It contains no credential, Actor, Screen, delegate or live template references.
2. **Queued in companion:** narrow localhost enqueue validates Journey/campaign/participants/size and atomically writes the canonical report to disk **before** acknowledging handoff. XCOM may compact the payload only after this acknowledgement; keep stable keys/receipt state for replay. A lost reply leads to the same enqueue, not a newly generated event.
3. **Accepted online:** background worker POSTs the immutable payload and validates/stores the acceptance receipt durably. `accepted` and `duplicate` both complete delivery. A lost HTTP reply leads to the exact same payload/ID. A socket handoff success is not online acceptance or evidence of XP.

Use one-event requests first and preserve dependency ordering per occurrence (start/deployment before completion, injury before corresponding recovery). One blocked occurrence must not stall all unrelated missions. No synchronous HTTPS or modal networking in a gameplay callback.

### Timestamp proof

`occurred_at` is a real-world timestamp, never the campaign's fictional calendar or the time of eventual network delivery. The SDK exposes `TimeStamp()`/`GetSystemTime`, but their timezone behavior is not documented sufficiently here. Before implementation, prove native output against the companion's local/UTC clock. If native output is local wall time, persist the captured components plus verified timezone metadata, and normalize once in the companion using rules for that date. Ambiguous/nonexistent DST times or untrusted clock shifts are held for diagnosis, not silently stamped as "now". Freeze the resulting timestamp at first durable handoff and preserve it on every retry. This proof is an implementation gate, not an excuse to backdate game years or bypass Journey lifecycle checks.

### Queue storage and bounds

- Endpoint/Journey/campaign-scoped companion files; identifiers are validated/hashed before becoming paths. Versioned records, atomic same-volume writes/replacement, flush-before-ack, recoverable receipt journal, integrity/semantic fingerprints and explicit damaged-file handling.
- Retain receipts when credentials are removed/replaced; never write bearer or development protection tokens into event records/logs/exports. Do not export raw files automatically.
- Stay within current protocol-2 65,536-byte frames. Proposed serialized ASCII enqueue budget: 48 KiB including escaped Unicode content. Validate the final envelope bytes, not only string length. No arbitrary HTTP forwarding.
- The existing companion reader requires ASCII frames. Encode non-ASCII JSON text as Unicode escapes on the UnrealScript sender; do not strip, corrupt or silently transliterate soldier names. Prove this through the actual UE sender as well as C# socket fixtures.
- Bound pending memory/save/disk growth. Proposed starting limits: 512 XCOM pending events / 8 MiB, 10,000 companion pending events / 128 MiB, subject to profiling before release. Compact handed-off payloads while retaining deduplication keys. At capacity, retain queued records, show reporting-full diagnostics and continue the game; do not delete old reports or claim unlimited losslessness. Receipt archive retention must preserve replay safety.

## 6. Network, credential and error rules

- New feature negotiation: retain protocol 2 and add `gameplay_events_version: 1`; propose companion 0.6.0 with matching mod. Missing feature support disables handoff with update guidance, not broken linking or a generic proxy fallback.
- Narrow operations: `events_enqueue`, `events_status`, `events_receipts`, `events_retry`. Require expected Journey/campaign binding; only the fixed supported event types/factual shape are accepted. Retry schedules only eligible stored records, never accepts a caller-provided URL or a replacement payload.
- Use the existing authenticated HTTPS client, certificate verification, redirect rejection, Windows vault and development-access configuration. No new scopes; use existing `events:write`. Journey lifecycle operations are separate and never automatic from a reporting error.
- Send only records matching the currently selected/validated credential's endpoint and Journey; recheck under the connection service's serialized guard so switching credentials cannot race delivery. Switching to another Journey pauses old records rather than relabeling/delivering them to the new Journey. Replacing a key for the same Journey can resume eligible reports.
- Retry network failures/timeouts/408/429/5xx with bounded exponential backoff and jitter; honor Retry-After and persist retry scheduling across restart. UI close/shutdown cancels safely; durable records remain.
- 401/403 pause for credential/permission action. New-event rejection because Upcoming/Finished pauses for explicit player lifecycle action; never start/reopen automatically. Exact retries of already accepted events can still be acknowledged by the API while Finished, so do not discard them merely because a cached context says Finished.
- 409 event/mission conflicts and 400/413/422 validation/context failures are visible held records, not blind retries, payload edits or fabricated new IDs. Preserve the original evidence. Unrelated valid occurrences may proceed.
- On corrupt queue files, keep/quarantine recoverably and show a stable diagnostic. Do not crash XCOM, silently erase records, log secrets or delete existing activation recovery receipts.

## 7. Class responsibilities and lifetime safety

Names below are proposed implementation names, not files already created:

| Area | Class | Responsibility |
|---|---|---|
| UnrealScript | `X2EventListener_TNBGameplay` | Stateless registration/callback routing for committed gameplay facts |
| UnrealScript | `TNB_EventCaptureService` | Before/after observations, mission/covert grouping and transition deduplication |
| UnrealScript | `TNB_SoldierConditionObserver` | Filtered committed native-condition/treatment deltas and scoped history-delegate lifecycle; no canonical Trait mutation or network work |
| UnrealScript | `TNB_EventFactory` | Bounded canonical capture records and API event construction inputs; no XP math |
| UnrealScript | `XComGameState_TNBEventLedger` | New versioned observation, occurrence and receipt-key records |
| UnrealScript | `XComGameState_TNBEventOutbox` | New versioned pending plain-data payloads and handoff state |
| UnrealScript | `TNB_EventPump` | World-owned asynchronous local transport; paced, bounded requests only |
| Companion | `EventContractValidator` | Strict allowlist/bounds/semantic/reference validation against contract fixtures |
| Companion | `EventOutbox` | Canonical records, atomic storage, conflict detection and receipt retention |
| Companion | `EventDeliveryWorker` | Pinned credential use, HTTP attempts, retry scheduling and validated receipt adoption |

Do not add world Actor/Screen references to DLC singleton state, template defaults or long-lived screen listeners. Locate a world's pump through world-local discovery; do not cache it globally. Clear completion delegates, stop timers and cancel transport on destruction/travel. No automatic popup or frame-by-frame roster/history traversal. Tests must include reloading without ever opening MCM, with/without companion, and while requests are pending. The newly stable reload path is a release gate.

Keep existing campaign/soldier associations, frozen bonuses, activation receipts and mapping config untouched. New ledger classes must initialize safely in older linked saves and survive transfer without rewriting old schema records. Presentation polls do not create gameplay events or game-state changes on every frame.

## 8. Player-visible status

Add a compact Reporting group to MCM and matching companion status: captured/not handed off, queued, retrying, paused/held, and last confirmed online acceptance. Counts must be scoped and labelled for the loaded campaign/active Journey; do not confuse another Journey's queue with the current campaign. Show a clear setup/update/mismatch message when appropriate.

Provide Refresh and Retry eligible reports. No modal errors interrupt combat. Viewing bonuses remains offline-readable, game play remains available, and closing the companion does not close XCOM. Explain that closing it pauses transfer/delivery and that already handed-off reports/history do not rewind with a save. Do not display "XP awarded" from a handoff receipt; the existing acceptance schema contains no XP balance/award amount.

## 9. Implementation sequence and gates

1. **Proof fixtures:** verify capture timestamps, actual start/end/transfer ordering, result/turn/roster access, covert parent-child identification, pending-state unit resolution, negative-condition active/pending/cured transitions and Infirmary completion, history-delegate ordering/teardown, and new-ledger transfer/save compatibility. No live API writes. If evidence contradicts a proposed hook, revise the capture seam before broad implementation.
2. **Pure contract/key tests:** fixtures for tactical/covert completion, commander-only participation and each character transition. Validate against current `SubmitJourneyEventV02Schema` plus `standardEventViolation`. Test role restrictions, unknown versus zero casualties, Unicode, bounded IDs/payloads and stable occurrence keys across pre-launch rewind.
3. **Companion durable queue:** fake API/vault/socket tests first. Prove flush-before-ack, restart/lost-reply recovery, exact duplicate acceptance, immutable conflict handling, credential switching/removal, per-occurrence ordering, retry timing, malformed receipts, disk-full/corrupt files and queue bounds. No new live fixture XP/events during these tests.
4. **Tactical vertical slice:** start/deployment/completion with saved observations and a world-safe asynchronous pump. Use a fake endpoint first. Compile with zero mod errors/warnings; verify no reward/link/mapping regression and no new world-reference leak.
5. **Covert actions and transitions:** add the verified hooks, ambush grouping, rank/wound episodes and temporary negative-condition acquisition/cure handling. Ensure a covert promotion and each physical/psychological transition are emitted once even if another listener/observer sees them. Do not wait for an Armory/menu visit to notice a committed rank change, active negative condition or Infirmary cure.
6. **Status/documentation/package:** integrate compact MCM/desktop status; keep names/branding consistent. Update dependencies, startup/testing instructions and validation records. Build self-contained companion, run hidden UI/regression tests, back up and hash-check source/SDK/game/artifact outputs before local install. No automatic GitHub publication.
7. **User-controlled real-game acceptance:** use the dedicated test Journey and separate saves. Start with one actual tactical mission, inspect portal history/XP once, then repeat view/reload/retry to prove no duplicate. Follow with ordinary covert action, promotion, wounds/recovery, negative-condition acquisition/Infirmary cure, and an ambush test where practical. Use controlled fake/native fixtures for rare conditions first; do not modify a real soldier or fabricate a death/condition without explicit user approval, or risk the only campaign save just to satisfy a test.

### Required automated cases

- Identical event after lost socket/HTTP response; accepted server-side then connection drops; companion restarts before reply/after durable write; game reload lacks acknowledgement.
- Pre-link -> linked -> pre-link; post-link -> post-link; changed outcome after an accepted completion; different linked participant after rewind; mission/site-ID reuse; copied campaign collision.
- Covert start/completion with no linked characters; unlinked casualties affect squad totals; staff slot removed at completion; promotion reward once; ambush delays parent completion; ambiguous parent holds rather than double-reports; direct tactical transfers do not invent another mission completion.
- Native negative conditions: pending-but-never-active produces no injury; active acquisition once; pre-existing baseline produces no backfill; future cure of baseline condition is allowed with honest missing acquisition provenance; multi-condition Infirmary cure produces one recovery per condition; treatment cancellation produces none; mission-based cure/replacement is not mislabeled as Infirmary or canonical Trait change; disabled mod/template is not a false cure; repeat callbacks, immediate save/reload and replay do not duplicate episodes. Physical wound healing cannot cure the psychological episode by accident, and vice versa.
- Old companion/API capabilities, malformed or oversized payload, different Journey credential, expired/revoked credential, Finished/Upcoming, throttling, offline operation, timezone/DST conversion and clock jumps.
- No silent loss on full/corrupt queue; no secret exposure; no long-lived references to an old world; no synchronous network dependency in game-state transactions; existing stat/ability/reward grants unchanged.

### Manual acceptance / definition of done

Reporting v1 is complete only after finalized tactical/covert events appear under the correct Journey/identities; real local rank/wound transitions are represented accurately; queue/retry state is truthful; identical retries/reloads do not duplicate history or XP; game/save stability remains intact; and known unsupported data/compatibility limits are documented. Unit tests or a visible Armory ability alone do not establish these passes.

Existing native economy/tactical ability checks continue separately. One successful mission does not prove every modded mission type, healing system, direct-transfer chain or covert-action overhaul. Unsupported seams must be clearly identified instead of silently guessed.

## 10. Source evidence checked for this plan

- API repo `D:/Projects/project-threadline`: `packages/contracts/src/common.ts`, `event.ts`; `apps/api/src/routes/events.ts`; `events/service.ts`, `events/repository.ts`; `growth/policy.ts`. Local main was clean when inspected. Event Contract v0.2, existing routes/limits/idempotency/lifecycle/XP behavior described above comes from these files.
- Installed Highlander `D:/Steam/steamapps/workshop/content/268500/1796402257/Src/XComGame/Classes`: `X2DownloadableContentInfo.uc`, `X2TacticalGameRuleset.uc` (`CleanupTacticalMission`), `XComGameStateContext_StrategyGameRule.uc` (`OnPostMission`, result/transfer/healing seams), `XComGameState_CovertAction.uc` (start/completion/ambush lookup), `XComGameState_Unit.uc` (`UnitRankUp`, `GetNumKills`, `UnitDied`), `XComGameStateContext_HeadquartersOrder.uc` (`UnitHealCompleted`), `XComGameState_BattleData.uc`, `XComGameState_Player.uc`.
- SDK `Core/Classes/Object.uc`: native system timestamp declarations (timezone behavior still requires proof). SDK `XComGame/Classes/XComGameState_CampaignSettings.uc`: persistent analytics campaign GUID.
- Negative-condition addition: installed Highlander `XComGameState_Unit.uc` (`AcquireTrait`, `AddAcquiredTrait`, `AcquirePendingTraits`, `RollForNegativeTrait`, `RecoverFromTraits`, `RecoverFromAllTraits`) and `XComGameStateContext_HeadquartersOrder.uc` (`CompleteRemoveTraits`); SDK `XComGameState_HeadquartersProjectRemoveTraits.uc`, `X2TraitTemplate.uc`, and `XComGameStateHistory.uc` (committed-history delegate registration/removal). The user supplied https://xcom.fandom.com/wiki/Negative_Traits for the intended feature; that page returned HTTP 402 to the browsing tool, so hook details here were verified against local source rather than attributed to the inaccessible wiki.
- Mod/companion: existing `TNB_CampaignService`, `TNB_Types`, `TNB_LoopbackClient`, activation recovery and localhost dispatch. These remain the binding/security/transport baseline, not evidence of already implemented event delivery.

## Review focus before implementation

Confirm the proposed single covert/ambush completion, first durable handoff/first accepted report replay rules, future-only capture, temporary native negative conditions as injury/recovery records without canonical Trait mutation, and no automatic lifecycle changes. Everything else follows the agreed companion architecture and existing event contract. Preparing this document grants no authority to submit synthetic events or alter real Journey history.
