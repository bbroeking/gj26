---
type: source
tags: [trades, leveling, gathering, crafting, economy, earthcraft, wildcraft, wayfinding, huntcraft]
status: draft
updated: 2026-06-13
sources: ["docs/wyrd-trades-recap.md", "docs/specs/45-trade-ladders-carto.md", "docs/specs/45-trade-ladders-earth.md", "docs/specs/45-trade-ladders-wilds.md", "docs/specs/45-trade-ladders-hunt.md", "docs/specs/45-trade-ladders-notes.md", "docs/cartography-progression.md", "docs/adr/0005-huntcraft-single-combat-trade.md", "docs/adr/0006-demo-level-cap-17.md", "docs/game-balance-playbook.md"]
---

# Source digest — Trades cluster

This file records which raw sources were read for the trades cluster, a one-line summary of each, and which wiki pages they fed.

## Sources read

| Source | Summary | Wiki pages fed |
|---|---|---|
| `docs/wyrd-trades-recap.md` | Authoritative code-grounded state of the trade system as of 2026-06-10; XP formula, three shipped trades (carto/earth/wilds), channel gathering, perks, the Wayfinder loop, economy touchpoints, and stale-doc audit | [[Trades and Leveling]], [[Gathering]], [[Crafting]], [[Economy]], [[Wayfinding]], [[Earthcraft]], [[Wildcraft]] |
| `docs/specs/45-trade-ladders-carto.md` | Full audit of Wayfinding 1–17: three dead holes (2/3/17) identified and filled, perk ladder designed (6 perks), XP pacing math (≈15–17 runs to cap), open questions on boss-den unenforced gate | [[Wayfinding]], [[Trades and Leveling]] |
| `docs/specs/45-trade-ladders-earth.md` | Earthcraft 1–17: two new ore tiers (starsilver E11, hedgesteel E15), 10 new forge recipes, 4 new item kinds, 2 new perks, economy-gate proof table for all new recipes | [[Earthcraft]], [[Gathering]], [[Crafting]], [[Economy]] |
| `docs/specs/45-trade-ladders-wilds.md` | Wildcraft 1–17: 6 herb tiers (World Bible names), 5-bottle heal ladder, Quill's Still deep shelf (3 brews), 2 discoverable inks (Mothglow/Foxglove), 2 new perks, dungeon tier-mix tables | [[Wildcraft]], [[Gathering]], [[Crafting]] |
| `docs/specs/45-trade-ladders-hunt.md` | Huntcraft 11–17: 3 new perks (Quick Nock H12, Heavy Draw H14, Even Breath H17 capstone), no new skill gates above 9 (argued), XP-pacing math vs Summit timeline, Driving Volley rejected alternative | [[Huntcraft]], [[Trades and Leveling]] |
| `docs/specs/45-trade-ladders-notes.md` | Integration-pass implementation notes: Gildleaf Ink added (stitch), cap clamp landed, Practiced Measures definition, tier plumbing generalized minimally, surprises (RNG reshuffle from new tier rolls) | [[Wayfinding]], [[Wildcraft]], [[Earthcraft]], [[Crafting]] |
| `docs/cartography-progression.md` | Pre-Godot Lv 1–99 cartography unlock table (three.js prototype scale). Superseded by 1–17 design. Mined for perk ideas (Practiced Measures from Lv 25; Atlas Press → Master Wayfinder). | [[Wayfinding]] |
| `docs/adr/0005-huntcraft-single-combat-trade.md` | Decision 2026-06-12: one combat trade (not atk/str/def split); kill XP `max(2, hp_max/3)` formula; migration notes for old saves; when to revisit (if melee/magic families land). | [[Huntcraft]], [[Trades and Leveling]], [[Design Decisions]] |
| `docs/adr/0006-demo-level-cap-17.md` | Decision 2026-06-12: cap at 17 (Summit req 16 + 1), extend other ladders, don't compress Wayfinding. XP curve unchanged; cap enforced at award time; post-demo cap lifts won't lose banked XP. | [[Trades and Leveling]], [[Wayfinding]], [[Earthcraft]], [[Wildcraft]], [[Huntcraft]], [[Design Decisions]] |
| `docs/game-balance-playbook.md` | Broad balance theory (Sirlin's fairness/viability/pacing) + gj26-specific recommendations: subtractive damage formula, cozy TTK 5–15 s trivial, linear tier scaling, no-telemetry balance via math + friends. | [[Economy]], [[Combat]] |

## Code files read

| File | What was extracted | Used in |
|---|---|---|
| `wyrd/scripts/game.gd` | PERKS (all 4 trades, all perks), LEVEL_CAP, xp_for_level, award_xp, TRADE_NAMES, SKILL_REQS, craft(), Second Pour, Smith's Thrift | All trade pages |
| `wyrd/data/gather.gd` | MATERIALS, NODE_KINDS, ORE_TIERS, HERB_TIERS, ORE_ROLLS_BY_TIER, FORAGE_ROLLS_BY_TIER, INK_RECIPES, INK_RECIPE_ORDER | [[Gathering]], [[Wayfinding]], [[Earthcraft]], [[Wildcraft]] |
| `wyrd/data/crafting.gd` | STATIONS (cookfire/still/forge), RECIPES (full list E1–17, W1–17), DRAUGHTS, DRAUGHT_ORDER, BUFF_DRAUGHTS, BUFF_DRAUGHT_ORDER | [[Crafting]], [[Wildcraft]], [[Earthcraft]] |
| `wyrd/data/economy.gd` | SELL_BY_RARITY, WARES | [[Economy]] |

## Contradictions and flags

1. **Boss-den `req_carto` is unenforced (dead data).** `wyrd/data/charts.gd` carries `req_carto: 8/12/14` on den entries; `socket_trophy` checks only trophy possession, not level. Flagged on [[Wayfinding]] page. (`docs/specs/45-trade-ladders-carto.md` Finding F2)

2. **Palechalk World Bible drift.** The World Bible lists palechalk as a tier-1 ore (tin analog). The game uses it as the E7 deep ore. Intentional; spec 45-earth explicitly follows the game and climbs the bible ladder for new names. Flagged on [[Earthcraft]] page.

3. **`wild_herb` not in World Bible.** The bible's forage rows (whitleberry, hedgecap, wishrose) are absent from the game. `wild_herb` is the tutorial-entangled tier-1 herb; bible names reserved for the post-demo 8–10-tier extension. Flagged on [[Wildcraft]] page.

4. **Hale/Heartsease heal numbers not playtested.** 140 and 220 vigor heals are anchored to ×1.75 steps from Deep (80), not to measured Summit damage. `docs/specs/45-trade-ladders-notes.md` explicitly flags these as needing a balance pass. Flagged on [[Wildcraft]] page.

5. **`cartography-progression.md` is superseded scale.** The Lv 1–99 unlock table and `src/ui/worldMap.js` references are the three.js prototype's design. Not current; flagged on [[Wayfinding]] page.

6. **Cap enforcement not present at conversation start.** `docs/specs/45-trade-ladders-hunt.md` Q1 asks which spec owns the `lv 17` guard. As of `45-trade-ladders-notes.md` it is confirmed shipped: `LEVEL_CAP := 17` in `game.gd` with a loop guard in `award_xp`.

## See also

- [[Trades and Leveling]], [[Gathering]], [[Crafting]], [[Economy]]
- [[Wayfinding]], [[Earthcraft]], [[Wildcraft]], [[Huntcraft]]
- [[Design Decisions]]
