---
type: source
tags: [source-digest, design-history, archive, three-js]
status: draft
updated: 2026-06-13
sources:
  - "docs/DESIGN_VISION.md"
  - "docs/rune-magic-design.md"
  - "docs/cartography-skill-explorations.md"
  - "docs/cartography-keystone-design.md"
  - "docs/cartography-inscribing-table-design.md"
  - "docs/cartography-inscribing-table-ux-prompts.md"
  - "docs/design/05-boss-design.md"
  - "docs/design/05a-hedgemother-bramble-pull.md"
  - "docs/design/06-equipment-progression.md"
  - "docs/design/07-skill-level-pacing.md"
  - "docs/design/09-active-abilities.md"
  - "docs/design/10-spell-system.md"
  - "docs/design/cartography-depth-20.md"
  - "docs/design/cartography-keystone.md"
  - "docs/design/skills-consolidation.md"
  - "docs/design/town-layout-plan.md"
  - "docs/design/whats-next-research.md"
  - "docs/design/_progress.md"
  - "docs/skills/falconry.md"
  - "docs/skills/magic.md"
---

# Source Digest — Design Archive

Per-document status summary for the source cluster ingested into [[Design Archive]]. These are all pre-Godot (three.js prototype era) or transitional design documents. None of them reflect the current Godot build. The status column classifies each doc's relationship to the current design.

**Status definitions:**
- **superseded** — the idea was replaced by a different design; the source content is obsolete
- **cut** — the idea was considered and explicitly rejected; permanently off the table unless design re-opens it
- **deferred** — the idea is not implemented but remains on the backlog; may ship in a future version
- **partly-live** — portions of the design were implemented; other parts were cut or deferred

---

## Source Table

| Doc (repo-relative) | One-line summary | Status | Wiki page |
|---|---|---|---|
| `docs/DESIGN_VISION.md` | v3 three.js prototype pitch ("Stardew meets RS in browser"); locked 2026-04-29; skill list, day cycle, NPCs, tech stack, jam scope | superseded | [[Design Archive]] §1 |
| `docs/rune-magic-design.md` | Full rune-magic system: 13 rune types, 21 spells, Runestone Pedestal, separate magic skill gated by Carto inks | cut | [[Design Archive]] §2a |
| `docs/cartography-skill-explorations.md` | Wide exploration of 40+ alternative cartography mechanics: survey verbs, decay models, social hooks, cross-skill bleed, narrative quests, wild ideas | superseded | [[Design Archive]] §4b |
| `docs/cartography-keystone-design.md` | Early affix list (~25), chart templates, good/bad-twin mechanics, XP formula — the foundation for the chart system | partly-live | [[Design Archive]] §4a |
| `docs/cartography-inscribing-table-design.md` | Two-tier alchemical crafting: 3×3 pattern-based ink recipes (Tier 1) + ink-slot chart inscription (Tier 2); 15-ink catalog, Recipe Codex, 10 UI prompts | partly-live | [[Design Archive]] §4c |
| `docs/cartography-inscribing-table-ux-prompts.md` | 8 Midjourney prompts for inscribing table UX moments (empty, mid-experiment, matched, hover ghost, success, smudge, codex, auto-fill); locked style stem + --sref | superseded | [[Design Archive]] §4d |
| `docs/design/05-boss-design.md` | Boss infrastructure audit for three.js (Hedgemother/Burrow Boar/Wolf Alpha); proposes unique mechanics per boss; references Hades/HK/OSRS | superseded | [[Design Archive]] §5a |
| `docs/design/05a-hedgemother-bramble-pull.md` | Detailed code sketch for Hedgemother phase-2 bramble-vine pull mechanic in three.js enemies.js; ~50-line diff | superseded | [[Design Archive]] §5b |
| `docs/design/06-equipment-progression.md` | Equipment audit for three.js (3 tiers, sword/dagger); proposes weapon-class differentiation, trinket slot, named endgame weapons, horizontal progression | superseded | [[Design Archive]] §6 |
| `docs/design/07-skill-level-pacing.md` | XP curve audit for three.js (quadratic `(n-1)²×8`); measured Lv 1–99 table; proposed cap at 25, 3 milestones/skill, raise early coefficient | deferred | [[Design Archive]] §3c |
| `docs/design/09-active-abilities.md` | 12-ability audit for three.js; found all-atk default bindings; shipped slot rebalance to one-per-tree; proposes weapon-bound slot-1 specials | superseded | [[Design Archive]] §7 |
| `docs/design/10-spell-system.md` | Three.js spell-handler audit: 21 spells, only 8 wired; 4 state-only, 8 explicit stubs, 1 runtime bug (`quench_stamina`); recommends cap at 8–10 v1 spells | superseded | [[Design Archive]] §2b |
| `docs/design/cartography-depth-20.md` | 20-idea Carto backlog (tagged S/M/L): Atlas, NPC-signed, themed families, echo charts, folded, seeds, vessels, living atlas, cursed, etc. | partly-live | [[Design Archive]] §4e |
| `docs/design/cartography-keystone.md` | Framing doc: Carto as progression spine; proposed unified Cartography Workshop UI (📐 HUD button, 4-launcher panel) | partly-live | [[Design Archive]] §4f |
| `docs/design/skills-consolidation.md` | Merges 13-skill list to 10 (wilds=forage+fish+wc, earth=mine+smith); milestones, XP routing, save migration helper | superseded | [[Design Archive]] §3a |
| `docs/design/town-layout-plan.md` | 60×30 tile village layout plan for three.js; NPC grouping by function, village-green spawn center, hedge boundary, path-east-to-danger | superseded | [[Design Archive]] §9 |
| `docs/design/whats-next-research.md` | April 2026 gap analysis on three.js prototype; 7-pillar ARPG-feel score (avg 7.1); gaps: loot juice, boss mechanics, ambient music, equipment depth | superseded | [[Design Archive]] §10 |
| `docs/design/_progress.md` | Self-paced iteration log over 5 design docs (05–10); documents what was shipped per deep-dive, what's gated on user input | superseded | [[Design Archive]] (all §§) |
| `docs/skills/falconry.md` | Falconry as standalone skill: Pernel companion, 3 milestones (scout/combat-assist/forager), partial three.js implementation | superseded | [[Design Archive]] §3b |
| `docs/skills/magic.md` | Magic skill reference for three.js (21 spells, ink-to-rune mapping, rune slot in charting at carto 50+magic 30) | partly-live | [[Design Archive]] §2a |

---

## Cross-reference: what fed which wiki pages

| Wiki page | Key source docs |
|---|---|
| [[Design Archive]] | All 20 sources above |
| [[Charts]] | `cartography-keystone-design.md`, `cartography-depth-20.md`, `cartography-inscribing-table-design.md` |
| [[Affixes]] | `cartography-keystone-design.md` |
| [[Inks]] | `cartography-inscribing-table-design.md`, `rune-magic-design.md` (ink-to-rune mapping) |
| [[The Crafting Bench]] | `cartography-inscribing-table-design.md`, `cartography-inscribing-table-ux-prompts.md` |
| [[Wayfinding]] | `cartography-keystone.md`, `cartography-depth-20.md` |
| [[Trades and Leveling]] | `skills-consolidation.md`, `DESIGN_VISION.md` |
| [[Combat]] | `DESIGN_VISION.md`, `09-active-abilities.md`, `rune-magic-design.md` |
| [[Skills]] | `09-active-abilities.md` |
| [[Bosses]] | `05-boss-design.md`, `05a-hedgemother-bramble-pull.md` |
| [[Items and Gear]] | `06-equipment-progression.md` |
| [[Enemies]] | `05-boss-design.md` |
| [[Huntcraft]] | `skills-consolidation.md` (combat triple context) |
| [[Wildcraft]] | `skills-consolidation.md` (wilds merge), `skills/falconry.md` |
| [[Earthcraft]] | `skills-consolidation.md` (earth merge) |
| [[Concept Art Prompts]] | `cartography-inscribing-table-ux-prompts.md` |
| [[Balance Philosophy]] | `07-skill-level-pacing.md`, `whats-next-research.md` |

---

## Notes on safe deletion

These source docs are safe to archive (move to `kb/raw/` or compress in git) once the following are confirmed:

1. `docs/DESIGN_VISION.md` — superseded; content fully captured in [[Design Archive]] §1. Safe to archive.
2. `docs/rune-magic-design.md` — fully captured in §2a. The ink-to-rune mapping that survived is in `wyrd/` code. Safe to archive.
3. `docs/cartography-skill-explorations.md` — fully captured in §4b. No active design dependency. Safe to archive.
4. `docs/cartography-keystone-design.md` — partly-live; the live affix/chart system supersedes this. Safe to archive.
5. `docs/cartography-inscribing-table-design.md` — partly-live; UI prompts section superseded, but two-tier model is live. **Keep or archive with note** — the recipe catalog detail may still be useful as a cross-reference.
6. `docs/cartography-inscribing-table-ux-prompts.md` — superseded (three.js UI). Safe to archive.
7. `docs/design/05-boss-design.md` — superseded. Design principles captured. Safe to archive.
8. `docs/design/05a-hedgemother-bramble-pull.md` — superseded. Mechanic concept captured. Safe to archive.
9. `docs/design/06-equipment-progression.md` — superseded. Principles captured. Safe to archive.
10. `docs/design/07-skill-level-pacing.md` — deferred; findings relevant but not actively referenced. Safe to archive.
11. `docs/design/09-active-abilities.md` — superseded. Safe to archive.
12. `docs/design/10-spell-system.md` — superseded. Safe to archive.
13. `docs/design/cartography-depth-20.md` — partly-live (some items now live in Godot); **keep as active backlog** — it is explicitly referenced from `docs/skills/carto.md`.
14. `docs/design/cartography-keystone.md` — partly-live; the Workshop UI it proposed is live. Safe to archive once [[Wayfinding]] page is complete.
15. `docs/design/skills-consolidation.md` — superseded. Safe to archive.
16. `docs/design/town-layout-plan.md` — superseded. Principles captured. Safe to archive.
17. `docs/design/whats-next-research.md` — superseded. Safe to archive.
18. `docs/design/_progress.md` — iteration log; no active content dependency. Safe to archive.
19. `docs/skills/falconry.md` — superseded (three.js). Safe to archive.
20. `docs/skills/magic.md` — partly-live (rune-slot cross-skill hook is live); **keep** until the Godot magic implementation is fully documented.

## See also

- [[Design Archive]] — synthesized content from all sources above
- [[Design Decisions]] — the ADRs that closed the design questions these docs raised
- [[Current State]] — what the Godot build does today
