# Commander/soldier UI patch and first mission smoke test

Mod UI patch **0.7.1**, using the existing **companion 0.7.0**. No new credential,
re-link, Journey, mapping configuration or companion executable is required.

## Screenshot feedback addressed

Reviewed Steam screenshots `20261019221352_1.jpg`, `20261019221451_1.jpg` and
`20261019221506_1.jpg`: the older save initially has no cached Journey title; after
refresh it displays **Test Journey 1**. Soldier cards show the frozen Will/sight
bonuses, Low Profile and the missing optional `SingleReloadMrC` mapping. The old
commander report and missing ability expose an invalid texture as a rainbow panel.

- Soldier details: explicit 20-point body text, fewer repeated fields/blank lines;
  technical source IDs, template, mapping key/revision and configured/applied values
  remain available through **Mapping details**. Full installed ability help stays
  readable/scrollable. Stat summary icons now have visible framed backgrounds.
- Commander: **MCM → The Name Beneath → View Commander & Bonuses → Open** now
  opens an independent graphical saved profile with resource/staff icons, actual
  committed one-time deltas, positive/negative colors and ONE-TIME/ONGOING/MONTHLY
  badges. Select a card for its scope/timing. Mapping details and Journey details
  are separate buttons; Refresh Journey name remains a pinned read with cosmetic
  metadata only. No giant image panel remains on the saved commander screen.
- Missing/broken ability artwork: a verified core unknown-ability icon replaces
  the invalid Insignia path; the unavailable-template explanation remains visible.
  Setup/picker fallback images also use real game artwork. No optional mod is added.
- Existing campaign-link confirmations, rewards, source mappings and reporting are
  unchanged. Opening either saved profile stays offline-capable. Refresh/save the
  title normally to retain it; no automatic network fetch or Avenger prompt is added.

First check the two reports, Mapping details, list/detail scrolling, Back/Escape and
name refresh once. Save to a separate slot and do the linked-save reload check.
If anything crashes or a placeholder remains, keep the screenshots and game logs.

## Console-assisted mission smoke test

Use the dedicated test Journey, a Started state and separate saves. Keep the
companion running with the matching Journey credential. This is a **delivery smoke
test**, not proof of ordinary combat, injury, promotion or optional perk behavior.

1. Load a linked **strategy** save and verify **MCM → Gameplay reporting** shows a
   capture timezone and verified native transition clock. Record the starting counts.
2. Launch a **new** tactical mission from strategy after setup; bring the linked
   soldier. An old in-progress tactical save may have no captured launch/roster and
   is not a valid first test. Wait for tactical initialization to finish.
3. Use your normal tactical auto-win command. In the installed WOTC SDK,
   `XComTacticalCheatManager.EndBattle(optional bool XComWins=true)` calls
   `X2TacticalGameRuleset.EndBattle` with the human/AI winner; `EndBattle true` is
   therefore a suitable first candidate. Modded mission scripts may behave
   differently. Do not use campaign-end/win-game commands or bypass the debrief.
4. Complete the normal debrief/return to the Avenger. Give the companion time to
   drain reports, then refresh MCM reporting. Inspect the portal history for one
   mission start, one linked-character deployment and one mission completion with
   the correct outcome/instances. Commander-only participation has no deployment
   record. Other genuine observed transitions may add events; do not assume the
   total accepted count must be exactly three.
5. Capture MCM reporting and portal-history screenshots. API acceptance and XP are
   separate: the backend decides XP, and receipts do not contain an XP amount.
6. Save/reload and refresh/retry only eligible reports. The same occurrence must not
   produce another mission award. If paused/held/conflicted, stop and preserve the
   diagnostic/journals; do not delete receipts or mint another event ID.

The native source hooks are `OnPreMission` (freeze launch/roster), tactical start,
`CleanupTacticalMission` (capture outcome), and `OnPostMission` (strategic completion).
The auto-win command reaches the normal ruleset entry point, but only the retail
test can establish that the complete return path fires for this mod setup. It will
not establish ordinary kills, wounds, actual promotions, Infirmary cures or covert
actions. Continue [EVENT_REPORTING_TESTING.md](EVENT_REPORTING_TESTING.md) afterward.
