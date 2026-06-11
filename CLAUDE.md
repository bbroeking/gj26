# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Project at a glance

**Wayfinder** (`wyrd/`) is a cozy fairytale dungeon-crawler built in
**Godot 4.6**, set in **Bramblewood** (`docs/WORLD_BIBLE.md`). FATE-style
camera and combat-as-one-verb, with **cozy skilling as the spine**
(ADR 0003): gather → craft → chart → delve. The differentiator is the
**Wayfinding trade** — inscribe charts (parameterized dungeon keys) whose
affixes shape each run; boss trophies unlock deeper dens up to the Summit.

The repo's earlier three.js prototype was removed 2026-06-12 (it lives in
git history before that commit). Its surviving value — item/recipe/skill
data, design docs — was ported into `wyrd/data/` and `docs/`.

## Run the game

```bash
godot --path wyrd                 # binary at /opt/homebrew/bin/godot
```

Dev hooks (env vars): `WYRD_NO_SAVE=1` (never touch the real save),
`WYRD_SHOT=1` (screenshot to /tmp/wyrd_town.png), `WYRD_UI_SHOT=<surface>`
(open a UI for capture; see `bash wyrd/tools/capture_ui.sh` for all 10),
`WYRD_DEV_CHART=<template>` + `WYRD_DEV_BOSS=<den_affix>` (boot straight
into a chart run), `WYRD_FAST_CHANNEL=1` (instant gather channels).

## Tests

```bash
cd wyrd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_transitions.gd
```

All three must stay green. Gotchas live in project memory
(`feedback_godot_headless_test_harness`): autoloads DO load in --script
mode (reuse the real `Game`), `_ready` needs a frame, always run with
`WYRD_NO_SAVE=1`. **Warning:** `_test_save_roundtrip` writes then deletes
the real save path — backing it up first is an open followup.

## Layout

```
wyrd/
├── project.godot          ← Godot 4.6, Forward+
├── scenes/                ← Town.tscn, World.tscn + component scenes
├── scripts/               ← game.gd (autoload: trades/satchel/charts/gold/
│   │                        tutorial/save), player_controller, layout_loader
│   │                        (dungeon build), town, combatant/boss, panels
│   └── ui/                ← wyrd_ui.gd (kit tokens + styleboxes), panels
├── data/                  ← charts.gd, gather.gd, crafting.gd, items.gd,
│   │                        drops.gd, economy.gd, elites.gd, affixes.gd
├── assets/                ← ui kit textures, fonts (IM Fell, Caveat),
│   │                        painted icons, cursors
├── audio/                 ← ElevenLabs SFX (tools/generate_audio.py)
├── models -> ../models    ← SYMLINK; do not break
├── textures/crypt -> ../../docs/concept-art/dungeons/crypt   ← SYMLINK
└── tools/                 ← capture_ui.sh, generate_audio.py,
                             check_ninepatch.py
models/                    ← all GLBs (Meshy/Blender pipeline)
docs/                      ← world bible, plans, specs/, adr/, ui-refs/
```

## Conventions

- **Language (CONTEXT.md):** a leveling discipline is a **Trade** (carto =
  Wayfinder, earth = Earthcraft, wilds = Wildcraft); "Skill" means hotbar
  abilities only. **Chart** not map/keystone; **Affix** good/bad twins;
  **GatherNode** kinds ore_rock / forage_node / log_pile.
- **UI:** everything derives from the Wayfinder UI Kit (Claude Design
  project `wayfinder-ui` + `wyrd/scripts/ui/wyrd_ui.gd` tokens/styleboxes).
  Ornament lives on frames/headers; body text is plain and high-contrast.
  New frame-like art must pass `wyrd/tools/check_ninepatch.py`.
- **Never `load()` a texture first inside `_draw()`** — it renders as a
  white rect forever (memory: godot-draw-load-white-texture). Preload in
  `_ready`.
- **All player-visible writing** follows `docs/WORLD_BIBLE.md` voice; code
  identifiers stay generic.
- Plans/state: `docs/wyrd-roadmap.md` (consolidated), detail in
  `docs/wyrd-skills-combat-plan.md`, `docs/wyrd-ui-design-pass.md`,
  `docs/specs/` (+ per-spec notes files).
