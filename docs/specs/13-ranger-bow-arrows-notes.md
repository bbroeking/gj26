# Implementation notes — 13-ranger-bow-arrows

## Decisions
- **Ranger GLB: `npc_ranger_body_v3.glb`.** The probe (`test_ranger.gd`) showed it's the only candidate with everything: a `Skeleton3D` (24 bones), `BoneAttachment3D` socket nodes, AND an `AnimationPlayer`. Socket tree: `RightHand → socket_hand_R`, `LeftHand → socket_hand_L`, `Spine01 → socket_back / socket_quiver`, `Head → socket_face`. Because the sockets hang off `BoneAttachment3D`s they track the skeleton through animation.
- **Bow attaches to `socket_hand_R`** (right-hand socket).
- **Animations: walking + running, NO idle.** Clips are `Armature|walking_man|baselayer` and `Armature|running|baselayer`. The Ranger has no idle clip — so `anim_driver.update()` plays `walking_man` while moving and **stops the AnimationPlayer (bind pose)** when still, rather than falling back to `running` (the first clip). Updated `anim_driver.gd` accordingly.
- **Fire key: `F`** (spec recommendation — Space reads as jump).
- **Arrow = kinematic** — `arrow.gd` moves it forward each physics frame and raycasts a short segment against the `world` layer; despawn on hit or lifetime. No `RigidBody3D` (avoids physics tuning).
- **Tuning start values**: `ARROW_SPEED` 18, `ARROW_LIFETIME` 3.0, `FIRE_COOLDOWN` 0.4 — per spec.

## Deviations
- Arrow tunables ended up in two `const` blocks, not one: `ARROW_SPEED`/`LIFETIME` in `arrow.gd`, `FIRE_COOLDOWN`/`ARROW_SPAWN_FWD` in `player_controller.gd`. They're different concerns (the projectile vs the shooter) and each file has a labelled block — acceptable, but the spec asked for one.

## Tradeoffs
- _none yet_

## Surprises
- **The Ranger has no idle animation** — only walk + run. `anim_driver.update()` plays `walking_man` while moving and stops the AnimationPlayer (bind pose) when still. A real idle is a followup.

## Status: WIRED, but TWO blocking bugs — not signed off

The plumbing is in and the scene boots with no errors (Ranger is the
player, bow-attach + arrow-fire code run clean). But two real defects came
up on visual inspection / from the user:

1. **The bow renders as a giant white orb.** `socket_hand_R` lives under a
   `BoneAttachment3D` inside the Ranger's `Skeleton3D`; the instanced
   `prop_bow_v1.glb` inherits a large bone-space scale and inflates into a
   huge pale blob covering the player. Fix: counter-scale the bow against
   the socket's world scale (or attach with `top_level` + manual transform).
2. **The player disappears when moving** (user-reported). Almost certainly
   the `walking_man` clip carries **root motion** — playing it translates
   the skeleton/root away from the `CharacterBody3D`, so the Ranger walks
   itself out of frame. Fix: strip the root-motion track, or route it
   through Godot's root-motion API instead of letting it move the mesh.

Both block spec-13 sign-off. Per the user's redirect they're folded into
the next grill + spec round (the disappearing-player bug is explicitly on
the user's list).

## Followups
- Real idle animation for the Ranger (Meshy `action_id 0`).
- The two bugs above.
- `prop_quiver_v1.glb` not used — could ride `socket_quiver` for visual completeness.
- Arrows don't damage enemies (out of scope here; combat is a separate spec).
