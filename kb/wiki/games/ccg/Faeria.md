---
type: game
tags: [game-study, ccg, digital-card-game, living-board, hex-grid, strategy, f2p]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Faeria
  - https://mmohuts.com/review/faeria
  - https://faeria.fandom.com/wiki/Faeria_Wiki
  - https://www.faeria.com/the-hub/guide/139-faeria-economy-part-1
---

# Faeria

Strategy CCG (Abrakam, 2017) — the rare card game that fuses deckbuilding with a living hex board, making terrain construction and creature positioning as strategically load-bearing as the cards themselves.

## Design

- **Living board**: Matches are played on a shared hexagonal grid. Each turn a player places one land tile (Prairie, Mountain, Forest, Desert, or Lake) — these tiles simultaneously create paths for your creatures and gate which cards you can play (Forest creatures require adjacent Forest tiles). The board is literally built during the match; every extension is an investment with spatial consequence.
- **Faeria resource**: Instead of a fixed mana bar, Faeria (the game's resource) accumulates without a cap. Players earn a base amount each turn and gain extra by controlling the four wells at the board's centre. This bankable currency replaces the binary spend-or-lose-it model and rewards forward planning: explosive multi-card turns are set up over several quiet turns.
- **Well control**: The four central wells pay out Faeria to whoever occupies the adjacent territory. Contesting wells is both an economic act (income) and a military one (map pressure) — collapsing economy and positioning into a single decision.
- **30-card decks, element restriction**: Cards belong to a colour and can only be played onto matching terrain. Splashing multiple colours requires building paths of multiple land types, which is physically expensive on a finite board.
- **Monetization**: Launched as buy-to-play (2017), moved to free-to-play with cosmetic packs, then returned to buy-to-play in July 2018. The game was originally Kickstarted in 2013 ($94k). The oscillating model reflects the difficulty of sustaining a niche hybrid game commercially; it currently operates as a buy-once title with cosmetic DLC.
- **Formats**: Ranked constructed, casual, and seasonal events. Monthly esports competitions ran during the game's peak.

## Implementation

- Built with Unity; released on PC/Mac (2017), Xbox One/Switch (August 2020), PS4 (November 2020).
- Metacritic 80/100. The client-server model authorises the board state server-side; tile placements and creature movement are validated before the opponent sees the result.
- RNG is limited to card draw; board construction and combat are deterministic, which reduces the "feel-bad" moments common in pure-draw games.

## Why it matters

Faeria proved that adding a spatial layer to CCG combat creates a distinct genre of decision rather than just added complexity. Terrain placement forces the same trade-off as positional strategy games — commitment versus flexibility — but at the hand-management tempo of a card game. Its commercial instability (three monetization pivots) is also instructive: hybrid genres require a committed audience willing to pay for the novelty.

## Relevance to Wayfinder

- **[[Economy]]**: The well-control system collapses resource generation and map pressure into one mechanic — a template for how gathering nodes or chart affixes in Wayfinder could reward contested territory rather than passive accumulation.
- **[[Affixes]]**: Elemental terrain requirements are a spatial affix system: a card's playability depends on the board state you've built, not just your hand. Dungeon affixes in Wayfinder could similarly gate options on pre-run investment.
- **[[Balance Philosophy]]**: Faeria's deterministic combat (no RNG once cards are in play) is a deliberate variance-control choice that kept skill expression high. Wayfinder's combat verb should consider which RNG sources feel earned versus arbitrary.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]] · [[MMO Economy and Itemization]]
- Siblings: [[Hearthstone]] · [[Gwent The Witcher Card Game]] · [[Mythgard]] · [[Eternal Card Game]]
- Wayfinder: [[Economy]] · [[Affixes]] · [[Balance Philosophy]]

## Sources

- https://en.wikipedia.org/wiki/Faeria
- https://mmohuts.com/review/faeria
- https://faeria.fandom.com/wiki/Faeria_Wiki
- https://www.faeria.com/the-hub/guide/139-faeria-economy-part-1
