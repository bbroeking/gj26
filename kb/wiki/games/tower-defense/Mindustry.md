---
type: game
tags: [game-study, tower-defense, factory, automation, rts, open-source, resource-chains]
status: draft
updated: 2026-06-14
sources:
  - "https://en.wikipedia.org/wiki/Mindustry"
  - "https://github.com/Anuken/Mindustry"
  - "https://mindustrygame.github.io/"
  - "https://tvtropes.org/pmwiki/pmwiki.php/VideoGame/Mindustry"
---

# Mindustry

Anuken's 2017 open-source automation-tower-defense RTS in which the defense itself is a supply chain: towers must be fed ammo via conveyor belts and factories, so building a sustainable production line is the same act as building a capable defense.

## Design

The TD loop fuses two traditionally separate genres at the systems level rather than gluing them together cosmetically. To defend, players must mine raw resources, refine them into ammo types via factory chains, route the ammo to turrets via conveyors and routers, and maintain power infrastructure for the whole network. A wall of turrets with no ammo supply is no different from no turrets at all — the factory and the defense are the same machine.

Turrets are ammunition-specific: some fire bullets (copper ammo), others fire rockets (pyratite ammo), others use more advanced materials unlocked later in the tech tree. Choosing turret type means choosing supply chain complexity, and the enemy pathfinder dynamically seeks out poorly-defended gaps in the perimeter, punishing players who optimise a single chokepoint and neglect others.

Wave escalation on Survival maps is orthodox — progressively stronger units — but the *preparation* for each wave is the factory optimisation game, not tower placement. Players spend inter-wave time extending conveyor lines, upgrading smelters, and opening new ore veins rather than repositioning towers. This makes the economy loop the primary gameplay.

The tech tree (unlocked by researching with items) introduces two full planet-scale campaigns (Serpulo and Erekir in v7.0) with different resource types and tech paths, effectively doubling the factory design space. Multiplayer supports cooperative and PvP servers, with co-op players sharing a team's build space and resource pool.

## Implementation

Developed by Anuken (solo); written in Java on the Arc framework (a fork of LibGDX). Open source under GPL-3.0 on GitHub. First developed for the GDL Metal Monstrosity Jam (April 2017); available on Steam, itch.io, Android, and iOS. Free on mobile; paid on Steam. Cross-platform Linux/Windows/macOS/mobile. Directly comparable to [[Factorio]] (factory-first, survival-defense secondary) but with a stronger RTS and active-unit combat layer.

## Why it matters

Mindustry demonstrates that "tower defense" can describe the *goal* (don't let enemies reach the core) without prescribing the *method* (passive placement). By making the supply chain the primary strategic layer, it shows how resource-gathering and base-building games can embed a survival-defense loop without those two things feeling like different games bolted together. It is the most direct precedent for any system where resource production is the same activity as combat preparation.

## Relevance to Wayfinder

1. [[Economy]] — Mindustry's factory-as-defense collapses the gather→craft→use pipeline into a single continuous flow, which is the aspirational model for Wayfinder's gather→craft→delve loop: resources gathered in the world should feed into dungeon capability directly, not via a disconnected inventory step.
2. [[Affixes]] — Dynamic enemy pathfinding that targets gaps means defense must be holistic rather than optimised around one corridor — a design principle for Wayfinder's affix system: affixes should reward adaptive builds, not single-tower dominance.
3. [[Combat]] — Mindustry's active units (player-built drones and robots) blur the player/tower distinction in a way that's relevant to Wayfinder's direction: the "one verb" of combat can encompass both personal action and deployed capability.

## See also

- [[Game Index]]
- [[Game Studies]]
- [[Design Influences]]
- [[Economy]]
- [[Affixes]]
- [[Combat]]
- [[Factorio]]
- [[Defense Grid The Awakening]]
- [[Plants vs Zombies]]

## Sources

- Wikipedia — https://en.wikipedia.org/wiki/Mindustry
- GitHub repository (Anuken/Mindustry) — https://github.com/Anuken/Mindustry
- Official site — https://mindustrygame.github.io/
- TV Tropes — https://tvtropes.org/pmwiki/pmwiki.php/VideoGame/Mindustry
