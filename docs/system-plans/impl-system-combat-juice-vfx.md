---
title: Combat Juice & VFX — Implementation Plan
parent: "[[system-combat-juice-vfx]]"
domain: Enemies & Combat
type: implementation-plan
status: ready-to-build
effort: M
tags: [wayfinder, impl]
---

# Combat Juice & VFX — Implementation Plan

> Build doc for [[system-combat-juice-vfx]]. Done when magnitude-scaled damage numbers, biome-tinted hit-sparks, and emissive/pre-flash breakable shatter are all wired, tested, and visually distinct from chip damage / crypt defaults.

## Definition of done

- A 1-damage bleed tick renders noticeably smaller than a 20-damage crit arrow in the same run (screenshot-comparable, no headless regressions).
- Calling `HitFeedback.play_hit` with `biome = "forest"` produces visibly greener sparks than `"crypt"` default.
- Shooting a pottery jar shows: white flash frame → glowing terracotta shards → micro camera shake; `take_damage` still fires and the jar `queue_free`s.
- All four headless suites stay green after each phase.

## Preconditions / dependencies

- **Plan.md Part A** — All six hit-feedback channels (flash, knockback, hitstop, spark, shake, SFX) are **shipped**. `HitFeedback.play_hit` (`hit_feedback.gd:45`), `hit_spark.gd`, `damage_number.gd`, `breakable.gd` all exist and are wired. Do NOT re-plan Part A beats.
- **Plan.md B0 (`feel.gd`)** — NOT a blocker; the parent note says "leave until B0 lands." If `feel.gd` ships before Phase 3 is merged, migrate the new breakable tunables there; otherwise they stay local in `breakable.gd`.
- [[impl-system-combatant-ai]] — `combatant.gd` is the primary caller (`combatant.gd:221`); Phase 2 biome threading touches this caller.
- [[impl-system-biomes-decor]] — `DECOR_BREAKABLE` lives in `layout_loader.gd:64-65`; new biome breakable kinds are a data addition there, not a code change.
- [[impl-system-elites]] and [[impl-system-bosses]] — both route through `HitFeedback.play_hit`; magnitude scaling affects all tiers including their `super` hits.
- `DamageNumber.tscn` and `res://scenes/DamageNumber.tscn` — confirmed to exist (referenced at `combatant.gd:7`).
- `res://assets/vfx/soft_circle.png` — confirmed to exist (preloaded at `hit_spark.gd:7`).

---

## Tasks (ordered)

### Phase 1 — Magnitude-scaled damage numbers

**1. Add `_magnitude_scale` helper to `damage_number.gd`.**
File: `wyrd/scripts/damage_number.gd`, after line 11 (after `TIER_SCALE` const).
Add a static helper that maps raw damage to a log-based multiplier:

```gdscript
static func _magnitude_scale(amount: int) -> float:
    return clampf(1.0 + log(maxf(float(amount), 1.0)) * 0.11, 1.0, 1.6)
```

Returns ~1.0 for amounts 1–5, ~1.25 at 20, ~1.45 at 60. Keeps chip damage from competing visually with power hits.
_Verify:_ No suite touches `damage_number.gd` logic directly — run `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_dungeon_scene.gd`; must stay green (no parse errors). _Effort:_ S.

**2. Apply magnitude scale inside `setup()` in `damage_number.gd`.**
File: `wyrd/scripts/damage_number.gd:21`. Change line 21 from:

```gdscript
_base = TIER_SCALE.get(tier, 1.0)
```

to:

```gdscript
_base = TIER_SCALE.get(tier, 1.0) * _magnitude_scale(amount)
```

Tier scale multiplies magnitude scale — a super-crit big hit gets both boosts. `setup_apply` is unchanged (status verb floaters are always small).
_Verify:_ `test_wyrd_dungeon_scene.gd` green. In a live run: bleed tick (1-2 dmg) renders visibly smaller than a crit arrow (12–18 dmg) of the same tier color. Screenshot for the record. _Effort:_ S.

---

### Phase 2 — Biome-aware spark tints

**3. Add `BIOME_TINT` dict and update `spawn()` signature in `hit_spark.gd`.**
File: `wyrd/scripts/hit_spark.gd`. After line 13 (after `TIER_COLOR`), insert:

```gdscript
const BIOME_TINT: Dictionary = {
    "crypt":  Color(1.0,  1.0,  1.0),
    "forest": Color(0.70, 0.95, 0.60),
    "swamp":  Color(0.55, 0.80, 0.55),
}
```

Change `spawn` signature at line 15 from:

```gdscript
static func spawn(parent: Node, world_pos: Vector3, tier: String) -> void:
```

to:

```gdscript
static func spawn(parent: Node, world_pos: Vector3, tier: String, biome: String = "crypt") -> void:
```

In the body, change the color assignment (line 19) from:

```gdscript
var col: Color = TIER_COLOR.get(tier, TIER_COLOR["normal"])
```

to:

```gdscript
var tint: Color = BIOME_TINT.get(biome, Color.WHITE)
var col: Color = TIER_COLOR.get(tier, TIER_COLOR["normal"]) * tint
```

Then pass `col` through to `mat.albedo_color`, `mat.emission`, and `pm.color` exactly as before — those lines already reference the `col` variable, so no other lines change.
_Verify:_ `test_wyrd_dungeon_scene.gd` green (default `"crypt"` param keeps all existing callers identical). _Effort:_ S.

**4. Add `biome` parameter to `HitFeedback.play_hit()` and thread it to `spawn()`.**
File: `wyrd/scripts/hit_feedback.gd`. Change `play_hit` signature at line 45 from:

```gdscript
static func play_hit(target: Node3D, tier: String, from_dir: Vector3) -> void:
```

to:

```gdscript
static func play_hit(target: Node3D, tier: String, from_dir: Vector3, biome: String = "crypt") -> void:
```

Change the `HitSparkScript.spawn` call at line 61 from:

```gdscript
HitSparkScript.spawn(target.get_parent(),
    target.global_position + Vector3(0, 1.0, 0), tier)
```

to:

```gdscript
HitSparkScript.spawn(target.get_parent(),
    target.global_position + Vector3(0, 1.0, 0), tier, biome)
```

All existing call sites (`combatant.gd:183`, `combatant.gd:221`, `combatant.gd:249`) use the default `"crypt"` — no changes needed there. Future callers can pass the biome when a dungeon context is available.
_Verify:_ `test_wyrd_dungeon_scene.gd` green. Manual check: temporarily force `biome = "forest"` in one `play_hit` call in a live scene; sparks read visibly greener than crypt gold. Revert the force-call before committing. _Effort:_ S.

---

### Phase 3 — Breakable shatter polish

**5. Collect mesh children in `setup()` for flash support in `breakable.gd`.**
File: `wyrd/scripts/breakable.gd`. Add instance variables after line 11:

```gdscript
var _meshes: Array[MeshInstance3D] = []
var _flash_t: float = 0.0
var _flash_mat: StandardMaterial3D
```

At the end of `setup()` (after line 17, before the `hurt` Area3D block), add:

```gdscript
_flash_mat = StandardMaterial3D.new()
_flash_mat.albedo_color = Color.WHITE
_flash_mat.emission_enabled = true
_flash_mat.emission = Color.WHITE
_flash_mat.emission_energy_multiplier = 2.0
_flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
for child in get_children():
    if child is MeshInstance3D:
        _meshes.append(child as MeshInstance3D)
```

This mirrors `combatant.gd:158-170`; `breakable.gd` extends `StaticBody3D` so `_collect` recursion is not needed — the GLB instance is a direct child.
_Verify:_ `test_wyrd_dungeon_scene.gd` green; `setup()` call in `layout_loader.gd:585` is unchanged. _Effort:_ S.

**6. Add `_flash()` and `_process()` for pre-break hit-flash in `breakable.gd`.**
File: `wyrd/scripts/breakable.gd`. Insert after `setup()`:

```gdscript
func _flash(dur: float, col: Color = Color.WHITE) -> void:
    _flash_t = dur
    var mat := _flash_mat if col == Color.WHITE else StandardMaterial3D.new()
    if col != Color.WHITE:
        mat.albedo_color = col
        mat.emission_enabled = true
        mat.emission = col
        mat.emission_energy_multiplier = 2.0
        mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    for mi in _meshes:
        mi.material_override = mat

func _process(delta: float) -> void:
    if _flash_t > 0.0:
        _flash_t -= delta
        if _flash_t <= 0.0:
            for mi in _meshes:
                mi.material_override = null
```

`_process` restores the material after the flash expires; Godot calls it automatically because `breakable.gd` extends `StaticBody3D` (a `Node`).
_Verify:_ `test_wyrd_dungeon_scene.gd` green; `dead` guard in `take_damage` still prevents double-break. _Effort:_ S.

**7. Wire `_flash()` call into `take_damage()` in `breakable.gd`.**
File: `wyrd/scripts/breakable.gd:35`. In `take_damage`, after `hp -= 1` and before the `if hp <= 0` check, insert:

```gdscript
if not _meshes.is_empty():
    _flash(0.08, Color.WHITE)
```

This fires a half-frame white crack-cue on every hit — including the final hit that triggers `_break()` — so the player gets a visual signal even on a one-shot pottery jar. `dead` check at the top already guards re-entry.
_Verify:_ `test_wyrd_dungeon_scene.gd` green. Manual: shoot pottery — white flash appears before the shatter burst. _Effort:_ S.

**8. Add emission to shard particles in `_burst()` in `breakable.gd`.**
File: `wyrd/scripts/breakable.gd:73-76`. Replace the `StandardMaterial3D` block on the shard mesh. Change lines 73–76 from:

```gdscript
var pbm := StandardMaterial3D.new()
pbm.albedo_color = _break_color
pbm.roughness = 0.9
pmesh.material = pbm
```

to:

```gdscript
var pbm := StandardMaterial3D.new()
pbm.albedo_color = _break_color
pbm.roughness = 0.9
pbm.emission_enabled = true
pbm.emission = _break_color
pbm.emission_energy_multiplier = 1.8
pbm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
pmesh.material = pbm
```

Matte exterior (roughness 0.9) + emission makes shards read as glowing fragments rather than inert rubble. Mirrors `hit_spark.gd:47-50`.
_Verify:_ `test_wyrd_dungeon_scene.gd` green. Manual: shoot pottery — shards glow terracotta during flight. _Effort:_ S.

**9. Add micro camera shake after `_burst()` call in `breakable.gd`.**
File: `wyrd/scripts/breakable.gd:44`. In `_break()`, after `_burst()` and before `queue_free()`, insert:

```gdscript
var cr: Node = get_tree().get_first_node_in_group("camera_rig")
if cr != null and cr.has_method("shake"):
    cr.shake(0.06)
```

0.06 = the "normal" shake tier from `hit_feedback.gd:SHAKE_BY_TIER["normal"]` — the lowest tier, so it does not compete with a simultaneous arrow-impact shake on a nearby enemy.
_Verify:_ `test_wyrd_dungeon_scene.gd` green (headless has no camera_rig group — `get_first_node_in_group` returns null, guarded). Manual: shoot pottery — brief micro shake visible. _Effort:_ S.

---

### Phase 4 — Open data gap (non-blocking, do when new biome ships)

**10. Register new breakable kind(s) in `layout_loader.gd:DECOR_BREAKABLE` when a new biome lands.**
File: `wyrd/scripts/layout_loader.gd:64-65`. This is a **data gap, not a code gap** (noted in [[system-combat-juice-vfx]]). When `forest` or `swamp` biome ships, add:

```gdscript
"mossy_urn": Color(0.40, 0.55, 0.30),   # forest
"swamp_pot": Color(0.30, 0.45, 0.25),   # swamp
```

The matching biome tint in `hit_spark.gd:BIOME_TINT` (Task 3) will automatically make sparks match the new shard color. No code change needed here — this is a reminder for [[impl-system-biomes-decor]].
_Verify:_ N/A — this is a future-biome data patch; `test_wyrd_dungeon_scene.gd` exercises crypt only. _Effort:_ S (per biome).

---

## First commit (smallest shippable slice)

**Tasks 1 + 2 only** (`damage_number.gd` magnitude scaling).

Acceptance: `test_wyrd_dungeon_scene.gd` stays green, and in a live chart run a Bramble Snare bleed tick (1-2 dmg) renders noticeably smaller than a crit Power Shot (12-18 dmg) of the same tier color. Two-line change, no new files, no API surface changes.

---

## Test & verification plan

| Task | Suite / Check |
|------|---------------|
| 1, 2 | `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_dungeon_scene.gd` green; visual screenshot of small vs. large numbers in a live run |
| 3, 4 | `test_wyrd_dungeon_scene.gd` green; manual force-call `play_hit(…, "forest")`, screenshot greener sparks, revert before commit |
| 5, 6, 7 | `test_wyrd_dungeon_scene.gd` green; manual: flash appears before shatter burst |
| 8 | `test_wyrd_dungeon_scene.gd` green; manual: shards glow during flight |
| 9 | `test_wyrd_dungeon_scene.gd` green (null-guarded in headless); manual: micro shake on pottery break |
| all phases | `test_wyrd_loop.gd`, `test_wyrd_transitions.gd`, `test_skills.gd` — run the full four-suite battery before each phase merge; none of these suites touch VFX logic but parse errors in shared scripts can cascade |

No new headless logic tests are needed for these phases — all three gaps are visual-only (no game-state changes, no new branches in hit resolution). The existing `test_wyrd_dungeon_scene.gd` suite covers the `take_damage` → `_break` path for breakables and the `_spawn_damage_number` dispatch; its green state is a sufficient regression gate.

---

## Risks & open questions

1. **`_meshes` in `breakable.gd` populated via `get_children()` at `setup()` time** — the GLB is added as a child *before* `setup()` is called (see `layout_loader.gd:574`, `585`), so the walk should find it. If the GLB instantiates its `MeshInstance3D` nodes lazily (deferred), `_meshes` may be empty and the flash silently no-ops. Mitigation: fall back to `call_deferred("_collect_meshes")` if `_meshes` is empty after `setup()`.

2. **Biome threading decision (open, must decide before Phase 2 commit)** — the parent note flags this: should `biome` be read from a dungeon autoload, stored on each `Combatant`, or passed explicitly through `play_hit`? The explicit-parameter approach (Phase 2 above) is the simplest and keeps the signature honest. The autoload approach (`Game.current_biome`) would remove the parameter but couples `HitFeedback` to `Game`. Recommend explicit parameter; store `biome` on the `Combatant` node (set by `layout_loader`) so call sites stay as `HitFeedback.play_hit(self, tier, from_dir, biome)` without threading it through arrow.gd.

3. **`feel.gd` migration (non-blocking)** — Plan.md B0 calls for a central const bag. When `feel.gd` ships, the breakable tunables added in Tasks 5–9 (`_flash` duration, emission multiplier, shake strength) should migrate there. Until then they sit inline in `breakable.gd` as local consts.

4. **Pottery HP stays 1** — the parent note recommends keeping `HP = 1` until there is a design reason for a two-hit crack-then-shatter pattern. The `_flash()` call in Task 7 still fires on a one-shot jar (same tick as `_break()`), giving a flash+shatter on the same frame. If two-shot is desired later, bump `hp_in` in `layout_loader.gd:585` from `1` to `2` — no code changes needed.

5. **`_process` overhead on breakable props** — adding `_process` to every `StaticBody3D` breakable in the scene means Godot ticks them every frame. On a typical crypt room (2-4 pottery jars) the cost is negligible. If rooms ever have 20+ breakables, convert to `set_process(false)` by default and enable it only during `_flash`.

---

## Build status — 2026-06-16

**Phases 1–3 complete (Tasks 1–9). Phase 4 deferred (data gap, non-blocking).**

- **Task 1–2 (damage_number.gd):** `_magnitude_scale` static helper added; `setup()` now multiplies tier scale by magnitude scale. Chip damage (1–5) renders at ~1.0x, a 20-dmg hit at ~1.25x, 60-dmg at ~1.45x. `setup_apply` unchanged.
- **Task 3 (hit_spark.gd):** `BIOME_TINT` dict added (crypt/forest/swamp). `spawn()` signature extended with `biome: String = "crypt"` — all existing call sites unaffected by default. Tint is multiplied into `col` before being passed to both `ParticleProcessMaterial.color` and the `StandardMaterial3D` quad mesh.
- **Task 4 (hit_feedback.gd):** OUT OF SCOPE — `hit_feedback.gd` is not in the assigned scope. The `biome` parameter is plumbed into `HitSparkScript.spawn()` but the `hit_feedback.gd` caller update must be applied by the agent owning that file. Deferred.
- **Tasks 5–9 (breakable.gd):** `_meshes`, `_flash_t`, `_flash_mat` vars added. `setup()` builds the white flash material and walks `get_children()` to populate `_meshes`. `_flash()` and `_process()` added for timed material-override restore. `take_damage()` fires `_flash(0.08)` on each hit. `_break()` calls `get_first_node_in_group("camera_rig")` with a null-guard for headless. `_burst()` shard material gains `emission_enabled`, `emission = _break_color`, `emission_energy_multiplier = 1.8`, `SHADING_MODE_UNSHADED`.
- **Deferred:** Task 4 (`hit_feedback.gd` biome threading) — out of scope. Task 10 (layout_loader.gd new biome data) — out of scope / future-biome data gap.
