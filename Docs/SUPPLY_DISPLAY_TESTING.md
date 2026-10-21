# Supply display polish - mod 0.8.5 / companion 0.8.0

The user approved keeping the large month-end report at its native base amount.
The collection popup and following floating collection message must describe the
same actual gain. This update changes display only, not reward arithmetic.

## Changes and safeguards

- Native resource cache Update assigns AmountForFlyoverPopup from the base reward
  before ResourceCacheSupplies. The existing listener now corrects only this field
  on the supplied pending cache when it still matches the confirmed base amount.
  The correction uses Original + the adjustment actually returned by ApplyResource.
- For 86 base, Resourceful +5% remains +4 (truncated), 90 received; the floating
  message now says Supplies +90. Extravagant -5% remains -4, 82 received, message
  Supplies +82. This reduces the new reward, never deducts existing inventory.
- No future cache reward, native month-end income, one-time grant, saved receipt
  schema, Scrounger month guard, item pool, mapping or event identity is changed.
- Display correction is idempotent. Instant collection's zero/no-flyover sentinel
  and an unrelated mod's already-different display amount are preserved. A fully
  reduced zero reward does not produce a misleading positive flyover.
- Collection text adds a brief explanation based on the actual signed adjustment:
  extra supplies recovered at the drop site, or supplies scattered/lost/taken
  before recovery. Zero rounded adjustment adds no speculative story. The existing
  base/modifier/total breakdown is retained.
- Native item-name HTML color tags are removed before the plain name is escaped.
  This fixes literal font tags on Stock/Hair Trigger. Empty names fall back to the
  template ID. The item's image, actual award and normal popup lifecycle remain.
- No extra timer, custom history submit, independent inventory adjustment or
  automatic Journey-link dialog is introduced. Companion and API are unchanged.

## Manual acceptance

1. Use a save before monthly rollover to see the next Scrounger item popup. Its
   item name should contain no literal font/bold tags. Existing queue entries also
   use the new formatting; loading alone never awards another item.
2. Use a save before collecting the supply cache. The large monthly report and
   available-drop preview remain 86 in the original fixture. Upon collection,
   verify the popup shows 86 base, +4 Resourceful, 90 total, plus the recovery text.
   The subsequent floating message should say Supplies +90, with inventory +90.
3. For an already-frozen negative-modifier test campaign, verify 86 base, -4,
   82 total, loss text and Supplies +82, with inventory +82. Do not silently edit an
   existing campaign's frozen mappings to manufacture the test. If no such campaign
   exists, the native policy tests cover the math but live acceptance remains open.
4. Check readable popup wrapping, mouse/controller acceptance and that save/reload
   after collection does not repeat inventory or Scrounger rewards. Keep backups.
5. Partial scan flyovers reflect that installment's actual amount. The final popup
   accumulates recorded installments with their actual per-installment rounding;
   it need not equal an individual installment's flyover. Instant collection does
   not gain an invented flyover. Unidentified custom display overrides are retained.

The first-menu slowness is currently not reproducible in new saves/builds, per the
user's latest testing. Its cause is unconfirmed; no speculative performance change
is included. Covert-action-specific portal titles remain a separate follow-up.
