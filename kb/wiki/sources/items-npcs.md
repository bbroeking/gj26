---
type: source
tags: [items, loot, inventory, gather-nodes, npcs, town]
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
  - docs/quest-items-models.md
  - docs/wyrd-guide.md
  - docs/WORLD_BIBLE.md
  - wyrd/data/items.gd
  - wyrd/data/affixes.gd
  - wyrd/data/drops.gd
  - wyrd/data/economy.gd
  - wyrd/data/gather.gd
  - wyrd/scripts/gather_node.gd
  - wyrd/scripts/wayfinder_npc.gd
  - wyrd/scripts/vendor_npc.gd
  - wyrd/scripts/quill_npc.gd
  - wyrd/scripts/town.gd
  - wyrd/scripts/ui/vendor_panel.gd
---

# Source digest — items, gather nodes, NPCs

This digest records which raw sources were read for the items/gear, gather-node, and NPC wiki pages, with a one-line summary of what each contributed.

## Wiki pages produced

- [[Items and Gear]] — item categories/rarities/affixes/slots/pack/stats/drops
- [[Gather Nodes]] — node kinds/tiers/regrowth/town placement/dungeon rolls
- [[NPCs]] — Mara/Hod/Quill roster, dialog, wares, unimplemented characters

## Source summaries

| Source | Summary |
|---|---|
| `docs/specs/27-item-system.md` | Master spec: 6 subspecs, locked decisions (Tetris grid, 5 slots, affix counts, item types, pickup key, inventory size, drop rates). |
| `docs/specs/27a-item-data.md` | Subspec: item kind catalogue, affix pool schema, `make_item()` design, drop table design, test harness. |
| `docs/specs/27a-item-data-notes.md` | Implementation notes: stat keys locked, 2 uniques decided, item sizes confirmed, affix value precision, unique fallback. Status: COMPLETE, 7/7 tests. |
| `docs/specs/27b-ground-pickup.md` | Ground beacons, pickup key changed to G, `ItemPickup` scene, multi-drop scatter. |
| `docs/specs/27c-inventory-ui.md` | 5×6 Tetris grid, drag/snap/rotate (R), I-key toggle, no-pause design, no auto-sort. |
| `docs/specs/27d-equipment.md` | 5 equipment slots, drag-equip flow, `gear_changed` signal, strict kind validation. |
| `docs/specs/27e-stats.md` | Derived stats wired to equipped items: hp, damage, crit_chance, crit_mult, fire_rate, move_speed. Base player values. |
| `docs/specs/27f-polish.md` | Hover tooltips, 3 SFX (pickup/equip/inv_open), rarity-color cell outlines, multi-drop cascade stagger. |
| `docs/quest-items-models.md` | Quest item model briefs for Hod, Quill, Sir Withering, and Maud quests; Blender pipeline specs per item. |
| `docs/wyrd-guide.md` | Player-facing guide: controls, the chart loop, Hod's counter gold prices, Mara intro, boss/elite descriptions. |
| `docs/WORLD_BIBLE.md` | Character Bible: Maud Pennycress, Old Hod Tenter, Sir Withering; locked metal/herb/animal taxonomy; naming rules; locations. |
| `wyrd/data/items.gd` | Code-canonical: `KINDS` (14 entries, 6 categories), `UNIQUES` (2), `N_AFFIXES`, `make_item()`. Tiebreaker over specs. |
| `wyrd/data/affixes.gd` | Code-canonical: 6 prefixes, 7 suffixes, `roll_affixes()` distribution logic, `compose_name()`. |
| `wyrd/data/drops.gd` | Code-canonical: `ROLE_DROP_CHANCE`, `ROLE_TIER_BIAS`, `BOSS_DROP_COUNT = 3`, `_roll_tier()` min-of-two-d10, trade-tool exclusion. |
| `wyrd/data/economy.gd` | Code-canonical: `SELL_BY_RARITY` (4/12/35/90g), `WARES` (6 items, prices). |
| `wyrd/data/gather.gd` | Code-canonical: `NODE_KINDS`, `ORE_TIERS` (5 tiers), `HERB_TIERS` (6 tiers), `MATERIALS` dict, `INK_RECIPES`, tier-roll tables. |
| `wyrd/scripts/gather_node.gd` | Channel logic, locking, regrowth, tint-per-tier, GLB loading with primitive fallback, `channel_seconds()` with all modifiers. |
| `wyrd/scripts/wayfinder_npc.gd` | Mara Linnet: tutorial step dialog tree (steps 0–6+), summit-cleared dialog, GLB `wanderer_v3.glb`, height 1.7 m. |
| `wyrd/scripts/vendor_npc.gd` | Old Hod Tenter: vendor scaffold, `npc_hod_v3.glb`, height 1.72 m, prompt text. |
| `wyrd/scripts/quill_npc.gd` | Quill the Herbalist: dialog lines, `npc_quill_v2.glb`, height 1.62 m, herb-corner lore. |
| `wyrd/scripts/town.gd` | All town positions (player spawn, NPC coords, station coords, herb patches, ore rocks, log piles), building GLBs, craft station IDs. |
| `wyrd/scripts/ui/vendor_panel.gd` | Hod's counter UI: sell list (reads `game.inventory`), buy list (reads `EconomyData.WARES`), Hod's in-panel voice line. |

## Contradictions flagged

1. **Mara Linnet not in the World Bible.** `docs/WORLD_BIBLE.md` (locked 2026-04-29) does not include a Wayfinder NPC named Mara Linnet. The Bible's cast covers Maud, Hod, and Sir Withering. Mara was added for the Godot slice. Code is canonical — page notes the discrepancy. Filed on [[NPCs]].

2. **Quill not in the World Bible.** Same issue: Quill the Herbalist is absent from the locked Bible. Her naming (plain English, herb connotation) is consistent with the Bible's naming rules. Code is canonical. Filed on [[NPCs]].

3. **`docs/specs/27a-item-data.md` references `godot/data/items.gd`** (the old directory prefix from before the rename from Wyrd to Wayfinder / godot → wyrd). Live code is at `wyrd/data/items.gd`. Not a logical contradiction — path only.

4. **`docs/quest-items-models.md` references `src/scene/characters.js`** — this is the three.js prototype path, removed 2026-06-12. The doc predates the Godot rewrite. Quest item model briefs remain valid as concept art / model pipeline targets; the loader registration path is stale.
