---
type: system
tags: [trades, progression, leveling, xp, perks]
status: draft
updated: 2026-06-13
sources: ["docs/wyrd-trades-recap.md", "docs/specs/45-trade-ladders-carto.md", "docs/specs/45-trade-ladders-earth.md", "docs/specs/45-trade-ladders-wilds.md", "docs/specs/45-trade-ladders-hunt.md", "docs/adr/0006-demo-level-cap-17.md", "wyrd/scripts/game.gd"]
---

# Trades and Leveling

A Trade is a leveling discipline — the four named progressions (Wayfinding, Earthcraft, Wildcraft, Huntcraft) that reward every verb in the game and are viewed on the **Trades page (K)**.

## The four trades

| Trade | Code key | XP source | Feeds |
|---|---|---|---|
| [[Wayfinding]] | `carto` | Chart completion, ink discovery (+50), pot smudge (+5) | Chart templates, affixes, ink perks |
| [[Earthcraft]] | `earth` | Mining ore (6–42 xp/harvest by tier) | Forge recipes, ore tiers, smith perks |
| [[Wildcraft]] | `wilds` | Foraging herbs (8–48 xp), chopping logs (12 xp), cooking/brewing | Heal draughts, buff brews, herb tiers |
| [[Huntcraft]] | `hunt` | Kills: `max(2, hp_max / 3)` | Combat perks (Steady Hands…Even Breath) |

"Skill" is a reserved word for hotbar abilities (Bow, Power Shot, etc.) — never a synonym for Trade (`wyrd/scripts/game.gd`, CONTEXT.md).

## The XP curve (shared)

All four trades share one formula (`game.gd::xp_for_level`):

```
xp_for_level(n) = (n-1)² × 8 + (n-1) × 32
```

Key thresholds: Lv 2 = 40 XP · Lv 5 = 256 · Lv 10 = 936 · Lv 16 = 2280 · Lv 17 = 2560.

The step between levels grows linearly: `16n + 24` XP per additional level, so Lv 1→2 costs 40 and Lv 16→17 costs 280. The curve is faster than OSRS at these scales and is intentionally not grindy: a full-clear tier-2 Hollow run yields ~180 Wayfinding XP and ~180+ Huntcraft XP in the same session.

## The demo level cap (ADR 0006)

The cap is **17**, enforced in `game.gd::LEVEL_CAP := 17`. The level-up loop stops at 17 but XP continues to accrue — post-demo cap lifts will not discard banked progress. The cap was chosen as Summit-level (16) + 1 so the final level-up is felt at or just after the endgame clear.

See [[Design Decisions]] for the full ADR rationale (cap 17 vs cap 10).

## Perks

Each trade unlocks perks at specific levels; they appear on the Trades page automatically. Code source: `PERKS` dict in `wyrd/scripts/game.gd`.

**Wayfinding:** Mara's Marginalia (2) · Practiced Measures (3) · Curious Fingers (5) · Sure Lines (10) · Thrifty Quill (14) · Master Wayfinder (17)

**Earthcraft:** Sturdy Swings (5) · Miner's Rhythm (10) · Rich Seams (13) · Smith's Thrift (17)

**Wildcraft:** Keen Eye (5) · Clean Splits (10) · Light Hands (13) · Second Pour (17)

**Huntcraft:** Steady Hands (5) · Hunter's Stride (10) · Quick Nock (12) · Heavy Draw (14) · Even Breath (17)

`perk_active(trade, id)` gates all perk effects — it checks `trade_lv(trade) >= perk.lv`.

## The Trades page (K)

Opened with the K key, the Trades page renders each trade's ladder: levels, template/affix/recipe unlocks, and perk rows. The panel reads generically from `Game.PERKS`, so new perk entries appear automatically without UI code changes.

## Identity (ADR 0003)

Cozy-skilling is the spine; the four trades express its verbs. [[Wayfinding]] is the differentiator — the other three trades exist to feed it with materials, sustain, and combat capability. The complete loop is: gather (Earthcraft/Wildcraft) → craft ink → inscribe [[Charts]] → clear dungeon → completion XP + materials → better charts.

## See also

- [[Wayfinding]], [[Earthcraft]], [[Wildcraft]], [[Huntcraft]]
- [[Chart Loop]], [[Gathering]], [[Crafting]], [[Economy]]
- [[Skills]] (hotbar abilities — distinct from Trades)
- [[Design Decisions]]

## Sources

- `docs/wyrd-trades-recap.md` — authoritative code-grounded state as of 2026-06-10
- `docs/adr/0006-demo-level-cap-17.md` — the cap-17 decision
- `wyrd/scripts/game.gd` — `PERKS`, `LEVEL_CAP`, `xp_for_level`, `award_xp`
