---
type: entity
tags: [chart, item, wayfinding, dungeon-key, template, tier]
status: draft
updated: 2026-06-13
sources: ["docs/cartography.md", "docs/cartography-keystone-design.md", "docs/cartography-progression.md", "wyrd/data/charts.gd"]
---

# Charts

A chart is a parameterized dungeon key — a craftable item that encodes a template, a seed, and a list of resolved [[Affixes]], and that the game consumes to generate and enter a hollow.

## What a chart contains

The shipped chart dictionary (`wyrd/data/charts.gd::inscribe`):

```gdscript
{
  "template_id": String,   # e.g. "hollow"
  "tier":        int,      # 1, 2, or 3
  "scope":       String,   # fed to the dungeon generator
  "name":        String,   # display name e.g. "Hollow — Mineral Vein, Barren"
  "affixes":     Array,    # [{id, good, resolvedId}, ...]
  "seed":        int,      # 31-bit RNG seed for the layout
}
```

Each affix entry records whether the good twin or bad twin landed (`good: bool`) and a `resolvedId` for the effect lookup (bad twin is `affix_id + "__bad"`). The seed is randomized fresh on every inscription — two charts from the same template with the same inks will almost always produce different layouts.

## Templates

Five templates are live in `wyrd/data/charts.gd`. Each defines tier, Wayfinder level gate, affix slot count, base cost, scope, and generator parameters:

| Template | Tier | Req Wayfinder | Affix slots | Ink slots | Base cost |
|---|---|---|---|---|---|
| `snug` | 1 | 1 | 0 | 0 | 1× hedge ink |
| `tier_1` | 1 | 1 | 1 | 2 | 2× hedge ink |
| `hollow` | 2 | 10 | 2 | 3 | 3× hedge ink |
| `briar_maze` | 2 | 15 | 2 | 3 | 3× hedge ink |
| `summit` | 3 | 16 | 0 | 0 | 4× hedge ink + 1× refined ink + 1× alpha fang |

> ⚠️ Design docs (`docs/cartography-keystone-design.md`) list additional templates (`chart_sunken_hut`, `chart_delve`) and a `chart_summit` at tier 5 requiring Lv 60. Shipped code has only five templates, `summit` is tier 3 at Lv 16, and `chart_delve`/`chart_sunken_hut` are absent. Code is current behavior.

The **Snug** template has zero affix slots and is used as the tutorial chart — a guaranteed clean run with no affixes to roll. The **Summit** has zero random affix slots too; it is the unique endgame keystone gated by the alpha fang trophy.

## Inscription and cost

A chart is created by calling `ChartsData.inscribe(template_id, ink_ids, carto_lv, trophy_id)`. The cost is computed by `craft_cost(template_id, ink_ids, trophy_id)`:

- Always pays the template's `base_cost` (hedge ink quantity scales with tier)
- Pays one of each slotted ink (only if the template has affix slots)
- Pays one of the slotted trophy (if any, and only if `affix_slots > 0`)
- A `hedge_discount` perk (Thrifty Quill) can reduce the base hedge ink cost by 1, floored at 1

## Tiers and scope

`tier` controls which affixes are eligible to roll (higher-req affixes are excluded below their `req_carto` threshold). The `scope` string is fed to `DungeonGen.generate` and influences room density, grid size, and which enemy kinds spawn. The `briar_maze` scope produces corridor-heavy layouts; `crypt` (used by Summit) generates the boss arena.

## XP on completion

`Charts.completion_xp(chart)` returns `tier × 75 + good_affixes × 40 + bad_affixes × 10`, multiplied by 1.3 if the Tyrannical good twin resolved. A clean Snug (no affixes) gives only `75` XP; a maxed-out Hollow with two good affixes gives `230` XP. See [[Chart Loop]] for the full progression curve.

## Ink slots vs affix slots

Each template exposes both counts. `affix_slots` is the number of affix positions the generator will fill; `ink_slots` is the maximum number of inks the bench will accept (always ≥ affix slots + 1 for the stability modifier). A template with `affix_slots = 0` ignores any inks or trophies slotted — the bench hides those sockets automatically (spec 42).

## See also

- [[Chart Loop]] — the full gather → inscribe → delve → trophy cycle
- [[Affixes]] — what fills the chart's affix slots
- [[Inks]] — how inks bias which affixes land
- [[The Crafting Bench]] — the physical station for inscription
- [[The Waystone]] — consuming a chart to enter the hollow
- [[Dungeon Generation]] — how the seed and template become a layout
- [[Wayfinding]] — the Trade that gates templates behind Wayfinder level

## Sources

- `docs/cartography.md`
- `docs/cartography-keystone-design.md`
- `docs/cartography-progression.md`
- `wyrd/data/charts.gd`
