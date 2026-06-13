---
type: system
tags: [multiplayer, networking, co-op, dungeon, town, enet]
status: draft
updated: 2026-06-13
sources: ["docs/specs/46-multiplayer-coop.md", "docs/specs/46-multiplayer-coop-notes.md", "wyrd/scripts/net_game.gd", "wyrd/scripts/game.gd"]
---

# Multiplayer Co-op

2–4 players share one Bramblewood instance over a host-authoritative ENet listen-server, stepping through the same [[The Waystone]] into the same chart run.

## Architecture

**Transport:** `ENetMultiplayerPeer` via Godot's high-level MultiplayerAPI. The host is also a player (listen-server). Transport is swappable later (GodotSteam, WebRTC) because nothing touches raw ENet — only the abstracted API (`docs/specs/46-multiplayer-coop.md`).

**Host authority:** The host runs truth for enemies, damage, loot rolls, and [[Chart Loop]] state. Guests own only their own player body's intent. The `NetGame` autoload (`wyrd/scripts/net_game.gd`) is the single co-op session manager — `active` is the switch every other system reads to know whether a session is live. Offline (`active = false`) the game runs identically to its pre-multiplayer state.

**Port:** 7777 by default (`DEFAULT_PORT`). Max 4 players (`MAX_PLAYERS`). Join flow v1 is direct IP — LAN and Tailscale are the supported story. UPnP is attempted opportunistically. Steam lobbies are post-demo.

## The Lantern

Pressing Esc in-session opens **The Lantern**, a small panel in the kit style. It surfaces host/join/roster/leave. Dev: `WYRD_NET=host` / `WYRD_NET=join:<ip>` boot hooks exist for headless smoke tests.

> ⚠️ The spec called for a "menu panel"; the notes confirm it landed as the Esc Lantern because the game boots directly into town with no main menu. The game boots straight to Town.tscn.

## Roster and per-peer spawning

`NetGame.players` is a `Dictionary` of `peer_id → {name}`. The host's copy is truth; it is re-broadcast whole on every change via `_sync_roster` RPC. On every roster change `_reconcile_players()` creates or removes `NetPlayer<peer_id>` nodes in the current scene, each with `set_multiplayer_authority(id)`. The single-player baked `Player` node is freed when `setup_scene()` is called by a scene's `_ready` during a live session.

> ⚠️ `NetGame` is looked up at runtime via `get_node_or_null("/root/NetGame")` inside `game.gd` and `player_controller.gd` — not as a compile-time global — because the headless loop test compiles those scripts before autoloads register. Scripts only ever loaded inside scenes use the ergonomic global.

## Phase A — Town together

Phase A proves de-singletonizing: guests walk the host's town, see each other move, names shown overhead. Key changes shipped:

- **12 Hz transform RPC** (`_net_state(pos, yaw, moving)` unreliable-ordered) from the authority; puppet lerps at 10× delta. The `MultiplayerSynchronizer` is deferred to Phase B where it earns its keep over many enemies.
- **Modal de-pause:** `Game.modal_opened/closed` counts modals instead of pausing the tree. In a session, the tree stays live and only local player input gates on `modal_count`. Offline behavior is unchanged (the suite proves it). All seven pause sites converted (spec said six; the Waystone panel was a seventh).
- **Dungeon gated in Phase A:** `enter_dungeon` refuses with a toast until Phase B.

## Phase B — Dungeon co-op

### Run start
The host sockets a [[Charts|chart]] at [[The Waystone]]; `NetGame.start_run(chart)` broadcasts `_run_start` to all peers. Each peer calls `Game.net_enter(chart)`, which builds the dungeon from the chart's seed locally.

### Seed-identical enemies
The chart seed also seeds `layout_loader._rng`, so every peer builds the same foes on the same tiles with the same elite rolls. Enemy bodies get deterministic names (`NetFoe<N>`). Guest bodies are flagged `net_puppet`.

### 10 Hz enemy snapshots
The host streams batched `name → [pos, hp]` snapshots via `_enemy_state` RPC (unreliable-ordered, 10 Hz via `ENEMY_SYNC_HZ = 10.0`). Absence from a snapshot means dead — guests despawn silently (set-membership pattern from claudecraft). This runs in `NetGame._process` on the host only when `in_dungeon` is true.

### Guest casts
Guest casts are cosmetic locally (puppet enemies take no damage). The cast is forwarded to the host, which replays the skill from that player's host-side body using `net_aim` override. Trust-the-party model for v1. The host re-runs `_try_skill` guards and RPCs a refusal string on failure.

### Damage routing
Damage to a guest body is detected by the host, which RPCs it to the owner; the owner applies real rules (ward, grit, iframes) locally.

### Kill credit
[[Skills|Arrows]] carry `owner_peer`. The host credits the killer's machine via `kill_credit(peer, foe_hp_max)` → `_kill_credit` RPC, awarding [[Huntcraft]] XP and the Even Breath focus refund.

### Per-player loot
The host broadcasts `drop_event(kind_id, rarity, pos)` to all peers. Each peer rolls its own affixes locally and spawns its own `ItemPickup` — per-player [[Items and Gear]] instancing. [[Gather Nodes]], chests, and shrines are per-peer for free (seed-built local physical objects).

### Party-wipe boss rules
Offline keeps any-death boss resets. In co-op, gates only drop when nobody stands. Puppet death edges ride the player state RPC so every machine can evaluate the wipe. See [[Bosses]].

### Exit and abandon
`NetGame.request_end(abandoned)` routes through the host. Non-abandoned exits trigger a 5-second grace period (`EXIT_GRACE_SEC = 5.0`) and a notice toast; the party then teleports together. Tear (abandon) is immediate. The at-the-stone vote is Phase C.

> ⚠️ A bug found while wiring Phase B: the spec-45 abandon stone never actually passed `abandoning` into `return_to_town` — abandoning was paying full completion XP. Fixed in Phase B (`docs/specs/46-multiplayer-coop-notes.md`).

## Phase C — Polish (queued)

- Walk-animation sync on puppets (the `moving` flag already rides the state RPC).
- 30-second reconnect grace (roster currently drops on disconnect immediately).
- Guest toast when host's lantern goes out (`session_ended` wired; toast TBD).
- Loot drop visibility per peer (currently all peers see all drops).
- Damage numbers on guests for their own hits.
- Boss telegraph visuals on guests (boss AI is host-only).
- Trophy attribution polish (each peer currently receives boss trophies locally — generous, kept on purpose).
- Exit-stone party vote.
- Party UI (invite/kick/leader) and join/leave ambience lines.

## Pre-work blockers (resolved for Phase A/B)

| Blocker | Resolution |
|---|---|
| Six modals pause the whole tree | `Game.modal_opened/closed` counter; local input gating |
| `Hitstop` sets `Engine.time_scale` globally | Still global in town (Phase A). Must become local-visual before Phase B goes live. |
| `layout_loader._rng` non-deterministic | Seed `_rng` from chart seed; host-spawn law |
| Enemy AI caches one player forever | Nearest-alive-player retarget per repath tick |
| Input read globally in `player_controller` | `if not is_multiplayer_authority(): return` + synchronizer |

## Out of scope (v1)

Dedicated servers, cross-version joins, more than 4 players, Steam transport, web export, anti-cheat beyond host validation, voice chat.

## See also

- [[Chart Loop]] — the run flow co-op extends
- [[Charts]] — host sockets the chart for the whole party
- [[The Waystone]] — party steps through together
- [[Bosses]] — party-wipe rules differ from solo
- [[Save System]] — each peer keeps their own save; guests never write the host's
- [[Dungeon Generation]] — seed-identical geometry across peers
- [[Enemies]] — host-authoritative; puppeted on guests
- [[Huntcraft]] — kill credit and Even Breath route through NetGame

## Sources

- `docs/specs/46-multiplayer-coop.md`
- `docs/specs/46-multiplayer-coop-notes.md`
- `wyrd/scripts/net_game.gd`
- `wyrd/scripts/game.gd`
