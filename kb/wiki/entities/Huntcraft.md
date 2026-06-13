---
type: entity
tags: [trade, huntcraft, combat, kills, perks, hunt]
status: draft
updated: 2026-06-13
sources: ["docs/adr/0005-huntcraft-single-combat-trade.md", "docs/specs/45-trade-ladders-hunt.md", "docs/adr/0006-demo-level-cap-17.md", "wyrd/scripts/game.gd"]
---

# Huntcraft

Huntcraft (code key: `hunt`) is the single combat Trade — the persistent ledger for the kill verb, decided by ADR 0005 on 2026-06-12 as one trade, not three.

## Identity (ADR 0005)

Combat is one verb among many (ADR 0003: cozy-skilling is the spine). Before ADR 0005, combat fed nothing persistent; kills already dropped trophies but the moment-to-moment fight had no progression voice. One trade gives the kill verb a ledger without making it the spine. Four rows on the Trades page stays readable; three rows (attack/strength/defence) would be a stat screen with no added decision.

> "Huntcraft's perks feed back into *how you fight*, not how much you must." — ADR 0005

Huntcraft splits only if melee/magic weapon families ever land (creating genuine training choices). Not before.

## XP per kill

Kill XP formula (`wyrd/scripts/combatant.gd`, per ADR 0005): `max(2, int(hp_max / 3))`.

Per enemy type (from `layout_loader.gd::ENEMY_KINDS` and `BOSS_KINDS`):

| Enemy | hp_max | XP/kill |
|---|---:|---:|
| skitterling | 7 | 2 (floor) |
| rat | 10 | 3 |
| bramble_imp | 12 | 4 |
| ghost | 14 | 4 |
| skeleton | 18 | 6 |
| hedge_sprite | 22 | 7 |
| elite | 23–33 | 7–11 |
| wolf_alpha | 55 | 18 |
| hedgemother | 60 | 20 |
| burrow_boar | 80 | 26 |
| Hedgemother Queen (Summit) | 160 | 53 |

Weighted average per trash kill: snug ≈ 3.9, hollow ≈ 4.7, crypt ≈ 5.0 XP. A full-clear tier-2 Hollow (~35–40 trash kills) yields ≈ 180–190 Huntcraft XP plus boss margin. (`docs/specs/45-trade-ladders-hunt.md` § XP pacing)

The Tyrannical affix (+50% enemy HP) scales kill XP ×1.5 → ~280 XP/run; Tyrannical + Festival Pace → ~420 XP/run. Chart affixes are the Huntcraft training dial — the chart loop trains the combat trade.

## Skill gates (1–9, unchanged)

Three skill gates exist from ship; the teaching arc is complete at H9. No skill gates above 9 are planned for the demo (ADR 0005 argument: 9 skills for 3 slots = 84 combinations; adding a 10th raises option count without decision quality). Hotbar skills are listed under [[Skills]].

| Gate | Skill unlocked |
|---|---|
| H4 | HuntersMark |
| H7 | HeartwoodWard |
| H9 | MercyShot |

## The perk ladder (1–17)

Five perks across the full demo ladder; levels 11/13/15/16 are intentionally quiet (kills are a constant drip — Huntcraft doesn't need a ping every level, it needs a few audible changes).

| Lv | Id | Name | Effect |
|---:|---|---|---|
| 5 | `steady_hands` | Steady Hands | +5% crit chance |
| 10 | `hunters_stride` | Hunter's Stride | +5% move speed |
| 12 | `quick_nock` | Quick Nock | +10% skill cooldown recovery (CDR cap 0.80) |
| 14 | `heavy_draw` | Heavy Draw | +25% crit damage (crits ×2.25, supers ×3.25) |
| 17 | `even_breath` | Even Breath | Every kill returns 6 Focus |

(`wyrd/scripts/game.gd::PERKS["hunt"]`, `docs/specs/45-trade-ladders-hunt.md`)

**Quick Nock** changes rotation cadence (BrambleSnare every 3.64 s instead of 4.0). **Heavy Draw** makes the crit line (Steady Hands → HuntersMark → MercyShot) a real spike build. Both reshape decisions without inflating raw numbers.

## Capstone: Even Breath (H17)

Every kill returns 6 Focus. Focus pool is 50; in-combat regen is 3/s. One kill = two seconds of combat regen; a 5-kill room = a free PowerShot + HuntersMark. "Kill → cast → kill" — the hunt funds itself.

The perk is loadout-agnostic (all 84 combinations benefit, unlike a mark-spread perk that would be dead weight for two-thirds of loadouts). It does nothing in a boss fight except on the kill itself. Boss-fight focus economy has other owners (Echoing Steps affix, Clearwater Philter). (`docs/specs/45-trade-ladders-hunt.md` § Capstone)

Implementation: `combatant.gd::_die()` next to the existing `award_xp("hunt", …)` block, and a new `add_focus(amount)` helper in `player_controller.gd`. (~8 lines across 2 files)

## XP pacing to the demo cap

| Target | Total XP | Plain full clears (÷180) | Tyrannical charts (÷280) |
|---|---:|---:|---:|
| H10 (shipped top) | 936 | ~5 | ~3.5 |
| H14 | 1768 | ~10 | ~6.5 |
| H17 (cap) | 2560 | ~14 | ~9 |

Sanity check: Wayfinding needs ~10–11 runs to reach carto 16. A player doing the full-clear runs the trophy chain demands banks ~1,800–2,400 Hunt XP by Summit time — H15–16 at the Summit gate, H17 within a run or two after. The Queen alone pays 53 XP. The capstone lands right at the demo's crescendo. (`docs/specs/45-trade-ladders-hunt.md` § XP pacing)

**Contingency (pre-tuned, playtest-gated):** if median playtesters reach the Summit below H14, change the XP formula divisor from `/3` to `/2` (one line in `combatant.gd:671`), boosting hollow average to ~7.3 XP/kill and ~9 plain clears to H17. The shared curve and other trade pacing are unaffected.

## The rejected alternative: Driving Volley (H12, post-demo)

A displacement skill — 5-arrow fan that shoves the pack back — was fully specced and rejected for the demo (Thornburst already owns the panic slot; two panic buttons in a 3-slot loadout cannibalize each other). Documented in `docs/specs/45-trade-ladders-hunt.md` § Rejected alternative.

## See also

- [[Trades and Leveling]], [[Combat]], [[Skills]]
- [[Wayfinding]] (Tyrannical/Festival Pace are the Huntcraft training dials)
- [[Bosses]], [[Enemies]]
- [[Design Decisions]]

## Sources

- `docs/adr/0005-huntcraft-single-combat-trade.md` — one trade decision, kill formula
- `docs/specs/45-trade-ladders-hunt.md` — full perk design, XP math, contingency
- `docs/adr/0006-demo-level-cap-17.md` — cap and extend rationale
- `wyrd/scripts/game.gd` — PERKS["hunt"], SKILL_REQS, SKILL_POOL
