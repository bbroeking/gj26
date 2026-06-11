# Implementation notes — 07-godot-evaluation

## Decisions
- **Install via Homebrew cask.** State check confirmed brew available and `godot` not installed. Picked `brew install --cask godot` over direct .dmg per the spec recommendation.
- **MCP scope: project-scoped** (`.mcp.json` in repo root). Travels with the repo; cleaner than user-global config.
- **GDScript**, not C#. Tiny code surface, no .NET runtime needed.
- **Symlinks (not copies)** for `models/` and crypt textures — one source of truth, no drift.
- **Static layout snapshot** (option A) for v1 — JS-side dump → `godot/data/crypt_floor1.json`. Procgen port is a separate decision.
- **No animations / no controls / no logic** — enemies in T-pose, player static. The point of v1 is the asset round-trip + renderer comparison.

## Deviations
- **`MESHY_OPERATIONS.md` lives at `docs/character-pipeline/MESHY_OPERATIONS.md`, not `docs/MESHY_OPERATIONS.md`** — spec referenced the wrong path. Appended Godot import section to the actual location.
- **`scripts/export_godot_snapshot.js` not created.** Spec listed it but the dump is genuinely just a paste from the JS console; a real script would require a build step or a separate Node entry point. The snippet lives inside `docs/GODOT_PIPELINE.md` instead. Cleaner than a one-off file.

## Tradeoffs
- **Floor planes are 1×1 PlaneMesh, not a TileSet/GridMap.** For ~150 tiles in a single floor, straight Node3D instancing is fine. If the snapshot ever swelled to a city-sized map, GridMap with a tile MultiMesh becomes the win — followup material.
- **Solid-color materials instead of crypt-texture PNGs.** The PNGs in `docs/concept-art/dungeons/crypt/` are concept art at 1024px-ish, not authored tileable surfaces. Slapping them on a 1m plane would either tile clumsily or stretch one image. Picked StandardMaterial3D solid color for v1; tiled textures are a polish step.

## Surprises
- **`brew install --cask godot` ships 4.6.2 directly** — no manual download needed, install was a single command, ~3 minutes.
- **Godot's import pass ran on all 189 GLBs and 471 sub-resources without a single failure.** glTF compatibility between the Meshy → `clean_ai_mesh.py` outputs and Godot's importer is total. The cache-bust headache from spec 04/05 has no equivalent here — Godot tracks asset hashes itself.
- **Headless smoke-test surfaced everything we needed.** `godot --headless --path godot --quit-after 60 res://scenes/World.tscn` printed `[layout_loader] crypt floor built — 15 decor, 3 enemies, boss=hedgemother` and exited 0 — confirms JSON parse + decor placement + boss spawn + enemy spawn all work without an editor + display.
- **Project-scoped `.mcp.json` is just a top-level file** — Claude Code picks it up on next session start. No additional registration step. (`mcp__godot__*` tools won't appear until restart, naturally.)
- **The `godot` CLI binary was masked by Bash's `cd godot` interpretation** initially — same word for the directory and the binary. Resolved by using absolute paths in shell commands. Worth knowing for any future `godot ...` invocations from inside `gj26/`.

## Procgen + web export (2026-05-20 follow-on)

### Procedural generation
- `godot/scripts/dungeon_gen.gd` — pure-GDScript rooms-and-corridors generator, seeded. `layout_loader.gd` now defaults to `USE_PROCGEN = true` — a fresh random dungeon every run. Verified via MCP `run_project`: `[layout_loader] crypt built — 14 decor, 6 enemies, boss=hedgemother, seed=8444879731714577599`.
- GDScript gotcha: `:=` type inference fails on array element access (`var a := rooms[i]`) — the array's element type is unknown, so it must be `var a: Dictionary = rooms[i]`. Hit this twice.

### Web export — IT WORKS
- Godot exports to HTML5/WASM. Installed the 4.6.2 export templates (1.2 GB `.tpz` download → extracted to `~/Library/Application Support/Godot/export_templates/4.6.2.stable/`).
- Threadless preset (`variant/thread_support=false`) so the build serves from **any plain static server** — no COOP/COEP header dance. Matches the three.js "any static server works" simplicity.
- Built headless: `godot --headless --path godot --export-release "Web" build/web/index.html`. Served on :8099, loaded in Chrome — the procgen crypt renders: player capsule, enemy GLBs, walls, decor, purple fog. **Confirmed running natively in the browser.**

### Web export — the size finding (important)
- First export was **617 MB** — `export_filter="all_resources"` packed every one of the 189 GLBs in the symlinked `models/` dir.
- Fixed by `export_filter="scenes"` + `export_files=PackedStringArray("res://scenes/World.tscn")` + an `include_filter` whitelisting the 8 GLBs the crypt scene actually uses (dynamically `load()`-ed GLBs are NOT auto-detected as dependencies — the whitelist is mandatory).
- Final build: **~37.5 MB total** = 36 MB `index.wasm` (fixed Godot runtime) + 1.1 MB `index.pck` (our assets) + 0.3 MB `index.js`.
- **The 36 MB WASM runtime is irreducible** — that's the floor for any Godot web build. Compare three.js: ~150 KB engine code + three.js from CDN (~600 KB gzipped). For a "click the link, you're playing" cozy game this is the single biggest mark against Godot-for-web.
- `export_filter="resources"` mode silently exports nothing without a populated `export_files` list — the World scene was missing from the first curated attempt. Use `scenes` mode + `export_files`.
- The `build/` dir must have a `.gdignore` or Godot scans its own export output as project resources and the next export fails with "Could not write file".

## Followups
- **Per-frame animation port** — the `src/anim/*.js` rotation rigs would translate to Godot AnimationPlayer tracks. The GLBs export with named bones (`Body`, `Head`, `Arm_L`, etc.) but no clips; clips would need authoring. Or `_process(delta)` GDScript that mirrors the per-frame rotation pattern.
- **Player input** — DONE (2026-05-20). `scripts/player_controller.gd` — CharacterBody3D, WASD/arrows, gravity, fixed follow cam. Walls + ground are `StaticBody3D` colliders. The Godot build is now walkable.
- **Texture polish** — crypt floor/wall PNGs as tileable materials (would need a small tileable variant generated or hand-authored).
- **GridMap/MultiMesh** if scenes scale up — current ~150 Node3D children render fine, but GridMap is the idiomatic Godot way and gets batched rendering for free.
- **Live MCP integration** — `.mcp.json` is committed but Claude Code needs a restart to expose `mcp__godot__*` tools. Confirm next session.
- **Decision: which engine ships?** Open. Both projects are kept side-by-side; revisit after a substantive comparison artifact lands.
