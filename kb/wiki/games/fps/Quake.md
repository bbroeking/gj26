---
type: game
tags: [game-study, fps, netcode, client-prediction, modding, quakec, esports, id-software]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Quake_(video_game)
  - https://en.wikipedia.org/wiki/Quake_engine
  - https://fabiensanglard.net/quakeSource/johnc-log.aug.htm
  - https://nition.momentstudio.co.nz/2020/01/the-origin-of-client-side-prediction/
  - https://en.wikipedia.org/wiki/Client-side_prediction
  - https://news.ycombinator.com/item?id=19915698
---
# Quake

First-person shooter released June 1996 by id Software that introduced true real-time 3D rendering, QuakeC modding, and — via the QuakeWorld update — the client-side prediction model that all online shooters still use.

## Design

**Core loop.** Navigate fully 3D Gothic/industrial arenas, destroy enemies with eight weapons, reach the exit. Unlike Doom's Mars aesthetic, Quake commits to a dark Lovecraftian horror tone with consistent architecture.

**Movement as skill.** Bunnyhopping, strafe-jumping, and rocket-jumping — all unintended physics emergences — were preserved because they rewarded mastery. Rocket-jumping in particular created a second economy of health cost for mobility gain that is still mined by hero shooters.

**Arena design.** Levels emphasize vertical space, interconnected corridors, and power-up timing (quad damage, pentagram). Competitive play calculates control cycles around these items — the first systematic "map control" meta in FPS history.

**Esports origin.** The 1997 Red Annihilation tournament — won by Dennis "Thresh" Fong — is widely credited as the first major esports event. Quake's tight mechanical skill ceiling made it the natural first benchmark for competitive FPS.

## Implementation

**Engine — id Tech 2.** Full real-time 3D rendering via software rasterizer, with early OpenGL hardware acceleration support added post-launch. BSP with pre-computed Potentially Visible Sets (PVS) handled culling. Lightmaps baked at level compile time gave rich atmospheric lighting at near-zero runtime cost.

**QuakeC.** Carmack shipped a purpose-built scripting language for game logic. Third parties could replace or extend nearly every behavior without touching the engine. This produced Team Fortress (1996), Capture the Flag, Threewave CTF, and dozens of other game types — an ecosystem richer than any licensed middleware of the era.

**Original netcode — client/server, 20 Hz.** The base Quake shipped with a client/server model at roughly 20 Hz server tick rate. Under dial-up latency (150–300+ ms), every player action felt delayed by multiple frames.

**QuakeWorld (December 1996) — the netcode revolution.** Carmack rewrote the network layer after launch, identifying that 99% of internet players had 300+ ms modem connections. Key changes:
- **Client-side movement prediction.** The client simulates the local player's movement immediately on input rather than waiting for a server round-trip. The server remains authoritative and sends corrections, which the client reconciles. At 200+ ms latency, this made local movement feel like single-player.
- **Per-packet simulation.** Instead of batching all inputs per 20 Hz frame, the server processes each arriving input packet immediately and replies — reducing server response time from >50 ms to <4 ms.
- **Unreliable UDP foundation.** The original code used a reliable stream with an unreliable sideband bolted on. QuakeWorld inverted this: unreliable UDP is primary, with reliability only where required, making latency trade-offs explicit.
- **Prediction scope limit.** Carmack deliberately capped client simulation to the local player's movement only — not projectiles or other players — to avoid compounding prediction errors that would require guessing opponent inputs.

## Why it matters

QuakeWorld's client-side prediction is the single most influential piece of FPS netcode ever written. Every subsequent online shooter — Half-Life, Counter-Strike, Valorant, Overwatch — inherits its core pattern: predict locally, send inputs, reconcile on authoritative server update. The QuakeC modding pipeline directly spawned Team Fortress, which became TFC, which became TF2 — a 28-year lineage from a single scripting decision.

## Relevance to Wayfinder

- **[[MMO Netcode and Tick Systems]].** QuakeWorld's per-packet server loop and client prediction are the template Wayfinder's [[Multiplayer Co-op]] netcode should study when choosing between fixed-tick and input-driven server architectures for a small-session dungeon crawler.
- **[[Combat]] feel.** Quake's emergent movement skill economy (rocket jumping at health cost) shows how purely physics-driven systems can generate deep gameplay without authored verbs. Relevant to Wayfinder's one-verb combat goal — the depth comes from positioning and resource cost, not a large moveset.
- **Mod-as-game-type.** QuakeC let community mods become canonical genres. Wayfinder's [[Charts]] system has similar potential: parameterized dungeon templates are user-configurable runs, not just difficulty sliders.

## See also

- [[Game Index]] · [[Game Studies]]
- [[Design Influences]] · [[MMO Netcode and Tick Systems]] · [[MMO Server Architecture]] · [[Multiplayer Co-op]] · [[Combat]]
- [[Doom 1993]] · [[Counter-Strike Global Offensive]] · [[Team Fortress 2]]

## Sources

- https://en.wikipedia.org/wiki/Quake_(video_game)
- https://en.wikipedia.org/wiki/Quake_engine
- https://fabiensanglard.net/quakeSource/johnc-log.aug.htm
- https://nition.momentstudio.co.nz/2020/01/the-origin-of-client-side-prediction/
- https://en.wikipedia.org/wiki/Client-side_prediction
- https://news.ycombinator.com/item?id=19915698
