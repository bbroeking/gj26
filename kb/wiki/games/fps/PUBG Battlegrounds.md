---
type: game
tags: [game-study, fps, battle-royale, unreal-engine-4, playerunknown, bluehole, krafton, genre-defining, free-to-play]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/PUBG:_Battlegrounds
  - https://pubg.ac/news/23012-dev-letter-server-performance-improvements
  - https://press.krafton.com/en-US/PUBG-BATTLEGROUNDS-TO-GO-FREE-TO-PLAY-ON-JAN-12-2022
  - https://www.gamesradar.com/pubg-free-to-play-interview/
---
# PUBG Battlegrounds

The steam-early-access survival shooter (March 2017, PUBG Studios / Bluehole) that single-handedly established battle royale as a mainstream genre — 2.28 million concurrent Steam players at peak, 75 million copies sold by December 2022 — by combining Brendan Greene's ARMA mod lineage with shrinking safe zones and 100-player drop-in matches on Unreal Engine 4.

## Design

PUBG structures each match as three overlapping subgames: the airdrop phase (where to land, what to contest), the loot phase (scavenging randomised weapon and armour spawns across a large map), and the combat endgame (eliminating rivals while the blue zone forces players together). The blue zone — a shrinking playfield boundary that deals damage to players outside it — is the genre's defining mechanical contribution: a timer that is also a strategic surface, rewarding map-reading and movement decision-making rather than reaction speed alone.

Maps evolved from the original 8×8 km Erangel (inspired by Russian/Eastern European aesthetics) to Miramar (desert), Sanhok (jungle, 4×4 km for faster games), and Vikendi (snow). Erangel's large scale forced Unreal Engine 4 into territory it was not designed for — Greene acknowledged UE4 was not built for environments of that size.

Cosmetic-only monetisation from launch: loot crates with skins and emotes, with PUBG Corporation explicitly committing that no item would "affect or alter gameplay." Free-to-play transition January 12, 2022 (with a $12.99 Battlegrounds Plus upgrade for ranked access). The mobile spin-off PUBG Mobile is separately operated and among the highest-grossing mobile games globally.

## Implementation

**Engine:** Unreal Engine 4.

**Server tick rate:** Target 30 Hz ("from 100 players to the very last bullet"), but early servers struggled to maintain this under load. A documented optimisation trajectory:
- *Update #14:* Network update rate doubled to 60 per second (not the actual server simulation rate, but how frequently state is sent to clients); gunfire delay improved ~18% (94.5 ms → 77 ms with 40 alive).
- *Update #19:* Actual server tick rate increased 22% on NA servers (18.5 → 22.9 Hz); gunfire delay dropped 58% (149.4 ms → 61.6 ms with 85 alive).
- *Replication interleaving:* Characters 70 m+ away skip 1 update frame; 400 m+ skip 2 frames. Net result: 20% server performance improvement with no perceptible gameplay impact.
- *Net Send Flush:* A dedicated network-flush stage was inserted before physics simulation, reducing the window between player action and state broadcast.

**Anti-cheat:** BattlEye, with over 13 million permanent bans by October 2018 — one of the largest anti-cheat enforcement actions in the industry at that point.

**Scale records:** Peak concurrent Steam players 2,279,084 (a Steam record at the time); fastest Steam Early Access title to 1 million units (16 days) and $100 million gross (79 days) — seven Guinness World Records during early access.

## Why it matters

- **Genre invention from mod lineage:** PUBG did not invent battle royale from scratch — Greene built on ARMA 2/3 mods and drew on the Japanese film Battle Royale — but it is the title that proved the format had mainstream commercial viability. Fortnite's battle royale mode launched two months after PUBG's early access as a direct response.
- **UE4 at large scale:** The engine was not designed for 8 km maps and 100 simultaneous physics-simulated characters. PUBG's engineering team had to invent replication throttling and network flush staging to approach the target tick rate. This is a practical case study in adapting a general engine to an outlier workload.
- **F2P transition timing:** Moving to free-to-play in January 2022 — five years after launch, after Fortnite had already captured the casual audience — preserved a premium-price playerbase through the game's peak years while allowing a second-generation audience acquisition. The Battlegrounds Plus upsell (ranked access) preserved some monetisation without fragmenting the core experience.
- **Cosmetics commitment:** The explicit cosmetics-only monetisation pledge, held across the game's commercial life, is a meaningful player-trust signal that competitors (Fortnite loot boxes, PUBG Mobile gacha) did not match.

## Relevance to Wayfinder

- [[MMO Netcode and Tick Systems]]: PUBG's replication interleaving by distance — skipping updates for far-away actors — is directly applicable to Wayfinder's dungeon scenes: entities outside combat range do not need full-rate state updates.
- [[Combat]]: The blue zone's role as a strategic constraint (not just a timer) maps to Wayfinder's dungeon affixes — environmental pressure that shapes player routing rather than directly punishing passivity.
- [[Multiplayer Co-op]]: PUBG's cosmetics-only monetisation commitment is the baseline player expectation for a multiplayer game with gear. Wayfinder should establish the same explicit pledge early: no pay-to-win Chart or Affix unlocks.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]] · [[Combat]]
- [[MMO Netcode and Tick Systems]] · [[Multiplayer Co-op]]
- Siblings: [[Fortnite]] · [[Apex Legends]] · [[Valorant]]

## Sources

- https://en.wikipedia.org/wiki/PUBG:_Battlegrounds
- https://pubg.ac/news/23012-dev-letter-server-performance-improvements
- https://press.krafton.com/en-US/PUBG-BATTLEGROUNDS-TO-GO-FREE-TO-PLAY-ON-JAN-12-2022
- https://www.gamesradar.com/pubg-free-to-play-interview/
