# MOBA Cluster — Raw Research Notes (Batch 1)
ingested: 2026-06-14

## Sources consulted

- https://en.wikipedia.org/wiki/League_of_Legends
- https://en.wikipedia.org/wiki/Dota_2
- https://en.wikipedia.org/wiki/Heroes_of_the_Storm
- https://en.wikipedia.org/wiki/Smite_(video_game)
- https://en.wikipedia.org/wiki/Paragon_(video_game)
- https://diamondlobby.com/server-tick-rates/
- https://productmint.com/what-happened-to-paragon/
- https://leagueoflegends.fandom.com/wiki/Queuing_and_Matchmaking
- https://wiki.leagueoflegends.com/en-us/Tick_and_updates
- https://github.com/ValveSoftware/Dota2-Gameplay/discussions/6777
- https://developer.valvesoftware.com/wiki/Source_2
- https://heroesofthestorm-archive.fandom.com/wiki/Heroes_of_the_Storm/Development
- https://smite.fandom.com/wiki/Hi-Rez_Studios
- https://www.gameleap.com/articles/smite-2-statement-from-hi-rez-president-approach-to-game-design-unreal-engine-5-more
- https://www.unrealengine.com/developer-interviews/why-paragon-fueled-moba-predecessor-shifted-to-unreal-engine-5
- https://games.mxdwn.com/news/tim-sweeney-of-epic-games-is-not-sure-what-lessons-to-learn-from-paragon/

## Key findings

### League of Legends
- Released October 27, 2009; dev: Riot Games; proprietary engine
- 30 Hz server tick rate (~33 ms tick), authoritative server model
- 172 champions (as of 2025); ~2-week patch cadence
- 10-tier ranked ladder (Iron → Challenger + Emerald added 2023); hidden MMR
- Core map: 3 lanes + jungle; dragon/Baron buffs; fog of war; inhibitors
- Free-to-play cosmetics only; ~$150M/month revenue (2016 peak)
- Esports: 12 regional leagues; worlds broadcast on ESPN/Twitch/Bilibili
- "League Next" modernization announced December 2025

### Dota 2
- Released July 2013 (Valve); sequel to Warcraft III custom map DotA (IceFrog hired 2009)
- Source engine → Source 2 migration September 2015 ("Dota 2 Reborn") — first Source 2 game
- ~30 Hz matchmaking tick (client sends ~150 byte updates 30x/second); client-server state model (not lockstep)
- 127 heroes; all free at launch; bi-weekly patches since 2018 (prior: infrequent large patches)
- MMR split by role (core/support); phone number verification to combat smurfing; recalibration every ~6 months
- Free-to-play: cosmetics + Dota Plus subscription; Battle Pass crowdfunds The International
- The International 2021 prize pool peaked at $40 million (largest in esports history)
- Standout mechanics: deny system, Captain's Mode draft, Talent Tree (introduced patch 7.00)
- Warcraft III lockstep → Dota 2 server-authoritative (determinism no longer required)

### Heroes of the Storm
- Released June 2, 2015 (Blizzard); engine: StarCraft II Galaxy engine (shared codebase)
- 89 heroes as of 2025; 6 roles (tank, bruiser, ranged/melee assassin, healer, support)
- No individual gold; shared team XP; 15 battlegrounds each with unique secondary objectives
- Heroic ability chosen at level 10 from 2 options; Storm Talents at 20
- Esports: Heroes Global Championship cancelled December 13, 2018
- Major development ended July 2022; maintenance mode continues post-Microsoft acquisition
- Differentiation: team-focused design, no individual carry — compressed MOBA for casual players

### Smite
- Released March 25, 2014 (Titan Forge / Hi-Rez); built on Unreal Engine 3
- Third-person camera (behind the shoulder) — fundamental differentiator from top-down peers
- 130+ gods across 15+ pantheons; TrueSkill-variant ranked matchmaking
- Monetization: rotating free 12 gods weekly or permanent god pack; $300M revenue by 2019
- Esports: annual World Championship ($1M capped prize pool); franchise model from Season 8
- Smite 2 launched January 2025 on Unreal Engine 5; original Smite concluded February 2025

### Paragon
- Early access March 2016; open beta August 2016; shutdown April 26, 2018 (Epic Games)
- Engine: Unreal Engine 4; third-person MOBA with verticality and non-traditional map
- Card-based itemization system (replaced traditional items) — controversial, hard to learn
- 7.3M downloads by July 2017; never found sustainable active player base
- "New Dawn" patch (August 2017) rebalanced all heroes + raised skin prices → community backlash
- Fortnite Battle Royale launched September 2017 → Epic redirected dev resources
- Tim Sweeney: "not sure what lessons to learn from Paragon"
- Legacy: ~$12–17M assets released free on UE4 marketplace → Predecessor, Overprime, Fault, CORE
- Predecessor raised $2.2M (Oct 2021); later also shut down
- Replay engine built for Paragon was later used in Fortnite

## Wiki pages fed
- wiki/games/moba/League of Legends.md
- wiki/games/moba/Dota 2.md
- wiki/games/moba/Heroes of the Storm.md
- wiki/games/moba/Smite.md
- wiki/games/moba/Paragon.md
