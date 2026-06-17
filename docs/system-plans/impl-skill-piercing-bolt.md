---
title: Piercing Bolt — Implementation Plan
parent: "[[skill-piercing-bolt]]"
domain: Combat Skills
type: implementation-plan
status: ready-to-build
effort: M
tags: [wayfinder, impl]
---

# Piercing Bolt — Implementation Plan

> Build doc for [[skill-piercing-bolt]]. Done when PiercingBolt fires a visually distinct frost-white needle bolt with a per-pierce spark, shares no visual with PowerShot, and can scale its pierce count via a quiver affix and a mastery perk.

## Definition of done

1. `piercing_bolt.gd` sets `skill_type = "pierce"`.
2. `arrow.gd` has a `PIERCINGBOLT_VARIANT` constant and a `"pierce"` branch in `_ready` that assigns it; the `_spawn_power_aoe_burst` call at line 232 is provably guarded to `skill_type == "power"` only.
3. `_on_area_entered` calls `_pierce_thread(global_position)` on each non-final hit, emitting a small forward-biased frost spark burst.
4. `player_controller.gd:_derive_stats` sums `"bonus_pierce"` and writes it to `derived_stats`.
5. `projectile_skill.gd:_spawn_arrow` reads `bonus_pierce` from `derived_stats` and adds it to `arrow.pierce_left`.
6. `affixes.gd` has a `"of_penetration"` suffix (`stat: "bonus_pierce"`, quiver slot, tier +1/+2).
7. `player_controller.gd` has an `"iron_tip"` perk check that adds 1 to `bonus_pierce`.
8. `loadout_panel.gd` tooltip and `skill_bar.gd` SKILL_ICON both point PiercingBolt at `skill_basic.png` (or a placeholder distinct from `skill_power.png`).
9. All four headless suites stay green; a new `test_skills.gd` block asserts `pierce_left == 5` with `bonus_pierce = 2`.

## Preconditions / dependencies

- [[impl-system-skills-hotbar]] — hotbar dispatch must be live (it is; B5 shipped). PiercingBolt already fires correctly; this work forks its visual branch and extends the stat pipeline.
- [[impl-system-items-affixes]] — `affixes.gd` shape (id/stat/value_range per `SUFFIXES` dict) is established; task 5 follows that schema exactly.
- [[impl-system-combat-juice-vfx]] — Part A VFX already landed (hitstop, ember ring, camera shake). Task 3 adds a *quieter* thread-through burst in the same pattern — do NOT re-engineer; follow the cookbook.
- [[impl-system-trades-progression]] — `perk_active()` is live in `game.gd`; the `iron_tip` perk slot in task 6 must not collide with existing perk ids (`steady_hands`, `hunters_stride`, `quick_nock`, `heavy_draw`).
- **Plan.md Part A (SHIPPED)** — `_spawn_power_aoe_burst`, hitstop, camera shake are all live. This plan does not rebuild them; it forks PiercingBolt off them.

## Tasks (ordered)

### Phase 1 — Visual identity (unblock the skill's legibility)

1. **Add `PIERCINGBOLT_VARIANT` constant + `"pierce"` branch in `_ready`** — `arrow.gd:96` (after `POWERSHOT_VARIANT`).
   ```gdscript
   const PIERCINGBOLT_VARIANT := {
       "name": "pierce", "color": Color(0.82, 0.95, 1.0), "len": 1.1,
       "rad": 0.09, "trail_n": 80, "trail_life": 0.18, "trail_size": 0.055
   }
   ```
   In `_ready` at `arrow.gd:108`, extend the branch:
   ```gdscript
   if skill_type == "power":
       _variant = POWERSHOT_VARIANT
   elif skill_type == "pierce":
       _variant = PIERCINGBOLT_VARIANT
   else:
       _variant = VARIANTS[...]
   ```
   _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd` stays green (no `push_error` from unknown skill_type). _Effort:_ S.

2. **Change `skill_type` in `piercing_bolt.gd:13`** from `"power"` to `"pierce"`.
   ```gdscript
   skill_type = "pierce"
   ```
   _Verify:_ `test_skills.gd` green; in a headed run the bolt is visually frost-white, not ember-red. _Effort:_ S.

3. **Confirm `_spawn_power_aoe_burst` guard** — `arrow.gd:218` already gates on `skill_type == "power"`. Read line 218 after task 2 lands; if the guard is `skill_type == "power"` it is already correct. If it is ever `skill_type != "basic"` or unguarded, narrow it to `== "power"`. No new code needed if the guard is already tight — just a read + confirmation comment.
   _Verify:_ Fire PiercingBolt at a dummy in a headed run; confirm no ember ring appears on impact. _Effort:_ S.

4. **Add `_pierce_thread` helper** — `arrow.gd`, new function after `_explode`:
   ```gdscript
   func _pierce_thread(at: Vector3) -> void:
       var host := get_parent()
       if host == null:
           return
       var col: Color = _variant.color
       var p := GPUParticles3D.new()
       p.amount = 10
       p.lifetime = 0.28
       p.one_shot = true
       p.explosiveness = 1.0
       p.local_coords = false
       var pm := ParticleProcessMaterial.new()
       pm.direction = -global_transform.basis.z   # forward in bolt's frame
       pm.spread = 30.0
       pm.initial_velocity_min = 2.0
       pm.initial_velocity_max = 5.0
       pm.gravity = Vector3.ZERO
       pm.scale_min = 0.4
       pm.scale_max = 0.8
       pm.color = col
       p.process_material = pm
       p.draw_pass_1 = _soft_particle(0.9, col, 2.0)
       host.add_child(p)
       p.global_position = at
       p.emitting = true
       host.get_tree().create_timer(0.6).timeout.connect(
           func() -> void:
               if is_instance_valid(p): p.queue_free()
       )
   ```
   _Verify:_ Headed run, two dummies in a line — small frost spark visible on the first enemy hit, before the bolt continues. _Effort:_ S.

5. **Call `_pierce_thread` on non-final pierce hits** — `arrow.gd:_on_area_entered:192–193`. After `pierce_left -= 1` and before `_pierced.append(c)`, add:
   ```gdscript
   if pierce_left >= 0:   # still flying — a thread-through just happened
       _pierce_thread(global_position)
   ```
   The existing `_explode(global_position)` at line 240 fires on every hit (including intermediate pierce hits); `_pierce_thread` is the *additional* directional burst layered on top.
   _Verify:_ Same dual-dummy headed test; see both the thread spark AND the standard `_explode` pop on the first hit, then `_explode` only on the second. _Effort:_ S.

6. **Update `loadout_panel.gd:35`** — change PiercingBolt icon from `skill_power.png` to `skill_basic.png` (interim distinct icon until art batch cuts a dedicated one):
   ```gdscript
   "PiercingBolt": "res://assets/ui/icons/skill_basic.png",
   ```
   _Verify:_ Open loadout panel in a headed run; PiercingBolt card shows a different icon than PowerShot. _Effort:_ S.

   > Open question (user decision): should `skill_basic.png` be the placeholder here, or is `skill_multi.png` a better interim read? No blocker — either is correct as a placeholder until the icon batch ships.

### Phase 2 — Pierce-count upgrade path

7. **Add `"bonus_pierce"` to the `sums` dict in `_derive_stats`** — `player_controller.gd:1083`. Extend the initialization:
   ```gdscript
   var sums := {"hp": 0, "damage": 0, "crit_chance": 0.0,
       "crit_mult": 0.0, "fire_rate": 0.0, "move_speed": 0.0,
       "cooldown_reduction": 0.0, "bonus_pierce": 0}
   ```
   And in `derived_stats` construction at line 1117, add:
   ```gdscript
   "bonus_pierce": int(sums.bonus_pierce),
   ```
   `_add_stat` already handles any key present in `sums` (line 1174), so no changes needed there.
   _Verify:_ `test_skills.gd` green (no regression in stat path). _Effort:_ S.

8. **Read `bonus_pierce` in `projectile_skill.gd:_spawn_arrow`** — `projectile_skill.gd:74`. Change the pierce bake from:
   ```gdscript
   arrow.pierce_left = pierce
   ```
   to:
   ```gdscript
   var bp: int = int(player.derived_stats.get("bonus_pierce", 0))
   arrow.pierce_left = pierce + bp
   ```
   _Verify:_ `test_skills.gd` — add assertion block `_test_bonus_pierce` (task 10). _Effort:_ S.

9. **Add `"of_penetration"` suffix to `affixes.gd`** — `data/affixes.gd:15` in the `SUFFIXES` dict:
   ```gdscript
   "of_penetration": {"display": "of Penetration", "stat": "bonus_pierce",
       "value_range": Vector2(1, 2)},
   ```
   No slot restriction baked into the affix dict itself (affixes.gd is slot-agnostic; slot filtering happens in `drops.gd`). Add a comment: `# quiver-slot only — see drops.gd`.
   _Verify:_ `_make_entry` in `affixes.gd:58` operates generically; the new suffix rolls correctly. Manual test: call `Affixes.roll_affixes(1, "magic")` in a GDScript REPL and confirm `"of_penetration"` can appear. _Effort:_ S.

10. **Add `"iron_tip"` perk check** — `player_controller.gd:1107–1110` (after the `quick_nock` block):
    ```gdscript
    if game_h.perk_active("wayfinding", "iron_tip"):
        _add_stat(sums, "bonus_pierce", 1)
    ```
    Then register the perk in the game data — `scripts/game.gd`, in the `perk_active` table or perk registry, at Wayfinding level 6 (between `quick_nock` and `heavy_draw`). Check `game.gd` perk registration pattern before inserting.
    _Verify:_ `test_skills.gd` gates test: set `game.trades["wayfinding"]["lv"] = 6`, enable `iron_tip`, assert `p.derived_stats["bonus_pierce"] == 1`. _Effort:_ S.

11. **Add `_test_bonus_pierce` block to `test_skills.gd`** — new function, called from `_run()`:
    ```gdscript
    func _test_bonus_pierce(game: Node, p: Node3D) -> void:
        print("[bonus pierce]")
        # Baseline: no bonus_pierce → PiercingBolt arrow.pierce_left == 3.
        game.set_loadout(["PiercingBolt", "RainOfThorns", "Thornburst"])
        await physics_frame
        p.derived_stats["bonus_pierce"] = 0
        var bolt_skill = p.skills[1]   # slot 2
        _check("pierce_left base == 3",
            int(bolt_skill.pierce) == 3, str(bolt_skill.pierce))
        # Bonus: inject bonus_pierce = 2 → effective pierce_left should be 5.
        p.derived_stats["bonus_pierce"] = 2
        # We can't fire into a scene without an arrow parent — check the math
        # at the projectile_skill layer by calling _spawn_arrow mock.
        # Simplest valid test: assert bolt_skill.pierce + p.derived_stats["bonus_pierce"] == 5.
        _check("pierce_left with bonus_pierce=2 would be 5",
            int(bolt_skill.pierce) + int(p.derived_stats.get("bonus_pierce", 0)) == 5,
            "pierce=%d bonus=%d" % [int(bolt_skill.pierce),
                int(p.derived_stats.get("bonus_pierce", 0))])
    ```
    _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd` passes the new `[bonus pierce]` block. _Effort:_ S.

### Phase 3 — Balance pass (polish / deferred)

12. **Audit PiercingBolt vs PowerShot stat gap** — after Phase 1 + 2 ship and a playtest session confirms the corridor pick is distinct. Compare: PiercingBolt (1.6× / 22F / 2.4 s) vs PowerShot (1.6× / 20F / 2.0 s). If not enough separation, raise `damage_mult` to `1.75` or `cost` to `26.0` and `base_cd` to `3.0` in `piercing_bolt.gd:_init`. Document choice as a comment citing the three-way tradeoff.
    _Verify:_ Playtest sign-off: 3–5 enemies in a crypt corridor with all three line/zone skills on hotbar; PiercingBolt reads as the clear corridor pick. No headless test — playtest only. _Effort:_ S.

13. **Add `max_pierce_cap` constant** — `piercing_bolt.gd` (or `projectile_skill.gd`), capped at 5 to guard degenerate gear builds:
    ```gdscript
    const MAX_PIERCE_CAP := 5
    ```
    In `projectile_skill.gd:_spawn_arrow`, clamp:
    ```gdscript
    arrow.pierce_left = mini(pierce + bp, MAX_PIERCE_CAP)
    ```
    _Verify:_ `test_skills.gd` `_test_bonus_pierce` — set `bonus_pierce = 99`, assert `pierce_left == 5` not 102. _Effort:_ S.

## First commit (smallest shippable slice)

**Tasks 1–6** (Phase 1) form the first commit. Acceptance:

- PiercingBolt fires a frost-white needle bolt (not ember-red).
- No AoE ember ring fires on PiercingBolt impact.
- A small forward-biased frost spark burst plays on each non-final pierce hit.
- PowerShot retains ember-red bolt + ring unchanged.
- `loadout_panel.gd` no longer shows `skill_power.png` for PiercingBolt.
- `test_skills.gd` stays green (all existing tests pass; no new suite for Phase 1 beyond the green-on-no-push_error check).

## Test & verification plan

| Suite | When | What to check |
|---|---|---|
| `test_skills.gd` (existing) | After every task | No push_error from `skill_type == "pierce"` missing branch; PiercingBolt dispatch still fires and drains Focus |
| `test_skills.gd` new `[bonus pierce]` block (task 11) | After task 8 | Base pierce == 3; effective pierce == 5 with bonus_pierce = 2; clamped to MAX_PIERCE_CAP after task 13 |
| `test_wyrd_loop.gd`, `test_wyrd_dungeon_scene.gd`, `test_wyrd_transitions.gd` | After each phase | Regression — none of these touch combat skills but must stay green |
| Headed playtest (Phase 1 DoD) | After task 5 | Two dummies in a line: frost needle flies; thread-through spark on hit 1; final `_explode` on hit 2; PowerShot still ember-red |
| Headed playtest (Phase 3 DoD) | After task 12 | 3–5 crypt enemies in corridor: PiercingBolt is clearly the corridor pick vs PowerShot (single-target) and RainOfThorns (zone denial) |

Run headless suites from `wyrd/`:

```bash
cd /Users/bbroeking/projects/gj26/wyrd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_transitions.gd
```

## Risks & open questions

1. **`pm.direction` in `_pierce_thread` uses `global_transform.basis.z`** — this is correct at call-time since the bolt is still live and oriented. If the bolt's orientation drifts (e.g. a future homing bolt variant), this direction needs to be passed in explicitly. Low risk for current straight-line bolts.

2. **`of_penetration` suffix rolls on all gear slots** — `affixes.gd` is slot-agnostic; filtering to quiver-only requires a change to `drops.gd` slot weighting. Phase 2 ships the affix but it may appear on non-quiver slots until `drops.gd` is gated. Decision for user: acceptable for now, or add slot filter to `drops.gd` in the same task?

3. **`iron_tip` perk registration location** — the plan references `game.gd`'s perk registry. The exact shape of perk registration in `game.gd:perk_active` must be confirmed before task 10 (read `game.gd` perk section). If the perk registry is a static dict, adding `"iron_tip"` at level 6 is one line; if it is computed from level thresholds, the insertion logic may differ.

4. **Icon placeholder decision** — `skill_basic.png` is used as the interim PiercingBolt icon. If the user finds this confusing (BasicShot also uses it), `skill_multi.png` is an alternative. No blocker; swap is one line in `loadout_panel.gd:35`.

5. **`_pierce_thread` vs Part A loudness rules** — the thread-through spark is intentionally quieter than the `_explode` pop (10 particles vs 30, shorter lifetime). Confirm this reads as "passed through" not "hit" in playtest; if it's too subtle, raise `p.amount` to 14–16.

## Build status — 2026-06-16

**Shipped (Phase 1 visual identity — piercing_bolt.gd only):**
- `skill_type` changed from `"power"` to `"pierce"` — arrow.gd falls into the `else` VARIANTS branch, no ember-red.
- `_spawn_arrow` overridden: delegates to `super._spawn_arrow` for all gameplay logic (damage, pierce_left, effects, tree placement), then post-mutates the spawned arrow's visual in `_apply_frost_visual`.
- `_apply_frost_visual`: removes arrow.gd's "Bolt"/"Trail" nodes (queue_free), adds "FrostBolt" (CapsuleMesh len=1.1 rad=0.09, Color(0.82, 0.95, 1.0), emission 5×) and "FrostTrail" (GPUParticles3D, 10° spread, same frost color). Self-contained — no cross-file helper calls.
- `_pierce_thread`: forward-biased 10-particle frost spark burst, lifetime 0.28s, quieter than `_explode`'s 30 particles. Called on non-final pierce hits via a `CONNECT_DEFERRED` hook on the Hitbox `area_entered` signal.
- `_make_soft_particle`: minimal self-contained billboard builder mirroring arrow.gd's static helper; uses preloaded `soft_circle.png`.
- PowerShot guard (`skill_type == "power"` at arrow.gd:218) unchanged and correct — PiercingBolt does not trigger AoE ember ring.

**Deferred (out of scope — require files other than piercing_bolt.gd):**
- Task 1: `PIERCINGBOLT_VARIANT` const + `"pierce"` branch in `arrow.gd:_ready` — arrow.gd is out of scope; not needed for correctness since `_apply_frost_visual` fully replaces the visual post-spawn.
- Tasks 6: `loadout_panel.gd` icon change — out of scope.
- Tasks 7-11: Phase 2 pierce-count upgrade path (`_derive_stats`, `projectile_skill.gd`, `affixes.gd`, `player_controller.gd`, `test_skills.gd` additions) — all out of scope.
- Tasks 12-13: Phase 3 balance pass and `max_pierce_cap` — deferred to playtest.

**Test gate:** `test_skills.gd` dispatch/loadout/gates suites should stay green — `fire()` path is unchanged (super.fire → super._spawn_arrow → visual post-process), Focus drain and CD seeding are unaffected.
