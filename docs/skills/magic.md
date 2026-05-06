# Magic

> Casts rune spells from the spell catalog. Levels unlock new spells
> across elemental damage, utility, buffs, travel, and named endgame
> spells. Magic also gates the **rune slot** on the Charting modal at
> Lv 30 (paired with Cartography 50) — the only direct cross-skill
> magic-into-cartography hook.

## How it works in code

- **Spell `reqLevel` gate** in `src/game/spells.js` — each spell has a
  `reqLevel` checked against `player.skills.magic.lv` before cast.
- 21 spells total; **`stub: true`** entries short-circuit `castSpell` —
  they show in the catalog with a "COMING SOON" badge but don't fire.
- **INK_TO_RUNE** mapping in `src/game/spells.js` connects the 9 ink
  recipes to their rune outputs — Magic and Cartography share the rune
  economy.
- Cast UI in `src/ui/spellbook.js`; bind to slots 1–8 from the action
  bar.

## XP sources

Each spell has an `xpOnCast` field. Magic XP scales by spell tier:

| tier | typical xp/cast |
|---|---|
| 1 | ~3 |
| 2 | ~10 |
| 3 | ~25 |

## Milestones (`src/data/skill-milestones.js`)

| Lv | Unlock | What |
|---|---|---|
| 1 | **Wind Strike** | Tier-1 air-element damage spell. |
| 13 | **Fire Strike** | Strongest tier-1 elemental. |
| 24 | **Wind Wave** | Tier-2 AoE damage spell, 4-tile range. |
| 30 | **Rune slot** (with carto 50) | Bake a passive into charts in the Charting modal. |

## Spell ladder

### Tier 1 — single-target damage + utility

| spell | reqLevel | works |
|---|---|---|
| Wind Strike | 1 | ✅ |
| Water Strike | 5 | ✅ |
| Sense Aggro | 6 | ⚠️ state-only |
| Quench Stamina | 8 | ⚠️ stub-fixed |
| Earth Strike | 9 | ✅ |
| Stone Skin | 12 | ⚠️ state-only |
| Fire Strike | 13 | ✅ |
| Ignite | 14 | 🚧 stub |

### Tier 2 — AoE + utility

| spell | reqLevel | works |
|---|---|---|
| Levitate | 16 | 🚧 stub |
| Quiet Thought | 18 | 🚧 stub |
| Wind Wave | 24 | ✅ |
| Water Wave | 28 | ✅ |
| Vigor | 30 | ⚠️ state-only |
| Bind Plant | 38 | 🚧 stub |
| Animal Sight | 41 | 🚧 stub |

### Tier 3 — endgame

| spell | reqLevel | works |
|---|---|---|
| Teleport: Bramblewood | 33 | ✅ |
| Teleport: Last Chartmaker | 35 | ⚠️ conditional |
| Holdinghut | 50 | 🚧 stub |
| Death's Whisper | 60 | ✅ |
| Blood Pact | 70 | 🚧 stub |
| Soul Bind | 85 | 🚧 stub |

8 spells fully wired; the rest are catalog-only (state-only or stub)
pending the spell-system audit (`docs/design/10-spell-system.md` §1a).

## How it connects to other systems

- **Cartography**: every ink type maps to a rune (`INK_TO_RUNE`). Press
  an ink at the Pedestal to produce a rune; runes are spell ammo AND
  chart catalysts at carto 50 + magic 30.
- **Combat**: damage spells go through the same `awardCombatXp` paths
  as melee — they award atk + str XP per hit on top of magic XP.

## Where the code lives

| Surface | File |
|---|---|
| Spell definitions + reqLevel gates | `src/game/spells.js` |
| `INK_TO_RUNE` map | `src/game/spells.js` |
| Spellbook UI + bind slots | `src/ui/spellbook.js` |
| Cast routing | `src/main.js` (cast handler) |
| Pedestal (ink → rune) | `src/ui/pedestal.js` |
| Rune-slot in charting | `src/ui/charting.js` |

## Reference docs

- `docs/design/10-spell-system.md` — full spell catalog audit
- `docs/cartography-systems.md` — rune-slot interaction with charts
