# Repository instructions

- Public product name: **The Name Beneath**. Use it in docs, UI, comments and new
  code. Follow `Docs/PUBLIC_NAMING.md`; retain only its explicitly approved API,
  environment and persisted-storage compatibility identifiers.
- Both the mod and companion belong in this repository. Keep private backend
  source, credentials, gameplay journals, personal pools/saves, SDK/game dumps and
  compiled distributions out of commits. Preserve third-party notices.
- Protect saved-game/history and credential compatibility. A naming cleanup must
  not change event identities, payloads, frozen bonuses or stored data locations.
- Make implementation changes on focused branches; run relevant synthetic tests
  and distinguish them from actual in-game acceptance. Do not claim gameplay
  acceptance from SDK or companion tests alone.
- Preserve source/localization encodings and existing user changes. Do not install
  over a running companion or game. No custom DLL is required by this integration.
