# Official release checklist

Status: [companion 0.10.4 alpha published](https://github.com/chand-gaming-dev/tnb-xcom2-integration/releases/tag/companion-v0.10.4-alpha.1)
on 2026-10-24 after the final Deja Vu test passed. Built from verified `main`
commit `c1af096922776d4b5905e946d82ab173a0ee6348`; matching mod version 0.9.5.
The Product Owner uploaded [[WOTC] The Name Beneath to Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3826279674);
the listing was accessible on 2026-10-24. Fresh Workshop installation, wider
gameplay coverage and independent clean-machine testing are not marked complete.

- [x] Complete the agreed focused gameplay acceptance and mapping review; obtain
  approval to publish the limited companion alpha. Wider test limitations remain
  in [the current acceptance checkpoint](ALPHA_ACCEPTANCE_SUMMARY.md).
- [x] After the final Deja Vu slider acceptance, merge/push the approved feature
  to `main` before packaging. Build/tag the approved `main` commit, not an
  unmerged feature or a dirty working tree. See [the current acceptance
  checkpoint](ALPHA_ACCEPTANCE_SUMMARY.md).
- [x] Build the companion from the reviewed release commit using the Win64 publish
  profile, producing the self-contained `TheNameBeneathCompanion.exe`.
- [x] Run the companion regression tests and verify the exact published executable,
  not only the development build.
- [ ] Independently confirm startup on a clean Windows machine without a .NET SDK
  or separately installed .NET runtime. A self-contained build/local test is not
  evidence of a separate clean-machine test.
- [x] Confirm the public deployment/API configuration and setup instructions do
  not depend on developer-only origins, protection tokens or private source trees.
- [x] Create a GitHub Release associated with the approved source tag/commit.
  State the matching mod and companion versions and any compatibility limitations.
- [x] **Attach the ready-to-run Windows x64 `TheNameBeneathCompanion.exe` to the
  release.** Include SHA-256 checksums and the applicable license/third-party
  notices. The automatically generated source-code ZIP is not the player download.
- [x] Document that the initial alpha executable is unsigned and may trigger
  Windows/browser warnings. Show checksum verification against the official
  release; do not present checksums as publisher signing or ask players to
  disable system-wide security protections.
- [x] Link the companion download prominently from the README and player setup
  instructions. Explain that no source build, .NET SDK/runtime installation or
  external DLL is required; the companion runs separately alongside XCOM.
- [x] Provide the matching mod installation route and clearly list Highlander,
  MCM and any optional mapped ability providers, with links and supported versions.
- [x] Download the release assets and verify their published checksums. All seven
  assets matched; the downloaded EXE passed its isolated connection self-test.
- [ ] Complete fresh player setup with the published Workshop mod and companion,
  without development tooling.

All four regression suites passed against the exact single-file release EXE
(connection/credentials, UI, pools, events). Its embedded product version includes
the source commit above. It is self-contained with .NET/Windows Desktop 10.0.12
and is unsigned. No release assets were committed to source control.

Executable SHA-256:
`64087e53dcd64d5ce13966af12b944b515a0e712888d8295531aa095223a8aa7`.

Keep compiled binaries in GitHub Releases, not source commits. Never include
credentials, `.env` files, gameplay journals, personal character pools/saves,
SDK/game binaries or other mods' content. Existing development builds are not
official releases merely because their source is public.
