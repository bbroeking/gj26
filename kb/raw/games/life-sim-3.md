# Raw Provenance: Life-Sim Cluster 3

Ingested: 2026-06-14
Feeds: wiki/games/life-sim/ (4 pages: Haunted Chocolatier, Palia, Wylde Flowers, Sun Haven)

## Sources fetched

| URL | Summary | Status |
|-----|---------|--------|
| https://www.hauntedchocolatier.net/ | Official site; core loop (gather → make chocolate → run shop), combat (shield-block stun), C# from-scratch, solo dev, no release date | OK |
| https://www.nintendolife.com/news/2024/12/concernedape-shares-new-development-update-on-haunted-chocolatier | Dec 2024 dev update; vertical slice complete before Stardew 1.6 break; ConcernedApe quotes on isolation dev philosophy | OK |
| https://www.gamespot.com/articles/haunted-chocolatier-release-date-trailer-news/1100-6535251/ | News aggregation; confirmed fishing mini-game returns; no release window | OK |
| https://www.gamesradar.com/haunted-chocolatier-guide/ | Guide page; content truncated in fetch; supplemented by other sources | Partial |
| https://en.wikipedia.org/wiki/Palia | Developer (Singularity 6), Unreal Engine, Windows/Switch/PS5/Xbox, free-to-play, skills list, zone expansion history, 10M players by Apr 2026, Daybreak acquisition Jul 2024 | OK |
| https://www.singularity6.com/news/software-architecture-of-palia | Technical architecture deep-dive: 25 players/instance, server matching algorithm, Rust microservices, ScyllaDB, Kubernetes/Agones stack | OK |
| https://massivelyop.com/2023/08/02/singularity-6-interview-palia-stakes-its-claim-as-the-cozy-cottagecore-sandbox-to-beat/ | Pre-beta interview; design philosophy on cozy MMO; co-op gather buffs; housing plot system | 403 (content extracted via search snippet) |
| https://www.pcgamer.com/combat-free-mmo-palia-gives-me-high-hopes-for-the-future-of-cozy-mmos/ | Critical perspective; combat-free as commercial differentiator; directionless-loop risk | Via search snippet |
| https://en.wikipedia.org/wiki/Wylde_Flowers | Developer Studio Drydock, Unity, platforms, Apple Arcade launch Feb 2022, PC/Switch Sep 2022, Gayming Award, Wylde Society prequel Dec 2024 | OK |
| https://developer.apple.com/news/?id=din5adp5 | Apple Developer feature; team size (~12 → ~50 over 3 yrs), camera evolution (top-down → isometric), 18 hrs dialogue, 350 cutscenes, 230 credits, cultural consultants, Schofield's Sims FreePlay background | OK |
| https://www.gamesradar.com/how-studio-drydock-created-one-of-the-most-memorable-and-welcoming-farming-sims-ive-ever-played-good-representation-was-integral/ | Content truncated; supplemented by Apple Developer article and Wikipedia | Partial |
| https://en.wikipedia.org/wiki/Sun_Haven | Developer Pixel Sprout Studios, Unity engine, Steam EA Jun 2021, full release Mar 2023, Switch Nov/Dec 2024, no-stamina mechanic | OK |
| https://store.steampowered.com/app/1432860/Sun_Haven/ | Full feature list: 5 skill trees lvl 70, 4 biomes, 8-player co-op, 40+ crafting tables, 130+ fish, 10 professions, 7 races, magic spells, 30k+ dialogue lines | OK |
| https://www.kickstarter.com/projects/sunhaven/sunhaven/community | Kickstarter community page; 2020 funding origin; community demand drove IndieGoGo expansion | Via search snippet |
| https://metaphorsandmoonlight.com/game-review-sun-haven-by-pixel-sprout-studios/ | Review; no-stamina design commentary; biome progression structure | Via search snippet |

## Notes

- **Haunted Chocolatier:** thin source base by design — the game is unreleased and ConcernedApe shares sparingly. Page marked `status: stub`. The hauntedchocolatier.net blog and Nintendo Life Dec 2024 update are the two authoritative primary sources. GamesRadar guide was truncated; holdtoreset.com returned 403. Flag for re-fetch when game ships.
- **Palia:** excellent technical source (S6 architecture blog). MassivelyOP interview returned 403; key facts recovered from search snippets. Daybreak acquisition (Jul 2024) and 10M players (Apr 2026) added from Wikipedia; these post-date the 2023 closed-beta sources.
- **Wylde Flowers:** Apple Developer feature was the richest single source (team structure, production detail, design philosophy). GamesRadar feature was truncated. Wikipedia handled release dates and awards.
- **Sun Haven:** Steam page was the primary design-features source (extracted cleanly). Wikipedia handled release history. Team size for Pixel Sprout Studios not found in any fetched source — marked uncertain in page.
