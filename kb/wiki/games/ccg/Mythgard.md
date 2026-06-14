---
type: game
tags: [game-study, ccg, digital-card-game, rhino-games, card-burning, lane-combat, urban-fantasy, f2p]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Mythgard
  - https://nerdlab-games.com/episode-42-mythgard-review-8-exceptional-design-choices-and-what-we-can-learn-from-them/
  - https://www.quartertothree.com/fp/2020/12/29/just-when-you-though-it-was-safe-to-ignore-collectible-card-games-mythgard-shows-up/
  - https://www.gamingnexus.com/News/44046/Rhino-Games-new-CCG-Mythgard-is-crazy2c-beautiful-fun
---

# Mythgard

Digital CCG (Rhino Games / Monumental, 2019) — an urban-fantasy CCG where every card in your hand doubles as a mana source, seven creature lanes replace the single battleline, and persistent lane enchantments create battlefield geography that outlives the creatures occupying it.

## Design

- **Card-burning mana system**: Mythgard has no dedicated land or power cards. Instead, players can "burn" any card from their hand to generate mana gems (coloured by that card's faction). Burnt cards go to the discard and cycle back; they are not lost. Every card therefore has two values: its play effect and its mana contribution. Opening hands are always live; no purely dead draws from mismatched resources.
- **Seven-lane combat**: Creatures are placed in one of seven lanes and attack the three lanes adjacent to them (two for edge lanes). Creatures must clear the lane directly ahead to reach the opponent — blocking is positional rather than a declared phase. This produces a spatial puzzle each turn: where to place, where to attack, how to outflank.
- **Lane enchantments (Paths)**: Special cards enchant individual lanes with persistent effects (e.g., Serpent Den grants bonuses to creatures in that lane). Enchantments survive even after the creatures using them die, creating durable battlefield geography that rewards positional planning across multiple turns.
- **No reaction stack**: Unlike Magic or Eternal, Mythgard does not allow instant-speed responses. Instead, first-mover disadvantage is partially offset by second-player path bonuses built into the lane system. This simplifies timing complexity while preserving board-wide tactical depth.
- **Rarity-copy limits**: Commons: 4 copies; Uncommons: 3; Rares: 2; Mythics: 1. Rarity limits function as a built-in power regulation: the strongest cards appear once, reducing "I drew 4 copies of the best card" situations.
- **Draft colour agency**: A "boost/cull" system in draft lets players influence which colours appear in upcoming packs, increasing agency over the draft pool without removing all randomness.
- **Monetization**: Free-to-play; cards purchasable or earnable. Rhino Games ceased active development in September 2021; Monumental took over in October 2021. The studio transition has limited ongoing support.

## Implementation

- PC (Steam), iOS, Android. Built by a small independent studio (Rhino Games, founded San Mateo 2016 by Peter Hu and Paxton Mason). Game entered a maintenance-mode-adjacent state under Monumental.
- The seven-lane system requires client tracking of individual lane states plus enchantment stacks per lane — more game state per frame than single-lane games. Handled server-side to prevent desync.
- Received positive coverage from smaller outlets; mainstream coverage was sparse. The game's complexity (eight design novelties simultaneously) likely contributed to its difficulty acquiring a mass audience.

## Why it matters

Mythgard is a dense set of design experiments executed simultaneously: card-burning, lane combat, enchantment geography, rarity limits, copy restrictions, draft agency. Not all landed commercially, but as a design lab the game demonstrates how many orthogonal systems a CCG can carry before the cognitive budget overflows — a cautionary lesson as much as an inspiration.

## Relevance to Wayfinder

- **[[Economy]]**: Card-burning is the cleanest possible dual-use resource design — every item is simultaneously a consumable and a component. Wayfinder's gathered materials should aspire to the same dual-value logic: ingredients usable either as crafting inputs or as fuel for a lesser immediate effect.
- **[[Affixes]]**: Lane enchantments that persist after the triggering creature dies are a model for dungeon-room effects in Wayfinder: room-level affixes that modify encounters independently of what spawns in them, rewarding map-reading and pre-planning.
- **[[Balance Philosophy]]**: The rarity-copy limit is a non-ban balancing tool. Wayfinder's affix frequency system could apply the same constraint: powerful affixes appear at most once per chart, preventing compounding.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- Siblings: [[Eternal Card Game]] · [[Hearthstone]] · [[Faeria]] · [[Gwent The Witcher Card Game]]
- Wayfinder: [[Economy]] · [[Affixes]] · [[Balance Philosophy]]

## Sources

- https://en.wikipedia.org/wiki/Mythgard
- https://nerdlab-games.com/episode-42-mythgard-review-8-exceptional-design-choices-and-what-we-can-learn-from-them/
- https://www.quartertothree.com/fp/2020/12/29/just-when-you-though-it-was-safe-to-ignore-collectible-card-games-mythgard-shows-up/
- https://www.gamingnexus.com/News/44046/Rhino-Games-new-CCG-Mythgard-is-crazy2c-beautiful-fun
