---
type: game
tags: [game-study, roguelite, metroidvania, procedural-generation, meta-progression, action, biomes, blueprints]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Dead_Cells
  - https://www.gamedeveloper.com/design/building-the-level-design-of-a-procedurally-generated-metroidvania-a-hybrid-approach-
  - https://www.indiedb.com/games/dead-cells/news/the-level-design-of-a-procedurally-generated-metroidvania
  - https://www.gametruth.com/guides/dead-cells-biome-progression-guide-routes-secrets-and-boss-cell-paths/
  - https://medium.com/@tunganh0806/difficulty-as-design-dead-cells-progressive-challenge-and-player-engagement-74f086064bf6
---
# Dead Cells

A 2018 roguelite-Metroidvania by Motion Twin (post-launch: Evil Empire) that fuses procedural biome generation with a hand-structured world map, a deep weapon/build system gated by Blueprints, and a Boss Stem Cell difficulty ladder that lets players self-select their challenge ceiling.

## Design

- **Hybrid procgen:** Lead designer Sebastien Benard documented the approach explicitly. The overall world map is fixed — biomes connect in predetermined ways and never shuffle. Within each biome, the generator assembles hand-authored "tile" chunks (rooms) by selecting from category-appropriate pools (combat, treasure, merchant) according to a per-biome "concept graph" that controls level length and special room placement. Algorithm fills graph nodes until all slots match their constraints; if a room doesn't fit, it retries. Result: authored feel with run-to-run variety.
- **Blueprint meta-progression:** Enemies and bosses drop Blueprints for new weapons/skills. Blueprints must reach the Collector NPC at a biome transition safe zone — dying before handoff loses the Blueprint permanently. Once handed off, players spend Cells (per-run currency lost on death) to add the item permanently to the loot pool. This creates a two-stage risk loop: survive long enough to bank knowledge, then accumulate cells to buy it.
- **Cells as dual currency:** Cells fund blueprint unlocks and can also buy per-run boosts at statues. The tension between "spend now for this run" vs. "bank for permanent unlocks" drives meta-decision-making every run.
- **Boss Stem Cell (BSC) difficulty:** Beating the final boss earns one BSC that can be activated to raise difficulty on all subsequent runs (up to 5). Each BSC level changes enemy constellations, removes health-flask recharge opportunities, and unlocks BSC-gated blueprints/biome paths. This is a voluntary difficulty gate — players plateau at their comfort level and still see all core content.
- **Scroll/stat build system:** Scrolls found in levels permanently upgrade one of three stats (Brutality/red, Tactics/purple, Survival/green) for that run. Each weapon has a color affinity and scales with the matching stat. Players who commit to a color synergy snowball; off-color scrolls are weaker. This creates emergent build identity per run without an explicit class system.
- **Colorless weapons** (from Cursed Chests) scale with the highest single stat regardless of color — a "wildcard" slot enabling hybrid builds at high risk (cursed = one-hit kill until a set number of enemies are killed).
- **Post-launch longevity:** Four paid DLCs (Bad Seed, Fatal Falls, Queen and the Sea, Return to Castlevania) added new biomes slotted into the fixed world map. Evil Empire handled post-launch support after Motion Twin moved to new projects. 10 million copies by June 2023.

## Implementation

- **Engine:** Heaps.io (Haxe-based open-source game framework), with a custom CastleDB tool for designing and tagging room tiles. Not Unity or Godot — a relatively unusual choice that gave fine-grained control over rendering.
- **Procgen toolchain:** Room tiles are authored in CastleDB with metadata tags (entrance/exit count, biome, category). The runtime generator reads the biome's concept graph and uses constraint-satisfaction to select rooms matching each node's requirements.
- **Platform:** PC, PS4, Xbox One, Switch, iOS/Android. 730,000 copies in first year; 2M by May 2019.

## Why it matters

Dead Cells is the canonical proof that a fixed world map + procgen biomes can deliver Metroidvania exploration feel with roguelite replayability. Its Blueprint system is one of the cleanest implementations of "permanent knowledge unlocked through play" — the risk of losing a blueprint before banking creates genuine drama without punishing the player unfairly. The BSC difficulty ladder is widely cited as a fair model for optional challenge escalation.

## Relevance to Wayfinder

- **Fixed world map + procgen internals → [[Dungeon Generation]]:** Wayfinder's den structure (chart-keyed dungeon with fixed boss at the end) could adopt Dead Cells' approach — fixed biome topology (crypt → antechamber → boss room), procgen room chunks within each section. Avoids the "impossible layout" problem.
- **Blueprint-style unlock risk → [[Chart Loop]] / [[Items and Gear]]:** Wayfinder's trophy-chain progression echoes Dead Cells' blueprint banking. Design implication: make the "bank" moment (handing off the boss trophy) feel weighty.
- **BSC difficulty ladder → [[Affixes]]:** Wayfinder's chart affix system is a natural analogue — harder affixes gate deeper content, players self-select. Dead Cells' execution suggests affixes should unlock content (paths, blueprints) not just raise numbers.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[Dungeon Generation]] · [[Chart Loop]] · [[Affixes]] · [[Items and Gear]]
- [[Spelunky]] · [[Slay the Spire]] · [[Hades]] (difficulty ladder parallel)

## Sources

- https://en.wikipedia.org/wiki/Dead_Cells
- https://www.gamedeveloper.com/design/building-the-level-design-of-a-procedurally-generated-metroidvania-a-hybrid-approach-
- https://www.gametruth.com/guides/dead-cells-biome-progression-guide-routes-secrets-and-boss-cell-paths/
- https://medium.com/@tunganh0806/difficulty-as-design-dead-cells-progressive-challenge-and-player-engagement-74f086064bf6
