---
tags: [moc, gj26, index]
---

# gj26 — Map of Content

> [!note] What this is
> The front page for the gj26 project knowledge. Open this folder as an Obsidian vault — every doc here is wikilinked. The 12-stage build pipeline is the spine; the playbooks are the references.

## Project bibles (locked decisions)

The non-negotiables. Update only when a major call changes.

- [[DESIGN_VISION]] — locked genre call (cozy RuneScape × Harvest Moon hybrid), MVP slice, risk register
- [[ART_BIBLE]] — visual target, master prompt stem, hero shots
- [[UI_BIBLE]] — UI design system, tokens, hero screens
- [[WORLD_BIBLE]] — lore + zones
- [[BLENDER_PIPELINE]] — asset workflow, GLB conventions
- [[ONBOARDING]] — Tutorial Island flow mapping

## Build pipeline (the 12-stage spine)

The order of operations from the [[build-stylized-rpg|build-stylized-rpg skill]]. Each stage produces a doc above; each doc cites a playbook below.

| Stage | Goal | Reference playbook |
|---|---|---|
| 1 — Genre survey | Know what game you're making | [[online-games-2000-2010-survey]] |
| 2 — Design vision | Lock the major decisions | [[DESIGN_VISION]] |
| 3 — Visual identity | Lock the look | [[ART_BIBLE]] |
| 4 — Engine bootstrap | Running scene at 60fps | [[threejs-stylized-bootstrap-playbook]] |
| 5 — Asset pipeline | GLB roundtrip Blender→scene | [[BLENDER_PIPELINE]] |
| 6 — UI bible & tokens | Design system locked | [[reference-to-ui-playbook]], [[UI_BIBLE]] |
| 7 — Game systems | Skill list, combat formula, schemas | [[game-balance-playbook]] |
| 8 — Character creation | Modal + 3D preview + persistence | [[character-creator-research]] |
| 9 — Onboarding | Tutorial Island that teaches every system | [[ONBOARDING]] |
| 10 — Content generation | Bulk gear/items/enemies/NPCs | [[content-generation-playbook]] |
| 11 — Balance pass | Difficulty curve right | [[game-balance-playbook]] |
| 12 — Polish & ship | Audio, save versioning, festivals | [[evoke-online-game-feel\|evoke-online-game-feel skill]] |

## Reference playbooks (cross-project knowledge)

### Design philosophy
- [[mmo-game-design-playbook]] — broader MMO theory (Bartle, Sirlin, retention, economy, Dunbar)
- [[cozy-life-sim-design-playbook]] — Harvest Moon / Stardew patterns
- [[online-games-2000-2010-survey]] — 30+ games, era survey, design lessons
- [[fate-2005-deep-dive]] — single-game deep dive on the cozy-ARPG ancestor (narrative + design philosophy)
- [[fate-implementation-summary]] — Fate from a *builder's* angle: schemas, formulas, numbers, 12-step shipping order

### Process playbooks
- [[reference-to-ui-playbook]] — 6-stage UI pipeline (mockup → tokens → HTML/CSS)
- [[content-generation-playbook]] — schemas + tier tables + prompt templates per content type
- [[game-balance-playbook]] — Sirlin's three balances, math toolkit, formulas, processes
- [[character-creator-research]] — 11 case studies + the scope spectrum + recommendations
- [[game-character-animation-playbook]] — Blender → glTF animation pipeline
- [[threejs-stylized-bootstrap-playbook]] — three.js engine setup, perf, post-processing

### AI / engineering reference
- [[evals-and-harnesses-research]] — 2026 state of evals (OpenAI, Anthropic, HN summaries, tooling landscape)
- [[content-evals-playbook]] — applied: 5 layers + balance sim + soul check, gj26-specific. Backed by `gj26/evals/`

## Reference assets (generated)

- `art-refs/` — locked hero shots and prop refs (open in Obsidian as image)
- `ui-refs/` — UI mockups (hero screens, components)

## Skills available (invoke in Claude Code)

The invokable workflows that operate on the docs above. From any conversation:

- `/build-stylized-rpg` — orchestrates the 12-stage pipeline; tells you what's next
- `/evoke-online-game-feel` — design philosophy, scoring rubric for "does this feel right?"
- `/character-creator-design` — character creator design + implementation
- `/game-content-generator` — bulk content (gear, enemies, NPCs, materials)
- `/reference-to-ui` — the 6-stage UI design pipeline
- `/threejs-stylized-game-bootstrap` — engine setup + perf tuning
- `/blender-stylized-game-assets` — 3D asset authoring + GLB export

## Tags

- #project — gj26-specific (bibles)
- #playbook — cross-project reference
- #research — survey / case studies
- #skill — invokable workflow

## How to navigate this vault

1. **Starting fresh**: open this MOC, click [[DESIGN_VISION]] to know what we're building
2. **Picking next work**: ask Claude `/build-stylized-rpg what's the next stage?`
3. **Adding content**: read [[content-generation-playbook]], invoke `/game-content-generator`
4. **Reviewing for soul**: invoke `/evoke-online-game-feel` and score the feature
5. **Stuck**: open [[online-games-2000-2010-survey]] for context on the genre lineage

## Reading lists

For sequenced paths through the docs by task: see **[[../../_READING_LISTS|Reading Lists]]** at the vault root. 11 themed lists (starting a project / adding content / balancing / UI / 3D / philosophy / evals / Fate / onboarding / reference / writing more research).

## Sister vault

For cross-project research not specific to gj26: [[../../research/output/_MOC|research output MOC]]
