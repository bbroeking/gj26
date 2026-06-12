# Spec 46 — Invite-your-friends co-op (host-authoritative ENet)

> **Outcome**: 2–4 players in one Bramblewood — a friend joins your town,
> you inscribe a chart, the party steps through the same Waystone into the
> same seed, and the trophy chain is something you do together.

Synthesis of two studies (2026-06-12): the **coupling scan** of our
codebase (14 `get_first_node_in_group("player")` sites, one Game
singleton, six tree-pausing modals) and the **world-of-claudecraft
breakdown** (`.claudecraft-ref/` — a shipped TS/websocket MMO-lite whose
patterns map cleanly onto Godot's high-level MultiplayerAPI).

## Decision

**Host-authoritative listen-server over ENet** (`ENetMultiplayerPeer`),
host is also a player. Guests own only their player body's *intent*;
the host runs truth: enemies, damage, loot rolls, chart state. Transport
is swappable later (GodotSteam / WebRTC) because the high-level
MultiplayerAPI abstracts the peer — design nothing against raw ENet.

Join flow v1 is honest about NAT: **Host (port 7777) / Join (IP:port)**
from a small menu panel. LAN and Tailscale/VPN are the supported story;
UPnP attempted opportunistically. Steam lobbies are the post-demo fix.

## The claudecraft steals (proven patterns, adopted)

1. **One command chokepoint** — every guest verb is a single
   `_cmd(dict)` RPC to the host (`game.ts:283` pattern). One switch =
   one place to validate and log.
2. **Host-side cast validation with flavor-text errors** — the host
   re-runs the `_try_skill` guards (dead/cooldown/Focus/range) and RPCs
   the refusal string back (`sim.ts:848` pattern). Never trust the
   caster, even among friends — it catches desyncs loudly.
3. **State vs events, two channels** — `MultiplayerSynchronizer` for
   continuous state (pos/hp/cast), unreliable one-shot RPCs for
   transient events (damage numbers, SFX pings, toasts).
4. **Private self-state** — other players replicate shallowly; satchel,
   cooldowns, chart case go only to the owning peer.
5. **Party-keyed instance claim** — *the chart run is the instance*:
   host's chart (with seed) is the claim key; everyone builds the same
   dungeon locally from the seed. claudecraft pre-allocates instance
   slots; we get this nearly free from seed-deterministic `DungeonGen`.
6. **Save-on-leave, rejoin at entrance** — a disconnecting guest's
   gains save immediately; rejoining mid-run spawns at the dungeon
   entry, never mid-room. Plus a **30s reconnect grace** (claudecraft's
   missing feature — their 2-second wifi blip = full leave).
7. **Disconnect hygiene as one host function** — clear aggro/taps off
   the leaver, drop from party UI, cancel interactions (their
   `removePlayer` checklist).
8. **Tap rights + nearby-party XP share with a group bonus** — co-op
   must never pay worse than solo (cozy-skilling spine).

## Loot & progression model

**Per-player everything**: each peer keeps their own Game state
(trades/satchel/gold/charts/save). The host's world is the *place*;
your character is *yours*. Host RPCs awards to the acting peer (gather →
the channeler, kill XP → tap owner + party share, completion XP → every
party member in the run). Guests never write the host's save.

## Pre-work (blockers found by the scan — must land before Phase A)

| # | Blocker | Fix |
|---|---|---|
| 1 | Six modals pause the whole tree (vendor, dialog, bench, shrine, loadout, craft) | Modals stop pausing; they capture local input instead (host opening the vendor must not freeze the server) |
| 2 | `Hitstop` sets `Engine.time_scale` globally | Becomes a local-visual effect (per-mesh pause), never time_scale |
| 3 | `layout_loader._rng.randomize()` — enemy placement is non-deterministic per machine | Host-spawn law: enemies exist only as host-spawned synced nodes; seed `_rng` anyway as belt-and-braces |
| 4 | Enemy AI caches THE player forever (`combatant.gd:226`) | Nearest-alive-player retarget per repath tick |
| 5 | Input read globally in `player_controller` | `if not is_multiplayer_authority(): return` + synchronizer |

## Phases

- **Phase A — town together (M)**: `NetGame` autoload (host/join/peers),
  player-per-peer spawning via `MultiplayerSpawner` (named by peer id,
  authority set), position/rotation/anim sync, name labels, the modal
  de-pause rework, local-only HUD/camera binding. Proves the
  de-singletonizing — ~70% of the total pain, zero combat risk.
- **Phase B — dungeon co-op (L)**: replicated `active_chart` + party
  scene change, seed-built geometry per peer, host-spawned synced
  enemies, `_cmd` chokepoint + host-validated casts, nearest-player
  AI, boss arena rules for parties (party-wipe resets, not first
  death), exit waystone = party vote or all-at-stone, abandon stone
  works per-player, per-player gather channels paying the channeler.
- **Phase C — polish (L–XL)**: statuses/elite effects replicated, loot
  drop visibility per peer, reconnect grace, guest death/respawn rules,
  lag-tolerant arrows, party UI (invite/kick/leader), join/leave
  ambience lines ("X steps into Bramblewood.").

Honest total for a credible 2-player slice: **~3–4 weeks focused**,
dominated by de-singletonizing, not networking.

## Out of scope (v1)

Dedicated servers, cross-version joins, more than 4 players, Steam
transport, web export, anti-cheat beyond host validation, voice.

## Done when (Phase A gate)

1. Host starts a server from the menu; guest joins by IP on LAN.
2. Both players walk the town, see each other move/animate, names
   overhead.
3. Host opens the vendor; the guest's world does not freeze.
4. Guest disconnects; host's world cleans up; guest rejoins.
5. All three headless suites still green in single-player mode.
