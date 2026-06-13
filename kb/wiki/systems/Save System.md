---
type: system
tags: [save, persistence, game-state, json, trades, satchel]
status: draft
updated: 2026-06-13
sources: ["wyrd/scripts/save_game.gd", "wyrd/scripts/game.gd", "docs/wyrd-implementation-notes.md"]
---

# Save System

Wayfinder persists all cross-scene player state to a single JSON file on quit, on every meaningful action, and on scene changes.

## Save path

`user://wayfinder_save.json` (resolves to the OS user data directory; Godot manages the path). The current schema version is `1`; a version mismatch on load discards the save and starts fresh with a warning.

> ⚠️ The comment in `save_game.gd` line 8 references `user://wyrd_save.json` but the actual constant is `SAVE_PATH := "user://wayfinder_save.json"` — the comment is stale; the code is authoritative.

## What persists

All state lives on the `Game` autoload (`wyrd/scripts/game.gd`) and is written/read by `SaveGame` (`wyrd/scripts/save_game.gd`):

| Field | Type | Notes |
|---|---|---|
| `trades` | Dict of `{lv, xp}` per trade key | [[Trades and Leveling]]: carto / earth / wilds / hunt |
| `materials` | Dict of material-id → count | The [[Gathering]] satchel |
| `charts` | Array of chart dicts | The player's chart case; see [[Charts]] |
| `gold` | int | [[Economy]] currency |
| `summit_cleared` | bool | Endgame flag; unlocks Mara's epilogue |
| `muted` | bool | Master mute state (spec 38); default `true` on fresh game |
| `loadout` | Array of 3 skill ids | [[Skills]] hotbar slots 2–4 |
| `discovered_inks` | Array of ink ids | [[Inks]] discovered via bench experimentation (spec 43) |
| `seen_hints` | Dict of kind → bool | One-time [[NPCs]] skill tutorial hints already shown |
| `tutorial_step` | int | Progress through the 8-step tutorial |
| `player_hp` | int | Snapshot taken right before a scene change; `-1` = full (first boot) |
| `inventory` | Array of placed item dicts with grid positions | [[Items and Gear]] Tetris grid |
| `equipment` | Dict of slot-name → item dict | Worn gear |

### What does NOT persist

- `buffs` (Quill's timed buffs) — deliberately runtime-only; a sip never outlives the session.
- `active_chart` / `in_dungeon` — closing mid-run saves the chart as consumed (keystone V1 ruling) and reopens the game in town.
- `pending_toasts` — in-flight toast queue, discarded on restart.

## When saves happen

`Game.save_now()` is called after every meaningful mutation: crafting, spending/earning gold, quaffing, mixing inks, adding a chart, entering/exiting a dungeon, changing the loadout, advancing the tutorial, discovering an ink recipe, and on `NOTIFICATION_WM_CLOSE_REQUEST` (window quit). The file is written synchronously via `FileAccess`.

## Inventory serialization

`Vector2i` grid positions and `Color` values cannot be stored in JSON directly. `SaveGame._encode` wraps them as `{"__v2": [x,y]}` and `{"__col": [r,g,b,a]}` respectively; `_decode` unwraps them on load. On restore, each item is re-placed in the Tetris grid to rebuild the cell map — if a saved position is no longer valid, `find_first_fit` finds the next available slot.

## WYRD_NO_SAVE

Setting the env var `WYRD_NO_SAVE=1` sets `Game.persistence_enabled = false`, which prevents any file I/O. All four headless test suites run with this flag — without it they would read and clobber the real player save.

```bash
WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_loop.gd
```

## Save roundtrip caveat

`_test_save_roundtrip` in the test suites writes then deletes the real save path (`user://wayfinder_save.json`). Backing up the save before running tests is an open followup — if the test is killed mid-run the save may be left in a partial or deleted state (`docs/wyrd-implementation-notes.md`).

## Backwards compatibility

On load, saves from before [[Huntcraft]] was added (pre-ADR 0005) are patched: if `trades` lacks the `"hunt"` key it is backfilled at `{lv:1, xp:0}`. Similarly, saves from before ink discovery (spec 43) do not have `discovered_inks` — they are given `["hedge_ink", "stoneground_ink", "refined_ink"]` so no progress is regressed.

## Multiplayer interaction

In co-op (see [[Multiplayer Co-op]]), each peer keeps their own `Game` instance and their own save. The host's world is the place; the character is always yours. Guests never write the host's save. Awards (gather XP, kill XP, loot) are routed to the acting peer's machine and saved there.

## See also

- [[Trades and Leveling]] — trade XP and levels are the core of what persists
- [[Charts]] — the chart case is persisted; the active chart is not
- [[Gathering]] — materials satchel
- [[Economy]] — gold balance
- [[Items and Gear]] — inventory and equipment serialization
- [[Inks]] — discovered ink recipes persist
- [[Multiplayer Co-op]] — each peer saves independently; no shared file

## Sources

- `wyrd/scripts/save_game.gd`
- `wyrd/scripts/game.gd`
- `docs/wyrd-implementation-notes.md`
