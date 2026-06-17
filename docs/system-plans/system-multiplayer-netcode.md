---
title: Multiplayer & Netcode (co-op)
domain: Multiplayer
type: system
status: partial
effort: M
tags: [wayfinder, plan]
---

# Multiplayer & Netcode (co-op)

> Phase A (town) and Phase B (dungeon) are both SHIPPED; Phase C polish — guest arrows, damage events, reconnect grace in-dungeon, exit vote, party UI, and ~10 residual `get_first_node_in_group` calls — is what remains.

## Current state

**Phase A (town together) — SHIPPED.** `NetGame` autoload (`wyrd/scripts/net_game.gd`) owns the ENet peer, roster (peer_id → name dict, host is truth, snapshot-synced via `_sync_roster.rpc`), per-peer `NetPlayer<id>` spawning with authority assignment, 12 Hz unreliable-ordered `_net_state` pos/yaw/moving/dead, name-tag Label3D, Tailscale-aware `local_addresses()`, 3-retry reconnect (`RECONNECT_TRIES=3`, `RECONNECT_DELAY=2.0`), and all seven modals de-paused in-session (`net_game.gd:70–75`). The Lantern (`wyrd/scripts/ui/system_menu.gd`) provides host + copy-address + join-by-IP flow with clear in-world language. `WYRD_NET=host|join:<ip>` dev hooks live in `wyrd/scripts/town.gd:77`.

**Phase B (dungeon co-op) — SHIPPED.** Host sockets a chart for the whole party (`game.gd:663–672`), guests receive `_run_start.rpc` → `game.net_enter()`. Enemies built seed-deterministically as `NetFoe<n>` (`layout_loader.gd:1041`); guests mark them `net_puppet=true`; host broadcasts 10 Hz snapshots (`_enemy_state`, `net_game.gd:294–337`). Guest casts forward to the host via `_net_cast.rpc` (`player_controller.gd:1346–1372`); damage to guest bodies forwards to the owner via `_net_take_damage` (`player_controller.gd:1336–1341`). Kill attribution goes to `last_hit_peer` (`combatant.gd:231`); `kill_credit` RPC refunds Even Breath focus on the killer's machine (`net_game.gd:342–353`). Per-player loot rolls: `drop_event` broadcasts kind+rarity, each peer instantiates its own pickup (`net_game.gd:357–372`). Party-wipe boss reset wired in `layout_loader.gd:711–726`. Exit/abandon: 5-second `EXIT_GRACE_SEC` grace on first exit; `_run_end.rpc` calls `return_to_town` on every machine. Puppet walk anim drives on the `moving` flag in `_net_remote_tick` (`player_controller.gd:1323–1334`). Hitstop skips `time_scale` in-session (`hitstop.gd:16–18`). Nearest-player AI retarget runs every `_tick_ai` cycle (`combatant.gd:278–280`).

**Remaining gaps.** The roadmap (`docs/wyrd-roadmap.md:144–146`) lists Phase C: guest arrows visible, damage numbers via events, boss telegraphs on guests, reconnect grace, exit vote. Additionally: ~10 `get_first_node_in_group("player")` calls remain in non-AI scripts (`town.gd:117,121,139,341`; `boss.gd:112`; `layout_loader.gd:1145`; `game.gd:255`; `player_hud.gd:286`; `cursor.gd:67`); these are mostly cosmetic-safe today but are latent wrong-player bugs in co-op. No in-dungeon rejoin-at-entrance logic exists yet (the reconnect is transport-layer only).

## Gaps — what needs fleshing out

- **[BLOCKER for polish] Guest arrow visibility**: `_net_cast.rpc` replays the full skill on every machine but the cosmetic arrow on non-authoritative guests is local-only; remote peers never see guests' arrows fly. Needs either a replicated Arrow MultiplayerSynchronizer or a lightweight position-stream RPC on the arrow node.
- **Damage numbers via events**: `combatant.net_apply_state` already spawns damage numbers on guests (`combatant.gd:251`) but only from enemy hp-delta. Player-vs-enemy hits from guest casts need a thin `_dmg_event.rpc` so all peers see numbers (cosmetic; no gameplay data required).
- **Boss telegraphs on guests**: boss charge windup, elite-status VFX, and arena gate signals are host-local. Guests see the boss move but miss the warning frame. Requires a small `_boss_event.rpc` (telegraph_start / telegraph_end / gate_up / gate_down).
- **Reconnect grace (in-dungeon)**: transport-layer reconnect (`RECONNECT_TRIES=3`, `RECONNECT_DELAY=2.0`, net_game.gd:19–23) totals ~6 s. The 30-second dungeon-hold described in spec 46 ("save-on-leave, rejoin at entrance") is not implemented: host never holds the run open while a guest reconnects, and guests rejoin town, not the dungeon entrance.
- **Exit vote UI**: currently the first peer to hit the exit triggers a 5-second `EXIT_GRACE_SEC` toast and then ends for everyone (`net_game.gd:253–277`). There is no in-world vote prompt ("X steps toward the waystone — follow or stay?") or per-player confirm.
- **Residual `get_first_node_in_group("player")` calls**: `town.gd:117,121,139,341`, `boss.gd:112`, `layout_loader.gd:1145`, `game.gd:255`, `player_hud.gd:286`, `cursor.gd:67` — these all grab an arbitrary player; the host in a 2+ player session may silently act on a guest body (cursor aim, town NPC dialog trigger). Most are cosmetic-low-risk today but `layout_loader.gd:1145` (first-player walk-to on dungeon complete) and `game.gd:255` (player snapshot on town enter) are gameplay-visible.
- **In-dungeon rejoin at entrance**: a guest who disconnects mid-dungeon (transport reconnect succeeds) is respawned in town via `setup_scene(town)`, not at the dungeon entry. No mechanism routes a re-joining peer to the active chart run.
- **Friend-invite UX beyond LAN**: Lantern shows `local_addresses()` (LAN + Tailscale). UPnP was noted as "attempted opportunistically" in spec 46 but is not implemented. Steam transport deferred to post-demo. The copy-address flow works; the discoverability gap is the main friction point for non-LAN friends.
- **Party UI (identity, kick, leader)**: the Lantern shows a flat name list. No in-world party frame (HP bars for party members), no kick button (only Leave for self), no leader-transfer (host is always the chart owner).

## Plan

### Phase C-1 — Residual first-node sweep + guest death correctness (S)

These are quick and prerequisite to everything else: wrong-player grabs corrupt co-op even without the bigger features.

- Audit all `get_first_node_in_group("player")` sites. For each: replace with `Game.local_player()` (already exists, `game.gd:79–83`) if the call is on a machine's local view; replace with `_nearest_player()` style loop if the intent is "any player."
  - `town.gd:117,121,139` — NPC dialog triggers: use `local_player()`.
  - `town.gd:341` — town-exit position write: use `local_player()`.
  - `boss.gd:112` — boss initial target: already has `_nearest_player` in combatant; mirror that pattern here.
  - `layout_loader.gd:1145` — walk-to post-dungeon: use `local_player()`.
  - `game.gd:255` — snapshot on town enter: use `local_player()`.
  - `player_hud.gd:286` — HUD bind: use `local_player()`.
  - `cursor.gd:67` — cursor aim: use `local_player()`.
- Verify guest death: `_net_state` already sets `dead=true` on the puppet when the authority dies (`player_controller.gd:1315–1319`). Confirm `_party_reset_check` sees the flag (`layout_loader.gd:716`). Write a `WYRD_NET=host WYRD_NET_RUN=2` two-process smoke: kill the guest; confirm host-side party-wipe check fires only when host also dies.
- **DoD:** All 8 `get_first_node_in_group("player")` sites replaced; two-process `WYRD_NET` smoke test green with kill-guest scenario; `test_wyrd_loop.gd`, `test_wyrd_dungeon_scene.gd`, and `test_wyrd_transitions.gd` green (single-player path untouched).
- **Effort:** S

### Phase C-2 — Arrow visibility + damage number events (S)

Guest casts are functionally correct (host replays the real shot); this phase makes them visible to all peers.

- **Arrow cosmetic RPC**: when `_net_cast` fires on a non-authoritative body, the arrow it spawns is local-only. Add a thin `_arrow_event.rpc(origin: Vector3, dir: Vector3, speed: float)` on `arrow.gd` (or `player_controller.gd`) so every peer spawns a cosmetic (no-damage) arrow from that origin. Broadcast from `_net_forward_cast` before the local shot (`player_controller.gd:1366`). Cosmetic arrows skip the damage hitbox; add them to a group `"cosmetic_arrow"` so they don't interact with the combat system.
- **Damage number events**: extend `net_game.gd` with a `dmg_event(pos: Vector3, amount: int, kind: String)` that broadcasts an `unreliable` RPC; combatant's `take_damage` path (host-authoritative) calls it. Guests receive and spawn the floating number locally. Reuse the existing `_spawn_damage_number` pattern in `combatant.gd:251`.
- **DoD:** In a two-process `WYRD_NET` session, host can see guest's arrows fly; both peers see damage numbers on enemy hits from either player. `test_wyrd_dungeon_scene.gd` still green.
- **Effort:** S

### Phase C-3 — Boss telegraphs on guests (M)

Boss charge windup and elite VFX are currently host-only. Guests see the foe teleport after the fact.

- Add `_boss_event.rpc(event_name: String, data: Dictionary)` to `net_game.gd` (authority → all, reliable). Events: `"telegraph_start"`, `"telegraph_end"`, `"gate_up"`, `"gate_down"`.
- In `boss.gd`: call `NetGame.boss_event("telegraph_start", {"dur": charge_windup_sec})` at charge begin; `"telegraph_end"` at release. Boss target position is already implied by the enemy snapshot; the RPC adds the windup visual cue only.
- In `layout_loader.gd`: gate raise/lower emits `"gate_up"` / `"gate_down"` when `active=true` and `NetGame.is_host()`.
- On guest machines, receive these in `combatant.gd` via a `net_boss_event(name, data)` method that re-triggers the local telegraph VFX without re-running the AI decision.
- Elite status-effect replication: when the host applies a status to a foe, include `status_id` in the 10 Hz enemy snapshot batch (extend the `[pos, hp]` array to `[pos, hp, status_flags_int]`). Guests play the matching VFX on status-flag change.
- **DoD:** In a two-process smoke test with `WYRD_DEV_BOSS=burrow_boar_den`, guest sees the charge telegraph VFX and arena gates raise/lower in sync with host. Existing boss headless test unchanged.
- **Effort:** M

### Phase C-4 — In-dungeon reconnect grace + rejoin at entrance (M)

Transport reconnect (3 tries × 2 s = ~6 s window) is live. This phase extends it to a 30 s dungeon-hold.

- Add `_run_hold_timer: SceneTreeTimer` to `net_game.gd`. When a peer disconnects mid-run (`_on_peer_disconnected` fires while `game.in_dungeon` is true), host:
  1. Notifies party: "X dropped — holding the run 30 s." (`_end_notice.rpc` reused).
  2. Starts a 30 s hold timer; does NOT call `_run_end`.
  3. If the peer reconnects within the hold, `_register_player` fires, `_reconcile_players` spawns them at `net_spawn` (dungeon entry Vector3 stored in `layout_loader.gd:251`). Cancel the timer.
  4. If timer expires or all remaining peers leave, call `_run_end(false)`.
- Guest rejoin: after transport reconnect, `_on_connected` fires. If `game.in_dungeon` is true on the host, the host sends the active chart via a new `_rejoin_run.rpc_id(peer, chart)` so the re-joining guest loads the dungeon scene (same seed → identical geometry, foes already puppet).
- Edge case: guest rejoins but the boss room is cleared. The guest spawns at entry and can walk out; no special handling needed for v1.
- **DoD:** Two-process smoke: host starts run with `WYRD_NET_RUN=2`; kill the guest process; relaunch within 30 s; guest rejoins, sees the dungeon, can move to the exit. Transport-reconnect toast visible on host. Headless suites green.
- **Effort:** M

### Phase C-5 — Exit vote + friend-invite UX (S)

Small UX polish that closes the most visible friction points.

- **Exit vote**: replace the silent 5-second grace with an in-world prompt. When the first peer hits the exit, `_end_notice.rpc` fires (already exists). Add a minimal `_show_exit_prompt(who_name)` on each guest's HUD: a small floating label "X stepped through — exit? [E]" using the existing Wyrd UI Kit toast pattern (`player_hud.gd`). If the guest presses Interact (`E`) before `EXIT_GRACE_SEC` runs out, they're teleported to the exit waystone position (not triggering the run end again — `exit_waystone.gd:52` already checks `_used`). When the timer fires normally, run ends for all regardless of guest position.
- **Display name from env fallback**: `net_game.gd:36` already falls back to `"Wayfinder"` if `$USER` is empty. Add an optional `WYRD_DISPLAY_NAME` env var check before the OS fallback so testers can customize their name without code changes.
- **UPnP opportunistic attempt**: add a `_try_upnp()` coroutine called from `host()` that runs `upnp.discover()` + `add_port_mapping()` on a background thread; if it succeeds, prepend the external IP to `local_addresses()` output. Cap the wait at 3 s before falling back. No UI change required — the address row in the Lantern will show the external IP if UPnP worked.
- **DoD:** In a two-process smoke: first exit triggers a HUD prompt on the other peer; guest can press E to warp to exit. Lantern shows an external IP on a network with UPnP-enabled router (manual test only; smoke test verifies the fallback path). Headless suites green.
- **Effort:** S

### Phase C-6 — Party UI frame (M, low-priority)

In-world party frame showing teammate HP bars. Deferred to after Phase C-1 through C-5 are complete and a playtest confirms the need.

- Add a small `PartyHUD` overlay (anchored top-left, below the local HP bar) listing each remote peer: name + HP bar (driven by the dead flag + the `p_hp` value already in the 10 Hz `_net_state` packet). No extra RPC needed — `_net_state` already carries `dead` and position; extend it to carry `p_hp: int` (one int per packet, cheap).
- Kick button in the Lantern (host-only): sends a `leave(reason)` RPC to the target peer's body, then removes from roster.
- Leader indicator: the host name in the Lantern roster gets a "★" prefix. No leader-transfer in v1.
- **DoD:** Two-process smoke shows guest's HP bar in host's party frame; bar empties when guest takes damage. Kick button removes the guest. Headless suites green.
- **Effort:** M

## Dependencies & links

- [[system-player-controller]] — authority guard (`_is_remote`, `_net_state`, `_net_cast`, `_net_take_damage`) lives here; Phase C-1 first-node fixes and C-2 arrow events touch this file directly.
- [[system-combatant-ai]] — `_nearest_player()` and `net_puppet` mode already implemented; Phase C-3 boss telegraphs and C-1 `boss.gd:112` first-node fix land here; `last_hit_peer` attribution for `kill_credit` lives in `combatant.gd`.
- [[system-bosses]] — Phase C-3 telegraph events require small changes to `boss.gd`; party-wipe reset via `_wire_party_reset` already in `layout_loader.gd`.
- [[system-camera]] — camera authority binding (`camera_rig.gd:64–72`) is Phase A shipped; `get_first_node_in_group("player")` fallback at `camera_rig.gd:100` is the one safe remaining call (it only fires if `_acquire_player` retries before NetGame spawns).
- [[system-hud]] — Phase C-5 exit-vote prompt and Phase C-6 party HP frame both extend `player_hud.gd`; whiteout death flow (`_hud.whiteout_in/out`) is already co-op-safe (local-only HUD).
- [[system-dungeon-generation]] — seed-deterministic `DungeonGen` is the mechanism that makes Phase C-4 rejoin at entrance safe: same seed → same geometry on the rejoined guest, no extra data transfer needed.
- [[system-save-load]] — spec 46 pattern "save-on-leave" (per-peer `Game` state); Phase C-4 must not corrupt the host's save when a guest reconnects. The `WYRD_NO_SAVE=1` guard already isolates headless tests.
- [[system-interactables]] — exit waystone `request_end` + `_used` guard already co-op-aware; Phase C-5 exit vote wraps around this.
- [[system-elites]] — elite status-effect replication (extend snapshot batch) is the Phase C-3 sub-task; elite definitions live in `data/elites.gd`.

**Plan.md cross-reference:** Part A combat-feel (P1–P5, SHIPPED) and Part B loop-feel (B0–B7, SHIPPED) are fully upstream. The net-side Phase C work here is orthogonal to Plan.md — it concerns replication correctness, not animation polish or gather/craft feel. Do not duplicate Plan.md's B-phase items.

## Verification

- **Phase C-1**: `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd` + `test_wyrd_loop.gd` green. Manual two-process smoke: `WYRD_NET=host WYRD_NET_RUN=3 godot --path wyrd` in one terminal, `WYRD_NET=join:127.0.0.1 godot --path wyrd` in a second; kill the guest; confirm host world cleans up without crash.
- **Phase C-2**: two-process smoke — fire a skill as guest, confirm host terminal shows the cosmetic arrow fly and damage numbers appear on both screens. No new headless suite required (visual).
- **Phase C-3**: `WYRD_DEV_BOSS=burrow_boar_den WYRD_NET=host WYRD_NET_RUN=2 godot --path wyrd` + guest join; observe boss charge telegraph VFX appears on guest screen before the hit lands.
- **Phase C-4**: two-process smoke — kill guest process mid-run; within 30 s relaunch guest with `WYRD_NET=join:127.0.0.1`; guest should load dungeon scene (same seed). `test_wyrd_dungeon_scene.gd` still green (offline path unchanged).
- **Phase C-5**: two-process smoke — host hits exit; guest receives HUD prompt; guest presses E; both players exit cleanly. UPnP: manual test on a home router.
- **Phase C-6**: two-process smoke — host's party frame shows guest HP decrement on hit. Kick: host presses kick in Lantern; guest returns to offline mode with a session_ended toast.

All tests: run from `wyrd/` directory with `WYRD_NO_SAVE=1`.

## Open questions

- **30 s dungeon hold (Phase C-4)**: should the hold timer pause enemy AI to avoid the guest re-spawning into a mob that cleared the room? Or is "rejoin at entry, loot already gone" acceptable for v1? Recommend the latter (simpler) unless playtests show it feels punishing.
- **Exit vote UX (Phase C-5)**: should the grace timer be configurable per-chart (longer for a big boss room, shorter for an abandoned chart)? Current `EXIT_GRACE_SEC = 5.0` is hard-coded in `net_game.gd:253`.
- **Arrow cosmetic authority (Phase C-2)**: guest arrows replayed on the host are the real shots (they hit enemies). Cosmetic arrows on non-host peers are a separate node. Should cosmetic arrows vanish on impact (collidable) or just play out their travel distance? The no-damage path simplifies the answer but confirm with a playtest.
