# Wayfinder

A cozy fairytale dungeon-crawler set in **Bramblewood**, built in
**Godot 4.6** — where the heart of the game is a trade called
**Wayfinding**: you forage, mix inks, and inscribe **charts** (dungeon
keys) whose affixes shape every run. Gather → craft → chart → delve,
then return to a village that grows with you.

![The Chartmaker's Yard](docs/media/town.png)

## What's in the game

- **The chart loop** — inscribe charts at a Minecraft-style crafting
  bench (placement sockets, live affix-odds preview, an on-bench mixing
  pot), socket them at the Waystone, and delve procedurally generated
  hollows shaped by the affixes you rolled. 15 rollable affixes, each
  with a good and a bad twin.
- **Recipe discovery** — ink recipes aren't given; you find them by
  experimenting at the pot. Misses smudge (or yield a wild ink, or — 
  rarely — serendipity); NPC riddles point the way; the codex tracks it.
- **Four trades to the level-23 cap** — Wayfinding, Earthcraft,
  Wildcraft, and Huntcraft (kills feed it), each with a full unlock
  ladder: 6 herb tiers, 5 ore tiers, a 24-recipe forge, Quill's buff
  tonics, and perks that change how you play.
- **Combat as one verb** — a 4-slot hotbar picked from 9 skills
  (pierce, thorn nova, hunter's mark, bark-skin ward, execute…),
  per-kind enemy AI, elites with storybook modifiers, and a trophy
  chain of three bosses leading to the Summit.
- **Authored randomness** — layouts and contents remain procedural, while
  up to three player-made Affixes bias enemy vigor, elite frequency,
  resources, and other encounter distributions.

| | |
|---|---|
| ![The Crafting Bench](docs/media/crafting-bench.png) | ![The Trades page](docs/media/trades.png) |
| ![A chart run](docs/media/dungeon.png) | ![The Chartmaker's Yard](docs/media/town.png) |

## Run it

**[Play Wayfinder in your browser](https://bbroeking.github.io/gj26/play/)** —
single-player, no download required.

Requires [Godot 4.6](https://godotengine.org/).

```bash
godot --path wyrd
```

First Road review routes:

```bash
WYRD_NO_SAVE=1 WYRD_DEV_FIRST_ROAD=choice godot --path wyrd
WYRD_NO_SAVE=1 WYRD_DEV_FIRST_ROAD=kind godot --path wyrd
WYRD_NO_SAVE=1 WYRD_DEV_FIRST_ROAD=bold godot --path wyrd
WYRD_NO_SAVE=1 WYRD_DEV_FIRST_ROAD=returned godot --path wyrd
```

Responsive-road review capture (1280×720, production Bold Road, WASD + roll):

```bash
WYRD_NO_SAVE=1 WYRD_MOVEMENT_CAPTURE_DIR=/tmp/wayfinder-motion godot --path wyrd --script res://tools/capture_movement_checkpoint.gd
```

**Keys:** WASD move · 1–4/F skills · E interact · Q quaff · G grab ·
I pack · M satchel · K trades · Space roll · F10 sound (off by default)

## Tests

Twenty headless suites gate every checkpoint (996 assertions at
`0.1.16-shaded-home`; the authoritative list lives in
`docs/test-manifest.md`):

```bash
cd wyrd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_transitions.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_boot_smoke.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_first_road_slice.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_movement_feel.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_hollow_readability.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_first_hollow_room_grammar.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_first_hollow_living_edge.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_web_tonal_separation.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_first_hollow_forest_continuity.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_first_road_soft_ground.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_first_road_open_canopy.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_first_hollow_room_composition.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_first_hollow_room_breathing.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_first_hollow_setpiece_breathing.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_first_hollow_readable_passages.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_creature_codex.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_town_tonal_separation.gd
```

## How it's built

The whole game — code, design docs, balance math, tests, and the art
pipeline — is built in collaboration with **Claude** (Anthropic), with
3D models generated through **Meshy**, concept art through
**Midjourney**, and SFX through **ElevenLabs**. The design history
lives in `docs/`: per-feature specs (`docs/specs/`), architecture
decision records (`docs/adr/`), and the world bible.

## Layout

```
wyrd/        the Godot 4.6 project (scenes, scripts, data tables, tests)
models/      GLB assets (Meshy/Blender pipeline)
docs/        world bible, specs, ADRs, design docs, concept art
```

## Status

A playable demo slice: the full tutorial → chart → trophy chain →
Summit loop works end to end as a single-player game. No
license has been chosen yet — all rights reserved for now.
