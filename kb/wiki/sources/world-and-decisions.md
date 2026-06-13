---
type: source
tags: [source-digest, world, lore, adr, design-vision]
status: draft
updated: 2026-06-13
sources:
  - "docs/WORLD_BIBLE.md"
  - "docs/WORLD_LORE.md"
  - "docs/DESIGN_VISION.md"
  - "CONTEXT.md"
  - "docs/adr/0001-inventory-controller-deferred.md"
  - "docs/adr/0002-dungeon-layout-typing-deferred.md"
  - "docs/adr/0003-cozy-skilling-spine.md"
  - "docs/adr/0004-controls-stay-numeric.md"
  - "docs/adr/0005-huntcraft-single-combat-trade.md"
  - "docs/adr/0006-demo-level-cap-17.md"
---

# Source Digest — World & Decisions

Inventory of the source documents read to build the world and decision pages in this wiki cluster. One-line summary per source, with the wiki pages each document fed.

---

## docs/WORLD_BIBLE.md

**Summary:** Locked 2026-04-29. Canonical setting, vibe, named cast, locations, enemy hierarchy, naming rules, and the full resource taxonomy (6-tier ore ladder, 6 creature meats, core forageables). Governs all player-visible writing — if writing conflicts with this doc, the writing changes.

**Fed:** [[Bramblewood]], [[Voice and Tone]]

---

## docs/WORLD_LORE.md

**Summary:** Companion to the World Bible. The deeper mythic layer: founding history, the Bramble Bargain, the Hedgemother's identity, the two-soldiers and two-herb-tenders faction undercurrents, the 4-festival calendar, whispered legends, and places named but not visited. Marked as suggestion rather than pronouncement.

**Fed:** [[Bramblewood]], [[World Lore]], [[Voice and Tone]]

---

## docs/DESIGN_VISION.md

**Summary:** v3 design vision (dated 2026-04-29, pre-Godot pivot). Describes the core hybrid loop (RuneScape skill grind + Stardew cozy life-sim), player motivation pyramid (Achiever primary), three nested loops (micro/meso/meta), MVP slice for jam, and the north star sentence ("a 12-year-old should load this in a browser and want to come back tomorrow"). Note: this doc predates the Godot decision (ADR 0003) and describes a three.js browser game; some specifics (localStorage save, three.js tech stack, click-to-attack tab-target) are superseded by the current Godot implementation.

**Fed:** [[Voice and Tone]]

> ⚠️ `docs/DESIGN_VISION.md` describes a three.js browser prototype (the "v3" jam build), including skills (Woodcutting/Fishing/Cooking/Attack), six NPCs with a 5-heart system, and LocalStorage save. The working game is now Godot 4.6 in `wyrd/` with a different set of systems ([[Trades and Leveling]], [[Chart Loop]], [[Save System]]). This doc is preserved as design history and north-star framing, not as a spec for the current build.

---

## CONTEXT.md

**Summary:** The project's domain glossary — authoritative definitions of the canonical terms: Trade (leveling discipline), Skill (hotbar ability), Chart, Affix, GatherNode, Waystone, Satchel, SkillEffect, HitFeedback, Interactable, Elite, and Pickup. Also identifies the working game as `wyrd/` (Godot 4.6 ARPG) alongside the frozen three.js prototype at `src/`.

**Fed:** [[Bramblewood]], [[Design Decisions]] (terminology alignment throughout)

---

## docs/adr/0001-inventory-controller-deferred.md

**Summary:** Deferred extraction of an `InventoryController` from `inventory_panel.gd` — one consumer (no second view yet) makes the seam hypothetical; revisit when spec 37 (vendor) or similar lands.

**Fed:** [[Design Decisions]] (ADR 0001 section)

---

## docs/adr/0002-dungeon-layout-typing-deferred.md

**Summary:** Deferred typing of `DungeonGen.generate()`'s Dictionary return as a `DungeonLayout` RefCounted — single consumer (`layout_loader._ready`) makes it pure clarity work with no payoff until a second consumer appears.

**Fed:** [[Design Decisions]] (ADR 0002 section)

---

## docs/adr/0003-cozy-skilling-spine.md

**Summary:** The identity decision — cozy skilling is the spine; combat is one verb; the ARPG roadmap (specs 30–43) is re-contextualized as seasoning. Vertical-slice-first; cartography is slice 2.

**Fed:** [[Design Decisions]] (ADR 0003 section)

---

## docs/adr/0004-controls-stay-numeric.md

**Summary:** WASD + F + 1–4 + E + Space + Q is the locked control scheme; click-to-move + QWER fork is closed after B3/B4a playtests confirmed the current scheme plays fine with per-kind enemies and the Boar charge.

**Fed:** [[Design Decisions]] (ADR 0004 section)

---

## docs/adr/0005-huntcraft-single-combat-trade.md

**Summary:** Kills feed exactly one Trade — Huntcraft (`hunt`) — not an OSRS three-stat combat block. XP = `max(2, hp_max/3)`. Perks: Steady Hands (Hunt 5) and Hunter's Stride (Hunt 10). Old saves backfilled at lv 1/0 XP.

**Fed:** [[Design Decisions]] (ADR 0005 section)

---

## docs/adr/0006-demo-level-cap-17.md

**Summary:** Demo cap is 17 (Wayfinding's Summit at 16, cap = 16+1). Wayfinding's ladder left untouched; Earthcraft/Wildcraft/Huntcraft extended to match in specs 45+. Cap enforced at XP award time; XP curve unchanged.

**Fed:** [[Design Decisions]] (ADR 0006 section)

---

## See also

- [[Bramblewood]] — the setting synthesized from the Bible and Lore docs
- [[World Lore]] — the myth layer synthesized from `docs/WORLD_LORE.md`
- [[Voice and Tone]] — the writing rules synthesized from the Bible and Design Vision
- [[Design Decisions]] — digest of all six ADRs
