# Mission-attempt reporting - mod 0.8.3 / companion 0.8.0

## Approved behavior

- A new tactical launch is a new mission attempt, even for an unchanged generated
  XCOM mission loaded from the same pre-mission save. Normal server-side XP rules
  apply; this non-verified integration does not suppress rewards for genuine replays.
- Tactical save reload, continuation to another tactical map and delivery retries
  continue the saved attempt. They do not mint replacement event/mission references.
- Contradictory facts for ONE attempt still conflict. Accepted facts remain immutable.
  Different attempts may report failure then success without overwriting either.
- A generated mission in a strategy save needs no regeneration or extra native fields.
  Launch metadata lives on the mod's ledger. No native mission-site/battle data changes.

This replaces the old mission-site-level rejection policy for NEW launches. It does
not remove already recorded failures, modify credentials, migrate accepted reports,
delete journals/receipts or create synthetic events. No API/schema/permission changes.
Companion 0.8.0 remains installed and compatible with optional game_data metadata.

## Implementation and compatibility

Installed Highlander CreateDefaultTacticalStartState_Singleplayer creates a fresh
BattleData.BizAnalyticsMissionID using GetGUID on every new launch. OnPreMission
already receives that start state after the saved mission site has been selected.
We READ that launch ID, normalize its 128-bit ASCII representation, and copy it into
a new plain-data TacticalMissionAttempt record on our ledger. Its occurrence key is
`tactical-attempt:<normalized-launch-id>`. Original site/source/timer/map-seed key is
retained only as context in `game_data.mission_source_key`; all three reports also
include `mission_attempt_id`. Only the event's existing key/mission_ref machinery is
used; companion transport, hashing, queue isolation and API contracts are unchanged.

The attempt is resolved only in PrepareMission for a supplied fresh tactical-start
context. Repeated invocation for that same launch is idempotent. Invalid/missing
launch IDs or conflicting/capacity-limited metadata diagnose and omit unsupported
capture; they never fall back to a stale previous attempt or block gameplay. Registry
is capped at 4096 entries. No seeded Rand, timestamp guess, localhost call or separate
history submission is needed to establish identity. Game rules own the transaction.

Start/deployed/completed use the same saved MissionObservation.Key. Existing injury
snapshots follow that key too. Tactical load and multi-map transfer never resolve a
new attempt; they carry saved ledger/current-key state. An older in-progress save
without attempt metadata retains its OLD key and exact old payload, not a new GUID
or added legacy flag. Existing pending CaptureJSON is not rewritten. Missing old
participation data is still unknown, not fabricated historical start/deployment.

Soldier promotion/wound/recovery/condition, bond and covert-action occurrence keys
are deliberately unchanged. This release changes tactical mission start, deployment
and completion identity only, not the entire campaign timeline. A repeated individual
transition may still deduplicate/conflict under its original rules. Ambush remains
part of its parent covert action rather than a second ordinary mission award.

The 0.8.1 loading/history allocation guard and 0.8.2 native promotion, gap recovery
and frozen all-squad wound fixes are unchanged. Existing structs are unchanged; only
a new plain-data attempt struct/ledger array are added. No Actors/templates/delegates
or credentials are saved in the registry, and linking/bonuses/UI are untouched.

## Manual test

1. Preserve the pre-mission and earlier post-promotion saves. Start the existing
   companion, then XCOM with mod 0.8.3. No new Journey/campaign/relinking is needed.
2. Load the pre-mission strategy save and launch Operation Hammer Prince. It should
   load normally and create a NEW start/deployment pair despite the old accepted
   failure. Logs include MISSION_ATTEMPT prepared new=1 and a short attempt marker.
3. If practical, save in a separate early tactical slot and reload it. The attempt
   should stay the same with no second start/deployment pair. This is the actual
   retail serialization/continuation check; offline array-copy tests do not prove it.
4. Complete the mission (keep the VIP alive if desired), return normally and promote
   Chand. The new completion should be accepted alongside the old failure. It should
   NOT conflict solely because it is the same mission site. Native UnitRankUp event
   and all-squad injury totals still need the earlier 0.8.2 manual acceptance checks.
5. If replaying from the pre-launch save again later, a NEW attempt is expected.
   Loading an existing mid-mission save remains that attempt; contradictory outcomes
   from replaying that tactical checkpoint can still conflict. Full Record game_data
   can distinguish attempt IDs while original mission_source_key remains the same.
6. Old 0.8.2-or-earlier tactical saves continue their legacy reporting identity. Do
   not expect a post-promotion load to retroactively emit the previously missed rank
   event, nor an already accepted legacy failure to be rewritten. No journal repair.

Current promotion/instant-recovery tests can be combined with this run. In particular,
the Templar's native mission wound should count even if recovery duration becomes
zero. That does not create an individual report for an unlinked soldier.

## Automated proof and limits

Compile, pure native identity/metadata/legacy tests, production JSON fixtures, unchanged
companion builder/outbox replay/restart/ordering tests and shared contract checks are
recorded under Validation/mission-attempts-*. Actual retail launch GUID persistence,
same-session tactical reload, transfer and event callbacks remain manual gates.
No live reports or XP were generated by these tests.

A trial that constructed X2FiraxisLiveClient directly in the SDK commandlet host
crashed that test process. That unsupported setup was removed from the final probe;
the mod runtime never constructs/calls that client. Production only reads battle
data already generated by the game. Final probes use explicit GUID fixtures; they
do not claim to test the game's GUID generator or full native save/load lifecycle.
