# 69 — Soft Ground

> **Outcome:** First Road clearings read as walked dirt and moss inside
> Bramblewood rather than one uniform sheet of polygonal dungeon stone.

## Why

The `0.1.8-deep-wood` replay proves the forest now continues past the playable
wall. The remaining board-like signal has moved inward: hard, evenly weighted
cells cover every room and corridor. The approved First Hollow references use
quiet dirt lanes and green shoulder variation so actors and landmarks own the
stage.

Wayfinder already has a seamless world-space toon-ground shader and a single
merged visual floor. Its existing morph controls can produce soft soil without
adding textures, decals, collision, draw calls, or a second ground system.

## Scope

**In:**

- Give only the `snug` First Road a warmer dirt base, moss-green macro mottle,
  broader warped clumps, and nearly absent grout and bevel.
- Keep the existing merged floor mesh, world-space shader, ground-cover scatter,
  navigation, collision, procedural footprint, and deterministic seed.
- Validate native and Web renders beside the approved forest concepts.

**Out:**

- Paths painted between rooms, splat maps, textures, decals, new floor meshes,
  grass simulation, or per-archetype ground content.
- Changes to later wood-grove Charts, layout, encounters, rewards, camera,
  walls, cutaway, controls, or audio.

## Player-visible contract

1. The clearing floor reads first as warm soil with moss variation, not cobble.
2. Large, low-contrast patches break sameness without becoming tactical noise.
3. The ranger, enemies, Waystone, projectiles, and room silhouettes remain the
   strongest gameplay shapes.
4. Every playable floor cell, collision surface, nav tile, and route remains
   exactly where the generated Chart placed it.

## Acceptance criteria

1. The production First Road still owns exactly one `FloorMerged` visual with
   one surface and the established toon-ground shader.
2. Its material uses `cell_strength <= 0.14`, `bevel <= 0.12`, broad cells of at
   least `1.2 m`, a warm dirt base, and a green moss accent.
3. A non-`snug` wood-grove material retains the shared biome defaults, proving
   this checkpoint does not spill into later Charts.
4. Native and Web 1280×720 play read as dirt-and-moss clearings beside the
   approved references, with no loss of actors, combat lanes, or wall clarity.
5. Canonical, retained-corpus, export, diagnostic, performance, documentation,
   version, game release, and companion-site gates pass.

## References

- `docs/concept-art/gameplay-direction/wayfinder-state-02-first-hollow.png`
- `docs/concept-art/gameplay-direction/wayfinder-state-03-town.png`
- `docs/specs/68-first-hollow-forest-continuity.md`

## Done check

- [x] First Road ground reads as dirt and moss rather than polygonal stone.
- [x] The existing one-surface floor and all gameplay authority are unchanged.
- [x] Later wood-grove scopes retain their accepted material.
- [x] Rendered, regression, release, and companion-site gates pass.
