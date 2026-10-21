# Modern Multiplayer Mod: networking investigation

Inspected locally on 2026-10-18, after the user downloaded Workshop item 3066536619. The user has excluded the older Tactical Co-Op mod from further investigation.

## Result

The inspected session-related code reuses XCOM's existing online subsystem and game-session interfaces. It adds lobby metadata, matchmaking filters, validation and presentation behavior. It does not provide a reusable Threadline HTTP/TLS client or a mechanism for calling an arbitrary native DLL from UnrealScript.

XCOM does support networking exposed to UnrealScript. The failed implementation gate is specifically the planned DLLBind/dllimport interface, not a general inability to communicate over a network.

## Inspected files

- D:/Steam/steamapps/workshop/content/268500/3066536619/Config/XComEngine.ini
- D:/Steam/steamapps/workshop/content/268500/3066536619/Script/ModernMultiplayerMod.u
- The installed WOTC SDK source for X2MPShellManager, XComShellPresentationLayer, OnlineGameInterfaceXCom and TcpLink.

The Workshop download has no loose Src folder. Its main .u package is 11,870,226 bytes and contains 389 readable class declarations. Those source-text fields were inspected directly from the package; they are not a decompilation of every bytecode object.

Package SHA-256: 1000A27B0FA65356D4A2A4F714DBF97D629BD922D16EC44EB118064719A8993E.

No DLL or EXE is bundled anywhere in the inspected Workshop item.

## Concrete call paths

### Game creation and matchmaking

The embedded source for X2MPShellManager_Overide contains:

- OnlineGame_DoCustomGame: records the selected match classification, then returns super.OnlineGame_DoCustomGame().
- OnlineGame_DoAutomatchGame: records classification, then calls super.OnlineGame_DoAutomatchGame().
- ReadOnlineGameSettings / ApplyInviteRoomSettingsFromLiveSession: query GameEngine.GetOnlineSubsystem().GameInterface.GetGameSettings('Game').

The SDK base implementation of X2MPShellManager.OnlineGame_DoCustomGame calls m_kShellPres.OSSCreateUnrankedGame(false). The presentation layer's OSSCreateGame then calls the online subsystem's GameInterface.CreateOnlineGame. The SDK OnlineGameInterfaceXCom extends the Steamworks game interface and documents Steam lobbies as the matchmaking mechanism.

This is delegation to game networking already compiled into XCOM, rather than loading new networking code from the mod.

### Invites

The embedded XComOnlineEventMgr_Override.OnGameInviteAccepted caches point limits, timers, ranked/automatch flags and encoded room metadata, then calls super.OnGameInviteAccepted. It does not establish an arbitrary web connection or import a custom DLL.

### Browser and combat presentation

UIMPShell_ServerBrowser_Override adjusts browser columns, labels and sorting. XComGameState_BattleDataMP_Override suppresses first-contact visualization. Neither implements an HTTP transport.

## What this means for Threadline

Steam session APIs exchange game/session data with other game clients. Threadline endpoints require authenticated HTTP requests over TLS, with JSON request/response bodies and the correct HTTP verbs and authorization header.

The SDK IpDrv.TcpLink class exposes TCP Open, SendText, SendBinary, ReadText and receive events. It could carry local bridge messages. TCP alone does not supply TLS, certificate verification, clipboard access or Windows Credential Manager operations.

A small companion process was subsequently approved by the user: XCOM talks to it over loopback, and it handles Threadline HTTPS, credential import/storage and eventually the durable event queue. Runtime loopback interoperability still needs its own proof before gameplay integration proceeds. See COMPANION_SETUP.md and IMPLEMENTATION_STATUS.md for the implemented connection milestone.

The other candidate is a custom in-process native loader. The multiplayer mod supplies no such loader, so that route would require a separate investigation and installation design.

## Limits and actions

- Readable source, configuration and native SDK declarations were inspected; the mod was not enabled or executed.
- The game's beta branch and AML selections were not changed.
- Absence of a client in this mod does not prove that every possible HTTPS or native-loading route is impossible.
- No companion, service, listener, credential or Threadline API operation was created during the multiplayer investigation itself. Subsequent companion development and read-only live checks are documented separately in IMPLEMENTATION_STATUS.md.
