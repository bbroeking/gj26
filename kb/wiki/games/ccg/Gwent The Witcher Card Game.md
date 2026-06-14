---
type: game
tags: [game-study, ccg, digital-card-game, witcher, three-round, provision, f2p, cd-projekt]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Gwent:_The_Witcher_Card_Game
  - https://www.playgwent.com/en/news/41252/gwents-design-01-provision
  - https://www.playgwent.com/en/faq
  - https://wccftech.com/gwent-witcher-card-game-dev-doesnt-want-people-spend-money-advantage/
---

# Gwent The Witcher Card Game

Digital CCG (CD Projekt Red, 2018) — the standalone evolution of the mini-game inside The Witcher 3, renowned for its three-round pass-or-play bluffing structure and a provision deck-building system that replaces mana entirely.

## Design

- **Three-round structure**: Players compete across best-of-three rounds with a shared hand of cards. Cards played in Round 1 are gone for Round 2; managing hand size across rounds is the game's central tension. A player can concede a round deliberately (sacrificing it cheaply) to draw more cards and win the remaining two — making "passing" a meaningful tactical tool, not an admission of defeat.
- **Point salad combat**: There are no life totals. Each round is won by the player with the higher total card power on the board at end-of-round. Cards accumulate value as a "point salad" rather than attacking a health pool; tempo and card efficiency matter more than direct damage racing.
- **Provision system**: Replaces mana. Decks of 25 cards are built from a base budget of ~150 provisions (plus a leader bonus). Each card costs provisions, forcing trade-offs between high-ceiling expensive cards and cheap filler. The system was designed to encourage "polarized" decks — mixing costly and cheap cards to minimise wasted provisions — while avoiding the land-flood/screw variance of Magic.
- **Five factions, leader abilities**: Each faction (Nilfgaard, Northern Realms, Scoia'tael, Monsters, Skellige) has a unique playstyle. Leader cards provide a once-per-game special ability, functioning as an elevated hero power.
- **Monetization**: Free-to-play with three currencies — Ore (earns Card Kegs / packs), Scraps (card crafting), and Meteorite Powder (premium cosmetic cards). CD Projekt Red publicly committed to not selling competitive advantage; all meta cards are earnable without spending. The Journey (seasonal battle pass) funds the studio without gating card access.
- **Draft mode**: Seasonal modes and a draft format expand the game beyond constructed play.

## Implementation

- PC (Windows/macOS), iOS, Android — cross-platform with shared account. Built internally at CD Projekt Red.
- Cards that persist on board across rounds require the server to track a board state that spans sub-games; this is architecturally more complex than single-round games. The pass mechanic requires both players to lock in simultaneously or sequentially, handled with a server-authoritative confirmation handshake.
- The provision system's mathematical nature (deck budget) makes balance patches predictable: changing a card's provision cost ripples through all decks using it without requiring emergency bans.

## Why it matters

Gwent's three-round bluffing layer adds a metagame of resource allocation that no other major CCG replicates. The pass-or-play decision is a hidden-information deduction puzzle stacked on top of the board puzzle, which produces a game that feels like poker in its mind-game depth. The provision system is also the cleanest digital-native answer to "how do we gate deck power without land cards" — a solved problem worth studying.

## Relevance to Wayfinder

- **[[Economy]]**: The Ore/Scraps/Powder three-currency model maps cleanly onto the separate track idea for Wayfinder's chart materials, craft reagents, and cosmetic inks — each currency earned through distinct play activities.
- **[[Affixes]]**: Provision costs are a budget-affix system: every affix on a chart should have a "provision" equivalent that gates total run power, preventing a chart from stacking unlimited upside.
- **[[Balance Philosophy]]**: The public commitment to no pay-to-win is a trust-building precedent. If Wayfinder ever goes live-service, mirroring this philosophy in how affixes and charts are unlocked will matter for community goodwill.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]] · [[MMO Economy and Itemization]]
- Siblings: [[Hearthstone]] · [[Legends of Runeterra]] · [[Faeria]] · [[Eternal Card Game]]
- Wayfinder: [[Economy]] · [[Affixes]] · [[Balance Philosophy]] · [[Inks]]

## Sources

- https://en.wikipedia.org/wiki/Gwent:_The_Witcher_Card_Game
- https://www.playgwent.com/en/news/41252/gwents-design-01-provision
- https://www.playgwent.com/en/faq
- https://wccftech.com/gwent-witcher-card-game-dev-doesnt-want-people-spend-money-advantage/
