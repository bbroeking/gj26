---
type: entity
tags: [gathering, nodes, resources, earthcraft, wildcraft, materials]
status: draft
updated: 2026-06-13
sources:
  - wyrd/data/gather.gd
  - wyrd/scripts/gather_node.gd
  - wyrd/scripts/town.gd
  - docs/wyrd-guide.md
  - docs/WORLD_BIBLE.md
---

# Gather Nodes

Gather nodes are interactive world objects — ore rocks, forage bushes, and log piles — that the player channels briefly with **E** to yield one or more materials into the [[Gathering|satchel]] and award [[Trades and Leveling|Trade]] XP.

## Three node kinds

Defined in `wyrd/data/gather.gd` as `NODE_KINDS`:

| Kind id | Verb | Trade | Base XP | Base channel |
|---|---|---|---|---|
| `ore_rock` | Mine | Earthcraft | 10 | 1.6 s |
| `forage_node` | Forage | Wildcraft | 8 | 1.0 s |
| `log_pile` | Chop | Wildcraft | 12 | 1.3 s |

Channel time is the single source of truth in `GatherNode::channel_seconds()`. It is reduced by an equipped trade tool (`gather_speed` stat), the Earthcraft perk "Quick Mining" (×0.65), the Wildcraft perk "Light Hands" (×0.75), and the Quickroot Tonic buff (×(1 − tonic_value)). The "Barren Veins" chart bad-twin lengthens all channels ×1.33.

Moving more than 0.6 m, dying, or taking damage during the channel cancels it without granting the material. A visual progress bar floats above the node.

## Ore tiers

`ORE_TIERS` in `gather.gd` defines five tiers gated by Earthcraft level:

| Tier | Material | Earthcraft req | XP | Channel |
|---|---|---|---|---|
| copper | `copper_ore` | 1 | 6 | 1.2 s |
| bogiron | `bogiron_ore` | 3 | 12 | 1.6 s |
| palechalk | `palechalk` | 7 | 20 | 2.0 s |
| starsilver | `starsilver_ore` | 11 | 30 | 2.4 s |
| hedgesteel | `hedgesteel_ore` | 15 | 42 | 2.8 s |

A locked vein shows its level requirement in the interaction prompt ("Bogiron Vein — needs Earthcraft 3") and is visible in the world — the coveted-not-hidden design. The Earthcraft perk "Rich Seams" grants an extra lump from `starsilver` and `hedgesteel` veins.

The shared ore prop (`prop_ore_vein_v1.glb`) is tinted per tier at load time; bogiron keeps the GLB's native rust color as the visual baseline.

## Herb tiers

`HERB_TIERS` mirrors the ore system for forage, gated by Wildcraft:

| Tier | Material | Wildcraft req | XP | Channel |
|---|---|---|---|---|
| wild | `wild_herb` | 1 | 8 | 1.0 s |
| bittergrass | `bittergrass` | 3 | 12 | 1.2 s |
| crowsfoot | `crowsfoot` | 7 | 18 | 1.5 s |
| mothmint | `mothmint` | 10 | 26 | 1.8 s |
| foxglove | `foxglove_blue` | 13 | 36 | 2.1 s |
| stonebreak | `stonebreak` | 16 | 48 | 2.4 s |

The herb-tier ladder uses the same lock-and-tint pattern as ores. World Bible flavor names are used in display; internal IDs are generic.

## Regrowth

Town nodes **respawn** (flag `respawns = true`) on a timer:
- Herb patches: 20 s (default)
- Ore rocks (Hod's spoil heap): 40 s
- Log piles (the woodpile by the cottage): 30 s

Dungeon nodes **do not respawn** — they deplete for the run. The "Wellspring" chart good-twin grants +1 extra material from every node inside that chart; the bad-twin "Barren Veins" stretches channel times.

## Town placement

The Chartmaker's Yard has practicing nodes for all three gather verbs:
- **Six forage patches** scattered across the yard (`wild_herb`, always regrow).
- **One bittergrass patch** by Quill's still (locked until Wildcraft 3 — visible from the start as a coveted goal).
- **Three ore rocks** at Hod's spoil heap: two copper, one bogiron (locked until Earthcraft 3).
- **Three log piles** by the cottage woodpile.

## Dungeon placement

Inside charts, nodes spawn from [[Affixes|affix]] rolls: Mineral Vein (good twin) gives 3–5 ore rocks; Bramble Bloom gives 4–6 forage nodes; Herbal Patch gives 6–9; Wood Grove gives 3–5 log piles. The ore and herb tiers rolled per chart use weighted tables in `ORE_ROLLS_BY_TIER` and `FORAGE_ROLLS_BY_TIER`, scaling richer as chart tier increases.

## Visual representation

Each node kind has a Meshy-pipeline prop GLB:
- `prop_ore_vein_v1.glb` (fit height 0.75 m)
- `prop_herb_bush_v1.glb` (fit height 0.60 m)
- `prop_log_pile_v1.glb` (fit height 0.65 m)

If a GLB is missing, the code falls back to procedural primitives (stretched sphere for ore/bush; two offset boxes for log pile). All nodes emit a soft shimmer (emissive material at 0.35 energy) so they read as interactive at a glance.

## See also

- [[Gathering]] — the satchel, the gather loop, XP economy
- [[Earthcraft]] — the mining Trade and its perk ladder
- [[Wildcraft]] — the foraging/chopping Trade
- [[Charts]] — which affixes spawn which node types in dungeons
- [[Affixes]] — Mineral Vein, Bramble Bloom, Wood Grove, Herbal Patch
- [[Items and Gear]] — trade tools (pickaxe/axe) that reduce channel time
- [[NPCs]] — Quill's still beside the bittergrass patch; Hod's spoil heap

## Sources

- `wyrd/data/gather.gd` — `NODE_KINDS`, `ORE_TIERS`, `HERB_TIERS`, `ORE_ROLLS_BY_TIER`, `FORAGE_ROLLS_BY_TIER`, all material definitions
- `wyrd/scripts/gather_node.gd` — channel logic, locking, regrowth, GLB loading
- `wyrd/scripts/town.gd` — town node placement coordinates and regrowth timers
- `docs/wyrd-guide.md` — player-facing gather descriptions and controls
- `docs/WORLD_BIBLE.md` — locked resource taxonomy (metal/herb/animal names)
