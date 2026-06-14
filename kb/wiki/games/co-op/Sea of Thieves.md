---
type: game
tags: [game-study, co-op, shared-world, open-world, emergent-gameplay, pirate, sandbox, azure]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Sea_of_Thieves
  - https://www.pcgamingwiki.com/wiki/Sea_of_Thieves
  - https://learn.microsoft.com/en-us/shows/azure-videos/sea-of-thieves
  - https://x.com/SoT_Support/status/1484530730638225417
  - https://gamerant.com/sea-of-thieves-ships-per-server-count/
  - https://www.clrn.org/how-many-people-in-a-sea-of-thieves-server/
---
# Sea of Thieves

Open-world pirate co-op (2018, Rare / Xbox Game Studios) — shared-world adventure where crews of 1–4 sail, plunder, and betray each other in a persistent sea populated by up to five simultaneous ships, with emergent PvPvE and structured Tall Tale quests as its two poles.

## Design

- **Crew-scaled ships as the session unit.** Three ship types map to crew size: Sloop (1–2), Brigantine (3), Galleon (4). Rare capped the crew at four because the designers felt larger groups harmed "intimate friendship and communication." The ship is both the vehicle and the social space — crew coordination on sailing (one steers, one manages sails, one fires cannons, one bails water) is the core co-op loop even before combat begins.
- **Shared world, organic encounter frequency.** Each server hosts up to **five ships and 16 players**. Rare deliberately limits density, aiming for another ship encounter roughly every 15–30 minutes. If too long passes without a player encounter, the matchmaker merges the player's instance with a more populated one. The result: other players feel like events, not noise.
- **Emergent betrayal as a design pillar.** The game deliberately avoids enforcing co-operation. Any player can attack any other; alliances can form and break mid-session; a crewmate can scuttle their own ship. The lack of formal teams means every encounter carries ambiguity. This is the game's most distinctive mechanic and also its most controversial: players seeking safe co-op bounty-running can be griefed without recourse.
- **Tall Tales: structured narrative within the sandbox.** Added in the Anniversary Update (2019), Tall Tales are authored story missions with fixed objectives and puzzle sequences. They coexist in the shared world — other player crews can interfere mid-tale. They represent Rare's solution to the tension between sandbox emergence and narrative coherence: the story exists in the world, not in a separate instance.
- **No traditional progression or power gates.** Gold and reputation unlock cosmetics only. A day-one player and a veteran are identically capable in combat. This was a deliberate anti-power-spiral decision that also means griefing by veterans carries no mechanical advantage (only skill).

## Implementation

- **Engine:** Unreal Engine 4. Rare's first project on UE4 after years on proprietary engines; the transition added scope risk but provided a well-documented networking baseline.
- **Azure + PlayFab backend.** Sea of Thieves is hosted on Microsoft Azure, using Azure PlayFab for player management, Azure Kubernetes Service (AKS) for dynamic session scaling, Azure Data Explorer for live analytics, and Azure Cache for Redis for session state. The PlayFab Party layer powers real-time voice and peer communications. This is one of the most publicly documented Azure game deployments and serves as Microsoft's reference architecture showcase for cloud-native multiplayer.
- **Session architecture: dedicated cloud servers.** Unlike the P2P-hosted model used by Deep Rock Galactic, Sea of Thieves runs authoritative dedicated server instances on Azure. The shared world state (ship positions, loot, enemy spawns) is server-owned. Players are migrated seamlessly between instances by the AKS orchestration layer when load balancing requires it — the "seam-crossing" is invisible to the player.
- **Server caps evolution.** At launch the server size was lower; a January 2022 update briefly set it to six ships / 16 players, then Rare walked back ship count to five to "allow for a wider variety of ship sizes per server" while maintaining the 16-player cap (per official @SoT_Support tweet). This public adjustment illustrates how server density is a tunable product decision, not just a technical constraint.
- **Automated gameplay testing from day one.** Rare built an automated QA system for gameplay features (GDC 2019 talk), running bot-driven sessions to catch regression in ship physics, treasure interactions, and multiplayer sync continuously.

## Why it matters

Sea of Thieves is the leading case study for **emergent co-op in a shared-world sandbox**: by hosting multiple crews on one server with no enforced teams, Rare created a social environment where every session is genuinely unpredictable. The Azure/PlayFab architecture is one of the most cited examples of cloud-native dedicated server scaling for a live-service game. The Tall Tales addition shows how structured quests can be layered into a sandbox without segregating it into a separate game mode.

## Relevance to Wayfinder

- **Dedicated servers vs. host-authoritative.** Sea of Thieves chose dedicated Azure servers to guarantee world-state authority — no one's PC is the truth. Wayfinder's [[Multiplayer Co-op]] design uses host-authoritative architecture with seed-identical dungeon generation, which avoids dedicated server costs but means the host's machine is the authority. The Sea of Thieves model is the aspirational upgrade path if Wayfinder needs to support larger or more persistent sessions.
- **Density as a design dial.** Rare's 5-ships/16-players cap and 15–30-minute encounter cadence were deliberate choices, not infrastructure limits. For Wayfinder's chart runs (private 2–4 player instances), the equivalent question is whether to ever allow open matchmaking that places stranger parties in the same dungeon seed — which would require similar density tuning.
- **Cosmetic-only progression removes power anxiety in co-op.** Sea of Thieves' refusal to gate power behind grind means any two players can meaningfully co-op. Wayfinder's [[Items and Gear]] and [[Trades and Leveling]] should consider what "power gap" between players feels like in a 2–4 player chart run — SoT argues the answer is: don't have one.

## See also

- [[Game Index]] · [[Game Studies]]
- [[Design Influences]] · [[MMO Lessons for Wayfinder]] · [[MMO Server Architecture]] · [[MMO Netcode and Tick Systems]]
- [[Monster Hunter World]] · [[Deep Rock Galactic]] · [[Helldivers 2]] · [[It Takes Two]]
- [[Multiplayer Co-op]] · [[Combat]] · [[Bosses]] · [[Chart Loop]] · [[Items and Gear]]

## Sources

- https://en.wikipedia.org/wiki/Sea_of_Thieves
- https://www.pcgamingwiki.com/wiki/Sea_of_Thieves
- https://learn.microsoft.com/en-us/shows/azure-videos/sea-of-thieves
- https://x.com/SoT_Support/status/1484530730638225417
- https://gamerant.com/sea-of-thieves-ships-per-server-count/
- https://www.clrn.org/how-many-people-in-a-sea-of-thieves-server/
