# 48 — Dungeon biomes — implementation notes

Built 2026-06-28/29. Owner asked to complete the dungeon biomes (beyond the
original crypt) with Meshy-generated props.

## What a "biome" is now
Before: a chart `scope` only recoloured the crypt geometry (palette tint). Now
`scripts/layout_loader.gd` has a **biome registry**:

- `SCOPE_BIOME` — maps a chart `scope` → a biome id.
- `BIOMES[id]` — `{decor: {crypt_kind → GLB}, tints: {crypt_kind → Color}, floor_tex}`.
  A biome **reskins the existing crypt decor `kind` slots** (altar/bones/
  sarcophagus/column/brazier/pottery/bookshelf) — so dungeon_gen places decor as
  before; the biome just swaps the mesh + tint. Unmapped kinds (torch_wall/rug/
  chest) and empty biomes fall back to crypt → behaviour-preserving.
- `_resolve_biome()` sets the active biome from `_scope`; `_decor_model(kind)`
  resolves the GLB (biome override → crypt fallback). `_build_decor` applies
  `_unmetal` + `_tint` (or `_outline_only`) to biome props **only** — crypt decor
  keeps its baked materials.

## Why tints
Meshy **lowpoly** props ship **untextured (white)** — no texture, no vertex
colors. So each biome prop gets a single thematic tint + the inverted-hull ink
outline — exactly the treatment the enemy GLBs get. Free, and on-style.

## The biome sets (28 Meshy lowpoly props, `models/biome_<biome>_*_v1.glb`)
| biome | scope(s) | props |
|-------|----------|-------|
| crypt | crypt | (original GLBs) |
| mineral_seam | hollow, tier_1 | ore-vein, crystals, mine cart, timber, lantern, rubble, mushrooms |
| wood_grove | briar_maze, snug | stump, log, bramble arch, toadstools, fern, boulder, fairy ring |
| bog | **mire** | roots, sunken log, dock post, lily pads, will-o-wisp, mud mound, reeds |
| summit | summit | standing stone, snow drift, pine, frost shrub, ice crystal, cairn, signpost |

## New chart scope: `mire` (Sallow Mire)
Bog had no scope, so a new chart was added end to end:
- `data/charts.gd`: `mire` template (tier 2, req_carto 12) + `TEMPLATE_ORDER`.
- `layout_loader`: `SCOPE_BIOME.mire = bog`, `SPAWN_TABLES.mire`, palette case.
- `dungeon_gen` (SCOPE_BANDS/THEMES/SETPIECES) falls back to crypt gracefully —
  fine, since the biome reskins whatever decor kinds get placed. (A bespoke mire
  setpiece pool is a future polish.)
- Also flipped the **Summit** chart `scope: crypt → summit` so the endgame uses
  the snowy summit biome (it was a crypt placeholder).

## Adding a biome later
1. Generate props (Meshy lowpoly text-to-3d, or Midjourney→image-to-3d) → `models/`.
2. `godot --headless --path wyrd --import` to make `.glb.import` sidecars.
3. Add a `BIOMES[id]` entry (decor + tints) and a `SCOPE_BIOME` mapping (and a
   chart template if it needs a new scope). QA via `WYRD_DEV_CHART=<template>`.

## Tooling
`tools/view_biome_props.gd` — offscreen SubViewport montage renderer for QA'ing
prop GLBs up close.
