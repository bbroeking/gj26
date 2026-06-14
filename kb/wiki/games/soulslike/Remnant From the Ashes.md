---
type: game
tags: [game-study, soulslike, third-person-shooter, procedural-generation, co-op, boss-design, loot-system]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Remnant:_From_the_Ashes
  - https://www.gamedeveloper.com/design/combat-co-op-and-proc-gen-inside-the-design-of-i-remnant-from-the-ashes-i-
  - https://www.unrealengine.com/developer-interviews/remnant-from-the-ashes-blends-genres-to-become-a-unique-co-op-shooter
  - https://game.info.intel.com/gaming-access/remnant-from-the-ashes-is-a-case-of-randomness-done-right
---
# Remnant From the Ashes

Third-person shooter soulslike (2019, Gunfire Games) — a post-apocalyptic survival game that grafts soulslike checkpoint tension and boss design onto procedurally generated levels and a three-player co-op shooter loop, with no death-based resource loss.

## Design

- **Procedural generation with modular tiles.** Levels are built from pre-set modular tiles assembled algorithmically — not fully random noise. The team ran many constraint iterations to ensure layouts remained navigable and thematically coherent across variations. A player's world can include areas entirely absent from a co-op partner's, making world-comparison a social activity ("you have the cathedral?" / "I don't have that").
- **No soul-loss on death.** Unlike FromSoftware games, Remnant imposes no resource penalty on death. Checkpoint crystals reset enemy spawns and restore health but do not punish the player's economy. Difficulty comes from encounter design and boss mechanics, not from the death-penalty fear loop.
- **AI director for co-op scaling.** Rather than multiplying enemy HP linearly, an AI director selects harder creature types for two or three-player sessions. Extra enemies also serve as ammunition delivery — in extended fights, players need kills to sustain their ranged resource economy.
- **MMO-style boss design.** Multi-player boss encounters create natural role assignments: one player handles adds, others focus boss pressure. Boss arenas introduce mechanics (specific weak points, projectile patterns, environmental hazards) that are more manageable when split across a team, mirroring MMO raid design in a 3-player format.
- **Trait system (passive progression).** A flat trait system provides passive stat bonuses earned through play milestones rather than boss kills. This separates character growth from loot — even an unlucky loot run builds the character.
- **Ward 13 as social hub.** A base camp that functions as the social hub between runs: vendors, crafting, trait investment. Structurally equivalent to a bonfire hub but built for co-op assembly.

## Implementation

- Engine: Unreal Engine 4.
- Developer: Gunfire Games (previously Vigil Games, makers of Darksiders).
- Release: August 20, 2019 (PC, PS4, Xbox One); Nintendo Switch March 2023.
- Metacritic: 81/100 (Xbox One), 78/100 (PC), 77/100 (PS4), 70/100 (Switch).
- Sales: 1 million units by October 2019; 3 million by December 2021.
- Sequel: Remnant 2 (July 2023) expanded the archetype system into a dual-class model.
- Prequel: Chronos: Before the Ashes (December 2020).

## Why it matters

Remnant is the clearest proof-of-concept that soulslike difficulty and three-player co-op are compatible — the tension just moves from the death-penalty economy to the encounter itself. The AI director scaling model (change enemy composition, not enemy HP) is a more elegant co-op solution than flat multipliers: it maintains encounter identity while delivering appropriate challenge. The modular-tile procedural system also shows how to preserve thematic coherence in proc-gen without committing to fully authored levels — a directly relevant model for Wayfinder's chart-seeded dungeon generation.

## Relevance to Wayfinder

- **Proc-gen dungeon tile model.** Modular tiles with algorithm-driven assembly is essentially Wayfinder's chart/dungeon-generation brief. Remnant's constraint work ("how do we make every layout feel navigable?") maps directly to the navigational-landmark problem Wayfinder will face. See [[Camera and Game Feel]].
- **AI director co-op scaling.** Changing enemy composition per player count, rather than multiplying health, is the scalability approach Wayfinder should evaluate for its 2–4 player co-op. It preserves encounter identity and keeps solo play from feeling underpopulated. See [[Multiplayer Co-op]], [[Bosses]].
- **No death penalty as an accessibility dial.** Remnant's removal of the soul-loss penalty shows that soulslike atmosphere can survive without punishing economy loss — relevant to Wayfinder's cozy positioning, where chart loss on death is already the softest possible stakes. See [[Combat]].

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[Dark Souls]] · [[Elden Ring]] · [[Dark Souls III]]
- [[Combat]] · [[Bosses]] · [[Camera and Game Feel]] · [[Multiplayer Co-op]] · [[Items and Gear]]

## Sources

- https://en.wikipedia.org/wiki/Remnant:_From_the_Ashes
- https://www.gamedeveloper.com/design/combat-co-op-and-proc-gen-inside-the-design-of-i-remnant-from-the-ashes-i-
- https://www.unrealengine.com/developer-interviews/remnant-from-the-ashes-blends-genres-to-become-a-unique-co-op-shooter
- https://game.info.intel.com/gaming-access/remnant-from-the-ashes-is-a-case-of-randomness-done-right
