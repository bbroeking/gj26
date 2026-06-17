---
title: Wayfinding Ladder & Progression
domain: Progression
type: system
status: partial
effort: M
tags: [wayfinder, plan]
---

# Wayfinding Ladder & Progression

> One unified Wayfinding skill (lv 1–17, XP curve `(n-1)²×8+(n-1)×32`, 19 auto-unlocking perks, `LEVEL_POWER 1.25` difficulty bands) — the core engine is shipped and green; the next priority is pick-one-of-N mastery choice at perk cluster levels (5, 10, 13, 14, 17) and the level-up feel moment (Plan.md Phase B3).

## Current state

The single-trade model is fully implemented and test-covered. `game.gd:22` declares `const SKILL := "wayfinding"` (ADR 0012); `game.gd:271–273` defines `xp_for_level(n)` as `(n-1)² × 8 + (n-1) × 32` — yielding 40 XP to reach lv 2 and 936 XP to reach lv 10. Level cap is `LEVEL_CAP = 17` (`game.gd:280`), enforced at award time in `award_xp` (`game.gd:282–291`); XP continues accruing past cap but levels stop. Combat gives zero XP (`award_xp` is never called from combat paths). The tier→den-level map `{1:3, 2:8, 3:13}` and `const LEVEL_POWER := 1.25` (`game.gd:739, 750`) implement ADR 0013's symmetric delta-scaling; both player (`player_controller.gd:1116`) and den enemies scale by `LEVEL_POWER^(lv-1)`, so only the level delta matters for difficulty.

The 19-perk ladder lives at `game.gd:415–459` under `PERKS["wayfinding"]`. All 19 perks auto-unlock by level (no player choice): four perks cluster at lv 5 (Curious Fingers, Sturdy Swings, Keen Eye, Steady Hands), four at lv 10 (Sure Lines, Miner's Rhythm, Clean Splits, Hunter's Stride), two at lv 13 (Rich Seams, Light Hands), two at lv 14 (Thrifty Quill, Heavy Draw), and four at lv 17 (Master Wayfinder, Smith's Thrift, Second Pour, Even Breath). Three skills gate on Wayfinding level: HuntersMark @ 4, HeartwoodWard @ 7, MercyShot @ 9 (`game.gd:118`).

`perk_active()` (`game.gd:461–465`) is purely level-threshold based — no player-facing choice is wired. `gather_bonus()` (`game.gd:469–478`) handles the gather perks; `_derive_stats()` (`player_controller.gd:1082–1116`) folds the combat perks (Steady Hands, Hunter's Stride, Quick Nock, Heavy Draw) into `derived_stats`. All perks are tested: `test_wyrd_loop.gd:539` asserts the unified ladder has exactly 19 perks, and `_test_crafting_perks()` exercises gather and craft perk effects.

The dev hook `WYRD_DEV_LEVEL=<n>` (`game.gd:211–215`) sets level on boot for playtesting the mastery ladder and difficulty bands. Save/load migrates legacy four-trade saves by summing XP into the single skill.

**Status is partial**: structure, XP curve, level cap, all 19 perks, the difficulty bands, and `_derive_stats()` wiring are complete and gate-green. Pick-one-of-N mastery (flagged in ADR 0012 as a planned refinement) and the level-up feel moment are the two meaningful gaps.

## Gaps — what needs fleshing out

1. **[BLOCKER for feel] Level-up visual/audio moment** — `leveled_up` signal fires and `level_up` SFX plays, but there is no burst, perk banner, or HUD flash. Plan.md Phase B3 owns this; see that plan before doing anything here — do not duplicate.
2. **[Design gap] Pick-one-of-N mastery at cluster levels** — lv 5 has 4 perks, lv 10 has 4, lv 17 has 4. ADR 0012 explicitly flags "pick-one-of-N mastery is a planned refinement." Currently all perks at a level auto-unlock simultaneously, removing all player agency. This is the highest-impact design gap. Requires: UI for the choice, save/load of chosen perks, `perk_active()` to check chosen set, plus balancing the clusters so each option is genuinely different.
3. **[Missing] Ledger as live stat source** — boss trophies should grant capped stat boosts via `ledger.gd` (ADR 0013 followup), plugging into `_derive_stats()`. The seam exists but `ledger.gd` is not wired.
4. **[UX gap] Den-level band preview** — ADR 0013 flags a "summary card" to surface `den_level` and the resulting band ("Den lv 8 · you lv 6 → very hard") before the player commits to a chart. Chart panel shows no difficulty signal today.
5. **[Tuning gap] XP faucet balance** — craft recipes award flat XP (`game.gd:410`); gather nodes award XP; chart completion awards `tier × 75 + good × 40 + bad × 10` (`test_wyrd_loop.gd:699–704`). No audit has been done on whether the curve feels right across all 17 levels with the real cozy loop (gather/craft/inscribe mix). The WYRD_DEV_LEVEL hook exists but no automated time-to-level estimate exists.
6. **[Minor] `gather_bonus()` still passes old trade keys** (`"wilds"`, `"earth"` — `game.gd:472, 474, 476`) instead of `"wayfinding"`, relying on `perk_active`'s key-agnostic lookup. This is functional but inconsistent with ADR 0012's single-key intent.

## Plan

### Phase 1 — Level-up feel (defer to Plan.md Part B / Phase B3)

This phase is fully specified in Plan.md Phase B3. Do not re-plan here. Key points for cross-reference:
- On `leveled_up`: player burst (gold ink-outline pulse + back-out scale punch), **perk banner** toast naming the new unlock, HUD trade readout count-up/flash, layered level-up chord.
- If mastery choice (Phase 2 below) lands first, the banner must say "Choose a mastery" instead of auto-naming the unlock.
- **DoD:** see Plan.md Phase B3 — burst + named-perk banner + HUD flash fire together within one frame of the signal; timer/logic test asserts banner names the correct perk.
- **Effort: S–M** (per Plan.md).

### Phase 2 — Pick-one-of-N mastery choice

The design heart of the ladder. At each cluster level (5, 10, 13, 14, 17), the player chooses **one perk from the cluster**; the others are locked out for the run / permanently (TBD — see Open Questions).

**Steps:**
1. Audit cluster clusters: lv 5 has 4 perks (1 gather-carto, 1 gather-earth, 1 gather-wilds, 1 combat-crit), lv 10 has 4 (chart, earth-gather, wilds-gather, combat-speed), lv 13 has 2 (earth deep, wilds deep), lv 14 has 2 (chart/carto, combat power), lv 17 has 4 (chart, forge, brew, combat-focus). Verify each cluster has at least one cozy and one combat-adjacent option so every player archetype has a meaningful choice.
2. Add `chosen_perks: Array` to `game.gd` persistent state (alongside `trades`). Save/load it.
3. Change `perk_active()` (`game.gd:461`) to require the perk to be in `chosen_perks` when its level is a cluster level; single perks (lv 2 Marginalia, lv 3 Practiced Measures, lv 12 Quick Nock) still auto-unlock.
4. On `leveled_up` at a cluster level, emit a new signal `perk_choice_pending(level, [perk_dicts])` instead of auto-unlocking.
5. Build a **Mastery Choice overlay** (reuse the Wayfinder UI Kit modal pattern from `wyrd_ui.gd`): displays the N candidates with name/desc/icon, blocks hotbar, fires `choose_perk(id)` on confirm.
6. Update the Trades tab (`ui/trades_panel.gd`) to show chosen vs available perks per cluster.
7. Tests: `test_wyrd_loop.gd` assert that a cluster-level perk is NOT active before choice, IS active after `choose_perk`, and that only one of the cluster is active.

- **DoD:** at each cluster level the game pauses with the mastery panel; choosing one perk activates it; the others are locked; the Trades tab reflects the state; choice survives save/load; headless test exercises the full lv-5 cluster choice path.
- **Effort: M**

### Phase 3 — Ledger stat source (ADR 0013 followup)

Wire boss trophies through `ledger.gd` into `_derive_stats()` as a capped per-slot bonus.

**Steps:**
1. Implement `ledger.gd` as a `RefCounted` that maps `trophy_id → stat_boosts[]` (consult `data/drops.gd` for the trophy list). Cap each bonus (e.g. max +3 damage per trophy tier) to avoid the gear-treadmill failure mode.
2. Add `ledger` to `game.gd` persistent state; populate on `add_trophy(id)`.
3. In `_derive_stats()` (`player_controller.gd:1082`), after the gear/perk pass, sum `Game.ledger.total_stat(stat)` for each of the five offensive stats. Trophy bonuses are flat additions (not multiplicative with `LEVEL_POWER`).
4. Test: headless assert that collecting a boss trophy raises `derived_stats.damage` by the expected amount.

- **DoD:** collecting a boss trophy raises combat power by a documented, capped amount; `test_stats.gd` (or `test_wyrd_loop.gd`) asserts the stat delta; `_derive_stats()` is the only place the number is computed.
- **Effort: M**

### Phase 4 — Den-level band preview in chart panel

Surface the ADR 0013 difficulty signal before the player commits to a chart run.

**Steps:**
1. In the chart inscription/select panel (`ui/chart_panel.gd` or equivalent), compute `delta = den_level - Game.trade_lv()` using the tier→den map already in `run_cfg()` (`game.gd:750`).
2. Display a band label: delta ≤ −2 → "Cozy farming", −1..+1 → "Fair fight", ≥ +2 → "Very hard — come back stronger", using the kit's good/bad twin colors from `wyrd_ui.gd`.
3. No new logic — `run_cfg()` already computes `den_level`; just surface it.

- **DoD:** every chart in the chart case shows a coloured band label matching ADR 0013's table; WYRD_DEV_LEVEL=3 + tier-3 chart shows "Very hard"; screenshot-verifiable.
- **Effort: S**

### Phase 5 — XP faucet audit & time-to-level estimates

Ensure the 17-level ladder feels rewarding across the full cozy loop, not just in one faucet.

**Steps:**
1. Write a headless sim (extend `test_wyrd_loop.gd` or a standalone `test_xp_pace.gd`) that runs a typical gather→craft→inscribe session and prints XP earned per loop, levels crossed, and approximate real-time at `WYRD_FAST_CHANNEL=1` pace. Not a gate test — an exploratory tool.
2. Identify any "dead zones" (levels where no new content unlocks and XP pace is slow) and either add a minor unlock or tune a faucet rate.
3. Fix the `gather_bonus()` legacy trade keys (`"wilds"`, `"earth"` → `"wayfinding"`) for ADR 0012 consistency. Low risk; `perk_active()` already ignores the key, so this is a cleanup only.

- **DoD:** sim script exists and prints a level-by-level pace table; no two consecutive levels are "dead" (no new unlock + < 50% of adjacent levels' XP gate); legacy trade keys removed from `gather_bonus()`.
- **Effort: S**

## Dependencies & links

- [[system-skills-hotbar]] — the hotbar is gated by Wayfinding level (`SKILL_REQS`: HuntersMark @ 4, HeartwoodWard @ 7, MercyShot @ 9); the mastery panel (Phase 2) must not conflict with the skills picker.
- [[system-charts-wayfinding]] — chart completion is the primary XP faucet for the carto loop; tier→den-level map (`run_cfg()`) is the input to the band preview (Phase 4).
- [[system-bosses]] — boss trophies are the ADR 0013 source #3 for vertical power; Phase 3 (Ledger) depends on what trophies exist and their stat values.
- [[system-combatant-ai]] — enemy HP/damage scale by `LEVEL_POWER^(den_level-1)`; the difficulty bands verified in ADR 0013 assume the same constant as player scaling.
- [[system-gathering]] — gather nodes are the highest-frequency XP faucet; perk effects (Keen Eye, Sturdy Swings, Clean Splits, Light Hands) live in `gather_bonus()`.
- [[system-crafting]] — craft recipes award XP and gate on Wayfinding level (`req_lv`); the XP faucet audit (Phase 5) must include the crafting loop.
- [[system-hud]] — the level-up burst, perk banner, and XP bar readout are HUD responsibilities; Phase 1 / Plan.md B3 touches `player_hud.gd`.
- [[system-save-load]] — `chosen_perks` (Phase 2) and `ledger` (Phase 3) must be added to the save dict and migrated for existing saves.
- **Plan.md Part B / Phase B3** — owns the level-up feel moment entirely. Phase 1 here is a cross-reference only; do not implement the burst/banner independently of Plan.md's B3.

## Verification

- **Phase 1**: Plan.md B3 verification (timer/logic test asserts banner fires correct perk name within one frame of `leveled_up`). Run with `WYRD_NO_SAVE=1` from `wyrd/`.
- **Phase 2**: extend `test_wyrd_loop.gd` — assert perk inactive before choice, active after `choose_perk(id)`, only one cluster perk active, state round-trips through save/load. Use `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd`.
- **Phase 3**: assert in `test_wyrd_loop.gd` (or a new `test_stats.gd` case) that adding a boss trophy raises `derived_stats.damage` by the expected capped delta. All five suites stay green.
- **Phase 4**: screenshot via `WYRD_DEV_LEVEL=3 WYRD_DEV_CHART=tier_3 WYRD_SHOT=1 godot --path wyrd`; verify "Very hard" band appears on the tier-3 chart.
- **Phase 5**: sim script outputs a pace table; review manually; the legacy-key cleanup is verified by all five headless suites staying green.

All headless runs use `cd wyrd` + `WYRD_NO_SAVE=1` (never the real save path).

## Open questions

1. **Mastery choice: permanent or per-run?** ADR 0012 says "planned refinement" without specifying. Permanent choice (locked in the Trades page) gives long-term identity; per-run choice (reset with the chart) adds replayability. The chart-inscription loop makes per-run feel natural — but then 17 levels of choice every run is tedious. Recommended: permanent, with a "respec at the inscribing table" cost (one uncommon ink).
2. **Cluster balance at lv 5**: four perks cover four distinct flavors (carto/earth/wilds/combat). If pick-one lands, should the player ever get a second cluster-pick at lv 5 (e.g. lv 6 gives the second slot)? Or stay at one-of-four permanently? Decide before Phase 2 implementation.
3. **LEVEL_POWER re-tuning**: ADR 0013 notes "re-tune once Deepening depth and real gear/trophy curves are in playtest." Phase 3 (Ledger) changes the power budget; LEVEL_POWER may need a small adjustment once trophies are live.
