# Implementation notes — 10-godot-physics

## Decisions
- **Floor collision = one thin `BoxShape3D` per floor tile** (open-decision option b). Box `1 × 0.2 × 1`, top surface at y=0. ~150 tiny shapes under one `StaticBody3D` — trivial to build, fine at this scale.
- **Enemy/boss collider = capsule.** Fixed sizes: enemies radius 0.4 / height 1.4; boss radius 0.7 / height 2.0. Not AABB-derived — fixed is deterministic and good enough for a static blocker.
- **Decor solidity**: `bookshelf` solid (box 0.9×1.8×0.5), `bones` solid low box (0.8×0.4×0.8), `torch_wall` pass-through (wall-mounted, nothing to bump). Recorded per the spec's open decision.
- **Kill-plane at y = -6**, `Area3D` + `WorldBoundaryShape3D`. Player body entering it → teleport back to the stored entry tile.
- **Collision layers**: `world` = layer 1, `player` = layer 2, `enemies` = layer 3 (bit value 4). Player body: layer 2, mask = world+enemies (1|4=5). World/decor static bodies: layer 1. Enemy/boss bodies: layer 3. Camera SpringArm keeps mask = 1 (world only).
- **Movement tune**: SPEED 6.0 → 5.0, ACCEL 12 → 10, GRAVITY 20 → 22 — a touch slower and heavier so walking reads as deliberate.

## Deviations
- **`_place_ground()` deleted, not modified.** Spec framed it as "replace the infinite plane"; the cleaner result was to drop the function entirely and add `_build_floor_collision(grid)` as a distinct pass. The visual `_place_floor` planes are untouched.

## Tradeoffs
- **One `StaticBody3D` holding ~150 `CollisionShape3D` children** for the whole floor, vs one body per tile. Fewer bodies is lighter for the physics broadphase; the per-tile shapes still give honest edges. If a merged trimesh ever matters it's a localized change in `_build_floor_collision`.
- **Fixed capsule sizes for boss/enemies** rather than AABB-derived. The boss GLB is scaled 0.85 and enemy GLBs vary; a fixed capsule (boss 0.7×2.0, enemy 0.4×1.4) is a deterministic blocker that's "close enough" — exact footprint fitting isn't worth a per-GLB AABB pass for static blockers.

## Surprises
- _none — the build came up clean on the first run, no warnings, no runtime errors from the kill-plane signal or the new colliders._

## Followups
- **Kill-plane respawn is untested against an actual fall.** The `Area3D` + `body_entered` wiring is correct and boots clean, but I haven't driven the player off an edge to watch the respawn fire. Worth a manual check next play session.
- **Enemy/boss colliders are `StaticBody3D`** — fine as blockers, but when enemies get AI/movement (a later spec) they'll need to become `CharacterBody3D` or `AnimatableBody3D`. The `_spawn_character` helper is the single place to change.
- **No collision on flat decor by design** — `torch_wall` passes through. If wall torches ever read as floor clutter the player expects to bump, revisit `DECOR_COLLIDER`.
