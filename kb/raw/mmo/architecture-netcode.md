# Raw Provenance: MMO Architecture and Netcode
_Ingested: 2026-06-13. Author: research agent. Feeds: [[MMO Server Architecture]], [[MMO Netcode and Tick Systems]]._

This file records raw facts, source URLs, and uncertainty flags from the web research session. It is the citation trail for the two wiki pages above.

---

## Source 1: Gabriel Gambetta — Client-Side Prediction Series
URL: https://www.gabrielgambetta.com/client-side-prediction-server-reconciliation.html  
URL: https://www.gabrielgambetta.com/entity-interpolation.html

**Facts extracted:**
- Client-side prediction algorithm: send input with sequence number → apply locally → store in buffer → on server reply, discard ACKed inputs → replay unACKed inputs on top of server state.
- Example latency: 100 ms RTT + 100 ms animation = 200 ms total delay without prediction.
- Example latency: 250 ms RTT scenario used to demonstrate reconciliation need.
- Interpolation: clients display remote entities 100 ms behind the most recent server snapshot (one update interval at 10 Hz).
- Interpolation detail: at t=1000 server state and t=1100 server state, client displays the t=900→t=1000 transition during the t=1000–1100 wall-clock window.
- Requirement: world must be deterministic (same input + same state = same output).

**Confidence: HIGH** — Gambetta's series is the canonical introductory reference, widely cited.

---

## Source 2: Glenn Fiedler / Gaffer On Games — Networked Physics (2004)
URL: https://gafferongames.com/post/networked_physics_2004/

**Facts extracted:**
- Server-authoritative model: "the true physics simulation runs on the server and the clients display an approximation."
- Transport: UDP (unreliable delivery); input timestamps on each packet let server ignore out-of-order packets.
- Client-side prediction "completely eliminates movement lag for the client."
- Position correction thresholds: >2 m → snap; <2 m → exponential smoothing at 10% per update.
- Client maintains circular buffer of moves for reconciliation replay.

**Confidence: HIGH** — Foundational industry reference; 20+ years of citation.

---

## Source 3: Glenn Fiedler / Gaffer On Games — Snapshot Interpolation
URL: https://gafferongames.com/post/snapshot_interpolation/

**Facts extracted:**
- Bandwidth at 60 pps, 900 entities: ~11.6 Mbit/s (225 bits per entity).
- Bandwidth at 10 pps: ~2 Mbit/s.
- Per-entity snapshot: 28.1 bytes (225 bits).
- Interpolation buffer: 3× send interval handles 2 consecutive lost packets (e.g., 300 ms at 10 pps).
- Hermite interpolation for smooth curves (uses velocity at endpoints).
- Slerp for orientation (spherical linear interpolation).
- Snapshots MUST use UDP — lost packets should be dropped, not retransmitted.
- Delta compression: server tracks per-client last-acknowledged snapshot, sends only changed fields.

**Confidence: HIGH**

---

## Source 4: Valve Developer Community — Source Multiplayer Networking
URL: https://developer.valvesoftware.com/wiki/Source_Multiplayer_Networking  
_(403 on fetch; facts from search snippet)_

**Facts extracted:**
- Source engine uses UDP-based delta snapshots.
- Client interpolation delay equals the snapshot interval.
- Lag compensation rewinds entity positions by client latency + interpolation delay.
- Rewind formula: `rewind_time = inputQueueDelay + interpolationBackTime + clientLatency − clientFiringDelay`.

**Confidence: MEDIUM-HIGH** — Valve is primary source; fetch was blocked but snippet cites official docs.

---

## Source 5: Valve Developer Community — Lag Compensation
URL: https://developer.valvesoftware.com/wiki/Lag_Compensation  
_(403 on fetch; facts from search snippet)_

**Facts extracted:**
- Server maintains ~1 second of position/animation history for lag compensation.
- Default: only player entities are rewound (not all entities).
- `CBasePlayer` does not implement lag compensation by default; derived classes must enable it.
- Lag compensation "takes a step back in time, on the server, and looks at the state of the world at the exact instant the user performed some action."

**Confidence: MEDIUM-HIGH** — Official Valve docs; fetch blocked.

---

## Source 6: OSRS Wiki — Game Tick
URL: https://oldschool.runescape.wiki/w/Game_tick

**Facts extracted:**
- Tick duration: exactly 600 ms (= 0.6 s), yielding 100 ticks/minute theoretical.
- Actual measured: 606–618 ms per tick depending on server load (World 302, high-pop worlds: 616–618 ms).
- Client-side UI tick rate: 20 ms (separate from server tick; handles menus, interface).
- Actions submitted during tick N begin execution at tick N+1 start.
- Servers can "miss" ticks, especially on high-population worlds.
- Tick manipulation meta: skilled players exploit tick boundary to multi-action within one server cycle.

**Confidence: HIGH** — Official game wiki with measured data.

---

## Source 7: WoW Classic / Wowisclassic.com — Spell Batching
URL: https://www.wowisclassic.com/en/news/spell-batching-classic-wow-confirmed/

**Facts extracted:**
- Vanilla WoW spell batch window: 400 ms (from 2004 launch through Warlords of Draenor, ~2014).
- All spell messages received within the same batch window processed simultaneously.
- Modern WoW (post-WoD): batch reduced to ~20 ms with improved hardware.
- WoW Classic deliberately re-introduced 400 ms batching for authenticity.
- Enables "simultaneous death" PvP interactions (both players hit each other and die in the same batch).

**Confidence: HIGH** — Blizzard confirmed spell batching in Classic announcement.

---

## Source 8: Edgegap — Game Server Tick Rate Explained
URL: https://edgegap.com/blog/game-server-tick-rate-explained-gameplay-precision-vs-infrastructure-cost

**Facts extracted:**
- VALORANT: 128 Hz; rebuilt Unreal networking; server frame time 2.34 ms (was 50 ms).
- CS2: 64 Hz + sub-tick microsecond event logging (avoids full 128 Hz overhead).
- Apex Legends: 20 Hz; Respawn: moving to 60 Hz saves 2 frames latency at 3× cost.
- Marathon: 60 Hz.
- Hunt: Showdown: 30 Hz.
- Minecraft: 20 Hz (50 ms).
- Halo Infinite: 60 Hz (4v4), 30 Hz (BTB 24-player).
- Doubling tick rate ≈ doubles CPU load and bandwidth.

**Confidence: HIGH** — Edgegap is a game server infrastructure vendor; data consistent with public announcements.

---

## Source 9: EVE University Wiki — Time Dilation
URL: https://wiki.eveuniversity.org/Time_dilation

**Facts extracted:**
- TiDi activates when a solar-system node is overloaded.
- Server load scales O(n²) with players on grid.
- TiDi speed range: Green (slight reduction) → Yellow (50%) → Red (low) → minimum 10% speed.
- At 10% TiDi: 1 second game time = 10 seconds real time.
- TiDi does not affect EVE Server Time, industry timers, or structure repair timers.
- Battle of B-R5RB (January 27, 2014): 7,548 unique players, 6,058 in system, peak 2,670 simultaneous. TiDi at 10% for ~21 hours.

**Confidence: HIGH** — Official EVE University wiki (player-maintained but extensively sourced from CCP data).

---

## Source 10: High Scalability — EVE Online Architecture
URL: https://highscalability.com/eve-online-architecture/

**Facts extracted:**
- 90–100 "SOL Blades" running 2 nodes each; "Proxy Blades" for connection routing.
- Stackless Python for both server and client game logic; cooperative tasklets (no kernel thread switching).
- SQL Server for data; blade servers with SSDs.
- Infiniband interconnects planned for reduced inter-blade latency.
- ~40,000 concurrent users, ~300,000 active players.
- ~250 million transactions/day in the database.
- Dedicated blades for high-traffic systems (Jita, Motsu, Saila).

**Confidence: HIGH** — High Scalability is a reliable aggregator of engineering presentations.

---

## Source 11: Game Developer Magazine — Single-Shard Architecture
URL: https://www.gamedeveloper.com/design/infinite-space-an-argument-for-single-sharded-architecture-in-mmos

**Facts extracted:**
- EVE's single central relational DB; all logic via stored procedures; no triggers or cascading FKs.
- "Players are the content" — single-shard enables emergent economy and social permanence.
- "The Great War" (2005+): wars involving tens of thousands of players across several years.
- Jita capacity improved from ~600 to ~1,200 concurrent players via 64-bit servers + StacklessIO + hardware (100% improvement in under 6 months).
- Single-shard advantage: no cross-shard character transfers, no replication complexity.
- Single-shard challenge: unpredictable player clustering creates O(n²) load spikes.

**Confidence: HIGH** — Game Developer Magazine (formerly Gamasutra) is a primary industry publication.

---

## Source 12: PRDeving — MMO Architecture Series
URL: https://prdeving.wordpress.com/2023/09/29/mmo-architecture-source-of-truth-dataflows-i-o-bottlenecks-and-how-to-solve-them/  
URL: https://prdeving.wordpress.com/2023/10/13/mmo-architecture-client-connections-sockets-threads-and-connection-oriented-servers/

**Facts extracted:**
- "The source of truth of your game world IS NOT the database." In-memory state service is authoritative.
- Persistence strategy: position snapshots every ~30 s; inventory changes immediately; zone transitions immediately.
- CAS (compare-and-swap) hash versioning for atomic DB writes.
- Redis pub/sub for multi-node state service synchronization.
- Connection threading: 30–100 connections per thread optimal; 40 threads × 200 clients = 4,000 concurrent.
- Frontend servers are stateless (horizontally scalable); game servers are stateful (partition-scaled).
- Single-threaded data service eliminates race conditions.

**Confidence: MEDIUM-HIGH** — Engineering blog; practical advice consistent with industry norms, but not a primary source from a named shipping MMO.

---

## Source 13: Guild Wars 2 Wiki — Megaserver System
URL: https://wiki.guildwars2.com/wiki/Introducing_the_Megaserver_System  
URL: https://www.guildwars2.com/en/news/introducing-the-megaserver-system/

**Facts extracted:**
- Rolled out April 2014.
- Megaserver replaced "overflow" mechanic.
- System description: "weighted load balancer for players" — scores each map instance by affinity (party, guild, language, home world, play history).
- Player placed in highest-scoring instance.
- New map instances spawned dynamically when population exceeds threshold.
- GW2 per-map threshold: ~150 players (from Alexander Bakharev's MMO article, consistent with community reporting; UNCERTAIN — ArenaNet has not published the exact number).
- No more realm-locked instances; all players in a region share one population pool.

**Confidence: HIGH for mechanism; MEDIUM for ~150 player threshold** — ArenaNet official announcement for mechanism; threshold is community-reported.

---

## Source 14: WoW Layering / Sharding / Phasing (Wowpedia + Blizzard Forums)
URLs:  
https://wowpedia.fandom.com/wiki/Layering  
https://us.forums.blizzard.com/en/wow/t/sharding-vs-layering/173062  
https://eu.forums.blizzard.com/en/wow/t/sharding-phasing-and-layering/376939

**Facts extracted:**
- **Sharding**: zone-level; auto-creates parallel copies of a zone when population exceeds threshold; transparent to player; each shard has its own NPC/node respawns. Introduced Warlords of Draenor.
- **Layering**: realm-wide sharding; all outdoor zones duplicated simultaneously. Used at WoW Classic (2019) launch for overcrowding; removed once populations stabilized.
- **Phasing**: quest/story progress determines which "phase" of the world a player sees. Players in different phases cannot interact. Introduced Wrath of the Lich King (2008). Not a population tool.
- **Cross-Realm Zones (CRZ)**: inverse of sharding; merges underpopulated zones across realms. Introduced Mists of Pandaria (2012).

**Confidence: HIGH** — Wowpedia is the authoritative WoW technical reference.

---

## Source 15: Alexander Bakharev — "So You Want to Build an MMO" (Medium)
URL: https://medium.com/@alexander.bakharev_16063/so-you-want-to-build-an-mmo-8-18-world-design-level-architecture-c07798d17f1c

**Facts extracted:**
- Seamless world tech (WoW): sharding + phasing + CRZ used in combination.
- Black Desert Online: zero loading screens via hierarchical level subdivision, proxy loading, impostor rendering.
- FFXIV: discrete zones with loading screens; per-zone optimization possible.
- GW2: megaserver with ~150-player per-map cap, dynamic new instances.
- Star Citizen Alpha 4.0: static server meshing supporting 500 players/shard across two solar systems.
- Star Citizen Expanded Server Mesh: dynamic splitting and merging by density (in development; race conditions and client handoffs are open problems).
- WoW sharding origin: "former engineer spent three days creating the sharding solution during Warlords of Draenor's launch crisis."

**Confidence: HIGH for established games; MEDIUM for Star Citizen (rapidly evolving project).**

---

## Source 16: SnapNet — Netcode Architectures Part 3
URL: https://snapnet.dev/blog/netcode-architectures-part-3-snapshot-interpolation/

**Facts extracted:**
- Snapshot interpolation vs. lockstep: no input delay required (unlike lockstep, which needs max-RTT input delay).
- Snapshot interpolation vs. rollback: less CPU (clients don't re-simulate most objects).
- Packet generation scales O(N²) with player count: 4 players → 16 object deltas; 8 players → 64 (4× increase for 2× players).
- Backwards reconciliation: server rewinds interpolated object states to match the client's visual moment when evaluating hits.
- Risk: at high latency, players feel "shot behind cover" — rewound state on server has target still exposed after client perceives cover.
- Apex Legends, CoD, CS use snapshot interpolation + prediction model.
- Rocket League abandoned snapshot interpolation for rollback (physics-heavy direct interaction requires rollback).

**Confidence: HIGH** — SnapNet is a dedicated netcode reference site.

---

## Source 17: Anti-Cheat and Listen Server
URL: https://discussions.unity.com/t/how-exactly-can-players-cheat-when-there-is-no-dedicated-server/904099  
URL: https://www.liquidweb.com/help-docs/hosting-services/dedicated-servers/dedicated-vs-listen-server/

**Facts extracted:**
- Listen-server host has access to all world state (positions of all entities including hidden ones).
- Malicious host can block anti-cheat software from loading in their session.
- Dedicated servers recommended for competitive games; listen-server appropriate for small trusted groups (<12 players).
- Cheats (fly hack, speed hack, teleport) can be prevented by giving authoritative server control over position.

**Confidence: HIGH** — Well-documented industry consensus.

---

## Uncertainty register

| Claim | Confidence | Note |
|---|---|---|
| GW2 ~150 player/map cap | MEDIUM | Community-reported; ArenaNet not published |
| Valve 1 s rewind history | MEDIUM-HIGH | From search snippet of official docs; direct fetch blocked |
| Star Citizen server meshing player counts | MEDIUM | Evolving project; Alpha 4.0 = 2024 state |
| WoW Classic spell batch = 400 ms | HIGH | Blizzard-confirmed |
| WoW Modern spell batch = ~20 ms | MEDIUM-HIGH | From search snippet; not from primary source |
| Apex 20 Hz | HIGH | Respawn publicly confirmed in tech blog |
| VALORANT 128 Hz, 2.34 ms frame time | HIGH | Riot published official engineering post |
