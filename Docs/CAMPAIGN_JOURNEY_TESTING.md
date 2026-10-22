# Campaign Journey setup and fresh skill test

Current mod 0.9.1 restores the automatic Avenger invitation with new lifecycle
ownership and read-only readiness. Start with AVENGER_INVITATION_TESTING.md for
the controlled reload/transition retry. Review Journey reaches the existing
confirmation directly; MCM is the fallback and saved opt-out UI. Companion remains
0.10.3. Older milestone instructions below are historical where superseded.

**Current 0.7.0:** Journey title appears in setup/confirmation and the saved report;
Refresh Journey name is cosmetic only. Follow [JOURNEY_AND_SOLDIER_UX_TESTING.md](JOURNEY_AND_SOLDIER_UX_TESTING.md)
for the current UI/reload checks. Automatic Avenger prompts stay disabled; MCM is the
campaign entry point. IDs and frozen effects remain unchanged. Older notes below are historical.

**Current 0.5.1 diagnostic build:** automatic Avenger reminders are disabled, including prompt-actor creation. Use MCM > The Name Beneath > Campaign Journey > Connect Campaign Journey / View Commander & Bonuses > Open. The old reminder checkbox is not shown; saved preference data is retained but dormant. Follow [FEEDBACK_AND_NEXT_TESTS.md](FEEDBACK_AND_NEXT_TESTS.md) for the current consolidated acceptance sequence. Reminder instructions below describe the earlier build, not expected behavior in 0.5.1. The user has now verified Low Profile addition/persistence and missing ChamberRound handling; tactical behavior is still a separate gate.

Lifecycle amendment (2026-10-19): use companion 0.5.0 and the matching mod after deploying the API/portal management branch + forward migration 0014. A fresh credential automatically includes `journey:manage`; older keys are not elevated. The earlier 0.4.1 instructions below remain applicable to manual/Started connections, except that an Upcoming Journey may now be started explicitly at confirmation.

## Explicit Start Journey and connect

1. Complete the XP/Skill purchases first, then create a separate **Upcoming** XCOM test Journey. Do not start it in the portal for this test. Issue its new credential through the updated portal (no scope choices) and validate/store it in companion 0.5.0. Do not paste secrets into chat/logs.
2. Import, Test connection, MCM Refresh/Test, load a campaign and dismiss an Avenger reminder. None may start the Journey. Before the final confirmation, the portal must still show Upcoming and XCOM must have no new commander rewards.
3. Open Campaign Journey, review every proposed commander effect and select **Start Journey and connect campaign**. Cancel the final **Start and connect** dialog once: no lifecycle or reward change. Reopen/review and confirm when ready.
4. Expect remote Started first, then the local saved commander report/rewards. No soldier is activated. Save XCOM. Repeatedly view/reload the post-association save: no second remote start, bonus grant or snapshot update.
5. With an older four-scope credential or old API/companion, Upcoming setup must explain manual portal Start or updating/reissuing the key. It must not silently elevate permissions. A manually Started Journey remains compatible with the older key.
6. A Finished Journey must require explicit portal Reopen; setup never automatically reopens/finishes. Reopen keeps history/XP/Skills and existing Journey instances/snapshots. It does not make an existing zero-Skill snapshot into a fresh Skill snapshot.
7. A timeout/cancel after sending Start may leave the server Started but XCOM unassociated. Retry reads current state and presents the remaining confirmation without repeating rewards. Do not force-kill the main campaign to test failure. If traits/skills change during Start, require refreshed bonus review before local commit.
8. API tests separately cover finish/reopen/finish, concurrent starts, audit attribution, stale versions, expiry/revocation and no duplicate awards. Native gameplay/Flash/camera/mod compatibility and purchased Skill injection still require the user's actual-game testing; compilation and fake API results are not those passes.

2026-10-19 UI amendment; companion remains 0.4.1, protocol 2, Armory feature 2. No new API or credential format. This checklist is not a completed in-game acceptance result.

## Campaign setup without soldiers

1. Use a separate non-Ironman manual test save with no campaign association. Start the configured companion, then load into the Avenger. Wait at the facility grid, outside tutorial objectives, camera movement, other dialogs and facilities. A reminder may appear after a few quiet seconds. It applies nothing by itself.
2. Choose **Not now**. No campaign link, character activation, bonus or persistent opt-out is created. Visiting facilities, rebuilding the HUD and returning from a mission must not repeat an already offered reminder during this session. Loading an unconnected strategy save later permits it again.
3. Open **Mod Config Menu > The Name Beneath > Campaign Journey > Connect / View Journey**. The dedicated screen should identify commander/Journey and list every proposed Trait/Skill effect. Review details, cancel/back out, and verify no reward. Merely opening setup also suppresses another automatic reminder for this session.
4. Reopen and select **Connect Journey**. Check the confirmation identifies the intended Journey/commander before accepting. Review the saved effect report and actual one-time deltas. Save the campaign. Zero soldier links is a supported configuration; supported commander bonuses must function on their own.
5. Reopen setup repeatedly, including with the companion closed. Saved commander details must remain readable offline. No rewards repeat, existing mappings are not re-resolved and switching the companion's credential cannot replace this saved association. Refresh/Test or reopen the MCM page to refresh its summary after returning from setup.
6. Load the post-association save and verify the same commander effects with no prompt or duplicate rewards. Loading a pre-association save removes this local link/benefits; it does not roll back any remote character activation.
7. Before association, use MCM's **Don't remind me to connect this campaign**, choose **Save Changes**, and then save the XCOM campaign. Reload: no reminder, but manual setup remains available. Unchecking and saving allows a future-load reminder again. The preference is campaign-local, not a global mod setting; loading an older save can restore its older preference. Cancelling MCM without saving changes must not persist a checkbox edit.
8. Main-menu/tactical MCM must disable campaign setup and preference controls, while retaining connection Refresh/Test. An unavailable or unconfigured companion must not cause repeated error popups. Starting/configuring it later allows the reminder at a quiet Avenger moment (local readiness checks are at most once per minute); setup verifies the remote Journey online before enabling confirmation.
9. Open an unassociated soldier's Armory: show setup guidance only. After campaign association, the existing soldier picker/recovery/report flow remains available. Follow ARMORY_TESTING.md for save-authoritative pairing and duplicate-stat checks.

## Fresh commander and character with two Skills each

The user reported successful preceding tests but explicitly had no purchased character Skills. Actual ability injection is therefore still an open gate, not a passed test.

- Create dedicated development-only test identities and a clearly named XCOM integration Journey; leave normal characters/Journeys untouched. The name alone is not a backend sandbox or XP-isolation flag. No special test-Journey mode or general XP-grant API has been found or added.
- The current growth policy charges 1,000 XP for the first Skill and 2,000 for the second: **3,000 available canonical XP per fresh identity**, 6,000 total. XCOM soldier XP/console promotion does not fund The Name Beneath Skill purchases. Merely creating a Journey grants no XP.
- Decide the development-only XP fixture once the identities exist. XP is derived from recorded event awards, not a directly editable balance; do not silently alter the production growth policy or fabricate normal campaign events. An explicitly authorized isolated fixture/setup Journey is preferable to changing everyone's prices. No XP grants, purchases, events, identities or Journeys have been created by this implementation.
- Purchase the two commander Skills through the portal **before XCOM campaign association**. Quartermaster plus Scrounger covers a +15 Supplies one-time reward and a recurring supply-drop item. Counterintelligence can substitute, but requires eligible Avatar progress to observe a negative pip; zero eligible progress correctly reports no change rather than deferring a reward.
- Purchase two character Skills **before the character's first activation in the target Journey**. Reusing an already activated instance returns its original snapshot even if canonical Skills were bought later. Use a fresh target Journey/instance for initial-link skill testing. If XP setup itself needed an activation in a separate setup Journey, do not reuse that setup instance as the target test.
- Select two Skills with installed ability templates for the positive test. For example Evasive Maneuvers maps to LightningReflexes and Cover Discipline to LowProfile; confirm template availability in this mod setup first. A visible missing-template skip is correct error handling but is NOT proof of successful ability injection. Optional-template/mod availability remains separate from the API Skill projection.
- Confirm two separate Skill records in the frozen report, launch a tactical mission and verify each ability's actual conditions/effect. Passive abilities need not have an action-bar button. Reload/reopen/retry: no duplicate abilities or stat applications. Test missing-template handling separately with an explicitly missing override and a fresh pre-link timeline, leaving the shipped config unchanged.

When the new identities/Journey are ready, provide their names/IDs (never the bearer secret in chat) so the exact isolated XP setup can be reviewed before it runs. Enter the new Journey credential in the companion normally.
