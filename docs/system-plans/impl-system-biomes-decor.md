---
title: Biomes, Decor & Breakables — Implementation Plan
parent: "[[system-biomes-decor]]"
domain: Wayfinding & Dungeons
type: implementation-plan
status: ready-to-build
effort: L
tags: [wayfinder, impl]
---

# Biomes, Decor & Breakables — Implementation Plan

> Build doc for [[system-biomes-decor]]. Done when `briar_maze` and `hollow` chart runs each show distinct decor palettes, the three unused crypt GLBs are placed, bones/bookshelf shatter, and `_decor_density_mult` scales with `festival_pace`.

## Definition of done

- Loading a `briar_maze` chart (`WYRD_DEV_CHART=briar_maze`) screenshots with zero crypt sarcophagi and at least one briar-themed prop.
- Loading a `hollow` chart screenshots with earthy/mossy palette and zero crypt-stone sarcophagi.
- `archway`, `stairs`, and `door_wood` GLBs (already in `models/`) are placed in crypt runs — archway at entrance/corridor mouths, stairs in deep rooms, door_wood as static decor.
- `bones` and `bookshelf` shatter on arrow hit (arrow hits Hurtbox → `take_damage` → `_break()`).
- A `festival_pace`-good chart produces ≥1.35× baseline decor count (asserted in `test_wyrd_decor.gd`).
- `test_wyrd_dungeon_scene.gd` remains green throughout.

## Preconditions / dependencies

- [[impl-system-dungeon-generation]] — `_dress_rooms` and `_assign_rooms` are the insertion points for scope-keyed theme selection; both must be stable before per-scope branching goes in. Currently stable — no pending changes to that contract.
- [[impl-system-charts-wayfinding]] — `scope` field on each template already set (`charts.gd` line 25–65); routing reads it. No new templates needed for Phase 1/2.
- Phase 3 shatter shader is noted in [[system-combat-juice-vfx]] as a deferred polish item — coordinate to avoid duplicate effort if that plan lands first.
- **Asset gate for Phase 2:** `briar_maze` and `hollow` procedural palettes below (wall color + noise) need no new GLBs. The parent note's Phase 2 calls for new Meshy GLBs (hollow barrel, mossy log, etc.) but those are explicitly deferred here — Phase 2 ships a procedural palette swap only. New props come after the palette is validated in-game.
- `test_wyrd_decor.gd` does not exist — Task 9 creates it.

## Tasks (ordered)

### Phase 1 — Wire unused crypt GLBs + extend DECOR_BREAKABLE

**Task 1** — `wyrd/scripts/layout_loader.gd:DECOR_MODEL` (line 37). Add three entries:
```gdscript
"archway":   "res://models/dungeon_crypt_archway_v1.glb",
"stairs":    "res://models/dungeon_crypt_stairs_v1.glb",
"door_wood": "res://models/dungeon_crypt_door-wood_v1.glb",
```
_Verify:_ `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_dungeon_scene.gd` stays green (GLBs exist, load() path won't crash). _Effort:_ S.

**Task 2** — `wyrd/scripts/layout_loader.gd:DECOR_COLLIDER` (line 50). Add collider sizes:
```gdscript
"archway":   null,                        # pass-through gate frame
"stairs":    Vector3(1.1, 0.5, 2.2),
"door_wood": Vector3(1.0, 2.0, 0.3),
```
_Verify:_ Same headless suite. _Effort:_ S.

**Task 3** — `wyrd/scripts/dungeon_gen.gd:ROOM_THEMES` (line 49). Add `entry_arch` theme and extend `antechamber` satellites; add `descent_hall` theme for deep rooms:
```gdscript
"entry_arch": {
    "focal":      {"kind": "archway",  "pattern": "center",  "count": [1, 1]},
    "satellites": [{"kind": "torch_wall", "pattern": "walls", "count": [1, 2]}],
},
"descent_hall": {
    "focal":      {"kind": "stairs",   "pattern": "center",  "count": [1, 1]},
    "satellites": [{"kind": "column",  "pattern": "corners", "count": [2, 4]},
                   {"kind": "torch_wall", "pattern": "walls", "count": [1, 2]}],
},
```
Also add `"door_wood"` as an optional satellite to the existing `antechamber` theme (count [0, 1]).
_Verify:_ `test_wyrd_dungeon_scene.gd` green. _Effort:_ S.

**Task 4** — `wyrd/scripts/dungeon_gen.gd:_assign_rooms` (line 682). After fixed roles + rest/treasure/shrine assignment, promote entrance room to `"entry_arch"` theme and assign `"descent_hall"` to the deepest combat room (depth ≥ 3):
```gdscript
rooms[0]["theme"] = "entry_arch"   # override antechamber default
# after all roles resolved, find deepest combat room:
var max_d := 0
for i in rooms.size():
    if rooms[i].get("role","") == "combat" and int(depths[i]) > max_d:
        max_d = int(depths[i]); deepest_idx = i
if deepest_idx >= 0: rooms[deepest_idx]["theme"] = "descent_hall"
```
(Note: `depths` is computed inside `_generate_one` at line 270 — pass it into `_assign_rooms` or compute a local BFS from `adj`; `_bfs_depths` is already a static helper.)
_Verify:_ Boot a crypt chart (`WYRD_DEV_CHART=tier_1 WYRD_SHOT=1`), inspect screenshot for archway at entrance and stairs in a deep room. `test_wyrd_dungeon_scene.gd` green. _Effort:_ M.

**Task 5** — `wyrd/scripts/dungeon_gen.gd:DECOR_KINDS` (line 28). Add `"archway"` and `"stairs"` to the constant used for scatter fallback candidates. Also update `DECOR_KINDS` to drop redundancy note — this constant is referenced in setpiece logic; verify no setpiece template uses it directly.
_Verify:_ `test_wyrd_dungeon_scene.gd` green. _Effort:_ S.

**Task 6** — `wyrd/scripts/layout_loader.gd:DECOR_BREAKABLE` (line 64). Add `bones` and `bookshelf`:
```gdscript
"bones":     Color(0.82, 0.78, 0.65),
"bookshelf": Color(0.34, 0.24, 0.14),
```
_Verify:_ Playtest — fire arrow at bones in a crypt run, confirm GPUParticles3D burst appears in cream/brown. `test_wyrd_dungeon_scene.gd` green. _Effort:_ S.

**Task 7** — `wyrd/scripts/layout_loader.gd:DECOR_FACING_OFFSET` (line 78). After booting with archway/stairs visible, probe native GLB facing: if `archway` faces away from the room interior, add `"archway": PI` here; same for `stairs`. The `door_wood` likely needs `PI / 2.0` to align with wall-edge orient. Set the known crypt values now; mark archway/stairs as `# probe-in-game`:
```gdscript
const DECOR_FACING_OFFSET := {
    "door_wood": PI / 2.0,   # native faces along Z; orient to wall
    # "archway": 0.0,         # confirm in-game
    # "stairs":  0.0,         # confirm in-game
}
```
_Verify:_ `WYRD_SHOT=1` screenshot shows archway framing the entrance opening correctly. _Effort:_ S.

---

### Phase 2 — Per-scope decor routing (briar_maze + hollow procedural palettes)

**Task 8** — `wyrd/scripts/dungeon_gen.gd` (after `COMBAT_THEMES`, line 103). Add `BIOME_THEMES` and `BIOME_COMBAT_THEMES` dicts mapping scope → theme lists, and update `_assign_rooms` to use them:
```gdscript
const BIOME_THEMES := {
    "crypt":      ["tomb_hall", "ossuary", "archive", "shrine", "vault", "antechamber", "hearthroom", "entry_arch", "descent_hall"],
    "hollow":     ["root_hollow", "earth_den", "antechamber", "hearthroom", "vault"],
    "briar_maze": ["thorn_passage", "briar_shrine", "antechamber", "hearthroom", "vault"],
    "snug":       ["antechamber", "hearthroom"],
}
const BIOME_COMBAT_THEMES := {
    "crypt":      ["tomb_hall", "ossuary", "archive"],
    "hollow":     ["root_hollow", "earth_den"],
    "briar_maze": ["thorn_passage", "briar_shrine"],
    "snug":       ["antechamber"],
}
```
Add `scope: String` param to `_assign_rooms`; use `BIOME_COMBAT_THEMES.get(scope, BIOME_COMBAT_THEMES["crypt"])` as the pool for unroled combat rooms (replacing the hardcoded `COMBAT_THEMES` reference at line 751).
_Verify:_ `test_wyrd_dungeon_scene.gd` green (hollow scope, checks produce no crash). _Effort:_ M.

**Task 9** — `wyrd/scripts/dungeon_gen.gd:ROOM_THEMES` (line 49). Add hollow and briar themes (procedural — no new GLBs yet; reuse crypt props with different emphasis):
```gdscript
"root_hollow": {
    "focal":      {"kind": "bones",    "pattern": "center",  "count": [1, 2]},
    "satellites": [{"kind": "rug",     "pattern": "scatter", "count": [2, 4]},
                   {"kind": "pottery", "pattern": "scatter", "count": [1, 3]}],
},
"earth_den": {
    "focal":      {"kind": "pottery",  "pattern": "center",  "count": [1, 1]},
    "satellites": [{"kind": "bones",   "pattern": "scatter", "count": [2, 4]}],
},
"thorn_passage": {
    "focal":      {"kind": "column",   "pattern": "corners", "count": [2, 4]},
    "satellites": [{"kind": "bones",   "pattern": "walls",   "count": [2, 4]},
                   {"kind": "pottery", "pattern": "scatter", "count": [1, 2]}],
},
"briar_shrine": {
    "focal":      {"kind": "altar",    "pattern": "center",  "count": [1, 1]},
    "satellites": [{"kind": "brazier", "pattern": "corners", "count": [2, 4]}],
},
```
_Verify:_ `test_wyrd_dungeon_scene.gd` green (themes are referenced but no crash without new GLBs). _Effort:_ S.

**Task 10** — `wyrd/scripts/dungeon_gen.gd:_generate_one` (line 165) and `_dress_rooms` (line 757). Thread `scope` from `cfg` into `_assign_rooms` and `_dress_rooms`:
```gdscript
var scope: String = String(cfg.get("scope", "crypt"))
_assign_rooms(rooms, rng, boss_idx, adj, scope)  # new param
var decor: Array = _dress_rooms(rooms, grid, entry, exit, rng, scope)  # new param
```
`_dress_rooms` uses `scope` only to select the `entry_arch` theme override (entrance always gets an archway) and to skip `descent_hall` on non-crypt scopes if desired. All other logic unchanged.
_Verify:_ `test_wyrd_dungeon_scene.gd` (scope=hollow) green; no crypt sarcophagi reported in its decor list. _Effort:_ M.

**Task 11** — `wyrd/scripts/layout_loader.gd:_ready` (line 179). Add `_scope` instance var and a `_build_materials(scope: String)` helper that branches `_floor_mat` / `_wall_mat` by scope. Read scope from `layout` after `_get_layout()`:
```gdscript
var _scope: String = "crypt"

func _build_materials(scope: String) -> void:
    match scope:
        "hollow", "tier_1":
            _floor_mat.albedo_texture = preload("res://textures/crypt/dungeon-crypt-floor-mossy-v1.png")
            _floor_mat.albedo_color = Color(0.68, 0.72, 0.58)   # earthy green-tan
            _wall_mat.albedo_color = Color(0.28, 0.32, 0.24)    # dark earth
        "briar_maze":
            _floor_mat.albedo_texture = preload("res://textures/crypt/dungeon-crypt-floor-mossy-v1.png")
            _floor_mat.albedo_color = Color(0.22, 0.30, 0.20)   # green-black leaf litter
            _wall_mat.albedo_color = Color(0.18, 0.22, 0.16)    # deep briar green
        "snug":
            _floor_mat.albedo_texture = preload("res://textures/crypt/dungeon-crypt-floor-cracked-v1.png")
            _floor_mat.albedo_color = Color(0.78, 0.70, 0.58)   # cellar sandstone
            _wall_mat.albedo_color = Color(0.44, 0.38, 0.30)    # rough clay
        _:  # "crypt" + summit fallback — unchanged
            _floor_mat.albedo_texture = preload("res://textures/crypt/dungeon-crypt-floor-brick-v1.png")
            _floor_mat.albedo_color = Color(0.84, 0.77, 0.66)
            _wall_mat.albedo_color = Color(0.34, 0.31, 0.28)
```
Call `_build_materials(String(layout.get("scope", "crypt")))` in `_ready` after `_floor_mat`/`_wall_mat` are created (after line 225) but before `_build_grid`. Use only already-preloaded textures (no `load()` in `_ready`'s material-fill path is fine since these are top-level preloads). Note: the existing preload of `dungeon-crypt-floor-brick-v1.png` at line 201 is inside `_ready`, not a `const` — this is safe (not `_draw()`), but for consistency move the `preload` calls to a `const` or inline them inside `_build_materials` using `preload` (compile-time, not runtime).
_Verify:_ `WYRD_NO_SAVE=1 WYRD_DEV_CHART=briar_maze WYRD_SHOT=1 godot --path wyrd` screenshot shows green-black walls; `WYRD_DEV_CHART=hollow` shows earthy tan. `test_wyrd_dungeon_scene.gd` green. _Effort:_ M.

**Task 12** — `wyrd/scripts/layout_loader.gd:_build_decor` (line 521). Add a `_models_for_scope(scope: String) -> Dictionary` helper that returns `DECOR_MODEL` as-is for `crypt`/`summit` and returns a filtered/remapped dict for hollow/briar that excludes `sarcophagus` and `bookshelf` (not thematically appropriate until new GLBs ship):
```gdscript
func _models_for_scope(scope: String) -> Dictionary:
    match scope:
        "hollow", "tier_1":
            var m := DECOR_MODEL.duplicate()
            m.erase("sarcophagus")
            return m
        "briar_maze":
            var m := DECOR_MODEL.duplicate()
            m.erase("sarcophagus")
            m.erase("bookshelf")
            return m
        _:
            return DECOR_MODEL
```
In `_build_decor`, replace the `if not DECOR_MODEL.has(kind):` check (line 543) with a scope-filtered dict: `var models := _models_for_scope(String(layout.get("scope","crypt")))` and use `models.has(kind)` / `load(models[kind])`.
_Verify:_ `WYRD_DEV_CHART=briar_maze` run produces no sarcophagus instances. `test_wyrd_dungeon_scene.gd` (scope=hollow) green. _Effort:_ M.

---

### Phase 3 — Decor density affix + new decor test suite

**Task 13** — `wyrd/scripts/layout_loader.gd:_read_chart_modifiers` (line 276). Add `_decor_density_mult` var alongside `_density_mult`:
```gdscript
var _decor_density_mult := 1.0

# in _read_chart_modifiers():
if game.affix_good("festival_pace"):
    _decor_density_mult = 1.5
if game.affix_bad("festival_pace"):
    _decor_density_mult = 0.75
```
_Verify:_ Compile-only check; no headless suite yet. _Effort:_ S.

**Task 14** — `wyrd/scripts/dungeon_gen.gd:_dress_rooms` (line 757). Add `density_mult: float = 1.0` parameter. In `_apply_rule`, scale the `n` count: `var n: int = rng.randi_range(...) scaled by density_mult`, clamped to a minimum of 1 for focal items (never drop the focal):
```gdscript
static func _dress_rooms(rooms: Array, grid: Array, entry: Dictionary,
        exit: Dictionary, rng: RandomNumberGenerator,
        scope: String = "crypt", density_mult: float = 1.0) -> Array:
```
Pass `density_mult` into each `_apply_rule` call. In `_apply_rule`, for `count[0] > 0` (satellite): `n = max(int(rule.count[0]), roundi(n * density_mult))`. For focal (`count == [1,1]`): `n = 1` always (focal never dropped).
Thread `_decor_density_mult` from `layout_loader._ready` into `DungeonGenScript.generate(seed, cfg)` by adding `"decor_density": _decor_density_mult` to the cfg dict before calling generate, OR apply the scale inside `_dress_rooms` by reading it from `cfg` passed via `_generate_one`:
```gdscript
# in _generate_one, cfg.get("decor_density", 1.0)
var decor: Array = _dress_rooms(rooms, grid, entry, exit, rng, scope,
    float(cfg.get("decor_density", 1.0)))
```
Also pass `"decor_density": _decor_density_mult` in `layout_loader._get_layout` when calling `DungeonGenScript.generate`.
_Verify:_ New `test_wyrd_decor.gd` (Task 15). _Effort:_ M.

**Task 15** — `wyrd/test_wyrd_decor.gd` (new file). Headless logic test: generate 10 layouts with `festival_pace` good affix, 10 without; assert average decor count in the good set is ≥1.35× the baseline average. Also assert that a `briar_maze` scope layout contains zero `sarcophagus` entries in its decor array:
```gdscript
extends SceneTree
const DungeonGenScript = preload("res://scripts/dungeon_gen.gd")

func _initialize() -> void:
    var baseline := 0.0; var dense := 0.0
    for i in 10:
        var l := DungeonGenScript.generate(i, {"scope": "crypt"})
        baseline += (l.decor as Array).size()
    for i in 10:
        var l := DungeonGenScript.generate(i, {"scope": "crypt",
            "affixes": [{"id":"festival_pace","good":true}], "decor_density": 1.5})
        dense += (l.decor as Array).size()
    var ratio := dense / maxf(baseline, 1.0)
    _check("festival_pace decor density ≥ 1.35×", ratio >= 1.35,
        "got %.2f" % ratio)
    # briar scope: no sarcophagi
    var bm := DungeonGenScript.generate(42, {"scope": "briar_maze"})
    var has_sarc := false
    for d in bm.decor:
        if String(d.get("kind","")) == "sarcophagus": has_sarc = true
    _check("briar_maze: no sarcophagus in decor", not has_sarc)
    quit(0 if _fail == 0 else 1)
```
_Verify:_ `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_decor.gd` exits 0. _Effort:_ M.

---

### Phase 4 — Summit antechamber set-piece (crypt scope)

**Task 16** — `wyrd/scripts/dungeon_gen.gd:ROOM_THEMES` (line 49). Add `"throne_antechamber"` theme for the Summit boss approach room:
```gdscript
"throne_antechamber": {
    "focal":      {"kind": "archway",  "pattern": "center",  "count": [1, 1]},
    "satellites": [{"kind": "column",  "pattern": "corners", "count": [4, 4]},
                   {"kind": "torch_wall", "pattern": "walls", "count": [3, 4]}],
},
```
In `_assign_rooms`, when `scope == "crypt"` and a room exists adjacent to the boss room (not the rest/entrance), assign it `"throne_antechamber"` theme instead of a random combat theme.
_Verify:_ `WYRD_NO_SAVE=1 WYRD_DEV_CHART=summit WYRD_SHOT=1 godot --path wyrd` screenshot shows archway + column framing before boss room. `test_wyrd_dungeon_scene.gd` green. _Effort:_ S.

## First commit (smallest shippable slice)

**Tasks 1–7 together** (Phase 1). The three unused GLBs appear in crypt runs, bones and bookshelves shatter on hit, and `DECOR_FACING_OFFSET` has a `door_wood` entry. This is a pure addition — no existing behavior changes, no new scopes. Acceptance: `test_wyrd_dungeon_scene.gd` green; `WYRD_SHOT=1` screenshot shows at least one archway; arrow to bones produces a particle burst.

## Test & verification plan

| Suite | When | Command |
|---|---|---|
| `test_wyrd_dungeon_scene.gd` | After every task | `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_dungeon_scene.gd` |
| `test_wyrd_decor.gd` (new) | After Task 15 | `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_decor.gd` |
| Crypt screenshot | After Task 4 | `WYRD_NO_SAVE=1 WYRD_SHOT=1 godot --path wyrd` → `/tmp/wyrd_town.png`; inspect archway at entrance |
| Briar screenshot | After Task 11 | `WYRD_NO_SAVE=1 WYRD_DEV_CHART=briar_maze WYRD_SHOT=1 godot --path wyrd` |
| Hollow screenshot | After Task 11 | `WYRD_NO_SAVE=1 WYRD_DEV_CHART=tier_1 WYRD_SHOT=1 godot --path wyrd` |
| Summit screenshot | After Task 16 | `WYRD_NO_SAVE=1 WYRD_DEV_CHART=summit WYRD_SHOT=1 godot --path wyrd` |
| Breakable playtest | After Task 6 | Live session: fire arrow at bones/bookshelf → confirm shatter burst |

The full four-suite headless battery (`test_wyrd_loop`, `test_wyrd_dungeon_scene`, `test_wyrd_transitions`, `test_skills`) must stay green after Tasks 4 and 10 (the two structural changes to `dungeon_gen.gd`).

## Risks & open questions

1. **`_assign_rooms` signature change (Task 8/10):** Adding `scope: String` param is a GDScript static method — callers in `_generate_one` are in the same file, so no external breakage. Still, verify `dungeon_gen.gd` has no other callers (it doesn't — confirmed it's only called from `_generate_one`).

2. **`preload` inside `_ready` for biome textures (Task 11):** GDScript `preload` is compile-time, not runtime — calling it inside a function body is legal and correct. The `load()` prohibition in CLAUDE.md is specifically about `_draw()`. However, to keep the spirit consistent, consider moving biome texture preloads to `const`s at the top of the file (one `const` per texture path). This avoids any future confusion.

3. **`bones` and `bookshelf` breakable HP (Task 6):** Both set to HP 1 (one-shot). If `bookshelf` should feel beefier (HP 2, requires two arrow hits), decide before shipping — the parent note leaves this open. Current plan: HP 1 for both.

4. **Briar/hollow room themes reuse crypt props (Task 9):** The parent note notes that shared assets save Meshy pipeline cost but reduce distinctiveness. Phase 2 here ships a procedural color palette swap + prop exclusion to distinguish scopes without new GLBs. New props (earthy barrel, mossy log, thorn-bush cluster) remain a Phase 2 backlog item blocked on the Meshy pipeline. Flag for the user when Phase 2 lands: "briar and hollow now read differently via palette; new GLBs will complete the distinction."

5. **`door_wood` orientation (Task 7):** Set tentatively to `PI / 2.0` — must be confirmed by viewing in-game. The GLB's native axis is unknown until loaded. This is a 5-minute playtest tweak.

6. **Shatter shader (Phase 3 of parent note):** Deferred per the parent note to [[system-combat-juice-vfx]]. Not included here. The current GPUParticles3D burst in `breakable.gd:_burst()` (lines 49–82) is the shipped visual.

7. **`door_wood` as obstacle vs static decor:** The parent note asks whether it should become a breakable obstacle. For this plan it is static decor only (`DECOR_BREAKABLE` does not include it). Adding it requires a design decision; note it as an open question for the user.
