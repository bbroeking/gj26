# 32c — HitFeedback adapter

> **Outcome**: the 6 channels of hit feedback (flash, knockback, hitstop, hit-spark, camera shake, SFX) collapse into one `HitFeedback` static module with two entry points — `play_hit` for an arrow impact and `tick_pulse` for a status DoT tick. `Combatant.take_damage` keeps the HP + crit + bleed-on-crit logic and hands feedback off in one call. Spec 31's deferred mesh-tint-pulse followup lands as the second entry point.

## Why

The `/improve-codebase-architecture` review flagged candidate #3 as "Worth exploring — defer-able." The grill upgraded it to ship in the pre-`spec 32` arc (Q3.3 resolution) because pack scaling (spec 32) will multiply the number of hits per frame; scattered feedback code becomes harder to tune at scale.

Today's `combatant.take_damage` interleaves 6 feedback channels with the HP + crit logic:

| Channel | How it currently happens |
|---|---|
| Mesh flash | `_flash_t = FLASH_SEC` + `_apply_flash()` (mutates `_meshes` material overrides) |
| Knockback | Set `_knockback` vector inline using tier-scaled `KNOCKBACK` |
| Hitstop | `get_node_or_null("/root/Hitstop")` then `hs.freeze(0.07 / 0.13 / 0.20)` per tier |
| Hit-spark | `HitSparkScript.spawn(get_parent(), position + Vector3.UP, tier)` |
| Camera shake | `_shake(tier)` which finds the camera rig via group lookup |
| SFX | `get_node_or_null("/root/Sfx")` then `play("crit" if tier != "normal" else "hit")` |

Six channels, three autoload/group lookups, three tier-keyed magic-number tables inline. Each new tunable (spec 36 affix-scaled feedback) means three edits.

Deletion test: remove `HitFeedback` and the 6 channels stay scattered across `combatant.gd`, `hit_spark.gd`, and `camera_rig.gd`. Every per-tier tweak takes three edits. Tests can't exercise feedback without spinning up a full enemy scene. The deepening earns its depth because **6 channels always fire together** and shouldn't drift apart.

Bonus alignment: spec 31's notes flagged a deferred followup — *"mesh tint pulse on tick — skipped this spec. Would need to coordinate with `_apply_flash` so they don't fight for `_meshes` ownership."* HitFeedback owns mesh-tint infrastructure; absorbing the tick pulse closes that followup for free.

## Scope

### In

- **`scripts/hit_feedback.gd`** (`class_name HitFeedback extends RefCounted`) — static module, like `aoe_query.gd`. No state; both entry points take their target as an argument.
- **Two entry points**:
  - `static play_hit(target: Node3D, tier: String, from_dir: Vector3) -> void` — fires all 6 channels in the right order. Used by `combatant.take_damage` (and future `player.take_damage` if we ever push status damage through it).
  - `static tick_pulse(target: Node3D, status_kind: String) -> void` — soft mesh-tint pulse for status DoT ticks (Burn, Bleed). Used by `combatant._tick_statuses` when a tick fires.
- **Tier-keyed constants** live as a const dict inside HitFeedback:
  ```gdscript
  const HITSTOP_BY_TIER := {"normal": 0.07, "crit": 0.13, "super": 0.20}
  const SHAKE_BY_TIER   := {"normal": 0.06, "crit": 0.15, "super": 0.30}
  const KNOCKBACK_MULT  := {"normal": 1.0,  "crit": 1.6,  "super": 1.6}
  const SFX_BY_TIER     := {"normal": "hit", "crit": "crit", "super": "crit"}
  ```
  Single source of truth — magic numbers move out of `take_damage` and `_shake`.
- **Pulse colours per status** live as a const dict:
  ```gdscript
  const PULSE_COLOR_BY_STATUS := {
      "burn":  Color(1.00, 0.55, 0.18, 0.35),
      "bleed": Color(0.85, 0.20, 0.20, 0.35),
  }
  ```
  Snared and Root don't pulse (no DoT ticks). The dict's `has(kind)` check gates whether a pulse fires.
- **Combatant exposes two public methods** (promoted from existing private logic):
  - `apply_flash(duration: float = FLASH_SEC, color: Color = Color.WHITE) -> void` — replaces the private `_apply_flash()`. Same logic: set `_flash_t`, swap `_meshes` material overrides to a flash material. Color parameter lets `tick_pulse` pass a status-themed color instead of plain white.
  - `apply_knockback(dir: Vector3, strength: float) -> void` — replaces the inline knockback setup. Computes `_knockback = dir.normalized() * strength * KNOCKBACK_DECAY`.
- **`combatant.take_damage` slims**:
  ```gdscript
  func take_damage(amount, from_dir, crit_chance = -1.0, crit_mult_bonus = -1.0):
      if dead or _iframe_t > 0.0: return
      # crit roll → tier + dmg
      # bleed-on-crit (existing spec 31 hook)
      hp -= dmg
      _spawn_damage_number(dmg, tier)
      _react_t = REACT_SEC
      if _state == State.IDLE: _state = State.CHASE
      HitFeedback.play_hit(self, tier, from_dir)
      if hp <= 0: _die()
  ```
  ~50 lines → ~20 lines.
- **`combatant._tick_statuses` calls the pulse**:
  ```gdscript
  if s.next_tick <= 0.0:
      s.next_tick = s.tick_interval
      _apply_tick_damage(s.damage_per_tick)
      HitFeedback.tick_pulse(self, kind)
  ```
  Closes the spec 31 followup. Currently the tick visual is just the damage number; this adds the soft tint pulse.
- **`scripts/hit_spark.gd`, `scripts/hitstop.gd`, `scripts/camera_rig.gd`** stay where they are — HitFeedback orchestrates them through their existing public APIs (`HitSparkScript.spawn`, `Hitstop.freeze`, `camera_rig.shake`).
- **`test_combat.gd`** stays largely the same — feedback assertions go via `combatant._knockback`, `combatant._flash_t`, `combatant.hp` (all still exist). Add one new test: T22 — calling `HitFeedback.tick_pulse(combatant, "burn")` flips `combatant._flash_t > 0` and uses the burn color (verify via the material override's albedo_color matches PULSE_COLOR_BY_STATUS["burn"]).
- **`CONTEXT.md` addition**:
  - **HitFeedback** — the system that fires the 6 visual/audio channels when a Combatant takes a hit or a status DoT ticks. Static module; tier-keyed tunables in one place. _Avoid_: impact-effect, hit-react.
- **`docs/GODOT_PIPELINE.md`** — add "Hit feedback (spec 32c)" pointing here.

### Out (explicit non-goals)

- **Affix-scaled feedback** (e.g. `+15% hit shake` affix). Spec 36 territory — but HitFeedback's tier dicts will be where those affixes plug in.
- **Player-side feedback**. `player_controller.take_damage` has its own flash/whiteout flow; not absorbed in v1. If we generalize, that's spec 32d+ work.
- **Spec 30 footnote**: PowerShot's `_fire_recoil = -0.6` recoil is a *bow* effect, not a *target* effect. Stays in `Skill._play_recoil`. HitFeedback is target-side only.
- **A new `Feedback` audio bus** or richer audio pipeline. SFX play stays via `/root/Sfx` autoload.
- **Generalised `MeshFlash` for any tint-mesh use case** (option C from the grill). Two entry points are enough for v1.
- **Removing the existing `_react_t` punch + telegraph punch in `_tick_feedback`**. Those are state-machine animation, not feedback dispatch. Stays in combatant.
- **Reordering when feedback fires relative to damage**. Current order (damage_number → flash → state → hitstop → spark → shake → SFX) preserved.

## Files

| Path | Action |
|---|---|
| `scripts/hit_feedback.gd` | **new** — static module; `play_hit` + `tick_pulse` + tier/status const dicts |
| `scripts/combatant.gd` | Promote `_apply_flash` → public `apply_flash(duration, color)`; add public `apply_knockback(dir, strength)`; slim `take_damage` to use `HitFeedback.play_hit`; `_tick_statuses` calls `HitFeedback.tick_pulse` on tick |
| `test_combat.gd` | Confirm existing assertions still pass; add one new test for `tick_pulse` |
| `CONTEXT.md` | Add HitFeedback entry |
| `docs/GODOT_PIPELINE.md` | Brief "Hit feedback (spec 32c)" section pointing here |

## Acceptance criteria

1. `HitFeedback.play_hit(combatant, "normal", Vector3.FORWARD)` fires all 6 channels: combatant flashes white, takes knockback, hitstop registers, hit-spark spawns, camera shakes (if camera_rig available), `Sfx.play("hit")` runs.
2. `HitFeedback.play_hit(combatant, "crit", ...)` and `("super", ...)` scale hitstop, shake, knockback per the tier dicts, and call `Sfx.play("crit")`.
3. `HitFeedback.tick_pulse(combatant, "burn")` applies a soft orange flash for 0.08s (lighter than `play_hit`'s flash) and doesn't trigger knockback/spark/shake/SFX.
4. `combatant.take_damage` is ≤ 25 lines (was ~50).
5. Combatant's `apply_flash(duration, color)` and `apply_knockback(dir, strength)` are public methods callable from `HitFeedback` and (in theory) any future caller.
6. Spec 31's status DoT ticks now visibly pulse the mesh in the status color — verify by hitting an enemy with PowerShot and watching the orange pulses every 0.5s for 3s.
7. `test_combat.gd` 22/22 green (21 existing + 1 new).
8. Every other harness still green.
9. World boots, score ≥ 0.9. Playtest a hit chain — combat feels identical to before, just with the added soft pulses on burning enemies.

## Open decisions

All load-bearing decisions resolved by the grill (#3.1, #3.2, #3.3). Mini-decisions resolved by lean:

- **`HitFeedback` extends `RefCounted`, not autoload** — no shared state, no need for global singleton. Static methods are sufficient. Same pattern as `AoeQuery` from spec 31.
- **`apply_flash` default color is white** — preserves existing hit-flash behavior. `tick_pulse` passes a status-themed color.
- **`apply_flash` accepts a `duration` param** so `tick_pulse` can use a shorter pulse (~0.08s) vs the hit flash's `FLASH_SEC = 0.12s`. Both go through the same internal mechanism.
- **Pulse colors use alpha 0.35** (not fully opaque) so the pulse reads as a soft wash rather than a hard flash. Distinguishes tick-pulse from hit-flash visually.
- **`tick_pulse` skips if `has_status_overlap_with_active_flash()`** — avoids fighting the hit-flash for `_meshes` ownership. If the combatant's `_flash_t > 0` (hit-flash active), the pulse is suppressed for this tick. Prevents the spec 31 followup concern from re-emerging.
- **Tier-keyed dicts on HitFeedback** (not on Combatant). Single source of truth.
- **No SFX for `tick_pulse`** — the existing hit/crit SFX would be too noisy at 0.5s tick rate. Visual only.
- **`HitSparkScript.spawn` call signature unchanged** — HitFeedback just passes through. Future spark refactor (spec 36?) could promote it into HitFeedback.
- **No ADR** — reversible refactor.

## References

- Architecture review HTML at `/var/folders/85/24ylx5853k791kpbpq8qzkjm0000gn/T/architecture-review-20260526-084353.html` (candidate #3).
- Spec 14 (`docs/specs/14-hit-feedback.md` if it exists, otherwise spec 14's notes) — original hit-feedback work this consolidates.
- Spec 26 — crit tiers (normal/crit/super) used by HitFeedback.
- Spec 31 (`docs/specs/31-status-and-aoe-notes.md`) — flagged the "mesh tint pulse on tick" followup that this spec closes.
- `CONTEXT.md` — HitFeedback entry added here.

## Done check

- [ ] `scripts/hit_feedback.gd` written with both entry points + tier/status dicts
- [ ] `combatant.gd::apply_flash` is public, accepts `(duration, color)`
- [ ] `combatant.gd::apply_knockback` is public, accepts `(dir, strength)`
- [ ] `combatant.take_damage` ≤ 25 lines; calls `HitFeedback.play_hit`
- [ ] `combatant._tick_statuses` calls `HitFeedback.tick_pulse(self, kind)` on tick
- [ ] `tick_pulse` suppressed when `_flash_t > 0` (no fight with hit-flash)
- [ ] `test_combat.gd` updates pass; new T22 added for tick_pulse
- [ ] Every other harness still green
- [ ] World boots; visual playtest confirms tick pulses appear on burning enemies
- [ ] `CONTEXT.md` HitFeedback entry present
- [ ] `GODOT_PIPELINE.md` Hit feedback section added
