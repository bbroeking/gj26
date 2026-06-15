---
type: design
tags: [system-design, coop]
status: draft
updated: 2026-06-14
sources:
  - "kb/wiki/systems/Multiplayer Co-op.md"
  - "kb/wiki/research/MMO Netcode and Tick Systems.md"
  - "kb/wiki/concepts/Balance Philosophy.md"
  - "kb/wiki/Universe Build-Out Plan.md"
  - "wyrd/scripts/net_game.gd"
  - "wyrd/scripts/game.gd"
  - "wyrd/scripts/boss.gd"
  - "kb/wiki/games/co-op/Deep Rock Galactic.md"
  - "kb/wiki/games/co-op/Helldivers 2.md"
  - "kb/wiki/games/co-op/Monster Hunter World.md"
  - "kb/wiki/games/co-op/It Takes Two.md"
  - "kb/wiki/games/co-op/Barotrauma.md"
---

# Multiplayer Co-op — Deep Design

> Forward-looking deep design. Current-state: [[Multiplayer Co-op]]. Constrained by [[Universe Build-Out Plan]].

## Player fantasy & role in the cozy spine

You are **a Wayfinder walking a friend's remembered way.** The host inscribed the chart; the party crosses the same [[The Waystone]] into the same seed-built place. Co-op is not a raid — it is *company on a walk*. Two to four neighbours gather, cook, chart, and delve together, then come home and grow the village by the same corner. The fantasy this demo protects is **shared stakes without a trinity**: nobody is "the healer," nobody is benched as DPS. Everyone carries the same one verb (the bow), everyone can gather, and the only role asymmetry is the soft flavor of which [[Trades and Leveling|Trade]] you've leaned into (ADR 0005: all four trades level everywhere, so a region cannot "be" the Earthcraft region — and a player cannot "be" the tank). The cozy contract from [[Balance Philosophy]] holds in co-op: never one-shot a friend below 50%, always allow retreat, death is fade-to-bed — not a wipe-and-restart. The demo's job is to make the existing session *correct on every screen*, then stop.

## What ships today (grounded in code)

`net_game.gd` (~289 lines) is at Phase B/C, host-authoritative over `ENetMultiplayerPeer` (DEFAULT_PORT 7777, MAX_PLAYERS 4). `active` is the one switch every system reads; offline the game is byte-identical to its pre-net state (`is_host()`, `_end()`). The roster is a snapshot, not deltas: `players: {peer_id → {name}}`, re-broadcast whole via `_sync_roster.rpc` on every change, then `_reconcile_players()` spawns/frees `NetPlayer<id>` nodes with `set_multiplayer_authority(id)` (the claudecraft set-membership pattern). The run flow works: `start_run(chart)` → `_run_start.rpc` → every peer calls `game.net_enter(chart)` and builds the **seed-identical** dungeon locally (the chart seed drives `layout_loader._rng`, so foes spawn on the same tiles with deterministic `NetFoe<N>` names). Enemy truth streams at `ENEMY_SYNC_HZ = 10.0` as `_enemy_state` (`unreliable_ordered`) batched `name → [pos, hp]`; **absence from a snapshot means dead** — guests despawn silently. Kill credit, per-player loot rolls (`drop_event` → each peer rolls its own affixes), and the 5-second `EXIT_GRACE_SEC` exit notice all route through the host. Per [[MMO Netcode and Tick Systems]], the transports are correct: 12 Hz transform RPC and 10 Hz enemy snapshot both `unreliable_ordered` (drop-and-skip), events (`_kill_credit`, `_run_start`) reliable. **What is NOT done** is the Phase C list in [[Multiplayer Co-op]]: walk-anim sync, reconnect grace, host-out toast, guest damage numbers, party UI, join/leave lines, and — the correctness gap — **boss telegraphs and Poise are host-only**, so a guest watching `boss.gd`'s `_phase_telegraph()` wind-up sees nothing.

## Deep design

### Core mechanics (Wayfinder-flavored)

**Finish Phase C correctness — seven pieces, then stop.**

1. **Walk-anim sync.** The `moving` flag already rides `_net_state(pos, yaw, moving)`. The puppet's `AnimationTree`/blend reads `moving` and lerps locomotion; no new RPC. Idle/walk only — the bow draw is a cosmetic local guess, re-corrected by the cast RPC.
2. **Boss telegraphs + Poise to ALL peers (the correctness requirement).** Boss AI stays host-only, but the *readable* state must replicate. Add a small `_boss_state.rpc` (unreliable_ordered, ~10 Hz, piggybacked on the dungeon's existing send tick) carrying `{phase, telegraph_kind, telegraph_t01, poise01, reeling_t}`. Guests drive the telegraph mesh (`boss.gd` `_telegraph_node`), boss-bar phase tag, and the Poise sub-meter off this — every screen reads the same wind-up and the same ~3s Reeling window from [[Combat]]. This is not polish; without it a guest "couldn't see it coming," which breaks the [[Combat]] reading loop in co-op.
3. **Guest damage numbers.** Damage to a guest's own body is already adjudicated on the owner machine (ward/grit/iframes local). Surface the local number there; for hits the guest deals to host-side foes, the host's `kill_credit`/hit path RPCs the number to the dealer (`_hit_number.rpc_id`). No new authority — just surfacing what's already computed.
4. **30s reconnect grace.** Today `_on_peer_disconnected` erases the roster row immediately. Instead, mark the row `{name, away_since}` and keep the `NetPlayer` body as a sleeping puppet (no input, frozen, faded) for `RECONNECT_GRACE := 30.0`. Re-join with the same display name reclaims the row and re-authorities the body. On timeout, erase and free. The body holding place means an in-flight delve doesn't collapse to a wipe over a flaky wifi blip.
5. **Host-out toast.** `session_ended` is wired; on `server_disconnected` show the Bramblewood-voice line, then drop to a single-player town cleanly (offline = `active=false`, the game already runs identically).
6. **Party UI (the Lantern roster).** Extend the existing Esc **Lantern** panel: roster rows (name, away/here dot, host crown), invite-by-IP, host-only kick. Kit-compliant, ninepatch-passing, with a `WYRD_UI_SHOT` capture surface (per [[Universe Build-Out Plan]] §6). No leader-vote, no role-picker.
7. **Join/leave ambience + the downed-revive.** Story lines (below), and the **Wildcraft "second pour" downed-revive** (below).

**Downed-not-dead, before party-wipe.** The cozy contract forbids a hard wipe. When a player's HP hits 0 *and at least one ally still stands*, they enter **Downed** (kneeling, faded, no input, a 20s bleed-out timer) instead of fade-to-bed. An ally standing in the small revive radius for ~3s pours a **Second Pour** — a Wildcraft-flavored revive that brings them back at 35% HP. Only when **nobody** stands does the existing party-wipe rule fire (gates drop, boss `reset_fight()`, party fades home). This reuses the boss `reset_fight()` and the documented "gates only drop when nobody stands" rule; it adds a downed state, not a new combat system.

> ⚠️ **Naming honesty:** `game.gd` already ships a Wildcraft perk literally named **"Second Pour"** (lv17) that gives a 25% chance of a bonus *crafting* output (`scripts/game.gd:383, 446`). The revive borrows the *flavor* ("the pot had more to give"), not the perk. Either rename one, or make the revive a *visual/voice* echo of the perk available to any Wildcraft-leaning player regardless of level. Resolve before shipping the string.

### Data model & formulas (GDScript-flavored)

| Field | Type | Owner | Notes |
|---|---|---|---|
| `players[id]` | `{name, away_since}` | host truth | `away_since` null = present; set on disconnect for grace window |
| `RECONNECT_GRACE` | `const float := 30.0` | — | body kept as sleeping puppet during window |
| `DOWN_BLEED_SEC` | `const float := 20.0` | each peer (own body) | bleed-out before contributing to wipe check |
| `REVIVE_SEC` | `const float := 3.0` | reviver machine | channel; interrupt resets |
| `REVIVE_HP_FRAC` | `const float := 0.35` | — | flat, cozy; no scaling |
| boss replication | `_boss_state.rpc(d: Dictionary)` | host | `{phase:int, tele_kind:String, tele_t01:float, poise01:float, reeling_t:float}` ~10 Hz unreliable_ordered |
| `away` row TTL | timer | host | on timeout: `players.erase(id)` + `_sync_roster` |

Wipe check (host-evaluated, already partly present): `var standing := count(bodies where not dead and not downed); if standing == 0: party_wipe()`. Downed bodies count as **not standing** but **not dead** — the timer only matters if everyone is down at once. HP scaling per party size stays **off** for the demo (Monster Hunter scales 150–260%; we deliberately do not — the cozy curve from [[Balance Philosophy]] tunes to a generous solo baseline and extra bows are the party's reward, not a tax). This is a tracked balance question, not a silent choice.

### Content to author (worked examples)

Bramblewood-voice strings (route through the lore-grader + string table per [[Universe Build-Out Plan]] §6):

| Event | Line |
|---|---|
| Guest joins town | "*{name} comes up the lane, boots still muddy from the road.*" |
| Guest joins a delve | "*{name} steps through after you — the way holds for two.*" |
| Player downed | "*{name} is on one knee. The pot's not empty yet.*" |
| Second Pour revive | "*You pour what's left of the kettle over {name}. They cough, and stand.*" |
| Player leaves | "*{name} waves from the gate and is gone down the road.*" |
| Host's lantern out | "*The host's lantern has gone out. You find your own way home.*" |
| Reconnect (within grace) | "*{name} finds the path again.*" |

### Edge cases, failure modes, anti-frustration

- **Downed at a sealed boss gate:** bleed-out continues; if the last stander falls, normal wipe → `reset_fight()`. No softlock.
- **Reviver downed mid-channel:** channel cancels; both are down; timers run independently.
- **Reconnect after the run ended:** rejoin lands in town, not a dead instance (roster row reclaim only re-bodies in the current scene).
- **Host leaves mid-delve:** no host migration (DRG ships without it; we accept the same cut). Clean drop to single-player town with the toast — never a frozen client.
- **Two peers same display name:** append peer-id suffix for body naming so node paths stay unique (paths must be identical-by-name across peers — a real invariant in `_reconcile_players`).
- **Telegraph packet lost:** unreliable is correct — next 10 Hz packet supersedes; a one-frame missed wind-up at LAN/Tailscale latency is imperceptible ([[MMO Netcode and Tick Systems]]).
- **Friendly fire:** OFF. Helldivers' permanent FF is its identity; it is the *opposite* of cozy. Not even an affix in demo scope.

## Interlocks

- **[[Combat]]** — Poise/stance-break and boss telegraphs are the demo's one reading mechanic; replicating them is the load-bearing correctness fix. Downed-revive is the co-op shape of the cozy death contract.
- **[[Chart Loop]] / [[Charts]] / [[The Waystone]]** — host sockets the chart; whole party crosses; seed-identical [[Dungeon Generation]] needs no world streaming (the Helldivers lesson: avoid shared persistent state; each run is a self-contained instance).
- **[[Bosses]]** — party-wipe rule differs from solo; the trophy-ritual ([[Items and Gear]]) is currently generous (each peer gets the trophy) — kept on purpose.
- **[[Huntcraft]]** — `kill_credit` already routes Huntcraft XP + Even Breath to the killer's machine.
- **[[Save System]]** — each peer keeps their **own** save; guests never write the host's. This is why **shared persisted data is Horizon** (below).

## Demo scope vs Horizon

**DEMO (build now — finish Phase C, then STOP):** walk-anim sync · boss telegraphs + Poise to all peers (correctness) · guest damage numbers · 30s reconnect grace · host-out toast · party-UI Lantern (roster/invite/kick) · join/leave lines · downed/Second-Pour revive before wipe. Host-authoritative contract **locked in Phase 0** (P7 cut-line: co-op ships only because the crypt + Pale Veins regions it runs in are complete).

**HORIZON (named, NOT built — per §4.6 and §10 of [[Universe Build-Out Plan]]):** the **shared chart-reader seat** (a new authoritative multiplayer subsystem — explicitly post-launch) · party Trade-roles (soft DRG-style "you gather, I cover" without class locks) · the **Charter** (per-party shared logbook) · two-person inscribing · cookfire feast · Well-seat rested-XP · SOS-flare / Friends-Pass (the MHW and It-Takes-Two adoption funnels) · asymmetric room density · party-size HP scaling. **The chart-reader seat is the headline Horizon ambition and is deliberately unspecced** — every specced phase is a magnet for premature work on a tiny team.

**Hard gate before ANY persisted shared data ships:** *how does the Charter/party-logbook survive a host change?* Today there is no host migration and each peer saves only themselves, so a shared per-party record has **no home** when the host's lantern goes out. This must be answered — save-size budget, which peer owns the canonical copy, how it merges on reconnect, what a guest keeps if the host never returns — **before** the Charter or any shared persistence is built. The save schema is versioned (Phase 0 migration ladder) so this can be added later without a destructive reset, but the *answer* is the prerequisite, not the schema.

## Implementation notes

- **Lives in:** `wyrd/scripts/net_game.gd` (roster grace, downed/revive routing, `_boss_state` RPC), `wyrd/scripts/boss.gd` (emit replicable telegraph/Poise state; guests apply it), the player body script (downed state + revive channel), `wyrd/scripts/game.gd` (`notify` toasts — `signal toast` + `pending_toasts` already exist), and the Lantern panel under `wyrd/scripts/ui/` (kit tokens via `wyrd_ui.gd`, `check_ninepatch.py` pass, `tools/capture_ui.sh` surface).
- **Guarded by:** the four headless suites stay green. `test_wyrd_dungeon_scene` and `test_wyrd_transitions` cover the run-build/return path; **add a headless net smoke** using the existing `WYRD_NET=host` / `WYRD_NET=join:<ip>` boot hooks to assert roster reconcile, downed→revive→stand, and that a `_boss_state` apply does not error on a guest. Reuse the real `Game`/`NetGame` autoloads (they load in `--script` mode); `_ready` needs a frame; run `WYRD_NO_SAVE=1`.
- **Perf:** `_boss_state` is a tiny dict at 10 Hz — within the Phase-C "co-op enemy-state RPC batching is checked when Phase C lands" budget. No new continuous streams.

## Open questions

1. **Second Pour name collision** — rename the lv17 craft perk, or make the revive a non-perk flavor echo? (resolve before strings ship)
2. **Party-size HP scaling** — stay off (cozy, extra bows = reward) or a light bump so a 4-stack boss isn't trivial? Balance-sim question, not a silent default.
3. **Trophy generosity** — each peer currently gets the boss trophy. Keep (cozy, "everyone remembers the walk") or make it one-per-party with a hand-off? Interlocks with the [[Items and Gear]] trophy ritual.
4. **Charter host-change persistence** — the named blocker above. No shared persisted data ships until answered.
5. **Reconnect identity** — display-name match is fragile (two "Wayfinder" defaults). A per-session token would be sturdier but adds handshake state.

## See also / Sources

- [[Multiplayer Co-op]] · [[MMO Netcode and Tick Systems]] · [[Combat]] · [[Chart Loop]] · [[Bosses]] · [[Save System]] · [[Balance Philosophy]] · [[Universe Build-Out Plan]]
- Game studies: [[Deep Rock Galactic]] (host-auth, no migration, soft-vs-hard roles) · [[Helldivers 2]] (avoid shared persistent state; FF is anti-cozy) · [[Monster Hunter World]] (SOS-flare drop-in, party HP scaling — both Horizon) · [[It Takes Two]] (Friends-Pass funnel — Horizon) · [[Barotrauma]] (run-time roles without class locks — the Horizon Trade-role model)
- Code: `wyrd/scripts/net_game.gd`, `wyrd/scripts/game.gd`, `wyrd/scripts/boss.gd`
