# Demo level cap is 17 — extend the other ladders, don't compress Wayfinding

The demo needs a level cap so every Trade can ship a *complete* unlock
ladder. Two options were on the table once the cap idea landed:

1. **Cap at 10 and compress Wayfinding** — re-level the chart templates,
   affixes, and boss dens (today spread 1–16, Summit at 16) down into
   1–10 so the trophy chain still ends inside the cap.
2. **Cap at 17 and extend everyone else** — leave Wayfinding's shipped,
   tested, balance-tuned ladder untouched (the Summit stays the level-16
   capstone) and build Earthcraft / Wildcraft / Huntcraft up to match.

**Decision (2026-06-12): cap 17, extend the others.**

Wayfinding's spread is the product of the whole chart-loop balancing
arc — boss dens at 8/12/14, fifteen rollable affixes interleaved so
most level-ups unlock something. Compressing it would stack multiple
unlocks per level, force re-testing the trophy chain, and squeeze out
the "every level matters" pacing for the trade that IS the game's
spine. Extending the other three trades is additive data work in
existing table shapes (ORE_TIERS, RECIPES, PERKS, INK_RECIPES) with no
re-balancing of shipped content.

The cap itself: 17 = the Summit's req (16) + 1, so the capstone is
reached one level before the ceiling and the last level-up is felt.

## Consequences

- Every Trade's ladder gets built out to 17 (specs 45-*): Earthcraft
  ore tiers + recipes above 9, the Wildcraft herb ladder (6 tiers at
  W1/3/7/10/13/16), Huntcraft perks/gates above 10.
- The long-term vision (8–10 herb tiers, deeper everything) extends the
  same tables past 17 after the demo; nothing decided here blocks it.
- XP curve is unchanged; the cap is enforced at award time.

## When to revisit

Post-demo, when the cap lifts. The relative ORDER inside each ladder is
the durable part; the absolute numbers can stretch.
