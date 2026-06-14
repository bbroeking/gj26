---
type: game
tags: [game-study, puzzle, adventure, top-down, world-nesting, indie, annapurna]
status: draft
updated: 2026-06-14
sources:
  - "https://www.gamedeveloper.com/design/the-challenges-of-laying-worlds-upon-worlds-in-puzzle-game-cocoon"
  - "https://en.wikipedia.org/wiki/Cocoon_(video_game)"
  - "https://store.steampowered.com/app/1497440/COCOON/"
---

# Cocoon

Geometric Interactive's 2023 puzzle-adventure in which the player carries entire self-contained worlds inside orbs that can be nested inside one another, making the act of traversal itself the central puzzle mechanic.

## Design

Cocoon's core verb is world-switching: the player (a beetle-like creature) places an orb into a pedestal to enter the world inside it, or lifts the orb to carry it between environments. Because each world contains pedestals that accept other orbs, worlds can be nested to arbitrary depth — a world inside a world inside a world — and the state of each world persists while the player is elsewhere.

The teaching approach is wordless and incrementally scaffolded. The game introduces world-jumping first, in isolation, before adding any puzzle logic. Each subsequent room adds exactly one new layer of complexity — changing only one variable — so players can attribute any new behavior to the one thing that changed. Director Jeppe Carlsen (previously lead gameplay designer on Limbo and Inside) describes this as designing for "mental scaffolding": each room's solution must be within reach of the cognitive model the previous room built.

Boss encounters deliberately break the puzzle rhythm. Each boss introduces a new movement mechanic (water jetpack, dash, mirror-teleportation) as a physical toy before weaving it into puzzle solutions. This pacing creates decompression moments that prevent cognitive overload and reward the player with kinetic pleasure between dense logic sequences.

The difficulty curve is notably linear: the game has no branch points, so a player stuck in one area cannot self-rescue by exploring elsewhere (unlike The Witness). Carlsen compensated by keeping individual puzzle complexity low enough that no single room should block for long.

## Implementation

Built in Unity. The nested world structure demanded substantially more complex scene management than a conventional linear game: the engine must hold multiple complete worlds in memory simultaneously, ready to swap in seconds when the player jumps between orbs. Level design became recursive — to test a single puzzle room, the designer must first set up the correct state of all surrounding worlds and place all orbs in their correct nesting order. Four distinct orb abilities were shipped: invisible bridge manifestation, vertical-tower toggling, orb-cloning into eggs, and cross-world projectile firing. A rhythm-based orb was prototyped and cut; player testing showed it introduced distraction rather than depth.

Released September 2023 across PC, Switch, PS4/5, and Xbox. Metacritic 88–90. Won The Game Awards Best Debut Indie Game and D.I.C.E. Award for Outstanding Achievement in an Independent Game; Eurogamer's 2023 Game of the Year.

## Why it matters

Cocoon shows that spatial reasoning at one level of abstraction (navigating a room) can be reused at a higher level (navigating between rooms-as-objects) with minimal new UI or vocabulary. The orb as simultaneously a tool, a world, and an inventory item is one of the cleanest multi-role object designs in recent games. Its wordless onboarding proves that even deeply novel mechanics can be player-discovered in under an hour given careful staging.

## Relevance to Wayfinder

1. [[Onboarding and Tutorial]] — The single-variable-change-per-room rule is a concrete heuristic Wayfinder can apply to den room sequencing: introduce one new encounter type or affix per room before layering interactions.
2. [[Dungeon Generation]] — Cocoon's recursive state problem (world state must be prepared before testing) is analogous to Wayfinder's affix-combination testing problem; the lesson is to build authored "safe sequences" the procgen can reference as scaffolding.
3. [[Dungeon Generation]] — Boss-as-decompression (kinetic toy before puzzle integration) is a model for Wayfinder's boss encounters breaking out of the one-verb combat loop with a distinct movement ability.

## See also

- [[Game Index]]
- [[Game Studies]]
- [[Design Influences]]
- [[Onboarding and Tutorial]]
- [[Dungeon Generation]]
- [[Portal 2]] (parallel: wordless teaching through environmental staging)
- [[Baba Is You]] (sibling: systems that nest inside each other)

## Sources

- [The Challenges of Laying Worlds Upon Worlds in COCOON — Game Developer](https://www.gamedeveloper.com/design/the-challenges-of-laying-worlds-upon-worlds-in-puzzle-game-cocoon)
- [Cocoon (video game) — Wikipedia](https://en.wikipedia.org/wiki/Cocoon_(video_game))
- [COCOON on Steam](https://store.steampowered.com/app/1497440/COCOON/)
