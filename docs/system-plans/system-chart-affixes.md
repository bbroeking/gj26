---
title: Chart Affixes (good/bad twins)
domain: Wayfinding & Dungeons
type: system
status: complete
effort: M
tags: [wayfinder, plan]
---

# Chart Affixes (good/bad twins)

> All 18 affixes (15 rollable + 3 boss-dens) are shipped and wired; the expansion roadmap focuses on tension tuning, a third affix wave, and multi-player fairness for the bad-twin effects.

## Current state

`wyrd/data/charts.gd` defines 18 affixes in `AFFIXES` (line 72–186) across four kinds — `bias`, `modifier`, `pacing`, `boss` — each with a `name`/`bad_name`, `good_desc`/`bad_desc`, `req_carto`, and `base_stab`. The weighted bias-roll engine (`compute_weights`, `roll_affix_ids`, `inscribe` — lines 269–375) applies ink multipliers against `BASE_WEIGHTS` (line 199–215) and then evaluates stability per-affix via `effective_stability` (line 306–311: `min(95, base_stab + carto_lv×0.6 + ink_bonus×100 + perk_bonus×100)`). The `TROPHY_TO_AFFIX` map (line 190–194) guarantees boss-dens are always deliberately inked in, never surprise-rolled. Trophy-slot flow (`inscribe` lines 354–367) handles that guarantee correctly.

All dungeon-side effects are wired: bias affixes scatter gather nodes via `dungeon_gen.GATHER_BY_AFFIX` (lines 283–294); `layout_loader._read_chart_modifiers` (lines 276–318) sets combat-modifier vars for tyrannical, festival_pace, sprinter, bursting, fog_of_hedge, frenzied, marked_quarry; `player_controller.gd` (lines 1141–1162) applies quiver and echoing to fire-rate and Focus-regen; `gather_node.gd` (lines 280, 317) applies wellspring's +1 yield / channel-time penalty. All 8 inks are defined with bias maps, including the three discoverable ones shipped in spec 43 and the three from spec 45 (lines 222–263). Every rollable affix has at least one courting ink. The inscribing table in `crafting_bench.gd` shows a live odds panel (weight % + stability %) plus hover tooltips surfacing `good_desc` / `bad_name` / `bad_desc` (lines 455–460, 804–820). `chart_label` (line 417–427) and `completion_xp` (lines 399–414) both handle the twin distinction correctly.

## Gaps — what needs fleshing out

- **Tension tuning (no quantitative baseline):** good/bad stability base values cluster at 50–55 and all good-twin completion XP is a flat `+40` per affix regardless of how punishing the bad twin is. There is no empirical playtest log of how often players exit with 0-good / all-bad charts at different carto levels, so the current thresholds are unvalidated.
- **Gilded bad-twin ("Picked Clean") has no dungeon effect:** `GATHER_BY_AFFIX` only handles the good twin (`"gilded"` → 2 extra chests). The bad twin text promises "no extra chests" which is the zero-chest default — technically correct but the bad twin is invisible / a no-op; no dedicated code path confirms this expectation is intentional vs. missed.
- **Sprinter bad-twin (Mired Boots) applies only in single-player:** `player_controller` line 1169 checks `game.in_dungeon` but the effect is applied to the local player only; in co-op, guests receive no slow unless the host broadcasts it. This is a multiplayer fairness gap.
- **No wave-3 affixes:** the roadmap ships 15 rollable affixes and notes dens stay trophy-only. There is design space for 2–4 new affixes targeting higher req_carto (17+) for post-cap charts once the level cap lifts, and for a `crafting` or `economy` kind affecting gold/vendor drops.
- **No bad-twin icon / colour signal at run-start:** when a bad twin lands, the player learns this at dungeon entry via the run banner, but there is no persistent HUD chip marking which affixes are active (good or bad). Players running a chart without checking the active-chart panel mid-dungeon have no reminder.
- **`echoing` bad twin (Hollow Echo) has no visual:** Focus regen slow is numeric only; no particle / vfx difference vs. the good twin's regen halo. Same for `quiver` / `Damp Strings`.
- **Waystone chart-socketing animation still owed** (see `docs/wyrd-roadmap.md` Standing followups): slotting the chart at the waystone has no socket pop / ritual feel. This lives in Plan.md Part B / Phase B6 and is tracked there — do not re-plan here.

## Plan
*(Status is complete — these phases are an expansion/polish roadmap.)*

### Phase 1 — Tension baseline & bad-twin audit
- Run 20+ inscribe samples at carto lv 1, 5, 10, 15 and log good/bad twin ratio per affix; capture in a TSV in `docs/specs/affix-balance-log.tsv`.
- Confirm `gilded` bad twin (Picked Clean) is intentionally a no-op; either add a negative chest-count tag or update the bad_desc to reflect "chest haul comes up normal".
- Audit each modifier bad-twin value: Damp Strings (−10% fire rate) vs. Quiver (+20%) are asymmetric — verify this asymmetry is intentional game-design choice vs. oversight; document in `affixes.gd` comment.
- Raise `base_stab` for early affixes (req_carto ≤ 5) to 58–60 if playtest log shows >40% bad-twin rate at lv 5; no changes without data.
- **DoD:** `docs/specs/affix-balance-log.tsv` exists with ≥20 rows; gilded bad-twin intent documented in a code comment; any asymmetry confirmed intentional.
- **Effort:** S

### Phase 2 — Multiplayer bad-twin sync
- `sprinter` bad-twin slow is applied in `player_controller._apply_chart_modifiers` (line ~1169) using a local `game.affix_bad()` query. In NetGame, guests must receive the slow through the existing stat-sync channel. Identify whether `_apply_chart_modifiers` is called per-peer or host-only; if host-only, emit a `net_chart_mods` RPC to guests carrying `{sprinter_bad: bool, mired_speed: float}`.
- Audit all player-side modifier appliers (quiver, echoing, sprinter) for the same host/guest gap.
- **DoD:** `WYRD_NET=host` + guest join, inscribe chart with Mired Boots; guest's movement speed is visibly slower (a `print` probe is acceptable as verification in the headless dungeon smoke test).
- **Effort:** S

### Phase 3 — Active-affix HUD chips
- Add a small persistent HUD strip (below the vigor bar or corner of screen) that shows 1–3 icon chips per active affix, coloured green (good) or red (bad). Each chip fits in ≤24×24px using the affix name's first letter or a hand-picked icon char from the existing UI font.
- Chips appear on dungeon entry (fade-in 0.3s) and fade at run end.
- Tapping/hovering a chip shows the affix `good_desc` or `bad_desc` in a tooltip using the existing `crafting_bench` tooltip font stack.
- **DoD:** In a tier_1 run with two affixes, both chips appear within the first 2 seconds; hovering each chip shows the correct description text; a headless test confirms chip count matches `active_chart.affixes.size()`.
- **Effort:** M

### Phase 4 — Wave-3 affixes (post-cap expansion)
- Design 2–4 new affixes targeting `req_carto` 17–20 (beyond ADR 0006's demo cap — gated until cap lifts):
  - `gilded_road` (bias, lv 17): extra gold piles scatter alongside the gather nodes. Bad twin: coin purses weigh heavier — carry penalty on next vendor trip.
  - `echoing_arms` (modifier, lv 18): skills cost 15% less Focus. Bad twin: skills cost 15% more.
  - `sealing_fog` (pacing, lv 19): rooms seal on entry, enemies must be cleared before the door opens. Bad twin: the exit seals too — solve before leaving.
  - `twin_quarry` (modifier, lv 20): elites spawn in linked pairs. Bad twin: pairs share HP (killing one heals the other).
- Each new affix must have an ink that courts it (extend `INKS` or widen an existing ink's bias dict).
- **DoD:** All new affixes load in the `compute_weights` pool at matching carto level; each has a courting ink; inscribe call produces them at lv 17; existing tests green.
- **Effort:** M

### Phase 5 — VFX tells for active modifier twins
- `quiver` good twin: a brief golden shimmer on the bow at run start (existing hit-flash reuse).
- `Damp Strings` bad twin: a damp-drip particle on the bow at run start (reuse fog-particle if available, else a simple `CPUParticles3D` fade).
- `echoing` good twin / bad twin: a subtle regen halo / drain pulse on the player Focus bar (UI-layer, not 3D).
- See Plan.md Part B / Phase B6 for the broader inscribing-ritual feel pass — keep VFX adds scoped to in-dungeon readability only here.
- **DoD:** Each VFX fires exactly once at dungeon entry when the affix is active; no VFX appears on runs without the affix; no regression in existing headless test suites.
- **Effort:** S

## Dependencies & links

- [[system-charts-wayfinding]] — inscribing table, template pool, ink economy, and crafting bench that hosts the live odds panel; all affix rolls go through `charts.gd`.
- [[system-dungeon-generation]] — `dungeon_gen.GATHER_BY_AFFIX` scatters bias-affix nodes; `layout_loader._read_chart_modifiers` reads modifier twins into the combat vars; both must stay in sync with the AFFIXES pool.
- [[system-bosses]] — boss-den affixes (`hedgemother_den`, `burrow_boar_den`, `wolf_alpha_den`) are the only affixes that cannot roll randomly; their trophy-ink chain is the progression spine.
- [[system-elites]] — `marked_quarry` twins directly scale elite trophy-drop probability (×2 / ×0.5 in `layout_loader` line 306–308).
- [[system-gathering]] — `wellspring` twins alter yield and channel time inside `gather_node.gd`; bias affixes (mineral_vein, bramble_bloom, etc.) scatter GatherNode decor.
- [[system-trades-progression]] — `effective_stability` scales with carto level (+0.6 pts/lv); the `sure_lines` perk (lv 10) adds +5 stability; wave-3 affixes must respect the ADR 0006 demo cap.
- [[system-multiplayer-netcode]] — sprinter bad-twin slow and any future player-stat modifiers need RPC coverage for guests (Phase 2).
- [[system-hud]] — Phase 3 active-affix chips are a new HUD element; must sit within the HUD layout contract.
- **Plan.md Part B / Phase B6** — waystone chart-socketing animation and the inscribing-ritual feel pass are owned there; do not re-plan them here.

## Verification

**Phase 1 (balance audit)**
```
# Manual: open crafting bench, inscribe 10 charts at carto lv 1, record good/bad count.
# Check gilded bad_twin code comment exists in charts.gd.
```

**Phase 2 (multiplayer sync)**
```
cd wyrd
WYRD_NET_RUN=15 WYRD_NO_SAVE=1 godot --headless --path . -- --server &
WYRD_NO_SAVE=1 godot --headless --path . -- --client
# Expect: "mired_speed" log line on guest; no crash.
```

**Phase 3 (HUD chips)**
```
cd wyrd
WYRD_NO_SAVE=1 WYRD_DEV_CHART=tier_1 godot --path . &
# Verify chips appear within 2s of dungeon entry; hover shows desc text.
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd
# Must stay green; chip count assertion added to the script.
```

**Phase 4 (wave-3 affixes)**
```
cd wyrd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd
# Both green; no "affix id not found" warnings in output.
```

**Phase 5 (VFX)**
```
cd wyrd
WYRD_NO_SAVE=1 WYRD_DEV_CHART=tier_1 godot --path . &
# Manual: inscribe a chart with Quiver; enter dungeon; observe bow shimmer.
# Inscribe with Damp Strings; observe drip.
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd
# Green (VFX must not crash headless).
```

## Open questions

- **Gilded bad twin (Picked Clean):** is the zero-chest-bonus intentionally the punishment (i.e., the bad twin is purely "you got nothing extra"), or should it add a penalty (e.g., remove one normal chest)? The current bad_desc says "no extra chests" which matches a no-op, but a stronger bad twin would improve the tension. Decision for the user.
- **Post-cap timeline for wave-3:** ADR 0006 locks the demo at lv 17. Wave-3 affixes at req_carto 17–20 are unreachable until the cap lifts. Should they be added now (gated but present) or deferred entirely? Pre-adding them keeps the data consistent with future spec work; deferring reduces dead-code risk.
