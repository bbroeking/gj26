---
type: game
tags: [game-study, arpg, crafting, time-travel, mastery, endgame, cycles, co-op]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Last_Epoch
  - https://www.pcgamesn.com/last-epoch/review
  - https://lastepoch.fandom.com/wiki/Crafting
  - https://maxroll.gg/last-epoch/resources/beginner-crafting-guide
  - https://www.icy-veins.com/last-epoch/crafting-guide
  - https://outof.games/news/7107-last-epoch-10-review-time-travelling-arpg-that-doesnt-end/
---
# Last Epoch

Time-travel themed loot-based action-RPG developed by Eleventh Hour Games (Kickstarted 2018, Early Access 2019, full release February 21 2024) distinguished by the most player-controlled crafting system in the genre and a permanent Monolith of Fate endgame loop.

## Design

**Class and mastery system.** Five base classes — Acolyte, Mage, Primalist, Rogue, Sentinel — each branch into three masteries early in the campaign (e.g., Primalist → Druid, Shaman, or Beastmaster). Mastery choice is permanent (no respec), but skill point allocation is respecable. Each mastery has a signature skill and a skill tree with node-based passive modifications, creating roughly 15 distinct archetypes. Skill trees allow transforming the same base skill dramatically: a single fireball skill can be specced into a bouncing projectile, an AoE DoT field, or a channeled beam.

**Crafting with Forging Potential.** The standout system. Every item has a Forging Potential (FP) stat — variable per drop, depleted by crafting. Players select which affix shard to add or upgrade (deterministic choice of target), but the FP cost is randomized within a range, and a Critical Success can trigger (free craft + random bonus tier upgrade). Glyphs modify the process: Glyph of Hope grants a 25% chance to cost zero FP; Glyph of Despair seals a junk affix into a locked slot. Runes perform major operations — Rune of Removal strips an affix and returns its tiers as shards; Rune of Ascendance converts a normal/magic/rare item into a unique of the same type. Shards are farmable from drops and via targeted activities, so players can actively work toward specific upgrade paths. The system sits deliberately between Diablo IV's simple enchanting and Path of Exile's near-unlimited (and overwhelming) crafting depth.

**Monolith of Fate endgame.** A web of timeline nodes (Echoes) each with modifiers that accumulate across encounters. Players navigate toward story boss encounters and optional corruption-scaling systems. Three endgame dungeons offer unique mechanics: Temporal Sanctum uses the time-travel mechanic directly (players toggle between two time periods to bypass obstacles or combo mechanics on the boss).

**Cycle (seasonal) system.** Seasonal Cycles reset characters and the economy, delivering new mechanics and story content. Cycle characters compete in fresh economies; Legacy characters (non-Cycle) persist permanently.

**Co-op.** Up to four players; multiplayer launched in beta March 2023, fully supported at 1.0 release.

## Implementation

Unity engine. Kickstarter 2018 raised $250K+; Steam Early Access April 2019; full launch February 21 2024. Sold 2.135M copies by late March 2024; 264,708 peak concurrent Steam users on launch day. Metacritic score approximately 82/100 (PC). macOS and Linux support cancelled post-launch (Apple ARM transition, Linux September 2024).

## Why it matters

Last Epoch cracked a long-standing ARPG design problem: how to give players meaningful crafting agency without either (a) making the system trivially simple or (b) requiring spreadsheets to navigate. Forging Potential + targeted shard application achieves "I'm building toward a specific item" without guaranteed outcomes. The mastery system's permanent-but-early specialization avoids the paralysis of always-open respecs while keeping the decision meaningful. The Temporal Sanctum is the ARPG genre's best use of a narrative mechanic (time travel) as an active gameplay system.

## Relevance to Wayfinder

- **[[Items and Gear]] crafting model.** Forging Potential's deterministic target + probabilistic cost is a strong reference for Wayfinder's [[Items and Gear]] crafting: players choose what they want to add (agency), but resource expenditure varies (tension). Shards as farmable targeted currency maps to how Wayfinder's reagents could gate specific upgrades.
- **[[Chart Loop]] and endgame progression.** Monolith of Fate's web-of-Echoes with accumulating modifiers is structurally similar to how Wayfinder's [[Chart Loop]] could scale: each chart run modifies the state of the next, building toward a boss encounter with compounding affix stacks.
- **[[Affixes]] and seasonal resets.** Cycle's fresh economy resets are directly relevant to Wayfinder's [[Affixes]] economy — periodic resets maintain meaningful scarcity and prevent early-adopter lock-in of the trading floor.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]] · [[MMO Economy and Itemization]]
- [[Items and Gear]] · [[Affixes]] · [[Chart Loop]] · [[Skills]]
- [[Diablo II]] · [[Path of Exile]] · [[Path of Exile 2]] · [[Grim Dawn]]

## Sources

- https://en.wikipedia.org/wiki/Last_Epoch
- https://www.pcgamesn.com/last-epoch/review
- https://lastepoch.fandom.com/wiki/Crafting
- https://maxroll.gg/last-epoch/resources/beginner-crafting-guide
- https://www.icy-veins.com/last-epoch/crafting-guide
- https://outof.games/news/7107-last-epoch-10-review-time-travelling-arpg-that-doesnt-end/
