# ADR 0012 — Compress the four trades into one skill (Wayfinding)

**Status:** Accepted (2026-06-14). **Supersedes ADR 0005** (Huntcraft as a
separate combat trade); amends the four-trade framing of ADR 0003 and ADR 0006.

## Context

The cozy-skilling spine (ADR 0003) shipped as **four** leveling trades —
Wayfinding (carto), Earthcraft, Wildcraft, and Huntcraft (the combat trade,
ADR 0005) — each with its own level, XP, and perk ladder (capped at 17,
ADR 0006). Four parallel progression bars added cognitive load, fragmented the
perk choices, and made combat (Huntcraft) a primary, always-on XP faucet that
risked out-pacing the cozy gather/craft faucets (flagged in the gap analysis).

## Decision

Compress the four trades into **one** leveling skill, **Wayfinding**:

- **One level, one XP pool** (still capped at 17, ADR 0006). Every cozy activity
  — gathering, crafting, foraging, charting — feeds the single skill.
- **One unified perk ladder.** The 19 former per-trade perks now live under the
  single skill, unlocked by its level. (Pick-one-of-N mastery is a planned refinement.)
- **Combat gives NO skill XP.** The bow is the verb; killing things awards zero
  skill XP — you level only by skilling. This keeps the spine the spine (ADR 0003)
  and removes the Huntcraft-out-faucets-gathering risk. The **Even Breath** perk
  still refunds Focus on a kill (a perk effect, not XP); co-op `kill_credit` still
  routes that Focus refund to the killer.

Implementation: `trade_lv` / `award_xp` / `perk_active` ignore the trade-key
argument and operate on the one skill (`SKILL := "wayfinding"`), so the ~25 call
sites that still pass `"carto"`/`"earth"`/`"wilds"`/`"hunt"` keep working
unchanged. Legacy four-trade saves migrate by summing their XP into the single
skill and recomputing the level.

## Consequences

- One progression number; one perk ladder; the Trades page shows a single skill.
- Combat is purely the reading-and-response verb — gear gives no power (ADR 0010)
  and now combat also grants no XP. Seasoning, never a second progression track.
- The `SKILL_REQS` that gated the hunting skills (HuntersMark/HeartwoodWard/
  MercyShot at 4/7/9) now gate on the single Wayfinding level.
- KB docs describing four trades (the Trades & Leveling design, the four trade
  entity pages, the Universe plan, the interlock map) are updated/flagged to the
  single skill.
- **Open:** pick-one-of-N mastery for the unified ladder.

## Alternatives considered

- **Keep four trades** (status quo) — rejected: cognitive load + combat-as-faucet.
- **One level, activity-themed perk picks** — considered; chose the single unified
  ladder for simplicity (the user's call).
