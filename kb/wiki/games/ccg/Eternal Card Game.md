---
type: game
tags: [game-study, ccg, digital-card-game, dire-wolf, f2p, fast-spells, influence, generous-economy]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Eternal_(video_game)
  - https://store.steampowered.com/app/531640/Eternal_Card_Game/
  - https://www.direwolfdigital.com/eternal/
  - https://www.direwolfdigital.com/eternal/faq/?locale=en_US
---

# Eternal Card Game

Digital CCG (Dire Wolf Digital, 2016/2018) — the pro-designed answer to Hearthstone's simplification, restoring full instant-speed interaction via fast spells while pairing it with a proven-generous free-to-play economy and unrestricted deckbuilding across five factions.

## Design

- **Fast spells / reactive gameplay**: Unlike Hearthstone, players can play spells at any speed — including in response to opponent actions during combat. This restores the interaction layer that Hearthstone deliberately removed, producing a game closer to Magic: The Gathering's stack model without the full complexity of priority windows.
- **Influence + Power system**: Power cards (drawn from the deck, one playable per turn) produce Influence (faction alignment). Cards have both a Power cost (total mana) and an Influence requirement (how much faction-coloured power). Playing multi-faction is always possible but requires hitting both constraints, creating meaningful deckbuilding tension without land flood/screw.
- **Aegis**: A shield-like keyword that absorbs one negative effect. Cards with Aegis require two actions to remove, making efficient removal sequencing a skill-test and protecting certain game-pieces from cheap disruption.
- **Unrestricted deckbuilding**: Any card can be used in any deck without format restrictions beyond Power/Influence costs. No block rotation in the main format (Throne), though a rotating Expedition format exists for a smaller card pool.
- **Multiple formats**: Throne (eternal/no rotation), Expedition (rotating), Draft (48-card draft, keep what you pick), Forge (sequential 3-card picks, keep cards), Sealed, Gauntlet (vs AI), Events. The breadth rivals Magic Online.
- **Monetization**: Free-to-play with maximum generosity as a stated design goal. First ranked win each day grants a pack; daily quests grant bonus packs or gold. All cards earnable without purchase. Designed by Magic Hall of Famers Luis Scott-Vargas and Patrick Chapin.
- **Economy**: Steam reviews describe it as having "the most generous card acquisition rate of any digital CCG." Packs can be drafted immediately; dust equivalents convert excess cards to target-craft specific ones.

## Implementation

- Dire Wolf Digital (Denver, CO), founded 2010. iOS/Android launch November 2016; Steam launch November 2018. Cross-platform: iOS, Android, Steam, Xbox One, Nintendo Switch — full shared account.
- Steam: Mostly Positive (79%, ~4,680 reviews). The game's longevity comes from its Magic-literate audience who value reactive gameplay depth the mainstream digital CCGs stripped out.
- Server-authoritative state with real-time priority windows — the fast-spell system requires client-server round-trips during the opponent's turn, making Eternal technically more demanding than turn-gated games.

## Why it matters

Eternal is the clearest demonstration that restoring reactive interaction to digital CCGs does not destroy accessibility if the tutorial and UI handle the complexity. It also has the best-documented generous F2P economy, providing a reference for what "fair" looks like in practice (daily pack, quest packs, all formats earnable).

## Relevance to Wayfinder

- **[[Economy]]**: Eternal's "first win per day = pack" structure maps onto Wayfinder's daily activity reward cadence. Generous baseline acquisition keeps players logging in without paywalling progress.
- **[[Affixes]]**: The Influence constraint (faction gating) is analogous to chart affix prerequisites: unlocking certain affix combinations could require having reached a trade level or gathered a specific reagent, gating power in a way that feels earned.
- **[[Balance Philosophy]]**: Aegis (absorb one effect) is a clean single-keyword model for defensive asymmetry. Wayfinder dungeon encounters could use equivalent shields on elites — requiring a specific counter action before a second hit lands — to teach counterplay without punishing players harshly.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]] · [[MMO Economy and Itemization]]
- Siblings: [[Hearthstone]] · [[Magic The Gathering Arena]] · [[Gwent The Witcher Card Game]] · [[Mythgard]]
- Wayfinder: [[Economy]] · [[Affixes]] · [[Balance Philosophy]]

## Sources

- https://en.wikipedia.org/wiki/Eternal_(video_game)
- https://store.steampowered.com/app/531640/Eternal_Card_Game/
- https://www.direwolfdigital.com/eternal/
- https://www.direwolfdigital.com/eternal/faq/?locale=en_US
