# Implementation notes — 27e-stats

## Decisions
- **`derived_stats` holds totals** (not just bonuses) — keys: `hp_max`,
  `damage`, `crit_chance`, `crit_mult_bonus`, `fire_cooldown`, `run_speed`,
  `walk_speed`. Combat consumers read totals directly; one less arithmetic
  step at the call site.
- **Affix application semantics:**
  - `hp` and `damage` — additive (base + sum of values).
  - `crit_chance` — additive on top of the 0.20 base, **clamped to 1.0**.
  - `crit_mult_bonus` — additive on top of the base ×2 (crit) / ×3 (super)
    multipliers; affix value 0.40 → crit deals `amount × 2.40`.
  - `fire_rate` — interpreted as **attack-speed bonus**; cooldown =
    `base / (1 + sum)`. Affix value 0.05 → ~5% faster shots.
  - `move_speed` — **multiplier** on both `RUN_SPEED` and `WALK_SPEED`.
- **Crit-chance + multiplier are *per-shot*** — the arrow carries them
  (`damage / crit_chance / crit_mult` instance vars set by the player
  before `add_child`), and `combatant.take_damage` accepts them as
  optional params (default `-1.0` = "use the combatant's own consts").
  Backward-compatible: every existing 2-arg call still works.
- **HP rules on derive** — `hp = mini(hp, hp_max)` after `hp_max` updates.
  Equipping a +HP item raises the *ceiling* but doesn't auto-heal; losing
  it shrinks the bar and clamps current HP down. PoE-style.
- **Dash + roll speeds NOT scaled** by `move_speed` — they're burst
  movement; gear shouldn't make them snappier (would compound oddly with
  the i-frame window). Run/walk only.

## Deviations
- *(none — implementation matches the spec.)*

## Tradeoffs
- **`fire_cooldown = base / (1 + bonus)`** vs `base * (1 - bonus)` — chose
  the divide form so 100% attack-speed gives a 0.5× cooldown (not 0×).

## Surprises
- **Boss `take_damage` signature broke compile** — `boss.gd` overrides
  `take_damage(int, Vector3)` and GDScript enforces parent-signature
  match. Adding the same defaulted crit params to the boss override fixed
  it. Without that, the entire test_combat harness fails to load (lost the
  G-section evals).
- **S1 expected `+10` only** in the first draft; forgot the helmet's own
  `base_stat: hp, base_value: 4` rolls in too. Fixed the test (expected
  +14). Worth remembering for 27f's tooltips: list the kind's base stat
  alongside the affixes so the reader sees the full picture.

## Followups
- **Cap UI** — no in-game readout of derived stats yet; 27f's tooltips
  will show per-item contributions, but a "character sheet" panel
  showing totals (HP/DMG/Crit/etc) is a clear next polish.
- **Move_speed compounds with `dash` cooldown** — currently dash COOLDOWN
  isn't affected, only run/walk speeds. If play-test asks for it, scale
  too.
- **Negative affixes** — none exist yet; if added later, `derive_stats`'s
  clamp on `crit_chance` (0..1) is the only guard. Other stats can
  go negative — fine for now (no current items emit negatives).
- **Crit_chance > 1.0 is clamped** but `super_crit_chance` (0.04) is
  unaffected by gear. Super always rolls first (`if roll < 0.04: super`)
  so even at 100% crit you still get supers within the 0..0.04 band.

## Status
COMPLETE — `test_stats.gd` **5/5**, `test_equipment.gd` **7/7**,
`test_inventory.gd` **8/8**, `test_drops.gd` **5/5**, `test_combat.gd`
**21/21**, `test_movement.gd` **6/6**, `test_items.gd` **7/7**, World boots
score 1.00. Equipped gear now actually changes combat — HP, damage, crit,
fire rate, move speed all live. 27f (tooltips + polish) closes the loop.
