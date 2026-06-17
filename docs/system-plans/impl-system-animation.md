---
title: Animation (procedural + rig) — Implementation Plan
parent: "[[system-animation]]"
domain: Audio & Animation
type: implementation-plan
status: ready-to-build
effort: M
tags: [wayfinder, impl]
---

# Animation (procedural + rig) — Implementation Plan

> Build doc for [[system-animation]]. Done when the gather verb drives arm bones (not the whole mesh), every non-shot skill raises the player's arms, dead code is excised, and the optional Phase 4/5 juice items are verified or explicitly deferred.

## Definition of done

- `GatherSwingModifier` drives `LeftArm`/`RightArm` through a per-kind arc on every gather beat; whole-body `rotation.x` tween is gone from `begin_gather`.
- Casting BrambleSnare, Thornburst, RainOfThorns, or HearthwoodWard visibly raises the player's arms; Basic/Power/MultiShot behavior is unchanged.
- `rat_anim.gd` is deleted; `RatAnimScript` preload removed from `layout_loader.gd`; all four headless suites stay green.
- `anim_driver.gd` carries a one-line enemy-only scope comment.
- `ranger_anim.gd` fate is decided (wire to NPC or delete).
- `wyrd/tools/feel_bench.gd` + `feel_bench.tscn` exist and `WYRD_FEEL=gather WYRD_SHOT=1` produces a mid-swing screenshot.

## Preconditions / dependencies

- [[impl-system-gathering]] — `begin_gather` / `end_gather` are the call sites for the new modifier; the `GatherNode` beat interval drives `swing_amount`. No code change needed on the gathering side as long as the call signatures stay the same.
- [[impl-system-skills-hotbar]] — the cast-pose hook (Phase 2) wires into `_try_skill()` in `player_controller.gd`; if the hotbar dispatch path changes, the hook site moves with it.
- [[impl-system-combat-juice-vfx]] — Part A (Phases 1–5) is **SHIPPED**; do not touch `hit_feedback.gd`, `hitstop.gd`, or the `creature_anim` attack-tell. Phase 4 below only extends `creature_anim` for death/hop.
- **Plan.md Part B** — B0 (`data/feel.gd`) must land before Phase 1 reads constants from it. Until B0 ships, stub constants inline in `gather_swing_modifier.gd` (the plan note explicitly says to). B1 is this Phase 1; B2 (harvest pop) depends on Phase 1 completing.
- **Missing file:** `wyrd/scripts/gather_swing_modifier.gd` does not exist — task 1 creates it.
- **Missing file:** `wyrd/data/feel.gd` does not exist — task 2 stubs it (or Phase 1 inlines constants until B0 ships).
- **Missing files:** `wyrd/tools/feel_bench.gd` and `wyrd/tools/feel_bench.tscn` do not exist — Phase 5 creates them.

---

## Tasks (ordered)

### Phase 1 — Gather arm-articulation (Plan.md B1)

**1. Create `gather_swing_modifier.gd`** — `wyrd/scripts/gather_swing_modifier.gd` (new file).
Mirror `bow_draw_modifier.gd` (38 lines). Extend `SkeletonModifier3D`; expose `swing_amount: float` (0..1) and `swing_angle: float` (set by caller per kind). In `_ready`, find `LeftArm`/`RightArm` on the `Skeleton3D` and cache rest-quaternions + a swing target using `Quaternion(Vector3.RIGHT, swing_angle)`. In `_process_modification()`, slerp each arm's current pose toward the target by `swing_amount` when `swing_amount > 0.001`.
```gdscript
const MINE_ANGLE := -0.9   # rad — ore / log arc
const FORAGE_ANGLE := -0.5 # rad — forage pluck
var swing_amount := 0.0
var swing_angle := MINE_ANGLE
```
_Verify:_ `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_loop.gd` (parse check; no instantiation yet). _Effort:_ S.

---

**2. Add `_gather_modifier` var + instantiate in `player_controller.gd:_ready`** — `wyrd/scripts/player_controller.gd` lines 93–95 (var block) and lines 245–250 (`_skel` block).
Add preload const at top of file (alongside `BowDrawModifier` at line 10) and the modifier var alongside `_bow_modifier`:
```gdscript
const GatherSwingModifier := preload("res://scripts/gather_swing_modifier.gd")
var _gather_modifier: SkeletonModifier3D = null
```
In `_ready` where `_bow_modifier` is added (lines 247–249), add the sibling:
```gdscript
_gather_modifier = GatherSwingModifier.new()
_skel.add_child(_gather_modifier)
```
_Verify:_ `test_wyrd_loop.gd` + `test_wyrd_dungeon_scene.gd` green. _Effort:_ S.

---

**3. Wire `begin_gather` to drive `_gather_modifier` on a sawtooth tween** — `wyrd/scripts/player_controller.gd` lines 934–969 (`begin_gather`).
Replace the whole-body `rotation.x` tween block (lines 958–969) with a tween that drives `_gather_modifier.swing_amount`:
- Set `_gather_modifier.swing_angle` to `MINE_ANGLE` (or stub constant) for `ore_rock`/`log_pile`, `FORAGE_ANGLE` for `forage_node`.
- Sawtooth: tween `swing_amount` 0→1 over `beat * 0.4` (ease-in QUAD), then 1→0 over `beat * 0.6` (ease-out QUAD), looped — same beat values already computed at lines 960–963.
- Keep `_mesh.rotation.y` facing logic (line 938), tool-in-hand logic (lines 940–955), and the tool `rotation.x` tween at lines 965–969 (the tool swing is fine).
- Remove ONLY the `_mesh, "rotation:x"` tween lines (961–964).
_Verify:_ `test_wyrd_dungeon_scene.gd` green; interim screenshot by running the game and pressing G near a gather node. _Effort:_ S.

---

**4. Reset `_gather_modifier` in `end_gather`** — `wyrd/scripts/player_controller.gd` lines 971–981 (`end_gather`).
After killing `_gather_tween`, also reset the modifier:
```gdscript
if _gather_modifier != null:
    _gather_modifier.swing_amount = 0.0
```
Remove the `_mesh.rotation.x = 0.0` line (976) — the modifier reset handles arm cleanup; the mesh itself no longer tips.
_Verify:_ Arms return to rest pose after channel ends. `test_wyrd_loop.gd` green. _Effort:_ XS.

---

### Phase 2 — Cast pose for non-shot skills

**5. Add `_cast_pose_t` + `CAST_POSE_TIME` to `player_controller.gd`** — lines 67–93 (constants/vars block).
```gdscript
const CAST_POSE_TIME := 0.18   # arm-raise duration for non-shot skills
var _cast_pose_t := 0.0
```
In `_physics_process`, in the existing `_bow_draw_t` decay block (lines 422–424), add parallel decay and modifier write:
```gdscript
_cast_pose_t = maxf(0.0, _cast_pose_t - delta)
if _bow_modifier != null:
    _bow_modifier.draw_amount = maxf(
        _bow_draw_t / BOW_DRAW_TIME,
        (_cast_pose_t / CAST_POSE_TIME) * 0.4  # 40% of full draw = "conjure" pose
    )
```
_Verify:_ Existing BasicShot bow-draw is unaffected (bow_draw_t overrides). `test_skills.gd` green. _Effort:_ S.

---

**6. Set `_cast_pose_t` in `_try_skill` for non-projectile skills** — `wyrd/scripts/player_controller.gd` lines 896–914 (`_try_skill`).
After `skill.fire(self)` at line 913, add:
```gdscript
if slot != 1:   # slots 2-4 are non-shot skills
    _cast_pose_t = CAST_POSE_TIME
```
This fires for BrambleSnare, Thornburst, RainOfThorns, HearthwoodWard. BasicShot at slot 1 routes through `_fire_buffer` and never reaches this line.
_Verify:_ `test_skills.gd` green (the only suite that exercises the hotbar dispatch path). Playtest: cast slot 2–4 and observe arm raise that decays within ~0.2 s. _Effort:_ XS.

---

### Phase 3 — Dead code cleanup

**7. Remove `RatAnimScript` preload from `layout_loader.gd`** — `wyrd/scripts/layout_loader.gd` line 16.
Delete: `const RatAnimScript = preload("res://scripts/rat_anim.gd")`.
Confirm `RatAnimScript` is not referenced anywhere else:
```bash
grep -rn "RatAnimScript\|rat_anim" wyrd/scripts/
```
_Verify:_ grep returns zero hits; `test_wyrd_dungeon_scene.gd` green. _Effort:_ XS.

---

**8. Delete `rat_anim.gd`** — `wyrd/scripts/rat_anim.gd`.
The class is a 41-line subset of `creature_anim.gd`; `CreatureAnimScript` handles all enemies including rats via the `bob` params table (`layout_loader.gd` line 963–966). After task 7 confirms no live references, delete the file.
_Verify:_ `grep -rn "rat_anim" wyrd/` returns zero hits. All four suites green. _Effort:_ XS.

---

**9. Decide `ranger_anim.gd` fate and act** — `wyrd/scripts/ranger_anim.gd`.
Decision gate (user): if the Ranger NPC walks in town → wire `ranger_anim.gd` to the NPC's `Skeleton3D` in `quill_npc.gd` or `wayfinder_npc.gd`; if static → delete. Either way:
- If **deleting**: confirm `bow_draw_modifier.gd` line 12 (`DRAW_ANGLE := -1.0`) already captures the fire-draw angle sourced from `ranger_anim.gd` line 78 (arms at -1.0 rad). Delete file; run grep.
- If **wiring**: add `var _ranger_anim = preload("res://scripts/ranger_anim.gd").new()` to the NPC script; call `_ranger_anim.setup(_skel)` in `_ready`; call `_ranger_anim.update(delta, state)` each frame.
_Verify:_ `grep -rn "ranger_anim" wyrd/scripts/` shows either zero hits (deleted) or exactly the NPC file (wired). All four suites green. _Effort:_ S (either path).

---

**10. Add enemy-only scope comment to `anim_driver.gd`** — `wyrd/scripts/anim_driver.gd` line 1 (file header).
Insert after the existing comment block:
```gdscript
# SCOPE: enemy / combatant GLBs only. player_controller.gd manages the
# player's clips inline (see _play_anim). Do NOT re-wire this to the player.
```
_Verify:_ No functional change; parse check passes. _Effort:_ XS.

---

### Phase 4 — Optional juice (Plan.md §4 Phase 5 remainder)

**11. Enemy death-squash in `combatant.gd:_die()`** — `wyrd/scripts/combatant.gd` (find `_die()` function).
After the body detaches from physics, drive a final wide-flat squash on `_proc_anim._node` using the same `_back_out` easing from `creature_anim.gd` line 133 — a brief tween to `Vector3(base.x * 1.3, base.y * 0.2, base.z * 1.3)` over 0.18 s then `queue_free`. Use `create_tween()` on the body node.
_Verify:_ `WYRD_GALLERY_ATTACK=1 godot --path wyrd res://tools/animation_gallery.tscn` screenshot shows floor-slap squash at enemy death. _Effort:_ S.

---

**12. Land-squash on hop valleys in `creature_anim.gd:update()`** — `wyrd/scripts/creature_anim.gd` lines 113–118 (moving branch).
Detect floor contact when `sinf(_phase)` crosses zero while `moving` is true. On crossing, apply a brief `Vector3(base.x * 1.04, base.y * 0.92, base.z * 1.04)` squash that self-restores to `_base_scale` via `lerp` over `~0.1 s` (fold into the existing per-frame lerp at line 116 by checking `absf(sinf(_phase)) < 0.08`).
_Verify:_ Playtest; running enemies show a visible bob double. `test_wyrd_dungeon_scene.gd` green. _Effort:_ S.

---

**13. Player movement lean** — `wyrd/scripts/player_controller.gd` (`_play_anim` or the velocity-update section, ~line 644).
Mirror `creature_anim.gd`'s `LEAN_ANGLE` pattern: add a `_player_lean: float` var; in `_physics_process`, when `state == "run"` lerp `_player_lean` toward `LEAN_ANGLE` (import from `creature_anim` or redeclare as `const PLAYER_LEAN := 0.10`); else lerp back to 0. Write to `_mesh.rotation.x` when `_mesh != null and not dead` (below the flinch block at lines 428–436).
_Verify:_ Playtest: player tilts forward at run speed, snaps upright when stopping. `test_wyrd_loop.gd` green. _Effort:_ S.

---

### Phase 5 — Feel bench (Plan.md B-3)

**14. Create `wyrd/tools/feel_bench.gd`** — new file, sibling of `animation_gallery.gd`.
Minimal headless-safe implementation. Key map: `G` gather swing, `H` harvest pop (stub), `L` level-up (stub), `P` pickup (stub), `C` craft (stub), `I` inscribe (stub). On `G`: spawn the chibi, call `begin_gather("ore_rock", Vector3(2,0,0))` and tween. Env var `WYRD_FEEL=<beat>` auto-triggers the beat then calls `get_viewport().get_texture().get_image().save_png("/tmp/wyrd_feel_<beat>.png")` and quits — mirrors `animation_gallery.gd` lines 88–99.
_Verify:_ `WYRD_FEEL=gather WYRD_SHOT=1 godot --path wyrd res://tools/feel_bench.tscn` produces `/tmp/wyrd_feel_gather.png` showing arm mid-swing. _Effort:_ S.

---

**15. Create `wyrd/tools/feel_bench.tscn`** — new scene file.
Minimal: a `Node3D` root with `feel_bench.gd` attached, a `Camera3D` positioned at `(0, 1.4, 4.0)` looking at `(0, 1.0, 0)`, a flat floor `MeshInstance3D` (same pattern as `animation_gallery.tscn`). Add a point light so the chibi's ink outline reads in the screenshot.
_Verify:_ Scene opens without errors in `godot --path wyrd res://tools/feel_bench.tscn`. All four suites green (scene not in test path). _Effort:_ XS.

---

## First commit (smallest shippable slice)

**Tasks 1–4** (Phase 1 complete): `gather_swing_modifier.gd` created; `_gather_modifier` added to `player_controller.gd`; arm bones drive the swing; whole-body tip removed from `begin_gather`; modifier resets in `end_gather`.

Acceptance: run the game, gather any ore node, observe arm bones articulating through the swing arc while legs and idle clip continue underneath. `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_dungeon_scene.gd` green.

---

## Test & verification plan

| Phase | Suite / check |
|---|---|
| Phase 1 (gather arm) | All 4 headless suites green; playtest gather to eyeball arm arc vs. tool swing sync |
| Phase 2 (cast pose) | `test_skills.gd` green (hotbar dispatch path); playtest slot 2–4 to see arm raise + decay |
| Phase 3 (cleanup) | `grep -rn "rat_anim\|RatAnimScript" wyrd/scripts/` → zero hits; all 4 suites green |
| Phase 4 (juice) | `WYRD_GALLERY_ATTACK=1 godot --path wyrd res://tools/animation_gallery.tscn` screenshot; playtest sign-off on hop-bob timing |
| Phase 5 (feel bench) | `WYRD_FEEL=gather WYRD_SHOT=1 godot --path wyrd res://tools/feel_bench.tscn` → `/tmp/wyrd_feel_gather.png` exists showing arm mid-arc |

**Headless suites** (run from `wyrd/` with `WYRD_NO_SAVE=1`):
```bash
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_transitions.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd
```
All four must stay green at the end of every phase. `test_skills.gd` is the single suite that catches hotbar dispatch regressions (frozen-hotbar regression shipped once without it — do not skip).

---

## Risks & open questions

1. **`ranger_anim.gd` fate (task 9 gate):** user decision required before task 9 can execute. Options and consequences documented in task 9 above. Default recommendation: delete (the fire-draw angle is already preserved in `bow_draw_modifier.gd:DRAW_ANGLE`).

2. **`BowDrawModifier` reuse for cast pose:** Phase 2 drives `_bow_modifier.draw_amount` to 40% for conjure poses (task 5). This is asymmetric vs. the bow-draw's 100%. If a future cast pose needs per-arm asymmetry (right arm raised, left lower), `bow_draw_modifier.gd` will need a `left_amount`/`right_amount` split or a separate `CastPoseModifier`. For now the symmetric 40% reads as "hands coming up to conjure" — acceptable.

3. **`_gather_modifier` on non-chibi fallback:** the modifier is only added when `_skel != null` (task 2 mirrors the `_bow_modifier` guard at `player_controller.gd:245–249`). On the legacy ranger mesh the arm-bone articulation silently no-ops — the whole-body tip removal in task 3 means the ranger fallback has no gather animation at all until it's also rigged. Acceptable for now; document in a comment.

4. **Plan.md B0 (`feel.gd`):** tasks 1–4 stub constants inline in `gather_swing_modifier.gd`. When B0 ships, move `MINE_ANGLE`/`FORAGE_ANGLE`/`CAST_POSE_TIME` into `data/feel.gd` and replace the inline consts. This is a mechanical refactor; no behavior change.

5. **Phase 4 enemy death-squash scope:** task 11 requires locating `_die()` in `combatant.gd` (not read above). If the death path calls `queue_free()` immediately rather than after a tween, the squash tween must complete before free. Use `queue_free` on tween completion callback, not before it.

---

## Build status — 2026-06-16

**Phase 1, Task 1 — DONE.**

`wyrd/scripts/gather_swing_modifier.gd` created (61 lines). Mirrors `bow_draw_modifier.gd` structure: extends `SkeletonModifier3D`, caches `LeftArm`/`RightArm` bone rest quaternions in `_ready`, blends each arm toward a swing target in `_process_modification` when `swing_amount > 0.001` (no-op at 0 preserves locomotion clip).

Public API delivered:
- `swing_amount: float` — 0..1, tweened per gather beat by `player_controller.gd`
- `swing_angle: float` — arc magnitude in radians; direct write or via `mode`
- `mode: String` — `"mine"` / `"chop"` (→ `MINE_ANGLE = -0.9 rad`) or `"forage"` (→ `FORAGE_ANGLE = -0.5 rad`); setter writes `swing_angle` immediately
- `MINE_ANGLE` / `FORAGE_ANGLE` constants inlined (Plan.md B0 / `data/feel.gd` not yet shipped)

Design note: target quaternion is recomputed each `_process_modification` call (not cached at `_ready` time) so that a `swing_angle` / `mode` change mid-beat takes effect without a restart. Cost is one `Quaternion` multiply per arm per frame during gather — negligible.

Tasks 2–4 (wiring into `player_controller.gd`) remain out of scope for this agent turn and are deferred to the next task slice.
