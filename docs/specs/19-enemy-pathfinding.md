# 19 — Enemy pathfinding (navmesh)

> **Outcome**: enemies route *around* walls to reach the player instead of pressing straight into a corner. Chase uses Godot's navigation system on a navmesh baked from the procgen crypt.

## Why

Spec 15 chose straight-line chase as the vertical-slice option — `move_and_slide` scrapes enemies along walls, and they visibly hang on corners when the player is around a bend. For a polished demo that reads badly. This swaps in real pathfinding.

## Scope

**In:**
- A **navigation mesh** for the crypt. The layout is procedural, so the navmesh is built at load: a `NavigationRegion3D` whose mesh is generated from the floor-tile set (the walkable tiles `layout_loader` already knows). Either bake a `NavigationMesh` from the floor geometry, or assemble a simple nav polygon from the tile grid.
- `combatant.gd` chase uses a **`NavigationAgent3D`** — set `target_position` to the player, move along `get_next_path_position()` instead of straight-at-the-player.
- Keep the aggro / attack-range / telegraph logic from spec 15 — only the *movement* in the chase state changes.
- Path refresh throttled (re-target every N frames, not every frame).

**Out:**
- Crowd avoidance / RVO between enemies (enemy↔enemy overlap stays allowed, spec 15).
- Flying / wall-ignoring enemies.
- Dynamic obstacle avoidance for moving blockers.
- Off-mesh links, jumps, multi-floor nav.

## Files

| Path | Action |
|---|---|
| `godot/scripts/layout_loader.gd` | modify — build the `NavigationRegion3D` from floor tiles |
| `godot/scripts/combatant.gd` | modify — `NavigationAgent3D`, path-following chase |
| `godot/test_combat.gd` | modify — a "reaches player around a wall" eval |
| `docs/GODOT_PIPELINE.md` | modify |

## Acceptance criteria

1. An enemy aggroed with a wall between it and the player routes *around* the wall and reaches melee range.
2. Enemies no longer visibly jam on wall corners.
3. Aggro / telegraph / attack (spec 15) still work; combat evals still pass.
4. No per-frame pathfinding cost spike — frame budget eval (E9) still passes.
5. Boots clean.

## Open decisions

- **Navmesh source** — bake a `NavigationMesh` from the assembled floor/wall geometry vs. build a nav polygon directly from the tile grid. Recommend **building from the tile grid** — the walkable set is already known exactly; baking is heavier and finicky with procgen timing.
- **Re-target cadence** — recommend every ~0.25 s (the player doesn't teleport; 4×/sec is smooth and cheap).
- **Agent radius** — match the enemy capsule (~0.4 m) so paths don't hug walls too tight.
- **Boss** — does the Hedgemother (spec 17) also path? Recommend yes, same `NavigationAgent3D`, unless her arena is open enough not to need it. Coordinate with spec 17.

## References

- Spec 15 notes — straight-line chase + the corner-hang followup
- `combatant.gd` `_tick_ai` chase state
- Godot `NavigationServer3D` / `NavigationRegion3D` / `NavigationAgent3D`

## Done check

- [ ] `NavigationRegion3D` built from the crypt floor tiles
- [ ] `combatant.gd` chase follows a path via `NavigationAgent3D`
- [ ] Enemy routes around a wall to the player
- [ ] Combat evals still pass (incl. frame budget)
- [ ] No boot/runtime errors
