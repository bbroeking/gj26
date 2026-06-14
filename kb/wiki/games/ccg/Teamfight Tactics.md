---
type: game
tags: [game-study, ccg, autobattler, trait-synergies, economy, set-rotation, riot-games]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Teamfight_Tactics
  - https://nexus.leagueoflegends.com/en-us/2019/06/dev-design-pillars-of-teamfight-tactics/
  - https://medium.com/@ZiberBugs/game-design-analysis-teamfight-tactics-bc6eb5aafeff
  - https://www.linkedin.com/pulse/game-design-study-teamfight-tactics-victor-ren%C3%A9
---

# Teamfight Tactics

Autobattler (2019, Riot Games) — Riot's answer to the Dota Auto Chess genre, built into the League of Legends client: eight players share a champion pool, draft units onto a hex grid, and watch them fight automatically, with the outcome determined by economy management, trait-synergy composition, and augment selection.

## Design

- **Core loop — draft, position, fight**: Each planning phase, players buy champions from a shared rolling shop (five visible slots, recharged between planning phases). Champions placed on the hex board fight autonomously. Eliminated players lose health; last player standing wins.
- **Shared champion pool**: All eight players draw from the same finite pool of units. Buying a champion removes it from the pool; selling returns it. This creates real-time information games — if your opponent is holding units you need, you can't get them, and vice versa.
- **Interest / streak economy**: Players earn interest on gold held (up to 5g per round at 50g+), plus streak bonuses for consecutive wins or losses. This creates a genuine economic meta-game: "lose-streak" strategies deliberately sacrifice early rounds to accumulate interest gold and buy experience, then spike power mid-game. Economic reads on opponents are as important as unit reads.
- **Trait synergies**: Each champion belongs to one or more traits (e.g., origin + class). Placing N units of a trait on the board activates trait bonuses that scale at thresholds (e.g., 2/4/6 Mages gives +20%/+40%/+60% spell power). Synergies are the primary composition decision driver.
- **Augments (Set 6+)**: At rounds 2-1, 3-2, and 4-2, each player independently chooses one of three augments from Silver/Gold/Prismatic tiers. Augments provide in-combat stat bonuses, resources (gold, items, free units), or modify fundamental rules (e.g., "your team starts with full mana"). Augments dramatically expand build diversity and replayability without expanding the champion pool.
- **Carousel (shared draft)**: At designated rounds, all players simultaneously select from a rotating ring of champions + attached items. This is the primary item acquisition route and a key PvP interaction — players compete for the same carousel unit in a brief free-for-all window.
- **Set rotation (~quarterly)**: New themed sets replace the entire champion roster and trait system every few months. Old units retire; new ones from League's skin universe rotate in. This prevents meta stagnation and gives returning players a fresh starting point. Mid-set updates swap individual traits partway through to address balance issues without waiting for a full set reset.
- **Monetization**: No pay-to-win. Little Legends (now Tacticians) are cosmetic avatars purchased via loot boxes or direct purchase. Battle passes provide cosmetic progression. The in-game experience is not gated by spending.

## Implementation

- Lives within the **League of Legends** client (PC); standalone mobile app launched March 2020.
- Client shares League's rendering infrastructure; unit models are adapted from existing League champion rigs, reducing asset cost for new sets.
- Server-authoritative combat simulation: the planning phase is client-local but the fight result is computed server-side and streamed back, ensuring determinism and anti-cheat.
- 33 million monthly players by September 2019 — reached this milestone three months after launch.
- The game's three design pillars (Volty, 2019): **Mastery** (five knowledge domains), **Playful Competition** (shared social experience), **Discovery** (ongoing exploration via set rotation).

## Why it matters

- The shared champion pool is the fundamental autobattler innovation for competitive fairness: your decisions affect the opponent's options in real time, creating an information PvP layer without any direct combat between players.
- Interest + streak economy demonstrates how to make economic play a first-class skill axis in a game where "economy" could otherwise feel invisible. The tension between spending gold now vs. holding for interest is a clean single-player-legible decision with multiplayer consequences.
- Augments added in Set 6 dramatically increased TFT's long-term health — they are the single biggest replayability lever in the game, generating high variance across matches without changing the core draft/fight loop.
- Set rotation is the subscription substitute: it gives players a reason to return every 3–4 months without requiring a sequel or expansion purchase.

## Relevance to Wayfinder

- **[[Affixes]]**: TFT augments are the closest existing precedent to Wayfinder's chart affixes — mid-run player choices from a small randomized offer that permanently alter that run's rules. The Silver/Gold/Prismatic tier model maps onto Wayfinder's affix rarity system (minor / major / legendary affixes on charts).
- **[[Economy]]**: TFT's interest + streak system is a transferable model for any game that wants economy to be a skill axis rather than a background resource. Wayfinder's gather loop could apply a similar logic: holding gathered materials in surplus unlocks "compound" crafting recipes, while selling for immediate gold sacrifices those bonuses.
- **[[Balance Philosophy]]**: Set rotation is a designed solution to long-term meta calcification. Wayfinder could apply the same pattern to dungeon biomes and chart affix pools: retire one biome per season, introduce one new one, so the knowledge landscape refreshes periodically without invalidating prior investment.

## See also

- [[Game Index]] · [[Game Studies]] · [[MMO Economy and Itemization]] · [[Design Influences]]
- Siblings: [[Hearthstone]] · [[Magic The Gathering Arena]] · [[Legends of Runeterra]] · [[Marvel Snap]]
- Wayfinder: [[Economy]] · [[Affixes]] · [[Balance Philosophy]] · [[Inks]]

## Sources

- https://en.wikipedia.org/wiki/Teamfight_Tactics
- https://nexus.leagueoflegends.com/en-us/2019/06/dev-design-pillars-of-teamfight-tactics/
- https://medium.com/@ZiberBugs/game-design-analysis-teamfight-tactics-bc6eb5aafeff
- https://www.linkedin.com/pulse/game-design-study-teamfight-tactics-victor-ren%C3%A9
