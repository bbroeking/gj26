# Implementation notes — 46-multiplayer-coop (Phase A)

## Decisions
- **Hand-rolled 12 Hz transform RPC over MultiplayerSynchronizer** for
  Phase A: an unreliable-ordered `_net_state(pos, yaw, moving)` from the
  authority + a 10×delta lerp on puppets. Synchronizer + replication
  configs in .tscn text would be fiddlier than ~30 lines of GDScript for
  2–4 players; revisit when Phase B syncs enemies (where Spawner /
  Synchronizer earn their keep).
- **The baked scene Player stays for offline** — tests and the shipped
  single-player path are untouched; `NetGame.setup_scene` frees it and
  spawns one body per roster entry (named `NetPlayer<peer_id>`, so node
  paths — and therefore RPC routing — match on every machine).
- **Modal pause became `Game.modal_opened/closed`**: offline it pauses
  the tree exactly as before (zero feel change, suites prove it); in a
  session it only counts, and the local player's input gates on
  `modal_count`. All seven pause sites converted (the scan said six; the
  waystone panel was a seventh).
- **Esc opens "The Lantern"** — host/join/roster/leave, in the kit
  style, with the honest NAT note (LAN / Tailscale). `WYRD_NET=host` /
  `WYRD_NET=join:<ip>` boot hooks exist for dev and made a real
  two-process headless loopback smoke test possible (both sides spawned
  both players, no errors).
- **Dungeons are gated in co-op** (`enter_dungeon` refuses with a toast)
  until Phase B — the town IS Phase A.

## Deviations
- None from the spec's Phase A list; the join-flow "menu panel" landed
  as the Esc Lantern rather than a main menu (the game boots straight
  into town; there is no main menu to put it in).

## Surprises
- **Autoload globals are compile-time-resolved, and the loop test
  compiles `game.gd` from `SceneTree._init` — before autoloads
  register.** Referencing `NetGame` as a bare global in any script a
  test loads that early is a compile error that silently nukes every
  downstream check. `game.gd` and `player_controller.gd` therefore use
  `get_node_or_null("/root/NetGame")` lookups; scripts only ever loaded
  inside scenes (town, camera, the Lantern) keep the ergonomic global.
- ENet + the high-level API needed nothing else: the whole Phase A net
  layer is ~150 lines (NetGame) + ~60 across player/camera/HUD.

## Tradeoffs
- Remote puppets glide (no walk-anim sync yet) — `moving` already rides
  the state RPC; wiring it into the procedural walk loop is Phase B
  polish.
- `camera_rig` retries every 0.2s until the local-authority body exists
  (NetGame spawns after scene `_ready`); a signal would be cleaner than
  a poll, but the poll is 4 lines and self-heals on respawn.

## Followups (Phase B head start)
- Walk-anim on puppets from `_net_moving`.
- Reconnect grace (30s slot hold) — the roster currently drops on
  disconnect immediately.
- Guest toast when the host's lantern goes out mid-session
  (session_ended is wired; the toast lands wherever the HUD is).
- Hitstop `Engine.time_scale` is still global — irrelevant in town
  (no combat), MUST become local-visual before Phase B.

---

# Phase B notes (2026-06-12, same day)

## Decisions
- **Seed-identical enemies, host-authoritative state** — instead of
  spawn-descriptor replication, the chart seed now also seeds the spawn
  RNG (`layout_loader._rng`), so every peer builds the same foes on the
  same tiles with the same elite rolls. Bodies get deterministic names
  (`NetFoe<N>`), guests flag theirs `net_puppet`, and the host streams
  10 Hz batched name→[pos, hp] snapshots. Absence from a snapshot means
  dead (claudecraft set-membership), so despawn needs no message.
- **Guest casts are cosmetic locally, replayed on the host** — the guest
  pays focus/cooldown and fires visually (puppet enemies take no damage);
  the cast forwards to the host, which replays the skill from that
  player's host-side body with the caster's aim + stats (`net_aim`
  override). Trust-the-party model, v1.
- **Damage to a guest forwards to their machine** — the host detects a
  hit on a remote body and RPCs it to the owner, who applies the real
  rules (ward, grit, iframes) locally.
- **Kill credit** — arrows carry `owner_peer`; the host credits the
  killer's machine with the Huntcraft xp + Even Breath refund.
- **Per-player loot** — the host broadcasts kind+rarity drop events;
  every peer rolls its own affixes and spawns its own pickup. Gather
  nodes, chests, and shrines were per-peer for free (seed-built local
  physical objects) — a feature, not a bug, under per-player progression.
- **Party-wipe boss reset** — offline keeps any-death resets; in co-op
  the gates only drop when nobody stands (puppet death edges ride the
  player state RPC so every machine can evaluate the wipe).
- **Exit/abandon stones end the run for the whole party** (host-routed;
  the at-the-stone vote stays Phase C).

## Bug found while wiring
- The spec-45 abandon stone never actually passed `abandoning` into
  `return_to_town` (a failed edit that only presence-tests caught) —
  abandoning was paying full completion XP. Fixed here.

## Verified
- Two-process headless smoke: host + guest cross on the run-start
  broadcast, build the identical crypt (same seed, same 6 foes), and
  the guest receives live enemy snapshots. All four suites green (343).

## Deferred to Phase C
- Other guests seeing a caster's arrows (only host + caster see them).
- Damage numbers on guests for their own hits (hp drops via snapshot).
- Boss telegraph visuals on guests (boss AI is host-only; puppets slide).
- Reconnect grace, exit-stone vote, trophy attribution polish (each peer
  currently receives boss trophies locally — generous, kept on purpose).
