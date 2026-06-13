---
type: source
tags: [source-digest, onboarding, history, tutorial, specs]
status: draft
updated: 2026-06-13
sources: ["docs/ONBOARDING.md", "docs/PLAYTEST.md", "docs/wyrd-guide.md", "docs/wyrd-slice.md", "docs/wyrd-implementation-notes.md", "docs/wyrd-roadmap.md", "docs/wyrd-animation-backlog.md", "docs/specs/README.md", "docs/specs/06-crypt-aftermath.md", "docs/specs/07-godot-evaluation.md"]
---

# Source Digest: Onboarding, History, and Tutorial

Covers the ingestion pass that produced [[Onboarding and Tutorial]] and [[Development History]].

---

## Sources read

| Doc | Summary | Wiki pages fed |
|---|---|---|
| `docs/ONBOARDING.md` | Full three.js onboarding design: OSRS Tutorial Island reference, 8-stage sequence (Wizard Aric → sleep), character creator spec (4-option modal, live 3D preview, `localStorage` persistence), UX rules (yellow `!`, click-advance dialog, verb isolation, 200ms feedback). Targeting a life-sim prototype — the NPC names and world details differ from shipped Bramblewood. | [[Onboarding and Tutorial]] |
| `docs/PLAYTEST.md` | Combat feel checklist for the three.js/early-Godot prototype: 21 rated dimensions with tuning constants (HITSTOP 0.09, AGGRO_RADIUS 7.0, boss HP gates 66%/33%). Referenced as the post-tutorial feel check. | [[Onboarding and Tutorial]], [[Combat]] |
| `docs/wyrd-guide.md` | Player-facing game guide for the shipped Wayfinder (Godot, renamed 2026-06-10): controls table, the 6-step loop, chart templates, inks, affixes, trophy chain, Hod, inside-chart room types, death rules, dev tools. Contains the live tutorial flow description. | [[Onboarding and Tutorial]], [[Chart Loop]], [[Charts]], [[Affixes]], [[Inks]] |
| `docs/wyrd-slice.md` | Design doc for the wyrd/ fork (2026-06-09): the 7-step tutorial beat machine (Mara Linnet as guide), chart templates v1, affix table (7 of 16), ink recipes, town layout, architecture changes vs `godot/` fork point. Deviations from keystone doc recorded. | [[Onboarding and Tutorial]], [[Development History]], [[Chart Loop]], [[Charts]] |
| `docs/wyrd-implementation-notes.md` | Build record for wyrd/ + Session 3: adversarial review (~19 issues fixed), implementation decisions (autoload scope, GLB sizing via GlbFit, dialog `_done` guard, E-key conflict), Session 3 (gold economy, trophy chain, town environment pass, 4 Meshy props). | [[Onboarding and Tutorial]], [[Development History]], [[Economy]], [[NPCs]] |
| `docs/wyrd-roadmap.md` | Consolidated roadmap (2026-06-12): full shipped log for specs 42–46 + B5/B6/B7/A6/A7/A8/43/45/gap pass. Three.js removal note. In-flight and next-candidates queue. | [[Development History]], [[Chart Loop]], [[Trades and Leveling]], [[Multiplayer Co-op]] |
| `docs/wyrd-animation-backlog.md` | P1/P2/P3 animation backlog: gather swing loop, quaff, bench socket snap, chart socketing at Waystone, combat ability effects, UI tweens. P1 mostly shipped 2026-06-12. | [[Animation Pipeline]], [[Development History]] |
| `docs/specs/README.md` | Phase 1 spec order (01–05), decisions finalized before specs began, operational defaults. "~90% built already" opening line. | [[Development History]] |
| `docs/specs/06-crypt-aftermath.md` | Three.js spec: village reactions after `cryptCleared`; Cook deep chart gift, Hod/Maud/Quill gossip lines, Withering follow-up, `witherings_signet`. References `src/game/quest.js`, `src/main.js`. | [[Development History]], [[NPCs]] |
| `docs/specs/07-godot-evaluation.md` | Pivot spec: bootstrap `godot/` with crypt layout from JSON snapshot; MCP setup; symlinks for `models/` + crypt textures; explicit "evaluation not migration" framing; dual-engine model; known-good Godot 4.6.2. | [[Development History]], [[Godot Pipeline]] |

---

## Spec timeline skeleton (01–46)

Inferred from directory listing + spec titles — not every spec was read in full:

```
01–06   three.js crypt arc (assets → boss → aftermath)
07      Godot evaluation (pivot spec)
08–12   Godot: procgen quality, camera, physics, animation, knight regeneration
13–22   Godot: bow+arrows, fluid combat, enemy AI, HP, visual sizing, Hedgemother fight,
          walk animation, pathfinding, GLB textures, rat rigging, playtest tuning
23–29   Godot: movement sandbox, dungeon readability, placement polish, typed rooms
30–33a  Godot: skills + cooldowns, status + AoE, pack scaling, pickup/interactable,
          hit feedback, player status
35      HUD upscale
36      Locomotion bindings research (HTML plan)
37      Skill depth research
38–41   UI redesign: tools/mute/globes, panel redesign, UI-from-design, cohesion
42      Chart crafting UI (Crafting Bench replaces menu panel)
43      Recipe discovery ("the experiment" — inks found not given)
45      Trade ladders to cap (carto/earth/wilds/hunt, 4 sub-specs + notes)
46      Multiplayer co-op (Phases A + B shipped; C queue open)
```

Specs 34, 44 absent from directory (not produced or absorbed into adjacent specs). Spec 12 is "knight regeneration" — likely a three.js holdover before the Godot evaluation.

---

## Contradictions and flags

- `docs/ONBOARDING.md` references a **three.js life-sim** (Lumbridge Plains, Wizard Aric, day cycle, fishing) that was entirely replaced by the Bramblewood / Wayfinder / Godot design. The ONBOARDING.md UX rules (yellow `!`, verb isolation, 200ms feedback) remain applicable; the NPC names and world details do not map 1:1 to shipped game. [[Onboarding and Tutorial]] documents both systems distinctly.

- `docs/wyrd-guide.md` lists three trades (Wayfinding, Earthcraft, Wildcraft) without mentioning Huntcraft — the guide predates the B7 Huntcraft spec ship on 2026-06-12 and has not been updated. The roadmap confirms four trades are shipped.

- `docs/wyrd-slice.md §Completion XP` gives `tier×75 + good×40 + bad×10` as shipped; keystone doc has `tier×30…` — noted as a deviation in wyrd-slice.md. Code is tiebreaker; XP formula in `wyrd/data/charts.gd` is authoritative.

- Spec 07 targets `godot/` (the evaluation project); wyrd/ is a later fork. The `godot/` directory was removed along with `src/` on 2026-06-12. Only `wyrd/` remains in the working tree.

---

## What these sources do NOT cover

- ADRs (0003–0006) — covered in the `world-and-decisions` source digest and [[Design Decisions]]
- Art pipeline, Blender/Meshy workflow — covered in `pipeline` source digest
- Charting, inks, affixes deep design — covered in `charting` source digest
- Combat system internals — covered in `combat` source digest
- Multiplayer protocol details — covered in `multiplayer` source digest

## See also

- [[Onboarding and Tutorial]] — primary wiki page synthesized from this digest
- [[Development History]] — primary wiki page synthesized from this digest
- [[Design Decisions]] — ADR digests
- [[Chart Loop]] — the core loop the tutorial teaches
