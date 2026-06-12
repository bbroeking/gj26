# Combat XP feeds ONE trade (Huntcraft), not an OSRS stat block

B7 on the build plan asked whether combat should grant trade XP. The
three.js prototype's model (awardCombatXp → attack/strength/defence)
would add three combat trades; the plan's risk table flagged that this
turns the Trades page into a stat screen and dilutes the three-trade
identity — ADR 0003 says cozy skilling is the spine and combat is one
verb among many.

**Decision (2026-06-12): one combat trade — Huntcraft (`hunt`).**
Kills feed it (XP scaled to the slain thing's vigor: `max(2, hp_max/3)`),
it levels on the shared curve, and it carries perks like the other
trades: **Steady Hands** (Hunt 5, +5% crit chance) and **Hunter's
Stride** (Hunt 10, +5% move speed). It appears as a fourth professions
row on the Trades page.

Why one and not zero: kills already drop trophies/essence, but moment-to-
moment combat fed nothing persistent — a whole verb with no progression
voice. One trade gives combat a ledger without making it the spine: four
rows total keeps the page readable, and Huntcraft's perks feed back into
*how you fight*, not how much you must.

Why not three: attack/strength/defence triples the page's combat surface
for zero added decisions (you don't choose which to train — everything
trains together with one damage type). That's stat-screen weight with no
gameplay.

## Migration

Old saves lack the `hunt` key; `SaveGame.load_into` backfills it at
lv 1 / 0 xp.

## When to revisit

If melee/magic weapon families ever land (multiple damage types =
genuine training choices), revisit splitting Huntcraft. Not before.
