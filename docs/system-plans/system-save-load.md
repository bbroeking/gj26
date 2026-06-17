---
title: Save / Load & Persistence
domain: Persistence
type: system
status: partial
effort: M
tags: [wayfinder, plan]
---

# Save / Load & Persistence

> The single-slot JSON save works for every shipped feature but has no corruption guard, no save-slot UX, and the roundtrip test still touches the real save path — three gaps that matter before a public build.

## Current state

`wyrd/scripts/save_game.gd` (static class, `VERSION = 1`, `SAVE_PATH = "user://wayfinder_save.json"`) handles the full loop: serialise `game.gd` state to JSON, round-trip `Vector2i` and `Color` through typed wrappers (`__v2` / `__col`), and restore all fields on load (`save_game.gd:13–36`, `41–113`). Fields saved: `trades`, `materials`, `charts`, `gold`, `summit_cleared`, `muted`, `loadout`, `discovered_inks`, `seen_hints`, `tutorial_step`, `player_hp`, `inventory` (Tetris grid re-placed on load), `equipment`.

Version checking is a strict equality guard (`save_game.gd:53–55`): any version mismatch discards the save silently and starts fresh. The v1 → legacy-four-trade migration (ADR 0012) sums `carto/earth/wilds/hunt` XP into the single Wayfinding skill and recomputes the level if `"wayfinding"` is absent (`save_game.gd:72–81`). The pre-spec-43 ink backfill path (`discovered_inks` absent → seed three base inks) is also live (`save_game.gd:88–95`). `game.gd:_ready` honours `WYRD_NO_SAVE` to skip the load (`game.gd:199–201`); `persistence_enabled := false` also blocks `save_now()` (`game.gd:89–93`). `save_now()` is called after every state-mutating event (craft, sell, quaff, chart added, loadout set, etc.).

`wyrd/scripts/checkpoint.gd` is an in-memory autoload (`Checkpoint`) that stores a single respawn slot per session — room id, position, and full HP — written by Hearths and read by `player_controller` on death (`checkpoint.gd:1–39`). No cross-session persistence is intended or implemented. A `clear()` call happens at every dungeon entry and return (`game.gd:683–685`, `729–731`).

The roundtrip test (`test_wyrd_loop.gd:607–672`) covers all persisted fields including the ADR-0012 Wayfinding migration and the pre-43 ink backfill, and it calls `SaveGame.clear()` at the end. However, the test writes to the real `SAVE_PATH` (`user://wayfinder_save.json`) rather than a temp path — if the process dies mid-test, the player's live save is overwritten with test data. The roadmap notes this as an open followup (`wyrd-roadmap.md` "Save-file safety").

Status is **partial**: the core mechanism ships and is green in all four test suites, but the corruption guard (version-mismatch currently silently discards the save), the test-safety gap, save-slot UX, and cross-session checkpoint persistence are all unbuilt.

## Gaps — what needs fleshing out

1. **(Blocker for public build) Test-roundtrip safety** — `_test_save_roundtrip` writes directly to `user://wayfinder_save.json`. Running the headless suite without `WYRD_NO_SAVE=1` would clobber a real save. The harness does set `persistence_enabled = false` via the env var, but the test manually calls `SaveGame.save(game)` bypassing that flag (`test_wyrd_loop.gd:629`). The fix is to redirect `SAVE_PATH` to a temp file inside the test, or to add a `SaveGame.save_to(path, game)` overload.
2. **(Blocker for public build) Corruption guard** — `save_game.gd:53–55` silently discards a save on any version mismatch and returns `false`. There is no backup-and-rename, no "your save could not be loaded" dialog, and no way to recover from a partial write (power loss mid-`store_string`). An atomic write (temp file + rename) and a user-visible error toast when a save is discarded are both missing.
3. **Version migration path is hard-coded for v1 only** — the legacy-trade migration only fires once (checks for the absence of `"wayfinding"`). When `VERSION` increments to 2 a proper migration chain needs to be added; today there is no scaffolding for v2+.
4. **No save-slot UX** — one fixed slot. The Lantern (system menu) has no "New Game" / "Delete Save" / slot picker. Players can't start fresh without manually deleting `user://wayfinder_save.json`.
5. **Cross-session checkpoint persistence** — `checkpoint.gd` is explicitly in-memory only (spec 29 ruling). Dying and quitting mid-run means returning to the dungeon entrance on reload rather than the last Hearth. Whether this should become cross-session is an open design question.
6. **Timed buffs not persisted** — `game.gd:buffs` is documented as "runtime-only, not saved" (`wyrd-roadmap.md` A8-full note). This is an intentional design call but worth calling out explicitly.

## Plan

### Phase 1 — Test safety (close the open followup from CLAUDE.md)

- Add a `SaveGame.save_to(path: String, game: Node) -> bool` overload that takes an explicit path; the existing `save()` calls through to it with `SAVE_PATH`.
- In `_test_save_roundtrip`, replace the direct `SaveGame.save(game)` / `SaveGame.load_into(game2)` calls with the path-overload variant pointing at `"user://wyrd_test_save.json"`. Remove the file in the `clear()` step.
- Verify the real `SAVE_PATH` file is never touched when the suite runs under `WYRD_NO_SAVE=1`.
- **DoD:** run `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd`; confirm `user://wayfinder_save.json` does not exist after the run (use `ls $(godot --path wyrd --headless -e --quit 2>&1 | grep -o 'user:/.*' | head -1)` or check Godot's user data dir). All 333+ checks still green.
- **Effort:** S

### Phase 2 — Atomic writes + corruption guard

- Wrap `FileAccess.open` / `store_string` in `save_game.gd:save()` to write to `SAVE_PATH + ".tmp"` first, then `DirAccess.rename_absolute` to the real path. Drop the `.tmp` file if rename fails.
- On `load_into`, when `parsed == null` or version is wrong: try loading `SAVE_PATH + ".bak"` before giving up. Before overwriting the real path in `save()`, copy the existing file to `.bak`.
- Add a `SaveGame.LOAD_RESULT` enum (`OK`, `CORRUPT`, `VERSION_MISMATCH`, `NOT_FOUND`); change `load_into` to return this instead of `bool`.
- In `game.gd:_ready`, if result is `CORRUPT` or `VERSION_MISMATCH`, call `Game.notify("Your save could not be read — starting fresh.")` so the player knows.
- **DoD:** manually corrupt `user://wayfinder_save.json` (write `{badkey}`), relaunch the game, see the toast; confirm the `.bak` path is loaded instead when present. The roundtrip test with version mismatch (`raw["version"] = 99`) returns `VERSION_MISMATCH`. All headless suites green.
- **Effort:** S

### Phase 3 — Migration scaffolding for VERSION 2+

- Add a `static func _migrate(data: Dictionary) -> Dictionary` in `save_game.gd` that applies versioned transforms in sequence (e.g. `if int(data.version) < 2: _migrate_to_v2(data)`). Call it in `load_into` before the field-restore block.
- The existing ADR-0012 legacy-trade migration and the pre-43 ink backfill become the first two entries in the chain.
- **DoD:** a unit test in `test_wyrd_loop.gd` that injects `"version": 0` data and asserts the migration chain produces a valid v-current dictionary. Headless suites green.
- **Effort:** S

### Phase 4 — Save-slot UX (New Game / Delete Save)

- Add a "New Game" button to The Lantern (`system_menu.gd`) that calls `SaveGame.clear()` then `Game.save_now()` (to write a fresh default state) and reloads the Town scene. Show a confirmation dialog first.
- Optionally: a "Copy Save" export to clipboard (base64) for the web/demo use-case.
- **DoD:** from a live save, open the Lantern, press "New Game", confirm — the game restarts at tutorial step 0 with no materials or charts. The old save file is gone. Headless suites unaffected.
- **Effort:** S

### Phase 5 — Cross-session checkpoint (expansion, pending design call)

This is explicitly deferred by spec 29. If the design decision changes:

- Extend `checkpoint.gd:save()` to write a `"checkpoint"` key into the main save via `SaveGame` (or a parallel `user://wyrd_checkpoint.json`), cleared on dungeon entry and clean return to town.
- On `load_into`, populate `Checkpoint._slot` if the key exists.
- `player_controller` already reads `Checkpoint` on respawn; no logic change needed there.
- **DoD:** die at a Hearth; quit; relaunch; re-enter the same chart seed — respawn at the Hearth room rather than the entrance. Existing checkpoint headless coverage (if any) plus a manual playtest.
- **Effort:** M (the design question dominates; the code is straightforward)

## Dependencies & links

- [[system-trades-progression]] — Wayfinding XP/level is the primary persisted progression; ADR-0012 migration in `save_game.gd:72-81` is load-critical.
- [[system-inventory-equipment]] — Tetris grid and equipment slots round-trip through `_items_out` / `_equipment_out`; the re-grid-on-load path (`save_game.gd:97-112`) must stay consistent with any inventory shape changes.
- [[system-charts-wayfinding]] — charts array, `discovered_inks`, and `summit_cleared` are all save fields; any new chart format keys need encode/decode coverage.
- [[system-skills-hotbar]] — loadout (3-skill array) rides the save; `SKILL_REQS` gates apply on restore via `set_loadout` validation.
- [[system-crafting]] — discovered ink state (`discovered_inks`) is the spec-43 persistence contract; crafting data changes must not break the pre-43 backfill path.
- [[system-economy]] — gold and `materials` dict are saved; vendor/buy/sell paths all call `save_now()`.
- [[system-multiplayer-netcode]] — co-op guests do NOT share a save; each peer owns their own `user://` slot; timed buffs are already runtime-only to avoid sync issues.
- [[system-npc-story-tutorial]] — `tutorial_step` and `seen_hints` ride the save; NPC dialog shown-once logic depends on the hints dict loading correctly.
- Plan.md Part B / Phase B7 (loop-feel) is complete per the roadmap (shipped 2026-06-12); no save-side work is outstanding from that phase.

## Verification

- **Phase 1:** `cd wyrd && WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` — all checks green; `user://wayfinder_save.json` must not exist after run.
- **Phase 2:** manual corruption test (write `{` to the save file, launch); toast visible. Roundtrip test with `raw["version"] = 99` returns the `VERSION_MISMATCH` result. All four headless suites green under `WYRD_NO_SAVE=1`.
- **Phase 3:** inject `"version": 0` in the roundtrip test; assert migration output matches current schema. All headless suites green.
- **Phase 4:** manual playtest — New Game flow from a live save; confirm tutorial step 0 + empty satchel. Headless suites unaffected (no save-slot state in the harness).
- **Phase 5:** manual playtest — die at Hearth, quit, relaunch, re-enter same chart, respawn at Hearth. Existing headless suites remain green.

## Open questions

1. **Cross-session checkpoint** — should dying in a chart and quitting mid-run mean the player re-enters at the last Hearth next session? Spec 29 says no; worth revisiting before a public playtest.
2. **Version increment policy** — when does `VERSION` tick to 2? Agreed criteria needed (any new field = minor patch with backfill? Only breaking schema changes?).
3. **Multi-slot saves** — is there ever a case for more than one save slot (e.g. per Steam profile, per co-op session)? The current single-file design makes this a bigger refactor if added later.
