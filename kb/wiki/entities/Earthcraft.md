---
type: entity
tags: [trade, earthcraft, ore, smithing, forge, perks, earth]
status: draft
updated: 2026-06-13
sources: ["docs/wyrd-trades-recap.md", "docs/specs/45-trade-ladders-earth.md", "docs/adr/0006-demo-level-cap-17.md", "wyrd/data/gather.gd", "wyrd/data/crafting.gd", "wyrd/data/economy.gd", "wyrd/scripts/game.gd"]
---

# Earthcraft

Earthcraft (code key: `earth`) is the mining and smithing Trade — it governs ore gathering, bar smelting, and gear forging at Hod's Anvil, and levels whenever the player mines ore.

## XP and leveling

XP is awarded per harvest: copper 6, bogiron 12, palechalk 20, starsilver 30, hedgesteel 42 XP. Smelting and smithing also award XP (8–100 XP per recipe at the forge). All on the shared curve (`xp_for_level(n) = (n-1)² × 8 + (n-1) × 32`). Cap: 17 (ADR 0006).

## The ore tier ladder

Five tiers in the demo, gated by Earthcraft level. Locked veins are visible and name their level requirement. (`wyrd/data/gather.gd::ORE_TIERS`)

| Tier | Req | Channel | XP | Node name |
|---|---|---|---|---|
| Copper | E1 | 1.2 s | 6 | Copper Vein |
| Bogiron | E3 | 1.6 s | 12 | Bogiron Vein |
| Palechalk | E7 | 2.0 s | 20 | Palechalk Vein |
| Starsilver | E11 | 2.4 s | 30 | Starsilver Vein |
| Hedgesteel | E15 | 2.8 s | 42 | Hedgesteel Vein |

Starsilver and Hedgesteel are named from the World Bible's locked metal taxonomy (tiers 4 and 5). Coalrose (fuel ore, tier between palechalk and starsilver) is intentionally skipped; Wildgold (tier 6) reserved post-demo. (`docs/specs/45-trade-ladders-earth.md` § New ore tiers)

> ⚠️ `docs/WORLD_BIBLE.md` lists palechalk as a tier-1 ore (the tin analog); the game uses it as the E7 deep ore. `docs/specs/45-trade-ladders-earth.md` records this intentional drift: "we follow the game and climb the bible ladder for new names."

## The forge ladder (Hod's Anvil, full 1→17)

`wyrd/data/crafting.gd::STATIONS.forge` lists recipes in level order. Every recipe at E10+ yields rare rarity (three affixes). (`docs/specs/45-trade-ladders-earth.md`)

| Lv | Unlock |
|---:|---|
| 1 | Copper Bar · Bogiron Bar · Shortbow |
| 2 | Bogiron Pickaxe / Axe (−30% channel) |
| 3 | Bogiron ore vein unlocks |
| 4 | Longbow |
| 5 | **Perk: Sturdy Swings** · Bogiron Cap · Bogiron Boots (magic) |
| 6 | Bogiron Jerkin (magic) |
| 7 | Palechalk Vein · Cinderbloom Pickaxe / Axe (−45% channel) |
| 8 | Copper Ring (magic) |
| 9 | Palechalk Ring (rare) · Palechalk Longbow (magic) |
| 10 | **Perk: Miner's Rhythm** · Palechalk Jerkin (rare) |
| 11 | Starsilver Vein · Starsilver Bar |
| 12 | Starsilver Pickaxe / Axe (−55% channel) |
| 13 | **Perk: Rich Seams** · Starsilver Band (rare) |
| 14 | Starsilver Longbow (rare) |
| 15 | Hedgesteel Vein · Hedgesteel Bar |
| 16 | Hedgesteel Cap (rare) · Hedgesteel Boots (rare) |
| 17 | **Capstone perk: Smith's Thrift** · Hedgesteel Warbow (rare) |

Note: the Hedgesteel Bar recipe requires `hedgesteel_ore ×2 + logs ×1` — a deliberate cross-trade pull (Wildcraft chopping feeds the deepest smithing). (`docs/specs/45-trade-ladders-earth.md`)

## Perks

All four perks in `PERKS["earth"]` (`wyrd/scripts/game.gd`):

| Lv | Id | Name | Effect |
|---:|---|---|---|
| 5 | `double_ore` | Sturdy Swings | 25% chance any vein gives a second lump |
| 10 | `quick_mining` | Miner's Rhythm | Mining channel −33% |
| 13 | `rich_seams` | Rich Seams | Starsilver and deeper veins always give a second lump (deterministic, tier-gated) |
| 17 | `smiths_thrift` | Smith's Thrift | 25% chance a forge craft returns one raw input — never a bar (a bar refund would crack the economy gate) |

Rich Seams is deterministic for tier ≥ starsilver only, so it doesn't retro-buff the copper/bogiron economy. Smith's Thrift is restricted to raw inputs (ore, chalk, logs) by the string suffix check in `game.gd::craft()` — a load-bearing convention: no raw material may be named with the `_bar` suffix.

## Dungeon ore sourcing

Deep ores (starsilver, hedgesteel) spawn in tier-2 Hollow and Briar Maze charts via the Mineral Vein affix. The Summit (`affix_slots: 0`) cannot roll Mineral Vein; the spec suggests placing two fixed Hedgesteel veins in the Summit layout as a one-shot flavorful moment. (`docs/specs/45-trade-ladders-earth.md` § Open Q1, `wyrd/data/gather.gd::ORE_ROLLS_BY_TIER`)

## Cross-trade hooks

- Wildcraft logs feed the Hedgesteel smelt, Starsilver Pickaxe/Axe, Starsilver Longbow, Hedgesteel Cap, and Warbow — keeping chopping relevant through E17.
- Earthcraft ores feed Wayfinding inks: bogiron feeds stoneground ink and refined ink; starsilver feeds the (planned) deep ink track. (`docs/specs/45-trade-ladders-earth.md` § Cross-trade hooks)
- Foxglove Ink (Wildcraft) requires bogiron ore — an Earthcraft pull into a Wildcraft recipe.

## See also

- [[Trades and Leveling]], [[Gathering]], [[Crafting]], [[Economy]]
- [[Wildcraft]] (logs feed deep smithing), [[Wayfinding]] (inks consume ore)
- [[Items and Gear]], [[NPCs]] (Hod Tenter)

## Sources

- `docs/specs/45-trade-ladders-earth.md` — full design spec, economy gate proof
- `docs/wyrd-trades-recap.md` — code-grounded state
- `wyrd/data/gather.gd` — ORE_TIERS, MATERIALS (ore + bar descs)
- `wyrd/data/crafting.gd` — STATIONS.forge, RECIPES E1–17
- `wyrd/scripts/game.gd` — PERKS["earth"], Smith's Thrift raw-only guard
- `docs/adr/0006-demo-level-cap-17.md` — cap rationale and extend-don't-compress
