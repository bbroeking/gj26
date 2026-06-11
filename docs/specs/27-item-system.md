# 27 — PoE-style item / loot / inventory system (master)

> Master spec. The full ARPG loot loop — colour-coded items with random affixes drop from enemies, you pick them up, sort them in a Tetris grid, equip them into character slots, the stats actually change combat. **Broken into six subspecs**, each `/spec`-able independently in order.

## Decisions (locked from the grill)

- **Inventory: Tetris grid** — per-item sizes, drag-snap, R-to-rotate.
- **Equipment in v1** — 5 slots (weapon · helmet · chest · boots · ring).
- **Full random affixes** — magic = 1 affix, rare = 3, uniques are predefined named sets. ~6 prefixes + ~6 suffixes in the starter pool.
- **Item types v1:** weapons · armor (helmet/chest/boots) · rings · gold.
- **Pickup:** F-key when overlapping a ground drop.
- **Inventory size:** 5×6 = 30 slots.
- **Ground display:** floating world-space label, rarity-coloured.
- **Drops:** ~50% per enemy on death, tier weighted by enemy depth/role; bosses guarantee rare+.

**Deferred:** stash · consumables/potions · character sheet UI · minimap loot beams · loot filters · trading.

## Subspec breakdown

Each subspec is a self-contained build that boots, passes the existing evals, and adds its own. Build in order — each one depends on the previous.

| # | Subspec | What it ships |
|---|---|---|
| **27a** | [Item data + drop tables](27a-item-data.md) | item dict, affix pool, enemy loot tables, `roll_drop()` → concrete instances |
| **27b** | [Ground pickup](27b-ground-pickup.md) | 3D beacon + floating label, F-to-pickup, wired into enemy `_die` |
| **27c** | [Inventory UI — Tetris grid](27c-inventory-ui.md) | 5×6 grid, item-shape rendering, drag/snap/rotate, I-key toggle |
| **27d** | [Equipment slots + drag-equip](27d-equipment.md) | 5-slot panel, drag inventory→slot (kind validation), equip/unequip |
| **27e** | [Stats — items grant stats](27e-stats.md) | derived stats from equipped items, combat consumes them |
| **27f** | [Tooltips + polish](27f-polish.md) | hover tooltips, pickup/equip SFX, visual polish |

## Build order rationale

- **a → b**: items must exist before they can drop on the ground.
- **b → c**: ground pickup pushes into the inventory data, so inventory exists first as data (a is enough); UI follows.
- **c → d**: equipment slots are a special inventory-adjacent panel; the inventory's drag-drop machinery is reused.
- **d → e**: stats only matter once items can be equipped; the data is there from 27a (each item has affixes), 27e wires them into the player.
- **e → f**: tooltips render the data already in place; SFX wraps the loop.

After 27f the loot loop is real and end-to-end satisfying.
