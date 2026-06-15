---
type: design
tags: [system-design, progression-endgame]
status: draft
updated: 2026-06-14
sources:
  - "kb/wiki/Universe Build-Out Plan.md"
  - "kb/wiki/concepts/Balance Philosophy.md"
  - "kb/wiki/research/MMO Progression Systems.md"
  - "kb/wiki/research/MMO Social and Endgame.md"
  - "kb/wiki/research/MMO Lessons for Wayfinder.md"
  - "kb/wiki/systems/Chart Loop.md"
  - "wyrd/scripts/game.gd"
  - "wyrd/data/charts.gd"
  - "kb/wiki/games/roguelike/Hades II.md"
  - "kb/wiki/games/life-sim/Animal Crossing New Horizons.md"
  - "kb/wiki/games/arpg/Path of Exile.md"
---

# Progression and Endgame — Deep Design

> Forward-looking deep design. Current-state: [[Chart Loop]] and [[Trades and Leveling]]. Constrained by [[Universe Build-Out Plan]].

## Player fantasy & role in the cozy spine

You are a Wayfinder filling in a storybook atlas of Bramblewood by *remembering the paths the village forgot*. Progression is not "get stronger" — by the lore constraint (P6, no King of Brambles, the Hedgemother quieted not killed) it is *get wider and remember more*. The endgame is the same loop you already love, made denser and more legible, with the village visibly growing as you walk it. Within the cozy spine (`gather → craft → chart → delve → come home`, ADR 0003), this system is the **come-home-and-it-mattered** layer: every run ticks a counter, fills a Codex page, or restores a walkable corner. It is the retention engine that keeps the spine spinning *without a single daily chore*.

## What ships today (grounded in code)

- **Four-Trade XP, capped at 17.** `game.gd::xp_for_level(n)` = `(n-1)²·8 + (n-1)·32` (quadratic, shallower than OSRS); `award_xp` stops levelling at `LEVEL_CAP = 17` but **keeps accruing XP past it** — so a cap lift loses no progress (per [[MMO Progression Systems]]).
- **Per-Trade perk ladders.** `game.gd::PERKS` defines a curated ladder per Trade (carto has 6, others 4), gated by level; `perk_active()` reads them. These are stable, milestone-spaced talent-lite nodes — not a PoE web.
- **The trophy chain is the vertical spine.** `charts.gd` boss-den affixes (`hedgemother_den` → `burrow_boar_den` → `wolf_alpha_den`) are inked by slotting a trophy; `summit` template is the capstone. `game.gd::return_to_town` sets `summit_cleared` and fires the quieting line.
- **Completion XP rewards the roll, even the bad one.** `charts.gd::completion_xp` = `tier·75 + good·40 + bad·10` (×1.3 if Tyrannical's good twin landed). **Bad twins still pay** — the existing hook the Deepening leans on.
- **Discovery already rewards, never gates.** `discover_ink()` awards 50 carto XP on first-find with a "yours for good" toast — the exact "reward on first-discovery" pattern the Codex generalizes.

## Deep design

### Core mechanics (precise, Wayfinder-flavored)

**1. The Wayfarer's Codex (DEMO — ships now).** A storybook ledger that fills itself. The first time the player *discovers* any affix twin, enemy, biome, recipe, or boss, its entry unlocks and a toast fires: "A page remembers itself." The entry text is a **verbatim quote from `WORLD_LORE`** (never paraphrase — P3, ADR voice). The Codex is **pure reward, never a gate**: nothing is locked behind a missing page. It is the cozy completion meter — an Animal-Crossing-style "soft goal" ([[Animal Crossing New Horizons]]) that pulls without forcing.

**2. The Deepening ladder (HORIZON — first post-demo system).** Each region tracks a **depth rank** (0..N). Charting a den at depth `d` and completing it unlocks `d+1`. Each rank grants **+1 affix slot** on that region's charts and **higher enemy density** — *never a bigger boss, never a new gear tier*. This is the horizontal-as-mandated-by-lore long tail: the same Boar, more *read* (more affixes interacting). Bad twins still pay `completion_xp`, so a deep run is never wasted. Modeled on WoW Mythic+ keystone scaling ([[MMO Social and Endgame]]) but stripped of timers and gear-score gatekeeping.

**3. The Living Atlas / town-growth (DEMO-minimal → HORIZON-full).** Every completed chart ticks a region counter; crossing a threshold **restores one walkable town corner** (P4) — the well animates, Hod arrives, a road clears. Demo ships the **minimal Almanac** (1–2 request-board pages spanning all four Trades, each completion restoring one corner). Full Living-Atlas port is Horizon.

**4. Horizontal titles & cosmetics (HORIZON).** Post-17, the long tail is cosmetic-only: Codex-completion titles, a quieting-cosmetic for the Summit ("Deeper Quieting" — cosmetic prestige, **no power**). No vertical capstone exists by P6.

### Data model & formulas (GDScript-flavored)

New persistent state on `Game` (rides the save like `discovered_inks`):

```gdscript
var codex_seen: Dictionary = {}     # entry_id -> true (first-discovery set)
var region_depth: Dictionary = {}   # scope -> int depth rank (Deepening)
var atlas_counts: Dictionary = {}   # scope -> charts completed (Living Atlas)
```

| Concept | Formula | Notes |
|---|---|---|
| Codex unlock | `codex_seen[id] = true` on first sight; idempotent | Fires reward toast once; no gate |
| Depth → slots | `affix_slots = template.affix_slots + region_depth[scope]` | +1 per rank; density up, boss unchanged |
| Depth → density | `enemy_density *= 1.0 + 0.12 * depth` | Gentle; cozy band (Balance Philosophy §3) |
| Deep completion XP | reuse `completion_xp`; extra slots = more affixes = more `good/bad` terms | Bad twins already pay — no new reward tech |
| Atlas threshold | corner restores at `atlas_counts[scope] >= [3, 8, 16]` | Soft goal, never a wall |

Depth scaling reuses the existing `run_cfg()` affix/density plumbing — **no new generator code** (P10). Stability (`effective_stability`, `carto_lv·0.6` term) already rises with level, so deeper charts stay legible as the player levels — no separate balance subsystem.

### Content to author (tiers / tables / worked examples)

| Layer | Demo authoring | Horizon authoring |
|---|---|---|
| Codex entries | Crypt + Pale Veins: ~4 affixes, 8 enemies, 2 bosses, ~6 recipes, 2 biomes — verbatim `WORLD_LORE` strings | Every twin/enemy/biome game-wide |
| Almanac pages | 1–2 pages, 3–5 requests each, cross-Trade | Full multi-page board |
| Town corners | The well (Pale Veins reveal) + 1 cookfire-side corner | Each chain leg restores a corner |
| Deepening | — (Horizon) | Per-region depth flavor lines per rank |

**Worked example (Deepening, Horizon):** Pale Veins at depth 2 → a Hollow chart rolls `2 + 2 = 4` affix slots, density ×1.24. The Boar is unchanged; the *reading* is harder (e.g. Frenzied + Bursting + a den + a gather twin all at once). Completion: `tier 2·75 + 3 good·40 + 1 bad·10 = 280` XP — strictly more than the base run, all horizontal.

**Worked example (Codex):** First kill of a Hedgewight → `codex_seen["enemy.hedgewight"] = true`, toast, and the entry shows the verbatim Pale Veins bestiary line. No mechanical change; pure remembering.

### Edge cases, failure modes, anti-frustration

- **No FOMO, no streaks, no expiring rewards** (P-cozy, [[MMO Lessons for Wayfinder]]). The ~1hr daily-obligation tipping point is the line we do not cross. Seasonal freshness (rotating affix pools, [[Path of Exile]]-style) is **opt-in and additive** — never a reset that deletes progress.
- **Deepening must never escalate the boss.** Hard rule, balance-sim-asserted: depth raises slots + density only. A `_test` asserts boss stat blocks are depth-invariant.
- **Codex can't gate.** A lint/test asserts no chart, recipe, or unlock reads `codex_seen` as a precondition.
- **Cap-lift safety.** XP accrues past 17 today; Deepening adds horizontal headroom so a future cap lift is optional, not load-bearing.
- **Atlas can't soft-lock.** Corner thresholds are met by *any* charts in scope; a player who hates one Trade still progresses town via the others.

## Interlocks — how this feeds/uses other systems

- **[[Chart Loop]]** — the engine this rides; Deepening adds a depth axis to chart inscription; completion feeds XP + Atlas counters.
- **[[Charts Affixes and Inks — Deep Design|Affixes]]** — depth = +1 affix slot; the long tail is *more affixes interacting*, the only honest endgame under P6.
- **[[Trades and Leveling]]** — perk ladders are the per-Trade vertical; this system is the post-cap horizontal continuation.
- **[[Dungeon Generation]]** — depth threads density through existing `run_cfg()` plumbing; no new generator.
- **[[Combat — Deep Design|Combat]]** — depth deepens *reading/response* load (more telegraphs at once), never TTK or boss tier (P8).
- **[[Save System]]** — new dicts ride the versioned save; needs the Phase-0 migration ladder (Universe Plan §9).
- **[[World Lore|WORLD_LORE]]** — Codex entries are verbatim quotes; this is a fiction-delivery surface (P3).
- **[[Multiplayer Co-op]]** — Atlas/Codex are per-save today; the shared-Charter persistence question is Horizon (Universe Plan §6).

## Demo scope vs Horizon

| Feature | Scope | P7 status |
|---|---|---|
| Wayfarer's Codex shell (crypt + Pale Veins entries, verbatim voice) | **DEMO** | Ships with Pillar Zero/One; near-free once fiction strings exist |
| Minimal Almanac (1–2 pages) + 1–2 town corners | **DEMO** | Ships with Pillar One spine-growth (P1) |
| XP-past-cap, perk ladders, trophy chain | **SHIPPED** | Already in code |
| The Deepening ladder | **HORIZON** | *First* post-demo system (Universe Plan §10.1) |
| Full Living Atlas, Cartographer's Board | **HORIZON** | Built only when a region needs it (P7) |
| Horizontal titles, Deeper Quieting (cosmetic), Echo Charts | **HORIZON** | Cosmetic-only; no power, no new tier |
| Opt-in seasonal affix rotation | **HORIZON** | Additive freshness, no FOMO |

Respecting the cut-line (P7): nothing post-demo ships until a region that uses it is complete end-to-end. Demo seeds **only** the Codex shell + minimal Almanac; the Codex is the spine-safe choice precisely because it costs almost nothing once the fiction pipeline exists and adds zero power.

## Implementation notes (Godot)

- **Lives in:** `wyrd/scripts/game.gd` (new state dicts + `codex_unlock()` / `atlas_tick()` helpers, called from `return_to_town` and discovery sites); `wyrd/data/charts.gd` (depth applied in `inscribe`/`run_cfg`); a new `wyrd/data/codex.gd` (entry id → `WORLD_LORE` string keys).
- **UI:** Codex and Almanac are new kit-compliant panels (`scripts/ui/wyrd_ui.gd` tokens) — each must pass `tools/check_ninepatch.py` and get a `WYRD_UI_SHOT` capture surface in `tools/capture_ui.sh` (Universe Plan §6 UI workstream). Never `load()` a texture in `_draw` (memory: godot-draw-load-white-texture).
- **Tests:** extend `test_wyrd_loop.gd` — Codex-never-gates assertion, Atlas-threshold tick, and (when Deepening lands) the **boss-depth-invariance** assertion alongside the existing economy gate. The four headless suites stay the only hard gate (P10).
- **Save:** new dicts versioned into the save via the Phase-0 migration ladder; back up the real save path before `_test_save_roundtrip`.

## Open questions

- Codex entry **granularity** — per-affix-twin (good and bad separately) or per-affix? Leaning per-twin (more pages = more reward), pending fiction budget.
- Does the **Almanac** award XP/ink, or only town-growth? Town-growth-only keeps it a pure cozy goal, but a small ink reward might pull harder.
- Deepening's **density ceiling** vs the perf budget (Universe Plan §6) — what depth rank hits the enemy-count cap, and does that *become* the natural soft cap?
- Should **opt-in seasonal rotation** ever touch the Atlas/Codex, or stay purely a chart-pool reshuffle to keep the "world without you" cozy promise intact?

## See also / Sources

- [[Chart Loop]] · [[Trades and Leveling]] · [[Charts Affixes and Inks — Deep Design]] · [[Combat — Deep Design]] · [[Dungeon Generation]] · [[Systems Interlock Map]]
- [[Universe Build-Out Plan]] · [[Balance Philosophy]]
- [[MMO Progression Systems]] · [[MMO Social and Endgame]] · [[MMO Lessons for Wayfinder]]
- [[Hades II]] · [[Animal Crossing New Horizons]] · [[Path of Exile]] · [[World of Warcraft]] · [[Final Fantasy XIV]]
- Code: `wyrd/scripts/game.gd`, `wyrd/data/charts.gd`
