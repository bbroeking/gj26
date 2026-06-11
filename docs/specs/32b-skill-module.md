# 32b — Skill module + SkillEffect

> **Outcome**: the four hardcoded `_fire_*` methods in `player_controller.gd` and the `skill_type`-string match in `arrow.gd` collapse into a two-level Skill hierarchy. On-hit consequences become data (`SkillEffect`) carried by the projectile. Adding a 5th skill becomes "subclass `ProjectileSkill` and set data fields." Spec 32 elite on-hit effects (Brambled, Sunlit) drop into `SkillEffect` without expanding the dispatch.

## Why

The `/improve-codebase-architecture` review flagged candidate #2 (skill dispatch) and #5 (on-hit effects) as the second-strongest deepening pair. The grill paired them (Q2.1 resolution): both ends of the loop — *fire* on the player side and *on-hit* on the arrow side — touch the same `Skill` concept. Splitting them into two specs would touch the same files twice.

Today's shape:
- `player_controller.gd` has `_fire_arrow`, `_fire_powershot`, `_fire_multishot`, `_cast_bramble_snare` — three of which are 95% identical (aim → spawn arrow(s) → recoil → SFX → bow_pop) and one of which is a different AoE shape.
- `_try_skill(slot)` is a match block that dispatches by slot number to the named method.
- `arrow.gd::_on_area_entered` has `match skill_type:` for the on-hit status apply, with arms for `"power"` (burn) and `"multi"` (snared).
- The `SKILLS` const dict only carries cost + cd; everything else lives in the firing code.

The interface restates the implementation. The Explore deletion test: remove a `Skill` adapter and copy-paste scales linearly with skill count — spec 30 already paid the price for the existing four, spec 32+ elite-modifier effects will pay again.

This spec ships as **spec 32b**, after 32a (Pickup) and before 32c (HitFeedback) and spec 32 (pack scaling). Order matters because spec 32's elite on-hit effects (Brambled death-nova → Bleed, Sunlit melee → Burn-patch) use `SkillEffect` for free if 32b lands first.

## Scope

### In

- **`scripts/skills/` subdirectory** — first per-module subdir in the project. Establishes a pattern for future per-concept clusters.
- **`scripts/skills/skill.gd`** (`class_name Skill extends RefCounted`) — abstract base. Common fields: `name: String`, `cost: float`, `base_cd: float`. Utility methods consumed by subclasses:
  - `_aim_dir(player) -> Vector3` — input direction or mesh-facing fallback (extract from `player._aim_dir`)
  - `_arrow_origin(player, dir) -> Vector3` — bow tip or chest origin (extract from `player._arrow_origin`)
  - `_spawn_arrow(player, origin, dir, damage, skill_type, effects)` — instantiates Arrow scene, sets damage/crit/skill_type/effects, add_child to player's parent
  - `_play_recoil(player, amount)` — sets `player._fire_recoil`
  - `_play_bow_pop(player, scale_mult)` — tween on player's bow
  - `effective_cd(player) -> float` — base_cd / (1.0 + clamp(derived_stats.cooldown_reduction, 0, CDR_CAP))
  - Abstract `fire(player) -> void` (pushes error if called on base)
- **`scripts/skills/projectile_skill.gd`** (`class_name ProjectileSkill extends Skill`) — data-driven default fire for arrow-based skills. Adds fields:
  - `damage_mult: float = 1.0` — multiplied with `player.derived_stats.damage`
  - `projectile_count: int = 1`
  - `spread_deg: float = 0.0`
  - `skill_type: String = "basic"` — for arrow visual scale
  - `on_hit_effects: Array[SkillEffect] = []`
  - `recoil_amount: float = 0.4`
  - `bow_pop_mult: float = 1.22`
  - `sfx_key: String = "fire"`
  
  Default `fire(player)` consumes these: aim, snap mesh rotation, compute origin, loop `projectile_count` arrows at ±half-spread around the aim, set each arrow's damage + skill_type + effects, play recoil + bow_pop + SFX.
- **`scripts/skills/basic_shot.gd`** (`class_name BasicShot extends ProjectileSkill`) — sets `name="BasicShot"`, `cost=0`, `base_cd=0.28`, `damage_mult=1.0`, `skill_type="basic"`, `on_hit_effects=[]`, `recoil_amount=0.4`, `bow_pop_mult=1.22`, `sfx_key="fire"`. No `fire()` override.
- **`scripts/skills/power_shot.gd`** (`class_name PowerShot extends ProjectileSkill`) — `cost=20`, `base_cd=1.5`, `damage_mult=2.5`, `skill_type="power"`, `on_hit_effects=[SkillEffect.burn(3.0, 1, 0.5)]`, `recoil_amount=0.6`, `bow_pop_mult=1.35`, `sfx_key="skill_power"`.
- **`scripts/skills/multi_shot.gd`** (`class_name MultiShot extends ProjectileSkill`) — `cost=25`, `base_cd=2.0`, `damage_mult=0.5`, `projectile_count=3`, `spread_deg=40` (±20° per arrow), `skill_type="multi"`, `on_hit_effects=[SkillEffect.snared(1.5, 0.5)]`, `recoil_amount=0.45`, `bow_pop_mult=1.20`, `sfx_key="skill_multi"`.
- **`scripts/skills/bramble_snare.gd`** (`class_name BrambleSnare extends Skill`) — extends `Skill` directly (not ProjectileSkill — it's AoE, not projectile). Overrides `fire(player)` with the existing snare logic from `player_controller._cast_bramble_snare` (AoeQuery.query_circle, apply_root, disc visual, SFX). Constants `SNARE_RADIUS = 2.5`, `SNARE_REACH = 4.0`, `SNARE_DURATION = 2.0` move here.
- **`scripts/skills/skill_effect.gd`** (`class_name SkillEffect extends RefCounted`) — single class for all v1 on-hit effects. Fields: `status_kind: String`, `duration: float`, `damage_per_tick: int = 0`, `slow_factor: float = 1.0`, `tick_interval: float = 0.0`. Method: `apply(target: Node) -> void` calls `target.apply_status(...)` if the target supports it. Static factories: `SkillEffect.burn(duration, dpt, interval)`, `SkillEffect.snared(duration, slow)`, `SkillEffect.bleed(...)` (for future use).
- **`scripts/arrow.gd`** — add `effects: Array = []` field. Replace the `match skill_type:` block with `for e in effects: e.apply(c)` after the existing `take_damage` call. `skill_type` field stays — it still drives the visual scale (`if skill_type == "power": scale *= 1.4`).
- **`scripts/player_controller.gd`**:
  - Remove `_fire_arrow`, `_fire_powershot`, `_fire_multishot`, `_cast_bramble_snare`, `_aim_dir`, `_arrow_origin`, `_spawn_arrow`, `_bow_pop`, `_effective_skill_cd`. These move into `Skill` / `ProjectileSkill`.
  - Remove the `SKILLS` const dict. Skill instances are the new source of truth.
  - Add `var skills: Array = []` instantiated in `_ready()`:
    ```gdscript
    skills = [BasicShot.new(), PowerShot.new(), MultiShot.new(), BrambleSnare.new()]
    ```
  - `_try_skill(slot)` becomes ~12 lines: bounds-check, focus check, cooldown check (read from `_skill_cooldowns[slot]`), call `skills[slot - 1].fire(self)`, decrement focus + arm cooldown + bump `_combat_t`.
  - The F-key fire path: `_fire_buffer` flow remains, but the firing call goes through `skills[0].fire(self)` (skill 0 = BasicShot).
- **`scripts/skill_bar.gd`** — read from `player.skills[i].name`, `.cost`, `.base_cd` instead of the now-deleted `SKILLS` const dict. `SKILL_LABELS` / `SKILL_COSTS` / `SKILL_BASE_CDS` arrays in `skill_bar.gd` go away (read from player.skills at bind time).
- **`test_skills.gd`** — rewrite T1–T6:
  - Tests instantiate Skill subclasses directly: `var s = PowerShot.new()`.
  - T2 (PowerShot Focus drain + cd) calls `s.fire(stub_player)` and asserts focus/cd.
  - T3 (MultiShot 3 arrows) asserts 3 arrows spawn with `skill_type="multi"` after `MultiShot.new().fire(player)`.
  - T4 (Snare roots) calls `BrambleSnare.new().fire(player)` and asserts enemies in radius get root status.
  - T5 (CDR affix scales skill 2-4) becomes `PowerShot.new().effective_cd(player)` with affix mocked into `player.derived_stats`.
  - New T7: `SkillEffect.burn(3.0, 1, 0.5).apply(target_combatant)` adds a "burn" status with the right fields.
- **`CONTEXT.md`** additions:
  - **Skill** — a player-usable ability bound to a hotbar slot. Carries cost (Focus), cooldown, and a list of SkillEffects applied on hit. Concrete kinds: BasicShot, PowerShot, MultiShot, BrambleSnare. _Avoid_: ability, spell, attack.
  - **SkillEffect** — the on-hit consequence of a Skill (e.g. apply burn, apply snared). Read by the arrow at impact and applied to the hit target. _Avoid_: on-hit, ailment-data.
- **`docs/GODOT_PIPELINE.md`** — add a "Skill system (spec 32b)" section pointing here.

### Out (explicit non-goals)

- **Subclass-per-SkillEffect-kind** (BurnEffect, SnaredEffect classes). v1 effects all apply statuses; a single class with a discriminator is enough. Subclass when a non-status effect kind appears (knockback-on-hit, damage-multiplier, summon-on-kill).
- **Skill variants / runes** (D3 model — 3 variants per skill, swappable Codex). Architecture *enables* this (Skill subclasses can have variant subclasses) but no variant ships in 32b.
- **Class-paths skill loadouts** (Ranger / Wisp / Forager pick different starting skills). Spec 34 territory. v1 stays with the single Ranger loadout inlined in `player._ready`.
- **`data/skills.gd`** registry. Skills are code, not data — the data-style registry pattern (mirroring `data/affixes.gd`) waits for class-paths to motivate it.
- **`scripts/skills/` migration of unrelated files**. Only new files land in the subdir. The status_effect.gd, aoe_query.gd, etc. stay at top-level.
- **`SkillBar` UI redesign**. The cooldown sweep + cost overlay stay as-is — only the data source changes.
- **Removing `_fire_buffer`** — the input-buffer pattern for the F-key BasicShot stays (it makes the snappy-spam feel work).
- **Renaming `skill_type` on Arrow**. The string identifier still routes the visual scale; it's not the on-hit dispatcher anymore.

## Files

| Path | Action |
|---|---|
| `scripts/skills/skill.gd` | **new** — base class + utility helpers + abstract `fire` |
| `scripts/skills/projectile_skill.gd` | **new** — extends Skill, data-driven default `fire` |
| `scripts/skills/basic_shot.gd` | **new** — extends ProjectileSkill, data only |
| `scripts/skills/power_shot.gd` | **new** — extends ProjectileSkill, data only |
| `scripts/skills/multi_shot.gd` | **new** — extends ProjectileSkill, data only |
| `scripts/skills/bramble_snare.gd` | **new** — extends Skill, overrides `fire` with AoE logic |
| `scripts/skills/skill_effect.gd` | **new** — RefCounted; status-applying on-hit data |
| `scripts/arrow.gd` | Add `effects: Array` field; replace `match skill_type:` with `for e in effects: e.apply(c)`. Keep `skill_type` for visual scale. |
| `scripts/player_controller.gd` | Remove the 4 `_fire_*` methods + helper methods; remove `SKILLS` const; add `skills: Array` instance; shrink `_try_skill` to dispatcher |
| `scripts/skill_bar.gd` | Read skill data from `player.skills[i]` instead of const arrays |
| `test_skills.gd` | Rewrite T1–T6 to instantiate Skill subclasses directly; add T7 for SkillEffect.apply |
| `CONTEXT.md` | Add Skill + SkillEffect entries |
| `docs/GODOT_PIPELINE.md` | Brief "Skill system (spec 32b)" section pointing here |

## Acceptance criteria

1. `BasicShot.new().fire(player)` spawns one arrow at the player's aim direction with damage = `player.derived_stats.damage`, skill_type=`"basic"`, empty effects.
2. `PowerShot.new().fire(player)` spawns one arrow with damage = `round(derived_stats.damage * 2.5)`, skill_type=`"power"`, effects containing one SkillEffect that applies burn.
3. `MultiShot.new().fire(player)` spawns three arrows in a ±20° cone, each with damage = `round(derived_stats.damage * 0.5)`, skill_type=`"multi"`, effects applying snared.
4. `BrambleSnare.new().fire(player)` spawns the emerald disc + roots every enemy in 2.5m of aim point for 2s — same behavior as current `_cast_bramble_snare`.
5. `arrow._on_area_entered` no longer contains `match skill_type:` — only the iteration `for e in effects: e.apply(c)`.
6. `player_controller.gd` no longer contains `_fire_arrow`, `_fire_powershot`, `_fire_multishot`, `_cast_bramble_snare`, or the `SKILLS` const dict.
7. `_try_skill(slot)` is < 15 lines.
8. SkillBar renders identically to before (cost labels + cooldown sweep + grey-out when unusable) but pulls from `player.skills[i]`.
9. `test_skills.gd` 7/7 green (T1–T6 rewritten + new T7 for SkillEffect.apply).
10. Every other harness still green (80/80 before this spec; 87/87 expected after if 32a's +1 lands too, otherwise 80/80 with test_skills going from 6 to 7).
11. World boots, score ≥ 0.9. Manual fire each of the 4 skills and confirm visual + Focus + cooldown behavior matches spec 30/31.

## Open decisions

All load-bearing decisions resolved by the grill (#2.1, #2.2). Mini-decisions resolved by lean:

- **`Skill` extends `RefCounted`** (not Node). Skills are pure logic + data, not scene objects. `RefCounted` is automatic memory management. Lifetime tied to the player.
- **`fire(player)` is abstract on `Skill`** (pushes error) and overridden by ProjectileSkill + BrambleSnare. Subclasses of ProjectileSkill don't need to override (data fields are enough).
- **`SkillEffect.apply(target)`** uses duck typing on `target.has_method("apply_status")` (same pattern as spec 31). If the target isn't a Combatant (player, for instance), apply is a no-op.
- **Static factories on SkillEffect** (`SkillEffect.burn(...)`) for ergonomics. The `new()` + set-fields path stays available.
- **`SKILL_LABELS`/`SKILL_COSTS`/`SKILL_BASE_CDS` in `skill_bar.gd` are removed** — read at bind time from `player.skills`. Avoids drift.
- **`MultiShot.damage_mult = 0.5`** preserves the spec 30 followup tuning (3 arrows × 50% = 1.5× total damage).
- **`BrambleSnare` does NOT have on_hit_effects** — its effect (Root) is applied directly inside `fire(player)` via `enemy.apply_root(2.0)`. Effects-as-data only apply to projectile skills.
- **No `data/skills.gd` registry** — the skill list is inlined in `player._ready` as the v1 loadout. The data/* pattern (mirroring affixes/items/drops) waits for class-paths to motivate it.
- **`effective_cd(player)` lives on `Skill` base** — returns base_cd / (1.0 + cooldown_reduction). Slot 1 (BasicShot) still scales with `fire_rate` for parity with spec 30 — overridden in BasicShot to read `derived_stats.fire_cooldown` instead.
- **`CDR_CAP = 0.80`** constant moves into `Skill` (used by `effective_cd`). Was on player_controller before.
- **`scripts/skills/` subdir adds a layer of preload paths**: `const BasicShot = preload("res://scripts/skills/basic_shot.gd")` etc. Use `class_name` declarations so callers can write `BasicShot.new()` without preloading.
- **No ADR** — the deepening is reversible; the two-level hierarchy is defensible but could collapse to single-level if 4 skills doesn't justify ProjectileSkill.

## References

- Architecture review HTML at `/var/folders/85/24ylx5853k791kpbpq8qzkjm0000gn/T/architecture-review-20260526-084353.html` (candidates #2 + #5).
- `CONTEXT.md` — Pickup definition (from spec 32a); Skill + SkillEffect entries added here.
- Spec 30 (`docs/specs/30-skills-and-cooldowns.md`) — original Skill system this deepens.
- Spec 31 (`docs/specs/31-status-and-aoe.md`) — `apply_status` interface that SkillEffect consumes; `AoeQuery.query_circle` reused by BrambleSnare.fire.
- Spec 32a (`docs/specs/32a-pickup-deepening.md`) — the prerequisite Pickup deepening; same architecture-review arc.
- Skill: `~/.claude/skills/improve-codebase-architecture/LANGUAGE.md` — module/interface/depth/seam/leverage/locality vocabulary used throughout.

## Done check

- [ ] `scripts/skills/` directory created
- [ ] `skill.gd` + `projectile_skill.gd` + `skill_effect.gd` written
- [ ] 4 concrete skill subclasses written (basic_shot / power_shot / multi_shot / bramble_snare)
- [ ] `arrow.gd` has `effects` field + iterating for loop
- [ ] `player_controller.gd` shrunk: 4 `_fire_*` methods + helper methods + SKILLS const removed; `skills: Array` instantiated; `_try_skill` < 15 lines
- [ ] `skill_bar.gd` reads from `player.skills[i]`
- [ ] `test_skills.gd` 7/7 green
- [ ] Every other harness still green
- [ ] World boots, manual playtest of all 4 skills works
- [ ] `CONTEXT.md` Skill + SkillEffect entries present
- [ ] `GODOT_PIPELINE.md` Skill section added
