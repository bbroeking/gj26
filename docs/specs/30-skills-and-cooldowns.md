# 30 — Skills + cooldowns + Focus

> **Outcome**: the player has a real 4-skill ARPG hotbar bound to keys 1–4. BasicShot stays free and snappy (slot 1, F also fires it). Three new skills — PowerShot, MultiShot, Bramble Snare — gate on a single regenerating **Focus** resource and per-skill cooldowns. The combat loop changes from "spam F" to "spend Focus on the right tool for the room."

## Why

Spec 29 ended with everything an ARPG needs *except* combat surface area — the player has one button (F) and one effect (single-target arrow). Every dungeon plays identically because there are no choices to make in a fight. The ARPG-roadmap synthesis put this at #1 priority: combat is what the player touches every second, so it has the biggest impact on "feels like Diablo/PoE/FATE."

The genre research (FATE: Reawakened, Diablo 3, Path of Exile 2 — see `30-skills-and-cooldowns-research.md`) recommends a 4-skill hotbar with a single regenerating resource, hybrid cooldown + cost gating, and skill design that answers four different questions (**kill a tank, clear a pack, create space, save my life**). The first three become PowerShot / MultiShot / Bramble Snare; the fourth (save-my-life) is already covered by Roll's i-frames outside the hotbar, so no ultimate slot ships in v1.

## Scope

### In

- **Focus resource on the player.** Var `focus: float`, max `FOCUS_MAX = 50`. Regen `FOCUS_REGEN_OUT = 10.0` /sec when not in combat, `FOCUS_REGEN_IN = 3.0` /sec when in combat. **In-combat = damaged in last 3 seconds** (timer `_combat_t` reset to 3.0 in `take_damage`, decremented each frame; in-combat while > 0).
- **4-slot hotbar bound to keys 1–4** via new actions `skill_1..4`. The existing `bolt_1..4` bindings (spec 26 variant cycling) are **removed**; BasicShot is hardwired to the gold visual variant.
- **F still fires BasicShot** (the muscle memory stays).
- **Skill 1 — BasicShot.** Existing arrow path. Free, 0.28s CD (the existing `FIRE_COOLDOWN`, still scaled by the existing `fire_rate` affix), 6 damage, gold variant. No mechanical change beyond losing the variant-cycle keybinds.
- **Skill 2 — PowerShot.** Single arrow, **2.5× BasicShot damage** (`int(round(damage_base * 2.5))`), 20 Focus, **1.5s** base CD. Same arrow scene, with `skill_type = "power"` so the renderer can scale the visual up (1.4× scale + bright trail). Travels at SPEED (existing 50).
- **Skill 3 — MultiShot.** Spawns **3 arrows in a cone** at ±20° from aim direction. 25 Focus, **2s** base CD. Each arrow does base damage (no per-arrow bonus). All three roll crit independently.
- **Skill 4 — Bramble Snare.** Spawns a **2.5m radius AoE** at the player's current aim point (`global_position + facing * 4.0`, clamped to the floor plane). Any enemy whose `global_position.distance_to(impact) < 2.5` calls `combatant.apply_root(2.0)` — root immobilizes for 2 seconds (`_root_t = 2.0`, enemy's `_tick_ai` short-circuits to `velocity.x = velocity.z = 0` while `_root_t > 0`). Visual: a circle decal on the floor + small "vine" sprites at each rooted enemy's feet, fade out as the root expires. 30 Focus, **4s** base CD. **No DoT and no generic status framework in v1** — root is a one-off, intentionally minimal (the framework lands in spec 31).
- **New `cooldown_reduction` affix.** Suffix pool entry (e.g. "of Swiftness"), values 0.05 / 0.10 / 0.15 / 0.20 by tier (normal / magic / rare / unique). Sums into `derived_stats.cooldown_reduction`. **Scales skills 2–4 only** — skill CD = `BASE_CD / (1.0 + cooldown_reduction)`. Capped at 0.80 (D3 model) so CDs can't go below 20% of base. `fire_rate` continues to scale BasicShot CD unchanged.
- **`damage` affix** continues to scale all skills (PowerShot's 2.5× is computed on top of the affix-summed base).
- **UI: Focus bar** under the HP bar in `PlayerHUD`. Ink-line style, same width as HP, half height, golden-amber fill (`#d8a25e`-ish). `player_hud.set_focus(cur, max)` updates it; player calls each frame after `_regen_focus`.
- **UI: skill bar** at bottom-center of the viewport. New `SkillBar.tscn` + `skill_bar.gd`. 4 square slots (60×60 px), 8 px gap, each shows: keybind label top-left (`1`/`2`/`3`/`4`), skill name center (placeholder text `Bow` / `Pow` / `Mlt` / `Snr` for v1 — proper icons are a polish followup), Focus cost bottom-right. Cooldown sweep is a `ColorRect` rotated each frame (D3 style — a semi-transparent black sector that shrinks counter-clockwise as the cooldown elapses); icon greys out (modulate alpha 0.4) while on cooldown OR while Focus < cost.
- **Skill dispatch on `player_controller`.** `func _try_skill(slot: int)` checks: (a) skill is off cooldown, (b) Focus ≥ cost. Fails silently if not (no error, but the icon stays greyed). On success: decrements Focus, sets the per-skill cooldown timer in `_skill_cooldowns: Dictionary`, spawns the relevant arrow(s) or snare effect, sets the in-combat timer (using a skill IS aggressive — counts as in-combat), plays a SFX.
- **`combatant.apply_root(duration: float)`** — new method. Sets `_root_t = duration`; `_tick_ai` skips chase/attack movement while `_root_t > 0`; `_physics_process` decrements. Visual indicator: a small bramble billboard via spawn_floater or a simple SpriteBase3D at the enemy's feet, queue_free'd after duration.
- **SFX hooks.** 3 new sfx paths (deferred audio, same pattern as spec 29): `skill_power`, `skill_multi`, `skill_snare`. play() no-ops until files land. **Confirm cost (~$0.30) before generating.**
- **Eval: `test_skills.gd`** — 6 evals.

### Out (explicit non-goals)

- **Ultimate slot (Hedgemother's Wrath).** Roll covers "save my life." Ultimate is its own followup spec.
- **Skill variants / runes.** D3-style swappable variants per skill — followup spec (likely 31 or 32).
- **Status effect framework.** Snare's root is a one-off; burn/freeze/poison/bleed and the tick system land in spec 31.
- **DoT ticks.** Snare is root-only. DoT system lands with spec 31.
- **Focus-related affixes** (focus_regen, focus_cost_reduction). v1 keeps Focus a fixed constant. Future spec 36 (expanded item pool) adds them.
- **Skill Codex screen** (the future rune-swap UI).
- **Proper skill icons.** v1 uses placeholder text; iconography is a polish followup (could be ink-style line drawings in the gj26 UI style).
- **Pet companion** (FATE-style scroll-holder). Class-paths spec (34) territory.
- **Class differentiation.** Single Ranger character; spec 34 adds paths.
- **Mana/energy renaming or per-class resource fragmentation.** One Focus pool for everyone.
- **AoE damage** beyond Snare. MultiShot's 3 arrows are 3 single-target hits, not an AoE. ExplosiveArrow + AoE damage shapes are spec 31.
- **Pack scaling.** Per-room enemy counts stay at current 2–5. Spec 32.

## Files

| Path | Action |
|---|---|
| `godot/scripts/player_controller.gd` | add `focus`/`focus_max`/`_combat_t`/`_skill_cooldowns`; new `_try_skill(slot)`; new `_fire_powershot()` / `_fire_multishot()` / `_cast_bramble_snare()`; remove `bolt_1..4` binds; rebind `1..4` to `skill_1..4`; extend `_derive_stats` to include `cooldown_reduction` and skill-specific cooldowns; extend `take_damage` to bump `_combat_t = 3.0` |
| `godot/scripts/arrow.gd` | add optional `skill_type: String = "basic"`; PowerShot uses `damage * 2.5` (already wired via `arrow.damage`); visual scale + trail tint per skill type |
| `godot/scripts/combatant.gd` | add `_root_t` var; new `apply_root(duration)`; `_tick_ai` short-circuits to zero velocity when `_root_t > 0`; `_physics_process` decrements; visual indicator (small vine SpriteBase3D at feet) |
| `godot/data/affixes.gd` | add suffix entry `of_swiftness` with stat `cooldown_reduction`, tier values `[0.05, 0.10, 0.15, 0.20]` |
| `godot/scripts/player_hud.gd` | add `set_focus(cur, max)`; updates Focus bar |
| `godot/scenes/PlayerHUD.tscn` | add Focus `ProgressBar` (or `ColorRect`) under the HP bar, same width, half height, golden fill |
| `godot/scenes/SkillBar.tscn` | **new** — CanvasLayer with 4 slot Control nodes |
| `godot/scripts/skill_bar.gd` | **new** — `bind_to_player(p)`; per-frame reads `p.focus`/`p._skill_cooldowns`/`p.derived_stats`; renders cooldown sweep + Focus-cost availability greyout |
| `godot/scripts/sfx.gd` | add `skill_power`, `skill_multi`, `skill_snare` paths (files deferred) |
| `godot/test_skills.gd` | **new** — 6 evals: each skill fires correctly, Focus drains + regens, Snare immobilizes, `cooldown_reduction` affix scales CDs |
| `docs/GODOT_PIPELINE.md` | brief "Skill system (spec 30)" section pointing to this spec |

## Acceptance criteria

1. Press **1** in-game — BasicShot fires (gold variant). F also fires BasicShot.
2. Press **2** — PowerShot fires (visibly bigger arrow), Focus drops by 20, slot 2 icon greys + shows cooldown sweep for 1.5s.
3. Press **3** — 3 arrows fan out in a ±20° cone, Focus drops by 25, slot 3 cools for 2s.
4. Press **4** — Bramble Snare AoE drops at aim point; any enemy in the 2.5m circle stops moving for 2s (visible: vines at their feet, fade out); Focus drops by 30, slot 4 cools for 4s.
5. Focus bar visible under HP bar. Drains on skill use, regens visibly faster when no enemies have hit recently.
6. Equip an item with `+15% cooldown_reduction` — PowerShot CD drops from 1.5s to ~1.30s; BasicShot CD unchanged.
7. Insufficient Focus → pressing the skill key does nothing (icon stays greyed; no error).
8. `test_skills.gd` 6/6 green.
9. Every existing harness still green (67/67 before this spec).
10. World boots, score ≥ 0.9.

## Open decisions

All resolved by the grill (see `30-skills-and-cooldowns-research.md` for the genre research that informed each). Mini-decisions resolved by lean:

- **Skill icon source** — placeholder text labels v1 (`Bow` / `Pow` / `Mlt` / `Snr`). Proper ink-line icons are a polish followup; out of scope here to keep v1 lean.
- **Cooldown reduction cap** — **0.80** (D3 model). CDs can't go below 20% of base; prevents degenerate stacking.
- **"In combat" definition** — **damaged in last 3.0 seconds**. Simpler than per-enemy aggro tracking; matches the visceral "the player just got hit" intuition.
- **Bramble Snare visual** — circle decal at impact point + small vine SpriteBase3D at each rooted enemy's feet. Fade modulate.a to 0 over the 2s root, then queue_free.
- **Snare aim point** — `player.global_position + facing_dir * 4.0`, clamped to the floor (set y = 0.05). Aims where the player is facing, not where the cursor is (gj26 has no cursor-aim system yet).
- **Pause behaviour** — Focus regen pauses when the tree is paused (modal up). Derives from `_physics_process` not running while paused. No code change needed.
- **Skill cost prevention** — if Focus < cost, the key press is a no-op (no input buffer, no consume-and-fail). Matches D3 and reads as "the skill isn't ready."
- **Combatant `_root_t` field** — float, default 0.0. Stored on Combatant base class so boss and enemies share it (boss may want immunity later — not in v1; root applies to everyone).
- **MultiShot cone angle** — ±20° (40° total spread). Each arrow gets independent crit roll. Tight enough to all hit a single tank at close range; wide enough to clip 3+ enemies in a pack.

## References

- `docs/specs/30-skills-and-cooldowns-research.md` — genre synthesis (FATE Reawakened, Diablo 3, Path of Exile 2)
- `docs/specs/29-typed-room-contracts.md` — interactable pattern (Area3D + scanner) reused for the SkillBar UI binding pattern
- Spec 27e (`docs/specs/27e-stats.md`) — `derived_stats` pipeline this spec extends
- Spec 26 — variant cycling on `bolt_1..4` (the thing being replaced)
- `godot/scripts/player_controller.gd` — `_fire_arrow`, `_derive_stats`, `_bind`, `take_damage`
- `godot/scripts/arrow.gd` — projectile spawn pattern; `damage` / `crit_chance` already per-shot
- `godot/scripts/combatant.gd` — `_tick_ai` state machine + `take_damage` knockback
- `godot/data/affixes.gd` — suffix pool to extend
- ARPG roadmap memory entry: [[project-arpg-roadmap]]

## Done check

- [ ] `focus` + `focus_max` + `_combat_t` + `_skill_cooldowns` on player
- [ ] `skill_1..4` actions bound to keys 1–4; `bolt_1..4` removed
- [ ] `_try_skill(slot)` dispatches and gates on cooldown + Focus
- [ ] PowerShot, MultiShot, Bramble Snare implemented + visually distinct
- [ ] `apply_root(duration)` on Combatant; AI short-circuits while rooted
- [ ] `cooldown_reduction` affix in `affixes.gd` + folded into `derived_stats`
- [ ] Focus bar in PlayerHUD; `set_focus(cur, max)`
- [ ] SkillBar.tscn + skill_bar.gd; bottom-center; cooldown sweep + greyout
- [ ] 3 new SFX paths in sfx.gd (files deferred until cost confirmed)
- [ ] `test_skills.gd` 6/6 green
- [ ] Existing harnesses still green (67/67)
- [ ] World boots, score ≥ 0.9
- [ ] `GODOT_PIPELINE.md` skill-system section added
- [ ] Playtest: 1/2/3/4 each fire something distinct, Focus drains, Snare visibly roots enemies
