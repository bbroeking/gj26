---
type: game
tags: [game-study, roguelite, city-builder, meta-progression, run-based, dark-fantasy, resource-management]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Against_the_Storm_(video_game)
  - https://www.gamedeveloper.com/business/how-against-the-storm-managed-to-mix-city-building-and-roguelite-play
  - https://techraptor.net/gaming/reviews/against-storm-ambient-roguelite-city-builder
  - https://gamermatters.com/against-the-storm-steam-early-access-impressions-city-builder-with-roguelite-elements-is-a-genius-combo/
---
# Against the Storm

A roguelite city-builder (Eremite Games / Hooded Horse, PC 2023) in which the "city" is your avatar — run-scoped settlements built during the lull between apocalyptic Blightstorms, with permanent upgrades accumulated in a Smoldering City hub between runs.

## Design

Eremite Games released Against the Storm into early access in October 2021 and to full release December 8, 2023. Console ports (Switch, PS4/5, Xbox) followed June 2025. The game reached over one million copies sold by May 2024 and holds a 91/100 Metacritic score.

**The city as avatar.** The design breakthrough, articulated by designer Michał Ogłoziński, was treating the settlement itself as the roguelite's character: "if your town is your avatar, what if it has quests or health?" This framing unlocked the full roguelite vocabulary — the city gains quests from the Queen, suffers resolve-loss as a health proxy, and completes runs when it achieves its goals — then is abandoned before it stagnates into the stability boredom of traditional city builders.

**Run structure.** Each run establishes a new settlement in procedurally varied terrain (forest biomes with different resource compositions, glade events, and available building types). Players must satisfy orders from the Queen, maintain settler resolve across up to seven species (Humans, Beavers, Harpies, Lizards, Foxes, plus DLC Frogs and Bats) with different needs, and hit a city-completion goal before the Blightstorm returns. Typical run: approximately one hour.

**Cornerstone system.** Three seasons within each run apply shifting buffs and debuffs; Cornerstone perks (offered at season transitions) let players double down on specific strategies — resource production, resolve generation, exploration. This is the run's affix layer: each Cornerstone pick narrows the optimal play pattern in exchange for multiplicative returns.

**Meta-progression: the Smoldering City.** Accumulated currency between runs is invested into a persistent tech tree — resource production rates, settler speed, new building unlocks, new Cornerstone availability. The Smoldering City is a "rebuilding after ruin" fantasy, mirroring the world's lore (the storm keeps destroying civilization; you keep rebuilding it).

**Three victory paths** — Orders (Queen's tasks), Resolve (settler happiness), Exploration (glade resources) — prevent single-strategy dominance and offer alternative routes when a run's resource composition doesn't suit one approach. Difficulty scales via a prestige/embark system; Blightrot and Corruption mechanics (high-difficulty pollution) add consequences absent in standard play.

## Implementation

Built on Unity. Procedural map generation varies terrain type, resource nodes, glade event sets, and available building combinations per run. The variety is achieved more through composition (which buildings/resources appear) than spatial layout variety — layout is generated but secondary to the systemic mix.

## Why it matters

Against the Storm solves **stability boredom** — the core failure mode of city builders — by structurally capping each run before permanence sets in. It also demonstrates that roguelite meta-progression can reframe repetition as progress within a lore-coherent "endless cycle" narrative (the Blightstorm), rather than as arbitrary death punishment. The city-as-avatar reframe is the key insight: once systems belong to an "avatar," roguelite verbs apply naturally.

## Relevance to Wayfinder

1. **[[Chart Loop]]:** Against the Storm's run-scoped settlement that resets to a new site mirrors Wayfinder's chart-scoped dungeon run. Both give each run a fresh procedural context while the meta-layer (Smoldering City / Trophy Chain) accumulates durable progress.
2. **[[Affixes]]:** The Cornerstone perk system — offered at fixed intervals, narrowing the run's optimal strategy — is structurally similar to chart affixes. Both are mid-run build-defining choices with compounding returns.
3. **[[Crafting]]:** Against the Storm's multi-species resource chain (species-specific needs feeding into crafting recipes) is a reference model for Wayfinder's gather → craft loop, where species variety in the Smoldering City parallels Bramblewood's biome / NPC diversity feeding the economy.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[Frostpunk]] — thematic peer (survival city-builder); [[Hades]] — narrative meta-progression model
- [[Chart Loop]] · [[Affixes]] · [[Crafting]] · [[Dungeon Generation]]

## Sources

- https://en.wikipedia.org/wiki/Against_the_Storm_(video_game)
- https://www.gamedeveloper.com/business/how-against-the-storm-managed-to-mix-city-building-and-roguelite-play
- https://techraptor.net/gaming/reviews/against-storm-ambient-roguelite-city-builder
- https://gamermatters.com/against-the-storm-steam-early-access-impressions-city-builder-with-roguelite-elements-is-a-genius-combo/
