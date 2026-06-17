---
title: Crafting & Stations — Implementation Plan
parent: "[[system-crafting]]"
domain: Gather · Craft · Economy
type: implementation-plan
status: ready-to-build
effort: M
tags: [wayfinder, impl]
---

# Crafting & Stations — Implementation Plan

> Build doc for [[system-crafting]]. Done when active buff timers are visible in the HUD, the still plays a distinct SFX, every station fires a `react()` call on a successful craft, and the bench's ink-discovery gating is confirmed complete (it already is — this task closes the audit).

## Build status — 2026-06-16
**Station `react()` SHIPPED & gate-green (Plan.md B5).** `game.craft()` now emits `crafted(station_id)` on success; each `CraftStation` connects and fires `react()` — a pause-immune glow pulse (light promoted to the `_react_light` instance var) + a 6-mote flavour-coloured burst (cookfire embers / forge sparks / still green vapor). Verified by a new `crafted(cookfire)`-fires assertion in `test_wyrd_loop` (now 241). So a craft READS in the world, not just as a toast.
**Remaining:** distinct `craft_still` SFX (gated on audio gen — see [[impl-system-audio-music]]); active buff-timer chips in the HUD (overlaps [[impl-system-hud]] Phase 4).

## Definition of done

- **Buff HUD:** brewing any still tonic causes a buff pill to appear immediately above the skill bar, drain over the tonic's duration, and disappear on expiry. No pill shown when `game.buffs` is empty.
- **Still SFX:** the still plays `craft_still` (a non-clang brew sound). Cookfire and forge SFX unchanged.
- **Station react():** each station has a distinct visible in-world reaction (light pulse + rising motes) on every successful `game.craft()` call; `react()` is never called on a gated or unaffordable attempt.
- **Bench ink gate (audit closed):** `crafting_bench.gd:socket_ink` allows any discovered ink (no `ink_discovered` check at socket time) — this is by design (the tray already filters to owned-count inks at `crafting_bench.gd:584–589`). No code change needed; task closes the audit.
- All four headless suites stay green (`WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_loop.gd` etc.).

## Preconditions / dependencies

- [[impl-system-hud]] — `player_hud.gd` exists and `GlobeGauge`/`_build_wyrd_overlay` patterns are understood. The buff pill row slots in above the skill bar at offset_top ≈ −172 (8 px above the `_toast_box` at −170).
- [[impl-system-audio-music]] — `sfx.gd:PATHS` pattern is the insertion point for `craft_still`.
- **Plan.md B0** (`data/feel.gd`) is a named prerequisite in [[system-crafting]] Phase 3. `data/feel.gd` does **not** currently exist. Phase 3 (react) will inline tuning values with `# TODO: move to Feel.*` comments until B0 ships. This is an acceptable workaround — Plan.md B0 is not a hard blocker for this impl, just a clean-up dependency.
- **Plan.md B2** (harvest pop mote pattern) shares the same `MeshInstance3D` + Tween approach used in Phase 3. B2 and this Phase 3 can be developed independently; no sequencing constraint.
- `game.gd:craft()` currently tracks no reference to the active station node. Phase 3 requires a mechanism for `game.craft()` to call `react()` on the correct node — see Task 7.

## Tasks (ordered)

### Phase 1 — Still buff HUD

1. **Add `BuffPillRow` inner class to `player_hud.gd`** — `player_hud.gd` (new inner class `BuffPillRow extends Control`). Implement `_draw()` to iterate `game.buffs` and paint one pill per entry: material name string glyph (`GatherDefs.material_name(id)`), a filled rect for the drain bar (`left / duration`), sage/green color. Add `_process(delta)` that accumulates `_t` and calls `queue_redraw()` only every 0.25 s. Preload nothing in `_draw()` — string glyphs only. _Verify:_ run `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_loop.gd`; no parse error. _Effort:_ S.

2. **Instantiate `BuffPillRow` in `_build_wyrd_overlay()`** — `player_hud.gd:_build_wyrd_overlay()`. After the `_toast_box` add (line ~209), create `var pill_row := BuffPillRow.new()` anchored to bottom-center, `offset_top = -172`, sized `±300 × 22`. Add to `self`. Connect `game.buffs_changed` to `pill_row.queue_redraw`. Store as `var _buff_pill_row: Control = null` on the outer script. _Verify:_ `WYRD_SHOT=1 godot --path wyrd` → brew quickroot at Quill's still → screenshot shows buff pill above skill bar. _Effort:_ S.

3. **Wire buff expiry redraw** — `player_hud.gd`. The `buffs_changed` signal fires on expiry (`game.gd:522`). No additional wiring needed beyond Task 2 (the signal connection covers both appearance and removal). Add a guard: if `game.buffs.is_empty()`, `BuffPillRow._draw()` skips all drawing and hides the row (`visible = false`). _Verify:_ wait out a 90 s tonic (or set `duration = 2.0` in a local test run) — pill disappears cleanly. _Effort:_ XS.

### Phase 2 — Dedicated still SFX

4. **Register `craft_still` in `sfx.gd:PATHS`** — `sfx.gd:PATHS` (after `"craft_smith"` entry, line 32). Add `"craft_still": "res://audio/craft_still.mp3"`. The file is deferred (ElevenLabs spend not yet approved); `sfx.play()` is a graceful no-op when the file is absent (`sfx.gd:87`). _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_loop.gd` stays green (no parse error from the new key). _Effort:_ XS.

5. **Generate `craft_still.mp3` via ElevenLabs pipeline** — `wyrd/audio/craft_still.mp3` (new file). Run `tools/generate_audio.py` with a bubbling-distillery prompt (glass / drip / fizz / warmth — cozy not industrial). Save output to `wyrd/audio/craft_still.mp3`. _Verify:_ launch game, brew at Quill's still, confirm a distinct (non-clang) brew sound plays. Cookfire (`craft_cook`) and forge (`craft_smith`) unchanged. _Effort:_ S.

6. **Fix `game.gd:409` to three-way SFX match** — `game.gd:409`. Replace `sfx.play("craft_cook" if station_id == "cookfire" else "craft_smith")` with a match block:
   ```gdscript
   match station_id:
       "cookfire": sfx.play("craft_cook")
       "forge":    sfx.play("craft_smith")
       "still":    sfx.play("craft_still")
   ```
   _Verify:_ `test_wyrd_loop.gd` passes; manual brew at each station confirms correct sound. _Effort:_ XS.

### Phase 3 — Station `react()` hook (Plan.md B5)

7. **Register station nodes in `town.gd`** — `town.gd:_place_stations()`. After each `add_child(hearth/anvil/still)` call (lines 242, 247, 256), also call `game.register_craft_station(hearth/anvil/still)` to let `game.gd` look up the node by `station_id`. Add `func register_craft_station(node: Node3D) -> void` to `game.gd` (stores in `var _craft_stations: Dictionary = {}` keyed by `node.station_id`). _Verify:_ headless parse clean. _Effort:_ S.

8. **Add `react()` to `CraftStation`** — `craft_station.gd` (new public method after `interact()`, line ~46). Dispatch per `station_id` to three private helpers. Use inline tuning constants (no `feel.gd` yet — annotate each with `# TODO: move to Feel.*`):
   - `_react_cookfire()`: tween `ember` OmniLight `light_energy` 1.6 → 3.2 → 1.6 over 0.4 s; spawn ≤6 `MeshInstance3D` `SphereMesh` motes (r=0.04, amber `StandardMaterial3D.unshaded=true`) at pot position, tween `position.y += 0.5` + `modulate.a → 0` over 0.5 s, then `queue_free()`.
   - `_react_forge()`: tween `glow` OmniLight energy 1.1 → 2.4 → 1.1 over 0.3 s; spawn ≤6 orange motes off the anvil body center; tween anvil `_prim` scale 1.0 → 1.08 → 1.0 over 0.25 s. Skip the light flash if `game.reduce_shake` is true.
   - `_react_still()`: tween `glow` OmniLight color to `Color(0.6, 1.0, 0.7)` then back over 0.5 s; spawn ≤4 green-tinted motes at catch-flask position.
   Each helper stores the OmniLight reference in `_build_*` and names it `_ember`, `_forge_glow`, `_still_glow` (update the `_build_*` methods to assign these instance vars). _Verify:_ headless parse clean; see Task 9 for logic assertion. _Effort:_ M.

9. **Call `react()` from `game.craft()` success path** — `game.gd:craft()`. After `award_xp(...)` (line 410) and before `return true`, add:
   ```gdscript
   if _craft_stations.has(station_id):
       (_craft_stations[station_id] as Node).react()
   ```
   `react()` must only be reached after all guard returns (gated → `return false`, unaffordable → `return false`, pack-full → `return false`). The placement after `award_xp` guarantees this. _Verify:_ add a test assertion to `test_wyrd_loop.gd`: craft `quickroot_tonic` with valid materials → observe `game._craft_stations["still"]` has `react` method (use `has_method`). Gated call returns false before that line. All four suites green. _Effort:_ S.

### Phase 4 — Bench ink-discovery gate audit (closes the gap)

10. **Confirm `socket_ink()` gate is correct by design** — `crafting_bench.gd:socket_ink()` (line 91–104). The current code checks only `_remaining(ink_id) > 0` (count the player owns minus bench claims). The tray (`_draw_tray`, line 584–589) already filters ink rows to `n > 0` (owned count), so a player can only drag inks they possess. No `ink_discovered` guard is needed at `socket_ink` time because ink possession implies either (a) the bench pot gifted it serendipitously, or (b) the player mixed it — either way it is a fair socket. Annotate `crafting_bench.gd:91` with `# ink possession = valid gate (tray filters to n>0; ink_discovered not required here)`. No logic change. _Verify:_ `test_wyrd_loop.gd` already passes the bench path; re-run to confirm. _Effort:_ XS.

### Phase 5 — Recipe depth expansion (deferred, data-only)

11. **Audit and fill the ~14 missing deep-tier recipes** — `wyrd/data/crafting.gd:RECIPES`. Compare against `spec 45-earth` and `spec 45-wilds` comments in the file. Add each missing recipe following the existing pattern (`req_lv`, `xp`, `inputs`, `yields_material`/`yields_item`). Update `BUFF_DRAUGHT_ORDER` if new still tonics are added. After additions, run `test_wyrd_loop.gd` and the economy sell-back gate. This is data authoring — defer until after the `B0` feel pass unless new ore tiers (palechalk, starsilver) are already gatherable. _Verify:_ `crafting.gd:RECIPES` has ≥43 entries; all four suites green; forge sell-back economy test passes (new gear recipes must not crack the gate at `crafting.gd:163`). _Effort:_ S–M.

## First commit (smallest shippable slice)

**Tasks 4 + 6 together**: register `craft_still` in `sfx.gd:PATHS` and fix the three-way SFX match in `game.gd:409`. This is two lines of code, zero risk of regression (`sfx.play()` is a no-op when the file is absent), and closes the "clang at the still" paper cut immediately. All four headless suites stay green.

Acceptance: `test_wyrd_loop.gd` green; manual brew at the still no longer plays a forge clang (even before the MP3 is generated, the branch is correct).

## Test & verification plan

| Task | Verification |
|------|-------------|
| 1–3 (buff HUD) | `WYRD_SHOT=1 godot --path wyrd` → brew quickroot → screenshot shows pill with drain bar. Wait expiry → pill gone. No headless suite change needed (cosmetic-only). |
| 4–6 (still SFX) | `test_wyrd_loop.gd` passes after each change. Manual: brew at each of three stations, confirm distinct SFX per station. |
| 7–9 (react) | Add one assertion to `test_wyrd_loop.gd`: `game.craft("still", "quickroot_tonic")` with valid materials → `game._craft_stations["still"].has_method("react")` is true AND `react()` not called on gated attempt (check via mock counter or stub). All four suites green after. Manual: visible in-world reaction at each station on successful craft. |
| 10 (bench audit) | Re-run `test_wyrd_loop.gd` — no changes to pass/fail. Code comment added only. |
| 11 (recipe fill) | All four suites green. Economy sell-back test passes. Visual: open forge panel, confirm new recipes appear at correct level gates. |

New headless assertion to author (Task 9):
```gdscript
# in test_wyrd_loop.gd, after the existing still tests (~line 419)
func _test_station_react() -> void:
    var game := _make_game()
    # give materials and trade level
    game.set_trade_lv("wilds", 3)
    game.add_material("wild_herb", 3)
    game.add_material("bittergrass", 2)
    var station_called := false
    # register a stub station
    var stub := Node.new(); stub.set_script(null)
    stub.set_meta("station_id", "still")
    # use has_method guard — react() must exist after Task 8
    var ok := game.craft("still", "quickroot_tonic")
    _check("still craft succeeds", ok)
    _check("station node registered", game._craft_stations.has("still"))
    # gated path must NOT call react
    game.set_trade_lv("wilds", 1)
    var gated := game.craft("still", "quickroot_tonic")
    _check("gated craft returns false", not gated)
```

## Risks & open questions

- **Buff persistence across scene transitions** — `game.gd` `buffs` is runtime-only (`crafting.gd:277` comment). A player who brews a 90 s tonic before entering a dungeon currently loses the buff on Town → Dungeon scene change. Decide: (a) save/restore `buffs` dict in `save_now()` / `load_save()` to persist within a session, or (b) accept loss (intentional design). This is an open question from [[system-crafting]].
- **`feel.gd` dependency for Task 8** — inline tuning constants are an acceptable bridge until Plan.md B0 ships. However, if B0 ships before Task 8 starts, the mote constants should go directly into `data/feel.gd` rather than inlined, avoiding a redundant cleanup commit.
- **`_emit` OmniLight references in `_build_*`** — `craft_station.gd:_build_cookfire()` uses a local `var ember` (line 62); `_build_anvil()` uses `var glow` (line 77); `_build_still()` uses `var glow` (line 101). Task 8 requires these to become instance variables (`var _ember: OmniLight3D`, `var _forge_glow: OmniLight3D`, `var _still_glow: OmniLight3D`) so `react()` can reference them. This is a safe rename; Godot will not complain about unused locals being promoted to instance vars.
- **Co-op safety** — `react()` animations are cosmetic and LOCAL per Plan.md B-1 rule. No RPC needed.
- **Recipe count target** (Phase 5) — confirm with user whether the 14-recipe gap (29 vs ~43) is a fill-now or defer-until-next-biome question before starting Task 11. The economy gate test must pass either way.
