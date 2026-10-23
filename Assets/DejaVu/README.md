# Deja Vu artwork

Original SVG and green PNG supplied by the project owner for the local XCOM
linking passive. The white SVG changes color/metadata only; path/circle geometry
is unchanged. The PNG/TGA are deterministic renders of that vector source.

Run `node .scripts/Build-DejaVuIcon.mjs <folder-containing-sharp-node_modules>`
from the repository root to reproduce the white PNG and 32-bit alpha TGA. This
optional asset-generation step does not run during ordinary mod builds.

The WOTC-editor-authored `TheNameBeneath/Content/UILibrary_TNB.upk` contains only
`Texture2D UILibrary_TNB.TNB_DejaVu`. That small authored texture package is
intentionally versioned; SDK packages, compiled scripts and local distributions
remain ignored. Import instructions and gameplay acceptance are in
`Docs/DEJA_VU.md`.
