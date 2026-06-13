---
type: source
tags: [source-digest, pipeline]
status: draft
updated: 2026-06-13
sources: ["docs/GODOT_PIPELINE.md", "docs/BLENDER_PIPELINE.md", "docs/ASSET_PIPELINE.md", "docs/ANIMATION_PIPELINE.md", "docs/ART_BIBLE.md", "docs/MODEL_REBUILD_RECIPE.md", "docs/character-pipeline/MESHY_OPERATIONS.md", "docs/character-pipeline/MODEL_DESCRIPTION_TEMPLATE.md", "docs/character-pipeline/AI_WORKFLOW.md", "docs/wyrd-animation-backlog.md"]
---

# Source Digest — Pipeline Cluster

Documents read to produce the five pipeline wiki pages. One-line summary of each, with the wiki pages it fed.

## Sources read

| File | Summary | Wiki pages fed |
|---|---|---|
| `docs/GODOT_PIPELINE.md` | Comprehensive Godot 4.6 project doc: engine setup, project layout, WYRD_* dev hooks, headless test suites, procgen dungeon system (TinyKeep method, scoring), collision layers, skill/status/loot/boss specs (specs 07–33a), web export size tradeoffs | [[Godot Pipeline]] |
| `docs/BLENDER_PIPELINE.md` | End-to-end Blender recipe: setup, reference-image workflow, three modeling approaches, Principled BSDF material recipe, rigging options (Mixamo / AccuRig / manual Rigify), glTF export settings, loading in three.js | [[Blender Pipeline]], [[Asset Pipeline]] |
| `docs/ASSET_PIPELINE.md` | Full concept-to-game workflow: phase 0 (decide), phase 1 (Midjourney), phase 2A/B/C (Blender model / dummy / rig), phase 3 (wire into game), phase 4 (validate); named-group rig contracts for biped/quadruped/bird/static | [[Asset Pipeline]], [[Blender Pipeline]] |
| `docs/ANIMATION_PIPELINE.md` | Two animation strategies (procedural vs. skinned), per-animation process (design → reference → author → wire → polish), taxonomy by kind, status flags, pitfalls (re-parent, don't mix strategies, rawDt for hitstop) | [[Animation Pipeline]] |
| `docs/ART_BIBLE.md` | Master style stem (RuneScape 3 × Genshin Impact), three hero shots to generate first, character/item/prop/tile prompt examples, workflow to lock the palette, anti-style rejection criteria | [[Art Bible]] |
| `docs/MODEL_REBUILD_RECIPE.md` | Synthesis of silhouette rules, shape language (circle/square/triangle), palette discipline (5–8 hues, one saturation peak, warm-light/cool-shadow), bevel+toon Blender Python recipe, named-group rig engine contract, common defects + fixes | [[Blender Pipeline]], [[Art Bible]] |
| `docs/character-pipeline/MESHY_OPERATIONS.md` | Three Meshy recipes: A (re-texture rigged body), B (add bow-draw clip via Animation Library or Mixamo fallback), C (generate new prop via Image-to-3D); Meshy hard-won facts (auto-rig on native t-pose only, dense mesh cap, rigging humanoid-only, texture after rigging, use with-skin variant) | [[Asset Pipeline]], [[Animation Pipeline]] |
| `docs/character-pipeline/MODEL_DESCRIPTION_TEMPLATE.md` | Template for character description files: identity, proportions, palette table, parts table, rig layout, surface texture approach, outline strategy (`_ruffle`/`_detail`/`_line`), validation checklist; filled Wren the Tinker example | [[Blender Pipeline]], [[Art Bible]] |
| `docs/character-pipeline/AI_WORKFLOW.md` | End-to-end Meshy AI character workflow: Stage 1 (Meshy Image-to-3D), Stage 2 (`clean_ai_mesh.py` flags and internals), Stage 3 (register in codex), Stage 4 (verify rig parts), Stage 5 (game integration — loader/builder/spawn/routing), Stage 6 (live test); troubleshooting table | [[Asset Pipeline]] |
| `docs/wyrd-animation-backlog.md` | Prioritized animation backlog as of 2026-06-12: P1 (gather channel poses, quaff, bench socket snap, bench pot mix, bench craft scroll, Waystone chart socket), P2 (combat skill VFX), P3 (ambient/UI polish); implementation notes (drawn-UI uses queue_redraw, player poses use procedural rigs, particles use assets/vfx/) | [[Animation Pipeline]] |

## Key contradictions noted

1. **GODOT_PIPELINE.md** is written partly in the context of the old `godot/` evaluation project (pre-2026-06-12 three.js removal), referencing `three.js` as "the live game." As of 2026-06-12, the three.js prototype was removed and Godot (`wyrd/`) is the live project. The GODOT_PIPELINE.md content from specs 07–33a describes the current Godot game accurately; the framing at the top ("three.js is the live one") is stale.

2. **BLENDER_PIPELINE.md** describes a pure three.js loading pattern (`src/anim/skeletal.js`, `src/scene/characters.js`) that still exists in git history but not in the current `wyrd/` codebase. The Blender modeling recipe itself (bevel, materials, export settings) remains valid for both paths.

3. **ANIMATION_PIPELINE.md** references `src/data/animations.js` (three.js) as the central animation registry. In the live Godot project, animation registration has moved to GDScript (`anim_driver.gd` + `AnimationPlayer`). The taxonomy and design process described remain valid guidance.

## What the pipeline cluster covers

- How the Godot 4.6 engine project is structured, run, and tested
- The complete art-production workflow from concept art (Midjourney) through AI 3D generation (Meshy) and manual authoring (Blender) to GLB files in `models/`
- Two animation strategies and the current backlog of owed animations
- The visual style target (master style stem, palette rules, shape language, anti-style list)
- The UI kit and Godot-side texture loading gotcha

## Wiki pages produced

- [[Godot Pipeline]] — engine setup, project structure, dev hooks, test suites
- [[Blender Pipeline]] — bevel + toon recipe, two-tier root, socket authoring
- [[Asset Pipeline]] — AI image-to-3D flow (Midjourney → Meshy → clean_ai_mesh → Blender → game)
- [[Animation Pipeline]] — procedural vs. skeletal, backlog, pitfalls
- [[Art Bible]] — visual style, master stem, shape language, UI kit, anti-style
