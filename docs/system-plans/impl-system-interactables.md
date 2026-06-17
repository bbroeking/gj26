---
title: Interactables — Implementation Plan
parent: "[[system-interactables]]"
domain: World & Interactables
type: implementation-plan
status: ready-to-build
effort: M
tags: [wayfinder, impl]
---

# Interactables — Implementation Plan

> Build doc for [[system-interactables]]. Shrine modal is restyled to the WyrdUi kit, buff pool has 10 entries with off-stat variety, hearth's `load()` is replaced with `preload`, and waystone interact paths are covered by headless tests — moving status from partial to done.

## Definition of done

- `ShrineChoiceModal` displays three `_BuffCard` drawn controls using `WyrdUi.draw_list_row` / `WyrdUi.style_panel`; screenshot via `WYRD_UI_SHOT` matches the Loadout panel's visual weight.
- `Shrine.BUFF_POOL` has 10 entries; `test_typed_rooms.gd:_t4_shrine_buff` passes with the extended 5-seed sweep confirming at least one off-stat buff appears.
- `hearth.gd` uses `preload` for `loadout_panel.gd`; `T5` stays green.
- `test_wyrd_dungeon_scene.gd` carries `_t7_exit_waystone_interact` and `_t8_portal_waystone_no_crash`; both pass headless.
- All four headless suites green: `test_wyrd_loop`, `test_wyrd_dungeon_scene`, `test_wyrd_transitions`, `test_typed_rooms`.

## Preconditions / dependencies

- `WyrdUi.draw_list_row`, `WyrdUi.draw_well`, `WyrdUi.style_panel` already exist (`wyrd/scripts/ui/wyrd_ui.gd:79,156,268`). No new kit tokens needed.
- [[impl-system-status-effects]] — `apply_shrine_buff` writes into `player.shrine_buffs` which flows through `_derive_stats`; new off-stat keys (`focus_regen_bonus`, `iframes_bonus`, `skill_cd_mult`) must be added to both the dict (line 151) and the `_derive_stats` / `apply_shrine_buff` consumers (lines 1082–1129, 1396–1400). This is self-contained in `player_controller.gd`; status-effects impl does not need to land first.
- `dungeon_crypt_hearth_v1.glb` does **not** exist in `models/`; the GLB swap (parent note Phase 4) is asset-gated and is **not** in this plan. `hearth.gd` continues using the brazier until a dedicated model is commissioned via the Meshy pipeline.
- `dungeon_crypt_chest_v1.glb` lid-node status is unknown — chest lid animation (parent note Phase 3) is also **deferred** here because it requires Blender confirmation and pairs with Plan.md Part B / Phase B4 (pickup suck). See [[impl-system-combat-juice-vfx]].
- No other impl note must land before these tasks.

## Tasks (ordered)

### Phase 1 — ShrineChoiceModal restyling

1. **Apply `WyrdUi.style_panel` to the modal's backing Panel** — `shrine_choice_modal.gd:_ready` (line 36). Replace the raw `Panel.new()` with a styled panel: after `_panel = Panel.new()` add `WyrdUi.style_panel(_panel)`. Style the title label: call `WyrdUi.style_title(title)` (line 46) instead of the bare `add_theme_font_size_override`. Remove the ad-hoc `offset_top = 16` and use the same inset pattern as `loadout_panel.gd:79–83`.
   _Verify:_ `bash wyrd/tools/capture_ui.sh` with `WYRD_UI_SHOT=shrine` — panel frame now shows the carved-wood nine-patch. `WYRD_NO_SAVE=1` headless suites stay green (modal never runs headless — no regression risk). _Effort:_ S.

2. **Add `_BuffCard` inner class to `shrine_choice_modal.gd`** — new inner class after line 77, modelled on `loadout_panel.gd:_SkillCard` (lines 169–265). Differences from `_SkillCard`: no `_locked` / `_focus` / `_req` fields; accent color is always `WyrdUi.GOLD` (selected) or `WyrdUi.INK_MID` (idle); no padlock glyph; no focus-cost chip. Minimum size `Vector2(180, 200)`. Implement `_draw()` calling `WyrdUi.draw_list_row(self, r, accent)` then `draw_string` for name (top, `WyrdUi.INK`) and `draw_multiline_string` for desc (bottom two lines, `WyrdUi.INK_MID`). No icon well needed (shrine buffs have no painted icons). Signal `pressed`.
   Sketch:
   ```gdscript
   class _BuffCard extends Control:
       var _name := ""; var _desc := ""; var _hover := false
       signal pressed
       func _init() -> void:
           custom_minimum_size = Vector2(180, 200)
           mouse_filter = Control.MOUSE_FILTER_STOP
       func setup(buff_name: String, buff_desc: String) -> void:
           _name = buff_name; _desc = buff_desc; queue_redraw()
       func _gui_input(event: InputEvent) -> void:
           if event is InputEventMouseButton and event.pressed \
                   and event.button_index == MOUSE_BUTTON_LEFT:
               pressed.emit(); accept_event()
       func _notification(what: int) -> void:
           if what == NOTIFICATION_MOUSE_ENTER: _hover = true; queue_redraw()
           elif what == NOTIFICATION_MOUSE_EXIT: _hover = false; queue_redraw()
       func _draw() -> void:
           var r := Rect2(Vector2.ZERO, size)
           var accent: Color = WyrdUi.GOLD if _hover else WyrdUi.INK_MID
           WyrdUi.draw_list_row(self, r, accent)
           var font := get_theme_default_font()
           draw_string(font, Vector2(12.0, 28.0), _name, HORIZONTAL_ALIGNMENT_LEFT,
               size.x - 24.0, 18, WyrdUi.INK)
           draw_multiline_string(font, Vector2(12.0, 56.0), _desc,
               HORIZONTAL_ALIGNMENT_LEFT, size.x - 24.0, 13, 4, WyrdUi.INK_MID)
   ```
   _Verify:_ Same `WYRD_UI_SHOT=shrine` capture shows drawn cards instead of raw `Button`s. _Effort:_ S.

3. **Wire `_BuffCard` into `setup()`, replacing raw `Button` nodes** — `shrine_choice_modal.gd:setup` (lines 61–77). Replace the `Button.new()` block with `_BuffCard.new()`; call `card.setup(String(b.name), String(b.desc))`; connect `card.pressed` to `_on_pressed.bind(b)`. Remove `btn.text`, `btn.autowrap_mode`. The `_hbox` sizing (`separation 20`, `alignment CENTER`) is unchanged.
   _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_typed_rooms.gd` — T4 still passes (modal is not reached headless, but shrine seeding / apply paths must stay green). `WYRD_UI_SHOT=shrine` screenshot reviewed. _Effort:_ S.

---

### Phase 2 — Shrine buff pool expansion

4. **Add 4 off-stat entries to `Shrine.BUFF_POOL`** — `shrine.gd:13–26`. Append after `"haste"` entry (line 24):
   ```gdscript
   {"id": "channeling", "stat": "focus_regen_bonus", "value": 0.08,
       "name": "Channeling of the Root", "desc": "+8 Focus/s regen"},
   {"id": "resilience", "stat": "iframes_bonus",    "value": 0.12,
       "name": "Resilience of Bark",    "desc": "+0.12s i-frames after dodge"},
   {"id": "wanderer",   "stat": "gather_speed",     "value": 0.25,
       "name": "Wanderer's Bounty",     "desc": "+25% gather channel speed"},
   {"id": "clarity",    "stat": "skill_cd_mult",    "value": 0.15,
       "name": "Clarity of the Glade",  "desc": "–15% skill cooldowns"},
   ```
   Note: `gather_speed` already has a consumer in `gather_node.gd:312` via `game.buff_value("gather_speed")`. The shrine path writes to `player.shrine_buffs`, which flows through `_derive_stats`. A new `_add_stat(sums, "gather_speed", ...)` pass in `_derive_stats` will make it readable by `gather_node` via a player getter (see task 5). `skill_cd_mult` maps to `cooldown_reduction` (same effect; see task 5). `focus_regen_bonus` and `iframes_bonus` need new wiring (tasks 5–6).
   _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_typed_rooms.gd` — T4 distinct/deterministic check still passes with pool size 10. _Effort:_ S.

5. **Extend `shrine_buffs` dict and `_derive_stats` sums in `player_controller.gd`** — lines 151–153 (dict init) and 1082–1085 (sums init). Add four keys:
   ```gdscript
   # line 151 — shrine_buffs dict:
   var shrine_buffs: Dictionary = {"hp": 0, "damage": 0, "crit_chance": 0.0,
       "crit_mult": 0.0, "fire_rate": 0.0, "move_speed": 0.0,
       "cooldown_reduction": 0.0, "focus_regen_bonus": 0.0,
       "iframes_bonus": 0.0, "gather_speed": 0.0, "skill_cd_mult": 0.0}
   # line 1082 — _derive_stats sums dict:
   var sums := {"hp": 0, "damage": 0, "crit_chance": 0.0,
       "crit_mult": 0.0, "fire_rate": 0.0, "move_speed": 0.0,
       "cooldown_reduction": 0.0, "focus_regen_bonus": 0.0,
       "iframes_bonus": 0.0, "gather_speed": 0.0, "skill_cd_mult": 0.0}
   ```
   In `derived_stats` construction (line 1117), add:
   ```gdscript
   "focus_regen_bonus": float(sums.focus_regen_bonus),
   "iframes_bonus":     float(sums.iframes_bonus),
   "gather_speed":      float(sums.gather_speed),
   "cooldown_reduction": clampf(float(sums.cooldown_reduction)
       + float(sums.skill_cd_mult), 0.0, CDR_CAP),
   ```
   (`skill_cd_mult` folds into `cooldown_reduction` at the last step so the CDR cap is honored once; no separate consumer needed.) Also add a read helper for gather_node compatibility: `func shrine_gather_speed() -> float: return float(derived_stats.get("gather_speed", 0.0))`.
   _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_typed_rooms.gd` — T4 `apply` assertion uses the `_:` branch which checks `p.shrine_buffs.get(picked.stat, 0) != 0`; all four new stats will hit that branch. _Effort:_ S.

6. **Wire `focus_regen_bonus` and `iframes_bonus` into live gameplay** — `player_controller.gd`.
   - Focus regen (line 465–467): change regen calculation to:
     ```gdscript
     var shrine_fregen: float = float(derived_stats.get("focus_regen_bonus", 0.0))
     focus = clampf(focus + (regen_rate + shrine_fregen) * _chart_focus_mult()
         * _buff_focus_mult() * delta, 0.0, focus_max)
     ```
   - Iframes bonus (line 756 / 760 — the two `_iframe_t = IFRAMES_SEC` assignments that fire on normal hit / ward expiry): replace both with:
     ```gdscript
     _iframe_t = IFRAMES_SEC + float(derived_stats.get("iframes_bonus", 0.0))
     ```
     (Roll iframes at line 641 intentionally left unchanged — roll invuln is mechanical, not a shrine power.)
   _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd` stays green. Manual playtest: apply "Channeling of the Root" at a shrine and observe faster focus fill on the HUD. _Effort:_ S.

---

### Phase 3 — Hearth `load()` → `preload` hygiene

7. **Replace `load()` with `preload` in `hearth.gd`** — line 59. Add at file top (after line 10):
   ```gdscript
   const LoadoutPanelScript := preload("res://scripts/ui/loadout_panel.gd")
   ```
   Change line 59 from:
   ```gdscript
   var lp: CanvasLayer = load("res://scripts/ui/loadout_panel.gd").new()
   ```
   to:
   ```gdscript
   var lp: CanvasLayer = LoadoutPanelScript.new()
   ```
   _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_typed_rooms.gd` — T5 (hearth heal + checkpoint) stays green. _Effort:_ XS.

---

### Phase 4 — Waystone test coverage

8. **Add `_t7_exit_waystone_interact()` to `test_typed_rooms.gd`** — append after `_t6_interactable_base_contract()` (line 258). Install a stub `Game` node with a `return_to_town(player, abandoning)` method that records calls. Instantiate `ExitWaystone` from `preload("res://scenes/ExitWaystone.tscn")` (or construct directly). Call `interact(mock_player)`, assert `_used == true` and stub received `(mock_player, false)`. Then test `abandoning = true` variant: new stone with `.abandoning = true`, call `interact(mock_player2)`, assert stub received `(mock_player2, true)`.
   Sketch:
   ```gdscript
   func _t7_exit_waystone_interact() -> void:
       # stub Game
       var stub := Node.new(); stub.name = "Game"
       var calls: Array = []
       stub.set_script(null)   # plain Node — add method via lambda workaround:
       # GDScript can't lambda-add methods; use a lightweight inner class instead.
       ...
       _check("T7a", ew._used, "ExitWaystone._used after interact")
       _check("T7b", ew_abandon._used, "abandon stone _used after interact")
   ```
   Note: GDScript does not support runtime method injection; the stub must be a small preloaded or inline script class. Use `class _GameStub extends Node` at the top of the test file. Add `ExitWaystoneScene := preload("res://scenes/ExitWaystone.tscn")` to the preloads.
   _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_typed_rooms.gd` — T7 passes. _Effort:_ S.

9. **Add `_t8_portal_waystone_no_crash()` to `test_typed_rooms.gd`** — append after T7. Add `PortalWaystoneScene := preload("res://scenes/PortalWaystone.tscn")` to preloads (verify scene exists at `wyrd/scenes/PortalWaystone.tscn` first — if absent, make it task 8a to create the `.tscn` wrapping `portal_waystone.gd`). Instantiate, add to host, await a physics frame. Call `interact(null)` and assert no crash (the current `interact` at `portal_waystone.gd:34` calls `get_tree().current_scene.add_child(panel)` which will fail on null scene — add a null guard: `if get_tree().current_scene == null: return`).
   ```gdscript
   func _t8_portal_waystone_no_crash() -> void:
       var host := Node3D.new(); root.add_child(host); await physics_frame
       var pw: Node3D = PortalWaystoneScene.instantiate()
       host.add_child(pw); await physics_frame
       pw.interact(null)   # must not crash
       _check("T8", true, "PortalWaystone.interact(null) did not crash")
   ```
   _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_typed_rooms.gd` — T8 passes. _Effort:_ S.

10. **Extend `_t4_shrine_buff` with a 5-seed sweep for off-stat coverage** — `test_typed_rooms.gd` inside `_t4_shrine_buff` (after line 195). After the existing assertion, add:
    ```gdscript
    # Extended: 5-seed sweep confirms off-stat buffs can appear.
    var off_stat_seen := false
    const OFF_STATS := ["focus_regen_bonus", "iframes_bonus", "gather_speed", "skill_cd_mult"]
    for sweep_seed in [42, 77, 303, 512, 999]:
        var sw: Node3D = ShrineScene.instantiate(); host.add_child(sw)
        sw.seed_value = sweep_seed; await physics_frame
        for b in sw.offered_buffs():
            if String(b.stat) in OFF_STATS: off_stat_seen = true
    _check("T4b", off_stat_seen, "at least one off-stat buff in 5-seed sweep")
    ```
    _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_typed_rooms.gd` — T4 and T4b both pass. _Effort:_ XS.

---

### Parking lot (not in this plan)

- **Hearth GLB swap** (`dungeon_crypt_hearth_v1.glb`) — asset-gated on a Meshy commission. When the model lands, `hearth.gd:10` changes `BRAZIER_GLB` path. One-line code change; track as a follow-up asset commit.
- **Chest lid-open animation** — requires Blender confirmation that `dungeon_crypt_chest_v1.glb` has a separable lid node. Pairs with Plan.md Part B / Phase B4 (pickup suck). See [[impl-system-combat-juice-vfx]].

## First commit (smallest shippable slice)

**Tasks 7 + 1** — `hearth.gd` preload hygiene (30-second change, zero risk) plus applying `WyrdUi.style_panel` to the shrine modal backing Panel. Together they make one focused commit titled "interactables: preload hygiene + shrine modal kit conformance start". Acceptance: `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_typed_rooms.gd` stays green; `WYRD_UI_SHOT=shrine` shows the carved-wood panel frame.

Tasks 2–3 (full `_BuffCard` restyle) are the next natural commit. Tasks 4–6 (buff pool expansion + stat wiring) form a third commit. Tasks 8–10 (waystone tests) form the final commit.

## Test & verification plan

Run all commands from `wyrd/` with `WYRD_NO_SAVE=1`:

```bash
# Full headless suite (must stay green at every task boundary)
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_transitions.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_typed_rooms.gd
```

New tests authored in this plan:
- `T4b` — 5-seed off-stat sweep (task 10, appended to `test_typed_rooms.gd:_t4_shrine_buff`)
- `T7` — `ExitWaystone.interact()` dispatch + `_used` + `abandoning` path (task 8, new in `test_typed_rooms.gd`)
- `T8` — `PortalWaystone.interact(null)` no-crash + null guard (task 9, new in `test_typed_rooms.gd`)

Screenshot verifications (require running game or `capture_ui.sh`):
```bash
# After tasks 1–3: shrine modal uses kit frame + drawn cards
WYRD_UI_SHOT=shrine godot --path .
```
Manual playtest milestone after task 6: apply "Channeling of the Root" buff at a shrine → observe HUD focus bar filling faster between skills.

## Risks & open questions

1. **`_BuffCard` vertical layout in the `HBoxContainer`** — `loadout_panel`'s `_SkillCard` is a horizontal row (62px tall); `_BuffCard` is vertical (180×200). The `HBoxContainer` with 20px separation will stretch each card to fill the panel's height by default. Set `size_flags_vertical = Control.SIZE_SHRINK_CENTER` on each card, or switch the outer container to a `VBoxContainer` with three cards stacked. The parent note describes cards side-by-side (three columns) — confirm this is still the desired layout before finalizing task 3.

2. **`shrine_buffs.gather_speed` vs. `game.buff_value("gather_speed")`** — `gather_node.gd:312` reads gather speed from `game.buff_value`, not from the player. A shrine buff that writes to `player.shrine_buffs.gather_speed` will not be seen by `GatherNode` without either: (a) exposing a `shrine_gather_speed()` getter on the player and reading it in `gather_node`, or (b) routing shrine gather-speed through `game.buff_value`. Option (a) is cleaner (no `Game` coupling). Confirm before task 5.

3. **`PortalWaystone.tscn` existence** — the `.tscn` is referenced in task 9 but the vault search did not confirm it exists. If `wyrd/scenes/PortalWaystone.tscn` is absent, task 9 must be preceded by a subtask creating it (a `PackedScene` with root `PortalWaystone` node, analogous to `Shrine.tscn`). Check `wyrd/scenes/` before starting task 9.

4. **Off-stat buff balance** — `iframes_bonus = 0.12 s` stacks additively with `IFRAMES_SEC = 0.6 s` (total 0.72 s). At aggressive shrine stacking this could feel unfair. The value is a design call; the code accepts any float. Confirm the four candidate values before shipping task 4.

## Build status — 2026-06-16

**Completed (in-scope files only):**

- **Task 7 (hearth preload hygiene)** — `hearth.gd`: added `const LoadoutPanelScript := preload(...)` at the top; replaced the runtime `load()` call in `interact()` with `LoadoutPanelScript.new()`. T5 headless path is unaffected.
- **Task 4 (shrine buff pool expansion)** — `shrine.gd:BUFF_POOL` extended from 6 to 10 entries. Added four off-stat entries: `channeling` (`focus_regen_bonus` +0.08), `resilience` (`iframes_bonus` +0.12), `wanderer` (`gather_speed` +0.25), `clarity` (`skill_cd_mult` +0.15). Pool size 10 preserves the 3-of-N seeded offer logic; T4 `_:` branch covers all four new stats.
- **Tasks 1–3 (ShrineChoiceModal kit restyling)** — `shrine_choice_modal.gd` fully restyled:
  - `WyrdUi.style_panel(_panel)` on the backing Panel; panel widened to 700 × 340.
  - `WyrdUi.style_title(title)` on the header label (terracotta IM Fell SC, size 30).
  - `_FlourishBar` inner class adds the ◆ flourish drawn under the title (no texture).
  - `_BuffCard` inner class: drawn Control using `draw_list_row` (GOLD accent on hover, INK_MID idle), divider line, `draw_string` name (size 16 INK), `draw_multiline_string` desc (size 13 INK_MID, 5 lines max). No icon well (shrine buffs carry no icons). `size_flags_vertical = SIZE_SHRINK_CENTER` keeps cards compact in the HBoxContainer.
  - `setup()` now builds `_BuffCard` instances instead of raw `Button` nodes; public contract (`signal chosen(buff)`, `setup(buffs)`) preserved.
- **`exit_waystone.gd` review** — no edits needed; the abandoning-exit variant (`abandoning` flag, conditional prompt, `return_to_town(player, abandoning)` dispatch) was already fully implemented. Gap confirmed closed.

**Deferred (out-of-scope files):**
- **Tasks 5–6** (`player_controller.gd`): extend `shrine_buffs` dict + `_derive_stats` sums to wire `focus_regen_bonus`, `iframes_bonus`, `gather_speed`, `skill_cd_mult`; live focus-regen and iframe-bonus gameplay integration. These four new buff entries in BUFF_POOL will write to `player.shrine_buffs` via the existing `apply_shrine_buff` method; the `_:` branch in T4 confirms the dict write, but the derived-stat consumers are not yet wired.
- **Tasks 8–10** (`test_typed_rooms.gd`): T7 `_t7_exit_waystone_interact`, T8 `_t8_portal_waystone_no_crash`, T4b 5-seed off-stat sweep. File is not in edit scope.
- **`portal_waystone.gd` null guard**: `interact(null)` crash guard needed for T8. File not in scope.
