---
type: game
tags: [game-study, fps, looter-shooter, live-service, co-op, mmo, raids, seasonal, bungie]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Destiny_2
  - https://www.pcgamer.com/the-strange-science-of-destiny-2s-uniquely-complicated-netcode/
  - https://bungie.fandom.com/wiki/Tiger_Engine
  - https://naavik.co/digest/bungie-destiny-2-live-service-model/
  - https://solismagazine.com/destiny-2s-end-on-june-9-and-the-9-year-saga-that-defined-live-service-shooters
---
# Destiny 2

Destiny 2 is a 2017 first-person looter-shooter by Bungie that pioneered the FPS-MMO hybrid with six-player raids, a seasonal live-service model, and a power-level progression loop — becoming the most influential live-service co-op shooter of its generation before ending active content updates in June 2026.

## Design

- **Looter-shooter core.** Players earn randomized weapon and armor rolls with distinct perk combinations, chasing "god rolls" — optimal perk configurations for specific activities. This loot variability drives replay far beyond a fixed progression ladder, and Bungie's weapon-crafting system (introduced in The Witch Queen, 2022) allowed players to eventually craft target rolls, softening the RNG grind.
- **Power level system.** All gear has a Power number; your effective Power is the average across your equipped slots. Seasonal soft caps and hard caps gate activity access, creating a deliberate onboarding ramp each season. Over nine years this generated significant power-creep critique but also kept each season's content feeling distinct.
- **Raids as social endgame.** Six-player raids are the definitive D2 activity: no matchmaking (must assemble a fireteam), multi-encounter puzzles requiring persistent communication, and exclusive loot. Raids like Last Wish and Vault of Glass became cultural events — world-first races attracted tens of thousands of livestream viewers. This is the most direct MMO-raid design outside of traditional MMOs.
- **Seasonal model (Year 2 onward).** Three-month seasons with a seasonal story (episodic, "like a TV show"), seasonal artifact providing temporary power bonuses, and a battle pass ($10) for cosmetics and XP boosts. Bungie pioneered "sunsetting" seasonal content — removing activities from the game when a season ended — which created significant backlash and was partially reversed.

## Implementation

- **Tiger engine** — Bungie's proprietary engine, evolved from the Halo-era Blam! engine. Tiger drives the Destiny series' large open patrol zones, cinematics, and dense PvE encounters.
- **Netcode.** Bungie described D2's netcode as "uniquely complicated" — a hybrid peer-to-peer and client-server model. The Activity Host (a player's machine) handles scoring and spawn timers at 10 Hz; combat damage samples at 30 Hz. This exposes players to host-migration instability and DDOS risk compared to pure dedicated-server approaches. Full dedicated-server migration was a long-running community request never completed before live-service ended.
- **Ten expansions** over nine years (Curse of Osiris through The Final Shape, 2017–2024). The Final Shape (June 2024) concluded the "Light and Darkness Saga." Active live-service content updates ceased June 2026, leaving the game playable in maintenance mode.
- At peak, Destiny 2 generated over $1 billion annually; Bungie's $766M write-down by Sony (2024–2025) and subsequent layoffs illustrate the volatility of live-service economics at scale.

## Why it matters

Destiny 2 is the template for "FPS-meets-MMO" — every co-op looter after it (Warframe excepted as a predecessor, Anthem as a cautionary tale, The Division 2 as a parallel) is measured against it. Its nine-year arc is also the most complete case study in live-service sustainability: content sunsetting alienated veterans; expanding the free-to-play tier (Destiny 2 went F2P in 2019) grew the top of the funnel but complicated the content onboarding experience. The raid design remains an unsurpassed model of high-commitment, high-reward co-op endgame — requiring no matchmaking forces community formation (LFG sites, Sherpa programs) that extended the social life of the game beyond the developer's control.

## Relevance to Wayfinder

- **Dungeon-as-raid analogue.** Wayfinder's chart-keyed dungeon runs can learn from D2's raid structure — deliberately no-matchmaking creates social investment; see [[MMO Social and Endgame]] and [[Multiplayer Co-op]].
- **Power-level pacing.** D2's soft-cap → hard-cap → pinnacle ladder is a proven ramp; Wayfinder's [[MMO Progression Systems]] can adapt it for the gathering→crafting→delving skill spine (ADR 0003).
- **Seasonal content rot.** Sunsetting seasonal content lost Bungie goodwill it never fully recovered — a warning for Wayfinder's content roadmap; see [[MMO Social and Endgame]].

## See also

- [[Game Index]] · [[Game Studies]] · [[Overwatch]] · [[Apex Legends]] · [[Fortnite]]
- [[MMO Progression Systems]] · [[MMO Social and Endgame]] · [[MMO Netcode and Tick Systems]]
- [[Combat]] · [[Multiplayer Co-op]] · [[Balance Philosophy]] · [[Design Influences]]

## Sources

- https://en.wikipedia.org/wiki/Destiny_2
- https://www.pcgamer.com/the-strange-science-of-destiny-2s-uniquely-complicated-netcode/
- https://bungie.fandom.com/wiki/Tiger_Engine
- https://naavik.co/digest/bungie-destiny-2-live-service-model/
- https://solismagazine.com/destiny-2s-end-on-june-9-and-the-9-year-saga-that-defined-live-service-shooters
