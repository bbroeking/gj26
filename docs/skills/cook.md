# Cooking

> Turn raw ingredients into healing food. The strongest gathering →
> combat bridge — every consumable HP item passes through this skill.

## How it works in code

- **Burn-chance**: at the hearth station,
  `burnChance = burnChanceLv1 − burnDecayPerLv × (cookLv − 1)`
  (`CONFIG.cooking` in `src/data/config.js`):
  - `burnChanceLv1: 0.40`
  - `burnDecayPerLv: 0.07`
  - At Lv 6 burn chance hits 0% — the milestone band where it stops
    feeling RNG-punishing.
- Recipes consumed by the hearth tile; cooked output replaces raw on success.
- Cooked food provides `food.heal` HP on consume (defined per item in
  `src/data/items.js`).
- `cookCdFrames: 65` in `CONFIG.player` — cook action takes ~1.08s.

## XP sources

| action | xp |
|---|---|
| Successful cook | `cookXpPerSuccess: 6` × tier multiplier |
| Burnt cook | `cookXpPerBurn: 1` |

Higher-tier ingredients (Hedgewight, Tusker) give the most XP per
action — burns still award a small consolation tick so misclicks don't
feel like total loss.

## Milestones (`src/data/skill-milestones.js`)

| Lv | Unlock | What |
|---|---|---|
| 5 | **Fewer burns** | Burn chance starts dropping noticeably. |
| 15 | **Tier-2 stews** | Whicker Stew + Hedgewight Strip for bigger heals. |
| 25 | **Pantry Stew** | Maud's 15-HP signature dish. |

## Cooked-food ladder

| food | heal | tier |
|---|---|---|
| Whitleberry | 1 | foraged (no cook) |
| Cooked Sardine | 3 | tier 1 |
| Brindle Roast | 5 | tier 1 |
| Pippin Spit | 4 | tier 1 |
| Whicker Stew | 4 | tier 2 |
| Tusker Crackling | 7 | tier 2 |
| Hedgewight Strip | 9 | tier 2 |
| Healing Draught | 12 | tier 3 (alchemical) |
| **Pantry Stew** | **15** | tier 3 (Maud's signature) |

## How it connects to other systems

- **Wilds → Cooking**: forageables, fish, and meat from gathered drops
  all flow into the hearth.
- **Cooking → HP**: every cooked item heals against the HP pool. HP
  gates how much survival the cook track buys you.
- **Cartography**: not direct — but quaffed food during a chart run
  lets you finish dungeons that gate carto XP.

## Where the code lives

| Surface | File |
|---|---|
| Burn formula + tunables | `src/data/config.js` (`CONFIG.cooking`) |
| Cook action loop | `src/main.js` (hearth interaction branch) |
| Cooked items + heal values | `src/data/items.js` (food entries) |

## Reference docs

- `docs/design/skills-consolidation.md` — Cooking left as its own skill
- `docs/design/07-skill-level-pacing.md` — burn-curve tuning
