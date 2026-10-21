# Covert outcomes and Scrounger stacking - mod 0.8.6

Companion remains 0.8.0. No relink, new credential, new dependency, API deployment,
balance change, native mission mutation or save migration is needed.

## Scope and compatibility

- Scrounger calls native `PutItemInInventory` in the existing monthly transaction.
  Matching unmodified items stack; unique/modified items retain native behavior.
  Existing separate rows are NOT automatically merged. No existing item is removed
  or regranted; the monthly guard and popup queue are unchanged.
- Covert completion reads the native action's risk results. The three installed
  LWOTC failure risks (Easy/Moderate/Hard) with `bOccurs` mean failure. Native
  reward-granted completion remains success. Reward withholding alone remains
  unknown, not guessed as failure. An already-associated failed child ambush can
  establish failure when LW risk evidence and withheld rewards agree. No LW helper
  or global last-ambush tracker is called/created; no hard LW dependency is added.
- Completion remains in the supplied native event transaction. Completed records
  return early; existing outbox keys/dedup and frozen participant roster are kept.
  Only this observer's unknown-result diagnostic can be cleared upon resolution.
  There is no historical scan/backfill of completed actions from before this build.
- New mod descriptions say "XCOM covert action started/completed" and distinguish
  soldier assignment. Standard event types, outcome schema, identities and server
  XP policy stay unchanged. Accepted records and queued old payloads stay immutable.
- Portal card headings intentionally retain "Mission succeeded/failed" across
  games, per final user decision. The XCOM description distinguishes covert
  actions. No separate API/contracts/portal label change is needed.
- Automatic Journey invitation remains disabled. Research warning screenshot
  `20261020160928_1.jpg` is a UX reference only, not proof of safe load-time timing.

## Focused retail acceptance

1. Retain pre-month-end and pre-covert-completion saves in separate slots. Do not
   overwrite the only campaign copy, clear receipts, or delete delivery journals.
2. From before an LWOTC failed action completes, allow failure again. Check XCOM's
   report and portal completion agree on failure for the correct linked soldier
   and commander. A failed action is not guaranteed on replay; do not change the
   real API outcome or force XP. Save before dismissing if convenient.
3. Complete a successful linked covert action; confirm success still arrives.
   New description says covert action, but the old generic portal heading remains.
4. Reload a post-completion save and allow delivery retries: no duplicate
   completion or changed outcome. No need to replay a tactical mission.
5. For stacking, let Scrounger award an ordinary item for which you already own
   the same template/quality. The existing stack should increase by one rather
   than gain a new row. A different random reward is not a failed stacking test.
   If two old rows already exist, native acquisition merges into a matching row;
   it does not consolidate all old rows. Verify the TOTAL increases by exactly one.
6. Reload the post-award save: no extra item and no repeat grant. Unique/modified
   items should remain distinct according to the game's own rules.

## Retail acceptance updates (October 20)

- 0.8.6 failed Combat Preparedness was accepted with failure, the standard +15 XP
  shown by the portal and the new covert-action wording. Success reporting passed.
- Console-adding one of each of the eight Scrounger pool items made the next award
  a guaranteed duplicate; user confirmed it stacked correctly. This tests the
  native inventory path, not a separate implementation from naturally looted items.
  On 0.8.7, user additionally confirmed a naturally awarded duplicate increased
  the existing quantity of 1 correctly. Stacking acceptance is CLOSED: both the
  controlled and natural duplicate paths passed. No further targeted rerolls needed.

## Already confirmed before this patch (October 20)

- 0.8.5 clean Laser Sight popup and supply collection receipt 86 + 4 = 90,
  matching map flyover +90. Native base preview remains 86 by design.
- User reports reload test without duplicate grants/events passed.
- Successful linked covert action start/deployment/completion were accepted.
- With companion closed, a complete successful covert action remained absent
  remotely; after restart all three distinct events were accepted. Journal keys
  and screenshot `20261020163504_1.jpg` match Rescue Advent Defector.
- Failed Manufacture Upgrade screenshot `20261020162711_1.jpg` showed failure,
  while only start/deployment reached the companion. Old code explicitly held
  reward-suppressed results as unknown; 0.8.6 handles the known LW failure risks.
- Laser Sight inventory screenshot `20261020162228_1.jpg` showed separate rows,
  not an extra award. Old Scrounger code bypassed native stacking.

Offline regression probes exercise production classification/summary/JSON helpers
and outbox dedup; fake-server companion checks exercise unchanged builder/journal
and retry policy. They do not prove native callback ordering, actual item stacking,
save serialization or live failure delivery. Those remain the retail checks above.

Injury/recovery, negative-condition treatment, actual bond formation/level increase,
new skill refresh, death/capture, negative resource modifiers and native ambush
edge cases can be observed during ordinary campaign play. Increased cohesion alone
does not imply a bond milestone.
