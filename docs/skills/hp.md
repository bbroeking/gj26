# Hit Points

> Health pool. The fourth combat-tree skill — caps your max HP and
> regenerates out of combat. Starts at level 10 by default so a
> cozy-RPG player isn't two-shot in early pulls.

## How it works in code

- `hpMaxForLv(lv) = lv × 2` in `src/game/skills.js`. Applied in
  `maybeLevelUp` when HP levels: `player.hpMax = hpMaxForLv(...)`.
- Starting value is `out.hp.lv = 10` in `makeSkills()` → starting
  `hpMax = 20`.
- Out-of-combat regen: **+1 HP per 3s**, gated by no combat target +
  `hurtT` cooldown elapsed (`src/game/player.js`).

## XP sources

Both the attacker AND the defender role award HP XP scaled by the
combat-style's `hp` multiplier (1.33 across all four styles):

```
HP XP += damage · style.hp
```

So HP levels on every hit dealt OR received, regardless of style. It's
the fastest-leveling combat skill at low levels — by design, since it
gates the survivability ceiling.

## Milestones (`src/data/skill-milestones.js`)

| Lv | Unlock | What |
|---|---|---|
| 10 | **20 HP cap** | Default starting cap. Each HP level adds 2 max HP. |
| 25 | **Last Stand** | Slot-4 ability: 5s of damage immunity below 20% HP. |
| 50 | **100 HP cap** | Mid-game survivability — most tier-2 enemies stop one-shotting you. |

## How it connects to other systems

- **Cooking** is the primary HP-restoration source — every consumable
  food's `food.heal` value reads against your HP pool.
- **Killing-blow flourish** (Atk system) doesn't bypass HP gates — Last
  Stand still triggers below 20% even on the final swing.
- **Hedgemother phase-2 bramble-pull** (`src/game/enemies.js`) roots
  the player via `player.rootedT = 1.0` — HP regen pauses while rooted.

## Where the code lives

| Surface | File |
|---|---|
| `hpMaxForLv` + level-up cap | `src/game/skills.js` |
| Out-of-combat regen | `src/game/player.js` |
| Last Stand ability | `src/game/abilities.js` |
| HP UI bar | `index.html` (`#hp-bar`) + `src/main.js` (`renderStats`) |

## Reference docs

- `docs/design/07-skill-level-pacing.md` — HP-per-level ramp
- `docs/design/01-combat-tuning.md` — Stardew floor + survivability
