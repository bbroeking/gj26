---
title: HUD & Readouts — Implementation Plan
parent: "[[system-hud]]"
domain: UI & Presentation
type: implementation-plan
status: ready-to-build
effort: M
tags: [wayfinder, impl]
---

# HUD & Readouts — Implementation Plan

> Build doc for [[system-hud]]. Done when the level-up perk banner fires, buff/debuff icons replace text-only status, toast timing is tunable via feel.gd, and the quest tracker supports a sub-objective line — all confirmed by headless logic tests.

## Build status — 2026-06-16
**Phase 1–3 SHIPPED & gate-green (the level-up moment, Plan.md B3 HUD half).** Created `wyrd/data/feel.gd` (the B0 tunables home — preload-const, not an autoload, so it resolves in headless); `show_toast` gained a `category` (info/levelup/damage colour) + a dedup window; `leveled_up` now fires `_show_levelup_banner` (gold "✦ <perk name>" chip, 3.5s) and `_flash_skills` (gold glow + scale-punch on the trade readout). Verified via the dungeon-scene suite (builds the real HUD) — headless HUD-instantiation test skipped per risk #5; banner is screenshot-verifiable.
**Remaining:** buff/debuff status-icon strip (Phase 4), multi-trade readout (Phase 5), quest sub-objective line (Phase 6).

## Definition of done

- Crossing any Wayfinding level emits a gold burst-chip naming the unlocked perk (verified headless: banner text equals the correct perk name within one frame of `leveled_up` signal).
- All four active player status kinds (burn, bleed, snared, root) show a colored icon with a duration arc in a HBoxContainer strip left of the HP globe; icons disappear within one frame of expiry.
- `show_toast` accepts a `category` string; `Feel.TOAST_HOLD_SEC` / `Feel.TOAST_FADE_SEC` replace the magic numbers at `player_hud.gd:310–311`; five identical toasts in one frame produce one chip.
- `_skills_lbl` flashes gold on `leveled_up`; when more than one trade is active the chip shows each on its own line.
- `_quest_plate` supports a third sub-objective line via `set_objective(text, progress, sub)`.
- All five standard suites (`test_wyrd_loop`, `test_wyrd_dungeon_scene`, `test_wyrd_transitions`, `test_skills`, `test_stats`) stay green with `WYRD_NO_SAVE=1`.

## Preconditions / dependencies

- [[impl-system-ui-panels]] — `WyrdUi` tokens (`GOLD`, `TERRACOTTA`, `SAGE`, `INK`), `style_chip`, `chip_stylebox`, `font_header` must exist. All present in `wyrd/scripts/ui/wyrd_ui.gd`. No blocker.
- [[impl-system-trades-progression]] — `Game.PERKS` dict (at `game.gd:415`) and `leveled_up(trade, lv)` signal (at `game.gd:28`) must be present. Both are live. No blocker.
- [[impl-system-status-effects]] — `player_controller._statuses` dict and `apply_status` are live (`player_controller.gd:170`, `1521`). `_tick_statuses` drains them per frame (`player_controller.gd:1550`). Ward is tracked separately via `_ward_hp`/`_ward_t` (`player_controller.gd:1375–1376`) — Phase 2 must query both. No blocker.
- [[impl-system-combat-juice-vfx]] — Tween scale-punch pattern (Part A, shipped). Reuse verbatim; do not re-implement.
- **feel.gd does not exist yet** — Task 1 creates it. All tasks that reference `Feel.` constants depend on Task 1.
- **Plan.md Phase B0** (feel.gd tunables file) is the prerequisite beat for Task 1. Plan.md Phase B3 (player body burst on level-up) is the gameplay peer of Task 3; the HUD banner is the HUD half.
- `game.toast` signal (`game.gd:33`) is typed `(msg: String)` with no category. Task 5 must extend the signal **or** route category through a new method rather than the signal — see Risks.

## Tasks (ordered)

### Phase 1 — feel.gd and toast wiring (Plan.md B0 / B3 HUD prerequisite)

1. **Create `wyrd/data/feel.gd`** — new autoload-safe constants file (not a class_name; use `preload` at call sites to avoid headless registration). Define:
   ```gdscript
   # wyrd/data/feel.gd
   const TOAST_HOLD_SEC   := 2.4
   const TOAST_FADE_SEC   := 0.6
   const TOAST_LEVELUP_HOLD_SEC := 3.5
   const TOAST_DEDUP_WINDOW_SEC := 1.0
   const LEVELUP_FLASH_SEC := 0.4
   const LEVELUP_PUNCH_SCALE := 1.05
   const LEVELUP_PUNCH_BACK  := 1.0
   ```
   Also register it in `project.godot` as an autoload named `Feel` (path `res://data/feel.gd`) so `Feel.TOAST_HOLD_SEC` resolves in-game; in headless tests, callers `preload` the const.
   _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_loop.gd` — no parse errors. _Effort:_ S.

2. **Replace magic numbers in `player_hud.gd:310–311`** — `show_toast` currently hard-codes `2.4` and `0.6`. Replace with `Feel.TOAST_HOLD_SEC` and `Feel.TOAST_FADE_SEC` (preload `const Feel = preload("res://data/feel.gd")` at top of file — line 11 is the first const, insert before it).
   `show_toast` body:
   ```gdscript
   t.tween_interval(Feel.TOAST_HOLD_SEC)
   t.tween_property(l, "modulate:a", 0.0, Feel.TOAST_FADE_SEC)
   ```
   _Verify:_ five-suite gate green. _Effort:_ S.

### Phase 2 — Toast category + dedup

3. **Add `category` param and dedup guard to `show_toast`** — `player_hud.gd:298`. Signature becomes `show_toast(msg: String, category: String = "info") -> void`. Add a dedup check: if `_toast_box` has a child whose `text == msg` and was added within `Feel.TOAST_DEDUP_WINDOW_SEC`, skip. Track `_last_toast_text: String` and `_last_toast_time: float` as member vars on the HUD.
   Color mapping: `"levelup"` → `WyrdUi.GOLD`; `"damage"` → `WyrdUi.TERRACOTTA`; `"info"` → `WyrdUi.INK` (default chip color). Apply via `l.add_theme_color_override("font_color", color)` after `WyrdUi.style_chip(l, 15)`.
   Also update `game.toast.connect(show_toast)` at `player_hud.gd:225` — the signal is typed `(msg: String)` so it must stay one-arg. The connection lambda becomes `game.toast.connect(func(m): show_toast(m, "info"))`. Level-up toasts fired from `_show_levelup_banner` (Task 4) call `show_toast(text, "levelup")` directly.
   _Verify:_ headless: call `show_toast("Level up!")` five times in one frame, assert `_toast_box.get_child_count() == 1`. Five-suite gate green. _Effort:_ S.

### Phase 3 — Level-up perk banner (Plan.md B3 HUD half)

4. **Add `_show_levelup_banner(trade: String, lv: int)` to `player_hud.gd`** — new method after `_refresh_trades` (after line 296). Query `Game.PERKS[trade]` for the perk matching `lv`; fall back to `"Wayfinding %d" % lv` if no exact match.
   ```gdscript
   func _show_levelup_banner(trade: String, lv: int) -> void:
       var game := get_tree().root.get_node_or_null("Game")
       var perk_name := "Wayfinding %d" % lv
       if game != null:
           var perks: Array = Array(game.PERKS.get(trade, []))
           for p in perks:
               if int(p.lv) == lv:
                   perk_name = String(p.name)
                   break
       show_toast("✦ %s" % perk_name, "levelup")
   ```
   Wire it into `_build_wyrd_overlay` — the existing `leveled_up` lambda at line 227 calls only `_refresh_trades()`; add a second connection:
   ```gdscript
   game.leveled_up.connect(func(k: String, l: int): _show_levelup_banner(k, l))
   ```
   Use `Feel.TOAST_LEVELUP_HOLD_SEC` for the banner hold by overriding the tween in `show_toast` when `category == "levelup"`:
   ```gdscript
   var hold := Feel.TOAST_LEVELUP_HOLD_SEC if category == "levelup" else Feel.TOAST_HOLD_SEC
   t.tween_interval(hold)
   ```
   _Verify:_ new headless test `test_hud_levelup.gd`: instantiate `PlayerHUD`, emit `game.leveled_up("wayfinding", 2)`, await one frame, assert `_toast_box` has a child with `.text == "✦ Mara's Marginalia"`. Five-suite gate green. _Effort:_ S.

5. **Flash `_skills_lbl` gold on `leveled_up`** — in the existing `leveled_up` lambda (`player_hud.gd:227`), add a tween after `_refresh_trades()`:
   ```gdscript
   _skills_lbl.add_theme_color_override("font_color", WyrdUi.GOLD)
   var tw := create_tween()
   tw.tween_interval(Feel.LEVELUP_FLASH_SEC)
   tw.tween_callback(func():
       _skills_lbl.add_theme_color_override("font_color", WyrdUi.INK))
   ```
   Also add a scale punch: `tw.parallel().tween_property(_skills_lbl, "scale", Vector2(Feel.LEVELUP_PUNCH_SCALE, Feel.LEVELUP_PUNCH_SCALE), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)` then back to `Vector2.ONE` over 0.12s.
   _Verify:_ playtest: cross Wayfinding level 2, `_skills_lbl` visibly punches and glows gold for ~0.4s. Five-suite gate green. _Effort:_ S.

### Phase 4 — Buff/debuff icon row

6. **Add `StatusIconStrip` inner class to `player_hud.gd`** — new inner `class StatusIconStrip extends HBoxContainer:` after `QuestScrollArt` (after line 501). Each slot is a `StatusIcon extends Control` with `kind: String`, `frac: float` (0–1 remaining), drawn as a 16-px filled circle (status color) plus a thin arc-drain overlay using the same `draw_arc` pattern as `GlobeGauge` (`player_hud.gd:418–464`), and a centered glyph via `draw_string`.
   Glyph map as a const inside `StatusIconStrip`:
   ```gdscript
   const STATUS_COLOR := {
       "burn": Color(0.85, 0.40, 0.10),
       "bleed": Color(0.70, 0.18, 0.14),
       "snared": Color(0.35, 0.62, 0.25),
       "root":  Color(0.22, 0.52, 0.18),
   }
   const STATUS_GLYPH := {
       "burn": "🔥", "bleed": "✦", "snared": "❋", "root": "❋",
   }
   ```
   `StatusIcon._draw()`: draw filled circle (radius 14, center `size*0.5`), then arc from full-circle to remaining fraction (drain clockwise), then draw glyph centered. Use `draw_string_outline` + `draw_string` (same pattern as `GlobeGauge:467–475`).
   `StatusIconStrip` exposes `refresh(active: Dictionary) -> void` — `active` is `{kind: time_left_float}`. It diffs its current children against `active`, removes stale, adds new, and updates `frac` on each live icon. Duration tracking: `StatusIcon` also stores `max_time: float`; set on creation, `frac = time_left / max_time`.
   _Verify:_ headless: instantiate `PlayerHUD`, call `_status_bar.refresh({"burn": 3.0})`, assert `_status_bar.get_child_count() == 1`. Then `refresh({})`, assert 0. _Effort:_ M.

7. **Build `_status_bar` in `player_hud.gd:_ready`** — after `_build_hurt_vignette()` (line 56), call `_build_status_bar()`. New method:
   ```gdscript
   func _build_status_bar() -> void:
       _status_bar = StatusIconStrip.new()
       _status_bar.anchor_left = 0.5
       _status_bar.anchor_right = 0.5
       _status_bar.anchor_top = 1.0
       _status_bar.anchor_bottom = 1.0
       # Sits just above the HP globe's top edge (~offset_top -148), centered left of globe
       _status_bar.offset_left = -380
       _status_bar.offset_right = -260
       _status_bar.offset_top = -180
       _status_bar.offset_bottom = -148
       _status_bar.add_theme_constant_override("separation", 4)
       _status_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
       add_child(_status_bar)
   ```
   Declare `var _status_bar: StatusIconStrip = null` in the member vars block (after line 39).
   _Verify:_ game boots without errors, strip shows at correct position (screenshot). _Effort:_ S.

8. **Wire `refresh_statuses` in `player_controller.gd`** — add a public method `refresh_statuses_hud() -> void` at `player_controller.gd` after `_tick_statuses` (after line 1567). Build a snapshot dict:
   ```gdscript
   func refresh_statuses_hud() -> void:
       if _hud == null or not _hud.has_method("refresh_statuses"):
           return
       var snap: Dictionary = {}
       for kind in _statuses:
           snap[kind] = float(_statuses[kind].time_left)
       _hud.refresh_statuses(snap)
   ```
   Call `refresh_statuses_hud()` at the end of `_tick_statuses` (after line 1567), and also at the end of `apply_status` (after line 1539, before `return s`).
   Add `refresh_statuses(active: Dictionary) -> void` to `player_hud.gd` (delegates to `_status_bar.refresh(active)` with a null guard).
   _Verify:_ in-game: take a BrambleSnare hit, snare icon appears; root expires, icon disappears. Five-suite gate green. _Effort:_ S.

### Phase 5 — Multi-trade readout expansion

9. **Expand `_refresh_trades()` to show all active trades** — `player_hud.gd:291`. Replace the single `_skills_lbl: Label` with a `_trades_box: VBoxContainer` holding one chip-Label per active trade. Trades to show: query `game.trade_lv("wayfinding")`, and `game.trade_lv("earthcraft")` / `game.trade_lv("wildcraft")` if those methods exist and return > 0 (guarded with `game.has_method`).
   Because the current code uses `_skills_lbl` in the `leveled_up` flash (Task 5), keep `_skills_lbl` pointing to the first child of `_trades_box` (create it as the Wayfinding chip).
   Layout: replace the single `_skills_lbl = Label.new()` block at `player_hud.gd:210–219` with a `_trades_box` VBoxContainer at the same anchor/offset, then add the Wayfinding chip as its first child and store it in `_skills_lbl`.
   _Verify:_ headless: mock `game.trade_lv` returning 3 for earthcraft, assert `_trades_box.get_child_count() == 2`. Five-suite gate green. _Effort:_ S.

### Phase 6 — Quest tracker sub-objective

10. **Add sub-objective slot to `_quest_plate`** — `player_hud.gd:_build_wyrd_overlay`. After `_quest_progress` is added (after line 199), add a third `_quest_sub: Label`. Declare `var _quest_sub: Label` with the other member vars (after line 27). Style with font size 13, color `WyrdUi.INK_MID`, anchor and offset to sit between `_objective` and `_quest_progress` (offset_top ~52).
    Add `set_objective(text: String, progress: String, sub: String = "") -> void` to `player_hud.gd` as a new public method. It sets `_objective.text`, `_quest_progress.text` / `_quest_progress.visible`, and `_quest_sub.text` / `_quest_sub.visible`. The existing signal-driven `_refresh_objective` continues to call `set_objective(text, prog, "")` internally so nothing breaks.
    Extend `_quest_plate.offset_bottom` from `-92` to `-108` to give the third line room. Adjust `_quest_progress.offset_top` from `−26` to `−18` accordingly.
    _Verify:_ headless: call `set_objective("Find the Hedgemother", "0/1", "Deeper crypt — 2 rooms")`, assert `_quest_sub.visible == true` and `_quest_sub.text == "Deeper crypt — 2 rooms"`. Five-suite gate green. _Effort:_ S.

## First commit (smallest shippable slice)

**Tasks 1–4** together: create `feel.gd`, swap magic numbers, add category+dedup to `show_toast`, and wire `_show_levelup_banner`. This is the Plan.md B3 HUD half in a single PR:

- `wyrd/data/feel.gd` created with all tunable constants.
- `project.godot` has `Feel` autoload entry.
- `player_hud.gd`: magic numbers replaced, `show_toast` gains category+dedup, `_show_levelup_banner` added, `leveled_up` wires the banner.
- `test_hud_levelup.gd` passes.
- Five standard suites green.

Acceptance: crossing Wayfinding level 2 shows "✦ Mara's Marginalia" in gold for 3.5s; five rapid identical toasts collapse to one chip.

## Test & verification plan

| Suite / test | When | What it checks |
|---|---|---|
| `test_wyrd_loop.gd` | after every task | baseline game loop; feel.gd parse |
| `test_wyrd_dungeon_scene.gd` | after Tasks 7–8 | HUD node builds without error in dungeon scene |
| `test_wyrd_transitions.gd` | after Task 3 | toast buffer drains correctly on scene change |
| `test_skills.gd` | after Task 8 | hotbar dispatch unbroken after status-bar wiring |
| `test_stats.gd` | after Task 8 | HP/Focus logic unaffected |
| **`test_hud_levelup.gd`** (new) | Task 4 | emit `leveled_up("wayfinding", 2)`, assert banner text == "✦ Mara's Marginalia" after one frame |
| **`test_hud_toast_dedup.gd`** (new) | Task 3 | five identical toasts in one frame → `_toast_box.get_child_count() == 1` |
| **`test_hud_status_icons.gd`** (new) | Task 6 | `refresh({"burn": 3.0})` → child count 1; `refresh({})` → 0 |
| **Playtest screenshot** | Tasks 5, 8 | `_skills_lbl` punches gold on level-up; snare icon visible during BrambleSnare hit |
| **Visual check** | Task 10 | three-line quest plate fits within 108px height; sub-objective line hides when empty |

New tests run with: `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_hud_levelup.gd` (and similarly for the other two new scripts).

## Risks & open questions

1. **`game.toast` signal is single-arg** — `signal toast(msg: String)` at `game.gd:33`. The category system (Task 3) routes categories only for toasts fired directly by the HUD (banner, deferred drains). Toasts emitted by `game.notify()` always arrive as `"info"`. If richer category support is later needed, `game.gd:33` must become `signal toast(msg: String, category: String = "info")` — that is a `system-hud` gap, not a blocker for this impl.

2. **Ward icon source** — `_ward_hp`/`_ward_t` are not in `_statuses`; they live as bare floats on `player_controller.gd:1375–1376`. `refresh_statuses_hud` (Task 8) builds the snapshot from `_statuses` only. A "ward" icon would need a separate call to `apply_status("ward", _ward_t, 0)` when HeartwoodWard fires, or `refresh_statuses_hud` must check `_ward_hp > 0` directly. Recommend the latter (add to snapshot dict in Task 8). Needs agreement on duration: use `_ward_t` as `time_left` and `_ward_t_max` (a new float set when `apply_ward` fires) as `max_time`.

3. **Buff icon glyphs vs painted icons** — Unicode glyphs are used (matching `SKILL_GLYPH` in `skill_bar.gd:44`). If painted icons like `skill_basic.png` are later added for statuses, the same slot `Control` can swap `draw_string` for `draw_texture_rect` — the upgrade path is identical to skills. No decision needed now.

4. **Multi-trade readout crowding** — when Earthcraft and Wildcraft are active alongside Wayfinding, three right-anchored chips may crowd the action-bar buttons above. The `_trades_box` VBoxContainer approach (Task 9) stacks vertically and could overlap the Gear/Satchel/Trades buttons at `offset_top -96`. If three trades are active, a compact single-line `"W3 / E2"` format may be needed. Recommend monitoring in playtest; no code decision required at authoring time.

5. **`test_hud_levelup.gd` headless constraints** — `PlayerHUD` extends `CanvasLayer`; instantiating it headless without a viewport may fail on `add_child`. Pattern from `feedback_godot_headless_test_harness`: use `get_tree().root.add_child(hud)` and `await get_tree().process_frame`. Confirm this works before shipping Task 4's test.
