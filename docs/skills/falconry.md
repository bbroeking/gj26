# Falconry

> Train and command a falcon companion. Sir Withering's quest gifts the
> player **Pernel**; falconry levels improve range, sight, and combat
> assist.

## How it works in code

- `falconry.lv` reads in falcon update logic (`src/main.js`).
- The `falcons_whistle` item is Withering's quest reward — calls Pernel
  to your shoulder.
- Pernel renders as a moving model overlaid on the world; level effects
  scale her radius + behavior.

## Status (current implementation)

| Beat | State |
|---|---|
| Pernel persistent companion | ✅ shipped |
| Sight-range overlay on minimap | ⚠️ partial |
| Combat assist swoop | ⚠️ scaffolded — animation works, damage routing TBD |
| Bonded variants (scout / fighter / forager) | ❌ design-only |

The smallest gameplay surface of any skill — by design, a "cozy
companion" that fills the personality slot more than the verb slot.

## XP sources

Currently awarded on falcon-assisted scouting + combat events. Audit
pending — the skill is the least-instrumented in `awardXp` paths.

## Milestones (`src/data/skill-milestones.js`)

| Lv | Unlock | What |
|---|---|---|
| 1 | **Pernel** | Sir Withering's falcon scouts for you. |
| 15 | **Sight range +2** | Falcon reveals a wider radius around the player. |
| 30 | **Combat assist** | Falcon swoops on aggro'd enemies for chip damage. |

## Where the code lives

| Surface | File |
|---|---|
| Falcon update logic | `src/main.js` (falcon branch in render loop) |
| Falcon mesh + perch | `src/scene/characters.js` (`buildFalconMesh`) |
| Falcon procedural anim | `src/anim/bird.js` |
| Whistle item | `src/data/items.js` (`falcons_whistle`) |

## Reference docs

- `docs/design/skills-consolidation.md` — kept as its own skill
- `docs/design/04-enemy-ai.md` — combat-assist behavior plan
