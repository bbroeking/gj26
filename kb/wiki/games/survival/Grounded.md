---
type: game
tags: [game-study, survival, crafting, base-building, co-op, accessibility, unreal-engine, insect-ecosystem]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Grounded_(video_game)
  - https://grounded.obsidian.net/game
  - https://www.denofgeek.com/games/grounded-obsidian-interview-pc-xbox/
  - https://www.tomsguide.com/reviews/grounded
---
# Grounded

Micro-scale survival co-op (2022, Obsidian Entertainment) in which up to four shrunken teenagers survive a suburban backyard, crafting gear from insect parts and grass blades while navigating a living ecosystem of ants, spiders, and beetles.

## Design

- **Scale inversion as world-building lever.** Shrinking players to bug scale turns a mundane backyard into a genuinely alien biome — a blade of grass is a climbable tower, a dewdrop is a water source, a garden tool is a dungeon landmark. This produces a dense, hand-authored world that reads as vast without procedural generation.
- **Dynamic insect ecosystem.** Insects follow real behavioral logic: ladybugs hunt aphids, wolf spiders patrol territory, ants carry resources to the colony. Clearing aphids from an area causes ladybugs to redirect. This creates an ecology the player can observe, predict, and manipulate — enemy management rather than pure avoidance.
- **Gear tier ladder tied to enemy parts.** Crafting progression gates on specific insect drops: spider silk for rope, mite fuzz for armor padding, larva blade for early weapons. Defeating harder insects unlocks better gear, tying combat challenge to crafting depth without a separate XP system.
- **Accessibility as a first-class feature.** Grounded shipped a five-level Arachnophobia Safe Mode that progressively removes spider legs, then fangs, then visual detail, down to a floating blob. This is a landmark in survival-game accessibility — a mechanic that would exclude many players was made opt-out without gameplay compromise.
- **Four-player shared-world co-op with persistent progression.** All players contribute to the same base and share crafting unlocks. The host's world persists; guests bring their own character inventory. This encourages specialization without fragmenting the economy.

## Implementation

- Built in **Unreal Engine 4**. Obsidian (an RPG studio) staffed the project as a smaller team experiment, shipping through Xbox Game Preview for two years before 1.0.
- Insect AI uses behavior trees with faction-aware target prioritization. Enemy difficulty scales with distance from the starting area, approximating a radial progression map.
- The arachnophobia system uses LOD swapping: high-threat spider meshes are replaced at runtime by low-poly stand-ins with reduced appendage count, preserving hitboxes and AI behavior.
- Crossplay and Shared Worlds require a Microsoft account; saves are cloud-synced across Xbox and PC.
- A sequel, Grounded 2, entered Game Preview in 2026, expanding the ecosystem to additional biomes.

## Why it matters

Grounded demonstrated that a AAA-adjacent studio could ship a polished survival game at reduced scope — the backyard is a tiny world, but its density rivals open-world titles. Its arachnophobia system became an oft-cited example of how accessibility options can be deeply mechanical rather than cosmetic. 20 million players across platforms by 2022 validated the survival genre on console as much as PC.

## Relevance to Wayfinder

- **Ecosystem-driven resource gathering:** insects behave predictably within their ecology; this maps cleanly to [[Gathering]] — GatherNodes whose yield or availability depends on surrounding den ecology could create the same "observe, plan, harvest" feel.
- **Enemy-part crafting gates:** tying [[Crafting]] tier unlocks to specific enemy drops (boss trophies, den materials) rather than XP is exactly the Wayfinder model — Grounded's implementation shows this works at scale without feeling grindy if enemy variety is high.
- **Accessibility-by-design:** Wayfinder's cozy positioning makes accessibility mandatory, not optional; Grounded's arachnophobia slider is a template for layered, mechanics-aware difficulty/comfort options.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- Siblings: [[Valheim]] · [[Minecraft]] · [[The Forest]] · [[Subnautica]] · [[Don't Starve]]
- Wayfinder: [[Gathering]] · [[Crafting]] · [[Multiplayer Co-op]] · [[Items and Gear]]

## Sources

- https://en.wikipedia.org/wiki/Grounded_(video_game)
- https://grounded.obsidian.net/game
- https://www.denofgeek.com/games/grounded-obsidian-interview-pc-xbox/
- https://www.tomsguide.com/reviews/grounded
- https://www.thegamer.com/grounded-arachnophobia-mode-guide/
