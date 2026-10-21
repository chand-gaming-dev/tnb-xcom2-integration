# Commander resource coverage

Updated: 2026-10-20, mod 0.8.4. Baseline: installed Highlander 1.31.3 / WOTC SDK 8917. Positive supply collection was tested in game: 86 base +4 Resourceful =90 (177 ->267). Broader source coverage and the new popups/monthly path still need actual-game acceptance. No blanket percentage is added to every HQ inventory change.

| Origin | Initial behavior | Identity / exclusion |
|---|---|---|
| Supplies/Intel mission rewards | Included when the reward ID is referenced by a historical MissionSite.Rewards entry and uses Reward_Supplies/Reward_Intel |
| Supplies/Intel scanning POI rewards | Included when referenced by PointOfInterest.RewardRefs and using those resource templates |
| Supplies/Intel covert-action rewards | Included when referenced by CovertAction.RewardRefs and using those resource templates |
| Monthly supply-drop partial/instant collection | Included at ResourceCacheSupplies, requiring a changed ResourceCache and positive Supplies delta |
| Spending and negative resource changes | Excluded |
| Commander one-time association grants | Excluded: no qualifying reward origin/cache event |
| Black market transactions, purchases, refunds, conversions | Excluded unless another mod incorrectly reuses a still-referenced qualifying mission/POI/action reward ID |
| Tactical loot, arbitrary direct grants, debug commands, unidentified mod rewards | Excluded in this first allowlist; no inference from resource type alone |
| Save/load reconstruction | No award path runs merely from loading |

The initial reward wrappers preserve and call the previously installed GiveRewardFn delegates. They register an immediate AddResource listener only during the original reward call, with a per-wrapper nested-origin stack and resource-name guard. Unqualified nested calls mask the outer origin. The listener modifies the pending resource item directly; it does not recursively call AddResource. Later mods can replace delegates and bypass these wrappers; that is a compatibility limitation, not permission to guess the source of an unrelated grant.

The cache path uses the verified ResourceCacheSupplies event for both scanned and instant collection. A pending ResourceCache is required. It adds a bonus to the original pending resource item, not a second independent inventory transaction. Resource reward IDs plus resource name, or resistance month plus cache scan number, are recorded in the campaign ledger in the same state change. Re-entry into the same award does not add another bonus. There are no retroactive bonuses on the Supplies/Intel already owned at association.

Scrounger now uses PreEndOfMonth, independently of income or cache collection. It records the incoming month (NumMonths + 1), adds the item and queues a non-immediate native item popup in the same pending transaction. The popup waits for monthly-report completion and live strategy idle. Existing collection-time month records are preserved, so old awards are not repeated. Missing months do not accumulate retroactive items, and loading does not award. The transient banner is replaced by a dismissible item popup identifying Scrounger and the actual item. See COMMANDER_MONTHLY_REWARDS_TESTING.md.

Supply cache collection also stores an additive mod-owned receipt for the existing completion/instant popup. It displays base supplies, saved commander modifier and actual total, not an estimated or newly recalculated bonus. Recorded installments accumulate their actual rounded adjustments. UI decoration never grants inventory, creates/submits a state, changes native callbacks or moves the camera. Missing/stale pre-update receipts leave the native popup unchanged.

Mod 0.8.5 also corrects the pending cache AmountForFlyoverPopup when it still equals the confirmed original collection amount, using the same actual signed adjustment. This synchronizes ordinary scanned collection's floating message with the receipt (86 +4 =90; 86 -4 =82) without another inventory change. Instant/no-flyover and unrelated custom amounts are retained. Native month-end income and future cache rewards are unchanged. Positive/negative recovery flavor is display-only. See SUPPLY_DISPLAY_TESTING.md.

One-time Avatar rules: add global progress up to remaining total capacity; remove global progress first, then pips on available mission sites/facilities. Zero eligible progress/capacity is consumed once as a no-change result, not deferred. Actual deltas and clamping are shown in the effect details. This does not remove protected/unavailable facility progress or manipulate the lose-mode countdown. Countdown/visibility interactions and economy-mod compatibility require in-game testing before release.

Acceptance checks still required: +5%/-5% Supplies, +10%/-10% Intel, opposing-pair cancellation, small gains/rounding, each included/excluded source, duplicate/re-entrant reward calls, save/reload, one-time staff/resource/Avatar results, instant/partial/merged supply drops, Scrounger notification, and representative economy mods. Unknown-origin support can be expanded only after source verification.
