---
type: game
tags: [game-study, strategy, tactics, rpg, mech, economy, procedural, mercenary]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/BattleTech_(video_game)
  - https://www.sarna.net/wiki/BattleTech_(Video_Game)
  - https://store.steampowered.com/app/637090/BATTLETECH/
  - https://www.paradoxinteractive.com/games/battletech/about
---
# Battletech 2018

Turn-based tactics / mercenary RPG (2018, Harebrained Schemes / Paradox Interactive), translating the classic tabletop wargame into a digital campaign where players manage a financially precarious mercenary company — balancing mech repair costs, pilot morale, and contract risk — between squad-level turn-based tactical battles.

## Design

- **Lance tactics** — players control up to four mechs per battle on a hex-like terrain grid; turn order is determined by unit initiative (speed and size), creating a queue system. The standout mechanic is **called shots**: when a mech is knocked down (from leg destruction or knockback), the player can target a specific location — a high-risk, high-reward attack that can core out a mech's center torso in one volley.
- **Heat management** — all weapons generate heat; exceeding the heat cap triggers shutdown, ammunition explosion, or pilot injury. Heat management is BattleTech's primary tactical constraint, making "alpha strike" (fire everything at once) a calculated gamble rather than a default play.
- **Mech customization** — chassis, weapons, armor tonnage, actuators, and gyros are individually adjustable; a heavy chassis with the wrong weapon loadout will underperform a well-optimized medium. Loadout decisions happen in the Mech Bay between missions, turning the downtime into a design puzzle.
- **Mercenary economy** — the campaign begins with the player heavily in debt; each mission pays C-Bills but also incurs repair and refit costs. Choosing contracts involves risk assessment: a high-difficulty skull-rating contract pays more but risks mech loss and pilot injury that outweighs the reward. Cash flow management is as important as tactical execution.
- **Pilot injuries and morale** — pilots accumulate injuries across missions; repeated injury risks permanent stat loss or death. Morale (raised by victories, lowered by defeats or harsh command choices) buffs evasion and provides a "Vigilance" defensive action. The systems humanize the lance beyond unit abstractions.
- **Procedural contract system** — after the story campaign, the sandbox generates contracts across star systems with varying difficulty and pay, creating a supply-and-demand economy of risk vs reward that keeps the post-story loop alive.

## Implementation

- **Unity** (C#); developed by Harebrained Schemes under Jordan Weisman (original BattleTech tabletop creator). Unity was chosen for cross-platform support (Windows/macOS/Linux) and the team's familiarity.
- Funded via Kickstarter in 2015 ($1.85M raised; stretch goal unlocked procedural campaign layer).
- Tabletop damage values were multiplied by 5 for digital translation — a deliberate balance pass that makes single-weapon hits feel impactful without requiring tabletop's granular location table.
- Metacritic: 80/100 (Windows). Three paid expansions (Flashpoint, Urban Warfare, Heavy Metal) each added new mission types, biomes, and mechs.

## Why it matters

- Battletech 2018 is the best modern example of **economic risk as a game system in its own right**: the merc-company cash flow layer means a player can win every tactical engagement and still lose the campaign through poor financial management. Two genre layers (tactics + management) that legitimately co-equal each other.
- The called-shot mechanic (only available when target is knocked down) elegantly gate-keeps the game's most powerful ability behind a tactical prerequisite, making the prerequisite feel rewarding before the payoff lands.
- Heat management as the central constraint is a design lesson in **resource that is both a weapon and a liability** — pushing heat opens more damage potential but risks catastrophic failure, producing genuinely tense decision trees.

## Relevance to Wayfinder

- **[[Economy]]** — the mercenary cash-flow model (mission income minus repair costs = net gain) is a direct template for Wayfinder's dungeon economics: chart inscription costs + consumable costs should be visible and meaningful, so a "profitable delve" requires more than just survival.
- **[[Combat]]** — called shots (contextual high-reward action unlocked by enemy state) is a transferable combat design pattern for Wayfinder: a boss entering a staggered phase could unlock a special attack window, rewarding players who pushed through the opener.
- **[[Balance Philosophy]]** — heat-as-double-edged-resource (more firepower = more risk of self-harm) maps to Wayfinder's affix trade-off design: strong positive affixes should carry a commensurate downside that can be mitigated but never fully eliminated.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[XCOM 2]] · [[Into the Breach]] · [[Warcraft III]]
- [[Economy]] · [[Combat]] · [[Balance Philosophy]]

## Sources

- https://en.wikipedia.org/wiki/BattleTech_(video_game)
- https://www.sarna.net/wiki/BattleTech_(Video_Game)
- https://store.steampowered.com/app/637090/BATTLETECH/
