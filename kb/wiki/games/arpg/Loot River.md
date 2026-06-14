---
type: game
tags: [game-study, arpg, roguelite, sliding-puzzle, dark-souls, pixel-art, straka-studio]
status: draft
updated: 2026-06-14
sources:
  - https://lootriver.com/press/sheet.php?p=loot_river
  - https://www.escapistmagazine.com/loot-river-review-in-3-minutes-block-shifting-mechanics-meet-roguelike-action/
  - https://gameinformer.com/review/loot-river/pieces-sailing-into-place
  - https://80.lv/articles/loot-river-a-game-about-unforgiving-procedural-labyrinths
  - https://eip.gg/reviews/loot-river-is-an-innovative-but-flawed-roguelike/
---

# Loot River

A Dark Souls-inspired action roguelite (2022, straka.studio) that fuses dungeon crawling with real-time Tetris-style tile-shifting: the player controls both their character and the floating ruins beneath them, sliding entire sections of floor to bridge gaps, manipulate combat terrain, and skip encounters.

## Design

**Standout mechanic: tile-shifting.** The right control stick (or equivalent) moves the platform the player stands on across a black water expanse, provided adjacent space exists. Platforms are Tetris-shaped blocks of floor; procedurally arranged at run start. The player can slide their block to connect it with other blocks, enabling movement to new sections — or to separate themselves from enemies, using water as a natural barrier. Crucially, most enemies cannot cross disconnected blocks, so isolating a platform mid-fight is a legitimate high-skill tactic. The mechanic also creates spatial puzzles: certain configurations require sequencing multiple slides to open a path, similar to a sliding-block puzzle.

**Combat.** Real-time, Soulslike-influenced: normal attacks, charged attacks, roll/dodge, and a parry mechanic. Parrying with correct timing renders the player briefly invulnerable and opens the enemy to a devastating counter. Weapon and build variety exists via loot drops (swords, axes, staves with different move sets and stat scaling), but the combat system is narrower than dedicated ARPGs — depth comes from the tile-shifting interaction rather than a deep build layer.

**Loot and roguelite loop.** Items (weapons, armor, spells) drop from enemies and bosses and are temporary, run-scoped. Permanent progression comes from "unholy knowledge" — extracted learnings that unlock permanent ability upgrades across runs, fitting the roguelite contract. Procedurally generated layouts ensure no two runs share the same platform arrangement or enemy placement. Run length is moderate, with multiple boss floors gating depth progression.

**Enemy design.** Enemies have distinct behavior profiles — some pursue aggressively across platforms, others guard fixed positions, some range-attack across water — creating different tile-shifting requirements per enemy type. The interaction between enemy behavior and platform manipulation is the game's richest design space.

**Standout endgame.** A level editor for custom platform layouts and sharing was released post-launch, extending replayability beyond the procedural base content.

## Implementation

Developed by straka.studio, a small Slovakian independent team. Backed by SUPERHOT PRESENTS (the indie funding initiative) and the Slovak Arts Council. Released May 3, 2022 for PC (Steam) and Xbox One/Series X|S; PS4/PS5 version followed December 2023. The game uses hand-drawn pixel art with real-time 3D shadows and a water simulation system — visually striking for the genre. Engine is not publicly disclosed; the pixel art with real-time shadow rendering suggests a custom or highly modified 2D engine with 3D lighting passes.

## Why it matters

Loot River is one of the clearest genre-combination successes in recent indie ARPGs: the tile-shifting mechanic is not a gimmick layered on combat but an environment-native tactical resource that interacts with every encounter. It demonstrates that a dungeon's physical layout can be a moment-to-moment gameplay variable rather than a static backdrop — a significant design space most ARPGs leave unexplored.

## Relevance to Wayfinder

- **[[Chart Loop]] — dungeon as interactive space.** Loot River's platforms-as-tactics model challenges Wayfinder to think about dungeon rooms as reactive environments. Chart affixes could alter room geometry or spawn dynamics rather than only modifying enemy stats.
- **[[Combat]] positioning depth.** The water-as-barrier mechanic shows that positioning can carry meaningful tactical weight without complex ability systems — movement itself as a primary skill. Wayfinder's FATE-camera combat can leverage terrain asymmetry similarly.
- **[[Affixes]] as run seeds.** Loot River's procedural platform arrangements are functionally per-run affixes on the spatial experience itself; Wayfinder's Charts already work this way for enemy composition and rewards, but could extend to dungeon layout parameters.

## See also

[[Game Index]] · [[Game Studies]] · [[Design Influences]] · [[Combat]] · [[Chart Loop]] · [[Affixes]] · [[Items and Gear]] · [[Hades]] · [[Path of Exile]] · [[Diablo II]]

## Sources

- https://lootriver.com/press/sheet.php?p=loot_river
- https://www.escapistmagazine.com/loot-river-review-in-3-minutes-block-shifting-mechanics-meet-roguelike-action/
- https://80.lv/articles/loot-river-a-game-about-unforgiving-procedural-labyrinths
- https://eip.gg/reviews/loot-river-is-an-innovative-but-flawed-roguelike/
