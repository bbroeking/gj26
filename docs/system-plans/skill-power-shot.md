---
title: Power Shot
domain: Combat Skills
type: skill
status: complete
effort: M
tags: [wayfinder, plan]
---

# Power Shot

> Core heavy-hitter is fully shipped — expansion roadmap: perk-gated upgrade tiers, Burn synergy combos with [[skill-hunters-mark]], and a loadout-screen balance pass to sharpen the skill's identity against [[skill-piercing-bolt]].

## Current state

`power_shot.gd:8-18` implements the full spec-32b contract in eight lines of `_init()`: `cost=20`, `base_cd=1.5`, `damage_mult=2.5`, `skill_type="power"`, `on_hit_effects=[SkillEffect.burn(3.0, 1, 0.5)]`, `recoil_amount=-0.6`, `bow_pop_mult=1.35`, `sfx_key="skill_power"`. All firing logic lives in `ProjectileSkill.fire()` (`projectile_skill.gd:28-60`).

The Burn DoT is data-driven via `skill_effect.gd:24-30`: 3 s duration, 1 dpt, 0.5 s tick interval = 6 total damage ≈ 40% of one hit at base level. `combatant.gd:487-528` handles highest-wins refresh stacking (D3 model) and `_tick_statuses` drives the per-frame tick loop with coloured ember particles (`combatant.gd:549-572`). No direct slot-gate exists for PowerShot — it ships in the default loadout (`game.gd:122`) and is available at Wayfinding lv 1.

The `arrow.gd` layer adds three spec-34 polish layers (lines 36-49, 89-96, 116-123, 282-349): a `POWER_AOE_RADIUS=1.8` splash that applies Burn to nearby enemies, a Zoe-Q bolt growth tween (0.6× → 1.4× over 0.5 s), a dedicated deep-ember `POWERSHOT_VARIANT` color, a `hs.freeze(0.10)` / `cr.shake(0.22)` impact weight floor, and a `_spawn_power_aoe_burst` ember-ring ground decal. The `Heavy Draw` perk (`game.gd:449`, `player_controller.gd:1108-1109`) adds `+crit_mult 0.25` at Wayfinding lv 14 — the only live perk that materially buffs PowerShot today.

No upgrade tiers exist for the skill itself. `SKILL_REQS` (`game.gd:118`) does not gate PowerShot; it is always selectable.

## Gaps — what needs fleshing out

- **No upgrade tiers.** `_init()` is fixed data; there is no mechanism for a tier-1 / tier-2 / tier-3 variant with improved stats or new behavior. The perk ladder (`game.gd:414-458`) has `heavy_draw` (lv 14) and `even_breath` (lv 17) as the closest adjacent buffs, but neither is PowerShot-specific.
- **Burn synergy is undeclared.** The Burn tag on the arrow and the `marked` tag from [[skill-hunters-mark]] both exist, but there is no "burning target takes extra hit damage" amplifier. The combination is currently additive by coincidence, not intentional design.
- **Balance anchor is unverified at depth.** At lv 17 with `heavy_draw` (+0.25 crit mult), `LEVEL_POWER` scaling, and Heavy gear, PowerShot's effective damage has never been charted against the den-scaling curve in `ADR-0013`. The Burn DoT is spec'd at 1 dpt regardless of level — flat DoT stops scaling when base damage does not.
- **Loadout tooltip is a one-liner.** `loadout_panel.gd` shows `"A heavy arrow, 2.5× damage, burns on hit. 20 focus."` — no mention of the AoE splash radius or the bolt growth tell. Players may not discover the AoE behavior.
- **Burn VFX cap contention.** `STATUS_PARTICLE_CAP = 2` (`combatant.gd:108`). If an enemy already has bleed + snared, a Burn applied by PowerShot lands silently (no particle) — the player gets no feedback that burn landed. The status still ticks; only the visual is suppressed.
- **No Burn-synergy skill in the pool.** The roster has nine skills (`game.gd:113-115`) but none explicitly keys off the `burn` status. Future expansion slots here are empty.
- **SFX key `skill_power` unverified.** `sfx_key = "skill_power"` is set in `_init()` (`power_shot.gd:17`); the SFX bank existence is not tested in `test_skills.gd`.

## Plan

### Phase 1 — Balance audit & DoT scaling

- Instrument a playtest run at lv 5 / 10 / 17 with `WYRD_DEV_LEVEL` and log PowerShot hit + Burn DoT contribution vs enemy HP at each tier.
- Add a `burn_dpt_scale` float to `power_shot.gd::_init()` that scales Burn dpt with `player.derived_stats.damage` at fire time rather than baking 1 flat into the `SkillEffect` constructor. Prototype in `projectile_skill.gd::fire()` or override `fire()` in `power_shot.gd`.
- Define a simple target ratio: Burn total damage ≤ 40% of one PowerShot hit at every Wayfinding level (the spec-32b intent).
- **DoD:** a printed table (debug log or test assertion) shows Burn/hit ratio stays in 30–50% across lv 1, 5, 10, 17 with `WYRD_NO_SAVE=1 WYRD_DEV_LEVEL=<n>` runs.
- **Effort:** S

### Phase 2 — Upgrade tiers via perk hooks

- Add a `tier: int = 1` field to `PowerShot` (and as a virtual on `Skill`). Wire `player_controller` to pass tier context when `Game.perk_active` conditions are met, or let `PowerShot.fire()` call `player.get("derived_stats")` and gate on Wayfinding level directly — consistent with how `Heavy Draw` and `Even Breath` already read `perk_active` in `player_controller.gd:1108`.
- Tier 2 (Wayfinding lv 8, no perk cost): Burn duration 3 s → 4 s. One-line change to the `SkillEffect.burn(...)` call.
- Tier 3 (Wayfinding lv 14, requires `heavy_draw` active): AoE splash radius `POWER_AOE_RADIUS` 1.8 → 2.4. Patch the constant in `arrow.gd:40` or expose it as an `Arrow` property the skill sets before `add_child`.
- No new perk slots needed — tiers ride lv-gating already in `skill_unlocked()` (`game.gd:120-121`).
- Update `loadout_panel.gd` tooltip to mention tier behavior.
- **DoD:** in a headless `test_skills.gd` run, a `PowerShot.new()` mock with lv 8 + lv 14 mock `derived_stats` reflects the tier 2 / tier 3 data fields; tooltip string in `loadout_panel.gd` includes AoE radius.
- **Effort:** S

### Phase 3 — Burn synergy: intentional combo with Hunter's Mark

This is the "flavor identity" phase. It introduces a deliberate Burn-amplification hook so the `PowerShot → Hunter's Mark` sequence (or vice versa) has a payoff distinct from stacking them independently.

- Add a `BURN_MARK_MULT: float = 1.15` constant to `combatant.gd` (alongside `MARKED_MULT`). In `take_damage()` after the `marked` check (`combatant.gd:203-204`), add: if the incoming arrow's `skill_type == "power"` AND `has_status("burn")`, multiply `dmg` by `BURN_MARK_MULT`.
- This requires the arrow to carry its `skill_type` to the combatant's damage resolution — it already does (`arrow.gd:57`, passed via `take_damage` call at `arrow.gd:204`). The `take_damage` signature already accepts per-call crit params; pass `skill_type` as an optional String arg (default `""` = no bonus) to avoid breaking existing callers.
- Alternatively (simpler, no signature change): read `skill_type` from a meta on the damaging arrow set before `take_damage`. The arrow sets `meta("skill_type", skill_type)` before impact; `take_damage` reads it if available.
- **DoD:** `test_statuses.gd` (the existing status headless suite) gains a case: a mock combatant with both `burn` and `marked` statuses hit by a `skill_type="power"` source takes ≥ `BURN_MARK_MULT * MARKED_MULT` of base damage.
- **Effort:** M (requires a careful `take_damage` signature or meta approach; touches `combatant.gd` and `arrow.gd`)

### Phase 4 — Polish: particle cap, tooltip, SFX

- Address the Burn-particle-cap silent-landing problem: when `STATUS_PARTICLE_CAP` is hit, show a brief header text `"singed!"` regardless (the `_spawn_apply_text` path at `combatant.gd:737-749` already fires independently of the particle). Confirm this is already true by grepping — if `_spawn_apply_text` is called before the particle-cap check in `apply_status`, no fix needed; document either way.
- Update `loadout_panel.gd` tooltip to: `"Heavy arrow — 2.5× damage, burns on hit (AoE splash), 20 Focus."` (one line, no numbers that might go stale).
- Add a `test_skills.gd` assertion that `sfx_key = "skill_power"` exists in the SFX bank dictionary, so a missing audio key fails the gate suite rather than a silent no-op in production.
- **DoD:** Burn particle-cap behavior documented in a code comment; tooltip updated; SFX key checked in `test_skills.gd`; all four headless suites still green.
- **Effort:** S

## Dependencies & links

- [[system-skills-hotbar]] — Hotbar dispatch (`_try_skill`), loadout persistence, and CDR scaling apply to PowerShot the same as all slots 2-4; tier gating must stay consistent with `skill_unlocked()` logic there.
- [[system-status-effects]] — Burn is owned entirely by `combatant.gd` / `status_effect.gd`; any dpt-scaling or particle-cap changes to Burn are shared with [[skill-bramble-snare]] (root) and [[skill-multi-shot]] (snare), so changes here need to be audited for status-framework impact.
- [[skill-hunters-mark]] — Phase 3 Burn synergy creates an intentional combo sequence; Hunter's Mark `marked` status is the other half of the synergy.
- [[skill-basic-shot]] — PowerShot's `POWER_AOE_RADIUS` splash and impact weight (`hs.freeze`, `cr.shake`) deliberately exceed BasicShot's; any camera-rig or hitstop budget changes need to preserve this loudness gap.
- [[skill-piercing-bolt]] — Both are single-target heavy projectiles with 1.5 s CD (PiercingBolt has `base_cd=1.5` too); the design distinction is "burst + DoT + splash" (PowerShot) vs. "pierce line" (PiercingBolt). The balance audit in Phase 1 should compare them.
- [[system-combatant-ai]] — Phase 3 passes `skill_type` into `take_damage`; this touches the combatant's core damage resolution path.
- [[system-trades-progression]] — `Heavy Draw` (lv 14) and `Even Breath` (lv 17) are the two Wayfinding perks most relevant to PowerShot. Tier gating in Phase 2 rides this ladder.
- [[system-combat-juice-vfx]] — The Zoe-Q bolt growth tween, `_spawn_power_aoe_burst`, and `hs.freeze`/`cr.shake` are all spec-34 juice; any VFX budget pass should check PowerShot's particle count per frame (`arrow.gd` trail + burn ember + ground ring).

Roadmap note: Part A combat-feel / animation P1–P5 is **SHIPPED** (bow-pop, recoil, hitstop, spark, shake all live). Part B loop-feel phases B0–B7 are all **SHIPPED** as of 2026-06-12 (see `docs/wyrd-roadmap.md`). This expansion roadmap is post-B7 polish — it does not re-plan anything the roadmap already owns.

## Verification

- **Phase 1:** `WYRD_NO_SAVE=1 WYRD_DEV_LEVEL=1 godot --headless --path wyrd --script res://test_wyrd_loop.gd` — confirm PowerShot fires and Burn ticks print at expected dpt; repeat at lv 10, lv 17.
- **Phase 2:** `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_skills.gd` — the tier-level assertions pass; loadout tooltip string updated.
- **Phase 3:** `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_statuses.gd` — new synergy case green.
- **Phase 4:** All four suites (`test_wyrd_loop.gd`, `test_wyrd_dungeon_scene.gd`, `test_wyrd_transitions.gd`, `test_skills.gd`) green; SFX key assertion in `test_skills.gd` passes.
- All runs require `cd wyrd` or `--path wyrd`; always prefix `WYRD_NO_SAVE=1`.

## Open questions

- Should Burn dpt scale with the *arrow's actual damage* (post-crit, post-mark) or with `derived_stats.damage` at the moment of firing? Scaling with pre-crit base damage keeps DoT predictable; scaling post-crit makes PowerShot crits dramatically more rewarding but may be swingy.
- Should the Phase 2 AoE-radius tier unlock be a loadout-panel tooltip hint, or should the ground ring visually grow to telegraph the new radius so players feel the tier-up viscerally?
- If Phase 3's Burn+Mark synergy lands, should it also apply to Burn ticks (so a marked burning enemy ticks harder) or only to direct hits? The tick path (`_apply_tick_damage`) bypasses `take_damage` crits deliberately — changing this would couple the two systems more tightly.
