---
title: Thornburst — Implementation Plan
parent: "[[skill-thornburst]]"
domain: Combat Skills
type: implementation-plan
status: ready-to-build
effort: M
tags: [wayfinder, impl]
---

# Thornburst — Implementation Plan

> Build doc for [[skill-thornburst]]. Done when `thornburst.gd` runs a 4-beat player-centered burst VFX (anticipation flash → amber disc → emerald thorn snap → wither), fires damage at snap-onset, has a dedicated impact SFX, carries a Wayfinding-5 unlock gate, and exposes mastery upgrade vars for snare-duration and radius.

## Definition of done

- `_ring_vfx` replaced by `_burst_vfx` with 4 visible beats: emissive player flash (≥1 frame), amber disc scale-in, emerald disc + thorn snap (inner + outer ring), wither retract.
- Damage + snare fire at Beat 3 onset (not at `fire()` call).
- `sfx.play("thornburst_impact")` fires at Beat 3; `skill_snare` plays at cast as wind-up cue.
- `SKILL_REQS` in `game.gd:118` contains `"Thornburst": 5`.
- `snare_duration_bonus: float` and `radius_bonus: float` instance vars gate mastery tiers.
- `test_skills.gd` assertions pass: `skill_unlocked("Thornburst")` false at lv 4, true at lv 5; `effective_radius` and `effective_snare` match bonus vars.
- All four headless suites stay green.

## Preconditions / dependencies

- [[impl-skill-bramble-snare]] — **must be merged before starting.** `_spawn_thorns`, `_make_thorn`, `_wither_subtree`, and `_make_ground_disc` in `bramble_snare.gd` are copied verbatim (no shared base class yet; duplication is intentional until a VFX helper module is extracted in [[impl-system-combat-juice-vfx]]).
- `res://assets/vfx/vine_grow.gdshader` — confirmed present at `wyrd/assets/vfx/vine_grow.gdshader`.
- `sfx.gd` — `"skill_snare"` key present at line 24; `"thornburst_impact"` key absent — Task 1 adds it.
- `game.gd:118` — `SKILL_REQS` is a `const` dict literal; Task 7 adds the `"Thornburst": 5` entry.
- `player_controller.gd:888` — `apply_recoil(amount: float)` confirmed present; `apply_ward(amount: int, duration: float)` confirmed at line 1386.
- `HitFeedback` — `apply_flash(sec, color)` is the pattern; player uses `_mesh` (confirmed `player_controller.gd:90`); Task 3 calls `player.apply_flash(0.08, Color(0.4, 1.0, 0.4))` if the method exists.
- `test_skills.gd:95–100` — Thornburst is already in the loadout test; the new assertions in Task 9 add to the existing file.
- Plan.md Part A (SHIPPED) — Beat timing vocabulary (BACK ease, CUBIC ease-out, squash-in punch) is already live in-engine; no new framework needed.
- Plan.md Part B B0 (`feel.gd` tunables) — NOT yet landed. Do NOT block on it; keep timing constants local to `thornburst.gd` for now.

## Tasks (ordered)

### Phase 1 — 5-beat VFX rebuild + impact SFX

1. **Add `"thornburst_impact"` key to `sfx.gd`** — `sfx.gd:38` (after the `"roll"` entry).
   ```gdscript
   "thornburst_impact": "res://audio/thornburst_impact.mp3",
   ```
   Audio file does not exist yet — `play()` is a graceful no-op until generated (same pattern as every deferred SFX). Generate with `tools/generate_audio.py` (heavy thud + rustle prompt, ~1 s). This task is a one-liner; commit it alone so the key is visible in diffs before the skill code references it.
   _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_loop.gd` — green (no parse error in sfx.gd). _Effort:_ S.

2. **Add timing + style constants block to `thornburst.gd:1–13`** — insert after the existing `const SNARE_SLOW` line.
   ```gdscript
   const TELEGRAPH_COLOR  := Color(0.95, 0.65, 0.20, 0.55)  # amber
   const ACTIVE_COLOR     := Color(0.30, 0.65, 0.25, 0.70)  # emerald
   const THORN_BASE_COLOR := Color(0.12, 0.06, 0.04)
   const ANTICIPATE_SEC   := 0.08
   const TELEGRAPH_SEC    := 0.12
   const SNAP_SEC         := 0.10
   const WITHER_SEC       := 0.25
   const OUTER_COUNT      := 8
   const INNER_COUNT      := 4
   const VINE_GROW_SHADER := preload("res://assets/vfx/vine_grow.gdshader")
   ```
   No logic change yet — constants only.
   _Verify:_ headless parse (same suite as Task 1). _Effort:_ S.

3. **Add `_anticipation_flash(player)` to `thornburst.gd`** — new private func before `fire()`.
   ```gdscript
   func _anticipation_flash(player: Node) -> void:
       if player.has_method("apply_flash"):
           player.apply_flash(ANTICIPATE_SEC, Color(0.4, 1.0, 0.4))
   ```
   Reuses `combatant.apply_flash` (confirmed in `hit_feedback.gd:50`); green-tinted instead of white so the cast-self-flash is distinct from a hit-flash. No new API needed.
   _Verify:_ no test yet; verified in Task 10 screenshot. _Effort:_ S.

4. **Add `_make_burst_disc(radius)` to `thornburst.gd`** — returns a `MeshInstance3D` amber `CylinderMesh`.
   ```gdscript
   func _make_burst_disc(radius: float) -> MeshInstance3D:
       var disc := MeshInstance3D.new()
       var dm := CylinderMesh.new()
       dm.top_radius = radius; dm.bottom_radius = radius; dm.height = 0.05
       disc.mesh = dm
       var mat := StandardMaterial3D.new()
       mat.albedo_color = TELEGRAPH_COLOR
       mat.emission_enabled = true
       mat.emission = Color(TELEGRAPH_COLOR.r, TELEGRAPH_COLOR.g, TELEGRAPH_COLOR.b)
       mat.emission_energy_multiplier = 2.4
       mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
       mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
       disc.material_override = mat
       return disc
   ```
   Direct port of `bramble_snare._make_ground_disc()` with parameterized radius and no separate name.
   _Verify:_ headless parse. _Effort:_ S.

5. **Add `_spawn_burst_thorns(holder, radius)` to `thornburst.gd`** — spawns outer ring (8 thorns at `radius * 0.90`) + inner ring (4 thorns at `radius * 0.40`), both via `vine_grow.gdshader`.
   ```gdscript
   func _spawn_burst_thorns(holder: Node3D, radius: float) -> void:
       for i in OUTER_COUNT:
           var angle: float = TAU * float(i) / float(OUTER_COUNT)
           var pos := Vector3(cos(angle) * radius * 0.90, 0.0, sin(angle) * radius * 0.90)
           holder.add_child(_make_burst_thorn(pos, angle, 1.0))
       for i in INNER_COUNT:
           var angle: float = TAU * float(i) / float(INNER_COUNT) + PI * 0.25
           var pos := Vector3(cos(angle) * radius * 0.40, 0.0, sin(angle) * radius * 0.40)
           holder.add_child(_make_burst_thorn(pos, angle, 0.75))
   ```
   Inner thorns smaller (scale factor 0.75) to read as "erupted from boots." Both rings use the same `growth` tween to `SNAP_SEC` with `TRANS_CUBIC / EASE_OUT`.
   _Verify:_ headless parse. _Effort:_ S.

6. **Add `_make_burst_thorn(pos, angle, scale_f)` and `_wither_subtree(node, tw)` to `thornburst.gd`** — direct copies from `bramble_snare.gd:422–448` and `bramble_snare.gd:541–550` respectively; no changes except dropped tether-related comments.
   ```gdscript
   func _make_burst_thorn(pos: Vector3, angle: float, scale_f: float) -> MeshInstance3D:
       # ... identical to bramble_snare._make_thorn except uses SNAP_SEC and scale_f
   func _wither_subtree(node: Node, tw: Tween) -> void:
       # ... verbatim copy
   ```
   _Verify:_ headless parse. _Effort:_ S.

7. **Replace `_ring_vfx` with `_burst_vfx(player, radius)` in `thornburst.gd:39–57`** — the 4-beat orchestrator. Moves AoE damage + snare inside a `create_timer(ANTICIPATE_SEC + TELEGRAPH_SEC)` callback so damage fires at Beat 3 onset.
   ```gdscript
   func _burst_vfx(player: Node, radius: float, dmg: int) -> void:
       _anticipation_flash(player)
       # Beat 2 — amber disc grows from pinprick at player feet
       var holder := Node3D.new()
       holder.position = player.global_position + Vector3(0, 0.05, 0)
       player.get_parent().add_child(holder)
       var disc := _make_burst_disc(radius)
       holder.add_child(disc)
       disc.scale = Vector3(0.05, 1.0, 0.05)
       var fill_tw := disc.create_tween()
       fill_tw.tween_property(disc, "scale", Vector3.ONE, TELEGRAPH_SEC) \
           .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
       # Beat 3 — snap: emerald, thorns, damage, SFX
       fill_tw.tween_callback(func() -> void:
           var disc_mat: StandardMaterial3D = disc.material_override
           disc_mat.albedo_color = ACTIVE_COLOR
           disc_mat.emission = Color(ACTIVE_COLOR.r, ACTIVE_COLOR.g, ACTIVE_COLOR.b)
           _spawn_burst_thorns(holder, radius)
           # AoE fires here — visual and damage land together
           for c in AoeQuery.query_circle(player.get_tree(), player.global_position, radius):
               var dir: Vector3 = c.global_position - player.global_position
               c.take_damage(dmg, dir, float(player.derived_stats.crit_chance),
                   float(player.derived_stats.crit_mult_bonus))
               if c.has_method("apply_status"):
                   c.apply_status("snared", SNARE_SEC + snare_duration_bonus, 0, SNARE_SLOW)
           var sfx = player.get_node_or_null("/root/Sfx")
           if sfx != null:
               sfx.play("thornburst_impact")
       )
       # Beat 4 — wither after SNAP_SEC
       var body_end := TELEGRAPH_SEC + SNAP_SEC
       player.get_tree().create_timer(body_end).timeout.connect(
           func() -> void:
               if not is_instance_valid(holder): return
               var tw := holder.create_tween()
               tw.set_parallel(true)
               var disc_mat: StandardMaterial3D = disc.material_override
               tw.tween_property(disc_mat, "albedo_color:a", 0.0, WITHER_SEC)
               tw.tween_property(disc_mat, "emission_energy_multiplier", 0.0, WITHER_SEC)
               _wither_subtree(holder, tw)
               tw.chain().tween_callback(holder.queue_free)
       )
   ```
   _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_skills.gd` — green. _Effort:_ M.

8. **Rewrite `fire()` in `thornburst.gd:19–36`** — move damage OUT of `fire()`, add upgrade vars, move recoil to pre-fire, call `_burst_vfx`.
   ```gdscript
   var snare_duration_bonus: float = 0.0
   var radius_bonus: float = 0.0

   func fire(player: Node) -> void:
       if player == null:
           return
       var dmg: int = int(round(float(player.derived_stats.damage) * DMG_MULT))
       var radius: float = RADIUS + radius_bonus
       # Recoil fires first — squash-in anticipation before eruption
       if player.has_method("apply_recoil"):
           player.apply_recoil(-0.5)
       # Cast wind-up cue SFX ("drawing in" feel)
       var sfx = player.get_node_or_null("/root/Sfx")
       if sfx != null:
           sfx.play("skill_snare")
       _burst_vfx(player, radius, dmg)
   ```
   Damage is now inside `_burst_vfx` Beat 3 callback (Task 7); `fire()` only sets up state and kicks the VFX.
   _Verify:_ `test_skills.gd` green; `test_wyrd_loop.gd` green. _Effort:_ S.

### Phase 2 — Player cast anticipation beat (squash punch)

9. **Add `_squash_punch(player)` to `thornburst.gd`** — 0.12 s squash-in on `player._mesh.scale` before thorns erupt.
   ```gdscript
   func _squash_punch(player: Node) -> void:
       var mesh: Node3D = player.get("_mesh")
       if mesh == null:
           return
       var base: Vector3 = player.get("_mesh_base_scale") if player.get("_mesh_base_scale") != null \
           else Vector3.ONE
       var squashed: Vector3 = Vector3(base.x * 1.08, base.y * 0.88, base.z * 1.08)
       var tw := mesh.create_tween()
       tw.tween_property(mesh, "scale", squashed, 0.06) \
           .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
       tw.tween_property(mesh, "scale", base, 0.06) \
           .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
   ```
   Called in `fire()` immediately after `apply_recoil` (same tick). Duration 0.12 s total — finishes before Beat 3 snap at ~0.20 s, so "coil then erupt" reads correctly.
   _Verify:_ screenshot at snap frame shows player mesh compressed; `test_skills.gd` green. _Effort:_ S.

### Phase 3 — Upgrade hooks + mastery gate

10. **Add `"Thornburst": 5` to `SKILL_REQS` in `game.gd:118`** — one dict entry.
    ```gdscript
    const SKILL_REQS := {"HuntersMark": 4, "Thornburst": 5, "HeartwoodWard": 7, "MercyShot": 9}
    ```
    Fits in the existing sorted-by-level ordering.
    _Verify:_ `test_skills.gd` assertions below (Task 11). _Effort:_ S.

11. **Add Thornburst upgrade assertions to `test_skills.gd`** — append after line 100.
    ```gdscript
    # Thornburst level gate
    Game.trades[Game.SKILL] = 4
    assert(not Game.skill_unlocked("Thornburst"), "Thornburst locked at lv4")
    Game.trades[Game.SKILL] = 5
    assert(Game.skill_unlocked("Thornburst"), "Thornburst unlocked at lv5")
    # Upgrade var assertions
    var tb := Thornburst.new()
    tb.radius_bonus = 0.8
    assert(absf((Thornburst.RADIUS + tb.radius_bonus) - 4.0) < 0.001, "effective radius 4.0")
    tb.snare_duration_bonus = 1.0
    assert(absf((Thornburst.SNARE_SEC + tb.snare_duration_bonus) - 3.0) < 0.001, "effective snare 3.0s")
    Game.trades[Game.SKILL] = 1  # reset
    ```
    _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_skills.gd` — all assertions pass. _Effort:_ S.

12. **Wire mastery perk tiers B and C in `game.gd`** — add two entries to the `SKILL` perk ladder (same pattern as `game.gd:414–464`).
    ```gdscript
    # In the PERKS[SKILL] array — add after existing entries:
    {"id": "thornburst_long_snare", "lv": 8,
     "desc": "Thornburst roots for 3 s instead of 2 s."},
    {"id": "thornburst_wide", "lv": 11,
     "desc": "Thornburst radius grows to 4.0 m."},
    ```
    In `game.gd` apply-perks path (wherever `player.set_skill_var` or equivalent fires on level-up), set `tb.snare_duration_bonus` and `tb.radius_bonus` based on `perk_active` checks. Exact hook site depends on where the skill instance is stored; follow the `HeartwoodWard` pattern at `heartwood_ward.gd:6–19` for reference.
    _Verify:_ `test_skills.gd` green; manual playtest at Wayfinding 8 confirms snare ticks for 3 s. _Effort:_ S.

## First commit (smallest shippable slice)

**Tasks 1–8** as one PR: `sfx.gd` key + constants + helper funcs + VFX rebuild + `fire()` rewrite. This replaces the bare torus with the 4-beat burst, moves damage to snap onset, and plays the new SFX key (graceful no-op until audio is generated). All four headless suites must stay green. Screenshot from `WYRD_SHOT=1` in dungeon confirms amber disc → emerald snap with thorn spikes visible.

The anticipation punch (Task 9), level gate (Tasks 10–11), and mastery perks (Task 12) follow in subsequent small commits.

## Test & verification plan

**Headless suites (run after every task):**
```
cd /Users/bbroeking/projects/gj26/wyrd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_transitions.gd
```

**New assertions (Task 11):** added to `test_skills.gd` — level gate at 4/5, `effective_radius` 4.0, `effective_snare` 3.0 s.

**Screenshot verification (after Task 7):**
```
WYRD_SHOT=1 godot --path wyrd
```
Fire Thornburst in dungeon; confirm screenshot frame shows amber disc, then emerald disc with 8 outer + 4 inner thorn spikes. The wither frame should show thorn spikes retracting tip-to-base.

**Screenshot verification (after Task 9):**
Capture frame just before snap — player mesh scale must be visibly compressed (scale.y < 1.0).

**Mastery playtest (after Task 12):**
Boot with `WYRD_DEV_LEVEL=8`; confirm snare DoT reads 3 s on an enemy. Boot with `WYRD_DEV_LEVEL=11`; confirm thorn ring fills the room perimeter at 4.0 m.

## Risks & open questions

1. **`apply_flash` on player** — `combatant.gd:436` confirms the method exists on combatants, and `player_controller.gd` inherits via combatant base. If player does NOT expose `apply_flash`, Task 3 silently skips via `has_method` guard and the anticipation beat degrades gracefully.

2. **Damage double-fire guard** — the current `fire()` calls damage, then `_ring_vfx`. After Task 7/8, damage moves entirely inside the `_burst_vfx` Beat 3 callback. If `fire()` is called on a client in multiplayer, the `AoeQuery.query_circle` will run client-side too. Per [[skill-thornburst]] Phase 4 note: verify Thornburst fires damage host-only before enabling co-op (same rule as enemy projectiles — damage call wrapped in `if multiplayer.is_server()`). Flag for [[impl-system-multiplayer-netcode]].

3. **Level gate design decision open** — parent note open question 1: gate at lv 5 (between HuntersMark:4 and HeartwoodWard:7) is the proposal. If the user wants Thornburst open from level 1 as the beginner panic option, Task 10 is skipped and Task 11's gate assertions are removed. Confirm before committing Task 10.

4. **Per-enemy vine tethers deferred** — parent note open question 2: Thornburst intentionally has NO tethers (eruption identity, not binding). Spike ring differentiates it visually from BrambleSnare's tether-and-bind. This decision is baked into the VFX above; revisit only in a separate Phase 4 PR after play-test sign-off.

5. **`thornburst_impact.mp3` generation** — add to next `generate_audio.py` run: `"thornburst_impact"`, prompt `"heavy ground thud, cracking bark, rustle of thorns erupting from earth, short decay"`, ~1.0 s. Until generated, `sfx.play("thornburst_impact")` is a no-op (graceful per `sfx.gd` design).

## Build status — 2026-06-16

**Shipped (thornburst.gd only):**
- Tasks 2–9 complete: timing/style constants block, `VINE_GROW_SHADER` preload, mastery upgrade vars (`snare_duration_bonus`, `radius_bonus`), `_anticipation_flash`, `_squash_punch`, `_make_burst_disc`, `_spawn_burst_thorns`, `_make_burst_thorn`, `_wither_subtree`, `_burst_vfx` 4-beat orchestrator, `fire()` rewrite (recoil + SFX at cast, damage deferred to Beat 3 snap). All public methods preserved; `fire(player)` signature unchanged.

**Deferred (outside thornburst.gd scope):**
- Task 1: `"thornburst_impact"` key in `sfx.gd` — file outside scope; `sfx.play("thornburst_impact")` in Beat 3 is a graceful no-op until added.
- Task 10: `"Thornburst": 5` entry in `game.gd` `SKILL_REQS` — file outside scope; level gate decision also open (see Risk 3).
- Task 11: New assertions in `test_skills.gd` — file outside scope.
- Task 12: Mastery perk wiring in `game.gd` — file outside scope.
