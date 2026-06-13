---
type: concept
tags: [mmo-research, implementation, netcode, tick-rate, prediction, lag-compensation, replication, networking]
status: draft
updated: 2026-06-13
sources:
  - https://gafferongames.com/post/snapshot_interpolation/
  - https://gafferongames.com/post/networked_physics_2004/
  - https://www.gabrielgambetta.com/client-side-prediction-server-reconciliation.html
  - https://www.gabrielgambetta.com/entity-interpolation.html
  - https://snapnet.dev/blog/netcode-architectures-part-3-snapshot-interpolation/
  - https://oldschool.runescape.wiki/w/Game_tick
  - https://edgegap.com/blog/game-server-tick-rate-explained-gameplay-precision-vs-infrastructure-cost
  - https://developer.valvesoftware.com/wiki/Source_Multiplayer_Networking
  - https://developer.valvesoftware.com/wiki/Lag_Compensation
---

# MMO Netcode and Tick Systems

The collection of techniques — fixed-rate server loops, client-side prediction, state replication, and lag compensation — that make a distributed game simulation feel responsive and consistent across heterogeneous network conditions.

## The Server Game Loop / Tick

Every authoritative game server runs a fixed-rate main loop called the **tick** (also: game loop iteration, server frame). Each tick:

1. Read all buffered client inputs received since the last tick.
2. Advance the simulation by one fixed time-step (process AI, physics, combat resolution, etc.).
3. Emit outgoing state (snapshots, events) to relevant clients.
4. Sleep until the next tick deadline.

**Tick rate** is measured in Hz (ticks per second). It determines both simulation granularity and update frequency.

### Tick Rate Comparisons

| Game | Tick Rate | Time/Tick | Notes |
|---|---|---|---|
| RuneScape (OSRS / RS3) | ~1.67 Hz | **600 ms** | Longest production tick in mainstream games; all combat, movement, skilling gated to this quantum |
| WoW Vanilla (spell batch) | ~2.5 Hz effective | **400 ms** | Spells processed in batches every 400 ms; not a strict global tick |
| WoW Modern | ~50 Hz effective | ~20 ms | Spell batch reduced to ~20 ms with hardware upgrades |
| Minecraft | 20 Hz | 50 ms | Block/entity simulation |
| Halo Infinite (BTB) | 30 Hz | 33 ms | 24-player modes intentionally lower |
| Halo Infinite (4v4) | 60 Hz | 16.7 ms | Competitive modes get higher tick |
| Apex Legends | 20 Hz | 50 ms | Respawn deliberately chose low tick for battle-royale scale |
| Hunt: Showdown | 30 Hz | 33 ms | Mid-tier extraction shooter |
| CS:GO / CS2 (default) | 64 Hz | 15.6 ms | CS2 adds sub-tick event timestamping |
| CS2 (sub-tick) | 64 Hz + µs events | — | Events logged with microsecond timestamps between ticks |
| VALORANT | 128 Hz | 7.8 ms | Fully invested in high-tick; rebuilt Unreal networking, 2.34 ms server frame time |
| EVE Online (normal) | ~1 Hz | ~1 s | Each solar system; TiDi can stretch to 10 s/tick under load |

### RuneScape's Deterministic 600 ms Tick

RuneScape's tick has been 600 ms since the original engine. It is the game's fundamental time quantum: movement, combat attacks, skill actions, and NPC AI all resolve on tick boundaries. No action resolves mid-tick. Actions submitted during tick N are processed at the start of tick N+1.

The client has its own 20 ms UI tick (for menus and interface responsiveness), entirely separate from the server tick. On heavily loaded worlds, ticks can slip to 616–618 ms; the server can also miss ticks entirely. This architecture makes RuneScape inherently lag-tolerant (a 200 ms ping costs nothing if the action window is 600 ms wide) but creates the notorious "tick manipulation" meta, where skilled players exploit the tick boundary to multi-action within a single server cycle.

### WoW's Spell Batching

Vanilla WoW did not have a strictly named "tick" for combat, but spells were resolved in a **batch window every 400 ms**. All spell cast messages received within the same batch window were processed simultaneously — enabling the famous "simultaneous Pyroblast death" interactions. This persisted from WoW's 2004 launch through Warlords of Draenor (2014), when CCP-style hardware improvements allowed the window to shrink to ~20 ms. WoW Classic (2019) deliberately re-introduced 400 ms batching for authenticity.

### High-Tick Action Combat

For action-combat games, higher tick rates improve hit registration fidelity but scale infrastructure costs linearly. Respawn's analysis of Apex: moving from 20 Hz to 60 Hz saves ~2 frames of latency at triple the bandwidth and CPU cost. VALORANT's 128 Hz server runs at 2.34 ms average server frame time (down from 50 ms before their networking rewrite), achieved by:
- Custom networking to replace default Unreal replication (75% animation CPU reduction).
- Hardware selection optimised for single-thread latency, not throughput.

Valve's Counter-Strike 2 took a different path: instead of raising tick rate above 64, they added **sub-tick event timestamping** — every player action is logged with a microsecond timestamp within the 15.6 ms tick window, so hit detection uses the precise moment of input rather than the tick boundary approximation. This eliminates quantization error without the full infrastructure cost of 128 Hz.

## Client-Side Prediction

At any tick rate, the round-trip time (RTT) from client input to server state update introduces perceived input lag. **Client-side prediction** eliminates this lag by having the client immediately apply its own inputs locally, without waiting for server confirmation.

### Algorithm

1. Client captures input, assigns it a monotonically increasing sequence number, and sends it to the server.
2. Client immediately applies the input to local state (predicted position, animation, etc.).
3. Client appends the input to a **pending input buffer** (circular buffer of moves not yet acknowledged by the server).
4. Server receives the input (delayed by RTT/2), processes it against the authoritative world state, and replies with the authoritative result tagged with the last acknowledged sequence number.
5. Client receives the server reply. It discards all inputs from the buffer with sequence numbers ≤ the acknowledged number.
6. Client compares its predicted state against the server's authoritative state. If they diverge beyond a threshold, the client **reconciles**: it resets to the server state and **replays** all remaining (unacknowledged) inputs from the buffer forward, arriving at a corrected current position.
7. A smoothing pass is applied to mask the visual jump (snap only if divergence > 2 m; exponential smoothing for smaller corrections).

The key requirement is **determinism**: the same input applied to the same state must always produce the same result. If the game uses floating-point physics with non-deterministic ordering, reconciliation will diverge. Wayfinder's enemy AI uses host-only authoritative simulation precisely because complex AI is hard to predict deterministically on clients.

### What Can and Cannot Be Predicted

**Predict on client:** Local player movement, animation state, UI feedback, cosmetic effects (particles, sound hits).

**Do not predict:** AI-controlled entities (too complex, non-deterministic), other players (require interpolation), loot rolls (authoritative), damage to the player's body from external hits.

## Server Reconciliation

Reconciliation is the process by which the client corrects its predicted state when the server disagrees. The input buffer is essential: without stored move history, the client cannot replay forward from the authoritative correction point.

At 100 ms RTT and 20 Hz server updates, the client has at most 2 un-acknowledged inputs pending. At 250 ms RTT and 20 Hz, up to 5 inputs are pending. Buffer overflow implies the client is too far ahead of acknowledged server state to recover smoothly — a sign of network trouble.

## Interpolation (Entity Smoothing)

For entities the client does **not** control (other players, enemies, projectiles), prediction is impractical. Instead, clients use **interpolation**: they render the entity at a position *in the past*, smoothly transitioning between the two most recent received snapshots.

Example (10 Hz server updates, 100 ms snapshot interval):
- At real time t=1000, client receives snapshot for t=1000.
- At t=1100, client receives snapshot for t=1100.
- During the interval t=1000–1100, client **displays** the entity moving from the t=900 position to the t=1000 position (it always displays 100 ms behind the most recent received snapshot).
- When t=1100 arrives, it interpolates from t=1000 → t=1100 during the next 100 ms.

This introduces a constant display lag of one update interval (100 ms at 10 Hz, 50 ms at 20 Hz, 15.6 ms at 64 Hz). A jitter buffer of 3× the send interval (e.g., 300 ms for 10 Hz) absorbs two consecutive lost packets before extrapolation is required.

Higher-quality interpolation uses **Hermite splines** (position + velocity at sample points) instead of linear interpolation, eliminating the pulsing artifacts visible with linear lerp on curved paths. For rotations, **spherical linear interpolation (slerp)** is standard.

## Lag Compensation

Interpolation creates a problem for hit detection: the attacker is aiming at a visually interpolated position (100 ms in the past), not the server's current position. A hit registered against the client's display position would miss on the server because the target has moved.

**Lag compensation** (Valve's term from the Source engine documentation) resolves this by rewinding the server's world state to the moment the client fired. Algorithm:
1. The server maintains a rolling history of entity positions (Valve keeps ~1 second of history by default).
2. When a hit-scan or projectile action arrives from a client, the server notes the client's current latency.
3. The server rewinds entity positions by `client_latency + interpolation_delay`.
4. The server evaluates the hit against the rewound positions.
5. The server resets entities to current positions and continues.

The rewind depth formula: `rewind_time = inputQueueDelay + interpolationBackTime + clientLatency − clientFiringDelay`. A client firing delay (a small deliberate lag on the client's local confirmation) reduces total rewind time at the cost of some responsiveness.

**Anti-cheat implication:** Lag compensation is exploitable. A high-latency client can shoot at positions the target has already left (they look like they're hitting behind cover on the server's timeline). Most games cap maximum rewind depth (Valve: 1 s). Some games apply directional sanity checks: if the rebound trace passes through solid geometry, reject it.

## State Replication: Snapshots vs Deltas vs Events

Three approaches to sending world state to clients:

### Full Snapshots
Every tick, send the complete state of all relevant entities (position, orientation, health, animation). Simple to implement; expensive at scale. At 60 pps with 900 entities, Glenn Fiedler measured ~11.6 Mbit/s (225 bits per entity). Used in early MOBAs and LAN party games; impractical for internet-scale.

### Delta Snapshots
**Delta compression**: rather than sending full state, send only what has changed since the last acknowledged snapshot. Requires the client to acknowledge each received snapshot so the server knows the baseline for the next delta. Delta compression can reduce bandwidth by up to 90% compared to full state. Counter-Strike and Source engine use delta compression. The sequence number on every packet enables the server to track per-client acknowledged baselines.

Modern delta snapshot stacks add:
- **Bit-packing** (write state at bit granularity, not byte boundaries).
- **Quantisation** (reduce float precision to what's perceptible: position to 0.1 cm, angle to 1°).
- **Huffman or arithmetic coding** for entropy compression.
- **Oodle Network** (commercial middleware, used by many AAA titles).

### Events / RPCs
Discrete, named, reliable messages for state transitions that cannot be missed: a player dies, a door opens, a boss enters phase 2. Events travel on a reliable channel (acknowledged delivery guaranteed). They complement snapshots rather than replacing them — snapshots carry continuous state, events carry singular transitions.

Wayfinder's `_kill_credit`, `_run_start`, and `_run_end` RPCs are events. The 10 Hz `_enemy_state` and 12 Hz `_net_state` RPCs are unreliable snapshots (as documented in [[Multiplayer Co-op]]).

## Reliable vs Unreliable Transport

| | Reliable | Unreliable |
|---|---|---|
| Delivery guarantee | Yes | No |
| Ordering guarantee | Yes (typically) | No (or "ordered-but-droppable") |
| Latency profile | Higher (RTT + retry) | Lower (one-way) |
| Use cases | Events, RPC, file transfers | Position snapshots, audio frames |
| Protocol | TCP or reliable-UDP | UDP |

**Why snapshots must use UDP:** If a position snapshot is late or lost, retransmitting it is worse than discarding it — by the time it arrives, a newer snapshot has rendered it stale. Retransmission (TCP) would cause the interpolation buffer to stall waiting for the retransmit before advancing. UDP drop-and-skip is the correct semantic.

Godot's ENet (used by Wayfinder) provides both reliable-ordered and unreliable-ordered channels over UDP. The 12 Hz transform RPC (`_net_state`) and 10 Hz enemy snapshot (`_enemy_state`) use `unreliable_ordered`, matching the correct semantic for continuous state.

## Bandwidth and Interest Management's Role in Netcode

Packet generation workload scales as O(N²) naively: with N players, each player must receive updates for N−1 others. Doubling player count roughly quadruples packet generation time (since each of 2N players gets updates about 2N−1 others). This becomes the dominant bottleneck before CPU or network bandwidth saturate.

**Interest management** (AoI, see [[MMO Server Architecture]]) breaks the O(N²) scaling by filtering: player A only receives updates for entities within their area of interest radius. At radius R in a uniform distribution, the expected number of visible entities scales with R² rather than with the total population. This reduces both server packet generation CPU and per-client ingress bandwidth.

At 10 Hz, 100 bytes/entity, 50 visible entities per player: each player receives 50 × 10 = 500 state updates/s = 50 KB/s. At 128 Hz with the same parameters: 640 KB/s per client. Bandwidth is linear in tick rate for a fixed visible entity count.

## Authority Models and Anti-Cheat

### Server-Authoritative (Dedicated)
All game logic runs on a trusted server process the player does not control. Cheats that manipulate client-side memory cannot affect authoritative outcomes. Server validates every action: movement speed, damage values, loot rolls. Standard for competitive and MMO titles.

### Host-Authoritative (Listen Server)
The host player's machine is also the authoritative server. Architecture is identical to dedicated server from the guest's perspective — the host runs all validation. Security flaw: **the host player has access to all world state**, including enemy positions, hidden entities, and upcoming events that non-host players cannot see. A malicious host can trivially extract this information (wallhacks, loot snipe). Additionally, a malicious host can block anti-cheat software from loading in their session entirely.

Suitability: listen-server is appropriate for small trusted groups (friends, LAN) where social trust substitutes for technical anti-cheat. Suitable for: Wayfinder's 2–4 player co-op with friends. Unsuitable for: ranked matchmaking, any competitive context with strangers.

### Mitigation in Listen-Server Games
- Limit host-visible data to entities in the current AoI (host should not receive data about entities behind a boss door before that door opens).
- Re-validate all guest actions on the host (Wayfinder does this: guests cast → host replays skill → host RPCs refusal on failure).
- Consider trust-the-party model for low-stakes games (Wayfinder Phase B explicitly documents this as v1 policy).

## Netcode Architectures Compared

| Architecture | Latency feel | Bandwidth | CPU | Complexity | Typical use |
|---|---|---|---|---|---|
| Lockstep | Input delay = max peer RTT | Very low | Low | Low | RTS, 2D fighters (old) |
| Rollback (with prediction) | Responsive; invisible rollback | Moderate | High (replay) | High | Fighting games, platformers |
| Snapshot interpolation + prediction | Responsive local player; smooth remote entities | Moderate–high | Moderate | Moderate | Shooters, MMOs |
| Pure snapshot (no prediction) | Delayed by RTT | Low–moderate | Low | Low | Turn-based, slow-tick MMOs |

Wayfinder's architecture is snapshot interpolation + host prediction: the local player is predicted (no input lag), enemies are interpolated from host snapshots (10 Hz), and remote player positions are interpolated from 12 Hz state RPCs. This is the standard architecture for a small-party action game.

## Relevance to Wayfinder

[[Multiplayer Co-op]] maps directly onto the fundamentals documented here:

- **Tick rate:** Godot's `_process` runs at display framerate (60+ Hz) but `ENEMY_SYNC_HZ = 10.0` and the transform RPC at 12 Hz establish effective netcode tick rates lower than render rate. This is correct — snapshot send rate and render rate are independent.
- **Snapshot transport:** Both the `_net_state` (12 Hz, unreliable-ordered) and `_enemy_state` (10 Hz, unreliable-ordered) RPCs use the correct UDP semantic for continuous state. Drop-and-skip is exactly right; a lost snapshot is superseded by the next one.
- **Host authority vs. client prediction:** Wayfinder does not implement client-side prediction for guest player movement. Guests lerp at 10× delta on the puppet (`puppet lerps at 10× delta`). At LAN/Tailscale latencies (< 20 ms), this is barely perceptible and correct for Phase A/B scope.
- **No lag compensation:** At sub-20 ms LAN latency, the interpolation delay (1/12 s ≈ 83 ms) dominates and lag compensation is unnecessary. If Wayfinder ever targeted internet play (> 80 ms RTT), hit-detection accuracy would require a rewind buffer.
- **RuneScape lesson:** Wayfinder's non-real-time pacing (dungeon movement is deliberate, not twitch) means a 10 Hz enemy snapshot is more than sufficient — analogous to how RuneScape's 600 ms tick is acceptable for its pace. The tick-rate-to-game-genre fit is the key design judgment.
- **Anti-cheat scope:** The trust-the-party model (Phase B v1) is appropriate. The relevant mitigations already in place: host re-runs `_try_skill` guards and RPCs refusals; loot rolls are host-side; damage adjudication routes through the host.

## See also

- [[MMO Server Architecture]] — the zone/shard/AoI architecture that this netcode runs on top of
- [[Multiplayer Co-op]] — Wayfinder's implementation of these patterns
- [[Combat]] — the host-authoritative combat loop
- [[Enemies]] — 10 Hz host-snapshot model for enemies
- [[Save System]] — per-peer saves; authoritative state lives on host
- [[Dungeon Generation]] — seed-identical world as an alternative to state streaming
- [[RuneScape]] — deterministic 600 ms tick as design anchor
- [[World of Warcraft]] — spell batching and evolving tick history
- [[EVE Online]] — TiDi as a dynamic tick-rate control under load
- [[MMO Research]] — survey index
- [[MMO Lessons for Wayfinder]] — distilled takeaways

## Sources

- Glenn Fiedler / Gaffer On Games: "Networked Physics (2004)" — https://gafferongames.com/post/networked_physics_2004/
- Glenn Fiedler / Gaffer On Games: "Snapshot Interpolation" — https://gafferongames.com/post/snapshot_interpolation/
- Gabriel Gambetta: "Client-Side Prediction and Server Reconciliation" — https://www.gabrielgambetta.com/client-side-prediction-server-reconciliation.html
- Gabriel Gambetta: "Entity Interpolation" — https://www.gabrielgambetta.com/entity-interpolation.html
- SnapNet: "Netcode Architectures Part 3: Snapshot Interpolation" — https://snapnet.dev/blog/netcode-architectures-part-3-snapshot-interpolation/
- OSRS Wiki: "Game Tick" — https://oldschool.runescape.wiki/w/Game_tick
- Edgegap: "Game Server Tick Rate Explained" — https://edgegap.com/blog/game-server-tick-rate-explained-gameplay-precision-vs-infrastructure-cost
- Valve Developer Community: "Source Multiplayer Networking" — https://developer.valvesoftware.com/wiki/Source_Multiplayer_Networking
- Valve Developer Community: "Lag Compensation" — https://developer.valvesoftware.com/wiki/Lag_Compensation
- WoW Classic info: "Spell Batching" — https://www.wowisclassic.com/en/news/spell-batching-classic-wow-confirmed/
- EVE University Wiki: "Time Dilation" — https://wiki.eveuniversity.org/Time_dilation
- Unity Netcode Docs: "Dealing with Latency" — https://docs.unity3d.com/Packages/com.unity.netcode.gameobjects@2.7/manual/learn/dealing-with-latency.html
