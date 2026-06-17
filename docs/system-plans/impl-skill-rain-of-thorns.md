---
title: Rain of Thorns — Implementation Plan
parent: "[[skill-rain-of-thorns]]"
domain: Combat Skills
type: implementation-plan
status: ready-to-build
effort: M
tags: [wayfinder, impl]
---

# Rain of Thorns — Implementation Plan

> Build doc for [[skill-rain-of-thorns]]. Done when the skill has correct crit/bleed/SFX logic and a Spec-34-quality 4-beat telegraph VFX stack visually distinct from and on par with [[impl-skill-bramble-snare]].

## Definition of done

- Phase 1: `test_wyrd_loop.gd` line 158-160 still green; new `test_skills.gd` assertions pass (crit eligible, bleed `dpt > 1` at `damage=50`); `sfx.play("skill_rain_of_thorns")` no longer a no-op.
- Phase 2: Animation Gallery key `R` shows 4 visually distinct beats in screenshot sequence — amber reticle ring at t=0, amber fill disc at t≈0.30 s, thorn-snap + emission burst at t=0.60 s, wither at t≈0.85 s. Disc is never white. All headless suites green.
- Phase 3: Recoil fires at cast; bleed motes visible on at least one enemy in gallery screenshot; balance sign-off from playtest session.

## Preconditions / dependencies

- [[impl-skill-bramble-snare]] — `_make_thorn`, `_wither_subtree`, `_spawn_landing_reticle` patterns are copied verbatim or adapted; BrambleSnare must be merged first so naming/shader patterns are stable.
- [[impl-system-combat-juice-vfx]] — shared disc-growth, emission-burst, camera micro-kick vocabulary. Phase 2 beat 3's micro-kick must respect the `WYRD_SHAKE` toggle (Plan.md Part A §3 — already shipped; do not re-plan).
- [[impl-system-status-effects]] — `SkillEffect.bleed(dur, dpt, interval)` factory at `skill_effect.gd:39`; bleed scaling (Phase 1) lands inside the timer callback.
- [[impl-system-audio-music]] — `sfx.gd` PATHS dict at line 8; `skill_rain_of_thorns` key must be registered before the SFX swap in Phase 1 unblocks.
- **`res://assets/vfx/vine_grow.gdshader`** — exists at `wyrd/assets/vfx/vine_grow.gdshader`. Required for thorn prisms in Phase 2 beat 3.
- **`res://assets/vfx/reticle_ring.png`** — exists at `wyrd/assets/vfx/reticle_ring.png`. Required for Phase 2 beat 1.
- **`res://audio/skill_rain_of_thorns.mp3`** — DOES NOT EXIST. The `play()` call is a graceful no-op until this file lands (`sfx.gd:87` guard). Generating it via `tools/generate_audio.py` (ElevenLabs) is an optional polish step; Phase 1 blocker is only the key registration in PATHS, not the audio file.

## Tasks (ordered)

### Phase 1 — Correctness (no VFX changes)

1. **Rename RANGE cap into explicit constants** — `rain_of_thorns.gd:13,26-27`. Replace `const RANGE := 9.0` and the inline `minf(RANGE, 6.0)` with two explicit constants:
   ```gdscript
   const CAST_RANGE := 6.0   # effective throw distance (intentionally inside max)
   const MAX_RANGE  := 9.0   # reserved for future upgrade tier
   ```
   Change `fire()` line 26-27 to `player.global_position + dir.normalized() * CAST_RANGE`.
   _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_loop.gd` (line 158 check still passes). _Effort:_ S.

2. **Pass crit args to `take_damage`** — `rain_of_thorns.gd:37`. Extend the detonation callback to match the Thornburst pattern (`thornburst.gd:27-28`):
   ```gdscript
   c.take_damage(dmg, to.normalized(),
       float(player.derived_stats.crit_chance),
       float(player.derived_stats.crit_mult_bonus))
   ```
   `take_damage` signature at `combatant.gd:175` accepts optional `crit_chance` and `crit_mult_bonus` floats — this fills them.
   _Verify:_ New `_check` in `test_skills.gd`: fire RainOfThorns on a mock target with `crit_chance=1.0`; assert `hit_damage > int(dmg * 1.0)` (crit path fired). _Effort:_ S.

3. **Scale bleed DPT off attack damage** — `rain_of_thorns.gd:38`. Change hardcoded `dpt=1` to:
   ```gdscript
   var dpt: int = maxi(1, int(float(player.derived_stats.damage) * 0.10))
   SkillEffect.bleed(2.0, dpt, 0.5).apply(c)
   ```
   `SkillEffect.bleed` signature at `skill_effect.gd:39` expects `(dur, dpt, interval)`.
   _Verify:_ New `_check` in `test_skills.gd`: mock player `derived_stats.damage = 50`; assert bleed `damage_per_tick == 5` (or `> 1`). _Effort:_ S.

4. **Register `skill_rain_of_thorns` SFX key** — `sfx.gd:24`. Add one line to the PATHS dict after the `skill_snare` entry:
   ```gdscript
   "skill_rain_of_thorns": "res://audio/skill_rain_of_thorns.mp3",
   ```
   The file is absent so `play()` will be a no-op (per `sfx.gd:87` guard) until the MP3 ships — that is acceptable.
   _Verify:_ No headless test change needed (play is a no-op). Visual: open Sfx autoload in editor, confirm key present. _Effort:_ S.

5. **Swap SFX call from `skill_snare` to `skill_rain_of_thorns`** — `rain_of_thorns.gd:41`. Change:
   ```gdscript
   sfx.play("skill_rain_of_thorns")
   ```
   Depends on task 4 (key must exist first, even as no-op). BrambleSnare retains `skill_snare` — no collision.
   _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_skills.gd` (all existing checks green). _Effort:_ S.

---

### Phase 2 — Telegraph VFX (Spec-34 4-beat stack)

> Identity note: Rain of Thorns *calls down* a volley; it is not a ground eruption. The visual language is **overhead arrival** (reticle snaps immediately, fill expands upward-to-ground) not BrambleSnare's *binding* feel.

6. **Refactor `_telegraph` into a holder-based builder** — `rain_of_thorns.gd:44-59`. Replace the bare `MeshInstance3D` with a `Node3D` holder parented to the scene root (not to `player`), so VFX survive a mid-delay player death. All subsequent beats are children of this holder. Keep old function signature `_telegraph(player: Node, center: Vector3) -> Node3D` but return the holder:
   ```gdscript
   func _telegraph(player: Node, center: Vector3) -> Node3D:
       var holder := Node3D.new()
       holder.name = "RainOfThornsVisuals"
       holder.position = center
       player.get_parent().add_child(holder)
       return holder
   ```
   Update `fire()` line 31 to capture the return value: `var _holder: Node3D = _telegraph(player, center)`.
   _Verify:_ `test_wyrd_loop.gd` and `test_skills.gd` green (no visual test yet). _Effort:_ S.

7. **Beat 1 — Landing reticle** — `rain_of_thorns.gd`: add `_spawn_landing_reticle(player: Node, holder: Node3D) -> void`. Adapted from `bramble_snare.gd:108-159` with Rain of Thorns constants:
   - Use `preload("res://assets/vfx/reticle_ring.png")` (file confirmed present).
   - Amber tint: `Color(0.95, 0.70, 0.20)` (not BrambleSnare's green).
   - Scale pop-in `0.1 → 1.0` over `0.08 s` `TRANS_BACK/EASE_OUT`.
   - 6 Hz pulse on `emission_energy_multiplier` for the full `DELAY` window.
   - Fade-out starts at `DELAY - 0.20 s` over `0.20 s`, then `queue_free`.
   - Add a `preload` const at the top of the file (not inside the function — satisfies the "never load in _draw" rule; this is `_ready`-equivalent):
     ```gdscript
     const TEX_RETICLE_RING := preload("res://assets/vfx/reticle_ring.png")
     ```
   Call from the refactored `_telegraph` after holder creation.
   _Verify:_ Animation Gallery key `R` screenshot at t=0 shows amber ring on ground. _Effort:_ S.

8. **Beat 2 — Telegraph fill (disc growth)** — `rain_of_thorns.gd`: add `_spawn_fill_disc(holder: Node3D) -> MeshInstance3D`. Disc grows from a pinprick to `RADIUS` over `0.40 s` (not `0.30 s` — Rain of Thorns has `DELAY=0.60 s`; the fill consumes 2/3 of the window):
   ```gdscript
   const FILL_SEC := 0.40
   const AMBER_COLOR := Color(0.95, 0.55, 0.15, 0.40)
   ```
   - `CylinderMesh` at `RADIUS`, height `0.06`.
   - `StandardMaterial3D` with `TRANSPARENCY_ALPHA`, `SHADING_MODE_UNSHADED`, `emission_enabled = true`.
   - `albedo_color = AMBER_COLOR`; emit at `Color(0.95, 0.55, 0.15)`.
   - Scale-tween `Vector3(0.02, 1.0, 0.02) → Vector3.ONE` over `FILL_SEC` with `TRANS_CUBIC/EASE_OUT`.
   - Add as child of holder; holder origin is already at `center`, so `position = Vector3.ZERO`.
   Call from `_telegraph` after reticle spawn.
   _Verify:_ Gallery screenshot at t≈0.30 s shows growing amber disc, distinct from the ring. _Effort:_ S.

9. **Beat 3 — Impact: thorn-snap + emission burst** — `rain_of_thorns.gd`: add `_on_detonate(holder: Node3D, disc_mat: StandardMaterial3D, player: Node) -> void`. Called from the existing `DELAY` timer callback in `fire()` immediately before `AoeQuery.query_circle`. Three simultaneous actions:
   - Snap disc color from amber to thorn-green: `disc_mat.albedo_color = Color(0.30, 0.65, 0.25, 0.55)`.
   - Ring of 6–8 thorn prisms around the perimeter (reuse `_make_thorn` copied from `bramble_snare.gd:422-448`, placed at `RADIUS * 0.92` on TAU angles). Grow-dissolve via `vine_grow.gdshader` with `growth` tweened `0 → 1` over `0.10 s`:
     ```gdscript
     const VINE_GROW_SHADER := preload("res://assets/vfx/vine_grow.gdshader")
     const THORN_COUNT := 6
     const IMPACT_SNAP_SEC := 0.10
     ```
   - Emission burst on disc: `emission_energy_multiplier` tweened `1.5 → 5.0` over `0.05 s`, then `5.0 → 1.5` over `0.05 s`.
   - Camera micro-kick (if `WYRD_SHAKE` env var not `"0"`): `player.get_viewport().get_camera_3d()` — apply `0.04` trauma to the existing shake node if present, otherwise skip gracefully.
   _Verify:_ Gallery screenshot at t=0.60 s shows thorn-green disc + perimeter thorn prisms + bright flash. _Effort:_ M.

10. **Beat 4 — Wither** — `rain_of_thorns.gd`: add `_wither(holder: Node3D, disc_mat: StandardMaterial3D) -> void`. Reuse `_wither_subtree` pattern from `bramble_snare.gd:541-550` (copy the function verbatim — it has no BrambleSnare-specific logic). Schedule after detonation + body time:
    ```gdscript
    const WITHER_SEC := 0.25
    # schedule: DELAY + IMPACT_SNAP_SEC + 0.15s body → wither
    ```
    - Parallel tween on disc: `albedo_color:a → 0` and `emission_energy_multiplier → 0` over `WITHER_SEC`.
    - `_wither_subtree(holder, tw)` — retracts thorn `growth` `1 → 0` with `TRANS_CUBIC/EASE_IN`.
    - `.chain().tween_callback(holder.queue_free)` — no leak.
    Call is scheduled in `fire()` via `create_timer(DELAY + IMPACT_SNAP_SEC + 0.15)`.
    _Verify:_ Gallery screenshot at t≈0.85 s shows fully dissipated holder. Suite: `test_wyrd_loop.gd` + `test_skills.gd` green. _Effort:_ S.

11. **Wire detonation callback to VFX** — `rain_of_thorns.gd:32-38`. Restructure `fire()` to pass the holder into the timer callback:
    ```gdscript
    var holder: Node3D = _telegraph(player, center)
    tree.create_timer(DELAY).timeout.connect(func() -> void:
        _on_detonate(holder, disc_mat_ref, player)
        for c in AoeQuery.query_circle(tree, center, RADIUS):
            ...damage + bleed...
    )
    ```
    `disc_mat_ref` is the `StandardMaterial3D` captured from `_spawn_fill_disc`'s return (add return type to that function). Schedule the wither timer in the same callback after `_on_detonate`.
    _Verify:_ Full end-to-end gallery playthrough (key `R`): 4 beats fire in sequence, no orphaned nodes after wither. `test_skills.gd` green. _Effort:_ S.

---

### Phase 3 — Polish (after Phase 2 ships)

12. **Cast recoil** — `rain_of_thorns.gd:21`. Add at the start of `fire()`:
    ```gdscript
    if player.has_method("apply_recoil"):
        player.apply_recoil(-0.3)
    ```
    Mirror of `bramble_snare.gd:96-97`.
    _Verify:_ `test_skills.gd` green (recoil is a no-op on mock player). Manual: player model bobs on cast. _Effort:_ S.

13. **Per-enemy bleed mote burst** — `rain_of_thorns.gd`: add `_bleed_mote(target: Node3D, holder: Node3D) -> void`. `GPUParticles3D` parented to the holder (not the enemy — avoids dangling parent if enemy dies), emitting a single burst of 8 soft-circle quads in thorn-green, centered on `target.global_position`. Cap at 6 motes total per cast:
    ```gdscript
    const TEX_SOFT_CIRCLE := preload("res://assets/vfx/soft_circle.png")
    const MAX_MOTE_ENEMIES := 6
    ```
    Call inside the detonation loop: `if mote_count < MAX_MOTE_ENEMIES: _bleed_mote(c, holder); mote_count += 1`.
    _Verify:_ Gallery screenshot after firing at 1+ dummy enemies shows small thorn-green puff on each hit enemy. _Effort:_ S.

14. **Balance review pass** — No code change. Playtest with a focus-heavy build; target: ≥2 enemies hit per cast at crypt density; bleed extends kill-efficiency by ~15% vs. unbleed baseline. Sign-off logged as a comment in `rain_of_thorns.gd` header.
    _Verify:_ Manual playtest session. _Effort:_ S.

15. **Level gate (optional, deferred)** — `game.gd:118` (SKILL_REQS table). If the skill pool grows large enough to need pruning, add `"RainOfThorns": 5`. Per [[skill-rain-of-thorns]] open question: currently all B5-wave1 skills are ungated. Do NOT add until the user decides.
    _Verify:_ `test_skills.gd` `_test_gates` check still passes. _Effort:_ S.

---

## First commit (smallest shippable slice)

**Tasks 1–5 together** (Phase 1 correctness). All five are pure logic/constant changes in two files (`rain_of_thorns.gd` and `sfx.gd`), touch no VFX, and keep all four headless suites green. They resolve the two blockers called out in [[skill-rain-of-thorns]] (misleading RANGE constant + wrong SFX key) and add the two correctness fixes (crit args + bleed scaling). The new `test_skills.gd` assertions (tasks 2 and 3) ship in the same commit.

**Acceptance:** `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_loop.gd` and `test_skills.gd` both pass; `sfx.gd` PATHS has `skill_rain_of_thorns` key; `CAST_RANGE` and `MAX_RANGE` constants replace the old `minf(RANGE, 6.0)`.

## Test & verification plan

**Headless (all phases must stay green):**
```
cd wyrd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_transitions.gd
```

**New assertions to add to `test_skills.gd` (Phase 1):**
- `_check("RainOfThorns: crit_chance forwarded to take_damage", ...)` — mock Combatant records crit args; `crit_chance=1.0` must produce `hit > base_dmg`.
- `_check("RainOfThorns: bleed dpt scales with damage=50", ...)` — set `player.derived_stats.damage = 50`; assert `bleed.damage_per_tick == 5`.

**Animation Gallery (Phase 2):**
- Add `KEY_R` case to `tools/animation_gallery.gd:267` input handler: instantiate a `RainOfThorns.new()` and call `.fire(_dummy_player_node)` on a stationary placeholder with `aim_dir()` returning `Vector3.FORWARD`.
- Capture 4 screenshots with `WYRD_SHOT=1` at t=0, t=0.30 s, t=0.60 s, t=0.85 s.
- Visual checklist per screenshot:
  1. t=0: amber reticle ring visible, disc not yet visible.
  2. t=0.30 s: amber disc ~50% scale, reticle still visible, no thorns.
  3. t=0.60 s: full thorn-green disc, 6–8 thorn prisms around perimeter, emission flare visible.
  4. t=0.85 s: all geometry faded/gone, no leftover nodes.

**Phase 3 playtest:** manual session in crypt biome, bleed mote screenshot, recoil check.

## Risks & open questions

1. **`CAST_RANGE = 6.0` vs `MAX_RANGE = 9.0` (open question from [[skill-rain-of-thorns]])** — at 6.0 m the caster is inside the 2.6 m burst radius when enemies are in melee. This is currently intentional "risk vs. reward" design but may feel punishing. Task 1 is a cosmetic rename; changing the actual value is a separate gameplay decision the user must sign off on before Phase 1 ships.

2. **Bleed "flavor vs. meaningful DoT" (open question from [[skill-rain-of-thorns]])** — `dmg * 0.10` at `damage=50` yields `dpt=5` over 4 ticks = 20 bonus damage. That is a real secondary damage source (~11% of the base hit at `DMG_MULT=1.8`). Confirm whether this is the intended direction before task 3 ships.

3. **Camera micro-kick access pattern** — Phase 2 beat 3 references a camera shake node. The existing shake infrastructure (Plan.md Part A §3) must be confirmed reachable from a skill object that only holds a `player: Node` reference. If the shake node is not accessible via `player.get_node_or_null("/root/CameraShake")` or equivalent, the micro-kick must be omitted or wired differently. The `WYRD_SHAKE` env var check should short-circuit before the node lookup.

4. **`_make_thorn` copy vs. shared utility** — Tasks 9 and 10 copy `_make_thorn` and `_wither_subtree` from `bramble_snare.gd`. If a third skill needs them later, they should migrate to [[impl-system-combat-juice-vfx]]'s shared toolkit. For now, copy-to-own is safer than a cross-file dependency in GDScript (no `import` — only `preload`).

5. **`class_name RainOfThorns` in headless** — per project memory, `class_name` does not register in `--script` mode. Tests must use `preload("res://scripts/skills/rain_of_thorns.gd").new()` (the pattern already used in `test_wyrd_loop.gd:158`). All new `test_skills.gd` assertions must follow this pattern.

## Build status — 2026-06-16

**Shipped (all in `wyrd/scripts/skills/rain_of_thorns.gd`):**
- Phase 1 (tasks 1–3, 5): `CAST_RANGE=6.0` / `MAX_RANGE=9.0` replace the old `minf(RANGE, 6.0)` pattern; crit args (`crit_chance`, `crit_mult_bonus`) forwarded to `take_damage`; bleed dpt scales as `maxi(1, int(damage * 0.10))`; SFX call swapped to `"skill_rain_of_thorns"` (graceful no-op until audio file + sfx.gd key registration land).
- Phase 2 (tasks 6–11): full 4-beat holder-based VFX stack — Beat 1 amber reticle ring with 6 Hz pulse + BACK pop-in, Beat 2 amber fill disc (CUBIC ease-out, 0.40 s), Beat 3 impact (amber→thorn-green snap + emission burst + 6 vine_grow thorn prisms), Beat 4 wither (parallel disc alpha-out + thorn retract, queue_free). Holder parented to scene root, not player.
- Phase 3 (task 12): cast recoil `apply_recoil(-0.3)` at top of `fire()`.

**Deferred:**
- Task 4: `sfx.gd` PATHS registration for `skill_rain_of_thorns` — sfx.gd is outside this agent's edit scope; the `play()` call is a graceful no-op until the key and MP3 both land.
- Task 13: per-enemy bleed mote burst (`_bleed_mote` / `GPUParticles3D`) — Phase 3 polish, no regression risk.
- Task 14: balance playtest sign-off — manual session required.
- Task 15: level gate (`game.gd` SKILL_REQS) — explicitly deferred per plan; user decision needed.
