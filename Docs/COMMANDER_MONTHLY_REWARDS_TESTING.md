# Commander monthly rewards and collection receipts - mod 0.8.4

Companion remains 0.8.0. No credential, API, journey, mapping or campaign restart
is needed. Retain pre-link and pre-month-end saves separately.

## Behavior

- Scrounger awards one eligible configured item at `PreEndOfMonth`, in the native
  month-end transaction. Zero or negative supply income, no spawned cache and
  leaving a cache uncollected do not suppress the monthly item.
- The item, existing `ScroungerMonths` guard and native queued popup are saved
  together. No own change state, timer, HTTP call or state-submitted grant is used.
- The incoming reward month is `NumMonths + 1`: native month-end increments the
  counter after the hook. This preserves numbering used by older collection-time
  awards; existing Suppressor/item grants are not repeated by migration or load.
- A dismissible native item-received alert shows The Name Beneath - Scrounger,
  the actual template's icon/name and that one item was added to inventory. Its
  native saved queue waits for live strategy, monthly report completion and an
  idle geoscape/Avenger side view. It never interrupts another modal screen.
- Percentage calculation and source allowlist remain unchanged. The supply cache
  transaction also saves a mod-owned display receipt: original amount, actual
  integer adjustment, total, source labels and collection identity. It accumulates
  recorded installments without recomputing rounding on the monthly total.
- The existing scanned/instant supply collection popup displays the matching
  receipt in its reward area. UI reads only; native callbacks/buttons, camera
  behavior and inventory are not modified. No extra supply popup is spawned.
- Old collection popups without a saved receipt are left alone. A stale receipt
  for another campaign, cache, month, scan count or still-active cache is rejected.
  Updating mid-drop cannot reconstruct previously unrecorded installments.
- No retroactive Scrounger award is made for an already-completed month. No reward
  is granted merely by loading a save, viewing a profile or refreshing the UI.

## In-game acceptance

1. Load a save before monthly rollover, with an associated commander who has
   Scrounger. First try zero income. Finish the monthly report/other modal alerts:
   a dismissible Scrounger item popup should appear and name the item actually
   added. Record that item's inventory count before/after when practical.
2. Close the popup, save/reload and return to the geoscape. There should be no new
   item or reward popup after its saved acknowledgement. An undismissed native
   queued popup may legitimately survive a save; redisplay never grants inventory.
3. Repeat using the positive-income pre-month save. Scrounger should award at
   rollover, not again when supplies are collected.
4. Collect the supply drop. For base 86 and Resourceful +5%, the completion popup
   should show `Base supplies: 86`, `Resourceful (+5%): +4`, `Total received: 90`.
   Inventory should increase from 177 to 267 in the original test case. Native
   month-end/available-drop previews still describe the base income, not the later
   collection bonus.
5. Check mouse/controller acceptance and return/ignore behavior; ensure receipt
   text is readable and does not overlap the existing popup layout.
6. When available, test partial scanned and instant collection, negative percentage
   mappings, small gains rounding to zero, and no-linked-commander saves. No extra
   item per installment; totals must reflect actual per-installment rounding.
7. A save with a legacy Scrounger month entry must not receive that month's reward
   a second time. The next legitimate rollover should still grant one item.

## Validation scope

Offline SDK checks cover production policy helpers, native popup property shape,
receipt calculation/dedup/identity/formatting, existing loading/reporting guards,
promotion/wound capture policies, bond/mission-attempt identities and graphical
profile regressions. Native month-end award execution in a live campaign, popup
ordering, Flash text layout and actual inventory counts require the above manual
acceptance. Do not mistake pure policy tests for a complete retail gameplay test.

The 2026-10-20 positive-income screenshots already confirm the old calculation:
86 base yielded 90 supplies (177 -> 267). Screenshot 20261020144328_1.jpg also
captures the old transient Scrounger banner naming Suppressor; the player verified
one Suppressor in inventory but had no before-count. This update addresses the
zero-income omission and notification visibility, not an assumed failure of that
positive-income award.
