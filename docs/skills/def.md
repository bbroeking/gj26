# Defence

> Determines how often you take a hit. Third of the **combat triple**.
> Reduces enemy hit chance against you symmetric to how Attack increases
> yours.

## How it works in code

`rollEnemySwing` in `src/game/combat.js`:

```
hitChance = enemyHitBase + atkContrib · enemy.atkLv − defContrib · (defLv + defBonus)
            (clamped to [enemyHitLo, enemyHitHi])
```

Tunables (`src/data/config.js` → `CONFIG.combat`):

- `enemyHitBase: 0.20` (lower than the player's 0.50)
- `enemyHitLo: 0.10`, `enemyHitHi: 0.85` (capped — bosses never auto-hit)

The lower enemy floor means at low levels the player dodges 60–70% of
incoming swings against tier-1 grunts — pulling 2 brindleboars at Lv 1
isn't a death sentence. Defence widens that dodge-band as it scales.

Equipment `def` bonus comes from `inventory.totalEquipBonus('def')` —
body / shield / helmet stack additively.

## XP sources

Damage **taken** is the primary XP source — you level Def by getting hit
and tanking it:

```
def XP += dmg · 4
```

Combat-style **Defensive** further routes 4× weight into Def per dealt
hit (see `atk.md` table).

## Milestones (`src/data/skill-milestones.js`)

| Lv | Unlock | What |
|---|---|---|
| 8 | **Shield Bash** | Stun a target briefly with your shield. |
| 14 | **Defensive Stance** | +30% defence buff for 25s. |
| 22 | **Riposte** | Parry-window counter — negates an incoming hit. |

## Tier signal

Def level gates **armor `reqLevel`** on body / shield / helm:

- Leather + Wooden Shield (def 1)
- Bogiron Cuirass + tier-2 shields (def 22)
- Cinderbloom Plate (def 38)

## Where the code lives

| Surface | File |
|---|---|
| Enemy hit roll | `src/game/combat.js` (`rollEnemySwing`) |
| Equipment def stacking | `src/game/inventory.js` (`totalEquipBonus`) |
| Shield Bash / Stance / Riposte | `src/game/abilities.js` |
| XP routing | `src/game/skills.js` (`awardCombatXp`) |

## Reference docs

- `docs/design/01-combat-tuning.md` — symmetric formula notes
- `docs/design/06-equipment-progression.md` — armor tier curve
- `docs/design/09-active-abilities.md` — Riposte parry window
