---
type: entity
tags: [trade, wayfinding, cartography, charts, inks, perks, carto]
status: draft
updated: 2026-06-13
sources: ["docs/wyrd-trades-recap.md", "docs/specs/45-trade-ladders-carto.md", "docs/cartography-progression.md", "docs/adr/0006-demo-level-cap-17.md", "wyrd/data/charts.gd", "wyrd/scripts/game.gd"]
---

# Wayfinding

Wayfinding (code key: `carto`) is the cartography Trade — the differentiating discipline of Bramblewood that unlocks chart templates, affixes, ink perks, and ultimately the Chart of the Summit.

## Identity

Wayfinding is the game's spine (ADR 0003). The other three trades exist to feed it with materials and sustain; the Wayfinder loop is: gather → mix ink → inscribe chart → clear dungeon → completion XP → better charts. Everything eventually flows through the inscribing table and the waystone.

## XP sources

Three sources earn Wayfinding XP:
1. **Chart completion** — paid at the exit waystone, not at inscription: `tier × 75 + good_affixes × 40 + bad_affixes × 10`. A Tyrannical good affix multiplies chart completion XP by ×1.3.
2. **Ink recipe discovery** — +50 XP the first time each ink recipe is found at the bench pot (4 discoverable inks × 50 = up to 200 XP one-time money).
3. **Pot smudge** — +5 XP per failed pot experiment (tiny, but "failing at the bench teaches").

Inscription itself pays nothing — completion-only keeps the "charts are promises kept" framing and prevents inscribe-and-discard farming. (`docs/specs/45-trade-ladders-carto.md` § Open Q4)

## The unlock ladder (1–17)

The existing 1–16 spread is untouched per ADR 0006; levels 2, 3, and 17 receive fills. Boss-den `req_carto` (8/12/14) is currently unenforced dead data — the trophy chain gates dens in practice (`docs/specs/45-trade-ladders-carto.md` Finding F2).

> ⚠️ `wyrd/data/charts.gd` carries `req_carto` fields on den entries (8/12/14) that `socket_trophy` does not read as of 2026-06-13. The de-facto gate is trophy possession only.

| Lv | Unlocks |
|---:|---|
| 1 | Snug + Tier 1 Hollow templates · Mineral Vein |
| 2 | Mara's Marginalia (bench QoL: codex shows all riddles) |
| 3 | Practiced Measures (click a known codex row → pot fills its makings) |
| 4 | Bramble Bloom |
| 5 | Tyrannical · **Perk: Curious Fingers** |
| 6 | Sprinting Things |
| 7 | Wood Grove · Festival Pace |
| 8 | Quiver |
| 9 | Gilded Hollow |
| 10 | **Hollow template** · Fog of Hedge · **Perk: Sure Lines** |
| 11 | Frenzied |
| 12 | Bursting |
| 13 | Wellspring |
| 14 | Herbal Patch · **Perk: Thrifty Quill** |
| 15 | **Briar Maze template** · Echoing Steps |
| 16 | **Chart of the Summit** · Marked Quarry |
| 17 | **Capstone: Master Wayfinder** (+1 ink slot on every chart that takes ink) |

## Perk ladder

All six perks live in `PERKS["carto"]` in `wyrd/scripts/game.gd` and appear on the Trades page (K) automatically.

| Lv | Perk | Effect |
|---:|---|---|
| 2 | Mara's Marginalia | Codex shows every recipe riddle (bypasses `seen_hints` gate) |
| 3 | Practiced Measures | Click a known ink in the codex → pot fills with its exact makings (claims, doesn't brew) |
| 5 | Curious Fingers | Pot miss resolves 40 / 45 / 15 smudge / wild ink / serendipity (was 60 / 30 / 10) |
| 10 | Sure Lines | Every affix roll +5 percentage points toward its good twin (stacks with inks; 95% cap) |
| 14 | Thrifty Quill | Each chart costs 1 less hedge ink (floor: 1; Tier 1: 2→1, Hollow/Briar: 3→2, Summit: 4→3) |
| 17 | Master Wayfinder | Every chart that takes ink holds one additional ink slot (Tier 1: 2→3, Hollow/Briar: 3→4) |

## Ink slots and stability

Charts have ink slots set per template. Slotted inks bias affix rolls; stability decides the good-vs-bad twin: `min(95, base_stability + carto_lv × 0.6 + ink_bonus × 100)`. At carto 10 a Sure Lines-boosted chart has +5 points over the raw formula; at carto 17 an extra slot can add up to +40 more stability. See [[Inks]] and [[Charts]].

## XP pacing math

From `docs/specs/45-trade-ladders-carto.md`:
- Lv 1→10: ~7–8 tier-1 runs (including ~200 XP of one-time ink discovery money).
- Lv 10→16: ~6–7 tier-2 runs at ~210 XP/run.
- Lv 16→17: 1–2 more runs (280 XP step; Summit clear alone pays 225).
- Total to cap: approximately 15–17 runs. Not grindy.

## Pre-Godot ladder (superseded scale)

`docs/cartography-progression.md` describes a Lv 1–99 ladder with 40 specialty unlocks (Lv 25 auto-arrange, Lv 80 Atlas Press re-roll, Lv 99 Grand Cartographer title). This document describes the three.js prototype's scale — superseded by the demo's 1–17 design. The ideas are mined for the demo's perk ladder (Practiced Measures rescoped from Lv 25; capstone borrows from Atlas Press).

> ⚠️ `docs/cartography-progression.md` targets a Lv 1–99 scale and references three.js code (`src/ui/worldMap.js`). It is design history, not the current game.

## See also

- [[Trades and Leveling]], [[Chart Loop]], [[Charts]], [[Affixes]], [[Inks]]
- [[The Crafting Bench]], [[The Waystone]]
- [[Earthcraft]], [[Wildcraft]] (feed Wayfinding materials)

## Sources

- `docs/specs/45-trade-ladders-carto.md` — full 1–17 audit, perk design, XP math
- `docs/wyrd-trades-recap.md` — code-grounded state 2026-06-10
- `wyrd/scripts/game.gd` — PERKS["carto"], xp_for_level, try_pot_mix
- `wyrd/data/charts.gd` — TEMPLATES, AFFIXES
- `docs/adr/0006-demo-level-cap-17.md` — cap rationale, don't compress Wayfinding
