# Journey titles and graphical soldier profile — 0.7.0

This display-only follow-up uses the deployed `journey_title` field on context and
lifecycle responses. Update both the companion and mod. Existing credentials,
instances, frozen mappings, soldier bonuses and reporting journals are retained.
No re-link, new Journey, new skill purchase or API migration is required.

## What changed

- Companion: Journey title first, commander/game separately, Journey ID/status and
  last-checked local timestamp underneath. Literal ampersands/Unicode, wrapping and
  old title-less cache fallback are supported. **Test connection** gets a fresh title.
- MCM: last-observed Journey title, commander/status and ID on separate rows;
  campaign summary uses its own saved association, never another active credential.
  Refresh reads the companion cache; Test fetches context. Long summary names are
  shortened; the campaign report and confirmation retain the full name.
- Campaign setup/confirmation and saved commander report show Journey title.
  **Refresh Journey name** performs a pinned GET and updates cosmetic metadata only.
  Opening the saved report stays offline-capable. Save normally to retain the label.
- Armory **The Name Beneath — Traits & Abilities** now opens a dedicated graphical,
  read-only profile: effect-icon cards, actual committed net stat deltas, clear
  positive/negative/skip colors, and a selectable details panel with ability help,
  link-time result, canonical source and mapping key. Normal promotion trees are
  untouched; no Officer/skill-screen mod is required. New links open the same view.

IDs remain the binding keys. A rename never reapplies rewards, rebalances a soldier,
refreshes frozen capabilities, changes event identity, activates another character,
or starts/finishes/reopens a Journey. Automatic Avenger invitations remain disabled.
Cached titles are last observed, not a claim that an offline name is current.

## Artwork decision

Reviewed latest GitHub main `df280dd`, including
`apps/portal/src/assets/canonical-artwork.ts` and `canonical-glyph.tsx`: canonical IDs
select inline 48×48 SVG paths, with category/polarity colors and fallbacks. They are
not a remote image library or API artwork fields. No API/image changes are needed.
This build shows the source definition name from The Name Beneath beside the actual installed XCOM
ability icon, or native PCS/perk stat artwork; missing targets use a safe fallback.
Portal SVGs were not copied into game config or passed as URLs. Adding a second
source-art icon would need a separate offline texture/package conversion and a
native rendering check; it is not necessary to understand the mappings here.

## One-pass game checks (pending)

1. Start companion 0.7.0. Use **Test connection**; confirm the recognizable Journey
   name, commander, game and unchanged Journey ID. No credential re-entry needed.
2. Load an existing linked strategy save. MCM **Test** should show the title and
   retain reporting status. Open **View Commander & Bonuses**; verify the full
   name and original committed one-time/ongoing bonuses. Use **Refresh Journey
   name** once; verify no Supplies/Intel/staff or soldier-stat changes.
3. Open a linked soldier's **Traits & Abilities**. Screenshot the full screen.
   Check icon loading, mouse selection, list/detail scrolling, Back/Escape, keyboard
   and controller navigation (if used), negative stat color and applied net totals.
   Inspect Low Profile and the unavailable Chamber Round mapping. Already-linked
   saves retain their old frozen template, not today's config spelling.
4. Close companion and reopen both saved reports: readable identity/bonuses, no
   connection required and no reapplication. A title never fetched for an old save
   may explicitly say unavailable until refreshed; it must not use the ID as a name.
5. Repeat linked→linked→pre-link in-session reload checks. Then optionally link in
   a separate pre-link test slot to confirm the post-link graphical profile and Save
   reminder. Do not overwrite the only save. No automatic linking popup may appear.
6. If a Journey is renamed normally in the portal, Test/Refresh should show it while
   IDs, soldier mappings, stats, instances and event receipts remain unchanged.

The reporting screenshot `20261019182516_1.jpg` was reviewed: companion handoff was
available, capture timezone populated, native transitions verified, and all counters
zero. This establishes status-screen/handshake evidence only, not mission delivery,
XP awards, Infirmary transitions or the new build's reload/rendering acceptance.
Continue [EVENT_REPORTING_TESTING.md](EVENT_REPORTING_TESTING.md) after UI/reload checks.
