---
type: system
tags: [gathering, nodes, channel, tiers, earthcraft, wildcraft]
status: draft
updated: 2026-06-13
sources: ["docs/wyrd-trades-recap.md", "docs/specs/45-trade-ladders-earth.md", "docs/specs/45-trade-ladders-wilds.md", "wyrd/data/gather.gd", "wyrd/scripts/game.gd"]
---

# Gathering

Gathering is the channel-time verb that extracts raw materials from GatherNodes — ore from veins, herbs from patches, logs from piles — and awards [[Trades and Leveling|trade]] XP to [[Earthcraft]] or [[Wildcraft]].

## The channel mechanic

Every harvest is a timed channel (1.0–2.8 seconds depending on node tier). A progress bar fills; moving or taking damage cancels the channel with no yield. When the channel completes, the material goes to the satchel and XP is awarded.

Three node kinds exist (`wyrd/data/gather.gd::NODE_KINDS`):

| Kind | Verb | Trade | Base XP | Base channel |
|---|---|---|---|---|
| `ore_rock` | Mine | earth | 10 | 1.6 s |
| `forage_node` | Forage | wilds | 8 | 1.0 s |
| `log_pile` | Chop | wilds | 12 | 1.3 s |

Channel times and XP are overridden per tier (see below). Tool perks and the [[Wildcraft]] Light Hands perk apply multipliers on top.

## Node tiers and level gates

Locked nodes are visible and display their level requirement — *coveted, not hidden* (A6 design principle). A player under the requirement sees the node name and level, but cannot gather it.

### Ore tiers (Earthcraft gates)

Defined in `wyrd/data/gather.gd::ORE_TIERS`. Five tiers ship in the demo:

| Tier | Item | Req Earthcraft | Channel | XP | XP/sec |
|---|---|---|---|---|---|
| Copper | `copper_ore` | 1 | 1.2 s | 6 | 5.0 |
| Bogiron | `bogiron_ore` | 3 | 1.6 s | 12 | 7.5 |
| Palechalk | `palechalk` | 7 | 2.0 s | 20 | 10.0 |
| Starsilver | `starsilver_ore` | 11 | 2.4 s | 30 | 12.5 |
| Hedgesteel | `hedgesteel_ore` | 15 | 2.8 s | 42 | 15.0 |

XP/sec climbs +2.5 per tier; channel grows +0.4 s per tier. (`docs/specs/45-trade-ladders-earth.md`)

### Herb tiers (Wildcraft gates)

Defined in `wyrd/data/gather.gd::HERB_TIERS`. Six tiers, World Bible's locked herb taxonomy:

| Tier | Item | Req Wildcraft | Channel | XP |
|---|---|---|---|---|
| Wild | `wild_herb` | 1 | 1.0 s | 8 |
| Bittergrass | `bittergrass` | 3 | 1.2 s | 12 |
| Crowsfoot | `crowsfoot` | 7 | 1.5 s | 18 |
| Mothmint | `mothmint` | 10 | 1.8 s | 26 |
| Foxglove-Blue | `foxglove_blue` | 13 | 2.1 s | 36 |
| Stonebreak | `stonebreak` | 16 | 2.4 s | 48 |

(`docs/specs/45-trade-ladders-wilds.md`, `wyrd/data/gather.gd`)

## Where nodes spawn

**In town** (regrowing, tutorialized):
- 6 wild herb patches around the Chartmaker's Yard — regrow 20 s
- 3 ore rocks at Hod's spoil heap — regrow 40 s
- 3 log piles at the cottage — regrow 30 s
- One locked Bittergrass Patch by Quill's still (visible from Wildcraft 1, usable at 3)

**In dungeons** (depletes per run, placed by chart affixes): `docs/wyrd-trades-recap.md` § In dungeons. The affix determines spawn count; bad twins of gather affixes place zero nodes.

## Dungeon node-tier rolls

The ore and herb tier that spawns in a dungeon is determined by chart tier, not solely by affix level. Tables live in `wyrd/data/gather.gd::ORE_ROLLS_BY_TIER` and `FORAGE_ROLLS_BY_TIER`. A single `_roll_tier` helper in `dungeon_gen.gd` consults the correct table at generation time.

| Chart tier | Ore pool | Herb pool (Bramble Bloom) |
|---|---|---|
| 1 | Copper 55 / Bogiron 45 | Wild 60 / Bittergrass 40 |
| 2 | Bogiron 35 / Palechalk 35 / Starsilver 20 / Hedgesteel 10 | Bittergrass 25 / Crowsfoot 40 / Mothmint 25 / Foxglove 10 |
| 3 | Palechalk 25 / Starsilver 40 / Hedgesteel 35 | Mothmint 35 / Foxglove 40 / Stonebreak 25 |

The Herbal Patch affix uses `FORAGE_ROLLS_PATCH`, which weights the deepest herb in the band higher.

## Tool and perk effects

Gather tools reduce channel time (e.g. Bogiron Pickaxe −30%, Cinderbloom −45%, Starsilver −55%). Tools apply to the relevant kind only (pickaxe → ore, axe → logs).

Perks from `wyrd/scripts/game.gd::PERKS`:
- **Keen Eye** (Wildcraft 5): +1 herb per forage
- **Clean Splits** (Wildcraft 10): +1 log per chop
- **Sturdy Swings** (Earthcraft 5): 25% chance of a second ore lump
- **Miner's Rhythm** (Earthcraft 10): −33% mining channel
- **Rich Seams** (Earthcraft 13): Starsilver and deeper veins always give a second lump
- **Light Hands** (Wildcraft 13): forage and chop channels −25%

`Game.gather_bonus(kind)` centralizes the deterministic bonus yield; chance perks roll there so GatherNode scripts stay simple.

## First-harvest tutorials

The first harvest of each kind triggers a one-time hint dialog (`SKILL_HINTS` in `game.gd`): Mara voices forage and logs; Hod voices ore. These are saved in `seen_hints`.

## See also

- [[Earthcraft]], [[Wildcraft]], [[Trades and Leveling]]
- [[Gather Nodes]], [[Chart Loop]], [[Dungeon Generation]]
- [[Affixes]] (gather affixes place or deny nodes)

## Sources

- `wyrd/data/gather.gd` — NODE_KINDS, ORE_TIERS, HERB_TIERS, roll tables
- `wyrd/scripts/game.gd` — gather_bonus, PERKS, SKILL_HINTS
- `docs/wyrd-trades-recap.md` — in-town nodes, channel mechanic
- `docs/specs/45-trade-ladders-earth.md` — ore tier table
- `docs/specs/45-trade-ladders-wilds.md` — herb tier table
