# Raw Research: MOBA/FPS Remainder Batch
ingested: 2026-06-14
pages fed:
- wiki/games/moba/Predecessor.md
- wiki/games/moba/Battlerite.md
- wiki/games/moba/Vainglory.md
- wiki/games/fps/PUBG Battlegrounds.md
- wiki/games/fps/Titanfall 2.md

---

## Predecessor

### Sources consulted
- https://en.wikipedia.org/wiki/Predecessor_(video_game) — Omeda Studios UK, founded 2020; Early Access Dec 2022; Open Beta Mar 28 2024; full release Aug 20 2024; UE5; 5v5 third-person; uses Paragon assets; 4 lane zones; Epic MegaGrant $2.2M 2021; $20M Series A July 2022; cross-play PC (Steam + EGS), PS4/PS5, Xbox Series X|S; Paragon creative director as advisor; no shutdown
- https://gamesbeat.com/omeda-studios-fixes-predecessor-multiplayer-matchmaking-by-consolidating-its-server-locations/ — Server consolidation to Dallas via Hathora; West Coast ping 100ms→40ms, East Coast 80ms→40ms; 2M players across platforms; team grew from 5-10 to 87; matchmaking backend: Pragma
- https://www.predecessorgame.com/en-US/news/dev-diary/Predecessor_2025_and_beyond — 16 patches in 2025; 8 new heroes; DLSS (1.8) + FSR (1.10); 3 new modes (Nitro, Legacy, ARAM); Augment System; 38 new items; World Shift events; tech debt flagged for 2026; F2P cosmetics (battlepasses, Loot Cores, Vault Passes)
- https://www.techradar.com/gaming/resurrected-moba-paragon-is-shutting-down-again — Paragon: The Overprime (Netmarble, different from Predecessor) shut down April 22 2024 after ~15 months; confirms Predecessor still active
- https://pragma.gg/case-studies/omeda-case-study — Pragma powers 1M+ players matchmaking; skill-based queuing cross-platform

### Key findings
- Omeda is the surviving Paragon spiritual successor; Overprime (Netmarble) and Fault (Strange Matter) had worse outcomes
- Server consolidation case: fewer nodes, closer geography → better average ping than spread multi-region pods at small population
- UE5 migration from UE4 driven by Lumen/Nanite for high-fidelity visuals that were Paragon's original selling point
- No public tick rate documentation

---

## Battlerite

### Sources consulted
- https://en.wikipedia.org/wiki/Battlerite — Stunlock Studios; Unity engine; Early Access Sept 2016 (440k copies in 3 months); F2P launch Nov 7 2017; peak 44,850 concurrent Nov 2017; <4000 monthly peak by 2018; Metacritic 85; development ended July 2019; maintenance mode Oct 2019; spiritual successor to Bloodline Champions
- https://kotaku.com/battlerite-is-a-true-moba-and-thank-god-1820989224 — no towers, no minions, no items; WoW Arena + Dota camera; round-based; teamfight distillation
- https://medium.com/nyc-design/the-moba-royale-battlerite-6100c9cb8619 — 2v2/3v3; rounds reset health and cooldowns; Battlerite picks between rounds; 10-20 min matches
- https://blog.stunlock.com/battlerite-4th-anniversary/ — studio retrospective; Battlerite Royale pivot (standalone paid Sept 2018) described as dev focus diversion
- Community forums: population spiral documented; V Rising pivot succeeded (survival-crafting doesn't require opponent pool)

### Key findings
- No public netcode/tick rate documentation; small arena scope (6 players max) implies naturally lower replication demands
- Battlerite Royale launched paid (not F2P) Sept 2018; community split across two products accelerated decline
- Population threshold failure: MOBA matchmaking requires minimum opponent pool; below threshold queue time rises → retention falls → pool shrinks further
- Subtraction design validated critically, failed commercially due to retention dynamics

---

## Vainglory

### Sources consulted
- https://en.wikipedia.org/wiki/Vainglory_(video_game) — Super Evil Megacorp; iOS Nov 16 2014; Android July 2 2015; Windows/macOS Feb 13 2019; cross-platform; F2P; 56 heroes by Update 4.11; Glory + ICE currencies; Talents system (168 upgrades); 3v3 and 5v5 modes; Metacritic 84; Rogue Games publisher 2019-2020
- https://www.gamedeveloper.com/production/why-super-evil-megacorp-built-a-proprietary-mobile-moba-engine — E.V.I.L. engine (10+ man-years); server-authoritative model; Apple Metal API; Tommy Krul quote on no existing engine solving networked touch games; built for precision control
- https://cloud.google.com/customers/superevilmegacorp — Google Cloud GKE (Kubernetes); Compute Engine; BigQuery; 45M players; auto-scaling replaced 5 manual on-call engineers; 1/5th cost of legacy provider; multi-region; Catalyst Black successor on same infra
- https://www.vainglorygame.com/news/vainglory-community-edition/ — April 1 2020 transition; client-authoritative shift; friends list/chat/leaderboards/quests/currencies removed in Stage 1; "app experience will get worse before it gets better"; matchmaking info stored on device; IAP disabled
- https://www.pocketgamer.biz/news/73049/super-evil-megacorp-rescues-vainglory/ — Rogue Games pulled plug March 2020; SEMC stepped in; "astronomical server costs" cited

### Key findings
- Server-authoritative mobile netcode in 2014 was technically exceptional; tied business model to ongoing OPEX
- Publisher transition exposed server cost as existential dependency
- Community Edition: client-authoritative degradation is well-documented — what server authority actually provides (social graph, leaderboards, anti-cheat, progression) becomes obvious when removed
- 3v3 reduced scope enabled mobile adoption; 5v5 expansion in 2018 diluted the focused identity
- 45M players but no long-term revenue model sustainable post-Rogue

---

## PUBG Battlegrounds

### Sources consulted
- https://en.wikipedia.org/wiki/PUBG:_Battlegrounds — PUBG Studios (Bluehole/Krafton); UE4; Early Access March 2017; full release Dec 20 2017; F2P Jan 12 2022 ($12.99 Battlegrounds Plus for ranked); 2,279,084 peak Steam concurrent; 75M copies by Dec 2022; 7 Guinness records; BattlEye (13M bans by Oct 2018); cosmetics-only monetisation pledge; Erangel 8×8 km; PUBG Mobile separate; inspired by ARMA mods + Battle Royale film
- https://pubg.ac/news/23012-dev-letter-server-performance-improvements — Target 30 Hz tick; Update #14: network update rate 2× to 60/sec, gunfire delay 94.5→77ms (-18%) at 40 alive; Update #19: actual tick 18.5→22.9 Hz (+22%), gunfire delay 149.4→61.6ms (-58%) at 85 alive; Net Send Flush stage (UDP flush before physics); replication interleaving (70m+ skip 1 frame; 400m+ skip 2 frames → +20% server perf)
- https://press.krafton.com/en-US/PUBG-BATTLEGROUNDS-TO-GO-FREE-TO-PLAY-ON-JAN-12-2022 — F2P confirmed Jan 2022; Battlegrounds Plus $12.99 for ranked + items
- https://www.gamesradar.com/pubg-free-to-play-interview/ — second-generation audience acquisition rationale; premium-to-F2P timing strategy

### Key findings
- Battle royale genre invention: ARMA mod lineage (Greene) → standalone commercial validation
- Blue zone: shrinking boundary as strategic surface not just timer; forces map-reading as primary skill
- UE4 stretched beyond designed scale; engineering had to invent replication throttling to approach 30 Hz
- F2P at year 5 (2022) preserved premium revenue through peak years, then opened to casual audience
- Cosmetics-only pledge publicly held; contrast with PUBG Mobile gacha model (separate operator)

---

## Titanfall 2

### Sources consulted
- https://en.wikipedia.org/wiki/Titanfall_2 — Respawn; EA publish; Oct 28 2016; PS4 + Xbox One + PC; Source engine heavily modified (renderer/audio/netcode replaced); PBR + HDR + custom texture streaming; double jump + wall run + ground slide + grapple; BT-7274 + Jack Cooper; Morgan Stanley: 4M units vs EA 9-10M target; UK week 1 = 25% of TF1; Apex Legends Feb 2019 (same engine, TF2 characters)
- https://developer.valvesoftware.com/wiki/Titanfall — Respawn quote: "replaced renderer, audio, netcode"; modified BSP; VPK packages; same branch as Apex
- https://www.gamedeveloper.com/design/the-idea-for-i-titanfall-2-i-s-most-iconic-level-predates-the-series-itself — Effect and Cause: two vertically stacked level copies, player teleports between them; mechanic predates TF series (Keating conception); GDC action blocks methodology
- https://www.gdcvault.com/play/1025105/Designing-Unforgettable-Titanfall-Single-Player — action blocks: self-contained vignettes prototyped in isolation, inserted into levels; enables variety-at-scale
- https://icon-era.com/blog/titanfall-2-player-count-and-statistics-2025.451/ — 2025: ~1,400-6,775 concurrent across platforms; Northstar client bypasses official DDOS-attacked servers; community-maintained multiplayer; Iowa most active datacenter

### Key findings
- Release window sabotage: between BF1 (Oct 21) and CoD:IW (Nov 4); EA scheduling overrode Respawn concern
- Action blocks: modular rapid-prototype level design methodology, transferable to dungeon/encounter design
- Effect and Cause: time-travel level = two stacked copies; technically elegant implementation of complex mechanic
- Northstar community server project: proof that community infrastructure can outlast publisher support
- Apex Legends: same engine + TF2 characters; Titanfall franchise effectively paused for battle royale pivot
- No official tick rate documentation; community estimates ~20 Hz server simulation
