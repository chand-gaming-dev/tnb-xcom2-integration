# Character Pool downloads - companion 0.9.0 / unchanged mod 0.8.7

## User flow

1. Start the companion normally. Existing credential/context are retained. Open
   **Character Pools**; the selected Journey name/ID are shown. Nothing downloads
   merely by opening this tab or checking connection status.
2. Click **Download Journey files**. The companion makes an authenticated GET to
   `/v1/game-journey/character-pools.zip`, using the stored credential's Journey.
   It never accepts a different Journey ID in a URL or sends a portal-owner login.
   Existing `roster:read` scope is sufficient for this endpoint; no new scope is
   requested. The existing companion still requires its usual integration scopes.
3. The complete ZIP is checked before save actions become available. **Save
   original ZIP...** retains the exact original bytes; no entries are extracted
   automatically. One attached .bin can contain multiple soldiers. Counts clearly
   distinguish files from parsed characters.
4. For supported standard XCOM and Appearance Manager pools, **Save merged pool...** becomes available.
   The header/counts are rebuilt and serialized character records are copied
   verbatim, retaining Unicode names/biographies, appearance choices and custom
   cosmetic template names. Only byte-identical record duplicates are removed;
   equal names alone never imply the same character.
5. Companion 0.9.2 suggests `TNB-<journey name>.bin` for the merged pool, replacing
   Windows-invalid filename characters and bounding long names without splitting
   Unicode surrogate pairs. A missing/unusable title falls back to a short Journey
   ID. Save As still lets the player choose folder and filename. Existing files
   are never overwritten; choose a NEW name if a previous export already exists.
   The merged save dialog defaults to WOTC's Importable
   folder when it exists (Windows Documents redirection/OneDrive are respected):
   `Documents\My Games\XCOM2 War of the Chosen\XComGame\CharacterPool\Importable`.
   Existing files are never overwritten and DefaultCharacterPool names are refused.
   No active/default pool, campaign soldier, link, activation or event is modified.
6. In XCOM's main-menu Character Pool, choose **Import Character**, select the new
   pool, and inspect/import the desired characters. Downloading does not perform
   the game import, recruit soldiers, or automatically pair them with The Name Beneath.
   Required cosmetic/perk mods still need to be installed. A multi-soldier export
   imports all its records, not just the character named on its portal attachment.

## Supported format and important limitation

The independent merger handles standard UE3 tagged-property XCOM 2 pool exports:
native CharacterPool count and PoolFileName, the redundant native serialize helper,
and native temporary GenderHelper. Character bodies are preserved without translating
or recreating appearance data. Native temporary caches are not roster records.

Companion 0.9.1 also supports Appearance Manager's `ExtraDatas` collection. This
stores alternate appearances by armor type, loadout, uniform options and other
per-character metadata. Each entry includes a `CharPoolData` snapshot: the mod
matches that snapshot to a native character record when loading, rather than
using the soldier's name alone, roster position or the saved runtime ObjectID.
The merger validates that association, combines the collections, and assigns
distinct runtime ObjectIDs. All character record bytes and all other metadata
bytes are preserved, including nested arrays and unknown cosmetic template names.
No dependency discovery or installed-mod check is performed. Missing cosmetics
are not a reason to reject a merge; the game and the player's mods handle them.
The companion does not guarantee how XCOM validates or replaces unavailable parts.

Duplicate metadata for the same snapshot is collapsed only if the payload bytes
match (ignoring its runtime ID and separately compared snapshot). Different
payloads for the same snapshot are an explicit conflict, not silently first-wins.
Metadata with no matching character snapshot is likewise kept ZIP-only, not
attached to a same-name soldier or discarded. Zero/None/empty native defaults,
field order and string encoding are normalized for snapshot comparison only;
this never changes character records or cosmetic payloads in the output.

Other unrecognized header extensions are **not silently dropped**.
If any file uses an unsupported format or has an invalid pool structure, the entire
merged output is disabled and the first blocking filename/reason is shown. The
verified original ZIP remains available. There is no hidden partial merge or
automatic stripping of mod-specific loadout/appearance information.

Local evidence: Developers.bin (143), Notables.bin (2), Pool of Actors.bin (101)
and Marbs Chand.bin (1) merged into 247 byte-preserved records. Marbs Chand.bin's
ExtraDatas entry retains seven armor appearances and its saved loadout. Its
character association and metadata content hashes survive merge/re-read. All
tests use read-only copies; no original pools or active game pool were changed.

Format evidence (reviewed 2026-10-21, no mod source copied into the companion):
- https://github.com/Iridar/WOTCIridarAppearanceManager/blob/master/WOTCIridarAppearanceManager/Src/WOTCIridarAppearanceManager/Classes/CharacterPoolManager_AM.uc
- https://github.com/Iridar/WOTCIridarAppearanceManager/blob/master/WOTCIridarAppearanceManager/Src/WOTCIridarAppearanceManager/Classes/UICharacterPool_ListPools_AM.uc
  The first defines CharacterPoolExtraData, snapshot-based lookup, runtime-ID reset
  and saving; the second transfers ExtraData on native character import/export.

Format reference, not a dependency or copied implementation:
https://github.com/Shaosil/XCOM2CharacterPoolUtility
The SDK CharacterPoolManager.uc independently documents CharacterPoolDataElement,
CharacterPoolSerializeHelper and GenderHelper. This companion does not run or
redistribute the external utility or include its code. No new package dependency.

## Safety and behavior

- Same limits as server: 200 files, 10 MiB per file, 100 MiB combined source bytes;
  downloaded ZIP bounded at 101 MiB. Standard nonencrypted single-disk ZIP only;
  ZIP64, unsafe paths, duplicate filenames, unsupported compression, bad CRC,
  truncation and inconsistent structure are rejected. No automatic extraction.
- Standard pool records: up to 10,000 characters, bounded property/string counts,
  nesting and lengths. Unknown versions/layouts fail closed for merge.
- Binary HTTP has a 75-second total deadline; JSON retains 15 seconds. Redirects
  are never followed and credentials never leave the configured origin. Only a
  200 application/zip response is accepted; error bodies are bounded/redacted.
- Download work does not hold the game/event/activation handoff gate. Large exports
  cannot introduce an additional full-download delay to game reporting handoffs.
- Credential/Journey controls are disabled during the UI operation; results also
  recheck the pinned credential after download. Changing/removing a credential
  invalidates stale results. A failed new download clears the previous result.
- Cancel/close cancels work; closing waits for the pool operation to settle before
  teardown. Atomic new-file publishing prevents partial output; only the operation's
  own explicit unique temporary file is cleaned up. Existing files are untouched.
- ZIP and merged data are in memory until saved, replaced, Journey change or close;
  there is no automatic personal-file cache. Files saved by the player remain.

## Remaining manual acceptance

1. Use a Journey with authorized XCOM attachments. Download using its stored
   credential, inspect counts and save the original ZIP under a fresh name.
2. For supported standard pools, save a merged .bin and import through XCOM.
   Verify count, names, biography, flags and appearance, including required mods.
   Offline format/byte preservation tests do NOT establish actual native import.
3. Include an Appearance Manager export along with a standard pool. Save the merged
   file through Save As and check normal appearance plus stored armor appearances
   and loadout with Appearance Manager enabled. No companion-side mod check is
   required. With the mod absent, base records remain present but its additional
   information is not promised to survive a game-side re-save. Back up active pools
   before import. Native game import remains an unperformed manual acceptance gate.
   A genuinely unknown layout, unmatched snapshot or conflicting metadata should
   still provide ZIP-only with an explanation, never a partial merge.
4. Test no files, expired credential/dev access, unsupported Journey/game, storage
   error, cancel and closing during a download. Do not rotate/delete a real
   credential merely to force a test; safe offline tests cover those failure paths.

No live API requests, uploads, grants, real credential edits or game-pool imports
were made during automated validation. API schema/storage changes belong to the
already-existing The Name Beneath feature; none are included in this companion patch.
