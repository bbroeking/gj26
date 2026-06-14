---
type: game
tags: [game-study, fps, tactical-shooter, hero-shooter, netcode, anti-cheat, 128-tick, riot-games, server-authoritative]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Valorant
  - https://www.riotgames.com/en/news/valorants-128-tick-servers
  - https://www.riotgames.com/en/news/peeking-valorants-netcode
  - https://www.dexerto.com/valorant/riot-reveal-valorant-features-high-tick-rate-anti-cheat-more-1336507/
  - https://edgegap.com/blog/game-backend-deep-dive-valorant-riot-games
  - https://en.wikipedia.org/wiki/Riot_Vanguard
---
# Valorant

Tactical hero-shooter released June 2, 2020 by Riot Games that merged Counter-Strike's round economy with Overwatch-style agent abilities and launched with an engineering commitment to 128-tick servers and kernel-level anti-cheat as explicit market differentiators.

## Design

**Core loop.** Two five-player teams trade Attacker/Defender roles across 25 rounds (first to 13). Attackers plant the Spike; Defenders defuse it. Economy system: each round's outcome determines next-round budget for weapons and armor — identical to CS:GO's buy-phase structure.

**Agent abilities.** Each of 29 agents (as of 2026) carries a unique ability kit: two basic abilities, one signature (free per round), one ultimate (charged by kills/orbs). Abilities create smokes, walls, flashes, heals, and zone-denial. The design constraint: no ability kills directly at release (later relaxed). Gunplay remains primary; abilities are tactical amplifiers, not win conditions.

**Agents as roster meta.** Team composition matters round-to-round (Controllers smoke, Sentinels hold sites, Initiators open space, Duelists entry). This layered an Overwatch-style team-building metagame onto a CS:GO economic skeleton.

**Map design.** Valorant maps are authored around agent synergies — teleporters, elevated positions, one-way smokes. Each new map ships with a designed ability interaction built into the geometry, making maps and agent roster co-evolve.

## Implementation

**Engine.** Unreal Engine 4 at launch; migrated to Unreal Engine 5 in July 2025. The low system requirements (targeting modest PCs globally) drove heavy optimization work.

**Netcode — 128-tick, server-authoritative.** Every player receives 128-tick service from launch. The server updates and sends state 128 times per second (every 7.8125 ms). Technical cost: Riot needed to fit multiple game instances per CPU core at under 2.34 ms per frame — achieved through RPC replication rewrites (100x–10000x improvement in specific subsystems), animation downsampling (every 4th frame lerped), and hardware migration to Intel Xeon Scalable (non-inclusive cache, +30%) with NUMA memory locality tuning (50% → 97–99% local access).

**Client prediction.** Clients predict local movement at a fixed 128 Hz timestep independent of render framerate. The server validates and sends corrections; clients reconcile.

**Lag compensation — rewind hit registration.** On a shot packet, the server rewinds all player positions and animation state to the shooter's view timestamp using a historical ring buffer, then resolves hit detection. This eliminates leading shots on moving targets. One buffered frame of movement data is maintained client-side; the server targets half a frame of buffer.

**Peeker's advantage reduction.** Riot measured the inherent attacker advantage (peeking player acts before defender can react): at 35 ms average latency and 60 FPS, they reduced peeker's advantage to ~51 ms — a 28% improvement over baseline. The 128-tick rate is part of this reduction; the other contributor is globally distributed data centers targeting sub-35 ms RTT.

**Anti-cheat — Riot Vanguard.** Kernel-level driver (ring-0) running at machine boot, not game launch. Monitors for DMA cheats, wallhacks, aimbots. The server's "fog of war" system withholds enemy position data from clients until the server calculates the enemy as visible — eliminating ESP/wallhack cheats at the data layer rather than at the detection layer. Bug bounty program offers up to $100,000 for Vanguard vulnerabilities.

**Distribution.** Free-to-play. Revenue from cosmetic bundles (weapon skins, player cards, sprays) and Battle Pass. Two currencies: Kingdom Credits (gameplay-earned, agent unlocks) and Valorant Points (purchased, cosmetics).

## Why it matters

Valorant is the clearest public case study in using netcode quality as a product promise. By committing to 128-tick for all players (versus CS:GO's 64-tick standard), Riot captured competitive players who had been asking Valve for better servers. The fog-of-war anti-cheat architecture — preventing wallhack data from reaching the client at the protocol level — is a design lesson in anti-cheat-by-design rather than detection-and-ban. The kernel anti-cheat generated significant controversy around privacy and security, documenting the trade-offs of aggressive cheat prevention.

## Relevance to Wayfinder

- **[[MMO Netcode and Tick Systems]].** Riot's 128-tick engineering write-up is the most detailed public documentation of server tick optimization for a fast-paced competitive game. Wayfinder's [[Multiplayer Co-op]] is co-op not competitive, but the per-frame budget reasoning (2.34 ms per frame at 128 Hz) informs any tick-rate decision.
- **[[Multiplayer Co-op]] — fog of war as anti-exploit.** Withholding enemy positions from clients until server-confirmed visibility is directly applicable to Wayfinder's dungeon co-op: enemy positions shouldn't be leaked to clients before they're in range. This is a cheat-prevention lesson but also a spoiler-prevention and tension-preservation design.
- **[[Combat]] — abilities as tactical amplifiers.** Valorant's constraint that abilities cannot kill (originally) kept gunplay primary. Relevant to Wayfinder's one-verb combat — skills should amplify the combat verb, not replace it.

## See also

- [[Game Index]] · [[Game Studies]]
- [[Design Influences]] · [[MMO Netcode and Tick Systems]] · [[MMO Server Architecture]] · [[Multiplayer Co-op]] · [[Combat]]
- [[Counter-Strike Global Offensive]] · [[Team Fortress 2]] · [[Quake]]

## Sources

- https://en.wikipedia.org/wiki/Valorant
- https://www.riotgames.com/en/news/valorants-128-tick-servers
- https://www.riotgames.com/en/news/peeking-valorants-netcode
- https://www.dexerto.com/valorant/riot-reveal-valorant-features-high-tick-rate-anti-cheat-more-1336507/
- https://edgegap.com/blog/game-backend-deep-dive-valorant-riot-games
- https://en.wikipedia.org/wiki/Riot_Vanguard
