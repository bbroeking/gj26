---
type: game
tags: [game-study, factory, automation, crafting, co-op, progression, unreal-engine, first-person]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Satisfactory
  - https://coffeestain.com/game/satisfactory/
  - https://satisfactory.wiki.gg/wiki/Satisfactory
  - https://satisfactory.wiki.gg/wiki/Space_Elevator
---
# Satisfactory

First-person factory construction and automation game (2024 full release, Coffee Stain Studios) in which a lone pioneer or co-op team lands on an alien planet and progressively automates resource extraction into increasingly complex manufacturing chains, culminating in supplying a space elevator to unlock the next tier of industrial civilization.

## Design

- **Space elevator as macro-progression spine.** The entire game is structured around four Space Elevator phases, each requiring increasingly complex manufactured goods. Delivering Phase goods unlocks Milestone Tiers 3–9 in pairs. This creates a clear, self-pacing loop: automate current resources → deliver elevator phase → unlock new machines → automate higher-tier resources. Players always know what they are building toward.
- **Automation as the core verb.** Manual crafting exists only as a bootstrap step; the real gameplay is designing automated production lines using conveyors, splitters, mergers, pipelines, and programmable machines. Throughput planning (balancing input rate to output rate across multiple factory floors) is the skill ceiling.
- **Hand-crafted 30 km² world with biome diversity.** Unlike most survival games, Satisfactory uses a fixed, authored map rather than procedural generation. Biomes are designed to distribute resources intentionally — copper deposits are near the spawn but steel requires cross-map logistics, nudging players to build transport infrastructure.
- **Tiered blueprint complexity.** Each of ten tiers unlocks new machine types and building recipes. Late-game Tier 9 introduces Quantum Encoders, Converters, and Portals (requiring massive power generation), ensuring the factory-design challenge scales with infrastructure scale.
- **Co-op as shared factory ownership.** Up to four players share a single persistent factory. All players build in the same world simultaneously; there is no host-only ownership model. This makes co-op feel genuinely collaborative rather than one player hosting a sandbox for guests.

## Implementation

- Built in **Unreal Engine 5** (migrated from UE4 in November 2023 before 1.0 launch). Coffee Stain cited improved streaming and stability as the primary migration drivers.
- Full release September 10, 2024 after five years in Early Access; the team shipped continuously during EA, using player feedback to tune progression pacing.
- Factory simulation uses a tick-based throughput model: each machine has an input/output rate in items-per-minute, and the game tracks inventory buffers in real time. No event-driven simulation — the factory either runs or stalls based on steady-state flow.
- Dedicated server support (via Coffee Stain's own server tool) allows persistent factory operation without a host being online — a significant co-op QoL feature.
- Console release (PS5, Xbox Series X/S) November 2025.

## Why it matters

Satisfactory validated the factory-automation genre for a mainstream audience by wrapping its complexity in a first-person exploration shell — players discover resource deposits by physically travelling to them, which makes the map feel alive rather than a logistics spreadsheet. Its five-year Early Access run is an example of a studio successfully using live player iteration to tune a system-heavy game without shipping a broken 1.0. The space elevator as a shared, visible macro-goal also serves as a social alignment mechanic in co-op: everyone knows what the team is building toward.

## Relevance to Wayfinder

- **Visible macro-goal as session anchor:** the Space Elevator gives every play session a known destination; Wayfinder's [[Economy]] and chart system could benefit from an equivalent — a season-long community goal (e.g., "fill the Summit vault") that individual chart runs contribute toward.
- **Automation unlocking at tiers:** the way Satisfactory gates machine types behind deliverable milestones is a template for Wayfinder's [[Crafting]] tier unlocks — not XP, but output: prove you can make X to gain access to Y.
- **Dedicated server for async co-op:** Satisfactory's dedicated server model means the factory runs when players are offline; Wayfinder's [[Multiplayer Co-op]] could reference this for persistent den instances or shared gathering plots that accumulate resources between sessions.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- Siblings: [[Minecraft]] · [[Valheim]] · [[No Man's Sky]]
- Wayfinder: [[Crafting]] · [[Economy]] · [[Gathering]] · [[Multiplayer Co-op]]

## Sources

- https://en.wikipedia.org/wiki/Satisfactory
- https://coffeestain.com/game/satisfactory/
- https://satisfactory.wiki.gg/wiki/Satisfactory
- https://satisfactory.wiki.gg/wiki/Space_Elevator
- https://coffeestain.com/news/satisfactory-1-0-launch/
- https://xgamingserver.com/blog/satisfactory-milestones-tech-tree/
