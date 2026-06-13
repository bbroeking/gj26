---
type: pipeline
tags: [godot, engine, testing, dev-tools, dungeon-generation]
status: draft
updated: 2026-06-13
sources: ["docs/GODOT_PIPELINE.md"]
---

# Godot Pipeline

Wayfinder's live engine: a Godot 4.6 project at `wyrd/` (formerly `godot/`) that hosts the full chart loop, economy, combat, and procedural dungeon system — superseding the original three.js prototype removed 2026-06-12.

## Engine setup

Install via Homebrew:

```bash
brew install --cask godot      # Apple Silicon Metal build
godot --version                # 4.6.2.stable.official or newer
```

Binary path: `/opt/homebrew/bin/godot`. The project uses the **Forward+** renderer (`wyrd/project.godot`).

## Project layout

```
wyrd/
├── project.godot
├── scenes/          ← Town.tscn, World.tscn + component scenes
├── scripts/         ← game.gd (autoload), player_controller, layout_loader,
│   └── ui/          ← wyrd_ui.gd (kit tokens + styleboxes)
├── data/            ← charts.gd, gather.gd, crafting.gd, items.gd, drops.gd, elites.gd, affixes.gd
├── assets/          ← UI kit textures, fonts (IM Fell, Caveat), icons, cursors
├── audio/
├── models -> ../models        ← SYMLINK — do not break
└── textures/crypt -> ../../docs/concept-art/dungeons/crypt  ← SYMLINK
```

`models/` is a symlink to the repo-root `models/` directory so one set of GLBs serves all contexts. The symlinked `textures/crypt` lets the dungeon tile renderer read concept-art PNGs without copying them.

## Running the game

```bash
godot --path wyrd              # open the project
```

Headless smoke test (boots World scene for 60 frames):

```bash
godot --headless --path wyrd --quit-after 60 res://scenes/World.tscn
# Look for: [layout_loader] crypt floor built — N decor, N enemies, boss=hedgemother
```

Headless lint (catches import + GDScript errors without opening the editor):

```bash
godot --headless --path wyrd --import
```

## Dev hooks (WYRD_* env vars)

| Env var | Effect |
|---|---|
| `WYRD_NO_SAVE=1` | Never write the real save file |
| `WYRD_SHOT=1` | Screenshot to `/tmp/wyrd_town.png` on boot |
| `WYRD_UI_SHOT=<surface>` | Open a specific UI surface for capture (see `wyrd/tools/capture_ui.sh` for all 10) |
| `WYRD_DEV_CHART=<template>` + `WYRD_DEV_BOSS=<den_affix>` | Boot straight into a chart run |
| `WYRD_FAST_CHANNEL=1` | Instant gather channels (skip the real timer) |

Always run tests with `WYRD_NO_SAVE=1` — `_test_save_roundtrip` writes then deletes the real save path (open followup: back it up first).

## Test suites

Four headless suites; all four must stay green before shipping:

```bash
cd wyrd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_transitions.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd
```

`test_skills.gd` covers the hotbar dispatch path — the only suite that catches a dead keypress. Its absence once let a frozen-hotbar regression ship.

**Gotchas (from `feedback_godot_headless_test_harness` project memory):**
- Autoloads DO load in `--script` mode; reuse the real `Game` autoload, don't mount fakes.
- `_ready` needs a frame — `await get_tree().process_frame` before asserting on-ready state.
- GLB AABBs need transform accumulation (the `GlbFit` helper).

## Dungeon generation

`wyrd/scripts/dungeon_gen.gd` is a seeded rooms-and-corridors generator (the "TinyKeep" method):

1. Place non-overlapping rooms.
2. Delaunay triangulation of room centers (`Geometry2D.triangulate_delaunay`).
3. Minimum spanning tree (Kruskal + union-find) — guarantees full connectivity, no cycles.
4. Re-add ~15% of non-MST Delaunay edges for loops.
5. Carve L-corridors along the final edge set.

Boss room = farthest room from entry by BFS hop count. Layouts are scored (`dungeon_score.gd`) on connectivity (hard gate: 1.0), critical path fraction (≥0.5), room count (5–12), floor ratio (0.18–0.45), corridor ratio (≤0.60), and dead-end count. The generator retries up to `MAX_ATTEMPTS` and returns the best candidate.

Typed rooms are guaranteed per run: entrance antechamber, boss arena, rest room (Hearth), treasure room (Chest), shrine room.

`layout_loader.gd` has a `USE_PROCGEN` toggle; set `false` to load a static JSON snapshot from `wyrd/data/`.

## Collision layers

Named in `project.godot`: `world` (1), `player` (2), `enemies` (3). Player collides with world + enemies; the SpringArm camera collides with world only.

## Skill system (spec 30)

4-slot hotbar on keys 1–4. Slot 1 = BasicShot (free, 0.28s cooldown). Slots 2–4 cost Focus (50 cap, regenerates 10/sec out of combat / 3/sec in combat). Implemented via `scripts/skills/skill.gd` (base RefCounted) and `ProjectileSkill` subclass. See [[Skills]] and the full spec at `docs/specs/30-skills-and-cooldowns.md`.

## Web export

```bash
godot --headless --path wyrd --export-release "Web" build/web/index.html
cd wyrd/build/web && python3 -m http.server 8099
```

Export templates must be installed once (~1.2 GB). The curated whitelist in `export_presets.cfg` keeps the build to ~37.5 MB (1.1 MB assets + 36 MB WASM floor). A naive `all_resources` export would balloon to ~617 MB from the 189 GLBs in `models/`.

## See also

- [[Asset Pipeline]] — how GLBs land in `models/` and get imported
- [[Animation Pipeline]] — skeletal clips vs. procedural rotation
- [[Dungeon Generation]] — the procgen system at game design level
- [[Skills]] — hotbar ability data
- [[Chart Loop]] — the top-level game loop that dungeon runs serve
- [[Blender Pipeline]] — upstream of every GLB

## Sources

- `docs/GODOT_PIPELINE.md`
