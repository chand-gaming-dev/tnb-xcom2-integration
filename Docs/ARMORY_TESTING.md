# Armory linking: first actual-game test

**Current feedback build 0.5.1:** use MCM-only campaign setup; no automatic Avenger prompt should appear. The connected MCM action reads View Commander & Bonuses; linked Armory menu reads The Name Beneath - Traits & Abilities. Follow FEEDBACK_AND_NEXT_TESTS.md first for reload/offline-report testing. User has confirmed stat/Low Profile persistence and the missing optional ChamberRound skip in the preceding build. Historical steps below still apply to pairing invariants, not to older menu labels/reminders.

Development build: companion 0.4.1 and matching Armory feature-2 mod. This replaces the earlier read-only preview. No console command is needed.

1. Use a **separate manual test save**, not your only campaign save or an Ironman campaign. Record the selected soldier's stats and current Supplies/Intel/staff/Avatar progress. Loading an older XCOM save cannot undo remote character activation.
2. Start the companion as usual with `.scripts/Start-Companion.ps1 -Development`, then launch XCOM through AML. Existing credentials do not need re-importing. Keep the companion running.
3. Connect the campaign separately using the Avenger reminder or **MCM > The Name Beneath > Campaign Journey > Connect / View Journey**. See CAMPAIGN_JOURNEY_TESTING.md. Before association, the Armory must only explain where to connect; it must not associate the campaign or apply commander effects itself.
4. Inspect the layout, select effect details, then cancel/back out once. Confirm no campaign rewards or character activation occurred. Reopen the action.
5. Select **Connect Journey** on the campaign setup screen, review the commander/Journey and permanence warning, then confirm only when ready. This commits the frozen commander effects and applies one-time rewards. Review the resulting effect rows, including actual clamped deltas or no-change results. Save in the separate manual slot. No soldier links are needed for these bonuses.
6. Close campaign setup, open the intended soldier's Armory and select **The Name Beneath - Link character**. Navigate roster pages if present. Select the intended character and inspect the permanent-pairing confirmation. Cancelling must not reserve or activate a character. Confirming persists the local reservation and companion intent, then POSTs only character_id and bind_existing. The actual frozen Trait/Skill snapshot is not available in the roster response, so a first activation's bonus details follow the successful local commit rather than being invented before it.
7. After confirmation, expect a link-completed message and one list row per characteristic/effect, including negative, unmapped, disabled, missing-template and already-present results. Stat totals are separate rows. No additional effects should be claimed when everything is unmapped/skipped. Save again.
8. Back out and reopen the soldier: the menu should say **Linked character**, with the same frozen report. Stop the companion and reopen the linked report; it should remain readable. Restart the companion before linking another soldier. Try a second soldier: a locally reserved/linked character must not be offered as a fresh pairing.
9. Reload the post-link manual save. Verify the same link, stats and one-time rewards, with no second application. Then test a mission launch/return for the linked soldier's earned abilities. Not every optional ability/modded-class combination has been validated yet.

Do not deliberately kill XCOM mid-write on the first test. Recovery/timeout and older-save tests follow the basic successful link. A pending intent **present in the loaded save** offers Resume for its original character/unit only. An activated receipt for that saved intent can finish its original local link even after the Journey finishes; a new/pending activation still requires Started. A soldier fingerprint mismatch blocks recovery rather than guessing a target. Copied/divergent campaign branches and multiple concurrent XCOM processes are not yet validated.

## Approved save-rollback behavior (0.4.1)

Create a manual save after commander association but BEFORE confirming any soldier link. This keeps commander behavior out of the rollback test.

1. Link soldier A to character C and record the instance/snapshot, applied effects and resulting stats. Save to a different slot.
2. Reload the pre-link slot. A must remain unlinked with the pre-link stats. Do not restore automatically from the companion journal. Leaving the Armory without linking is a valid opt-out.
3. Open soldier B's picker and choose C. It should use C's already established Journey instance and original snapshot, but resolve current local mappings once against B's pre-link stats. A remains unlinked in this loaded timeline. Existing Threadline activation/history is not erased.
4. Reload the pre-link slot again and choose a different character D for A. This should succeed; C's instance remains intact but unused locally in that timeline. The companion must not apply old effects or force the old pairing.
5. Reload the POST-link slot from step 1. A must still have exactly its saved effects. Reopening/retrying/reporting must not re-resolve mappings, add stats again, or offer reassignment. C remains unavailable to a second soldier in this same loaded timeline.
6. Optional balance test: change mappings, restart, and load the pre-link slot. A newly confirmed link may use current mappings. Loading an existing post-link slot must retain its old frozen mappings instead.

Only the loaded save decides whether a local link exists. A saved pending intent is still an in-progress choice; use a slot from before confirmation to choose differently. Do not delete recovery files or detach components to force reassignment. Missing/inconsistent bonus ledgers fail safely without subtracting or reapplying stats; the campaign remains playable. The new persistent unit-value marker is an additional guard for new links; valid 0.4.0 link records remain idempotent without being regranted.

If the Replit development app sleeps, restart it and retry; do not delete the credential or recovery journal. If an error occurs, send a screenshot of the safe error text and say which step failed. Do not send the credential textbox, .env contents or protection-token URLs. For the first handoff, checking the picker/confirmation layout before pressing any irreversible confirmation is useful on its own.

After the basic link/save/tactical checks, separately exercise commander percentage gains and Scrounger per RESOURCE_COVERAGE.md. The Scrounger banner should explicitly name the awarded item. Mission/promotion/injury/death event delivery is not part of this build yet.
