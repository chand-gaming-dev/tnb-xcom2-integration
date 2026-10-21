# Promotion and mission-wound test - mod 0.8.2 / companion 0.8.0

## Evidence from October 20

- Both commander-only and linked-rookie missions loaded with the 0.8.1 guard.
  Logs show background work deferred through create/post-create and resumed in
  TurnPhase_UnitActions. The user completed an ordinary mission without cheats,
  returned to the Avenger and promoted Chand; no mission-transition crash occurred.
- Steam screenshots 20261020101300_1 through 20261020101433_1 show Operation Hammer
  Prince failure, the VIP killed, five returning Active squad members, Chand's
  first mission/one kill, Rookie-to-Squaddie Quartermaster promotion and Low Profile.
- Summary 1 wounded is the unlinked Templar hit for 1 damage, whose modded ability
  reduced recovery to zero; 1 killed is the VIP. Correct deployed-squad counts are
  1 injury/0 deaths. No individual Threadline event is attributed to the unlinked
  Templar. Being Active after return is not proof of never having been wounded.
- The existing accepted report incorrectly contains 0 squad injuries/0 deaths;
  its failure result is correct. The companion has no queued/held/accepted promotion.
  MCM screenshot 20261020102456_1 shows observation_history_unavailable, zero local
  reports/companion backlog, verified clock and four accepted Journey reports.

## Changes

1. Immediate UnitRankUp captures actual native before/after rank in the supplied
   transaction, only for a soldier already linked to this campaign/Journey/commander.
   Newly created/reward units, mere eligibility, class/ability selection without a
   rank increase, unlinked units and rank decreases are not new promotion events.
   Existing unit/instance/from/to occurrence keys and payloads are retained; intent
   tokens and volatile history indices are not new award namespaces. Accepted queue
   state advances only after capture succeeds. Observer fallback uses the same helper
   and a per-link rank high-water mark so older retained frames cannot re-emit ranks.
2. Missing/reset history no longer permanently stops inspection. During a safe work
   tick, rebaseline scoped current soldiers and advance to the current head, emitting
   NO inferred acquisition/recovery/promotion/death events for the unobserved interval.
   Preserve wound/condition counters, mark episode continuity unknown and drop causal
   injury refs across the gap. Pending outbox and SeenKeys remain untouched. A separate
   saved HistoryDiagnostic/gap count stays visible in MCM, alongside other errors.
   This intentionally sacrifices reconstruction across the lost interval; it does not
   claim to recover all past transitions. Already-missed promotions are not backfilled
   merely by loading a post-promotion save. Future native rank-up remains independent.
3. During native CleanupTacticalMission (before transfer/recovery), freeze
   WasInjuredOnMission counts over the saved deployed-soldier roster, linked or not.
   VIPs/ghosts/nondeployed units are excluded. PostMission uses this snapshot, not
   strategy IsInjured/recovery time. Squad deaths keep finalized deployed-roster
   semantics; a VIP death remains a mission failure, not a soldier death. Missing
   legacy/partial snapshots omit unknown totals, not a false zero/flawless assertion.

Native handlers only append to the transaction supplied by XCOM. They do not create
their own history submissions, call HTTP, change ranks/grants or calculate XP.
Background reporting retains the exact 0.8.1 allocation/loading/latent/travel guards
and actor/delegate/socket lifetime. Companion 0.8.0 is unchanged. Existing saved
structs remain intact; new ledger fields and a new plain-data injury snapshot default
empty on old saves. No saved links/mappings or character/commander bonuses are changed.

## Replay warning

Superseded for fresh launches by mod 0.8.3: each new launch now has a separate
attempt identity. A successful replay can be accepted alongside the old failure.
The warning below remains true for contradictory reports using the same attempt
or preserved legacy tactical identity. See MISSION_ATTEMPTS_TESTING.md.

Reloading before Operation Hammer Prince does not remove its accepted failure.
If the same mission identity is replayed with success or corrected casualties,
the new facts conflict with the already accepted original. The mod/companion must
retain that conflict rather than overwrite facts, delete receipts or mint an ID to
award a second attempt. Native promotion is a separate occurrence without that
mission reference and can still be tested/delivered. No remote API/admin changes
or real journal edits are part of this fix. For a clean future end-to-end portal
history, use a fresh campaign/Journey, not deletion of evidence.

## Manual acceptance

1. Preserve separate pre-mission and post-promotion saves. Start companion 0.8.0 and
   XCOM fresh with mod 0.8.2. No re-linking or credentials change is needed.
2. It is fine to replay the pre-mission save for the campaign. Keep the VIP alive
   if desired. Verify mission load/play/return remain stable; the companion can stay
   open. Do not treat a held changed-result replay as a new transmission regression.
3. When Chand actually ranks up, look for `TNB_REPORT PROMOTION source=UnitRankUp`
   and captured=True. Verify one character.promoted event with from_rank=0/to_rank=1
   for the correct instance, regardless of when class/ability UI is opened. Reopen
   screens/reload an already-promoted save: no new event or repeated bonus.
4. A history gap may show HISTORY_GAP_REBASE in logs and a warning in MCM. Confirm
   future rank/condition observations continue; the warning documents omitted history
   rather than an active permanent block. No speculative retroactive event is expected.
5. Verify MISSION_INJURIES logs roster count and frozen injury count at cleanup. On a
   new mission identity, one hit followed by zero recovery time must still produce
   squad_injuries=1, even for an unlinked soldier; no unlinked individual event. Mission
   deaths exclude VIPs. For the replayed mission inspect local capture/log evidence,
   not the immutable old remote completion, to validate the corrected count.
6. Distinct normal wounds, infirmary negative conditions, covert actions and real
   bond callbacks still require separate acceptance. Automated fixtures are not
   retail actor/history/save proofs or evidence of actual online XP award behavior.

New log markers: PROMOTION (source/from/to/captured), MISSION_INJURIES
(known/roster/injured), HISTORY_GAP_REBASE (reason/cursor/head/count). Existing
CREATE/SUBMIT and loading defer/resume markers are retained. No credentials,
canonical participant IDs, event bodies or soldier names are newly logged.
