---
title: UI Kit & Panels — Implementation Plan
parent: "[[system-ui-panels]]"
domain: UI & Presentation
type: implementation-plan
status: ready-to-build
effort: M
tags: [wayfinder, impl]
---

# UI Kit & Panels — Implementation Plan

> Build doc for [[system-ui-panels]]. The shrine-choice modal is kit-styled, a buff-HUD chip shows active shrine buffs with draining meters, the chart/affix body text is font-consistent, the vendor hover contrast and scroll thumb are fixed, and the affix-reveal animates one-by-one on craft.

## Build status — 2026-06-16

**Tasks 5 + 8 (Phase 3) SHIPPED** in `inventory_panel.gd`:
- `_draw_slots`: `get_theme_default_font()` replaced with `WyrdUi.font_body()` + fallback.
- `_draw_tooltip`: same replacement + rarity accent stripe (items-affixes task 12 — see that note). Scroll thumb (`_draw_scroll_marker`) already at 7 px — no-op per risk note 3.

**Loadout + bench font polish SHIPPED** (`crafting_bench.gd`, `loadout_panel.gd`):
- `BenchView._draw()`: `get_theme_default_font()` replaced with `WyrdUi.font_body()` + fallback. Locks kit-font consistency across the bench tray, codex, tips, and result pane.
- `_SkillCard._draw()`: same replacement. Locked-card overlay uses `Color(WyrdUi.KIT_PLATE, 0.45)` (matches kit vocabulary). Focus-cost chip background uses `WyrdUi.KIT_WELL` (recessed read) instead of raw `Color(0.86, 0.79, 0.66)`.

**Deferred (out of scope for this agent):** tasks 1–4 (shrine modal, buff HUD chip — touch `player_controller.gd`/`player_hud.gd`), tasks 6–7 (vendor hover + font — `vendor_panel.gd` not in scope), tasks 9–12 (affix-reveal animation — requires `craft()` logic change), task 12 portrait stub (`dialog_panel.gd`).

## Definition of done

- `shrine_choice_modal.gd` uses `WyrdUi.style_panel` + drawn `_BuffCard` controls indistinguishable in visual language from vendor/loadout/waystone panels.
- `player_hud.gd` renders one `_BuffChip` per active shrine buff (from `player_controller.shrine_buffs` delta-tracked) with a draining trough; chip disappears when the buff is no longer tracked.
- No `get_theme_default_font()` call remains inside any panel `_draw()` body (inventory tooltip `inventory_panel.gd:547`, vendor card `vendor_panel.gd:268`).
- Vendor hover overlay bumped to `0.14` alpha; inventory scroll thumb width increased to `7px` in `_draw_scroll_marker`.
- `BenchView._draw_result` reveals affixes sequentially after `craft()`, ~0.3s per affix, each with a `pop()` overshoot.
- All four headless suites stay green (`WYRD_NO_SAVE=1`). `wyrd/tools/check_ninepatch.py` clean after any stylebox change.

## Preconditions / dependencies

- [[impl-system-hud]] — `player_hud.gd` is the host file for the buff chip; the globe layout and chip anchor positions are already stable there (Task 4 adds a new `_build_buff_chips()` call in `_ready`).
- `shrine_buffs` dict lives on `PlayerController` (`player_controller.gd:151–153`), not on `Game` — the HUD must reach the local player node. The `player_hud.gd` `_build_wyrd_overlay` already uses `get_tree().get_first_node_in_group("player")` or `game.local_player()` patterns; Task 4 follows the same pattern.
- `Game.buffs_changed` signal (`game.gd:496`) tracks **timed draught buffs** on `Game.buffs`. Shrine buffs are permanent-per-run accumulations on `player_controller.shrine_buffs` — no signal exists yet. Task 4a adds `signal shrine_buff_applied` to `PlayerController` so the HUD can connect cleanly instead of polling.
- [[impl-system-crafting]] — `BenchView._pops` / `stamp()` machinery is the animation substrate for Task 5. It is already present (`crafting_bench.gd:282–344`). Task 5 adds `_reveal_t`/`_reveal_idx` fields alongside the existing ones.
- [[impl-system-charts-wayfinding]] / [[impl-system-items-affixes]] — odds-row data in `_draw_result` is the render target for Task 5; no data changes needed.
- No missing files. `shrine_choice_modal.gd` exists at `wyrd/scripts/shrine_choice_modal.gd:1–78`; its `.tscn` scene is preloaded by `shrine.gd:10`.

## Tasks (ordered)

### Phase 1 — Shrine-choice modal kit port

1. **Apply `WyrdUi.style_panel` to `shrine_choice_modal.gd:_ready`** — `shrine_choice_modal.gd:26–36`. After `_panel = Panel.new()` and before `add_child(_panel)`, insert `WyrdUi.style_panel(_panel)`. The `_panel` also needs `custom_minimum_size = Vector2(680, 340)` (10px wider to accommodate card padding). _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_loop.gd` green. Visual: `WYRD_SHOT=1` run into a dungeon with a shrine. _Effort:_ S.

2. **Replace raw title label with `WyrdUi.style_title`** — `shrine_choice_modal.gd:38–46`. Remove `add_theme_font_size_override("font_size", 28)`, replace with `WyrdUi.style_title(title)`. Change `offset_top = 16` / `offset_bottom = 56` to `offset_top = 22` / `offset_bottom = 60` to match panel inset from the carved wood frame. _Verify:_ same suite + screenshot shows terracotta small-caps header over the parchment frame. _Effort:_ S.

3. **Replace raw `Button` buff cards with drawn `_BuffCard` inner class** — `shrine_choice_modal.gd:65–71`. Remove `Button.new()` card loop. Add an inner class `_BuffCard extends Control` (mirror `_VendorCard` in `vendor_panel.gd:220–289`): `custom_minimum_size = Vector2(192, 210)`, `_draw()` calls `WyrdUi.draw_list_row(self, Rect2(Vector2.ZERO, size), accent)` where `accent = WyrdUi.SAGE` (positive buff), then draws buff name at y=32 with `WyrdUi.font_header()` + TERRACOTTA, description lines at y=56 with `WyrdUi.font_body()` + INK, and a centered glyph (`✦`) in GOLD at y=164. Wire `gui_input` for click → emit `chosen`. Sketch:
   ```gdscript
   var card := _BuffCard.new()
   card.buff = b
   card.accent = WyrdUi.SAGE
   card.pressed.connect(_on_pressed.bind(b))
   _hbox.add_child(card)
   ```
   _Verify:_ four-suite gate green; `WYRD_SHOT=1` screenshot shows three parchment card rows identical in language to vendor panel. `wyrd/tools/check_ninepatch.py` clean. _Effort:_ M.

### Phase 2 — Buff HUD chip

4a. **Add `signal shrine_buff_applied` to `PlayerController`** — `player_controller.gd:1396–1400`. After `shrine_buffs[stat] += value` and `_derive_stats()`, emit: `shrine_buff_applied.emit(stat, value)`. Also add `signal shrine_buff_applied(stat: String, value: float)` near the existing `signal gear_changed` at `player_controller.gd:136`. This gives the HUD a clean hook without polling. _Verify:_ four-suite gate green (signal emit is a no-op if nothing is connected). _Effort:_ S.

4b. **Add `_build_buff_chips()` to `player_hud.gd:_ready`** — `player_hud.gd:59`. After `_build_mute_indicator()`, call `_build_buff_chips()`. Implement `_build_buff_chips()` to create a `VBoxContainer _buff_chip_box` anchored top-right (above action bar): `anchor_left = 1.0`, `anchor_right = 1.0`, `offset_left = -360`, `offset_top = 10`, `offset_right = -16`. Get the local player node (same pattern as `_build_wyrd_overlay` — `get_tree().root.get_node_or_null("Game")` + `game.local_player()` / `get_tree().get_first_node_in_group("player")`); if found and has signal `shrine_buff_applied`, connect `_on_shrine_buff_applied`. Sketch:
   ```gdscript
   var player := _get_local_player()
   if player != null and player.has_signal("shrine_buff_applied"):
       player.shrine_buff_applied.connect(_on_shrine_buff_applied)
   ```
   _Verify:_ four-suite gate green. _Effort:_ S.

4c. **Implement `_BuffChip` inner class in `player_hud.gd`** — new inner class below `QuestScrollArt`. A `Control` with `custom_minimum_size = Vector2(200, 32)`. Holds `stat: String`, `value: float`. `_draw()` uses `WyrdUi.chip_stylebox()` painted as `StyleBoxFlat` (draw_rect with `KIT_PLATE` fill + `KIT_EDGE` border + GOLD accent stripe left-edge via `WyrdUi.draw_list_row`), draws stat name in Caveat hand font (14px, INK) left-padded, and value string right-padded in GOLD. Since shrine buffs are permanent-per-run (no duration), the chip is a pure static label — no trough. Chips are rebuilt in `_on_shrine_buff_applied` by clearing and re-adding one chip per non-zero entry in `player.shrine_buffs`. Sketch:
   ```gdscript
   func _on_shrine_buff_applied(_stat: String, _val: float) -> void:
       for c in _buff_chip_box.get_children():
           c.queue_free()
       var player := _get_local_player()
       if player == null: return
       for key in player.shrine_buffs:
           if float(player.shrine_buffs[key]) == 0.0: continue
           var chip := _BuffChip.new()
           chip.stat = String(key)
           chip.value = float(player.shrine_buffs[key])
           _buff_chip_box.add_child(chip)
   ```
   _Verify:_ logic test in `test_wyrd_loop.gd` — create a mock player with `shrine_buffs`, call `apply_shrine_buff("hp", 20)`, assert chip box child count == 1; four-suite gate green. _Effort:_ M.

### Phase 3 — Font consistency + vendor readability + scroll thumb

5. **Replace `get_theme_default_font()` in `inventory_panel.gd` tooltip draw** — `inventory_panel.gd:547`. Change `var font := get_theme_default_font()` to:
   ```gdscript
   var font: Font = WyrdUi.font_body()
   if font == null:
       font = get_theme_default_font()
   ```
   Same replacement at `inventory_panel.gd:431` (the `_draw_slots` fallback at line 430–431). _Verify:_ four-suite gate green. _Effort:_ S.

6. **Replace `get_theme_default_font()` in `vendor_panel.gd` `_VendorCard._draw`** — `vendor_panel.gd:268`. Change `var font := get_theme_default_font()` to:
   ```gdscript
   var font: Font = WyrdUi.font_body()
   if font == null:
       font = get_theme_default_font()
   ```
   _Verify:_ four-suite gate green; screenshot with `WYRD_UI_SHOT=vendor` (see `wyrd/tools/capture_ui.sh`) shows vendor card text in IM Fell. _Effort:_ S.

7. **Bump vendor hover contrast** — `vendor_panel.gd` `_VendorCard` hover overlay. Find the `_hover` overlay draw call (the `if _hover:` block in `_VendorCard._draw`); change alpha from `0.10` to `0.14`. Exact line to verify with a `grep -n "_hover\|hover.*overlay\|0\.10" vendor_panel.gd` at task time. _Verify:_ `WYRD_UI_SHOT=vendor` screenshot shows visible hover highlight. _Effort:_ S.

8. **Widen inventory scroll thumb from 4px to 7px** — `inventory_panel.gd:686–688`. The track is `Vector2(4.0, ...)` at line 681; the thumb `Rect2` width at line 688 is currently `Vector2(7.0, th)` — the parent note says 4px but the code already reads 7px. **Re-verify at task time** with `grep -n "thumb\|4\.0\|7\.0" inventory_panel.gd`; if the thumb is already 7px, this task is a no-op and can be dropped. If the track rect width at 681 is still 4px, widen it to 7px and shift `track.position.x` inward by 1.5. _Verify:_ four-suite gate green; screenshot Pack panel with a tall satchel showing the thumb. _Effort:_ S.

### Phase 4 — Affix-reveal animation (Plan.md Part B / Phase B6b)

9. **Add `_reveal_idx: int` and `_reveal_t: float` fields to `BenchView`** — `crafting_bench.gd:282` (alongside `_stamp_t`, `_pops`). Initialize: `var _reveal_idx: int = -1` / `var _reveal_t: float = 0.0`. When `_reveal_idx >= 0`, `_process` already runs (`set_process(true)` is called by `pop()`); piggyback on the same `_process` method. Sketch in `BenchView._process`:
   ```gdscript
   if _reveal_idx >= 0 and _reveal_t > 0.0:
       _reveal_t -= delta
       if _reveal_t <= 0.0:
           _reveal_idx += 1
           pop("affix%d" % _reveal_idx)
           _reveal_t = 0.3
       busy = true
   ```
   _Verify:_ four-suite gate green (field additions are inert). _Effort:_ S.

10. **Wire reveal start from `craft()` success** — `crafting_bench.gd` (the `craft()` public method). After `_game.inscribe_chart(...)` or equivalent success path, add:
    ```gdscript
    _view._reveal_idx = 0
    _view._reveal_t = 0.3
    _view.set_process(true)
    ```
    Also add a stop condition in `_process`: when `_reveal_idx >= computed_affix_count` (bench computes affix count via `bench.affix_slots()` + `(1 if bench.trophy != "" else 0)`), set `_reveal_idx = -1`. _Verify:_ manual playtest — inscribe a chart and observe sequential affix appearance; logic test: `craft()` then advance `_process(0.35)` three times, assert `_reveal_idx` incremented. _Effort:_ M.

11. **Gate affix rows in `_draw_result` behind `_reveal_idx`** — `crafting_bench.gd:806–828`. The odds-rows loop currently draws all affix rows unconditionally. Add a counter `var drawn := 0` before the loop; inside the loop add `if _reveal_idx >= 0 and drawn >= _reveal_idx: break`. Trophy line (line 822–828) similarly gated: only draw if `_reveal_idx < 0 or drawn < _reveal_idx`. Each freshly revealed affix calls `pop("affix%d" % drawn)` which applies the scale-overshoot via `_pop_scale`. _Verify:_ `WYRD_FEEL=inscribe` feel-bench capture (Plan.md B-3 feel bench); four-suite gate green. _Effort:_ M.

### Phase 5 — Portrait slot expansion (art-gated)

12. **Add `portrait_tex: Texture2D` to `dialog_panel.gd:PortraitWell`** — `dialog_panel.gd:137`. Add `var portrait_tex: Texture2D = null` to the `PortraitWell` class. In `PortraitWell._draw()`, before or instead of the silhouette placeholder, add:
    ```gdscript
    if portrait_tex != null:
        draw_texture_rect(portrait_tex, Rect2(Vector2.ZERO, size), false)
    else:
        # existing silhouette draw...
    ```
    Callers (`quill_npc.gd` etc.) set `dialog.portrait_tex = preload("res://assets/portraits/quill.png")` in `_ready` — **preload in `_ready`, never `load()` in `_draw()`** (memory: godot-draw-load-white-texture). This task is a code stub; shipping it requires the portrait art asset. _Verify:_ four-suite gate green; null portrait still shows silhouette (regression guard). `WYRD_UI_SHOT=dialog` once an asset lands. _Effort:_ S (code stub only).

## First commit (smallest shippable slice)

**Tasks 1–3** (shrine modal kit port): apply `WyrdUi.style_panel`, replace the title label, replace raw Button cards with drawn `_BuffCard` controls. Acceptance: `WYRD_SHOT=1` screenshot of the shrine modal shows three parchment cards on the carved wood frame, visually consistent with vendor/loadout panels. Four-suite gate green. This is the highest-priority gap per the parent note ("BLOCKER — cosmetic") and the smallest coherent unit of user-visible polish.

## Test & verification plan

| Suite | When to run |
|-------|------------|
| `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_loop.gd` | After every task — this is the main integration suite |
| `test_wyrd_dungeon_scene.gd` | After Tasks 4a–4c (buff chip), Task 10 (reveal wire) |
| `test_wyrd_transitions.gd` | After Tasks 1–3 (modal opens/closes without leaking the pause) |
| `test_skills.gd` | After Phase 3 (font pass); confirms hotbar dispatch unaffected |
| `wyrd/tools/check_ninepatch.py` | After Tasks 1, 3 (any `StyleBoxTexture` changes) |

**New logic tests to author** (add to `test_wyrd_loop.gd`):
- Task 4c verification: mock a `PlayerController`-like node with `shrine_buffs` dict; call `apply_shrine_buff("hp", 20)`; assert `_buff_chip_box.get_child_count() == 1`.
- Task 10 verification: instantiate `CraftingBench`, call `place_base("standard")` + `craft()`; call `_view._process(0.35)` × 3; assert `_view._reveal_idx == 3` (or stopped at affix count).

**Screenshot / feel-bench captures**:
- `WYRD_SHOT=1` after Tasks 1–3: shrine modal styled.
- `WYRD_UI_SHOT=vendor` after Task 6–7: vendor hover contrast.
- `WYRD_FEEL=inscribe` after Tasks 9–11: sequential affix reveal.
- `WYRD_UI_SHOT=dialog` after Task 12 (once portrait art exists).

## Risks & open questions

1. **Shrine buff display vs timed buff display**: `player_controller.shrine_buffs` is a permanent-per-run accumulation (no duration); `game.buffs` is the timed draught system with `left` countdowns. The parent note describes a "draining trough" for the buff chip. With shrine buffs having no expiry, the trough would be meaningless — the implementation here uses a **static chip** (name + value) instead. If the design intent is to show timed draught buffs in the HUD chip (rather than shrine buffs), Tasks 4a–4c should connect to `game.buffs_changed` and read `game.buffs` instead. **Decision needed from user.**

2. **`_BuffCard` mouse region**: `Control.gui_input` requires `mouse_filter = MOUSE_FILTER_STOP`. If the `_BuffCard` inner class draws over the `_hbox` container, the parent `_hbox` already has `mouse_filter = MOUSE_FILTER_PASS` by default — the child cards will receive clicks correctly. Confirm during Task 3 that the modal resumes the tree on card click (calls `get_node("/root/Game").modal_closed()`).

3. **Scroll thumb discrepancy**: The parent note says the thumb is 4px; the current code (`inventory_panel.gd:688`) already shows `Vector2(7.0, th)`. Task 8 may be a no-op. Verify at task time.

4. **Affix-reveal stop condition**: When `bench.affix_slots() == 0` (a clean chart), the reveal loop would start at `_reveal_idx = 0` and immediately overshoot. Guard: only start the reveal sequence if `bench.affix_slots() > 0 or bench.trophy != ""`.

5. **Portrait art asset**: Task 12 is code-only. The `res://assets/portraits/quill.png` asset must exist before the portrait renders; the stub is inert until then. Coordinate with art pipeline (Midjourney → clean pass → import).
