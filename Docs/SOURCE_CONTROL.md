# Source-control boundaries

This public repository contains both the mod and companion sources. The original
unversioned solution was fully backed up before the first repository snapshot.
The backup includes items deliberately excluded from public Git history; ignored
files are not protected merely by creating commits.

## Included

- Active UnrealScript and companion code, synthetic tests, configuration defaults,
  localization and project/build definitions.
- Required licensed MCM API/build-helper source and original notices.
- The integration's existing branding assets, separately identified in LICENSING.md.
- Setup, mapping design and acceptance checklists, including known alpha limitations.

## Kept locally, not published

- `Artifacts/`, build caches, bin/obj, IDE user files and compiled game packages.
- `.env` files, Windows credentials, runtime context caches, event journals and logs.
- Personal character pools, ZIP downloads, campaign saves and crash dumps.
- `Native/`: the obsolete DLL feasibility experiment, not a runtime dependency.
- `Docs/Validation/` and `Docs/Prototypes/`: development evidence, screenshots,
  old test-script copies and superseded prototypes.
- The two original high-level integration/sample plans in the mod directory.
  They describe superseded direct-DLL and credential-storage designs, not current
  implementation instructions.

The ignored archive remains on the original development machine and in the
pre-source-control backup. Historical notes may link to that local evidence;
those links will not resolve in a fresh public clone. Reusable tests live in
the active source tree. No game/SDK or private backend checkout is bundled.

## Routine workflow

Keep `main` as the reviewed baseline. Make future implementation changes on
focused feature branches, review/test the diff, then merge. Push regularly;
uncommitted changes and ignored local files still need their own backups.

Before each push, review `git diff --cached --stat` and `git diff --cached` for
unintended files or sensitive data. Do not force-add ignored data to share a bug
report. Use synthetic fixtures or explicitly redacted excerpts instead. Keep
compiled distribution packages in GitHub Releases rather than source commits.

`.gitattributes` deliberately preserves existing bytes rather than normalizing
mixed encodings/line endings. In particular, source localization must retain its
encoding; deployed game localization may be UTF-16. Handle any formatting migration as
a separate reviewed change, never as incidental source-control setup.
