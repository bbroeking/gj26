---
type: game
tags: [game-study, survival, crafting, horde, tower-defense, voxel, zombie, base-building, co-op]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/7_Days_to_Die
  - https://7daystodie.com/
  - https://www.corrosionhour.com/7-days-to-die-review-survival-horde-crafter/
  - raw/games/survival-3.md
---
# 7 Days to Die

A post-apocalyptic zombie-survival horde-crafter (Early Access 2013; 1.0 release July 2024, The Fun Pimps) that fuses open-world crafting, RPG skill trees, and voxel base-building under the pressure of a repeating 7-day countdown to a Blood Moon horde that destroys everything you've built.

## Design

- **The 7-day cycle as design spine.** Every seventh in-game night is Blood Moon: a relentless, escalating zombie horde attacks the player's current position for the entire night. This creates an inviolable pacing structure — players have exactly seven days to gather, craft, and fortify before the next wave. The horde's power scales with total days survived: the cycle at day 7 is survivable with basic defenses; the cycle at day 700 is a stress test of late-game engineering. The entire game is essentially "prepare for the next horde, survive, repeat."
- **Voxel destruction with structural physics.** Buildings are fully destructible voxel structures, and the game models structural integrity — unsupported blocks collapse under their own weight. Zombie AI targets load-bearing supports, not just walls, meaning players must engineer their bases to be mechanically sound or watch them collapse mid-horde. A cement pillar fort with flat roofs survives differently from a wood-frame house; understanding physics is part of the game's skill floor.
- **Integrated tower defense.** Players craft barbed wire, blade traps, electric turrets, pressure plates, and automated doors. The horde base becomes a puzzle of funnel design and kill-zone engineering — a sub-genre of its own within the survival format.
- **Five-attribute RPG skill tree.** Characters invest in Perception, Strength, Fortitude, Agility, or Intellect, each with subordinate skills (mining, crafting, weapons, medical). The system creates soft build identities: a Strength/Fortitude character is a melee brawler with high carry capacity; an Intellect character crafts faster and builds automated systems. Points come from leveling via in-game actions, not level-ups — skills improve as you use them.
- **World variety.** Players choose between the hand-crafted Navezgane, Arizona map (fixed, with authored locations and narrative markers) or randomly generated worlds seeded across several biome types (forest, desert, snow, wasteland, burned). Both support the same survival loop; Navezgane rewards map knowledge over time.

## Implementation

- **Engine:** Unity (PC and consoles). PC version has been in continuous development since 2013, one of Steam Early Access's longest runs.
- **Co-op:** Player-hosted servers and LAN; no official cap stated but typically 8 players on community servers. No official dedicated server service — community-hosted.
- **Platforms:** Windows, macOS, Linux, PS4/5, Xbox One/Series. Console versions (ported by Abstraction Games) received poor reviews (Metacritic 35–45/100) due to performance issues; the PC version has a substantially stronger reputation and player base.
- **Sales/reception:** Ranked in Steam's top 100 games of 2017 during early access; reached 1.0 after a decade of paid early access.

## Why it matters

7 Days to Die is the clearest demonstration in the genre that a regular external pressure event can replace all other pacing structures. No quest line, no story chapter beats — the seven-day cycle forces urgency through countdown rather than narrative. Its voxel physics system (buildings collapsing mid-combat) creates emergent challenge that scripted games cannot replicate: players lose because they miscalculated structural load, not because a designer placed a hard checkpoint. This makes failure feel instructive rather than unfair.

## Relevance to Wayfinder

- **Cyclical pressure events** — the horde night — are a design pattern Wayfinder could adapt for [[Dungeon Generation]]: a repeating in-world threat (seasonal boss wave, chart expiry, den "reset") that gives each delve a countdown rather than an open-ended optional feel.
- **Crafting as horde preparation** directly parallels Wayfinder's gather→craft→delve loop in [[Crafting]]: the emotional weight of crafting comes from knowing you need what you're making before a specific threat arrives.
- **Skill progression via use** (not arbitrary XP) is worth considering for Wayfinder's Trade leveling (see [[Gathering]]): tying skill gain to the act rather than a number reinforces the skilling-as-spine identity.

## See also

- [[Game Index]] · [[Game Studies]]
- [[Design Influences]] · [[Crafting]] · [[Items and Gear]] · [[Dungeon Generation]] · [[Economy]]
- [[Minecraft]] · [[Valheim]] · [[Rust]] · [[The Forest]]

## Sources

- https://en.wikipedia.org/wiki/7_Days_to_Die
- https://7daystodie.com/
- https://www.corrosionhour.com/7-days-to-die-review-survival-horde-crafter/
- raw/games/survival-3.md
