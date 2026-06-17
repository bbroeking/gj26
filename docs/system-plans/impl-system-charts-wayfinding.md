---
title: Charts & Wayfinding — Implementation Plan
parent: "[[system-charts-wayfinding]]"
domain: Wayfinding & Dungeons
type: implementation-plan
status: ready-to-build
effort: L
tags: [wayfinder, impl]
---

# Charts & Wayfinding — Implementation Plan

> Build doc for [[system-charts-wayfinding]]. Done when the waystone panel shows colour-coded affix previews + XP estimates, the inscription bench enforces a chart-case cap and enforces trophy uniqueness, the inscription ritual animates a sequential affix reveal with table glow and seal SFX, and a completion debrief toast fires with the Tyrannical XP bonus line.

## Definition of done

- `waystone_panel.gd`: each affix line is coloured (`WyrdUi.GOLD` / `WyrdUi.TERRACOTTA`), a tier badge renders beside the chart name, and an expected-XP line appears under the affix block.
- `crafting_bench.gd`: inscription at a full chart case (≥8) is blocked with a "Chart case full" message; `craft()` returns false and the Craft button disables.
- `crafting_bench.gd` + `inscribing_table.gd`: pressing Craft triggers a ≤1.2 s sequential affix reveal — table glow pulse, then per-affix overshoot pop — driven by a coroutine `_reveal_affixes()` on `BenchView`.
- `sfx.gd`: `"inscribe_seal"` key registered (graceful no-op until audio file lands).
- `game.gd`: `return_to_town()` fires a `run_completed` signal (with `chart` + `xp` payload) on non-abandoned exits; `player_hud.gd` subscribes and shows a 3 s debrief toast listing affix names + the Tyrannical bonus line when applicable.
- `test_wyrd_loop.gd` assertion: `run_completed` fires with `xp > 0` on a non-abandoned run.
- All four headless suites green after every task.

## Preconditions / dependencies

- **Plan.md B0** (`data/feel.gd` tunables + audio scaffolding) — the sequential reveal duration constant should live in `feel.gd` once B0 lands. Tasks here hard-code `0.18 s` per affix as a fallback; replace with `Feel.INSCRIBE_REVEAL_STEP` when B0 ships. Phase 1 (inscription ritual) is strictly unblocked without B0 — the glow + reveal animation work today; only the SFX path benefits from B0's scaffolding.
- **Plan.md B5** (craft station reaction) — shares the `stamp()` + `_pops` machinery; B5 must not regress that path.
- `data/feel.gd` does **not** exist yet — tasks reference it as a future constant; fallback literals in place until B0 creates it.
- [[impl-system-audio-music]] — `"inscribe_seal"` SFX file generation; `sfx.gd` key is a stub until then.
- [[impl-system-hud]] — the run-completed debrief overlay surface (Task 7) could conflict if HUD refactor lands simultaneously; coordinate merge order.
- [[impl-system-dungeon-generation]] — `briar_maze` decor is out of scope here (see parent note Phase 5); `dungeon_gen.gd` is NOT touched by this plan.

## Tasks (ordered)

### Phase A — Waystone panel preview (independent, ships first)

1. **Colour-code affix lines in waystone panel** — `waystone_panel.gd:_render()` (l. 131–144). Replace the plain `Label` with a `RichTextLabel` (BBCode) or keep `Label` per-line and set per-line colour via `add_theme_color_override`. Pattern: `if bool(a.get("good", false)): col = WyrdUi.GOLD else: col = WyrdUi.TERRACOTTA`. Each affix gets its own `Label` child appended to `_detail`'s parent container — replace the single `_detail` Label with a `VBoxContainer _detail_box` containing one Label per affix. _Verify:_ `WYRD_UI_SHOT=waystone` screenshot — good-twin lines gold, bad-twin lines terracotta. _Effort:_ S.

2. **Add tier badge to chart list button** — `waystone_panel.gd:_render()` (l. 123–129). Amend `b.text` to prefix with a tier badge: `"T%d  %s" % [int(chart.get("tier", 1)), ChartsData.chart_label(chart)]`. Use `WyrdUi.TERRACOTTA` font colour on a selected button (already handled by `mark_selected`). _Verify:_ `WYRD_UI_SHOT=waystone` shows "T1", "T2" badges on each button row. _Effort:_ S.

3. **Expected-XP line under detail block** — `waystone_panel.gd:_render()` (l. 143–148). After the affix lines are built, append a final Label: `"≈ %d xp on completion" % ChartsData.completion_xp(chart)`. Use `WyrdUi.style_dim` (13 pt). Call `ChartsData.completion_xp(chart)` — already a `static func` in `data/charts.gd` l. 399. _Verify:_ `WYRD_UI_SHOT=waystone` — XP line present; a snug chart (0 affixes) shows "≈ 75 xp". _Effort:_ S.

### Phase B — Chart-case cap + trophy guard (independent)

4. **Chart-case cap constant in game.gd** — `game.gd:add_chart()` (l. 649–657). Add `const CHART_CASE_MAX := 8` near the chart-case section. In `add_chart()`, guard at the top: `if (charts as Array).size() >= CHART_CASE_MAX: notify("Chart case full (%d/%d) — socket one first." % [CHART_CASE_MAX, CHART_CASE_MAX]); return`. _Verify:_ `test_wyrd_loop.gd` — call `add_chart()` 9 times; assert `charts.size() == 8`. _Effort:_ S.

5. **Bench Craft button disabled at cap** — `crafting_bench.gd:craft()` (l. 188–208) + `BenchView._draw_result()` (l. 780–839). In `craft()`, before spending: `if _game != null and (_game.charts as Array).size() >= int(_game.CHART_CASE_MAX): _game.notify("Chart case full — socket a chart at the Waystone first."); return false`. In `_draw_result()`, compute `var case_full: bool = _game != null and (_game.charts as Array).size() >= int(_game.CHART_CASE_MAX)` and pass `can and not case_full` to `WyrdUi.draw_carved_button`. Draw a "Case full (8/8)" dim string above the Craft button when `case_full`. _Verify:_ `test_wyrd_loop.gd` — fill chart case to 8, assert `craft()` returns false. _Effort:_ S.

6. **Waystone trophy-slot uniqueness warning** — `waystone_panel.gd:_render()` (l. 131–148). After building the affix detail block, check whether any boss-den affix on the selected chart is a bad twin (good == false for a "boss" kind affix) — if so, append a dim warning: `"⚠ Den affix resolved bad — boss won't appear."` using `WyrdUi.TERRACOTTA`. This surfaces the existing bad-twin roll result clearly at the socket step. _Verify:_ `WYRD_UI_SHOT=waystone` with a bad-twin den affix chart loaded in dev save — warning line appears. _Effort:_ S.

### Phase C — Inscription ritual (B6 — the signature)

7. **Register `inscribe_seal` SFX key in sfx.gd** — `sfx.gd:PATHS` (l. 8–38). Add `"inscribe_seal": "res://audio/inscribe_seal.mp3"` to the `PATHS` dict. File absent = graceful no-op (existing pattern). _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_loop.gd` stays green; no crash from missing key. _Effort:_ S.

8. **Extend BenchView stamp → two-stage coroutine** — `crafting_bench.gd:BenchView.stamp()` (l. 311–313) + new `_reveal_affixes(affixes: Array)` coroutine method. Change `stamp()` to call `Sfx.play("inscribe_seal")` and launch `_reveal_affixes.call_deferred(bench._last_inscribed_affixes)`. Add `var _reveal_index := -1` state var to `BenchView`. `_reveal_affixes(affixes)` is an `async` coroutine (uses `await get_tree().create_timer(STEP).timeout` where `STEP := 0.18`): loop over `affixes`, for each increment `_reveal_index`, call `pop("affix%d" % _reveal_index)`, then await. Cap total to ≤1.2 s (≤6 affixes × 0.18 s + 0.12 s stamp = 1.2 s). Add `var _last_inscribed_affixes: Array = []` to the `CraftingBench` class and populate it in `craft()` before calling `_view.stamp()`: `_last_inscribed_affixes = (chart as Dictionary).get("affixes", []).duplicate()`. _Verify:_ `WYRD_UI_SHOT=inscribing` — stamp appears, then affixes pop one by one. Manual play-test: timing ≤ 1.2 s. _Effort:_ M.

9. **Colour-tint per-affix pop in result panel** — `crafting_bench.gd:BenchView._draw_result()` (l. 780–839). In the odds/affix draw loop, when rendering an affix row that has already resolved (index < `_reveal_index`), use `WyrdUi.GOLD` for good-twin rows and `WyrdUi.TERRACOTTA` for bad-twin rows instead of the default `TXT`. Gate the colour on `_reveal_index >= i` so rows that haven't revealed yet stay hidden (draw nothing / dim placeholder). _Verify:_ Manual screenshot — revealed good-twin rows gold, bad-twin terracotta, unrevealed rows blank. _Effort:_ S.

10. **Table glow pulse signal from bench** — `inscribing_table.gd:_ready_interactable()` (l. 24–38) + `crafting_bench.gd:craft()`. `InscribingTable` already holds an `OmniLight3D glow` (energy 1.4). Add `func pulse_glow() -> void` to `InscribingTable` that tweens `glow.light_energy` from 1.4 → 3.0 → 1.4 over 0.6 s using `create_tween()`. In `craft()` on `CraftingBench`, after `_view.stamp()`, find the table node: `var table := get_tree().get_nodes_in_group("inscribing_table").front()` (requires `InscribingTable._ready_interactable()` to call `add_to_group("inscribing_table")`). Call `table.pulse_glow()` if found. _Verify:_ `WYRD_UI_SHOT=inscribing` — the table glow visibly brightens in the 3D scene behind the panel. _Effort:_ S.

### Phase D — Run-completed debrief (Plan.md B6 companion)

11. **Add `run_completed` signal + debrief helper to game.gd** — `game.gd` near existing signals (l. 27–34). Add `signal run_completed(chart: Dictionary, xp: int)`. In `return_to_town()` (l. 709–733), after `award_xp("carto", xp)`, emit: `run_completed.emit(active_chart, xp)`. Keep existing `notify()` toast. _Verify:_ Add assertion to `test_wyrd_loop.gd`: connect `run_completed`, simulate a `return_to_town()` call, assert signal fires with `xp > 0`. _Effort:_ S.

12. **Debrief toast in player_hud.gd** — `player_hud.gd:_build_wyrd_overlay()` (l. 133–) + new `_on_run_completed(chart, xp)` method. In `_build_wyrd_overlay()`, after connecting `game.toast`, also connect `game.run_completed.connect(_on_run_completed)`. `_on_run_completed(chart: Dictionary, xp: int)` builds a multi-line toast string: chart name on line 1, each affix as "✓ Good Twin name" or "✗ Bad Twin name" on subsequent lines, then "Wayfinder XP: +N"; if `tyrannical` good-twin is present, append "(+30% Tyrannical bonus)". Call `show_toast(msg)`. _Verify:_ `WYRD_DEV_CHART=tier_1 WYRD_NO_SAVE=1` playthrough — complete a Tyrannical chart, debrief toast shows affix names + bonus line. `test_wyrd_loop.gd` new assertion for `run_completed` signal with `xp > 0`. _Effort:_ S.

13. **Bad-twin active-affix chip on dungeon HUD** — `player_hud.gd:_build_wyrd_overlay()` (after task 12). On dungeon entry, read `get_node("/root/Game").active_chart.affixes` and build a small `HBoxContainer` of Label chips for each bad twin (`WyrdUi.TERRACOTTA` bg, white text, bad_name string). Show this chip row only `in_dungeon`. This surfaces `frenzied` bad ("Seething") and `sprinter` bad ("Mired Boots") silently-applied penalties that the parent note (gap 8) flags as missing feedback. _Verify:_ `WYRD_DEV_CHART=tier_1 WYRD_NO_SAVE=1` — enter a chart that rolled a bad twin; the bad-twin chip appears in the HUD corner. _Effort:_ S.

## First commit (smallest shippable slice)

**Tasks 1–3 (waystone panel polish):** colour-coded affix lines, tier badge, XP estimate. These are pure UI reads — no logic changes, no test regression risk, immediately visible value in the Waystone. Acceptance: `WYRD_UI_SHOT=waystone` confirms gold/terracotta colouring and "≈ N xp" line. All four headless suites green.

## Test & verification plan

| Task(s) | Verification method |
|---|---|
| 1–3 (waystone preview) | `WYRD_UI_SHOT=waystone` screenshot; `test_wyrd_transitions.gd` green |
| 4–5 (case cap) | `test_wyrd_loop.gd` — add 9 charts, assert size=8; craft() returns false at cap |
| 6 (den warning) | Dev save with bad-twin boss affix + `WYRD_UI_SHOT=waystone` |
| 7 (SFX key) | `test_wyrd_loop.gd` headless — no crash from missing audio file |
| 8–9 (reveal coroutine) | `WYRD_UI_SHOT=inscribing`; manual play-test timing ≤ 1.2 s |
| 10 (table glow) | Manual screenshot of 3D scene behind open bench panel |
| 11 (signal) | New assertion in `test_wyrd_loop.gd` — `run_completed` fires with `xp > 0` |
| 12 (debrief toast) | `WYRD_DEV_CHART=tier_1 WYRD_NO_SAVE=1` Tyrannical run → toast shows bonus line |
| 13 (bad-twin chip) | `WYRD_DEV_CHART=tier_1 WYRD_NO_SAVE=1` bad-twin run → chip in HUD |

All four suites (`test_wyrd_loop.gd`, `test_wyrd_dungeon_scene.gd`, `test_wyrd_transitions.gd`, `test_skills.gd`) run with `WYRD_NO_SAVE=1` after every task.

No new test suite required — `test_wyrd_loop.gd` absorbs the chart-case cap and `run_completed` signal assertions. The bad-twin chip (task 13) is playtest-verified only (HUD is not exercised headlessly).

## Risks & open questions

1. **`_reveal_affixes` coroutine in a freed node.** If the player closes the bench panel mid-reveal, `BenchView` is freed while the coroutine is awaiting. Guard with `if not is_instance_valid(self): return` after each `await` step (standard Godot pattern).
2. **`BenchView` is an inner class** — `class_name` registration is blocked in headless. The `_last_inscribed_affixes` field lives on the outer `CraftingBench` node (not the inner `BenchView`) to keep the public API testable without pixel drag.
3. **`Feel.INSCRIBE_REVEAL_STEP` is not yet defined** (B0 unshipped). Task 8 hard-codes `0.18` as a literal; leave a `# TODO: replace with Feel.INSCRIBE_REVEAL_STEP` comment so B0 can land it without touching reveal logic.
4. **Chart-case cap decision: 8 or perk-expandable?** Parent note open question 1 — `CHART_CASE_MAX := 8` is a const in `game.gd` for now. A future "Chartmaster's Satchel" perk could replace the const with a computed func. No design decision needed to ship task 4.
5. **Debrief toast vs full-screen overlay.** Parent note open question 2 recommends toast now, overlay in Phase 6 (Tier 3). Task 12 implements the toast only. If the design decision changes before shipping, the `run_completed` signal stays — only the subscriber in `player_hud.gd` changes.
6. **`get_nodes_in_group("inscribing_table")` may return empty** in dev boots that skip Town.tscn. Task 10 null-guards the call — no crash, no glow pulse in dev mode.
7. **Tier 2+ exclusive affixes and `briar_maze` decor** are parent-note Phases 4–5 and are explicitly out of scope here. They depend on this plan's affix engine being stable (it is) and on [[impl-system-dungeon-generation]] for the decor pass. File those as a follow-on impl note.

## Build status — 2026-06-16

**Phase A (Tasks 1–3 + Task 6) — SHIPPED** in `wyrd/scripts/ui/waystone_panel.gd`.

Changes made (waystone_panel.gd only):
- **Task 1** — Replaced single `_detail: Label` with `_detail_box: VBoxContainer`. Each affix gets its own `Label`; good twins coloured `WyrdUi.SAGE`, bad twins `WyrdUi.TERRACOTTA`. Stability % appended to good-twin lines (`(%d%% stable)` from `base_stab`; no carto level stored on chart dict so base value used — accurate for the default preview).
- **Task 2** — Tier badge prefixed to every chart button: `"T%d  %s" % [tier, chart_label]`.
- **Task 3** — Expected-XP dim label appended at the bottom of the detail block via `ChartsData.completion_xp(chart)`.
- **Task 6** — Boss-den bad-twin warning `"⚠ Den affix resolved bad — boss won't appear."` appended in TERRACOTTA when any resolved affix has `kind == "boss"` and `good == false`.

Select→socket→enter flow, `_on_go()`, `_close()`, `_unhandled_input()`, and all public method signatures preserved unchanged. No other files touched.

**Phase B–D** (tasks 4–13) — deferred; require edits to game.gd, crafting_bench.gd, inscribing_table.gd, sfx.gd, player_hud.gd — outside this agent's scope.
