# XCOM 2 mapping reference: icon and description inventory

**Design inventory only — 2026-10-22.** Companion/mod source baseline: `0995fb7`.
No images, textures, packages, localization files or third-party code were exported,
copied into the integration or packaged. This inventory does not establish permission
to redistribute game/mod artwork on a public website. See [LICENSING.md](../LICENSING.md).

## 1. Ability assets already found

These are **actual installed-provider** lookups, not invented artwork. TNB already
uses the installed `X2AbilityTemplate.IconImage`, `LocFriendlyName`, and
`GetMyLongDescription(, Unit)` / help-text fallback in
`TheNameBeneath/Src/TheNameBeneath/Classes/TNB_EffectPresentation.uc:118–144`.
A game texture URI is not a browser image URL or an automatically licensed web asset.

| Canonical Skill | Verified template / installed display name | Actual icon URI | Definition and wording source |
| --- | --- | --- | --- |
| Evasive Maneuvers | `LightningReflexes` / Lightning Reflexes | `img:///UILibrary_PerkIcons.UIPerk_lightningreflexes` | WOTC SDK `Development/SrcOrig/XComGame/Classes/X2Ability_AdvancedWarfareCenter.uc:12–46`; installed game's `XComGame/Localization/INT/XComGame.int`, section `[LightningReflexes X2AbilityTemplate]` |
| Cover Discipline | `LowProfile` / Low Profile | `img:///UILibrary_LW_PerkPack.LW_AbilityLowProfile` | P2 `Src/LW_PerkPack_Integrated/Classes/X2Ability_PerkPackAbilitySet.uc:975`; P2 English localization section `[LowProfile X2AbilityTemplate]` |
| Weapon Handling | `SingleReloadMrC` / Chamber Round | `img:///ABBIcons.Perks.SingleReload` | P1 `Src/rustycloistaperks/Classes/ABWspray_Ability_Weapongranted.uc:17–93`; `Localization/XComGame.int:81`; `Config/support/XcomFreeBeacon.ini:8–11` |
| Leading Shots | `GrazingFire` / **Grazing Attacks** in the installed LWOTC version | `img:///UILibrary_LW_PerkPack.LW_AbilityGrazingFire` | P2 ability-set file above, `:3760`; `X2Effect_GrazingFire.uc`; `Config/XComLW_SoldierSkills.ini:534`; P2 English section `[GrazingFire X2AbilityTemplate]` |
| Field Surgery | `FieldSurgeon` / Field Surgeon | `img:///UILibrary_LW_PerkPack.LW_AbilityFieldSurgeon` | P2 `Src/LW_PerkPack_Integrated/Classes/X2Ability_PerkPackAbilitySet2.uc:1184`, `X2Effect_FieldSurgeon.uc`; P2 English section `[FieldSurgeon X2AbilityTemplate]` |
| Independent Operator | `LoneWolf` / Lone Wolf | `img:///UILibrary_LW_PerkPack.LW_AbilityLoneWolf` | P2 first ability-set file, `:951`, `X2Effect_LoneWolf.uc`; `Config/XComLW_SoldierSkills.ini:1036–1042`; P2 English section `[LoneWolf X2AbilityTemplate]` |

Local roots used:

- Game: `D:\Steam\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\XComGame`.
- SDK: `D:\Steam\steamapps\common\XCOM 2 War of the Chosen SDK`.
- P1 / Modpocalypse: `D:\Steam\steamapps\workshop\content\268500\2936550132`.
- P2 / installed LWOTC experimental: `D:\Steam\steamapps\workshop\content\268500\2663990965`.
- P2 English wording: `Localization/LW_PerkPack_Integrated/XComGame.int`.
- P1 texture container found: `Content/ABBIcons.upk`.
- P2 texture container found: `Content/LW_PerkPack_Integrated/UILibrary_LW_PerkPack.upk`.
- Native texture containers are resolved through the game's engine package paths;
  the verified identifiers above identify the textures. No stand-alone web images
  or export locations are being promised.

## 2. Verified effect renderings and reference cautions

Use these **paraphrased mechanics**, or verified/permission-cleared game wording.
Do not present the following as raw localization copied into a Portal asset bundle.

- Native Lightning Reflexes makes the first reaction attack against the soldier
  in each turn miss. It is not Shadowstep and not `LightningReflexes_LW`.
- Low Profile treats partial cover as full cover. A base-game effect class of
  similar name and the Chosen's ability do not establish that the mapped soldier
  template is native.
- Chamber Round adds one round to the primary weapon as a free action under its
  normal requirements: it must need a reload, two AP must be available, and the
  default is two charges. It is not a full reload or an always-visible tactical action.
- Installed Grazing Attacks can change a missed weapon attack to a graze. The
  provider's configured success threshold is 50, reduced by target Dodge. Its
  source includes melee weapon attacks; a different provider may be primary-only.
  Do not label this a flat Aim increase or assume every provider has identical scope.
- Field Surgeon reduces the HP used for eligible post-mission wound recovery by
  one. It includes the user; it is not an active combat heal. Source/target death,
  capture, previous bleed-out and provider cleanup rules matter. The standalone
  counterpart's hook must be checked independently.
- Installed Lone Wolf scales Aim/Defense with distance from the nearest eligible
  ally. Current source configuration caps them at +12/+12 with +0 Crit.
  Defense is disabled under relevant impairments. Do not reuse those numbers for
  another provider. In particular, the source formula includes a one-tile offset
  while localized threshold tags simplify the presentation: render/check actual
  game text before publishing a fixed threshold.

Localization contains dynamic `<Ability:.../>` tags and game markup. Resolve
them against the selected **release provider and its default configuration**;
do not publish raw tags, unresolved image names or generic placeholder text.
Additional user mods can alter the effective runtime description; a static
Portal page must describe the named shipped-default release, not inspect or
pretend to represent each player's installed mod stack.

## 3. Proposed class-free provider is not yet an asset source

P3: [[WOTC] LW2 Classes Perk Pack [FINAL], 1790938526](https://steamcommunity.com/sharedfiles/filedetails/?id=1790938526).
Its creator describes a class-free perk library with configurable changes to
vanilla perks. It is **not installed here**. Its linked ability spreadsheet was
not accessible through the browsing tool.

Therefore **P3 exact template IDs, icon URIs, English sections, default numbers,
vanilla-change toggles and gameplay hooks are NOT verified in this audit**.
The `LW2WotC_...` spelling seen in other mods is not accepted as authoritative
source proof for this package/version. Do not ship guessed aliases, reuse P2
descriptions/icons as if they were P3's, or describe it as a drop-in replacement.
Obtain/read the actual source and localization and validate the chosen profile
after Product Owner approval, without installing it into the active LWOTC setup.

## 4. Existing stat/campaign presentation assets

These are presentation categories, **not named abilities**. A future page should
primarily describe the configured numeric effect and frequency; do not invent an
ability or imply that this artwork itself is the canonical Trait.

| Effect | Existing game asset reference in TNB_EffectPresentation.uc |
| --- | --- |
| HP | `img:///UILibrary_Common.implants_health` |
| Will | `img:///UILibrary_Common.implants_will` |
| Mobility | `img:///UILibrary_Common.implants_mobility` |
| Sight radius | `img:///UILibrary_PerkIcons.UIPerk_squadsight` |
| Hacking | `img:///UILibrary_PerkIcons.UIPerk_hack` |
| Defense | `img:///UILibrary_PerkIcons.UIPerk_aimcover` |
| Critical chance | `img:///UILibrary_PerkIcons.UIPerk_aggression` |
| Combat Intelligence | `UIUtilities_Image.EventQueue_Science` |
| Supplies / Intel | `img:///UILibrary_XPACK_StrategyImages.Invx_Supplies` / `Invx_Intel` |
| Engineer / Scientist | `UIUtilities_Image.AlertIcon_Engineering` / `AlertIcon_Science` |
| Avatar progress | `UIUtilities_Image.EventQueue_Alien` |
| Scrounger item | Actual item template image when received; generic `LootIcon_Loot` is only a category icon |

These existing in-game references are not permission to extract them for Portal
hosting. Native text-only effect renderings are sufficient where an ability icon
does not exist. For an unmapped entry show **No default XCOM 2 effect**, not an
unknown/rainbow placeholder presented as an earned ability.

## 5. Canonical TNB artwork is separate

Repository-relative paths in the related canonical repository:

- `apps/portal/src/assets/canonical-artwork.ts`: 29 inline SVG paths keyed by
  the currently published Trait/Skill IDs, plus kind fallbacks.
- `apps/portal/src/components/canonical-glyph.tsx`: canonical ID lookup,
  polarity/kind colors and SVG rendering.
- `apps/portal/src/components/canonical-definition-label.tsx`: canonical
  icon/name composition.
- `apps/portal/public/icons/`: branding/favicons, not game ability artwork.

These can identify the canonical source characteristic on the future page; they
must not be substituted for the **actual XCOM ability icon** and represented as
such. No API artwork endpoint or rasterization/export is needed for this audit.

## 6. Public reference handoff, after approval

The static alpha page should be titled **Default XCOM 2 configuration**.
For each published canonical ID show both identity contexts; include the canonical
name, actual selected-provider ability name/icon where applicable, accurate effect,
timing, and **No default XCOM 2 effect** for reviewed exclusions. Explain that
organizers can override local mappings and that missing optional abilities remain
unavailable rather than becoming substitutes.

Keep pack names, template IDs, INI syntax, dependency versions and installation
profiles in organizer-facing README/Workshop documentation, not every player row.
Reference the approved audit revision and exact shipped configuration. Link from
Getting Started and Trait/Skill choices where practical. This audit authorizes
neither the Portal page nor a new API. Export/redistribution permission for game
and third-party art remains a separate release gate; do not mistake source-code
licenses or a provider's ability to display assets in-game for web asset rights.

