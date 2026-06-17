---
title: Dungeon Generation & Scoring — Implementation Plan
parent: "[[system-dungeon-generation]]"
domain: Wayfinding & Dungeons
type: implementation-plan
status: ready-to-build
effort: L
tags: [wayfinder, impl]
---

# Dungeon Generation & Scoring — Implementation Plan

> Build doc for [[system-dungeon-generation]]. Done when every biome scope produces distinct room themes and boss dressing, three or more setpiece templates exist per scope, score bands pass ≥0.70 for all chart types without silent fallback, layout affixes surface as chart knobs, and multi-floor descent with staircase generation and HUD depth readout is playable.

## Definition of done

- `test_wyrd_dungeon_scene.gd` (plus a new scope-assertion block) passes with `WYRD_NO_SAVE=1` for a `snug`, `briar_maze`, and `crypt` seed; all five existing suites stay green.
- Running a briar_maze chart: at least one room has theme `thorn_bower` or `glade`; running a snug chart: at least one room has theme `root_cellar` or `wine_rack`.
- Boss room theme is scope-appropriate for every scope (not always `tomb_hall`).
- Three or more distinct setpiece templates appear across 10 fresh seeds per scope.
- Score ≥ 0.70 first-pass (no best-of-12 fallback) for `snug` (grid=28) and standard `hollow`/`crypt` charts.
- A `cramped`-affix chart produces 7–9 rooms; a `sprawling`-affix chart produces 4–6 rooms.
- Entering a multi-floor chart, reaching a staircase, and descending shows `depth+1` in the HUD; the same base seed always produces the same floor sequence; the boss floor has no staircase.

## Preconditions / dependencies

- [[impl-system-charts-wayfinding]] — `run_cfg()` is the sole input to `generate()`; Phase 4 (`cramped`/`sprawling` affixes) and Phase 5 (`floor_count` chart property) need new keys added to `charts.gd:TEMPLATES` and threaded through `game.gd:run_cfg()`.
- [[impl-system-biomes-decor]] — new theme entries in `dungeon_gen.gd:ROOM_THEMES` may name new decor `kind` keys that must also appear in `layout_loader.gd:DECOR_MODEL`. New kinds with no ready GLB must fall back to an existing path; Phase 1 sets a fallback policy so the loader never crashes.
- [[impl-system-bosses]] — Phase 1 adds a per-scope boss room theme; `_assign_rooms` currently hardcodes `"tomb_hall"` at `dungeon_gen.gd:689`. No boss scene changes required.
- [[impl-system-hud]] — Phase 5 adds a depth readout Label to `PlayerHUD.tscn` / `player_hud.gd`.
- [[impl-system-save-load]] — Phase 5 arc state (`base_seed`, `depth`, `scope`) lives in `game.gd` run-time vars; must not overwrite the real save path (use `WYRD_NO_SAVE=1`).
- Plan.md Part B / Phase B6 (inscription ritual feel): do not re-plan inscription UX here; only thread affix knobs through the existing `run_cfg()` → `generate()` pipeline.

## Tasks (ordered)

### Phase 1 — Per-scope room themes and boss room dressing

**1. Add `SCOPE_THEMES` to `dungeon_gen.gd`** — `dungeon_gen.gd` (top-level constants block, after line 103).

Add a `SCOPE_THEMES` dict that maps each scope to its allowed combat themes and its boss room theme, and add minimal new entries to `ROOM_THEMES` for snug and briar_maze biomes:

```gdscript
# New ROOM_THEMES entries (after line 102, before COMBAT_THEMES):
"root_cellar": {
    "focal":      {"kind": "pottery", "pattern": "center",  "count": [1, 1]},
    "satellites": [{"kind": "bones",      "pattern": "scatter", "count": [2, 4]},
                   {"kind": "torch_wall", "pattern": "walls",   "count": [1, 2]}],
},
"wine_rack": {
    "focal":      {"kind": "bookshelf", "pattern": "walls",  "count": [2, 3]},
    "satellites": [{"kind": "pottery",  "pattern": "scatter", "count": [2, 4]}],
},
"thorn_bower": {
    "focal":      {"kind": "brazier",   "pattern": "center",  "count": [1, 1]},
    "satellites": [{"kind": "bones",    "pattern": "scatter", "count": [2, 4]},
                   {"kind": "torch_wall","pattern": "walls",  "count": [1, 2]}],
},
"glade": {
    "focal":      {"kind": "column",    "pattern": "corners", "count": [2, 2]},
    "satellites": [{"kind": "pottery",  "pattern": "scatter", "count": [1, 3]}],
},

# Replace COMBAT_THEMES const with SCOPE_THEMES:
const SCOPE_THEMES := {
    "snug":       {"combat": ["root_cellar", "wine_rack", "ossuary"],
                   "boss": "hearthroom"},
    "hollow":     {"combat": ["tomb_hall", "ossuary", "archive"],
                   "boss": "tomb_hall"},
    "briar_maze": {"combat": ["thorn_bower", "glade", "ossuary"],
                   "boss": "thorn_bower"},
    "crypt":      {"combat": ["tomb_hall", "ossuary", "archive"],
                   "boss": "tomb_hall"},
}
# Keep COMBAT_THEMES as the crypt fallback for unknown scopes:
const COMBAT_THEMES := ["tomb_hall", "ossuary", "archive"]
```

_Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd` plus a new scope-assertion block (Task 7). _Effort:_ S.

---

**2. Wire `SCOPE_THEMES` into `_assign_rooms`** — `dungeon_gen.gd:_assign_rooms` (lines 682–751).

Thread the chart's `scope` into `_assign_rooms` via a new parameter, replacing the two hardcoded strings:

```gdscript
static func _assign_rooms(rooms: Array, rng: RandomNumberGenerator,
        boss_idx: int, adj: Array, scope: String = "crypt") -> void:
    var stheme: Dictionary = SCOPE_THEMES.get(scope, SCOPE_THEMES["crypt"])
    # line 689: was rooms[boss_idx]["theme"] = "tomb_hall"
    rooms[boss_idx]["theme"] = String(stheme.get("boss", "tomb_hall"))
    # line 751: was COMBAT_THEMES[rng.randi_range(...)]
    var ctlist: Array = stheme.get("combat", COMBAT_THEMES)
    r["theme"] = ctlist[rng.randi_range(0, ctlist.size() - 1)]
```

Update the call site at `dungeon_gen.gd:251`: `_assign_rooms(rooms, rng, boss_idx, adj, String(cfg.get("scope", "crypt")))`.

_Verify:_ Same suite. _Effort:_ S.

---

**3. Add decor fallback in `layout_loader.gd:_build_decor`** — `layout_loader.gd:_build_decor` (around line 544).

New themes (`thorn_bower`, `glade`, `root_cellar`, `wine_rack`) reuse existing GLB kinds (`brazier`, `pottery`, `bookshelf`, `bones`, `column`) already in `DECOR_MODEL`. No new GLB paths needed yet. Add a guard comment and confirm at the top of `_build_decor` that unknown kinds are silently skipped (the `if not DECOR_MODEL.has(kind): continue` guard at line 545 already handles this). No code change needed — document that new kind names must be kept in sync with `DECOR_MODEL`.

_Verify:_ Screenshot check `WYRD_SHOT=1 godot --path .` with a briar_maze chart: decor objects appear in boss and combat rooms using existing meshes. _Effort:_ XS.

---

**4. Scope-gate setpiece selection** — `dungeon_gen.gd:_pick_setpiece` (line 564).

Replace the single `SETPIECES` constant with a `SCOPE_SETPIECES` dict; fall back to `[]` rather than stamping a crypt vault into a briar maze:

```gdscript
const SCOPE_SETPIECES := {
    "snug":       ["larder"],         # Task 5
    "hollow":     ["vault", "shrine"],
    "briar_maze": ["hedge_circle"],   # Task 5
    "crypt":      ["vault", "shrine"],
}
# In _pick_setpiece, accept scope param:
static func _pick_setpiece(rooms: Array, rng: RandomNumberGenerator,
        scope: String = "crypt") -> void:
    var pool: Array = SCOPE_SETPIECES.get(scope, SCOPE_SETPIECES["crypt"])
    if pool.is_empty():
        return
    # ... (pick largest eligible combat room, same logic as before)
    rooms[best]["setpiece"] = pool[rng.randi_range(0, pool.size() - 1)]
```

Update call site at `dungeon_gen.gd:253`: `_pick_setpiece(rooms, rng, String(cfg.get("scope", "crypt")))`.

_Verify:_ `test_wyrd_dungeon_scene.gd` scope-assertion block (Task 7). _Effort:_ S.

---

### Phase 2 — Setpiece library expansion

**5. Author three new ASCII setpiece templates** — `wyrd/data/rooms/` (new files).

Create `larder.txt` (snug), `hedge_circle.txt` (briar_maze), and `crypt_hall.txt` (crypt/hollow), following the same convention as `vault.txt` and `shrine.txt` (7×7 or 9×9, `#` = interior wall, `.` = floor, letters from `SETPIECE_DECOR`):

`larder.txt` (8×8 snug storage room — shelved walls, pottery cluster):
```
........
.p....p.
.p.....p
........
.p.....p
.p....p.
........
```

`hedge_circle.txt` (9×9 briar-maze glade ring — column+brazier ring):
```
...o.o...
..o...o..
.o.....o.
o...b...o
.........
o...b...o
.o.....o.
..o...o..
...o.o...
```

`crypt_hall.txt` (11×7 double-column hall — sarcophagi flanking a central path):
```
s....s...s.
...........
...........
......a....
...........
s....s...s.
...........
```

Add `SCOPE_SETPIECES["crypt"]` and `["hollow"]` to include `"crypt_hall"` (Task 4 already wires the pool). Ensure all new glyph mappings exist in `SETPIECE_DECOR` at `dungeon_gen.gd:108–111` (only `p` = pottery needs adding if not present — check: `p` is already mapped). No new GLBs required.

_Verify:_ Generate 10 seeds for `crypt` and `briar_maze` scopes in `test_wyrd_dungeon_scene.gd` (Task 7 new block); assert at least two distinct `setpiece` values appear across the set. _Effort:_ S.

---

### Phase 3 — Scope-aware score bands

**6. Populate per-scope defaults in `_score_cfg`** — `dungeon_gen.gd:_score_cfg` (lines 117–126).

If `cfg` does not specify bands, pick them from the scope:

```gdscript
static func _score_cfg(cfg: Dictionary = {}) -> Dictionary:
    var scope := String(cfg.get("scope", "crypt"))
    # Per-scope defaults: snug is a smaller grid, briar_maze allows more dead ends.
    const SCOPE_BANDS := {
        "snug":       {"room_count_min": 3, "room_count_max": 7,
                       "floor_ratio_min": 0.18, "floor_ratio_max": 0.60,
                       "dead_end_max_frac": 0.50},
        "briar_maze": {"dead_end_max_frac": 0.55, "corridor_ratio_max": 2.4},
        "hollow":     {},
        "crypt":      {},
    }
    var sb: Dictionary = SCOPE_BANDS.get(scope, {})
    return {
        "room_count_min":           int(cfg.get("room_count_min",   sb.get("room_count_min",   ROOM_COUNT_MIN))),
        "room_count_max":           int(cfg.get("room_count_max",   sb.get("room_count_max",   ROOM_COUNT_MAX))),
        "floor_ratio_min":          float(cfg.get("floor_ratio_min", sb.get("floor_ratio_min",  FLOOR_RATIO_MIN))),
        "floor_ratio_max":          float(cfg.get("floor_ratio_max", sb.get("floor_ratio_max",  FLOOR_RATIO_MAX))),
        "corridor_ratio_max":       float(cfg.get("corridor_ratio_max", sb.get("corridor_ratio_max", CORRIDOR_RATIO_MAX))),
        "dead_end_max_frac":        sb.get("dead_end_max_frac", DEAD_END_MAX_FRAC),
        "critical_path_target_frac": CRITICAL_PATH_TARGET_FRAC,
    }
```

Also add scope to the `DEBUG_SCORE` print in `layout_loader.gd:267–273`:

```gdscript
print("[layout_loader] score=%.2f scope=%s ..." % [s.total, layout.get("scope","?")])
```

_Verify:_ `test_wyrd_dungeon_scene.gd` new block: generate a snug chart (`cfg.scope="snug"`, `cfg.grid=28`) and assert `score.total >= 0.70` on first attempt, not best-of-12. _Effort:_ S.

---

**7. Extend `test_wyrd_dungeon_scene.gd` with scope-variance assertions** — `wyrd/test_wyrd_dungeon_scene.gd` (new assertion block after existing checks).

Add a headless-only `_check_scope_variance()` function that:
- Generates a snug layout via `DungeonGenScript.generate(-1, {"scope": "snug", "grid": 28, "room_min": 6, "room_max": 9})` and asserts at least one room has `theme` in `["root_cellar", "wine_rack"]` and `score.total >= 0.70`.
- Generates a briar_maze layout and asserts at least one room has `theme` in `["thorn_bower", "glade"]` and boss room theme is `"thorn_bower"`.
- Generates 5 crypt seeds and asserts at least two distinct `setpiece` values appear.

_Verify:_ All five existing suites green; new block prints `✓` for all scope-variance checks. _Effort:_ S.

---

### Phase 4 — Generation tuning knobs surfaced via chart affixes

**8. Add `cramped` and `sprawling` affix families to `charts.gd`** — `wyrd/data/charts.gd:AFFIXES` (after line 186, before `TROPHY_TO_AFFIX`).

```gdscript
"cramped": {
    "name": "Cramped",  "bad_name": "Hollowed Out",
    "good_desc": "A warren of tight rooms — many small chambers, close quarters.",
    "bad_desc": "The hollow has caved in — fewer, emptier rooms.",
    "kind": "layout", "req_carto": 6, "base_stab": 52,
    "gen_good": {"grid": 32, "room_max": 10, "room_count_max": 9},
    "gen_bad":  {"grid": 40, "room_min": 9,  "room_count_min": 4},
},
"sprawling": {
    "name": "Sprawling", "bad_name": "Constricted",
    "good_desc": "Grand wide chambers — fewer rooms, more breathing room.",
    "bad_desc": "Something sealed the passages — tight and close.",
    "kind": "layout", "req_carto": 10, "base_stab": 50,
    "gen_good": {"grid": 56, "room_min": 10, "room_max": 18, "room_count_min": 4},
    "gen_bad":  {"grid": 32, "room_max": 9,  "room_count_max": 8},
},
```

Add both to `BASE_WEIGHTS` with weight `6`.

_Verify:_ No runtime test yet — validated in Task 10. _Effort:_ S.

---

**9. Thread layout-affix knobs through `game.gd:run_cfg`** — `wyrd/scripts/game.gd:run_cfg` (lines 743–766).

After building `cfg` from the template's `gen` block, iterate over active affixes and merge any `gen_good` / `gen_bad` overrides:

```gdscript
# After: cfg["affixes"] = active_chart.get("affixes", [])
for a in cfg["affixes"]:
    var aff: Dictionary = ChartsData.AFFIXES.get(String(a.get("id", "")), {})
    var gen_override: Dictionary = aff.get(
        "gen_good" if bool(a.get("good", false)) else "gen_bad", {})
    for k in gen_override:
        cfg[k] = gen_override[k]
```

_Verify:_ `test_wyrd_dungeon_scene.gd` Task 10 block (or debug print during a playtest). _Effort:_ XS.

---

**10. Extend `test_wyrd_dungeon_scene.gd` with layout-affix assertions** — new `_check_layout_affixes()` block.

Generate a `cramped` layout (inject `{"scope":"hollow","grid":32,"room_max":10,"room_count_max":9}` into cfg) and assert `layout.rooms.size() >= 7 and layout.rooms.size() <= 9`; generate a `sprawling` layout and assert `layout.rooms.size() <= 6`. Also assert `DEBUG_SCORE` `_raw.rooms` agrees with the cfg band.

_Verify:_ `test_wyrd_dungeon_scene.gd` all green. _Effort:_ S.

---

### Phase 5 — Multi-floor descent

> Depends on Phases 1–4 being green. Large, self-contained. Pairs with [[impl-system-charts-wayfinding]] for `floor_count` on chart templates.

**11. Add `floor_count` to chart templates in `charts.gd`** — `wyrd/data/charts.gd:TEMPLATES` (lines 19–67).

Add `"floor_count": 1` to `snug`, `tier_1`, `hollow`, `briar_maze`; set `"floor_count": 3` on `summit`. The key is optional and defaults to `1` everywhere it is absent:

```gdscript
"summit": {
    ...
    "floor_count": 3,
    "gen": { ... },
},
```

_Verify:_ No runtime change yet; `run_cfg()` task (Task 12) reads it. _Effort:_ XS.

---

**12. Thread `floor_count` and `depth` through `game.gd:run_cfg` and arc state** — `wyrd/scripts/game.gd`.

Add three run-state vars below `active_chart`:

```gdscript
var active_floor_count: int = 1   # total floors in the current arc
var active_depth: int = 1         # floor we are currently on (1-indexed)
var active_base_seed: int = -1    # original chart seed, held across descents
```

In `run_cfg()`, read `floor_count` from the template and expose `depth`:

```gdscript
cfg["floor_count"] = int(t.get("floor_count", 1))
cfg["depth"] = active_depth
# Deterministic per-floor seed: base_seed × 31 + depth
if active_depth > 1 and active_base_seed >= 0:
    cfg["seed"] = (active_base_seed * 31 + active_depth) & 0x7FFFFFFF
```

Add `start_arc(chart)` helper that sets `active_base_seed`, resets `active_depth`, and calls `set_active_chart`. Existing chart-run code calls this instead of setting `active_chart` directly.

_Verify:_ Manual integration; confirmed by Task 16 headless test. _Effort:_ S.

---

**13. Add staircase placement to `dungeon_gen.gd:_generate_one`** — `dungeon_gen.gd:_generate_one` (lines 165–277, return dict at line 263).

After placing the boss room (exit), if `depth < floor_count`, pick a staircase tile: a floor tile adjacent to the `exit` tile that is NOT inside the boss room, not the entry, and not already occupied:

```gdscript
# Compute inside _generate_one, after exit is set:
var floor_count: int = int(cfg.get("floor_count", 1))
var depth: int = int(cfg.get("depth", 1))
var staircase: Dictionary = {}
if depth < floor_count:
    staircase = _pick_staircase_tile(grid, exit, boss, entry, rooms)
# Return dict: add "staircase": staircase, "floor_count": floor_count, "depth": depth
```

```gdscript
static func _pick_staircase_tile(grid: Array, exit: Dictionary,
        boss: Dictionary, entry: Dictionary, rooms: Array) -> Dictionary:
    var offsets := [Vector2i(2,0), Vector2i(-2,0), Vector2i(0,2), Vector2i(0,-2),
                    Vector2i(1,1), Vector2i(-1,1), Vector2i(1,-1), Vector2i(-1,-1)]
    var bx0 := int(boss.x); var bx1 := bx0 + int(boss.w) - 1
    var by0 := int(boss.y); var by1 := by0 + int(boss.h) - 1
    for off in offsets:
        var sx := int(exit.x) + off.x
        var sy := int(exit.y) + off.y
        if sy < 1 or sy >= grid.size() - 1 or sx < 1 or sx >= grid[0].size() - 1:
            continue
        if String(grid[sy][sx]) != "floor":
            continue
        if sx >= bx0 and sx <= bx1 and sy >= by0 and sy <= by1:
            continue  # inside boss room
        if sx == int(entry.x) and sy == int(entry.y):
            continue
        return {"x": sx, "y": sy}
    return {}
```

_Verify:_ Task 16 headless test. _Effort:_ M.

---

**14. Instantiate `StaircaseNode` in `layout_loader.gd:_build_exit_waystone`** — `layout_loader.gd:_build_exit_waystone` (lines 1071–1096).

After the existing exit waystone block, check `layout.staircase`:

```gdscript
# At end of _build_exit_waystone, new block:
var staircase = layout.get("staircase", {})
if not (staircase as Dictionary).is_empty():
    var sn: Node3D = StaircaseNodeScript.new()
    sn.position = Vector3(int(staircase.x) + 0.5, 0.0, int(staircase.y) + 0.5)
    add_child(sn)
```

Create `wyrd/scripts/staircase_node.gd` — a `Node3D` with a small `Area3D` interact zone that emits `descended(next_seed: int)` when the player steps into it. Game hears this signal via `game.gd` (new `_on_descended` handler) and reloads `World.tscn` with `active_depth += 1` (which causes `run_cfg()` to generate the next floor seed).

Also add `const StaircaseNodeScript = preload("res://scripts/staircase_node.gd")` at the top of `layout_loader.gd` (near the other const preloads, lines 12–21).

_Verify:_ Playtest: walk to staircase → descend → new floor generated with depth+1 in score print. _Effort:_ M.

---

**15. Add depth readout to `player_hud.gd`** — `wyrd/scripts/player_hud.gd` (`_ready` and `_build_wyrd_overlay`).

Add a `Label` node (`_depth_lbl`) that is hidden unless `game.active_floor_count > 1`, and a `refresh_depth(d: int, total: int)` method. Wire it in the overlay builder and refresh it from `layout_loader.gd:_ready` after the dungeon is built (call `$PlayerHUD.refresh_depth(depth, floor_count)` if the HUD node exists):

```gdscript
# player_hud.gd — new:
var _depth_lbl: Label = null
func refresh_depth(d: int, total: int) -> void:
    if _depth_lbl == null:
        return
    _depth_lbl.visible = total > 1
    _depth_lbl.text = "Floor %d / %d" % [d, total]
```

`layout_loader.gd:_ready`, after the final print: 
```gdscript
var hud := get_tree().get_first_node_in_group("player_hud")
if hud != null and hud.has_method("refresh_depth"):
    hud.refresh_depth(int(layout.get("depth", 1)), int(layout.get("floor_count", 1)))
```

_Verify:_ Playtest with a `summit` (3-floor) chart — depth label reads "Floor 1 / 3" on first load, "Floor 2 / 3" after first descent. Single-floor charts show no label. _Effort:_ S.

---

**16. Extend test suite — `test_wyrd_descent.gd`** — new headless test file at `wyrd/test_wyrd_descent.gd`.

Pure-logic test (no World.tscn instantiation): call `DungeonGenScript.generate()` directly for depths 1, 2, 3 of a 3-floor arc with `base_seed=12345`. Assert:
- `layout.staircase` is non-empty for floors 1 and 2.
- `layout.staircase` is empty dict (`{}`) on floor 3 (`depth == floor_count`).
- Floor 2 seed == `(12345 * 31 + 2) & 0x7FFFFFFF`.
- Each floor has `layout.rooms.size() >= 2`.
- All five existing suites remain green.

_Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_descent.gd` exits 0. _Effort:_ S.

---

## First commit (smallest shippable slice)

**Tasks 1–3 + 7 (partial):** Add `SCOPE_THEMES` and new `ROOM_THEMES` entries, wire them into `_assign_rooms`, confirm decor fallback, and add the scope-variance assertion block to `test_wyrd_dungeon_scene.gd`.

**Acceptance:** Running `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd` from `wyrd/` shows `✓` for all existing checks AND the new scope-theme assertions for briar_maze and snug. A screenshot (`WYRD_SHOT=1`) with a briar_maze chart shows rooms using `brazier`/`pottery`/`bones` decor layouts (not always `sarcophagus`-dominated) and the boss room no longer tagged `tomb_hall` in the score print.

---

## Test & verification plan

**All suites run as:** `cd wyrd && WYRD_NO_SAVE=1 godot --headless --path . --script res://<suite>.gd`

| Suite | What it must show |
|-------|------------------|
| `test_wyrd_loop.gd` | Unchanged green — no regressions from SCOPE_THEMES constant rename |
| `test_wyrd_dungeon_scene.gd` | All existing checks pass; new scope-variance block passes (Tasks 7, 10) |
| `test_wyrd_transitions.gd` | Unchanged green |
| `test_skills.gd` | Unchanged green |
| `test_wyrd_descent.gd` (new, Phase 5) | Staircase presence/absence assertions, seed determinism, room count |

**Screenshot playtest checks (not headless):**
- `WYRD_SHOT=1 godot --path wyrd` with a `briar_maze` chart: boss room decor reads non-crypt; at least one `glade`/`thorn_bower`-themed room visible.
- `WYRD_SHOT=1 godot --path wyrd` with a `summit` chart after Phase 5: HUD shows "Floor 1 / 3"; staircase node visible in the dungeon.

**Score-band regression check (Phase 3):**
- With `DEBUG_SCORE=true`, run `snug` chart 5 times; every run shows `attempts=1` (first-pass accept, not best-of-12 fallback).

---

## Risks & open questions

1. **New theme GLB gaps:** `thorn_bower`, `glade`, `root_cellar`, `wine_rack` all reuse existing GLBs (`brazier`, `pottery`, `bookshelf`, `bones`). The rooms will read thematically distinct from role and layout pattern alone, not from unique models. Unique models are a [[impl-system-biomes-decor]] concern; document this clearly so the art pass knows what to target.

2. **`cramped`/`sprawling` as rollable affixes:** Adding them to `BASE_WEIGHTS` means they can land randomly on any chart. That may surprise players who inscribed a specific template for its grid size. Consider restricting to `affix_slots >= 2` templates only, or making them `"kind": "layout"` and filtering them out of the random roll pool (slottable only via deliberate ink bias). Decision needed before Task 8 ships.

3. **`_score_cfg` `SCOPE_BANDS` const inside a static func:** GDScript does not allow a `const` declaration inside a `static func`. The `SCOPE_BANDS` dict must instead be a top-level `const` in the file or inlined as a literal. Write it as a top-level constant next to `SCORE_THRESHOLD`.

4. **Multi-floor HP policy (spec-03 open question):** Does the rest/Hearth room heal between floors? If yes, multi-floor descent loses most of its tension. Recommended: Hearth heals on the floor it appears; descending carries current HP. The Hearth on the final floor before the boss is the intended recovery window. Needs explicit decision before Phase 5 ships.

5. **`staircase_node.gd` interact zone vs. player scanner:** The existing `ExitWaystoneScript` uses a `Node3D` approach; `StaircaseNode` should use the same `Area3D` on `INTERACT_LAYER` pattern as `Shrine.tscn` / `Chest.tscn` so the player's scanner auto-detects it without new input code.

6. **`test_wyrd_descent.gd` autoload behavior:** The existing test harness note (`feedback_godot_headless_test_harness`) confirms autoloads DO load in `--script` mode. `test_wyrd_descent.gd` calls `DungeonGenScript.generate()` directly (static, no autoloads needed), so it avoids this complexity entirely — keep it pure-static.

---

## Build status — 2026-06-16

**Completed (Phases 1–3 + partial Phase 4):**

- `SCOPE_THEMES` const added to `dungeon_gen.gd` (maps each scope to combat theme list + boss theme).
- Four new `ROOM_THEMES` entries: `root_cellar`, `wine_rack`, `thorn_bower`, `glade` — all reuse existing GLB kinds.
- `SCOPE_BANDS` top-level const added (Risk 3 resolved — not inside static func).
- `_score_cfg()` updated to read per-scope band defaults; snug and briar_maze no longer rely on best-of-12 fallback.
- `_assign_rooms()` accepts `scope` param; boss room theme and combat theme list are now scope-driven.
- `_pick_setpiece()` accepts `scope` param; uses `SCOPE_SETPIECES` pool per scope.
- `SCOPE_SETPIECES` const: snug→`["larder"]`, briar_maze→`["hedge_circle"]`, hollow/crypt→`["vault","shrine","crypt_hall"]`.
- `SETPIECES` legacy const preserved for backward compatibility (not used by new path).
- Three new ASCII setpiece templates authored: `larder.txt` (snug), `hedge_circle.txt` (briar_maze), `crypt_hall.txt` (crypt/hollow).
- `test_procgen.gd` extended with: scope-variance assertions (snug/briar_maze/crypt/hollow boss themes + combat themes), layout-affix knob checks (cramped/sprawling cfg), setpiece-variety assertions (>= 2 distinct values for crypt over 5 seeds, pool-validity for briar_maze and snug).
- Return contract of `generate(seed, cfg)` unchanged — `grid/rooms/score/bossKind` all preserved.

**Deferred:**
- **Phase 4 chart-affix wiring** (Tasks 8–10): `charts.gd` AFFIXES cramped/sprawling entries and `game.gd:run_cfg()` threading — out of scope (would require editing `charts.gd` and `game.gd`).
- **Phase 5 multi-floor descent** (Tasks 11–16): staircase generation, `layout_loader.gd` staircase node, `player_hud.gd` depth readout, `game.gd` arc state — all require out-of-scope files (`layout_loader.gd`, `game.gd`, `player_hud.gd`).
- **Phase 3 score-print scope label** (Task 6 tail): adding `scope=%s` to the DEBUG_SCORE print in `layout_loader.gd:267` — out of scope (layout_loader.gd is gated).

**Known open issues:**
- Snug boss room uses `"hearthroom"` theme as metadata; `_dress_rooms` skips boss rooms, so visual dressing comes from `layout_loader` (same as crypt using `"tomb_hall"`). Art pass should target hearthroom dressing for snug boss arenas.
- `crypt_hall.txt` is 11 wide — rooms must be at least 11×8 for the stamp to fit; smaller rooms simply skip it (no crash, `_stamp_setpiece` returns early if template is larger than room).
