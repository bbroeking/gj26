# 33a — Player-side status framework

> **Outcome**: the player can be Burn / Bleed / Snared / Root'd — same status framework as Combatant from spec 31, ported onto `player_controller`. Sunlit elite (spec 32) finally applies real Burn DoT instead of the +3 immediate stand-in. HP bar gains a status-suffix readout (`"HP 25/30 — burning"`). Minimal v1: functional behavior + text UI; per-status particles and tick pulses on the player are a polish followup.

## Why

Spec 32 shipped Sunlit elites that *should* apply Burn to the player on melee contact. But `player_controller` doesn't extend Combatant, so spec 31's `apply_status` interface isn't there. The v1 stand-in was `take_damage(3, Vector3.ZERO)` — works as damage, doesn't read as "I'm on fire."

This spec ports the framework. Future enemy modifiers / boss attacks / environmental hazards can target the player with the same `apply_status` interface they use against enemies.

This is **spec 33a** — the "a" because spec 33 is reserved for "Loot rain feel" per the roadmap (Phase A #4). Sequencing this BEFORE 33 because the showcase site work (and any further elite tuning) benefits from the player visibly burning.

## Scope

### In

- **`player_controller.gd::_statuses: Dictionary`** — same shape as Combatant's, keyed by kind string. Default `{}`.
- **`player_controller.gd::apply_status(kind, duration, dpt, slow_factor, tick_interval) -> StatusEffect`** — port of Combatant's method:
  - If dead, return null
  - If status exists: take max of `time_left`, max of `damage_per_tick`, min of `slow_factor`. Refresh-by-stronger.
  - Else create a new StatusEffect, store, return.
  - **Skip the Briarbound CC-immune gate** — that's Combatant-side (elite gates only their own statuses).
  - **Skip visual creation** — no per-status particles on player v1.
- **`player_controller.gd::has_status(kind) -> bool`** and **`get_status(kind) -> StatusEffect`** — simple dict accessors.
- **`player_controller.gd::_tick_statuses(delta)`** — same shape as Combatant's: per-frame decrement, fixed-interval damage tick, expiry cleanup. Call from `_physics_process` after the existing combat/skill bookkeeping.
- **`player_controller.gd::_apply_tick_damage(amount)`** — port of Combatant's helper. Bypasses `take_damage`'s i-frame check (DoT ticks should land even during i-frames; player can't dodge their own status). Spawns a damage number; flashes the HP bar.
- **`player_controller.gd` slow application** — extend the existing speed pickup in `_physics_process` (`var spd: float = derived_stats.walk_speed if Input.is_action_pressed("walk") else derived_stats.run_speed`) to multiply by `_status_slow_product()`. Cap at 0.25× minimum like Combatant.
- **`player_hud.gd::set_hp(cur, mx, status_suffix: String = "")`** — extend the existing signature with an optional status suffix. Text becomes `"HP 25/30 — burning · snared"`. When no suffix, behavior unchanged.
- **`player_controller.gd::_physics_process` integration**:
  - Call `_tick_statuses(delta)` after the existing combat-timer/skill-cooldown decrement
  - After tick, compute status suffix string (e.g. `"burning"`, `"snared"`, etc.) and call `_hud.set_hp(hp, hp_max, suffix)` if any status is active
  - Otherwise call `_hud.set_hp(hp, hp_max, "")` (current default)
- **`combatant.gd::_trigger_burn_pulse` rewrite** — replace the spec 32 stand-in:
  ```gdscript
  # OLD: _player.take_damage(3, Vector3.ZERO)
  # NEW:
  if _player.has_method("apply_status"):
      _player.apply_status("burn", 3.0, 1, 1.0, 0.5)
  ```
- **Eval coverage**: new `test_player_status.gd` — 4 evals:
  - **P1** — `player.apply_status("burn", 3.0, 1, 1.0, 0.5)` → `has_status("burn") == true`; over 6 fixed-interval ticks, HP drops by 6.
  - **P2** — `player.apply_status("snared", 1.5, 0, 0.5, 0.0)` → player movement speed during the snare is 50% of the unsnared speed (verify via `_status_slow_product()` return).
  - **P3** — `player.apply_status("bleed", 4.0, 1, 1.0, 1.0)` → 4 ticks, 4 damage total.
  - **P4** — End-to-end Sunlit: spawn elite Sunlit combatant, position adjacent to player, trigger its attack (via `_did_hit = true` and `_telegraph_t = 0` path in `_tick_ai`), verify `player.has_status("burn")` afterwards.

### Out (explicit non-goals)

- **Per-status particles on the player.** Enemies get particle visuals via Combatant's `_make_status_particle`; player doesn't. v1 ships function + text UI only.
- **`HitFeedback.tick_pulse` on the player.** Player has no `apply_flash` method (the spec 32c work was Combatant-side). Adding it requires touching the existing damage flash infrastructure on player_controller; out of scope.
- **Player-side status icons HUD** (Diablo-style row of icons next to HP). Polish followup; text suffix carries v1.
- **Enemy crits bleeding the player.** Spec 31's bleed-on-crit hook stays gated to `is_in_group("enemy")`. Bleed-on-crit is the player's *reward*; not flipping to a punishment.
- **Briarbound CC-immune for player.** The CC-immunity gate is elite-side only (it's about being a tough leader). Player gets normal apply_status without the gate.
- **Sunlit reverting to +3 immediate damage on fallback.** If apply_status fails on the player (shouldn't happen), the burn just doesn't land. No double-damage path.
- **Spec 31's status framework extraction into a shared mixin.** Architecturally cleaner, but Combatant's status code is entangled with `_meshes` / `_flash_mat` / `_apply_tick_damage`. Port now; extract later if a third caller (e.g. boss-side status, breakable obj statuses) appears.

## Files

| Path | Action |
|---|---|
| `godot/scripts/player_controller.gd` | Add `_statuses` + `apply_status` / `has_status` / `get_status` / `_tick_statuses` / `_apply_tick_damage` / `_status_slow_product` / `_status_suffix`. Wire tick + suffix into `_physics_process`. Apply slow to movement speed. |
| `godot/scripts/player_hud.gd` | `set_hp(cur, mx, status_suffix: String = "")` — optional 3rd arg for suffix. |
| `godot/scripts/combatant.gd` | `_trigger_burn_pulse` switches from `take_damage(3, ZERO)` to `apply_status("burn", ...)`. |
| `godot/test_player_status.gd` | **new** — 4 evals. |
| `docs/GODOT_PIPELINE.md` | Brief "Player status system (spec 33a)" pointing here. |

## Acceptance criteria

1. `player.apply_status("burn", 3.0, 1, 1.0, 0.5)` adds the status; `has_status("burn")` returns true.
2. Over a 3-second burn (6 fixed-interval ticks at 0.5s each), player HP drops by 6 (one per tick).
3. While `Snared` (slow_factor 0.5), player movement is half the un-snared speed (verifiable via inspecting the speed multiplier).
4. While `Root`'d, player can't move (slow product clamped at 0.25× still allows some movement; player's existing dash/roll bypass).
5. HP bar text reads `"HP 25/30 — burning"` when burn is active, `"HP 25/30 — burning · snared"` when multiple, `"HP 25/30"` when none.
6. Sunlit elite hitting the player applies real Burn (verify via `player.has_status("burn") == true` post-hit) and ticks damage over 3s. The +3 immediate stand-in is gone.
7. `test_player_status.gd` 4/4 green.
8. Every existing harness still green (86/86 before this spec; 90/90 after).
9. World boots, manual playtest: get hit by a Sunlit, see burning suffix in HP bar.

## Open decisions

All resolved by leans. Mini-decisions:

- **`_apply_tick_damage` bypasses `take_damage`'s i-frame check** on the player. Same reasoning as Combatant: i-frames are for incoming attacks, not for ticks of already-applied statuses. Otherwise an i-frame from a roll could pause your burn.
- **Status suffix joins with `" · "`** (middle dot, U+00B7) — visually distinct from comma; reads as a list separator.
- **Suffix words are lower-case** to read as "the player is X" rather than label-style ("HP — Burning · Snared"). Stylistic match to FATE's HP-text approach.
- **Status order in the suffix** follows the dict's insertion order. Stable enough; doesn't need sort.
- **`_status_slow_product` clamped 0.25 ≤ x ≤ 1.0** matches Combatant. Root is the only true immobilizer (and bypasses through being a separate `has_status("root")` check, not the slow product).
- **No `_combat_t` bump** when a status applies. Combatant's combat timer is for Focus regen rate; that's player-side already and unaffected by *being* burned. The combat timer bumps from `take_damage` (existing).
- **Sunlit's `_trigger_burn_pulse` keeps the distance check** (`global_position.distance_to(_player.global_position) <= 2.5`). Just swaps the action.

## References

- Spec 31 (`docs/specs/31-status-and-aoe.md`) — the original status framework being ported.
- Spec 32 (`docs/specs/32-pack-scaling.md`) — Sunlit elite, the immediate consumer of the new player-status interface.
- `scripts/combatant.gd::_statuses` / `apply_status` / `_tick_statuses` / `_apply_tick_damage` — the pattern being ported.

## Done check

- [ ] `_statuses` + `apply_status` / `has_status` / `get_status` on `player_controller`
- [ ] `_tick_statuses` + `_apply_tick_damage` ported
- [ ] `_status_slow_product` applied to movement speed; root bypass
- [ ] `_physics_process` calls tick + updates HUD suffix
- [ ] `player_hud.set_hp(cur, mx, status_suffix)` signature extended
- [ ] `combatant._trigger_burn_pulse` switches to `apply_status` call
- [ ] `test_player_status.gd` 4/4 green
- [ ] Every other harness still green
- [ ] World boots; Sunlit hit visibly burns the player in the HP-bar text
- [ ] `GODOT_PIPELINE.md` player-status section added
