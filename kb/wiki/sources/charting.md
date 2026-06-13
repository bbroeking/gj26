---
type: source
tags: [charting, wayfinding, source-digest]
status: draft
updated: 2026-06-13
sources: ["docs/cartography.md", "docs/cartography-systems.md", "docs/cartography-keystone-design.md", "docs/cartography-inscribing-table-design.md", "docs/cartography-progression.md", "docs/cartography-skill-design.md", "docs/specs/42-chart-crafting-ui.md", "docs/specs/42-chart-crafting-ui-notes.md", "docs/specs/43-recipe-discovery.md", "docs/specs/43-recipe-discovery-notes.md", "docs/specs/08-quality-procgen.md", "docs/specs/25-interesting-dungeons.md", "docs/specs/28-dungeon-placement-polish.md", "docs/specs/29-typed-room-contracts.md", "wyrd/data/charts.gd", "wyrd/data/affixes.gd"]
---

# Source Digest — Charting

Summary of all sources read for the charting cluster. These fed the pages [[Chart Loop]], [[Dungeon Generation]], [[Charts]], [[Affixes]], [[Inks]], [[The Crafting Bench]], and [[The Waystone]].

## docs/cartography.md

High-level overview of the Cartography skill as implemented in the three.js prototype. Covers the four main verbs (sketch, mix, transmute, inscribe), village locations (Chartmaker's Stone, Maud's Hut, Quill the herbalist), the ink-to-rune table, the chart variety table (Tier 1–3), and the tutorial path. Contains prototype code paths (`src/ui/inscribingTable.js`, etc.) superseded by Godot.

**Fed**: [[The Waystone]] (location), [[Charts]] (variety table), [[Inks]] (ink list)

## docs/cartography-systems.md

Describes four systems built on the keystone arc: the Cartography Workshop (hub UI), the Living Atlas (meta-map progression), Echo Charts (overworld-inversion runs), and Inkwell Vessels (cross-skill tier-3 ink gating). All four are three.js prototype designs; none are fully ported to Godot yet.

**Fed**: [[Chart Loop]] (Living Atlas, echo charts), [[Inks]] (tier-3 vessels, design-only)

## docs/cartography-keystone-design.md

Core design document for the chart-as-keystone system. Defines the six affix categories, the full ~25-affix design-stage list, the seven chart templates, the XP completion formula (old version), and open design questions (loot pity, boss-affix cost, dungeon save state). This is the authoritative design intent document; code in `wyrd/data/charts.gd` is the current behavior when they conflict.

**Fed**: [[Affixes]] (full list, categories), [[Charts]] (template table), [[Chart Loop]] (XP formula discrepancy)

## docs/cartography-inscribing-table-design.md

Detailed design for the two-tier alchemical crafting system: the 3×3 ingredient grid for making inks (Tier 1) and the ink-slot inscription UI for charts (Tier 2). Describes 15 target ink recipes, the spatial pattern system, the Recipe Codex, the smudge/wild-ink fallback, and UI design prompts. The 3×3 grid was NOT ported to Godot (per spec 43 notes); shipped uses a mixing-pot quantity recipe system instead.

**Fed**: [[The Crafting Bench]] (two-tier design, Codex, smudge mechanic), [[Inks]] (full 15-ink design list vs 8 shipped)

## docs/cartography-progression.md

Full Wayfinder unlock table from Lv 1 to Lv 99: track breakdown (map vision, chart templates, ink recipes, resource bias, specialty paths, endgame), every level with a named title and unlock description, density analysis, and implementation hook (`CARTO_UNLOCKS` in `src/ui/worldMap.js`).

**Fed**: [[Chart Loop]] (progression table), [[Charts]] (template level gates), [[Wayfinding]] (skill milestones)

## docs/cartography-skill-design.md

Companion to the keystone design, covering the four-phase active skill loop: Survey (Surveyor's Poles + triangulation), Sketch (Field Journal, Pokédex-shaped collection), Inscribe (the chartmaker's desk outputs), and Walk (passive tile XP trickle). Also covers specialty paths (Hydrographic/Geological/Biological), NPC integration (Chartmaker, Sir Withering, Quill, Hod, Brother Pell), risk/failure modes, and the Atlas of Bramblewood endgame.

**Fed**: [[Wayfinding]] (four-phase skill), [[Chart Loop]] (Atlas endgame), [[NPCs]] (NPC roles)

## docs/specs/42-chart-crafting-ui.md

Spec for the Crafting Bench UI replacement (phase 1: placement sockets + mixing pot; phase 2: tutorial rework). Defines the three-panel bench layout, satchel tray, base/ink/trophy sockets, result slot with live odds, mixing pot sub-area, tutorial highlight mechanism, and the contract (unchanged GDScript function signatures).

**Fed**: [[The Crafting Bench]] (primary spec)

## docs/specs/42-chart-crafting-ui-notes.md

Implementation notes for spec 42. Key decisions: click-crafts (no drag-out), public bench API for headless testing, auto-mix on exact recipe match, trophy tray rows hide when empty, tutorial highlight = pulsing gold ring with soft-locks. Notable: the old `inscribing_panel.gd` deleted cleanly.

**Fed**: [[The Crafting Bench]] (implementation decisions)

## docs/specs/43-recipe-discovery.md

Spec for ink-recipe discovery at the bench. Inks start unknown (except Hedge Ink); "Try the Mix" button enables risky experimentation; three outcomes on failure (smudge/wild/serendipity); two new inks added (Ash Ink, Chalkwash Ink); codex strip on the bench.

**Fed**: [[Inks]] (discovery system, two new inks), [[The Crafting Bench]] (Try the Mix, codex strip)

## docs/specs/43-recipe-discovery-notes.md

Implementation notes for spec 43. Key decisions: 3×3 spatial grid not ported (quantity-match instead), auto-mix stays for discovered recipes, consolation = cheapest pot material, serendipity hands the bottle not the recipe, riddle gating rides `seen_hints`. Notes the 5-row codex caused panel height growth (560 → 620px).

**Fed**: [[Inks]] (deviation: no spatial grid), [[The Crafting Bench]] (pot implementation details)

## docs/specs/08-quality-procgen.md

Spec for the Delaunay + MST + generate-and-test dungeon pipeline. Defines the six scoring metrics, the `MAX_ATTEMPTS` retry loop, the boss-room placement (BFS hops not Euclidean distance), the `LOOP_EDGE_FRACTION`, and debug surfacing.

**Fed**: [[Dungeon Generation]] (algorithm, quality scoring)

## docs/specs/25-interesting-dungeons.md

Spec for characterful dungeon interiors: five phases — room roles + themed dressing, varied room shapes, authored ASCII setpieces, loops + optional side-rooms, pacing curve. Defines the seven themes and their dressing rules, the five roles, and the shaped escalation from entrance to boss.

**Fed**: [[Dungeon Generation]] (room roles, themes, pacing)

## docs/specs/28-dungeon-placement-polish.md

Spec fixing three decor placement bugs (wrong inset, wrong orientation, corridor-mouth blocking) and introducing the focal + satellites room dressing structure. Each theme now has one centerpiece and satellites placed after.

**Fed**: [[Dungeon Generation]] (decor placement rules)

## docs/specs/29-typed-room-contracts.md

Spec promoting room roles from cosmetic labels to mechanical contracts: interactable Chest (treasure), Shrine (3-buff choice), Hearth (full heal + checkpoint). Guarantees one of each per dungeon; rest room adjacent to boss. Defines the `INTERACT_LAYER` scanner pattern and the shrine buff pool.

**Fed**: [[Dungeon Generation]] (typed room contracts table)

## wyrd/data/charts.gd

Authoritative code for the shipped chart system. Contains `TEMPLATES` (5 entries), `AFFIXES` (18 entries: 15 rollable + 3 boss dens), `TROPHY_TO_AFFIX`, `BASE_WEIGHTS`, `INKS` (8 entries), and the bias-roll engine (`compute_weights`, `effective_stability`, `inscribe`, `craft_cost`, `completion_xp`).

**Fed**: [[Charts]], [[Affixes]], [[Inks]] — primary code ground-truth for all three

## wyrd/data/affixes.gd

Item-level affix system (prefixes + suffixes for gear randomization). Separate from chart affixes — this file governs `Sharp`, `Hardened`, `of_Health`, etc. Not directly relevant to charting but clarifies the namespace: "affixes" has two meanings in the codebase.

**Fed**: [[Items and Gear]] (item affix system; out of charting scope but noted for disambiguation)

## Key contradictions found

1. **XP formula**: Design doc `cartography-keystone-design.md` states `tier × 30 + good × 25 + bad × 5`. Shipped `charts.gd::completion_xp` uses `tier × 75 + good × 40 + bad × 10`. Code wins.
2. **Template count**: Design docs reference `chart_sunken_hut` (Tier 3, Lv 22), `chart_delve` (Tier 3, Lv 30), and a `chart_summit` at Tier 5 / Lv 60. Shipped code has `summit` at Tier 3 / Lv 16 and excludes sunken_hut and delve. Code wins.
3. **Ink count**: Design doc targets 15 inks via 3×3 spatial patterns. Shipped code has 8 inks via mixing-pot quantity recipes. The 3×3 grid was explicitly not ported per spec 43 notes.
4. **Affix count**: Design doc targets ~25 affixes (including risk/atmosphere categories). Shipped code has 15 rollable affixes + 3 boss dens = 18 total. Risk and atmosphere categories absent.

## See also

- [[Chart Loop]]
- [[Dungeon Generation]]
- [[Charts]]
- [[Affixes]]
- [[Inks]]
- [[The Crafting Bench]]
- [[The Waystone]]
- [[Wayfinding]]
