---
type: game
tags: [game-study, roguelike, emergent-systems, simulation, ascii, permadeath, dungeon-crawler]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/NetHack
  - https://nethackwiki.com/wiki/The_DevTeam_Thinks_of_Everything
  - https://www.nethack.org/
  - https://www.theregister.com/2026/05/05/nethack_5/
---
# NetHack

A free, open-source single-player roguelike first released July 28, 1987 by the NetHack DevTeam (originating with Mike Stephenson, Izchak Miller, and Janet Walz), renowned for its staggering depth of emergent simulation and the community maxim "The DevTeam Thinks of Everything."

## Design

- **Origin:** NetHack is a fork of *Hack* (1984), which itself descended from [[Rogue]]. The name reflects that developers collaborated over the Internet — unusual for 1987.
- **Emergent simulation over authored content:** NetHack's design philosophy centers on interconnected rules rather than scripted scenarios. Hundreds of monsters, items, terrain types, and environmental features interact under consistent physics. Players can dip a sword in a potion to identify it, engrave text with a wand to test its charges, or polymorphed into a monster to bypass locked doors. No single "correct" path exists.
- **TDTTOE ("The DevTeam Thinks of Everything"):** The community acronym for moments when the game has programmed a response to even the most absurd player action. Sacrificing a unicorn horn on an altar, writing your own name in blood — the game responds to these edge cases. This perceived omniscience is a design goal: every interaction should have a meaningful consequence.
- **Dungeon structure:** ~50 procedurally generated levels descending through multiple branches — the main dungeon, Gehennom (a hell-themed lower section), the Gnomish Mines, Sokoban, and class-specific quest branches. The objective: retrieve the Amulet of Yendor from the deepest level and ascend through the Astral Plane.
- **Ascension kit:** High-level play revolves around constructing an "ascension kit" — a curated set of items (reflection, magic resistance, cancellation, levitation, a unicorn horn for stat restoration) assembled across the run. This is the closest NetHack gets to a meta-build system.
- **Permadeath:** True permadeath. Wizmode aside, dead characters stay dead. Years of play can end in a single bad turn.
- **Food clock:** Nutrition depletes each turn (starting at 900 points; a food ration restores ~800). This pressures exploration pace and limits loitering — the same function as Spelunky's ghost, handled through resource rather than spawn.

## Implementation

- **Language:** C, compiled for dozens of platforms (Windows, Linux, macOS, BSD, Solaris). The codebase has been continuously extended since 1987.
- **Display:** ncurses for terminal ASCII; tile frontends available (Tiles mode, SDL frontends). Multiple third-party interfaces exist.
- **Procgen:** Level generation is procedural but not heavily seeded in the public API — each game differs. Some branch layouts (Sokoban, Minetown) use authored templates with random variation; the main dungeon uses room-and-corridor generation descended from Rogue's approach.
- **Open license:** The NetHack General Public License permits forks, spawning *Slash'EM*, *UnNetHack*, *dNethack*, and many variants. NetHack 5.0.0 was released May 2026, its first major version since 3.6.x.
- **Spoiler culture:** The community has exhaustively documented every secret. The wiki and spoilers are quasi-official: without them, first ascension is nearly impossible for most players. The game rewards knowledge accumulation across runs, not just skill.

## Why it matters

NetHack demonstrates that *consistent rule systems generate better content than authored content at scale.* Its ~37 years of development never added a "story" — it deepened the simulation. The lesson: if your rules are consistent and granular, players will synthesize emergent stories from them. TDTTOE is a design aspiration: the world should respond plausibly to any player action, not just anticipated ones.

## Relevance to Wayfinder

- **[[Affixes]]:** NetHack's item identification mechanic — unknown potions/scrolls/rings whose effects are shuffled per run — is the direct ancestor of affix-style mystery. Wayfinder's dungeon affixes create a similar "what does this do?" discovery arc each chart run.
- **[[Dungeon Generation]]:** NetHack's branching dungeon with authored setpieces (Sokoban, Minetown) inside procedural floors is a model for mixing hand-designed landmark rooms with generated connective tissue — worth studying for Wayfinder's crypt/biome rooms.
- **[[Balance Philosophy]]:** TDTTOE as a design principle applies to Wayfinder's combat and gather interactions: every reasonable player action (combine two affix types, use a gather tool on an enemy, etc.) should yield a consistent, predictable result even in novel combinations.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[Rogue]] — parent; [[Spelunky]] — spiritual descendant
- [[Dungeon Generation]] · [[Affixes]] · [[Balance Philosophy]]
- [[MMO Progression Systems]] · [[MMO Lessons for Wayfinder]]

## Sources

- https://en.wikipedia.org/wiki/NetHack
- https://nethackwiki.com/wiki/The_DevTeam_Thinks_of_Everything
- https://www.nethack.org/
- https://www.theregister.com/2026/05/05/nethack_5/
