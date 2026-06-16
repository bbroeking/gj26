# ADR 0014 — Player systems: the formal model (abilities, Focus, gear, satchel)

**Status:** Accepted (2026-06-16)
**Ties together [ADR 0006](0006-demo-level-cap-17.md) (cap 17),
[ADR 0012](0012-one-skill-wayfinding.md) (one trade),
[ADR 0013](0013-vertical-progression.md) (vertical power). This ADR is the
single canonical description of how a Wayfinder character *works* — what the
numbers are, where they live, and how they connect.**

## Context

The character systems (abilities, the Focus resource, gear/affixes, the satchel)
were each built spec-by-spec and are fully implemented and tested, but the model
was never written down in one place. This ADR formalizes it so the parts are
named once and future work has a reference. It is descriptive of the shipped
build (code is the tiebreaker) plus the few load-bearing decisions it locks.

## Decision — the model

### 1. Two live resources: Health and Focus

- **Health** — `hp` / `hp_max`. Base `PLAYER_HP = 30`
  (`player_controller.gd:72`), scaled by level (below) and raised by armor/HP
  affixes. Death = warm reset (wake at home, keep mats + trophies — see the
  cozy-danger design).
- **Focus is the one and only spend resource (the "mana").** `FOCUS_MAX = 50`;
  regen **10/s out of combat, 3/s in combat** (a 3s window after a hit or cast),
  modulated by chart affixes and tonics (`player_controller.gd:147-154,398-401`).
  Skills cost Focus; the basic Bow shot is free. The only refund is the
  **Even Breath** mastery (+6 Focus per clean kill).
- There is no stamina, rage, or second bar. One resource keeps the read simple.

### 2. The hotbar: one verb + three chosen skills

- **Slot 1 is always the Bow** (`BasicShot`): free, ~0.28s cadence scaled by
  `fire_rate`, 1× damage. The one-verb core (ADR 0003 spirit).
- **Slots 2–4 are a loadout** the player picks from a pool of **9 skills**
  (`game.gd:113` `SKILL_POOL`), each a data object (`scripts/skills/*.gd`
  extending `Skill`) with `cost` (Focus), `base_cd`, and a `fire(player)` effect.
  Effective cooldown = `base_cd / (1 + cooldown_reduction)`, CDR capped at
  `CDR_CAP = 0.80` (`scripts/skills/skill.gd`).
- Three skills gate on Wayfinding level (`game.gd:118` `SKILL_REQS`):
  HuntersMark @ 4, HeartwoodWard @ 7, MercyShot @ 9. The rest are open from lv 1.
- The pool (cost / base_cd / effect): PowerShot 20/1.5 burn · MultiShot 25/2.0
  3-arrow cone + snare · BrambleSnare 30/4.0 AoE root · PiercingBolt 22/2.4
  pierce-3 · RainOfThorns 32/5.0 delayed AoE + bleed · Thornburst 30/8.0 panic
  ring + snare · HuntersMark 15/6.0 +30% taken · HeartwoodWard 25/14.0 30-HP ward
  · MercyShot 28/5.0 execute <35%. **Every slot casts** (`_try_skill`,
  `rebuild_skills` in `player_controller.gd`); dispatch is guarded by
  `test_skills.gd`.

### 3. Gear: 7 slots, rolled affixes, real power

- Slots (`equipment.gd:11`): `weapon, helmet, chest, boots, ring` (5 combat) +
  `pickaxe, axe` (2 trade tools). Tools feed only `gather_speed`; the 5 combat
  slots feed the offensive/defensive stats.
- Items (`data/items.gd`) carry `category, base_stat, base_value, rarity,
  affixes, size`. Rarities: `normal` (0 affixes) → `magic` (1) → `rare` (3) →
  `unique` (fixed). Affixes (`data/affixes.gd`) are prefix/suffix rolls over
  `hp, damage, crit_chance, crit_mult, fire_rate, move_speed,
  cooldown_reduction`.
- **Gear confers real combat power** (ADR 0013, reversing the ADR 0010 freeze) —
  smithing-gated, not kill-loot-gated.

### 4. Satchel & inventory

- **Materials satchel** — `game.materials` (`game.gd`): a `{id: count}` bag of
  ore/herb/ink/draught/trophy stacks, persisted in the save.
- **Pack** — a 5×6 Tetris grid (`inventory.gd`) holding gear items with
  footprint/rotation. Both survive Town↔Dungeon (they live on the Game autoload).
- Crafting (`data/crafting.gd`): 3 stations, 40+ recipes consuming satchel
  materials to yield materials or gear.

### 5. The single source of truth: `_derive_stats()`

`player_controller.gd:_derive_stats()` is the **only** place combat numbers are
computed. It folds, into one `derived_stats` dict, in this order:

1. **Level scaling** (ADR 0013): base `damage` (6) and `hp_max` (30) ×
   `LEVEL_POWER^(trade_lv − 1)`.
2. **Equipped gear**: every slot's `base_stat`/`base_value` + rolled affixes.
3. **Masteries** (perks): e.g. Steady Hands +5% crit, Quick Nock +10% CDR,
   Heavy Draw +25% crit-mult.
4. **Run-scoped buffs**: shrine boons + tonic/chart effects.

It re-runs on equip change (`_on_gear_changed`), on level-up
(`_on_leveled_up` — ADR 0013 followup), and on load. Combat consumers read
`derived_stats`, never the raw constants.

### 6. Progression

One **Wayfinding** trade (ADR 0012), cap **17** (ADR 0006), leveled only by the
cozy loop — gather / craft / chart, **never kills** (combat gives no XP). The
**19-perk mastery ladder** (`game.gd:408` `PERKS`) is shown as a level-1→17
skill tree in the Trades tab. Power is **vertical** and difficulty is the
player↔den level delta (ADR 0013).

## Consequences

- Anyone adding a skill edits `SKILL_POOL` + a `scripts/skills/<name>.gd` data
  object; adding a perk edits `PERKS`; adding gear edits `data/items.gd` /
  `affixes.gd`. No combat-loop code changes for content.
- The model is uniform: all combat power resolves through `_derive_stats()`, so
  a new source (e.g. the future trophy **Ledger**) plugs into one place.

## Deliberately out of scope (design choices, not gaps)

No item durability, no transmog, no equipment set bonuses, no second resource
bar, no per-item level requirements, and no points-allocation skill tree (perks
auto-unlock by level). These were considered and declined to keep the cozy,
one-verb, low-bookkeeping feel; revisit only with a concrete need.

## Followups

- Trophy **Ledger** as a live `derived_stats` source (ADR 0013 followup).
- A data-driven skill **registry** (the `world-of-claudecraft` pattern: pure-data
  abilities + one effect interpreter) — only worth it if the skill count grows
  well past the current 9.
- A 2-player end-to-end automated co-op test (currently verified by hand).
