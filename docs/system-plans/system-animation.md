---
title: Animation (procedural + rig)
domain: Audio & Animation
type: system
status: partial
effort: M
tags: [wayfinder, plan]
---

# Animation (procedural + rig)

> Four complementary drivers are live and composing correctly; the next highest-value work is wiring gather arm-articulation (Plan.md Phase B1) and adding per-skill cast poses so non-shot abilities have a visible tell.

## Current state

**Player (chibi) — rigged, clip-driven + procedural overlay.**
`player_controller.gd` finds the chibi's `AnimationPlayer` at `_ready` (line 243) and resolves idle/walk/run clip names case-insensitively. A `BowDrawModifier` (`SkeletonModifier3D`) is added to the `Skeleton3D` at init (lines 248–249) and drives both arm bones toward a raised draw pose on each shot, blending additively over the playing locomotion clip (`bow_draw_modifier.gd` lines 28–37). Death is a procedural tween: squash + sink + `rotation.x` crumple, with the `AnimationPlayer` paused (`player_controller.gd` lines 781–815). The whole-mesh gather swing (forward lean on `rotation.x`, looped tween) is live at `begin_gather` (lines 920–970) — it rotates the **body mesh**, not the arm bones.

**Enemies and bosses — fully procedural (`creature_anim.gd`).**
`CreatureAnimScript` supersedes `RatAnimScript` for the entire enemy cast (`layout_loader.gd` lines 16–17, 962–967). `RatAnimScript` is imported but never instantiated; `creature_anim` handles every enemy including bosses (lines 683–688). The driver writes idle breathing + sway + hop-bob when moving + velocity lean, plus a full anticipation/lunge attack tell with ease-in wind-back and ease-out lunge (`creature_anim.gd` lines 68–136). Spawn pop-in (back-out overshoot from 0.01 scale over 0.28 s) and velocity lean (7°, `LEAN_ANGLE := 0.12`) are live (lines 25–65, 119–130). Per-creature phase offsets are deterministic (from spawn position, RNG-free, line 64).

**`ranger_anim.gd` — written, not wired.**
The full procedural walk-cycle driver for the Ranger NPC GLB (`ranger_anim.gd`) implements idle/walk/run/dash/roll leg cycles, arm counter-swing, spine lean, fire draw pose, and collapse (lines 1–103). It is **not instantiated anywhere** in the current codebase — `bow_draw_modifier.gd` (line 10) notes "the pose angle is ported from the (otherwise unused) ranger_anim fire pose." `anim_driver.gd` (lines 45–63) handles walk/idle switching for rigged GLBs via case-insensitive clip lookup; it is ticked from `combatant.gd` line 359 but not from `player_controller.gd`.

**Rigged GLBs exist but are not the primary path.**
`_resolve_model` in `layout_loader.gd` (lines 631–637) prefers `_rigged.glb` variants when they exist. Rigged files are present on disk (`enemy_skeleton_v1_rigged.glb`, `enemy_ghost_v1_rigged.glb`, `enemy_hedge_sprite_v1_rigged.glb`, `hedgemother_v2_rigged.glb`) but enemies universally fall back to procedural `creature_anim` because the Meshy auto-rig cannot pose non-humanoid or amorphous meshes (Plan.md §0). `test_anim.gd` probes these GLBs for clip names but is a standalone diagnostic, not part of the test suite.

**Blender clip easing is explicitly parked** (Plan.md §4 Parked section and §B parked).

## Gaps — what needs fleshing out

1. **[Blocker-adjacent] Gather arm-articulation missing.** `begin_gather` swings the whole mesh on `rotation.x` rather than driving arm bones through a `SkeletonModifier3D`. This is the most-repeated verb in the game and the gap is architecturally identical to the already-shipped bow-draw (Plan.md B1).
2. **No cast/spell pose for non-shot skills.** `Thornburst`, `BrambleSnare`, `RainOfThorns`, `HearthwoodWard` — none trigger an arm pose on the player. `Skill.fire()` has no animation hook; only `BasicShot` path fires `_bow_draw_t` (line 890 in `player_controller.gd`). Cozy-AoE skills are visually silent on the player body.
3. **`ranger_anim.gd` is dead code.** It implements a full procedural walk cycle but is never instantiated. Either wire it to the Ranger NPC (`npc_ranger_v5_rigged.glb`) or consolidate its fire-draw angle into `bow_draw_modifier.gd` and delete it.
4. **`rat_anim.gd` is superseded but not removed.** `RatAnimScript` is imported in `layout_loader.gd` (line 16) but never called — `creature_anim` handles all enemies including rats via the `bob` params table. This is dead weight.
5. **Phase 5 optional polish not complete.** Plan.md §4 Phase 5 notes land-squash on hop valleys, death-squash for enemies, and a player movement lean remain unshipped.
6. **No feel bench for cozy beats.** `animation_gallery.gd` covers the combat tell; Plan.md B-3 calls for a `WYRD_FEEL=<beat>` capture tool for gather/harvest/level-up/pickup, but `feel_bench.gd` does not exist yet.
7. **`anim_driver.gd` not connected to player.** `AnimDriver.update()` is ticked from `combatant.gd` for enemies; `player_controller.gd` uses its own inline clip management (lines 644–725). This is intentional divergence but means `AnimDriver` is enemy-only — worth documenting so it isn't accidentally re-wired.

## Plan

### Phase 1 — Gather arm-articulation (Plan.md B1 implementation)

*This is the Plan.md B1 phase translated to concrete file/function steps — the plan note for [[system-gathering]] cross-references this as the animation prerequisite.*

- Add `GatherSwingModifier` in `wyrd/scripts/gather_swing_modifier.gd` extending `SkeletonModifier3D`, mirroring `bow_draw_modifier.gd`'s structure. Drive `LeftArm` / `RightArm` bones through a mine/chop arc (tunable depth angle ~−0.9 rad for ore/log, ~−0.5 rad for forage) via `_process_modification()`.
- Add a `swing_amount` float (0..1); `begin_gather` in `player_controller.gd` creates the modifier on the `Skeleton3D` (sibling of `_bow_modifier`) and drives `swing_amount` on a per-kind sawtooth tween synced to the channel beat interval.
- Remove the whole-mesh `rotation.x` tween from `begin_gather` (lines 958–968) — the modifier replaces it. Keep the mesh facing-toward-node (line 938) and the tool-in-hand logic (lines 940–970).
- Read constants from `data/feel.gd` when it exists (Plan.md B0); stub inline constants in the modifier until `feel.gd` is built.
- **DoD:** arm bone visibly swings through the arc on each gather beat; legs/idle clip keeps playing underneath; whole-body tip is gone; screenshot via `WYRD_SHOT=1` mid-swing; four test suites green.
- **Clones:** `bow_draw_modifier.gd` (identical modifier shape). **Effort: M.**

### Phase 2 — Cast pose for non-shot skills

- Add a `_cast_pose_t := 0.0` float and `CAST_POSE_TIME := 0.18` constant to `player_controller.gd` (mirrors `_bow_draw_t`/`BOW_DRAW_TIME` at lines 67/93).
- In `_physics_process`, decay `_cast_pose_t` and apply it to `_bow_modifier.draw_amount` (or a new `_cast_modifier`) identically to the bow-draw path (line 424). This reuses the existing `BowDrawModifier` — non-shot skills raise the arms to ~40% of the full draw angle, which reads as "conjuring" rather than "shooting."
- In `Skill.fire()` (or as a player hook the hotbar calls before dispatching), set `_cast_pose_t = CAST_POSE_TIME` for skills whose `kind` is `"aoe"` or `"support"`.
- **DoD:** casting BrambleSnare, Thornburst, RainOfThorns, or HearthwoodWard visibly raises the player's arms; the pose decays within 0.2 s; Basic/Power/Multi Shot behavior is unchanged. Verified by screenshot mid-cast + test_skills.gd green.
- **Clones:** `_bow_draw_t` pattern in `player_controller.gd`. **Effort: S.**

### Phase 3 — Dead code cleanup

- Delete `rat_anim.gd` (superseded by `creature_anim.gd`); remove the `RatAnimScript` preload from `layout_loader.gd` line 16.
- Decide the fate of `ranger_anim.gd`: if the Ranger NPC will walk around town, wire it to `npc_ranger_v5_rigged.glb` from whatever script owns that NPC; if the Ranger NPC is static, delete `ranger_anim.gd` and note the fire-draw angle (`-1.0` rad) is already captured in `bow_draw_modifier.gd` line 12.
- Add a one-line comment to `anim_driver.gd` clarifying it is **enemy-only** (combatants only, not player) so future contributors don't re-wire it.
- **DoD:** `grep -rn "rat_anim\|RatAnimScript" wyrd/` returns zero hits (or only a deleted-file note); test suites green.
- **Effort: S.**

### Phase 4 — Phase 5 optional juice (Plan.md §4 remainder)

*These are the items Plan.md Phase 5 left as "remaining optional polish."*

- **Enemy death-squash:** in `combatant.gd`'s `_die()`, drive `_proc_anim` to a final wide-flat squash (scale X/Z ×1.3, Y ×0.2) before the body frees, using the existing `_back_out` easing curve from `creature_anim.gd` line 133.
- **Land-squash on hop valleys:** in `creature_anim.update()`, detect when `absf(sin(_phase))` crosses zero while moving (floor contact) and apply a brief scale squash (Y −0.08, X/Z +0.04) that self-restores over ~0.1 s.
- **Player movement lean:** mirror the `LEAN_ANGLE` pattern from `creature_anim.gd` line 119 onto the player `_mesh` node via `_anim_state`/`_play_anim` when `state == "run"`.
- **DoD:** enemy deaths have a visible floor-slap squash; running enemies show a discernible floor-contact bob; the player tilts slightly forward at run speed. Verified by `WYRD_GALLERY_ATTACK=1` extended frame + playtest.
- **Effort: S–M.**

### Phase 5 — Feel bench (Plan.md B-3)

*Infrastructure for verifying cozy-beat animation, required before B2/B5/B6 can be screenshot-verified.*

- Create `wyrd/tools/feel_bench.gd` + `feel_bench.tscn` (sibling of `animation_gallery`). Keys: `G` gather swing, `H` harvest pop, `L` level-up burst, `P` pickup suck, `C` craft react, `I` inscribe ritual.
- Add `WYRD_FEEL=<beat>` env var handling in `feel_bench.gd` that auto-triggers one beat then calls `WYRD_SHOT=1` to capture the key frame — mirrors `WYRD_GALLERY_ATTACK=1` pattern in `animation_gallery.gd` line 88.
- **DoD:** `WYRD_FEEL=gather WYRD_SHOT=1 godot --path wyrd res://tools/feel_bench.tscn` produces a screenshot showing the arm mid-swing; four test suites green.
- **Effort: S.**

## Dependencies & links

- [[system-gathering]] — Phase B1 gather arm-articulation lives at the intersection of these two systems; `begin_gather` / `end_gather` in `player_controller.gd` are the call sites.
- [[system-combat-juice-vfx]] — Plan.md Part A Phases 1–5 (SHIPPED) own combat hit-feel, attack tells, spawn pop-in, velocity lean. Do NOT duplicate. Cross-reference Plan.md Part A §2 table for the authoritative "what's done" list.
- [[system-player-controller]] — all player animation drives through `player_controller.gd`; the `_bow_modifier`, `_gather_tween`, `_bow_draw_t`, and `_mesh` transform writes all live here.
- [[system-skills-hotbar]] — the cast-pose gap (Phase 2) requires a hook between `Skill.fire()` dispatch and `player_controller._cast_pose_t`; the hotbar dispatch path is owned here.
- [[system-combatant-ai]] — `combatant.gd` ticks `AnimDriver.update()` (line 359) and calls `_proc_anim.attack()` / `_proc_anim.strike()` (lines 333–347); the procedural anim contract is defined by this note.
- [[system-audio-music]] — every new animation beat (gather swing, harvest pop, cast, level-up) needs a paired SFX stub via `tools/generate_audio.py`; Plan.md §3 cross-cutting rule.
- **Plan.md Part A** — combat animation Phases 1–5 are SHIPPED; do not replan them. The shared vocabulary (squash/stretch, two-layer transform split, event scale-punch) defined in §1/§3 is the foundation this note builds on.
- **Plan.md Part B** — B0 (`feel.gd` constants) must land before Phase 1 here reads from it; B1 (gather arm-articulation) is this note's Phase 1; B2 (harvest pop) depends on Phase 1.

## Verification

- **All phases:** `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_loop.gd` + `test_wyrd_dungeon_scene.gd` + `test_wyrd_transitions.gd` + `test_skills.gd` must stay green. Run from `wyrd/` directory.
- **Phase 1 gather arm:** screenshot mid-swing via `WYRD_SHOT=1 godot --path wyrd res://tools/feel_bench.tscn` once the feel bench exists; interim: `animation_gallery` with a gather trigger.
- **Phase 2 cast pose:** screenshot mid-cast + `test_skills.gd` green (the only suite that catches hotbar dispatch regressions).
- **Phase 3 cleanup:** `grep -rn "rat_anim\|RatAnimScript" wyrd/scripts/` returns no hits; four suites green.
- **Phase 4 juice:** `WYRD_GALLERY_ATTACK=1` screenshot shows enemy death-squash; playtest sign-off on felt timing.
- **Phase 5 feel bench:** `WYRD_FEEL=gather WYRD_SHOT=1 godot --path wyrd res://tools/feel_bench.tscn` exits with a screenshot in `/tmp/`.

## Open questions

1. **`ranger_anim.gd` fate:** should the Ranger NPC walk in town (wire `ranger_anim.gd`) or remain a static prop (delete it and keep only the fire-draw angle in `bow_draw_modifier.gd`)? The answer determines whether Phase 3 wires or removes this file.
2. **`anim_driver.gd` for rigged enemies:** the rigged GLBs (`enemy_skeleton_v1_rigged.glb` etc.) are loaded via `_resolve_model` but `creature_anim` still handles all enemies. Should rigged enemies play their baked `Idle` clip from `AnimDriver` *in addition to* the procedural overlay, or is procedural-only the permanent answer? (Plan.md §0 says procedural-only for now — confirm this is still the call.)
3. **`BowDrawModifier` reuse for cast pose (Phase 2):** the modifier drives both arms to a bow-draw angle. A "conjure" pose might want asymmetric arms (right arm raised, left lower). Should Phase 2 extend `BowDrawModifier` to accept a per-arm angle, or add a separate `CastPoseModifier`?
