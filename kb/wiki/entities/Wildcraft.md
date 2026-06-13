---
type: entity
tags: [trade, wildcraft, herbs, cooking, alchemy, brews, perks, wilds]
status: draft
updated: 2026-06-13
sources: ["docs/wyrd-trades-recap.md", "docs/specs/45-trade-ladders-wilds.md", "docs/adr/0006-demo-level-cap-17.md", "wyrd/data/gather.gd", "wyrd/data/crafting.gd", "wyrd/scripts/game.gd"]
---

# Wildcraft

Wildcraft (code key: `wilds`) is the foraging and brewing Trade — it governs herb and log gathering, heal draught cooking at the Cottage Hearth, and buff brewing at Quill's Still, leveling on every forage, chop, and brew.

## XP and leveling

XP per action: forage herb (8–48 XP by tier), chop log (12 XP, flat), cook at the Hearth (15–60 XP by recipe), brew at the Still (20–70 XP). Shared curve (`xp_for_level`), cap 17 (ADR 0006).

## The six herb tiers

Defined in `wyrd/data/gather.gd::HERB_TIERS`. Herb names from the World Bible's locked taxonomy:

| Tier | Item | Req Wildcraft | Channel | XP | Patch name |
|---|---|---|---|---|---|
| 1 | `wild_herb` | 1 | 1.0 s | 8 | Wild Herb Patch |
| 2 | `bittergrass` | 3 | 1.2 s | 12 | Bittergrass Patch |
| 3 | `crowsfoot` | 7 | 1.5 s | 18 | Crowsfoot Patch |
| 4 | `mothmint` | 10 | 1.8 s | 26 | Mothmint Patch |
| 5 | `foxglove_blue` | 13 | 2.1 s | 36 | Foxglove Patch |
| 6 | `stonebreak` | 16 | 2.4 s | 48 | Stonebreak Patch |

Locked patches are visible and name their level. Stonebreak only exists in Summit-tier charts — it is the last herb and its tonic (grit) is intended to be brewed for the Queen fight. (`docs/specs/45-trade-ladders-wilds.md`)

> ⚠️ `docs/WORLD_BIBLE.md` lists existing forage rows (whitleberry, hedgecap, wishrose) not present in the game. `wild_herb` (id) is not in the Bible. The spec keeps `wild_herb` for the demo (tutorial-entangled) and notes the bible's rows as a post-demo 8–10-tier extension.

## The Wildcraft unlock ladder (1–17)

| Lv | Unlocks |
|---:|---|
| 1 | Wild Herb patches · log piles · Hearth Draught (cook) · hedge ink (Mara teaches) |
| 2 | — (Wayfinding carto 1–4 affixes carry early sessions) |
| 3 | **Bittergrass** · Quickroot Tonic (still) |
| 4 | **Bitter Draught** (55 vigor) |
| 5 | **Perk: Keen Eye** (+1 herb per forage) |
| 6 | Clearwater Philter (still, focus regen) |
| 7 | **Crowsfoot** |
| 8 | Deep Draught (80 vigor) |
| 9 | Crowsfoot Cordial (still, move speed) |
| 10 | **Mothmint** · **Perk: Clean Splits** (+1 log) · Mothglow Ink becomes mixable |
| 11 | Hale Draught (140 vigor) |
| 12 | Mothmint Mend (still, vigor regen) |
| 13 | **Foxglove-Blue** · **Perk: Light Hands** (−25% gather channels) · Foxglove Ink becomes mixable |
| 14 | — (carto 14 Herbal Patch affix feeds the trade) |
| 15 | Heartsease Draught (220 vigor) |
| 16 | **Stonebreak** · Stonebreak Tonic (still, grit −15% damage) |
| 17 | **Capstone perk: Second Pour** (25% chance +1 bottle from any hearth or still craft) |

"Becomes mixable" means the herb tier just unlocked provides the input; the ink itself is discovered by experimentation at the bench pot per spec 43. (`docs/specs/45-trade-ladders-wilds.md`)

## Heal draught ladder

Q quaffs smallest-first — a small scratch won't drink the good bottle. Five heals ship in the demo:

35 (Hearth) → 55 (Bitter) → 80 (Deep) → 140 (Hale) → 220 (Heartsease)

(`wyrd/data/crafting.gd::DRAUGHTS`, `DRAUGHT_ORDER`)

> ⚠️ Hale (140) and Heartsease (220) heal amounts are anchored to ×1.75 steps from Deep, not to measured Summit boss damage. `docs/specs/45-trade-ladders-notes.md` flags these as needing a balance pass against tier-3 hits before shipping.

## Quill's Still — buff brews

Buff brews are quaffed with Q at full vigor (heal priority while hurt). Buffs are runtime-only and do not save. Five brews from Wildcraft 3 to 16:

| Brew | Req | Inputs | Effect | Duration |
|---|---|---|---|---|
| Quickroot Tonic | W3 | wild_herb ×3 | +25% gather speed | 90 s |
| Clearwater Philter | W6 | wild_herb ×2, palechalk ×1 | +50% focus regen | 90 s |
| Crowsfoot Cordial | W9 | crowsfoot ×2, bittergrass ×1 | +10% move speed | 90 s |
| Mothmint Mend | W12 | mothmint ×2, crowsfoot ×1 | +1 vigor/sec regen | 120 s |
| Stonebreak Tonic | W16 | stonebreak ×2, foxglove_blue ×1 | grit: −15% damage taken | 90 s |

`vigor_regen` and `grit` are new buff stats added in spec 45; both require new plumbing (`player_controller.gd` for regen tick; damage-intake point for grit). (`wyrd/data/crafting.gd::BUFF_DRAUGHTS`)

## Discoverable inks from Wildcraft herbs

Two inks unlock when the required herb tier is reachable:

| Ink | Inputs | Bias | Riddle hint |
|---|---|---|---|
| Mothglow Ink | mothmint ×2, hedge_ink ×1 | fog_of_hedge ×2.2, quiver ×1.8 | `still` |
| Foxglove Ink | foxglove_blue ×2, bogiron_ore ×1 | tyrannical ×2.0, frenzied/bursting ×1.8 | `forge` |

(`wyrd/data/gather.gd::INK_RECIPES`) Foxglove Ink requires a bogiron ore — Earthcraft feeding a Wildcraft recipe, feeding Wayfinding's charts.

## Perks

All four perks in `PERKS["wilds"]` (`wyrd/scripts/game.gd`):

| Lv | Id | Name | Effect |
|---:|---|---|---|
| 5 | `keen_eye` | Keen Eye | +1 herb on every forage (deterministic) |
| 10 | `clean_splits` | Clean Splits | +1 log on every chop |
| 13 | `light_hands` | Light Hands | Forage and chop channels −25% |
| 17 | `second_pour` | Second Pour | 25% chance any hearth or still craft pours a second bottle |

## See also

- [[Trades and Leveling]], [[Gathering]], [[Crafting]], [[Economy]]
- [[Earthcraft]] (logs feed deep smithing; bogiron in Foxglove Ink)
- [[Wayfinding]] (herbs → inks → charts)
- [[Inks]], [[NPCs]] (Quill the Herbalist, Mara Linnet)
- [[Gather Nodes]]

## Sources

- `docs/specs/45-trade-ladders-wilds.md` — complete ladder design, herb tiers, brew tables
- `docs/wyrd-trades-recap.md` — code-grounded state (Cottage Hearth, perk list)
- `wyrd/data/gather.gd` — HERB_TIERS, MATERIALS, INK_RECIPES
- `wyrd/data/crafting.gd` — RECIPES (draughts), BUFF_DRAUGHTS, STATIONS
- `wyrd/scripts/game.gd` — PERKS["wilds"], Second Pour in craft(), quaff logic
