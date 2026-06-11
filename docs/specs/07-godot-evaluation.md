# 07 — Godot evaluation: render the crypt dungeon natively

> **Outcome**: a working **Godot 4.6.2** project lives at `godot/` inside the repo. It loads the same crypt dungeon layout the three.js game produces, renders it with the existing GLB models, spawns the Hedgemother + a small enemy roster + a placeholder player at the right tiles, frames a working camera, and documents how future Meshy AI outputs land in both engines side-by-side. The three.js game keeps running unchanged.

## Why

The user wants a hands-on comparison of Godot vs. the current three.js stack. Engine choice is the most expensive decision-cost on this project. Making it on a working artifact — not on vibes — saves months in either direction. This spec is **evaluation, not migration**. After it lands, both projects coexist and the user can pick.

## Scope

**In:**

### A. Tooling install
- Install **Godot 4.6.2** (Apple Silicon, Metal renderer) — Homebrew cask preferred (`brew install --cask godot`), fallback to direct download from godotengine.org.
- Verify **Node 18+** is present (needed for the MCP server).
- Install **`@coding-solo/godot-mcp`** as the MCP bridge.
- Wire the MCP server into Claude Code's MCP config (project-scoped — `.mcp.json` in repo root, OR user-scoped — `~/.claude/config.json`). Project-scoped preferred so the MCP travels with the repo.
- Confirm the MCP is reachable on next session start (will surface as `mcp__godot__*` tools).

### B. Godot project bootstrap
- Create `godot/` directory inside the repo.
- `godot/project.godot` set to **Forward+ on Apple Silicon, Metal driver**, **Vulkan/MoltenVK** fallback for Intel. `physics/3d/default_gravity = 9.8`. Standard Godot 4.6 defaults otherwise.
- Add `.gitignore` for Godot build artifacts (`.godot/`, `*.import` is okay to commit).
- One scene tree:
  - `scenes/World.tscn` — the dungeon root
  - `scenes/Player.tscn` — a placeholder CharacterBody3D (capsule + camera arm)
  - `scenes/Enemy.tscn` — a generic GLB-instance container used as a packed scene for skeleton/rat/ghost/hedgemother spawns

### C. Asset wiring
- **Do not duplicate the `models/` directory.** Symlink `godot/models` → `../models` (relative). Both engines read the same files.
- **Do not duplicate texture PNGs.** Symlink `godot/textures/crypt` → `../docs/concept-art/dungeons/crypt`.
- Godot will auto-generate `.import` sidecar files. Commit them.
- Test imports for: a couple of crypt decor GLBs (`dungeon_crypt_chest_v1.glb`, `dungeon_crypt_pillar_v1.glb` or similar) + the four enemy GLBs (`enemy_skeleton_v1.glb`, `enemy_rat_v1.glb`, `enemy_ghost_v1.glb`, `enemy_hedge_sprite_v1.glb`) + the boss (`hedgemother_v2.glb`).

### D. Layout source — JSON snapshot
- **Do not port `src/scene/dungeon.js` procgen to GDScript.** Far too much code for an evaluation.
- Instead: add a tiny browser-console snippet documented in `docs/GODOT_PIPELINE.md` that dumps `dungeon.layout` (when in a crypt arc) to JSON. User pastes the result into `godot/data/crypt_floor1.json`.
- The JSON contains: `grid` (2D string array of `'floor' | 'wall'`), `entry` (`{x, y}`), `exit`, `chestTile`, `rooms`, `decor` (list of `{kind, x, y}`), `bossRoom`, `bossKind`.

### E. Godot renderer (`scripts/layout_loader.gd`)
- Reads `data/crypt_floor1.json` at scene load.
- For each tile in `grid`:
  - `'floor'` → place a 1×1 flat plane (StandardMaterial3D, stone color) at `(x + 0.5, 0, y + 0.5)`
  - `'wall'` → place a 1×2×1 stone-textured block at the same XZ, Y=1
- For each `decor` entry: instance the corresponding GLB from `res://models/` (the symlink) at the tile center.
- Spawn the Hedgemother GLB at the boss room's center tile.
- Spawn a skeleton, rat, and ghost GLB at 3 distinct floor tiles (hand-picked from the snapshot, NOT random).
- Place the Player at `entry`, attach a SpringArm3D camera looking down at ~30°.

### F. Meshy AI flow integration
- Update `docs/MESHY_OPERATIONS.md` with a **"Godot import"** section that explains:
  - The Meshy → `clean_ai_mesh.py` → `models/*.glb` flow is unchanged.
  - Godot picks up new GLBs automatically via the symlinked directory.
  - First time a new GLB is opened in Godot, it auto-imports; commit the resulting `.import` file.
- No new Python scripts needed — the existing `clean_ai_mesh.py` outputs glTF 2.0 which Godot reads natively.

### G. Documentation
- New `docs/GODOT_PIPELINE.md` capturing:
  - Install steps (Godot + Node + MCP)
  - How to dump a layout snapshot from the JS game
  - How to add a new asset (mirrors the three.js flow with a Godot annotation)
  - The dual-engine model and why we keep both for now
  - Known-good Godot version (4.6.2)

**Out (explicit non-goals):**
- Porting **any** game logic from `src/` — no combat, no skills, no inventory, no quests, no NPCs, no dialog, no charts, no save/load.
- GDScript ports of `src/anim/*.js` per-frame animators — enemies stand still in T-pose for v1.
- Hedgemother phase machine / boss HP bar / boss room seal — out.
- Multi-floor descent / staircases — load one floor.
- Procgen in Godot — static snapshot only.
- Web export from Godot — premature.
- Replacing the three.js game — both run.
- Authoring tools (`editor.html` stays the source of truth for any future content).
- Lighting polish, post-FX, fog tuning — defaults are fine for evaluation.
- Tilesets / GridMap optimizations — straight Node3D placement is fine at v1 scale.

## Files

| Path | Action |
|---|---|
| `~/.claude/config.json` or `.mcp.json` (project root) | modify — add `godot` MCP server entry |
| `godot/` | new directory |
| `godot/project.godot` | new |
| `godot/.gitignore` | new |
| `godot/icon.svg` | new (default Godot icon is fine) |
| `godot/models` | new symlink → `../models` |
| `godot/textures/crypt` | new symlink → `../../docs/concept-art/dungeons/crypt` |
| `godot/scenes/World.tscn` | new |
| `godot/scenes/Player.tscn` | new |
| `godot/scenes/Enemy.tscn` | new |
| `godot/scripts/layout_loader.gd` | new |
| `godot/data/crypt_floor1.json` | new — snapshot dumped from the JS game |
| `docs/MESHY_OPERATIONS.md` | modify — add "Godot import" section |
| `docs/GODOT_PIPELINE.md` | new |

## Acceptance criteria

1. `godot --version` reports `4.6.2.stable.official` or newer.
2. `npx -y @coding-solo/godot-mcp --help` exits 0 (server is installed and reachable).
3. Claude Code MCP config has a `godot` entry — next session will surface `mcp__godot__*` tools.
4. `godot/project.godot` opens in the Godot editor without import errors (all GLBs and PNGs resolve via the symlinks).
5. `godot/data/crypt_floor1.json` exists and has at least `grid`, `entry`, `exit`, `decor`, `bossRoom`, `bossKind`.
6. Running `godot --path godot --quit` (headless lint) exits 0.
7. Opening `World.tscn` in the editor and pressing F5 renders a recognizable crypt floor: tiled floor + walls, decor props placed, Hedgemother visible at the boss tile, 3 enemy GLBs visible elsewhere, player capsule at the entry tile, camera framed on the player.
8. `docs/GODOT_PIPELINE.md` exists and includes (a) the install commands actually used, (b) the JSON-snapshot dump snippet, (c) the dual-engine asset model.
9. `docs/MESHY_OPERATIONS.md` has a "Godot import" subsection.
10. `git status` in the repo root shows the new `godot/` directory + the docs changes, no accidental modifications to `src/` or `models/`.

## Open decisions

- **Install method**: Homebrew cask vs. direct download. Recommend `brew install --cask godot` — managed updates, and any Mac with Homebrew already gets it; fall back to direct download from godotengine.org if the cask serves an old build.
- **MCP scope**: project-scoped `.mcp.json` vs user-scoped `~/.claude/config.json`. Recommend **project-scoped** so the MCP server travels with this repo and doesn't clutter unrelated sessions.
- **GDScript vs C#**: GDScript. Tiny amount of code; no .NET runtime dependency.
- **Symlink vs copy** for `models/` and crypt textures: **symlink**. One source of truth, no drift.
- **Static snapshot vs procgen port**: **static snapshot**. The point is to see the renderer + asset round-trip; procgen is a separate decision.
- **Animations**: skip per-frame animators for v1. Enemies stand in their bind pose. Adding `AnimationPlayer` is a followup.
- **Player controls**: skip keyboard/mouse input for v1 — the player is a static decoration. Adding `CharacterBody3D._physics_process` movement is a followup.
- **What three.js side has to do**: nothing. The JS code is read-only for this spec. The user just opens the game in a browser, runs `JSON.stringify(window.__dungeon.layout)` in the console, and pastes the result into the Godot JSON file.

## References

- Godot 4.6.2 macOS: <https://godotengine.org/download/macos/>
- Godot MCP (Coding-Solo): <https://github.com/Coding-Solo/godot-mcp>
- Existing dungeon procgen + renderer: `src/scene/dungeon.js` (`generateDungeonLayout`, `buildDungeonGroup`)
- Existing GLB pipeline: `docs/ASSET_PIPELINE.md`, `scripts/clean_ai_mesh.py`, `docs/MESHY_OPERATIONS.md`
- Memory: `project_future_ai_image_to_3d.md` (Meshy is active flow)
- Existing models: `models/` (90+ GLBs including crypt decor, enemies, NPCs, props)

## Done check

- [ ] Godot 4.6.2 installed and `godot --version` works
- [ ] godot-mcp server installable via `npx @coding-solo/godot-mcp`
- [ ] MCP config updated (project-scoped `.mcp.json` preferred)
- [ ] `godot/project.godot` opens cleanly with no import errors
- [ ] Symlinks to `models/` and crypt textures resolve from inside `godot/`
- [ ] `crypt_floor1.json` snapshot dumped from the JS game
- [ ] `World.tscn` renders the dungeon with Hedgemother + 3 enemies + player + camera
- [ ] `GODOT_PIPELINE.md` written
- [ ] `MESHY_OPERATIONS.md` updated with Godot section
- [ ] No modifications to `src/` or `models/`
- [ ] The three.js game still runs unchanged
