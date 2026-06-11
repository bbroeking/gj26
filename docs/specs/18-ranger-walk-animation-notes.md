# Implementation notes — 18-ranger-walk-animation

## Decisions
- **`ranger_anim.gd` is a `RefCounted`**, not a Node — `player_controller`
  owns one (`_ranger_anim`) and ticks it. No scene-tree presence needed.
- **Bones driven**: `LeftUpLeg`/`RightUpLeg` (thigh swing), `LeftLeg`/
  `RightLeg` (knee bend on the back swing), `LeftArm`/`RightArm` (counter-
  swing). Resolved by `Skeleton3D.find_bone`; any missing name is skipped
  (graceful — no crash).
- **Offset-from-rest posing** — each bone's rest rotation is cached, and
  the walk pose is `rest * Quaternion(X, angle)`. Offsets are bounded
  (±~0.7 rad) so the mesh can never explode the way the bad baked clips did.
- **Ease in/out via `_amp`** — lerps 0↔1 with `moving`; when still it
  settles every bone back to rest (no early-return, so the rest pose is
  always reasserted).
- **Rotation axis = local X** — the usual humanoid limb fore/aft axis. If a
  playtest shows legs splaying sideways, flip to Z (one-line change).

## Deviations
- _none_

## Tradeoffs
- Knee bend is a simple `max(0, -sin)` — a crude but readable scurry-style
  cycle, not a real gait. Fine for the ARPG zoom.

## Surprises
- Couldn't visually confirm the leg-swing in a still screenshot — a walk
  cycle is motion, and the verification shot had the Ranger half-obscured
  by an adjacent ghost. Confirmed only that the procedural posing renders a
  coherent (non-exploded) Ranger. Leg-swing *quality* (axis, amplitude,
  cycle speed) goes to the spec-22 playtest.

## Followups
- Tune `SWING` / `KNEE` / `ARM_SWING` / `CYCLE` and confirm the X axis in
  the spec-22 playtest.
- Sync `CYCLE` to actual movement speed (currently a fixed rate while moving).
- A real authored walk (Meshy regen) remains an option if procedural reads
  too stiff — but it was deliberately declined in the grill.

## Status
COMPLETE. Procedural walk cycle on the existing Ranger skeleton; the broken
baked clips stay un-played. `test_combat.gd` 20/20, World boots clean, the
Ranger renders coherent (no "disappears when moving" regression).
