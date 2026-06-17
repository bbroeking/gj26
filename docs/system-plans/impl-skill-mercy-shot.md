---
title: Mercy Shot — Implementation Plan
parent: "[[skill-mercy-shot]]"
domain: Combat Skills
type: implementation-plan
status: ready-to-build
effort: M
tags: [wayfinder, impl]
---

# Mercy Shot — Implementation Plan

> Build doc for [[skill-mercy-shot]]. Done when: the execute threshold shows an amber pulsing ground-ring on any enemy below 35% HP, and a Mercy Shot finishing blow plays a distinct silver-white kill burst — both readable in co-op, both verifiable headless and by screenshot.

## Definition of done

- Any enemy that drops below 35% vigor shows an amber pulsing TorusMesh ring at its feet; the ring disappears on death or when HP rises back above the threshold.
- A Mercy Shot that kills its target (execute branch fires AND `c.hp - dealt <= 0`) shows a silver-white particle fountain + fast-expand ring layered over the standard warm-gold `_kill_burst`.
- Both effects appear on puppet combatants in co-op (visual reads from synced HP fraction).
- All four headless suites remain green after each task.
- Phase 3 (feel.gd tunables) and Phase 4 (mastery perks) are explicitly deferred per [[skill-mercy-shot]] Plan §Phase 3 and §Phase 4; Phase 5 (icon) is deferred pending the icon-gen asset.

## Preconditions / dependencies

- [[impl-system-combat-juice-vfx]] must have shipped the TorusMesh/tween ring pattern (`_death_burst`, `_kill_burst`) that these tasks reuse — **already present** in `combatant.gd:1039-1056` and `combatant.gd:1067-1136`. No blocker here.
- [[impl-system-combatant-ai]] — `combatant.gd` is the surgery site for Task 1–2; read `take_damage` at line 175 and `net_apply_state` at line 245 before editing.
- [[impl-system-status-effects]] — `_kill_burst()` is already called from `_die()` at line 804; the new execute burst layers on top via `arrow.gd`; no status-effect machinery is touched.
- `feel.gd` does NOT exist yet — Phase 3 of [[skill-mercy-shot]] is blocked on Plan.md B0. Do not attempt to create it here.
- No new scene files or assets are needed for Phase 1 or Phase 2 (fully procedural, following the existing torus/GPUParticles pattern).

## Tasks (ordered)

### Phase 1 — Execute-threshold indicator

1. **Add `EXECUTE_RING_BELOW` constant to `combatant.gd`** — `wyrd/scripts/combatant.gd`, constants block near `TELEGRAPH_SEC` at line 41.
   Add `const EXECUTE_RING_BELOW: float = 0.35` and `var _execute_ring: Node3D = null` in the member-var section (near `_elite_ring` at line 80 — same ownership pattern).
   _Verify:_ `grep -n EXECUTE_RING_BELOW wyrd/scripts/combatant.gd` returns one hit. No suite run needed yet.
   _Effort:_ S.

2. **Add `_update_execute_ring(hp_frac: float)` to `combatant.gd`** — `wyrd/scripts/combatant.gd`, new private method after `_kill_burst()`.
   - If `hp_frac < EXECUTE_RING_BELOW` and `_execute_ring == null`: create a `Node3D` container, add a `MeshInstance3D` child holding a `TorusMesh` (inner_radius `0.28`, outer_radius `0.38`), `StandardMaterial3D` with `albedo_color = Color(1.0, 0.65, 0.1, 0.6)`, `emission_enabled = true`, `emission = Color(1.0, 0.65, 0.1)`, `emission_energy_multiplier = 1.8`, `transparency = BaseMaterial3D.TRANSPARENCY_ALPHA`, `shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED`; position the container at `global_position + Vector3(0.0, 0.05, 0.0)`, parent to `get_parent()`, store as `_execute_ring`. Start a looped `Tween` on `mat.albedo_color:a` from `0.45` to `0.75` over `0.8 s` (`set_loops(0)`).
   - If `hp_frac >= EXECUTE_RING_BELOW` and `_execute_ring != null`: call `_execute_ring.queue_free()`, set `_execute_ring = null`.
   - Guard: if already in the correct state, return early (no-op).
   - Explicit types throughout (`var mat: StandardMaterial3D`, `var tw: Tween`, etc.) — "inferred from Variant" is a hard GDScript error.
   _Verify:_ syntax check only at this step; suite green after Task 3.
   _Effort:_ S.

3. **Call `_update_execute_ring` from `take_damage` and `net_apply_state`** — `wyrd/scripts/combatant.gd`.
   - In `take_damage` (line 175), after `hp -= dmg` (line 213, before `_spawn_damage_number`): add `_update_execute_ring(float(hp) / float(hp_max))`.
   - In `net_apply_state` (line 245), after `hp = p_hp` (line 252): add `_update_execute_ring(float(hp) / float(hp_max))`. This handles the puppet path — the ring fires purely from synced HP fraction, no RPC needed.
   - Guard: wrap both call-sites with `if hp_max > 0` to avoid divide-by-zero on just-spawned combatants.
   _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` (stays green — the execute-ring is visual only, no stat mutation). Then a live run: spawn any enemy (e.g. rat or skeleton), chip it below 35% — amber ring should appear at its feet; kill it — ring gone.
   _Effort:_ S.

4. **Clean up `_execute_ring` in `_die()`** — `wyrd/scripts/combatant.gd:806-808`.
   After the `_elite_ring` cleanup block (`_elite_ring.queue_free()`, line 807), add the same pattern for `_execute_ring`:
   ```
   if _execute_ring != null and is_instance_valid(_execute_ring):
       _execute_ring.queue_free()
       _execute_ring = null
   ```
   This ensures the ring does not outlive the death-sink tween.
   _Verify:_ live run — kill an enemy that had the amber ring visible; ring disappears cleanly with the body.
   _Effort:_ S.

> **First commit target:** Tasks 1–4 ship together as the smallest shippable Phase 1 slice. See "First commit" section below.

---

### Phase 2 — Distinct Mercy Shot kill burst

5. **Add `_was_execute_kill: bool` state var to `arrow.gd`** — `wyrd/scripts/arrow.gd`, near `_spent` at line 99.
   Add `var _was_execute_kill: bool = false`. No other changes in this task.
   _Verify:_ `grep -n _was_execute_kill wyrd/scripts/arrow.gd` returns one hit.
   _Effort:_ S.

6. **Set `_was_execute_kill` before `take_damage` in `_on_area_entered`** — `wyrd/scripts/arrow.gd:200-204`.
   Before calling `c.take_damage(...)` (line 204), peek at HP to set the flag:
   ```gdscript
   var hp_frac: float = float(c.get("hp")) / float(c.get("hp_max")) \
       if float(c.get("hp_max")) > 0.0 else 1.0
   var will_kill: bool = (int(c.get("hp")) - dealt) <= 0
   _was_execute_kill = execute_mult > 1.0 and hp_frac < execute_below and will_kill
   ```
   This peek is safe because `take_damage` is synchronous and `_on_area_entered` runs on the physics thread (single-threaded in Godot 4).
   _Verify:_ no suite changes needed yet; logic verified in Task 7.
   _Effort:_ S.

7. **Add `_spawn_mercy_kill_burst(at: Vector3)` to `arrow.gd` and call it** — `wyrd/scripts/arrow.gd`, new private method after `_spawn_power_aoe_burst`.
   Visual spec (silver-white, contrasts the warm-gold `_kill_burst`):
   - `GPUParticles3D`: `amount = 22`, `lifetime = 0.5`, `one_shot = true`, `explosiveness = 1.0`, upward bias `direction = Vector3(0, 1, 0)`, `spread = 40.0`, `initial_velocity_min = 3.5`, `initial_velocity_max = 6.0`, `gravity = Vector3(0, -8.0, 0)`. Color: `Color(0.88, 0.94, 1.0, 0.95)` (cool silver-white). Use `_soft_particle(1.2, Color(0.88, 0.94, 1.0), 3.2, TEX_SOFT_CIRCLE)` for `draw_pass_1` (TEX_SOFT_CIRCLE already preloaded in `arrow.gd:14`).
   - Fast-expand thin ring: `TorusMesh` (inner_radius `0.18`, outer_radius `0.26`), `StandardMaterial3D` with `albedo_color = Color(0.85, 0.92, 1.0, 0.7)`, `emission_enabled = true`, `emission = Color(0.85, 0.92, 1.0)`, `emission_energy_multiplier = 3.5`, `transparency = BaseMaterial3D.TRANSPARENCY_ALPHA`, `shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED`. Tween: scale from `Vector3(0.1, 1.0, 0.1)` → `Vector3(3.0, 1.0, 3.0)` over `0.15 s` (`EASE_OUT`), parallel alpha fade `0.7 → 0.0` over `0.15 s`, then `queue_free`.
   - Parent both to `get_parent()` (so they outlive the arrow's own `queue_free`).
   After `c.take_damage(...)` and the effects loop (line 209-211), after the existing `_explode(global_position)` call (line 240), add:
   ```gdscript
   if _was_execute_kill and c.dead:
       _spawn_mercy_kill_burst(global_position)
   ```
   Strategy: **layer** the mercy burst on top of the standard `_kill_burst` (simpler; revisit if playtests find it noisy — see Open questions in [[skill-mercy-shot]]).
   _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` AND `test_skills.gd` both green (no stat mutation, purely visual). Live screenshot: land a Mercy Shot kill at <35% HP — silver-white burst visible; repeat with BasicShot — warm-gold burst only.
   _Effort:_ S.

## First commit (smallest shippable slice)

**Tasks 1–4** together: the execute-threshold amber ring on enemies. This is the blocker gap from [[skill-mercy-shot]] §Gap 1 and §Phase 1.

Acceptance: any enemy chipped below 35% HP shows the amber pulsing ring; ring disappears on death; `test_wyrd_loop.gd` and `test_skills.gd` stay green; co-op guest sees the ring via the `net_apply_state` path. Screenshot the ring before merging.

Task 5–7 can follow as a second commit (Phase 2 — kill burst).

## Test & verification plan

| Step | Command / action | Pass criterion |
|---|---|---|
| After Task 3 | `cd wyrd && WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` | Green |
| After Task 3 | `cd wyrd && WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd` | Green |
| After Task 4 (Phase 1 full) | Live run — chip enemy below 35% | Amber pulsing ring at feet |
| After Task 4 (Phase 1 full) | Live run — kill that enemy | Ring gone, body sinks |
| After Task 4 (Phase 1 full) | Live run — enemy never drops below 35% | No ring spawns |
| After Task 7 (Phase 2 full) | `cd wyrd && WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` | Green |
| After Task 7 (Phase 2 full) | `cd wyrd && WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd` | Green |
| After Task 7 (Phase 2 full) | Live run — Mercy Shot kill at <35% HP | Silver-white burst visible |
| After Task 7 (Phase 2 full) | Live run — BasicShot kill on same enemy type | Warm-gold burst only |
| After Task 7 (Phase 2 full) | Live run — Mercy Shot that does NOT kill (target survives) | No silver burst; only normal `_explode` |

No new headless test scripts are required for Phase 1–2 because both changes are purely visual (no stat mutations). If Phase 4 (mastery perks) ships, extend `test_wyrd_loop.gd` with a perk-active branch per [[skill-mercy-shot]] §Phase 4 DoD.

## Risks & open questions

1. **Tween leak on instant death.** If an enemy is killed in the same frame the ring is created (unlikely but possible at very high damage), the looped `Tween` may not have started before `queue_free` fires. Mitigation: store the tween reference and call `tw.kill()` inside the `_die()` cleanup block alongside `_execute_ring.queue_free()`.

2. **Ring position drift.** The ring is parented to `get_parent()` (world/dungeon node) and positioned at `global_position + Vector3(0, 0.05, 0)` at spawn time. It does NOT follow the enemy if it moves. For the amber "stay ready" phase this is acceptable — the parent-follow pattern (reparenting to the combatant body) would require the ring to be parented to the combatant instead, which complicates the `_die()` cleanup. Decision: world-parented, static position. If the enemy moves significantly after the threshold crosses, the ring drifts. Flag for playtesting.

3. **Layered vs. exclusive kill burst (Phase 2 open question from [[skill-mercy-shot]]).** Tasks 1–7 layer both bursts. If playtests find the combined warm-gold + silver-white too noisy, suppress `_kill_burst()` for Mercy Shot kills by passing a `skip_standard_burst: bool` flag into `_die()` and guarding `_kill_burst()` with it. Defer until Phase 2 is played.

4. **`EXECUTE_RING_BELOW` vs. `execute_below` skew.** The ring constant in `combatant.gd` (0.35) and `mercy_shot.gd:15` (`execute_below = 0.35`) are separate values that must stay in sync until Plan.md B0 ships `feel.gd`. If the design threshold ever changes, edit both files. This is the Phase 3 blocker documented in [[skill-mercy-shot]] §Phase 3.

5. **Boss HP pools (open question from [[skill-mercy-shot]]).** At 35% on a boss, the ring may linger for a long time. Phase 1 ships uniform pulse speed; add a `boss_pulse_mult: float` parameter to `_update_execute_ring` if playtests reveal the boss ring reads as broken rather than epic.
