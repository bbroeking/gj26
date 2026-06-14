---
type: game
tags: [game-study, strategy, 4x, turn-based, city-building, progression, economy]
status: draft
updated: 2026-06-14
sources:
  - https://www.gamedeveloper.com/design/designing-i-civilization-vi-i-s-distinctive-districts-system
  - https://en.wikipedia.org/wiki/Civilization_VI
  - https://civilization.fandom.com/wiki/District_(Civ6)
  - https://www.gamedeveloper.com/design/firaxis-big-swing-with-civilization-vii-convincing-players-to-actually-finish-their-games
---
# Civilization VI

4X turn-based strategy (2016, Firaxis Games / 2K), redesigning city-building around tile-occupying districts and a dual tech/civics progression system that rewards active play over passive waiting.

## Design

- **Districts system** — cities expand across multiple tiles; each specialty district (Campus, Holy Site, Industrial Zone, Harbor, etc.) occupies its own tile and yields adjacency bonuses from neighboring terrain features and complementary districts. The map is elevated from backdrop to primary planning surface.
- **Population gate** — a city may build one district per three population, enforcing specialization and preventing any single city from becoming an all-purpose powerhouse.
- **Meaningful trade-offs** — placing a district destroys existing tile improvements (farms, forests, lumber mills), creating permanent opportunity costs in every city layout decision.
- **Eureka/Inspiration boosts** — completing in-game actions (harvesting a forest, building a certain unit) grants a 50% cost reduction on specific technologies or civics, rewarding engagement over idle waiting and shortening the feedback loop between exploration and advancement.
- **Parallel tech and civics trees** — Science drives technology; Culture drives the Civics tree. Two independent progression axes diversify how civilizations differentiate and gate policy cards (slot-based government bonuses).
- **Policy cards** — slotted into government types, creating a meta-layer of customization that players swap as their civics progress, giving each turn era a distinct economic flavor.

## Implementation

- Custom Firaxis proprietary engine (not Unreal), built on Civilization V's codebase with added support for a day/night cycle, camera rotation, and a completely new terrain-generation system.
- Procedural placement of environmental objects (trees, roads, city buildings) lets cities grow organically as districts accumulate across up to five or six building tiers, each with unique visual states and era-appropriate art variants.
- The principal technical challenge was art: a component-driven district system required civilization-specific visual variants, destructibility states per tier, and backward-compatible tile layering—all authored during a relatively compressed production cycle.

## Why it matters

- Civilization VI proved that transforming an abstract economic variable (city output) into a **spatial planning decision** deepens player investment without increasing complexity budgets: players read the map instead of a spreadsheet.
- The Eureka system is a rare example of diegetic pacing—player actions in the world advance a meta-progression meter, keeping exploration purposeful even mid-game.
- Population-gating district count is a clean lever for managing power curves in a 4X context: growth becomes a prerequisite, not just a reward.

## Relevance to Wayfinder

- **[[Economy]]** — district adjacency bonuses show how spatially-grounded yield systems create legible trade-offs; Wayfinder's gather nodes and crafting stations could reward placement-awareness without requiring a full tile engine.
- **[[Balance Philosophy]]** — population gates on district count are analogous to gating chart affixes behind trophy-tier unlocks: scarcity forces meaningful choices and prevents early-game over-optimization.
- **[[Dungeon Generation]]** — Eureka-style "active engagement unlocks progression" moments map neatly onto Wayfinder's gather→craft→chart loop; chart affixes could unlock when players complete in-run discovery actions rather than accumulating passive currency.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[Balance Philosophy]] · [[Economy]] · [[Dungeon Generation]]
- [[Crusader Kings III]] (parallel progression tracks) · [[XCOM 2]] (spatial tactical planning) · [[Into the Breach]] (map-as-puzzle)

## Sources

- https://www.gamedeveloper.com/design/designing-i-civilization-vi-i-s-distinctive-districts-system
- https://en.wikipedia.org/wiki/Civilization_VI
- https://civilization.fandom.com/wiki/District_(Civ6)
