---
type: entity
tags: [combat, skill, huntcraft, hotbar, focus]
status: draft
updated: 2026-06-13
sources:
  - docs/specs/30-skills-and-cooldowns.md
  - docs/specs/31-status-and-aoe.md
  - docs/specs/32b-skill-module.md
  - wyrd/scripts/skills/basic_shot.gd
  - wyrd/scripts/skills/power_shot.gd
  - wyrd/scripts/skills/multi_shot.gd
  - wyrd/scripts/skills/bramble_snare.gd
  - wyrd/scripts/skills/piercing_bolt.gd
  - wyrd/scripts/skills/rain_of_thorns.gd
  - wyrd/scripts/skills/thornburst.gd
  - wyrd/scripts/skills/hunters_mark.gd
  - wyrd/scripts/skills/heartwood_ward.gd
  - wyrd/scripts/skills/mercy_shot.gd
  - wyrd/scripts/game.gd
  - wyrd/scripts/player_controller.gd
---

# Skills

Skills are the 9 player-usable abilities that fill Wayfinder's 4-slot hotbar — concrete hunting verbs that answer the four ARPG questions: kill a tank, clear a pack, create space, and survive.

## The loadout system

Slot 1 is always **BasicShot** (the Bow), hardwired and free. Slots 2–4 are chosen at the Hearth from the 9-skill pool. The current loadout is persisted in the save and starts as `["PowerShot", "MultiShot", "BrambleSnare"]`. Changing loadouts requires meeting each skill's [[Huntcraft]] gate (see below).

Skill architecture: each skill is a `Skill` subclass in `wyrd/scripts/skills/` (spec 32b). Projectile skills extend `ProjectileSkill` and carry `on_hit_effects: Array[SkillEffect]`; non-projectile skills override `fire(player)` directly. The player instantiates the loadout in `_ready()` and dispatches via `_try_skill(slot)`.

The 4th slot binds to key `4`, slots 2–4 to `2` and `3`; `F` always fires slot 1. The `cooldown_reduction` affix (via [[Affixes]]) scales slots 2–4 only, capped at 0.80.

## The 9-skill pool

### Open from the start (no Huntcraft gate)

| Skill | Class | Cost | CD | Description |
|---|---|---|---|---|
| **BasicShot** | `ProjectileSkill` | 0 | 0.28 s | Single arrow, 1.0× damage, gold variant. Free; F also fires it. |
| **PowerShot** | `ProjectileSkill` | 20 | 1.5 s | Single arrow, 2.5× damage. Applies **burn** on hit (3 s / 0.5 s ticks / 1 dmg). Visually larger arrow with bright trail. |
| **MultiShot** | `ProjectileSkill` | 25 | 2.0 s | 3 arrows in a ±20° cone, each 0.5× damage. Each applies **snared** on hit (1.5 s, 0.5× move speed). All three roll crit independently. |
| **BrambleSnare** | `Skill` | 30 | 4.0 s | AoE root at aim point (2.5 m radius, 4 m reach). Every enemy in range is **rooted** for 2 s; emerald disc visual. No projectile. |
| **PiercingBolt** | `ProjectileSkill` | 22 | 2.4 s | Heavy shot that pierces up to 3 enemies in a line. 1.6× damage. Corridor skill — rewards lining packs up. |
| **RainOfThorns** | `Skill` | 32 | 5.0 s | Delayed (0.6 s) thorn volley at aim point (2.6 m radius, up to 9 m away). 1.8× damage + **bleed** (2 s / 0.5 s ticks). Telegraph disc warns the player. Zone-control nuke. |
| **Thornburst** | `Skill` | 30 | 8.0 s | Panic button: emerald ring erupts from the player's boots, hitting everything within 3.2 m for 1.4× damage and snaring them 2 s. No aim required. |

### Gated by Huntcraft level

| Skill | Gate | Cost | CD | Description |
|---|---|---|---|---|
| **Hunter's Mark** | Huntcraft 4 | 15 | 6.0 s | Quick gold bolt (0.5× damage) that applies **marked** for 8 s — the target takes ×1.3 from all subsequent hits. The primer for big pulls. |
| **Heartwood Ward** | Huntcraft 7 | 25 | 14.0 s | No projectile. Applies a bark-shield absorbing the next 30 damage for 8 s (`player.apply_ward`). Defensive verb. |
| **Mercy Shot** | Huntcraft 9 | 28 | 5.0 s | Deliberate arrow (1.2× base) that deals 3× that damage when the target is below 35% HP — the clean kill. |

> ⚠️ Spec 30 described a 4-skill pool (BasicShot/PowerShot/MultiShot/BrambleSnare). Code (`wyrd/scripts/game.gd::SKILL_POOL`) confirms 9 skills shipped across specs 30 and B5. The 4-skill table in spec 30 docs is the v1 baseline; the full pool is in the code.

## Status applied per skill (see [[Combat]])

- PowerShot → **burn** (orange particle, rises)
- MultiShot → **snared** (green vine ring at feet)
- Bramble Snare → **root** (emerald disc)
- Rain of Thorns → **bleed** (red drops fall)
- Hunter's Mark → **marked** (gold; all hits amplified ×1.3)
- Crits and super-crits on enemies → **bleed** (automatic, via `combatant.take_damage`)

Bosses are immune to root and snared; burn and bleed land at 50% duration (spec 31, "Unyielding").

## See also

- [[Combat]] — Focus resource, hotbar mechanics, hit feedback
- [[Huntcraft]] — the Trade that gates Hunter's Mark, Heartwood Ward, Mercy Shot
- [[Enemies]] — how statuses interact with enemy AI and elite modifiers
- [[Bosses]] — boss status immunity table
- [[Affixes]] — cooldown_reduction affix that scales skills 2–4
- [[Items and Gear]] — fire_rate affix scales BasicShot only

## Sources

- `docs/specs/30-skills-and-cooldowns.md` — original 4-skill design
- `docs/specs/31-status-and-aoe.md` — status applied per skill
- `docs/specs/32b-skill-module.md` — Skill/ProjectileSkill/SkillEffect architecture
- `wyrd/scripts/skills/*.gd` — authoritative stats for all 9 skills
- `wyrd/scripts/game.gd` — `SKILL_POOL`, `SKILL_REQS`, default loadout
