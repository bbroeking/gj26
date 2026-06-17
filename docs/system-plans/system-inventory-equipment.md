---
title: Inventory (Tetris) & Equipment
domain: Gather · Craft · Economy
type: system
status: partial
effort: M
tags: [wayfinder, plan]
---

# Inventory (Tetris) & Equipment

> Core data model and drag-UI are fully shipped; the remaining work is pack-size progression tied to Wayfinding mastery, stacking rules for consumables, a "full pack" visual/SFX prompt, and the deferred InventoryController split triggered when a second view (vendor) goes live.

## Current state

**Data layer — complete.** `wyrd/scripts/inventory.gd` (lines 1–99) implements the full 5×6 Tetris grid: `COLS = 5`, `ROWS = 6`, per-cell back-references, `can_place` / `try_place` / `remove` / `move` / `find_first_fit` with rotation. Footprint axis-swap on rotation is correct (`footprint()` static helper, line 25). The model is a `RefCounted`; item dicts carry `pos: Vector2i`, `rotated: bool`, and `size: Vector2i`.

**Equipment layer — complete.** `wyrd/scripts/equipment.gd` (lines 1–51) owns 7 named slots: `weapon / helmet / chest / boots / ring / pickaxe / axe` (`SLOT_ORDER`, line 11; spec 38 trade-tool extension). `equip()` returns the displaced item; `changed` signal fires on every mutation. The trade-tool pair (pickaxe/axe) never eats bag space when equipped.

**Panel — complete except full-pack feedback and accessibility polish.** `wyrd/scripts/inventory_panel.gd` (lines 1–901) renders in a single `_draw` pass: paper-doll + 7 slots (SLOT_OFFSET map, lines 28–39), Tetris grid (64px cells), drag/rotate (R key, line 153), green/red drop-preview ghost, right-click quick-equip, rarity glows, hover tooltips via `Affixes.format_affix` (lines 505–552), full four-tab window (Gear / Satchel / Charts / Trades) with scrollable non-Gear pages. All icon textures are preloaded in `_ready` (lines 109–117) — the Godot `_draw`-load-white-texture gotcha is already avoided.

**Derived stats — complete.** `player_controller._derive_stats()` (line 1082) sums `base_stat` + `affixes` from all 7 equipment slots, then overlays shrine buffs and Wayfinding perks. `equipment.changed` → `_on_gear_changed()` (line 1057) triggers the recalc and plays `equip` SFX. Level-up also re-derives stats (`_on_leveled_up`, line 1068) with delta-HP growth.

**Pickup and save — complete.** `item_pickup.try_take()` (line 99) runs `find_first_fit` → `try_place`; if no fit, the item stays on the ground with a log line (no in-game HUD prompt yet). `save_game.gd` serializes `inventory.items` and `equipment.slots` with Vector2i round-tripping (lines 27–111).

**What is skeletal / missing:**
- No stacking rules — every gear item always occupies its full footprint regardless of count; consumable-type objects (draughts, tonics) land in the grid as 1×1 single items rather than stacking.
- Pack-size progression is not implemented: `Inventory.ROWS` and `COLS` are compile-time constants; no Wayfinding mastery perk unlocks extra rows.
- "Inventory full" feedback is a `print()` only (`item_pickup.gd:110`) — no on-screen prompt or SFX.
- ADR 0001 deferred `InventoryController` extraction until a second view (vendor) forces the seam.
- `ledger.gd` trophy stat source is a followup stub in ADR 0013 — not yet wired; equipment derives power, trophies do not yet contribute.

## Gaps — what needs fleshing out

1. **(blocker for feel)** "Inventory full" HUD prompt — a brief pop-up or HUD chip + `inv_full` SFX when `try_take` returns false. Players currently get no feedback that an item was left on the ground.
2. **(polish)** Consumable stacking — draughts/tonics occupy 1×1 each; a `stack_max` field on item dicts + a `find_stack_cell` path in `try_take` would let them merge instead of clutter the grid.
3. **(progression)** Pack-size progression — Spec 32's design notes reference a future mastery perk that adds a row; the constant `ROWS = 6` must become a runtime value read from the player's Wayfinding level, with `Inventory.resize(new_rows)` shifting placed items if needed.
4. **(architecture, deferred)** InventoryController split (ADR 0001) — triggered by the vendor panel landing. Until then, drag-state and `try_equip` logic live in `inventory_panel.gd`; this is intentional per the ADR.
5. **(economy)** Trophy / Ledger stat source (ADR 0013 followup #1) — `ledger.gd` is not yet a live stat source; boss trophies do not contribute to `_derive_stats`. Low urgency until Deepening depth playtests.
6. **(UX)** "Compare on hover" — tooltip shows the hovered item's stats but no delta vs. currently equipped. A second tooltip column or diff line would let players make informed swap decisions without opening the slots separately.
7. **(UX)** Keyboard navigation — the panel is mouse-only; a keyboard cursor for accessibility / controller support is not planned but worth noting.

## Plan

### Phase 1 — Full-pack feedback (S)

Ship a small HUD chip or floating label at the player's feet when `try_take` returns false.

- In `item_pickup.try_take()` (line 110): after the `print`, call `sfx.play("inv_full")` if an Sfx node exists.
- Add a brief on-screen label via `player_controller` or `player_hud`: `"Pack full — %s left behind" % preview.name`, fading over 2s using a `Tween`. Reuse the existing `notify()` path in `game.gd` (line 291) — that's the correct seam; `game.notify()` already surfaces a brief HUD message.
- **DoD:** Drop a pickup when the pack is full; a toast reads "Pack full — \<item name\> left behind." No `print`-only fallback. Manual playtest confirms the message surfaces during a dungeon run with a full grid.
- **Effort:** S

### Phase 2 — Consumable stacking (S)

Allow draughts and tonics to stack in a single 1×1 cell instead of consuming one cell each.

- Add `stack_max: int` to the relevant `KINDS` entries in `wyrd/data/items.gd` (currently missing; all gear is `stack_max = 1` implicitly). Draughts and tonics: `stack_max = 10`.
- Add `stack_count: int = 1` to item dicts built by `Items.make_item()`.
- In `Inventory.find_first_fit()`, before the full empty-cell scan, add `find_stack_cell(item)` that looks for a placed item with the same `kind_id` and `stack_count < stack_max`. Return that cell with `rotated = existing.rotated` if found.
- Update `_draw_item_in_grid` to render the stack count in the cell corner when `stack_count > 1`.
- **DoD:** Picking up 3 draughts fills one 1×1 cell with count "3". The save round-trip preserves `stack_count`. Headless: extend `test_wyrd_loop.gd` with a stack-pickup eval (`WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd`).
- **Effort:** S

### Phase 3 — Pack-size progression (M)

Tie grid row count to a Wayfinding mastery perk so clearing den tiers rewards more carry capacity.

- Change `Inventory.ROWS` from a compile-time `const` to a `var rows: int = BASE_ROWS` where `BASE_ROWS = 6`.
- Add `Inventory.resize(new_rows: int)` that expands `cells` (appending empty rows) or, on shrink, checks that the bottom rows are empty before truncating (refuse shrink if items would be orphaned).
- Add a Wayfinding perk entry in `game.gd`'s `PERKS` dict (e.g. `"pack_runner"` at Lv 5 and `"pack_master"` at Lv 12) that calls `game.inventory.resize(7)` / `resize(8)` respectively when unlocked. Wire the perk check into `_on_leveled_up` (line 1068).
- Update `inventory_panel.gd::_win_rect()` and `grid_origin` to use `inventory.rows` dynamically so the panel redraws at the correct height.
- **DoD:** At Wayfinding Lv 5 the grid visually gains a row. At Lv 12 it gains another. Save/load round-trips the inventory without orphaning items from the extra rows. `test_wyrd_loop.gd` includes a level-and-resize eval.
- **Effort:** M (perk table entry is trivial; `resize()` edge cases need care)

### Phase 4 — Compare-on-hover tooltip delta (S)

Surface the stat delta when hovering a grid item that could displace an equipped item of the same category.

- In `_tooltip_lines()` (line 505): after building the hovered item's lines, check `equipment.get_slot(item.category)`. If occupied, compute the delta for each shared stat and append diff lines (green for positive, terracotta for negative) using the same `Affixes.format_affix` formatter.
- **DoD:** Hovering a shortbow while a longbow is equipped shows "+2 damage vs equipped" or "−2 damage vs equipped" in the tooltip. No regression on normal/magic item hovers (no equipped item → no diff section).
- **Effort:** S

### Phase 5 — InventoryController split (M, deferred until vendor)

Triggered by ADR 0001's condition: a second view (vendor panel, `wyrd/scripts/ui/vendor_panel.gd`) needing the same cross-cutting drag/equip invariants.

- Extract `_try_pick_up_at`, `_try_drop_at`, `_quick_equip`, `_quick_unequip`, `_snap_back` into a new `InventoryController` (plain `RefCounted`) that holds `Inventory` + `Equipment` references and exposes them as pure, signal-free functions.
- `inventory_panel.gd` becomes a pure view — it calls controller methods, receives updated state via `Inventory`/`Equipment` signals, and redraws.
- **DoD:** Both `inventory_panel.gd` and `vendor_panel.gd` use the same controller. No duplicated equip-swap logic. ADR 0001's re-open condition is satisfied; the ADR is updated to "Accepted."
- **Effort:** M
- **Dependency:** Vendor panel must exist first (see [[system-economy]]).

## Dependencies & links

- [[system-items-affixes]] — item dicts (`kind_id`, `size`, `category`, `affixes`) are the payload that `Inventory.try_place` positions; rarity glows in the panel read from the same `RARITY_COLOR` map. Stacking rules (Phase 2) require a `stack_max` field added to `KINDS`.
- [[system-drops-loot]] — `ItemPickup.try_take` is the single pickup seam that calls `inventory.find_first_fit`; the "full pack" prompt (Phase 1) lives in the same path. Drop quality and item sizes set by drops feed directly into grid congestion.
- [[system-crafting]] — crafted gear lands in the inventory via `game.try_craft()` (line 375) which calls `inventory.find_first_fit`; if no fit, the craft silently fails. The "full pack" feedback (Phase 1) should fire here too — check `game.gd:375`.
- [[system-economy]] — the vendor panel (`vendor_panel.gd`) is the ADR 0001 trigger for the InventoryController split (Phase 5); `game.sell_item()` (line 327) removes items from the Tetris grid via `inventory.remove`.
- [[system-trades-progression]] — Wayfinding level drives pack-size progression (Phase 3) and gates the `"pack_runner"` / `"pack_master"` mastery perks. ADR 0013's `LEVEL_POWER` scaling also means a higher-level player carries better gear and benefits most from the extra rows.
- [[system-save-load]] — `save_game.gd` serializes `inventory.items` and `equipment.slots`; `stack_count` (Phase 2) and dynamic `rows` (Phase 3) must be added to the serialization schema with backward-compat (missing fields default to 1 / 6).
- [[system-hud]] — the "full pack" toast (Phase 1) and the diff tooltip (Phase 4) both touch HUD rendering; `game.notify()` is the shared seam.
- Plan.md Part B loop-feel (B5 loadouts, B6 affixes, B7 Huntcraft) are **all shipped** and feed into the equipment pipeline — gear affixes from B6 display in the panel's tooltip via `Affixes.format_affix`, loadout picks from B5 bypass the Tetris grid entirely (skills live in `game.loadout`, not the inventory). No duplication with those phases.

## Verification

**Phase 1 (full-pack toast):**
```
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd
```
Add an eval: fill the 5×6 grid (30 items), attempt one more pickup, assert `game.notify` was called with a "Pack full" message. Manual: run a dungeon with a full pack and confirm the toast appears.

**Phase 2 (consumable stacking):**
```
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd
```
Add an eval: pick up 3 draughts, assert `inventory.items.size() == 1` and `inventory.items[0].stack_count == 3`. Save + reload, assert count survives.

**Phase 3 (pack-size progression):**
```
WYRD_DEV_LEVEL=5 WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd
```
Assert `game.inventory.rows == 7` at Lv 5 and `rows == 8` at Lv 12. Visual: `WYRD_DEV_LEVEL=5 WYRD_SHOT=1 godot --path wyrd` → screenshot confirms the extra row renders.

**Phase 4 (compare tooltip):**
Manual only — equip a shortbow, hover a longbow in the grid, confirm diff lines appear with correct sign. No headless path for rendered tooltip content.

**Phase 5 (InventoryController split):**
All four headless suites must stay green after the refactor:
```
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_transitions.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd
```

## Open questions

1. **Pack-size perk names and levels** — "Pack Runner" at Lv 5 / "Pack Master" at Lv 12 are placeholders. Do these fit the Wayfinding perk ladder's current 6-perk schedule (spec 45)? If the ladder is full, one perk may need to be replaced or the expansion deferred to a second ring slot.
2. **Second ring slot** — only one `ring` slot exists currently. A second ring slot (common in ARPGs) would require a `SLOT_ORDER` change, a new `SLOT_OFFSET` entry, and a save-schema migration. Worth deciding before Phase 3 ships so the panel layout accounts for it.
3. **Stacking scope** — should crafting materials (`game.materials`) ever enter the Tetris grid, or do they remain in the satchel's flat dict forever? If materials go in the grid, Phase 2's stacking rules apply to them; if not, the satchel remains a separate flat store and the grid stays gear-only.
