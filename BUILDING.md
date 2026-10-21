# Building locally

Use Windows. Clone the complete repository; both projects and `.scripts` are
needed. Normal builds do not require the private Threadline source repository.

## Companion

Install the .NET 10 SDK with Windows desktop targeting support. From the root:

```powershell
powershell.exe -NoProfile -File .\.scripts\Build-Companion.ps1
```

The script runs synthetic connection/activation, UI, character-pool and event
tests, then publishes the self-contained Win64 executable to
`Artifacts/Companion/ThreadlineCompanion.exe`. Use `-TestOnly` to skip publication.
Tests use fake HTTP handlers, temporary data and synthetic credentials, not a
live Journey. Credential tests require access to Windows Credential Manager.
Run them outside an active game/companion session. Native cross-language event
fixtures and real gameplay acceptance are additional checks, not covered by this
script alone. No personal `.bin` fixtures are needed for the synthetic pool tests.

Start an unprotected deployment explicitly:

```powershell
.\Artifacts\Companion\ThreadlineCompanion.exe --api https://your-api-origin.example/
```

For a protected development origin, copy `.env.example` to the ignored `.env.local`,
set its API origin/protection token privately, then run:

```powershell
powershell.exe -NoProfile -File .\.scripts\Start-Companion.ps1 -Development
```

An existing private configuration elsewhere can be used explicitly:

```powershell
powershell.exe -NoProfile -File .\.scripts\Start-Companion.ps1 -Development -DevelopmentConfig 'C:\private\integration.env'
```

Paste the Journey credential in the companion, not the command line. Developer
checks can optionally read `THREADLINE_JOURNEY_CREDENTIAL` from the private file;
this does not automatically import it into the app's vault. `-Development -CheckOnly`
performs the existing read-only connection check, with no listener or credential
installation. Development protection tokens are only supported for Replit origins.

Keep the default loopback port 27129 unless you also change `CompanionPort` in
the mod's configuration. The listener binds only to localhost. Do not expose it
to the network or commit anything from the app's local data directory.

## XCOM mod

Install XCOM 2: War of the Chosen and the War of the Chosen SDK / ModBuddy through
Steam, plus the Highlander dependency. The SDK and its base game script sources
must remain local and are not redistributed here.

Open `TheNameBeneath.XCOM_sln` in WOTC ModBuddy and configure its game/SDK paths.
The included X2ModBuildCommon integration invokes `.scripts/build.ps1`. When
compiling against Highlander, configure its `IncludeSrc` option in that entrypoint
using the matching installed Highlander `Src` directory or matching source
checkout; the file documents both options. The build helper expects the WOTC
game root, not its `XComGame` subfolder. It builds and deploys to the configured
game, so close XCOM first and inspect the configured paths before building.

The entrypoint can also be invoked from the appropriate SDK/PowerShell build
environment with `-srcDirectory`, `-sdkPath`, `-gamePath`, and `-config default`
or `-config debug`. See the vendored
[build-system documentation](.scripts/X2ModBuildCommon/README.md) for prerequisites
and advanced options. The tested script package is `TheNameBeneath.u`; do not
commit it. Enable the resulting mod and its declared dependencies in your launcher.

Do not rebuild or replace packages while XCOM is running. Companion-only changes
do not require a game package rebuild. Neither build requires a custom DLL.

## Artwork and publishing

The checked-in icon and preview are sufficient for builds. Optional regeneration
scripts use a separately installed `sharp` package resolved from the checkout
argument; their private Threadline checkout examples are conveniences, not normal
build dependencies. Preserve the artwork's separate licensing status.

Create release archives from reviewed build outputs separately. Never package
credentials, development `.env` files, gameplay journals, personal pools, saves,
SDK/game binaries, or source from other Workshop mods. The first repository
snapshot is source only; it does not publish a Workshop item or service backend.
