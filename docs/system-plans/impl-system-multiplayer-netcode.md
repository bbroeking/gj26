---
title: Multiplayer & Netcode — Implementation Plan
parent: "[[system-multiplayer-netcode]]"
domain: Multiplayer
type: implementation-plan
status: ready-to-build
effort: M
tags: [wayfinder, impl]
---

# Multiplayer & Netcode — Implementation Plan

> Build doc for [[system-multiplayer-netcode]]. Phase C polish is done when all co-op sessions show guest arrows, damage numbers, boss telegraphs, a 30 s dungeon hold, a graceful exit vote, and zero `get_first_node_in_group("player")` calls outside of authoritative-AI contexts.

## Definition of done

- All 7 `get_first_node_in_group("player")` call sites in non-AI scripts replaced with `Game.local_player()` or `_nearest_player()`.
- A two-process `WYRD_NET` smoke with `WYRD_DEV_BOSS=burrow_boar_den` shows: guest arrows visible to host, damage numbers on both screens, boss telegraph VFX on the guest screen, 30 s dungeon hold on guest drop + rejoin, exit-vote HUD prompt on the peer who did NOT step through.
- `WYRD_DISPLAY_NAME` env var sets the in-session name.
- Opportunistic UPnP prepends external IP to the Lantern address row.
- `test_wyrd_loop.gd`, `test_wyrd_dungeon_scene.gd`, `test_wyrd_transitions.gd` all green (WYRD_NO_SAVE=1) after every phase.

## Preconditions / dependencies

- [[impl-system-combatant-ai]] — `_nearest_player()` already implemented in `combatant.gd:233`; Phase C-1 boss fix mirrors it.
- [[impl-system-bosses]] — telegraph node authoring (`boss.gd:165–178`, `_begin_attack:194`) is the hook for C-3 boss-event RPC.
- [[impl-system-hud]] — Phase C-5 exit-vote prompt extends `player_hud.gd`; `_hud.whiteout_in/out` is already co-op-safe.
- [[impl-system-elites]] — elite status-flag extension to enemy snapshot batch (C-3 sub-task) requires `data/elites.gd` status IDs.
- [[impl-system-dungeon-generation]] — seed-deterministic dungeon is the safety invariant that makes C-4 rejoin-at-entrance safe (same seed → same layout, no extra data transfer).
- [[impl-system-save-load]] — Phase C-4 must not corrupt the host save; `WYRD_NO_SAVE=1` guard already isolates headless tests.
- [[impl-system-interactables]] — `exit_waystone.gd` `_used` guard and `interact()` are the seam for the C-5 exit-vote warp.
- Phase A and Phase B are SHIPPED. Do not re-implement `_net_state`, `_net_cast`, `_enemy_state`, or `kill_credit`; build on top.

## Tasks (ordered)

### Phase C-1 — Residual first-node sweep (prerequisite to all later phases)

1. **Fix `boss.gd:112` initial-target grab** — `boss.gd:_tick_ai`. Replace `get_tree().get_first_node_in_group("player")` with the inherited `_nearest_player()` from `combatant.gd:233` (call it as `_nearest_player()`; Boss extends Combatant). One-liner swap; no logic change for single-player. _Verify:_ `test_wyrd_dungeon_scene.gd` green; two-process smoke — host spawns boss, guest is picked as target when nearest. _Effort:_ S.

2. **Fix `layout_loader.gd:1145` walk-to post-dungeon** — `layout_loader.gd:_position_player`. Replace `get_tree().get_first_node_in_group("player")` with `var game := get_node_or_null("/root/Game"); var player: Node = game.local_player() if game != null else null`. The function already returns if `player == null`, so the null path is safe. _Verify:_ `test_wyrd_dungeon_scene.gd` green; single-player dungeon entry positions the player at the entry tile. _Effort:_ S.

3. **Fix `game.gd:255` loadout-apply** — `game.gd:set_loadout`. Replace `get_tree().get_first_node_in_group("player")` with `local_player()` (already defined at `game.gd:80`). This is an in-class call so no lookup needed. _Verify:_ `test_wyrd_loop.gd` green; test `Game.set_loadout(["basic_shot"])` does not error in headless. _Effort:_ S.

4. **Fix `town.gd:117,121,139,341` dev-shot + position writes** — `town.gd:_ready` (lines 117, 121, 139) and `town.gd:_position_player` (line 341). Replace each `get_first_node_in_group("player")` with `get_node_or_null("/root/Game").local_player()` (null-guarded). The WYRD_UI_SHOT paths are dev-only so guest-vs-host confusion is low-risk, but the fix is cheap and removes the smell. `_position_player` at line 341 sets the spawn for the local player only — `local_player()` is correct. _Verify:_ `test_wyrd_transitions.gd` green; `WYRD_UI_SHOT=trades godot --path wyrd` still opens the trades panel. _Effort:_ S.

5. **Fix `player_hud.gd:286` button dispatch fallback** — `player_hud.gd` (line 285–286). The guard already tries `game.local_player()` first; the fallback `get_first_node_in_group("player")` is unreachable in practice but is still a code smell. Remove the fallback entirely: `var player: Node = game.local_player() if game != null else null`. _Verify:_ `test_skills.gd` green (exercises hotbar dispatch path). _Effort:_ S.

6. **Fix `ui/cursor.gd:67` aim fallback** — `ui/cursor.gd`. Replace `get_first_node_in_group("player")` with `get_node_or_null("/root/Game").local_player()` (null-safe). Cursor aim must track the local player, not an arbitrary one. _Verify:_ Single-player: cursor still tracks the player. Two-process smoke: host cursor does not snap to guest position. _Effort:_ S.

7. **Verify guest-death party-wipe path** — no code change; read-through verification only. `_net_state` sets `dead=true` on puppet (`player_controller.gd:1317–1319`); `_party_reset_check` in `layout_loader.gd:712–726` iterates `get_nodes_in_group("player")` (correct — iterates all, not first). Confirm by running two-process smoke: kill guest; host-side party-wipe check fires only when host also dies. Log `[net] party wipe` from layout_loader. _Verify:_ two-process smoke as described. No code change needed unless the smoke reveals a bug. _Effort:_ S.

---

### Phase C-2 — Arrow visibility + damage number events

8. **Add `_arrow_event` cosmetic RPC to `player_controller.gd`** — `player_controller.gd:_net_forward_cast` (line 1366). Before the `_net_cast.rpc(...)` call, also call a new `@rpc("any_peer","unreliable_ordered") func _arrow_event(origin: Vector3, dir: Vector3, skill: String) -> void` that spawns a cosmetic arrow on every non-authoritative peer. The cosmetic arrow is the same Arrow scene but with `damage = 0`, `effects = []`, `owner_peer = 0`, added to group `"cosmetic_arrow"` so it does not interact with the hitbox system. Sketch:
   ```gdscript
   @rpc("any_peer", "unreliable_ordered")
   func _arrow_event(origin: Vector3, dir: Vector3, skill: String) -> void:
       if is_multiplayer_authority():
           return   # the authority already fired the real arrow
       var ArrowScene := preload("res://scripts/arrow.gd") # no class_name — use preload
       # spawn cosmetic node: damage=0, effects=[], group "cosmetic_arrow"
   ```
   Call `_arrow_event.rpc(global_position, aim_dir(), current_skill_type)` from `_net_forward_cast` before the existing `_net_cast.rpc`. _Verify:_ two-process smoke — fire guest BasicShot; host terminal sees the cosmetic arrow fly. _Effort:_ S.

   > Note: Arrow scene is `res://scenes/Arrow.tscn` — check with `find wyrd/scenes -name "Arrow*"` before coding. If absent, fall back to `preload("res://scripts/arrow.gd")` and instantiate directly.

9. **Add `dmg_event` RPC to `net_game.gd`** — `net_game.gd` (after line 371, end of drop_event block). Add:
   ```gdscript
   func dmg_event(pos: Vector3, amount: int, kind: String) -> void:
       if is_host():
           _dmg_event.rpc(pos, amount, kind)

   @rpc("authority", "unreliable_ordered")
   func _dmg_event(pos: Vector3, amount: int, kind: String) -> void:
       # re-use combatant._spawn_damage_number pattern locally
       var label := Label3D.new()
       label.text = str(amount)
       # ... same pattern as combatant.gd _spawn_damage_number
   ```
   Call `NetGame.dmg_event(global_position, dealt, "normal")` from `combatant.gd:take_damage` (line ~216) when `NetGame.active` and `multiplayer.is_server()`, so only the authoritative host broadcasts it. _Verify:_ two-process smoke — guest fires, enemy takes damage; damage number appears on both screens. _Effort:_ S.

   > `combatant.gd:_spawn_damage_number` — confirm it exists at approx line 251 before wiring the call site; if it is inline at `net_apply_state`, extract it first.

10. **Confirm `_spawn_damage_number` is a callable method** — `combatant.gd`. If `_spawn_damage_number` is inlined inside `net_apply_state` (line ~251), extract it into a standalone `func _spawn_damage_number(amount: int, tier: String) -> void` so both `net_apply_state` and the new `_dmg_event` receiver can call it. _Verify:_ `test_wyrd_dungeon_scene.gd` still green after refactor. _Effort:_ S.

---

### Phase C-3 — Boss telegraphs on guests

11. **Add `boss_event` RPC to `net_game.gd`** — `net_game.gd` (after `drop_event` block). Add:
    ```gdscript
    func boss_event(event_name: String, data: Dictionary) -> void:
        if is_host():
            _boss_event.rpc(event_name, data)

    @rpc("authority", "call_local", "reliable")
    func _boss_event(event_name: String, data: Dictionary) -> void:
        # find the active boss puppet and call net_boss_event on it
        for b in get_tree().get_nodes_in_group("boss"):
            if b.has_method("net_boss_event"):
                b.net_boss_event(event_name, data)
    ```
    _Verify:_ no crash; log fires in headless. _Effort:_ S.

12. **Wire telegraph start/end calls in `boss.gd`** — `boss.gd:_begin_attack` (line 210–221) and `boss.gd:_resolve_attack` (line 242). At the start of `_telegraphing = true` path in `_begin_attack`, call:
    ```gdscript
    var net := get_node_or_null("/root/NetGame")
    if net != null and net.has_method("boss_event"):
        net.boss_event("telegraph_start", {"dur": _tele_total, "kind": _pending,
            "origin": global_position, "dir": _charge_dir if _pending == "charge" else Vector3.ZERO})
    ```
    At `_resolve_attack` entry, call `boss_event("telegraph_end", {})`. Also wire `_begin_lunge` (line 230) the same way. _Verify:_ Two-process smoke with `WYRD_DEV_BOSS=burrow_boar_den`: guest receives `[boss_event telegraph_start]` log before the hit resolves. _Effort:_ S.

13. **Add `net_boss_event` receiver to `boss.gd`** — `boss.gd` (new method). On guests (non-server), replay the telegraph VFX only — no AI state change:
    ```gdscript
    func net_boss_event(event_name: String, data: Dictionary) -> void:
        if multiplayer.is_server():
            return   # host drives its own state machine; no re-entry
        if event_name == "telegraph_start":
            var kind: String = String(data.get("kind", ""))
            var origin: Vector3 = data.get("origin", global_position)
            var dir: Vector3 = data.get("dir", Vector3.FORWARD)
            var dur: float = float(data.get("dur", 0.6))
            _tele_total = dur
            _tele_t = dur
            _telegraphing = true
            _pending = kind
            if kind == "charge" or kind == "lunge":
                _charge_dir = dir
                _telegraph_node = _make_line_telegraph(origin, dir,
                    CHARGE_RANGE if kind == "charge" else LUNGE_RANGE,
                    CHARGE_WIDTH if kind == "charge" else LUNGE_WIDTH)
            else:
                _telegraph_node = _make_telegraph(origin,
                    SWEEP_RADIUS if kind == "sweep" else STOMP_RADIUS)
        elif event_name == "telegraph_end":
            _telegraphing = false
            if _telegraph_node != null:
                _telegraph_node.queue_free()
                _telegraph_node = null
    ```
    Guests drive the telegraph timer visually from `_physics_process` — the existing `_telegraphing` branch already handles the fade (`boss.gd:165–178`), so this piggybacks on it. Guests must NOT call `_resolve_attack()` from the timer path; guard: `if net_puppet: return` before `_resolve_attack()`. _Verify:_ Two-process smoke: guest sees charge corridor glow before the boss moves. _Effort:_ M.

14. **Extend enemy snapshot to carry `status_flags` int** — `net_game.gd:_process` (line 312) and `combatant.gd:net_apply_state`. Change the snapshot array from `[pos, hp]` to `[pos, hp, status_flags_int]` where `status_flags_int` encodes active status IDs as a bitmask (one bit per status kind, defined in `data/elites.gd`). On `net_apply_state`, compare old vs new flags; spawn/remove the matching elite VFX node if the bit changed. This is an additive array index change — use `int(st[2]) if st.size() > 2 else 0` on the guest side for backwards compat during rollout. _Verify:_ `test_wyrd_dungeon_scene.gd` green (array size guard). Two-process smoke with an elite foe: guest sees the status VFX appear when the host's elite gets it. _Effort:_ M.

---

### Phase C-4 — In-dungeon reconnect grace + rejoin at entrance

15. **Store dungeon entry Vector3 on `net_game.gd`** — `net_game.gd`. Add `var _dungeon_entry := Vector3.ZERO`. In `net_game.gd:_run_start` (line 246), after `game.net_enter(chart)` resolves, set `_dungeon_entry = game.get("layout").net_spawn` if available; alternatively hook `layout_loader._position_player` to write it via a signal or direct property: `NetGame._dungeon_entry = _entry_pos` at `layout_loader.gd:1148` (after `_entry_pos` is set). _Verify:_ log `[net] dungeon_entry stored: %v` in `start_run`; confirm non-zero in two-process smoke. _Effort:_ S.

16. **Add `_run_hold_timer` logic to `net_game.gd:_on_peer_disconnected`** — `net_game.gd:_on_peer_disconnected` (line 159). When the host detects a disconnect mid-dungeon:
    ```gdscript
    func _on_peer_disconnected(id: int) -> void:
        if multiplayer.is_server():
            var game := get_node_or_null("/root/Game")
            if game != null and bool(game.in_dungeon) and not _ending:
                var who: String = peer_name(id)
                _end_notice.rpc("%s dropped — holding the run 30 s." % who)
                var t: SceneTreeTimer = get_tree().create_timer(30.0)
                t.timeout.connect(func() -> void:
                    if active and bool(game.in_dungeon):
                        _run_end.rpc(false))
                _hold_peer_id = id
                _hold_timer = t
            players.erase(id)
            _sync_roster.rpc(players)
            _apply_roster()
    ```
    Add `var _hold_peer_id := 0` and `var _hold_timer: SceneTreeTimer = null` to net_game state. _Verify:_ Two-process smoke: kill guest process mid-run; host toast says "holding 30 s"; host run does NOT end immediately. _Effort:_ S.

17. **Cancel hold timer on peer reconnect** — `net_game.gd:_on_connected` and `_register_player`. When `_register_player` fires and the new peer matches `_hold_peer_id`, cancel `_hold_timer` and rejoin them at the dungeon entry. Call `_rejoin_run.rpc_id(id, _active_chart)` where `_active_chart` is stored from the last `start_run` call (`var _active_chart: Dictionary = {}`). Add:
    ```gdscript
    @rpc("authority", "reliable")
    func _rejoin_run(chart: Dictionary) -> void:
        var game := get_node("/root/Game")
        game.net_enter(chart)   # same seed → deterministic rebuild
    ```
    After spawn, position the re-joined player at `_dungeon_entry`. _Verify:_ Two-process smoke: kill guest; relaunch within 30 s; guest loads dungeon scene and appears at entry tile. _Effort:_ M.

---

### Phase C-5 — Exit vote + friend-invite UX

18. **Add exit-vote HUD prompt to `player_hud.gd`** — `player_hud.gd` (new method `show_exit_prompt(who_name: String)`). Wire it from `net_game.gd:_end_notice` (line 280–284) by adding a call to the local player's HUD:
    ```gdscript
    @rpc("authority", "call_local", "reliable")
    func _end_notice(who_name: String) -> void:
        # existing notify call unchanged
        var game := get_node("/root/Game")
        game.notify(...)
        # NEW: show the follow-exit prompt on the guest's HUD
        var pl: Node = game.local_player()
        if pl != null and pl.has_method("show_exit_prompt"):
            pl.show_exit_prompt(who_name)
    ```
    In `player_hud.gd:show_exit_prompt`, display a temporary Label (Wyrd UI Kit toast style) "X steps through — press [E] to follow". If the player presses Interact (`E`) during `EXIT_GRACE_SEC`, call `exit_waystone.interact(player)` on the nearest `ExitWaystone` node in group. Use a `var _exit_prompt_active := false` flag; clear it in `_input` after E or after `EXIT_GRACE_SEC`. _Verify:_ Two-process smoke: host steps through; guest sees HUD prompt; guest presses E; both exit. _Effort:_ S.

19. **Add `WYRD_DISPLAY_NAME` env var fallback** — `net_game.gd:_ready` (line 36). After `display_name = OS.get_environment("USER")`, prepend a check:
    ```gdscript
    display_name = OS.get_environment("WYRD_DISPLAY_NAME")
    if display_name == "":
        display_name = OS.get_environment("USER")
    if display_name == "":
        display_name = "Wayfinder"
    ```
    _Verify:_ `WYRD_DISPLAY_NAME=Thorn godot --path wyrd` → Lantern shows "Thorn" in the roster. _Effort:_ S.

20. **Add opportunistic UPnP in `net_game.gd:host`** — `net_game.gd:host` (after `active = true`, line 77). Add a detached coroutine:
    ```gdscript
    func host(port: int = DEFAULT_PORT) -> bool:
        # ... existing peer setup unchanged ...
        _try_upnp(port)
        return true

    func _try_upnp(port: int) -> void:
        var upnp := UPNP.new()
        var result: int = await get_tree().create_timer(3.0).timeout  # cap wait
        # run discover on thread to avoid blocking; Godot 4 WorkerThreadPool:
        WorkerThreadPool.add_task(func() -> void:
            var r: int = upnp.discover()
            if r == UPNP.UPNP_RESULT_SUCCESS:
                upnp.add_port_mapping(port)
                var ext: String = upnp.query_external_address()
                if ext != "" and ext != "0.0.0.0":
                    call_deferred("_upnp_found", ext)
        )

    func _upnp_found(ext_ip: String) -> void:
        _external_ip = ext_ip
        roster_changed.emit()   # triggers Lantern to refresh address row
    ```
    Add `var _external_ip := ""`. In `local_addresses()`, prepend `_external_ip` if non-empty. Cap the worker thread by storing the task ID and ignoring its result after `leave()`. _Verify:_ On a UPnP-capable router: Lantern shows an external IP. On a non-UPnP network: no crash, no hang beyond 3 s (fallback path). _Effort:_ S.

---

### Phase C-6 — Party UI frame (deferred; low-priority)

21. **Extend `_net_state` RPC to carry `p_hp: int`** — `player_controller.gd:_net_tick_send` (line ~1305) and `_net_state` (line 1309). Add `p_hp: int = 0` parameter to the RPC signature; send `int(hp)` from the authority. On puppet receive, store `_net_peer_hp := p_hp` for the party frame. Backwards-compat: default 0 means "not tracked yet" in older builds. _Verify:_ `test_wyrd_dungeon_scene.gd` green; no type error from Variant mismatch. _Effort:_ S.

22. **Add `PartyHUD` overlay to `player_hud.gd`** — `player_hud.gd`. Add a small VBoxContainer anchored top-left (below local HP bar) that listens to `NetGame.roster_changed` and builds one row per remote peer: name label + ProgressBar driven by `_net_peer_hp / hp_max`. Update on every `_net_state` receive via a signal `peer_hp_changed(id, hp, hp_max)` emitted from `player_controller.gd`. _Verify:_ Two-process smoke: host's overlay shows guest HP bar emptying on damage. _Effort:_ M.

23. **Kick button in Lantern (host-only)** — `scripts/ui/system_menu.gd`. For each row in the roster list that is not the local peer, show a small "✕" button (host-only visible). On press, call `NetGame.kick(id)` which calls `leave("You were removed from the party.")` on the target peer via `@rpc("authority")`. _Verify:_ Two-process smoke: host clicks kick; guest sees session_ended toast; host roster updates. _Effort:_ S.

## First commit (smallest shippable slice)

**Tasks 1–7 (Phase C-1, first-node sweep).**

PR acceptance: all 7 `get_first_node_in_group("player")` sites replaced; `test_wyrd_loop.gd`, `test_wyrd_dungeon_scene.gd`, `test_wyrd_transitions.gd`, `test_skills.gd` all green; two-process smoke with guest kill shows no wrong-player targeting. This is safe to ship independently — no new RPCs, no logic change, pure bugfix.

## Test & verification plan

**Headless suites** (run from `wyrd/` with `WYRD_NO_SAVE=1`):

```bash
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_transitions.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd
```

Run after every task. No new headless suites are required — two-process smoke tests cover the visual/network surface.

**Two-process smoke recipes** (run from repo root):

| Phase | Terminal A | Terminal B | Pass criterion |
|-------|-----------|-----------|----------------|
| C-1 | `WYRD_NET=host WYRD_NET_RUN=3 godot --path wyrd` | `WYRD_NET=join:127.0.0.1 godot --path wyrd` — kill B | Host world cleans up; no crash |
| C-2 | host (above) | guest fires BasicShot | Both screens show arrow fly + damage number |
| C-3 | `WYRD_NET=host WYRD_DEV_BOSS=burrow_boar_den godot --path wyrd` | guest joins | Guest sees charge corridor glow before impact |
| C-4 | host in dungeon | kill B process; relaunch within 30 s | Guest spawns at entry tile |
| C-5 | host steps through exit | guest receives prompt | Guest presses E; both exit cleanly |

**Screenshot/playtest** for C-3 telegraph visibility and C-5 UPnP external IP: manual only (visual; no headless path).

## Risks & open questions

- **Arrow scene path (Task 8)**: Arrow node may be at `res://scenes/Arrow.tscn` (scene) or only `res://scripts/arrow.gd` (script). Confirm with `find wyrd/scenes -name "Arrow*"` before coding; if the scene is absent, the cosmetic arrow must be built procedurally from the script or the Arrow scene must be extracted.
- **`_spawn_damage_number` existence (Task 10)**: The parent note cites `combatant.gd:251` as the site — confirm it is a named callable before wiring `NetGame.dmg_event`. If inlined, Task 10 (extraction) becomes a prerequisite for Task 9.
- **30 s dungeon hold + mob AI (Task 16)**: the hold does NOT pause enemy AI. A re-joining guest may enter a room where all enemies are dead or already pursuing the host at the wrong side of the map. For v1 this is acceptable ("rejoin at entry, loot already gone"); recommend deferring AI-freeze to a post-demo patch based on playtest feedback. See [[system-multiplayer-netcode]] open question.
- **UPnP thread safety (Task 20)**: `WorkerThreadPool.add_task` with a lambda that calls `call_deferred` is the Godot 4 pattern; confirm there is no UPNP class thread-safety caveat in Godot 4.6 before shipping. The 3 s cap is conservative but safe.
- **Guest telegraph re-entry (Task 13)**: the guest's `_physics_process` runs the `_telegraphing` branch which calls `_resolve_attack()` on timer. The guard `if net_puppet: return` before `_resolve_attack` prevents the guest from applying damage or setting AI state. Confirm `net_puppet` is always `true` on the boss guest-side copy — it is set in `layout_loader.gd:1041` for all `NetFoe<n>` nodes, but `boss.gd` extends Combatant and the same `net_puppet := false` default applies. Layout_loader must set `net_puppet = true` on the boss puppet explicitly; verify this is already wired or add it.
- **Exit vote grace overlap (Task 18)**: if the host is the first to step through, `_end_notice` fires `call_local` — the host will also see its own exit prompt. Guard: `if is_multiplayer_authority() and not _is_remote: return` inside `show_exit_prompt` (the host's body is the authority; the prompt is only for peers who haven't exited yet).
