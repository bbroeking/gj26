---
type: system
tags: [combat, skill, focus, status, hit-feedback, aoe, elite]
status: draft
updated: 2026-06-13
sources:
  - docs/specs/14-fluid-combat.md
  - docs/specs/15-enemy-ai-player-hp.md
  - docs/specs/26-combat-juice.md
  - docs/specs/30-skills-and-cooldowns.md
  - docs/specs/31-status-and-aoe.md
  - docs/specs/32-pack-scaling.md
  - docs/specs/32b-skill-module.md
  - docs/specs/32c-hit-feedback.md
  - docs/specs/33a-player-status.md
  - docs/wyrd-skills-combat-plan.md
  - wyrd/scripts/combatant.gd
  - wyrd/scripts/player_controller.gd
---

# Combat

Combat is the "one verb" of Wayfinder (ADR 0003 / ADR 0005): a 4-slot hotbar of ranged skills gated by a single regenerating Focus resource, expressed through the Ranger's bow.

## The north star

Per ADR 0003, cozy-skilling is the spine; combat is seasoning. Every combat piece must pass the **spine test**: would a player voluntarily do this verb with no quest pointing at it? Combat is not a separate progression track — it serves the [[Chart Loop]] and is driven by the [[Trades and Leveling]] system through [[Huntcraft]].

## Hotbar and Focus

The player has a **4-slot hotbar** bound to `1`–`4` (plus `F` fires slot 1, BasicShot, for muscle-memory continuity). Slots 2–4 cost **Focus**, a single regenerating resource (`FOCUS_MAX = 50`):

- **Out-of-combat regen**: 10 Focus/sec (no enemy has hit in the last 3 s)
- **In-combat regen**: 3 Focus/sec (within 3 s of taking damage or using a skill)

Slot 1 (BasicShot) is free and always available. If Focus is insufficient for a skill, the keypress is silently ignored and the icon greys out — no error, no penalty (D3 model). Cooldown reduction (`cooldown_reduction` affix, capped at 0.80) scales skills 2–4 only; BasicShot's cooldown is governed by the `fire_rate` affix.

See [[Skills]] for the full 9-skill pool and what each slot can carry.

## Hit feedback (6 channels)

Every hit fires all six channels through `HitFeedback.play_hit` (`wyrd/scripts/hit_feedback.gd`, spec 32c):

| Channel | Normal | Crit (×2, 20% chance) | Super-crit (×3, 4% chance) |
|---|---|---|---|
| Mesh flash | white 0.12 s | white 0.12 s | white 0.12 s |
| Knockback | 1.0× | 1.6× | 1.6× |
| Hitstop | 0.07 s | 0.13 s | 0.20 s |
| Hit spark | motes | gold motes | gold motes |
| Camera shake | 0.06 | 0.15 | 0.30 |
| SFX | "hit" | "crit" | "crit" |

Damage numbers pop with a scale-punch (0 → 1.3 → 1.0 over 0.12 s) and scatter upward — cream for normal, gold for crit, purple for super-crit (spec 26, MapleStory maximalism). Status DoT ticks fire a softer coloured pulse (`HitFeedback.tick_pulse`) that is suppressed when a hit-flash is already active.

## Status effects

The status framework (`wyrd/scripts/status_effect.gd`, spec 31) is a `_statuses: Dictionary` keyed by kind, shared by all `Combatant` instances and the player (`player_controller.gd`, spec 33a). Stacking model: **highest-wins + duration refresh** (D3 model). Fixed-interval ticks — never delta-scaled.

| Status | Applied by | Duration | Tick | Effect |
|---|---|---|---|---|
| **burn** | PowerShot on hit | 3 s | 0.5 s / 1 dmg | total ~6 dmg; orange particle rises |
| **bleed** | Any crit / super-crit on enemy | 4 s | 1 s / ~6.25% of crit dmg | red drops fall; "bleeding!" text |
| **snared** | MultiShot on hit | 1.5 s | none | 0.5× move speed; green vine ring at feet |
| **root** | Bramble Snare | 2 s | none | immobilises (AI skips chase/attack); emerald disc |
| **marked** | Hunter's Mark | 8 s | none | target takes ×1.3 from all hits |

Boss status immunity: the Hedgemother is **fully immune to root and snared** (blocks CC lock-at-range); burn and bleed land at 50% duration. Her boss bar appends " — Unyielding" to flag this to the player (spec 31).

The player can be burned, snared, and rooted via enemy abilities (e.g. Sunlit elite's `burn_pulse`). Active statuses appear as a text suffix in the HP bar: `"HP 25/30 — burning · snared"` (spec 33a).

## AoE helpers

`wyrd/scripts/aoe_query.gd` (spec 31) provides two shape queries:

- `AoeQuery.query_circle(tree, center, radius, group)` — used by Bramble Snare, Thornburst, and elite death / on-attack effects.
- `AoeQuery.query_cone(tree, origin, dir, range, half_angle_deg, group)` — shipped but unused in v1; reserved for future melee/cleave skills.

## Pack scaling

Combat rooms scale from 4 enemies at depth 0 to 10 at depth 6 (`n = 4 + clamp(depth/2, 0, 6)`). Each room has a probabilistic elite roll (`chance ≈ n/8`). See [[Enemies]] for the full elite modifier table.

## Player survival

Player starts with 30 HP (`PLAYER_HP = 30`). On hit: hitstop + screen-edge red flash + knockback + i-frames (0.6 s). Death triggers a brief pause then respawns at the room entry at full HP; enemies are not reset. The `roll` move (Space) grants 0.27 s of i-frames — about 60% of its 0.45 s duration, leaving a punishable recovery tail (spec 36 tuning).

## See also

- [[Skills]] — the 9-skill pool, Focus costs, and Huntcraft gates
- [[Enemies]] — enemy AI, per-kind stats, elite modifiers
- [[Bosses]] — phase machines, telegraphed attacks, trophy chain
- [[Chart Loop]] — how combat fits into a run
- [[Huntcraft]] — the fourth Trade that gates deeper skills
- [[Affixes]] — cooldown_reduction and other combat-relevant chart modifiers
- [[Design Decisions]] — ADR 0003 (cozy spine), ADR 0004 (control scheme), ADR 0005 (Huntcraft)

## Sources

- `docs/specs/14-fluid-combat.md` — hitbox/hurtbox, hitstop, input buffering
- `docs/specs/15-enemy-ai-player-hp.md` — player HP, i-frames, death/respawn
- `docs/specs/26-combat-juice.md` — crit system, damage numbers, SFX
- `docs/specs/30-skills-and-cooldowns.md` — Focus resource, hotbar design
- `docs/specs/31-status-and-aoe.md` — status framework, AoE helpers
- `docs/specs/32-pack-scaling.md` — pack density formula, elite rolls
- `docs/specs/32b-skill-module.md` — Skill class hierarchy
- `docs/specs/32c-hit-feedback.md` — HitFeedback static module
- `docs/specs/33a-player-status.md` — player-side status framework
- `wyrd/scripts/combatant.gd` — authoritative stat constants
- `wyrd/scripts/player_controller.gd` — Focus consts, loadout, bindings
