# Licensing and third-party notices

The MIT license in [LICENSE](LICENSE) applies to this project's original source
code and documentation, except for the separately identified material below.
It does not replace third-party licenses or grant rights we do not own.

## Third-party source

- `.scripts/X2ModBuildCommon/`: X2CommunityCore's X2ModBuildCommon (vendored
  distribution with a changelog through 1.2.1), MIT. Keep its
  [license](.scripts/X2ModBuildCommon/LICENSE), copyright notices and upstream
  [documentation](.scripts/X2ModBuildCommon/README.md).
  Upstream: https://github.com/X2CommunityCore/X2ModBuildCommon
- `TheNameBeneath/Src/ModConfigMenuAPI/`: Mod Config Menu API, copyright
  Andrew Gu, MIT. Keep [the original notice](Docs/MCM_LICENSE.txt).
  Upstream: https://github.com/andrewgu/ModConfigMenu

## Original mod project template

This solution was created from Iridar's Enhanced Mod Project Template:
https://github.com/Iridar/EnhancedModProjectTemplate
Its upstream README describes creating and customizing mods with the template.
The existing `Help.uc` and `ConfigEngine.uc` in
`TheNameBeneath/Src/TheNameBeneath/Classes/` retain Iridar's author headers. The
project scaffolding, `TheNameBeneath/Src/extra_globals.uci`, and starter configuration
also derive from that template. These upstream portions are not claimed as our
original work or relicensed under this repository's MIT grant. The template has
no separate top-level SPDX license identified during this review; do not assume
that our MIT license grants unrestricted rights to those upstream portions.

## Branding and artwork

The Name Beneath name, logos and branding artwork are excluded
from the source-code MIT grant. This includes
`Companion/TheNameBeneathCompanion/Assets/PortalFavicon.svg`, the derived
`Companion.ico`, and `TheNameBeneath/ModPreview.jpg`. No additional permission
to reuse the branding or imply endorsement is granted by the code license.

## Game, engine and Workshop material

XCOM 2, War of the Chosen, Unreal Engine, and their SDK content remain subject
to their respective owners' terms. References to built-in icons, abilities or
game classes do not transfer ownership of those assets. Do not add game/SDK
source dumps, compiled packages, or other mods' content to this repository.
Workshop distribution remains subject to Steam and applicable publisher terms.
The integration is unofficial and is not endorsed by Valve, Firaxis, or 2K.

Optional ability mappings reference their providers by exact template name and
Workshop URL; those references do not license or bundle the providers' code.

The character-pool utility at
https://github.com/Shaosil/XCOM2CharacterPoolUtility and the Appearance Manager
source at https://github.com/Iridar/WOTCIridarAppearanceManager were format
references. Their code and binaries are not bundled as dependencies.

## Backend and credentials

The private backend for The Name Beneath is not part of this repository and is not
licensed by this project's MIT license. Use of the hosted service requires
authorization and remains subject to its separate terms. A public integration
does not grant backend source access, service credentials, or service rights.
