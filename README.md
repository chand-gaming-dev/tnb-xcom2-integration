# The Name Beneath - XCOM 2 Integration

An unofficial XCOM 2: War of the Chosen mod and Windows companion connecting a
campaign, its commander and selected soldiers to a Journey in The Name Beneath.

**Alpha:** mod **0.9.2**, companion **0.10.3**. This is a source snapshot of an
actively tested integration, not a finished Workshop release. Back up campaign
saves; start a new campaign for acceptance testing. Not every mapping or gameplay
event has completed in-game acceptance.

## What it does

- Associates a campaign with a Journey and applies configurable commander effects.
- Links soldiers from the Armory, applies mapped traits/skills, and displays
  their saved benefits without requiring a custom promotion-tree row.
- Reports mission/covert-action results and supported soldier events through a
  durable companion queue, including capture/freedom and bond formation/development.
- Downloads Journey character-pool ZIPs and offers a combined `.bin` through
  Save As, including supported Appearance Manager metadata. Import remains manual.

Player-configurable mappings are in
[XComTheNameBeneath.ini](TheNameBeneath/Config/XComTheNameBeneath.ini).
Optional ability providers are documented beside their mappings; missing
providers skip the affected grant rather than becoming hard dependencies.
See [mapping customization](Docs/MAPPING_CUSTOMIZATION.md).

## Requirements and setup

- Windows and XCOM 2: War of the Chosen.
- [WOTC Community Highlander](https://steamcommunity.com/sharedfiles/filedetails/?id=1796402257),
  development baseline and declared minimum **1.31.3**.
- [Mod Config Menu](https://steamcommunity.com/sharedfiles/filedetails/?id=667104300).
- The mod enabled in your mod launcher and the companion running alongside XCOM.
- A Journey credential for The Name Beneath and a reachable compatible backend.
  The private backend is not included. The current default API is a temporary
  development origin, not a promised public service endpoint.

No external DLL is installed in the game's Binaries directory. The self-contained
companion includes its runtime. Closing it does not close XCOM; online features
and transfer/delivery pause while saved links and bonuses remain in the game.

There is no release package in this initial source snapshot. See
[BUILDING.md](BUILDING.md) for building and installing locally. When available,
compiled packages belong under this repository's GitHub Releases, not in Git.
Before the official release, a ready-to-run Windows x64 companion executable will
be attached to [GitHub Releases](https://github.com/chand-gaming-dev/tnb-xcom2-integration/releases)
and linked here. Players will not need to build it or install the .NET SDK/runtime.
See the [release checklist](Docs/RELEASE_CHECKLIST.md); no release is published yet.

1. Build/install the mod and companion, then launch the companion for the intended
   API origin. Paste the Journey credential into its masked field and validate/save.
   It is stored in Windows Credential Manager, never in mod configuration.
2. In an unlinked campaign, wait for a quiet Avenger screen and choose **Review
   Journey** in the automatic invitation. Review and explicitly confirm commander
   effects; **Not now** applies nothing and dismisses it for this play session.
   MCM > The Name Beneath > Campaign Journey remains the manual fallback.
3. Optionally link soldiers from the Armory. Commander-only play is supported.
4. Keep the companion running for linking and online reporting; save your campaign.

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

Start with [current acceptance work](Docs/FEEDBACK_AND_NEXT_TESTS.md) and
[capture/bond/multi-soldier testing](Docs/CAPTIVITY_RELATIONSHIPS_UX_TESTING.md).
The restored invitation has a separate
[reload/lifecycle acceptance checklist](Docs/AVENGER_INVITATION_TESTING.md).
Promotion replay reporting and server-owned XP recognition are covered by
[promotion occurrence testing](Docs/PROMOTION_OCCURRENCE_TESTING.md).
Older documents contain dated milestones and machine-specific examples; the
current version headers, this README and BUILDING.md take precedence for setup.
Archived validation logs, screenshots, original prototypes and personal pools
are deliberately not published. Some historical documents reference that archive.

Original code is [MIT licensed](LICENSE). See [LICENSING.md](LICENSING.md) for
third-party notices and the exclusions for branding, game assets and the private
backend. Never include credentials, personal pools/saves, or unredacted gameplay
logs in issues or commits.

Use **The Name Beneath** as the product name in all documentation, UI and new code.
See [public naming](Docs/PUBLIC_NAMING.md) for the narrowly preserved compatibility
identifiers; these are not alternate product names.
