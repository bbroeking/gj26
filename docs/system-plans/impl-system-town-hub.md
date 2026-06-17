---
title: Town Hub (Chartmakers Yard) — Implementation Plan
parent: "[[system-town-hub]]"
domain: World & Interactables
type: implementation-plan
status: ready-to-build
effort: M
tags: [wayfinder, impl]
---

# Town Hub (Chartmakers Yard) — Implementation Plan

> Build doc for [[system-town-hub]]. Done when the Living Atlas board reacts to den unlocks, regrowth pops with SFX, co-op peers spawn in a fan arc, and a return-from-delve arrival beat wires into `town.gd`.

## Definition of done

- `game.gd:return_to_town` sets `_returning_from_delve = true` before the scene change; `town.gd:_ready` reads it, delays music 0.3 s, fires `sfx.play("town_arrival_swell")`, and nudges `_zoom_target` on the camera rig.
- A Living Atlas board (`MeshInstance3D` parchment quad) sits on the Tower south wall; it reads `game.summit_cleared` and Wayfinding level on `_ready` and pulsed its emissive on `game.leveled_up` and `game.summit_cleared`.
- `gather_node.gd` emits a `regrew` signal; `town.gd` connects all town patches and plays `sfx.play("regrow_pop")` + a 6-mote leaf burst.
- `sfx.gd` has stub keys for `town_arrival_swell`, `town_ambient_birds`, `town_fire_crackle`, `regrow_pop` (silent no-ops until audio assets drop).
- `town.gd` exports `var net_spawn: Vector3`; `net_game.gd:_spawn_player` fans peers in a cos/sin arc instead of a straight +X line.
- All four headless suites stay green (`WYRD_NO_SAVE=1` from `wyrd/`).

## Preconditions / dependencies

- [[impl-system-audio-music]] — `sfx.gd` is the single registration point; the stub keys added here (task 1) are the same stubs Plan.md B0 registers for the full ambient pass. If [[impl-system-audio-music]] lands first and already includes these keys, skip task 1.
- [[impl-system-multiplayer-netcode]] — `net_game.gd:_spawn_player` (line 202) is the only callsite for the fan spawn; the fix here must not break `test_wyrd_transitions.gd`.
- [[impl-system-charts-wayfinding]] — the Living Atlas board reads `game.leveled_up` (game.gd:28) and `game.summit_cleared` (game.gd:108); both already exist. No new game.gd API needed.
- [[impl-system-gathering]] — `gather_node.gd:_regrow` (line 362) is the injection point for the `regrew` signal; the tween already exists, no new dep.
- **Plan.md B0** (`data/feel.gd`) — _not_ a hard blocker here; ambient constants live inline in `town.gd` until B0 lands. When B0 ships, replace the inline floats with `Feel.*` references in a follow-up cleanup.
- **Plan.md B7** — this note implements the `town.gd`/`gather_node.gd` wiring side of B7. The feel bench capture and the full ambient-life timer pass (light sway, drifting motes) are Plan.md B7's scope; they are NOT in this impl — link only.
- `data/feel.gd` does **not** exist yet (confirmed — `wyrd/data/` has no feel.gd). It is _not_ required for this slice; inline constants are fine.

## Tasks (ordered)

### Phase 1 — SFX stubs + arrival wiring + net spawn fan

1. **Register ambient SFX stub keys** — `sfx.gd:PATHS` (line 8). Add four keys with `res://audio/` paths that are silent no-ops until audio is generated:
   ```gdscript
   "town_arrival_swell": "res://audio/town_arrival_swell.mp3",
   "town_ambient_birds": "res://audio/town_ambient_birds.mp3",
   "town_fire_crackle":  "res://audio/town_fire_crackle.mp3",
   "regrow_pop":         "res://audio/regrow_pop.mp3",
   ```
   No new functions needed; `play()` is already a graceful no-op for missing files.
   _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` stays green (sfx graceful no-op path). _Effort:_ S.

2. **Add `_returning_from_delve` flag to `game.gd`** — `game.gd:return_to_town` (line 709). Add `var _returning_from_delve := false` near the modal state block (~line 58). In `return_to_town`, set the flag immediately before `change_scene_to_file.call_deferred`:
   ```gdscript
   _returning_from_delve = true
   get_tree().change_scene_to_file.call_deferred(TOWN_SCENE)
   ```
   _Verify:_ `test_wyrd_transitions.gd` stays green; `print("[game] _returning_from_delve=true")` visible in run log after a dungeon exit. _Effort:_ S.

3. **Wire arrival beat in `town.gd:_ready`** — `town.gd:_ready` (line 61). Read and clear the flag; if set, delay music and nudge the camera:
   ```gdscript
   var game: Node = get_node_or_null("/root/Game")
   if game != null and bool(game.get("_returning_from_delve")):
       game._returning_from_delve = false
       get_tree().create_timer(0.3).timeout.connect(func() -> void:
           var sfx2 := get_node_or_null("/root/Sfx")
           if sfx2 != null:
               sfx2.play("town_arrival_swell")
               sfx2.music("town_theme"))
       # ease camera in from a slightly further zoom
       var rig: Node = get_tree().get_first_node_in_group("camera_rig")
       if rig != null:
           rig.set("_zoom_target", rig.get("ZOOM_DEFAULT") + 4.0)
   else:
       # cold boot — music immediately (existing behaviour, line 62-64)
       var sfx3 := get_node_or_null("/root/Sfx")
       if sfx3 != null and sfx3.has_method("music"):
           sfx3.music("town_theme")
   ```
   Remove the unconditional `sfx.music("town_theme")` call at line 62–64 so it only fires on cold boot or is deferred on return. The camera's normal `ZOOM_LERP` eases it back within ~1 s.
   _Verify:_ `WYRD_SHOT=1 godot --path wyrd` cold-boot plays music immediately (check `[Sfx]` log); `test_wyrd_transitions.gd` green; manual playtest: return from dungeon delays music 0.3 s. _Effort:_ S.

4. **Export `var net_spawn: Vector3` on `town.gd`** — `town.gd` (after the `PLAYER_SPAWN` const, ~line 30). Add:
   ```gdscript
   var net_spawn: Vector3 = PLAYER_SPAWN + Vector3(0.0, 0.0, 1.2)
   ```
   This lets `net_game.gd:_spawn_pos` (line 212) pick up `net_spawn` instead of falling through to the hardcoded fallback. No change needed in `net_game.gd`.
   _Verify:_ `WYRD_NO_SAVE=1 WYRD_NET=host godot --path wyrd` log shows `[net] spawned` at a position offset from PLAYER_SPAWN. `test_wyrd_transitions.gd` green. _Effort:_ S.

5. **Fan co-op spawn arc in `net_game.gd:_spawn_player`** — `net_game.gd:_spawn_player` (line 202). Replace the straight +X offset with a cos/sin fan:
   ```gdscript
   var idx: int = players.keys().find(id)
   var angle: float = (float(idx) - float(players.size() - 1) * 0.5) * 0.7  # ~40° spread
   var offset := Vector3(cos(angle), 0.0, sin(angle)) * 1.5 * float(maxi(idx, 1))
   p.global_position = spawn + offset
   ```
   For a single player `idx=0`, `offset` is `Vector3(1.5, 0, 0)` — effectively unchanged from the old 1.2m. For two peers the arc fans ±20°.
   _Verify:_ `WYRD_NET_RUN=5 WYRD_NET=host godot --path wyrd` + a joining client: check `[net] spawned` prints show different positions with no Node name clash. `test_wyrd_transitions.gd` green. _Effort:_ S.

**Phase 1 VERIFY:** all four suites green: `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd`, `test_wyrd_dungeon_scene.gd`, `test_wyrd_transitions.gd`, `test_skills.gd`.

---

### Phase 2 — Regrowth pop signal + Living Atlas board

6. **Add `regrew` signal to `gather_node.gd`** — `gather_node.gd:_regrow` (line 362). Add one signal declaration at the top of the file near the other vars:
   ```gdscript
   signal regrew(pos: Vector3)
   ```
   Emit it at the top of `_regrow()` before the tween:
   ```gdscript
   func _regrow() -> void:
       if not is_instance_valid(self):
           return
       regrew.emit(global_position)   # ← add this line
       _depleted = false
       ...
   ```
   _Verify:_ `test_wyrd_dungeon_scene.gd` stays green (dungeon nodes with `respawns=false` don't use `_regrow`, so no false firings). _Effort:_ S.

7. **Connect `regrew` in `town.gd:_place_herb_patches` and ore/log loops** — `town.gd:_place_herb_patches` (line 286). After each `add_child(node)`, connect the signal:
   ```gdscript
   node.regrew.connect(_on_node_regrew)
   ```
   Apply the same one-liner after `add_child(rock)` and `add_child(pile)`. Add the handler at the bottom of `town.gd`:
   ```gdscript
   func _on_node_regrew(pos: Vector3) -> void:
       var sfx := get_node_or_null("/root/Sfx")
       if sfx != null:
           sfx.play("regrow_pop")
       _spawn_regrow_motes(pos)
   ```
   _Verify:_ playtest — deplete a herb patch, wait 20 s, observe `[town] regrow pop` logprint + mote burst. _Effort:_ S.

8. **Regrowth mote burst in `town.gd`** — `town.gd:_spawn_regrow_motes` (new func). Spawn ≤6 cheap leaf-motes that back-out upward and free themselves:
   ```gdscript
   func _spawn_regrow_motes(origin: Vector3) -> void:
       var rng2 := RandomNumberGenerator.new()
       rng2.seed = int(origin.x * 1000.0 + origin.z)
       for i in 6:
           var mi := MeshInstance3D.new()
           var sm := SphereMesh.new()
           sm.radius = 0.045; sm.height = 0.09
           mi.mesh = sm
           mi.position = origin + Vector3(rng2.randf_range(-0.3, 0.3),
               0.1, rng2.randf_range(-0.3, 0.3))
           add_child(mi)
           var t := create_tween()
           t.tween_property(mi, "position:y", origin.y + 0.8, 0.4) \
               .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
           t.parallel().tween_property(mi, "modulate:a", 0.0, 0.4).set_delay(0.15)
           t.chain().tween_callback(mi.queue_free)
   ```
   Never `load()` a texture in this function — pure procedural mesh, no texture reference.
   _Verify:_ `WYRD_SHOT=1 godot --path wyrd` screenshot at 25 s (after one herb respawn) captures mid-tween scale < 1 and mote visible. `test_wyrd_dungeon_scene.gd` green (motes never spawn in dungeon). _Effort:_ S.

9. **Living Atlas board — placement in `town.gd:_place_dressing`** — `town.gd:_place_dressing` (line 258). Add a parchment-quad `MeshInstance3D` on the Tower south wall; name it `"AtlasBoard"` so `_on_board_update` can find it:
   ```gdscript
   # Living Atlas — a parchment quad on the Tower's south wall; lit by
   # _on_board_update when a den tier or the Summit is unlocked.
   const ATLAS_POS := Vector3(20.5, 1.6, 8.0)
   var board := MeshInstance3D.new()
   var bm := QuadMesh.new()
   bm.size = Vector2(0.8, 0.6)
   board.mesh = bm
   board.name = "AtlasBoard"
   var bmat := StandardMaterial3D.new()
   bmat.albedo_color = Color(0.88, 0.82, 0.65)  # parchment
   bmat.roughness = 0.9
   bmat.emission_enabled = true
   bmat.emission = Color(0.0, 0.0, 0.0)
   bmat.emission_energy_multiplier = 0.0
   board.material_override = bmat
   board.position = ATLAS_POS
   board.rotation.x = -0.12   # tilt toward the yard slightly
   add_child(board)
   ```
   _Verify:_ `WYRD_SHOT=1 godot --path wyrd` screenshot shows parchment quad visible on tower. _Effort:_ S.

10. **Living Atlas board — react to unlocks in `town.gd:_ready`** — `town.gd:_ready` (after `_place_dressing()`, ~line 68). Connect signals and read initial state:
    ```gdscript
    var game2: Node = get_node_or_null("/root/Game")
    if game2 != null:
        # Reflect any unlocks that happened before this _ready (prior session).
        _on_board_update()
        game2.leveled_up.connect(func(_t: String, _lv: int) -> void:
            _on_board_update())
        # summit_cleared has no signal — poll at _ready only; a session that
        # clears the Summit will call return_to_town → _ready fires again.
    ```
    Add handler to `town.gd`:
    ```gdscript
    func _on_board_update() -> void:
        var board2: MeshInstance3D = get_node_or_null("AtlasBoard")
        var game3: Node = get_node_or_null("/root/Game")
        if board2 == null or game3 == null:
            return
        var lv: int = int(game3.call("trade_lv", "wayfinding"))
        var cleared: bool = bool(game3.get("summit_cleared"))
        # Energy scales with progression: 0 = untouched, up to 1.2 fully charted
        var base_e: float = clampf(float(lv - 1) / 10.0, 0.0, 1.0)
        if cleared:
            base_e = 1.2
        var mat: StandardMaterial3D = board2.material_override as StandardMaterial3D
        if mat == null:
            return
        mat.emission_energy_multiplier = base_e
        print("[town] board updated: lv=%d cleared=%s energy=%.2f" % [lv, cleared, base_e])
        if base_e > 0.0:
            # Pulse: overshoot then settle
            var t := create_tween()
            t.tween_method(func(v: float) -> void:
                if is_instance_valid(mat):
                    mat.emission_energy_multiplier = v,
                base_e * 2.0, base_e, 0.6) \
                .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    ```
    _Verify:_ run `WYRD_DEV_LEVEL=5 WYRD_NO_SAVE=1 godot --path wyrd` and grep output for `[town] board updated: lv=5`; confirm emission_energy > 0. `test_wyrd_loop.gd` and `test_wyrd_transitions.gd` green. _Effort:_ M.

**Phase 2 VERIFY:** all four suites green. `WYRD_SHOT=1 godot --path wyrd` at 25 s captures parchment board visible on tower. `WYRD_DEV_LEVEL=5 WYRD_NO_SAVE=1 godot --path wyrd` log shows `[town] board updated`.

---

### Phase 3 — Ambient ambient life timers (nice-to-have, after B0)

> **Gate:** defer until Plan.md B0 (`data/feel.gd`) ships so ambient timer constants live in one tuning block. The tasks below are specified but not required for the first PR.

11. **Ambient bird/fire SFX timers in `town.gd:_ready`** — `town.gd:_ready` (end of function). After `_build_environment()`:
    ```gdscript
    # Ambient life — jittered timers that layer low-vol sounds.
    # Constants move to Feel.* when data/feel.gd (Plan.md B0) ships.
    const BIRD_MIN := 8.0; const BIRD_MAX := 15.0
    const FIRE_MIN := 6.0; const FIRE_MAX := 10.0
    _schedule_ambient("town_ambient_birds", BIRD_MIN, BIRD_MAX, 0.12)
    _schedule_ambient("town_fire_crackle",  FIRE_MIN, FIRE_MAX, 0.18)
    ```
    ```gdscript
    func _schedule_ambient(key: String, min_sec: float, max_sec: float, vol_scale: float) -> void:
        var rng3 := RandomNumberGenerator.new()
        rng3.seed = 26 + key.hash()
        var delay := rng3.randf_range(min_sec, max_sec)
        get_tree().create_timer(delay).timeout.connect(func() -> void:
            var sfx4 := get_node_or_null("/root/Sfx")
            if sfx4 != null:
                sfx4.play(key, 0.06)   # narrow pitch-jitter for ambience
            _schedule_ambient(key, min_sec, max_sec, vol_scale))
    ```
    _Verify:_ playtest — in a 60-second town session, logprint confirms `[Sfx]` fires at least once for both keys (or graceful no-op if .mp3 absent). `test_wyrd_loop.gd` green (timer fires after scene teardown safely because `get_node_or_null` returns null). _Effort:_ S.

12. **Co-op lantern warmth on peer join (optional cosmetic)** — `town.gd:_ready` (net_env section, ~line 89). In the `roster_changed` connection callback added for net play, pulse the plaza lanterns' `OmniLight3D` energy via tween:
    ```gdscript
    NetGame.roster_changed.connect(func() -> void:
        NetGame.setup_scene(self)
        _pulse_lanterns(), CONNECT_ONE_SHOT)
    ```
    ```gdscript
    func _pulse_lanterns() -> void:
        for child in get_children():
            var light := child.get_node_or_null("OmniLight3D")
            if light == null:
                continue
            var t := create_tween()
            t.tween_property(light, "light_energy", 3.5, 0.2) \
                .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
            t.tween_property(light, "light_energy", 2.0, 0.3)
    ```
    _Verify:_ two-client smoke test (`WYRD_NET=host` + `join`) — lanterns visibly pulse when second peer connects; no crash. _Effort:_ S.

## First commit (smallest shippable slice)

**Tasks 1–5 (Phase 1).** This is one focused PR:

- `sfx.gd`: 4 stub keys added (silent no-ops).
- `game.gd`: `_returning_from_delve` flag added; set in `return_to_town` before scene change.
- `town.gd`: arrival beat reads flag (music delay + camera nudge); `var net_spawn` exported.
- `net_game.gd`: fan arc spawn replaces straight +X offset.

**Acceptance:** `WYRD_NO_SAVE=1` all four headless suites green; `WYRD_NET=host` + second client spawns without node-name clash; `WYRD_SHOT=1` cold-boot plays music immediately; return-from-delve delays 0.3 s (logprint confirms).

## Test & verification plan

| Suite / check | Tasks covered | Command |
|---|---|---|
| `test_wyrd_loop.gd` | 1, 2, 10 | `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` |
| `test_wyrd_dungeon_scene.gd` | 6, 7, 8 | `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd` |
| `test_wyrd_transitions.gd` | 3, 4, 5, 10 | `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_transitions.gd` |
| `test_skills.gd` | (gate green) | `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd` |
| Screenshot: board visible | 9 | `WYRD_SHOT=1 godot --path wyrd` → `/tmp/wyrd_town.png` |
| Log assert: board updated | 10 | `WYRD_DEV_LEVEL=5 WYRD_NO_SAVE=1 godot --path wyrd` → grep `[town] board updated` |
| Log assert: arrival delay | 3 | manual return from dungeon → grep `[Sfx] play: town_arrival_swell` or timer logprint |
| Net smoke test | 5, 12 | `WYRD_NET_RUN=5 WYRD_NET=host godot --path wyrd` + `WYRD_NET=join:localhost godot --path wyrd` |
| Screenshot: mid-grow mote | 8 | `WYRD_SHOT=1 godot --path wyrd` timed at ~25 s after herb patch depletes |

All commands run from `wyrd/`.

## Risks & open questions

1. **`_returning_from_delve` flag reset race** — if `town.gd:_ready` fires before `Game._ready` in a headless test, the flag read returns the default `false`. Mitigate: read with `get("_returning_from_delve")` (returns `null` on missing property → cast to bool is `false`), which is safe even if Game loads late.

2. **Atlas board material mutation** — `material_override` is a shared resource if preloaded; mutating `emission_energy_multiplier` in-place would affect all boards in the scene (only one exists, so this is safe, but note it). If a second board is ever added, duplicate the material on placement.

3. **Arrival beat — every return vs. first only** — current spec plays the swell on every return from a delve. If repeated returns feel intrusive in playtest, add `var _arrived_once := false` and gate the full beat behind it. Decision for the user after playtest.

4. **`regrew` signal in multiplayer** — `gather_node` is not authority-gated; in a co-op session the regrow timer fires on all peers, meaning `regrew` emits and motes spawn on all clients simultaneously. This is cosmetically fine (each client sees its own motes) but may double-play SFX on the host. If so, gate `_on_node_regrew` on `not net_active()` or `is_multiplayer_authority()`.

5. **Phase 3 ambient timers on scene teardown** — `get_tree().create_timer` timers are freed with the SceneTree, not the node; if the player exits to dungeon mid-timer the callback fires on a freed scene node. The `get_node_or_null("/root/Sfx")` null-check in `_schedule_ambient` guards the crash but the callback still fires. Low risk but worth noting.

6. **`summit_cleared` has no signal** — the board only updates at `_ready` and on `leveled_up`. A session that clears the Summit calls `return_to_town` which triggers a scene reload — the board will update on the next `_ready`. This is acceptable; no patch needed unless a "live summit clear" pulse is desired.

## Build status — 2026-06-16

**Scope delivered (town.gd + town_environment.gd only):**

- `var net_spawn: Vector3 = Vector3(20.0, 0.0, 27.2)` added to town.gd; net_game.gd:_spawn_pos already reads it — no net_game.gd change needed.
- **Arrival beat** — `_ready` reads `game._returning_from_delve` via null-safe `get()`. If true: clears the flag, delays music 0.3 s via `create_timer`, fires `sfx.play("town_arrival_swell")`, and nudges `_zoom_target` on the camera rig. Cold boot plays music immediately (existing path preserved).
- **Living Atlas board** — `QuadMesh` parchment quad added in `_place_dressing` at `(20.5, 1.6, 8.0)`, named `AtlasBoard`, with `StandardMaterial3D` (emission enabled, energy=0 at spawn). `_on_board_update()` reads `trade_lv("wayfinding")` and `summit_cleared`, drives emissive via a back-out `tween_method` pulse. Wired to `game.leveled_up` signal in `_ready` after `_place_dressing`.
- **Regrow mote burst** — `_on_node_regrew(pos)` + `_spawn_regrow_motes(pos)` added; connection in `_place_herb_patches` / ore / log loops guarded by `has_signal("regrew")` so it's a no-op until gather_node.gd adds the signal (deferred task — out of scope).
- **Ambient SFX timers** — `_schedule_ambient("town_ambient_birds", 8, 15, 0.12)` and `_schedule_ambient("town_fire_crackle", 6, 10, 0.18)` wired in `_ready`; recursive lambda, graceful no-op if audio files absent.
- **town_environment.gd ambient life** — 12 billboard `QuadMesh` firefly/dust motes placed at rest origins, oscillated each frame via Lissajous sin/cos (no drift), alpha-pulsed. Plaza lanterns' `OmniLight3D` nodes collected and flickered per-frame with two overlaid sines. `_process` enabled in `_ready`.

**Deferred (out-of-scope for this pass):**
- `gather_node.gd` `regrew` signal + emit in `_regrow()` — needs a gather_node.gd edit. Handlers in town.gd are ready; connections activate automatically once the signal exists.
- `game.gd` `_returning_from_delve` flag — needs a game.gd edit for the arrival beat to fire on delve return. The read in town.gd is already there and null-safe (returns false until the flag exists).
- `sfx.gd` stub key registration — needs sfx.gd edit to avoid silent graceful-no-op log spam when audio files land.
- Net spawn fan arc in `net_game.gd:_spawn_player` — net_game.gd is out of scope; `var net_spawn` on town.gd already provides the offset point.
- Phase 3 co-op lantern pulse on `roster_changed` — deferred to Phase 3.

**Parse risks mitigated:**
- `tween_method` called with a named `fn` Callable variable, not an inline lambda with trailing-comma ambiguity.
- `mat.albedo_color.a =` written as copy-modify-write (`var c := mat.albedo_color; c.a = ...; mat.albedo_color = c`) to avoid Godot 4 value-type sub-property assignment issue.
- `Array[Color]` typed literal used in `_build_ambient_motes` (valid Godot 4.6).
- All `get()` calls on potentially-missing properties checked for `== true` / `!= null`, never via `bool()`.
- No `load()` calls inside `_draw` or any draw path.
