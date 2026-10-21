# The Name Beneath: commander mapping defaults

Approved by the user on 2026-10-18. This matrix supersedes the original one-time-only matrix and the subsequent percentage-only assumption. These are XCOM-owned, player-configurable defaults, not canonical API effects. Initial code paths are present in the experimental 0.4.0 build; actual-game acceptance is pending. Only an explicit in-game association confirmation applies one-time rewards to a campaign.

| Source | Canonical ID | Default effect | Frequency |
|---|---|---|---|
| Resourceful | trait.resourceful | +5% Supplies | Ongoing qualifying resource gains |
| Engineering-Minded | trait.engineering-minded | +1 Engineer | One time |
| Scientifically Minded | trait.scientifically-minded | +1 Scientist | One time |
| Inquisitive | trait.inquisitive | +10% Intel | Ongoing qualifying resource gains |
| Extravagant | trait.extravagant | -5% Supplies | Ongoing qualifying resource gains |
| Secretive | trait.secretive | -10% Intel | Ongoing qualifying resource gains |
| Overconfident | trait.overconfident | +1 Avatar Project progress pip | One time |
| Quartermaster | skill.quartermaster | +15 Supplies | One time, not a percentage modifier |
| Counterintelligence | skill.counterintelligence | Remove 1 eligible Avatar Project progress pip | One time |
| Scrounger | skill.scrounger | Receive 1 random common item | Every monthly rollover, including zero-income months |

## Implementation requirements

- Keep Trait and Skill definitions separate and match immutable canonical IDs/versions rather than names.
- Freeze resolved effects in the campaign save; player config changes do not silently rebalance existing associations.
- Encode the ongoing defaults in basis points: Resourceful +500, Extravagant -500, Inquisitive +1000, Secretive -1000.
- Sum modifiers for the same resource and apply once to the original qualifying gain; do not recursively modify the modifier. The opposing listed pairs therefore cancel when both apply.
- Preserve the resource-interceptor origin allowlist and rounding validation from the implementation plan. Negative modifiers reduce qualifying gains; they do not cause periodic resource deductions or modify spending.
- Give one-time effects a campaign-save ledger; save/load, repeated UI actions, companion restart, and credential rotation must not repeat them.
- Treat Scrounger as a distinct monthly item reward, not a generic chance on every Supplies increase. Mod 0.8.4 uses native PreEndOfMonth and the preserved per-month guard.
- Common-item pool remains the previously agreed basic weapon upgrades/medikits/grenades direction; no PCS, advanced/superior equipment or rare/unique items. Exact templates and eligible Avatar pips remain engineering verification work.
- Player customization remains in the mod mapping configuration; these amounts are shipped defaults rather than hard-coded balance policy.

## Approved timing

- One-time effects fire on the first explicit campaign/Journey association, including an already-running campaign. Save/load, retries, and later credential changes do not regrant them.
- On 2026-10-20 the user approved moving Scrounger to monthly rollover so zero income/no cache does not prevent the reward. Keep once-per-month protection and do not backfill on load.
- Show a dismissible item popup naming the bonus item and identifying Scrounger as its source, after the normal monthly report sequence. A debug log or transient banner alone is not sufficient. Supply percentage adjustments are shown separately on the existing collection popup.
