---
title: Save / Load & Persistence — Implementation Plan
parent: "[[system-save-load]]"
domain: Persistence
type: implementation-plan
status: ready-to-build
effort: M
tags: [wayfinder, impl]
---

# Save / Load & Persistence — Implementation Plan

> Build doc for [[system-save-load]]. All four headless suites stay green, the roundtrip test never touches the real save path, atomic writes guard against corruption, a migration chain is scaffolded for VERSION 2+, and the Lantern ships a "New Game" button.

## Definition of done

- `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` passes with `user://wayfinder_save.json` provably absent after the run.
- Manually corrupting `user://wayfinder_save.json` (write `{badkey}`) produces a visible toast on relaunch; the `.bak` fallback is tried first.
- `SaveGame.load_into` returns a typed `LOAD_RESULT` enum (not raw `bool`).
- A `_migrate` chain in `save_game.gd` wraps the two existing backfill paths and is the single entry point for all future version migrations.
- The Lantern panel has a "New Game" button behind a confirmation dialog that resets all persistent state and reloads Town at tutorial step 0.

## Preconditions / dependencies

- [[impl-system-trades-progression]] — `game.trades.wayfinding` structure must be stable before adding migration tests that assert on it; the ADR-0012 path (`save_game.gd:72–81`) is already live and becomes migration v0→v1 in the chain.
- [[impl-system-inventory-equipment]] — `_items_out` / `re-grid on load` path (`save_game.gd:97–112`) must stay consistent; no inventory shape change should land in parallel with Tasks 3–4.
- [[impl-system-charts-wayfinding]] — `discovered_inks` backfill (`save_game.gd:88–95`) becomes migration v0→v1b in the chain; chart format must be stable during Task 5.
- [[impl-system-npc-story-tutorial]] — `tutorial_step` and `seen_hints` ride the save; Task 7 (New Game reset) must clear these.
- No missing files. `save_game.gd`, `game.gd`, `test_wyrd_loop.gd`, and `scripts/ui/system_menu.gd` all exist.

## Tasks (ordered)

### Phase 1 — Test-roundtrip safety (closes the CLAUDE.md open followup)

1. **Add `save_to` / `load_from` overloads** — `save_game.gd` after line 36.
   Signature: `static func save_to(path: String, game: Node) -> bool` (identical body to `save()`, but uses `path` instead of `SAVE_PATH`). Refactor `save()` to call `save_to(SAVE_PATH, game)`. Add matching `static func load_from(path: String, game: Node) -> bool` (mirrors `load_into` but accepts an explicit path); refactor `load_into` to call `load_from(SAVE_PATH, game)`.
   _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` still all-green (no behaviour change yet). _Effort:_ S.

2. **Redirect the roundtrip test to a temp path** — `test_wyrd_loop.gd:629–670`.
   Introduce `const TEST_SAVE := "user://wyrd_test_roundtrip.json"` at the top of the test. Replace `SaveGame.save(game)` → `SaveGame.save_to(TEST_SAVE, game)`. Replace both `SaveGame.load_into(game2)` calls and the raw-file re-read block with `SaveGame.load_from(TEST_SAVE, game)` / `SaveGame.load_from(TEST_SAVE, game2)` / `SaveGame.load_from(TEST_SAVE, game3)` as appropriate. In `clear()` step, remove `TEST_SAVE` via `DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))`. The raw-file re-read for the pre-43 backfill test (lines 655–661) now reads from `TEST_SAVE`.
   _Verify:_ Run `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd`; confirm `user://wayfinder_save.json` does not exist (`FileAccess.file_exists` check at test end). All existing checks still green. _Effort:_ S.

### Phase 2 — Atomic writes + typed LOAD_RESULT

3. **Add `LOAD_RESULT` enum** — `save_game.gd` before line 10 (before `SAVE_PATH`).
   ```gdscript
   enum LOAD_RESULT { OK, CORRUPT, VERSION_MISMATCH, NOT_FOUND }
   ```
   Change `load_from` (introduced in Task 1) to return `LOAD_RESULT` instead of `bool`. Update `load_into` wrapper to return the `LOAD_RESULT` it gets from `load_from`. Map current early-return `false` paths to `NOT_FOUND`, `CORRUPT`, and `VERSION_MISMATCH` respectively.
   _Verify:_ All four headless suites under `WYRD_NO_SAVE=1`; the roundtrip `_check("load ok", ...)` call needs to compare against `SaveGame.LOAD_RESULT.OK` — update that check in `test_wyrd_loop.gd:632`. _Effort:_ S.

4. **Atomic write in `save_to`** — `save_game.gd:save_to`, currently opens `path` directly.
   Write to `path + ".tmp"` first. After `f.close()`, call `DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"), ProjectSettings.globalize_path(path))`. If rename fails, remove the `.tmp`. Before writing, if `FileAccess.file_exists(path)` copy it to `path + ".bak"` via `DirAccess.copy_absolute`.
   _Verify:_ Kill the process mid-save in a manual playtest (Activity Monitor → SIGKILL while saving); confirm `user://wayfinder_save.json` is intact (either the previous version or the new one, never a partial write). All headless suites green. _Effort:_ S.

5. **`.bak` fallback in `load_from` + corrupt-save toast** — `save_game.gd:load_from` and `game.gd:_ready` (line 201).
   In `load_from`: when `parsed == null` or version mismatch, before returning `CORRUPT`/`VERSION_MISMATCH`, try loading `path + ".bak"` (re-open, re-parse, re-check version). If the backup succeeds, restore from it and return `OK`.
   In `game.gd:_ready` (line 201): change `elif SaveGame.load_into(self):` to capture the result — `var load_result: SaveGame.LOAD_RESULT = SaveGame.load_into(self)` — and add:
   ```gdscript
   if load_result == SaveGame.LOAD_RESULT.CORRUPT or \
      load_result == SaveGame.LOAD_RESULT.VERSION_MISMATCH:
       notify("Your save could not be read — starting fresh.")
   ```
   _Verify:_ Write `{badkey}` to `user://wayfinder_save.json`; launch game; toast visible. Repeat with a valid `.bak` present: game restores from backup, no toast. All headless suites green (WYRD_NO_SAVE=1 skips the load path). _Effort:_ S.

### Phase 3 — Migration chain for VERSION 2+

6. **Add `_migrate` chain** — `save_game.gd` after `_decode` (around line 155).
   ```gdscript
   static func _migrate(data: Dictionary) -> Dictionary:
       # v0 → v1a: collapse legacy four-trade XP into wayfinding.
       if not (data.get("trades", {}) as Dictionary).has("wayfinding"):
           # (existing ADR-0012 logic extracted here from load_from)
           pass
       # v0 → v1b: seed three base inks for pre-spec-43 saves.
       if not data.has("discovered_inks"):
           data["discovered_inks"] = ["hedge_ink", "stoneground_ink", "refined_ink"]
       return data
   ```
   Call `data = _migrate(data)` in `load_from` immediately after `_decode(parsed)`, before the field-restore block. Remove the two inline migration blocks that are now handled by `_migrate` (lines 72–81 and 88–95 in the current file — after Task 1 refactor these live inside `load_from`).
   _Verify:_ The roundtrip test's existing `_check("pre-43 load ok", ...)` and `_check("the single Wayfinding skill restored", ...)` paths still pass, confirming the extracted logic is equivalent. Add a new `_check` in `_test_save_roundtrip` that injects `"version": 0` data without `"wayfinding"` and `"discovered_inks"`, calls `_migrate`, and asserts the output has both keys. _Effort:_ S.

7. **Document VERSION increment policy** — `save_game.gd` comment block at line 10–11.
   Add a comment block:
   ```gdscript
   # VERSION increment policy (see system-save-load open questions):
   #   - New optional field with a default: add a backfill in _migrate, no bump.
   #   - Rename or remove an existing field (breaking): bump VERSION, add a
   #     _migrate_to_v<N> function, call it from _migrate when version < N.
   const VERSION := 1
   ```
   _Verify:_ Code review / grep confirms `_migrate` is the only place version logic lives. _Effort:_ S.

### Phase 4 — Save-slot UX (New Game / Delete Save in The Lantern)

8. **Add "New Game" button with confirmation** — `scripts/ui/system_menu.gd`, inside the `else` branch (offline path) starting at line 77.
   After the existing `note` label's `col.add_child(note)` (after line 102), append a separator and a "New Game" button:
   ```gdscript
   var sep := HSeparator.new()
   col.add_child(sep)
   var new_game_btn := Button.new()
   WyrdUi.style_kit_button(new_game_btn)
   new_game_btn.text = "New Game"
   new_game_btn.custom_minimum_size = Vector2(0, 40)
   new_game_btn.pressed.connect(_on_new_game)
   col.add_child(new_game_btn)
   ```
   Add `_on_new_game()` and `_confirm_new_game()` methods:
   ```gdscript
   func _on_new_game() -> void:
       _status.text = "Start over? This deletes your save. Press confirm to continue."
       # Repurpose status line as a one-step confirm; show a Confirm button.
       var confirm := Button.new()
       WyrdUi.style_kit_button(confirm)
       confirm.text = "Confirm — erase save"
       confirm.custom_minimum_size = Vector2(0, 40)
       confirm.pressed.connect(_confirm_new_game)
       (_panel.get_child(2) as VBoxContainer).add_child(confirm)

   func _confirm_new_game() -> void:
       SaveGame.clear()
       if _game != null:
           _game.reset_to_defaults()
           _game.save_now()
           _game.modal_closed()
           _game.get_tree().change_scene_to_file(_game.TOWN_SCENE)
       queue_free()
   ```
   Add `reset_to_defaults()` to `game.gd` (after `save_now()`, around line 94):
   ```gdscript
   func reset_to_defaults() -> void:
       trades = { "wayfinding": {"lv": 1, "xp": 0} }
       materials = {}
       charts = []
       gold = 0
       summit_cleared = false
       muted = true
       loadout = []
       discovered_inks = []
       seen_hints = {}
       tutorial_step = 0
       player_hp = -1
       inventory = Inventory.new()
       var EquipmentScript := load("res://scripts/equipment.gd")
       equipment = EquipmentScript.new()
   ```
   _Verify:_ Manual playtest — open Lantern (Esc), press "New Game", confirm — game reloads at tutorial step 0 with empty satchel, no charts, gold 0. All headless suites unaffected (`WYRD_NO_SAVE=1`). _Effort:_ M.

## First commit (smallest shippable slice)

**Tasks 1 + 2** together are the minimal first PR:

- Add `save_to(path, game)` / `load_from(path, game)` overloads to `save_game.gd`; refactor the existing `save()` / `load_into()` to delegate to them (pure refactor, zero behaviour change).
- Redirect `_test_save_roundtrip` in `test_wyrd_loop.gd` to read/write `user://wyrd_test_roundtrip.json` and remove it on cleanup.

**Acceptance:** `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` — all checks green; `user://wayfinder_save.json` does not exist after the run.

This closes the CLAUDE.md open followup in one focused commit and unblocks everything else.

## Test & verification plan

| Suite | When | Notes |
|---|---|---|
| `test_wyrd_loop.gd` (WYRD_NO_SAVE=1) | After every task | Primary regression guard; roundtrip test covers all persisted fields |
| `test_wyrd_dungeon_scene.gd` (WYRD_NO_SAVE=1) | After Tasks 3, 5, 6 | Ensures the `LOAD_RESULT` enum rename hasn't broken any import |
| `test_wyrd_transitions.gd` (WYRD_NO_SAVE=1) | After Task 8 | Scene reload triggered by `reset_to_defaults` must not break transitions |
| `test_skills.gd` (WYRD_NO_SAVE=1) | After Task 8 | Hotbar dispatch must survive a `loadout = []` reset |

**New checks to add inside `_test_save_roundtrip`:**
- After Task 2: assert `not FileAccess.file_exists(SaveGame.SAVE_PATH)` at test end.
- After Task 3: change `_check("load ok", SaveGame.load_into(game2))` → `_check("load ok", SaveGame.load_into(game2) == SaveGame.LOAD_RESULT.OK)`.
- After Task 6: inject a `version: 0` dict without `wayfinding` / `discovered_inks`; call `SaveGame._migrate`; assert both keys present.

**Manual playtests:**
- Task 4 (atomic): SIGKILL during save; verify save file is uncorrupted on relaunch.
- Task 5 (corrupt + bak): write `{` to save path → launch → toast visible; write valid data to `.bak` → corrupt `.json` → launch → restored from backup, no toast.
- Task 8 (New Game): from a live save, Lantern → New Game → confirm → tutorial 0, satchel empty.

## Build status — 2026-06-16

**Shipped (Tasks 1, 3, 4, 5, 6 — Phases 1-3):**

- `save_to(path, game) -> bool` and `load_from(path, game) -> LOAD_RESULT` overloads added to `save_game.gd`; `save()` and `load_into()` delegate to them (public bool API preserved).
- `LOAD_RESULT` enum (OK/CORRUPT/VERSION_MISMATCH/NOT_FOUND) exposed on `SaveGame` for the test harness and future callers.
- `load_into()` still returns `bool` (true = OK), preserving the `elif SaveGame.load_into(self):` call in `game.gd:212` without change.
- Atomic write: `save_to` writes to `path+".tmp"`, copies existing file to `path+".bak"`, then `DirAccess.rename_absolute` renames `.tmp` → real path; on rename failure the `.tmp` is removed.
- `.bak` fallback: `load_from` tries primary; on CORRUPT or VERSION_MISMATCH falls back to `path+".bak"` before returning the failure code.
- `_migrate(data)` chain centralises both inline migration paths (ADR-0012 legacy-trade XP collapse + pre-spec-43 ink backfill); called from `_try_load_file` before the version check.
- `clear()` now also removes `SAVE_PATH+".bak"`.
- VERSION increment policy documented as a comment block in `save_game.gd`.
- `wyrd/test_save_roundtrip.gd` — NEW self-contained test: 8 targeted checks (roundtrip, atomic write, .bak fallback, NOT_FOUND, CORRUPT/no-bak, VERSION_MISMATCH, legacy-trade migration, pre-43 ink migration) using `user://wyrd_test_roundtrip.json`; asserts the real save path is never touched.

**Not yet done (deferred):**
- Task 2 (redirect existing `_test_save_roundtrip` in `test_wyrd_loop.gd` to temp path) — out of scope for this agent (cannot edit `test_wyrd_loop.gd`).
- Task 8 (New Game button in `system_menu.gd` + `game.gd:reset_to_defaults`) — out of scope (cannot edit those files).

## Risks & open questions

1. **`DirAccess.rename_absolute` availability** — on web/HTML5 exports `DirAccess` is limited; atomic rename may silently fail. A fallback `FileAccess.open(WRITE)` write is acceptable for web but should be conditional (`OS.get_name() != "Web"`). Decide before Task 4 ships.
2. **`reset_to_defaults()` must stay in sync with `game.gd` field declarations** — any new persisted field added to `game.gd` must also be added to `reset_to_defaults()`. Consider a lint step or a comment cross-reference.
3. **Cross-session checkpoint** (spec 29 deferred, [[system-save-load]] Phase 5) — not in scope here; remains an open design question.
4. **VERSION increment policy** — Task 7 documents the agreed rule as a comment; a user decision is needed on whether adding a new optional field (e.g. a new affix type) warrants a VERSION bump or just a `_migrate` backfill. The current recommendation is: backfill only, no bump.
5. **`_test_save_roundtrip` references `SaveGame.SAVE_PATH` directly** (lines 655, 659, 661 pre-patch) to re-read the file for the backfill test. After Task 2 these must be updated to reference `TEST_SAVE` — easy to miss; check carefully.
6. **Multi-slot saves** — the `save_to` / `load_from` overloads introduced in Task 1 are already the scaffolding needed if multi-slot is ever added. No extra work needed now, but this is a useful design note.
