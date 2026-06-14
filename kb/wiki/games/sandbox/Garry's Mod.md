---
type: game
tags: [game-study, sandbox, ugc, lua, modding, physics, source-engine, community-modes]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Garry%27s_Mod
  - https://gmod.fandom.com/wiki/Garry's_Mod
  - https://www.gamephilosophy.org/wp-content/uploads/confmanuscripts/pcg2017/Nelson%20-%202017%20-%20A%20Game%20Made%20From%20Other%20Games%20Actions%20and%20Entities%20in%20Garrys%20Mod.pdf
  - https://store.steampowered.com/app/4000/Garrys_Mod/
---
# Garry's Mod

A physics sandbox (2006, Facepunch Studios / Valve) built on Valve's Source engine that ships with no objectives, no win state, and no content of its own — everything meaningful is built by the community using Lua scripts and the Steam Workshop.

## Design

Garry's Mod's design philosophy is pure substrate: two tools (a Physics Gun for picking up and rotating objects; a Tool Gun for welding, constraining, and scripting props) plus access to every prop and character model from installed Source games. The game provides no goals. Players decide what to build.

The standout mechanic is the **community game-mode system**. Because the entire game is scriptable in Lua, the player community built entirely new genres on top of the sandbox:

- **Trouble in Terrorist Town (TTT):** A social deduction mode (winner of the 2009 Fretta Contest) in which hidden traitors kill innocents while detectives investigate — an implementation of the social-deception game *Mafia* in 3D shooter form.
- **DarkRP:** A freeform roleplay mode with persistent player jobs, a currency, a property system, and player-run economies. The unofficial "game within a game" that drove millions of hours.
- **Prop Hunt:** Hide-and-seek using props as disguises; mechanics later surfaced in Call of Duty, Fortnite, and Genshin Impact.

Content is distributed via the Steam Workshop (which replaced the older Toybox system). Commercial scripts trade on GmodStore (formerly ScriptFodder) — a gray-market economy for server owners purchasing premium gamemode plugins.

## Implementation

- **Engine:** Valve Source Engine; the game borrows assets from any other Source-engine game the player owns.
- **Scripting:** Lua — full access to entity spawning, physics constraints, UI, networking, and AI hooks. The barrier is low enough that teenagers authored Trouble in Terrorist Town.
- **Sales:** 25.5 million copies by November 2024; recognized by Guinness World Records as the best-selling PC-exclusive game in September 2024. Revenue estimated at $119.8 million by December 2020.
- **Successor:** S&box (Facepunch, released April 2026) transitions the sandbox-with-Lua-modes concept to Source 2 / Unreal Engine 4.
- **No creator monetization infrastructure:** Unlike Roblox, GMod has no first-party creator economy. Server operators pay for premium scripts; Facepunch earns nothing from that market. This led to rampant DMCA disputes over Source assets.

## Why it matters

GMod demonstrated that **the game-mode is the product** — that selling a scripting substrate at low cost can generate an ecosystem of community-built games dwarfing what any single studio could produce. It did this a full decade before Roblox made the model mainstream, without any formal creator payout system. TTT and Prop Hunt prove that small Lua scripts can define entirely new genres. The commercial gap (no native creator economy) is instructive: it eventually ceded the UGC-platform crown to Roblox precisely because it had no flywheel.

## Relevance to Wayfinder

1. **[[Economy]]** — GMod's absence of a creator economy is the cautionary lesson: community modding tools without monetization infrastructure produce vibrant scenes but no sustainable flywheel. Wayfinder chart-sharing should learn from this gap.
2. **[[Multiplayer Co-op]]** — DarkRP's player-run job economy (players pay each other for services) is a reference model for emergent co-op social structures without scripted NPC economies.
3. **[[MMO Social and Endgame]]** — The TTT social-deduction layer shows how simple rule overlays (roles, hidden information) create high-replayability from low-complexity ingredients.

## See also

- [[Game Index]] · [[Game Studies]]
- [[Economy]] · [[Multiplayer Co-op]] · [[MMO Social and Endgame]]
- [[Roblox]] (the UGC-platform archetype that followed) · [[Second Life]] (creator rights model) · [[VRChat]] (social sandbox)
- [[EVE Online]] (player-driven economy)

## Sources

- https://en.wikipedia.org/wiki/Garry%27s_Mod
- https://gmod.fandom.com/wiki/Garry's_Mod
- https://www.gamephilosophy.org/wp-content/uploads/confmanuscripts/pcg2017/Nelson%20-%202017%20-%20A%20Game%20Made%20From%20Other%20Games%20Actions%20and%20Entities%20in%20Garrys%20Mod.pdf
- https://store.steampowered.com/app/4000/Garrys_Mod/
