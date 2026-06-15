# ADR 0010 — Gear is frozen at zero combat power

**Status:** Accepted (2026-06-14)
**Supersedes nothing. Linchpin of the Tier-0 build (see `kb/wiki/Gap Analysis and Build Plan.md`).**

## Context

Wayfinder's doctrine (ADR 0003 cozy-skilling spine; the Universe Build-Out Plan;
the 15 deep-system designs) is that **combat is one verb — the bow — deepened
only by reading the fight, never by a bigger weapon or a higher gear tier.**
Itemization is meant to be the trophy-**Ledger**: small, flat, capped,
*horizontal* boons.

The shipped build contradicts this. It ships a full ARPG weapon/gear ladder:

- weapon tiers `shortbow → longbow → warbow` (+ palechalk/starsilver bows) with
  rising base damage (6 → 8 → 11) — `data/items.gd`;
- rolled magic/rare prefix/suffix affixes that add combat power — `data/affixes.gd`
  (sharp/heavy/of_fury → damage, swift → fire_rate, fierce/of_precision →
  crit_chance, of_carnage → crit_mult, of_swiftness → cooldown_reduction);
- `player_controller._derive_stats()` folds every equipped item's
  `base_stat`/`base_value` **and** its rolled affixes into the live combat
  stats — so a "Swift Warbow of Fury" literally out-damages and out-fires the
  base bow;
- a smithing treadmill in `data/crafting.gd`, and `test_wyrd_loop.gd:342`
  asserting the forge "carries the full gear ladder".

The red-team flagged this as **the linchpin**: every downstream itemization
decision (the Ledger, the dissolve-to-ink sink, the no-arbitrage economy) is
built on whether this ladder confers power.

## Decision

**Freeze gear at zero combat power (option b).** Equipped items keep existing —
slots, inventory, the dissolve-to-ink sink, and the future trophy-Ledger seam —
but contribute **zero** to the five offensive combat stats:
`damage, crit_chance, crit_mult, fire_rate, cooldown_reduction`.

Implementation: a single filter in the `_derive_stats()` equipment loop skips
those five stats for both an item's `base_stat` and its rolled affixes.

Scope — what is **unchanged**:

- **Equipped gear only.** One filter; no data deleted.
- **HP from armor is retained** (survival, not a DPS treadmill): helm/chest/boots
  and hp affixes still raise `hp_max`.
- **move_speed from gear is retained for now** (`of_haste`) as mobility QoL —
  *open question, revisitable* (see below).
- **Huntcraft perks, shrine/spec-29 buffs, and chart affixes are UNTOUCHED.**
  They feed the same `sums` dict by separate paths and remain live. Shrines are
  run-scoped temporary buffs, not a gear treadmill, and are out of scope here.
- **The trophy-Ledger** becomes the *only* item path that touches combat power,
  and it is flat / capped / horizontal (its own ADR to come).
- The affix and weapon **data is kept** — items still show their rolled affixes
  in tooltips and the forge ladder still exists as craftable content; the stats
  simply never reach `derived_stats`.

We chose (b) over **(a) remove the ladder** to avoid ripping out shipped, tested
content (smithing recipes, affix roll tables, the equip/inventory system) and to
keep a home for cosmetic/slot items and the Ledger.

## Consequences

- `derived_stats.damage` floor is exactly `6`, `crit_chance` `0.20`, etc., before
  perks/shrines — combat power no longer comes from loot.
- Loot stays meaningful via the Ledger (flat boons), the dissolve-to-ink sink,
  and cosmetic/slot value — never raw DPS.
- `test_wyrd_loop.gd:342` is **unchanged** (it counts forge *recipes*, which still
  exist); the economy no-arbitrage gate is unchanged (gold prices, not stats).
- `test_stats.gd` S2/S3/S4 (which asserted equip → higher damage/crit) are
  rewritten to the freeze invariant, plus added GF1–GF4 invariant checks.
- **Open question:** whether `move_speed` from gear should also be frozen
  (currently kept as mobility QoL).

## Alternatives considered

- **(a) Remove the weapon tiers + combat affixes.** Cleanest doctrinally but
  deletes shipped/tested content and the affix system — rejected as higher-churn.
