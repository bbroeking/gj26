# Raw Provenance: FPS Cluster 1

Ingested: 2026-06-14
Pages fed: Doom 1993.md, Quake.md, Counter-Strike Global Offensive.md, Valorant.md, Team Fortress 2.md

## Sources consulted

### Doom 1993
- https://en.wikipedia.org/wiki/Doom_(1993_video_game) — release Dec 10 1993, five difficulty levels, deathmatch coinage, 3.5M copies by 1999, Library of Congress preservation 2007
- https://en.wikipedia.org/wiki/Doom_engine — BSP rendering, 2.5D limitations (no room-over-room, fixed camera height), 35 Hz fixed tick, WAD format, 1999 GPL source release
- https://www.engadget.com/hitting-the-books-doom-guy-john-romero-abrams-press-143005383.html — Romero/Carmack account of peer-to-peer multiplayer implementation, "deathmatch" coined, "frag" origin, one-month dev window for netcode
- https://doomwiki.org/wiki/Doom_networking_component — peer-to-peer architecture detail, IPX broadcast flooding corporate LANs, modem dial-up limitations
- https://doomwiki.org/wiki/Deathmatch — Romero coined term; deathmatch design inspired by fighting games
- https://www.vice.com/en/article/the-multiplayer-mode-of-doom-almost-never-happened/ — multiplayer added September–October 1993, one month before December release

### Quake
- https://en.wikipedia.org/wiki/Quake_(video_game) — June 1996, GT Interactive, QuakeC scripting, bunnyhopping/strafe-jumping/rocket-jumping, Red Annihilation 1997 esports, World Video Game Hall of Fame 2025
- https://en.wikipedia.org/wiki/Quake_engine — full real-time 3D, OpenGL acceleration, BSP + PVS, lightmaps, GPL release December 21 1999
- https://fabiensanglard.net/quakeSource/johnc-log.aug.htm — Carmack's August 1996 QuakeWorld log: 99% of players on 300+ ms modem; replaced reliable stream with unreliable UDP; per-packet server simulation (>50 ms → <4 ms response); client-side movement prediction; capped prediction scope to local player only to avoid error compounding
- https://nition.momentstudio.co.nz/2020/01/the-origin-of-client-side-prediction/ — Duke Nukem 3D (January 1996) used client-side prediction first (Ken Silverman confirmed); QuakeWorld (August 1996) popularized it; Wikipedia credit history
- https://en.wikipedia.org/wiki/Client-side_prediction — technical summary: client samples input → sends to server → server runs authoritative simulation → client reapplies unprocessed inputs on correction receipt
- https://news.ycombinator.com/item?id=19915698 — HN thread on Carmack QuakeWorld business model letter, 1996 latency context

### Counter-Strike: Global Offensive
- https://en.wikipedia.org/wiki/Counter-Strike:_Global_Offensive — August 2012, Valve + Hidden Path Entertainment, Source engine, free-to-play December 2018, CS2 (Source 2) September 2023, Major Championships $1M prize pools
- https://developer.valvesoftware.com/wiki/Lag_Compensation — Source engine lag comp: 1 second position history, rewind to shooter's view time, default players-only rewind, server-side resolution
- https://profilerr.net/64-ticks-vs-128-ticks-in-csgo-differences-and-what-is-better/ — 64 Hz official servers, 128 Hz community comp servers, coarser spray/peek at 64-tick, CS2 sub-tick partially resolves this
- https://counterstrike.fandom.com/wiki/Valve_Anti-Cheat — VAC launched 2002, delayed-ban strategy, permanent bans on VAC-secured servers
- https://help.steampowered.com/en/faqs/view/571A-97DA-70E9-FF74 — Valve support: VAC automated, not manual review; delayed detection on purpose

### Valorant
- https://en.wikipedia.org/wiki/Valorant — June 2, 2020; Riot Games; Unreal Engine 4 → UE5 July 2025; 29 agents as of May 2026; free-to-play Kingdom Credits + Valorant Points; 1.73M concurrent Twitch viewers at beta launch
- https://www.riotgames.com/en/news/valorants-128-tick-servers — 128-tick server engineering: 7.8125 ms per frame; initial 3 games/core target; RPC replication 100x–10000x improvement; animation every 4th frame; Xeon Scalable migration +30%; NUMA 50% → 97–99%; CFS scheduler 0.5ms → 0ms; rewind hit registration
- https://www.riotgames.com/en/news/peeking-valorants-netcode — server-authoritative model; client movement prediction at fixed 128 Hz; lag compensation via historical ring buffer rewind; 51ms peeker's advantage at 35ms/60fps (28% improvement); 1 buffered frame client-side, half-frame server target
- https://www.dexerto.com/valorant/riot-reveal-valorant-features-high-tick-rate-anti-cheat-more-1336507/ — Riot's pre-launch announcement of 128-tick and Vanguard as deliberate CS:GO differentiators
- https://edgegap.com/blog/game-backend-deep-dive-valorant-riot-games — server-authoritative architecture summary, global data center distribution, sub-35ms latency target
- https://en.wikipedia.org/wiki/Riot_Vanguard — kernel-level ring-0 driver; fog-of-war server-side enemy position withholding; $100K bug bounty; May 2026 IOMMU update for DMA cheats

### Team Fortress 2
- https://en.wikipedia.org/wiki/Team_Fortress_2 — October 10 2007; Valve; The Orange Box; nine classes; free-to-play June 2011; 12x revenue increase within 9 months of F2P; hat economy $50M+ valuation 2011; bot crisis 2020–2024; source code release February 2025
- https://wiki.teamfortress.com/wiki/Lag_compensation — Source engine lag comp in TF2: server "rewinds" on high-ping attacker action; backstab-through-wall perception explained; community mitigation (ping limits, reduced history length)
- https://developer.valvesoftware.com/wiki/Team_Fortress_2_engine_branch — TF2 branch is newer Source 2013 Multiplayer; default 66 Hz tick, max 100 Hz
- https://gamerant.com/team-fortress-2-source-code-full-client-released/ — February 2025 source code release, community mod enablement, Steam Workshop distribution license
- https://www.pcgamer.com/games/fps/valve-releases-team-fortress-2-sdk-enabling-creators-to-build-completely-new-games-based-on-tf2/ — SDK enables "completely new games based on TF2" free on Steam Workshop
