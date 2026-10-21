The Name Beneath - factual events mod 0.9.0 / XCom 2 companion 0.10.2

New committed captures and confirmed returns from captivity report Character
captured/freed. Bond formation and upgrades now report Relationship formed/developed
using the new The Name Beneath contracts. These fact-only types award zero XP; historical
milestones, accepted facts and queued legacy reports are not rewritten. Missing
native relationship data is not treated as bond breakage. Existing links remain.

The companion now has separate Journey, Gameplay reporting and Character Pools
tabs, grouped sections and persistent action feedback. Its title identifies XCom 2.
Soldier ability cards reflect the currently installed ability provider; original
link-time results/notes remain in Mapping details. No bonuses are re-applied.

Both mod and companion need updating. Save in a separate test slot. See
Docs/CAPTIVITY_RELATIONSHIPS_UX_TESTING.md for the focused acceptance sequence.
Native-game acceptance remains pending; offline probes are not campaign proof.
No automatic Journey prompt, live API mutation, mapping change or GitHub release.

Historical Scrounger flavor text mod 0.8.7 / companion 0.8.0:

The Scrounger popup now describes finding the named item while rummaging around
the Avenger, without the supply-income/collection explanation. Item name/image,
normal popup lifecycle, native stacking, monthly award timing and guard, reporting
and all saved state are unchanged. No relink or companion update is needed.
Generic portal Mission succeeded/failed headings are intentionally retained;
game-supplied descriptions distinguish covert actions. No API/portal change needed.

Previous covert/inventory notes (retained):

Scrounger now uses native item acquisition/stacking, respecting modified and unique
items. Existing separate inventory rows are not migrated or regranted. Known
LWOTC Easy/Moderate/Hard failure risks now report failed covert-action completion;
unrecognized reward suppression stays unknown. New event descriptions say covert
action; portal headings remain a separate API/portal display change. Event types,
IDs, XP policy, links and monthly award protection are unchanged. No companion
update or relink required. See Docs/COVERT_AND_INVENTORY_TESTING.md.

Previous supply-display notes (retained):

Scrounger item names no longer show literal native color tags. Supply collection
flyovers now match the actual adjusted gain, for both positive and negative
modifiers, without changing inventory again. The collection popup retains its
exact breakdown and adds brief sign-specific recovery/loss flavor text. The large
month-end report and base drop previews remain unchanged. Existing saves/links,
monthly item protection and the companion remain compatible. No relink is needed.
See Docs/SUPPLY_DISPLAY_TESTING.md.

Previous monthly-reward notes (retained):

Scrounger now grants one configured common item at each monthly rollover,
including zero-income months, with a dismissible item popup after the monthly
report. Existing once-per-month records are preserved; loading does not grant.
Supply-drop collection saves a receipt for the existing completion/instant popup:
base supplies, commander modifier and actual total, including installment rounding.
Existing saves/links/mappings and mission reporting remain compatible. No companion
or API update is required. See Docs/COMMANDER_MONTHLY_REWARDS_TESTING.md.

Previous mission-attempt notes (retained):

A fresh tactical launch is a new mission attempt, even when replaying the same
generated XCOM mission. XCOM's fresh launch GUID is copied into mod-owned saved
metadata; native mission data is not modified. Start/deployment/completion share
that attempt identity. Delivery retries and loading an in-progress save retain it.
Older tactical saves retain their legacy identity/payloads; no retroactive migration.
Both failure and success attempts can be recorded and earn normal server-side XP.
Contradictory facts for the SAME attempt remain conflicts. Existing remote reports
and local receipts are not deleted or overwritten. Companion remains 0.8.0.
The earlier mission-site replay-conflict warning below applies to legacy identities
only. Soldier transition/covert/bond identities are unchanged. Promotion/wound fixes
and mission-loading safeguards remain included. See Docs/MISSION_ATTEMPTS_TESTING.md.

Previous promotion and mission-wound notes (retained):

Actual UnitRankUp captures promotions in the game's own transaction. History
gaps rebaseline future observations without inventing missing events; a warning
and gap count remain visible in MCM. Mission wound counts are frozen before
tactical transfer/recovery, for all deployed soldiers including unlinked ones.
Fast/instant recovery no longer hides a mission wound. Missing older snapshots
omit unknown totals. Saved links, bonuses, mappings and loading safeguards stay.
Companion remains 0.8.0. No API, credential or event-identity changes.
Accepted remote facts do not rewind: replaying the same mission with a different
result is a held conflict, not a replacement for an accepted failure. Promotion
capture is independent. Do not delete receipts/journals or mint replacement IDs.
See Docs/PROMOTION_AND_MISSION_WOUNDS_TESTING.md for the controlled test.

Previous reporting-load diagnostic notes (retained):

Background reporting now defers game-state allocation/submission during mission
creation, tactical save loading, travel, replay, mission teardown and latent
submissions. It resumes only during live strategy/tactical play when the ruleset
accepts new states. Existing baselines no longer cause an empty initialization
submission. TNB_REPORT log lines bracket bookkeeping and mission hooks; no secrets
or event payloads are logged. No mappings, bonuses, links or save schemas change.
Companion remains 0.8.0; no reinstall or credential changes are required.
This is a suspected-crash fix, not verified retail-game acceptance. Start with the
same commander-only linked save and mission; retain pre-link saves separately.
See Docs/REPORTING_LOAD_DIAGNOSTIC.md for the controlled test sequence.

Previous bond milestone notes (retained):

Update both mod and companion to 0.8.0. Initial soldier bonds and completed
bond-level increases report one Milestone reached event, with pair/level and
linked participant details. No canonical relationship or Trait/Skill edits.
Existing credentials, links, bonuses, mappings and event journals are retained.
Initialize the reporting capture clock before testing a new bond. The default
BondSoldiers cheat bypasses these hooks; use real bond confirmation/training.
See Docs/BOND_MILESTONES_TESTING.md. Dedicated bond event taxonomy is a final
review item, not a deferral of this implementation.

Earlier milestone notes below describe the retained UI/reporting baseline.

UI patch: saved commander bonuses now use the same graphical effect cards
as soldiers, with resource/staff icons and one-time/ongoing/monthly labels.
Soldier detail text is condensed; technical IDs are under Mapping details.
Missing artwork uses a verified neutral icon instead of rainbow textures.
No new companion executable, mappings, gameplay or event-capture changes.
See Docs/COMMANDER_UX_AND_MISSION_SMOKE_TEST.md for this pass's checks.

Current display follow-up: Journey names appear in the companion, MCM,
campaign setup/confirmation, commander report and soldier profile. Test the
companion connection / MCM Test once to retrieve the latest name. Saved
commander reports also offer Refresh Journey name; no bonuses are reapplied.
The linked soldier Armory entry opens a read-only graphical icon-card screen
with applied stat totals, installed ability help and missing-mod explanations.
No Officer-screen mod or new dependency is needed. Existing mappings and
reporting logic are unchanged. Automatic Avenger prompts remain disabled.
See Docs/JOURNEY_AND_SOLDIER_UX_TESTING.md for the next manual checks.

Current testing: gameplay event capture and durable companion delivery are
implemented for tactical/covert missions and soldier transitions. This is a
test build, not completed native-game acceptance. Start the companion first,
load a linked strategy save and refresh MCM > The Name Beneath > Gameplay
reporting. Wait for a capture clock zone before playing a new mission.
First verify in-session reloads again. Then complete ONE actual test mission
and inspect history before replay/retry tests. See Docs/EVENT_REPORTING_TESTING.md.

Captured in the save, durably queued in the companion, and accepted online
are separate states. Closing this app pauses delivery, not XCOM. Remote
history and reports already handed off do not rewind with an XCOM save.
Do not delete events-v1 or links journals as a repair. Conflicts/invalid
reports are held; network errors retry. No automatic Journey start/reopen
or client-authored XP. No hits/misses, guessed kills/damage/turn totals.
Native negative conditions are local injury/recovery records, not direct
changes to The Name Beneath Traits. Existing mappings/rewards are unchanged.

The older milestone notes below are retained for background; use companion
0.8.0 with this mod (protocol 2, gameplay events feature 1, bond milestones 1).

Feedback build 0.5.1: campaign linking is MCM-only while investigating
in-session save-reload crashes. No automatic Avenger linking popup is created.
Use MCM > The Name Beneath > Campaign Journey > Connect Campaign Journey,
or View Commander & Bonuses, then Open. A linked soldier's Armory entry is
The Name Beneath - Traits & Abilities. Both saved reports work offline.
See Docs/FEEDBACK_AND_NEXT_TESTS.md for current testing and deferred work.

Lifecycle update: companion 0.5.0 can explicitly Start Journey and connect an
Upcoming Journey after reviewing commander bonuses. Requires the updated
API/portal (feature/journey-management, migration 0014) and a newly issued key;
management permission is automatic in the portal. Existing keys keep their
permissions, including on rotation; manual portal Start remains a fallback.
No status/test/preview starts a Journey, and XCOM never automatically finishes
or reopens one. Remote Start survives cancellation or loading older saves.
Save after the campaign association. Existing frozen rewards/links remain.

Requires XCOM 2: War of the Chosen, WOTC Community Highlander (development
baseline 1.31.3), and Mod Config Menu. Enable all three mods through AML.

Start the separate TheNameBeneathCompanion.exe before opening the mod's MCM page.
No custom DLL is installed in the game's Binaries folder. The companion is a
self-contained Windows x64 build. From the source solution directory:

  powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\.scripts\Start-Companion.ps1 -Development

Enter your Journey credential in the companion's masked field and select
Validate and save. Confirm the Journey name, commander, Journey ID, and status.
The app supports typing or standard paste; no programmatic clipboard reader
is used. Test/replace/remove controls are in the desktop app. Minimize it while
playing; closing it disconnects linking/online features, not XCOM itself.
The stored credential and existing saved links/bonuses are retained.

Open MCM > The Name Beneath to view connection status. Refresh after changing
credentials in the desktop app. The read-only Credential stored checkbox
reflects Windows Credential Manager; companion reachability and last-known
Journey verification are shown separately. Refresh reads cached status;
Test verifies the credential online. A
network failure does not delete the credential. The secret is never returned
to UnrealScript, saved in an INI, or logged. Companion 0.5.0 and the mod use
protocol 2; update both together. Protocol-1 builds are incompatible.

This milestone has host-side tests and a successful WOTC script build. Basic
in-game connectivity and the preceding read-only Armory preview were verified.
The user confirmed commander Engineer/Supplies rewards, saved character stats,
Low Profile addition/persistence and safe missing optional ability handling.
In-session reload still requires diagnostic testing; tactical and ongoing
economy effects need separate verification. Use a separate manual test save.
Event reporting/delivery is not enabled yet.
See Docs/COMPANION_SETUP.md and Docs/IMPLEMENTATION_STATUS.md in the solution.
No GitHub release has been published.

Connect the campaign using loaded-campaign MCM > The Name Beneath >
Campaign Journey > Connect Campaign Journey > Open.
Review commander effects, then confirm to apply one-time rewards immediately.
Commander bonuses do not require soldier links. Automatic reminders are
disabled in this diagnostic build; the old saved opt-out remains dormant.
Main-menu/tactical MCM cannot associate a campaign.
Reopening campaign setup shows saved commander effects, including offline,
without regranting bonuses. Existing campaign associations are unchanged.
Afterward, optionally open a soldier's Armory and select The Name Beneath -
Link character. Choose a Journey roster character and confirm the pairing.
Online activation cannot be undone by loading an older XCOM save. No
soldier baseline is uploaded. A saved per-Trait/Skill effect report follows
a successful local link; existing linked reports are readable offline.
There is no reassignment of an existing link in a loaded save or fourth
promotion row. Loading a pre-link save leaves the soldier unlinked: choose
again or opt out. A different soldier may then use the same character's
original Journey instance. Old companion receipts do not lock that choice.
Bonuses apply once to the loaded timeline, never again to a committed link.
No console is needed. See Docs/CAMPAIGN_JOURNEY_TESTING.md for fresh tests.
Save after association/linking. Pending links resume only the original pairing.
Do not delete the companion's links recovery folder to resolve an error.
Startup instructions and existing Started-Journey connections are unchanged.
Use companion 0.5.0 and the matching Armory feature-2 mod for the new explicit
Journey Start workflow. See Docs/ARMORY_TESTING.md,
MAPPING_CUSTOMIZATION.md and RESOURCE_COVERAGE.md for limits and test gates.

Third-party attribution
-----------------------
Created with Enhanced Mod Project Template v1.4 / X2ModBuildCommon v1.2.1.
https://github.com/Iridar/EnhancedModProjectTemplate

Mod Config Menu API: https://github.com/andrewgu/ModConfigMenu
Copyright (c) 2016 Andrew Gu
Credits also include Superd22, BlueRaja, Patrick-Seymour, RealityMachina,
CMDBob, korgano and robojumper. API source from Workshop item 667104300.

The MIT License (MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
