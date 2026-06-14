# Colony Sim Batch 2 — Raw Research Notes
_ingested: 2026-06-14_

Pages fed from this raw file:
- [[Frostpunk 2]]
- [[Surviving Mars]]
- [[Banished]]
- [[Timberborn]]
- [[Anno 1800]]
- [[Going Medieval]]
- [[Workers and Resources Soviet Republic]]

---

## Frostpunk 2
- Developer: 11 Bit Studios | Publisher: 11 Bit Studios | Release: 2024-09-20 (PC), 2025-09-18 (console)
- Engine: Unreal Engine 5 (predecessor used proprietary Liquid Engine)
- Key pivot: "social survival" — faction politics as the primary threat, not environment
- District-scale building (not individual structures); weekly timescale (not real-time hours)
- Council: 100 seats; 51-vote majority for standard laws; 67-vote supermajority for power-granting laws
- Idea Tree: faction-proposed research branches; adopting one branch closes rival branches
- Breaking promises to factions damages trust and can trigger rebellion events
- Reception: 85/100 Metacritic, 95% OpenCritic; 592,000 copies / $18.5M by Dec 2024; Best Sim/Strategy at TGA 2024
- Sources: https://en.wikipedia.org/wiki/Frostpunk_2 | https://11bitstudios.com/games/frostpunk-2/

---

## Surviving Mars
- Developer: Haemimont Games (2018-2021), Abstraction Games (2021-present) | Publisher: Paradox Interactive
- Release: 2018-03-15 | Relaunched as Surviving Mars: Relaunched (2025, consolidates all DLC)
- Engine: Haemimont proprietary (also used in Tropico 5, Victor Vran)
- Two-layer resource model: outer (surface infrastructure) + inner (dome ecology)
- Colonist stats: Health, Sanity, Comfort, Morale — all tracked per-agent
- Trait examples: Loner (loses Comfort in domes >30 pop); Dreamer (required for Inner Light mystery)
- Mystery system: one Mars mystery + one asteroid mystery per game; condition-gated event chains (not scripted cutscenes)
- Inner Light mystery requires: 250 Dreamer-trait colonists + Dream Simulation research + Dream Reality research
- Supply rocket cadence: 30-40 day travel time from Earth; forces long-range supply forecasting
- Sector scanning gates construction (reveals deposits and mystery triggers)
- Reception: 73-76 Metacritic; praised for depth, criticised for tutorial sparsity
- Sources: https://en.wikipedia.org/wiki/Surviving_Mars | https://survivingmars.paradoxwikis.com/Mystery | https://www.paradoxinteractive.com/games/surviving-mars-relaunched/news/mysteries-of-mars

---

## Banished
- Developer: Shining Rock Software (solo: Luke Hodorowicz) | Release: 2014-02-18
- Engine: custom C++ / DirectX 11 (no middleware beyond physics library)
- Price: $20; sold 1M+ copies in first year; no marketing budget
- Core philosophy: "build what you want, when you want it" — no tech tree
- Resource availability is the only gate; players can build any building with sufficient materials
- Citizens are per-agent: each has home, job, spouse, tool-type inventory slot
- Job pathfinding: first-available (not optimised) → layout-sensitive labour efficiency
- Age pyramid trap: simultaneous founding groups retire simultaneously → dependency wave
- Seasonal pressure: crop failure in winter; food stores must precede first frost
- Death is permanent; each birth is a multi-year investment
- Community modding extended content surface for years
- Sources: https://en.wikipedia.org/wiki/Banished_(video_game) | https://www.gamedeveloper.com/business/-i-banished-i-s-build-what-you-want-when-you-want-it-game-design | http://www.playthepast.org/?p=5695

---

## Timberborn
- Developer: Mechanistry (Poland) | EA: Sept 2021 → full release 2025 | Engine: Unity (C#)
- Hit 1M players before full release
- Water system: hybrid 2D/3D tile-pipe model derived from academic fluid dynamics research
- Each tile connects to 4 neighbours via virtual pipes; depth values level continuously
- Water momentum calculated between ticks → realistic flooding (shallow river vs. full reservoir differ)
- Irrigation: moisture spreads from water tiles to adjacent ground at diminishing rates; elevation blocks spread
- Dry season: water sources weaken gradually before formal drought (smooth visual warning)
- Badwater tide: contaminated water flood variant; requires barriers and purification infrastructure
- Factions: Folktails (pastoral/bio) vs. Iron Teeth (mechanical/industrial) — same water constraint, different building vocabularies
- Vertical building: multi-story towers + underground burrowing; emerged from player demand
- Update 6 (Wonders of Water): added true 3D water physics + official mod support
- Game works as both hardcore strategy and cozy sim (explicit developer positioning)
- Sources: https://en.wikipedia.org/wiki/Timberborn | https://www.gamedeveloper.com/design/deep-dive-timberborn-s-water-mechanics | https://www.gamedeveloper.com/marketing/deep-dive-how-we-got-one-million-players-to-give-a-dam-about-timberborn

---

## Anno 1800
- Developer: Ubisoft Blue Byte | Publisher: Ubisoft | Release: 2019-04-16 (PC), 2023-03-16 (console)
- Engine: proprietary Ubisoft Blue Byte engine; DirectX 11
- Fastest-selling Anno game; 4x more copies than Anno 2205 in first week
- Metacritic: 78-83 across platforms
- 5 residential tiers: Farmers → Workers → Artisans → Engineers → Investors
- Higher-tier workers cannot substitute for lower-tier: Farmers permanently required for agricultural buildings
- Production chains: range from 1-step to multi-branch; different cycle timings require throughput ratio calculation
- Blueprint mode: ghost placement without resource expenditure; enables pre-planning
- Dual world: Old World (temperate, Europe) + New World (tropical, Americas) with complementary goods
- Industrialisation trade-off: factory construction reduces city attractiveness → tourism revenue tension
- Four seasonal DLC passes: botanical gardens, arctic, skyscrapers, airships, new population tiers (through 2023)
- Sources: https://en.wikipedia.org/wiki/Anno_1800 | https://www.anno-union.com/devblog-residential-tiers/ | https://anno1800.fandom.com/wiki/Production_chains

---

## Going Medieval
- Developer: Foxy Voxel (Serbia) | EA: 2021-06-01 → full release: 2026-03-17
- Engine: Unity (Windows)
- Setting: alternate-history 14th-century Britain, post-Black Death plague survivors
- 83% OpenCritic recommendation
- Key differentiator: full 3D voxel building — hillside digging, underground cellars, multi-story towers
- Indirect colonist control: task assignment, autonomous pathfinding (like RimWorld)
- Colonist mood tracked; sustained neglect causes permanent departure (not just debuff)
- Procedural maps with adjustable terrain and threat settings (raid frequency, wildlife)
- Raids: bandit attacks, animal attacks, diplomatic aggression — serve as castle-building stress tests
- Vertical strata naturally emerge: fields/workshops ground → workshops/storage first floor → quarters upper → cold storage underground
- Compared to RimWorld/Dwarf Fortress in reviews; positioned as more accessible visual entry point
- Sources: https://en.wikipedia.org/wiki/Going_Medieval | https://screenrant.com/foxy-voxel-interview-going-medieval-early-access/ | https://www.pcgamer.com/going-medieval-is-a-colony-sim-that-takes-its-castle-building-quite-seriously/

---

## Workers and Resources: Soviet Republic
- Developer: 3Division (Slovakia) | Publisher: Hooded Horse | EA: 2019-03-15 → full release: 2024-06-20
- Setting: fictional Eastern Bloc republic, 1960s-1990s; no time limit
- Mostly Positive Steam reviews (tens of thousands of ratings)
- DLC: Biomes (June 2024), World Maps (December 2024), Early Start (May 2025)
- 30+ commodities; each requires specific vehicle and storage types
  - Liquids: pipe networks or tanker trucks
  - Bulk ore: conveyor belts, flatbed train cars, dump trucks
  - Prefab panels: flatbed transport
- Transport simulation: every vehicle line manually configured (route, vehicle count, stop order, cargo, load/unload points)
- Road gradient affects vehicle performance (speed, fuel consumption)
- Dual-currency import: rubles (Eastern) vs. dollars (Western tech); dollars only earned via exports
- Realistic Mode: removes all abstraction — no instant building purchase, no money-completion; all materials physically transported to construction site; demolition produces rubble requiring transport
- Worker welfare → direct production failure (unhealthy/unhappy workers don't show up)
- DMCA dispute Feb 2023 (realistic mode naming); resolved March 2023
- Same publisher (Hooded Horse) as Manor Lords — "hardcore city-builder" niche
- Sources: https://en.wikipedia.org/wiki/Workers_%26_Resources:_Soviet_Republic | https://mygamingtutorials.com/2025/06/04/15-steps-for-beginners-a-comprehensive-guide-to-realistic-mode-in-workers-and-resources-soviet-republic/ | https://wiki.hoodedhorse.com/Workers_Resources_Soviet_Republic/Game_settings
