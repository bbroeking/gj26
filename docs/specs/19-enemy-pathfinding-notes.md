# Implementation notes — 19-enemy-pathfinding

## Decisions
- **Navmesh built directly from the tile grid**, not baked. `_build_navmesh`
  assembles one quad per `"floor"` tile into a `NavigationMesh` via a shared
  vertex pool (grid corners keyed by `Vector2i`) — adjacent tiles share
  corner vertices, so the polygons connect natively with no
  `edge_connection_margin`. Deterministic, no rasterization, no procgen
  bake-timing fuss.
- **Straight-line fallback kept.** `combatant.gd` chase tries the
  `NavigationAgent3D` path; if `get_next_path_position()` yields no usable
  step (no navmesh, path not yet computed, off-mesh) it falls back to
  heading straight at the player. This keeps the eval harness working (it
  builds combatants with no navmesh) and is a sane in-game safety net.
- **Re-target at 4 Hz** (`CHASE_REPATH = 0.25`) — the player doesn't
  teleport; cheap and smooth.

## Deviations
- Direct-build navmesh means **no agent-radius inset** — paths can run flush
  against walls, so enemies may visually graze a corner. Acceptable for the
  vertical slice (the goal — route *around* walls instead of jamming — is
  met); a baked navmesh would inset but reintroduces bake complexity.

## Tradeoffs
- Avoidance left **off** (`avoidance_enabled = false`) — enemy↔enemy
  overlap stays allowed (spec 15). Adding RVO is a separate concern.

## Surprises
- **The F7 eval failed first because the test player fell.** The harness
  builds no floor collision, so a `PlayerScene` instance dropped to Y=−100;
  its position became the nav target → off-mesh → garbage path. Fix: F7
  uses a plain non-falling `Node3D` in group `"player"` as the chase
  target, and frees the F1–F6 players first (the chaser finds its target
  via the group, tree-wide).

## Followups
- Baked navmesh with agent-radius inset, if corner-grazing reads badly.
- The Hedgemother boss (spec 17) inherits this `NavigationAgent3D` chase —
  no extra work expected.

## Status
COMPLETE. Navmesh built from the crypt floor (≈297 tiles), enemy chase
follows it, straight-line fallback intact. `test_combat.gd` 16/16 (F7 added:
nav path routes around an L corner — 6.4 m vs 5.0 m straight). World boots
clean.
