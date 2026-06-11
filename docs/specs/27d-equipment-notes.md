# Implementation notes — 27d-equipment

## Decisions
- **`Equipment` is its own `class_name`** (separate from `Inventory`), with
  a `Dictionary` of slot_name → item-or-null. Cleaner separation than
  cramming slots into the inventory grid.
- **Slot validation = category match**: `slots.has(String(item.category))`.
  No "any slot for any item" mode — strict, per the spec lean.
- **Equipment emits `changed`** (RefCounted owns Object's signal machinery);
  `player_controller` listens and re-emits **`gear_changed`** as the
  player-level signal 27e will subscribe to.
- **Pre-check the displacement** on a swap — if equipping a new item would
  displace a previous item that has nowhere to land in the inventory,
  reject the swap and snap back. (Avoids ever putting Equipment + Inventory
  into an "I had to drop your old gear" loss state.)
- **Slot layout** — single column, **72×72 px** boxes, 4 px gaps, anchored
  at `(854, 200)` — sits just left of the grid (which is at `(940, 200)`).
  Items inside a slot are rendered scaled-to-fit (not at their grid-cell
  size) so a 2×4 weapon and a 1×1 ring read at the same slot size.
- **Held-item provenance** as a dict (`_held_source`):
  `{"type":"grid","pos":Vector2i,"rotated":bool}` or
  `{"type":"slot","name":"weapon"}`. One `_snap_back()` routes both cases.
- **Right-click quick-(un)equip** — strictly when no item is held; if the
  cursor is on a slot → unequip into inventory; on a grid item → equip
  into its category's slot.

## Deviations
- *(none — implementation matches the spec.)*

## Tradeoffs
- **`_quick_equip` removes the item from the grid first** before calling
  `find_first_fit` for the displaced item — otherwise `find_first_fit`
  counts the equipping item's own cells as occupied and may falsely report
  "no fit." On rejection it puts the item back at its original spot.

## Surprises
- *(none — the existing 27c drag plumbing was straightforward to extend.)*

## Followups
- **Quick-equip with no displacement** is cheap; with displacement it
  involves a remove → fit search → equip → place. Fine, but if items grow
  in size or grid in count, the fit search is O(grid). Plenty of margin.
- **Slot art** — currently each slot is a labelled box; equipped items
  render as a coloured rect (kind colour + rarity border). Real slot icons
  (sword silhouette, helmet, etc.) are 27f / future polish.
- **A "stats" panel** showing total HP/damage/etc next to the equipment
  column — would be a nice 27e/27f addition.
- **Drag-equip from ground** (skip the inventory entirely) — not in the
  spec; reasonable polish if play-test asks for it.

## Status
COMPLETE — `test_equipment.gd` **7/7**, `test_inventory.gd` **8/8**,
`test_drops.gd` **5/5**, `test_combat.gd` **21/21**, `test_movement.gd`
**6/6**, World boots score 0.97. The full loot loop now reaches the
equipment slots; `gear_changed` is ready for 27e to wire stat derivation.
