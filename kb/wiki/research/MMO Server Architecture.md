---
type: concept
tags: [mmo-research, implementation, server-architecture, networking, interest-management, sharding, scaling]
status: draft
updated: 2026-06-13
sources:
  - https://www.gamedeveloper.com/design/infinite-space-an-argument-for-single-sharded-architecture-in-mmos
  - https://highscalability.com/eve-online-architecture/
  - https://wiki.eveuniversity.org/Time_dilation
  - https://prdeving.wordpress.com/2023/09/29/mmo-architecture-source-of-truth-dataflows-i-o-bottlenecks-and-how-to-solve-them/
  - https://prdeving.wordpress.com/2023/10/13/mmo-architecture-client-connections-sockets-threads-and-connection-oriented-servers/
  - https://medium.com/@alexander.bakharev_16063/so-you-want-to-build-an-mmo-8-18-world-design-level-architecture-c07798d17f1c
  - https://wiki.guildwars2.com/wiki/Introducing_the_Megaserver_System
  - https://wowpedia.fandom.com/wiki/Layering
  - https://wowpedia.fandom.com/wiki/Phasing
---

# MMO Server Architecture

The totality of server-side systems — login, world, zone, and database tiers — that keep an authoritative game world consistent across thousands of concurrent clients.

## The Authoritative-Server Model

In every production MMO, a **server-authoritative** model is the non-negotiable foundation: the server is the sole source of truth for the game world. Clients submit *intent* (inputs, actions) and receive *state* (positions, health, events) back. The server validates all actions, runs physics/AI, and adjudicates conflicts.

The corollary: the database is **not** the source of truth. With 1,000 concurrent players each updating positions once per second, treating the DB as authoritative would require unsustainable write volumes. Instead, authoritative state lives **in memory** inside the game server process. The DB is a persistence layer — checkpointed at intervals, on inventory changes, and at zone transitions (roughly every 30 s for position, immediately for item ownership). A compare-and-swap (CAS) hash-versioning scheme is standard to prevent race conditions on concurrent writes.

## Server Tier Separation

A classical MMO server cluster separates concerns into three tiers:

| Tier | Responsibility |
|---|---|
| **Login Server** | Authenticates credentials, issues a session token, returns character list and the world server to connect to. Stateless; horizontally scalable. |
| **World Server** | Holds the global player roster, cross-zone chat, auction/economy state, guild/friend data, and zone directory. Players connect here after login to receive a zone server address. |
| **Zone Server** | Runs the actual game simulation for one geographic region: AI, collision, combat, loot, NPC schedules. Maintains in-memory state for all entities in the zone. |

Frontend (login/world) servers are nearly stateless and can scale horizontally behind a load balancer. Zone servers are stateful and CPU-intensive; scaling them is the central hard problem.

## Realms, Shards, and the Vocabulary

These five terms are routinely confused. Precise definitions:

### Realm (or Server)
A **realm** is a fully independent copy of the entire game world running on dedicated hardware, with its own character database. Players on different realms cannot interact. This is the original WoW, EverQuest, and FFXIV model (e.g., WoW's "Stormrage" vs "Area 52"). Each realm has a population cap; at capacity a new realm is provisioned. Cross-realm play requires explicit "cross-realm zones" or server transfers.

### Shard
A **shard** is a dynamic, transparent copy of a *zone* or *area* created automatically when population exceeds a threshold. Unlike realms, shards are invisible infrastructure — the player never chooses a shard. When a zone fills, a new shard of that zone is spawned; players entering the area are distributed across shards. WoW introduced this during the Warlords of Draenor launch (2014) as a crisis response. Players on different shards of the same zone cannot see each other.

> Precise definition: sharding = real-time zone-level replication for population management. Scope: one zone at a time.

### Layering
**Layering** is sharding applied at **realm-wide scope** — the entire outdoor world is duplicated. Used in WoW Classic (2019) at launch: the whole world had Layer 1, Layer 2, etc. Each layer has its own NPC respawns, herb nodes, and rare spawns. Players on different layers cannot see each other across the whole game. Layering was removed from WoW Classic once server populations stabilized, because it undermined the intended social density.

> Precise definition: layering = realm-wide version of sharding. Scope: all zones simultaneously.

### Phasing
**Phasing** is a *narrative* / *progression* tool, not a population management tool. The world appears differently based on the player's quest progress. A player who has completed the quest "Burn the Village" sees the village on fire; a player who hasn't sees it intact. Players in different phases of the same area cannot see or interact with each other even if occupying the same physical space. WoW introduced phasing in Wrath of the Lich King (2008). Phasing is per-player (or per-quest-state), not per-population.

> Precise definition: phasing = divergent world state based on story progress. Scope: individual player.

### Cross-Realm Zones (CRZ)
The *inverse* of sharding — used when a zone is *under-populated*. The server merges players from multiple realms into the same zone instance so it feels alive. Introduced in WoW MoP (2012). CRZ is transparent; players see a tag on character names indicating their home realm.

### Instancing
**Instancing** creates a private or semi-private copy of a zone *on demand*, typically for group content (dungeons, raids). Each group gets its own instance; instances are destroyed when the group leaves or the session timer expires. All major MMOs use instancing for dungeons. It differs from sharding in that it is *intentional*, group-scoped, and content-gated (not a population safety valve).

### Megaserver
A **megaserver** eliminates fixed realms entirely. All players in a region share one logical world; a weighted load-balancer dynamically assigns incoming players to map instances. Guild Wars 2 (2014) is the canonical example: when a map instance fills (~150 players), the system spawns a new copy and routes players into the most "affinity-weighted" instance — factoring in party membership, guild affiliation, language, and play history. Players can find each other via the social graph rather than realm selection. FFXIV's data-center travel (patch 6.18, 2022) is a softer megaserver variant: characters can visit any world in their region with restricted activity permissions.

| Mechanism | Scope | Trigger | Visibility to player |
|---|---|---|---|
| Realm | Whole game | Provisioning | Explicit (character-bound) |
| Shard | One zone | Population spike | Hidden |
| Layering | All zones | Population spike (launch) | Hidden |
| Phasing | Per-player space | Quest/story state | Implicit |
| CRZ | One zone | Under-population | Name tag |
| Instance | Group space | Group entry | Explicit portal |
| Megaserver | Map copy | Population + social graph | Weighted placement |

## Single-Shard Architecture

**EVE Online** (CCP Games) is the extreme outlier: all ~300,000 active players share a single cluster, *Tranquility*. Rather than shards, the universe is partitioned by solar system — each solar system is an independent server process on a dedicated blade. Jumping between systems transparently migrates the player's game session to the destination process.

Technical pillars:
- One central relational database binds the whole world; all game logic goes through stored procedures, no triggers.
- Stackless Python runs both server and client game logic, using lightweight cooperative tasklets instead of OS threads.
- **StacklessIO** (later addition) enabled ~1,000-player fleet fights where previously 500 caused severe lag.
- 90–100 blade servers ("SOL Blades") run 2 nodes each; "Proxy Blades" handle the public-facing connection tier.
- The database processes ~250 million transactions/day.

The Achilles heel is player clustering (the "Jita problem"): trade hubs and fleet battles create unpredictable O(n²) load spikes. EVE's engineering response is **Time Dilation (TiDi)**: when a node is overloaded, the server slows in-game time — reducing tick processing to as low as 10% of real time (i.e., 1 second of game time = 10 seconds of real time). This preserves simulation correctness at the cost of painful slowdown. The Battle of B-R5RB (January 2014) involved 7,548 unique players, 6,058 in a single system, with peak TiDi reducing time to 10% speed for 21 hours.

## Spatial Partitioning and Interest Management (AoI)

The core scalability problem: with N entities, naïve broadcast produces O(N²) messages. Interest management (Area of Interest, AoI) reduces this by filtering which entities each client needs to know about.

**The question:** for each entity E, which other entities must E's client receive updates for?

Common implementations:

- **Fixed-cell grid:** The world is divided into cells of fixed size (e.g., 64×64 units). An entity's AoI is the 3×3 or 5×5 cell neighbourhood around it. Server maintains a spatial index: on every tick, for each entity, compute the set of entities in neighbouring cells and diff against the previously known set. Additions trigger `SPAWN` messages; removals trigger `DESPAWN`. Grid lookup is O(1) amortized, making this the most common production choice. MMOs typically use coordinate hashing for the index rather than a true quadtree, since grid construction and maintenance is cheaper than tree rebalancing for a highly dynamic scene.

- **Quadtree:** Recursively subdivides 2D space into four quadrants. Good for non-uniform density (sparse open fields, dense cities) but higher maintenance cost than fixed grids. Used in some physics engines but less common as the primary AoI structure in game servers.

- **Pub/Sub (topic-based):** Entities subscribe to channels corresponding to their current cells. State updates are published to the cell's channel; subscribers receive only what is relevant. This integrates cleanly with Redis pub/sub for multi-process architectures.

AoI solves both the O(N²) bandwidth problem and the downstream interest-management role in netcode (see [[MMO Netcode and Tick Systems]]).

## Zone Hand-Off

When a player crosses a zone boundary in a seamless world, the handoff sequence is:

1. Zone A's server detects the player crossing the border line.
2. Zone A serialises the player's in-memory state (position, stats, inventory, active buffs) and sends it to Zone B's server over the server-to-server link.
3. Zone B ACKs receipt; Zone A drops the player's session and closes the connection.
4. The client is redirected to Zone B's server address (some engines do this as a brief transparent reconnect; others like WoW use a loading screen as the cover).
5. Zone B spawns the player at the border position.

For seamless worlds (no loading screen), the handoff must complete in milliseconds. Two servers must briefly simulate the same player simultaneously in an overlap region to allow the transition to be imperceptible. Star Citizen's "server meshing" (Alpha 4.0, 2024) is the bleeding-edge take: static meshing splits solar systems across server nodes with explicit handoff, while dynamic meshing (in development) would split and merge load regions based on real-time density.

## Database Persistence and Save Models

| Pattern | Description | Used by |
|---|---|---|
| **Write-through** | Every state change immediately persisted | Rare at scale; too slow |
| **Write-behind (async)** | State changes queued; DB written asynchronously | Standard for most MMOs |
| **Checkpoint** | Full world snapshot at interval (e.g., 30 s position, immediately on item transfer) | EVE Online, PRDeving pattern |
| **Event sourcing** | Append-only event log; world state reconstructed from events | Rare in games; used in fintech |

FFXIV uses discrete zone architecture allowing per-zone DB sharding. EVE uses one central DB with stored procedures only (no cascading FKs, no triggers) for operational simplicity. The in-memory state service pattern (PRDeving) recommends Redis pub/sub to synchronize multiple state service nodes, with a single-threaded data service to eliminate race conditions.

## Scaling Strategies

**Vertical scaling** (bigger box) has historically dominated zone servers — CCP upgrades to 64-bit blades, SSDs, and Infiniband interconnects. Diminishing returns hit at the O(n²) boundary.

**Horizontal scaling** applies cleanly to stateless tiers (login, proxy). For stateful game servers, horizontal scaling requires partitioning: either geographic (each zone server owns a region) or instancing (each instance server owns a content pocket).

**Cloud/containerisation trends:** The advent of game-server-as-a-service platforms (Edgegap, Multiplay, Agones on Kubernetes) allows zone servers to be spun up as containers on demand. Agones manages Kubernetes pods as dedicated game server processes — allowing 50 ms spin-up time vs. bare-metal provisioning hours. The tradeoff is containerisation overhead (~10 ms jitter vs. bare-metal) and hypervisor scheduling latency on shared cloud hardware.

## Relevance to Wayfinder

[[Multiplayer Co-op]] uses a **listen-server** (host-authoritative) model — one of the four players acts as the authoritative server. This is the smallest possible slice of the MMO server hierarchy: a single zone server that also doubles as a client. Key correspondences:

- The host process is Wayfinder's "zone server" — it runs all enemies, damage, loot rolls, and chart-loop state.
- There is no login server, world server, or database tier for co-op state. Each peer keeps their own [[Save System]] file; guests never write the host's save.
- Interest management is implicit and trivially cheap at 2–4 players (all entities are always relevant to all peers). At scale the 10 Hz batched enemy snapshot (`_enemy_state` RPC) serves the same function as AoI-filtered zone updates.
- The seed-identical dungeon layout (from `layout_loader._rng` seeded off the chart seed) is Wayfinder's substitute for zone-hand-off: rather than migrating state, all peers build the same world locally from the same seed — a deterministic alternative to state streaming.

If Wayfinder ever moved to dedicated servers or supported larger parties, the first structural upgrade would be to separate the NetGame session manager into a dedicated process (the "world server" role) and evaluate AoI grids for enemy-snapshot routing.

## See also

- [[MMO Netcode and Tick Systems]] — the game loop, tick rates, and replication mechanics that run on top of this architecture
- [[Multiplayer Co-op]] — Wayfinder's listen-server implementation
- [[Save System]] — per-peer persistence; each guest keeps their own save
- [[Dungeon Generation]] — seed-identical geometry replaces zone state transfer
- [[MMO Research]] — survey index
- [[EVE Online]] — single-shard architecture deep-dive
- [[World of Warcraft]] — sharding, layering, phasing, CRZ in one game
- [[Final Fantasy XIV]] — discrete-zone model and data-center travel
- [[RuneScape]] — deterministic tick loop
- [[MMO Lessons for Wayfinder]] — distilled takeaways

## Sources

- Game Developer Magazine: "Infinite Space: An Argument for Single-Sharded Architecture in MMOs" — https://www.gamedeveloper.com/design/infinite-space-an-argument-for-single-sharded-architecture-in-mmos
- High Scalability: "EVE Online Architecture" — https://highscalability.com/eve-online-architecture/
- EVE University Wiki: "Time Dilation" — https://wiki.eveuniversity.org/Time_dilation
- PRDeving: "MMO Architecture: Source of Truth, Dataflows, I/O Bottlenecks" — https://prdeving.wordpress.com/2023/09/29/mmo-architecture-source-of-truth-dataflows-i-o-bottlenecks-and-how-to-solve-them/
- PRDeving: "MMO Architecture: Client Connections, Sockets, Threads" — https://prdeving.wordpress.com/2023/10/13/mmo-architecture-client-connections-sockets-threads-and-connection-oriented-servers/
- Alexander Bakharev: "So You Want to Build an MMO 8/18 — World Design & Level Architecture" — https://medium.com/@alexander.bakharev_16063/so-you-want-to-build-an-mmo-8-18-world-design-level-architecture-c07798d17f1c
- Guild Wars 2 Wiki: "Introducing the Megaserver System" — https://wiki.guildwars2.com/wiki/Introducing_the_Megaserver_System
- Wowpedia: "Layering" — https://wowpedia.fandom.com/wiki/Layering
- Wowpedia: "Phasing" — https://wowpedia.fandom.com/wiki/Phasing
- Wikipedia: "Battle of B-R5RB" — https://en.wikipedia.org/wiki/Battle_of_B-R5RB
- Edgegap: "Game Server Tick Rate Explained" — https://edgegap.com/blog/game-server-tick-rate-explained-gameplay-precision-vs-infrastructure-cost
