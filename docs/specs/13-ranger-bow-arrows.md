# 13 — Ranger as player: bow attached, arrows firing

> **Outcome**: in the Godot build the player **is the Ranger** — its bow is attached to its hand socket, and pressing the fire key looses an arrow that flies in the direction the Ranger is facing, travels, and despawns on hitting geometry or after its lifetime. Rigged and hooked in end to end.

## Why

The project already has a full Ranger asset set — `npc_ranger_body_v3.glb` and socket variants, `prop_bow_v1.glb`, `prop_arrow_v1.glb`, `prop_quiver_v1.glb`, ranger animations — built through the three.js `rig_test.html` socket sandbox. None of it is in the Godot build. This spec wires it in: the Ranger replaces the capsule/knight as the Godot player, the bow rides its hand socket, and arrow-firing works. It's the first real *weapon* mechanic in the Godot evaluation.

## Scope

**In:**

### A. Pick the Ranger GLB
- Inspect the candidates — `npc_ranger_body_v3.glb`, `npc_ranger_body_v2_sockets.glb`, `ranger_sockets_v1.glb`, `green_ranger_anims.glb`, `green_ranger_armature.glb`, `ranger_anim_v1.glb` — with the probe pattern (`test_anim.gd`): which has named **socket** nodes (hand / bow attach points) and which carries usable **animations**.
- Pick the one (or pair) that gives a Ranger with a hand socket. Document the choice + the socket node name(s) in notes.

### B. Ranger becomes the player
- Swap `Player.tscn`'s mesh (currently `knight_v4.glb`) for the chosen Ranger GLB, kept as the child node named `Mesh` so `player_controller.gd` keeps rotating it to face travel.
- Keep the `CharacterBody3D` + capsule collider + collision layers from spec 10.
- If the Ranger GLB has an `AnimationPlayer`, start its idle via `anim_driver.gd`.

### C. Attach the bow
- Instance `prop_bow_v1.glb` and parent it to the Ranger's hand **socket** node (found in step A). If the GLB has no usable socket, fall back to a hand-position offset and record it in notes.
- The bow should ride with the Ranger as it moves/turns.

### D. Arrow firing (`scripts/arrow.gd` + a fire hook in `player_controller.gd`)
- A `fire` input action (key — e.g. `F` or `Space`; not a mouse button, per the chosen design) registered programmatically like the movement keys.
- On fire, if a cooldown has elapsed:
  - Instance `prop_arrow_v1.glb`.
  - Spawn it at the bow's world position.
  - Orient + launch it along the Ranger's current facing direction (the `Mesh` node's yaw).
  - Add it to the world (not as a child of the player — it's independent once loosed).
- `arrow.gd` — moves the arrow forward each frame at `ARROW_SPEED`; despawns on `ARROW_LIFETIME` or on hitting world geometry (a short ray or an `Area3D` against the `world` collision layer).
- A fire cooldown (`FIRE_COOLDOWN`) so holding the key doesn't spew arrows.
- Tunables (arrow speed, lifetime, cooldown, spawn offset) in one `const` block.

### E. Docs
- Update `docs/GODOT_PIPELINE.md` Controls + a short "Ranger weapon" note.

**Out (explicit non-goals):**
- Damage / health / hit resolution — arrows fly and despawn; they do **not** hurt enemies yet.
- Enemy hit reactions, knockback.
- Aiming with the mouse / cursor-world raycast (the chosen design is key + facing direction).
- Ammo count / quiver depletion — infinite arrows for v1.
- A draw/aim/release animation on the Ranger — fire is instant for v1 (note it as a followup).
- The knight (spec 12) and the three.js game.
- Multiplayer, character switching.

## Files

| Path | Action |
|---|---|
| `godot/scenes/Player.tscn` | modify — Ranger GLB as `Mesh`, fire wiring stays in the controller |
| `godot/scripts/player_controller.gd` | modify — bow attach on `_ready`, fire input + cooldown, arrow spawn |
| `godot/scripts/arrow.gd` | new — arrow travel + despawn |
| `godot/scripts/anim_driver.gd` | reuse — idle for the Ranger if it has clips |
| `docs/GODOT_PIPELINE.md` | modify — controls + weapon note |

## Acceptance criteria

1. Launching `World.tscn`, the player is visibly the Ranger (not the knight/capsule).
2. The bow is attached to the Ranger's hand and moves/turns with it.
3. Pressing the fire key spawns an arrow at the bow.
4. The arrow travels in the direction the Ranger is facing.
5. The arrow despawns on hitting a wall and on lifetime expiry — no infinite/stuck arrows accumulating.
6. A fire cooldown prevents arrow spam from a held key.
7. The scene boots with no errors; arrows firing produce no runtime errors.
8. All arrow tunables are in one `const` block.

## Open decisions

- **Which Ranger GLB.** Determined by inspection in step A. Recommend the variant that has both named sockets and an `AnimationPlayer`; if those are split across two GLBs, use the socket body and accept a static Ranger for v1 (note it).
- **Socket discovery.** The three.js sandbox authored socket empties in Blender (`_sockets` GLBs). In Godot these import as child `Node3D`s with the authored names. If no socket node is found, fall back to a fixed local offset for the bow (e.g. `(0.25, 1.0, 0.1)` from the player root) — notes record which path was used.
- **Arrow physics.** Kinematic (script moves it, raycast for collision) vs `RigidBody3D` vs `Area3D`. Recommend **kinematic + a short raycast** — predictable, no physics-tuning rabbit hole, easy to despawn cleanly.
- **Fire key.** `F` vs `Space`. Recommend `F` (Space often reads as jump). Notes record.
- **Tuning.** Suggested starting values: `ARROW_SPEED` 18 m/s, `ARROW_LIFETIME` 3 s, `FIRE_COOLDOWN` 0.4 s. Tune after a playtest.
- **Fire direction when standing still.** The Ranger faces its last travel direction; the arrow uses the `Mesh` node's current yaw. If the Ranger has never moved, default facing is -Z. Acceptable.

## References

- Ranger assets: `models/npc_ranger_body_v3.glb`, `models/ranger_sockets_v1.glb`, `models/green_ranger_anims.glb`, `models/prop_bow_v1.glb`, `models/prop_arrow_v1.glb`
- Socket-attach prior art: the three.js `rig_test.html` sandbox + `docs/character-pipeline/MESHY_OPERATIONS.md`
- Godot player: `godot/scenes/Player.tscn`, `godot/scripts/player_controller.gd`
- Collision layers (spec 10): `world` = 1, `enemies` = 3 — arrows ray against `world`
- `anim_driver.gd` — idle helper from spec 11

## Done check

- [ ] Ranger GLB chosen + socket node identified (notes)
- [ ] Ranger is the Godot player, controllable, idle playing if rigged
- [ ] Bow attached to the hand socket, rides with the Ranger
- [ ] Fire key spawns an arrow at the bow
- [ ] Arrow flies along facing direction
- [ ] Arrow despawns on wall hit + on lifetime
- [ ] Fire cooldown works
- [ ] Tunables in one `const` block
- [ ] No boot/runtime errors
- [ ] `GODOT_PIPELINE.md` updated
