# Strength

> Determines damage dealt per swing. Second of the **combat triple**.
> Powers the size of the random damage roll on every successful melee
> hit.

## How it works in code

`rollPlayerSwingDetailed` in `src/game/combat.js` rolls max damage:

```
maxHit = floor(strBase + strContrib · (strLv + strBonus))
         · weapon.dmgMul
         (with minMaxHit floor)
```

Tunables (`src/data/config.js` → `CONFIG.combat`):

- `strBase: 1.5`, `strContrib: 0.35`, `minMaxHit: 2`
- Per-weapon `dmgMul`: sword 1.0, dagger 0.80, axe-tier varies

The Stardew floor (`hitBase: 0.50`, `hitLo: 0.40`) means the roll always
lands somewhere in [0, maxHit] — Strength is what stretches the
ceiling. A Lv 1 player with a sword has `maxHit ≈ 2`; a Lv 25 player has
`maxHit ≈ 10`.

## XP sources

Combat damage dealt, scaled by style (see `atk.md` for the table). The
**Aggressive** style routes 4× into Strength.

## Milestones (`src/data/skill-milestones.js`)

| Lv | Unlock | What |
|---|---|---|
| 10 | **Bull Rush** | Charge through enemies, knocking them back. |
| 15 | **Sunder** | Heavy strike that lowers the target's defence. |
| 25 | **Bogiron weapons** | Wield Bogiron tier-2 swords / daggers / axes. |

## Tier signal

Strength gates `reqLevel` on **heavy weapon variants** (axes
specifically) and on `dmgMul`-bonus passives planned for str 35+.

## Where the code lives

| Surface | File |
|---|---|
| Damage roll | `src/game/combat.js` (`rollPlayerSwingDetailed`) |
| Bull Rush + Sunder | `src/game/abilities.js` |
| Weapon tiers + dmgMul | `src/data/items.js` (weapon entries) |
| XP routing | `src/game/skills.js` (`awardCombatXp`) |

## Reference docs

- `docs/design/06-equipment-progression.md` — weapon tier curve
- `docs/design/09-active-abilities.md` — ability balance
- `docs/design/01-combat-tuning.md` — Stardew-floor tuning
