# Earth

> The umbrella **extract-and-shape** skill. Absorbs Mining and Smithing
> into one identity: *what you take from the ground and work into
> shape*. Every miner is a smith and vice-versa; both share the same
> metal-tier ladder.
>
> Consolidated 2026-05-04 per `docs/design/skills-consolidation.md`.
> Legacy keys (`mine`, `smith`) are aliased to `earth`.

## What it does in code

| Verb | Source | Tool | Output |
|---|---|---|---|
| Mine ore | `world.oreNodes` | `tool: 'pickaxe'` | raw ore |
| Smelt bar | recipe table in `src/main.js` | forge tile | metal bar |
| Smith weapon/armor | recipe table | forge tile | equipment item |

**Skill gates**: ore tiles declare `source: { skill: 'earth', level: N }`;
smith recipes declare `reqSkill: 'earth'`. UI E hover-tooltips show the
gap before the player tries.

## XP sources

| action | xp |
|---|---|
| Mine an ore (Mosswort, Palechalk, Bogiron, Coalrose) | ~10 each |
| Smelt a bar (`smelt_brindle`, `smelt_iron`, `smelt_steel`) | 14 / 14 / 24 |
| Smith a weapon / armor | 28 / 56 / 100+ depending on tier |

## Milestones (`src/data/skill-milestones.js`)

| Lv | Unlock | What |
|---|---|---|
| 5 | **Pickaxe + smith strikes** | ~10% cooldown reduction. |
| 15 | **Bogiron tier** | Bogiron ore + tier-2 weapons/armor. |
| 22 | **Bogiron cuirass** | Heavy tier-2 chest armor. |
| 30 | **Cinderbloom tier** | Coalrose alloy + tier-3 sword/dagger/axe/helm/shield. |
| 38 | **Cinderbloom plate** | Tier-3 endgame plate armor. |

## Tier ladder (mining → smithing)

| ore | mine req | combine | bar | weapons unlock |
|---|---|---|---|---|
| Mosswort + Palechalk | 1 | alloyed | Brindle Bar | Brindle weapons (req 1) |
| Bogiron Ore | 15 | single | Bogiron Bar | Bogiron weapons (req 15–22) |
| Bogiron + Coalrose | 25–30 | alloyed | Cinderbloom Bar | Cinderbloom weapons (req 30–38) |

## How it connects to other systems

- **Cartography**: earthen materials (charcoal_stick, ore_dust,
  bog_silt, stone_chip, bogiron_ore) feed the Inscribing Table.
  Stoneground / Refined / Lustrous inks all bias on `earthen` essence.
- **Vessel commission**: Hod (the smith) takes 1 stoneground_ink + 2
  charcoal_stick for a Clay Flask — earth gathering enables tier-3
  Forge-Brand Ink.
- **Combat**: every weapon + armor in `atk.md` / `def.md`'s tier
  ladders is smithed via Earth.

## Where the code lives

| Surface | File |
|---|---|
| Ore-node spawn + respawn | `src/scene/world.js` (`oreNodes`) |
| Smith / smelt recipes | `src/main.js` (recipe table) |
| Skill gate hover | `src/main.js` (UI E tooltip helper) |

## Reference docs

- `docs/design/skills-consolidation.md` — the 13→10 consolidation
- `docs/design/06-equipment-progression.md` — tier curve
