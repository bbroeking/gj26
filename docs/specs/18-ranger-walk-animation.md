# 18 — Ranger walk animation (procedural)

> **Outcome**: the player Ranger walks — legs cycle and arms swing when moving, settling to rest when still — via **procedural per-frame bone rotation** of its existing skeleton. No Meshy, no new asset.

## Why

Spec 16 disabled the Ranger's animation: its baked walk/run *clips* fling the skeleton to garbage coordinates (the "disappears when moving" bug). But the **skeleton itself is fine** — the bind pose renders correctly. So the fix is to drive that working skeleton ourselves, the way the three.js game animates its characters (`src/anim/` — per-frame rotation of named limbs). Grill decision: procedural over a Meshy regen — free, immediate, no round-trip, no risk of a fresh rig landing equally broken.

## Scope

**In:**
- A **`ranger_anim.gd`** — a procedural walk-cycle driver for the Ranger's `Skeleton3D`:
  - On `_ready`, resolve the leg/arm bone indices by name (from the spec-14 probe: `LeftUpLeg`, `RightUpLeg`, `LeftLeg`, `RightLeg`, `LeftArm`/`LeftForeArm`, `RightArm`/`RightForeArm`, plus `Hips`/`Spine` for a body bob). Cache each bone's **rest rotation**.
  - Each frame: a walk phase advances with movement speed. Upper legs swing fore/aft on a sine, left/right in opposite phase; lower legs add a knee bend; arms swing opposite to the legs; a slight Hips bob. All as **offsets from the cached rest rotation** via `Skeleton3D.set_bone_pose_rotation`.
  - When still, the phase eases the bones back to rest (no hard snap).
- **Wire into `player_controller`** — instead of the removed `AnimDriver` call, tick `ranger_anim` with the `moving` flag + speed. Remove the spec-16 "stop the AnimationPlayer" workaround is kept (the broken clips must stay un-played) — procedural posing happens *on top of* the stopped AnimationPlayer.
- The bow rides `socket_hand_R` on the `RightHand` bone — rotating the arm bones carries the bow naturally; verify it still sits in the hand.
- Confirm the "disappears when moving" bug stays fixed (we never play the bad clips).

**Out:**
- Meshy regeneration / a new Ranger GLB.
- Attack / draw-bow / death animations — walk + rest only.
- Animating the enemies (rigged ones already animate; the rat is spec 21).
- Foot IK / ground adaptation.

## Files

| Path | Action |
|---|---|
| `godot/scripts/ranger_anim.gd` | new — procedural walk-cycle driver |
| `godot/scripts/player_controller.gd` | modify — tick `ranger_anim`; keep the AnimationPlayer stopped |
| `docs/GODOT_PIPELINE.md` | modify |

## Acceptance criteria

1. Moving, the Ranger's legs visibly cycle and arms swing.
2. Standing still, it settles to a clean rest pose (no jitter, no snap).
3. The player never disappears — moving, turning, firing.
4. The bow stays in the hand through the walk cycle.
5. `test_combat.gd` still passes; boots clean.

## Open decisions

- **Bone names** — taken from the spec-14 `test_walkanim.gd` probe; if a name differs, the driver resolves what it can and logs misses (degrade gracefully, don't crash).
- **Walk-cycle tuning** — swing amplitude, knee bend, body-bob height, cycle speed-vs-movement: first-pass values, tuned by eye / in the spec-22 playtest.
- **Skeleton pose API** — `set_bone_pose_rotation` each frame (recommended) vs a `SkeletonModifier3D`. Recommend the direct call — simple, matches the per-frame ethos.
- **Phase ease-out when stopping** — recommend lerping the phase amplitude to 0 over ~0.2 s so the legs glide to rest.

## References

- Spec 16 notes — broken-clip root cause; the AnimationPlayer is force-stopped
- Spec 14 `test_walkanim.gd` — the Ranger's bone names
- `src/anim/` (three.js) — the per-frame limb-rotation pattern this mirrors
- `player_controller.gd` — the disabled animation hook

## Done check

- [ ] `ranger_anim.gd` — procedural walk cycle on the existing skeleton
- [ ] Wired into `player_controller`; broken clips stay un-played
- [ ] Legs cycle when moving, settle when still
- [ ] No disappearing; bow stays in hand
- [ ] Evals pass; boots clean
