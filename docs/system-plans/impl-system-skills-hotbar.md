---
title: Skills, Hotbar & the Mastery Tree — Implementation Plan
parent: "[[system-skills-hotbar]]"
domain: Player & Abilities
type: implementation-plan
status: ready-to-build
effort: M
tags: [wayfinder, impl]
---

# Skills, Hotbar & the Mastery Tree — Implementation Plan

> Build doc for [[system-skills-hotbar]]. Pick-one-of-N mastery choice at lv 5/10/14/17 is wired into the data model, choice modal, Trades-page display, and save/load — after which `perk_active` reflects only what the player chose, and `test_skills.gd` covers the new path.

## Build status — 2026-06-16
**Phase 1 core SHIPPED & gate-green** (the "most choosy" ruling: pick-1 at lv **5/10/13/14/17** — note 13 was added vs the original `[5,10,14,17]`). Done: tasks 1–4 (data model, `perk_active` rewrite, `choose_perk`, signal), 5–6 (`scripts/ui/mastery_choice_panel.gd` + `Game._on_mastery_choice_ready` wiring), 7–8 (save persist + old-save migration), 10 (`_test_mastery_choice` + 8 downstream test fixes that assumed auto-grant). Deviations: `choose_perk` emits `perks_changed` → player re-derives (the note's `_derive_stats()`-in-game.gd was wrong — it lives on the player); migration auto-grants the first perk per reached tier.
**Remaining: task 9** (Trades-page renders choice tiers as side-by-side cards — the persistent "view your tree" display) + **Phase 2** (5 painted skill icons) + **Phase 3** (discoverability / CDR transparency).

## Definition of done

- `game.gd:perk_active` returns `false` for unchosen perks at multi-perk levels (5/10/14/17), `true` only for the single player-chosen perk per tier.
- A blocking modal (`mastery_choice_panel.gd`) fires after every level-up that hits one of those four tiers; it cannot be dismissed without picking.
- `chosen_perks` is persisted in `wayfinder_save.json`; old saves without the key auto-migrate (first perk in each tier auto-granted).
- The Trades page renders choice-node tiers as a side-by-side comparison, with chosen = sage ring, unchosen-but-available = dim, unreached = locked.
- `test_skills.gd` extended with `_test_mastery_choice`; all five headless suites pass.
- Phase 2 (painted icons) and Phase 3 (discoverability / CDR transparency) are also complete. See DoD in [[system-skills-hotbar]] Phase 2/3 sections.

## Preconditions / dependencies

- [[impl-system-save-load]] — `chosen_perks` schema addition (task 4 below) must coordinate with any simultaneous save-schema changes.
- [[impl-system-trades-progression]] — `award_xp` (`game.gd:282`) is the emission point for the new signal; the XP/level engine must stay stable.
- [[impl-system-hud]] — the mastery-choice modal must sit above the skill bar (layer 50) and the inventory panel; use layer 100 matching `shrine_choice_modal.gd`.
- [[impl-system-ui-panels]] — `_SkillCard` inner class from `scripts/ui/loadout_panel.gd:169` is the reuse target for the choice modal cards.
- **`mastery_choice_panel.gd` does not exist yet** — task 5 creates it.
- **Open question (user must decide before task 1 ships):** one-of-N or two-of-four at lv 5? Plan defaults to strictly one; change `MASTERY_CHOICE_LVS` constant and the `choose_perk` guard if two is wanted.
- **Open question:** permanent choice vs re-pickable at Hearth? Task 1 implements permanent; a re-pick path would require an "undo" branch in `choose_perk` and is a distinct follow-up.
- Plan.md Phase B3 (level-up burst + perk banner) should land before or alongside task 5 — the modal should fire *after* the B3 burst, not instead of it. Not a hard blocker; the modal fires correctly on `mastery_choice_ready` regardless.

## Tasks (ordered)

### Phase 1 — Pick-one-of-N mastery choice

1. **Add `chosen_perks`, `MASTERY_CHOICE_LVS`, `PERK_CATEGORY`, and `mastery_choice_ready` signal to `game.gd`** — `game.gd` top of signals block (`game.gd:27–34`) and state block (`game.gd:101–128`).
   - Add signal: `signal mastery_choice_ready(level: int)` alongside the existing signals at `game.gd:27`.
   - Add const: `const MASTERY_CHOICE_LVS: Array[int] = [5, 10, 14, 17]` near `SKILL_REQS` (`game.gd:118`).
   - Add const: `const PERK_CATEGORY: Dictionary = { "curious_fingers": "craft", "double_ore": "gather", "keen_eye": "gather", "steady_hands": "combat", "sure_lines": "chart", "quick_mining": "gather", "clean_splits": "gather", "hunters_stride": "combat", "quick_nock": "combat", "rich_seams": "gather", "light_hands": "gather", "thrifty_quill": "chart", "heavy_draw": "combat", "master_wayfinder": "chart", "smiths_thrift": "craft", "second_pour": "craft", "even_breath": "combat" }`.
   - Add var: `var chosen_perks: Dictionary = {}` next to `loadout` (`game.gd:122`).
   _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` stays green (parse/autoload only). _Effort:_ S.

2. **Rewrite `perk_active` in `game.gd:461`** — change from pure threshold check to choice-aware logic.
   ```gdscript
   func perk_active(_trade: String, perk_id: String) -> bool:
       for perk in PERKS[SKILL]:
           if String(perk.id) == perk_id:
               if MASTERY_CHOICE_LVS.has(int(perk.lv)):
                   return chosen_perks.get(perk_id, false)
               return trade_lv(SKILL) >= int(perk.lv)
       return false
   ```
   _Verify:_ `test_wyrd_loop.gd` green (perk_active called by gather_bonus). _Effort:_ S.

3. **Add `choose_perk` func to `game.gd`** — new function after `perk_active` (`game.gd:465`).
   ```gdscript
   func choose_perk(perk_id: String) -> bool:
       for perk in PERKS[SKILL]:
           if String(perk.id) == perk_id:
               var pl: int = int(perk.lv)
               if not MASTERY_CHOICE_LVS.has(pl):
                   return false
               if trade_lv(SKILL) < pl:
                   return false
               # Only allow a choice if this tier has no pick yet.
               var already: bool = false
               for p2 in PERKS[SKILL]:
                   if int(p2.lv) == pl and chosen_perks.get(String(p2.id), false):
                       already = true
                       break
               if already:
                   return false
               chosen_perks[perk_id] = true
               _derive_stats()
               save_now()
               return true
       return false
   ```
   _Verify:_ logic unit-checked in `_test_mastery_choice` (task 9). _Effort:_ S.

4. **Emit `mastery_choice_ready` in `award_xp` (`game.gd:282`)** — after `leveled_up.emit` inside the while loop (`game.gd:290`), add:
   ```gdscript
   if MASTERY_CHOICE_LVS.has(int(trades[SKILL].lv)):
       mastery_choice_ready.emit(int(trades[SKILL].lv))
   ```
   _Verify:_ `test_wyrd_loop.gd` green. _Effort:_ S.

5. **Create `scripts/ui/mastery_choice_panel.gd`** — new file; does not exist.
   Pattern: copy `shrine_choice_modal.gd` structure (layer 100, `process_mode = ALWAYS`, backdrop, centred panel, `modal_opened/closed` calls, no Esc dismiss). Changes vs shrine:
   - Title: `"A new mastery opens — Lv %d" % level`.
   - Cards: one `_SkillCard`-equivalent card per perk at the given level (preload `loadout_panel.gd`'s inner class cannot be accessed cross-file — reimplement a minimal inline card: `Button` with `custom_minimum_size = Vector2(200, 140)`, perk name + PERK_CATEGORY label + desc + `draw_…` via a minimal `_SkillCard` reimplementation, OR use a `VBoxContainer + Label` stack inside a `PanelContainer`).
   - On card press: call `Game.choose_perk(perk_id)` → `queue_free()` + `modal_closed()`.
   - No Esc: `_unhandled_input` consumes `ui_cancel` and does nothing.
   ```gdscript
   extends CanvasLayer
   signal perk_chosen(perk_id: String)
   func open(level: int) -> void:  # builds card HBox from Game.PERKS filtered by lv
   func _on_card_pressed(perk_id: String) -> void:
       get_node("/root/Game").choose_perk(perk_id)
       get_node("/root/Game").modal_closed()
       perk_chosen.emit(perk_id)
       queue_free()
   ```
   _Verify:_ screenshot — at lv 5 a card panel appears; clicking a card closes it. _Effort:_ M.

6. **Wire `mastery_choice_ready` to spawn the modal** — listener goes in `game.gd:_ready` (or on the player HUD `player_hud.gd`). Cleanest: in `game.gd._ready`, connect `mastery_choice_ready` to a local handler that instantiates the panel and attaches it to the current scene:
   ```gdscript
   func _ready() -> void:
       mastery_choice_ready.connect(_on_mastery_choice_ready)
   func _on_mastery_choice_ready(level: int) -> void:
       if get_tree().current_scene == null:
           return
       const MasteryPanel := preload("res://scripts/ui/mastery_choice_panel.gd")
       var panel: CanvasLayer = MasteryPanel.new()
       get_tree().current_scene.add_child(panel)
       panel.open(level)
       modal_opened()
   ```
   Note: `mastery_choice_panel._on_card_pressed` calls `modal_closed()` itself; do not double-count.
   _Verify:_ playtest — award enough XP to reach lv 5 (`WYRD_FAST_CHANNEL=1`), verify modal appears and pick is reflected in perk_active. _Effort:_ S.

### Phase 1 — Save & migration

7. **Add `chosen_perks` to `save_game.gd:save` (`save_game.gd:14`)** — in the `data` dict literal, add `"chosen_perks": game.chosen_perks`. _Effort:_ S.

8. **Load and migrate `chosen_perks` in `save_game.gd:load_into` (`save_game.gd:41`)** — after the `loadout` load block (`save_game.gd:83–85`):
   ```gdscript
   if data.has("chosen_perks"):
       game.chosen_perks = {}
       for id in data.get("chosen_perks", {}):
           game.chosen_perks[String(id)] = bool(data.chosen_perks[id])
   else:
       # Old save — auto-grant first perk at each choice tier the player has reached.
       game.chosen_perks = {}
       var lv: int = int(game.trades[game.SKILL].lv)
       for p in game.PERKS[game.SKILL]:
           if game.MASTERY_CHOICE_LVS.has(int(p.lv)) and lv >= int(p.lv):
               var already := false
               for p2 in game.PERKS[game.SKILL]:
                   if int(p2.lv) == int(p.lv) and game.chosen_perks.get(String(p2.id), false):
                       already = true
                       break
               if not already:
                   game.chosen_perks[String(p.id)] = true
   ```
   _Verify:_ `test_wyrd_loop.gd` green; manual: create a save at lv 9 without `chosen_perks`, reload, assert no errors and lv-5 tier has one auto-granted pick. _Effort:_ S.

### Phase 1 — Trades page update

9. **Update `_draw_trades_tab` in `inventory_panel.gd:864`** — inside the `for p in perks` loop where each perk card is drawn, split the rendering into three cases for choice-node levels:
   - Detect choice tiers: `var is_choice_node: bool = game.MASTERY_CHOICE_LVS.has(int(p.lv))`.
   - For `is_choice_node`: collect all perks at the same level into a same-row group (batch them); render a compact "Choose one" chip above the group when `lv >= pl` and no pick has been made for that tier; render the chosen perk's card with a sage double-ring (existing `ok` style), unchosen-but-reachable with a dim border, unreachable with the existing locked style.
   - For non-choice-node perks: keep the existing single-card logic unchanged.
   - The grouping pass can be done by collecting perks by `lv` into a `Dictionary` before the loop, then iterating tier by tier.
   _Verify:_ `WYRD_UI_SHOT=inventory` screenshot at lv 5 shows two side-by-side cards at the tier-5 row, one lit (sage ring), others dim; "Choose one" chip shows if no pick is made. _Effort:_ M.

### Phase 1 — Headless test extension

10. **Add `_test_mastery_choice` to `test_skills.gd`** — after `_test_gates`, add:
    ```gdscript
    func _test_mastery_choice(game: Node) -> void:
        print("[mastery choice]")
        game.chosen_perks = {}
        game.trades["wayfinding"]["lv"] = 4
        # Check signal fires on level-up to 5.
        var signal_fired := false
        game.mastery_choice_ready.connect(func(_lv): signal_fired = true, CONNECT_ONE_SHOT)
        game.award_xp("wayfinding", game.xp_for_level(5) - int(game.trades["wayfinding"].xp) + 1)
        _check("mastery_choice_ready fires at lv 5", signal_fired)
        # Choosing steady_hands activates it, others stay off.
        var ok: bool = game.choose_perk("steady_hands")
        _check("choose_perk steady_hands returns true", ok)
        _check("steady_hands is active after choice",
            game.perk_active("", "steady_hands"))
        _check("double_ore is NOT active (unchosen)",
            not game.perk_active("", "double_ore"))
        _check("curious_fingers is NOT active (unchosen)",
            not game.perk_active("", "curious_fingers"))
        _check("keen_eye is NOT active (unchosen)",
            not game.perk_active("", "keen_eye"))
        # Can't choose a second pick for the same tier.
        _check("second choose_perk at same tier rejected",
            not game.choose_perk("double_ore"))
        # Non-choice perks (lv 12) still use threshold.
        game.trades["wayfinding"]["lv"] = 12
        _check("quick_nock active at lv 12 (threshold perk)",
            game.perk_active("", "quick_nock"))
        game.trades["wayfinding"]["lv"] = 11
        _check("quick_nock inactive at lv 11",
            not game.perk_active("", "quick_nock"))
    ```
    Wire the call: inside `_run()` after `_test_gates`, add `_test_mastery_choice(game)`.
    _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd` — all checks green. _Effort:_ S.

### Phase 2 — Painted skill icons for remaining 5

11. **Commission / generate 5 painted icons** — `assets/ui/icons/skill_piercing.png`, `skill_rain.png`, `skill_burst.png`, `skill_mark.png`, `skill_ward.png`, `skill_mercy.png` (64×64, ink-line style matching `skill_basic/power/multi/snare.png`). Drop files; run `wyrd/tools/check_ninepatch.py` on each.
    _Verify:_ files exist and `check_ninepatch.py` exits 0 per icon. _Effort:_ asset round-trip.

12. **Register icons in `skill_bar.gd:35` and `loadout_panel.gd:31`** — add entries to `SKILL_ICON` in both files:
    ```gdscript
    "PiercingBolt":  "res://assets/ui/icons/skill_piercing.png",
    "RainOfThorns":  "res://assets/ui/icons/skill_rain.png",
    "Thornburst":    "res://assets/ui/icons/skill_burst.png",
    "HuntersMark":   "res://assets/ui/icons/skill_mark.png",
    "HeartwoodWard": "res://assets/ui/icons/skill_ward.png",
    "MercyShot":     "res://assets/ui/icons/skill_mercy.png",
    ```
    In `loadout_panel.gd`, also remove the three redundant shared-icon entries (`PiercingBolt → power`, `RainOfThorns/Thornburst → snare`, `HuntersMark/HeartwoodWard/MercyShot → basic`). Ensure `_tex_cache` preload loop in `loadout_panel.gd:56` picks up new paths automatically (it iterates `SKILL_ICON.values()` — no change needed).
    _Verify:_ `WYRD_SHOT=1` screenshot — all 9 hotbar slots show distinct painted icons; no Unicode glyphs. Open loadout panel: all 9 skill cards show distinct icons. _Effort:_ S.

### Phase 3 — Discoverability & CDR transparency

13. **Extend locked `_SkillCard` in `loadout_panel.gd`** — in `_SkillCard.setup` (`loadout_panel.gd:187`), the `_desc` is already stored. In `_SkillCard._draw` (wherever it renders the locked state), add a `draw_multiline_string` call to render `_desc` in dim colour under the gate badge — same `draw_multiline_string` pattern as `inventory_panel.gd:896`. Cap at 2 lines; use font size 11; dim colour `Color(0.52, 0.46, 0.39)`.
    _Verify:_ screenshot of loadout panel at lv 1 — HuntersMark card shows a visible description under "Wayfinding 4". _Effort:_ S.

14. **Add CDR annotation section to `_draw_trades_tab` in `inventory_panel.gd`** — after the mastery-ladder loop ends (after `cardy` loop, before `y = cardy + 12.0` at `inventory_panel.gd:900`), draw a "Current loadout — effective cooldowns" sub-section:
    - Iterate `Game.loadout` (3 picks).
    - For each, look up the `Skill` instance from `player_controller.SKILL_FACTORY` — or read base_cd from the skill file's const. Use `game.trades[game.SKILL]` CDR stat if available (check `_derive_stats` path).
    - One text line per skill: `"QuickNock · CDR 10% → PowerShot 1.36s"`. If `cooldown_reduction >= CDR_CAP`, show a cap notice.
    - Keep it compact: 14px font, INK colour, inside the Trades tab scroll region.
    _Verify:_ screenshot of Trades page at lv 12 (Quick Nock active) shows effective cooldown lines for the three loadout skills. _Effort:_ S.

15. **Edit `even_breath` perk desc in `game.gd:PERKS`** — change `game.gd:457`:
    ```gdscript
    {"id": "even_breath", "lv": 17, "name": "Even Breath",
        "desc": "A clean kill steadies you — every kill returns 6 Focus (not XP, a Focus refund)"},
    ```
    _Verify:_ Trades page shows the updated desc in the even_breath card. _Effort:_ XS.

## First commit (smallest shippable slice)

**Tasks 1–4 + 7–8 + 10:** Data model + signal + `perk_active` rewrite + `choose_perk` + save schema + `_test_mastery_choice`. No new UI files; no visible change in-game (perk_active now requires a choice at choice-node levels, but the migration in `load_into` auto-grants for old saves and the signal fires into the void without task 5).

Acceptance: `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd` passes including `_test_mastery_choice`; all other four gate suites stay green; `perk_active("", "steady_hands")` returns `false` on a fresh-game lv 5 save until `choose_perk("steady_hands")` is called.

## Test & verification plan

**Headless (required — all must stay green):**
```
cd wyrd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_transitions.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_stats.gd
```

**New test function** — `_test_mastery_choice(game)` in `test_skills.gd` (task 10) covers:
- Signal fires on level-up to a choice tier.
- `choose_perk` returns true for a valid pick, false for a double-pick attempt.
- `perk_active` returns true only for chosen perk at a choice tier.
- Non-choice-tier perks (`quick_nock` at lv 12) still use threshold logic.

**Save-migration test (manual):**
1. Create a save at lv 9 without `chosen_perks` key (edit the JSON directly or use a pre-task-7 build).
2. Load in the new build; assert no errors; assert lv-5 tier has exactly one auto-granted pick; assert lv-10 tier has one auto-granted pick.

**Screenshot/playtest (WYRD_SHOT + WYRD_DEV_LEVEL):**
- `WYRD_DEV_LEVEL=5 godot --path wyrd` → mastery modal appears at load; verify it blocks input.
- `WYRD_UI_SHOT=inventory` → Trades tab shows choice-node tiers as side-by-side cards at lv 5/10.
- After picking: chosen card has sage ring; unchosen cards are dim.
- Hotbar at lv 9 with all 9 skills in loadout panel: all 9 slots show distinct painted icons (Phase 2, after task 12).
- Loadout panel at lv 1: locked skills show description text under gate badge (Phase 3, task 13).
- Trades page at lv 12: effective cooldown section visible for current loadout (task 14).

## Risks & open questions

1. **One-of-N vs two-of-four at lv 5** — `MASTERY_CHOICE_LVS` and `choose_perk` implement strictly one pick per tier. If the design shifts to two-of-four, the `already` guard in `choose_perk` (task 3) needs a per-tier count rather than a boolean presence check. **Decide before task 1 ships.**

2. **Permanent vs re-pickable mastery** — task 3 implements permanent (once chosen, `choose_perk` rejects the same tier). Re-pickable at a Hearth would require clearing `chosen_perks[tier_perks]` for the tier, a confirmation modal, and coordination with [[impl-system-town-hub]]. Permanent is the shipped default; flag as an open follow-up.

3. **`_SkillCard` is an inner class** — it cannot be preloaded across file boundaries in GDScript. The mastery-choice modal (task 5) must either duplicate the card drawing logic inline, or `loadout_panel.gd` must be refactored to expose the card as a standalone `scripts/ui/skill_card.gd`. The simplest path is a lightweight inline `PanelContainer + VBoxContainer + Label` stack in `mastery_choice_panel.gd` — good enough for the choice UI, less code to maintain.

4. **`_derive_stats` coupling** — `choose_perk` calls `_derive_stats()` (task 3), but `_derive_stats` may not exist or may have a different name in `game.gd`. Confirm the stat-derivation hook name before task 3 lands; if absent, use `emit_signal("stats_changed")` or a no-op comment marking the hook point.

5. **B3 level-up burst sequencing** — the mastery modal fires synchronously on `leveled_up`'s frame. If Plan.md B3 adds a tween/animation before the burst completes, the modal should be deferred one frame with `call_deferred("open", level)` so the burst animation is not clipped. Low risk but worth noting.

6. **`test_stats.gd` existence** — the five listed suites include `test_stats`; confirm this file exists in `wyrd/` before the first commit CI run (it is listed in CLAUDE.md but was not observed in this read-pass).
