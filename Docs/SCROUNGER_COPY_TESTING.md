# Scrounger flavor text - mod 0.8.7 / companion 0.8.0

Popup body (Laser Sight example):

> While rummaging around the Avenger, you uncover a forgotten Laser Sight.
> It has been added to your inventory.

The actual native item label substitutes `{ItemName}` in localized text or the
English fallback, after the existing tag normalization/escaping. The item image,
title, Accept button, native queued-alert lifecycle, award timing/stacking/monthly
guard and saved state are unchanged. No reward or event is added while rendering.
No supply-drop, income or monthly-rollover explanation appears in the popup body.
Mechanical timing remains documented in the commander effects/setup documentation.

## Quick visual check

Load a separate save before monthly rollover and let Scrounger grant normally.
Confirm body contains the same item name as its native title and image, reads
naturally, fits the existing panel and shows neither `{ItemName}` nor formatting
tags. Dismiss normally. No need to relink, reset credentials or update companion.
Reloading a post-award save must not add another reward (unchanged guard).

Existing 0.8.6 failure and deterministic stacking tests passed. Natural duplicate
testing may continue but is optional. Generic portal Mission succeeded/failed
headings are intentionally retained; only XCOM descriptions distinguish covert
actions. No API/contracts/portal label work is outstanding.
