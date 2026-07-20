# Dungeon Forge procedural-generation fit for Wayfinder

**Research date:** 2026-07-19  
**Source snapshot:** Majid Manzarpour's `threejs-procedural-dungeon`, commit
[`0a2aa09`](https://github.com/majidmanzarpour/threejs-procedural-dungeon/tree/0a2aa0980028cbbc77af6642b4232b45713dc5de)  
**Scope:** identify what the linked tweet actually contributes, what may be
reused, and how it should influence Wayfinder's Godot dungeon and gathering
generation.

**Implementation status (2026-07-19):** adopted in Wayfinder's Godot generator.
The implementation is an original GDScript adaptation of the documented
pattern, not a source port: scatter and separation, topology-derived
entrance/boss/critical path, semantic side rooms, and variable-width corridors
now precede carving and dressing. Wayfinder's stronger Chart, Affix, biome
resource, campaign, co-op, scoring, and deterministic-seed contracts remain in
place.

## Finding

The [tweet](https://x.com/majidmanzarpour/status/2073880053536940501) links to
Majid Manzarpour's
[`threejs-procedural-dungeon`](https://github.com/majidmanzarpour/threejs-procedural-dungeon).
The repository is a self-contained Three.js demonstration called **Dungeon
Forge**. It does **not** provide an external map, herb, item, biome, or encounter
dataset to pull into Wayfinder. Its reusable contribution is the generation
pipeline and the intermediate layout data it produces. The author describes the
pipeline as scatter → separation → Delaunay → MST plus loops → semantics →
carving → rasterization/BFS → decoration, all driven by one seed
([README](https://github.com/majidmanzarpour/threejs-procedural-dungeon/blob/0a2aa0980028cbbc77af6642b4232b45713dc5de/README.md#L20-L34),
[algorithm summary](https://github.com/majidmanzarpour/threejs-procedural-dungeon/blob/0a2aa0980028cbbc77af6642b4232b45713dc5de/README.md#L92-L117)).

Wayfinder had already implemented much of the architectural core in
[`dungeon_gen.gd`](../../wyrd/scripts/dungeon_gen.gd): seeded rooms, Godot's
Delaunay triangulation, an MST, optional loop edges, room roles, carved tile
geometry, deterministic dressing, generation scoring, and connectivity
validation. The spatial core has now been redone around the missing
scatter/separate stage and the remaining semantic ideas, without vendoring the
Three.js application.

## What Dungeon Forge actually does

1. **One deterministic random stream.** A 32-bit `mulberry32` generator feeds
   every stage, so a seed reproduces the same rooms, roles, props, and lights
   ([source](https://github.com/majidmanzarpour/threejs-procedural-dungeon/blob/0a2aa0980028cbbc77af6642b4232b45713dc5de/src/main.js#L23-L44)).
2. **Compact room scatter.** Rooms are sampled inside a disc; 45% are small,
   40% medium, and 15% large, with at least two large rooms. Rectangular,
   elliptical, and octagonal footprints are then separated by up to 300 AABB
   relaxation passes
   ([source](https://github.com/majidmanzarpour/threejs-procedural-dungeon/blob/0a2aa0980028cbbc77af6642b4232b45713dc5de/src/main.js#L190-L235)).
3. **Connected graph with controlled loops.** Delaunay edges form the candidate
   graph. A minimum spanning tree guarantees room connectivity; short leftover
   edges may return as loops. For maps with at least 20 rooms, loop edges are
   pruned until the graph retains at least three leaves
   ([source](https://github.com/majidmanzarpour/threejs-procedural-dungeon/blob/0a2aa0980028cbbc77af6642b4232b45713dc5de/src/main.js#L237-L285)).
4. **Topology becomes authored pacing.** The largest room becomes the boss
   room; the entrance is the leaf farthest from it. BFS depth becomes normalized
   difficulty. Deep leaves become treasure rooms, off-path mid-depth rooms can
   become shrines, and late critical-path rooms can become elites
   ([source](https://github.com/majidmanzarpour/threejs-procedural-dungeon/blob/0a2aa0980028cbbc77af6642b4232b45713dc5de/src/main.js#L287-L344)).
5. **Corridors express importance.** Critical-path corridors are three cells
   wide, ordinary links two, and some treasure branches one. Corridors use
   aligned cuts where room overlap allows and L-shaped cuts otherwise
   ([source](https://github.com/majidmanzarpour/threejs-procedural-dungeon/blob/0a2aa0980028cbbc77af6642b4232b45713dc5de/src/main.js#L358-L424)).
6. **Generation is tested, not merely rolled.** A floor-tile BFS rejects a map
   unless all floor is reachable; the outer generator retries up to five times
   with derived seeds
   ([validation](https://github.com/majidmanzarpour/threejs-procedural-dungeon/blob/0a2aa0980028cbbc77af6642b4232b45713dc5de/src/main.js#L522-L542),
   [retry loop](https://github.com/majidmanzarpour/threejs-procedural-dungeon/blob/0a2aa0980028cbbc77af6642b4232b45713dc5de/src/main.js#L176-L188)).
7. **Content placement reads semantic data.** Room type, BFS difficulty, room
   area, occupied cells, door proximity, corridors, and theme flags determine
   encounters and dressing; decoration is emitted as data before rendering
   ([source](https://github.com/majidmanzarpour/threejs-procedural-dungeon/blob/0a2aa0980028cbbc77af6642b4232b45713dc5de/src/main.js#L543-L645)).

The five themes are authored JavaScript objects containing colors, lights,
liquids, particles, prop flags, and name fragments. They are example renderer
configuration, not a content corpus Wayfinder needs to import
([theme data](https://github.com/majidmanzarpour/threejs-procedural-dungeon/blob/0a2aa0980028cbbc77af6642b4232b45713dc5de/src/main.js#L51-L121)).

## Current Wayfinder fit

| Concern | Wayfinder today | Useful Dungeon Forge addition |
|---|---|---|
| Determinism | Chart seed drives layout and downstream placement. Attempts use deterministically derived seeds. | Keep this contract; do not introduce an unrelated RNG stream for the loading preview. |
| Room graph | Delaunay → MST → configurable loop fraction already exists. | Add explicit critical-path and loop metadata to the returned layout instead of recomputing it in each consumer. |
| Quality | Up to 12 attempts are scored; floor connectivity is already a hard gate in [`dungeon_score.gd`](../../wyrd/scripts/dungeon_score.gd). | Keep Wayfinder's stronger quality gate. Add a minimum-leaf target only for larger templates if playtests show overly web-like graphs. |
| Semantics | Entrance, boss, combat, rest, treasure, shrine, setpiece, room depth, and biome-specific themes already exist. | Make depth normalized and expose critical-path membership so encounter and gathering placement can use pacing rather than only random eligible rooms. |
| Gathering | Good gather Affixes scatter seeded nodes; native biome resources are guaranteed and validated. [`gather.gd`](../../wyrd/data/gather.gd) owns the ore/herb tiers and roll weights. | Preserve this data. Place optional Affix nodes through semantic candidate pools while leaving biome guarantees untouched. |
| Loading overview | The generated layout already returns grid, rooms, edges, depths, decor, scope, tier, and seed. | Use that exact frozen layout to paint the pre-map overview; never generate a cosmetic second map. |

### Gathering implications

Dungeon Forge has no herbs. Wayfinder's herb ladder and weighted chart-tier
rolls remain the authoritative data. Today, good **Bramble Bloom** places 4–6
forage nodes, good **Herbal Patch** places 6–9, and each node rolls from the
chart tier's forage table. Native resources such as Mire Mothmint and Rootroad
Wellmoss are separate generation guarantees. The generator already excludes the
entrance and boss rooms and rejects occupied tiles
([Wayfinder scatter implementation](../../wyrd/scripts/dungeon_gen.gd#L646),
[Wayfinder herb tables](../../wyrd/data/gather.gd#L368)).

The useful upgrade is not “more randomness.” It is **seeded constrained
placement**:

- Build candidate cells after room roles and BFS depths are known.
- Keep guaranteed biome resources on their existing validated path.
- Distribute optional Affix forage across distinct non-boss rooms, preferring
  side branches and shrine/treasure-adjacent rooms before ordinary combat rooms.
- Reserve doorway clearance and avoid placing multiple nodes on the same cell
  or all nodes in one room.
- Record `room_id`, normalized depth, source (`biome_guarantee` or `affix`), and
  rolled resource tier in the layout manifest. That makes the same truth
  available to loading art, tests, co-op peers, and the instantiated
  `GatherNode`.
- Do not reveal exact coordinates or the entire route on the loading screen;
  summarize promises such as “Bramble Bloom · 5 patches · mostly side paths.”

## Implemented order

1. **Freeze one layout before loading the map.** Generate it from the Chart seed
   once, store it as the pending run layout, and pass that same dictionary to
   the loading screen and `LayoutLoader`.
2. **Enrich the layout schema.** Add `critical_room_ids`, edge flags
   (`critical`, `loop`), normalized `difficulty`, `entry_room_id`,
   `boss_room_id`, and a gather manifest. These are the highest-value ideas from
   Dungeon Forge because they support gameplay and the requested artistic map
   breakdown simultaneously.
3. **Render an interpretive overview.** Paint the room graph as an inked Chart:
   a gold route for the critical path, faint loops, role glyphs, biome wash,
   Affix illustrations, and qualitative resource/danger callouts. The loading
   screen should describe the generated result, not expose a tactical minimap.
4. **Upgrade optional resource placement.** Replace repeated random room picks
   for Affix resources with a shuffled semantic candidate list. Keep current
   weighted herb/ore rolls, node counts, level gates, and guaranteed biome
   manifests.
5. **Replace rejection placement with scatter-and-separate.** This is now the
   production path. A fixed-seed multi-biome corpus proves reproducibility,
   non-overlap, largest-room boss selection, entrance-to-boss critical paths,
   and three-tile critical corridors. The ordinary procgen quality gate still
   scores connectivity, route length, floor ratio, corridor ratio, room count,
   and dead ends.

## Licensing

The repository is MIT-licensed. It permits use, modification, distribution,
and sublicensing, but requires the copyright and permission notice to be
included in copies or substantial portions
([LICENSE](https://github.com/majidmanzarpour/threejs-procedural-dungeon/blob/0a2aa0980028cbbc77af6642b4232b45713dc5de/LICENSE#L1-L20)).
If implementation copies or closely ports its source, add Majid Manzarpour's
MIT notice to Wayfinder's third-party notices. Prefer adapting the specific
semantic behaviors to the existing Godot generator rather than importing
`src/main.js`; the renderer, shaders, procedural meshes, and browser UI do not
belong in Wayfinder's runtime.
