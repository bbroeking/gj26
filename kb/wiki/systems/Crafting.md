---
type: system
tags: [crafting, cooking, alchemy, smithing, ink, stations]
status: draft
updated: 2026-06-13
sources: ["docs/wyrd-trades-recap.md", "docs/specs/45-trade-ladders-earth.md", "docs/specs/45-trade-ladders-wilds.md", "wyrd/data/crafting.gd", "wyrd/data/gather.gd", "wyrd/scripts/game.gd"]
---

# Crafting

Crafting is the transformation of gathered materials into consumables, gear, and inks at four town stations, each gated by a Trade level and rewarding XP in the station's trade.

## The four stations

All crafting routes through `Game.craft(station_id, recipe_id)` — one mutation point. Recipes are gated by `req_lv` in the station's trade.

### The Cottage Hearth (`cookfire`, Wildcraft)

Cooks heal draughts. Two herbs and a log make a bottle; higher herbs make stronger bottles. Q quaffs smallest-first, so the inventory is never depleted wastefully.

| Recipe | Req Wildcraft | Inputs | Heal | XP |
|---|---|---|---|---|
| Hearth Draught | 1 | wild_herb ×2, logs ×1 | 35 vigor | 15 |
| Bitter Draught | 4 | bittergrass ×2, wild_herb ×1, logs ×1 | 55 vigor | 22 |
| Deep Draught | 8 | wild_herb ×4, logs ×2 | 80 vigor | 35 |
| Hale Draught | 11 | mothmint ×2, wild_herb ×2, logs ×2 | 140 vigor | 45 |
| Heartsease Draught | 15 | foxglove_blue ×2, mothmint ×2, logs ×2 | 220 vigor | 60 |

(`wyrd/data/crafting.gd::DRAUGHTS`, `DRAUGHT_ORDER`)

### Quill's Still (`still`, Wildcraft)

Brews timed buff draughts. Q quaffs a buff only at full vigor, so it doesn't displace a heal. Buffs are runtime-only (not saved between sessions).

| Recipe | Req Wildcraft | Inputs | Effect | Duration |
|---|---|---|---|---|
| Quickroot Tonic | 3 | wild_herb ×3 | +25% gather speed | 90 s |
| Clearwater Philter | 6 | wild_herb ×2, palechalk ×1 | +50% focus regen | 90 s |
| Crowsfoot Cordial | 9 | crowsfoot ×2, bittergrass ×1 | +10% move speed | 90 s |
| Mothmint Mend | 12 | mothmint ×2, crowsfoot ×1 | +1 vigor/sec regen | 120 s |
| Stonebreak Tonic | 16 | stonebreak ×2, foxglove_blue ×1 | −15% damage taken (grit) | 90 s |

(`wyrd/data/crafting.gd::BUFF_DRAUGHTS`, `BUFF_DRAUGHT_ORDER`)

### Hod's Anvil (`forge`, Earthcraft)

Smelts ore into bars and smiths bars into gear. All recipes in level order; deep gear (E10+) rolls rare (three affixes). `Game.craft()` checks pack space before spending materials — a full pack is refused cleanly.

**Smelting** (material yields):
- Copper Bar (E1): copper ×2
- Bogiron Bar (E1): bogiron ×2
- Starsilver Bar (E11): starsilver ×2
- Hedgesteel Bar (E15): hedgesteel ×2, logs ×1

**Tier tools** (−30% / −45% / −55% gather channel for pickaxe/axe):
- Bogiron Pickaxe & Axe (E2): 1 bar + 1 log
- Cinderbloom Pickaxe & Axe (E7): 2 palechalk + 1 bogiron bar + 1 log
- Starsilver Pickaxe & Axe (E12): 2 starsilver bars + 1 log

**Gear** (items into Tetris pack): Shortbow (E1), Longbow (E4), Bogiron Cap/Boots/Jerkin/Ring (E5/6/8), Copper Ring (E8, magic), Palechalk Ring/Longbow/Jerkin (E9/10), Starsilver Band/Longbow (E13/14), Hedgesteel Cap/Boots (E16), Hedgesteel Warbow (E17).

The forge's economy gate: selling any smithed gear back to Hod always yields less gold than buying the inputs cost (`_test_wyrd_loop.gd::_test_economy_gate` asserts this). See [[Economy]].

### The Inscribing Table / bench pot (ink-mixing, Wayfinding)

Ink mixing is not a station recipe but a discoverable experiment (spec 43). The player loads materials into the bench pot and presses Try; an exact match mixes, and a miss resolves 60 / 30 / 10 smudge / wild ink / serendipity (adjusted to 40 / 45 / 15 with the Curious Fingers perk at carto 5). Discovering a recipe awards +50 Wayfinding XP.

Ink recipes live in `wyrd/data/gather.gd::INK_RECIPES`. Eight inks total; hedge ink is known from the start:

| Ink | Inputs | Bias |
|---|---|---|
| Hedge Ink | wild_herb ×3 | green affixes ×2 |
| Stoneground Ink | bogiron_ore ×2 | Mineral Vein ×2.5 |
| Refined Ink | hedge_ink ×2, bogiron_ore ×1 | +stability |
| Ash Ink | logs ×2, wild_herb ×1 | Wood Grove, Festival Pace |
| Chalkwash Ink | palechalk ×1, wild_herb ×2 | deep affixes |
| Mothglow Ink | mothmint ×2, hedge_ink ×1 | fog_of_hedge ×2.2, quiver ×1.8 |
| Foxglove Ink | foxglove_blue ×2, bogiron_ore ×1 | tyrannical ×2.0, frenzied/bursting ×1.8 |
| Gildleaf Ink | starsilver_ore ×1, wild_herb ×2 | gilded ×2.2, festival_pace ×1.8 |

See [[Inks]] and [[Charts]] for how inks affect affix rolls.

## Perk effects on crafting

- **Second Pour** (Wildcraft 17): 25% chance a hearth or still recipe yields a second bottle
- **Smith's Thrift** (Earthcraft 17): 25% chance a forge craft returns one raw input (never a bar — bar refunds would break the economy gate)

## See also

- [[Economy]], [[Gathering]], [[Trades and Leveling]]
- [[Wayfinding]], [[Earthcraft]], [[Wildcraft]]
- [[Inks]], [[Charts]], [[The Crafting Bench]]
- [[Items and Gear]], [[NPCs]] (Hod, Quill, Mara)

## Sources

- `wyrd/data/crafting.gd` — STATIONS, RECIPES, DRAUGHTS, BUFF_DRAUGHTS
- `wyrd/data/gather.gd` — INK_RECIPES, INK_RECIPE_ORDER
- `wyrd/scripts/game.gd` — craft(), perk_active(), Second Pour, Smith's Thrift
- `docs/specs/45-trade-ladders-wilds.md` — still recipes and brews
- `docs/specs/45-trade-ladders-earth.md` — forge recipes E10–17
