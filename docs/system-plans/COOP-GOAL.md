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

### Phase 1 — Live windowed acceptance test  ← START HERE
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

### Phase 4 — Party flow polish
- Exit/party flow: `_end_notice` is a toast (net_game.gd:321) — add an
  interactive follow/exit-vote HUD prompt so the party leaves together cleanly.
- Reconnect robustness: guest auto-reconnect exists (`_reconnect_left`); test a
  real mid-run drop → auto-reconnect → rejoin, and add a host-side slot-hold if
  the slot isn't preserved.
- C-6 party HP frame (see allies' health) — low priority.

### Phase 5 — Internet invite (real friends, not just LAN)
UPnP/external-IP path (`_try_upnp`) can't be tested on localhost. Verify a real
internet join (or document the Tailscale/LAN path as the supported route).

## Pointers
net_game.gd (host/join/roster/snapshots/rejoin/end-notice) · player_controller
.gd (`_net_send_tick`, `_net_cast`, `_net_state`) · combatant.gd
(`net_apply_state`, net_puppet) · layout_loader.gd (NetFoe tagging, `_build_boss`)
· boss.gd (boss AI). Dev hooks: `WYRD_NET=host|join:<ip>`, `WYRD_NET_RUN=<sec>`.
