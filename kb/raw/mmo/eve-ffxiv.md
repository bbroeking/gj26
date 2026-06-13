# Raw Provenance — EVE Online & FFXIV Research

Fetched 2026-06-13. Facts + URLs for both games; feeds `wiki/research/EVE Online.md` and `wiki/research/Final Fantasy XIV.md`.

---

## EVE Online

### Single-Shard / Cluster Architecture

- **Source:** https://highscalability.com/eve-online-architecture/
  - Cluster: ~90–100 SOL blades, each running 2 nodes; a node = one EVE server process on one CPU core.
  - Three tiers: Proxy Blades (player-facing), SOL Blades (simulation), Database Cluster (persistence via SQL Server with SSDs).
  - High-traffic systems (Jita, Motsu, Saila) get dedicated SOL blades where the second node is idle.
  - Tranquility cluster supported ~300K active accounts, 40K concurrent, 250M daily transactions.
  - 64-bit upgrade enabled RAM headroom; prior 32-bit cap constrained high-density systems to ~600 concurrent.

- **Source:** https://www.gamedeveloper.com/design/infinite-space-an-argument-for-single-sharded-architecture-in-mmos
  - CCP position: "a single shard should be the natural choice of any MMO developer."
  - "Players are the content" — emergent wars require a single shared universe.
  - Single relational DB: no triggers, no cascading FK, "read uncommitted" queries for performance.
  - Yulai problem: spontaneous trade-hub formation forced map redesign; Jita became the new hub needing dedicated hardware.
  - SSD migration critical to remove DB I/O bottleneck.

- **Source:** https://www.gamedeveloper.com/game-platforms/feature-ccp-outlines-single-shard-mmo-development
  - Single DB eliminates cross-shard character transfers and replication complexity.
  - Solar systems, space stations, market regions, corporation services, and proxy services are all distributable units.

- **Source:** https://ng.cs.ucl.ac.uk/?p=101 (EVE Online Architecture, UCL)
  - Pre-reinforcement nodes: ~450–700 players before heartbeat failures (AMD Opteron era).
  - Intel Xeon blades sustained 1,200 concurrent before issues.
  - Corporation directors could petition CCP 24h in advance to pre-stage fleet-fight systems on reinforced nodes.

### StacklessIO / CarbonIO / BlueNet

- **Source:** https://www.eveonline.com/news/view/stacklessio-or-how-we-reduced-lag (launched Tranquility 2008-09-16)
  - StacklessIO replaced old network layer; old system could delay packets up to 1–2 minutes on loaded nodes.
  - Post-deployment: Jita sustained 1,400 concurrent (up from 800–900 cap) with improved responsiveness.
  - Average cluster ping ~3x lower; max ping ~2x lower; std-dev ~2x lower.
  - Proxy server memory dropped 50%.

- **Source:** https://www.eveonline.com/news/view/carbonio-and-bluenet-next-level-network-technology-1
  - CarbonIO: full rewrite of StacklessIO; handles data marshaling entirely outside Python's GIL.
  - Runs WSARecv() immediately on connection; decrypts/decompresses/parses via concurrent thread pools; queues for Python.
  - BlueNet: C++ routing layer that bypasses GIL using a read-only copy of Machonet routing structures + 8–10 byte out-of-band header.
  - Proxy CPU drop: dramatic overall reduction; Sol node CPU: 8–10% improvement.

- **Source:** https://www.eveonline.com/news/view/my-node-was-equipped-with-the-following...
  - Stackless Python for game logic enables "thread-based programming without conventional thread overhead."
  - Planned Infiniband interconnects for low-latency intra-cluster networking.

### Time Dilation (TiDi)

- **Source:** https://www.eveonline.com/news/view/introducing-time-dilation-tidi
  - TiDi slows the game clock to drain the server's tasklet queue; can run at any % (e.g., 98% if slightly overloaded).
  - During 1,600-pilot fight: ~5% at warp-in, stabilises ~30% mid-fight, ~60% as casualties mount, ~10% at retreat.
  - Hard lower limit exists; "no sense running at 0.1%" so players can still act.

- **Source:** https://wiki.eveuniversity.org/Time_dilation
  - Minimum speed: **10%** (one real second = ten game seconds); called "90% TiDi."
  - Load scales at O(n²) relative to players on grid.
  - Does NOT affect: EVE server time, industry jobs, skill training, Upwell repair timers.
  - Does affect: all in-space actions (combat, movement).

- **Source:** https://www.eveonline.com/news/view/time-dilation-hows-that-going
  - Launched early 2012; tested in F-9F6Q (1,300+ pilots, reinforced node) and 92D-OI (1,350+ pilots, normal node).
  - Module delay held under 1 second in both fights (pre-TiDi: delays of 20–600 seconds were common).
  - 12.87 hours total universe-wide TiDi accumulated in measured period; ~45 min/day average.

- **Source:** https://www.eveonline.com/news/view/the-bloodbath-of-b-r5rb (Battle of B-R5RB, 2014-01-27)
  - 7,548 unique characters; peak 2,670 simultaneous in B-R5RB.
  - 21 real-time hours; server ran only ~2 game-hours of simulation (≈10% TiDi throughout).
  - 75 Titans destroyed; ~$300–330K USD estimated losses; 11 trillion ISK.

### Economy

- **Source:** https://community.eveonline.com/news/news-channels/press-releases/eve-online-appoints-in-world-economist-1/
  - CCP hired Dr. Eyjólfur Guðmundsson as Lead Economist (first MMO to do so); role likened to "research scientist for a central bank."
  - ISK (Interstellar Kredits) is the primary currency; nearly half a quadrillion ISK traded per day.

- **Source:** https://support.eveonline.com/hc/en-us/articles/14141550499612-ISK-and-PLEX
  - PLEX (Pilot's License Extension) introduced 2008; tradeable on market; converts real money → ISK legally.
  - Price of PLEX in ISK fluctuates with supply/demand across all of New Eden (one market, one economy).

### Skill Training

- **Source:** https://support.eveonline.com/hc/en-us/articles/203217062-Skill-Training
  - Skills train in real time whether logged in or offline; up to 150 skills in queue.
  - Omega Clone: 2× speed, access to advanced skills and larger ships.
  - No active gameplay required to advance skill level.

---

## Final Fantasy XIV

### 1.0 Failure → A Realm Reborn

- **Source:** https://www.pcgamesn.com/final-fantasy-xiv-a-realm-reborn/naoki-yoshida-final-fantasy-xiv-a-realm-reborn
  - 1.0 released 2010-09-30; critical and commercial failure.
  - Yoshida appointed Director & Producer December 2010; logged into 1.0 for only 4m 50s before determining a simple fix was impossible.
  - ~10,000 change points identified; 80% unreachable without rebuilding the foundational structure.
  - Total ARR development: 2 years 8 months.
  - Core philosophy: "an MMO, but before that an RPG, before that a Final Fantasy game" — story-first.

- **Source:** https://na.finalfantasy.com/topics/21 (5-year retrospective, Square Enix Lodestone)
  - The original 1.0 engine was fundamentally broken for modern MMO expectations (UI, input latency, content access).
  - Yoshida's team ran 1.0 alongside ARR development; 1.0 servers shut 2012-11-11, ARR beta tested 2012–2013.

### Job System

- **Source:** https://ffxiv.consolegameswiki.com/wiki/Job
  - One character can unlock all classes and jobs; no character slots wasted.
  - Classes advance to their Job at level 30 (post-Stormblood: no secondary class prerequisite).
  - Switch jobs by equipping/unequipping the Soul Crystal; each job has its own independent XP bar.
  - All jobs of the same role (tank / healer / DPS) balanced to equal combat output at level cap.
  - Raids designed assuming any job in its role is viable ("all jobs are raid-compatible").

### Duty Finder & Instanced Content

- **Source:** https://ffxiv.consolegameswiki.com/wiki/Duty_Finder
  - Matchmaking spans all worlds within the same data center (cross-world, not cross-DC by default).
  - Queue for up to 5 duties simultaneously if same party size; accepting one cancels others.
  - High-end content (Raid Finder): fixed composition — 2 tanks, 1 pure healer, 1 barrier healer, 2 ranged DPS, 1 melee, 1 other DPS.
  - Trust / Duty Support: queue with NPC party members in supported duties (avoids wait times).

### Data Center Travel

- **Source:** https://na.finalfantasyxiv.com/lodestone/playguide/contentsguide/datacentertravel/
  - Introduced ~2022 (Endwalker era); lets players visit worlds outside their home data center.
  - Regions: JP (Elemental/Gaia/Mana/Meteor), NA (Aether/Crystal/Dynamis/Primal), EU (Chaos/Light), OCE (Materia — visits unavailable).
  - Cross-DC friends list: cannot form parties or chat cross-DC.
  - Restrictions while visiting: no retainer management, no market selling, no housing, no Firmament/cosmic exploration.
  - No time limit on visits.

- **Source:** https://primagames.com/featured/ffxiv-data-center-travel-is-taking-its-toll-on-the-party-finder
  - DC Travel shifted raiding population to consolidate on single DCs per region; created Party Finder imbalances.
  - Cross-DC Party Finder not implemented at 2022 launch; players must physically visit the raiding DC.

### Netcode / Tick Rate

- **Source:** https://forum.square-enix.com/ffxiv/threads/521594
  - Positional server tick: ~0.3s (~3.3 Hz) — tracks player and actor positions.
  - Actor (DoT/HoT) tick: 3 seconds.
  - WoW comparison: ~0.05s (~20 Hz).
  - Effects: players die in spread mechanics when server position lags client by up to 0.3s; heal timing unpredictable in high-end content; AoE resolution is "snapshot not visual."

- **Source:** https://www.akhmorning.com/resources/raiding-fundamentals/
  - Moving objects on client screen are ~1 second behind server state.
  - GCD ability queue: press next GCD ~0.5s before current GCD ends for reliable queueing.
  - Quote: "FFXIV netcode sucks, everything on your screen is a lie."
  - Position resolved by center of player model at cast-bar completion (cast attacks) or animation frame (instant attacks).

### Patch Cadence

- **Source:** https://justabout.com/video-games/37582/making-sense-of-the-final-fantasy-xiv-patch-cycle
  - Major patches every ~4–4.5 months (stretched to ~5 months in Endwalker and post-Dawntrail).
  - Odd patches (x.1, x.3, x.5): alliance raid series, gear upgrade tokens, crafting/gathering gear.
  - Even patches (x.2, x.4): 8-man raid (Normal + Savage), new tomestone currency, new crafted combat gear.
  - Savage unlocks ~1 week after Normal.
  - Raid progression cycle: 2–4 weeks clearing → 3–4 weeks reclear for BiS → next tier in ~2–3 months.

### Mentor / Community

- **Source:** https://ffxiv.consolegameswiki.com/wiki/Mentor_System_and_Novice_Network
  - New characters receive "Sprout" icon until they meet activity thresholds.
  - Two mentor types: Battle Mentor (combat experience req.) and Trade Mentor (crafting/gathering req.).
  - Novice Network: dedicated chat channel; mentors get bonus XP for grouping with sprouts.
  - Widely cited as one of the most welcoming MMO communities.
