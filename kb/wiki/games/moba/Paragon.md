---
type: game
tags: [game-study, moba, third-person, epic-games, unreal-engine, shutdown, cautionary-tale]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Paragon_(video_game)
  - https://productmint.com/what-happened-to-paragon/
  - https://games.mxdwn.com/news/tim-sweeney-of-epic-games-is-not-sure-what-lessons-to-learn-from-paragon/
  - https://www.unrealengine.com/developer-interviews/why-paragon-fueled-moba-predecessor-shifted-to-unreal-engine-5
---
# Paragon

Third-person AAA MOBA (Early Access March 2016, Epic Games) that combined Unreal Engine 4 production values with a card-based item system and vertical map design, then shut down April 26, 2018 after failing to retain a sustainable player base in the shadow of Fortnite's rise.

## Design

- **Third-person camera:** Like Smite, Paragon placed the camera behind the hero rather than above the map, emphasising visual spectacle and manual-aim skill shots. With UE4 fidelity, it was the best-looking MOBA at launch.
- **Card-based itemization:** Rather than a traditional shop, players assembled decks of cards between matches that granted stat bonuses and unlocked new powers in-game. Designed to create strategic pre-match choices but in practice made the game opaque and hard to learn for newcomers. A major late overhaul replaced cards with a more conventional system — players saw this as a loss of identity.
- **Map verticality:** The map had meaningful elevation, with high ground and chokepoints that rewarded spatial awareness beyond lane/jungle navigation. Unique among genre peers.
- **Hero design:** Colorful, distinct characters with strong visual identities; detailed animations and voice acting. An estimated $12–17 million worth of hero assets, environments, and VFX were created over the game's life.
- **Player numbers:** 7.3 million downloads by July 2017 — a headline number that concealed poor day-30 retention. Active concurrent players were never publicly stated but were described internally as insufficient for sustainability.
- **"New Dawn" patch (August 2017):** Full hero rebalance plus skin price increases. Community backlash from existing players was severe; new players were not acquired to compensate.

## Implementation

- **Engine:** Unreal Engine 4. Epic used Paragon as an internal showcase for UE4's capabilities in a live-service context. The replay/broadcast system built for Paragon was later repurposed for Fortnite's replay engine.
- **Netcode:** UE4 standard client-server authoritative model. No separately documented tick rate or notable netcode innovations in available sources.
- **Platform:** PC and PlayStation 4 simultaneously — an unusual launch decision for an early-access MOBA that may have diluted the community.

## Why it matters

- **Resource competition kills live-service games:** Fortnite's Battle Royale mode launched September 2017; within months Epic shifted significant dev resources away from Paragon. A live-service game can survive a design misstep but rarely survives having its studio redirect attention elsewhere. The practical lesson: internal competition for resources is as dangerous as external market competition.
- **Late-stage pivot risk:** The card system overhaul alienated the existing player base without attracting enough newcomers — a classic case of changing the wrong variable. The community's complaint ("LoL wannabe 2.0") captured the loss of differentiation.
- **Generous sunset, transferable tech:** Epic released all Paragon assets free on the UE4 Marketplace and repurposed the replay tech in Fortnite. Even a failed game generates reusable value when the team builds in a generalizable engine.
- **Tim Sweeney's candour:** His public statement that he was "not sure what lessons to learn from Paragon" is unusual executive honesty — and itself a lesson that post-mortem clarity is rare when a title is overshadowed by a sudden mega-hit.
- **Successor fragility:** Paragon's spiritual successors (Predecessor, Overprime) reused its assets but could not inherit its audience; Predecessor itself later shut down. Asset quality alone does not rebuild a community.

## Relevance to Wayfinder

- [[Combat]]: Paragon's card system shows the danger of making the pre-game itemization phase opaque — Wayfinder's chart/affix system must be learnable within a few runs, with complexity revealed progressively rather than front-loaded.
- [[Multiplayer Co-op]]: The dual PC/PS4 simultaneous launch fractured an already thin player pool. Wayfinder should focus platform breadth only after proving a healthy population on a primary platform.
- [[Balance Philosophy]]: The "New Dawn" patch failure — full rebalance plus monetization change in one update — illustrates why balance changes and monetization changes should be decoupled. Don't ask the community to absorb two adjustments at once.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]] · [[Balance Philosophy]]
- [[MMO Social and Endgame]]
- Siblings: [[League of Legends]] · [[Dota 2]] · [[Heroes of the Storm]] · [[Smite]]
- Wayfinder: [[Combat]] · [[Multiplayer Co-op]] · [[Balance Philosophy]]

## Sources

- https://en.wikipedia.org/wiki/Paragon_(video_game)
- https://productmint.com/what-happened-to-paragon/
- https://games.mxdwn.com/news/tim-sweeney-of-epic-games-is-not-sure-what-lessons-to-learn-from-paragon/
- https://www.unrealengine.com/developer-interviews/why-paragon-fueled-moba-predecessor-shifted-to-unreal-engine-5
