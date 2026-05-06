# Wilds

> The umbrella **gathering** skill. Absorbs Foraging, Fishing, and
> Woodcutting into one identity: *what nature gives you*. Every harvest
> verb in meadow / forest / pond pool feeds the same level.
>
> Consolidated 2026-05-04 per `docs/design/skills-consolidation.md`.
> Legacy keys (`forage`, `fish`, `wc`) are aliased to `wilds` at engine
> level (`aliasSkill` in `src/game/skills.js`) so older code routes XP
> correctly.

## What it does in code

| Verb | Source data | Tool | Notes |
|---|---|---|---|
| Forage | `world.forageSpawns` | none | berries, herbs, mushrooms |
| Fish | water tiles | `tool: 'rod'` | catch chance scales with level |
| Woodcut | `world.trees` | `tool: 'axe'` | logs feed Cooking + smithing |

**Fish catch chance**: `min(0.95, 0.60 + 0.03 × (wilds.lv − 1))` — a
Lv 1 player lands ~60%, a Lv 12 player ~93%.

**Skill gates**: items declare `source: { skill: 'wilds', level: N }`
in `src/data/items.js`. UI E hover-tooltips show "needs Wilds N (you
have M)" before the player tries an under-levelled gather.

## XP sources

| action | xp |
|---|---|
| Pick a forageable | flat per-item (tier-2 herbs award more) |
| Catch a fish | flat per-fish |
| Chop a log | flat per-chop |

## Milestones (`src/data/skill-milestones.js`)

| Lv | Unlock | What |
|---|---|---|
| 5 | **Catch chance up** | Fishing climbs faster — fewer empty rod-pulls. |
| 12 | **Mid-tier herbs** | Wishrose + Mossvine for inscribing. |
| 15 | **Coalrose chunks** | Harvest coalrose at higher Wolds elevations. |
| 25 | **Foxfire Glow** | Rare night-only forageable for endgame charts. |
| 35 | **Endgame fish + ash** | Briarcoast fish + Hard Ash logs for tier-3 crafting. |

## How it connects to other systems

- **Cartography**: verdant materials (hedgecap, whitleberry, wishrose,
  bramble resin, thorn essence) all feed the Inscribing Table. The
  workshop's Materials section groups them under **Verdant**.
- **Cooking**: raw fish + foraged ingredients feed the cook station.
- **Vessel commission**: Quill (the herbalist) takes 1 vellum + 2
  wishrose for a Bound Parchment vessel — wilds gathering directly
  enables tier-3 ink mixing.

## Where the code lives

| Surface | File |
|---|---|
| Forage spawns + respawn | `src/scene/world.js` (`forageSpawns`) |
| Tree spawns + chop loop | `src/scene/world.js` (`trees`) |
| Fish catch + cooldown | `src/main.js` (fishing branch in interact) |
| Skill-gate hover tooltip | `src/main.js` (UI E tooltip helper) |

## Reference docs

- `docs/design/skills-consolidation.md` — the 13→10 consolidation
- `docs/design/07-skill-level-pacing.md` — gather XP curves
