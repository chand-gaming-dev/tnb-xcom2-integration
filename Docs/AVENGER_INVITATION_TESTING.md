# Automatic Avenger invitation: controlled retry

Retail follow-up: the user passed Not now, mixed linked/unlinked same-session
reloads, fresh-process review followed by commander and soldier linking, normal
Research/Engineering response, and a completed two-linked-soldier mission on 0.9.1.
The reported invitation/mission-load regression is closed. Optional saved-opt-out,
offline/timing stress and longer campaign acceptance are not implied by that result.

Mod **0.9.1**, companion **0.10.3** unchanged. No credential replacement,
relinking, API change, event rewrite or balance/mapping change is required.
This is a new implementation, not simply re-enabling the old actor. The exact
cause of the original invitation-related crashes was never conclusively isolated.

## Player behavior

- An unlinked campaign at the quiet top-level Avenger can offer **The Name Beneath
  - Connect a Journey?**, with **Review Journey** and **Not now**.
- The companion must be running with a stored Upcoming/Started Journey. Readiness
  is a local cache/status check, not a live API authorization or activation.
- Review Journey opens the existing commander/Journey review directly. The normal
  explicit confirmation still controls Journey start, campaign association and
  one-time bonuses. Soldier linking remains optional. No MCM save prompt is involved.
- Not now / Escape changes no game state or online state. The same campaign is
  not offered again during this XCOM play session, including HUD rebuilds/reloads.
  A fresh XCOM process can offer again if the campaign is still unlinked.
- Linked campaigns and saved reminder opt-outs do not receive invitations.
- MCM > The Name Beneath > Campaign Journey remains the fallback. Its restored
  "Don't remind me" checkbox is campaign-local and writes only on explicit MCM
  Save Changes; save the XCOM campaign too. Uncheck/save to allow future-session
  invitations. This preference is not changed by dismissing the automatic dialog.
- Readiness is canceled if the grid loses focus or is removed. Quiet-screen retries
  stop after about ten seconds; an unavailable companion does not block gameplay.
  If it is started later, leave and return to the top-level Avenger to retry, or use MCM.

## Required first checks

Offline validation: the WOTC SDK compiled this build with zero errors/warnings;
all nine native probe commandlets passed, including invitation lifecycle-policy
checks. The unchanged companion's synthetic event/replay/restart tests also passed
with the new native fixtures. These do not replace the retail checks below.

Use separate non-Ironman slots. Preserve the existing pre-link save and the only
campaign copy. Do not invent live events or reset journals to manufacture a test.

1. Start the companion normally; confirm the intended Journey. Fresh-start XCOM
   and load the **unlinked/pre-link** strategy save. Let the Avenger settle. Confirm
   the invitation appears without opening MCM, and the text/buttons are readable.
2. Choose **Not now** (or Escape). Enter Research/Engineering/Armory, return, and
   reload that same save several times. No repeated invitation this play session,
   no crash, no bonuses, no Journey start/association and no MCM save prompt.
3. Fresh-start XCOM with the same unlinked save. Choose **Review Journey**, inspect
   commander benefits and cancel/back out before final confirmation. No association
   or one-time bonus. Keep normal game navigation and repeated reloads working.
4. Fresh-start, review again and explicitly confirm. Verify the expected commander
   resources/staff once. Save separately, reload linked -> unlinked -> linked in
   the same process, and confirm no crash or repeated grant. Linked saves show no
   invitation; manual saved commander reports remain available through MCM.
5. Load an unlinked save and immediately open another screen, pause/load menu or
   reload before readiness completes. No delayed dialog should appear over another
   screen or from an old world. Repeat with the companion closed/restarted.
6. From a linked save, launch a tactical mission and return to strategy. Repeat
   with a soldier link if convenient. No mission-load regression or surprise popup.
7. Optional opt-out check: in a separate unlinked save, check the MCM reminder
   opt-out, explicitly Save Changes and save the campaign. Fresh-start/reload:
   no invitation. Uncheck/save and test a fresh play session again.

The critical gates are repeated same-session save loading, native dialog callback
teardown and mission transitions. Offline policy tests cannot establish those.

## Fail-safe and diagnostics

To disable only automatic invitations, close XCOM and set this in the installed
mod's `Config/XComTheNameBeneath.ini`, then restart:

```ini
[TheNameBeneath.TNB_AvengerJourneyPrompt]
bEnableAutomaticInvitations=false
```

MCM/manual campaign linking and all existing saved bonuses remain available.
The implementation also honors any older saved campaign opt-out.

Logs use the `TNB_PROMPT` marker: scheduled, checking_local_status,
offered_read_only, dismissed_no_changes, opening_existing_review, ignored_stale_answer,
or stopped with a bounded reason. No credentials, Journey/campaign IDs, names or
network payloads are logged by these markers. Preserve crash/launch logs privately;
do not publish full gameplay data automatically.
