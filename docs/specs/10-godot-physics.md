# 10 — Godot physics: real collision, not an infinite plane

> **Outcome**: the Godot crypt has honest collision. The player walks on actual floor tiles (not an infinite invisible plane), can't stroll out over the void, is stopped by walls *and* by the boss and decor props, and the movement constants are tuned so walking feels deliberate rather than skatey.

## Why

Spec 07's collision is a placeholder: one `WorldBoundaryShape3D` — an *infinite* ground plane — means the player can walk off the dungeon in any direction onto invisible floor forever. Walls collide, but enemies, the boss, and decor props are pure visuals you walk straight through. This spec makes the collision match what's actually on screen.

## Scope

**In:**
- **Floor collision = the floor tiles.** Replace the infinite `WorldBoundaryShape3D` with collision that exists only where `grid[y][x] == "floor"`. Two viable approaches (see Open decisions): a merged `ConcavePolygonShape3D` trimesh of all floor tiles, or one `StaticBody3D` + thin `BoxShape3D` per floor tile. Either way: step off the floor → there is nothing under you.
- **A kill-plane / respawn.** Because the floor now has edges, add a `WorldBoundaryShape3D` `Area3D` a few units below y=0; if the player falls into it, teleport them back to the entry tile. Cheap safety net.
- **Wall colliders** stay (already `StaticBody3D` from spec 07) — verify they're tight to the mesh.
- **Boss + enemy colliders.** Each spawned GLB gets a `StaticBody3D` (or `CharacterBody3D` later) wrapper with a capsule/box collider sized to its footprint, so the player is blocked by the Hedgemother and the crypt enemies instead of clipping through them.
- **Decor colliders.** Solid props (bookshelf, bones piles) get a simple box collider. Flat/ignorable decor can stay non-colliding — pick per kind.
- **Collision layers.** Define named layers — `world` (floor/walls/decor), `player`, `enemies` — and set each body's layer/mask so the rig is legible and future combat code has clean categories.
- **Movement tuning.** Revisit `SPEED`, `ACCEL`, `GRAVITY` in `player_controller.gd` so motion has a little weight; capsule radius/height and the +0.9 Y offset verified against the new floor height.

**Out (explicit non-goals):**
- Combat hit detection, damage, knockback, ragdoll.
- Enemy AI / enemy movement — enemies are static colliders for now.
- Moving platforms, doors, traps.
- Jumping (the dungeon is flat; no need yet).
- The three.js physics.

## Files

| Path | Action |
|---|---|
| `godot/scripts/layout_loader.gd` | modify — per-tile/merged floor collision, kill-plane Area3D, enemy/boss/decor colliders, collision layers |
| `godot/scripts/player_controller.gd` | modify — tune constants, kill-plane respawn hook, verify capsule fit |
| `godot/project.godot` | modify — name the collision layers under `[layer_names]` |
| `docs/GODOT_PIPELINE.md` | modify — note the collision model |

## Acceptance criteria

1. The player walks across floor tiles normally.
2. Walking the player past the edge of the floor — they fall (there is no floor over the void), and the kill-plane returns them to the entry tile within ~2 s.
3. The player is physically stopped by walls.
4. The player is physically stopped by the Hedgemother and by crypt enemies — no clipping through.
5. The player is stopped by solid decor (bookshelf); flat decor is intentionally pass-through and documented.
6. Collision layers are named in `project.godot` and each body sets its layer/mask deliberately.
7. Movement feels deliberate — no ice-skating — per the tuned constants.

## Open decisions

- **Floor collision shape.** (a) one merged `ConcavePolygonShape3D` built from all floor-tile quads — one body, efficient, but rebuilt each generation; (b) one thin `BoxShape3D` per floor tile under a single `StaticBody3D` — trivial to build, more shapes. At ~150 tiles either is fine; recommend (b) for simplicity, revisit if it ever shows up in the profiler.
- **Enemy collider shape.** Capsule sized from the GLB's AABB vs a plain box. Recommend capsule — characters are roughly cylindrical and it slides nicer.
- **Which decor is solid.** `bookshelf` solid; `bones` solid-ish (low box); `torch_wall` is wall-mounted — non-colliding. Notes record the final per-kind table.
- **Kill-plane depth.** Recommend y = -6. Far enough that a legitimate step-down never triggers it, close enough that a fall resolves fast.
- **Capsule offset.** Spec 07 used a +0.9 Y offset on the capsule. Verify it still seats the player on the new floor; adjust if the floor collider sits at a different height than the old infinite plane.

## References

- `godot/scripts/layout_loader.gd` — `_place_wall`, `_place_ground`, `_build_enemies`, `_build_boss`, `_build_decor`
- `godot/scripts/player_controller.gd` — `CharacterBody3D`, `move_and_slide`, `is_on_floor`
- Godot docs — `ConcavePolygonShape3D`, collision layers/masks, `Area3D` body-entered signal

## Done check

- [ ] Infinite ground plane replaced with floor-tile collision
- [ ] Kill-plane Area3D + respawn-to-entry
- [ ] Wall colliders verified
- [ ] Boss + enemy colliders
- [ ] Decor colliders (per-kind solid/pass-through table)
- [ ] Named collision layers in `project.godot`
- [ ] Movement constants tuned
- [ ] Collision model documented
