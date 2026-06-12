# 45 — Trade Ladders: Wayfinding (carto) 1→17 audit

> **Outcome**: Wayfinding's 1–17 ladder is audited against ADR 0006; the
> three dead levels (2, 3, 17) get small additive fills, the trade gains a
> perk ladder to match Earthcraft/Wildcraft/Huntcraft, and level 17 has a
> capstone. Nothing existing moves.

Per ADR 0006: demo cap is 17, the Summit stays the level-16 capstone, and
Wayfinding's existing spread is **untouched**. This spec is additive only.

## Ground truth (audited 2026-06-12)

- **Templates** (`wyrd/data/charts.gd` TEMPLATES): req_carto 1 (snug,
  tier_1), 10 (hollow), 15 (briar_maze), 16 (summit).
- **Rollable affixes** (AFFIXES, 15 of them): req_carto 1, 4, 5, 6, 7, 7,
  8, 9, 10, 11, 12, 13, 14, 15, 16 — interleaved so most levels ping.
- **Boss dens** (3): req_carto 8 / 12 / 14 — but see Finding F2; these
  values are currently *dead data*.
- **Perks** (`wyrd/scripts/game.gd` PERKS): earth, wilds, hunt each have
  2 perks at 5/10. **carto has none.** The Trades page
  (`inventory_panel.gd::_trade_unlock_rows`) renders perks generically
  from `Game.PERKS`, so new carto perks appear in the ladder UI for free.
- **Carto XP sources** (exactly three): chart completion
  (`game.gd::return_to_town` → `Charts.completion_xp`), ink-recipe
  discovery +50 (`discover_ink`), pot-miss smudge +5 (`try_pot_mix`).
  Inscribing a chart awards nothing. 4 of the 5 INK_RECIPES are
  discoverable (hedge ink is known from the start) → 200 XP of one-time
  discovery money.
- **Curve**: `xp_for_level(n) = (n-1)²·8 + (n-1)·32`, cumulative (XP never
  resets; `award_xp` loops while total ≥ next threshold).

## Findings

- **F1 — carto is the only trade with zero perks.** The spine trade has a
  content-only ladder while the three support trades each get two felt
  perk moments (5/10). Parity gap, and the Trades page makes it visible.
- **F2 — boss-den `req_carto` (8/12/14) is never read.** Dens never enter
  `compute_weights` (absent from BASE_WEIGHTS), and
  `crafting_bench.gd::socket_trophy` checks only trophy possession — not
  level. The de-facto gate is the trophy chain itself. Harmless today,
  but it's a promise in data the code doesn't keep. (Open question Q1.)
- **F3 — three dead levels: 2, 3, 17.** Every other level unlocks at
  least one thing. 2 and 3 land in the first session (40 / 96 XP — one or
  two runs in), exactly when the player lives at the bench. 17 is the
  ADR's "last level-up is felt" moment and currently feels like nothing.
- **F4 — XP tail is healthy, not grindy** (math below). No re-pacing
  needed.

## The ladder, 1→17 (existing + proposed fills)

Existing rows are plain; **proposed** rows are marked ✚ and detailed in
the sections after the table. Boss dens are listed in parentheses because
their req is currently unenforced (F2).

| Lv | Cum. XP | Unlocks today | Proposed fill |
|---:|---:|---|---|
| 1 | 0 | Snug + Tier 1 Hollow templates · Mineral Vein | — |
| 2 | 40 | — **hole** | ✚ Mara's Marginalia (codex shows all riddles) |
| 3 | 96 | — **hole** | ✚ Practiced Measures (auto-arrange known recipes at the pot) |
| 4 | 168 | Bramble Bloom | — |
| 5 | 256 | Tyrannical | ✚ perk: Curious Fingers (pot misses smudge less) |
| 6 | 360 | Sprinting Things | — |
| 7 | 480 | Wood Grove · Festival Pace | — |
| 8 | 616 | Quiver · (Hedgemother's Den req — unenforced) | — |
| 9 | 768 | Gilded Hollow | — |
| 10 | 936 | **Hollow template** · Fog of Hedge | ✚ perk: Sure Lines (+5 stability every roll) |
| 11 | 1120 | Frenzied | — |
| 12 | 1320 | Bursting · (Burrow Boar's Wallow req — unenforced) | — |
| 13 | 1536 | Wellspring | — |
| 14 | 1768 | Herbal Patch · (Wolf Alpha's Roost req — unenforced) | ✚ perk: Thrifty Quill (charts cost −1 hedge ink) |
| 15 | 2016 | **Briar Maze template** · Echoing Steps | — |
| 16 | 2280 | **Chart of the Summit** · Marked Quarry | — |
| 17 | 2560 | — **hole** (cap) | ✚ capstone: Master Wayfinder (+1 ink slot) |

Design note: 5, 10, 14 already unlock affixes, so the perks stack on live
levels rather than filling holes — that's deliberate. 5/10 mirrors every
other trade's perk rhythm; 10 is the level the affix slots double (Hollow)
so the stability perk lands exactly when bad-twin exposure doubles; 14 is
the Wolf Alpha level, when the player starts burning 3-ink charts farming
dens. The true holes (2, 3, 17) get QoL and the capstone instead — bench
quality-of-life belongs in the first session, not at perk depth.

## Hole fills (levels 2 and 3) — bench QoL

At most one fill per hole; both are bench-side, both gate off
`Game.perk_active("carto", id)` so they ride the same PERKS rows and show
on the Trades page automatically.

| Lv | Id | Name | Effect | Hook |
|---:|---|---|---|---|
| 2 | `marginalia` | Mara's Marginalia | The bench codex shows every recipe's riddle, hint seen or not (replaces the bare `???`). | `crafting_bench.gd:714` — the `seen_hints` gate becomes `seen OR perk_active("carto","marginalia")`. One-line change. |
| 3 | `practiced_measures` | Practiced Measures | One click at the pot sets out the makings for any discovered recipe (you still need the ingredients). | Bench pot UI: per discovered ink, a click fills `pot` from `GatherDefs.INK_RECIPES[id].inputs` if `can_afford`. This is the old design's "auto-arrange known recipes" (cartography-inscribing-table-design.md, was Lv 25), rescoped to the demo cap. |

Player-facing copy (codex/Trades page, world-bible voice):
- Marginalia: *"Mara's notes crowd the codex margins — every riddle, plain
  to read."*
- Practiced Measures: *"Known mixes set themselves out. The pot remembers
  what your hands have done."*

## Perk ladder (PERKS["carto"]) — the chart/bench game only

All three affect inscription odds or bench economy; none touch combat.

| Lv | Id | Name | Exact effect | Hook |
|---:|---|---|---|---|
| 5 | `curious_fingers` | Curious Fingers | A pot miss resolves 40/45/15 smudge / wild ink / serendipity (was 60/30/10). Smudge XP unchanged. | `game.gd::try_pot_mix` — the `roll < 0.6` / `roll < 0.9` thresholds become 0.40 / 0.85 when `perk_active("carto","curious_fingers")`. |
| 10 | `sure_lines` | Sure Lines | Every affix roll leans +5 percentage points toward its good twin (stacks with inks; 95 cap unchanged). | `charts.gd::effective_stability` gains an optional `perk_bonus: float = 0.0` param (added inside the `mini(95, …)`); both call sites pass it: `inscribe` (thread a new optional arg from `crafting_bench.gd:178`) and the live preview (`crafting_bench.gd:760`). |
| 14 | `thrifty_quill` | Thrifty Quill | Every chart's base cost asks one less Hedge Ink, never below one. (Tier 1: 2→1, Hollow/Briar: 3→2, Summit: 4→3. Slotted-ink costs unchanged.) | `charts.gd::craft_cost` gains optional `hedge_discount: int = 0`; subtract from `base_cost.hedge_ink` with a floor of 1. Callers at `crafting_bench.gd:173` and `:782` pass `1` when the perk is active. |

Perk copy (desc fields, voice-checked — plain, warm, no grimdark):
- Curious Fingers: *"A failed mix smudges less — curiosity keeps more of
  what it touches."*
- Sure Lines: *"Your nib doesn't waver. Every affix leans a little toward
  its good twin."*
- Thrifty Quill: *"Each chart asks one less pot of hedge ink. Waste not."*

Numbers, justified: +5 stability ≈ 8 levels of the built-in 0.6/level
scaling — felt but smaller than one Refined Ink (+10). The smudge cut
(60→40) keeps the experiment cozy without making misses free (a miss
still eats most of the pot). −1 hedge ink is a ~33% cost cut on tier-2
charts right when den-farming makes chart volume the loop.

## Level-17 capstone

**Proposal: `master_wayfinder` — Master Wayfinder, +1 ink slot on every
chart that takes ink.** (Tier 1: 2→3, Hollow/Briar Maze: 3→4. Snug and
Summit have no affix slots — ink does nothing there and `craft_cost`
already refuses to charge for it, so they stay at 0.)

- Copy: *"Master Wayfinder. Every chart holds one more pot of ink — the
  page listens closer."*
- Hook: `crafting_bench.gd:198 ink_slots()` is the single funnel —
  `return int(template().get("ink_slots", 0)) + (1 if has-slots and
  perk_active("carto","master_wayfinder") else 0)`. The bench UI's slot
  drawing and the `inks.size() >= ink_slots()` guard (line 94) both read
  this function already, so it's one edit.
- Balance: a 4th Refined Ink would be +40 stability points, still under
  the existing `ink_stability_bonus` cap of +0.5 — no new clamps needed.
- Why this over a re-roll: it deepens the bias game the player has spent
  16 levels learning (more ink = sharper pulls), costs one line, and is
  the demo-scale version of the old mastery ladder's Atlas Press
  (cartography-progression.md Lv 80). A re-roll mechanic ("re-ink one
  affix") is the stronger long-term fantasy but needs chart-mutation UI
  and a cost loop — right-sized for post-demo, noted in Q3.

## XP pacing math

Per-level step: `xp(n+1) − xp(n) = 16n + 24` — 40 at the first level-up,
264 at 15→16, 280 at 16→17. Linear growth in the step.

Run income (completion = tier·75 + good·40 + bad·10):

| Run | Expected XP |
|---|---:|
| Snug (tier 1, 0 affixes) | 75 |
| Tier 1 Hollow, ~58% good twin (mid-levels, no refined ink) | ~102 |
| Hollow / Briar (tier 2, 2 affixes, ~65% good) | ~210 (×1.3 on a good Tyrannical) |
| Summit (tier 3, 0 affixes) | 225 |

- **1→10** needs 936 cumulative. One-time discovery money (4 inks × 50 +
  a handful of +5 smudges) covers ~200–250 of it; the rest at ~100/run on
  tier-1 charts ≈ **7–8 runs**.
- **10→16** needs 1,344 more at ~210/run ≈ **6–7 runs**.
- **Runs to 16 ≈ 13–15.** Runs to 17: the last step is 280 — a Summit
  clear (225) plus any leftover progress usually dings it, worst case
  **+2 tier-2 runs**. Total ≈ **15–17 runs**.

**Verdict: not grindy — no fix proposed.** Late levels cost ~1.3 tier-2
runs each, and 17 tends to land at or just after the Summit clear, which
is exactly ADR 0006's "the last level-up is felt." With the Sure Lines
perk the good-twin rate rises ~5 points, nudging late runs to ~215 XP —
negligible to pacing, so the perks don't need XP rebalancing. The only
degenerate path is snug-spam (75 XP, ~4 runs/level late), which is
self-inflicted and already pays worse than engaging with affixes.

## Files (when implemented — this spec is audit-only)

| Path | Action |
|---|---|
| `wyrd/scripts/game.gd` | add `PERKS["carto"]` (5 rows: 2/3/5/10/14/17 → marginalia, practiced_measures, curious_fingers, sure_lines, thrifty_quill, master_wayfinder); adjust `try_pot_mix` thresholds behind curious_fingers |
| `wyrd/data/charts.gd` | optional params: `effective_stability(…, perk_bonus)`, `craft_cost(…, hedge_discount)`, `inscribe(…, perk_bonus)` |
| `wyrd/scripts/ui/crafting_bench.gd` | thread perk args at lines 173/178/760/782; `ink_slots()` +1 at 198; codex gate at 714; pot auto-arrange click |

## Acceptance criteria (for the implementing spec)

1. Trades page shows six carto rows at 2/3/5/10/14/17 alongside the
   existing template/affix ladder; all copy passes the world-bible read.
2. At carto 2 the codex shows every riddle; below 2, unseen hints stay `???`.
3. At carto 5 a deliberate pot miss resolves smudge ~40% over a sample.
4. At carto 10 the bench preview's stability percentages read 5 higher
   than the same setup at 9 (beyond the 0.6/level drift).
5. At carto 14 the Hollow's previewed cost reads 2 hedge ink; the Snug
   still costs 1.
6. At carto 17 the Tier 1 Hollow offers 3 ink sockets; Snug/Summit still 0.
7. All three headless tests stay green (`WYRD_NO_SAVE=1`).

## Open questions

- **Q1 (F2): boss-den `req_carto` is dead data.** Enforce it in
  `socket_trophy` (one check + a gentle toast: *"This den asks for
  Wayfinder 12."*), or delete the field? Recommendation: **enforce** — the
  trophy chain already paces it in practice, so the check costs nothing,
  and data that lies eventually bites. Either way, decide; don't leave it.
- **Q2: perk slot 14 vs 13.** 13 is the thinnest late level (Wellspring
  only); 14 already carries Herbal Patch + the Wolf den. Thrifty Quill at
  13 would smooth the table more; 14 matches the den-farming moment.
  Spec'd at 14; moving to 13 is a one-number change if the table feel
  wins.
- **Q3: capstone alternative — re-roll.** "Re-ink one affix on an
  inscribed chart (costs 1 Refined Ink)" is the old Atlas Press fantasy
  and a stronger hook for post-demo mastery (Lv 18+ when the cap lifts).
  Parked, not rejected.
- **Q4: should inscription itself pay a sliver of carto XP** (e.g. +5)?
  Today the bench act pays nothing and completion pays everything. Leaning
  no — completion-only keeps the "charts are promises kept" framing and
  avoids inscribe-and-discard farming. Flagged because the smudge already
  pays +5, which makes *failing* at the bench the only bench act that
  teaches.
- No contradictions found between ADR 0006, charts.gd, game.gd, and
  gather.gd; the old cartography docs (Lv 25/50/80 ladder) are superseded
  scale but their ideas are mined above.

## References

- `docs/adr/0006-demo-level-cap-17.md` — cap 17, don't move Wayfinding
- `wyrd/data/charts.gd` — TEMPLATES / AFFIXES / INKS / engine
- `wyrd/scripts/game.gd` — PERKS, award_xp, try_pot_mix, xp_for_level
- `wyrd/data/gather.gd` — INK_RECIPES (discovery XP feed)
- `wyrd/scripts/ui/crafting_bench.gd` — all bench hooks
- `docs/cartography-progression.md`, `docs/cartography-inscribing-table-design.md`
  — the pre-Godot mastery ladder this borrows from
- `docs/WORLD_BIBLE.md` — voice
