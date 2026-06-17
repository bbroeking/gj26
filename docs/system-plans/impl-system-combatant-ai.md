---
title: Enemy AI & Combatant — Implementation Plan
parent: "[[system-combatant-ai]]"
domain: Enemies & Combat
type: implementation-plan
status: ready-to-build
effort: M
tags: [wayfinder, impl]
---

# Enemy AI & Combatant — Implementation Plan

> Build doc for [[system-combatant-ai]]. Chain-aggro, IDLE wander, two new archetypes (Warden + Barrow Brute), a ground AoE telegraph, two new elite modifiers (Herald + Protector), and the co-op ranged-replication fix are all wired up and verified.

## Definition of done

- Pulling one skeleton in a crypt room wakes every skeleton within 5 m; a rat in the far corner stays asleep.
- Enemies in IDLE shuffle around their spawn cell — they never stand frozen.
- A Warden heals adjacent allies 2 HP every 4 s; killing it first makes the pack measurably easier.
- A Barrow Brute telegraphs an expanding floor ring for 0.7 s before a 14-damage strike.
- Herald elite makes nearby enemies visibly faster for 3 s bursts; Protector elite grants +4 max HP to its escorts.
- Two-player session: ghost orb + telegraph are visible to the guest; damage lands once.
- `test_combat.gd` Section F + I pass; new `_check_chain_aggro`, `_check_warden_heal`, `_check_brute_ring`, `_check_herald_aura` stanzas green in `test_wyrd_dungeon_scene.gd`.

## Preconditions / dependencies

- [[impl-system-status-effects]] — `apply_status` / `has_status` / `_slow_product` are live; the warden's `heal_pulse` guard uses `has_status("root")` and the dead-flag. **Already shipped.**
- [[impl-system-elites]] — `Elites.MODIFIERS` dispatch pattern (`on_death`, `on_attack`) is live in `combatant.gd::_elite_on_death` / `_elite_on_attack`. New herald/protector modifiers extend it with a new `_elite_on_tick` hook. **Already shipped.**
- [[impl-system-combat-juice-vfx]] — `_make_root_disc` / emissive `CylinderMesh` recipe is in `combatant.gd` (line 605–622); Warden green ring and Brute AoE disc reuse it. **Already shipped.**
- [[impl-system-charts-wayfinding]] — `_aggro_mult` is read from `fog_of_hedge` affix in `layout_loader.gd` (line 173, 299–301) and applied at line 947. Chain-alert radius uses the same multiplier — no new affix knob needed for the first cut.
- [[impl-system-multiplayer-netcode]] — Phase 3 replication follows the existing `drop_event` host-broadcast pattern in `net_game.gd`; Phase 3 task touches `combatant.gd` + `enemy_projectile.gd`.
- **No missing files** — `combatant.gd`, `layout_loader.gd`, `enemy_projectile.gd`, `data/elites.gd` all exist. The GLB placeholders for Warden (`hedge_sprite`) and Brute (`bramble_imp`) are in `layout_loader::ENEMY_KINDS` already.

## Tasks (ordered)

### Phase 1 — Chain aggro (first commit — makes rooms threatening)

1. **Add `_alert_nearby(radius: float)` to `combatant.gd`** — `scripts/combatant.gd` new func after `_chase_move` (after line 388). Queries `get_tree().get_nodes_in_group("enemy")`, skips `self` and any node where `bool(node.get("dead"))`, and transitions any `State.IDLE` peer within `radius` to `State.CHASE`. Guards against propagation: only IDLE enemies trigger the chain (CHASE/ATTACK ones are already awake). Code sketch:
   ```gdscript
   func _alert_nearby(radius: float) -> void:
       for peer in get_tree().get_nodes_in_group("enemy"):
           if peer == self or bool(peer.get("dead")):
               continue
           if int(peer.get("_state")) == State.IDLE:
               var d: float = global_position.distance_to((peer as Node3D).global_position)
               if d <= radius:
                   peer.set("_state", State.CHASE)
   ```
   _Verify:_ `test_combat.gd` Section F still passes (no regression); new `_check_chain_aggro` stanza in `test_wyrd_dungeon_scene.gd` (Task 3). _Effort:_ S.

2. **Wire `_alert_nearby` into `_tick_ai` IDLE→CHASE transition** — `combatant.gd:_tick_ai` (around line 307). In the `State.IDLE` branch, after `_state = State.CHASE`, call `_alert_nearby(aggro_radius * 1.4)`. The 1.4× multiplier spreads the alert a bit wider than personal aggro so a pack can wake even if peers are at the edge of the room; `aggro_radius` already bakes in `_aggro_mult` from `layout_loader` (line 947). **Do not call on the leash-return path** (CHASE→IDLE does not call this). Code sketch:
   ```gdscript
   # In State.IDLE branch:
   if dist < aggro_radius:
       _state = State.CHASE
       _alert_nearby(aggro_radius * 1.4)
   ```
   _Verify:_ manual play-test `WYRD_DEV_CHART=crypt` — one arrow wakes the near pack; far corner enemy stays IDLE. _Effort:_ XS.

3. **Add `_check_chain_aggro` stanza to `test_wyrd_dungeon_scene.gd`** — after line 162 (before `world.free()`). Build two combatants 3 m apart; place player 6 m from combatant A. Tick until A enters CHASE, assert B is also CHASE. Use headless `CombatantScript.new()` + `add_to_group("enemy")` pattern (mirrors `test_combat.gd` `_make_enemy`). _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd` green. _Effort:_ S.

### Phase 2 — IDLE wander / shuffle

4. **Add `_spawn_pos` and wander state vars to `combatant.gd`** — new vars after line 116 (near `_repath_t`):
   ```gdscript
   var _spawn_pos := Vector3.ZERO
   var _wander_t := 0.0
   const WANDER_REPATH := 2.5
   ```
   _Verify:_ compile-only — covered by any headless run. _Effort:_ XS.

5. **Set `_spawn_pos` in `setup()`** — `combatant.gd:setup` (around line 130), after `_base_scale = scale`:
   ```gdscript
   _spawn_pos = global_position   # set AFTER add_child so world pos is valid
   ```
   Because `setup` is called before `add_child` completes in some paths, also call `_spawn_pos = global_position` at the top of `_tick_ai` when `_spawn_pos == Vector3.ZERO` as a fallback. _Verify:_ covered by wander visual test. _Effort:_ XS.

6. **Implement wander tick in `_tick_ai` IDLE branch** — `combatant.gd:_tick_ai` (around line 304). Replace the bare `velocity = Vector3.ZERO` in `State.IDLE` with a wander sub-tick:
   ```gdscript
   State.IDLE:
       if dist < aggro_radius:
           _state = State.CHASE
           _alert_nearby(aggro_radius * 1.4)
       else:
           _wander_t -= delta
           if _wander_t <= 0.0:
               _wander_t = WANDER_REPATH
               if _agent != null:
                   var off := Vector3(randf_range(-2.0, 2.0), 0.0, randf_range(-2.0, 2.0))
                   _agent.target_position = _spawn_pos + off
           var nd: Vector3 = _agent.get_next_path_position() - global_position
           nd.y = 0.0
           if nd.length() > 0.3:
               var slow_w := move_speed * 0.4
               velocity.x = nd.normalized().x * slow_w
               velocity.z = nd.normalized().z * slow_w
               _face(nd.normalized())
           else:
               velocity.x = 0.0
               velocity.z = 0.0
   ```
   The enemy never wanders outside spawn + 2 m (the random offset is clamped to spawn origin); `NavigationAgent3D` + leash radius prevent room escape. On IDLE→CHASE, `_wander_t` is left as-is (gets reset next IDLE). _Verify:_ visual inspection — `godot --path wyrd WYRD_DEV_CHART=crypt`; watch skeletons shuffle. _Effort:_ S.

### Phase 3 — Ranged co-op replication

7. **Add `spawn_ranged_cosmetic` RPC to `combatant.gd`** — new func after `_fire_projectile` (after line 413). Declare with `@rpc("authority","call_remote","unreliable")`:
   ```gdscript
   @rpc("authority", "call_remote", "unreliable")
   func spawn_ranged_cosmetic(from: Vector3, dir: Vector3) -> void:
       var proj := EnemyProjectile.new()
       get_parent().add_child(proj)
       proj.setup(from, dir, proj_speed, 0)   # damage = 0 — cosmetic only
   ```
   _Verify:_ compile-only first; co-op test in Task 9. _Effort:_ S.

8. **Broadcast from `_fire_projectile`** — `combatant.gd:_fire_projectile` (around line 403). After spawning the real projectile, if running as server in an active session, broadcast the cosmetic:
   ```gdscript
   var netd := get_node_or_null("/root/NetGame")
   if netd != null and bool(netd.active) and multiplayer.is_server():
       spawn_ranged_cosmetic.rpc(global_position + Vector3(0, 0.6, 0) + dir.normalized() * 0.5, dir)
   ```
   _Verify:_ two-instance local test (`WYRD_NET=host` / `WYRD_NET=join:127.0.0.1`) — guest sees the magenta orb before it arrives; damage lands once. Run `test_wyrd_dungeon_scene.gd` to confirm host-only mode unchanged. _Effort:_ M (netcode touch; follow `drop_event` pattern in `net_game.gd`).

9. **Broadcast telegraph cosmetic** — same `_spawn_ranged_telegraph` path (`combatant.gd` line 391): add `@rpc` variant `spawn_telegraph_cosmetic(dir, length)` that calls `EnemyProjectile.make_telegraph` and adds to parent; broadcast when server + active session. _Verify:_ same two-instance test — guest sees the floor aim-line grow during the windup. _Effort:_ S.

### Phase 4 — Warden archetype (support / buffer)

10. **Add `"warden"` to `ENEMY_KINDS` in `layout_loader.gd`** — after line 116 (after `"skitterling"` entry):
    ```gdscript
    "warden": {"model": "res://models/enemy_hedge_sprite_v1.glb", "scale": 1.8,
        "hp": 20, "damage": 3, "speed": 1.1, "atk_cd": 2.2,
        "tint": Color(0.44, 0.70, 0.40),   # greener than hedge_sprite
        "support": true},
    ```
    Placeholder: `hedge_sprite` GLB at a smaller scale with a green-gold tint. The `support` flag is read by the combatant in Task 11. _Verify:_ `WYRD_DEV_CHART=crypt` — a warden spawns at expected size. _Effort:_ XS.

11. **Add `is_support` var and escort-positioning to `combatant.gd`** — new var after line 79 (`is_elite`):
    ```gdscript
    var is_support := false
    var _heal_t := 0.0
    const HEAL_INTERVAL := 4.0
    ```
    In `_tick_ai` `State.CHASE` branch, before the CHASE→ATTACK check: if `is_support`, find the nearest non-self living enemy within 6 m, move toward it (via `_chase_move`-style velocity) instead of the player. If adjacent (dist ≤ 1.5 m) to that ally AND ally `_state != IDLE`, tick `_heal_t`; when it reaches 0 emit a `heal_pulse`:
    ```gdscript
    if is_support:
        var ally := _nearest_ally(6.0)
        if ally != null:
            var ato: Vector3 = (ally as Node3D).global_position - global_position
            ato.y = 0.0
            if ato.length() <= 1.5:
                _heal_t -= delta
                if _heal_t <= 0.0:
                    _heal_t = HEAL_INTERVAL
                    if not bool(ally.get("dead")) and not ally.has_method("has_status") or \
                            not ally.call("has_status", "root"):
                        ally.call("_heal_direct", 2)
            else:
                _chase_toward(ato.normalized())
        return   # warden doesn't personally attack
    ```
    Add `_nearest_ally(radius)` helper that queries `get_tree().get_nodes_in_group("enemy")`, skips `self` and dead, returns nearest within radius. Add `_heal_direct(amount: int)` to add `amount` to `hp` (clamped to `hp_max`), spawning a green `+2` damage number using the existing `_spawn_damage_number` pipe (pass a new `"heal"` tier string — DamageNumber shows it in green). Guard: if `ally.has_status("root")` and ally is dead → skip heal. _Verify:_ new `_check_warden_heal` stanza in `test_wyrd_dungeon_scene.gd` (Task 13). _Effort:_ M.

12. **Add green ring VFX to Warden spawn** — `layout_loader.gd:_spawn_enemy` (after line 968, near the `_proc_anim` assignment). If `def.get("support", false)` is true, call a new `_make_warden_ring(body)` helper: reuse `combatant.gd::_make_root_disc` recipe but with green-gold color and floating at `y = 0.9` (chest height); attach as a child of the body. `MeshInstance3D` — NOT a particle — so it's cheap and always visible. _Verify:_ visual inspection in play-test. _Effort:_ S.

13. **Add warden to spawn tables + `_check_warden_heal` test** — `layout_loader.gd:SPAWN_TABLES` (line 131): add `["warden", 10]` to `"hollow"` and `"crypt"` tables. Then add `_check_warden_heal` to `test_wyrd_dungeon_scene.gd`: build a warden + two skeletons, set `_heal_t = 0.0` on the warden, place skeleton at 1 m, tick a couple of frames (physics_frame × 8 to cover one `_heal_direct` call), assert `skeleton.hp > initial_hp`. _Verify:_ `test_wyrd_dungeon_scene.gd` green. _Effort:_ S.

14. **Set `is_support` in `layout_loader.gd:_spawn_enemy`** — after line 950 (`body.burst_on_death = ...`):
    ```gdscript
    body.is_support = bool(def.get("support", false))
    ```
    _Verify:_ covered by Task 13 test. _Effort:_ XS.

### Phase 5 — Barrow Brute archetype + AoE telegraph

15. **Add `"barrow_brute"` to `ENEMY_KINDS`** — `layout_loader.gd` after line 116 (alongside warden):
    ```gdscript
    "barrow_brute": {"model": "res://models/bramble_imp_v4.glb", "fit_h": 1.7,
        "hp": 32, "damage": 14, "speed": 1.0, "atk_cd": 3.0,
        "tint": Color(0.28, 0.22, 0.18),   # dark charcoal — hulking weight
        "bruiser": true},
    ```
    `fit_h: 1.7` scales the `bramble_imp` GLB to a chunky mid-height; `tint` darkens it to read as a distinct archetype from the green imp. _Verify:_ `WYRD_DEV_CHART=crypt` spawn check. _Effort:_ XS.

16. **Add `is_bruiser` var + AoE ring vars to `combatant.gd`** — new vars after `is_support` (after line 79 group):
    ```gdscript
    var is_bruiser := false
    var _brute_ring: MeshInstance3D = null
    ```
    _Verify:_ compile. _Effort:_ XS.

17. **Add `_make_brute_ring` factory to `combatant.gd`** — new func after `_make_root_disc` (after line 622). Creates a hollow `CylinderMesh` disc (top/bottom radius = `ATTACK_RANGE * 1.6`, height 0.06), unshaded emissive orange-red (`Color(0.95, 0.35, 0.10, 0.55)`), parented at `Vector3(0, 0.04, 0)`. Reuses the same material recipe as `_make_root_disc`:
    ```gdscript
    func _make_brute_ring(radius: float) -> MeshInstance3D:
        var disc := MeshInstance3D.new()
        var dm := CylinderMesh.new()
        dm.top_radius = radius
        dm.bottom_radius = radius
        dm.height = 0.06
        disc.mesh = dm
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color(0.95, 0.35, 0.10, 0.55)
        mat.emission_enabled = true
        mat.emission = Color(0.95, 0.35, 0.10)
        mat.emission_energy_multiplier = 1.8
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        disc.material_override = mat
        disc.position = Vector3(0.0, 0.04, 0.0)
        disc.scale = Vector3(0.05, 1.0, 0.05)   # start tiny; tween to full
        return disc
    ```
    _Verify:_ visual in play-test. _Effort:_ S.

18. **Wire brute ring spawn/free into `_tick_ai` CHASE→ATTACK transition** — `combatant.gd:_tick_ai` (around line 321, `_state = State.ATTACK` branch). When `is_bruiser` is true, spawn the ring and tween its `scale.x` / `scale.z` from 0.05 → 1.0 over `_telegraph_t` (which is auto-set to `clampf(attack_cooldown * 0.3, 0.32, 0.6)` — with `atk_cd = 3.0` this lands at 0.6 s; override to 0.7 s for the brute):
    ```gdscript
    if is_bruiser:
        _telegraph_t = 0.7
        _brute_ring = _make_brute_ring(ATTACK_RANGE * 1.6)
        add_child(_brute_ring)
        var tw := _brute_ring.create_tween()
        tw.tween_property(_brute_ring, "scale", Vector3(1.0, 1.0, 1.0), _telegraph_t)
    ```
    Free the ring when the hit fires (in `State.ATTACK` after `_did_hit = true`):
    ```gdscript
    if _brute_ring != null and is_instance_valid(_brute_ring):
        _brute_ring.queue_free()
        _brute_ring = null
    ```
    Also free in `_die()` alongside `_elite_ring` cleanup (after line 806). _Verify:_ new `_check_brute_ring` stanza (Task 20). _Effort:_ M.

19. **Set `is_bruiser` in `layout_loader.gd:_spawn_enemy`** — after `body.is_support = ...` (Task 14):
    ```gdscript
    body.is_bruiser = bool(def.get("bruiser", false))
    ```
    Add `"barrow_brute"` to `"crypt"` spawn table at weight 8 (`["barrow_brute", 8]`). _Verify:_ covered by Task 20. _Effort:_ XS.

20. **Add `_check_brute_ring` + `_check_brute_damage` stanzas to `test_wyrd_dungeon_scene.gd`** — build a brute (`CombatantScript.new()`), set `is_bruiser = true`, put a `DummyPlayer` at `ATTACK_RANGE` distance, tick into CHASE then wait for the ATTACK transition, assert `_brute_ring != null` after the transition frame, tick through the full `_telegraph_t`, assert player took ≥ 14 damage. _Verify:_ headless green. _Effort:_ S.

### Phase 6 — Elite modifier expansion (Herald + Protector)

21. **Add `"herald"` and `"protector"` to `data/elites.gd::MODIFIERS`** — after line 39 (after `"briarbound"`):
    ```gdscript
    "herald": {
        "name": "Herald",
        "hp_mult": 1.2,
        "scale_mult": 1.3,
        "tint": Color(1.0, 0.92, 0.55),
        "on_tick": "speed_aura",
        "aura_interval": 3.0,
        "aura_radius": 5.0,
        "aura_mult": 1.25,
        "aura_dur": 3.0,
    },
    "protector": {
        "name": "Protector",
        "hp_mult": 1.4,
        "scale_mult": 1.3,
        "tint": Color(1.0, 0.92, 0.55),
        "on_ready": "shield_escorts",
        "escort_radius": 3.0,
        "escort_hp_bonus": 4,
    },
    ```
    _Verify:_ `data/elites.gd` loads in headless (no `class_name` registration needed — `preload` const pattern already used in `combatant.gd:1`). _Effort:_ XS.

22. **Add `_elite_on_tick` dispatch + aura timer var to `combatant.gd`** — new var after `_cc_immune_until` (line 79 group):
    ```gdscript
    var _elite_aura_t := 0.0
    ```
    New func `_elite_on_tick(delta: float)` after `_elite_on_attack` (after line 1004):
    ```gdscript
    func _elite_on_tick(delta: float) -> void:
        var mod: Dictionary = Elites.MODIFIERS.get(modifier, {})
        match String(mod.get("on_tick", "")):
            "speed_aura":
                _elite_aura_t -= delta
                if _elite_aura_t <= 0.0:
                    _elite_aura_t = float(mod.get("aura_interval", 3.0))
                    _trigger_speed_aura(mod)
    ```
    Add `_trigger_speed_aura(mod: Dictionary)` func: queries `get_tree().get_nodes_in_group("enemy")` within `aura_radius`, skips `self` and dead peers, sets `peer._move_mult = float(mod.aura_mult)` for `aura_dur` seconds via a deferred reset timer (`get_tree().create_timer(aura_dur).timeout.connect(...)`). Call `_elite_on_tick(delta)` in `_tick_ai` when `is_elite and modifier != ""` (add after the existing `_elite_on_attack` call site in `State.ATTACK`, then also add to a per-frame call at the top of `_tick_ai`). _Verify:_ new `_check_herald_aura` stanza (Task 24). _Effort:_ M.

23. **Add `_elite_on_ready` protector dispatch to `apply_elite`** — `combatant.gd:apply_elite` (after line 884, after `add_child(_elite_ring)`). If `mod.has("on_ready")` and `mod.on_ready == "shield_escorts"`, call `_trigger_shield_escorts(mod)` in a deferred way (so the enemy is fully in the tree first):
    ```gdscript
    if String(mod.get("on_ready", "")) == "shield_escorts":
        call_deferred("_trigger_shield_escorts", mod)
    ```
    `_trigger_shield_escorts(mod)`: queries `"enemy"` group within `escort_radius`, skips `self` and dead, calls `peer.hp_max += int(mod.escort_hp_bonus)` and `peer.hp += int(mod.escort_hp_bonus)` (clamped). _Verify:_ `_check_protector_escorts` in `test_wyrd_dungeon_scene.gd` (Task 24). _Effort:_ M.

24. **Add `_check_herald_aura` + `_check_protector_escorts` stanzas to `test_wyrd_dungeon_scene.gd`** — Herald: spawn a herald elite + two rats within 4 m, tick 3.5 s (`await create_timer(3.5).timeout`), assert `rat._move_mult > 1.0`. Protector: spawn protector + two skeletons at 2 m, call `apply_elite("protector")`, tick one frame, assert `skeleton.hp_max == initial_hp_max + 4`. _Verify:_ headless green. _Effort:_ S.

## First commit (smallest shippable slice)

**Tasks 1–3 (chain aggro)** — adds `_alert_nearby`, wires it to the IDLE→CHASE transition, and adds the `_check_chain_aggro` headless test. No new assets, no new vars beyond the function body, no FSM changes. Acceptance: `test_wyrd_dungeon_scene.gd` passes; manual `WYRD_DEV_CHART=crypt` confirms near-pack wakes, far rat sleeps.

## Test & verification plan

| Task | Suite / check |
|---|---|
| 1–3 Chain aggro | New `_check_chain_aggro` stanza in `test_wyrd_dungeon_scene.gd`; manual `WYRD_DEV_CHART=crypt` play-test |
| 4–6 Wander | Visual inspection: `godot --path wyrd` with `WYRD_DEV_CHART=crypt`; confirm no room escape |
| 7–9 Ranged co-op | Two-instance: `WYRD_NET=host` + `WYRD_NET=join:127.0.0.1`; guest sees orb + telegraph; `test_wyrd_dungeon_scene.gd` headless (host-only regression) |
| 10–14 Warden | `_check_warden_heal` in `test_wyrd_dungeon_scene.gd`; manual play-test kill-order diff |
| 15–20 Brute | `_check_brute_ring` + `_check_brute_damage` in `test_wyrd_dungeon_scene.gd` |
| 21–24 Elite mods | `_check_herald_aura` + `_check_protector_escorts` in `test_wyrd_dungeon_scene.gd` |

All headless runs:
```
cd wyrd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_transitions.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd
```
`test_combat.gd` also covers Section F (AI FSM) and Section I (elite modifiers) — run it after every phase.

## Risks & open questions

- **`net_puppet` guard on `_alert_nearby`**: guest-side mirror bodies have `net_puppet = true` and their `_state` is driven by host snapshots. `_alert_nearby` must skip `net_puppet` peers or the guest will double-wake enemies. Add `if bool(peer.get("net_puppet"))` guard in the helper.
- **Wander without NavMesh**: `_tick_ai` wander branch calls `_agent.get_next_path_position()` which returns `global_position` when no path is baked (dev boots without a World.tscn navmesh). Guard: `if _agent.is_navigation_finished() or nd.length() <= 0.3: velocity = Vector3.ZERO`.
- **`_heal_direct` tier string**: `_spawn_damage_number` currently accepts `"normal"`, `"crit"`, `"super"`. A `"heal"` tier needs a small patch in `damage_number.gd` to render green / with a `+` prefix. Decide: add the tier, or just call `_spawn_damage_number(2, "normal")` with a green tint via a new overload. Simpler to reuse `"normal"` with no visual distinction for the first cut.
- **Brute telegraph timing**: 0.7 s is longer than any current tell (skeleton 0.35 s, ghost 0.6 s). Play-test will confirm whether it reads as "readable danger" or "free punish window." If too long, lower to 0.55 s.
- **Protector HP bonus on dead enemies**: `_trigger_shield_escorts` deferred call fires one frame after `apply_elite`; if another enemy dies in that frame, it still gets the deferred bonus. Guard: `if not bool(peer.get("dead"))`.
- **Warden model**: using `hedge_sprite` GLB at scale 1.8 with a greener tint as placeholder. A unique staff-carrier silhouette is a nice-to-have; open as a Meshy pipeline task once the behavior is tuned.
- **Chain aggro and boss rooms**: [[system-combatant-ai]] notes boss rooms are already cleared of regular enemies at build time (`layout_loader` line 814); no guard is needed in `_alert_nearby` for boss bodies, but confirm with `grep _spawn_boss layout_loader.gd` that boss entities are NOT added to the `"enemy"` group.
