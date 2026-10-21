# Bond milestones — mod and companion 0.8.0

Bond formation and level increases now use the existing standard
`threadline.narrative.milestone_reached`, type version 1. No API/schema change is
needed. This records an XCOM fact for future Threadline interpretation; it does not
create a canonical relationship, alter Traits/Skills or choose an XP award.

## Captured facts

- Initial bond: `facts.milestone_key = xcom2.bond.formed`.
- Completed bond-level increase: `xcom2.bond.level_increased`.
- Public factual summary/label name the soldiers and resulting level. Private
  bounded `game_data` retains the native event, previous/resulting level, both
  local unit IDs/names and each applicable linked instance ID. Auxiliary details
  are retained in the raw report, not currently exposed in shared Portal history.
- One event describes the pair. Both current-Journey linked instances participate
  if available; with one linked soldier the other remains local partner detail.
  Neither linked: no report. No activation or invented Threadline identity occurs.

Native sources: installed `UISoldierBondConfirmScreen` fires `BondCreated` after
setting both level-1 bond records; SDK `XComGameState_HeadquartersProjectBondSoldiers`
fires `BondLevelUpComplete` after increasing both records and finishing training.
The listener adds its outbox/observation records to that same pending game state:
an abandoned transaction cannot leave a submitted report. No HTTP or recursive
game-state submission happens in the hook.

The before/after pair levels must agree and increase. Availability notifications,
starting/cancelling training, existing bonds on load/link, and duplicate callbacks
do not count. Pair ordering is stable; per-pair episodes distinguish a genuine
later re-bond from retries of an earlier formation. The source history index only
suppresses duplicate callbacks in one transaction; it is not the remote event ID.
Outbox identity/first durable facts and replay-conflict rules remain unchanged.

## Testing

1. Update **both** mod and companion to 0.8.0. Existing credentials, saves, reporting
   journals and frozen bonuses are retained. Start the companion and initialize
   MCM reporting's verified capture timezone before the first new bond transition.
2. Use a disposable test slot. Bring the linked soldier and an ordinary unlinked
   soldier to bond availability, then confirm the actual level-1 bond in the game
   UI. Availability alone should submit nothing; confirmation should produce one
   Milestone reached event with both names/level and only the linked participant.
3. Save/reload and refresh/retry: no second formation award/event. An existing
   bond loaded from an older save should not be backfilled as a new formation.
4. When eligible, start bond training: no milestone yet. On actual completion,
   expect one level-increased event with correct previous/new levels. Cancelling
   training produces none. Two linked bondmates should share one event/two instances.
5. Close the companion after initial clock setup and form/upgrade a bond. Save,
   restart the companion and verify capture → durable handoff → online acceptance.
   No history is erased by loading an old save. Preserve held/conflicting records.

Console caution: SDK `BondSoldiers "Full Name A" "Full Name B"` directly changes
bond level and **does not fire these hooks**. Do not use that default as proof of
capture. Its third argument `false` only raises cohesion; if used in a disposable
test, confirm through the real bond UI afterward. Names must match exactly: the
native cheat accesses a bondmate before its null checks, so a typo is unsafe.
Third-party code that changes bonds without firing the native events is currently
outside coverage; no claim of exhaustive historical/state-diff recovery is made.

The existing capture/outbox limits still apply; capacity/clock/credential failures
must be diagnosed, not repaired by deleting journals or rewriting event identities.
The additional bond-pair observation limit is 4,096 per local campaign. An old
companion lacks `bond_milestones_version=1`; the mod retains those reports and asks
for an update instead of sending them for permanent rejection. Unrelated compatible
reports remain eligible. No new protocol or existing feature number is required.

## Final review: event taxonomy (not capture deferral)

Bond milestones are implemented now. At the final product review, decide whether
to keep the generic milestone representation or introduce a dedicated factual
bond/relationship event. Preserve accepted milestone history, native levels and
pair identity; do not rewrite old events or infer canonical relationship strength.
Future interpretation and any XP policy remain separate server-side decisions.
