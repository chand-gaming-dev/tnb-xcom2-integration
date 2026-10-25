# The Name Beneath - XCOM 2 Integration

An unofficial XCOM 2: War of the Chosen mod and Windows companion connecting a
campaign, its commander and selected soldiers to a Journey in The Name Beneath.

**Accepted update: mod 0.9.6** moves manual Journey linking and the saved
commander-bonuses view to **Avenger > Command > The Name Beneath**, removing that
action from MCM. The Product Owner confirmed native acceptance on 2026-10-25;
the Workshop update is pending upload. MCM now starts with inline Companion/Refresh
and Journey/Test rows,
followed immediately by the Deja Vu percentage; detailed diagnostics are lower.
Companion 0.10.4 is unchanged. See [Command-menu testing](Docs/COMMAND_MENU_TESTING.md).

**Currently published alpha:** mod **0.9.5**, companion **0.10.4**. The companion
is distributed through
[GitHub Releases](https://github.com/chand-gaming-dev/tnb-xcom2-integration/releases/tag/companion-v0.10.4-alpha.1);
the mod is listed as [[WOTC] The Name Beneath on Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3826279674).
Back up campaign saves; a new
campaign is recommended for alpha testing. See the [current acceptance
summary](Docs/ALPHA_ACCEPTANCE_SUMMARY.md) for confirmed gameplay tests and remaining
limitations; automated tests do not establish in-game compatibility.

## What it does

- Associates a campaign with a Journey and applies configurable commander effects.
- Links soldiers from the Armory, applies mapped traits/skills, and displays
  their saved benefits without requiring a custom promotion-tree row.
- Gives newly linked soldiers the local **Deja Vu** passive, with a configurable
  promotion-XP bonus (5% by default).
- Reports mission/covert-action results and supported soldier events through a
  durable companion queue, including capture/freedom and bond formation/development.
- Downloads Journey character-pool ZIPs and offers a combined `.bin` through
  Save As, including supported Appearance Manager metadata. Import remains manual.

Player-configurable mappings are in
[XComTheNameBeneath.ini](TheNameBeneath/Config/XComTheNameBeneath.ini).
Optional ability providers are documented beside their mappings; missing
providers skip the affected grant rather than becoming hard dependencies.
See [mapping customization](Docs/MAPPING_CUSTOMIZATION.md).

## Requirements

- Windows and XCOM 2: War of the Chosen.
- [WOTC Community Highlander beta](https://steamcommunity.com/sharedfiles/filedetails/?id=1796402257),
  tested with **1.31.3**, which is also this mod's declared minimum.
  If Alien Hunters DLC is installed and enabled, also use the matching
  [beta Alien Hunters Highlander plugin](https://steamcommunity.com/sharedfiles/filedetails/?id=2635921321).
  Do not use the plugin without that DLC, or mix stable and beta Highlander copies.
- [Mod Config Menu](https://steamcommunity.com/sharedfiles/filedetails/?id=667104300).
- The mod enabled in your mod launcher and the companion running alongside XCOM.
- A Journey credential issued by [The Name Beneath](https://thenamebeneath.com).
  The companion uses `https://thenamebeneath.com/` by default. No Replit access key,
  API URL entry or development configuration is required for normal use.

Optional perk packs are needed only for their mapped abilities, not for the mod
to load. Check the provider links beside the [default mappings](TheNameBeneath/Config/XComTheNameBeneath.ini)
before installing additional mods. Missing abilities are identified in the soldier
profile; other compatible mapped effects can still apply.

## Installation and first connection

Subscribe to [[WOTC] The Name Beneath on Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3826279674)
and enable the mod and its required dependencies in your mod launcher.
Download the separate ready-to-run Windows x64
[TheNameBeneathCompanion.exe](https://github.com/chand-gaming-dev/tnb-xcom2-integration/releases/download/companion-v0.10.4-alpha.1/TheNameBeneathCompanion.exe).
The [companion alpha release](https://github.com/chand-gaming-dev/tnb-xcom2-integration/releases/tag/companion-v0.10.4-alpha.1)
also includes checksums and license notices. Use only one copy of the mod: do not
enable the local development build and Workshop copy together. Developers can use
[BUILDING.md](BUILDING.md) for source builds.
GitHub's automatic source-code ZIP is not the player download.

Run the companion by double-clicking the EXE: no PowerShell command,
source build, .NET SDK/runtime installation or external DLL in the game's Binaries
directory is required. Packaging remains subject to the [release
checklist](Docs/RELEASE_CHECKLIST.md).

1. Install/enable the mod and its required dependencies, then launch the companion.
   Paste the production Journey credential into its masked field and validate/save.
   It is stored in Windows Credential Manager, never in mod configuration.
   Development credentials, cached Journeys and queued reports stay separate and
   are not migrated to Production. Use a production Journey with an unlinked save
   or new campaign when testing the public service.
2. In an unlinked campaign, reach the Avenger (after the opening mission in a new
   campaign). On its idle screen choose **Review Journey** in the automatic
   invitation. Review and explicitly confirm commander effects. An Upcoming Journey
   can be started with your confirmation; a Finished Journey is not reopened
   automatically. **Not now** applies nothing and dismisses the invitation for this
   play session. Avenger > Command > The Name Beneath is the manual fallback
   and lets you review saved commander bonuses afterward.
3. Optionally link soldiers from the Armory. Commander-only play is supported.
   **Traits & Abilities** shows each linked soldier's effects and missing providers.
4. Keep the companion running for linking and online reporting; save your campaign.

The Command-menu route above applies to the accepted 0.9.6 update. Published
mod 0.9.5 still uses MCM > The Name Beneath > Campaign Journey for manual access.

Closing the companion does **not** close XCOM or remove saved links and bonuses.
Gameplay reports can be captured in the campaign save while it is offline;
transfer/delivery resumes when it reconnects. Save before quitting XCOM. You can
check connectivity and reporting in MCM, and delivery diagnostics in the companion's
**Gameplay reporting** tab. Saved profiles remain readable offline.

### Unsigned alpha companion

The initial release is unsigned, so Windows or your browser may display a
warning. Download only from this repository's official Releases page and compare
the file's SHA-256 with the published checksum before running it:

```powershell
Get-FileHash .\TheNameBeneathCompanion.exe -Algorithm SHA256
```

This command is an optional verification step, not a launch requirement. A checksum
checks file integrity; it is not publisher signing or a safety guarantee. Do not
disable antivirus or other system-wide protections to run the companion.

## Bonuses, settings and saved games

Mappings are resolved when a campaign/soldier is linked and retained in that save.
Editing mapping overrides affects future links, not already-applied effects. Back
up your overrides before mod updates. See [mapping customization](Docs/MAPPING_CUSTOMIZATION.md)
for supported effects, version matching and optional ability providers.

**Deja Vu is a local XCOM linking bonus, not an online trait/skill or online XP.**
MCM > The Name Beneath > Linking bonuses has one **Deja Vu bonus promotion XP (%)**
slider, 0-100, default 5. It grants extra promotion credit from qualifying new kills,
assists and ordinary covert-action XP; fractions accumulate. It does not grant
Ability Points or multiply guaranteed promotions.

Set it to **0%** to stop future bonus XP without removing links, the passive or
previously earned credit. Newly linked soldiers still receive the passive at 0%,
clearly shown as disabled. Rate changes apply to future earnings for all holders;
they do not retroactively multiply old XP. Older linked soldiers that never received
the passive are not automatically backfilled. Full-XP-system overhauls are not
supported by this bonus. See [Deja Vu details](Docs/DEJA_VU.md).

**Loading an older save does not rewind online Journey history.** A pre-link save
does not retain a later soldier association. Subsequent linking can reuse the
Journey's existing instance; local saved grants must not stack.

## Source layout and testing

| Location | Contents |
| --- | --- |
| `TheNameBeneath/` | ModBuddy project, UnrealScript, mappings, localization, preview |
| `Companion/TheNameBeneathCompanion/` | .NET Windows Forms companion and synthetic tests |
| `.scripts/` | Build/start helpers and licensed vendored mod build system |
| `Docs/` | Design, setup, mapping guidance and acceptance checklists |

Start with the [current acceptance summary](Docs/ALPHA_ACCEPTANCE_SUMMARY.md), then
[BUILDING.md](BUILDING.md) for build/test commands. Capture/rescue, bond and some
other lifecycle/overhaul paths still need wider native alpha coverage; implemented
does not mean gameplay-verified. Detailed procedures include
[capture/bond/multi-soldier testing](Docs/CAPTIVITY_RELATIONSHIPS_UX_TESTING.md).
The restored invitation has a separate
[reload/lifecycle acceptance checklist](Docs/AVENGER_INVITATION_TESTING.md).
Promotion replay reporting and server-owned XP recognition are covered by
[promotion occurrence testing](Docs/PROMOTION_OCCURRENCE_TESTING.md).
The [feedback log](Docs/FEEDBACK_AND_NEXT_TESTS.md) and older documents contain
historical milestones, superseded OPEN notes and machine-specific examples. Use
the current acceptance summary for test status, and this README/BUILDING.md for setup.
Archived validation logs, screenshots, original prototypes and personal pools
are deliberately not published. Some historical documents reference that archive.

Original code is [MIT licensed](LICENSE). See [LICENSING.md](LICENSING.md) for
third-party notices and the exclusions for branding, game assets and the private
backend. Never include credentials, personal pools/saves, or unredacted gameplay
logs in issues or commits.

Use **The Name Beneath** as the product name in all documentation, UI and new code.
See [public naming](Docs/PUBLIC_NAMING.md) for the narrowly preserved compatibility
identifiers; these are not alternate product names.
