# 27d — Equipment slots + drag-equip

> Five equipment slots — weapon · helmet · chest · boots · ring — sit next to the inventory grid. Drag an item from the grid onto a matching slot to equip; drag back to unequip. Slots validate by item kind.

## Why

Equipping is what makes loot *meaningful* — without it, the Tetris grid is a hoard you admire but never use. Stats themselves come in 27e; this subspec wires the *flow*.

## Scope

### A. Equipment data
- Extend `Inventory` (or a parallel `Equipment` class) with 5 named slots: `weapon · helmet · chest · boots · ring`. Each slot holds zero or one item.
- API: `equip(item) -> Item|null` (validates kind, swaps existing, returns the displaced item to inventory), `unequip(slot) -> Item|null`.
- Each item kind (27a) carries its `category`; the slot accepts only matching categories (weapon slot ← `weapon` items; helmet ← `helmet`; etc.).

### B. UI — the equipment panel
- Extend `InventoryPanel` — a column of 5 slots beside the grid. Each slot: an outlined box sized to the item kind's typical footprint, labelled (`Weapon` / `Helmet` / …), with the equipped item rendered inside.

### C. Drag-equip flow
- Drag an item from the grid → drop onto a slot → if kind matches, equip; the slot displays it; the inventory cells free up. If a slot was occupied, the previous item returns to the inventory (auto-find-first-fit; if no space, snap back and log "Inventory full").
- Drag from a slot → onto the grid → unequip into the grid.
- Right-click an equipped slot → quick-unequip (auto-find-fit, like the inverse of a quick-pickup).

### D. Stat hooks (stubbed for 27e)
- On `equip()` / `unequip()` → fire a `gear_changed` signal on the player. 27e wires this to a derive-stats pass.

### E. Eval coverage
- `test_equipment.gd` — kind validation rejects wrong slots; equip swaps the previous item back to inventory; un-equip fails to a full inventory cleanly.

## Files

| Path | Action |
|---|---|
| `godot/scripts/inventory.gd` | extend — equipment slots + equip/unequip |
| `godot/scripts/inventory_panel.gd` | extend — render the slot column, drag/drop wiring |
| `godot/scripts/player_controller.gd` | hold the Equipment; emit `gear_changed` |
| `godot/test_equipment.gd` | new — equip/unequip evals |

## Acceptance
1. Dragging a weapon onto the weapon slot equips it; the grid cells free.
2. Dragging a helmet onto the weapon slot snaps back (kind mismatch).
3. Equipping over an occupied slot returns the old item to the inventory.
4. Right-click an equipped item quick-unequips it.
5. `gear_changed` fires on every equip/unequip.
6. `test_equipment.gd` green · combat + movement still pass.

## Open decisions
- **Slot count** — 5 (weapon/helmet/chest/boots/ring). Lean: keep 5; expansion is trivial later.
- **Slot validation** — strict (kind must match) vs permissive (any item, any slot). Lean: **strict**.
- **Quick-equip from inventory** — right-click an item to auto-equip to its slot. Lean: yes, friendly.
