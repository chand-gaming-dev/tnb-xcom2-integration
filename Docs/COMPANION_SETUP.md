# Companion, campaign Journey and Armory integration

Public-source setup: use [BUILDING.md](../BUILDING.md) for portable build/start
commands. The startup helper now accepts `-DevelopmentConfig` and otherwise reads
the ignored `.env.local` beside the solution; it no longer assumes the author's
private backend checkout. Dated notes below describe earlier development builds.

**Current companion 0.10.3 / mod 0.9.0:** the desktop title is
The Name Beneath - XCom 2 Companion <version>. Separate Journey, Gameplay reporting
and Character Pools tabs organize setup, delivery counts/diagnostics and pool import.
Existing credentials and delivery journals are retained. New capture/freedom and
bond formed/developed events use the backend factual types; legacy milestone reports
remain unchanged. See CAPTIVITY_RELATIONSHIPS_UX_TESTING.md.

The companion project/executable is now TheNameBeneathCompanion. The official
product name is The Name Beneath; existing API identifiers, environment keys,
credentials, context and journals retain compatibility. See PUBLIC_NAMING.md.

The header includes the original favicon and uses text-sized stacked rows so
title/subtitle do not overlap as the window or Windows text scaling changes.
Minimize/restore ignores the transient zero-width client area when constraining
header text. This prevents the green header from expanding over the tabs after
restore. Regression tests exercise all tabs, normal/maximized windows and minimum
size with empty and connected synthetic Journey states. Credentials/data and the
native mod are unchanged. Verify by minimizing/restoring each tab repeatedly;
tabs and controls should remain visible and the selected tab/Journey should stay.

Download the current Journey's complete authorized ZIP with
the existing credential; save the original or a separately merged .bin pool for
manual XCOM import using Save As to choose folder and filename. The suggested merged
filename is `TNB-<journey name>.bin`, sanitized for Windows. Standard pools and
Appearance Manager ExtraDatas are supported, preserving saved armor appearances,
loadouts and character association. Missing cosmetic mods do not block merging.
Existing pools are never overwritten. Conflicting/unmatched metadata and other
unsupported layouts stay ZIP-only with an explanation, rather than silently
discarding data. No new scope, login, game-mod
update or relink is required. See CHARACTER_POOL_DOWNLOAD_TESTING.md. Earlier
milestone/version notes below are historical where superseded.

**Current 0.7.0:** use [JOURNEY_AND_SOLDIER_UX_TESTING.md](JOURNEY_AND_SOLDIER_UX_TESTING.md).
Journey title is displayed separately from commander/game/ID. Test connection to
refresh old caches. Armory Traits & Abilities is now a graphical, offline-readable
profile. No re-link or credential re-entry is needed. Gameplay reporting from 0.6.0
is retained; Avenger prompts remain disabled. Older milestone notes below are historical.

**Current feedback build 0.5.1:** automatic Avenger invitations are disabled for reload diagnosis. Campaign setup is MCM-only: Campaign Journey > Connect Campaign Journey / View Commander & Bonuses > Open. Linked Armory reports are now Traits & Abilities. The companion closing guidance is corrected; it does not stop XCOM. See FEEDBACK_AND_NEXT_TESTS.md for the current combined acceptance procedure. Earlier reminder instructions below are historical. Existing credentials/receipts/saves remain compatible; no API changes are included.

Current lifecycle amendment (2026-10-19): companion 0.5.0 plus the matching mod can explicitly start an Upcoming Journey as part of the Avenger/MCM campaign confirmation. Deploy `feature/journey-management` API/contracts/portal and migration 0014 first; issue a new credential through the updated portal, which includes Journey management automatically. Existing keys are not upgraded by rotation. Older keys/API versions remain usable for already-Started Journeys (manual portal Start is the fallback). Finished Journeys are never reopened automatically. The existing four required companion permissions are unchanged; management is optional until needed. Closing/cancelling/loading an older save cannot undo a remote start. See CAMPAIGN_JOURNEY_TESTING.md and Validation/journey-management-validation.md. The original snapshots/receipts, credential target, startup command and Armory feature 2 remain compatible.

Current UI amendment (2026-10-19): campaign association has moved out of the Armory. Use the Avenger reminder or loaded-campaign MCM > The Name Beneath > Campaign Journey > Connect / View Journey. It reviews commander effects before confirmation and needs no soldier links. The same action shows saved commander effects offline afterward. Not now dismisses the reminder for the current load/session; disable future reminders using the campaign-local MCM checkbox, Save Changes, then save the XCOM campaign. Main-menu and tactical MCM retain connection status but cannot associate a campaign. Companion 0.4.1 is unchanged; install the new mod scripts/localization only. See CAMPAIGN_JOURNEY_TESTING.md. The earlier milestone descriptions below are historical where they describe Armory-based association.

Companion 0.4.1 / protocol 2 / Armory feature 2. The experimental local build includes Armory linking, campaign association, frozen mappings and initial resource/Scrounger paths. The loaded save now owns soldier pairings: a pre-link save can choose again or opt out, while existing committed links cannot stack stats. The Name Beneath instances/snapshots remain immutable and reusable. Commander association is unchanged. Actual-game acceptance is pending; see ARMORY_TESTING.md and RESOURCE_COVERAGE.md. Update both mod and companion; no credential re-import is needed. Event delivery is not enabled yet.

## Dependencies

- XCOM 2: War of the Chosen.
- WOTC Community Highlander; development baseline 1.31.3, Workshop item 1796402257.
- Mod Config Menu, Workshop item 667104300.
- The Name Beneath local mod, enabled through AML.
- TheNameBeneathCompanion.exe running alongside XCOM. No custom DLL goes in the game's Binaries folder. The published executable includes its runtime; building from source requires .NET SDK 10 with Windows desktop support.

## Start the desktop app locally

Open PowerShell in your integration checkout. Copy `.env.example` to the ignored
`.env.local` and configure your authorized development origin privately, then run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\.scripts\Start-Companion.ps1 -Development
```

The companion opens a Windows desktop window. Minimize it while playing. Closing it stops the listener and cancels pending requests; the stored credential is retained. ExecutionPolicy Bypass applies only to the new PowerShell process, not the machine policy. No Windows service is installed.

The Development switch reads `.env.local` by default, or the private file supplied
with `-DevelopmentConfig`. Only THREADLINE_DEV_API_BASE_URL,
REPLIT_DEV_EXTERNAL_ACCESS_TOKEN, and THREADLINE_JOURNEY_CREDENTIAL are recognized;
process environment values take precedence. The Replit protection token stays in
the companion. The Journey credential from that file is used only by
--check-development-connection or --check-development-journey, not automatically
stored or placed in the desktop field. Never commit the private configuration.

For an unprotected endpoint, the published EXE can be opened directly. It accepts --api https://your-api-origin/ and --port 27129. Change CompanionPort in XComTheNameBeneath.ini if the port changes. Never pass a Journey credential as a command-line argument. The default origin is the development Replit URL supplied by the user, so use the Development startup command for that protected server.

Read-only live validation without opening a window, starting a listener, or storing a real credential:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\.scripts\Start-Companion.ps1 -Development -CheckOnly
```

## Enter and verify the credential

1. Type or use ordinary paste into the masked Journey credential field in the companion. The app does not programmatically read the clipboard.
2. Select Validate and save. The field clears immediately. The helper checks GET /v1/game-journey and all required scopes before storing the secret in Windows Credential Manager.
3. Confirm the displayed commander, Journey ID, and lifecycle status. Credential stored is a read-only vault-backed indicator; connection validity is separate.
4. Test connection verifies the stored credential. Offline failures retain it. Restart reports Stored, not yet verified this session until a test succeeds.
5. To rotate/switch, enter another credential and select Validate and save; replacement requires confirmation. Failed validation preserves the previous credential. Switching active Journey does not move existing campaign links or history.
6. Remove credential requires confirmation and deletes only the active local vault entry. It does not revoke the server credential or remove The Name Beneath activations/history. Other previously stored Journey credentials are not erased.

No real credential is prefilled or read back into the field. No secret is returned to XCOM, written to an INI/save, or included in UI error text. Normal Windows credential-field input necessarily exists briefly in process memory; clearing the field is not a guarantee that immutable managed-string copies are erased.

## In-game status and checks

Basic connection, live Test, companion-off timeout, and reconnect were confirmed by the user through AML on 2026-10-18. See Validation/in-game-connection-validation.md. The simplified page retains MCM as a required dependency and uses only The Name Beneath branding. Its read-only rows separately report companion reachability, last-known Journey verification, commander/lifecycle context, and stored-credential status; Refresh/Test are the only actions. Credential management remains in the desktop app. The technical build row has been removed.

1. Start the companion, then launch WOTC through AML with Highlander, MCM, and The Name Beneath enabled.
2. Open MCM > The Name Beneath. The page should show the current stored indicator and connection state without timing out. A fresh install reports Not configured. This proves the actual game/socket path.
3. After saving/removing a credential in the desktop app, click Refresh in MCM or reopen the page. Both displays should agree. Test in MCM performs a read-only verification; credential management is only in the companion.
4. Close/reopen MCM, then stop the companion and reopen the page. It should report unavailable/timeout rather than hang the UI or assert that the credential was deleted. Restart the companion and retry.

Without a fresh credential available, steps 1-2 still exercise the essential runtime transport gate. Do not post a secret or field contents when reporting results. A screenshot of status labels is sufficient. TNBProbeCompanion is an optional console ping diagnostic; it never accepts a secret.

The earlier SDK standalone-game probe was rejected before gameplay because that executable requires editor/commandlet mode; the user's subsequent actual-game test provided the runtime proof. Host-side tests alone are not an in-game pass. True API-offline and other hardening scenarios remain separate from closing the companion. Old protocol-1 companion/mod combinations deliberately fail the version check; update both together. This status-page cleanup keeps protocol 2 and does not require a new companion executable or credential import.

## Armory linking in 0.4.1

The Armory action performs character linking and shows saved per-effect reports. Connect the campaign separately in the Avenger/MCM first. Use a separate manual test save and follow [ARMORY_TESTING.md](ARMORY_TESTING.md). No console command is needed. One-time commander effects apply at campaign association, not when selecting a soldier; character confirmation performs real activation. Existing credentials and the startup command are unchanged. Test results and limitations are in [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md).

## Earlier read-only Armory preview (0.3.0)

Historical note: the user supplied two actual-game screenshots on 2026-10-19 confirming this preceding preview menu/dialog. In the 0.4.0 build it is replaced by the workflow below. The old instructions in this section describe 0.3.0 only; they are not a promise that the new Link action is read-only.

After starting companion 0.3.0, load a campaign through AML and open a soldier's Armory main menu. Select The Name Beneath - Journey preview. It should display the organizing commander, Journey/game/lifecycle context, separate Trait/Skill counts when available, and up to five eligible character names. It explicitly states that no association, activation, or bonuses were applied. No character is selected or linked. A full paginated picker is future linking work; this preview labels the first page rather than claiming a complete roster.

Try reopening or cycling soldiers to check that only one menu entry appears. Closing the Armory or changing the selected soldier during a request must not show a stale result for a different soldier. Missing companion/API errors should leave the menu usable. These are the next actual-game checks, not yet claimed as passed. No campaign save transaction or The Name Beneath POST occurs.

The preview uses additive protocol-2 operations that an older 0.2.0 companion does not support; update the companion as well as the mod. Existing Windows credential targets and the startup command are unchanged; no re-import is required.

For developer-only read-only context and first-page roster projection validation, run the published EXE with --dev-config C:\private\integration.env --check-development-journey. It prints only redacted results, stable errors and HTTP status. A temporary HTTP 404/non-JSON failure cleared after the user restarted the sleeping development app; the existing token still worked. Do not infer that a credential needs replacement solely from a hosting error. If the development app is unavailable, first confirm it is running, then repeat the check.

## Storage, configuration, and trust

- Secrets: Windows Credential Manager, target prefix Threadline/TheNameBeneath, partitioned by API origin and Journey.
- Nonsecret context: %LOCALAPPDATA%\Threadline\TheNameBeneath\<endpoint-hash>.context.json.
- Listener: 127.0.0.1:27129, protocol 2, ping/status/test, journey_context/roster, and the new activation_status/activate/activation_ack operations. There is no credential import/remove socket operation, browser HTTP support, arbitrary URL forwarding, or secret-bearing response. Gameplay requests are Journey-pinned; the Armory checks its feature version before enabling the workflow.
- Nonsecret recovery journal: %LOCALAPPDATA%\Threadline\TheNameBeneath\links\<endpoint-Journey-campaign-hash>.json. Receipts recover an exact confirmed intent present in the loaded save; they do not own or automatically restore local pairings after a rewind. Schema 1 remains readable; writes migrate to schema 2 while preserving old receipts. Do not delete this folder to fix a pending link. Removing a credential does not delete receipts or saved XCOM links. Do not downgrade to 0.4.0 after schema migration; use matched Armory feature-2 builds.
- Other local processes under the same Windows account are inside the trust boundary. Loopback is not isolation from malware or user authentication. Future gameplay/event operations must validate the campaign/Journey.
- An occupied port prevents normal desktop startup. Close another companion instance rather than running two writers with separate cached contexts.
- Development protection failures may redirect to Replit login; redirects are rejected without displaying raw URLs or exception messages. Refresh the local protection token, then restart the helper to reload it.

No production secrets, Windows service, firewall rule, scheduled task, AML setting change, or Steam beta change is installed.

## Build and test

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\.scripts\Build-Companion.ps1
```

This runs fake-API/loopback tests, hidden synthetic desktop UI tests, and an isolated Windows credential-vault roundtrip, then publishes Artifacts\Companion\TheNameBeneathCompanion.exe. Synthetic vault entries and unique test directories are cleaned afterward. Tests do not change the real Journey or its stored credential. Exit the companion before replacing its running EXE.

Internal --headless starts only the listener for diagnostics; it cannot import/remove credentials. --ui-self-test uses synthetic data in an invisible test window and tests shared desktop/socket status and shutdown. No GitHub packaging/publication has been performed.

The vendored MCM API license is retained in Docs/MCM_LICENSE.txt and the packaged mod ReadMe.txt.
