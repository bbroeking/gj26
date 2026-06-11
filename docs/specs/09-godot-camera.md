# 09 — Godot camera: a proper third-person rig

> **Outcome**: the Godot crypt has a real third-person camera — it follows the player smoothly, orbits with the mouse (or Q/E), zooms with the scroll wheel, clamps pitch to sane angles, and pulls in when a wall is between it and the player so you never see through geometry.

## Why

The spec 07 camera is a bare `SpringArm3D` at a fixed pitch with collision disabled — it sits at one frozen angle, can't be rotated or zoomed, and (collision off) happily renders from inside walls or outside the room. To actually play and evaluate the Godot build, the camera has to behave like a third-person game camera.

## Scope

**In:**
- A camera rig (`scripts/camera_rig.gd` on the `CameraArm` node, or a small dedicated scene) that:
  - **Smooth follow** — the rig's target position eases toward the player each frame (`lerp`), no hard snapping.
  - **Orbit** — hold right-mouse-drag to orbit yaw + pitch; also bind **Q / E** for keyboard yaw so it's usable without a mouse.
  - **Pitch clamp** — pitch limited to a sane band (e.g. -10° to -70°) so you can't flip under the floor or stare at the ceiling.
  - **Zoom** — scroll wheel adjusts `SpringArm3D.spring_length` between a min and max.
  - **Wall-aware** — re-enable `SpringArm3D` collision so the camera springs in when geometry is between it and the player (walls are `StaticBody3D` as of the physics work / spec 07).
- A sensible default: ~35° downward pitch, mid-zoom, framed behind the player.
- All tunables (follow speed, orbit sensitivity, pitch limits, zoom min/max/step) in one `const` block.

**Out (explicit non-goals):**
- First-person mode.
- Cutscene / cinematic cameras, camera shake, FOV punch.
- Click-to-move (that's a control scheme, not a camera; out of scope).
- Touching the three.js camera.
- Minimap / secondary viewports.

## Files

| Path | Action |
|---|---|
| `godot/scripts/camera_rig.gd` | new — follow + orbit + zoom + pitch clamp |
| `godot/scenes/Player.tscn` | modify — attach the rig script to `CameraArm`, re-enable its collision, set default transform |
| `godot/scripts/player_controller.gd` | modify only if movement needs to be camera-relative (see Open decisions) |
| `docs/GODOT_PIPELINE.md` | modify — update the Controls section with orbit/zoom |

## Acceptance criteria

1. Launching `World.tscn`, the camera frames the player from behind at a downward angle.
2. Moving the player — the camera follows smoothly with no snapping.
3. Right-mouse-drag orbits the camera around the player; Q/E also rotate yaw.
4. Pitch is clamped — you cannot rotate the camera below the floor or above the horizon past the configured limits.
5. Scroll wheel zooms between the configured min and max distance.
6. Walking the player so a wall sits between camera and player — the camera springs in instead of showing the player through the wall.
7. All camera tunables are in one labelled `const` block.

## Open decisions

- **Camera-relative movement.** Once the camera can orbit, "W = forward" should arguably mean "forward relative to where the camera faces", not world -Z. Recommend: yes, make `player_controller` movement camera-relative (project input onto the camera's yaw). It's a few lines and makes orbit actually usable. Notes record.
- **Orbit input.** Right-mouse-drag vs middle-mouse vs always-on. Recommend right-drag (doesn't fight a future click-to-move/attack on left click) + Q/E as the no-mouse path.
- **Rig as script-on-node vs separate scene.** Recommend script on the existing `CameraArm` `SpringArm3D` — least restructuring.
- **Zoom range.** Recommend spring_length 4–14, step 1.5. Notes record final.

## References

- `godot/scenes/Player.tscn` — current `CameraArm` (`SpringArm3D`) + `Camera3D`
- `godot/scripts/player_controller.gd` — movement (may go camera-relative)
- Godot `SpringArm3D` docs — `spring_length`, `collision_mask`, `margin`

## Done check

- [ ] Camera rig script created
- [ ] Smooth follow
- [ ] Orbit (right-drag + Q/E)
- [ ] Pitch clamp
- [ ] Scroll zoom
- [ ] Wall-aware spring (collision re-enabled)
- [ ] Tunables in one `const` block
- [ ] Controls doc updated
