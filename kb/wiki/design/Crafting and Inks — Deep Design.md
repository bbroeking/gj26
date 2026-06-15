---
type: design
tags: [system-design, crafting]
status: draft
updated: 2026-06-14
sources:
  - "kb/wiki/systems/Crafting.md"
  - "kb/wiki/entities/Inks.md"
  - "kb/wiki/entities/The Crafting Bench.md"
  - "kb/wiki/concepts/Balance Philosophy.md"
  - "kb/wiki/Universe Build-Out Plan.md"
  - "wyrd/data/crafting.gd"
  - "wyrd/data/items.gd"
  - "wyrd/data/gather.gd"
  - "wyrd/data/charts.gd"
  - "wyrd/scripts/game.gd"
  - "wyrd/scripts/ui/crafting_bench.gd"
---

# Crafting and Inks — Deep Design
> Forward-looking deep design. Current-state: [[Crafting]], [[Inks]], [[The Crafting Bench]]. Constrained by [[Universe Build-Out Plan]].

## Player fantasy & role in the cozy spine
You are a Wayfinder who *remembers* a way home and makes it real with your hands: you grind the same bone-white chalk you mined into an ink, and that ink steadies a chart so the path you remembered holds. Crafting is the third beat of the spine (gather → **craft** → chart → delve, ADR 0003) and the bridge between the other three — gather feeds it, charting consumes its inks, delving spends its draughts. Inks are the **value spine** (P12): every chart inscription, reroll, and dissolve routes through them, so the cozy verb of *mixing a quiet pot of colour* is also the economy's pulse. The fantasy is legibility and care, never min-max: you can always afford to chart, gathering is always cheaper than buying (the no-arbitrage gate), and a failed mix teaches rather than punishes.

## What ships today (grounded in code — cite files/functions you read)
Four stations route through one mutation point, `Game.craft(station_id, recipe_id)` (`wyrd/scripts/game.gd:351`), which gates on the station's trade level, checks `can_afford(inputs)`, reserves pack space *before* spending for gear (`find_first_fit`), and awards trade XP. The stations (`wyrd/data/crafting.gd::STATIONS`): the **Cottage Hearth** (`cookfire`, Wildcraft) cooks the heal ladder Hearth→Heartsease (35→220 vigor); **Quill's Still** (`still`, Wildcraft) brews five runtime-only timed buffs; **Hod's Anvil** (`forge`, Earthcraft) smelts ore→bars and smiths the gear/tool ladder E1–E17, where deep gear (E10+) rolls rare (`N_AFFIXES`, `items.gd:111`). Inks are *not* a station recipe but a discovery experiment: `mix_ink()` (`game.gd:541`) auto-mixes known recipes; the "Try the Mix" verb resolves an exact match as a **discovery** (+50 carto XP, `discover_ink()`) or a miss as 60/30/10 smudge/wild/serendipity (40/45/15 with the Curious Fingers perk, `game.gd:603`). Eight inks ship (`charts.gd::INKS`, recipes in `gather.gd::INK_RECIPES`); `refined_ink`'s `_stability: 0.10` is the special case — it adds flat good-twin chance rather than biasing which affix lands. The bias engine is real and tested: `compute_weights(tier, ink_ids, carto_lv)` → normalize → percent; `effective_stability(affix, carto_lv, ink_bonus, perk_bonus)` caps at 95 (`charts.gd:306`). The economy gate (`test_wyrd_loop.gd::_test_economy_gate`) asserts smithed gear sells for less than its inputs cost, and the deep ores (palechalk, starsilver, hedgesteel) are never shelf-stocked.

## Deep design
### Core mechanics (precise, Wayfinder-flavored)
Three deepenings, all named DEMO in the plan (§4.2), all built on existing seams:

1. **Ink-refining as a craft step** (the headline craft deepening). Today `chalkwash_ink` is a flat pot recipe (`1 palechalk + 2 wild_herb`). Pillar One adds a two-input *refine* at the bench pot: deep ore + a binder, where the player chooses the binder **grade** to match the ore's grade. Output is **Palechalk Ink**, a Stoneflesh-biasing ink that also carries `_stability`. The craft is cozy (no timing, no fail-state) but legibly *better-with-care*: a good grade-match yields a higher `_stability` roll on the ink instance.

2. **Grade-matching for stability.** Deep ore mined in the Pale Veins carries a `grade` (1–3, from vein-reading — the gather minigame, §4.2). Refining pairs ore-grade against binder-grade; the closer the match, the higher the ink's stability payload (see formula). This is the one place crafting has a *quality axis* — kept to inks only, never gear (no new gear tier, P8).

3. **The cook→chart stabilizing draught.** One Wildcraft recipe at the Cottage Hearth — a **Stabilizing Draught** — consumed *before* inscribing to add a flat one-shot bonus to that inscription's stability roll. This is the single concrete cook→chart link (§4.2): cooking demonstrably matters to the spine without a full cooking subsystem.

### Data model & formulas (concrete, GDScript-flavored; use tables)
Refining reuses the recipe shape and adds a `refine` flag and per-output grade carry. The ink instance grows one field, `stability_bonus` (replacing the constant `_stability` for refined inks only):

```gdscript
# gather.gd::INK_RECIPES — new entry (refine step)
"palechalk_ink": {
    "inputs": {"deep_ore": 1, "binder_chalk": 1}, "yields": 1,
    "refine": true,                # routes through refine_ink(), not mix
    "bias": {"stoneflesh": 2.2, "_stability": 0.0},  # base; payload added per-craft
    "hint_key": "bench",
    "riddle": "Hod: 'Match the grit to the grade. Mismatched, it still draws — just shakier.'",
}
```

| Term | Value | Notes |
|---|---|---|
| ore grade `g_o` | 1–3 | from vein-reading hit quality |
| binder grade `g_b` | 1–3 | player picks the binder |
| match `m` | `1.0 - abs(g_o - g_b) / 2.0` | 1.0 perfect → 0.0 worst |
| ink `stability_bonus` | `round((0.04 + 0.06 * m) * 100) / 100` | 0.04 floor → 0.10 perfect |
| draught bonus | `+0.08` flat, one inscription | consumed on craft, not stacked |

The `_stability` reader (`ink_stability_bonus`, `charts.gd:297`) changes one line: read `ink.bias._stability` **or** the instance's `stability_bonus` if present; the +0.5 cap and 95-stability ceiling are unchanged, so the worst-grade refine still helps and the best never trivializes a roll (Balance Philosophy: "always winnable, never frustrating").

### Content to author (tiers / tables / worked examples)
Ink roster stays at the design-intent three tiers ([[Inks]]): Tier-1 single-essence (`hedge_ink`), Tier-2 two-essence (`stoneground`, `chalkwash`, `ash`), and the **refined** tier that now means *ore-refined*, not the speculative Inkwell-Vessel tier (kept Horizon). Pale Veins ships exactly **one** new signature ink (Palechalk Ink) plus a re-flavoring of the existing affix-courting inks toward stone — no new affix-courting inks beyond budget (§4.3 honest affix budget).

Worked example: a player mines two grade-3 ore chunks (vein-read with the grain), refines with grade-3 chalk binder → `m=1.0` → Palechalk Ink at `stability_bonus 0.10`. Slotting it plus drinking a Stabilizing Draught (+0.08) on a tier-2 inscription pushes a base-50 Stoneflesh affix to `effective_stability = min(95, 50 + carto*0.6 + 18) ≈ 75`. That is a meaningful, readable tilt the player *built*, not bought.

### Edge cases, failure modes, anti-frustration
- **Refine never bricks materials.** A grade mismatch always produces a usable ink (0.04 floor) — the worst case is "shakier," matching the cozy contract (no destroyed inputs).
- **Pack-space and pot reservation** already handled by `craft()` and the running-claims pot dict ([[The Crafting Bench]]); refine inherits both.
- **No-arbitrage stays intact:** Palechalk Ink's deep-ore input is unbuyable by construction, so it can never be both shelf-stocked and a peak input (the planned ADR + no-arbitrage assertion, §4.5). Add the refine output to the economy-gate assertion's coverage.
- **Discovery clarity:** the refine recipe is hinted via Hod (existing `hint_key: "bench"` pattern); the codex strip already shows hinted-unknown riddles, so no new UI grammar.
- **Stacking abuse:** draught bonus is one-shot and not stackable with itself; multiple refined inks still hit the existing +0.5 cap.

## Interlocks — how this feeds/uses other systems
- [[Gathering]] supplies deep ore *with a grade* via the Pale Veins vein-reading minigame — the grade is the gather→craft handshake.
- [[Charts]] / [[Chart Loop]] consume inks at inscription; refined-ink stability + the draught feed `effective_stability`. This is the cross-trade chain (Earthcraft ore → Wayfinding ink, §4.1) made tangible.
- [[Affixes]] are what inks bias; Palechalk Ink courts the Pale Veins' stone twins (Stoneflesh / its bad twin).
- [[Economy]] — inks are the value spine; the dissolve-gear-to-ink-dust sink (§4.5) routes overflow back here.
- [[Earthcraft]] gets its pick-one-of-N mastery (Rich Seams / smelt-yield / faster-channel, §4.1) which feeds refining throughput.
- [[The Crafting Bench]] is where refine and inscription co-locate; [[Wildcraft]] cooks the draught.

## Demo scope vs Horizon (respect the P7 cut-line and P1 spine-growth)
**DEMO (Pillar One, ship now):** ink-refining as a bench step; grade-matching → ink stability payload; the one Stabilizing Draught (cook→chart link); Palechalk Ink + stone re-flavor of existing inks; Earthcraft pick-one-of-N mastery; dissolve-to-ink-dust sink; refine added to the economy-gate test. These *are* the P1 spine-growth deliverable for this pillar.

**HORIZON (named, not built):** the full Inkwell-Vessel Tier-3 ink system and the 15-ink design catalog ([[Inks]] warning); the 3×3 spatial-grid crafting (explicitly not ported, spec-43-notes); full cooking depth beyond the one draught; pick-one-of-N for all four trades; craft-tree deepenings in regions beyond the Pale Veins (P7 — built only when a region needs them); inscribed-gear temper at Hod's Anvil (no new gear tier, ever).

## Implementation notes (Godot)
- **Data:** add `palechalk_ink` to `wyrd/data/gather.gd::INK_RECIPES` (with `refine: true`) and to `charts.gd::INKS`; add `stabilizing_draught` to `crafting.gd::RECIPES` + the `cookfire` station's recipe list and `DRAUGHTS`/order if quaffable, or a distinct one-shot inscription buff if not.
- **Logic:** a new `Game.refine_ink(ore_id, binder_grade)` beside `mix_ink()` that computes `m` and stamps `stability_bonus` on the produced ink material; extend `ChartsData.ink_stability_bonus` to read the per-instance payload; a one-shot `inscription_stability_bonus` field consumed by the bench at craft time (mirrors how the trophy socket is consumed).
- **UI:** the refine interaction lives in `wyrd/scripts/ui/crafting_bench.gd` (the pot sub-area) — a grade picker chip on the binder; must pass `wyrd/tools/check_ninepatch.py` and get a `WYRD_UI_SHOT` capture surface (§6 UI workstream). No new panel; reuse the codex strip + pot grammar.
- **Tests:** `test_wyrd_loop.gd` is the guard — extend `_test_economy_gate` to cover the refine output's no-arbitrage and add a `_test_refine` asserting grade-match → stability payload monotonicity and the floor/cap. Keep all four headless suites green (CLAUDE.md gate).

## Open questions
- Does the Stabilizing Draught live in the heal `DRAUGHTS` ladder (quaffed by Q) or as a distinct inscription-time consumable applied at the bench? The latter is cleaner for the cook→chart link but adds one consume-path.
- Where does ore `grade` persist — on the satchel material stack (needs a per-stack field, a save-schema touch) or rolled at refine time from a gather-session statistic? Stack-level grade is truer to the fantasy but bigger; resolve before the migration ladder ships (§6 persistence).
- Should multiple refined inks' `stability_bonus` stack additively into the +0.5 cap, or take max? Max is safer against accidental trivialization; needs a balance-sim pass.

## See also / Sources
- [[Crafting]], [[Inks]], [[The Crafting Bench]], [[Charts]], [[Chart Loop]], [[Affixes]], [[Economy]], [[Gathering]], [[Earthcraft]], [[Wildcraft]], [[Balance Philosophy]], [[Universe Build-Out Plan]]
- Code: `wyrd/data/crafting.gd`, `wyrd/data/items.gd`, `wyrd/data/gather.gd`, `wyrd/data/charts.gd`, `wyrd/scripts/game.gd` (`craft`, `mix_ink`, `discover_ink`, `try_mix`), `wyrd/scripts/ui/crafting_bench.gd`, `wyrd/test_wyrd_loop.gd`
