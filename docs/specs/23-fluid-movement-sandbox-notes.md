# Implementation notes — 23-fluid-movement-sandbox

## Decisions
- **Movement state machine** = `enum Move { NORMAL, DASH, ROLL }` on
  `player_controller`. NORMAL covers idle/walk/run (one locomotion state, a
  speed); DASH and ROLL are timed bursts that lock the direction and lock
  out fire. The anim *state* string (`idle/walk/run/dash/roll`) is derived
  separately and passed to the animator.
- **Keys** — walk = hold `Shift`, dash = `Space`, roll = `Ctrl`, fire = `F`,
  move = WASD/arrows. Always-run; Shift slows to a walk (the grill lean).
- **Burst movement is instant** — dash/roll set `velocity` directly (no
  lerp); the snap *is* the responsiveness. NORMAL keeps the eased lerp.
- **Roll tumble** = `player_controller` spins the whole `Mesh` node a full
  `TAU` about local X over `ROLL_TIME` — a clean read, and it sidesteps
  trying to tumble a procedural skeleton. `ranger_anim` just tucks the limbs.
- **Roll i-frames** reuse the existing `_iframe_t` — roll sets it to
  `max(_iframe_t, ROLL_IFRAMES)`, so the same field serves hit-i-frames and
  dodge-i-frames.
- **Projectile rework** — arrow `SPEED` 18→28, a warm emissive streak so
  the shot reads, a bow-flex scale-pop on fire, and a brief arm draw-pose
  (`ranger_anim.trigger_fire()`).
- **Dummies are Combatants** — so arrows hitting them show the real feedback
  (flash / damage numbers / knockback); placed beyond aggro range so they
  stay put until you walk over.

## Deviations
- The spec is `/goal`-d as "produce a plan"; the user then said go, so this
  pass *implemented* it (sandbox + state machine + animator + projectile +
  evals), not just planned.

## Tradeoffs
- The fire draw-pose is crude (both arms snap to one angle for 0.28 s) — a
  real nock-draw-release would need more bones/keys; fine at the ARPG zoom.
- Dash and roll can't interrupt each other (you commit to one) — simpler,
  and avoids cancel-spam.

## Surprises
- **No Ranger GLB has working baked clips** — probed all three in planning:
  `npc_ranger_body_v3` and `ranger_anim_v1` both explode the skeleton,
  `green_ranger_anims` is degenerate + meshless. Confirmed the all-
  procedural path; `AnimationTree` was never an option.

## Death animation (added on request)
- **Crumple + sink + Pokémon white-out.** `_die()` plays a procedural
  death: `ranger_anim.collapse()` poses the limbs into a heap, a tween
  squashes the Mesh (scale.y → 0.3×), sinks it (y → −1.1), and tilts it;
  the `PlayerHUD` `Whiteout` ColorRect fades the screen to full white; the
  respawn (teleport + restore) happens *under* the white; then it fades
  back. The white-out reuses the spec-15 HUD pattern (a second ColorRect,
  drawn last so it covers the HP bar too).
- The crumple animates the **Mesh node**, not the body — the camera
  follows the body, so sinking the body would drag the camera down.

## Bow + fire follow-ups (on request)
- **Bow scaled to 0.5×** — the `prop_bow_v1.glb` GLB is ~1.9 m (taller than
  the 1.7 m Ranger); scaled down so the Ranger reads larger. `BOW_SCALE` /
  `BOW_OFFSET` / `BOW_ROT_DEG` are tunable consts in `player_controller`.
- **Bow anchor** — a probe showed the bow GLB's origin *is* its geometric
  centre (centre ≈ 0,0,0), so parenting it to `socket_hand_R` already grips
  it at the core middle; no offset needed (`BOW_OFFSET` stays 0).
- **Fire direction** — `_fire_arrow` now fires the *held* movement
  direction (and snaps the Ranger to face it); falls back to the current
  facing when standing still. Was: the lerped mesh yaw, which lagged.

## Meshy archer Ranger (option B — user-requested, ~43 credits)
- **A fresh Meshy Ranger replaces the procedural-animated one.** Pipeline:
  `text_to_3d` (t-pose) → `refine` (texture) → `remesh` (784K→50K) → `rig`
  → `animate` (idle). Rigged cleanly — no "pose estimation failed".
- **Correction:** the first clip probe wrongly read "BROKEN" — it measured
  the Meshy rig's ~160-unit *internal* skeleton space. In **world** space
  all three clips (idle/walk/run) span a sane ~1.8 m. They work.
- **Clip merge** — the three Meshy GLBs are each `mesh + one clip`.
  `player_controller._setup_clips()` loads the walk + run GLBs and copies
  their `Animation` resources into the idle GLB's `AnimationPlayer` library
  (same rig → compatible). The player is now **clip-based** (idle/walk/run
  via `AnimationPlayer`), not procedural — `ranger_anim.gd` is retired for
  the player (the rat still uses `rat_anim.gd`).
- **Bow** — the Meshy rig has no authored socket, so the bow rides the
  **`RightHand` bone**: parented to the player (normal scale, dodging the
  skeleton's internal scaling), repositioned each frame from the bone's
  world transform (`_update_bow`).
- Dash → run clip; roll → run clip + the mesh-tumble; death crumple +
  white-out unchanged (mesh-node tween, animation-independent).

## Followups
- **Web export whitelist** — `npc_ranger_v5_rigged.glb`, `_ranger_v5_walk.glb`,
  `_ranger_v5_run.glb` must be added to `export_presets.cfg` before the next
  browser build.
- Tune `BOW_SCALE` / `BOW_ROT_DEG` and the bow's hand-tracking by eye.
- `npc_ranger_body_v3.glb` + `ranger_anim.gd` are now orphaned for the
  player — safe to leave; `calibration.gd` still points at the old ranger.
- A play-test of the clip animation feel (walk/run cadence, crossfades).
- Tune every movement constant in a play session (speeds, dash/roll
  distances + cooldowns, cycle rates, lean angles, fire pose).
- Confirm the procedural-anim X rotation axis reads right (legs swing
  fore/aft, not splay) — same open item as spec 18.
- The dungeon — rooms/hallway sizing + GLB-built walls — a separate spec
  (deferred per the user; their grievances are recorded for it).

## Status
COMPLETE. `Sandbox.tscn` (flat arena, dummies) + a walk/run/dash/roll state
machine + state-driven procedural animation + the projectile rework.
`test_movement.gd` 6/6; `test_combat.gd` still 20/20; sandbox boots clean.
Ready for a feel play-test.
