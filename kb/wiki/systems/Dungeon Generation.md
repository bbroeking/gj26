---
type: system
tags: [dungeon, procgen, rooms, layout, affixes]
status: draft
updated: 2026-06-13
sources: ["docs/specs/08-quality-procgen.md", "docs/specs/25-interesting-dungeons.md", "docs/specs/28-dungeon-placement-polish.md", "docs/specs/29-typed-room-contracts.md", "wyrd/data/charts.gd"]
---

# Dungeon Generation

The dungeon generator converts a crafted [[Charts|chart]] — its template, [[Affixes|affixes]], and seed — into a fully-connected procedural hollow with typed rooms, themed dressing, gather nodes, and an enemy population, ready to be loaded by `wyrd/scripts/layout_loader.gd`.

## Pipeline overview

```
chart { template_id, tier, affixes, seed }
      ↓
DungeonGen.generate(seed, cfg)
      ├── place rooms (rectangles, circles, irregular shapes)
      ├── Delaunay triangulation of room centers
      ├── Minimum Spanning Tree (Kruskal's) for connectivity
      ├── add ~15% non-MST edges back for loops
      ├── carve L-shaped corridors along final edge set
      ├── score layout (6 metrics) — regenerate if below threshold
      ├── assign room roles + themes
      ├── place interactables (Chest, Shrine, Hearth)
      ├── dress rooms (focal decor + satellites, flush to walls)
      └── seed gather nodes and enemy spawns via affix rules
```

The connection algorithm is the standard "TinyKeep" rooms-and-corridors pipeline: Delaunay triangulation so corridors stay spatially local, MST for guaranteed minimal connectivity, a fraction of non-MST edges added back for alternate routes. Corridors are never carved in placement order (which cross-cuts the map). Spec 08 (`docs/specs/08-quality-procgen.md`).

## Quality scoring (generate-and-test)

Every layout is scored against six metrics before being accepted. The generator retries up to `MAX_ATTEMPTS = 12` seed variants; it always returns a layout even if none clear the threshold.

| Metric | Measure | Constraint |
|---|---|---|
| `connectivity` | BFS flood-fill floor coverage from entry | Hard gate — must be 1.0 |
| `critical_path` | BFS hop-count entry → boss room | ≥ 0.5 × room count |
| `room_count` | number of rooms | `[ROOM_COUNT_MIN, ROOM_COUNT_MAX]` |
| `floor_ratio` | floor tiles ÷ grid area | `[0.18, 0.45]` |
| `corridor_ratio` | corridor tiles ÷ room tiles | ≤ 0.6 |
| `dead_ends` | degree-1 nodes in room graph | `[1, ceil(room_count × 0.4)]` |

A layout with `connectivity < 1.0` fails regardless of other scores. The boss room is placed at the farthest room from the entrance by BFS hop count, not Euclidean distance.

## Template parameters

Each chart template passes a `gen` block to the generator. From `wyrd/data/charts.gd`:

- **Snug**: 28-tile grid, rooms 6–9 tiles, 3–7 rooms, `enemy_density 0.5` (gentle tutorial)
- **Tier 1 Hollow**: 36-tile grid, rooms 7–11 tiles, 4–9 rooms
- **Hollow**: uses dungeon_gen defaults (48-tile grid, rooms 8–14 tiles)
- **Briar Maze**: rooms 6–10 tiles, `loop_fraction 0.55`, `corridor_ratio_max 2.4` (corridor-heavy feel)
- **Summit**: custom boss kind `hedgemother_queen`, `enemy_density 1.4`, `loop_fraction 0.4`

## Room roles and typed contracts

Rooms carry a `role` that determines their mechanical contract (spec 29, `docs/specs/29-typed-room-contracts.md`):

| Role | Contract | Interactable |
|---|---|---|
| `entrance` | spawn point; always calm | — |
| `combat` | enemy spawns by depth | — |
| `treasure` | interactable chest, drops loot | Chest.tscn |
| `shrine` | 3-buff choice pauses the run | Shrine.tscn |
| `rest` | full heal + in-run checkpoint | Hearth.tscn |
| `boss` | sealed arena, boss entity | — |

Every dungeon guarantees at least one of each non-combat role. The rest room is always placed adjacent to the boss room on the room graph so careful players learn to expect the pattern.

## Room themes and dressing

Each role maps to one of seven visual themes (spec 25, `docs/specs/25-interesting-dungeons.md`):

`tomb_hall` · `ossuary` · `archive` · `overgrown` · `shrine` · `vault` · `antechamber`

Each theme specifies a **focal** piece (one item placed at room center) and **satellite** decor (walls, corners, clusters). Spec 28 (`docs/specs/28-dungeon-placement-polish.md`) ensures decor sits flush against actual walls (not one tile inboard), faces the room interior, and never blocks corridor mouths. No two adjacent rooms share a theme.

## Affix effects on generation

[[Affixes]] inscribed in the chart directly alter what the generator populates:

| Affix (good twin) | Generation effect |
|---|---|
| `mineral_vein` | 3–5 ore-rock gather nodes spawned in rooms |
| `bramble_bloom` | 4–6 forage spawns |
| `wood_grove` | 3–5 log piles |
| `herbal_patch` | 6–9 herb spawns |
| `tyrannical` | enemies +50% HP |
| `festival_pace` | +50% enemy density |
| `sprinter` | all entity move speed +25% |
| `fog_of_hedge` | enemies' detection radius reduced |
| Boss dens | deepest room becomes that boss's arena |

Bad twins invert or remove the good effect (e.g., `mineral_vein` bad twin = no ore at all).

## Echo Charts

A special chart type that captures the live overworld layout rather than generating a fresh one. `generateEchoLayout` reads the overworld tile grid around an anchor point and converts walkable tiles to dungeon floor, blocked tiles to wall. Same enemy/loot pipeline, different layout source. Three echo places ship in design docs; they go through the same inscription process as procgen charts. (Prototype code: `docs/cartography-systems.md`; not yet ported to Godot.)

## See also

- [[Charts]] — what a chart is; template definitions including the `gen` block
- [[Affixes]] — the full affix list and which generation effects each one has
- [[Chart Loop]] — how the player gets from raw materials to a completed run
- [[Enemies]] — how enemy kinds are assigned per room depth and role
- [[Gather Nodes]] — the ore/forage/log nodes that affixes can populate
- [[Bosses]] — how boss dens work as a room role

## Sources

- `docs/specs/08-quality-procgen.md`
- `docs/specs/25-interesting-dungeons.md`
- `docs/specs/28-dungeon-placement-polish.md`
- `docs/specs/29-typed-room-contracts.md`
- `wyrd/data/charts.gd` (gen blocks per template)
