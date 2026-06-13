---
type: source
tags: [source, art, content-generation, concept-art, character-pipeline, evals]
status: draft
updated: 2026-06-13
sources: []
---

# Source Digest: Art and Content

Digest of the raw source documents read for the art pipeline and content-generation cluster. Covers character briefs, concept art prompts, and the content-generation/evals methodology.

---

## Character Pipeline Sources

### `docs/character-pipeline/MODEL_DESCRIPTION_TEMPLATE.md`
**Summary:** Canonical template for per-character model briefs — 8 required sections (identity, proportions, palette, parts table, rig, surface texture approach, outline strategy, validation checklist). Includes a fully worked example (Wren the Tinker, ~30 primitives, all positions, skip-outline flags, GLB size projection). Defines the `<Char>_<Slot>` material naming convention, outline suffix conventions (`_ruffle`, `_detail`, `_line`), and the 7-point validation gate.
**Feeds:** [[Character Model Briefs]]

### `docs/character-pipeline/AI_WORKFLOW.md`
**Summary:** End-to-end 6-stage pipeline from Meshy Image-to-3D to a walking in-game NPC. Stage 1: Meshy (Image-to-3D, Stylized preset, ~35 credits). Stage 2: `clean_ai_mesh.py` (weld + decimate + slice into rig parts + named empties). Stage 3: `register_ai_character.py` (codex.js insert). Stage 4: codex verification (all 6 rig parts must appear). Stage 5: `characters.js` + `main.js` integration (loadXxxGLB + buildXxxMesh + NEW_NPCS entry + cache-buster bumps). Stage 6: live test. Troubleshooting table covers 6 common failure modes.
**Feeds:** [[Character Model Briefs]], [[Asset Pipeline]]

### `docs/character-pipeline/MESHY_OPERATIONS.md`
**Summary:** Three Meshy recipes: (A) AI Texturing — re-texture a rigged GLB after Meshy's animation export strips textures; (B) bow-draw animation clip via Meshy Animation Library or Mixamo fallback; (C) prop mesh generation via Image-to-3D with static rig. Hard-won facts: Meshy auto-rig requires native T-pose generations (clean_ai_mesh outputs fail); 300K face cap means dense Meshy 6 meshes need `meshy_remesh` first; "Merged Animations" sidecar GLBs are degenerate — always grab the "with-skin" variant; animation clip names come through in `gltf.animations[].name`. Cost reality: ~29 credits/model (not ~20 advertised). Notes a dual-engine approach — one GLB serves both three.js (via `_v1.glb` procedural rig) and Godot (via `_rigged.glb`).
**Feeds:** [[Character Model Briefs]], [[Asset Pipeline]], [[Animation Pipeline]]

### `docs/character-pipeline/PROP_ATTACHMENT.md`
**Summary:** Sockets (named empties parented to bones) as the prop-attachment primitive. Socket table for the Meshy UniRigArmature 29-bone rig: `socket_hand_L/R`, `socket_back`, `socket_quiver`, `socket_cape`. Two asset-prep strategies: clean re-gen (preferred — generate body without props, props separately) vs surgical extraction (painful). Blender socket authoring recipe. Runtime attachment via `getObjectByName` + `placeInSocket` with per-socket TUNE table. Bow-draw state machine (STOW → DRAW → AIM → RELEASE → STOW) with prop reparenting and clip crossfading. Tool-role breakdown: Meshy generates meshes only; Mixamo provides body clips; game code owns the state machine.
**Feeds:** [[Character Model Briefs]], [[Animation Pipeline]]

### `docs/character-pipeline/bramble_charger.md` (root level)
**Summary:** Full model description brief for the Bramble Charger — the 4-section compact version used for the Meshy pipeline (identity, visual key features, palette, rig type). Compact quadruped boar, body buried under ~28 leaf-cones, cream snout + upturned tusks as silhouette anchors, amber emissive eyes, plank armor on flanks.
**Feeds:** [[Character Model Briefs]], [[Enemies]]

### `docs/character-pipeline/specs/` (11 files)
**Summary:** One-page visual brief for each character in the pipeline. Each file covers: role, one-liner, visual key features, palette (hex codes), rig type, surface texture approach, notable challenges.

| File | Character | Type |
|---|---|---|
| `bramble_archer.md` | Bramble Archer | Enemy (ranged skirmisher) |
| `bramble_charger.md` | Bramble Charger | Enemy (dasher) |
| `brother_pell.md` | Brother Pell | NPC (mendicant scribe) |
| `hedgemother.md` | Hedgemother | Boss (matriarch bramble-spirit) |
| `hedgewight.md` | Hedgewight | Boss (bramble-grown bear-beast) |
| `iron_gob.md` | Iron Gob | Enemy (heavy goblin brute) |
| `marsh_rat.md` | Marsh Rat | Enemy (scaly quadruped) |
| `quill.md` | Quill | NPC (young forager) |
| `sir_withering.md` | Sir Withering | NPC (gnome-knight) |
| `skitterling.md` | Skitterling | Enemy (lesser bramble spirit) |
| `tusker_sow.md` | Tusker Sow | Enemy (boar matriarch) |

**Feeds:** [[Character Model Briefs]], [[Enemies]], [[Bosses]], [[NPCs]]

### `docs/build-plans/eldra.md`
**Summary:** Complete build plan for Eldra the Lampwright — the most detailed character build doc in the project. 65 total parts across STAFF (8), LANTERN×2 (10), BEARD (10), HAIR (8), BACKPACK (7), and standalone parts. Defines 10-hue palette with `lantern_flame` as the one saturation peak (emissive 2.5). Animation contract: biped 6-empty rig, `cadenceMul: 0.7`, `leanMul: 1.6`, `locked_arms: R`. Includes v1.1 detail additions (+780 tris) and concept/model alignment checklist (24 items — 19 captured, 4 deferred).
**Feeds:** [[Character Model Briefs]], [[NPCs]]

### `docs/research/eldra/_principles.md`
**Summary:** Six art-style principles derived from `~/projects/research/wiki/art/` applied to Eldra's iterative redesign: (1) shape commitment — pick a primary shape and exaggerate past comfort (Eldra = CIRCLE); (2) hierarchy — 60-70% primary, 20-30% secondary, <10% tertiary; (3) limited palette — 5–8 hues, ONE saturation peak (lantern flame); (4) cel shading — tone ramp + inverted-hull outline + flat textures; (5) Wind Waker chibi proportions; (6) thumbnail test — 64×64 silhouette read. Includes a planned test matrix (r009–r011) for palette desat and hue-reduction variants.
**Feeds:** [[Character Model Briefs]], [[Art Bible]]

---

## Concept Art Prompt Sources

### `docs/concept-art-prompts-master.md`
**Summary:** 53 prompts across 9 categories (A–I), all shipped 2026-05-01. Locked character stem: "Stylized low-poly fantasy RPG render in the style of RuneScape 3 meets Genshin Impact…". Locked item stem: "Stylized low-poly fantasy RPG item render…, 3/4 top-down icon angle, slight drop shadow." Categories: A (6 player archetypes), B (7 enemies), C (12 weapons by tier), D (3 shields), E (4 armor), F (9 quest items), G (5 cartography props), H (4 new NPCs), I (3 environment landmarks). Workflow guidance: save to `docs/concept-art/<slug>.png`, append to `INDEX.md`, hand slug to engineer.
**Feeds:** [[Concept Art Prompts]]

### `docs/concept-art-prompts-archetypes.md`
**Summary:** Three prompts for v2 archetype rebuilds (Knight, Druid, Wanderer). Uses the same locked character stem. Key Blender note: use `keep_transform=False` when parenting rig empties — `keep_transform=True` bakes parent world position into `parent_inverse`, cancelling the rig position (the v2 GLB collapse-to-origin bug). Save to `docs/art-refs/<slug>_archetype.png`.
**Feeds:** [[Concept Art Prompts]], [[Blender Pipeline]]

### `docs/concept-art-prompts-cow.md`
**Summary:** Brindlecow prompt using the locked character stem. Key visual requirements: one coherent shape, head directly against body, spots on body surface (not floating), all four legs reach ground. Documents three failure modes from the previous `cow.glb` build. Includes rebuild plan: ~12–15 Blender primitives, spots welded onto body mesh, named rig empties Body/Head/Tail/Leg_FL/FR/BL/BR preserved for animation compatibility.
**Feeds:** [[Concept Art Prompts]], [[Character Model Briefs]]

### `docs/concept-art-prompts-next.md`
**Summary:** Batch 2 prompts (25 subjects) organized into groups A–F. Uses an alternative "hand-painted storybook concept art" stem with a soft watercolor wash voice — this stem was later rejected in favor of the chunky-toon stem (see skills prompts). Groups: A (5 village ambient props), B (4 new NPCs overlapping master sheet H), C (4 mid-tier hostile creatures), D (3 landmarks), E (4 quest props), F (5 cartography items). Items largely overlap with master sheet F–I but the stem is a useful alternative stem reference.
**Feeds:** [[Concept Art Prompts]]

### `docs/concept-art/INDEX.md`
**Summary:** Status table for all generated PNGs. Columns: file, subject, status (Shipped/Placeholder/Missing), mesh notes. Tracks which GLBs are still placeholders needing new concept art. As of the index: hedgewight.glb and bramble-imp.glb use tinted placeholder GLBs; wolf-alpha and burrow-boar GLBs are missing; hedgemother.glb is shipped. Dummy models table lists 7 slugs with their base mesh, what they represent, and the concept-art prompt to use.
**Feeds:** [[Concept Art Prompts]], [[Enemies]], [[Asset Pipeline]]

### `docs/concept-art/dungeons/crypt/PROMPTS.md`
**Summary:** 20 crypt tile prompts for the mossy fairytale crypt biome. Master stem uses `--cref dungeon-interior-1.png --cw 50` for style lock. Per-piece polycount targets: 3,000 for floors/walls/small props, 5,000 for furniture, 2,000 for tiny doodads. ASCII layout file format with 19-character legend mapping chars to GLBs. Floor tile shortcut: use the PNG as a tileable texture on a PlaneGeometry rather than going through Meshy (Meshy struggles with flat tiles). Future biomes follow the same template with a different `--cref`.
**Feeds:** [[Concept Art Prompts]], [[Dungeon Generation]]

### `docs/concept-art/enemies/PROMPTS.md`
**Summary:** 4 crypt enemy prompts using niji 6 (`--niji 6 --ar 3:4 --stylize 400`). Enemies: Skeleton (biped, 5k tris, HP 18), Crypt Rat (quadruped, 3k tris, HP 8), Ghost (static, 3k tris, HP 14 — animator handles bob), Hedge-Sprite (biped, 5k tris, HP 22). Meshy settings: Standard model (not Stylized for this batch), A-pose for bipeds. Post-GLB work: `enemies.js` stat registry, `src/anim/<name>.js` × 4, `dungeonSpawns.js` `MOB_CRYPT` entries.
**Feeds:** [[Concept Art Prompts]], [[Enemies]], [[Dungeon Generation]]

### `docs/concept-art/ranger-props/PROMPTS.md`
**Summary:** 6 prop/expression assets for the Mosscloak Ranger. Covers: stripped body (A-pose, `--cw 80` with `archer-player.png` as `--cref`), bramble longbow (must say "archery weapon" to avoid ribbon confusion), single arrow (`--ar 16:9`, origin at nock end pointing +X), quiver (Symmetry Off), hooded cloak (back view), expression sprite sheet (4×2 grid, 8 expressions). Expression atlas engine integration using UV offset (`repeat.set(1/4, 1/2)` + `offset.set(col/4, 1-(row+1)/2)`). Post-gen flow: Meshy → sockets → Mixamo clips → `rig_test.html` swap → face quad + `setExpression`.
**Feeds:** [[Concept Art Prompts]], [[Character Model Briefs]], [[Animation Pipeline]]

### `docs/skills/CONCEPT_ART_PROMPTS.md`
**Summary:** 13 ability codex prompts. First batch (2026-05-26) rejected — watercolor stem produced "blurry atmospheric mist, not chunky toon." Second stem: "Storybook chunky cartoon illustration, bold black ink outlines, flat cel-shaded colors, thick linework…" `--ar 16:9 --v 6 --stylize 50 --no blur, mist, painterly, soft photo`. Includes job_ids for the rejected first-batch images for reference.
**Feeds:** [[Concept Art Prompts]], [[Art Bible]]

### `docs/prompts/eldra_iterations.md`
**Summary:** 5 Blender script iteration prompts (A–E) for the Eldra redesign — not Midjourney, but structured prompts to a code-execution agent for Blender. Each tests one lever in isolation (tapered limbs, asymmetry, round forms, multi-shade gradient cloth, cylinders + sphere head). Includes GOAL/REFERENCE/PIPELINE/WHAT-IT-MEANS/CONSTRAINTS/GRADE sections. Winner: Variant A (tapered limbs). Variant E (full cylinders + sphere head) pushes the direction further and is the planned propagation pattern for other NPCs.
**Feeds:** [[Concept Art Prompts]], [[Character Model Briefs]], [[Blender Pipeline]]

---

## Content Generation and Evals Sources

### `docs/content-generation-playbook.md`
**Summary:** The generator reference — schemas, tier tables, and LLM prompt templates for all five content axes (items, skills, enemies, NPCs, materials). Defines the 6 gear tiers (Bronze through Rune), consumable tiers (Snack through Feast), 5 enemy tiers (Trivial through Boss), and 5 skill stages (Apprentice through Legend). Provides per-type prompt templates (weapons, armor, consumables, gathering materials, enemies, NPCs, skills). Validation checklist with per-type rules. Worked example: 5 iron weapons — all pass tier budget, naming convention, and voice check. When NOT to use the generator: hero items, quest-critical items, first entry of a new category, onboarding items.
**Feeds:** [[Content Generation and Evals]], [[Economy]], [[Items and Gear]]

### `docs/content-evals-playbook.md`
**Summary:** The 7-layer eval pipeline with full code examples. Code-based layers: (1) schema eval — required fields, type checks, slot validity, description length; (2) tier conformance — `atk + str === WEAPON_TIER_BUDGET[tier]` etc.; (3) cross-reference integrity — NPC gift lists → items.js, enemy drops → items.js, `cooked_X` → `raw_X` exists. LLM-grader layers: (4) voice & style — 1–7 score, fail < 5; (5) lore consistency — reads `WORLD_BIBLE.md`, verdicts: consistent/contradiction/new_lore/tone_mismatch; (6) balance sim — Monte Carlo win-rate targets per tier; (7) soul check — 9-feeling rubric from `evoke-online-game-feel`, threshold ≥ 12. `run-all.js` orchestrator; `--full` flag enables LLM graders. Story consistency: character-constraints.yml as YAML NPC constraints; for jam scope write heart events by hand.
**Feeds:** [[Content Generation and Evals]]

### `docs/evals-and-harnesses-research.md`
**Summary:** 2026 survey of the eval/harness discipline. Central claim: "the AI" is the cybernetic system of model + harness — harness changes alone improved 15 LLMs at coding in one afternoon. Anthropic's Opus 4.5 scored 42% on CORE-Bench, then 95% after fixing harness bugs (rigid grading, ambiguous tasks, stochastic tasks, over-constrained scaffold). Key HN consensus: cross-model grading is essential; going from 0 to 5 tests beats 50 to 500. 2026 tooling: OpenAI Evals (reference), DeepEval (pytest-style, 12k stars), Promptfoo (CLI + red-teaming), Langfuse (observability, acq. ClickHouse Jan 2026), Arize Phoenix (OSS), Braintrust (all-in-one). Recommended stacks: Promptfoo + Arize Phoenix (engineer-owned, $0) or Braintrust (managed). Seven rules distilled from the research; applied to Wayfinder in `content-evals-playbook.md`.
**Feeds:** [[Content Generation and Evals]]

---

## What These Sources Feed

| Source cluster | Wiki pages produced |
|---|---|
| Character pipeline docs (MODEL_DESCRIPTION_TEMPLATE, AI_WORKFLOW, MESHY_OPERATIONS, PROP_ATTACHMENT, specs/) | [[Character Model Briefs]] |
| Concept art prompt files (master, archetypes, cow, next, INDEX, crypt/PROMPTS, enemies/PROMPTS, ranger-props/PROMPTS, skills/CONCEPT_ART_PROMPTS, eldra_iterations) | [[Concept Art Prompts]] |
| Content generation and evals docs (content-generation-playbook, content-evals-playbook, evals-and-harnesses-research) | [[Content Generation and Evals]] |

Secondary feeds (cross-links from the pages above): [[Enemies]], [[Bosses]], [[NPCs]], [[Art Bible]], [[Asset Pipeline]], [[Animation Pipeline]], [[Blender Pipeline]], [[Dungeon Generation]], [[Economy]], [[Items and Gear]], [[Trades and Leveling]], [[Balance Philosophy]]

## See also

- [[Character Model Briefs]] — primary output of the character pipeline sources
- [[Concept Art Prompts]] — primary output of the concept art sources
- [[Content Generation and Evals]] — primary output of the playbook sources
- [[pipeline]] — source digest for the broader pipeline cluster
