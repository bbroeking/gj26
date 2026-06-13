---
type: source
tags: [multiplayer, networking, save, persistence, source-digest]
status: draft
updated: 2026-06-13
sources: ["docs/specs/46-multiplayer-coop.md", "docs/specs/46-multiplayer-coop-notes.md", "docs/specs/07-godot-evaluation.md", "docs/wyrd-implementation-notes.md", "wyrd/scripts/net_game.gd", "wyrd/scripts/game.gd", "wyrd/scripts/save_game.gd"]
---

# Source Digest — Multiplayer and Save

Digest of the sources ingested to build [[Multiplayer Co-op]] and [[Save System]].

## Sources read

### `docs/specs/46-multiplayer-coop.md`
The design spec for Spec 46: invite-your-friends co-op over host-authoritative ENet. Covers the architectural decision (listen-server, ENet, MultiplayerAPI abstraction), the "claudecraft steals" (proven patterns adopted from a reference TS/websocket MMO), the loot and progression model (per-player everything), pre-work blockers found by a coupling scan, and the three phases (A: town, B: dungeon, C: polish). Includes the "done when" gate for Phase A and the out-of-scope list for v1.
→ Primary source for [[Multiplayer Co-op]]

### `docs/specs/46-multiplayer-coop-notes.md`
Implementation notes for Phase A and Phase B, written on 2026-06-12. Records decisions (hand-rolled 12 Hz RPC over Synchronizer; baked scene Player stays for offline; modal pause became `Game.modal_opened/closed` with seven sites, not six; Esc opens The Lantern rather than a main menu; dungeons gated until Phase B). Phase B decisions: seed-identical enemies, guest-cast cosmetic replay, damage-to-guest forwarded to owner, `owner_peer` kill credit, per-player loot rolls, party-wipe boss reset, exit/abandon host-routed. Surfaced a bug: spec-45 abandon stone was paying full completion XP — fixed here.
→ Primary source for [[Multiplayer Co-op]]

### `docs/specs/07-godot-evaluation.md`
The original Godot evaluation spec (engine selection, project bootstrap, asset wiring). Not directly relevant to multiplayer or save, but establishes the symlink model (`wyrd/models → ../models`) and the Godot 4.6 project structure that the multiplayer layer builds on. Confirms GDScript as the language choice.
→ Background context only; no wiki pages updated from this source.

### `docs/wyrd-implementation-notes.md`
Companion doc to the design doc, recording what was actually built, decisions made during implementation, the adversarial review round, known gaps, and Session 3 additions (economy, trophy chain, town environment). Notes the save roundtrip caveat (`_test_save_roundtrip` touches the real save path) and the WYRD_NO_SAVE flag requirement for tests.
→ Supporting source for [[Save System]]

### `wyrd/scripts/net_game.gd`
The `NetGame` autoload — full implementation of Phase A and Phase B networking (~290 lines). Key facts confirmed by code: `DEFAULT_PORT = 7777`, `MAX_PLAYERS = 4`, `PlayerScene` preloaded, `active` flag is the session switch, roster is a `peer_id → {name}` dict broadcast whole on every change, player nodes named `NetPlayer<peer_id>`, `EXIT_GRACE_SEC = 5.0`, `ENEMY_SYNC_HZ = 10.0`, enemy snapshots use set-membership (absence = dead), kill credit routes Huntcraft XP and Even Breath refund, drop events broadcast kind+rarity and each peer rolls its own affixes. `_end_notice` formats the toast "X steps through the waystone — the run ends shortly."
→ Primary source and code tiebreaker for [[Multiplayer Co-op]]

### `wyrd/scripts/game.gd`
The `Game` autoload — cross-scene state, trades, satchel, chart case, run flow, modal accounting. Confirms: `modal_opened/closed` counter pattern, `local_player()` uses authority check in co-op, `net_active()` uses `get_node_or_null` (not bare global), `enter_dungeon` checks `is_host()` in co-op and calls `net.start_run(chart)`, `net_enter(chart)` is the guest-side scene change entry point, `return_to_town` is called by `_run_end` RPC passing `local_player()`. Save fields confirmed: trades, materials, charts, gold, summit_cleared, muted, loadout, discovered_inks, seen_hints, tutorial_step, player_hp, inventory, equipment. Buffs are explicitly NOT saved.
→ Primary source for [[Save System]]

### `wyrd/scripts/save_game.gd`
The `SaveGame` class — serialization to `user://wayfinder_save.json`, schema version `1`, `_encode`/`_decode` for `Vector2i` and `Color` JSON wrappers, backwards-compat patches for Huntcraft and ink discovery. Confirms `WYRD_NO_SAVE` disables `persistence_enabled`. Stale comment references `wyrd_save.json` but `SAVE_PATH` constant is `wayfinder_save.json` — code wins.
→ Primary source for [[Save System]]

## Contradictions and flags

- `save_game.gd` line-8 comment says `user://wyrd_save.json`; `SAVE_PATH` constant says `user://wayfinder_save.json`. Flagged in [[Save System]].
- `46-multiplayer-coop.md` says "six modals pause the tree"; notes confirm seven (Waystone panel was a seventh). Flagged in [[Multiplayer Co-op]].
- Spec 46 called for a main-menu "menu panel" for host/join; landed as Esc Lantern in town (no main menu exists). Flagged in [[Multiplayer Co-op]].
- `Hitstop` `Engine.time_scale` is still global as of Phase B (not yet made local-visual). Flagged as a pre-work blocker not yet resolved in [[Multiplayer Co-op]].

## Wiki pages fed

- [[Multiplayer Co-op]] — created
- [[Save System]] — created
