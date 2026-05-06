# Attack

> Determines whether your swing connects. The first half of the **combat
> triple** (Attack / Strength / Defence). All melee swings, ranged shots,
> and most active abilities route through Attack's hit-chance roll.

## How it works in code

`rollPlayerSwingDetailed(player, target)` in `src/game/combat.js` rolls
hit chance using the formula:

```
hitChance = hitBase + atkContrib · (atkLv + atkBonus) − defContrib · target.defLv
            (clamped to [hitLo, hitHi])
```

Tunables (`src/data/config.js` → `CONFIG.combat`):

- `hitBase: 0.50`, `atkContrib: 0.04`, `defContrib: 0.02`
- `hitLo: 0.40`, `hitHi: 0.98`

After the **combat-style pivot** (2026-05), every swing connects — `hitLo
= 0.40` is a quality floor, not a hit/miss probability. Attack level
biases the *quality* of the roll toward `maxHit`, not whether the swing
lands at all. Damage is rolled separately by Strength once hit-chance
resolves the quality.

## XP sources

Combat damage dealt, scaled by combat-style multiplier (`CONFIG.combat.styles`):

| style | atk | str | def | hp |
|---|---|---|---|---|
| Accurate | **4** | 0 | 0 | 1.33 |
| Aggressive | 0 | **4** | 0 | 1.33 |
| Defensive | 0 | 0 | **4** | 1.33 |
| Controlled | 1.34 | 1.34 | 1.34 | 1.33 |

Computed in `awardCombatXp` (`src/game/skills.js`).

## Milestones (`src/data/skill-milestones.js`)

| Lv | Unlock | Slot | What |
|---|---|---|---|
| 5 | **Cleave** | 1 | Two-tile-ahead AoE swing. |
| 12 | **Leap** | 2 | Click-to-leap with AoE on landing. |
| 18 | **Rend** | 3 | Bleed DoT on the target. |
| 25 | **Whirlwind** | 4 | Spin attack hitting all adjacent enemies. |

Atk also gates the **ranged tree** (Aimed Shot 16, Backstab 20) and
several rogue/finisher abilities. The Atk catalog is the largest of any
skill.

## Combat juice

When an Attack swing kills (`willKill`):

- **0.12s hit-stop** (time freezes briefly on impact)
- **24-spark burst** at the corpse position
- Camera FOV pulses **−3°** for snap
- Floating text reads **"⚔ FELLED"** in red
- Splat kind escalates: `crit` (1.4× scale, yellow) when crit; `kill`
  (1.6× scale, red) when killing-blow

See `src/game/combat.js` killing-blow flourish + `src/core/floaters.js`
splat kinds.

## Tier signal

Attack level gates **weapon `reqLevel`** on every weapon item:

- Brindle tier (atk 1)
- Bogiron tier (atk 15)
- Cinderbloom tier (atk 30)

## Where the code lives

| Surface | File |
|---|---|
| Hit-chance + damage roll | `src/game/combat.js` |
| Combat-style multipliers | `src/data/config.js` (`CONFIG.combat.styles`) |
| Abilities (Cleave, Leap, Rend, Whirlwind, Aimed Shot, Backstab) | `src/game/abilities.js` |
| XP routing | `src/game/skills.js` (`awardCombatXp`) |
| Killing-blow juice | `src/game/combat.js` + `src/core/floaters.js` |

## Reference docs

- `docs/design/01-combat-tuning.md` — current numbers + history
- `docs/design/04-enemy-ai.md` — telegraphs and group tactics
- `docs/design/09-active-abilities.md` — ability balance audit
- `docs/research/arpg-game-feel.md` — juice research that drove the
  killing-blow flourish + crit-feel layer
