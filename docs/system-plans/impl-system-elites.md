---
title: Elite Enemies — Implementation Plan
parent: "[[system-elites]]"
domain: Enemies & Combat
type: implementation-plan
status: ready-to-build
effort: M
tags: [wayfinder, impl]
---

# Elite Enemies — Implementation Plan

> Build doc for [[system-elites]]. Each of the four existing modifiers has a distinct body tint, ring color, and floating promotion label; depth-scaled spawn density and retinue counts are wired; two new modifier archetypes (thornshelled, blightwalker) are playable; and elite kill rewards differentiate by modifier threat level.

## Definition of done

- Four existing modifiers (brambled, swift, sunlit, briarbound) each display a distinct body tint **and** ring color — visually distinguishable from 5m without a tooltip.
- A floating modifier-name label (e.g. "Swift") appears once above the head on promotion, using per-modifier `label_color`.
- Elite spawn rate scales with room depth: `WYRD_DEV_LEVEL=1` shows rare elites; `WYRD_DEV_LEVEL=10` gives near-guaranteed coverage in every combat room.
- Retinue count scales 2–5 with depth instead of flat 2–3.
- Two new modifiers (thornshelled, blightwalker) are rollable in normal play with distinct tints, labels, and working on-attack / on-death triggers.
- Per-modifier `reward_tier_bonus` gives thornshelled a magic-or-better guarantee at depth ≥ 2.
- All 4 headless suites green after every phase.

## Preconditions / dependencies

- [[impl-system-status-effects]] — `apply_status("snared", ...)` and `apply_status("burn", ...)` on the player must be wired before Phase 3 thornshelled and blightwalker triggers are exercised. The framework exists (spec 31 / `combatant.gd:487`); confirm the player script also has `apply_status` before Phase 3 lands.
- [[impl-system-combat-juice-vfx]] — tint / ring colors must harmonize with the UI kit token palette (`wyrd/scripts/ui/wyrd_ui.gd`). No code gate, but run the visual diff before finalizing colors.
- [[impl-system-drops-loot]] — `drops.gd::roll_drop` is the reward pipe touched in Phase 4. Signature is `roll_drop(role: String, depth: int)` (`drops.gd:26`); Phase 4 modifies the caller site in `combatant.gd::_spawn_drops`, not `drops.gd` itself.
- `wyrd/data/elites.gd` — EXISTS at line 10 with four `MODIFIERS` entries, all sharing `Color(1.0, 0.92, 0.55)`.
- `wyrd/scripts/combatant.gd` — EXISTS; `apply_elite` at line 860, `_make_elite_ring` at line 915, `_spawn_apply_text` at line 737, `_spawn_drops` at line 817, `_elite_on_death` at line 959, `_elite_on_attack` at line 1000, `_trigger_bleed_nova` at line 967, `_trigger_burn_pulse` at line 1010.
- `wyrd/scripts/layout_loader.gd` — EXISTS; elite roll at line 838 (`float(n) / 8.0`), retinue count at line 865 (`randi_range(2, 3)`).

## Tasks (ordered)

### Phase 1 — Per-modifier visual differentiation (the gap being operationalized)

1. **Differentiate tints in `elites.gd`** — `data/elites.gd:15,22,29,36`. Replace the shared `Color(1.0, 0.92, 0.55)` with per-modifier tints and add `"ring_color"` + `"label_color"` keys to each entry:
   ```gdscript
   # brambled (bleeder — sap green)
   "tint": Color(0.55, 0.90, 0.40),
   "ring_color": Color(0.40, 0.85, 0.25),
   "label_color": Color(0.55, 0.95, 0.35),
   # swift (fast — ice blue)
   "tint": Color(0.50, 0.80, 1.0),
   "ring_color": Color(0.30, 0.65, 1.0),
   "label_color": Color(0.55, 0.85, 1.0),
   # sunlit (fire — ember gold)
   "tint": Color(1.0, 0.70, 0.20),
   "ring_color": Color(1.0, 0.50, 0.10),
   "label_color": Color(1.0, 0.75, 0.20),
   # briarbound (armored — deep violet)
   "tint": Color(0.85, 0.40, 0.90),
   "ring_color": Color(0.70, 0.25, 0.80),
   "label_color": Color(0.90, 0.50, 0.95),
   ```
   _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_dungeon_scene.gd` stays green. _Effort:_ S.

2. **Pass `ring_color` to `_make_elite_ring`** — `combatant.gd:884`. In `apply_elite`, change the ring construction line to read the new key:
   ```gdscript
   var ring_color: Color = mod.get("ring_color", tint)
   _elite_ring = _make_elite_ring(ring_color)
   ```
   `_make_elite_ring` signature stays `func _make_elite_ring(tint: Color) -> GPUParticles3D` — no signature change needed, just the call site.
   _Verify:_ Manual: run `WYRD_DEV_CHART=tier_1 godot --path wyrd`, spot four elite types — ring color now differs from body tint on each. _Effort:_ S.

3. **Spawn floating modifier-name label on promotion** — `combatant.gd:885` (after `add_child(_elite_ring)`). After the ring is added, spawn a promotion label using the existing `_spawn_apply_text` pipe and the new `label_color` key:
   ```gdscript
   var label_color: Color = mod.get("label_color", tint)
   var dn := DamageNumberScene.instantiate()
   var host: Node = get_parent()
   if host == null:
       host = get_tree().root
   host.add_child(dn)
   dn.global_position = global_position + Vector3(0.0, 2.6, 0.0)
   if dn.has_method("setup_apply"):
       dn.setup_apply(String(mod.get("name", modifier_key)), label_color)
   ```
   `DamageNumberScene` is already preloaded at `combatant.gd:7`. `setup_apply` exists at `damage_number.gd:37`. Note: this block goes inside `apply_elite` — NOT inside `_draw` — satisfying the no-load-in-_draw constraint.
   _Verify:_ Manual: promote an elite (enter a combat room); "Brambled" / "Swift" etc. floats up in per-modifier color once. Headless suite `test_wyrd_dungeon_scene.gd` stays green. _Effort:_ S.

### Phase 2 — Depth-scaled spawn density and retinue

4. **Scale elite spawn probability by depth** — `layout_loader.gd:838`. Replace the flat probability with a depth-adjusted formula. `depth` is already in scope as `depths[ri]`:
   ```gdscript
   var elite_chance: float = clampf((float(n) / 8.0) * (1.0 + 0.12 * float(depth)), 0.05, 0.60)
   if role == "combat" and _rng.randf() < elite_chance:
   ```
   _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_dungeon_scene.gd` green. Manual: `WYRD_DEV_LEVEL=1` vs `WYRD_DEV_LEVEL=10` — clearly different elite density. _Effort:_ S.

5. **Add `elite_density` chart-config multiplier** — `layout_loader.gd:838` (same block as task 4). Read the cfg multiplier set up during `_build_room_decor`-equivalent initialization. `cfg` is already read at `layout_loader.gd:310`. Store it as a field during `_load_chart_cfg`:
   ```gdscript
   # in _load_chart_cfg (near line 310)
   _elite_density_mult = float(cfg.get("elite_density", 1.0))
   # in _build_enemies elite roll:
   var elite_chance: float = clampf((float(n) / 8.0) * (1.0 + 0.12 * float(depth)) * _elite_density_mult, 0.05, 0.60)
   ```
   Add `var _elite_density_mult: float = 1.0` to the `layout_loader` field list (near `_density_mult`).
   _Verify:_ Headless suite green. A manually crafted chart with `elite_density: 2.0` in cfg doubles elite frequency vs the default. _Effort:_ S.

6. **Scale retinue count by depth** — `layout_loader.gd:865`. Replace `randi_range(2, 3)` with depth-scaling:
   ```gdscript
   var retinue_count: int = _rng.randi_range(2, 2 + clampi(depth / 3, 0, 3))
   ```
   This gives 2 at depth 0–2, up to 5 at depth ≥ 9.
   _Verify:_ Headless suite green. Manual: note retinue size visibly larger in depth-8 rooms vs depth-1. _Effort:_ S.

### Phase 3 — Two new modifier archetypes

7. **Add `thornshelled` data entry to `elites.gd`** — `data/elites.gd:39` (after briarbound, before closing `}`). New pure-data entry:
   ```gdscript
   "thornshelled": {
       "name": "Thornshelled",
       "hp_mult": 2.0,
       "scale_mult": 1.35,
       "tint": Color(0.60, 0.80, 0.30),
       "ring_color": Color(0.45, 0.70, 0.20),
       "label_color": Color(0.65, 0.90, 0.35),
       "cc_immune_window": 8.0,
       "on_attack": "spine_burst",
       "reward_tier_bonus": 2,
   },
   ```
   `pick_random` at line 44 picks uniformly from `MODIFIERS.keys()` — the new entry is automatically included with no code change.
   _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_dungeon_scene.gd` green (deterministic seed test still passes — dict length changed but pick is `randi_range(0, keys.size()-1)`). _Effort:_ S.

8. **Add `blightwalker` data entry to `elites.gd`** — same block as task 7:
   ```gdscript
   "blightwalker": {
       "name": "Blightwalker",
       "hp_mult": 1.2,
       "scale_mult": 1.2,
       "tint": Color(0.35, 0.80, 0.50),
       "ring_color": Color(0.20, 0.65, 0.35),
       "label_color": Color(0.40, 0.90, 0.55),
       "on_death": "blight_pool",
       "reward_tier_bonus": 1,
   },
   ```
   _Verify:_ Headless suite green. _Effort:_ S.

9. **Implement `_trigger_spine_burst` in `combatant.gd`** — add after `_trigger_burn_pulse` (after line 1015). Thornshelled on-attack: applies Snared to the player on each melee hit within range:
   ```gdscript
   func _trigger_spine_burst() -> void:
       if _player == null:
           return
       if global_position.distance_to(_player.global_position) <= 2.5:
           if _player.has_method("apply_status"):
               _player.apply_status("snared", 1.5, 0, 0.55, 0.0)
   ```
   Wire it into `_elite_on_attack` (`combatant.gd:1002`) — add a new `match` arm:
   ```gdscript
   "spine_burst":
       _trigger_spine_burst()
   ```
   _Verify:_ Manual — provoke thornshelled melee hit; "snared!" floats above player. Headless suite green. _Effort:_ S.

10. **Implement `_trigger_blight_pool` in `combatant.gd`** — add after `_trigger_spine_burst`. Blightwalker on-death: spawns a 2m poison disc that deals 1 dpt at 0.5s intervals for 5s, then frees itself. Mirror the bleed-nova disc pattern (`combatant.gd:975`):
    ```gdscript
    func _trigger_blight_pool() -> void:
        var center := global_position
        var disc := MeshInstance3D.new()
        disc.name = "BlightPool"
        var dm := CylinderMesh.new()
        dm.top_radius = 2.0
        dm.bottom_radius = 2.0
        dm.height = 0.06
        disc.mesh = dm
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color(0.25, 0.75, 0.35, 0.50)
        mat.emission_enabled = true
        mat.emission = Color(0.25, 0.75, 0.35)
        mat.emission_energy_multiplier = 1.4
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        disc.material_override = mat
        disc.position = center
        var host := get_parent()
        if host == null:
            return
        host.add_child(disc)
        # Tick damage every 0.5s for 5s (10 ticks), then free.
        var ticks_left := 10
        var tick_fn: Callable
        tick_fn = func():
            ticks_left -= 1
            for enemy in AoeQuery.query_circle(disc.get_tree(), center, 2.0, "player"):
                if enemy.has_method("apply_status"):
                    enemy.apply_status("burn", 1.0, 1, 1.0, 0.5)
            if ticks_left <= 0:
                var tw := disc.create_tween()
                tw.tween_property(mat, "albedo_color:a", 0.0, 0.5)
                tw.tween_callback(disc.queue_free)
            else:
                disc.get_tree().create_timer(0.5).timeout.connect(tick_fn)
        disc.get_tree().create_timer(0.5).timeout.connect(tick_fn)
    ```
    Wire it into `_elite_on_death` (`combatant.gd:961`):
    ```gdscript
    "blight_pool":
        _trigger_blight_pool()
    ```
    _Verify:_ Manual — kill a blightwalker; green disc persists 5s on the floor; player standing in it takes burn ticks. All 4 headless suites green. _Effort:_ S.

11. **Add Briarbound CC-immunity to thornshelled in `apply_status`** — `combatant.gd:495`. The existing immunity gate hard-codes `modifier == "briarbound"`. Extend to handle any modifier with a `cc_immune_window` key:
    ```gdscript
    # replace the single-modifier check with a data-driven one:
    if is_elite and (kind == "root" or kind == "snared"):
        var cc_window: float = float(Elites.MODIFIERS.get(modifier, {}).get("cc_immune_window", 0.0))
        if cc_window > 0.0:
            var now: float = float(Time.get_ticks_msec()) / 1000.0
            if now < _cc_immune_until:
                return null
            _cc_immune_until = now + cc_window
    ```
    Remove the old `modifier == "briarbound"` branch.
    _Verify:_ Headless suite green. Manual: briarbound still becomes CC-immune after first root; thornshelled also gains 8s CC-immunity after first snare. _Effort:_ S.

### Phase 4 — Per-modifier reward differentiation

12. **Apply `reward_tier_bonus` in `_spawn_drops`** — `combatant.gd:820`. After the `role = "elite"` path is established by `apply_elite`, the effective depth passed to `Drops.roll_drop` should incorporate the modifier's bonus. Modify the call at line 820:
    ```gdscript
    var drop_depth: int = depth
    if is_elite and modifier != "":
        drop_depth += int(Elites.MODIFIERS.get(modifier, {}).get("reward_tier_bonus", 0))
    var pile: Array = Drops.roll_drop(role, drop_depth)
    ```
    This raises the tier roll in `drops.gd:_roll_tier` via `bias += depth/2` — a +2 bonus from thornshelled adds ~1 full rarity tier at mid-depth.
    _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_loop.gd` green. _Effort:_ S.

13. **Clamp thornshelled drops to magic minimum** — `combatant.gd:820` (same site as task 12). After computing `drop_depth`, add a minimum rarity clamp for high-bonus elites. Rather than modifying `drops.gd`, filter the pile post-roll:
    ```gdscript
    var pile: Array = Drops.roll_drop(role, drop_depth)
    # Guarantee magic+ for elites with reward_tier_bonus >= 2 (thornshelled)
    if is_elite and int(Elites.MODIFIERS.get(modifier, {}).get("reward_tier_bonus", 0)) >= 2:
        for i in pile.size():
            if pile[i].get("rarity", "normal") == "normal":
                pile[i]["rarity"] = "magic"
    ```
    _Verify:_ Manual: kill 10 thornshelled elites at depth 5+ (use `WYRD_DEV_LEVEL=5`); expect ≥9/10 magic or better. `test_wyrd_loop.gd` green. _Effort:_ S.

## First commit (smallest shippable slice)

**Tasks 1–3 (Phase 1 visual differentiation only).**

- Modify `data/elites.gd` to add per-modifier `tint`, `ring_color`, and `label_color` keys.
- Modify `combatant.gd::apply_elite` to read `ring_color` for the feet-ring and spawn a floating modifier-name label using `DamageNumberScene`.

Acceptance: run `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_dungeon_scene.gd` — green. Then run `WYRD_DEV_CHART=tier_1 godot --path wyrd` and visually confirm four distinct tints plus floating labels on elite promotion. This is the gap explicitly flagged ("all four share one golden tint today") and ships with zero new behavior — safe to merge any time.

## Test & verification plan

| Phase | Suite | Manual check |
|-------|-------|-------------|
| 1 | `test_wyrd_dungeon_scene.gd` | 4 elite types: distinct body tint, distinct ring color, floating name label in per-modifier color |
| 2 | `test_wyrd_dungeon_scene.gd` | `WYRD_DEV_LEVEL=1` vs `WYRD_DEV_LEVEL=10` — clearly different elite density; large retinue visible in deep rooms |
| 3 | All 4 suites | thornshelled: "snared!" floats on player after melee hit; blightwalker: green disc persists 5s on floor; briarbound CC-immunity still fires |
| 4 | `test_wyrd_loop.gd` | 10 thornshelled kills at depth 5+ yield ≥9 magic+ drops |

New test to author (Phase 3): a lightweight `test_elite_modifiers.gd` that creates a combatant, calls `apply_elite("thornshelled")` / `apply_elite("blightwalker")`, and asserts `is_elite == true`, `modifier == "thornshelled"` etc. This does not need a full dungeon scene — run with `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_elite_modifiers.gd`. Keep it inside the existing headless harness pattern (autoloads load automatically, needs one frame via `await get_tree().process_frame` before reading state).

## Risks & open questions

- **Floating label in headless:** `DamageNumberScene.instantiate()` in `apply_elite` will execute in headless during `test_wyrd_dungeon_scene.gd`. The scene uses `Label3D` (not a `Control`), which is headless-safe. Confirm no crash before shipping Phase 1.
- **Tick-fn closure in `_trigger_blight_pool`:** The recursive `Callable` self-referencing pattern (`tick_fn = func(): ... disc.get_tree().create_timer(0.5).timeout.connect(tick_fn)`) is valid GDScript 4 but the closure must capture `disc` and `mat` by reference — verify `is_instance_valid(disc)` before ticking to avoid use-after-free if the dungeon room is unloaded during the 5s timer chain.
- **Biome-locking new modifiers:** should thornshelled / blightwalker be crypt-only or fully cross-biome? Currently `pick_random` is biome-agnostic (all keys, uniform weight). Decision for user — biome-locking would require passing a biome hint into `pick_random`. V1: leave cross-biome (simpler, more variety per run).
- **HUD "Elite: Swift" readout:** the parent note asks whether a floating label is sufficient or if a persistent HUD readout while targeting is needed. V1: floating name only (tasks 1–3); defer persistent HUD readout to [[impl-system-hud]].
- **Weighted depth-pick for new modifiers:** should thornshelled/blightwalker be more likely at deeper dens? Currently uniform. Defer to a future pass — flat pick keeps the catalogue legible before the content volume justifies weighting.
- **`_cc_immune_until` refactor scope (task 11):** the existing `apply_status` branch hard-codes `modifier == "briarbound"`. Task 11 replaces it with a data-driven check. Run the full headless suite before and after to confirm no regression on the existing briarbound behavior.

## Build status — 2026-06-16

**Phase 1 (Task 1) DONE — `wyrd/data/elites.gd` only.**

- All four original modifiers now have distinct `tint`, `ring_color`, and `label_color` keys:
  - brambled: thorn-green (`Color(0.55, 0.90, 0.40)`) / lime ring
  - swift: ice-blue (`Color(0.50, 0.80, 1.0)`) / deep-sky ring
  - sunlit: ember-gold (`Color(1.0, 0.70, 0.20)`) / hot-orange ring
  - briarbound: deep-violet (`Color(0.85, 0.40, 0.90)`) / vivid-purple ring
- Two new modifier data entries added (thornshelled, blightwalker) with distinct tints and all required keys. Both use only existing dispatch keys (`on_attack`, `on_death`, `cc_immune_window`) already wired in combatant.gd. New dispatch *values* (`spine_burst`, `blight_pool`) are no-ops until combatant.gd is updated.
- `pick_random` is unchanged (picks uniformly from `MODIFIERS.keys()` — automatically includes the two new entries).
- All existing keys per modifier entry preserved; no existing keys removed.

**Deferred to combatant.gd (out of scope):**
- Task 2: pass `ring_color` to `_make_elite_ring` in `apply_elite`
- Task 3: spawn floating modifier-name label using `DamageNumberScene` in `apply_elite`
- Task 9: implement `_trigger_spine_burst` + wire `"spine_burst"` arm in `_elite_on_attack`
- Task 10: implement `_trigger_blight_pool` + wire `"blight_pool"` arm in `_elite_on_death`
- Task 11: data-driven CC-immunity refactor in `apply_status` to cover thornshelled
- Task 12–13: `reward_tier_bonus` consumption in `_spawn_drops`

**Deferred to layout_loader.gd (out of scope):**
- Tasks 4–6 (Phase 2): depth-scaled elite spawn probability, `elite_density` chart multiplier, retinue count scaling
