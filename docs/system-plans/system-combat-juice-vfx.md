---
title: Combat Juice & VFX
domain: Enemies & Combat
type: system
status: partial
effort: M
tags: [wayfinder, plan]
---

# Combat Juice & VFX

> Six-channel hit feedback is shipped and solid; the remaining work is three targeted polish passes — biome-tinted spark colors, magnitude-scaled damage numbers, and a breakable-decor shatter shader that reads as material-aware rather than a plain particle dump.

## Current state

All six hit-feedback channels are wired and functional through a single `HitFeedback.play_hit(target, tier, from_dir)` call (`wyrd/scripts/hit_feedback.gd:45`). Hitstop runs as an autoload (`hitstop.gd:15-29`) with tier-keyed durations (0.07 / 0.13 / 0.20 s) and a co-op guard that skips `time_scale` manipulation when NetGame is active. Hit-sparks (`hit_spark.gd:15-59`) spawn GPUParticles3D with three tier colors: normal = warm cream (`Color(1.00, 0.90, 0.55)`), crit = gold, super = purple; particle count bumped 3× from spec baseline after user feedback. Damage numbers (`damage_number.gd:18-30`) use TIER_SCALE = {normal:1.0, crit:1.45, super:1.9} and three matching tier colors, but scale is **purely tier-gated** — a 1-damage normal hit and a 40-damage normal hit render at identical size. The `setup_apply` variant (line 37) handles status verb floaters. Breakable decor (`breakable.gd:42-82`) shatters into a `BoxMesh` particle burst using a flat `_break_color` from `DECOR_BREAKABLE` (`layout_loader.gd:64-65`); only one kind (`pottery`, crypt-brown) is currently registered; the burst uses hard-edged matte cubes with no emission, no biome variance, no hit-flash before the break. Plan.md Part A §2 marks all six channels "textbook, leave it" — the plan here covers only the three remaining partials.

## Gaps — what needs fleshing out

1. **Damage-number magnitude scaling (medium priority)** — `damage_number.gd` maps tier → scale but ignores `amount`. A 2-damage chip and a 60-damage nuke read the same size within the same tier. MapleStory-style magnitude scaling (size grows with `log(amount)` within the tier band) would let big hits feel visually distinct from chip damage without cluttering small numbers.
2. **Spark tier-color biome variants (low-medium priority)** — `hit_spark.gd` has a single global color table. Crypt biome reads correctly, but future biomes (forest, swamp) should tint the spark toward their palette so the feedback feels grounded rather than imported. No biome parameter flows through `HitFeedback.play_hit` today.
3. **Breakable shatter quality (low priority, polish)** — `breakable.gd:_burst()` spawns hard matte `BoxMesh` shards with `roughness=0.9` and no emission. There is no pre-break hit-flash, no screen shake on break (separate from the arrow-hit shake), and the burst is indistinguishable across decor kinds. A two-pass upgrade: (a) add a brief white flash + momentary squash on first hit (pottery survives one hit with HP > 1 via the existing `hp` field — line 8), and (b) give the shard mesh an emission pass matching the break color so shards read as glowing fragments rather than inert rubble.
4. **DECOR_BREAKABLE registry is crypt-only** — `layout_loader.gd:64-65` registers only `pottery`. When new biomes ship, they need their own breakable kinds with matching colors. Not a code gap but a **data gap** — process: add kind → color entry to `DECOR_BREAKABLE`, add GLB asset, done.
5. **`feel.gd` tunables bag is not yet created** — Plan.md B0 calls for a central const bag for all feel tunables. The `hit_feedback.gd` tunables pattern is the reference, but a shared `feel.gd` (planned in B0) could absorb the combat-side constants too. Not blocking; leave it until B0 lands to avoid a double-move.

## Plan

### Phase 1 — Magnitude-scaled damage numbers

Scope: modify `damage_number.gd` and `damage_number.setup()` only. No other files change.

- Add a `_magnitude_scale(amount: int) -> float` helper that maps raw damage to a multiplier via `log`: e.g. `clampf(1.0 + log(maxf(amount, 1)) * 0.11, 1.0, 1.6)`. This returns ~1.0 for amounts 1-5, ~1.25 at 20, ~1.45 at 60. The tier scale then multiplies on top (`_base * _magnitude_scale(amount)`).
- Update `setup(amount, tier)` line 18-21: apply `_magnitude_scale` to `_base` after the tier lookup.
- Keep `setup_apply` unchanged (status verbs are always small).
- Tune the log coefficient against real combat numbers (basic shot ~6-10, crit ~12-18, super ~25-40+) so normal crits do not visually overlap with modest super hits.
- **DoD:** In a live run, a Bramble Snare bleed tick (1-2 dmg) produces a noticeably smaller number than a Power Shot crit (15+ dmg) of the same tier color. Screenshot-comparable. No regressions in `test_wyrd_dungeon_scene.gd`.
- **Effort:** S

### Phase 2 — Biome-aware spark tints

Scope: `hit_spark.gd` and `hit_feedback.gd`. No scenes or assets required.

- Add an optional `biome: String = "crypt"` parameter to `HitSparkScript.spawn(parent, world_pos, tier, biome)`.
- Add a `BIOME_TINT` dict in `hit_spark.gd`: `{"crypt": Color(1,1,1,1), "forest": Color(0.70, 0.95, 0.60), "swamp": Color(0.55, 0.80, 0.55)}`. The biome tint multiplies the tier color (`col * BIOME_TINT.get(biome, Color.WHITE)`).
- Update `HitFeedback.play_hit` to accept an optional `biome` param (default `"crypt"`) and pass it through to `HitSparkScript.spawn`.
- Callers (`combatant.gd:221`) can pass the biome when the dungeon seed records it; for now default `"crypt"` is correct and no callers break.
- **DoD:** Manually call `HitFeedback.play_hit(target, "crit", dir, "forest")` in a test scene; sparks read visibly greener than crypt-default gold. No regressions in existing headless suites (spark is visual-only, no logic paths change).
- **Effort:** S

### Phase 3 — Breakable shatter polish

Scope: `breakable.gd` only (no layout changes, no new assets).

- **Phase 3a — pre-break hit-flash.** When `HP > 1` (multi-hit breakables, future use) or even at `HP == 1`, call `apply_flash(0.08, Color.WHITE)` on `self` (the `StaticBody3D`) — mirror the combatant flash pattern. Because `StaticBody3D` lacks `apply_flash`, add a minimal local `_flash(dur, col)` that iterates `_meshes` (collect `MeshInstance3D` children in `setup()`) and applies a timed `material_override`, same pattern as `combatant.gd:apply_flash`. This gives a half-frame "crack" cue before the particle burst.
- **Phase 3b — emissive shard particles.** In `_burst()` (`breakable.gd:49`), replace the plain `StandardMaterial3D` on the `BoxMesh` with one that sets `emission_enabled = true`, `emission = _break_color`, `emission_energy_multiplier = 1.8`, and `shading_mode = SHADING_MODE_UNSHADED`. This mirrors the `hit_spark.gd` emissive billboard approach. Roughness stays 0.9 (matte exterior); emission makes the shard glow briefly as it flies.
- **Phase 3c — micro camera shake on break.** After `_burst()`, attempt `get_tree().get_first_node_in_group("camera_rig").shake(0.06)` (lowest shake tier). This is smaller than a normal hit shake (0.06 = normal tier) so it does not compete with a simultaneous arrow-hit shake.
- **DoD:** Shoot a pottery jar in the crypt: see a white flash frame, then a burst of glowing terracotta shards with a micro shake. Run `test_wyrd_dungeon_scene.gd` — no new errors; breakable still registers a `take_damage` hit and `queue_free`s correctly.
- **Effort:** S-M

## Dependencies & links

- [[system-combatant-ai]] — `combatant.gd` is the primary caller of `HitFeedback.play_hit`; magnitude scaling lands there via `_spawn_damage_number`. Biome param would be threaded from the combatant's dungeon context.
- [[system-biomes-decor]] — `DECOR_BREAKABLE` lives in `layout_loader.gd` alongside biome decor kinds; new biomes add entries there and Phase 2 biome tints must match.
- [[system-elites]] — Elite enemies route through the same `HitFeedback.play_hit` path; the `super` tier spark fires on marked kills, so magnitude scaling affects elite fight feel directly.
- [[system-bosses]] — Boss `take_damage` calls `HitFeedback.play_hit` on self; super-tier hits on a boss are the highest-stakes VFX moment in the game.
- [[system-status-effects]] — `HitFeedback.tick_pulse` is the status DoT companion to `play_hit`; the tick path intentionally does NOT fire sparks (bleed/burn have their own mesh tint pulse at `hit_feedback.gd:74-86`).
- [[system-audio-music]] — Every phase should wire a matching SFX call; `SFX_BY_TIER` in `hit_feedback.gd` already routes to `Sfx.play`; breakable break needs its own one-shot audio entry.
- **Plan.md Part A** — Phases P1-P5 are shipped/gate-green. This plan is the expansion roadmap for the three gaps Part A left open. Do not re-plan P1-P5 here.
- **Plan.md Part B / Phase B0** — When `feel.gd` lands, migrate `HITSTOP_BY_TIER`, `SHAKE_BY_TIER`, and `KNOCKBACK_MULT` from `hit_feedback.gd` into it for one-file tuning. Not blocking this plan.

## Verification

- **Phase 1** — `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_dungeon_scene.gd` must stay green. Visual check: run a chart run, confirm small bleed ticks (1-2) render smaller than crit arrows (12-18). Screenshot for the record.
- **Phase 2** — No headless coverage for visual-only path; manual check: temporarily call `HitFeedback.play_hit(target, "crit", dir, "forest")` in a test scene, screenshot spark color. Revert the force-call before committing. `test_wyrd_dungeon_scene.gd` must stay green (no API breakage on default `"crypt"` callers).
- **Phase 3** — `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_dungeon_scene.gd` must stay green. Manual play-test: shoot pottery jar, confirm flash + emissive shards + micro shake. Also confirm `take_damage` path still fires (jar must not be invincible after `setup` changes).

## Open questions

- Should pottery have `HP = 1` always (current) or `HP = 2` (allow one crack-flash before shatter)? One-shot is snappier; two-shot adds skill expression for players who want to conserve arrows. Recommend keeping `HP = 1` until there is a design reason to change.
- When biome context flows into `HitFeedback.play_hit`, should the biome be read from the dungeon autoload, passed explicitly, or stored on the `Combatant` node? Explicit parameter is the simplest; autoload lookup avoids threading it through callers. Decide before Phase 2 commit.
