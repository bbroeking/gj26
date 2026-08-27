# AGENTS.md

Guidance for Codex (and other agents) working in this repository.

> **`CLAUDE.md` is the canonical project-instructions file** — it is kept
> current and goes into more depth than this file. Read it first; this is a
> short orientation that mirrors its essentials.

## Project at a glance

**Wayfinder** (in `wyrd/`) is a cozy fairytale dungeon-crawler built in
**Godot 4.6**, set in **Bramblewood** (`docs/WORLD_BIBLE.md`). FATE-style camera,
combat-as-one-verb, with **cozy skilling as the spine** (ADR 0003): gather →
craft → chart → delve. The differentiator is the **Wayfinding trade** — inscribe
charts (parameterized dungeon keys) whose affixes shape each run.

> The earlier browser-based **three.js prototype was removed 2026-06-12** (it
> lives in git history). If you find docs or instructions describing a three.js /
> `src/main.js` / `python3 -m http.server` build, they are stale — the live game
> is Godot in `wyrd/`.

## Run the game

```bash
wyrd/tools/godot.sh --path wyrd   # prefers the project-matched Godot 4.6.2
```

## Tests (the gate — all 23 entrypoints must stay green)

```bash
wyrd/tools/test_checkpoint_gate.sh
```

## Layout

```
wyrd/        the Godot 4.6 project — scenes/, scripts/ (game.gd autoload,
             player_controller, layout_loader, combatant/boss, ui/), data/
             (charts, gather, crafting, items, drops, economy, affixes), tests
models/      all GLBs (Meshy/Blender pipeline; wyrd/models is a symlink — keep it)
docs/        WORLD_BIBLE, WORLD_LORE, wyrd-roadmap, specs/ (per-feature
             contracts), adr/ (decisions)
kb/          the LLM Wiki — synthesized, interlinked design knowledge base
             (start at kb/index.md; schema in kb/CLAUDE.md)
```

## Conventions worth knowing

- **Language (`CONTEXT.md`):** a leveling discipline is a **Trade** (Wayfinding /
  Earthcraft / Wildcraft / Huntcraft); "Skill" means hotbar abilities only.
  **Chart** not map/keystone; **Affix** good/bad twins.
- **All player-visible writing** follows the `docs/WORLD_BIBLE.md` voice; code
  identifiers stay generic.
- **UI** derives from the Wayfinder UI Kit (`wyrd/scripts/ui/wyrd_ui.gd`). Never
  `load()` a texture inside `_draw()` (renders white forever) — preload in `_ready`.
- **Plans / state:** `docs/wyrd-roadmap.md` (consolidated) + `docs/specs/`. The
  synthesized design map (systems, entities, world, decisions, pipeline, plus an
  MMO-research cluster) lives in the **`kb/` wiki** — read it to understand how
  Wayfinder fits together.

## Project memory

Auto-memory lives in `~/.claude/projects/-Users-bbroeking-projects-gj26/memory/`
(see its `MEMORY.md` index). The most load-bearing entry for asset work is
`feedback_blender_bevel_pipeline.md` — read it before authoring a new GLB. The
asset/Blender/animation pipelines are documented in the `kb/wiki/pipeline/` pages.
