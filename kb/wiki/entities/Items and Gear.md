---
type: entity
tags: [items, loot, inventory, equipment, affixes, economy]
status: draft
updated: 2026-06-13
sources:
  - docs/specs/27-item-system.md
  - docs/specs/27a-item-data.md
  - docs/specs/27a-item-data-notes.md
  - docs/specs/27b-ground-pickup.md
  - docs/specs/27c-inventory-ui.md
  - docs/specs/27d-equipment.md
  - docs/specs/27e-stats.md
  - docs/specs/27f-polish.md
  - wyrd/data/items.gd
  - wyrd/data/affixes.gd
  - wyrd/data/drops.gd
  - wyrd/data/economy.gd
---

# Items and Gear

Items are the random-affix loot that drops from dungeon enemies, fills the player's Tetris-grid pack, and plugs into five equipment slots to permanently raise derived combat stats.

## Item categories

Six equipment categories are defined in `wyrd/data/items.gd`:

| Category | Kinds (v1) | Base stat | Grid size |
|---|---|---|---|
| weapon | Shortbow, Longbow, Hedgesteel Warbow | damage | 2×4 |
| helmet | Leather Cap | hp | 2×2 |
| chest | Leather Jerkin | hp | 2×3 |
| boots | Leather Boots | hp | 2×2 |
| ring | Copper Ring, Starsilver Band | crit_chance / crit_mult | 1×1 |

Two additional categories — **pickaxe** and **axe** — are trade tools (Bogiron Pickaxe, Cinderbloom Pickaxe, Starsilver Pickaxe; matching axes). They occupy dedicated tool slots and contribute `gather_speed` rather than combat stats. Trade tools are **crafted at Hod's anvil** and never appear as random loot (`drops.gd` explicitly excludes them and the capstone Warbow/Starsilver Band from the random pool).

## Rarities

| Rarity | Affix count | Ground label color | Sell to Hod |
|---|---|---|---|
| Normal | 0 | white | 4g |
| Magic | 1 (prefix or suffix) | blue | 12g |
| Rare | 3 (≥1 prefix + ≥1 suffix) | gold | 35g |
| Unique | predefined set | orange | 90g |

Rarity is determined at drop time by `drops.gd::_roll_tier()` — a "min of two d10" curve biased by enemy role and dungeon depth. At depth 0 the approximate distribution is 75 / 21 / 3 / 1 normal/magic/rare/unique (from the notes file, verified by 1000-roll eval). Bosses are clamped to tier ≥ 8 (rare+) and always drop three items.

## Affix pool

Defined in `wyrd/data/affixes.gd`. Six prefixes and seven suffixes in v1:

**Prefixes:** Sharp (+damage 1–3), Heavy (+damage 3–6), Hardened (+hp 3–8), Fortified (+hp 8–15), Fierce (+crit_chance 2–5%), Swift (+fire_rate 2–6%).

**Suffixes:** of Health (+hp 4–10), of Vigor (+hp 10–20), of Fury (+damage 2–5), of Carnage (+crit_mult 10–30%), of Haste (+move_speed 5–15%), of Precision (+crit_chance 1–4%), of Swiftness (+cooldown_reduction 5–20%, capped at 80%).

Multiple items can roll the same stat; equipped values are summed (PoE-style stacking). Integer stats (hp, damage) are rounded; fractional stats snap to 0.01.

## Unique items

Two uniques ship in v1 (expandable via the `UNIQUES` dict):

- **Whispering Yew** (from `shortbow`) — +5 damage, +10% crit chance, +40% crit mult.
- **Coatcap of the Bramble** (from `leather_helm`) — +20 hp, +10% move speed.

If a unique roll lands on a kind with no `UNIQUES` entry, it falls back to rare gracefully.

## The Pack — Tetris inventory

The player carries a **5×6 grid** (30 slots) accessed with **I**. Items take a footprint matching their `size` (see table above). Drag to reposition; **R** rotates 90 degrees; invalid placements snap back. The inventory does not pause combat. When the pack is full, a ground pickup stays on the floor with a visual signal. There is no auto-sort.

Pickup key is **G** (for "grab"). Gold auto-picks on overlap; other items require G. See [[Gathering]] and [[Economy]] for the material satchel, which is a separate stackable store.

## Equipment slots

Five slots sit beside the grid: weapon · helmet · chest · boots · ring. Drag a grid item onto its matching slot to equip. Equipping over an occupied slot returns the displaced item to the pack. Right-click an equipped slot to quick-unequip.

Equipping fires a `gear_changed` signal that triggers `_derive_stats()` on the player (spec 27e). Base player stats (no gear): HP 30, damage 6, crit 20%, crit ×2, fire cooldown 0.28s, run speed 4.0, walk speed 2.0. Equipped items add base_value × category_multiplier plus all affix contributions.

## Ground drops and beacons

On enemy death, `roll_drop()` is called with the enemy's role and depth. Each returned item spawns an `ItemPickup` node: a glowing emissive beacon in the item's rarity color and a billboarded floating name label. Multi-drops from bosses stagger spawn ~80 ms apart for a cascade read.

## Tooltips

Hovering an item (grid, equipment slot, or ground beacon) shows a tooltip: name in rarity color, category, base stat, and each affix on its own line (spec 27f). SFX: soft chime on pickup, metallic clink on equip, paper rustle when opening the pack.

## See also

- [[Affixes]] — the chart-level good/bad-twin system (separate from item affixes)
- [[Economy]] — Hod's sell/buy counter and gold flow
- [[Trades and Leveling]] — trade tools (pickaxe/axe) as gear
- [[Dungeon Generation]] — how enemy roles and depth feed drop tables
- [[Gather Nodes]] — the material satchel (separate from the Tetris pack)
- [[NPCs]] — Old Hod Tenter who buys and sells

## Sources

- `docs/specs/27-item-system.md` through `27f-polish.md` — master spec and all six subspecs
- `wyrd/data/items.gd` — `KINDS`, `UNIQUES`, `N_AFFIXES`, `make_item()`
- `wyrd/data/affixes.gd` — `PREFIXES`, `SUFFIXES`, `roll_affixes()`
- `wyrd/data/drops.gd` — `ROLE_DROP_CHANCE`, `ROLE_TIER_BIAS`, `roll_drop()`
- `wyrd/data/economy.gd` — `SELL_BY_RARITY`, `WARES`
