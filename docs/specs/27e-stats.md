# 27e — Stats: items grant stats

> Wire the loot loop into combat. Equipped items add their base stat + affix values to the player's derived stats — HP, damage, crit chance, crit multiplier, fire rate, move speed. Combat consumes the derived numbers.

## Why

Without this, equipping is just sorting. This is where loot stops being decorative and starts being *power*.

## Scope

### A. Derived stat model
- `player.derived_stats: Dictionary` — `{ hp_max, damage, crit_chance, crit_mult, fire_rate, move_speed }`.
- `_derive_stats()` — starts from base player values (current consts), then iterates equipped items: adds the kind's `base_stat × base_value` and each affix's stat contribution.
- Called on `gear_changed` (the signal from 27d).

### B. Consumers
- **HP** — `hp_max` uses the derived value; `hp` clamps to it on derive (don't increase past current full).
- **Damage** — `arrow.gd` reads the player's derived damage (passed at fire time, not the const).
- **Crit chance / crit multiplier** — `combatant.take_damage()` consults the *attacker* (the player) for crit chance + multiplier (overrides the `CRIT_CHANCE` const when present).
- **Fire rate** — `FIRE_COOLDOWN` uses the derived value (lower cooldown = faster).
- **Move speed** — `RUN_SPEED` / `WALK_SPEED` scale.

### C. Drop chain
- The arrow needs to know the player's damage at fire time. Solution: arrow `setup(damage, crit_chance, crit_mult)` called from `_fire_arrow` with the derived values. arrow stores them; `_on_area_entered` calls `c.take_damage(self.damage, fwd, self.crit_chance, self.crit_mult)`.
- Combatant `take_damage(amount, dir, crit_chance := -1.0, crit_mult := -1.0)` — if positive, uses them; else falls back to its const.

### D. Eval coverage
- `test_stats.gd` — equipping a "+10 HP" item raises `hp_max` by 10; equipping a +damage weapon increases arrow damage; equipping a +crit-chance ring raises observed crit rate over N rolls; unequipping reverts.

## Files

| Path | Action |
|---|---|
| `godot/scripts/player_controller.gd` | `derived_stats` + `_derive_stats()`; consume derived values |
| `godot/scripts/arrow.gd` | `setup(dmg, cc, cm)` carries the player's combat stats |
| `godot/scripts/combatant.gd` | `take_damage` accepts optional `crit_chance/crit_mult` from the attacker |
| `godot/test_stats.gd` | new — equip → derive → consume evals |

## Acceptance
1. Equip a +10 HP item → `hp_max` increases by 10, healing the player accordingly.
2. Equip a +damage weapon → arrows deal the higher number.
3. Equip a +crit-chance ring → crit rate measurably rises in a 200-hit eval.
4. Unequip reverts all of the above.
5. `test_stats.gd` + `test_combat.gd` + `test_movement.gd` all pass.

## Open decisions
- **Base player stats** — current consts become the "no gear" baseline. Confirm: HP 30, damage 6, crit 20%, crit ×2 (super ×3), fire cooldown 0.28, run 4.0, walk 2.0.
- **Stat caps** — crit chance caps at 100%; others uncapped for v1. Tunable.
- **Stacking** — affixes from multiple items add (sum), not multiply. Simple, fair.
