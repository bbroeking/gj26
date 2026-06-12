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
