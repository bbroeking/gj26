# Implementation notes — 32c-hit-feedback

## Decisions
- **`apply_flash` reuses `_flash_mat` for white**, allocates a fresh material for coloured pulses. Hit flashes happen many times per second in combat; allocating per call would churn. Status tick pulses are 0.5s+ apart; per-call materials are fine.
- **Combatant's `_apply_tick_damage` no longer applies a flash itself** — `HitFeedback.tick_pulse` is called from `_tick_statuses` after the damage hook. Keeps the visual layer in one place. `_apply_tick_damage` only nudges `_flash_t` up to half-FLASH_SEC so `_tick_feedback`'s decay still has something to chew on if a status kind has no pulse colour entry.
- **`HitFeedback` is a static class** (`extends RefCounted`, no instance state). Pattern matches `AoeQuery`. The const tier dicts and the `HitSparkScript` preload are the only state.

## Deviations
- **`apply_flash` accepts the duration as a parameter** instead of setting it in the caller. Spec said the same — confirmed in implementation. The old `_flash_t = FLASH_SEC` + `_apply_flash()` two-step is now one call.
- **Did not promote `_restore_flash` to public**. It's only called by `_tick_feedback` (per-frame internal decay); no external caller needs it.

## Tradeoffs
- **Suppress-during-hit-flash gate** uses `_saved.is_empty()` as the lock (it's already the existing re-entrance guard in `apply_flash`). When a hit-flash is active, `_saved` is non-empty → a second `apply_flash` call returns early → tick_pulse no-ops cleanly. Reuses the existing guard; no new state.
- **Coloured pulse emission energy is 1.5×** (vs the white flash's 2.0×). Subtler — pulses shouldn't read as "this is a fresh impact." Per the spec's "softer than the hit flash" lean.

## Surprises
- **Test T22 became H1** — slotted into the existing `_test_section_h` (newly created) so the section letter naming (E/F/G) extends cleanly. Spec said "T22"; section letter is a better convention here.
- **`var pre_pulse_flash := e._flash_t`** triggered the recurring GDScript Variant-inference parse error (since `e` is `Node3D` typed and `_flash_t` access goes through `get()`). Fixed with explicit `var pre_pulse_flash: float = ...`. Same pitfall as specs 25/26/27a/27c/31/32b.
- **`HitSparkScript.spawn(target.get_parent(), ...)`** moved smoothly into HitFeedback. The spark spawn was already a static call; just relocated the call site.

## Followups
- **`tick_pulse` emission energy 1.5×** vs hit flash 2.0× — playtesting may want a different ratio. Tunable via `HitFeedback`'s materials, but currently the value lives inline in `combatant.apply_flash`. If we want HitFeedback to fully own the visual params, expose `apply_flash` differently (e.g. take a full material) — followup if the playtest signals it.
- **The `_flash_mat` field stays on Combatant** even though most flashes now flow through `apply_flash(...)`. It's used as the white-default shortcut. Could move into HitFeedback if we wanted; current placement keeps the per-combatant mesh-cache code together.
- **Player-side feedback** (`player_controller.take_damage`) doesn't go through HitFeedback. That's by spec scope. If we ever want unified feedback (e.g. an enemy crit on the player triggering the same spark/shake), promote.

## Status
COMPLETE — `test_combat.gd` 22/22 (added H1 for tick_pulse) + every other harness still green (82/82 across 11 harnesses). HitFeedback is the deep seam for impact + tick-pulse visuals; spec 32 elites' on-hit modifiers (Brambled death-nova, Sunlit melee burn) will trigger feedback through this seam cleanly.
