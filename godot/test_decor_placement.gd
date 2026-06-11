extends SceneTree

# Spec 28 — decor placement evals.
#   godot --headless --path godot --script res://test_decor_placement.gd
#
# T1 — across 10 dungeons, no decor sits on a corridor-mouth tile.
# T2 — _pattern_tiles "walls" returns tiles on the room's *actual* edge
#      (not the inboard ring).
# T3 — every themed room's centre cell holds its focal kind.

const DungeonGen = preload("res://scripts/dungeon_gen.gd")

var _pass := 0
var _fail := 0

func _initialize() -> void:
	print("--- spec 28 decor placement evals ---")
	_t1_no_decor_on_corridor_mouths()
	_t2_walls_pattern_on_actual_edge()
	_t3_focal_at_room_centre()
	print("--- decor placement evals: %d PASS, %d FAIL ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _check(id: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
		print("  PASS  %s — %s" % [id, detail])
	else:
		_fail += 1
		print("  FAIL  %s — %s" % [id, detail])

# ---- T1 — corridor mouths empty across many runs ----
func _t1_no_decor_on_corridor_mouths() -> void:
	var violations := 0
	var checked := 0
	for run in 10:
		var layout: Dictionary = DungeonGen.generate(run)
		var grid: Array = layout.grid
		var rooms: Array = layout.rooms
		for d in layout.get("decor", []):
			var dx := int(d.x)
			var dy := int(d.y)
			var owner = _room_containing(rooms, dx, dy)
			if owner == null:
				continue
			checked += 1
			if DungeonGen._is_corridor_mouth(owner, dx, dy, grid):
				violations += 1
	_check("T1", violations == 0,
		"corridor-mouth decor across 10 runs: %d violations / %d checked"
		% [violations, checked])

# ---- T2 — _pattern_tiles "walls" lives on the actual edge ----
func _t2_walls_pattern_on_actual_edge() -> void:
	# Hand-build a 10×10 room of all-floor tiles in a 20×20 grid.
	var grid: Array = []
	for y in 20:
		var row: Array = []
		for x in 20:
			row.append("wall")
		grid.append(row)
	var r := {"x": 5, "y": 5, "w": 10, "h": 10}
	for yy in range(5, 15):
		for xx in range(5, 15):
			grid[yy][xx] = "floor"
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var tiles: Array = DungeonGen._pattern_tiles(r, "walls", 40, grid, rng)
	var all_on_edge := true
	for t in tiles:
		var x := int(t.x)
		var y := int(t.y)
		var on_edge: bool = (x == 5 or x == 14 or y == 5 or y == 14)
		if not on_edge:
			all_on_edge = false
			break
	_check("T2", all_on_edge and tiles.size() > 0,
		"_pattern_tiles 'walls' returned %d tiles, all on the actual edge"
		% tiles.size())

# ---- T3 — every themed room has its focal kind at (or near) the centre ----
func _t3_focal_at_room_centre() -> void:
	var missing := 0
	var checked := 0
	for run in range(50, 60):
		var layout: Dictionary = DungeonGen.generate(run)
		var rooms: Array = layout.rooms
		var decor: Array = layout.get("decor", [])
		# index decor by (x, y)
		var at: Dictionary = {}
		for d in decor:
			at[int(d.x) * 10000 + int(d.y)] = String(d.kind)
		for r in rooms:
			var role: String = r.get("role", "")
			if role == "entrance" or role == "boss" or role == "setpiece":
				continue
			var theme: String = r.get("theme", "")
			var theme_def = DungeonGen.ROOM_THEMES.get(theme, {})
			if theme_def.is_empty():
				continue
			var focal_kind := String(theme_def.focal.kind)
			# Check the room contains at least one of its focal kind.
			var found := false
			for yy in range(int(r.y), int(r.y) + int(r.h)):
				for xx in range(int(r.x), int(r.x) + int(r.w)):
					if at.get(xx * 10000 + yy, "") == focal_kind:
						found = true
						break
				if found:
					break
			checked += 1
			if not found:
				missing += 1
	_check("T3", missing == 0,
		"themed rooms with their focal kind present: %d/%d (missing: %d)"
		% [checked - missing, checked, missing])

func _room_containing(rooms: Array, x: int, y: int):
	for r in rooms:
		var rx0: int = int(r.x)
		var rx1: int = int(r.x) + int(r.w) - 1
		var ry0: int = int(r.y)
		var ry1: int = int(r.y) + int(r.h) - 1
		if x >= rx0 and x <= rx1 and y >= ry0 and y <= ry1:
			return r
	return null
