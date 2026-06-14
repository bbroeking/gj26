---
type: game
tags: [game-study, colony-sim, automation, factory-building, logistics, progression, systems-thinking]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Factorio
  - https://medium.com/gaming-is-good/factorio-taught-me-systems-thinking-part-i-f8a1d2a8a349
  - https://arxiv.org/pdf/2102.04871
---
# Factorio

Automation and factory-building game (2020, Wube Software) where the player's goal is to launch a rocket by constructing an ever-expanding automated industrial supply chain on an alien planet.

## Design

- **Automation as the core verb.** Every action the player performs manually is a step toward automating that action away. Mining → auto-drills; hand-crafting → assemblers; hand-delivery → belts and inserters. The game's tension is always the gap between current throughput and what the next tier of research demands.
- **Belt/inserter logistics.** The game's elegantly constrained transport layer: items move on conveyor belts, inserters swing items between belt and machine. Bottlenecks are spatially legible — a backed-up belt is a visual cue. This physical layout of production chains makes factory design a puzzle of geometry as much as resource flow.
- **Research tech tree as pacing engine.** Science packs of increasing complexity (red → green → blue → purple → yellow → space) gate technology unlocks. Each tier requires new raw material categories, pulling the player deeper into automation investment before the next frontier opens.
- **Scalability spiral.** Early-game manual crafting; mid-game "main bus" designs with centralised resource throughput; late-game parallel mega-factories and train logistics networks spanning the map. The same problem (make more of X) recurses at each scale, but the solution space expands.
- **Standout mechanic — biters and pollution.** The factory produces pollution; pollution attracts native biter creatures to attack. This is an elegant loop: expand too fast → generate too much pollution → overwhelm defences → lose factory. Growth is the threat to growth.

## Implementation

- Built by a small Czech team (Wube Software) in **C++** with a proprietary engine optimised for high entity counts; the game is notorious for remaining smooth with factories running tens of thousands of entities simultaneously.
- Simulation uses a game-tick model (60 ticks/second); each entity updates on its scheduled interval. Belts use a specialised transport-line simulation that avoids per-item physics, enabling massive belt throughput without per-entity cost.
- Blueprint system serialises factory layouts as data strings, enabling community sharing and enabling the game's extensive speedrun and challenge culture.
- 3.1 million copies sold by February 2022; the 2024 *Space Age* expansion sold 400,000 copies in its first week at a full premium price — exceptional commercial performance for a 4-year-old indie.

## Why it matters

Factorio crystallised **factory-building as a genre** and demonstrated that complexity without UI polish can be commercially dominant if the underlying system is mathematically elegant. It also proved that a satisfaction loop built entirely on *throughput optimisation* (make the number bigger) can sustain hundreds of hours of engagement with no narrative layer at all.

## Relevance to Wayfinder

- The **bottleneck-as-feedback** design (belt backup = visible problem) is a model for [[Gathering]] node visualisation: a depleted ore rock or forage node should communicate resource state spatially, not through a pop-up.
- The **automation unlock curve** (research unlocks better extraction tools) maps directly onto [[Crafting]] Trade progression: each Trade level should meaningfully change *how* you gather or craft, not just boost numbers.
- Factorio's **pollution/biters loop** — where expansion creates its own threat — is a [[Balance Philosophy]] reference: in Wayfinder, deeper chart affixes should increase dungeon hostility, so ambition costs.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[RimWorld]] · [[Dwarf Fortress]] · [[Oxygen Not Included]]
- Wayfinder: [[Crafting]] · [[Gathering]] · [[Economy]] · [[Balance Philosophy]]

## Sources

- https://en.wikipedia.org/wiki/Factorio
- https://medium.com/gaming-is-good/factorio-taught-me-systems-thinking-part-i-f8a1d2a8a349
- https://arxiv.org/pdf/2102.04871
- https://arxiv.org/html/2502.01492v1
