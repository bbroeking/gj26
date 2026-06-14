---
type: game
tags: [game-study, roguelite, platformer, procedural-generation, permadeath, physics, co-op, branching-paths]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Spelunky_2
  - https://game-wisdom.com/analysis/spelunky-2
  - https://spelunky.fandom.com/wiki/Cosmic_Ocean_(2)
  - https://mossranking.com/cat_coop.php?cat=720
---
# Spelunky 2

A 2020 platform roguelite sequel by Mossmouth and BlitWorks that expands Spelunky's physics-simulation dungeon formula with branching biome paths, liquid physics, four-player online co-op, and a 99-level true-ending gauntlet called the Cosmic Ocean.

## Design

- **Branch paths add replayability variance:** After the opening Dwelling biome, players choose between forking routes — e.g. Volcana (lava-themed, shortcuts via drill) vs. Tide Pool (water/mounts, alternate boss). The branch choice shapes the entire run, creating meaningful macro decisions absent from Spelunky 1's linear biome chain.
- **Backlayer secrets:** Every level contains a hidden "backlayer" parallel space accessible through bombs or specific exits, holding shortcuts, narrative content, and alternate paths to endgame bosses (Olmec → Hundun → true ending). Skilled players must manage two spatial layers per level.
- **Mounts:** Tamed rideable creatures (turkey, rock dog, axolotl) grant a free extra jump and absorb one hit — a persistent survivability tool within the run that rewards enemy-charming over blind killing.
- **Liquid physics:** A new simulation system allows water, lava, and acid to flow naturally, creating emergent interactions (lava cools to stone, water carries items, acid destroys terrain). This deepens the "shared ruleset" design philosophy: fluid obeys the same physics as everything else.
- **Cosmic Ocean — the true endgame:** A post-credits 94-level gauntlet (floors 7-1 through 7-99) with a unique per-level objective: destroy three floating orbs to move a blocking Celestial Jelly from the exit. Beating 7-99 creates a Constellation — a persistent record of every character the player used. This is an extreme mastery target available only to players who unlock all three endings in sequence.
- **Difficulty shift vs Spelunky 1:** Spelunky 2 is harder from the first floor; lava appears in the second biome (Volcana) rather than near the end; item/bomb/rope economy is tighter. Critics noted fewer than 10% of Steam players reach the credits. The game targets a narrower audience than contemporaries like Hades or Dead Cells that scaffold difficulty for newcomers.
- **Co-op:** Four-player online and local co-op added. Players can revive each other by carrying ghost jars — the game remains fully deadly for all participants, making co-op chaotic rather than safety-net.

## Implementation

- **Developer:** Mossmouth (Derek Yu, lead design) with BlitWorks handling programming — the same split used for the Spelunky HD console port.
- **Engine:** Custom C++ codebase descended from Spelunky HD; no commercial engine.
- **Procgen approach:** Retains Spelunky's 4×4 grid of room templates with a guaranteed solution path carved from entry to exit. Spelunky 2 expands the template library per biome and introduces branching at the world map level (not the level level), so the procgen governs room layout within each biome while the player navigates a hand-structured world tree.
- **Platforms:** PS4 (Sep 2020), PC (Sep 2020), Switch (Aug 2021). Metacritic scores: PC 91, Switch 92.

## Why it matters

Spelunky 2 proves that the Spelunky formula scales to expanded scope (more biomes, more endings, more players) without losing the "shared ruleset" consistency that makes its physics feel fair. The branching world map is a clean lesson in adding run variance at the macro level rather than within individual level generation. Its extreme difficulty ceiling (Cosmic Ocean) demonstrates how a single skill-gated endgame can sustain a hardcore community for years post-launch.

## Relevance to Wayfinder

- **Branching dungeon paths → [[Chart Loop]] / [[Dungeon Generation]]:** Wayfinder's chart affix system could use branch structure to give players route decisions (e.g., long path with more loot vs. short path to the boss) within a single den, mirroring Spelunky 2's Volcana/Tide Pool fork.
- **Backlayer as hidden depth → [[Dungeon Generation]]:** Secret parallel spaces reward players who master resource management (bombs/ropes = Wayfinder's ink/supplies), creating layered content without bloating the main path.
- **Extreme mastery target → [[Chart Loop]]:** The Cosmic Ocean's 99-floor unlock condition is a model for Wayfinder's Summit endgame — a trophy-chain gate that keeps completionists engaged long past the credits.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[Dungeon Generation]] · [[Chart Loop]] · [[Affixes]]
- [[Spelunky]] (original — shares procgen approach) · [[The Binding of Isaac Rebirth]] · [[Dead Cells]]

## Sources

- https://en.wikipedia.org/wiki/Spelunky_2
- https://game-wisdom.com/analysis/spelunky-2
- https://spelunky.fandom.com/wiki/Cosmic_Ocean_(2)
- https://mossranking.com/cat_coop.php?cat=720
