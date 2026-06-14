---
type: game
tags: [game-study, co-op, fps, pve, procedural-generation, class-roles, extraction-shooter]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Deep_Rock_Galactic
  - https://www.pcgamesn.com/deep-rock-galactic/deep-rock-galactic-unreal-engine-4
  - https://deeprockgalactic.wiki.gg/wiki/Multiplayer
  - https://devtrackers.gg/deep-rock-galactic/p/17551c7b-host-migration-should-be-mandatory-for-any-game-with-peer-to-peer-connections
  - https://progameguides.com/deep-rock-galactic/all-deep-rock-galactic-classes-explained/
---
# Deep Rock Galactic

Co-op PvE FPS (2020 full release, Ghost Ship Games) — "Rock and stone" battle-cry game where 1–4 space dwarves descend into procedurally carved alien caves, each filling a hard-locked class role, to mine minerals and fight bugs before a timed extraction.

## Design

- **Four hard-locked classes with non-overlapping tools.** Scout (grappling hook + flare gun, illumination and vertical mobility), Driller (power drill + flamethrower, opens routes through any surface and clears packed swarms), Engineer (platform gun + turrets, creates safe firing positions and bridges gaps), Gunner (minigun + zipline, raw suppression + team mobility). Each class provides something the others cannot: the squad is mechanically incomplete without every role represented.
- **The descent-and-extraction loop.** Every mission follows the same skeleton: drop pod → mine/kill objective → reach extraction pod within a countdown. The looping structure is deliberately repetitive at the macro level so that procedural variety can do all the work at the micro level. No two cave layouts, mineral placements, or enemy swarms are identical.
- **Procedural mesh-carved caves.** CTO Henrik Edwards developed a "true mesh-carving" approach using UE4 static meshes as the base geometry unit — not a block grid. Lead programmer Jonas Møller layered a semi-procedural system on top: designers hand-craft simple room templates; the engine populates cavern networks with procedural detail. Geography directly sets mission difficulty — deeper caves have fewer escape routes. Flat shading emerged as a byproduct of the mesh pipeline's lack of smoothing; Ghost Ship made it a style rule.
- **Class interdependence as depth.** A solo Scout can complete a mission but will struggle without Engineer's platforms for unreachable minerals or Driller's shortcuts during emergency retreats. The game rewards a group that communicates over one that min-maxes individual DPS.
- **Cosmetic-only progression.** Unlock tiers and overclocks change play style but not raw power level. Veterans and new players can run the same hazard together without the new player being a liability due to gear, only skill.
- **"Rock and Stone" as social glue.** The in-game salute/callout became the game's cultural identifier — a zero-cost social ritual that reinforces team identity without UI systems.

## Implementation

- **Engine:** Unreal Engine 4. The UE4 networking stack provided "really solid character control that is networked" (CTO Henrik Edwards), letting Ghost Ship focus on gameplay rather than low-level netcode. The mesh-carving system is custom, built on top of UE4's static mesh and destructible mesh systems.
- **P2P host-authoritative, no dedicated game servers.** One player's machine hosts the session; up to three others connect as clients. The host controls mission selection, hazard level, and join permissions (open/friends-only/password). Client latency is directly dependent on the host's upstream bandwidth — a known pain point the community raised repeatedly.
- **No host migration.** If the host disconnects, the session ends and the mission progress is lost. Ghost Ship acknowledged this as a significant gap compared to industry norms and it remains one of the game's most-requested features as of 2026.
- **Matchmaking via server browser + platform APIs.** Players find sessions through an in-game browser (filterable by mission type and hazard level), a Quick Join terminal, or direct invites via Steam overlay / Discord Rich Presence. The game relies on Steam and console platform backends for the actual relay/NAT traversal.
- **Session size: 1–4 players.** Solo play is fully supported with no difficulty penalty (only cosmetic changes like slightly fewer enemy waves). This is unusual in the class-role genre and lowers the entry barrier significantly.

## Why it matters

Deep Rock Galactic is the reference implementation for **hard-locked class roles** in co-op PvE: when every class provides a unique, non-substitutable capability, the squad composition itself becomes a design variable. The procedural cave system proved that a relatively small studio could generate replayable environments without hand-crafting every run, as long as the generation logic respects mission-type constraints and difficulty scaling.

## Relevance to Wayfinder

- **Class interdependence without locking players out.** Wayfinder's 2–4 player [[Multiplayer Co-op]] design should consider whether roles are soft (any player can gather/fight) or hard (certain tasks require specific Trades). DRG shows that hard locks create genuine co-op depth but demand session-filling UX. A middle path: soft roles where Wayfinder Trades give strong bonuses to certain chart-run tasks (Earthcrafter clears obstacles, Wildcrafter tracks rare spawns) without making solo unviable.
- **Procedural caves, mission-type contracts.** DRG's biome templates + procedural population is a close analogue to Wayfinder's [[Dungeon Generation]]: the chart (affix set) is the template; the seed provides procedural variation. The lesson is to constrain generation tightly per mission type so the procedural layer feels meaningful, not random.
- **Extraction as session structure.** The timed-extraction finale creates a natural session climax without a boss fight on every run. Wayfinder's chart runs could use a similar "hold the extraction point" beat as a [[Combat]] endcap, distinct from boss encounters.

## See also

- [[Game Index]] · [[Game Studies]]
- [[Design Influences]] · [[MMO Lessons for Wayfinder]]
- [[Monster Hunter World]] · [[Helldivers 2]] · [[Sea of Thieves]] · [[It Takes Two]]
- [[Multiplayer Co-op]] · [[Combat]] · [[Bosses]] · [[Dungeon Generation]] · [[Chart Loop]]

## Sources

- https://en.wikipedia.org/wiki/Deep_Rock_Galactic
- https://www.pcgamesn.com/deep-rock-galactic/deep-rock-galactic-unreal-engine-4
- https://deeprockgalactic.wiki.gg/wiki/Multiplayer
- https://devtrackers.gg/deep-rock-galactic/p/17551c7b-host-migration-should-be-mandatory-for-any-game-with-peer-to-peer-connections
- https://progameguides.com/deep-rock-galactic/all-deep-rock-galactic-classes-explained/
