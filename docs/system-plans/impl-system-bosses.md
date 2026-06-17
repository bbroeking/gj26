---
title: Bosses, Trophies & Den Progression — Implementation Plan
parent: "[[system-bosses]]"
domain: Enemies & Combat
type: implementation-plan
status: ready-to-build
effort: M
tags: [wayfinder, impl]
---

# Bosses, Trophies & Den Progression — Implementation Plan

> Build doc for [[system-bosses]]. Done when every boss kind shows its correct name on the bar, the Ledger turns accumulated trophies into capped persistent stat bonuses (saved and loaded), the Inscribing Table previews den difficulty, and the hedgemother_queen gains a distinguishing phase-3 summon.

## Build status — 2026-06-16
**Boss-bar per-kind name + the Ledger SHIPPED & gate-green.** `BOSS_KINDS` now carries a `name` per kind; `boss_bar.set_boss_name()` (renamed off the engine's `Node.set_name`) drives the banner, so the Burrow Boar / Wolf Alpha / Queen no longer read "The Hedgemother" — the "Unyielding" tag stays (root/snared immunity is shared `Boss` base behaviour). Ledger trophy→stat is live (see [[impl-system-items-affixes]] build status).
**Remaining:** per-chart boss-kind swap wiring, the Inscribing-Table den-difficulty preview (overlaps [[impl-system-charts-wayfinding]]), and the Queen's phase-3 summon.

## Definition of done

- `boss_bar.gd` never shows "The Hedgemother" for a Boar or Wolf fight.
- `ledger.gd` exists; `game.gd` exposes `apply_ledger_bonuses()`; `player_controller._derive_stats()` calls it; the bonus survives a save/load round-trip.
- The crafting bench result slot shows den level + difficulty band when a trophy is socketed.
- Entering the Queen's phase 3 spawns ≥ 2 skeletons and produces a wider red telegraph disc; standard Hedgemother does not.
- All four headless suites stay green.

## Preconditions / dependencies

- `ledger.gd` **does not exist** — Task 3 creates it.
- [[impl-system-combatant-ai]] — `boss.gd` extends `combatant.gd`; HP, hurtbox, and death signals must remain stable.
- [[impl-system-charts-wayfinding]] — `TROPHY_TO_AFFIX` and `AFFIXES` in `charts.gd` are read directly; the bench and den-level preview depend on them.
- [[impl-system-trades-progression]] — `game.trade_lv("wayfinding")` drives the difficulty band comparison (Phase 2) and the Ledger cap math.
- [[impl-system-save-load]] — Ledger bonuses ride `save_game.gd`; Task 6 adds the field to the save dict.
- [[impl-system-hud]] — `boss_bar.gd` is a separate CanvasLayer; Task 1 touches only `prime()` and `set_phase()`.
- Plan.md Part A (combat-feel) is shipped; Part B (loop-feel B0–B7) is in progress — den-difficulty readout (Task 4) complements B6.

## Tasks (ordered)

### Phase 1 — Boss bar label fix (first commit, unblocks correctness)

1. **Add `display_name` to every `BOSS_KINDS` entry** — `layout_loader.gd:142–155`.
   Add `"display_name"` key to each of the four entries:
   ```
   "hedgemother":       "The Hedgemother"
   "burrow_boar":       "The Burrow Boar"
   "wolf_alpha":        "The Wolf Alpha"
   "hedgemother_queen": "The Hedgemother, Queen of Thorns"
   ```
   _Verify:_ `grep "display_name" wyrd/scripts/layout_loader.gd` shows 4 hits. _Effort:_ S.

2. **Pass `display_name` from `_build_boss()` to `bossbar.prime()`** — `layout_loader.gd:703`.
   Change `bossbar.prime(boss_hp)` to `bossbar.prime(boss_hp, String(def.get("display_name", "Boss")))`.
   The `_build_boss()` function already has `def` (the BOSS_KINDS entry) and `bossbar` in scope at line 703.
   _Verify:_ compile check (no unresolved symbols). _Effort:_ S.

3. **Update `boss_bar.gd:prime()` and `set_phase()` to use the injected name** — `boss_bar.gd:33,49`.
   - `prime(mx: int, display_name: String = "The Hedgemother") -> void` — store `_boss_name := display_name`; replace the hardcoded literal at line 37 with `WyrdUi.set_meter(_meter, 1.0, _boss_name + " — Unyielding")`.
   - Add `var _boss_name: String = "The Hedgemother"` as a class-level var.
   - `set_phase(phase: int) -> void` — replace the hardcoded string at line 54 with `_label.text = "%s — Phase %d — Unyielding" % [_boss_name, phase]`; likewise for the `_meter.label` line 56.
   _Verify:_ `test_wyrd_dungeon_scene.gd` — extend the existing boss-bar wiring test OR add a new assertion that after `bossbar.prime(80, "The Burrow Boar")` the label text contains "Burrow Boar". Run: `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_dungeon_scene.gd`. _Effort:_ S.

### Phase 2 — Den difficulty readout at the bench

4. **Add `_den_band()` helper to `crafting_bench.gd`** — new `func _den_band() -> String` after `_carto_lv()` at line 213.
   When `trophy != ""` and `base_id != ""`, look up the den affix via `ChartsData.TROPHY_TO_AFFIX[trophy]`; read `den_level` from `({1:3,2:8,3:13}).get(int(template().get("tier",1)), 3)`; read player level via `_carto_lv()`; compute `delta := den_level - player_lv`; return a string like `"Den lv %d — %s"` where band is `"easy"` for delta ≤ −2, `"moderate"` for −1..+1, `"very hard"` for ≥ +2. Return `""` when no trophy is slotted.
   _Verify:_ unit-testable via `test_wyrd_loop.gd` — create a bench, place `tier_1` base, socket `thorn_essence`, call `_den_band()` with carto lv 6, assert result contains "Den lv 3". _Effort:_ S.

5. **Render the band chip in `BenchView._draw_result()`** — `crafting_bench.gd:BenchView._draw_result`, after the trophy certainty line (around line 827).
   After drawing `"★ <den.name> — certain"`, call `bench._den_band()` and, if non-empty, draw a second line in amber (`Color(0.85, 0.65, 0.30)`) at `y += 19.0` using the standard `draw_string(font, Vector2(rx, y), band_str, ...)` pattern already used throughout the method.
   _Verify:_ `WYRD_NO_SAVE=1 WYRD_DEV_LEVEL=6 godot --path wyrd` → open Inscribing Table → socket `thorn_essence` → confirm "Den lv 3 — easy" appears. Screenshot via `WYRD_SHOT=1`. _Effort:_ S.

### Phase 3 — Ledger: trophy → capped stat boost

6. **Create `wyrd/data/ledger.gd`** — new file (does not exist).
   ```gdscript
   # Ledger — maps boss trophy material id to the persistent stat bonus
   # it grants. Counts stack up to cap; repeated runs compound the gain.
   const ENTRIES: Dictionary = {
       "thorn_essence": {"stat": "crit_chance",  "bonus": 0.04, "cap": 0.12},
       "tusker_tusk":   {"stat": "damage_flat",  "bonus": 2.0,  "cap": 6.0},
       "wightpelt":     {"stat": "move_speed",   "bonus": 0.05, "cap": 0.15},
       "alpha_fang":    {"stat": "fire_rate",    "bonus": 0.08, "cap": 0.16},
   }
   ```
   _Verify:_ `preload("res://data/ledger.gd").ENTRIES.has("thorn_essence")` evaluates true in a headless script. _Effort:_ S.

7. **Add `apply_ledger_bonuses(sums: Dictionary, materials: Dictionary)` to `game.gd`** — new static-style method after `run_cfg()` (around line 767).
   ```gdscript
   const LedgerDefs = preload("res://data/ledger.gd")
   func apply_ledger_bonuses(sums: Dictionary, mats: Dictionary) -> void:
       for trophy_id in LedgerDefs.ENTRIES:
           var entry: Dictionary = LedgerDefs.ENTRIES[trophy_id]
           var count: int = int(mats.get(trophy_id, 0))
           if count <= 0:
               continue
           var raw: float = float(entry.bonus) * float(count)
           var capped: float = minf(raw, float(entry.cap))
           var stat: String = String(entry.stat)
           sums[stat] = float(sums.get(stat, 0.0)) + capped
   ```
   _Verify:_ test in `test_wyrd_loop.gd` — call `game.apply_ledger_bonuses(sums, {"thorn_essence": 1})`, assert `sums.crit_chance == 0.04`. _Effort:_ S.

8. **Call `apply_ledger_bonuses()` in `player_controller._derive_stats()`** — `player_controller.gd:1097` (after shrine buffs, before the Wayfinding level power factor).
   ```gdscript
   if game_h != null:
       game_h.apply_ledger_bonuses(sums, game_h.materials)
   ```
   This slot sits after `for k in shrine_buffs` (line 1096) and before the `pf` power-factor block (line 1114). The `damage_flat` stat feeds `_add_stat(sums, "damage_flat", ...)` — add handling in `_derive_stats()` final dict: `"damage": int(round(6.0 * pf)) + int(sums.get("damage", 0)) + int(sums.get("damage_flat", 0.0))`.
   _Verify:_ `test_wyrd_loop.gd` — give game `materials["thorn_essence"] = 1`, call `_derive_stats()` on a fresh player, assert `derived_stats.crit_chance > 0.20` (base). _Effort:_ S.

9. **Persist Ledger bonuses via materials (no extra save field needed)** — `save_game.gd`.
   The Ledger reads directly from `game.materials` which is already serialised at `save_game.gd:18`. No new save field required — verify this by tracing `"thorn_essence"` in materials through save/load.
   _Verify:_ `test_wyrd_transitions.gd` — confirm that `game.materials` survives save+load and the crit_chance derived stat matches pre-save value. _Effort:_ S.

   > NOTE on open question (from [[system-bosses]] §Open questions #3): the ruling baked in here is that **trophies are NOT consumed by the Ledger** — the bonus accrues from _owning_ them. `spend_materials()` in `crafting_bench.craft()` does consume the trophy as part of `craft_cost()`, so crafting a den chart spends the trophy from the satchel and removes the Ledger contribution. This is the mechanically cleanest interpretation; confirm with user before shipping Phase 3.

### Phase 4 — Queen of Thorns: phase-3 summon mechanic

10. **Widen the Queen's phase-3 telegraph disc** — `boss.gd:_make_telegraph()` call site in `_begin_attack()`.
    When `kind == "hedgemother_queen"` and `_phase == 3` and `_pending == "sweep"`, pass `radius * 1.6` to `_make_telegraph()` and tint the material red-deep: after `_make_telegraph(center, radius)` returns, override `_telegraph_node.material_override.albedo_color = Color(0.80, 0.10, 0.08, 0.30)`.
    Add a check at the top of `_begin_attack()`: `if kind == "hedgemother_queen" and _phase == 3: _queen_phase3_begin()` which sets up the wider disc _and_ schedules the summon signal before delegating to the normal sweep/stomp path.
    _Verify:_ visual — `WYRD_DEV_CHART=summit WYRD_SHOT=1 godot --path wyrd` and confirm disc colour. _Effort:_ S.

11. **Emit a `summon_wave` signal on Queen phase-3 attacks and connect it in `layout_loader._build_boss()`** — `boss.gd` + `layout_loader.gd`.
    - Add `signal summon_wave(count: int)` to `boss.gd`.
    - In the new `_queen_phase3_begin()` method: emit `summon_wave.emit(2)` immediately before starting the telegraph so the loader has the full wind-up window.
    - In `layout_loader.gd:_build_boss()`, after the existing `boss.phase_changed.connect(bossbar.set_phase)` wiring (around line 701), add:
      ```gdscript
      boss.summon_wave.connect(func(n: int): _spawn_queen_summons(n))
      ```
    - Add `func _spawn_queen_summons(count: int) -> void` in layout_loader: iterate `count` times, call the existing enemy-spawning path (via `_spawn_enemy("skeleton", cx + rng_offset, cy + rng_offset)` or equivalent) using the boss room centre coordinates stored in `_boss_body.global_position`.
    _Verify:_ `test_wyrd_dungeon_scene.gd` — new test: set `WYRD_DEV_CHART=summit`, drive boss below 33% HP (`boss.hp = int(boss.hp_max * 0.30)`), advance one frame, assert `get_tree().get_nodes_in_group("enemy").size() >= 2`. Run `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_dungeon_scene.gd`. _Effort:_ M.

12. **Tighten Queen phase-3 cooldown** — `boss.gd:_phase_cooldown()` at line 96.
    Add an override: if `kind == "hedgemother_queen"` return `[2.6, 1.9, 1.0][_phase - 1]` (phase 3 drops from 1.3 → 1.0). A minimal `if` before the array lookup:
    ```gdscript
    func _phase_cooldown() -> float:
        if kind == "hedgemother_queen":
            return [2.6, 1.9, 1.0][_phase - 1]
        return [2.6, 1.9, 1.3][_phase - 1]
    ```
    _Verify:_ headless — instantiate Queen boss, set `_phase = 3`, call `_phase_cooldown()`, assert result is 1.0. _Effort:_ S.

### Phase 5 — New-boss registration checklist (documentation gate)

13. **Write `docs/specs/add-new-boss.md` checklist** — new file (documentation only; code unchanged).
    Five-step checklist referencing the exact file:line for each concern:
    1. `layout_loader.gd:BOSS_KINDS` — add model, scale/fit_h, hp, damage, radius, height, bob, trophy, display_name.
    2. `data/charts.gd:TROPHY_TO_AFFIX` — add trophy_id → den_affix_id.
    3. `data/charts.gd:AFFIXES` — add den affix entry with name, bad_name, good_desc, bad_desc, kind="boss", req_carto, base_stab, trophy.
    4. `data/charts.gd:BASE_WEIGHTS` — boss dens are intentionally absent (trophy-only inscription).
    5. `boss.gd:_begin_attack()` — add `if kind == "<new_boss>":` branch with the new moveset.
    6. `data/ledger.gd:ENTRIES` — add trophy_id → stat/bonus/cap.
    _Verify:_ file exists at `docs/specs/add-new-boss.md` and is linked from `system-bosses.md`. _Effort:_ S.

## First commit (smallest shippable slice)

**Tasks 1–3: Boss bar label fix.**

Single commit touching `layout_loader.gd` (BOSS_KINDS display_name entries + prime call) and `boss_bar.gd` (prime signature, _boss_name field, set_phase literal replacement). Nothing else changes.

Acceptance:
- `test_wyrd_dungeon_scene.gd` passes (existing suite, no new test needed for the label fix — the existing boss-bar wiring test at minimum exercises the path).
- `WYRD_NO_SAVE=1 WYRD_DEV_BOSS=burrow_boar_den godot --path wyrd` boots and the bar reads "The Burrow Boar — Unyielding".

## Test & verification plan

| Suite | What to assert | When |
|---|---|---|
| `test_wyrd_dungeon_scene.gd` | `bossbar.prime(80, "The Burrow Boar")` → label contains "Burrow Boar" | After Task 3 |
| `test_wyrd_loop.gd` | `apply_ledger_bonuses(sums, {"thorn_essence":1})` → `sums.crit_chance == 0.04` | After Task 7 |
| `test_wyrd_loop.gd` | `_derive_stats()` on player with 1× thorn_essence → `derived_stats.crit_chance > 0.20` | After Task 8 |
| `test_wyrd_transitions.gd` | Materials survive save/load; derived `crit_chance` matches | After Task 9 (verify existing coverage) |
| `test_wyrd_dungeon_scene.gd` | Queen below 33% HP → `enemy` group grows by ≥ 2 | After Task 11 |
| Screenshot / playtest | Boss bar correct label for all three named bosses | After Tasks 1–3 |
| Screenshot / playtest | Den band chip shows in Inscribing Table result slot | After Task 5 |
| Screenshot / playtest | Queen's phase-3 disc is wider + deeper red; skeletons spawn | After Tasks 10–11 |

Run all headless suites with:
```
WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_dungeon_scene.gd
WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_loop.gd
WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_transitions.gd
WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_skills.gd
```

## Risks & open questions

1. **`damage_flat` stat key** — `_derive_stats()` uses `"damage"` as the sums key; the Ledger introduces `"damage_flat"` as a separate accumulator. The final dict must add them together (Task 8 sketch above). If any gear affix also uses `"damage_flat"`, it will stack — check `data/items.gd` affix keys before shipping Task 8.

2. **Trophy consumption ruling** (from [[system-bosses]] §Open questions #3) — the current design lets the Ledger bonus _persist while the trophy sits in the satchel_ but the trophy is also spent when crafting a den chart. This means crafting the den chart removes the Ledger bonus. Confirm: is the intent that trophies are kept for stat power AND separately spent on den inks, or is the bonus decoupled from material count?

3. **Queen summon source** — Task 11 emits `summon_wave` immediately at phase-3 wind-up start. The skeletons arrive during the telegraph window. If layout_loader's enemy-spawn path depends on the nav mesh being baked, deferred-spawning them (via `call_deferred`) may be necessary to avoid a nav-crash.

4. **Queen summon re-fire** — the summon fires on every phase-3 attack (every ~1.0 s). Two skeletons per burst could flood the arena quickly. A cooldown gate on `_queen_phase3_begin()` (e.g. only summon once every 8 s) is worth discussing before shipping Task 11.

5. **`class_name` headless constraint** — `ledger.gd` must NOT register a `class_name` (headless mode rejects it). Use `preload()` everywhere — the Task 7 sketch above uses `const LedgerDefs = preload(...)` which is correct.
