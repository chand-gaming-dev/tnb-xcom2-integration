# Command-menu Journey access - mod 0.9.6

Branch: `feature/command-menu-journey`. Companion 0.10.4 is unchanged. This is a
development update, not a new Workshop publication or companion release. Do not
merge or publish until the Product Owner confirms native acceptance.

## Change

- One **The Name Beneath** entry in the Avenger's **Command** submenu.
- Linked campaign: opens the existing saved Commander & Bonuses profile, including
  Journey details and Quick Learner recipients; saved content is readable offline.
- Unlinked campaign: opens existing Journey preview/confirmation. No Journey start,
  association or reward occurs merely from registering or opening the menu.
- MCM no longer links campaigns or opens commander profiles. It retains status,
  reporting controls, reminder preferences and the Deja Vu slider. Its visible help,
  the Armory's unlinked instructions and the invitation point to Command.
- MCM's first two rows combine Companion status/Refresh and Journey status/Test.
  The Deja Vu slider is the next setting group; campaign preferences follow.
  Detailed connection metadata and reporting diagnostics are lower. The reporting
  refresh row also displays its awaiting-handoff count instead of a duplicate label.
- Automatic invitation, Armory linking, saved grants, mappings, event identities
  and the companion remain unchanged.

## Safety and automated checks

The stateless listener registers only a UI descriptor through Highlander's
`ModSubMenus` extension; it has no polling, network request or history submission.
An idempotent helper preserves other mods' menu rows and removes stale duplicates
of our own ID. Clicks resolve the current presentation/world/top screen rather than
retaining an old screen across reloads, reject loading/travel/busy/dialog contexts,
then call the existing campaign screen's Open method.

`TNB_CommandMenuProbeCommandlet` checks descriptor/callback presence, repeated
registration, duplicate cleanup, other-mod ordering/content preservation, allowed
screen policy and null-context guards. All offline SDK probes should pass. These
checks do not exercise the Flash menu, actual clicks, camera transitions or a
real saved campaign; those require the checks below.

## Native acceptance

Use only one copy in AML: the development test build, not both local and Workshop.
Keep backups and use a pre-link save and a linked save; no mission replay required.

1. Open Command on an unlinked save: exactly one The Name Beneath item. Check that
   the other mods' entries still work. Open our item, review, then cancel: no
   campaign link, Journey start or commander reward should occur.
2. Open it again and confirm association. Check the existing commander results,
   then reopen repeatedly: show saved bonuses, no duplicated supplies/staff/contact
   capacity or Quick Learner grants. Exit directly without an MCM Save prompt.
3. On a linked save, close the companion and use Command: saved commander effects,
   Journey title and Quick Learner recipients remain readable. A manual title refresh
   may report the unavailable companion; it must not alter saved effects.
4. Reload linked and unlinked saves in the same session, then restart XCOM. Check
   correct routing, exactly one menu entry, no crash or delayed Research/Engineering
   navigation. The automatic invitation and Not now should still work.
5. MCM: no Journey linking/view button; current status and navigation hint visible.
   Companion and Journey status are inline with Refresh/Test, and the Deja Vu
   percentage is visible near the top without scrolling past diagnostics. Refresh
   updates local/cached status; Test performs online verification. Close/restart the
   companion and Refresh to see unavailable/connected without reopening MCM. A
   reachable companion with a rejected credential must not be shown as disconnected.
   Reporting controls, the read-only stored-credential indicator, and Deja Vu/reminder
   saves still work. Main-menu/tactical MCM must not expose a campaign-link action.

No automatic merge, Workshop upload or companion re-publication follows these tests.

## Automated verification and local install - 2026-10-24

- All 13 offline SDK probes passed in debug mode and again in release mode.
  The mod compilation reported zero errors/warnings in both modes.
- A forced clean release rebuild without the generated mapping fixture passed
  Command-menu, invitation, Deja Vu, presentation and promotion/gameplay-fix probes.
  The mapping probe returned its expected missing-fixture result (exit 22), proving
  test defaults are absent from the installed package.
- Static checks confirmed the ModBuddy entries, updated navigation strings, and
  MCM's remaining four diagnostic actions (Refresh, Test, reporting Refresh/Retry),
  with no campaign-opening button or callback. Documentation links/whitespace and
  the build helper's PowerShell syntax passed validation.
- With the Product Owner's confirmation that XCOM was closed, the local development
  copy was updated to 0.9.6. Original scripts/API/localization/readme and mapping
  config were backed up and hash-verified under ignored
  `Artifacts/InstallBackups/CommandMenu-20261024`.
- The installed mapping file remained byte-for-byte unchanged: 48 shipped rows and
  five player overrides. The Workshop copy, companion, uploader ID, saves,
  credentials and generated game configuration were not changed.
- The shared SDK initially had inconsistent build modes/partial generated caches.
  Its base was rebuilt unattended and left consistently in release mode; prior
  debug packages are recoverable under ignored
  `Artifacts/Mod/SDKDebugBeforeRelease-CommandMenu-20261024`. Base compilation had
  three existing TLE duplicate-class warnings; the mod itself compiled cleanly.

Installed mod script SHA-256:
`234BE207A1A51E708283DE2EFD1A67A504286EF0CA843239FD301CC55008AEE0`.

Native menu interaction, offline display, linked/unlinked reloads and MCM behavior
remain pending Product Owner acceptance. No merge or publication has occurred.

## Compact MCM follow-up - 2026-10-24

The Product Owner gave positive feedback on the Command-menu placement and asked
for a less cluttered MCM layout. The same 0.9.6 feature branch now provides:

1. Connection: **Companion: Connected [Refresh]**, **Journey: Connected [Test]**.
   Labels update in place when opened or explicitly refreshed/tested; no new timer.
   Journey Connected means the companion's last reported verification, not a
   continuous online heartbeat. The tooltip explains cached versus live testing.
2. Deja Vu: the existing percentage slider, immediately below those two rows.
3. Campaign: saved association, Command navigation hint and reminder preference.
4. Connection details: last-observed identity/lifecycle, read-only credential
   indicator and Journey ID.
5. Gameplay reporting diagnostics: awaiting-handoff count alongside Refresh,
   delivery/acceptance/clock/error details and Retry eligible reports.

All 14 release-mode SDK probes passed; mod compilation had zero errors/warnings.
The new `TNB_MCMProbeCommandlet` verifies independent local/online states, timeouts,
protocol errors, missing/rejected credentials, unverified/unknown states and failed
online tests. Static checks verified the exact two-row header, group ordering,
slider priority and absence of duplicated status labels or MCM linking actions.
The installed MCM provider's SetLabel implementation supports live button-row text.

A clean release rebuild passed MCM, Command-menu, invitation, Deja Vu, presentation
and gameplay-fix probes; the mapping probe again confirmed the SDK fixture absent.
With XCOM closed as confirmed by the Product Owner, the local copy was updated and
hash-verified. All 48 shipped mappings/five overrides remained byte-identical;
companion, Workshop copy, uploader ID and saved data were unchanged. The earlier
local build is recoverable from `Artifacts/InstallBackups/MCMCompact-20261024`.

Current installed script SHA-256 (supersedes the prior test build above):
`85E973C2CB8C76CD65FEC53CC5E8C600051AC0F0CCC7A7151A064119F0A0BDC9`.

Native MCM layout/readability, live Refresh/Test updates and unchanged setting-save
behavior still need Product Owner verification. No merge or publication.
