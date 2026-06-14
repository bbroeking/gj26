---
type: game
tags: [game-study, tower-defense, co-op, upgrade-trees, hero-system, live-service]
status: draft
updated: 2026-06-14
sources:
  - "https://store.steampowered.com/app/960090/Bloons_TD_6/"
  - "https://bloons.fandom.com/wiki/Bloons_TD_6"
  - "https://www.co-optimus.com/game/8476/pc/bloons-td-6.html"
  - "https://www.bloonswiki.com/Bloons_TD_6"
---

# Bloons TD 6

Ninja Kiwi's 2018 flagship tower-defense, built around a deeply branching upgrade tree and a 2–4 player co-op mode where players share a map but own distinct tower budgets.

## Design

The core loop: place monkey towers on a fixed track, pop balloon (Bloon) waves, earn cash from pops, upgrade. The upgrade system is the game's engine — each of 25 towers has three upgrade paths, but a single path can be taken all the way to tier 5 (the most powerful state) while only one other path can reach tier 2. This forces players to specialise each tower and plan around complementary placements rather than buffing everything uniformly.

Heroes are a separate layer: 17 unique characters that level up passively during a round, contribute special abilities on cooldown, and share XP earned across the map. Heroes fill the role of active abilities in an otherwise passive placement game, introducing a timing dimension to wave management.

Difficulty and economy are tightly coupled: each game mode (Easy/Medium/Hard/Impoppable) adjusts the cash-per-pop multiplier, starting gold, and available abilities, so the same map plays as a gentle puzzle or a resource-starved grind. Monkey Knowledge — 100+ meta-upgrades unlocked through accumulated XP — provides an account-level power layer that persists across all sessions.

Live-service additions (Boss Events, Odysseys, Contested Territory, Content Browser) layer seasonal challenge on top of the base game, providing wave modifiers and curated map sequences that function similarly to affix-weighted runs.

## Implementation

Mobile-first (iOS/Android, December 2018; Steam 2019), developed in Unity by Ninja Kiwi. Co-op unlocked at player account level 20; supports 2–4 players. Each player can either share the entire map or claim a dedicated section; all players share an income pool from Bloon pops but maintain independent tower stacks and one Hero slot each. Tier-5 upgrades are per-player, not shared, so co-op requires explicit build-role negotiation.

## Why it matters

BTD6 is the most-played tower-defense on Steam and the genre reference for deep upgrade branching and live-service content cadence. Its asymmetric co-op — shared income, individual tower ownership — demonstrates how a single-player TD loop can be extended to multiplayer without trivialising the economy or making roles redundant.

## Relevance to Wayfinder

1. [[Multiplayer Co-op]] — Map-section ownership + shared income pool is the cleanest existing model for splitting dungeon-floor responsibilities among co-op players without merging all resources.
2. [[Economy]] — Per-mode cash-per-pop multipliers show how to tune run difficulty via a single economy scalar rather than rebalancing every tower; relevant to chart affix difficulty tiers.
3. [[Affixes]] — Boss Events and Odysseys are effectively affix-weighted run sequences: named modifiers that stress specific tower synergies, directly analogous to Wayfinder's chart affix concept.

## See also

- [[Game Index]]
- [[Game Studies]]
- [[Design Influences]]
- [[Economy]]
- [[Affixes]]
- [[Multiplayer Co-op]]
- [[Plants vs Zombies]]
- [[Kingdom Rush Origins]]

## Sources

- Steam store page — https://store.steampowered.com/app/960090/Bloons_TD_6/
- Bloons Wiki (Fandom) — https://bloons.fandom.com/wiki/Bloons_TD_6
- Co-Optimus co-op info — https://www.co-optimus.com/game/8476/pc/bloons-td-6.html
- Blooncyclopedia — https://www.bloonswiki.com/Bloons_TD_6
