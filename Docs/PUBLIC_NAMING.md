# Public naming

The official public product name is **The Name Beneath**. Use it in documentation,
UI, comments, release notes and new code. Do not use the internal development
codename as a product name, namespace, class name, executable or example path.

Current integration names:

- Project/executable: `TheNameBeneathCompanion` / `TheNameBeneathCompanion.exe`.
- Companion namespace: `TheNameBeneath.Companion`.
- Backend client class: `JourneyApi`.
- Mod: `TheNameBeneath`, with existing `TNB_` classes.

## Approved compatibility exceptions

These exact machine identifiers remain deliberately unchanged. Do not rename,
obfuscate or reinterpret them as part of a prose/branding cleanup:

- Canonical API event names/prefixes: `threadline.*`, including emitted events,
  validators, queue grouping and their matching synthetic/native tests.
- Existing development configuration keys: `THREADLINE_DEV_API_BASE_URL` and
  `THREADLINE_JOURNEY_CREDENTIAL`. They remain recognized by the companion and
  the private developer configuration; `.env.example` documents the actual keys.
- Windows Credential Manager target prefix `Threadline/TheNameBeneath/` and
  the existing `%LOCALAPPDATA%\Threadline\TheNameBeneath\` data root. Their exact
  values preserve stored credentials, cached context, receipts and event journals.

Technical documentation may quote those identifiers when needed to describe the
real protocol or persisted paths. They are compatibility details, not branding.
Changing them requires an explicitly coordinated backend/storage migration and
separate review. This update does not rewrite saved events, Journey history or
game saves, and does not require re-entering credentials or re-linking soldiers.

The original source snapshot remains in Git history. This is an ordinary forward
rename, not a history rewrite or removal of previously published history.
