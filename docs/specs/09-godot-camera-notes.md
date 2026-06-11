# Implementation notes — 09-godot-camera

## Decisions
- **Camera rig is a separate top-level node, not a child of Player.** The spec's open decision leaned "script on the existing CameraArm" — but a SpringArm parented to the player follows *instantly*, which contradicts the spec's hard requirement of *smooth* follow. The only way to lerp the follow is a rig that is NOT parented to the player. So: new `scenes/CameraRig.tscn` (pivot Node3D → SpringArm3D → Camera3D), added to `World.tscn`; `Player.tscn` loses its camera nodes.
- **Camera-relative movement: yes.** Open decision recommended it; implemented. `player_controller.gd` projects WASD onto the active camera's flattened forward/right each frame.
- **Pitch is positive.** SpringArm casts the camera along local -Z; a positive `rotation.x` tilts -Z up-and-back for a downward view. Range `[10°, 70°]`, default 35°. (The spec said "-10° to -70°" — sign was wrong in the spec; Godot's convention makes it positive. Recorded as a deviation.)
- **Orbit on right-mouse-drag**, Q/E for keyboard yaw — per the spec recommendation (keeps left-click free for future click-to-attack).
- **Zoom range** spring_length 4–14, step 1.5, default 9.

## Deviations
- **Pitch clamp sign flipped vs spec.** Spec wrote "-10° to -70°"; the working values are positive `+10°..+70°` because Godot's SpringArm + a downward view need positive `rotation.x`. Same intent, correct sign.
- **Player.tscn camera nodes removed.** Spec Files table said "modify Player.tscn — attach rig to CameraArm". Instead the camera left Player entirely (see Decisions — smooth follow demands it). `Player.tscn` is now just body + mesh + collision.

## Tradeoffs
- **Snap-on-first-frame.** The rig starts at world origin; the player spawns at the entry tile. A pure lerp would swoop the camera across the whole map on load. Added a one-shot `_snapped` flag that hard-sets position on frame 1, then lerps after. Cheap, removes the opening swoop.

## Surprises
- **`basis` is a reserved property name on `Node3D`** — a local `var basis` in `player_controller` shadowed it and warned. Renamed to `cam_basis`.
- **A hand-invented `uid://` triggers a load warning** until Godot's UID cache catches up. Dropped the `uid=` attribute from the `CameraRig` ext_resource in `World.tscn` — a path-only reference resolves cleanly every time. Same fix applies to any future hand-authored `.tscn` referencing another.
- **`InputEventKey.physical_keycode` wants the `Key` enum**, not a bare `int` — a `key: int` param on the bind helper warned. Typed it `key: Key`.

## Followups
- **No verification that orbit/zoom feel right** — the rig is wired and warning-free, but the actual feel (sensitivity, follow speed, pitch band) hasn't been tuned against a human hand. Tune the `const` block after a real play session.
- **Camera has no occlusion fade** — the SpringArm pulls the camera *in* at walls, but a wall directly between a mid-zoom camera and the player can still briefly clip. A material-fade or dither on occluding geometry is the polished fix; out of scope here.
