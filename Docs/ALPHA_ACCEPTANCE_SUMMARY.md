# Focused alpha acceptance checkpoint - 2026-10-24

These are Product Owner reports from actual gameplay, distinct from offline SDK,
synthetic API, UI and queue tests. Historical checklists may contain older OPEN
notes; this checkpoint records the confirmed outcomes without claiming exhaustive
coverage of every configurable mapping or mod combination.

## Confirmed

- Production onboarding/connectivity to thenamebeneath.com, as far as the local
  distribution allows; final player installation requires Workshop/release assets.
- Commander/character linking, graphical results, save/reload and the guarded
  Avenger invitation. A completed two-linked-character mission reports both subjects.
- Mission and covert-action outcomes, offline capture/delivery on reconnect,
  monthly resource receipts and Scrounger notification/inventory stacking.
- Promotion delivery, recovery of held promotion reports, and replay of a real
  promotion as another journal entry with no additional XP.
- Quick Learner's two intelligence recipients and the Pioneer acquired-trait path.
- A soldier linked while already wounded later reports recovery, without inventing
  a retrospective injury event.
- A failed mission with one linked soldier injured, one linked soldier dead,
  one unlinked soldier injured and one unlinked soldier dead reported the correct
  linked-character and commander facts in the production portal.
- Deja Vu completed-link display, save/reload and the earlier MCM settings behavior.
  The final slider-only simplification still needs the focused check below.

## Final pre-package check

Mod 0.9.5 replaces the Deja Vu grant checkbox with the single XP-percentage slider.
Check 0% and a positive rate on an existing holder, plus one completed new link:
no unlink/removal or lost earned credit; 0% clearly disabled; a positive rate shown
correctly; no selectable bonus row among roster identities. The passive is granted
on new links even at 0%; only future bonus XP is disabled. No retroactive XP award.

After the Product Owner confirms that test, merge/push the feature to main before
packaging from the approved main commit. Do not merge, package or publish before
the confirmation. Workshop upload and downloadable companion release remain
separate delivery steps, not evidence of gameplay testing.

## Explicit alpha limitations / wider-test coverage

- Capture/rescue is implemented but not feasibly reproducible in this solo run.
  Do not manufacture it or label it gameplay-verified; retain it for wider alpha.
- Bond formation/upgrades, negative-condition acquisition/Infirmary cure, and the
  remaining mapping/overhaul combinations are not all natively verified.
- Deja Vu's full numerical XP progression, assist/covert edge cases and external
  mod grants have automated coverage but are not all confirmed in a played campaign.
- Production pool import/alternate appearances, clean-machine installation and
  multi-player Journey-owner workflows need distributed alpha coverage as applicable.
- Player overrides are intentionally open-ended. Passing tests does not certify
  every value, arbitrary third-party implementation or mod loadout.

The Product Owner accepts proceeding toward a limited alpha after the final
Deja Vu check; this is not a claim that every supported path has been exercised.

## Mod 0.9.5 automated verification / local test installation

All 12 SDK probes passed; compilation reported zero errors/warnings. A clean build
without the generated mapping fixture passed the focused promotion, Deja Vu and
presentation probes, and the mapping probe confirmed the fixture is absent.
Slider tests cover a legacy false toggle being ignored, a new passive at 0%,
suppressed zero-percent preview, explicit disabled result/details, preserved banked
credit and switching to a positive rate. These are not native gameplay acceptance.

The local install preserves all 48 shipped mapping rows and five local overrides,
existing MCM percentage settings, saved data and the unchanged companion. Prior
script/config/localization/readme files are backed up under ignored
`Artifacts/InstallBackups/DejaVuSlider-20261024`.

Mod script SHA-256:
`916CB74BBBE93723CF2CCCEFD2D14CA3234CE04908902DE48389915E2865EDF2`.
