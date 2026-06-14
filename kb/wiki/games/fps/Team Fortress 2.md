---
type: game
tags: [game-study, fps, class-based, live-service, cosmetics, economy, free-to-play, valve, source-engine]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Team_Fortress_2
  - https://wiki.teamfortress.com/wiki/Lag_compensation
  - https://developer.valvesoftware.com/wiki/Team_Fortress_2_engine_branch
  - https://gamerant.com/team-fortress-2-source-code-full-client-released/
  - https://www.pcgamer.com/games/fps/valve-releases-team-fortress-2-sdk-enabling-creators-to-build-completely-new-games-based-on-tf2/
---
# Team Fortress 2

Class-based multiplayer FPS released October 10, 2007 by Valve that pioneered the cosmetic live-service model, the nine-class team design template, and a player-driven hat economy that — within four years of going free-to-play — had generated more revenue than the game's initial paid launch.

## Design

**Nine-class system.** Three categories (Offense, Defense, Support) of three classes each (Scout/Soldier/Pyro, Demoman/Heavy/Engineer, Medic/Sniper/Spy). Each class has a distinct movement speed, health pool, and role identity that is instantly readable from silhouette. The design goal — "pub players with no coordination can still contribute by playing their role" — was achieved by making each class's contribution self-contained.

**Objective modes.** Capture the flag, control points, payload (push a cart), attack/defend, and King of the Hill. Modes are tightly coupled to class strengths: Medic enables sustained pushes; Engineer locks down chokepoints; Spy disrupts Sentry nests. Map design and mode design co-evolved with class archetypes.

**Cosmetics and hats.** The 2009 "WAR! Update" introduced cosmetic hats — no gameplay value, purely aesthetic. The community response was outsized. By 2011 Valve reported that cosmetics revenue after going free-to-play was 12x higher than paid-game revenue. Rare hats traded on the Steam Community Market for thousands of dollars, creating an emergent player economy Valve had not planned.

**Update cadence as content.** From 2007–2016 Valve shipped themed "content updates" (the Meet Your Match, Jungle Inferno, etc.) that added maps, game modes, weapons, and cosmetics simultaneously. This event-driven update rhythm kept a live community without a battle pass — a model later formalized by Fortnite and most live-service games.

## Implementation

**Engine — Source.** TF2 runs on a modified Source engine. Server tick rate defaults to 66 Hz (configurable up to 100 Hz). The engine's lag compensation system stores 1 second of player position history; on a shot, the server rewinds opponent positions to the attacker's view time and resolves hit detection. This produces the notorious "I shot through a wall" perception: at high ping, rewind can place a player's hitbox at a past position that is geometrically different from their rendered position.

**Netcode trade-offs.** Source's lag compensation architecture favors attackers: high-latency players effectively "reach into the past" when shooting. Community servers often enforce ping limits or reduce history length to cap this advantage. The system was designed for the latency distribution of 2007 broadband; modern high-ping exploits were not anticipated.

**Source code release (February 2025).** Valve released the full TF2 client and server source code under a license permitting free community mods distributed via Steam Workshop. This extends TF2's modding ecosystem and allowed the community to build TF2-derived games — the culmination of a 28-year lineage from the original QuakeC Team Fortress mod.

**Bot crisis (2020–2024).** Automated aimbots and vote-kick bots infested official servers for four years, nearly rendering casual play unplayable. The #SaveTF2 community movement and a Change.org petition with 250,000+ signatures eventually prompted Valve ban waves in 2023–2024. The episode is a documented case study in what happens when anti-cheat investment lags a free-to-play title's age.

**Distribution.** Launched in 2007 at $9.99 as part of The Orange Box bundle; went free-to-play in June 2011. Revenue thereafter is entirely cosmetic: Mann Co. Supply Crates (loot boxes with keys sold for ~$2.49 each), Steam Community Market, and direct store purchases.

## Why it matters

TF2 invented the cosmetics-only live-service economy. The nine-class silhouette design became the template for Overwatch's hero roster design. The hat economy showed that player-to-player trading at scale could dwarf developer-to-player sales. The source code release in 2025 is a landmark for community preservation and modding rights. The bot crisis is the clearest case study in the long-term cost of neglecting anti-cheat for a free-to-play FPS.

## Relevance to Wayfinder

- **[[Multiplayer Co-op]] — legible class roles.** TF2's instant-silhouette-readable classes let players coordinate without communication. Wayfinder's four [[Trades]] (Wayfinding, Earthcraft, Wildcraft, and combat) have the same potential: distinct gathering, crafting, and combat roles that pub groups self-organize around without being forced into composition requirements.
- **[[Economy]] — cosmetics as sustainable revenue.** TF2 proved cosmetic revenue can multiply paid-game revenue 12x. Relevant if Wayfinder ever ships commercially: chart cosmetics (ink color, scroll art), cosmetic gathering tools, and housing decorations are a proven live-service spine.
- **[[Combat]] — Source lag compensation limits.** TF2's high-ping backstab problem documents exactly what happens when lag compensation is not carefully capped. A cautionary reference for Wayfinder's [[MMO Netcode and Tick Systems]] design.

## See also

- [[Game Index]] · [[Game Studies]]
- [[Design Influences]] · [[MMO Netcode and Tick Systems]] · [[Multiplayer Co-op]] · [[Combat]] · [[Economy]]
- [[Quake]] · [[Counter-Strike Global Offensive]] · [[Valorant]]

## Sources

- https://en.wikipedia.org/wiki/Team_Fortress_2
- https://wiki.teamfortress.com/wiki/Lag_compensation
- https://developer.valvesoftware.com/wiki/Team_Fortress_2_engine_branch
- https://gamerant.com/team-fortress-2-source-code-full-client-released/
- https://www.pcgamer.com/games/fps/valve-releases-team-fortress-2-sdk-enabling-creators-to-build-completely-new-games-based-on-tf2/
