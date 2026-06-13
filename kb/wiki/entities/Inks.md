---
type: entity
tags: [ink, crafting, wayfinding, affix-bias, recipe-discovery]
status: draft
updated: 2026-06-13
sources: ["docs/cartography-inscribing-table-design.md", "docs/cartography.md", "docs/specs/43-recipe-discovery.md", "docs/specs/43-recipe-discovery-notes.md", "wyrd/data/charts.gd"]
---

# Inks

Inks are craftable items that the player slots into [[The Crafting Bench]] when inscribing a [[Charts|chart]] — each ink multiplies the weight of one or more [[Affixes]] in the random roll, turning a flat lottery into a probability-weighted gamble the player can tilt in their favor.

## How inks bias the roll

Each ink has a `bias` dictionary mapping affix IDs to weight multipliers. The engine (`ChartsData.compute_weights`) starts from base weights, applies all slotted inks multiplicatively, then normalizes to 100%. A single `stoneground_ink` (bias `mineral_vein: 2.5`) roughly doubles the chance of that affix landing versus the base pool.

The `_stability` key in a bias dict is a special case — it adds a flat bonus to the stability roll's good-twin chance rather than biasing which affix lands.

## Shipped inks

Eight inks are defined in `wyrd/data/charts.gd::INKS`:

### Always-known inks (start discovered)

| Ink | Icon | Affix bias |
|---|---|---|
| `hedge_ink` | ● | `bramble_bloom` ×2.0, `herbal_patch` ×2.0, `wood_grove` ×2.0 |
| `refined_ink` | ✦ | `_stability` +0.10 (flat +10% good-twin chance across all affixes) |

Hedge Ink is the universal binding agent — every chart recipe costs at least one and it is the starting ink Mara (Wayfinder NPC) teaches in the tutorial.

### Discoverable inks (spec 43)

These inks are unknown on a fresh save and must be discovered by experimenting at the mixing pot or by receiving NPC hints. Discovery awards +50 Wayfinder XP and teaches the recipe forever.

| Ink | Icon | Recipe (at the mixing pot) | Affix bias |
|---|---|---|---|
| `stoneground_ink` | ◆ | 2× ore | `mineral_vein` ×2.5 |
| `ash_ink` | ◉ | 2× logs + 1× wild herb | `wood_grove` ×2.5, `sprinter` ×1.8 |
| `chalkwash_ink` | ○ | 1× palechalk + 2× wild herb | `wellspring` ×1.8, `echoing` ×1.8, `marked_quarry` ×1.8 |

### Spec 45 inks (wave-2 affix coverage)

Three additional inks were added in spec 45 to ensure every rollable affix has at least one ink that courts it:

| Ink | Icon | Affix bias |
|---|---|---|
| `mothglow_ink` | ☽ | `fog_of_hedge` ×2.2, `quiver` ×1.8 |
| `foxglove_ink` | ❖ | `tyrannical` ×2.0, `frenzied` ×1.8, `bursting` ×1.8 |
| `gildleaf_ink` | ✧ | `gilded` ×2.2, `festival_pace` ×1.8 |

> ⚠️ Design doc (`docs/cartography-inscribing-table-design.md`) describes a much larger ink catalog (15 named inks including Aurora Ink, Wightblood Ink, Tideink, Bog Ink, Ember Ink, Lustrous Ink, etc.) via a 3×3 spatial grid crafting system. Shipped code has 8 inks with a mixing-pot quantity recipe system. The 3×3 grid was explicitly not ported (see `docs/specs/43-recipe-discovery-notes.md`). Code is current behavior.

## Ink tiers (design intent)

Design docs categorize inks into three tiers:
- **Common / Tier 1** — single-essence vertical-line recipes (3× of one type), always low bias
- **Refined / Tier 2** — two-essence pattern recipes, moderate bias
- **Rare / Tier 3** — hard to make, require Inkwell Vessels commissioned from NPCs, carry +10% stability on top of bias

Only Tier 1 and Tier 2 inks (and their simpler pot-quantity equivalents) are shipped in code. The Inkwell Vessel system and Tier 3 inks are design-stage only.

## Recipe discovery

Ink recipes start unknown (except Hedge Ink). A player discovers them by:

1. **Experimentation** — drop the right quantities into the pot and click "Try the Mix"; on exact match of an undiscovered recipe, the recipe is learned permanently
2. **NPC hints** — Hod's ore dialogue already hints the Stoneground recipe ("he's the hint NPC"); Quill hints the still recipes
3. **Serendipity** — a 10% chance on a failed pot attempt yields a random discoverable ink as an item (recipe stays unknown — a tease, not a teach)
4. **Smudge** — 60% of failed attempts consume materials and return the cheapest ingredient as consolation

A codex strip on the bench shows discovered recipes (`● Name — recipe`), hinted unknowns (`◌ ??? — <riddle>`), and fully unknown slots (`◌ ???`). See [[The Crafting Bench]].

## Stability ink (refined_ink)

Refined Ink (`✦`) is special: instead of biasing which affix lands, its `_stability: 0.10` adds 10 percentage points to every affix's good-twin chance. Multiple stability inks stack up to a +0.5 cap (+50 percentage points). This is the "Charcoal Bind" concept from the prototype, renamed and shipped as refined_ink.

## See also

- [[Affixes]] — what inks bias toward; the affix weight table
- [[Charts]] — how inks become part of a chart's inscription cost
- [[The Crafting Bench]] — where inks are mixed and slotted
- [[Chart Loop]] — the loop that makes choosing inks meaningful
- [[Wayfinding]] — the Trade whose level gates ink recipe unlocks
- [[Gathering]] — supplies the raw materials that become inks

## Sources

- `docs/cartography-inscribing-table-design.md`
- `docs/cartography.md`
- `docs/specs/43-recipe-discovery.md`
- `docs/specs/43-recipe-discovery-notes.md`
- `wyrd/data/charts.gd` (INKS constant)
