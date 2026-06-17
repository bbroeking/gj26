---
title: Inventory (Tetris) & Equipment — Implementation Plan
parent: "[[system-inventory-equipment]]"
domain: Gather · Craft · Economy
type: implementation-plan
status: ready-to-build
effort: M
tags: [wayfinder, impl]
---

# Inventory (Tetris) & Equipment — Implementation Plan

> Build doc for [[system-inventory-equipment]]. The system is done when pack-full pickups show a HUD toast, consumables stack up to 10 in one cell, pack rows grow on Wayfinding leveling, and the tooltip shows a stat delta vs. the equipped item.

## Definition of done

- Picking up an item when the 5×N grid is full fires `game.notify()` and plays `inv_full` SFX — no `print`-only path remains in `item_pickup.gd:110`.
- Draughts and tonics stack (up to 10) in a single 1×1 cell; `stack_count` survives a save round-trip.
- At Wayfinding Lv 5, `game.inventory.rows == 7`; at Lv 12, `rows == 8`; the panel redraws the extra row without resizing the window outside the viewport.
- Hovering a grid item whose `category` matches an occupied equipment slot shows a green/terracotta diff line in the tooltip.
- All four headless suites remain green after every task.

## Preconditions / dependencies

- [[impl-system-save-load]] — `save_game.gd:97-107` rebuilds inventory on load; `stack_count` and `inventory.rows` must be added to the schema with back-compat defaults. No blocking dependency: the changes are additive field additions.
- [[impl-system-items-affixes]] — `items.gd` must carry `stack_max` on consumable `KINDS` entries (Task 2). No other impl note must land first; `items.gd` is standalone data.
- [[impl-system-trades-progression]] — pack-size perks (Task 6) slot into `game.gd PERKS` on the single Wayfinding ladder; the ladder already exists at `game.gd:415-459`. No prerequisite except that the perk ids chosen here must not collide with existing ids.
- [[impl-system-economy]] — InventoryController split (Phase 5, *deferred*) is gated on the vendor panel existing; not part of this plan.
- `item_pickup.gd:110` — the `print`-only full-pack path is the first fix target.
- `game.gd:375-377` — crafting already calls `notify("Your pack has no room …")`; Phase 1 only needs the pickup path to match.
- No file needs to be created from scratch; all three core files exist.

## Tasks (ordered)

### Phase 1 — Full-pack HUD feedback

**Task 1** — `item_pickup.gd:try_take` (lines 108-111): replace the bare `print` on inventory-full with `game.notify()` + `inv_full` SFX.

```gdscript
# Replace lines 109-111:
if fit.is_empty():
    var game_h := player.get_node_or_null("/root/Game")
    if game_h != null:
        game_h.notify("Pack full — %s left behind." % String(preview.name))
    var sfx := player.get_node_or_null("/root/Sfx")
    if sfx != null:
        sfx.play("inv_full")
    return false
```

_Verify:_ In `test_wyrd_loop.gd` add `_test_full_pack_toast()`: instantiate `Inventory`, fill with 30 1×1 items, call `try_take` on a mock player with a signal-capturing shim; assert `game.notify` was called with a string containing "Pack full". Suite: `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd`. _Effort:_ S.

---

### Phase 2 — Consumable stacking data

**Task 2** — `data/items.gd:KINDS`: add `stack_max: int` to draught and tonic kind entries; all other kinds implicitly default to 1 (handled by `make_item`).

```gdscript
# Example — add stack_max to each consumable entry in KINDS:
"healing_draught": {
    "name": "Healing Draught", "category": "consumable",
    "size": Vector2i(1, 1), "base_stat": "", "base_value": 0,
    "icon_color": Color(0.72, 0.25, 0.28), "stack_max": 10,
},
```

Also update `Items.make_item()` (line 123 block) to copy `stack_max` from the kind dict and add `"stack_count": 1` to every new item dict.

_Verify:_ `_test_make_item_stack_fields()` in `test_wyrd_loop.gd`: call `Items.make_item("healing_draught", "normal")`; assert `item.has("stack_count")` and `item.stack_max == 10`. Gear kinds assert `item.get("stack_max", 1) == 1`. _Effort:_ S.

---

**Task 3** — `scripts/inventory.gd`: add `find_stack_cell(item: Dictionary) -> Dictionary` before `find_first_fit`; update `find_first_fit` to call it first for stackable items.

```gdscript
# New method — insert before find_first_fit (after line 65):
func find_stack_cell(item: Dictionary) -> Dictionary:
    var max_s: int = int(item.get("stack_max", 1))
    if max_s <= 1:
        return {}
    var kid: String = String(item.get("kind_id", ""))
    for placed in items:
        if String(placed.get("kind_id", "")) == kid \
                and int(placed.get("stack_count", 1)) < max_s:
            return {"pos": placed.pos, "rotated": placed.get("rotated", false),
                    "stack_target": placed}
    return {}

# In find_first_fit — prepend before the y/x scan (line 70):
var stk := find_stack_cell(item)
if not stk.is_empty():
    return stk
```

Update `try_place` to increment `stack_count` on the target instead of placing a new cell when `fit` carries `"stack_target"`. Add a `consume_from_stack(item, amount)` helper for future use item paths.

_Verify:_ `_test_stack_pickup()`: place one draught at (0,0); call `find_first_fit` for a second draught; assert result has `"stack_target"` and the target's `stack_count` becomes 2 after `try_place`. No second cell occupied. _Effort:_ S.

---

**Task 4** — `scripts/inventory_panel.gd:_draw_item_in_grid` (line 458): render the stack count badge when `stack_count > 1`.

```gdscript
# After the existing _draw_item_rect_scaled call (line 462):
var sc: int = int(it.get("stack_count", 1))
if sc > 1:
    var badge_pos := top + Vector2(fp.x * CELL - PAD - 22, fp.y * CELL - PAD - 4)
    var badge_font := get_theme_default_font()
    draw_string(badge_font, badge_pos, str(sc),
        HORIZONTAL_ALIGNMENT_RIGHT, 22, 11, Color(0.97, 0.93, 0.82))
```

_Verify:_ Manual playtest — pick up 3 draughts; the cell shows "3" in the bottom-right corner. Screenshot: `WYRD_NO_SAVE=1 WYRD_SHOT=1 godot --path wyrd` with a pre-seeded save holding stacked draughts. _Effort:_ S.

---

**Task 5** — `scripts/save_game.gd:load_into` (lines 97-107): preserve `stack_count` and `stack_max` on the item dict round-trip. No code change needed if the dict is `duplicate(true)`'d — confirm `_items_out` already does so (line 124: `(item as Dictionary).duplicate(true)` — yes). Only ensure `stack_count` is not stripped. Add a back-compat note: items loaded from saves that predate Phase 2 will have neither field; the `int(item.get("stack_count", 1))` default already handles this.

_Verify:_ Extend `_test_save_roundtrip()` in `test_wyrd_loop.gd`: place a stacked draught (stack_count=3), save, reload, assert `stack_count == 3`. Suite: `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd`. _Effort:_ S.

---

### Phase 3 — Pack-size progression

**Task 6** — `scripts/inventory.gd`: convert `ROWS` from a compile-time `const` to a runtime `var`; add `resize(new_rows: int)`.

```gdscript
# Replace line 11:
const BASE_ROWS := 6
var rows: int = BASE_ROWS   # runtime, perk-expanded

# Replace all internal ROWS references with `rows` (can_place line 35, find_first_fit lines 70/76, _init line 18).

# New method (after remove(), before find_first_fit):
func resize(new_rows: int) -> bool:
    if new_rows <= rows:
        # Refuse shrink if bottom rows occupied.
        for y in range(new_rows, rows):
            for x in COLS:
                if cells[y][x] != null:
                    return false
        # Truncate.
        cells.resize(new_rows)
        rows = new_rows
        return true
    # Expand — append empty rows.
    for _y in range(rows, new_rows):
        var row: Array = []
        row.resize(COLS)
        row.fill(null)
        cells.append(row)
    rows = new_rows
    return true
```

Also update `can_place` (line 35): replace `ROWS` with `rows`. Update `inventory_panel.gd:_cell_at` (line 194) to use `inventory.rows` instead of the local const `ROWS`, and update `_draw_grid` (line 408) and `_win_rect` (line 53) to use `inventory.rows` dynamically so the window height reflects the live row count.

_Verify:_ `_test_inventory_resize()`: make an Inventory; place items in rows 0-5; call `resize(7)`; assert `inventory.rows == 7` and `inventory.cells.size() == 7`. Attempt `resize(5)` while row 6 is occupied; assert returns false. _Effort:_ M.

---

**Task 7** — `scripts/game.gd:PERKS` (line 419 block) and `_on_leveled_up` (line 1068): add pack-size perk entries and wire the resize call.

```gdscript
# In PERKS["wayfinding"] array — insert after "curious_fingers" entry:
{"id": "pack_runner", "lv": 5, "name": "Pack Runner",
    "desc": "A wider satchel seam — your pack grows a row"},
{"id": "pack_master", "lv": 12, "name": "Pack Master",
    "desc": "A second seam sewn by Mara herself — one more row"},
```

```gdscript
# In _on_leveled_up (after line 1073, before the hud update):
if perk_active(SKILL, "pack_runner") and inventory != null \
        and inventory.rows < 7:
    inventory.resize(7)
if perk_active(SKILL, "pack_master") and inventory != null \
        and inventory.rows < 8:
    inventory.resize(8)
```

_Verify:_ `_test_pack_progression()`: instantiate Game, set `trades.wayfinding.lv = 5`, call `_on_leveled_up("wayfinding", 5)`, assert `game.inventory.rows == 7`. Repeat for lv 12 → rows == 8. Suite: `WYRD_DEV_LEVEL=5 WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd`. Visual: `WYRD_DEV_LEVEL=5 WYRD_SHOT=1 godot --path wyrd` — screenshot confirms the panel renders the extra row. _Effort:_ S.

---

**Task 8** — `scripts/save_game.gd:save` (line 27) and `load_into` (line 97): persist `inventory.rows` so it survives reload.

```gdscript
# In save() data dict — add alongside "inventory":
"inventory_rows": game.inventory.rows if game.inventory != null else 6,

# In load_into() — after `game.inventory = Inventory.new()`:
var saved_rows: int = int(data.get("inventory_rows", 6))
if saved_rows > 6:
    game.inventory.resize(saved_rows)
```

_Verify:_ Extend `_test_save_roundtrip()`: set `inventory.rows = 7`, save, reload, assert `game.inventory.rows == 7`. Backward-compat: omit `inventory_rows` from a test dict; assert `rows == 6` on load. _Effort:_ S.

---

### Phase 4 — Compare-on-hover tooltip delta

**Task 9** — `scripts/inventory_panel.gd:_tooltip_lines` (line 505): append stat diff lines when the hovered grid item has a category that matches an occupied equipment slot.

```gdscript
# Append after the existing affix lines loop (after line 522):
if equipment != null:
    var cat: String = String(item.get("category", ""))
    var equipped = equipment.get_slot(cat)
    if equipped != null and equipped != item:
        lines.append({"text": "— vs equipped —",
            "color": Color(0.55, 0.47, 0.38, 0.85), "size": 10})
        # Collect stats from hovered item.
        var hov_stats := {}
        _accumulate_stat(hov_stats, String(item.get("base_stat", "")),
            float(item.get("base_value", 0.0)))
        for a in item.get("affixes", []):
            _accumulate_stat(hov_stats, String(a.get("stat", "")),
                float(a.get("value", 0.0)))
        # Collect stats from equipped item.
        var eq_stats := {}
        _accumulate_stat(eq_stats, String(equipped.get("base_stat", "")),
            float(equipped.get("base_value", 0.0)))
        for a in equipped.get("affixes", []):
            _accumulate_stat(eq_stats, String(a.get("stat", "")),
                float(a.get("value", 0.0)))
        # Emit deltas for shared stats.
        for stat in hov_stats:
            var delta: float = float(hov_stats[stat]) - float(eq_stats.get(stat, 0.0))
            if abs(delta) < 0.001:
                continue
            var sign_str := "+" if delta > 0.0 else ""
            var col: Color = Color(0.30, 0.68, 0.38) if delta > 0.0 \
                else Color(0.75, 0.32, 0.28)
            lines.append({"text": "%s%s %s" % [sign_str,
                Affixes.fmt_value(stat, delta), stat.replace("_", " ")],
                "color": col, "size": 11})
```

Add `_accumulate_stat(d: Dictionary, stat: String, val: float) -> void` private helper and confirm `Affixes.fmt_value` exists or inline the formatting. (If `Affixes` does not export `fmt_value`, use `"%.0f" % delta` for integer stats and `"%.0f%%" % (delta * 100.0)` for ratio stats with a simple match block.)

_Verify:_ Manual only — equip a shortbow, hover a longbow in the grid; tooltip shows a signed damage delta in green/terracotta. No diff section appears when hovering a ring while no ring is equipped. _Effort:_ S.

---

### Phase 5 — InventoryController split (deferred)

> **Do not start until `vendor_panel.gd` exists.** This is the ADR 0001 trigger condition. See [[system-inventory-equipment]] Phase 5 and [[system-economy]] for the trigger.

When the time comes: extract `_try_pick_up_at`, `_try_drop_at`, `_quick_equip`, `_quick_unequip`, `_snap_back` from `inventory_panel.gd` (lines 209-333) into `scripts/inventory_controller.gd` (`RefCounted`, holds `Inventory` + `Equipment` refs). `inventory_panel.gd` becomes a pure view.

_Verify when triggered:_ All four headless suites stay green after the refactor. `vendor_panel.gd` uses the same controller with no duplicated equip-swap logic. _Effort:_ M.

---

## First commit (smallest shippable slice)

**Tasks 1 only.** Changes: `item_pickup.gd:try_take` — replace the `print`-only path with `game.notify()` + `inv_full` SFX. Add `_test_full_pack_toast()` to `test_wyrd_loop.gd`.

Acceptance: pick up an item with a full 5×6 grid; the HUD toast reads "Pack full — \<item name\> left behind." No print-only fallback remains. All four headless suites green.

Rationale: this is the only gap flagged as **(blocker for feel)** in the parent note; it is also the smallest unit of shippable value and the right seam to validate before the stacking + progression work begins.

---

## Test & verification plan

| Suite | Tasks covered | Command |
|---|---|---|
| `test_wyrd_loop.gd` | 1–3, 5–8 | `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` |
| `test_wyrd_dungeon_scene.gd` | regression | `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd` |
| `test_wyrd_transitions.gd` | regression | `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_transitions.gd` |
| `test_skills.gd` | regression (Phase 5 only) | `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd` |

**New evals to author in `test_wyrd_loop.gd`:**

1. `_test_full_pack_toast()` — fill 30 cells (30 × 1×1 normal items), mock a notify-capturing player node, call `try_take`; assert `notify` was called with a string containing "Pack full".
2. `_test_make_item_stack_fields()` — `Items.make_item("healing_draught", "normal")`; assert `stack_count == 1`, `stack_max == 10`; gear kind asserts `stack_max == 1` (default).
3. `_test_stack_pickup()` — place one draught; `find_first_fit` second draught; assert `stack_target` present; after `try_place`, assert `inventory.items.size() == 1` and `stack_count == 2`.
4. `_test_save_roundtrip_stack()` — stacked draught at count 3; save + reload; assert `stack_count == 3`.
5. `_test_inventory_resize()` — resize 6→7 succeeds; resize 7→5 with occupied row 6 returns false.
6. `_test_pack_progression()` — lv 5 fires `_on_leveled_up`; assert `inventory.rows == 7`; lv 12 → `rows == 8`.
7. `_test_save_roundtrip_rows()` — rows == 7 survives save/reload; missing `inventory_rows` in legacy blob defaults to 6.

**Screenshots / manual playtest:**

- `WYRD_DEV_LEVEL=5 WYRD_SHOT=1 godot --path wyrd` — confirm extra row renders in the pack panel without clipping.
- Manual draught-stacking run: pick up 3 draughts; cell shows "3" badge; use one; cell shows "2".
- Manual tooltip delta: equip shortbow, hover longbow in grid; diff lines appear with correct sign.

---

## Risks & open questions

1. **Pack-size perk ladder collision** — `"pack_runner"` at Lv 5 and `"pack_master"` at Lv 12 land in a cluster where `"curious_fingers"`, `"double_ore"`, `"keen_eye"`, and `"steady_hands"` already sit at Lv 5, and `"quick_nock"` at Lv 12. The ladder is documented as pick-one-of-N in the future; for now all perks at the same level are active simultaneously. Confirm whether these new ids conflict with any planned pick-one groups before Task 7 ships.

2. **Second ring slot** — `Equipment.SLOT_ORDER` has one `ring` slot; adding a second (`ring2`) before Phase 3 ships would require a `SLOT_OFFSET` entry in the panel and a save-schema migration. If this is planned, deciding before Task 6 avoids a panel-height re-layout. If deferred, the window calculated from `inventory.rows` dynamically still accommodates it later.

3. **Stacking scope for crafting materials** — `game.materials` is a flat `Dictionary` (string→int) that lives entirely outside the Tetris grid. Phase 2 stacking only applies to consumable items that enter the grid. If materials ever move to the grid, Phase 2's `find_stack_cell` applies automatically (same `kind_id` match) — no extra work. The open question is whether that migration is intended.

4. **`Affixes.fmt_value` existence** — Task 9 references this helper. If `data/affixes.gd` does not export it, inline a two-branch format (`"%.0f" % val` for integer stats, `"%.0f%%" % (val*100)` for ratio stats) inside `_tooltip_lines`. Check `data/affixes.gd` before starting Task 9.

5. **`inventory_panel.gd` local `ROWS` const** — the panel has its own `const ROWS := 6` at line 13 (used in `_cell_at`, `_draw_grid`, `_win_rect`, and the `clamped` computation in `_draw_held`). Task 6 must replace all four of those with `inventory.rows` (or a guarded `inventory.rows if inventory != null else 6`) to avoid the constant shadowing the live value and breaking the new row.
