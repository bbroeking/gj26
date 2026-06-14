# Raw Provenance: Co-op Game Studies — Batch 1
ingested: 2026-06-14
analyst: claude-sonnet-4-6
wiki-pages-produced:
  - wiki/games/co-op/Monster Hunter World.md
  - wiki/games/co-op/Deep Rock Galactic.md
  - wiki/games/co-op/Helldivers 2.md
  - wiki/games/co-op/Sea of Thieves.md
  - wiki/games/co-op/It Takes Two.md

---

## Sources fetched per game

### Monster Hunter World
- https://en.wikipedia.org/wiki/Monster_Hunter:_World — release date (Jan 26 2018 PS4/XB1, Aug 9 2018 PC), 14 weapon types, 4-player co-op, SOS Flare mechanic, 16-player session hub, MT Framework engine, custom Windows matchmaking, Iceborne expansion sales
- https://www.gamedeveloper.com/design/how-capcom-designed-i-monster-hunter-world-i-to-feel-approachable-and-alive — GDC postmortem by Yuya Tokuda: ecosystem design, monster AI pathfinding, turf wars, three core pillars (action/co-op/upgrade), approachability changes for Western market
- https://www.gdcvault.com/play/1024981/-Monster-Hunter-World-Postmortem — confirmed paywalled; session overview only; no additional technical detail extracted
- https://monsterhunterworld.wiki.fextralife.com/Multiplayer — SOS Flare cross-session joining, story quest solo requirement, HP scaling (150% at 2p, 220-260% at 3-4p), Palico disabled at 3+ players
- https://www.player.one/monster-hunter-world-multiplayer-sessions-squads-explained-123469 — 16-player session = virtual server with unique Session ID; Gathering Hub social space; hunts capped at 4

### Deep Rock Galactic
- https://deeprockgalactic.wiki.gg/wiki/Multiplayer — confirmed P2P, no dedicated servers, host machine runs session, up to 3 clients, Quick Join terminal, server browser with hazard-level filters, no host migration
- https://www.pcgamesn.com/deep-rock-galactic/deep-rock-galactic-unreal-engine-4 — CTO Henrik Edwards on mesh-carving system in UE4; lead programmer Jonas Møller on semi-procedural approach (room templates + procedural population); flat shading as byproduct of pipeline; UE4 provided out-of-box networked character control
- https://devtrackers.gg/deep-rock-galactic/p/17551c7b-host-migration-should-be-mandatory-for-any-game-with-peer-to-peer-connections — community/dev discussion confirming no host migration; Ghost Ship acknowledged the gap
- https://progameguides.com/deep-rock-galactic/all-deep-rock-galactic-classes-explained/ — four classes: Scout (grapple/flares), Engineer (platforms/turrets), Gunner (minigun/zipline), Driller (drill/flamethrower); class tool non-substitutability

### Helldivers 2
- https://en.wikipedia.org/wiki/Helldivers_2 — Arrowhead Game Studios, Sony Interactive Entertainment; PS5/PC Feb 8 2024, Xbox Aug 26 2025; Stingray engine; 1-4 players; friendly fire permanent; crossplay
- https://helldivers.wiki.gg/wiki/Second_Galactic_War_Mechanics — planet health pool (1,000,000 base), hourly regeneration, mission influence formula, full/partial operation multipliers, galactic impact modifier scaling, Liberation vs Defense campaign types, siege mechanic
- https://explore.st-aug.edu/exp/the-helldivers-2-wiki-decoding-stratagems-lore-and-the-galactic-war — stratagem input codes, Major Orders as narrative driver, Game Master ("Joel") confirmed human operator
- https://www.switchbladegaming.com/helldivers-2/galactic-war-guide/ — liberation meter detail, individual mission → planet health math
- https://icon-era.com/threads/helldivers-ii-was-built-on-an-archaic-engine-that-you-cant-access-anymore.9888/ — Stingray engine discontinuation, CEO quote about engineering burden, server sync requirement for horizontal scaling

### Sea of Thieves
- https://en.wikipedia.org/wiki/Sea_of_Thieves — Rare/Xbox Game Studios, March 20 2018 launch; Unreal Engine 4 (Rare's first UE4 project); no power-gated progression; Tall Tales added 2019 Anniversary Update; crew/ship type mapping
- https://learn.microsoft.com/en-us/shows/azure-videos/sea-of-thieves — Azure PlayFab, AKS, Azure Data Explorer, Azure Cache for Redis; dynamic session scaling; seamless player migration between instances
- https://x.com/SoT_Support/status/1484530730638225417 — official: server cap adjusted from 6 ships to 5 ships to "allow wider variety of ship sizes"; maintained 16-player max
- https://gamerant.com/sea-of-thieves-ships-per-server-count/ — detail on ship count change rationale
- https://www.clrn.org/how-many-people-in-a-sea-of-thieves-server/ — 5 ships / 16 players current cap; encounter frequency ~15-30 min; server merging when player-dry
- Rare designer Mike Chapman encounter-frequency quote (via Wikipedia): "every 15 minutes to half an hour"

### It Takes Two
- https://en.wikipedia.org/wiki/It_Takes_Two_(video_game) — Hazelight/EA; March 26 2021; UE4 + AngelScript; mandatory 2-player only; split-screen both local and online; Friends Pass; crossplay within platform families only; Metacritic 89 PS5; GOTY TGA 2021; 30M copies by April 2026; Switch port 2022 (Turn Me Up Games) required custom local wireless solution
- https://geekculture.co/geek-interview-hazelight-studios-josef-fares-it-takes-two/ — Josef Fares on "collaboration" as the design word; "never repeat" mechanic rule; designing for two from the start not retrofitting; rejection of collectibles
- https://facewaretech.com/blog/interview-hazelight-studios-talks-facial-animation-on-it-takes-two/ — facial mocap at Hazelight, actor improvisation; UE4 confirmed
- https://www.hazelight.se/games/it-takes-two/ — studio page confirming mandatory 2-player and Friends Pass
- https://whatsontech.co.uk/is-it-takes-two-cross-platform-or-crossplay-in-2024/ — crossplay limits: Xbox/PC together, PS4/PS5 together, no Xbox↔PlayStation

---

## Notes on source quality

- Monster Hunter World netcode internals are not publicly documented by Capcom. P2P vs. relay-server architecture is inferred from community reports of host-dependent latency; treat as uncertain.
- Deep Rock Galactic: P2P confirmed by official wiki. Mesh-carving pipeline confirmed by named engineers (Edwards, Møller) in PCGamesN feature.
- Helldivers 2: server sync requirement inferred from community discussion on Icon-Era; crossplay architecture confirmed; Stingray engine confirmed by CEO. Launch server crisis (~450k peak concurrent) widely reported but specific capacity figures not from official source.
- Sea of Thieves: Azure/PlayFab architecture is officially documented by Microsoft. Ship/player caps from official @SoT_Support Twitter. Dedicated server model (not P2P) inferred from Azure documentation and no community reports of host-dependency issues.
- It Takes Two: P2P inferred from no dedicated server announcement and single-connection architecture; platform crossplay limits confirmed by community/tech sources. AngelScript integration is documented in UE4 community.
