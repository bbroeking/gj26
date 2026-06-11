# 27c — Inventory UI (Tetris grid)

> Replace the stub `inventory_stub` with a real **5×6 Tetris grid**. Items take their `size` footprint; the player drags them around, rotates with R, drops them on valid spots. I-key toggles the panel.

## Why

The grid is the heart of the loot system — it's where the player actually *feels* the hoard. Tetris (per-grill) means item sizes matter, the packing is gameplay.

## Scope

### A. Inventory data
- `scripts/inventory.gd` — a class wrapping a 5×6 cell grid (`cells: Array[Array]`, each cell either `null` or a reference to an item dict already placed). Per-cell reference (not duplicate) so iterating doesn't double-count.
- API: `try_place(item, pos: Vector2i, rotated: bool) -> bool` (collision check + commit), `remove(pos)`, `find_first_fit(item) -> Vector2i` (used by auto-place on pickup), `move(from, to, rotated) -> bool`.

### B. Pickup integration
- Replace `player.inventory_stub` with an `Inventory.new()` instance.
- 27b's grab → `inventory.find_first_fit(item) → try_place`. If full, the pickup stays on the ground (give a tiny shake/flash to signal "inventory full"); a status line logs "Inventory full".

### C. The UI panel
- `scenes/InventoryPanel.tscn` + `scripts/inventory_panel.gd` — a `CanvasLayer` panel: a 5×6 grid of cells, item sprites (placeholder coloured rectangles sized by footprint) overlaid at each item's position.
- **Toggle** — I-key opens/closes; pauses combat? Lean: **no pause** (PoE-style — combat continues, you must time it).

### D. Drag / snap / rotate
- Click an item → it follows the cursor; the grid shows the would-be-placed cells in green (valid) or red (collision).
- Release on a valid spot → commit. Release on invalid → snap back.
- **R while dragging** → rotate the item 90° (swap its size axes) and re-evaluate the fit visual.
- Cursor outside the grid → snap back.

### E. Eval coverage
- `test_inventory.gd` — pure data: `try_place` collision detection; `find_first_fit` finds gaps; `move` round-trips; rotation flips the footprint. UI behaviour is hand-tested.

## Files

| Path | Action |
|---|---|
| `godot/scripts/inventory.gd` | new — data model + collision/placement |
| `godot/scenes/InventoryPanel.tscn` | new — the UI |
| `godot/scripts/inventory_panel.gd` | new — drag/snap/rotate, render items |
| `godot/scripts/player_controller.gd` | wire I-key, hold the Inventory, route pickups |
| `godot/test_inventory.gd` | new — placement + collision evals |

## Acceptance
1. I toggles the panel.
2. Picking up an item adds it to the first-fit position; if full, the pickup stays on the ground.
3. Dragging an item shows a valid/invalid placement preview; release commits or snaps back.
4. R rotates the held item; the preview updates.
5. `test_inventory.gd` green; combat + movement evals still 21/21 + 6/6.

## Open decisions
- **Pause combat while open** — lean **no** (PoE: open inventory mid-fight, time it).
- **Sprite art** — placeholder coloured rects sized by footprint for v1. A real icon set is a polish followup (could be ChatGPT/Midjourney-sourced).
- **Cell size on screen** — ~64×64 px; grid sits ~middle-right.
- **Auto-sort** — PoE explicitly *doesn't* have it; we won't either.
