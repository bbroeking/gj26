---
type: game
tags: [game-study, moba, third-person, unreal-engine-5, paragon, omeda-studios, live-service, cross-platform]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Predecessor_(video_game)
  - https://gamesbeat.com/omeda-studios-fixes-predecessor-multiplayer-matchmaking-by-consolidating-its-server-locations/
  - https://www.predecessorgame.com/en-US/news/dev-diary/Predecessor_2025_and_beyond
  - https://www.techradar.com/gaming/resurrected-moba-paragon-is-shutting-down-again
  - https://pragma.gg/case-studies/omeda-case-study
---
# Predecessor

A free-to-play cross-platform third-person MOBA by Omeda Studios (UK) that resurrects Epic's cancelled Paragon — reusing its hero assets and Agora map on Unreal Engine 5 — and reached over two million players across PC, PlayStation, and Xbox by 2024.

## Design

Predecessor is a 5v5 third-person action MOBA played on a symmetrical three-lane map (Offlane, Jungle, Mid, Duo lanes plus a shared river zone). Heroes are drawn directly from Paragon's roster, repaired and rebalanced for the new game; eight additional heroes were added in 2025 alone. Each hero has four unique abilities plus a basic attack; players build items from an in-match shop to scale power. The Augment System (added 2025) layers passive bonuses on top of the item build, allowing further specialisation. Late-match objectives — towers, inhibitors, and a contested power node — gate the winning push.

The game ships core mode variants alongside the main match: ARAM (all-random, one lane), Nitro (fast-paced mode), and Legacy (original Paragon map recreation). World Shift events (Cataclysm, Frostfall) dynamically reskin the map mid-season to maintain novelty. Ranked mode runs 24/7 since patch 1.6.

Monetization is free-to-play cosmetics: seasonal battlepasses, Loot Cores, and Vault Passes that unlock previous season cosmetics. No pay-to-win stat items.

## Implementation

**Engine:** Unreal Engine 5. Omeda migrated from UE4 (where Paragon's source assets lived) specifically to leverage Lumen and Nanite for the high-fidelity visuals that were Paragon's calling card, without the bespoke UE4 lighting rigs Epic originally used.

**Server infrastructure:** Initially launched with separate West Coast and East Coast servers via a legacy cloud provider, producing inconsistent 80–100 ms pings. After migrating to Hathora's dedicated game-server orchestration platform, Omeda consolidated North American traffic through a single Dallas datacenter, dropping typical player latency to ~40 ms for both coasts. The matchmaking backend runs on Pragma, which powers skill-based queue formation and cross-platform lobby management for PC (Steam + Epic Games Store), PS4/PS5, and Xbox Series X|S.

**Team scale:** Founded 2020 with 5–10 people; grew to 87 employees by open beta (March 2024). Epic MegaGrant of $2.2 M in 2021 preceded a $20 M Series A in July 2022.

**DLSS and FSR** upscaling were added in patches 1.8 and 1.10 respectively, addressing UE5 performance cost on mid-tier hardware.

## Why it matters

- **Asset rescue → audience acquisition gap:** Paragon: The Overprime (Netmarble) also reused Epic's free assets and shut down April 22, 2024 after ~15 months. Predecessor survived by investing in a native player community and iterating on design; raw asset quality is not a moat.
- **Cross-platform matchmaking trade-offs:** Merging PC and console queues in a skill-shot-heavy MOBA requires careful input-matching logic. Omeda pools by skill first, platform second — a reasonable priority order, but one that increases console queue times when the population thins.
- **Server consolidation over distribution:** The counter-intuitive move to funnel all NA traffic through one datacenter (Dallas) improved average latency because queue times shrank and players stopped landing on underpopulated regional pods. For small live-service games, fewer, better-connected nodes can beat geographically spread infrastructure.
- **Pace of content:** 16 patches and 8 heroes in 2025 signals a studio burning roadmap aggressively; the dev diary explicitly named "tech debt" as a 2026 priority. Fast shipping and code health are in tension.

## Relevance to Wayfinder

- [[Multiplayer Co-op]]: Predecessor's cross-platform pool-by-skill-first approach is directly applicable to Wayfinder's dungeon matchmaking — prioritise run-difficulty compatibility over input device.
- [[Combat]]: Paragon's hero identity (strong visual language, four-ability kit) survived the transition to Predecessor intact. Wayfinder's Chart-based combat customisation should similarly anchor to a readable core before layering [[Affixes]].
- [[MMO Netcode and Tick Systems]]: The Hathora/Dallas consolidation case is a practical small-studio netcode story — minimise server sprawl until population justifies distribution.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]] · [[Multiplayer Co-op]]
- [[MMO Netcode and Tick Systems]] · [[Combat]]
- Predecessor: [[Paragon]]
- Siblings: [[Dota 2]] · [[League of Legends]] · [[Smite]]

## Sources

- https://en.wikipedia.org/wiki/Predecessor_(video_game)
- https://gamesbeat.com/omeda-studios-fixes-predecessor-multiplayer-matchmaking-by-consolidating-its-server-locations/
- https://www.predecessorgame.com/en-US/news/dev-diary/Predecessor_2025_and_beyond
- https://www.techradar.com/gaming/resurrected-moba-paragon-is-shutting-down-again
- https://pragma.gg/case-studies/omeda-case-study
