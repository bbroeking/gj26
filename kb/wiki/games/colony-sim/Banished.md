---
type: game
tags: [game-study, colony-sim, survival, resource-management, population-dynamics, no-tech-tree, solo-dev]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Banished_(video_game)
  - https://www.gamedeveloper.com/business/-i-banished-i-s-build-what-you-want-when-you-want-it-game-design
  - http://www.playthepast.org/?p=5695
---
# Banished

Village-survival colony sim (2014, Shining Rock Software / Luke Hodorowicz) — a solo-developed medieval settlement builder where population itself is the primary resource, constrained by food, shelter, and seasonal cycles rather than any tech tree.

## Design

- **Population as the scarce resource.** Food, firewood, tools, and clothing are means to an end; the end is keeping the population alive and growing. Every death is permanent and every birth is a years-long investment — the colonists must survive childhood, learn a profession, produce into middle age, and retire into dependency. A village of 30 that loses six adults in a bad winter may never recover because the age pyramid collapses.
- **No tech tree — resource availability as gating.** Hodorowicz's explicit design choice: "The only requirements are the resources to build it." Players can place any building from the start if they have the materials. This removes arbitrary progression locks and shifts the constraint to logistics: a tailor requires leather, a blacksmith requires iron, both require workers who need food and shelter. Organic sequencing emerges from scarcity rather than from level gates.
- **Seasonal pressure without scripted crises.** Crops fail in winter; rivers freeze; food stores must be accumulated before first frost. The game generates crisis through calendar mechanics rather than scripted disaster events — the threat is always there, always predictable, and always survivable with good planning. This low-drama, high-stakes structure suits extended play without desensitizing the player.
- **Standout mechanic — the age pyramid trap.** Early-game expansion tempts players to settle large founding populations simultaneously. If all founders age together, they retire together, creating a dependency wave: a sudden crop of elderly citizens who stop producing just as their children are still too young to work. The trap is invisible until it is almost too late, encoding demographic planning as a core skill.
- **Open-ended creative sandbox.** Players may maintain a tiny self-sufficient hamlet or sprawl a logging economy across a map; neither is gated. The only feedback loop is survival — the game ends when all colonists die, not when a condition is met.

## Implementation

- Built in a custom C++ engine by a single developer over several years; DirectX 11; no engine middleware beyond a physics library.
- Citizen simulation runs per-agent: each colonist has a home, a job assignment, a spouse, and an inventory slot for the tool type their profession requires. Job pathfinding is first-available rather than optimised, causing real labour inefficiencies that players must manage by building layout.
- Sold over one million copies in its first year, remarkable for a $20 solo-dev title with no marketing budget. A substantial modding community extended the content surface for years.

## Why it matters

Banished proved that **resource availability is a more elegant progression gate than tech trees**. Its demographic trap — the age pyramid — is one of the genre's most memorable emergent mechanics, arising entirely from a simple aging simulation rather than scripted events. The solo-dev achievement also demonstrated that city-builder complexity does not require large teams, only careful constraint design.

## Relevance to Wayfinder

- The **no-tech-tree philosophy** echoes Wayfinder's [[Gathering]] and [[Crafting]] design intent: unlock access through resource ownership, not arbitrary level gating. Players who farm the right materials should be able to craft advanced items earlier, creating meaningful decision points.
- The **population-as-resource framing** maps to [[Economy]]: in Wayfinder, active players (party size, NPC allies) are a finite resource whose loss has downstream consequences — losing a companion in a crypt run should feel like losing a Banished carpenter, not respawning at a checkpoint.
- The **seasonal inevitability** pattern (known threat, predictable timing) is a [[Balance Philosophy]] target: Wayfinder's dungeon pacing could use seasonal-style threat escalation — each floor darker and colder — rather than random spike events.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[RimWorld]] · [[Dwarf Fortress]] · [[Frostpunk]]
- Wayfinder: [[Crafting]] · [[Gathering]] · [[Economy]] · [[Balance Philosophy]]

## Sources

- https://en.wikipedia.org/wiki/Banished_(video_game)
- https://www.gamedeveloper.com/business/-i-banished-i-s-build-what-you-want-when-you-want-it-game-design
- http://www.playthepast.org/?p=5695
- https://tvtropes.org/pmwiki/pmwiki.php/VideoGame/Banished2014
