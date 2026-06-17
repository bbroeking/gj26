---
title: Hunter's Mark
domain: Combat Skills
type: skill
status: complete
effort: M
tags: [wayfinder, plan]
---

# Hunter's Mark

> A fully wired boss-setup skill — mark lands, +30% amplification applies, particle is the generic fallback; the expansion roadmap is a dedicated particle, a boss HUD tell, and perk-gated synergies.

## Current state

`wyrd/scripts/skills/hunters_mark.gd:9–19` defines the skill as a `ProjectileSkill` subclass: cost 15 Focus, 6 s cooldown, `damage_mult = 0.5` (the bolt itself is a light tap), `on_hit_effects = [SkillEffect.marked(8.0)]`, gold-tinted `recoil_amount` / `bow_pop_mult` for the distinctive fire feel. `SkillEffect.marked()` (`skill_effect.gd:49–53`) creates a status with `status_kind = "marked"` and no DoT/slow fields. On impact, `Combatant.apply_status` stores the entry in `_statuses`; `take_damage` (`combatant.gd:202–204`) checks `has_status("marked")` and multiplies damage by `MARKED_MULT = 1.3` before deducting HP. The amplification therefore stacks on top of every source — crits, bleeds (bleed ticks bypass the multiplier because they use `_apply_tick_damage`, not `take_damage`), and the `MercyShot` execute bonus.

The skill is gated at Wayfinding lv 4 (`game.gd:118`, `SKILL_REQS`). It is present in `skill_bar.gd:ABBREV/ICONS/TOOLTIPS` and `loadout_panel.gd` (icon, cost, description). The "marked!" apply-text and gold `STATUS_COLOR` exist in `combatant.gd:96–102`. The visual particle for `"marked"` is the generic fallback branch (`combatant.gd:699–710`): 12 upward-drifting gold quads — functional but undifferentiated from the root fallback.

`boss.gd`'s `apply_status` override (`boss.gd:69–74`) does **not** list `"marked"` in `IMMUNE_KINDS`, meaning Hunter's Mark **fully works on the boss** — the Hedgemother takes the +30% amplification for 8 s, making this the definitive boss-setup slot.

Status is **complete**: the skill fires, the mark sticks, damage amplification is read by `take_damage`, and the UI pipeline is wired end-to-end.

## Gaps — what needs fleshing out

1. **Dedicated "marked" visual particle** — the gold upward-drift cubes fall through to the generic `_:` branch in `_make_status_particle` (`combatant.gd:699`). Every other status has a bespoke motion language (burn rises, bleed falls, snared orbits feet). Mark should radiate — a slow pulsing outward ring or orbiting motes to signal "this thing takes more damage" at a glance during a fight.
2. **Boss HUD / mark tell** — the boss bar (driven by `boss_hp_changed`) currently shows HP and phase. There is no visible cue on the bar or the boss body that the Hedgemother is currently marked. A gold tint on the boss HP bar or a "◎ marked" label for the 8 s window would teach the player "fire now."
3. **`even_breath` synergy is implicit, not documented** — `even_breath` (`game.gd:456`, lv 17) returns 6 Focus per kill. Hunter's Mark costs 15 Focus. The chain "mark → amplified kill → even_breath refund" recovers 40% of the cost per kill, which is a strong rotational loop that no tooltip surfaces.
4. **Bleed-on-crit does NOT double-dip the mark** — bleed ticks go through `_apply_tick_damage` (`combatant.gd:581–596`), which skips the `has_status("marked")` check. This is correct design (DoTs shouldn't benefit twice) but undocumented; the distinction should live in a code comment and in the tooltip.
5. **`marked_quarry` chart affix is name-collision adjacent** — `layout_loader.gd:306–308` has a `marked_quarry` affix that doubles/halves trophy odds. The name overlaps thematically with the skill but does NOT interact with the status mechanically. This is fine as designed; a chart-affix description tweak ("Quarry is marked for glory…") would clarify the distinction.
6. **No headless timer test for the amplification path** — the five test suites (see `CLAUDE.md`) cover hotbar dispatch (`test_skills.gd`) but do not assert that a `take_damage` call on a marked combatant lands `≥ base * 1.3`. This is a gap in regression coverage.

## Plan

*Status is complete; these phases are an expansion/polish roadmap ordered by player-legibility payoff.*

### Phase 1 — Dedicated "marked" particle + boss tell

- In `combatant.gd:_make_status_particle`, add a `"marked":` branch in the `match kind:` block. Motion language: slow outward-orbiting motes at head height (≈1.8 m), wide horizontal spread (`spread = 360`, `flatness = 1.0`), very low velocity (0.1–0.3 u/s), 2.0 s lifetime, gold (`Status_COLOR["marked"]`), `amount = 16`. Reuse the `TEX_SOFT_CIRCLE` billboard quad and the `3x bumped` mesh-size convention already established at `combatant.gd:650`.
- In `boss.gd:take_damage` (or a `_tick_feedback` override), check `has_status("marked")` and drive a subtle gold tint pulse on the boss mesh (reuse `apply_flash` with a low-alpha gold color, fired once when the mark is first applied, NOT every frame). Duration should match `FLASH_SEC` so it reads as a quick acknowledgment, not a persistent override of the phase golden tint (which would collide with phase-transition visuals).
- Add a "◎ marked" label or gold dot to the boss HUD bar in `player_hud.gd` (or the dedicated boss bar scene) that is visible while `boss.has_status("marked")`. The label should auto-hide on expiry — a 1 s tween-fade is sufficient.
- **DoD:** (a) marking a regular enemy shows orbiting gold motes clearly distinct from the burn/bleed/snare/root visuals; (b) marking the Hedgemother shows a brief gold flash + boss HUD indicator; (c) the indicator disappears when the 8 s expires. Verify by `WYRD_NO_SAVE=1 godot --path wyrd` playtest screenshot, gate still green.
- **Effort: S–M**

### Phase 2 — Regression test for the amplification path

- Add a test case in `test_wyrd_loop.gd` (or a new `test_combat_mechanics.gd`): spawn a `Combatant` via `setup()`, call `apply_status("marked", 8.0, 0, 1.0, 0.0)`, fire `take_damage(100, Vector3.FORWARD)` with `crit_enabled = false`, assert `hp_max - hp >= 130`. A second test: call `_apply_tick_damage(10)` on a marked combatant and assert `hp_max - hp == 10` (bleed ticks do not double-dip).
- **DoD:** both assertions pass under `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_loop.gd`. All five suites stay green.
- **Effort: S**

### Phase 3 — Tooltip synergy call-outs + code comment

- `skill_bar.gd:TOOLTIPS["HuntersMark"]`: extend to "Name the quarry — it takes +30% from every hit while the mark holds. Crits, shots, and spells all count; bleed ticks do not." (One sentence, cozy voice per WORLD_BIBLE.)
- `loadout_panel.gd:DESCRIPTIONS["HuntersMark"]`: same addition.
- `combatant.gd:_apply_tick_damage`: add a comment "DoT ticks bypass `take_damage` deliberately — marked amplification does not apply to ticks." Cite this note and spec 31.
- **DoD:** the tooltip accurately describes the bleed non-interaction; no gameplay change. No test needed — content-only. Gate green.
- **Effort: S**

### Phase 4 — `even_breath` rotation surfacing (perk lv 17 — future)

- When `even_breath` is unlocked (Wayfinding lv 17, `game.gd:456`), consider surfacing the Focus refund in the skill tooltip once the perk is active: "Even Breath: a clean kill returns 6 Focus." This is a runtime-conditional tooltip addition — `skill_bar._build_tooltip()` could check `game.perk_active("wayfinding", "even_breath")`.
- **DoD:** at lv ≥ 17 the HuntersMark tooltip shows the even_breath clause; below lv 17 it is absent. Headless: a `test_skills.gd` case that toggles level and asserts tooltip content.
- **Effort: S** (depends on the perk-conditional tooltip pattern being worth generalizing)
- **Note:** this phase is a "nice-to-have" — hold until at least one other perk also uses the pattern, so the infrastructure earns its place.

## Dependencies & links

- [[skill-basic-shot]] — shares `ProjectileSkill` base; mark fires on-hit, same pipe as BasicShot's arrow.
- [[skill-power-shot]] — primary follow-up after marking; `PowerShot` benefit amplified 1.3× makes it the preferred "mark + delete" pairing.
- [[skill-mercy-shot]] — the other boss-finisher; MercyShot's `execute_mult` and HuntersMark's `MARKED_MULT` both multiply inside `take_damage`, making them additively composable (both read the damage value at the same point). Worth calling out in tooltips once both perks are unlocked.
- [[skill-bramble-snare]] — common combo: snare roots the target, player fires mark safely, then unleashes burst damage. Phase dependencies: snare must apply before mark for the full combo window.
- [[skill-rain-of-thorns]] and [[skill-multi-shot]] — AoE skills; mark benefits per-projectile, so a marked pack hits in every arrow of a Multi Shot fan.
- [[system-status-effects]] — the status framework that stores/ticks/clears `"marked"`; any changes to `apply_status` stacking rules affect mark duration.
- [[system-skills-hotbar]] — skill unlock gating lives in `game.gd:SKILL_REQS`; the mastery tree context for "lv 4 is the first thing kills teach you."
- [[system-combatant-ai]] — `take_damage` in `combatant.gd` is where the amplification is applied; the mark fallback particle is also built there.
- [[system-bosses]] — `boss.gd` inherits `apply_status`; mark is NOT in `IMMUNE_KINDS` (intentional), making this the primary boss-setup skill.
- [[system-trades-progression]] — Wayfinding lv 4 gate and `even_breath` lv 17 rotation synergy.
- [[system-combat-juice-vfx]] — Phase 1's dedicated particle and boss HUD tell overlap with the VFX system; reuse the `TEX_SOFT_CIRCLE` billboard and `spec-34` mesh-size convention.
- [[system-hud]] — Phase 1's boss HUD indicator lives in the HUD system.

Plan.md overlap: Part A combat-feel is SHIPPED (Phases 1–5 gate-green) — the `take_damage` path, `MARKED_MULT`, flash/particle systems, and `hit_feedback.gd` channels Hunter's Mark already relies on are all Part A deliverables. Part B loop-feel (B0–B7) does not overlap with this skill's expansion phases. No duplication.

## Verification

- **Phase 1 particle:** `WYRD_NO_SAVE=1 godot --path wyrd` playtest — mark a crypt enemy, confirm gold orbiting motes distinct from other status types. Screenshot-capture the marked Hedgemother during Phase 1 boss encounter. Check HUD indicator appears and fades at 8 s.
- **Phase 2 regression test:** `cd wyrd && WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` — both new assertions green; bleed non-interaction assertion green.
- **Phase 3 tooltip:** `WYRD_UI_SHOT=skill_bar godot --path wyrd` screenshot — verify bleed clause visible in the HuntersMark tooltip row.
- **Phase 4 perk tooltip:** set `WYRD_DEV_LEVEL=17`, open the hotbar, screenshot the tooltip — confirm `even_breath` clause appears; set `WYRD_DEV_LEVEL=3`, confirm it is absent.
- All five suites must remain green after each phase: `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_loop.gd` (and siblings for `test_wyrd_dungeon_scene`, `test_wyrd_transitions`, `test_skills`).

## Open questions

- Should mark have a **hard cap on boss duration** (e.g., bosses shrug off the mark after 4 s instead of 8 s), similar to how the boss reduces burn/bleed duration by `REDUCED_DURATION = 0.5`? Currently the full 8 s applies to the Hedgemother — intentional, but worth a playtest read once Phase 1's HUD tell makes it visible.
- Is the `damage_mult = 0.5` on the mark bolt itself correctly tuned? The design intent is "does little itself" (`hunters_mark.gd:4`), but at high Focus-efficiency (`even_breath` + lv 17 CDR via `quick_nock`) the mark can be fired very often. A follow-up playtest at lv 14+ should confirm the bolt doesn't over-reward mark-spamming.
