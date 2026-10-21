# Gameplay reporting: 0.6.0 test build

Current client pairing: mod UI patch **0.7.1** with **companion 0.7.0**. The original
reporting pipeline below is unchanged. Start with
[COMMANDER_UX_AND_MISSION_SMOKE_TEST.md](COMMANDER_UX_AND_MISSION_SMOKE_TEST.md)
for the approved UI follow-up and a console-assisted tactical completion smoke test.

This implements the approved v1 event pipeline against the existing Event Contract v0.2. It is not a claim that native-game acceptance has passed. No synthetic events, live XP grants, API/schema/migration changes, credential changes, or automatic GitHub publication accompany the build.

## First test: loading and reporting setup

1. Start companion 0.7.0 normally, using your existing development configuration and credential. Confirm the existing commander/Journey. There is no new credential requirement.
2. Load a linked **strategy** test save. Open MCM > The Name Beneath > Gameplay reporting. Wait a few seconds and Refresh reporting. The capture clock zone should be set, typically Eastern Standard Time on this machine. Existing ranks/wounds/conditions establish a baseline, not historical events.
3. Before completing any mission, reload the same save, then another linked save and an unlinked save in the same XCOM process. Repeat with the companion closed/restarted. The automatic Avenger linking invitation remains disabled. Report any crash or reporting diagnostic before continuing.
4. Capture the Reporting status and, if possible, Steam screenshots. The game log contains one `TNB_REPORTING_CLOCK_SAMPLE` per world; this lets us verify actual committed-frame timestamp format against the native system clock without logging credentials. Unknown clock/history formats are held, never replaced by delivery time.

These steps are the native observer/delegate teardown and immediate-save recovery gates. The SDK compiler and standalone fixtures cannot prove a retail campaign's world cleanup. An SDK commandlet cannot instantiate a full campaign History under its editor engine; that isolated experiment asserted, not the user's game. No conclusion about live history ordering or serialization is drawn from it.

## One real tactical mission next

Use the dedicated test Journey and separate saves. Keep a pre-mission save. Do not use the only copy of a campaign for acceptance.

1. Start a new tactical mission after reporting setup. Deploy at least one linked soldier when available; commander-only participation is also supported.
2. Finish and return to strategy. Allow the companion to drain reports. MCM shows **this loaded campaign/Journey**; the desktop summarizes **all campaigns in the active Journey**.
3. Inspect Threadline history: one mission start, one deployment event for the linked roster (none for an empty linked roster), and one mission completion. Standard mission completion is v2; the backend decides XP. Confirm actual names/instances and outcome. The receipt has no XP amount, so an acceptance count is not a displayed XP award.
4. Save, reload, reopen status/Armory, and Retry eligible reports. History/XP must not duplicate. Check linked -> linked -> unlinked -> linked loading again with requests active.
5. Test offline handoff separately: close the companion during gameplay, save the captured events, reopen the companion, and let it transfer. For HTTPS-offline testing, distinguish a running local companion with queued records from an absent companion with save-side captures.
6. Replaying a previously handed-off occurrence with different facts must be visibly held/conflicted, not become another accepted victory. Do not expect loading an old save to undo accepted events or queued companion reports.

An in-progress tactical mission or covert action begun before this build may lack an authoritative frozen roster/start. It is diagnosed rather than backfilled. Test a newly launched occurrence first.

## Follow-up native checks

- Covert action: one ordinary mission sequence, frozen assigned linked roster, genuine promotion reward once. An ambush delays parent completion and is supporting metadata, not a second mission award. Ambiguous/missing parent evidence is held. Modded concurrent actions, unusual mission sources and extra ambush units need explicit coverage.
- Physical injury: newly finalized strategic wounds once, full native healing once, injury reference when known, no fatigue tick/equipment/link-time HP changes masquerading as wounds. Check an unlinked casualty's effect on verified whole-squad totals too.
- Actual promotion: rank changes, not eligibility/popups. Cover Armory and covert-action promotion paths.
- Temporary negative soldier condition: pending-only gives no injury; committed active acquisition gives one `xcom2_negative_trait` injury; each actual cure gives a recovery. Infirmary enrollment/cancellation gives none. Baseline conditions produce no past acquisition, but a future verified cure can be reported without inventing that acquisition.
- Infirmary: immediately save after the actual cure, reload, and check one recovery per cured condition. The saved native history checkpoint is intended to recover a notification before the next pump tick; this requires retail-game proof. Also test multi-condition cure and native mission-based recovery/positive replacement. Local replacements are metadata only, not canonical Trait edits.
- Final death/capture: use a disposable test scenario only with explicit player approval. Tactical apparent death is not submitted immediately. Captured soldiers remain capture metadata, not death events. Do not manufacture a death/condition in a real campaign just to satisfy a check.

## Status and recovery rules

- **Captured in this save** means not durably handed off; it can be lost by loading a save that predates it. Local held records remain in that count and carry a diagnostic.
- **Queued/retrying** means the companion committed an immutable report to its endpoint-scoped journal. It continues delivery even if XCOM closes or an older save is loaded.
- **Accepted online** means a matching accepted/duplicate API receipt was validated and saved. The first durable factual payload/timestamp is reused across identical recaptures and retries.
- **Paused** requires credential/permission or explicit lifecycle action. Retry eligible after resolving it. Reporting never starts, finishes or reopens a Journey automatically.
- **Held/conflict** requires diagnosis. Retry does not rewrite payloads, generate another ID or blindly resend permanently rejected/conflicting records. A blocked occurrence does not block unrelated mission groups.
- Switching to another Journey pauses the old queue; switching back/rotating a valid key for the same Journey resumes eligible records. Removing credentials retains journals and receipts.
- The desktop's damaged-file/replay-conflict diagnostics are endpoint-wide and explicitly labeled, not falsely attributed to the selected campaign.

Do not delete `events-v1`, activation receipts, saved link records, or credentials to troubleshoot duplicates. Preserve evidence for review. Local journal files are nonsecret but still contain gameplay information; do not publish them automatically.

## Clock and limits

SDK `GetSystemTime`/`TimeStamp()` were verified to return Windows local time, not UTC. The companion handshake records the Windows timezone ID in the save, and the native committed-frame clock must also match a live system-clock sample before history transitions are enabled. Enqueue verifies the sender's current clock and normalizes captured local components using that timezone's date-specific rules. Missing setup, changed Windows timezone, invalid/ambiguous DST and future clock values are diagnosed/held. A timezone change requires review; old evidence is not silently reinterpreted in the new zone. Preserve the first canonical timestamp after handoff. The portal's Journey active intervals still govern acceptance.

Limits: protocol 2, gameplay feature 1; 65,536-byte transport maximum with a 48-KiB ASCII enqueue budget; 512 save-side reports / 8 MiB serialized ASCII capture content; 10,000 pending companion records / 128 MiB serialized pending records. Accepted receipts/payloads are retained for replay protection, with a 100,000-record archive cap; up to 1,000 distinct conflict records are retained. Capacity rejects new handoffs visibly and never discards existing records. Capture overflow can prevent recording a new event; this is not an unlimited-losslessness guarantee.

History catch-up examines at most 256 committed frames per work tick, triggered by notifications/load, with no HTTP or recursive SubmitGameState in the callback. Unknown/archived-away history or a reset history index is diagnosed; it is not reconstructed using fabricated times. Native save/transfer/observer performance remains an acceptance gate.

No per-hit/miss stream, guessed mission-local kills/damage/highest shot, unproven turn counts or duration is submitted. Unknown covert casualty totals are omitted. Direct tactical transfers retain the logical mission and do not independently complete it; verify the actual multi-map campaign path before declaring compatibility.

## Deferred, unchanged work

Journey names and graphical soldier/commander reports are implemented in the current
client. The optional Avenger invitation remains disabled/deferred. Resource
interceptors/Scrounger already exist and still need their separate native economy
checks. Mapping revision remains `tnb-alpha-2026-10-19-r2`, including optional
`SingleReloadMrC` and Workshop provenance comments. No extra perk mod is installed.
