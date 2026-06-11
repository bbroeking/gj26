# 08 — Quality procgen: Delaunay + MST + generate-and-test

> **Outcome**: the Godot dungeon generator stops connecting rooms in placement order and instead connects them via a Delaunay-triangulation + minimum-spanning-tree pipeline (the "TinyKeep" method), then scores every layout against explicit quality metrics and regenerates until the score clears a threshold. A debug print shows the score breakdown so layout quality is tunable by numbers, not vibes.

## Why

`godot/scripts/dungeon_gen.gd` (spec 07 follow-on) connects rooms as `rooms[i-1] → rooms[i]` — i.e. in random *generation* order. The result: corridors zig-zag across the whole map, cross each other, and slice through unrelated rooms, smearing clean room clusters into corridor blobs. The fix is the standard rooms-and-corridors pipeline: triangulate room centers so edges are spatially local, take the MST for guaranteed minimal connectivity, add a few edges back for loops, then reject layouts that score poorly. This makes "is this dungeon any good" a measurable number instead of a judgment call.

## Scope

**In:**

### A. Connection pipeline rewrite (`dungeon_gen.gd`)
- Replace the placement-order corridor loop with:
  1. **Delaunay triangulation** of room center points. Godot 4 ships `Geometry2D.triangulate_delaunay(points: PackedVector2Array)` — use it; no hand-rolled triangulation.
  2. **Minimum Spanning Tree** over the triangulation edges, weighted by Euclidean distance between room centers. Kruskal's with a union-find is simplest in GDScript.
  3. **Loop edges**: add back a configurable fraction (`LOOP_EDGE_FRACTION`, default 0.15) of the non-MST Delaunay edges, chosen at random.
  4. Carve L-shaped corridors only along the final edge set (MST ∪ loop edges).
- Entry / exit / boss-room selection stays, but boss room becomes "farthest from entry **by BFS hop count on the room graph**", not Euclidean distance.

### B. Quality scoring (`dungeon_gen.gd` or a sibling `dungeon_score.gd`)
- `score_layout(layout) -> Dictionary` returning per-metric values + a total:
  | Metric | Measure | Target |
  |---|---|---|
  | `connectivity` | BFS flood-fill of floor tiles from entry; fraction of floor reached | hard gate — must be 1.0 |
  | `critical_path` | BFS hop count entry-room → boss-room on the room graph | ≥ 0.5 × room count |
  | `room_count` | number of rooms | within `[ROOM_COUNT_MIN, ROOM_COUNT_MAX]` |
  | `floor_ratio` | floor tiles ÷ grid area | within `[0.18, 0.45]` |
  | `corridor_ratio` | corridor tiles ÷ room tiles | ≤ 0.6 |
  | `dead_ends` | room-graph nodes of degree 1 | within `[1, ceil(room_count × 0.4)]` |
- Each metric contributes 0..1 to a weighted total. `connectivity < 1.0` is an automatic fail regardless of the rest.

### C. Generate-and-test loop
- `DungeonGen.generate(seed)` becomes: try up to `MAX_ATTEMPTS` (default 12) seeds derived from the base seed, score each, return the **first layout that clears `SCORE_THRESHOLD`** — or the best-scoring one if none clear (never hard-fail; always return a playable dungeon).
- The returned layout dictionary gains a `score` sub-dictionary so callers/debug can read it.

### D. Debug surfacing
- `layout_loader.gd` prints the score breakdown on build: `[layout_loader] score=0.82 (conn=1.0 path=0.7 rooms=1.0 floor=0.9 corr=0.8 deadends=0.6) attempts=3`.
- A `DEBUG_SCORE` const in `layout_loader.gd` (default `true`) gates the verbose line.

### E. Tunables block
- All knobs (`ROOM_COUNT_MIN/MAX`, `LOOP_EDGE_FRACTION`, `SCORE_THRESHOLD`, `MAX_ATTEMPTS`, metric target bands, metric weights) live in a clearly-marked `const` block at the top of `dungeon_gen.gd` so tuning is one file, one place.

**Out (explicit non-goals):**
- Touching the three.js generator (`src/scene/dungeon.js`) — Godot-only spec.
- Room *shapes* other than rectangles — no L-rooms, no caves, no cellular automata.
- Themed room tagging (treasure/puzzle/shrine) — the three.js side has this; not porting it here.
- Multi-floor / staircases.
- Corridor *width* > 1 tile.
- Visual polish (textures, lighting) — spec 07 followups, not this.
- Porting the scorer back to three.js.
- Procgen of decor placement beyond what spec 07 already does (random floor tiles).

## Files

| Path | Action |
|---|---|
| `godot/scripts/dungeon_gen.gd` | modify — Delaunay+MST connection, generate-and-test loop, tunables block |
| `godot/scripts/dungeon_score.gd` | new — `score_layout()` + BFS/flood-fill helpers (kept separate so the scorer is unit-testable) |
| `godot/scripts/layout_loader.gd` | modify — print score breakdown, `DEBUG_SCORE` const |
| `docs/GODOT_PIPELINE.md` | modify — document the scoring metrics + how to tune them |

## Acceptance criteria

1. `dungeon_gen.gd` no longer contains the `rooms[i-1] → rooms[i]` placement-order connection.
2. Corridors are carved only along MST ∪ loop edges; visually, corridors no longer cross each other or slice through unrelated rooms (verify by running the scene several times via the Godot MCP).
3. `score_layout()` returns all six metrics + a weighted total in `[0, 1]`.
4. A layout with an unreachable room scores `connectivity < 1.0` and is rejected by the generate-and-test loop.
5. `DungeonGen.generate()` always returns a playable (fully-connected) layout — even on a pathological seed it returns the best of `MAX_ATTEMPTS`.
6. Running the World scene prints the score breakdown line, and the printed `conn=` is always `1.0`.
7. Across 10 consecutive runs (different seeds), every dungeon is fully connected and the average total score is ≥ `SCORE_THRESHOLD`.
8. All tunables are in one labelled `const` block at the top of `dungeon_gen.gd`.
9. `docs/GODOT_PIPELINE.md` has a "Procgen quality" section explaining each metric and how to tune.

## Open decisions

- **Delaunay edge source.** `Geometry2D.triangulate_delaunay` returns triangle index triples; the edges are the triangle sides (dedup shared edges). Recommend extracting a unique-edge set from the triple list. If a degenerate point set (all-collinear room centers, or < 3 rooms) returns no triangles, fall back to a nearest-neighbour chain so the generator never dies.
- **MST algorithm.** Kruskal's (sort edges, union-find) vs Prim's. Recommend Kruskal's — fewer moving parts in GDScript, and we already have the edge list from Delaunay.
- **Score weighting.** Start equal-weight across the five soft metrics (connectivity is a gate, not weighted). Tune after seeing real numbers; record final weights in notes.
- **`SCORE_THRESHOLD`.** Recommend 0.7 to start — high enough to reject junk, low enough that `MAX_ATTEMPTS=12` reliably clears it. Notes record the value that actually held up.
- **Loop edge fraction.** 0.15 recommended (TinyKeep uses ~12.5%). Higher = more loops/alternate routes; lower = more linear. Notes record.
- **Boss room = farthest by BFS hops** vs Euclidean. BFS hops is the real "journey length"; spec picks BFS. If the room graph BFS is fiddly, Euclidean is an acceptable fallback — notes record which shipped.
- **Where the scorer lives.** Separate `dungeon_score.gd` (recommended — testable in isolation) vs inline in `dungeon_gen.gd`. Spec says separate.

## References

- Spec 07 (Godot eval) + its notes: [`07-godot-evaluation.md`](./07-godot-evaluation.md), [`07-godot-evaluation-notes.md`](./07-godot-evaluation-notes.md)
- Current generator: `godot/scripts/dungeon_gen.gd`
- Godot API: `Geometry2D.triangulate_delaunay`, `RandomNumberGenerator`
- The technique is the widely-documented "TinyKeep" / "Procedural Dungeon Generation" algorithm — rooms → Delaunay → MST → re-add loop edges.
- Three.js procgen for comparison (not modified): `src/scene/dungeon.js` `generateDungeonLayout`

## Done check

- [ ] Placement-order connection removed
- [ ] Delaunay triangulation of room centers
- [ ] Kruskal MST over Delaunay edges
- [ ] ~15% loop edges added back
- [ ] Corridors carved along final edge set only
- [ ] `dungeon_score.gd` with all six metrics + weighted total
- [ ] Generate-and-test loop, `MAX_ATTEMPTS`, always returns a connected layout
- [ ] Score breakdown printed on scene build
- [ ] Tunables in one `const` block
- [ ] 10-run check: all connected, avg score ≥ threshold
- [ ] `GODOT_PIPELINE.md` updated with the quality section
