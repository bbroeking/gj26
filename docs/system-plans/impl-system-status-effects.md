---
title: Status Effects — Implementation Plan
parent: "[[system-status-effects]]"
domain: Player & Abilities
type: implementation-plan
status: ready-to-build
effort: M
tags: [wayfinder, impl]
---

# Status Effects — Implementation Plan

> Build doc for [[system-status-effects]]. Player visual parity (tick-pulse + HUD pip row), `marked` suffix fix, cleanse-path wiring, and multiplayer status sync are all green; `test_statuses.gd` and `test_player_status.gd` are in the standard gate.

## Definition of done

- A burning/bleeding player produces an orange/red mesh-tint pulse on every DoT tick.
- A row of coloured drain-arc pips above the HP globe reflects every active player status; pips appear on `apply_status` and vanish when the status expires.
- `marked` appears correctly in the HP-bar suffix if ever applied to the player.
- Consuming a `quickroot_tonic` while rooted/snared immediately clears those statuses.
- In co-op, a guest standing next to a Sunlit elite takes burn (HP drain + HUD pip visible on guest).
- `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_statuses.gd` and `test_player_status.gd` both exit 0 and appear in CLAUDE.md's standard run order.

## Preconditions / dependencies

- [[impl-system-combat-juice-vfx]] — `HitFeedback.tick_pulse` (hit_feedback.gd:74) is already shipped and tested; Phase 1 of this plan calls it from the player side.
- [[impl-system-hud]] — `player_hud.gd` GlobeGauge class (`_draw`-on-Control pattern) is live; the pip strip is a sibling Control added inside `player_hud.gd`.
- [[impl-system-multiplayer-netcode]] — `net_game.gd` RPC patterns (host-authoritative, `@rpc("authority","call_local","reliable")`) are established; Phase 3 adds one new RPC.
- `status_effect.gd` exists at `wyrd/scripts/status_effect.gd` (pure-data RefCounted, lines 1–19). No changes needed to it until Phase 4.
- `test_player_status.gd` exists at `wyrd/test_player_status.gd` (P1–P4 passing). New assertions P5–P7 are added here in Phases 1–3.
- `test_statuses.gd` exists at `wyrd/test_statuses.gd` (T1–T7 passing). No new assertions needed; it is promoted into the gate in Phase 4.
- `combatant.gd` `STATUS_COLOR` palette (lines 89–95) is the canonical colour source; player_controller.gd and player_hud.gd must read from a shared constant rather than duplicating — resolved in Phase 4 (registration point).
- Plan.md Part A (hit-flash / HitFeedback pipeline) is **shipped**; do not re-plan it. Plan.md Part B (cozy verb loop) is orthogonal.

## Tasks (ordered)

### Phase 1 — Player visual parity + `marked` fix

**1. Add `marked` to `STATUS_WORD`**
`player_controller.gd:1514` — `STATUS_WORD` dict.
Add `"marked": "marked"` as the fifth entry so the HP-bar suffix doesn't fall back to the raw string when any future path applies marked to the player.
```gdscript
const STATUS_WORD := {
    "burn": "burning", "bleed": "bleeding",
    "snared": "snared", "root": "rooted", "marked": "marked",
}
```
_Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_player_status.gd` exits 0 (existing P1–P4 must still pass). _Effort:_ S.

---

**2. Wire `HitFeedback.tick_pulse` on player DoT ticks**
`player_controller.gd:1572` — `_apply_tick_damage`.
The player has a single `_mesh: Node3D` (line 90) and no `_flash_t` / `apply_flash` like combatant does. Strategy: add a `_flash_t: float` member and a minimal `apply_flash(duration, color)` helper that tweens the mesh's material albedo mod, then call `HitFeedback.tick_pulse(self, kind)` from `_tick_statuses` after `_apply_tick_damage` returns (mirroring combatant.gd line 567).

Add to member vars block (~line 90):
```gdscript
var _flash_t: float = 0.0
```

Add method after `_apply_tick_damage` (~line 1579):
```gdscript
func apply_flash(duration: float, color: Color) -> void:
    _flash_t = duration
    if _mesh != null:
        var tw := create_tween()
        tw.tween_property(_mesh, "modulate", color, 0.0)
        tw.tween_property(_mesh, "modulate", Color.WHITE, duration)
```

In `_tick_statuses` (~line 1562), after the existing `_apply_tick_damage` call:
```gdscript
if not dead:
    HitFeedback.tick_pulse(self, kind)
```

`HitFeedback.tick_pulse` already guards on `_flash_t` (hit_feedback.gd:80) and `apply_flash` (line 85), so the player now participates in the same path as combatants.
_Verify:_ Extend `test_player_status.gd` with **P5**: apply burn → call `_tick_statuses(0.5)` once → assert `_flash_t > 0.0`. Gate suites stay green. _Effort:_ S.

---

**3. Add status pip row to HP globe in `player_hud.gd`**
`player_hud.gd` — new inner class `StatusPipRow` (a `Control` rendered in `_draw`, no `load()` calls).
Add immediately after the `GlobeGauge` class (~line 476, before `QuestScrollArt`).

The pip row:
- Is a `Control` child placed above the HP globe (`_hp_globe`).
- `_ready` in `player_hud` creates it after `_place_globe` and stores a reference as `_pip_row: StatusPipRow`.
- Exposes `set_statuses(active: Array[Dictionary])` — each dict has `{ "kind": String, "frac": float }` — which calls `queue_redraw()`.
- `_draw` iterates the list: for each entry, draws a filled circle in `STATUS_COLOR[kind]` (8px radius), then a clockwise-drain arc in a darker shade showing `frac` of the full circle. No texture loads.

```gdscript
class StatusPipRow extends Control:
    const STATUS_COLOR := {  # duplicate until Phase 4 extracts a shared const
        "burn": Color(1.00, 0.55, 0.18), "bleed": Color(0.85, 0.20, 0.20),
        "snared": Color(0.45, 0.65, 0.30), "root": Color(0.30, 0.65, 0.25),
        "marked": Color(1.00, 0.82, 0.30),
    }
    var _pips: Array[Dictionary] = []

    func set_statuses(pips: Array[Dictionary]) -> void:
        _pips = pips
        queue_redraw()

    func _draw() -> void:
        const R := 8.0
        const GAP := 22.0
        var cx := size.x * 0.5 - (_pips.size() - 1) * GAP * 0.5
        for p in _pips:
            var col: Color = STATUS_COLOR.get(String(p["kind"]), Color(0.7, 0.7, 0.7))
            draw_circle(Vector2(cx, R), R, col.darkened(0.25))
            var arc_end := TAU * float(p.get("frac", 1.0))
            draw_arc(Vector2(cx, R), R, -PI * 0.5, -PI * 0.5 + arc_end, 24, col, 3.5)
            cx += GAP
```

Place the row above the HP globe in `_ready` (~line 52 after `_place_globe(_hp_globe, -220.0)`):
```gdscript
_pip_row = StatusPipRow.new()
_pip_row.anchor_left = 0.5; _pip_row.anchor_right = 0.5
_pip_row.anchor_top = 1.0; _pip_row.anchor_bottom = 1.0
_pip_row.offset_left = -286; _pip_row.offset_right = -154
_pip_row.offset_top = -170; _pip_row.offset_bottom = -152
_pip_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
add_child(_pip_row)
```

Add `update_pips(pips: Array[Dictionary])` method to `player_hud.gd` that forwards to `_pip_row.set_statuses(pips)`.

In `player_controller.gd`, call `_hud.update_pips(...)` at the end of `apply_status` and at the top of `_tick_statuses` (after any erase), passing the current `_statuses` dict serialised to `[{"kind": k, "frac": s.time_left / s.tick_interval …}]`. Since `StatusEffect` doesn't store the original duration, add `var duration: float = 0.0` to `status_effect.gd` (line 19) and set it in `player_controller.apply_status` on first apply (not on refresh).

_Verify:_ Screenshot: `WYRD_SHOT=1 WYRD_DEV_CHART=... godot --path wyrd` near a Sunlit elite; confirm orange pip above HP globe appears. Gate suites stay green. _Effort:_ M.

---

### Phase 2 — Cleanse path

**4. Add `duration` field to `status_effect.gd`**
`status_effect.gd:18` — add after `var visual: Node3D = null`:
```gdscript
var duration: float = 0.0   # original apply duration; used by HUD pip drain arc
```
Set `s.duration = duration` in both `player_controller.apply_status` (line ~1535) and `combatant.apply_status` (line ~510) on first-apply (not on refresh). This is needed by the pip drain-arc and the cleanse feedback.
_Verify:_ `test_player_status.gd` P1 still passes (duration stored correctly). _Effort:_ S.

---

**5. Add `cleanse_status` to `player_controller.gd`**
`player_controller.gd` — new method after `get_status` (~line 1547):
```gdscript
func cleanse_status(kind: String) -> void:
    if _statuses.erase(kind):
        if _hud != null and _hud.has_method("update_pips"):
            _hud.update_pips(_build_pip_list())
```

Add private helper `_build_pip_list() -> Array[Dictionary]` that serialises `_statuses` into the `[{kind, frac}]` format consumed by `update_pips`.
_Verify:_ Extend `test_player_status.gd` with **P6**: apply root → `cleanse_status("root")` → assert `not has_status("root")`. _Effort:_ S.

---

**6. Wire `quickroot_tonic` consumption to `cleanse_status`**
`game.gd:529` — `quaff_buff_draught()`.
After `apply_buff(...)` for the `quickroot_tonic` case, call `cleanse_status` on the local player:
```gdscript
if id == "quickroot_tonic":
    var pl: Node = local_player()
    if pl != null and pl.has_method("cleanse_status"):
        pl.cleanse_status("root")
        pl.cleanse_status("snared")
```
`quaff_buff_draught` iterates `BUFF_DRAUGHT_ORDER` and consumes the first available; the cleanse call lives inside the loop body just before `return true`.
_Verify:_ `test_wyrd_loop.gd` (existing tonic-brew path, lines 384–387) stays green. P6 in `test_player_status.gd` validates end-to-end. _Effort:_ S.

---

**7. Extend `SkillEffect` with a `cleanse` static factory**
`skill_effect.gd` — currently has `burn`, `snared`, `bleed`, `marked` factories (lines ~1–54). Add:
```gdscript
static func cleanse(kind: String) -> SkillEffect:
    var e := SkillEffect.new()
    e.kind = "cleanse"
    e.target_kind = kind   # new field: which status to remove
    return e
```
Wire `apply()` to call `target.cleanse_status(target_kind)` if target has the method. This keeps future skill-based cleanses data-driven without touching `player_controller` again.
_Verify:_ No existing tests use cleanse; add a one-liner in P6 after the quaff path to confirm `SkillEffect.cleanse("root").apply(player)` also removes the status. _Effort:_ S.

---

### Phase 3 — Multiplayer status sync

**8. Add `status_sync` RPC to `net_game.gd`**
`net_game.gd` — new RPC after `_kill_credit` (~line 354). The host calls this whenever it applies a status to a non-local player body.

```gdscript
# Host → all peers: a player body received a status.
# peer_id identifies the player node ("NetPlayer<id>" or "Player" for host).
@rpc("authority", "call_local", "reliable")
func _status_sync(peer_id: int, kind: String, duration: float,
        dpt: int, slow_factor: float, tick_interval: float) -> void:
    var scene := get_tree().current_scene
    if scene == null:
        return
    var nm := "NetPlayer%d" % peer_id if peer_id != 1 else "Player"
    var pl := scene.get_node_or_null(nm)
    if pl != null and pl.has_method("apply_status"):
        pl.apply_status(kind, duration, dpt, slow_factor, tick_interval)
```

Add a public `sync_player_status(peer_id, kind, duration, dpt, slow_factor, tick_interval)` helper that guards `is_host()` then calls `_status_sync.rpc(...)`.

In `combatant.gd` `_trigger_burn_pulse` (the Sunlit path that calls `_player.apply_status`), after the apply call:
```gdscript
var net := get_node_or_null("/root/NetGame")
if net != null and net.has_method("sync_player_status") and net.is_host():
    var pid: int = int(_player.get_multiplayer_authority())
    net.sync_player_status(pid, "burn", 3.0, 1, 1.0, 0.5)
```
Duration expiry is handled locally by each peer's own `_tick_statuses`; no expire RPC needed.
_Verify:_ Manual play-test: host + guest in same dungeon; Sunlit elite near guest; guest HP drains and guest HUD shows burn pip. Or extend `test_player_status.gd` with **P7** using a mock RPC stub: two player nodes, simulate `_status_sync` call on peer-2 node, assert `has_status("burn")`. _Effort:_ M.

---

### Phase 4 — Gate integration + registration point

**9. Verify boss-bar "Unyielding" tag renders correctly**
`boss_bar.gd:37` — `prime()` already calls `WyrdUi.set_meter(_meter, 1.0, "The Hedgemother — Unyielding")`. `set_phase()` (line 54) also sets the text. This is confirmed shipped. No code change needed; add a playtest note confirming the tag is visible after aggro.
_Verify:_ Screenshot after aggro: boss bar reads "The Hedgemother — Phase 1 — Unyielding". _Effort:_ S.

---

**10. Extract a shared `STATUS_DEFS` registration dict to `status_effect.gd`**
`status_effect.gd:18` — add a static const after the existing vars:
```gdscript
static const STATUS_DEFS := {
    "burn":   {"color": Color(1.00, 0.55, 0.18), "word": "burning",  "apply_text": "singed!",   "particle": "rise"},
    "bleed":  {"color": Color(0.85, 0.20, 0.20), "word": "bleeding", "apply_text": "bleeding!", "particle": "fall"},
    "snared": {"color": Color(0.45, 0.65, 0.30), "word": "snared",   "apply_text": "snared!",   "particle": "orbit"},
    "root":   {"color": Color(0.30, 0.65, 0.25), "word": "rooted",   "apply_text": "rooted!",   "particle": "disc"},
    "marked": {"color": Color(1.00, 0.82, 0.30), "word": "marked",   "apply_text": "marked!",   "particle": "none"},
}
```
Update three consumers to read from this single source:
- `combatant.gd:89` — `STATUS_COLOR` → `StatusEffectScript.STATUS_DEFS[k]["color"]`; `APPLY_TEXT` → `["apply_text"]`; `STATUS_WORD` (absent in combatant — not needed there).
- `player_controller.gd:1514` — `STATUS_WORD` → read from `StatusEffectScript.STATUS_DEFS[k]["word"]`.
- `player_hud.gd StatusPipRow` — replace its local `STATUS_COLOR` const with a preload + `STATUS_DEFS` lookup.

This is a refactor commit; no behaviour change. Adding a seventh status kind now touches only `STATUS_DEFS`.
_Verify:_ All four gate suites + `test_statuses.gd` + `test_player_status.gd` stay green after the refactor. _Effort:_ S.

---

**11. Promote status test suites into the standard gate**
`CLAUDE.md` — add `test_statuses.gd` and `test_player_status.gd` to the Tests section alongside the four existing suites:
```
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_statuses.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_player_status.gd
```
_Verify:_ Both exit 0 in a clean headless run. _Effort:_ S.

## First commit (smallest shippable slice)

**Tasks 1 + 2** together: add `"marked"` to `STATUS_WORD` and wire `HitFeedback.tick_pulse` from `player_controller._tick_statuses` (plus the `_flash_t` + `apply_flash` stub needed by tick_pulse). This is a single-file change to `player_controller.gd` (~15 lines), is independently testable via P5, has no scene dependencies, and closes the most visible readability gap (a burning player now flashes orange on every DoT tick). The PR acceptance: `test_player_status.gd` P1–P5 green; four gate suites green.

## Test & verification plan

| Task | Suite / check |
|------|---------------|
| 1 | `test_player_status.gd` P1–P4 (regression) |
| 2 | `test_player_status.gd` P5 (new: `_flash_t > 0` after one burn tick) |
| 3 | Screenshot: orange pip above HP globe while burning |
| 4 | `test_player_status.gd` P1 (duration stored without regression) |
| 5–6 | `test_player_status.gd` P6 (cleanse_status + quaff path) |
| 7 | P6 extended: SkillEffect.cleanse factory removes status |
| 8 | Manual co-op play-test OR `test_player_status.gd` P7 (mock RPC) |
| 9 | Screenshot: boss bar shows "Unyielding" after aggro |
| 10 | All six suites green after refactor |
| 11 | Both status suites in CLAUDE.md; both exit 0 |

New tests to author (extend `test_player_status.gd`):
- **P5** — tick_pulse fires on burn tick: `apply_status("burn", 3.0, 1, 1.0, 0.5)` → `_tick_statuses(0.5)` → `assert _flash_t > 0.0`.
- **P6** — cleanse: `apply_status("root", 2.0, ...)` → `cleanse_status("root")` → `assert not has_status("root")`. Second sub-check: quaff `quickroot_tonic` item via `game.quaff_buff_draught()` → same assertion.
- **P7** — net sync: two player nodes, call `_status_sync(peer_id, "burn", 3.0, 1, 1.0, 0.5)` on a mock NetGame, assert guest node `has_status("burn")`.

All headless runs: `cd wyrd && WYRD_NO_SAVE=1 godot --headless --path .`

## Risks & open questions

1. **Player `apply_flash` vs combatant's** — the player uses a single `_mesh: Node3D` (no `_meshes: Array`); the proposed tween-modulate approach differs from combatant's per-surface material override. If the chibi body ever uses multiple mesh children, this will need to match `cache_meshes` pattern. For now, `_mesh.modulate` is sufficient.
2. **Pip `frac` drain arc** — requires storing the original `duration` on `StatusEffect` (Task 4). If the `duration` field is zero (a status applied before Task 4 ships), the arc will skip rather than show a full circle; add a guard `if s.duration > 0.0 else 1.0`.
3. **Open question from [[system-status-effects]]** — should `marked` ever be applicable to the player (boss "marks the prey")? If yes, `PULSE_COLOR_BY_STATUS` in `hit_feedback.gd` needs a `"marked"` entry and the pip row needs a visual for it. Currently marked has no `damage_per_tick`, so `tick_pulse` would fire silently (the colour guard in `HitFeedback` line 77 would skip it). Defer until a boss ability requires it.
4. **Open question** — `clearwater_philter` cleansing DoT statuses (burn/bleed) vs `quickroot_tonic` for movement statuses (root/snared)? The thematic split is clean and future-proof; Task 6 only wires the root/snare cleanse. A follow-up task (not in scope here) would add `cleanse_status("burn"); cleanse_status("bleed")` to the `clearwater_philter` branch of `quaff_buff_draught`.
5. **Net sync timing** — `status_sync` fires a `reliable` RPC; on high-latency connections the status will apply slightly late on the guest. Since DoT durations are 2–8 s and the RPC is reliable (not unreliable-ordered), drift is bounded by RTT and acceptable at LAN scale. Document this in a code comment.
6. **`STATUS_DEFS` in `status_effect.gd` (Task 10)** — `class_name StatusEffect` is registered in the project; the static const is accessible as `StatusEffect.STATUS_DEFS` in the running game but NOT in headless `--script` mode (the `class_name` autoload restriction). Use `preload` const alias (`const StatusEffectScript := preload("res://scripts/status_effect.gd")`) in all three consumers to stay consistent with the existing pattern in `combatant.gd:11` and `player_controller.gd:15`. The `StatusEffectScript.STATUS_DEFS` form works in headless.
