# GOAL: Co-op works — invite-a-friend solid

**Status:** active goal (set 2026-06-17). Definition of done: two people on
separate machines can light a fire, join, delve a full chart **including the
boss**, see each other move/shoot/take hits/loot, survive a wifi blip, and
finish the run — without desync, stuck states, or error spam.

## Already verified working (2-instance headless, this session)
- Connect over ENet; roster sync; **display names** (C-5 names) propagate.
- **Deterministic shared run** — same seed → identical dungeon on both peers.
- **C-4 mid-run join** — a guest joining mid-dungeon is pulled into the active
  chart and rebuilds it identically (`_rejoin_run`).
- **Enemy snapshot stream** — host → guests, real foe counts replicate (pos+hp).
- **Guest arrows** — `_net_cast` (player_controller.gd:1393) replays casts
  cosmetically on guests (plumbing present; not yet eyeballed).
- **Net-tick guard** — fixed the RPC-before-connected spam (commit 2dee087).

## The work (phased, highest-leverage first)

### Phase 1 — Live windowed acceptance test  ← VISUAL ✅ / combat-eyeball PENDING
2-window windowed capture (commit 88d99b2 added WYRD_SHOT_PATH) confirmed live:
both player bodies render together in the same dungeon with name tags, and the
party HP frame shows both peers. **Still needs a human at the keyboard:** drive
actual combat to eyeball guest damage numbers (C-2), arrows, and the boss
telegraphs in a real fight (the captured characters were idle). Best done as a
real 2-player session (Tailscale) or by driving two windows.
The headless logs can't show what a player sees. Run **two windowed instances**
(`WYRD_NET=host` / `WYRD_NET=join:127.0.0.1`), drive a full session, and capture
both views at key beats. Confirm with eyes: both players visible & moving in
sync, **guest sees host's arrows**, **guest sees damage numbers** when the host
hits a foe (C-2), loot drops & pickup work for both, camera follows each local
player, no desync/stuck. **This phase produces the real remaining bug list** —
everything below is the known-from-code set; the live test finds the rest.
- Driving combat needs input (the headless auto-run leaves players idle) — use
  scripted input or a co-op playtest with the user. C-2 damage numbers are the
  one piece headless could not exercise.

### Phase 2 — Boss host-authority (C-3) — ✅ DONE (commit 4ba2359)
Shipped: the boss was already a net_puppet (pos+hp+death replicate); added
cosmetic replay so guests get the boss bar, arena gates, phase, dodgeable
telegraphs, and live bar HP. test_coop (6/6) in the gate; 2-instance boss-den
smoke builds an identical den on both peers; boss-node authority = host (default,
verified). **Minor followups (non-blocking edge cases):** (a) a guest joining
*mid-boss-fight* misses the one-shot aggro RPC → no bar/gates for that late
joiner (fix: resend boss aggro/phase in the C-4 `_rejoin_run` path); (b) a
telegraph decal can outlive a boss that dies mid-telegraph until the dungeon
unloads (the auto-free tween dies with the boss) — cosmetic leak.

#### (original scope notes)
Today only `NetFoe<N>` bodies get `net_puppet=true` (layout_loader.gd:1094); the
**boss is built separately and is NOT a puppet**, so each guest runs its OWN
boss AI → boss fights desync (and every chart ends in a boss/den). Make the boss
host-authoritative: tag it a net_puppet, include it in the host snapshot stream,
have guests drive it from snapshots + replay its telegraphs cosmetically (the
deferred C-3 "boss telegraph host-sync"). Largest change here — boss.gd +
layout_loader.gd + net_game.gd snapshot batch.

### Phase 3 — Enemy status replication — ✅ DONE (commit e26bcdc)
Snapshot extended to `[pos, hp, flags]`; puppet foes mirror the host's active
status kinds cosmetically (host still owns the DoT). test_coop 10/10; live
2-instance flows 16 foes under the new format, clean.

### Phase 4 — Party flow polish — ✅ DONE (commit c3361ca)
- Party HP frame (C-6): player hp rides `_net_state`; top-left HUD frame shows
  every peer's name + HP bar (co-op only).
- Exit countdown: `run_ending` signal → prominent HUD countdown banner.
- Reconnect: `reconnecting` → same HUD banner. Reconnect logic was already sound
  (3 retries; the guest's own Game persists across the blip; C-4 rejoin guards
  in_dungeon) — no host-side slot-hold needed since state isn't lost.
- test_coop 12/12; 2-instance co-op-dungeon smoke runs the party-HUD path clean.
- **Followup:** HP-bar visual styling (default ProgressBar → kit-styled);
  eyeball the frame/banner in a live windowed session (Phase 1).

### Phase 5 — Internet invite — ✅ DONE (unblocked + documented; commit e1d2a0f)
UPnP was *crashing* every host→quit (SIGABRT, see below) — fixed by draining the
worker before teardown + a 900ms discover timeout. local_addresses() surfaces a
usable IPv4 (verified) and ranks Tailscale (100.x) first. Can't test a real
internet join from here (no router UPnP / second internet machine), so the
**supported invite paths** are:
- **Tailscale / VPN (recommended):** both run Tailscale; host opens the Lantern
  (Esc), copies its 100.x address, friend pastes it into Join. Rock-solid, no
  port-forward, works anywhere.
- **Same LAN:** host shares its 192.168/10.x address; friend on the same network
  joins. No setup.
- **UPnP (opportunistic):** if the router supports it, `_try_upnp` maps the port
  and the external IP appears first in the Lantern. No longer crashes; just may
  not find a mapping on many routers.
- Manual port-forward (DEFAULT_PORT 7777) is the fallback for internet without
  Tailscale/UPnP.

> **The crash (fixed this session):** hosting ran a UPnP probe as a GDScript
> lambda on a WorkerThreadPool task; `~WorkerThreadPool` aborted on that live
> Callable at engine teardown → SIGABRT on EVERY host→exit (7 crash reports in
> ~5h). This was the "engine keeps crashing." Fixed in e1d2a0f; proven by
> revert (exit 134 + fresh crash report) vs fix (exit 0, none).

## Pointers
net_game.gd (host/join/roster/snapshots/rejoin/end-notice) · player_controller
.gd (`_net_send_tick`, `_net_cast`, `_net_state`) · combatant.gd
(`net_apply_state`, net_puppet) · layout_loader.gd (NetFoe tagging, `_build_boss`)
· boss.gd (boss AI). Dev hooks: `WYRD_NET=host|join:<ip>`, `WYRD_NET_RUN=<sec>`.
