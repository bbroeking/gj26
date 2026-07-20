# Player animation sidecar delivery record

Delivery audit: 2026-07-16.

## Purpose

The original Meshy exports each repeat the full rigged player mesh and texture.
For Web, Wayfinder ships one body GLB plus small same-skeleton animation GLBs.
Godot merges the named clips into the body's `AnimationPlayer` at runtime.

## Source and provenance

- Source files: `_ranger_v5_walk.glb`, `_ranger_v5_run.glb`,
  `player_chibi_v1_walk.glb`, and `player_chibi_v1_run.glb`.
- Provenance: derived only from project-owned Meshy animation exports; no new
  geometry, reference image, or third-party animation was introduced.
- Authoring tool: Blender 5.1.1 command-line export.
- Reproduction:

  ```bash
  /Applications/Blender.app/Contents/MacOS/Blender \
    --background --factory-startup \
    --python wyrd/tools/export_animation_sidecars.py
  ```

## Delivered files

| Output | Source | Bytes | Contract |
|---|---|---:|---|
| `ranger_walk_anim_v1.glb` | `_ranger_v5_walk.glb` | 35,052 | 25 nodes; one walk animation |
| `ranger_run_anim_v1.glb` | `_ranger_v5_run.glb` | 31,576 | 25 nodes; one run animation |
| `player_chibi_walk_anim_v1.glb` | `player_chibi_v1_walk.glb` | 34,908 | 25 nodes; one walk animation |
| `player_chibi_run_anim_v1.glb` | `player_chibi_v1_run.glb` | 31,424 | 25 nodes; one run animation |

All four outputs contain no `meshes`, `materials`, `textures`, or `images`
arrays. The Blender script fails delivery if render payload leaks in or if an
animation is missing.

## Runtime and QA contract

- Godot +Y up; imported bone names and hierarchy remain unchanged.
- `player_controller.gd` dynamically merges the first clip matching `walk` or
  `run`. Missing clips degrade to another available locomotion clip rather than
  leaving the player in a T-pose.
- The Web manifest ships the chibi body plus its two sidecars. Ranger sidecars
  remain available to native fallback builds but are not packed for Web.
- `test_wyrd_transitions.gd` verifies that the shipped sidecars have an
  `AnimationPlayer`, contain no `MeshInstance3D`, and merge as the live
  player's `walk` and `run` clips.
