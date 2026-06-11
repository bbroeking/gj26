# Implementation notes — 27c-inventory-ui

## Decisions
- **`Inventory` is a `class_name`** — globally accessible after `--import`
  registers it (test harnesses preload it explicitly to dodge the boot
  ordering question entirely).
- **Per-cell back-references** — `cells[y][x]` stores the item dict (or
  null), so collision check is O(footprint) and click hit-test is O(1).
- **`find_first_fit`** tries non-rotated first, then rotated (only if the
  footprint isn't square). Mirrors PoE's pickup-into-first-gap behaviour.
- **Panel structure** — `CanvasLayer` (outer, matches the project's
  `PlayerHUD` pattern) + `Control` named **`Root`** with the script. The
  player holds `_inv_root` and calls `_inv_root.toggle()` /
  `_inv_root.set_inventory(...)`.
- **Rendering via a single `_draw`** on the Root Control — backdrop, grid,
  items, held-item preview, header. No per-cell node bloat; one redraw per
  meaningful state change.
- **Input via global `_input`** with manual hit-testing — simpler than
  fighting Control `_gui_input` + mouse_filter for drag-and-drop. The
  panel's `_input` early-returns when `visible == false`.
- **Panel auto-instances from `player_controller._ready`** — no scene
  wiring required; works in `World.tscn` and `Sandbox.tscn` alike.
- **Snap-back via remove-then-place** — picking up removes the item from
  the grid; dropping tries `try_place(new)`, falls back to
  `try_place(origin, original_rotation)` on collision/invalid drop.

## Deviations
- **Combat doesn't pause** when the panel is open (per the spec lean). The
  backdrop dims everything; clicks/keys still reach the player.

## Tradeoffs
- **Item dicts mutated in place** with `pos` + `rotated` on placement —
  simpler than a separate placement-metadata structure. Works because the
  dicts are created in 27a (`make_item`) and are mine to mutate.
- **`_input` global vs Control `_gui_input`** — global needs the
  `if not visible: return` guard but gives consistent hit-test maths; the
  alternative wrestles with focus/mouse_filter for drag/snap.

## Surprises
- **`class_name` requires `--import`** before a fresh `--script` run can
  resolve the global. Caught by parse-error in `test_inventory.gd`.
- **`var ok :=` type-inference** fails on Dictionary-indexed comparisons
  (same class of error as specs 25/26). `var ok: bool =` is the fix.
- **`scn.add_child(panel)` from the player's `_ready`** triggers *"Parent
  node is busy setting up children"* — the player is itself mid-setup of
  the scene. Fixed with `scn.add_child.call_deferred(panel)`.

## Followups
- **Sprite art per kind** — each item renders as a flat colored rect with
  a rarity-coloured border. Bespoke icons (per kind) are the polish v2; the
  spec called this v1 (placeholder).
- **Right-click quick-equip** — 27d.
- **Hover tooltips** — 27f.
- **"Inventory full" feedback** — logs to console; in-game pulse / SFX is
  27f polish.
- **Backdrop darkness** — currently 0.35 alpha; if play-test feels too
  intrusive, tune down.
- **Grid origin (940, 200)** — assumes a ~1152-wide viewport (the project's
  game canvas). Will need anchor-based positioning for a real resize-aware UI.

## Status
COMPLETE — `test_inventory.gd` **8/8**, `test_drops.gd` **5/5**,
`test_combat.gd` **21/21**, `test_movement.gd` **6/6**, World boots score
1.00. Ready for 27d (equipment slots + drag-equip).
