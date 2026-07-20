extends SceneTree

# Spec 65 — deterministic authored clearing grammar for the procedural First
# Road.  This test stays generator-only; production wall/camera behavior lives
# in test_hollow_readability.gd.

const DungeonGenScript = preload("res://scripts/dungeon_gen.gd")
const ChartsData = preload("res://data/charts.gd")

var passed := 0
var failed := 0


func check(label: String, ok: bool, detail = "") -> void:
	if ok:
		passed += 1
		print("  ✓ %s" % label)
	else:
		failed += 1
		print("  ✗ %s %s" % [label, str(detail)])


func _initialize() -> void:
	print("--- First Hollow room grammar ---")
	var first := _layout(26072026)
	var replay := _layout(26072026)
	check("same seed reproduces room archetypes and footprints",
		_room_signature(first.rooms) == _room_signature(replay.rooms))
	check("same seed reproduces the playable boundary",
		first.boundary_cells == replay.boundary_cells)

	var archetypes := {}
	var variants := {}
	for seed in [26072026, 26072027, 26072028, 26072029, 26072030]:
		var layout := _layout(seed)
		for room_v in layout.rooms:
			var room: Dictionary = room_v
			archetypes[String(room.get("archetype", ""))] = true
			variants["%s:%d" % [String(room.get("archetype", "")),
				int(room.get("footprint_variant", -1))]] = true
	check("fixed seed sample realizes at least three clearing archetypes",
		archetypes.size() >= 3, archetypes.keys())
	check("seeded footprint variants change without changing the graph system",
		variants.size() >= 5, variants.keys())

	var boundary_valid := true
	for cell_v in first.boundary_cells:
		var cell: Dictionary = cell_v
		if not _touches_floor(first.grid, int(cell.x), int(cell.y)):
			boundary_valid = false
			break
	check("every authored wall cell touches reachable floor", boundary_valid,
		first.boundary_cells.size())
	check("boundary is substantially smaller than the unused wall field",
		first.boundary_cells.size() * 2 < _wall_cell_count(first.grid),
		{"boundary": first.boundary_cells.size(), "all_walls": _wall_cell_count(first.grid)})

	var clear := true
	var blocked = null
	for decor_v in first.decor:
		var decor: Dictionary = decor_v
		for room_v in first.rooms:
			var room: Dictionary = room_v
			if String(room.get("role", "")) != "combat":
				continue
			if _inside_aperture(room, int(decor.x), int(decor.y)):
				clear = false
				blocked = {"room": room.get("id", -1), "decor": decor}
				break
		if not clear:
			break
	check("combat apertures contain no generated dressing", clear, blocked)
	check("First Road remains fully connected",
		float(first.score.connectivity) >= 0.999, first.score.connectivity)

	print("--- First Hollow room grammar: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _layout(seed: int) -> Dictionary:
	var cfg: Dictionary = (ChartsData.TEMPLATES.first_road.gen as Dictionary).duplicate(true)
	cfg.merge({"scope": "snug", "template_id": "first_road", "tier": 1,
		"affixes": [
			{"id": "tyrannical", "good": true, "resolvedId": "tyrannical"},
			{"id": "elite_signs", "good": true, "resolvedId": "elite_signs"},
			{"id": "gilded", "good": true, "resolvedId": "gilded"},
		]}, true)
	return DungeonGenScript.generate(seed, cfg)


func _room_signature(rooms: Array) -> String:
	var signature: Array = []
	for room_v in rooms:
		var room: Dictionary = room_v
		signature.append({"id": room.id, "role": room.role,
			"archetype": room.get("archetype", ""),
			"variant": room.get("footprint_variant", -1),
			"footprint": room.get("footprint_cells", [])})
	return JSON.stringify(signature)


func _touches_floor(grid: Array, x: int, y: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx := x + dx
			var ny := y + dy
			if ny >= 0 and ny < grid.size() and nx >= 0 and nx < grid[ny].size() \
					and String(grid[ny][nx]) == "floor":
				return true
	return false


func _wall_cell_count(grid: Array) -> int:
	var count := 0
	for row_v in grid:
		for cell_v in row_v:
			if String(cell_v) == "wall":
				count += 1
	return count


func _inside_aperture(room: Dictionary, x: int, y: int) -> bool:
	var aperture: Dictionary = room.get("protected_aperture", {})
	if aperture.is_empty():
		return false
	var nx := (float(x) + 0.5 - float(aperture.cx)) / float(aperture.rx)
	var ny := (float(y) + 0.5 - float(aperture.cy)) / float(aperture.ry)
	return nx * nx + ny * ny <= 1.0
