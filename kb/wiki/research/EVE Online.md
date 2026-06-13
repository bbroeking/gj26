---
type: concept
tags: [mmo-research, single-shard, server-architecture, economy, pvp, emergent-gameplay, networking, case-study]
status: draft
updated: 2026-06-13
sources:
  - https://highscalability.com/eve-online-architecture/
  - https://www.eveonline.com/news/view/stacklessio-or-how-we-reduced-lag
  - https://www.eveonline.com/news/view/carbonio-and-bluenet-next-level-network-technology-1
  - https://www.eveonline.com/news/view/introducing-time-dilation-tidi
  - https://www.eveonline.com/news/view/time-dilation-hows-that-going
  - https://www.eveonline.com/news/view/the-bloodbath-of-b-r5rb
  - https://wiki.eveuniversity.org/Time_dilation
  - https://www.gamedeveloper.com/design/infinite-space-an-argument-for-single-sharded-architecture-in-mmos
  - https://www.gamedeveloper.com/game-platforms/feature-ccp-outlines-single-shard-mmo-development
  - https://community.eveonline.com/news/news-channels/press-releases/eve-online-appoints-in-world-economist-1/
  - https://support.eveonline.com/hc/en-us/articles/14141550499612-ISK-and-PLEX
  - https://support.eveonline.com/hc/en-us/articles/203217062-Skill-Training
  - https://www.gdcvault.com/play/1014031/The-Server-Technology-of-EVE
---

# EVE Online

A massively multiplayer online game developed by CCP Games (launched 2003) set in the New Eden universe — one of the longest-running examples of a **true single-shard MMO**, where all players worldwide share one persistent server cluster called **Tranquility**.

EVE is the primary case study for single-shard architecture, player-driven emergent politics, and adaptive server-load management (Time Dilation). It contrasts directly with the instanced themepark model exemplified by [[Final Fantasy XIV]].

---

## Single-Shard Universe

Unlike nearly every other large-scale MMO, EVE does not split its player population across regional shards or separate servers. One universe, one economy, one ruleset — all ~300K active accounts share Tranquility.

**CCP's stated position:** "A single shard should be the natural choice of any MMO developer." The argument is that players _are_ the content. Emergent wars, trade empires, and political intrigue require critical mass achievable only in a unified population. Sharding fractures social graphs and economies into small ponds where individual manipulation is easy and macro-scale events are impossible.

New Eden contains ~7,800 star systems organized into regions, constellations, and systems. Security status determines rules:

- **High-sec** — CONCORD police; PvP limited to consensual war declarations and crime flagging.
- **Low-sec** — reduced NPC police response; gate guns present.
- **Null-sec** — fully lawless; player alliances claim sovereignty through Territorial Claim Units (TCUs) and Infrastructure Hubs.
- **Wormhole space** — randomly connected systems with no local intel channel; no sovereignty.

The entire map is one contiguous simulation; a player in Jita (the main trade hub, high-sec) and a player fighting in a null-sec sov war five jumps away occupy the same server cluster at the same moment.

---

## Cluster Architecture

### Node Types

Tranquility runs on three blade tiers:

| Tier | Role |
|---|---|
| **Proxy Blades** | Public-facing entry point; handle player TLS connections, route packets inbound/outbound |
| **SOL (Simulation) Blades** | ~90–100 blades; each runs 2 nodes; a **node** = one EVE server process pinned to one CPU core |
| **Database Cluster** | Persistence layer; SQL Server; SSD-backed; single relational DB for the entire universe |

The smallest unit of simulation is a **solar system**: every system in New Eden is assigned to a node, and a single node may host dozens of low-traffic systems simultaneously.

High-traffic systems receive dedicated hardware:
- Jita, Motsu, and Saila historically ran on dedicated SOL blades where the second node slot is reserved (idle), giving the entire blade's resources to one system.
- Corporation directors could petition CCP 24 hours in advance to stage fleet-fight systems on **reinforced nodes** — blades with double cores and faster RAM — for anticipated large engagements.

### Scaling Limits Per Node

Hardware has evolved significantly, but the architectural constraint is the **single-core-per-node** model:

- AMD Opteron era: ~450–700 concurrent players before node failures.
- Intel Xeon upgrade: ~1,200 concurrent before issues.
- The O(n²) scaling of grid physics (every entity must calculate interactions with every other entity) makes large fleet fights catastrophic for single-core throughput.

### Single Database Design

CCP made a deliberate choice to keep one relational database rather than distributed shards:

- No triggers; no cascading foreign keys (for audit-trail transparency).
- "Read uncommitted" transaction isolation for performance on read-heavy queries.
- No cross-database character transfers needed; no replication lag between shards.
- The Yulai Problem: early in EVE's history players spontaneously formed a trade hub at Yulai. CCP redesigned the gate network and dedicated hardware to the new emergent hub (Jita), demonstrating that single-shard design requires operational flexibility rather than static capacity planning.

---

## Networking Stack Evolution

### Stackless Python

EVE's game logic runs on **Stackless Python** — a cooperative multitasking variant using lightweight tasklets rather than OS threads. Benefits:

- Distributed function calls that cross process boundaries (node-to-node across the cluster) look synchronous to the programmer.
- No GIL-contention from thousands of OS threads; tasklets are cheap and yield cooperatively.
- The same paradigm runs on both server and (historically) client, enabling code reuse.

### StacklessIO (2008)

The original network layer could delay packet delivery **up to 1–2 minutes** on heavily loaded nodes — module activations simply sat in queue. StacklessIO rewrote network I/O to run off-GIL in non-blocking threads:

- Jita capacity grew from ~800–900 peak to **1,400 concurrent** with improved responsiveness.
- Average cluster-wide ping fell ~3×; maximum ping fell ~2×; standard deviation ~2×.
- Proxy server memory usage dropped 50%.

Source: https://www.eveonline.com/news/view/stacklessio-or-how-we-reduced-lag

### CarbonIO + BlueNet (post-2012)

A full rewrite of StacklessIO to push even more work outside the Python GIL:

- **CarbonIO:** issues `WSARecv()` on connection; decrypts, decompresses, parses in concurrent C++ thread pools; queues data awaiting Python. Sends are also async — Python hands data to a worker thread and continues immediately.
- **BlueNet:** a C++ routing layer maintaining a read-only copy of the Machonet packet-routing table, using an 8–10 byte out-of-band header to route most traffic without touching Python at all.
- Results: measurable per-user CPU drops on proxy; Sol node CPU improved 8–10%; bottleneck shifted from network to single-core simulation.

Source: https://www.eveonline.com/news/view/carbonio-and-bluenet-next-level-network-technology-1

---

## Time Dilation (TiDi)

Time Dilation is EVE's adaptive server-load governor. Introduced in early 2012 after years of catastrophic fleet-fight node crashes, it is the single most important engineering feature that made large-scale PvP viable.

### Mechanism

When a node's tasklet queue backs up (load spikes), TiDi **slows the in-game clock** proportionally:

- The system can run at any integer percentage from 100% down to **10%**.
- At 10% TiDi: one real second = ten simulated seconds. Known as "90% TiDi" (90% reduction).
- The server targets a "very small queue of waiting tasklets"; when load clears, it raises the clock back toward 100%.
- Fine-grained: the server may run at 98% if only slightly overloaded. This is imperceptible to players.

Load scales at **O(n²)** relative to players on grid (each entity must check interactions against all others), so doubling fleet size roughly quadruples node load.

### What TiDi Affects / Does Not Affect

| Affected | Not Affected |
|---|---|
| All in-space actions (firing, movement, warping) | EVE Server Time (wall clock) |
| Module cycle times | Skill training |
| Drone deployment | Industry job timers |
| Fleet warp | Upwell structure repair timers |

### Fleet Fight Profile (CCP data)

During a simulated 1,600-pilot fight, TiDi progression:

1. Warp-in spike: ~5% speed
2. Active combat: stabilises ~30%
3. Casualties mount, fewer entities on grid: ~60%
4. Retreat wave: ~10% (another spike)
5. Post-fight: returns to 100%

### Benchmark: Battle of B-R5RB (2014-01-27)

The largest recorded EVE battle at the time of writing; the stress test that proved TiDi's production limits:

| Metric | Value |
|---|---|
| Unique characters involved | 7,548 |
| Peak simultaneous in system | 2,670 |
| Real-time duration | 21 hours |
| Simulated game time | ~2 hours (≈10% TiDi throughout) |
| Titans destroyed | 75 |
| ISK destroyed | 11 trillion |
| USD estimated equivalent | $300,000–$330,000 |

No node crash. Module delays held under seconds. Pre-TiDi, 1,300-pilot fights routinely produced 20–600 second module delays and frequent node death.

Source: https://www.eveonline.com/news/view/the-bloodbath-of-b-r5rb

---

## Player-Driven Economy

EVE's economy is fully player-driven and operates as a single unified market spanning New Eden. CCP employs professional economists to monitor and publish quarterly economic reports — the first MMO to do so.

### Key Figures

- **Dr. Eyjólfur Guðmundsson** — Lead Economist from ~2007; described his role as "a research scientist for a central bank."
- Near half a quadrillion ISK (Interstellar Kredits) traded daily at the market's peak.

### ISK and PLEX

- **ISK** — the sole primary currency; earned through mining, manufacturing, combat bounties, trading, and exploration.
- **PLEX (Pilot's License Extension)** — introduced 2008; a tradeable in-game item redeemable for 30 days of Omega (subscriber) status. A wealthy player with limited time can buy PLEX with real money and sell it for ISK. A time-rich player can grind ISK and buy PLEX to play subscription-free. This creates a legal, CCP-sanctioned link between real and virtual economies.
- PLEX price in ISK fluctuates by supply/demand — a real economic signal watched by the community.

### Manufacturing and Logistics

The full production chain is player-operated: mining raw ores → refining → component manufacturing → ship assembly → transport → market listing → consumption. No NPC vendor sells endgame ships; they exist only because players built them. This makes logistics and industrial alliances a required pillar of null-sec warfare.

---

## Skill Training

EVE uses **passive, real-time skill training** as its progression mechanic:

- Skills train continuously whether the player is logged in or offline (server-side clock).
- Up to **150 skills** can be queued.
- Omega Clone (subscriber) status: 2× training speed, access to advanced skills and capital-class ships.
- Alpha Clone (free-to-play): limited skill list, 1× speed, smaller ship classes.

Design implications:

- No grind required to advance; encourages long-term retention.
- Creates an irreversible time-investment: characters become more valuable the longer they exist, discouraging account deletion.
- New players cannot catch up in raw skill points but can fill specialized niches in days (e.g., logistics pilots, tacklers, scouts) — fleet doctrine design exploits this.
- Monetization pressure: PLEX purchases can buy Skill Injectors to fast-track specific skills (added later, contentious but CCP-monitored for inflation impact).

---

## Full-Loot PvP and Emergent Politics

### Full Loot

In null-sec and wormhole space, all cargo and fitted modules drop on death — a total loss. This creates genuine stakes:

- "Don't fly what you can't afford to lose" is the game's first lesson.
- Loss generates demand, which sustains the manufacturing economy. Destroyed ships must be replaced; the cycle funds industrial alliances.
- Asymmetric risk between rich veteran players and new recruits is a design tension CCP manages through corp/alliance welfare systems (player-run ship replacement programs).

### Sovereignty and Politics

Null-sec space is organized into player-held empires. Alliances numbering thousands of members control territories, establish jump-gate networks, build citadels, and levy "taxes" on members' activities. Major power blocs include historical entities like Goonswarm Federation, TEST Alliance, and Pandemic Legion — names with decade-long histories of wars, betrayals, and political maneuvers.

Documented real-world parallels:
- **Embezzlement:** EVE's governance runs entirely on trust and reputation; corporation directors have stolen billions of ISK through social engineering — documented on the eve-online.com dev blog and IEEE Spectrum.
- **Espionage:** infiltrating enemy alliances to steal ship blueprints or leak strategic plans is a recognized profession.
- **Diplomatic treaties** with real-world enforcement mechanisms (forum posts, voice comms recordings).

CCP's explicit design stance: do not dictate how players use their tools; emergence requires freedom to build and to betray.

---

## GDC / Engineering References

- **"The Server Technology of EVE Online: How to Cope with 300,000 Players in One World"** — GDC Vault (https://www.gdcvault.com/play/1014031/The-Server-Technology-of-EVE). Covers the full cluster architecture, Stackless Python, and single-DB approach.
- **StacklessIO blog post** (2008): https://www.eveonline.com/news/view/stacklessio-or-how-we-reduced-lag
- **TiDi introduction** (2012): https://www.eveonline.com/news/view/introducing-time-dilation-tidi
- **CarbonIO/BlueNet** (post-2012): https://www.eveonline.com/news/view/carbonio-and-bluenet-next-level-network-technology-1

---

## Lessons for Wayfinder

EVE is architecture-as-content: the single shard is not just a technical choice but a design statement. Several patterns are transferable even at Wayfinder's far smaller co-op scale:

1. **Adaptive load management over hard capacity limits** — TiDi's graceful degradation (slow time rather than crash) is a model for handling host-node overload in co-op sessions. Rather than disconnecting players, a host-authoritative game could throttle simulation frequency transparently.
2. **Economy as a closed loop that generates its own demand** — EVE's full-loot PvP ensures constant crafting demand. Wayfinder's economy could adopt this via meaningful item loss on dungeon wipe (see [[Economy]], [[Chart Loop]]).
3. **Passive progression to retain non-daily players** — Real-time skill training means casual players still advance. Wayfinder's Trade XP accrues only during play; the contrast is worth noting if retention becomes a concern (see [[Trades and Leveling]]).
4. **Single database / no shard** — For a small co-op game this is trivially achievable; the lesson is to avoid premature sharding that fragments community (see [[Multiplayer Co-op]]).

---

## See Also

- [[Final Fantasy XIV]] — contrasting instanced themepark architecture
- [[MMO Research]] — survey index
- [[MMO Server Architecture]] — technical comparison across MMOs
- [[MMO Economy and Itemization]] — economy design patterns
- [[MMO Netcode and Tick Systems]] — tick rate and networking
- [[MMO Progression Systems]] — passive vs. active progression
- [[MMO Social and Endgame]] — emergent politics and endgame loops
- [[MMO Lessons for Wayfinder]] — applied takeaways
- [[Design Influences]] — Wayfinder's genre lineage
- [[Economy]] — Wayfinder's economy design
- [[Multiplayer Co-op]] — Wayfinder's co-op architecture
- [[Trades and Leveling]] — Wayfinder's progression system

---

## Sources

- CCP Official dev blog — StacklessIO: https://www.eveonline.com/news/view/stacklessio-or-how-we-reduced-lag
- CCP Official dev blog — TiDi introduction: https://www.eveonline.com/news/view/introducing-time-dilation-tidi
- CCP Official dev blog — TiDi retrospective: https://www.eveonline.com/news/view/time-dilation-hows-that-going
- CCP Official dev blog — CarbonIO/BlueNet: https://www.eveonline.com/news/view/carbonio-and-bluenet-next-level-network-technology-1
- CCP Official — Bloodbath of B-R5RB: https://www.eveonline.com/news/view/the-bloodbath-of-b-r5rb
- EVE University Wiki — Time Dilation: https://wiki.eveuniversity.org/Time_dilation
- High Scalability — EVE Online Architecture: https://highscalability.com/eve-online-architecture/
- Game Developer — Infinite Space (single-shard argument): https://www.gamedeveloper.com/design/infinite-space-an-argument-for-single-sharded-architecture-in-mmos
- Game Developer — CCP outlines single-shard dev: https://www.gamedeveloper.com/game-platforms/feature-ccp-outlines-single-shard-mmo-development
- GDC Vault — Server Technology of EVE Online: https://www.gdcvault.com/play/1014031/The-Server-Technology-of-EVE
- CCP Press Release — Lead Economist appointment: https://community.eveonline.com/news/news-channels/press-releases/eve-online-appoints-in-world-economist-1/
- CCP Support — ISK and PLEX: https://support.eveonline.com/hc/en-us/articles/14141550499612-ISK-and-PLEX
- CCP Support — Skill Training: https://support.eveonline.com/hc/en-us/articles/203217062-Skill-Training
