---
type: game
tags: [game-study, autobattler, dota, valve, f2p, shared-pool, synergies]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Dota_Underlords
  - https://dotesports.com/dota-2/news/dota-underlords-how-to-play-guide
  - https://boosteria.org/guides/dota-underlords-the-rise-fall-and-steady-persistence-in-the-gaming-world
  - https://www.pcgamesn.com/dota-underlords/strategy-best-tactics
---

# Underlords

Autobattler (Valve, 2020) — Valve's official Dota 2 take on the Auto Chess genre: eight players share a depleting hero pool, earn interest on banked gold, and arrange Dota heroes on a grid whose positions are frozen once combat auto-resolves.

## Design

- **Autobattler core loop**: Each round, players draft heroes from a five-unit shop drawn from a shared pool, position them on an 8×8 half-board, then watch combat resolve automatically. No input during combat — positioning and composition chosen beforehand is the entire skill expression.
- **Shared hero pool**: All eight players draw from the same fixed pool (~45 copies per hero across three tiers). Contested compositions cause scarcity; reading the lobby and pivoting to uncontested heroes is central to advanced play. This creates a metagame layer above the in-game decisions.
- **Gold and interest economy**: Players earn base gold per round plus bonus gold for win/loss streaks. Unspent gold earns interest (1 gold per 10 held, capped at 5). Mastering the interest curve — knowing when to bank versus when to roll the shop — is the game's economic skill ceiling. This is one of the purest implementations of economy as a core mechanic in any genre.
- **Alliance synergies**: Heroes belong to classes and species alliances. Fielding the required count triggers a bonus applying to all eligible units. Alliances create combinatorial space — the same hero gains different value in different compositions, increasing strategic variety without requiring new cards.
- **3-star merging**: Three identical heroes of the same tier merge into a single upgraded unit. This creates a "lottery" tension where buying duplicates is both an upgrade path and a commitment to a strategy others may contest.
- **Underlord system**: Underlords are powerful single-unit commanders with upgradeable talents, adding a personal vertical progression layer on top of each match's horizontal composition decisions.
- **Monetization**: Free-to-play; purchases limited to cosmetic battle pass (City Crawl), board skins, and courier upgrades. No hero or ability is paywalled.

## Implementation

- Built on Valve's Source 2 engine within the Dota 2 client ecosystem; released early access June 2019, full release February 2020. Available on PC (Steam), iOS, and Android with cross-play.
- Server-authoritative combat simulation: all combat calculations run server-side and clients receive the result. This prevents desync and cheating while accepting that clients show a replay rather than a live simulation.
- Over 200,000 concurrent Steam players and 1.5 million downloads in the first week of early access. GameSpot scored it 9/10.
- The game entered maintenance mode in 2020 as the studio shifted focus; updates slowed significantly after December 2020.

## Why it matters

Underlords is the clearest distillation of the interest-economy mechanic in games: gold management is simultaneously a resource game, a timing game, and a risk/reward bet. The shared pool is also a landmark design for "competition without direct combat" — players fight each other economically and in composition space before a single unit swings.

## Relevance to Wayfinder

- **[[Economy]]**: The gold-interest system is a direct model for chart-material banking in Wayfinder — rewarding players who resist spending every reagent immediately and save up for a high-value chart.
- **[[Affixes]]**: Alliance synergies are affix-like: they reward intentional composition building and punish random accumulation. Wayfinder's affix pairing system (good/bad twins) could use a similar "critical mass" trigger logic.
- **[[Balance Philosophy]]**: The shared pool creates healthy scarcity that forces adaptation. A lesson for Wayfinder dungeon generation: scarce resources (certain gather nodes, rare elite spawns) push players to engage with the full design space rather than routing to the optimal path.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]] · [[MMO Economy and Itemization]]
- Siblings: [[Teamfight Tactics]] · [[Hearthstone]] · [[Slay the Spire]]
- Wayfinder: [[Economy]] · [[Affixes]] · [[Balance Philosophy]]

## Sources

- https://en.wikipedia.org/wiki/Dota_Underlords
- https://dotesports.com/dota-2/news/dota-underlords-how-to-play-guide
- https://boosteria.org/guides/dota-underlords-the-rise-fall-and-steady-persistence-in-the-gaming-world
- https://www.pcgamesn.com/dota-underlords/strategy-best-tactics
