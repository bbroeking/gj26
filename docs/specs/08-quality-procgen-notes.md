# Implementation notes — 08-quality-procgen

## Decisions
- **Kruskal's MST** with union-find (path-compression-free, the room count is tiny so it doesn't matter).
- **Delaunay edges** extracted as a deduped set from `Geometry2D.triangulate_delaunay`'s triangle-index triples. Fallback to a nearest-neighbour chain when < 3 rooms or the triangulator returns nothing (collinear centers).
- **Scorer in a separate `dungeon_score.gd`** — `DungeonScore.score_layout(layout, cfg)` static. `cfg` carries the target bands + weights so all tunables stay in `dungeon_gen.gd`.
- **Equal weights** across the 5 soft metrics to start; `connectivity` is a hard gate (not weighted — if < 1.0 the total collapses).
- **Boss room = farthest from entry by BFS hops** on the final room graph (MST ∪ loop edges).
- `SCORE_THRESHOLD = 0.70`, `LOOP_EDGE_FRACTION = 0.15`, `MAX_ATTEMPTS = 12` — spec recommendations, will adjust in notes if the 10-run check disagrees.

## Deviations
- **Added `godot/test_procgen.gd`** — a headless `SceneTree` harness that runs `generate()` 10× and prints the metric breakdown. Not in the spec's file table, but acceptance criterion 7 ("10-run check") needs it and it's the natural way to verify future tuning. Kept it in the repo as a reusable test.
- **`GRID` bumped 24 → 28.** With `ROOM_COUNT_MIN = 5` and rooms up to 9×9, a 24-grid couldn't reliably fit 5 non-overlapping rooms — room placement starved and the fallback pair kicked in too often. 28 gives the placer room to breathe.
- **`preload` instead of `class_name` for the scorer.** `dungeon_gen.gd` referencing `DungeonScore` by its `class_name` failed with "Identifier not declared" — the global class cache hadn't registered the sibling script at parse time. `const DungeonScoreScript = preload(...)` is order-independent and always resolves. Same gotcha pattern as the spec 07 `:=` array-inference issue — GDScript's parse-time resolution is stricter than expected.

## Tradeoffs
- **Equal metric weights, kept.** The 10-run check (avg 0.97) shows the generator reliably lands well above threshold without weight tuning, so equal weights shipped. If a metric needs to matter more later, the weight hooks are trivial to add.

## Surprises
- **`floor_ratio` and `corridor_ratio` scored 1.00 on every one of 10 runs** — they never discriminate with the current room-size config. The Delaunay+MST connection is naturally so corridor-frugal that `corridor_ratio` is always well under 0.6, and 5–8 rooms of 4–9 tiles always lands floor coverage in `[0.18, 0.45]`. Not harmful — they act as guard rails that simply never trip — but they're dead weight in the average. See Followups.
- **Generate-and-test almost never retries.** Every run in the 10-run check cleared `SCORE_THRESHOLD` on `attempts=1`. The MST pipeline is good enough that the rejection loop is essentially insurance, not a workhorse. That's the desired outcome (cheap, reliable) — worth knowing the threshold could be raised to 0.85+ before retries become common.

## Followups
- **Tighten or drop `floor_ratio` / `corridor_ratio`** — they're always 1.0. Either narrow the bands so they discriminate (and actually shape layouts) or remove them from the average and let the 3 working metrics carry the score. Decide after the generator's room-size config stabilizes.
- **No explicit broken-layout test** — acceptance criterion 4 (unreachable room → rejected) is covered by code logic and the connectivity gate, but I didn't construct a deliberately-disconnected layout to prove the rejection fires. The MST guarantees connectivity so a natural broken layout is hard to produce; a unit test would need to hand-craft one.
- **Corridor width is 1 tile** — fine for v1, but 2-wide corridors read better for a 3D crawler. Spec explicitly deferred this.
- **Port the scorer back to three.js?** The same metrics would catch bad layouts in the live game's `src/scene/dungeon.js`. Out of scope here; worth considering if the three.js generator ever produces complaints.
