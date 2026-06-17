---
title: Piercing Bolt
domain: Combat Skills
type: skill
status: partial
effort: M
tags: [wayfinder, plan]
---

# Piercing Bolt

> The corridor skill — a 1.6× line shot that punches through up to 3 enemies; the highest-priority gap is a distinct visual identity (it currently fires the same ember-red bolt as PowerShot) and no upgrade path exists for the pierce count.

## Current state

`piercing_bolt.gd:7–17` defines the full data contract: `cost = 22.0`, `base_cd = 2.4`, `damage_mult = 1.6`, `pierce = 3`, `skill_type = "power"`, `recoil_amount = -0.7`, `bow_pop_mult = 1.3`. The class extends `ProjectileSkill`, which bakes `pierce` into `arrow.pierce_left` at spawn time (`projectile_skill.gd:74`). `arrow.gd:185–211` implements the pierce mechanic: each hit decrements `pierce_left`; `_pierced: Array` prevents multi-hitting the same target; the arrow only becomes `_spent` (and is freed) when `pierce_left == 0` at the moment of impact.

The mechanic is **fully functional** — pierce fires, decrement works, multi-hit guard is correct. However, `skill_type = "power"` causes `arrow.gd:108–123` to assign the POWERSHOT_VARIANT (ember-red visual + Zoe-Q scale growth + AoE burst on impact). Piercing Bolt therefore looks and sounds identical to PowerShot: same deep-red bolt, same growing scale effect, same AoE ember ring on impact. The "punches through" fantasy is invisible; there is no corridor-lightning or elongated trail that would read as a penetrating shot. Additionally, `arrow.gd:218–239` triggers a `_spawn_power_aoe_burst` for any `skill_type == "power"` arrow — an ember AoE that contradicts Piercing Bolt's single-line corridor identity.

No pierce-count upgrade path exists anywhere in the codebase: `_derive_stats` (`player_controller.gd:1082–1134`) does not sum a `bonus_pierce` stat, `data/affixes.gd` has no `pierce` affix, and the mastery perk table in `game.gd:1099–1111` has no pierce entry. The loadout panel tooltip (`ui/loadout_panel.gd:15`) correctly describes the skill but shares the same `skill_power.png` icon as PowerShot (`loadout_panel.gd:35`), reducing legibility.

## Gaps — what needs fleshing out

1. **[BLOCKER] Visual identity mismatch** — `skill_type = "power"` gives Piercing Bolt the PowerShot ember visual. It needs its own `skill_type` value (e.g. `"pierce"`) so `arrow.gd` renders a distinct elongated silver/frost bolt without the AoE burst. This is confusing to players and visually noisy (a corridor skill shouldn't spray an AoE ember ring).
2. **No pierce-count upgrade path** — `pierce = 3` is a hard constant baked in `_init()`. There is no gear affix, perk, or shrine that can raise it. The design note says "plan pierce-count upgrades" but the stat pipeline ignores pierce entirely.
3. **No per-pierce hit VFX** — when the bolt passes through an enemy, there is no distinct "thread-through" spark or trail scar to telegraph to the player that a pierce occurred. The `_explode` burst fires only on the final `_spent` arrow; intermediate hits are visually silent.
4. **Icon shared with PowerShot** — `loadout_panel.gd:35` and `skill_bar.gd:45` both use `skill_power.png` / `➸`. A corridor skill reads better with a different icon (a bolt with a trail, distinct from the heavy-hit icon).
5. **Balance vs Rain of Thorns is untuned** — Rain (`rain_of_thorns.gd:14–18`) deals 1.8× damage over a 2.6m AoE at 32 Focus / 5.0 s CD. Piercing Bolt at 1.6× / 22 Focus / 2.4 s CD is significantly cheaper and more frequent; the corridor constraint is the intended cost, but no playtest data validates whether corridor + 1.6× + 22 Focus is overcrowding PowerShot (1.6× / 20 Focus / 2.0 s CD in `power_shot.gd`). The two are nearly identical in stats.

## Plan

### Phase 1 — Own visual identity (unblock the skill's legibility)

- Add `"pierce"` to the `skill_type` vocabulary in `arrow.gd`'s comment header (line 56) and to the per-type branch logic.
- In `arrow.gd:_ready`, add a `elif skill_type == "pierce":` branch that assigns a new PIERCINGBOLT_VARIANT constant: long narrow frost-white capsule (e.g. `"color": Color(0.85, 0.95, 1.0)`, `"len": 1.1`, `"rad": 0.09`) — reads as a needle, not a fireball.
- In `piercing_bolt.gd:_init`, change `skill_type = "power"` to `skill_type = "pierce"`.
- Guard the `_spawn_power_aoe_burst` call at `arrow.gd:232` behind `skill_type == "power"` (it already is; confirm the new type doesn't accidentally trigger it).
- Add a per-pierce intermediate spark: inside `arrow.gd:_on_area_entered`, when `pierce_left > 0` before decrement, call a new `_pierce_thread(global_position)` helper that spawns a tiny directional 8-particle burst in the bolt color (short lifetime, forward-biased spread) — communicates "passed through."
- Update `skill_bar.gd` and `loadout_panel.gd` to point PiercingBolt at a new icon (or a distinct emoji `↣`/`⇒` as a placeholder until art is cut).
- **DoD:** PiercingBolt fires a visually distinct frost-white needle bolt; no ember-ring AoE fires on impact; a small spark burst plays each time the bolt pierces a target (visible with 2+ enemies in a line); PowerShot retains ember-red with AoE ring unchanged. Verified by running the game with `WYRD_NO_SAVE=1` + positioning two training dummies in a line and firing; screenshot the thread-through spark.
- **Effort: S**

### Phase 2 — Pierce-count upgrade path

- Extend the `_derive_stats` sums dictionary in `player_controller.gd:1083` to include `"bonus_pierce": 0`.
- Add `_add_stat` handling for `"bonus_pierce"` (integer sum) and write it into `derived_stats` as `"bonus_pierce": int(sums.bonus_pierce)`.
- In `projectile_skill.gd:fire()`, change the arrow spawn line to: `arrow.pierce_left = pierce + int(player.derived_stats.get("bonus_pierce", 0))`. This means base pierce (3) is augmented by gear/perks.
- Add one gear affix entry to `data/affixes.gd`: `{"id": "bolt_penetration", "label": "Bolt Penetration", "stat": "bonus_pierce", "tier_values": [1, 2], "slot": "quiver"}` — allows quiver-slot gear to grant +1 or +2 extra pierce.
- Add one mastery perk to the `perk_active` block in `player_controller.gd:1099` under an appropriate Wayfinding level: `"iron_tip"` → `_add_stat(sums, "bonus_pierce", 1)`. Gate at level ~6 (between `quick_nock` at implicit level and `heavy_draw` heavy-draw tier).
- Update the `loadout_panel.gd` description dynamically to show the effective pierce count if `derived_stats.bonus_pierce > 0`.
- **DoD:** equipping a `bolt_penetration` quiver affix raises PiercingBolt's effective pierce from 3 to 4 or 5; the perk grants a flat +1; the tooltip reflects the live count. Timer/logic test: spawn a PiercingBolt arrow with `bonus_pierce = 2`, assert it hits 5 targets before expiring. Gate green (`test_skills.gd`).
- **Effort: M**

### Phase 3 — Balance pass against PowerShot and Rain of Thorns (expansion/polish)

This phase is an EXPANSION/POLISH roadmap since the skill ships and works; the numbers just haven't been playtested against the full skill roster.

- Audit the three-way comparison: PiercingBolt (1.6× / 22F / 2.4 s) vs PowerShot (1.6× / 20F / 2.0 s) vs RainOfThorns (1.8× / 32F / 5.0 s). PiercingBolt and PowerShot currently differ only in focus cost (+2) and cooldown (+0.4 s), with pierce as the sole differentiator. Once Phase 1 gives PiercingBolt a visual identity, consider: raise `damage_mult` to 1.75 (corridor risk = fair reward) OR raise `cost` to 26 and `base_cd` to 3.0 to create clearer budget separation from PowerShot. Decide after a playtest session with multiple enemies in corridor formation.
- Document chosen values as constants with a comment explaining the three-way tradeoff (PowerShot = single-target burst, PiercingBolt = corridor, RainOfThorns = zone denial).
- Consider a `max_pierce_cap` constant (e.g. 5) to prevent degenerate gear builds from making the bolt effectively infinite.
- **DoD:** a playtest with 3-5 enemies in a corridor shows PiercingBolt as the clear skill choice over PowerShot; Rain of Thorns remains differentiated as zone-control; the skill picker in a fresh run has three meaningfully different archetypes available. No timer test — validated by playtest sign-off.
- **Effort: S** (numbers-only, no new systems)

## Dependencies & links

- [[skill-power-shot]] — shares `skill_type = "power"` and nearly identical base stats; Phase 1 disentangles the visual; Phase 3 rebalances the stat gap. Ensure PowerShot's ember visual is explicitly guarded to `skill_type == "power"` only.
- [[skill-rain-of-thorns]] — the balance counterpart for corridor vs zone-control; Phase 3 validates the trio of single-target / corridor / AoE reads as distinct archetypes.
- [[skill-multi-shot]] — uses `focal` hierarchy for fan visual; the `_pierce_thread` burst in Phase 1 should follow the same cookbook (dim/bright focal logic already at `arrow.gd:131–136`).
- [[system-skills-hotbar]] — the mastery perk added in Phase 2 (`iron_tip`) lives on the Wayfinding ladder; confirm perk level placement doesn't collide with existing perk slots.
- [[system-items-affixes]] — Phase 2 adds the `bolt_penetration` affix to `data/affixes.gd`; must follow the existing affix shape (id, label, stat, tier_values, slot).
- [[system-combat-juice-vfx]] — the per-pierce thread-through spark (Phase 1) is a small VFX beat; it should follow the Part A visual loudness rules (smaller and quieter than the final impact burst).
- **Plan.md Part A (SHIPPED)** — the ember-bolt VFX, `_spawn_power_aoe_burst`, hitstop, and camera shake that PiercingBolt currently inherits were all landed in Part A. Phase 1 here does NOT rebuild them; it forks PiercingBolt off onto its own visual branch while leaving PowerShot's Part A beats untouched.
- **Plan.md Part B (PLANNED)** — no direct overlap; PiercingBolt is combat-only. The Part B loop-feel work (gather/craft/level-up) is independent.

## Verification

- **Phase 1** — run `WYRD_NO_SAVE=1 godot --path wyrd` (headed), place two enemies in a line, fire PiercingBolt: assert frost-white needle flies (not ember-red), per-pierce spark visible on first hit, no AoE ember ring on impact. PowerShot still shows ember-red + ring. Screenshot both. Then run the four headless suites from `wyrd/`: `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd` must stay green (skill dispatch path; verifies PiercingBolt still fires and no push_error from missing skill_type branch).
- **Phase 2** — add a timer/logic test to `test_skills.gd`: construct a `PiercingBolt` instance, manually set `derived_stats.bonus_pierce = 2`, call `fire()` on a mock player, assert the spawned arrow's `pierce_left == 5`. Also assert that `bonus_pierce = 0` gives `pierce_left == 3`. All four headless suites green.
- **Phase 3** — playtest sign-off with the user: 3–5 enemies in a crypt corridor, hotbar has PiercingBolt + PowerShot + RainOfThorns; confirm each skill reads as the correct archetype and PiercingBolt is the clear corridor pick.

## Open questions

1. Should `"pierce"` be a first-class `skill_type` in `arrow.gd` (triggering its own branch), or is it cleaner to keep `skill_type = "power"` and add a boolean `is_piercing` flag to gate the AoE burst guard? The branch approach is more explicit; the flag avoids multiplying skill_type strings.
2. What is the max pierce-cap? Unlimited pierce (bolt never expires until wall-hit) would be a fun gear fantasy but could feel overpowered in small rooms. Propose `max_pierce_cap = 5` as a soft ceiling, but playtest first.
3. Icon: should PiercingBolt get a dedicated painted icon sprite now (asset pipeline) or keep the shared `skill_power.png` until the icon batch is done? No blocker — Phase 1 can ship with an emoji placeholder in `skill_bar.gd`.
