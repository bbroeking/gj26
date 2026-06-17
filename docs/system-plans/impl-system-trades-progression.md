---
title: Wayfinding Ladder & Progression — Implementation Plan
parent: "[[system-trades-progression]]"
domain: Progression
type: implementation-plan
status: ready-to-build
effort: L
tags: [wayfinder, impl]
---

# Wayfinding Ladder & Progression — Implementation Plan

> Build doc for [[system-trades-progression]]. The level-up moment is unmissable and the mastery clusters give the player a meaningful permanent choice at each threshold level, with choice state surviving save/load.

## Build status — 2026-06-16
**Largely SHIPPED & gate-green.** Both halves of the DoD are live: the **pick-one-of-N mastery** (data model + modal + save/migration — see [[impl-system-skills-hotbar]]) and the **unmissable level-up moment** (gold perk banner + readout punch — see [[impl-system-hud]]). The **Ledger** (trophy→permanent stat) also lands here (see [[impl-system-items-affixes]]). Built at the "most choosy" ruling: pick-1 at lv 5/10/13/14/17.
**Remaining:** the Waystone den-level band preview before committing to a chart (overlaps [[impl-system-charts-wayfinding]]).

## Definition of done

- Crossing any level fires a visible burst + named-perk banner + HUD flash (Plan.md B3, verified by timer/logic test).
- At cluster levels (5, 10, 13, 14, 17) the game pauses with a mastery modal; the player picks one perk from the cluster; the unchosen ones are locked; the Trades page reflects chosen vs. locked state.
- `chosen_perks` round-trips through save/load; a fresh save defaults to all auto-unlocks only.
- `perk_active()` gates on `chosen_perks` for cluster-level perks, not just raw level threshold.
- `ledger.gd` exists, receives boss trophies, and `_derive_stats()` folds in ledger bonuses.
- Every chart in the Waystone panel shows a coloured difficulty-band label.
- `gather_bonus()` uses `"wayfinding"` keys exclusively (ADR 0012 cleanup).
- All five headless suites stay green after every task.

## Preconditions / dependencies

- **Plan.md Phase B3** — owns the burst/banner/HUD-flash feel. Tasks 1–3 below implement B3; do not ship them independently of Plan.md's B3 acceptance.
- [[impl-system-hud]] — `player_hud.gd` is the host for the level-up burst; any HUD structural changes there must land before or in the same PR as task 2.
- [[impl-system-save-load]] — `save_game.gd` must be extended in task 5 before any playtest that exercises level-ups in a real session.
- [[impl-system-skills-hotbar]] — the mastery modal (task 6) must not conflict with the skills picker; both block the hotbar, so modal-count logic (`game.gd:68–76`) handles re-entrancy.
- [[impl-system-bosses]] — task 8 (Ledger) depends on `drops.gd` boss trophy list being stable; `BOSS_DROP_COUNT` and trophy item defs must exist.
- **`ledger.gd`** does not exist yet — task 7 creates it.
- `data/drops.gd` — exists; contains `BOSS_DROP_COUNT := 3` (`drops.gd:23`); trophy item defs must be confirmed before task 8 adds ledger wiring.

## Tasks (ordered)

### Phase 1 — Level-up feel moment (Plan.md B3)

1. **Add `_on_leveled_up` burst trigger in `player_controller.gd`** — `player_controller.gd:_on_leveled_up` (add or extend). On `leveled_up` signal from `Game`, tween the player mesh's scale: `1.0 → 1.18 → 1.0` over 0.35 s (back-out easing, clone of spawn back-out in `creature_anim`), and pulse the ink-outline shader uniform from its current color to gold then back. Sketch: `tween.tween_property(_mesh, "scale", Vector3(1.18,1.18,1.18), 0.12).set_trans(Tween.TRANS_BACK)`; second step returns to `1.0`. _Verify:_ `WYRD_DEV_LEVEL=1 WYRD_SHOT=1 godot --path wyrd` then force a level-up via console; visually confirm the punch. Also add a `_test_burst_fires` case to `test_wyrd_loop.gd` asserting the `leveled_up` signal fires when XP crosses the threshold. _Effort:_ S.

2. **Add perk-banner toast in `game.gd:award_xp`** — `game.gd:287–294`. After `leveled_up.emit`, look up the perk(s) for `new_lv` in `PERKS["wayfinding"]` and call `notify("[perk.name] unlocked")`. For cluster levels (see task 4's `MASTERY_CLUSTERS`), emit `"Choose a mastery — open Trades (K)"` instead of naming any individual perk. Sketch: `var unlocked := PERKS[SKILL].filter(func(p): return int(p.lv) == new_lv)`. _Verify:_ headless `test_wyrd_loop.gd` assert banner text equals the correct perk name at lv 2 (`"Mara's Marginalia"`), lv 3 (`"Practiced Measures"`), and the choose-mastery string at lv 5. _Effort:_ S.

3. **HUD trade readout count-up flash in `player_hud.gd`** — `player_hud.gd:227` (`leveled_up` lambda). Replace the plain `_refresh_trades()` call with a brief animated count-up: store the current displayed level, connect the `leveled_up` signal to a new `_animate_level_flash(new_lv)` func that tweens a `Label` color from `WyrdUi.GOLD` to `WyrdUi.INK` over 0.6 s while the count steps from `old_lv` to `new_lv`. _Verify:_ `WYRD_UI_SHOT=trades` screenshot shows the level numeral in gold immediately after a forced level-up; `test_wyrd_loop.gd` asserts `leveled_up` fires (signal path intact). _Effort:_ S.

### Phase 2 — Pick-one-of-N mastery choice

4. **Add `MASTERY_CLUSTERS` constant and `perk_cluster(lv)` helper in `game.gd`** — `game.gd` after the `PERKS` block (~line 459). Define `const MASTERY_CLUSTERS: Array = [5, 10, 13, 14, 17]` and a pure function `func perk_cluster(lv: int) -> Array` that returns the sub-array of `PERKS[SKILL]` whose `p.lv == lv` when `lv` is in `MASTERY_CLUSTERS`, else `[]`. Sketch: `return PERKS[SKILL].filter(func(p): return int(p.lv) == lv) if lv in MASTERY_CLUSTERS else []`. _Verify:_ `test_wyrd_loop.gd` assert `perk_cluster(5).size() == 4`, `perk_cluster(10).size() == 4`, `perk_cluster(2).size() == 0`. _Effort:_ S.

5. **Add `chosen_perks: Array` to game state and save/load** — `game.gd:102–127` (state block) + `save_game.gd:14–36` (save) + `save_game.gd:56–113` (load). Declare `var chosen_perks: Array = []` next to `trades`. In `SaveGame.save()` add `"chosen_perks": game.chosen_perks`. In `load_into()` after the trades block, restore `game.chosen_perks = []` and append each `String(id)`. Default (missing key in old saves) = `[]` — auto-unlocks still work because `perk_active()` will be updated next. _Verify:_ `test_wyrd_loop.gd` new case: `game.chosen_perks = ["curious_fingers"]; SaveGame.save(game); SaveGame.load_into(g2); assert g2.chosen_perks.has("curious_fingers")` (headless, `WYRD_NO_SAVE=1` skips the real file). _Effort:_ S.

6. **Update `perk_active()` to require `chosen_perks` for cluster perks** — `game.gd:461–465`. Change to: if the perk's level is in `MASTERY_CLUSTERS`, return `chosen_perks.has(perk_id)`; otherwise return `trade_lv(SKILL) >= int(perk.lv)`. Sketch:
   ```
   func perk_active(_trade: String, perk_id: String) -> bool:
       for perk in PERKS[SKILL]:
           if String(perk.id) == perk_id:
               if int(perk.lv) in MASTERY_CLUSTERS:
                   return chosen_perks.has(perk_id)
               return trade_lv(SKILL) >= int(perk.lv)
       return false
   ```
   _Verify:_ `test_wyrd_loop.gd` assert: at lv 5, `curious_fingers` inactive before choice; after `game.chosen_perks.append("curious_fingers")` it's active; `double_ore` stays inactive. Also confirm that existing auto-unlock perks (lv 2 `marginalia`, lv 3 `practiced_measures`, lv 12 `quick_nock`) still return true at threshold. Run `test_skills.gd` and `test_wyrd_loop.gd`. _Effort:_ S.

7. **Emit `perk_choice_pending` signal on cluster level-up** — `game.gd:27–34` (signals block) + `game.gd:287–294` (award_xp). Add `signal perk_choice_pending(lv: int, candidates: Array)`. In `award_xp`, after `leveled_up.emit`, if `perk_cluster(new_lv).size() > 0`, emit `perk_choice_pending(new_lv, perk_cluster(new_lv))` instead of the banner. _Verify:_ `test_wyrd_loop.gd` assert signal fires with the correct candidates array when XP is force-pumped to lv 5. _Effort:_ S.

8. **Build `MasteryChoiceModal` scene/script** — create `wyrd/scripts/mastery_choice_modal.gd` (new file; mirrors `shrine_choice_modal.gd` structure). On `setup(lv, candidates)`: build N candidate cards (one per perk) with name + desc, a title "Choose a Mastery", pause the tree via `Game.modal_opened()`, emit `chosen(perk_id: String)` on confirm, call `Game.modal_closed()` then `queue_free()`. Wire `.tscn` for the CanvasLayer node (minimal: just the script binding, same pattern as `shrine_choice_modal.gd`). The modal must block keyboard/gamepad from closing without choosing (no `ui_cancel` handler — mastery is permanent). _Verify:_ playtest via `WYRD_DEV_LEVEL=4 godot --path wyrd`, gain enough XP to hit lv 5, modal appears; choosing a perk dismisses it and activates the correct perk (check Trades page). _Effort:_ M.

9. **Wire `perk_choice_pending` to open `MasteryChoiceModal` in town and dungeon scenes** — `wyrd/scripts/town.gd` and the dungeon scene root (likely `wyrd/scenes/World.tscn`'s root script). Connect `Game.perk_choice_pending` in each scene's `_ready`; on signal, instantiate and add child `MasteryChoiceModal`; in the `chosen` callback, append to `Game.chosen_perks`, call `Game.save_now()`, and notify the perk name. Sketch: `game.perk_choice_pending.connect(func(lv, cands): _open_mastery_modal(lv, cands))`. _Verify:_ `WYRD_DEV_LEVEL=4 WYRD_FAST_CHANNEL=1 godot --path wyrd`, gather to lv 5 — modal fires in town. Reload the save and confirm the chosen perk still shows active in Trades. _Effort:_ S.

10. **Update Trades page ladder in `inventory_panel.gd` to show chosen vs. locked state** — `inventory_panel.gd:864–899` (card loop). Change the `ok` boolean: for cluster perks, `ok = game.chosen_perks.has(String(p.id))`; for others keep `ok = lv >= pl`. For cluster perks that are at a reachable level but not chosen (i.e., `lv >= pl` and not in `chosen_perks`), show a third state: card dimmed with an amber ring and label `"✗ not chosen"`. Sketch:
   ```
   var is_cluster: bool = int(p.lv) in game.MASTERY_CLUSTERS
   var ok: bool = is_cluster and game.chosen_perks.has(String(p.id))
   var reachable_not_chosen: bool = is_cluster and lv >= int(p.lv) and not ok
   ```
   _Verify:_ `WYRD_UI_SHOT=trades` screenshot after choosing `curious_fingers` at lv 5 shows it earned, and `double_ore` / `keen_eye` / `steady_hands` show `"✗ not chosen"`. _Effort:_ S.

### Phase 3 — Ledger stat source

11. **Create `wyrd/scripts/ledger.gd`** (new file — does not exist). A `RefCounted` with `var trophies: Array = []` and:
    - `func add_trophy(id: String) -> void` — appends if not already present.
    - `func total_stat(stat: String) -> int` — sums the capped stat boost for each trophy. Consult `data/drops.gd` for trophy IDs; assign a flat bonus per tier (tier-1 boss trophy: +1 damage, tier-2: +2, tier-3: +3). Cap per-stat total at +6. Return `int`.
    Sketch:
    ```
    const TROPHY_BONUSES := {
        "burrow_boar_trophy": {"damage": 1},
        "wolf_alpha_trophy": {"damage": 2},
        "hedgemother_trophy": {"damage": 3},
    }
    const STAT_CAP := 6
    func total_stat(stat: String) -> int:
        var s := 0
        for id in trophies:
            s += int((TROPHY_BONUSES.get(id, {}) as Dictionary).get(stat, 0))
        return mini(s, STAT_CAP)
    ```
    _Verify:_ in `test_wyrd_loop.gd`, `var l := load("res://scripts/ledger.gd").new(); l.add_trophy("burrow_boar_trophy"); assert l.total_stat("damage") == 1; l.add_trophy("hedgemother_trophy"); assert l.total_stat("damage") == 4`. _Effort:_ S.

12. **Add `ledger` to `game.gd` state and save/load** — `game.gd:102` (state block) + `save_game.gd`. Declare `const LedgerScript = preload("res://scripts/ledger.gd")` at the top of `game.gd`, then `var ledger: RefCounted = LedgerScript.new()`. In `SaveGame.save()` add `"ledger_trophies": game.ledger.trophies`. In `load_into()` restore `game.ledger = LedgerScript.new(); for id in data.get("ledger_trophies", []): game.ledger.add_trophy(String(id))`. Old saves with no `ledger_trophies` key get an empty ledger (safe). _Verify:_ add a trophy, save, reload — headless round-trip test in `test_wyrd_loop.gd`. _Effort:_ S.

13. **Wire ledger bonuses into `_derive_stats()`** — `player_controller.gd:1117–1129` (after the perk pass, before the final `derived_stats` dict). Add:
    ```
    var ledger_dmg := 0
    if game_h != null and game_h.has_method("get"):
        var lg = game_h.get("ledger")
        if lg != null:
            ledger_dmg = int(lg.total_stat("damage"))
    ```
    Then add `ledger_dmg` to `derived_stats.damage`. Trophy bonuses are flat (not multiplied by `LEVEL_POWER`). _Verify:_ `test_wyrd_loop.gd` — create a game node, add a `burrow_boar_trophy` to its ledger, attach a mock player, call `_derive_stats()` and assert `derived_stats.damage` is 1 higher. _Effort:_ S.

### Phase 4 — Den-level band preview

14. **Add `difficulty_band(chart)` helper in `game.gd`** — after `run_cfg()` (~line 766). Pure function: takes a chart dict, computes `den_level = ({1:3, 2:8, 3:13}).get(int(chart.get("tier",1)), 3)`, then `delta = den_level - trade_lv()`. Returns a tuple-as-dict `{"label": String, "color": Color}`: delta ≤ −2 → `{"label": "Cozy farming", "color": WyrdUi.SAGE}`; −1..+1 → `{"label": "Fair fight", "color": WyrdUi.GOLD}`; ≥ +2 → `{"label": "Very hard", "color": WyrdUi.TERRACOTTA}`. Import `WyrdUi = preload("res://scripts/ui/wyrd_ui.gd")` at top of `game.gd` (check if already preloaded). _Verify:_ `test_wyrd_loop.gd` assert `difficulty_band({"tier":1}).label == "Cozy farming"` at lv 5; `"Very hard"` at lv 1 + tier 3. _Effort:_ S.

15. **Surface band label in `waystone_panel.gd:_render`** — `waystone_panel.gd:107–148`. After `b.text = ChartsData.chart_label(chart)`, append the band label to the button text as a short suffix: `" · Cozy farming"` / `" · Fair fight"` / `" · Very hard"`. Color the band text via a `RichTextLabel` chip or by setting `b.add_theme_color_override("font_color", band.color)` for the selected slot. In the detail block, prepend the band line to `_detail.text`. _Verify:_ `WYRD_DEV_LEVEL=3 WYRD_DEV_CHART=tier_3 WYRD_SHOT=1 godot --path wyrd`, open the Waystone panel — screenshot confirms "Very hard" label in terracotta. _Effort:_ S.

### Phase 5 — XP faucet audit & cleanup

16. **Fix `gather_bonus()` legacy trade keys** — `game.gd:469–478`. Replace `perk_active("wilds", "keen_eye")` → `perk_active("wayfinding", "keen_eye")`, `perk_active("wilds", "clean_splits")` → `perk_active("wayfinding", "clean_splits")`, `perk_active("earth", "double_ore")` → `perk_active("wayfinding", "double_ore")`. Functional behaviour is unchanged (perk_active already ignores the trade key); this is ADR 0012 consistency cleanup. _Verify:_ `test_wyrd_loop.gd` — existing perk tests (`keen_eye on at wilds 5`, `clean_splits on at wilds 10`, `double_ore rolls near 25%`) must still pass. Run all five suites. _Effort:_ XS.

17. **Author `test_xp_pace.gd` sim script** — new file at `wyrd/test_xp_pace.gd`. A headless script (not a gate test, so it prints and exits 0 always) that simulates one loop per level: each loop awards `gather_xp * 3 + craft_xp + chart_completion_xp` using the real constants from `game.gd`/`charts.gd`. Print a table: `lv | xp_to_next | loops_to_next | perks_unlocked`. Identify dead zones (consecutive levels with no new perk AND XP gate > 1.3× the previous). Run with `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_xp_pace.gd`. _Verify:_ script executes without error and prints a 17-row table. Review output manually — no automated gate. _Effort:_ S.

## First commit (smallest shippable slice)

**Tasks 4 + 5 + 6** — `MASTERY_CLUSTERS` constant, `chosen_perks` state + save/load round-trip, and the updated `perk_active()` gate. This is purely additive data-model work with no visible UI change, all existing tests stay green, and it is the prerequisite for every other mastery task. Acceptance: `test_wyrd_loop.gd` passes with new assertions (task 4 cluster size + task 6 perk-active gate logic).

## Test & verification plan

| Phase | Suite / Method | What it checks |
|---|---|---|
| B3 burst | `test_wyrd_loop.gd` | `leveled_up` signal fires; banner text = correct perk name at lv 2/3; cluster string at lv 5 |
| B3 HUD | `WYRD_UI_SHOT=trades` screenshot | gold flash on level numeral |
| Mastery data model | `test_wyrd_loop.gd` | `perk_cluster(5).size()==4`; perk inactive before choice; active after; only one cluster active; save/load round-trip |
| Mastery modal | playtest `WYRD_DEV_LEVEL=4` | modal appears on lv 5 crossing; perk sticks in Trades after reload |
| Trades page state | `WYRD_UI_SHOT=trades` | chosen perk = "✓ earned"; unchosen cluster perks = "✗ not chosen" |
| Ledger unit | `test_wyrd_loop.gd` | `total_stat("damage")` sums + caps correctly; round-trips save |
| Ledger stats | `test_wyrd_loop.gd` | `_derive_stats()` produces correct delta with a ledger trophy present |
| Band preview | `WYRD_DEV_LEVEL=3 WYRD_DEV_CHART=tier_3 WYRD_SHOT=1` | "Very hard" in terracotta in waystone panel |
| Band logic | `test_wyrd_loop.gd` | `difficulty_band` returns correct label at each delta bucket |
| XP cleanup | all five headless suites | gather perk tests still green after key rename |
| XP sim | `test_xp_pace.gd` (manual review) | 17-row pace table prints; no dead zones flagged |

All headless runs: `cd wyrd && WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` (and equivalent for the other four suites).

## Risks & open questions

1. **Mastery permanence vs. per-run**: this plan implements permanent choice (locked in the Trades page). The parent note recommends a "respec at the inscribing table for one uncommon ink" escape hatch — that feature is a followup and not scoped here. Decide before shipping task 9 whether a respec verb is in-scope for the same PR.
2. **Cluster balance at lv 5**: four perks cover four distinct flavors (chart-carto / earth-gather / wilds-gather / combat-crit). `curious_fingers` (chart) and `keen_eye` (wilds) are clearly differentiated. `double_ore` (earth) and `steady_hands` (combat) are narrow. Playtest may show one option dominates — balance pass is post-B3.
3. **`LEVEL_POWER` re-tune**: wiring ledger bonuses (task 13) adds +1–3 flat damage on top of the `pf` scale. At high levels this may push the player above the difficulty band. Re-tune `LEVEL_POWER` or the trophy bonus caps after the first real playthrough with ledger active.
4. **Trophy ID alignment**: `ledger.gd`'s `TROPHY_BONUSES` dict must match the actual trophy item `kind_id` values in `data/drops.gd`. Confirm before shipping task 11 — if the trophy IDs don't exist yet, task 11 blocks on [[impl-system-bosses]].
5. **`WyrdUi` preload in `game.gd`**: task 14 requires `WyrdUi` in `game.gd`. If it creates a circular dependency (WyrdUi imports anything that imports game.gd), extract `difficulty_band` to a pure static helper in `charts.gd` instead, or inline the color constants.
6. **`class_name` in headless**: `MasteryChoiceModal` (task 8) must NOT use `class_name` — use `preload` const at call sites, per the headless test harness gotcha.
