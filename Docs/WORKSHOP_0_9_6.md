# Workshop update - mod 0.9.6

Accepted by the Product Owner on 2026-10-25. Update the existing Workshop item
**3826279674**, titled **[WOTC] The Name Beneath**; do not create a second item.
The upload itself remains with the Product Owner.

## Player-facing change notes

- Added **The Name Beneath** to the Avenger's **Command** menu. Connect your
  campaign to a Journey there, or review your saved commander bonuses.
- Removed Journey linking from MCM to avoid its unnecessary save-settings prompt.
- Tidied MCM: Companion status/Refresh and Journey status/Test at the top, the
  Deja Vu XP slider just below, and detailed diagnostics farther down.
- Removed redundant campaign information from MCM. The automatic Journey
  invitation and Armory soldier linking remain available.

Existing campaign links and bonuses are retained. No relinking, new campaign,
companion update or mapping migration is required for this UI-only update.
Keep using companion **0.10.4** from the existing GitHub alpha release.

## Upload preparation

The prepared local folder is
`Artifacts/Releases/mod-v0.9.6/TheNameBeneath/` (ignored, not committed).
It uses the exact accepted script package, clean source defaults rather than local
player overrides, packaged localization/artwork, and the existing Workshop ID.
It excludes development source, private guides, user data and the companion EXE.
The sibling `SHA256SUMS.txt` and `BUILD_MANIFEST.md` record file hashes and source
provenance. Do not upload those sibling verification files as mod content.

Select/update the existing item in your uploader, confirm the content folder and
preview, retain required dependencies, and paste the change notes above. Once
uploaded, test with only the Workshop copy enabled in AML, not both copies.
Fresh Workshop installation remains a separate check; local acceptance is not
proof that the uploaded/downloaded files are correct.
