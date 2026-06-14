---
type: game
tags: [game-study, ccg, digital-card-game, monetization, f2p, riot-games, cosmetics-only]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Legends_of_Runeterra
  - https://www.pcgamesn.com/legends-of-runeterra/monetisation
  - https://www.pcgamer.com/Legends-of-runeterra-coins-microtransactions-economy/
  - https://mobalytics.gg/blog/lor/legends-of-runeterra-guide/
  - https://masteringruneterra.com/does-legends-of-runeterra-make-a-profit/
---

# Legends of Runeterra

Digital CCG (2020, Riot Games) — the most generous-economy card game ever shipped at scale, built on cosmetics-only monetization and a weekly vault acquisition system that let players earn the full card pool through play alone.

## Design

- **Attack token alternation**: Instead of turn-based play, each round one player holds the "attack token" and can commit to an attack; the opponent then responds. The token alternates each round and can also be passed — creating a reactive, decision-dense flow without Magic's full priority stack.
- **Spell speed tiers**: Four speeds — Slow (pre-combat only, opponent can respond), Fast (during combat, opponent can respond), Burst (instant, no counterplay), Focus (instant, outside combat only). Speed selection replaces the full stack model, giving meaningful counterplay options while reducing rules complexity.
- **Champion leveling**: Champion cards transform mid-game into stronger versions when a specified in-game condition is met (e.g., attack six times), and all copies in the deck upgrade simultaneously. Creates narrative momentum without card advantage RNG.
- **Region deck-building**: Ten regions with distinct identities; standard decks may combine cards from at most two regions. No neutral cards. Forces thematic synergy and limits degenerate multi-color stacking.
- **Cosmetics-only monetization**: At launch, real money bought only cosmetics (card backs, boards, guardian pets). Cards themselves were never sold in random packs. Players could purchase specific cards directly with earned shards or coins (with a weekly cap of 3 champion purchases to pace collection growth).
- **Weekly Vault**: A tiered chest that levels up based on weekly play, yielding cards, shards, and wildcards. Higher play frequency unlocks higher chest tiers — a pacing mechanism that rewards engagement without demanding spending.
- **Postmortem**: The model proved financially unsustainable. By January 2024, Riot downsized the LoR team significantly, pivoting to PvE content. The cosmetics-only model generated insufficient revenue to sustain competitive development. _(Source: Wikipedia, industry reporting)_

## Implementation

- Built on **Unity**; cross-platform on Windows, iOS, and Android with shared progression.
- Server-authoritative state with client prediction for animation; the attack/block flow requires tight sync because both players act during a single round.
- Card effects resolved through a keyword-based system rather than a full stack engine, reducing both implementation complexity and player cognitive load.
- Launched April 29, 2020; mobile added simultaneously.

## Why it matters

- Proved definitively that cosmetics-only monetization for a competitive card game at scale is likely unviable without IP draw strong enough to command high cosmetic ARPU (like Fortnite skins). The lesson is not "never do it" but "cosmetics-only requires enormous concurrent player base or very high per-cosmetic ASP."
- The attack token / spell speed model is a compelling middle ground between Magic's full-priority complexity and Hearthstone's no-interaction turns. It introduces meaningful counterplay without requiring encyclopedic rules knowledge.
- Champion leveling is a transferable mechanic for any game that wants card/unit upgrade without random draw — the condition is visible and plannable, not RNG-gated.

## Relevance to Wayfinder

- **[[Economy]]**: LoR is the hardest cautionary data point for free-card economies. If Wayfinder's gather-and-craft loop produces every chart piece freely, monetization must rest entirely on cosmetics ([[Inks]], board art, tactician skins) — and that requires high concurrent players. The lesson is to scope cosmetic ambition to realistic player count projections.
- **[[Affixes]]**: Spell speed tiers map onto how Wayfinder might layer dungeon affix timing — some affixes that activate immediately on entry, some that trigger during combat, some that can be countered by the correct preparation item. The tier system is a cleaner model than a full stack.
- **[[Balance Philosophy]]**: Champion leveling shows how to make progression feel earned and legible: publish the condition, let players plan for it. Wayfinder's boss trophy chains and chart unlock trees could adopt the same visible-condition-to-upgrade pattern.

## See also

- [[Game Index]] · [[Game Studies]] · [[MMO Economy and Itemization]] · [[Design Influences]]
- Siblings: [[Hearthstone]] · [[Magic The Gathering Arena]] · [[Marvel Snap]] · [[Teamfight Tactics]]
- Wayfinder: [[Economy]] · [[Affixes]] · [[Balance Philosophy]] · [[Inks]]

## Sources

- https://en.wikipedia.org/wiki/Legends_of_Runeterra
- https://www.pcgamesn.com/legends-of-runeterra/monetisation
- https://www.pcgamer.com/Legends-of-runeterra-coins-microtransactions-economy/
- https://mobalytics.gg/blog/lor/legends-of-runeterra-guide/
- https://masteringruneterra.com/does-legends-of-runeterra-make-a-profit/
