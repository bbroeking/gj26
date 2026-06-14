---
type: game
tags: [game-study, roguelike, procedural-generation, permadeath, ascii, dungeon-crawler]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Rogue_(video_game)
  - https://playbackgames.medium.com/rogue-1980-53d63e37628d
  - https://procedural-generation.tumblr.com/post/113155864626/rogue-1980
---
# Rogue

A Unix dungeon-crawling RPG designed by Michael Toy and Glenn Wichman (with Ken Arnold), released circa 1980, that invented procedural dungeon generation and permadeath and gave its name to an entire genre.

## Design

- **Procedural dungeon:** Each playthrough generates a new dungeon. Toy and Wichman rejected "canned" adventures where the layout is identical each run. Structurally, each level is conceived as a 3×3 tic-tac-toe grid; rooms of varying size fill each cell and hallways connect them, preventing orphaned dead zones from fully random placement.
- **Depth and objective:** The dungeon descends 26 floors. The player's goal is to retrieve the Amulet of Yendor from the deepest level and escape back to the surface — an early example of a timed/scarcity arc rather than pure score-chasing.
- **Permadeath with save-deletion:** Death is permanent. Notably, the save file is deleted on load, preventing players from reloading at a checkpoint. Wichman later called this "consequence persistence."
- **Item identification:** Potions, scrolls, rings, and wands appear with randomized descriptors (a potion is "bubbly," a scroll is "ZELGO MER") whose true identities are shuffled every run. Discovery happens through experimentation or risk — a mechanic that drives curiosity and tension simultaneously.
- **Food clock:** Hunger depletes each turn, pressuring forward movement and penalizing loitering on a level — the earliest example of what Spelunky would later solve with the Ghost.
- **Turn-based, single-player:** Tile movement, melee combat, and monster behavior are all turn-based, giving players time to think even under resource pressure.

## Implementation

- **Engine:** Ken Arnold's `curses` library (later `ncurses`) allowed characters to be placed at arbitrary terminal positions, enabling the ASCII "graphics" — dungeon walls as `#`, the player as `@`, monsters as letters. This was the key technical enabler.
- **Language / platform:** Written in C for Unix. Distributed widely through BSD 4.2, making it a fixture on university systems in the early–mid 1980s. Commercial ports for personal computers were later made by Toy, Wichman, and Jon Lane under A.I. Design (published by Epyx).
- **Procgen approach:** The 3×3 room grid + hallway connection system is deterministic per-seed but varies each game. The seed is not exposed to the player, which means there is no concept of "daily seeds" — the game is simply different each time.
- **Successors:** Hack (1982) and Moria (1983) built directly on Rogue's foundation; NetHack (1987) and Angband are direct descendants.

## Why it matters

Rogue is the genre singularity. Every mechanic it introduced — procedural dungeons, permadeath, item identification via experimentation, hunger clocks — became the load-bearing design language of roguelikes and, later, roguelites. The word "roguelike" literally derives from it. Understanding Rogue is prerequisite knowledge for understanding why any of its descendants make the choices they do.

## Relevance to Wayfinder

- **[[Dungeon Generation]]:** Rogue's 3×3 grid-of-rooms approach is an ancestor of layout strategies worth considering — guaranteed connectivity, controlled room count, hallways as explicit connectors. Wayfinder's chart-driven dungeons share the goal: a navigable space that is always completable.
- **[[Chart Loop]]:** Rogue's "descend, retrieve Amulet, escape" arc is the original chart-loop template — enter a keyed space, reach the objective, extract. The trophy chain in Wayfinder maps onto this.
- **[[Affixes]]:** Rogue's randomized item identification (unknown descriptors, shuffled per run) is an early affix-adjacent mechanic — items carry hidden properties the player must discover. Wayfinder's affixes are more structured but share the "unknown until engaged" tension.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[NetHack]] · [[Spelunky]] — direct descendants
- [[Dungeon Generation]] · [[Chart Loop]] · [[Affixes]]
- [[MMO Progression Systems]] · [[MMO Lessons for Wayfinder]]

## Sources

- https://en.wikipedia.org/wiki/Rogue_(video_game)
- https://playbackgames.medium.com/rogue-1980-53d63e37628d
- https://procedural-generation.tumblr.com/post/113155864626/rogue-1980-weve-mentioned-roguelikes-but-just
