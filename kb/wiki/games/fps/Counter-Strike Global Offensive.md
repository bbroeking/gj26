---
type: game
tags: [game-study, fps, tactical-shooter, economy, netcode, esports, free-to-play, valve, anti-cheat]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Counter-Strike:_Global_Offensive
  - https://developer.valvesoftware.com/wiki/Lag_Compensation
  - https://profilerr.net/64-ticks-vs-128-ticks-in-csgo-differences-and-what-is-better/
  - https://counterstrike.fandom.com/wiki/Valve_Anti-Cheat
  - https://help.steampowered.com/en/faqs/view/571A-97DA-70E9-FF74
---
# Counter-Strike Global Offensive

Tactical first-person shooter released August 2012 by Valve and Hidden Path Entertainment that defined competitive FPS esports economics and sparked the global weapon-skin market before transitioning to Counter-Strike 2 in September 2023.

## Design

**Core loop — economy-driven rounds.** Teams alternate Terrorist (plant bomb/eliminate CT) and Counter-Terrorist (defuse/eliminate T) roles across 30 rounds. Each round's outcome dictates the next round's budget: winners earn more, losers receive "loss bonuses" to stay viable. Players buy weapons, armor, and grenades at round start — no mid-round respawn.

**Buy-phase economy.** The in-round economy is CS:GO's strategic spine. Saving ("eco round") or spending ("force buy") are team decisions with downstream consequences two rounds later. The economy rewards teams that read opponent budgets, not just those with better aim. This creates macro-level strategy in a round-based micro-combat game.

**Map design canon.** CS:GO's active pool (Dust2, Mirage, Inferno, etc.) refined layouts over decades. Maps converge on two bomb sites reachable by known chokepoints; angles are deterministic; smoke-grenade line-ups are memorized. The metagame is partially a knowledge game played through a tight mechanical filter.

**Cosmetic economy.** The 2013 Arms Deal update introduced tradeable weapon skins obtainable through loot cases. By 2018 the skin market had generated hundreds of millions of dollars and spawned a secondary market on third-party sites, some operating as de facto gambling platforms. The free-to-play transition in December 2018 funded the game entirely through cosmetics thereafter.

## Implementation

**Engine.** Source engine (Valve, derived from id Tech / GoldSrc lineage). Counter-Strike 2 (September 2023) replaced Source with Source 2, enabling global illumination, sub-tick architecture, and shader-based smoke grenades.

**Netcode — lag compensation, 64/128-tick.** CS:GO's official servers ran at 64 Hz tick rate (updates every ~15.6 ms). Community competitive servers commonly ran 128 Hz. The Source engine's lag compensation system maintains 1 second of position history; when a player fires, the server rewinds opponent positions to the shooter's view time before resolving hit detection. Client-side prediction handles local movement.

**64 vs 128 tick.** At 64 Hz, projectile traces and movement snapshots are coarser — detectable in spray-and-pray patterns and peek trades at high frame rates. CS2's sub-tick architecture decouples game event timestamps from tick boundaries, partially resolving the debate without doubling server cost.

**VAC anti-cheat.** Valve Anti-Cheat runs as a background process scanning for known cheat signatures. It is deliberately delayed-ban (sometimes months after detection) to avoid revealing detection methods. Prime Matchmaking (2016) added phone-verified accounts to separate suspected smurf/cheat accounts.

**Distribution.** Shipped at $14.99 in 2012; free-to-play since December 2018. Operation passes and weapon case keys provide recurring revenue. Steam Workshop enables community map submission; the active duty pool is curated from this.

## Why it matters

CS:GO proved that the two-sided team economy — not just gunplay — can be the game's central strategic layer. The weapon-skin market redefined live-service cosmetics for competitive games and created a multi-hundred-million-dollar grey secondary market with no developer take. Valve's 64-tick/128-tick community tension directly motivated Riot Games to commit to 128-tick servers for Valorant as a launch differentiator.

## Relevance to Wayfinder

- **[[Economy]] — scarcity as strategy.** CS:GO's buy-phase forces players to choose between now and later. Wayfinder's [[Charts]] with ink cost, and the gather-craft supply chain, create similar "save or spend" micro-decisions per run — a transferable tension structure.
- **[[Multiplayer Co-op]] — team budgets.** The shared-economy round design shows how constraining shared resources raises team coordination stakes without complex systems. Relevant to co-op run preparation in Wayfinder.
- **[[MMO Netcode and Tick Systems]].** The 64/128-tick debate and CS2's sub-tick solution are the clearest public case study on tick rate cost vs. feel trade-offs — essential reading for Wayfinder's co-op netcode design.

## See also

- [[Game Index]] · [[Game Studies]]
- [[Design Influences]] · [[MMO Netcode and Tick Systems]] · [[Multiplayer Co-op]] · [[Combat]] · [[Economy]]
- [[Quake]] · [[Valorant]] · [[Team Fortress 2]]

## Sources

- https://en.wikipedia.org/wiki/Counter-Strike:_Global_Offensive
- https://developer.valvesoftware.com/wiki/Lag_Compensation
- https://profilerr.net/64-ticks-vs-128-ticks-in-csgo-differences-and-what-is-better/
- https://counterstrike.fandom.com/wiki/Valve_Anti-Cheat
- https://help.steampowered.com/en/faqs/view/571A-97DA-70E9-FF74
