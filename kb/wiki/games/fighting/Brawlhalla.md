---
type: game
tags: [game-study, fighting, platform-fighter, f2p, crossplay, rollback-netcode, roster, pvp]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Brawlhalla
  - https://www.brawlhalla.com/
  - https://store.steampowered.com/app/291550/Brawlhalla/
  - https://steamcommunity.com/app/291550/discussions/0/2796125475578125516/
  - https://www.metricgamer.com/game/brawlhalla/
---
# Brawlhalla

Free-to-play platform fighter by Blue Mammoth Games (acquired by Ubisoft in 2018) featuring 68 "Legends," a weapon-assignment roster system, and full crossplay across every major platform since 2019 — with over 80 million registered players as of 2022.

## Design

**Platform and roster.** Brawlhalla launched in Early Access in 2015, reaching full release October 17, 2017 across Windows, macOS, and PS4, with Switch and Xbox One following in 2018 and mobile (iOS/Android) in 2020. As of early 2026 the roster stands at 68 Legends. Rather than giving each Legend a wholly unique moveset, every fighter draws from a pool of 15 weapons (sword, axe, hammer, spear, rocket lance, katars, blasters, bow, scythe, gauntlets, cannon, orb, greatsword, battle boots, chakram). Each Legend is assigned exactly two weapons and has four tunable stats — Strength, Dexterity, Defense, and Speed — that differentiate fighters who share the same weapon pair. This design dramatically reduces the asset footprint per character while preserving meaningful matchup variance.

**F2P model.** Nine Legends rotate weekly for free play; all 68 can be permanently unlocked for $19.99 (all-access pack) or through earned in-game currency (Gold). Cosmetics — skins, colors, KO effects, podium animations — are sold via premium Mammoth Coins or a seasonal Battle Pass. There is no pay-to-win element: stats and weapons are locked per Legend regardless of spending.

**Standout mechanic — mobility and wall interaction.** Legends have three jumps and near-unlimited wall scaling, enabling vertical play more aggressive than most platform fighters. This, combined with a dodge system that has both ground and air variants, opens up movement sequences that reward high-level mastery without requiring the frame-perfect wavedashing of [[Super Smash Bros Ultimate]].

**Crossover Legends.** Brawlhalla aggressively licenses outside IP — Rayman, Lara Croft, WWE superstars, Harley Quinn, and many others appear as "cross-overs" (reskinned Legend slots) rather than unique roster additions, letting the game tap pop-culture moments without fracturing balance.

**Competitive scene.** Annual World Championships have run since 2016, with Royale-format majors since 2023, giving the game one of the longest-running tournament circuits in platform fighting.

## Implementation

Brawlhalla uses a server-authoritative rollback netcode system. Both clients run independent local simulations with no artificial input delay; if a client's inputs arrive late to the server, the server rolls back to resync the simulation. Because the authority lives on the server rather than peer-to-peer, lag from one player does not degrade the experience for the other — a design trade-off that favors casual accessibility over the pure peer-to-peer rollback quality of more technically demanding titles. Full crossplay across PC, PS4/PS5, Xbox One/Series, Switch, iOS, and Android has been live since October 2019.

## Why it matters

Brawlhalla demonstrates that a platform fighter can reach massive F2P scale (80 M+ accounts) by decoupling cosmetics from mechanics, using a weapon-pool system instead of per-character unique framedata, and running crossplay across 6+ platforms from a single codebase. Its server-rollback model trades some competitive purity for a smoother casual experience — a meaningful data point for any multiplayer dungeon-crawler that needs online play to "just work" across device types.

## Relevance to Wayfinder

1. → [[Combat]]: the weapon-pool stat-block model (each fighter picks 2 weapons, 4 numeric stats) is a lightweight design pattern that could inform how Wayfinder arms and differentiates character builds without ballooning unique-asset cost per class.
2. → [[Multiplayer Co-op]]: server-authoritative rollback and full crossplay as a package shows that accessible co-op online play is achievable without requiring pure peer-to-peer rollback infrastructure, which matters for a cozy game aimed at broad platform reach.
3. → [[Multiplayer Co-op]]: the rotating free-character model and cosmetic-only monetization is a proven template for keeping a F2P co-op experience feel fair and welcoming to new players.

## See also

- [[Super Smash Bros Ultimate]]
- [[MultiVersus]]
- [[Rivals of Aether]]
- [[Combat]]
- [[Multiplayer Co-op]]
- [[Game Index]]
- [[Game Studies]]
- [[Design Influences]]

## Sources

- https://en.wikipedia.org/wiki/Brawlhalla
- https://www.brawlhalla.com/
- https://store.steampowered.com/app/291550/Brawlhalla/
- https://steamcommunity.com/app/291550/discussions/0/2796125475578125516/
- https://www.metricgamer.com/game/brawlhalla/
