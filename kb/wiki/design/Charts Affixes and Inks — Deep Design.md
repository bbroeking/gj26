---
type: design
tags: [system-design, wayfinding]
status: draft
updated: 2026-06-14
sources:
  - "kb/wiki/entities/Charts.md"
  - "kb/wiki/entities/Affixes.md"
  - "kb/wiki/entities/Inks.md"
  - "kb/wiki/entities/The Crafting Bench.md"
  - "kb/wiki/entities/The Waystone.md"
  - "kb/wiki/systems/Chart Loop.md"
  - "kb/wiki/concepts/Balance Philosophy.md"
  - "kb/wiki/Universe Build-Out Plan.md"
  - "wyrd/data/charts.gd"
  - "wyrd/data/affixes.gd"
  - "kb/wiki/games/arpg/Path of Exile.md"
  - "kb/wiki/games/roguelike/Balatro.md"
  - "kb/wiki/games/roguelike/Slay the Spire.md"
  - "kb/wiki/games/ccg/Inscryption.md"
---

# Charts Affixes and Inks — Deep Design

> Forward-looking deep design. Current-state: [[Charts]], [[Affixes]], [[Inks]]. Constrained by [[Universe Build-Out Plan]].

## Player fantasy & role in the cozy spine

You are a Wayfinder, and to inscribe a chart is to *remember a way the village forgot* — not to roll a dungeon, but to draw a path that "was always there." The parameterization engine is the heart of the differentiator: you mix inks from what you gathered, lay a chart base on the bench, and **tilt weighted dice of your own making** before walking the place you remembered. The cozy promise (ADR 0003) is honored by making the gamble *legible and upside-leaning* — a bad twin is a quieter run, never a punishment. This is the spine's payoff verb: gather → craft → **chart** → delve.

## What ships today (grounded in code)

`wyrd/data/charts.gd` already ships the whole engine, not a stub:

- **5 templates** in `TEMPLATES` (`snug`, `tier_1`, `hollow`, `briar_maze`, `summit`), each with `tier`, `req_carto`, `affix_slots`, `ink_slots`, `base_cost`, `scope`, and a `gen` block threaded into `DungeonGen.generate(seed, cfg)`.
- **~16 affixes** in `AFFIXES` (15 random-rollable + 3 boss dens; the page count of "9" undercounts the shipped roster). Each carries a `name`/`bad_name`, `good_desc`/`bad_desc`, `kind` (`bias`/`modifier`/`pacing`/`boss`), `req_carto`, `base_stab` (46–55).
- **8 inks** in `INKS`, each a `bias` dict (affix_id → weight multiplier; the `_stability` key is a flat good-twin bonus, capped +0.5 by `ink_stability_bonus`).
- **The bias-roll engine**: `compute_weights(tier, ink_ids, carto_lv)` (filters by `req_carto`, applies ink multipliers, normalizes to percent); `effective_stability(affix_id, carto_lv, ink_bonus, perk_bonus)` = `min(95, base_stab + carto_lv*0.6 + (ink_bonus+perk_bonus)*100)`; `roll_affix_ids` (weighted distinct picks); `inscribe(...)` (resolves twins via `rng.randf()*100 < stab`, writes `resolvedId = id` or `id + "__bad"`, randomizes a 31-bit `seed`); `completion_xp` = `tier*75 + good*40 + bad*10` (×1.3 if Tyrannical good).
- **Boss dens are deliberate, not rolled**: `TROPHY_TO_AFFIX` guarantees a den affix when its trophy is slotted; the stability roll still applies (bad twin = Empty Throne).
- **The bench** ([[The Crafting Bench]], spec 42) already draws live odds bars from `compute_weights` + `effective_stability`.

The gaps: there is **no twin *roster*** — the bad twin is a string suffix (`__bad`) with no per-affix behavioral table; there is **no per-biome flavor table**; and **no reroll sink** (Smudge Stick) exists.

## Deep design

### Core mechanics (precise, Wayfinder-flavored)

1. **Templates × biome = the two axes (P3).** Today `scope` is a single string that picks the generator block and spawn table. The Pale Veins ships **biome as a second axis** by adding a `biome` field to the chart dict and a swap of theme pools/tilesets/spawn tables over the *existing* generator — not a new engine. A Hollow inscribed in the Pale Veins is the same template, dressed in pale stone.

2. **The twin is a coin, the ink loads the coin.** Two independent rolls per slot, exactly as shipped: **(a)** *which affix* lands (weighted by inks via `compute_weights`); **(b)** *which twin* lands (the stability coin from `effective_stability`). Inks affect both: bias inks tilt (a); `_stability` inks tilt (b). This separation is the design's spine — keep it.

3. **The twin roster (new, the headline work).** Promote `__bad` from a string suffix to a **data-driven behavior table**: every affix declares its `good` and `bad` effect explicitly so the dungeon side reads the resolved effect, not a paraphrase. A bad twin is *honest disappointment or modest risk*, never a cozy-breaking spike (Balance Philosophy: "always winnable, never frustrating"). Bias affixes degrade to *absence* (Barren, Wilted, Picked Clean); modifiers flip the beneficiary (Mired Boots = *you* slow, not them). Bad twins still pay `completion_xp` — "a botched roll is still a lesson."

4. **Per-biome flavor table (new).** A biome re-skins the *same* affix mechanic with biome-specific `name`/`bad_name`/`good_desc`/`bad_desc` strings and a `base_stab` nudge, so a Pale Veins `mineral_vein` reads as "Pale Seam / Choked Vein," not "Mineral Vein." Mechanics shared; fiction biome-local (P2: biome-coupled affixes).

5. **The inscription ritual.** Place base → (sockets reveal only if `affix_slots > 0`) → slot inks → optionally slot a boss trophy → **read the summary card** → stamp. The trophy *guarantees* its den in one slot; the only gamble left there is its stability coin.

6. **The "what this run feels like" summary card (the legibility keystone).** On the result slot, in plain storybook English: biome name + one-line procedural **rumor header** (`template + biome + resolved-intent`), the resolved/likely good-bad twin per slot with an icon, the boss gimmick implied if a trophy is slotted, and **honest live odds** read straight from `compute_weights`/`effective_stability` — never a number the run won't honor (the charts.gd invariant: only implemented affixes are rollable).

7. **The reroll sink — Smudge Stick (new, the one demo reroll).** After inscription, spend ink to **smudge one resolved twin and re-roll only its stability coin** (not which affix) — informed randomness + an ink sink (P12) + zero gear inflation. Fresh Quill (re-roll *which affix*) and Steady Hand (lock a good twin) are Horizon.

### Data model & formulas (GDScript-flavored)

**Twin roster — replace the `__bad` string with a typed table** (extends the existing `AFFIXES` entries, no engine rewrite):

```gdscript
# AFFIXES[id] gains an explicit twin behavior block:
"mineral_vein": {
    ...,                                   # existing name/desc/req_carto/base_stab
    "good": {"spawn": "ore_rock", "count": Vector2i(3, 5)},
    "bad":  {"spawn": "ore_rock", "count": Vector2i(0, 0)},   # Barren = absence
},
"sprinter": {
    ...,
    "good": {"enemy_speed_mult": 1.25},
    "bad":  {"player_speed_mult": 0.90},   # flip the beneficiary, modest
},
```

**Per-biome flavor (new file `data/biome_affixes.gd`, a thin lookup):**

```gdscript
const FLAVOR := {
  "pale_veins": {
    "mineral_vein": {"name": "Pale Seam", "bad_name": "Choked Vein",
      "good_desc": "Pale ore branches through the stone — 3–5 seams.",
      "bad_desc": "The vein chokes off in chalk. No ore.", "stab_delta": +3},
  },
}
# resolve(affix_id, biome) -> merged display dict; falls back to AFFIXES if absent.
```

**Stability math (unchanged — the doc must respect it):**

| Input | Effect |
|---|---|
| `base_stab` | 46–55 per affix (boss dens lowest) |
| `carto_lv * 0.6` | +0.6 pts/level (Lv 1 → +0.6; Lv 17 → +10.2) |
| `ink_bonus*100` | `refined_ink` +10 pts each, capped +50 total |
| `perk_bonus*100` | Sure Lines +5 pts |
| cap | hard `min(95, …)` — a bad twin is *always* possible |

**Smudge Stick (new):**

```gdscript
static func smudge(chart, slot_idx, carto_lv, ink_bonus, perk_bonus, rng) -> Dictionary:
    var a := chart.affixes[slot_idx]
    var stab := effective_stability(a.id, carto_lv, ink_bonus, perk_bonus)
    a.good = rng.randf() * 100.0 < stab          # re-roll the coin only
    a.resolvedId = a.id if a.good else a.id + "__bad"
    return chart   # cost: 1 smudge_ink, charged by caller
```

### Content to author (tiers / tables / worked examples)

- **Twin roster:** author `good`/`bad` blocks for all ~16 affixes (a single data pass; the effects already exist in the dungeon code — this just makes them table-driven).
- **Pale Veins flavor table:** re-skin ~6–8 affixes (the resource-bias + 2–3 modifiers most thematic to stone) + the Boar den. One biome only (P-budget honesty).
- **Worked example — a Pale Veins Hollow (Tier 2, 2 slots, Lv 12):**
  - Slot inks: 1× `stoneground_ink` (`mineral_vein` ×2.5) + 1× `refined_ink` (+10 pts).
  - `compute_weights` → `mineral_vein` ~22%, rest diluted. Roll lands `mineral_vein` + `tyrannical`.
  - Stability: `mineral_vein` = `min(95, 55 + 12*0.6 + 0.10*100)` = **72%**; with Pale Veins `stab_delta +3` → **75%**. `tyrannical` = `52 + 7.2 + 10` = **69%**.
  - Summary card: *"A Pale Seam Hollow in the Pale Veins, where the stone branches into other things. Likely: Pale Seam (75%), Tyrannical (69%)."*
  - `completion_xp` if both good = `2*75 + 2*40` = **230**, ×1.3 (Tyrannical) = **299**.

### Edge cases, failure modes, anti-frustration

- **`affix_slots = 0` templates** (`snug`, `summit`): bench hides ink/trophy sockets; never charge for inks (shipped `craft_cost` already guards). Summary card shows only biome + rumor header.
- **All bad luck:** `min(95, …)` means a string of bad twins is statistically possible. Smudge Stick is the relief valve; the cozy floor (bad twin = absence/modest, never a spike) ensures even a fully-bad chart is *quiet*, not *brutal*.
- **First-time-affix teaching (P-narrative):** the first inscription of a never-seen affix biases that den to feature only it; tracked in save, no popup beyond the storybook name.
- **No phantom promises:** keep the charts.gd invariant — an affix may only enter the roster once its dungeon-side effect ships. The summary card cannot lie.
- **Honest odds, not optimistic odds:** the card shows the *real* normalized weight and stability, including the bad-twin chance — never rounds up.

## Interlocks — how this feeds/uses other systems

- **[[Crafting and Inks — Deep Design]]** — inks are crafted here; their `bias` dicts are the levers this engine reads. Palechalk/Smudge inks originate in the crafting deep design.
- **[[Gathering — Deep Design]]** — supplies ink reagents and is *biased by* good twins (`mineral_vein`, `wellspring`); the loop is circular by design.
- **[[Chart Loop — Deep Design]]** — this engine is the inscription step at the loop's center; `completion_xp` feeds [[Trades and Leveling — Deep Design]] (Wayfinding XP).
- **[[Dungeon Generation]]** — consumes `seed` + `scope`/`biome` + resolved twins via [[The Waystone]].
- **[[Combat — Deep Design]]** — boss-den affixes + trophy chain wire the Hedgemother/Boar gimmicks; modifier twins (Quiver, Frenzied) shape the bow fight.
- **[[Economy]]** — inscription cost + Smudge sink route value through inks (P12), no gold inflation.

## Demo scope vs Horizon

| Feature | Scope |
|---|---|
| Twin roster as a typed data table (all ~16 affixes) | **DEMO** — table pass, no engine rewrite |
| Pale Veins per-biome flavor table (~6–8 affixes + Boar den) | **DEMO** — one biome only (P2) |
| `biome` as the chart's second axis (theme/tileset/spawn swap) | **DEMO** — over existing generator (P3) |
| Procedural rumor header + "what this run feels like" card | **DEMO** — strings + existing math (the legibility keystone) |
| Smudge Stick (re-roll one stability coin) | **DEMO** — the one reroll sink |
| First-time-affix teaching | **DEMO** |
| Affixes as interacting Balatro-style **rule-changers** across biomes | **HORIZON** — large owned balance workstream (§10) |
| Fresh Quill / Steady Hand rerolls; Echo Charts; soft in-run fork | **HORIZON** |
| The Deepening (+1 affix slot per depth rank; bad twins still pay XP) | **HORIZON** — first post-demo system |

The cut-line (P7): nothing here ships ahead of the Pale Veins region that uses it. Spine-growth (P1): the engine's *new depth* is the twin roster + biome flavor + the legibility card, authored as richly as any combat move.

## Implementation notes (Godot)

- **Lives in** `wyrd/data/charts.gd` (engine + twin roster table) and a new `wyrd/data/biome_affixes.gd` (flavor lookup). Keep `compute_weights`/`effective_stability`/`completion_xp` signatures stable — the bench and tests depend on them.
- **Bench UI** ([[The Crafting Bench]], `scripts/ui/`): the summary card is a new kit-compliant panel (must pass `tools/check_ninepatch.py`, get a `WYRD_UI_SHOT` capture surface, derive from `wyrd_ui.gd` tokens). Preload its textures in `_ready` (never `load()` in `_draw`).
- **Strings** flow through the WORLD_BIBLE voice + string table; rumor headers compose from fragments, not inline literals.
- **Test suite that guards it:** `test_wyrd_loop.gd` exercises inscribe → completion_xp; add assertions that (a) the twin roster resolves to a behavior block for every affix, (b) the summary-card odds equal `compute_weights` output (no drift), (c) Smudge re-rolls only stability. The on-demand **balance-sim script** validates the Pale Veins flavor table (P10 — a script, never a commit gate).

## Open questions

- Does Smudge Stick re-roll cost scale with tier/slot, or flat? (Lean flat for legibility.)
- Should `_stability` inks and Smudge stack, or does Smudge ignore inks already spent? (Lean: Smudge re-rolls at the *original* effective stability.)
- Per-biome `stab_delta`: does it risk drifting biomes apart on difficulty? (Cap at ±5; balance-sim watches it.)
- Where does the rumor header live — chart dict (persisted) or recomputed on display? (Recompute; keep the dict thin for save-size.)

## See also / Sources

- [[Charts]] · [[Affixes]] · [[Inks]] · [[The Crafting Bench]] · [[The Waystone]] · [[Chart Loop]]
- [[Balance Philosophy]] · [[Universe Build-Out Plan]]
- Siblings: [[Chart Loop — Deep Design]] · [[Crafting and Inks — Deep Design]] · [[Gathering — Deep Design]] · [[Combat — Deep Design]] · [[Systems Interlock Map]]
- Game refs: [[Path of Exile]] (currency-as-crafting, targeted vs wholesale reroll) · [[Balatro]] (affix-as-rule-changer, animated legibility) · [[Slay the Spire]] (relics reframe the run) · [[Inscryption]] (no dead resource; biome rules differ)
- Code: `wyrd/data/charts.gd` (`TEMPLATES`, `AFFIXES`, `INKS`, `compute_weights`, `effective_stability`, `inscribe`, `completion_xp`), `wyrd/data/affixes.gd`
