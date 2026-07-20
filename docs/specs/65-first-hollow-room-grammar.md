# 65 — First Hollow room grammar

> **Outcome:** the First Road remains a seeded procedural Chart, but its rooms
> read as a sequence of natural, camera-sized Bramblewood clearings instead of
> exposed rectangular wall tiles.

## Why

The accepted First Road, responsive movement, and wall-cutaway checkpoints
made the opening playable and readable, then exposed the next leading gap. In
the rendered game, the generator is still visible as tall orthogonal slabs,
deep exterior wall fields, blocked sightlines, central prop clutter, and rooms
that do not compose as places. The approved First Hollow concept instead
frames a clean combat floor with an organic perimeter, strong entrances and
landmarks, and uninterrupted silhouettes.

This checkpoint changes the spatial presentation contract without replacing
the Chart graph, combat rules, controls, camera, rewards, or campaign state.

## Scope

**In:**

- Keep the seeded scatter → separation → Delaunay → MST/loops Chart graph.
- Give every First Road room a deterministic archetype selected from a
  role-aware pool, with seeded variation inside the archetype.
- Use archetypes to author the room footprint and readable central aperture,
  not merely to rename existing rectangular rooms.
- Render only the wall boundary that encloses reachable floor; do not build
  solid visual plateaus across unused grid space.
- Give the boundary an irregular, natural profile through deterministic
  height, inset, orientation, and silhouette variation while preserving robust
  collision and navigation truth.
- Keep entrances and corridor mouths visually open and at least as wide as the
  generated route contract.
- Keep combat-room collidable dressing out of the protected central aperture;
  focal and satellite dressing should reinforce the perimeter and approach.
- Preserve the continuous FATE camera. Extend the existing room-aware wall
  obstruction behavior so near walls lower cleanly and restore without camera
  snaps, arena locks, transparency holes, or changed collision.
- Add deterministic layout, production-scene, rendered-native, and Web checks
  for the new room grammar.
- Compare before/after evidence with
  `docs/concept-art/gameplay-direction/wayfinder-state-02-first-hollow.png`.

**Out (explicit non-goals):**

- Replacing procedural Charts with handcrafted complete maps.
- Camera locks, room snaps, doors that seal every encounter, or a new input
  mode.
- Propagating the grammar to Mire, Rootroads, Summit, or late boss rooms before
  the First Road proof is accepted.
- New enemies, Skills, Affixes, rewards, campaign chapters, or progression.
- A wholesale asset-library replacement or paid asset-generation pass.
- Final encounter-staging, audio, or biome-propagation polish; those remain
  eligible later checkpoints after the spatial foundation is proven.

## Player-visible contract

1. Entering a seeded First Road still feels like following one continuous
   Chart, but each chamber has a recognizable clearing silhouette.
2. At ordinary play zoom, the ranger, immediate enemies, aiming lane, and next
   opening remain readable without showing a field of unused wall tops.
3. Walls feel like a natural Bramblewood boundary rather than a voxel box:
   irregular edge rhythm, controlled height variation, and strong perimeter
   mass frame the floor.
4. The middle of a combat room remains available for movement, rolls, and bow
   lines. Chests, bushes, and focal decor do not occupy the protected aperture.
5. The camera follows continuously through rooms and corridors. Occluding
   boundary pieces lower and restore locally without changing collision or
   revealing void-like holes.
6. Different seeds choose and vary archetypes while the same seed reproduces
   the same room identities, footprints, walls, content, and route.

## Files

| Path | Action |
|---|---|
| `wyrd/scripts/dungeon_gen.gd` | add deterministic role-aware room archetypes, footprints, aperture and boundary metadata |
| `wyrd/scripts/layout_loader.gd` | build boundary-only natural wall presentation and preserve collision/navigation truth |
| `wyrd/scripts/camera_rig.gd` | adapt local obstruction handling to the new boundary pieces if required |
| `wyrd/test_procgen.gd` | prove archetype determinism, variation, connectivity, mouths, and protected apertures |
| `wyrd/test_hollow_readability.gd` | prove production-scene wall boundary and obstruction behavior |
| `wyrd/tools/capture_movement_checkpoint.gd` | retain or extend rendered production evidence if needed |
| `docs/playtests/first-hollow-room-grammar/` | before/after native and Web evidence plus observation notes |
| `docs/wyrd-roadmap.md` | record checkpoint state when accepted |
| `docs/CHANGELOG.md` | record the shipped version when accepted |
| `docs/devlog.md` | explain the player-visible problem and result when accepted |
| `docs/test-manifest.md` | update the canonical gate if a focused suite joins it |

## Acceptance criteria

1. The same First Road seed produces identical room archetype ids, footprint
   cells, boundary cells, entrances, and decor; a fixed multi-seed sample
   demonstrates at least three First Road archetypes or variants.
2. Every generated First Road remains connected, preserves its room/critical
   path budget, and keeps all corridor mouths passable at their authored width.
3. Every rendered wall cell is part of the floor boundary; no wall is rendered
   more than one grid step from reachable floor.
4. A protected combat aperture derived from each room contains no collidable
   decorative object and retains enough floor for the existing roll and
   one-verb bow combat.
5. The production Bold Road shows a recognizable irregular perimeter, at least
   two distinct room silhouettes, and substantially fewer wall nodes than the
   accepted pre-checkpoint baseline.
6. In the production 1280×720 pressure position, the ranger, elite company,
   aiming lane, and at least one room opening remain readable. Near boundary
   pieces lower locally and restore when the camera relationship clears.
7. Camera position/yaw/zoom remain continuous across room boundaries; no room
   entry code snaps, locks, or replaces the established FATE follow.
8. The canonical eight-suite gate remains green, the complete retained native
   suite has no new failures, and the exported Web build passes its resource
   audit and a real title → town → First Road → return journey with an empty
   diagnostic ledger.
9. Native and Web before/after evidence is reviewed beside the approved First
   Hollow concept. Acceptance requires a clearer central stage and more
   natural perimeter in the real game, not merely passing structural tests.

## Open implementation decisions

- **Boundary mesh construction:** prefer a small deterministic set of
  low-poly procedural profiles or batched modular pieces. Choose the smallest
  approach that produces an organic silhouette in native and Web without
  restoring one-node-per-unused-cell cost.
- **Archetype representation:** keep the contract data-driven and inspectable.
  ASCII masks, normalized shape functions, or compact descriptors are all
  acceptable if seed determinism and corridor-mouth repair are explicit.
- **Cutaway unit:** lower a coherent short boundary run when individual pieces
  flicker or create a picket-fence read; otherwise retain the smallest local
  unit that protects the player aperture.

## References

- `docs/concept-art/gameplay-direction/README.md`
- `docs/concept-art/gameplay-direction/wayfinder-state-02-first-hollow.png`
- `docs/specs/60-first-road-vertical-slice.md`
- `docs/specs/61-responsive-locomotion-checkpoint.md`
- `docs/specs/62-readable-hollow-checkpoint.md`
- `docs/system-plans/system-dungeon-generation.md`
- `docs/system-plans/system-camera.md`
- `docs/adr/0018-authored-charts-single-player-focus.md`

## Done check

- [ ] First Road archetype selection and variation are deterministic.
- [ ] At least three archetypes/variants appear across the fixed seed sample.
- [ ] Routes, mouths, navigation, resources, encounters, and return remain
      valid.
- [ ] Unused deep wall fields are no longer rendered.
- [ ] Combat apertures remain clear of collidable dressing.
- [ ] Natural boundary walls lower and restore cleanly under the continuous
      FATE camera.
- [ ] Native and Web evidence materially closes the approved-concept gap.
- [ ] Native, Web, performance, resource, and diagnostic gates pass.
- [ ] Roadmap, notes, changelog, devlog, version, and test manifest are current.
- [ ] Game and companion website are committed, pushed, deployed, and verified.

