---
type: game
tags: [game-study, colony-sim, emergent-narrative, storyteller-ai, crafting, economy, permadeath]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/RimWorld
  - https://zaydqazi.substack.com/p/the-story-generator-a-game-design
  - https://www.gamedeveloper.com/design/dwarf-fortress-and-rimworld-tell-very-different-stories
  - https://rimworldgame.com/
---
# RimWorld

Colony management sim (2018, Ludeon Studios / Tynan Sylvester) that replaces scripted campaigns with an AI Storyteller that orchestrates events to generate emergent drama from systems collisions.

## Design

- **AI Storyteller system.** Three director personas — Cassandra Classic (escalating tension), Phoebe Chillax (relaxed), Randy Random (chaos) — monitor colony state and inject events (raids, disease, mental breaks) timed to maximize narrative pressure rather than follow a fixed schedule. Each playthrough is a different story authored by the rules, not the writer.
- **Pawn trait/need simulation.** Every colonist carries randomised backstories, skills, and personality traits that interact continuously: a pyromanic surgeon heals wounds by day and sets fires during mental breaks. Physical health (injuries, prosthetics, illness) and psychological well-being (mood, needs) are tracked in parallel, so a cascade from one domain floods the other.
- **Production chains and economy.** Survival demands interlocked loops: grow crops → cook meals → feed workers → maintain mood → sustain productivity. Trade caravans and orbital traders create an export economy: craft goods, sell surplus, buy technology. Scarce resources force genuine trade-offs (burn wood for warmth vs. build defences).
- **Research progression.** A tech tree advances the colony from neolithic tools through industrial to spacefaring technology. Research unlocks new production recipes, structures, and combat options, sustaining engagement across multi-year playthroughs.
- **Standout mechanic — event cascade.** A single pawn injury can avalanche: treatment takes a skilled doctor off farming duty → food stores shrink → hunger debuffs reduce hauling speed → construction stalls → winter arrives under-prepared. The game is a cascade machine.

## Implementation

- Built on **Unity** (C#); tile-based top-down view with ASCII-readable information density borrowed from Dwarf Fortress's readability ambitions, but delivered through actual sprites.
- Procedurally generated maps and biomes via seeded noise; storyteller events are drawn from a weighted pool filtered by current colony wealth and threat score, keeping difficulty responsive without a hard difficulty slider.
- Pawn needs tick on a per-second basis; mood is a rolling average of recent needs satisfaction, smoothing out single-frame spikes while allowing sustained neglect to accumulate.
- Steam Workshop modding pipeline extended the content surface dramatically; over $100 million revenue by 2020 on a single-developer codebase.

## Why it matters

RimWorld proved that an AI event director — not scripted story — is the engine of compelling colony narrative. Tynan Sylvester's *Designing Games* (2013) codified the theory before RimWorld shipped the proof. The lesson: invest in systems that collide interestingly, then let a lightweight director amplify the drama already latent in those collisions.

## Relevance to Wayfinder

- The **AI Storyteller model** directly informs how [[Affixes]] could modulate dungeon run difficulty: instead of fixed parameters, affix combinations create emergent pressure curves without scripted beats.
- The **cascade mechanic** is a design target for [[Gathering]] and [[Crafting]]: a broken gather node should propagate downstream through the craft → equip → delve loop, making resource choices feel weighty.
- The **pawn economy loop** (produce surplus → trade → unlock tech) mirrors Wayfinder's intended [[Economy]]: chart profits should fund Trade ladders, not sit in a wallet.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[Dwarf Fortress]] · [[Oxygen Not Included]] · [[Frostpunk]]
- Wayfinder: [[Crafting]] · [[Gathering]] · [[Economy]] · [[Balance Philosophy]]

## Sources

- https://en.wikipedia.org/wiki/RimWorld
- https://zaydqazi.substack.com/p/the-story-generator-a-game-design
- https://www.gamedeveloper.com/design/dwarf-fortress-and-rimworld-tell-very-different-stories
- https://rimworldgame.com/
