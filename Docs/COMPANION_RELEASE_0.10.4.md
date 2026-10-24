# The Name Beneath - XCOM 2 Companion 0.10.4 (Alpha)

Windows x64 standalone companion for **The Name Beneath mod 0.9.5**.
Release tag: `companion-v0.10.4-alpha.1`.

## Download and run

Download **TheNameBeneathCompanion.exe** from this release's Assets and double-click
it. No PowerShell command, source build, .NET SDK/runtime installation or external
game DLL is required. GitHub's automatic source archives are not the player app.
Install the matching [[WOTC] The Name Beneath mod from Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3826279674)
and enable its required dependencies. The mod is not bundled with the companion;
do not enable both a local development copy and the Workshop copy together.

The companion connects to **https://thenamebeneath.com/** by default. Paste your
Journey credential into the masked field and select **Validate and save**; it is
stored in Windows Credential Manager. No Replit key or development configuration
is needed. Keep the companion running alongside XCOM for linking and online report
delivery; closing it does not close the game or remove saved bonuses.

## Included

- Journey/commander connection, soldier linking support and readable connection
  and reporting status.
- Durable gameplay report delivery, including promotion replay records whose
  additional XP recognition is controlled by the service.
- Journey character-pool ZIP download and merged `.bin` export using Save As.
- Production API defaults and the promotion-report timezone validation fix.

The matching mod includes the accepted Deja Vu passive, configurable with one
0-100% promotion-XP slider (default 5%). At 0%, future bonus XP stops; links, the
passive and earned credit remain. This is local XCOM promotion credit, not online XP.

## Requirements and alpha limitations

- Windows x64, XCOM 2: War of the Chosen, and the matching mod 0.9.5 enabled.
- WOTC Community Highlander (tested/minimum 1.31.3 beta) and Mod Config Menu.
  With Alien Hunters DLC installed/enabled, use the matching beta Highlander plugin.
  Optional mapped abilities need their separate providers; see the
  [README links](https://github.com/chand-gaming-dev/tnb-xcom2-integration/blob/companion-v0.10.4-alpha.1/README.md#requirements).
- A production Journey credential. Development credentials and queues are not
  migrated to production. Back up saves; a fresh campaign is recommended for alpha.

Focused gameplay acceptance passed, including linked-soldier injury/death,
recovery, two linked soldiers in a mission, promotion replay without duplicate XP,
and the final Deja Vu settings. Capture/rescue, bonds, other lifecycle/overhaul
combinations and all numerical XP edge cases are not exhaustively gameplay-tested.
See [the acceptance summary](https://github.com/chand-gaming-dev/tnb-xcom2-integration/blob/companion-v0.10.4-alpha.1/Docs/ALPHA_ACCEPTANCE_SUMMARY.md).
Independent clean-machine
and wider player installation coverage remain alpha work; this release does not
certify arbitrary mod combinations.

## Unsigned download and licenses

The EXE is **unsigned**. Windows or browser warnings may occur. Download only from
this repository's official release and compare its SHA-256 with `SHA256SUMS.txt`:

```powershell
Get-FileHash .\TheNameBeneathCompanion.exe -Algorithm SHA256
```

This optional verification command is not required to launch the app. Checksums
verify file integrity against the published value; they do not replace publisher
signing or guarantee safety. Do not disable system-wide security protections.
License and third-party notices accompany the executable; branding remains excluded
from the source-code MIT grant. No credentials, personal pools, saves or gameplay
journals are included in the release.
