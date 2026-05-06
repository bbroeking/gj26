# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project at a glance

`gj26` is a browser-based cozy fairytale RPG set in **Bramblewood** (see `docs/WORLD_BIBLE.md`). Mechanically OSRS-shaped (chop / cook / fight / level / 28-slot inventory) but flavor-wise *not* OSRS — original world, named neighbors, storybook tone. Built in three.js with chunky low-poly Blender assets and a hand-drawn ink UI. **No build system, no package.json, no tests, no node_modules** — vanilla ES modules served as static files. Three.js loads from a CDN via importmap in `index.html`.

**All player-visible writing** flows from `docs/WORLD_BIBLE.md` — NPC names, quest copy, location signs, item descriptions. Code identifiers (`kind: 'goblin'`, `goblin.glb`, `cookSpawn`) stay generic; only display strings get the Bramblewood flavor.

## Run the game

```bash
# from the project root, any static server works:
python3 -m http.server 8765
# then open http://127.0.0.1:8765/index.html
```

That's it. Edit a `.js` or `.css` file, hard-reload (`Cmd+Shift+R`) — changes appear. There is no compile step, no linter, no test runner.

## High-level architecture

### Top-level loop

`src/main.js` is the only entry point. It boots three.js, parses the map, spawns the player and enemies, and runs the animation loop. It pulls from every subsystem — when something is broken end-to-end, this is the file that wires it up. It is large (~1400 lines) by design: small modules + thin glue is preferred over a `Game` class.

### Subsystem layout

```
src/
├── main.js              ← boot + game loop + DOM event wiring
├── data/
│   ├── config.js        ← all tunables (HP, XP curves, combat formulas, world cols/rows)
│   ├── items.js         ← ITEMS dict; food, equipment, tools, ores
│   ├── map.txt          ← ASCII 60×30 grid; W=wall G=grass T=tree S=stone F=floor X=spawn etc.
│   └── npcs.js          ← NPC dialog tables (Cook for now)
├── core/                ← engine glue (camera, input, mouse, A*, floating text)
├── scene/
│   ├── world.js         ← parses map.txt, builds terrain + obstacles, scatters trees/forage/ore
│   ├── characters.js    ← procedural meshes + GLB loaders + toon-shader + per-instance variety
│   ├── terrain.js       ← terrainHeightAt() — single source of truth for vertical placement
│   └── clouds.js / smoke.js / demoPads.js
├── anim/                ← per-frame rotation rigs (cow.js, goblin.js, knight.js, procedural.js)
├── game/                ← rules logic with no rendering: skills, combat, quest, enemies, player
└── ui/
    ├── tokens.css       ← design system; every color/spacing/font lives here
    ├── dialog.js        ← showDialog() + showLevelUp() shared modal
    └── charCreator.js   ← Name Thy Adventurer screen
```

### The GLB asset pipeline (load-side)

Models in `models/*.glb` are built in Blender via the MCP server. The end-to-end *concept → model → game* workflow lives in **`docs/ASSET_PIPELINE.md`** — start there for any new character/enemy/prop work. The Blender-specific recipe is in **`docs/BLENDER_PIPELINE.md`** and the user-validated `feedback_blender_bevel_pipeline.md` memory. The recipe in short:

1. Materials must use Principled BSDF nodes (not just `diffuse_color`) — otherwise glTF drops the color
2. `bpy.ops.mesh.remove_doubles` before bevel — glTF imports faces with split verts so bevel does nothing without this
3. Scale-aware bevel modifier with `limit_method='ANGLE'` at 30°, `width = min(0.025, dim * 0.08)`, 2 segments
4. Export with `export_yup=True, export_apply=True, export_animations=False, export_skins=False`

On the JS side `src/scene/characters.js` is the integration point:

- `_loadOnce(key, promiseKey, url)` — singleton GLB cache + promise
- `toonifyMaterials(scene)` — runs after every load; swaps every `MeshStandardMaterial` to `MeshToonMaterial` with a 4-step grayscale gradient (defined as `_toonGradient`). The gradient floor is intentionally bright (200/255) so OSRS-saturated colors don't crush in shadow
- `varyInstance(inst, opts)` — per-spawn jitter (scale + per-material HSL tint) so the herd doesn't look like clones. Materials must be cloned first because `Object3D.clone(true)` shares them
- `buildCowMesh()` / `buildGoblinMesh()` — return a Group; **prefer the GLB if loaded, fall back to procedural** so the game stays playable while assets load

### Procedural animation, not skeletal

GLBs export with no skins or clips (`export_animations=False`). Animation is per-frame rotation of named groups in `src/anim/*.js` (e.g. `Body`, `Head`, `Arm_L`, `Arm_R`, `Leg_L`, `Leg_R`, `Tail`). Sub-parts (eyes, fangs, spots, hooves) are re-parented in Blender so rotating `Head` carries them along. If you add a new GLB and find it animating like a marionette with detached parts, the re-parenting step was skipped — see the goblin/cow re-parent passes in git history.

### Design tokens (UI)

Every color, spacing, font, and decorative SVG in the UI is a token in `src/ui/tokens.css`. **Do not author hex codes or px values for theme** in `index.html` or component CSS — use `var(--token)`. Fixed game-canvas dimensions like `800×576` are content, not theme, and stay as raw px. The frame around `#stage` and `#panel` is an inline-SVG `border-image` named `--frame-ink` — reuse it for any future framed surface (modals already do).

The aesthetic is locked in `docs/UI_BIBLE.md` with reference images in `docs/ui-refs/`. New screens should reuse the master prompt stem there before generating, then drop the new ref into `docs/ui-refs/` and translate via the `reference-to-ui` skill.

### World coordinates

`1 tile = 1 unit = 1 meter`. The map is parsed once at boot from `src/data/map.txt`. World x grows east, z grows south, y is up. The terrain has subtle height noise — always use `terrainHeightAt(x, z)` from `src/scene/terrain.js` when placing anything on the ground (cook, castle, forge, enemies). Don't hardcode `y = 0`.

### State expectations

- `window.__game = { world, player }` is set at boot for browser-console debugging. The game loop and DOM event wiring assume `world` and `player` exist by the time the canvas renders.
- The character creator (`#char-creator.cc-open`) gates the game on first load. If you're testing something via the JS console after reload, you may need to dismiss it first.

## Conventions worth knowing

- **Per-skill XP and level data** lives on `player.skills[key] = { lv, xp }` where keys come from `SKILL_KEYS` in `src/game/skills.js`. Level-up fires `setLevelUpHook` which already plays a jingle, spawns floating text, re-renders stats, and shows the celebratory modal — wire any new feedback there, not at every call site.
- **Floating text popups** (XP, damage, level-up): use `spawnFloat(worldVec, text, kind)` from `src/core/floaters.js`. The DOM overlay at `#floaters` projects from world coords each frame.
- **Logging** is the in-panel chronicle; `log(kind, msg)` in `main.js` accepts kinds `combat | skill | quest | hint`. Don't `console.log` for anything the player should see.
- **Dialog modal** is the right surface for any blocking choice (NPC, level-up, future shop/death). Multiple `showLevelUp` calls in one frame queue automatically.

## Project memory and skill playbooks

- `~/.claude/projects/-Users-bbroeking-projects-gj26/memory/` — auto memory; user/feedback/project notes accumulated across sessions. The most load-bearing entry is `feedback_blender_bevel_pipeline.md` — read it before authoring a new GLB.
- `docs/*.md` — long-form playbooks (Blender pipeline, UI bible, art bible, onboarding flow, character-creator research, RuneScape-style MMO design notes). These are reference material, not code-controlled docs.
- `v1/` and `v2/` — earlier prototypes. Read for historical context only; nothing in `src/` imports from them.
