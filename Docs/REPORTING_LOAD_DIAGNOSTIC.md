# Reporting/mission-load diagnostic - mod 0.8.1, companion 0.8.0

## Evidence and scope

On October 20, mission launch crashed in both a fresh soldier-linked campaign
and the commander-only association control. Soldier rank and ability injection
are therefore not required to reproduce the failure. The latest log reaches
CreateTacticalGame/map generation/unit initialization, but has no script stack
identifying this mod. Numerous asset NetIndex errors also occur before linking;
they are not by themselves proof of a responsible asset or mod.

Source inspection found an unsafe possibility: TNB_EventPump's repeating one-second
worker could allocate/submit reporting bookkeeping as soon as a ruleset existed,
including during tactical creation and load. The native ruleset explicitly locks
history during these phases. This is a candidate cause, not a confirmed diagnosis.

## Diagnostic change

- Fail closed before all background work and each state allocation when the world
  is not active/started, travel/map change is pending, history differs, rules are
  missing/loading/building a latent submission, or the top history frame is still
  a start state. Respect AddNewStatesAllowed after initialization checks.
- Tactical background work additionally requires TacticalGameIsInPlay AND a live
  TurnPhase_* ruleset phase. In-play alone is insufficient: native load sets that
  flag before the load's history lock is released. Creation, load, post-creation,
  challenge initialization, replay, teardown and unknown phases remain deferred.
- Defer baseline, clock-zone, observations, handoff acknowledgements, held-report
  writes AND socket work together. Replies wait in memory without acknowledgement
  changes while paused; durable companion retries retain existing keys.
- Initializing an existing ledger with no missing linked-soldier baselines does
  not allocate/submit an empty baseline update. A genuinely missing ledger still
  gets created in safe play, even for a commander-only campaign.
- Background submissions are synchronous after guarded allocation/edit, with no
  latent wait or network operation between them. Refused submissions do not mark
  initialization complete, discard dirty observations, or consume pending replies.
- History callbacks remain notification-only; when loading they only record the
  clock sample/dirty flag, without component lookups or history scans. Existing
  per-world ownership, delegate removal, timer and socket teardown are preserved.
- Native mission/covert/bond/injury callbacks still append to the transaction
  provided by the game. They must not be gated by background readiness or mission
  start/cleanup facts would be lost. This patch adds entry/exit logging to tactical
  hooks; it does not redesign capture, grants, transfer or event payloads.

Companion stays 0.8.0. No credential changes, XP grants, remote Journey transitions,
API changes, mapping/grant changes, save migrations, save repair or journal deletion.
The approved commander/soldier UI and disabled automatic prompt are unchanged.

## Log markers

Search Launch.log for `TNB_REPORT`. Markers include build 0.8.1, PUMP_START,
PUMP_DEFERRED with a reason, PUMP_RESUMED, PUMP_DESTROY, BASELINES_UNCHANGED,
CREATE_BEGIN/END, SUBMIT_BEGIN/END with operation and acceptance, PRE_MISSION
carry/preparation boundaries, LOAD_STRATEGY/TACTICAL, tactical begin-play/cleanup
and transfer/post-mission boundaries. Context includes world/ruleset phase,
loading/latent/in-play flags, history index and pending object count. Deferred
messages appear on reason changes and at most once per 30 seconds per stable
reason, not every timer tick. Submission markers bracket every actual background
bookkeeping write. No credentials, event JSON, soldier names or Journey IDs are logged.

Expected: no CREATE/SUBMIT reporting markers during tactical initialization or
load. The worker resumes only after native startup reaches live turn phases.
Engine-owned transactions may still produce legitimate mission-hook log entries
during initialization; those are not independent background submissions.

## Controlled retail test (still required)

1. Retain separate pre-link and linked save slots. Start the companion and XCOM
   freshly; do not create another campaign or delete links/journals.
2. Load the same fresh-campaign commander-only linked strategy save and launch
   the same mission. If that association was not saved, load the pre-link slot
   and reconnect through MCM, with no soldier links, then launch.
3. Report whether terrain, units and normal tactical controls load. If it crashes
   or produces the old void/sky symptom, stop and preserve the newest log/crash
   folder for analysis. Do not continue permutations or claim success based on
   compiling. Review the hook boundaries and the last CREATE/SUBMIT pair.
4. If it loads, use a fresh game process to repeat from a soldier-linked save
   (or link one soldier in the pre-link timeline). An unpromoted rookie should
   be supported; promoted/rookie isolation is only needed if this case still fails.
5. Once launch is stable, smoke-test a completion through normal debrief/Avenger
   return and inspect reporting status/portal. Auto-win is fine for transport
   smoke testing, but does not validate ordinary wounds, promotions or bond events.
6. Separately verify tactical save loading and strategy save reloads. Logs should
   show deferral during loads, resumption afterward and no repeat gameplay grants.

Automated checks can verify pure gate policy, no-op baseline policy, compilation,
unchanged gameplay files and event regressions. SDK fixtures do not reproduce a
retail campaign's native locks, actor travel or the crash. Runtime acceptance is
not established until these tests pass.
