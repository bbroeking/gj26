# Implementation notes — 32b-skill-module

## Decisions
- **Skill is RefCounted, not Node.** Skills are pure logic + data; no scene tree presence needed. Lifetime is the `skills` Array on the player. Matches the spec lean.
- **`scripts/skills/` is the first subdirectory in `scripts/`.** Establishes a pattern. The existing top-level convention is preserved for spec 29/31 data classes (`status_effect.gd`, `aoe_query.gd`, `checkpoint.gd`).
- **Duck-typing on the player arg** (`player.has_method("aim_dir")`, `player.get("derived_stats")`, etc.). Defensive against bad caller args — if a Skill is fired against something that isn't the gj26 player, the operations no-op gracefully. Small runtime cost; large flexibility win for future tests.
- **`SkillEffect.apply` duck-types on `target.has_method("apply_status")`** instead of checking `is Combatant`. Lets the same effect apply to a future stand-in target (puppet enemy, training dummy) without subtype gymnastics.

## Deviations
- **Did NOT remove `const ARROW_SCENE` and `const ArrowScript` from `player_controller.gd`** — they're orphaned by 32b (the player no longer spawns arrows directly), but removing them risks a hidden caller. Logged as a followup; non-blocking.
- **`skills` declared `Array`, not `Array[Skill]`** (typed array). GDScript's typed-array `Array[Skill]` requires `class_name Skill` to be registered at parse time, and the loose-typed `Array` works identically for our usage. Minor; could tighten in a followup.

## Tradeoffs
- **Two-level hierarchy (Skill → ProjectileSkill) vs single base.** Picked two-level per Q2.2. ProjectileSkill's data-driven default `fire()` handles 3/4 skills. BrambleSnare extends Skill directly because its shape (AoE, no projectile) doesn't fit the projectile data fields. The hierarchy reads cleanly; the extra abstraction layer is justified by the 3 subclasses that share the data-driven path.
- **`effective_cd` override on BasicShot** specifically — uses `derived_stats.fire_cooldown` instead of `base_cd / (1 + cdr)`. Preserves spec 30's split (fire_rate affix → slot 1; cooldown_reduction affix → slots 2-4). One-method override is cheap; consolidating into a single formula would require a flag or per-skill scaling stat which is more surface area.

## Surprises
- **`test_statuses` T2/T3 regressed** when I removed the `match skill_type:` dispatch from arrow.gd — the spec 31 tests directly set `arrow.skill_type = "power"` and called `_on_area_entered`, relying on the now-dead string-match path. Fixed by setting `arrow.effects = [SkillEffect.burn(...)]` directly in those tests. The Skill module path itself works; the test was poking at internals that moved.
- **`var aim := player.global_position + dir * SNARE_REACH`** failed type inference in `bramble_snare.gd::fire`. GDScript couldn't decide if `dir` (a `Vector3` from `player.aim_dir() if has_method else Vector3.FORWARD`) was actually `Vector3` because of the ternary. Annotated explicitly as `var aim: Vector3` to fix. Same Variant-inference pitfall that bit specs 25/26/27a/27c/31.
- **The four `_fire_*` methods collapsed cleanly** — no hidden state in `player_controller` that they relied on beyond `_mesh`, `_bow`, `_fire_recoil`, `derived_stats`. All of those are now accessed through the new public helpers (`aim_dir`, `arrow_origin`, `bow_pop`, `apply_recoil`) or the `player.get("...")` duck-type path.

## Followups
- **Remove `const ARROW_SCENE` + `const ArrowScript` from `player_controller.gd`** — orphaned after the spec 32b refactor. ProjectileSkill carries its own `ArrowScene` preload. Probably 2 lines to delete.
- **Tighten `var skills: Array` → `var skills: Array[Skill]`** once we're confident `class_name Skill` is reliably available at parse time. Currently loose-typed.
- **Skill variants / runes** (D3 model — 3 variants per skill, swappable Codex). Architecture *enables* this (variant subclasses), no variant ships in v1.
- **`data/skills.gd` registry** — when class-paths (spec 34) need per-class loadouts, a factory like `class_loadout(class_name) -> Array[Skill]` can move out of `player._ready` into a data file.
- **Promote SkillEffect to subclasses** if non-status effects appear (knockback-on-hit, damage-multiplier-on-hit). v1's single-class shape covers status applications only.

## Status
COMPLETE — `test_skills.gd` 7/7 + every other harness still green (81/81 across 11 harnesses). Skill module is the deep seam for player abilities; spec 32 elite on-hit effects plug into `SkillEffect` without expanding the dispatch.
