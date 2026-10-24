# Official release checklist

Status: companion alpha publication approved on 2026-10-24 after the final Deja Vu
test passed. Workshop publication remains a separate Product Owner step. This
checklist does not mark wider gameplay coverage or clean-machine testing complete.

- [x] Complete the agreed focused gameplay acceptance and mapping review; obtain
  approval to publish the limited companion alpha. Wider test limitations remain
  in [the current acceptance checkpoint](ALPHA_ACCEPTANCE_SUMMARY.md).
- [ ] After the final Deja Vu slider acceptance, merge/push the approved feature
  to `main` before packaging. Build/tag the approved `main` commit, not an
  unmerged feature or a dirty working tree. See [the current acceptance
  checkpoint](ALPHA_ACCEPTANCE_SUMMARY.md).
- [ ] Build the companion from the reviewed release commit using the Win64 publish
  profile, producing the self-contained `TheNameBeneathCompanion.exe`.
- [ ] Run the companion regression tests and verify the exact published executable,
  not only the development build.
- [ ] Independently confirm startup on a clean Windows machine without a .NET SDK
  or separately installed .NET runtime. A self-contained build/local test is not
  evidence of a separate clean-machine test.
- [ ] Confirm the public deployment/API configuration and setup instructions do
  not depend on developer-only origins, protection tokens or private source trees.
- [ ] Create a GitHub Release associated with the approved source tag/commit.
  State the matching mod and companion versions and any compatibility limitations.
- [ ] **Attach the ready-to-run Windows x64 `TheNameBeneathCompanion.exe` to the
  release.** Include SHA-256 checksums and the applicable license/third-party
  notices. The automatically generated source-code ZIP is not the player download.
- [ ] Document that the initial alpha executable is unsigned and may trigger
  Windows/browser warnings. Show checksum verification against the official
  release; do not present checksums as publisher signing or ask players to
  disable system-wide security protections.
- [ ] Link the companion download prominently from the README and player setup
  instructions. Explain that no source build, .NET SDK/runtime installation or
  external DLL is required; the companion runs separately alongside XCOM.
- [ ] Provide the matching mod installation route and clearly list Highlander,
  MCM and any optional mapped ability providers, with links and supported versions.
- [ ] Verify the downloaded release asset matches its published checksum and
  completes a fresh player setup without development tooling.

Keep compiled binaries in GitHub Releases, not source commits. Never include
credentials, `.env` files, gameplay journals, personal character pools/saves,
SDK/game binaries or other mods' content. Existing development builds are not
official releases merely because their source is public.
