# ADR 0016 — Four Trades, each level 1–23

**Status:** Accepted direction (2026-07-17)

**Supersedes:** ADR 0006 (level-17 cap) and ADR 0012 (one unified
Wayfinding level). It does not reverse ADR 0003's gather → craft → chart →
delve spine or ADR 0013's vertical-progression intent.

## Context

The playable build compressed all progression into one Wayfinding level and
capped it at 17. That reduced cognitive load, but it also removed the distinct
mastery fantasies of learning to chart, mine and smith, forage and brew, and
hunt. The full-game direction now requires every leveling discipline to run
from level 1 through level 23.

The project vocabulary still matters: a leveling discipline is a **Trade**;
a hotbar combat action is a **Skill**. This prevents “level 12 skill” from
meaning both a profession level and an ability unlock.

## Decision

Wayfinder has four independently leveled Trades, all using the same 1–23
level range:

1. **Wayfinding** — chart inscription, affix discovery, chart completion,
   boss-chart construction, and Living Atlas restoration.
2. **Earthcraft** — mining, refining, smithing, tools, gear, and charms.
3. **Wildcraft** — foraging, woodcutting, cooking, brewing, inks, and field
   preparations.
4. **Huntcraft** — encounter completion, elite hunts, boss mastery, and the
   gradual unlocking/upgrading of hotbar Skills.

The existing cumulative XP curve is extended without changing its shape:

```gdscript
xp_for_level(n) = (n - 1) * (n - 1) * 8 + (n - 1) * 32
```

Level 23 therefore requires 4,576 lifetime XP in each Trade. XP remains
activity-specific: mining does not level Huntcraft, kills do not level
Wayfinding, and buying inputs never awards Trade XP.

Players begin with only the fixed Basic Shot. Combat Skills are introduced
one at a time through Huntcraft and the story; the three configurable hotbar
slots remain an opportunity-cost loadout rather than an ever-growing action
bar.

## Consequences

- Save data must migrate from the one-level model to four Trade records. For
  existing development saves, clone the old lifetime XP into all four Trades
  (clamped to level 23). The old unified level represented all activities, and
  preserving every previously unlocked verb is safer than guessing a split.
  New saves earn the four XP pools independently.
- Every Trade needs a visible reward at each of the 23 levels. A reward may be
  a recipe, resource, chart, building service, Skill, Skill upgrade, passive,
  or story gate; it need not always be raw power.
- The current Summit at Wayfinding 16 becomes the hinge between the shipped
  Bramblewood arc and the deeper Norse-inspired root saga, not the final end
  of the full game.
- Gear tiers, biome tiers, boss charts, buildings, item icons, and story
  chapters share this same 1–23 content ladder.
- The capstone legendary requires level 23 in all four Trades, making the
  whole cozy loop—not combat alone—the final pursuit.

## Guardrails

- Four Trade bars are introduced through onboarding, not shown as four urgent
  chores on the first screen.
- No daily quests, seasonal power resets, endless paragon track, auction house,
  or mandatory kill grind is added to justify the larger progression model.
- Random charts carry authored story fragments and guaranteed pity progress;
  campaign advancement can never be blocked by an unlucky drop streak.
- The project remains warm and local. Norse myth supplies structure and
  symbols; it does not turn Bramblewood into a grim apocalypse retelling.
