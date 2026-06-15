---
type: design
tags: [system-design, chart-loop]
status: draft
updated: 2026-06-14
sources:
  - "kb/wiki/systems/Chart Loop.md"
  - "kb/wiki/entities/Charts.md"
  - "kb/wiki/Universe Build-Out Plan.md"
  - "kb/wiki/concepts/Balance Philosophy.md"
  - "wyrd/data/charts.gd"
  - "wyrd/scripts/layout_loader.gd"
  - "wyrd/scripts/game.gd"
  - "kb/wiki/games/arpg/Hades.md"
  - "kb/wiki/games/roguelike/Slay the Spire.md"
  - "kb/wiki/games/roguelike/Dead Cells.md"
  - "kb/wiki/games/arpg/Path of Exile.md"
---

# Chart Loop — Deep Design

> Forward-looking deep design. Current-state: [[Chart Loop]] (and [[Charts]]). Constrained by [[Universe Build-Out Plan]].

## Player fantasy & role in the cozy spine

You are a Wayfinder, and a chart is not a dungeon you *make* — it is a way the village forgot that you **remember hard enough to walk again**. The loop's emotional arc is *settle → remember → go → come home fuller*. Charting is the keystone of the cozy spine (`gather → craft → chart → delve → return → grow`, ADR 0003): every other Trade pours into the chart (ore and herbs become inks; cooked draughts steady the roll), and the chart is the only door that turns that quiet preparation into a place with weather and sorrow. The loop must never feel like *rolling a dungeon* (a Phase-0 success metric in [[Universe Build-Out Plan]] §8: testers should describe it as "remembering a way"). The chart is the spine's payoff verb, not a slot machine.

## What ships today (grounded in code)

The loop is **real and tested**, not aspirational:

- **Inscription engine** — `charts.gd::inscribe(template_id, ink_ids, carto_lv, trophy_id, perk_bonus)` rolls a chart dict (`template_id / tier / scope / name / affixes[] / seed`). Affixes are weighted-picked (`compute_weights` → `roll_affix_ids` → `_weighted_pick`); each resolves to a **good or bad twin** by a stability coin-flip (`effective_stability = min(95, base_stab + carto_lv·0.6 + (ink_bonus + perk_bonus)·100)`). Only affixes with implemented dungeon-side effects are rollable — the preview never lies.
- **Five templates** (`TEMPLATES` / `TEMPLATE_ORDER`): `snug` (tutorial, 0 affixes), `tier_1`, `hollow`, `briar_maze`, `summit`. The `gen` block on each is threaded straight into `DungeonGen.generate`.
- **Run lifecycle** (`game.gd`): `add_chart` (bench → case), `enter_dungeon` (socket at the [[The Waystone|Waystone]]: consume chart, snapshot player, swap scene), `return_to_town(player, abandoned)` (completion XP via `completion_xp = tier·75 + good·40 + bad·10`, ×1.3 if Tyrannical's good twin; `abandoned` pays nothing). `run_cfg()` translates the active chart into the generator config and promotes a good boss-den twin into `boss_kind`.
- **The trophy chain is wired** — `TROPHY_TO_AFFIX` guarantees a boss-den affix when a trophy is slotted; bosses drop the next key (`layout_loader.gd::BOSS_KINDS[*].trophy`); elites seed the first `thorn_essence` at ~25% (`marked_quarry`-modified).
- **Anti-softlock exists** — every run has an abandon stone at the entry (`layout_loader.gd::_build_exit_waystone`), and bad boss-den twins stamp an "empty throne" so the den is never bare.

Two honesty flags carried from [[Chart Loop]]: the **Living Atlas / town-growth payoff is NOT in code yet** (`grep` finds no atlas/region/restore in `game.gd`), and `affixes.gd` has **no twin roster** beyond the inline `*__bad` convention.

## Deep design

### Core mechanics (precise, Wayfinder-flavored)

1. **Two-station ritual, kept.** Remembering happens at the **Inscribing Table** (cold-craft: roll the chart, spend inks); *going* happens only at the **Waystone** (socket the finished chart, cross over). This separation is load-bearing — it lets the bench be a calm planning beat and the Waystone the committed step, and it is already how `town.gd` places both stations.
2. **The "what this run feels like" summary card** (DEMO, §4.3 of the Plan) is the legibility keystone: on the bench, before you spend a pot, show biome name + one-line storybook **rumor header**, the resolved good/bad twin icons in plain English, the implied boss gimmick, and **honest live odds** read off `compute_weights` / `effective_stability`. Informed randomness, never hidden math (Balance Philosophy §7; the [[Path of Exile]] "targeted vs wholesale reroll" lesson).
3. **One reroll sink — the Smudge Stick** (DEMO): ink-priced reroll of *one already-resolved twin*. Adds player agency and an ink sink (P12) without a gear treadmill. Fresh Quill / Steady Hand are Horizon.
4. **Vein-reading feeds the loop** (spine depth, Pillar One): the Pale Veins ore minigame yields the deep ore that **refines into Palechalk Ink**, which biases stone affixes and stabilizes the inscription — the cross-trade chain (`gather → refine → chart`) made tangible.

### Data model & formulas (GDScript-flavored)

The chart dict and roll math are shipped and should **not** be re-architected. New work is *additive*:

| Field / function | Shape | Status |
|---|---|---|
| `chart` dict | `{template_id, tier, scope, name, affixes[], seed}` | shipped |
| `compute_weights(tier, inks, lv)` | base weight × ink bias, normalized to % | shipped |
| `effective_stability(id, lv, ink, perk)` | `min(95, base_stab + lv·0.6 + (ink+perk)·100)` | shipped |
| `completion_xp(chart)` | `tier·75 + good·40 + bad·10`, ×1.3 if Tyrannical-good | shipped |
| `chart.region` (NEW) | `String` — `"crypt"` / `"pale_veins"`; **default `"crypt"`** for old saves | **add** |
| `AtlasData.regions` (NEW) | `{region: {needed:int, done:int, restored:bool}}` | **add** |
| `atlas_credit(chart)` (NEW) | on completion, `regions[chart.region].done += 1`; if `done >= needed` and not restored → restore corner | **add** |

The town-growth threshold is a **count of completions**, not XP, so it reads as *visiting a place enough to remember it whole*. Worked threshold for the demo: **Pale Veins `needed = 3`** (three completed Pale Veins charts → the well animates, the corner opens). Keep it small — the payoff must land inside one play session's MEDIUM cadence.

### Content to author (tiers / tables / worked examples)

**Cadence contract** (Plan §4.2) — every chart declares which clock it serves:

| Cadence | Vehicle | Target length | Reward |
|---|---|---|---|
| SHORT | one chart run | 4–10 min | completion XP, mats, ink dust |
| MEDIUM | one Almanac page / one town corner | a session | a restored walkable corner + neighbor |
| LONG | a leg of the trophy chain | the demo arc | a region opens; the chain advances |

**Demo template ladder** (keep shipped five; add region tag):

| Template | Tier | Req carto | Affix slots | Region | Worked completion XP |
|---|---|---|---|---|---|
| `snug` | 1 | 1 | 0 | crypt | 75 (clean) |
| `tier_1` | 1 | 1 | 1 | crypt | 115 (one good) |
| `hollow` | 2 | 10 | 2 | crypt / pale_veins | 230 (two good) |
| `briar_maze` | 2 | 15 | 2 | (Horizon: Briarward) | 230 |
| `summit` | 3 | 16 | 0 | (Horizon: Summit) | 225 |

**Worked Pale Veins example.** Inscribe `hollow` with `region = pale_veins`, slot 1× Palechalk Ink + 1× Stoneground Ink, carto 12. Summary card reads: *"A wallow in the Pale Veins, where the stone branches into other things."* High odds on `mineral_vein` (good), a `burrow_boar_den` if the tusk is slotted. Complete it → +230 carto XP, deep ore, and one tick toward the Pale Veins corner.

### Edge cases, failure modes, anti-frustration

- **Boss-den softlock** — solved (abandon stone at entry; abandoning pays no XP but never traps).
- **Dud roll feels bad** — bad twins still pay `completion_xp` ("a botched roll is still a lesson"); the Smudge Stick gives one targeted save. Cozy contract: never punish, only vary upside.
- **Old saves with no `region`** — `chart.region` defaults to `"crypt"`; the migration ladder (Plan §9 step 1) backfills, never discards.
- **Atlas double-credit** — `restored` flag is one-way; re-running a restored region keeps giving XP but never re-triggers the town beat.
- **Co-op chart authority** — host-only socketing is already enforced (`enter_dungeon` net branch); atlas credit must be **host-authoritative** and synced so a guest doesn't double-count.

## Interlocks — how this feeds/uses other systems

- Consumes [[Inks]] (the value spine, P12) and [[Gathering]] output; [[Crafting]] refines ink (the cross-trade chain).
- Rolls [[Affixes]] (good/bad twins) which drive [[Dungeon Generation]] via `scope` + `gen` + `run_cfg`.
- Gates and is gated by [[Wayfinding]] (template `req_carto` ladder) and the trophy chain through [[Bosses]].
- Pays into the **Living Atlas** town-growth payoff and the [[Almanac|Almanac]] request board (the MEDIUM cadence).
- Constrained by [[Balance Philosophy]] (cozy pacing, XP-curve calibration, no-arbitrage economy) and shares the trophy ritual with [[Economy]].

## Demo scope vs Horizon

**DEMO (built now, per the P7 cut-line — only because Pillar One uses them):**
- The summary card; the Smudge Stick reroll; the Pale-Veins region tag on charts.
- **Living Atlas v1 — the spine-growth payoff (P1/P4):** completing 3 Pale Veins charts **restores one walkable town corner** (the well animates; Hod arrives as Earthcraft mentor). This is the one piece of town-growth the demo commits.
- Minimal Almanac (1–2 pages), each completion restoring a corner.
- Procedural rumor headers; the cadence/no-idle audit.

**HORIZON (named, not built):** full Living-Atlas port, Cartographer's Board, the Deepening ladder (+1 affix slot per depth rank — the *first* post-demo system), Echo Charts, the soft in-run fork at the rest room, affixes-as-rule-changers across multiple biomes, the full Almanac. None ships until a completed region needs it.

## Implementation notes (Godot)

- **Roll engine:** `wyrd/data/charts.gd` — add a `region` field to each `TEMPLATES` entry and thread it through `inscribe`; do **not** touch `compute_weights` / `completion_xp` (tested balance).
- **Lifecycle:** `wyrd/scripts/game.gd` — add `atlas_credit(chart)` inside `return_to_town`'s non-abandoned branch; persist atlas state through the existing save path (`save_now`).
- **New data file:** `wyrd/data/atlas.gd` (region thresholds + restored flags), mirroring the `charts.gd` static-data pattern.
- **Town payoff:** `wyrd/scripts/town.gd` reads atlas state on `_ready` and toggles the restored-corner node (a GLB swap + a neighbor NPC), kit-compliant per `wyrd_ui.gd`.
- **UI:** the summary card is a new `wyrd/scripts/ui/` panel — must pass `tools/check_ninepatch.py` and gain a `WYRD_UI_SHOT` capture surface (Plan §6).
- **Tests:** `test_wyrd_loop.gd` guards inscribe → enter → return → XP and the economy gate; extend it with an **atlas-credit assertion** (completing N charts flips `restored` exactly once). `test_wyrd_transitions.gd` guards scene swaps. The on-demand balance-sim validates the Pale Veins affix table (never a commit gate, P10).

## Open questions

- Does the Almanac page **share** completion counters with the Living Atlas, or track separately? (Risk: double-feeling the same MEDIUM beat.)
- Should the summary-card odds show **per-twin stability** or only the affix weights? (More math = more honest, but more cognitive load against the cozy register.)
- Atlas threshold tuning: is 3 completions the right MEDIUM length, or does it stretch past one session?
- Co-op: does atlas credit accrue **per party** or per player's home save? (Ties to the unresolved Charter/persistence question, Plan §6.)

## See also / Sources

- [[Chart Loop]] · [[Charts]] · [[Affixes]] · [[Inks]] · [[Dungeon Generation]] · [[Wayfinding]] · [[Bosses]] · [[Balance Philosophy]] · [[Universe Build-Out Plan]]
- Game refs: [[Hades]] (run-authored difficulty, hub-with-verbs), [[Slay the Spire]] (typed-node route as decision space), [[Dead Cells]] (affixes unlock content, weighty trophy "bank"), [[Path of Exile]] (currency-as-craft, targeted reroll)
- Code: `wyrd/data/charts.gd`, `wyrd/scripts/layout_loader.gd`, `wyrd/scripts/game.gd`
