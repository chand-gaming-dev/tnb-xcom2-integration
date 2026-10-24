# Promotion recovery and linking feedback - mod 0.9.3 / companion 0.10.4

Native acceptance remains required. This feature branch combines the Deja Vu
passive, public Production companion default, and the following focused fixes.
It does not change the approved mappings, canonical catalog, backend or Production
configuration. No main merge or public release is authorized by this test build.

## Promotion reporting

The native promotion Store path omitted `clock_zone` even when the campaign's
reporting ledger already held the companion-verified zone. The companion correctly
refused durable handoff with `event_clock_unverified`. Native tests previously
supplied the missing field in the C# fixture consumer, hiding the omission.

New captures copy the ledger's zone. On a safe reporting work tick, a narrowly
scoped repair can add that missing field to a saved, not-yet-handed-off promotion
capture. Held reports are eligible only under the known missing-metadata/invalid
diagnostics. The original report key, occurrence GUID, participants, rank facts
and captured local timestamp stay unchanged. A report with an existing zone,
acknowledged event ID, wrong event type or malformed rank transition is not repaired.
An unknown or changed ledger zone does not permit recovery. The companion still
performs its ordinary clock/contract validation; there is no validation bypass.

Repair uses the existing reporting safety gate and one ordinary pending state,
not a socket callback or a nested event submission. There is no new timer. A later
delivery retry is the same occurrence, not another XP award. Other held reports,
companion journals and backend events are not rewritten or silently discarded.

First test tomorrow: launch the companion normally (no `-Development`), then load
the **saved post-promotion game**. Remain on a quiet Avenger screen for reporting.
Both saved promotions should reach the portal without replaying the mission or
promoting again. Save after successful delivery. Reload that save: no extra entries.
The diagnostic build logs `PROMOTION_CLOCK_RECOVERY` with the recovery count.
If the save predates promotion, it cannot contain those later captures.

## Quick Learner recipients

After a new campaign association, an explicit result dialog lists the saved
soldier names and Combat Intelligence before -> after. The commander profile's
**Quick Learner** button reopens the same receipt, including in existing linked
saves. It does not reroll, reapply rewards, award AP or depend on current roster
membership. Recipients are the existing frozen `IntelligenceGrants` records; no
new save schema or bonus calculation is introduced.

Check the button on the current linked save. Use a pre-association save to test
the immediate dialog. Verify that the listed two soldiers match the saved benefit.

## Deja Vu before soldier linking

Only when MCM -> Linking bonuses -> automatic grant is enabled, the character
picker includes a Deja Vu information row/icon and the final confirmation explains
the local bonus and configured percentage. With automatic grant disabled, neither
preview is displayed and a new link gets no grant. Existing holders retain their
ability and profile card. An already-owned grant cannot stack; replacement full-XP
overhauls show the existing inactive-scope warning rather than promising a bonus.

Check enabled and disabled states on an unlinked soldier; canceling a confirmation
must apply nothing. Configured 0% is described as 0%, not silently changed to 5%.
Reopening existing links is not a retroactive Deja Vu grant.

## Automated coverage

SDK probes exercise production Store JSON with a host-zone fixture, narrow recovery,
no changes to original identity/time/facts, repeated recovery, conflicts, already
handed-off reports, unrelated types, Quick Learner frozen/escaped recipient text,
and enabled/disabled/custom-percentage Deja Vu previews. The companion's native
promotion fixture consumer now requires the emitted zone instead of inserting it.
Its queue checks reject the old omission and prove recovery is an exact retry.

These are synthetic/offline checks, not native campaign acceptance. No synthetic
events are sent to a real Journey to force a result. Installed user overrides,
saves, personal pools and credentials must be preserved during deployment.

Verification on 2026-10-23: all 12 SDK probes passed (zero compile errors/warnings),
as did all four companion suites. The published companion accepted three native
promotion fixtures with their emitted host zone, and recovered JSON was an exact
retry of the original capture. A forced clean gameplay build passed the focused
promotion, Deja Vu and presentation probes; the mapping probe's expected missing-
fixture result confirmed test defaults are absent from the gameplay package.

Clean mod script SHA-256:
`143B6AA04BACB5DE82A81D1F3F60394A418435247578E09390338A8FF9DC21C7`.
Private probe logs and installation backups remain ignored under `Artifacts/`.
