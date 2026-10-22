# Promotion occurrences and previously credited XP

Mod **0.9.2**, companion **0.10.3** unchanged. A compatible TNB backend/portal
must have Journey-local promotion XP recognition deployed before a live replay
test; an older backend can still award XP per newly accepted promotion event.
No new credential, scope, request field, endpoint or client XP setting is required.
This change does not deploy or modify the backend.

## Behavior and compatibility

- A genuine newly observed rank increase receives one platform-generated GUID in
  the existing pending capture transaction. It does not use gameplay randomness.
  The key and report are saved together; the native listener and history observer
  share the saved rank high-water mark to avoid a second capture for the same
  observed increase. No independent history submission was added.
- A post-promotion save reload or network/credential retry reuses the saved report
  and exact event ID. A real promotion replayed from a pre-promotion save receives
  a new occurrence ID. Loading, linking, promotion eligibility and buying an
  ability are not themselves promotion occurrences; old ranks are not backfilled.
- Existing queued/accepted reports retain their original keys, payloads and
  receipts. They are not converted to the new key format or automatically resent
  as new occurrences. New format: the old soldier/transition prefix plus
  `:occurrence:<GUID>`. The existing Journey/campaign/key hash still forms the
  transport event ID; no companion journal or saved-state schema changes.
- Factual payload remains `threadline.character.promoted`, `type_version=1`,
  `from_rank`/`to_rank` as canonical decimal strings and
  `promotion_track=xcom2_soldier_rank`, with exactly one linked Character subject
  in role `promoted`. No client-authored XP, suppression reason or replay flag.
- The compatible server awards positive promotion XP once per canonical Character,
  Journey, ordinary XCOM track and target rank. A replay is a new accepted journal
  entry, possibly **0 XP** with **Previously credited in this Journey**. A higher
  rank, different Character or different Journey is independently eligible.
- Recognition currently covers strictly increasing numeric transitions from 0-6
  to 1-7. Extended/modded ranks, other tracks and differently formatted ranks keep
  the backend's existing event-based award behavior. The mod does not guess
  equivalence, alter rank numbers or promise suppression outside this subset.
- `201 accepted` means a newly stored event, not an XP award. `200 duplicate`
  acknowledges the same old event. XP/reasons are history data, not ingestion
  receipt fields. The existing companion runtime already handles both correctly.
- Mission attempts/references, deployment/completion policy, injuries/conditions,
  bonds, captivity, links/grants/mappings and automatic invitations are unchanged.

## Focused retail test

Use separate non-Ironman slots. Preserve the pre-promotion save. Do not delete
journals, clear accepted events or use linking/refresh to manufacture a promotion.

1. With the new backend deployed, load a linked save from before an actual rank
   increase. Perform the promotion normally (the in-game promotion action, not
   merely the after-action PROMOTE/eligibility label). For Chand's already-credited
   first rank in the existing Journey, expect a **new** promotion entry with
   **0 XP** and the previously-credited explanation. No mission replay is needed
   if an eligible pre-promotion Avenger save is available.
2. Save AFTER the promotion, refresh history, reload that saved game and revisit
   the soldier. No extra promotion entry. Restarting the companion must not create
   one either; do not expect ingestion receipts to show XP.
3. Load the BEFORE-promotion save again and actually promote again. Expect another
   new occurrence ID/timestamp with 0 XP and the explanation. A simple refresh,
   reconnect or delivery retry must not do this.
4. Reach the next ordinary rank for the first time in this Journey. Expect a new
   event and the server's normal promotion award (default 25 XP), not a permanent
   per-Character promotion ban. Replay that rank: a new 0-XP occurrence.
5. Optional offline delivery: stop the companion, perform a real promotion and
   save AFTER it. Restart the companion and let reporting drain. Exactly one new
   occurrence should arrive. Reload the AFTER save and reconnect: still one.
6. Confirm ordinary Avenger navigation, automatic invitation dismissal/linking,
   save reload and mission transitions still behave normally. Already queued old
   reports should drain with their old IDs, not be rewritten.

Native probes use supplied GUIDs and plain saved records; they do not establish
real platform GUID generation or retail save/load acceptance. Companion synthetic
tests validate queue, receipt and retry compatibility, not the server's XP policy.
No live API events or private player journals are used in those tests.

## Offline validation record

- WOTC SDK compile: zero errors and warnings. All nine native commandlets passed,
  including same-rank replay/new-rank keys, duplicate-hook and post-promotion guards,
  invalid GUID/capacity failure without rank advancement and untouched legacy reports.
- Companion build: zero errors and warnings. General connection/lifecycle/title,
  isolated synthetic Windows vault, pool and event suites passed. The event suite
  consumed all three new native promotion occurrences and checked exact durable
  retries, restart, primary participant attribution, receipt compatibility, legacy
  immutability and rejection of client-supplied XP. Companion runtime unchanged.
- All 26 generated fixtures passed the actual current API v0.2 TypeBox schemas
  and standard-event semantic validation. The three native promotion occurrences
  also passed the real backend recognition helper: distinct occurrence IDs, same
  recognition key for repeated rank 1 and a different key for rank 2. No server
  award/database behavior was simulated as proof of live XP acceptance.
- Initial sandbox-only general self-test could not use Windows Credential Manager;
  its isolated `.invalid` fixture passed outside the sandbox and was removed by the
  test. Initial sandbox TypeScript validation could not query Windows user info;
  the same local validator passed outside the sandbox. No player credential was read.

Retail acceptance of this build remains pending; follow the focused checklist above.
