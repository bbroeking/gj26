---
type: game
tags: [game-study, rpg, obsidian, infinity-engine-spiritual-successor, skill-gating, companion-design, crafting, dual-resource, kickstarter]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Pillars_of_Eternity
  - https://pillarsofeternity.fandom.com/wiki/Skills
  - https://pillarsofeternity.fandom.com/wiki/Attributes
  - https://www.gamepressure.com/pillarsofeternity/skills/zb7479
  - https://steamcommunity.com/app/291650/discussions/0/2957166487932199959/
  - https://gamefaqs.gamespot.com/ps4/211832-pillars-of-eternity-complete-edition/faqs/79897/character-creation
---
# Pillars of Eternity

Isometric role-playing game (2015, Obsidian Entertainment / Paradox Interactive) — a Unity-engine spiritual successor to Baldur's Gate and Planescape Torment, set in a hand-crafted world threatened by a crisis of souls, that demonstrated Kickstarter's viability for premium RPGs and refined the real-time-with-pause tactical formula with a clean dual-resource system and deeply gated skill checks.

## Design

- **Five skills as content keys.** Skills (Stealth, Athletics, Lore, Mechanics, Survival) operate entirely outside combat — they are the Watcher's toolkit for engaging with the non-combat world. Mechanics unlocks hidden doors, traps, and containers; Lore gates high-level scroll use and dialogue wisdom checks; Athletics governs endurance during scripted events; Stealth enables scouting; Survival extends food and potion duration. Crucially, only the Watcher's skills (not companions') count in dialogue checks — the player must invest personally to unlock the best narrative branches. Party-level optimization (one companion with Mechanics handles traps; the Watcher maxes Lore for dialogue) encourages specialization without redundancy.
- **Dual resource: Endurance and Health.** Combat depletes Endurance (fast, recovers between fights) and slowly drains Health (permanent per-rest). Dying in combat costs Endurance; running out of Health causes permanent incapacitation until resting. This forces players to think in campaigns rather than individual fights — resources spent across three rooms matter, not just one boss. The system was widely praised for adding strategic tension without frustrating permadeath.
- **Eleven classes and specialization.** Fighter, Paladin, Priest, Chanter, Rogue, Ranger, Cipher, Druid, Wizard, Monk, Barbarian each have distinct ability trees and at least two per-rest vs. per-encounter ability tracks. All attributes are universally useful (Might governs damage and healing, not just melee damage; Resolve affects concentration and deflection for any class), reducing dump-stat trap design.
- **Reputation and reactivity.** The Watcher earns reputation scores with major factions and towns (Honest, Clever, Benevolent, Cruel, etc.) that accumulate via dialogue choices. NPCs react based on faction standing, some quests lock behind threshold reputations, and the ending epilogues reflect how each region was shaped by the player's conduct. The system tracks character disposition rather than alignment, producing nuanced reactive storytelling.

## Implementation

- **Unity engine** with 3D characters rendered over 2D pre-rendered isometric backgrounds (continuing the Infinity Engine aesthetic without the Infinity Engine). Fog-of-war and real-time lighting on pre-rendered assets was a technical challenge Obsidian documented post-launch.
- **Kickstarter-funded** (nearly $4 million from 75,000 backers in 2012) and released 2015; sold 700,000 units by February 2016. 89/100 Metacritic. Sequel Deadfire (2018) and spiritual successor Avowed (2025, first-person in the same world) followed. The project proved that a traditional cRPG without a AAA publisher could find a commercially viable audience.
- Crafting in Pillars requires only character level and gathered ingredients — no separate crafting skill gate. This keeps gathering/crafting accessible without a separate leveling track, though it also means crafting carries less identity weight than its ingredients.

## Why it matters

Pillars of Eternity shows that **skill-as-content-key** design (skills open world layers rather than improve combat stats) produces meaningful character differentiation without number inflation. The dual-resource system is a clean, learnable solution to the "nova problem" (characters blowing all resources on one fight): by separating fast/combat resources from slow/campaign resources, players must think across a dungeon wing rather than fight-by-fight. The reputation/disposition system is more granular than a morality meter and more portable to smaller-scope games — tracking a handful of trait axes (Benevolent, Cruel, Honest) is simpler to implement than full DA:O approval.

## Relevance to Wayfinder

- **[[Skills]]:** Pillars' party-specialization model — one character owns Mechanics, one owns Stealth — maps directly onto Wayfinder's co-op design. Each Trade could grant passive social/world-interaction skills (Earthcraft unlocks ore-reading dialogue; Wildcraft unlocks herbalist checks) encouraging parties where different Trades open different world layers.
- **[[Items and Gear]]:** Pillars' ingredient-plus-level crafting — no separate crafting Trade needed — is a useful contrast to Wayfinder's gather-to-craft spine. Wayfinder's differentiation is that crafting IS a Trade expression, not a background utility; Pillars shows what the flatter version looks like and why it might feel lower-stakes.
- **[[Balance Philosophy]]:** The universal-attribute design (Might powers healing AND damage; Resolve helps all classes) eliminates dump stats and makes every stat point feel meaningful regardless of class — a principle worth borrowing for Wayfinder's affix and gear design.

## See also

- [[Game Index]] · [[Game Studies]]
- [[Design Influences]] · [[MMO Progression Systems]]
- Wayfinder: [[Skills]] · [[Items and Gear]] · [[Balance Philosophy]] · [[Trades and Leveling]] · [[Combat]]
- Siblings: [[Baldurs Gate 3]] · [[Pathfinder Wrath of the Righteous]] · [[Planescape Torment]] · [[Dragon Age Origins]] · [[Disco Elysium]]

## Sources

- https://en.wikipedia.org/wiki/Pillars_of_Eternity
- https://pillarsofeternity.fandom.com/wiki/Skills
- https://pillarsofeternity.fandom.com/wiki/Attributes
- https://www.gamepressure.com/pillarsofeternity/skills/zb7479
- https://steamcommunity.com/app/291650/discussions/0/2957166487932199959/
- https://gamefaqs.gamespot.com/ps4/211832-pillars-of-eternity-complete-edition/faqs/79897/character-creation
