extends SceneTree

# Spec 66 — deterministic archetype-owned perimeter composition for the First
# Road. Production realization and cutaway behavior remain in
# test_hollow_readability.gd.

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
	print("--- First Hollow living edge ---")
	var first := _layout(26072026)
	var replay := _layout(26072026)
	check("same seed reproduces the full perimeter manifest",
		JSON.stringify(first.perimeter_dressing) \
			== JSON.stringify(replay.perimeter_dressing))
	check("every boundary cell owns exactly one visual profile",
		first.perimeter_dressing.size() == first.boundary_cells.size(),
		{"profiles": first.perimeter_dressing.size(),
			"boundary": first.boundary_cells.size()})

	var boundary_keys := {}
	for cell_v in first.boundary_cells:
		var cell: Dictionary = cell_v
		boundary_keys["%d:%d" % [int(cell.x), int(cell.y)]] = true
	var all_real := true
	var ownership_valid := true
	var inward_valid := true
	var landmarks_by_room := {}
	var profile_ids := {}
	for row_v in first.perimeter_dressing:
		var row: Dictionary = row_v
		var key := "%d:%d" % [int(row.x), int(row.y)]
		all_real = all_real and boundary_keys.has(key)
		inward_valid = inward_valid and (int(row.get("inward_x", 0)) != 0 \
			or int(row.get("inward_y", 0)) != 0)
		profile_ids[String(row.profile)] = true
		var room_id := int(row.room_id)
		if room_id >= 0:
			ownership_valid = ownership_valid and _touches_room_footprint(
				int(row.x), int(row.y), first.rooms[room_id])
			if bool(row.landmark):
				landmarks_by_room[room_id] = int(landmarks_by_room.get(room_id, 0)) + 1
	check("every perimeter profile names a real wall boundary", all_real)
	check("owned profiles touch their named room footprint", ownership_valid)
	check("every profile points from the wall toward real floor", inward_valid)
	var one_each: bool = landmarks_by_room.size() == first.rooms.size()
	for room_id in first.rooms.size():
		one_each = one_each and int(landmarks_by_room.get(room_id, 0)) == 1
	check("every generated room owns exactly one edge landmark", one_each,
		landmarks_by_room)
	check("the shipped Bold seed carries at least five edge silhouettes",
		profile_ids.size() >= 5, profile_ids.keys())

	var landmark_signatures := {}
	for seed in [26072026, 26072027, 26072028, 26072029]:
		var layout := _layout(seed)
		landmark_signatures[_landmark_signature(layout.perimeter_dressing)] = true
	check("different seeds remix landmark placement", landmark_signatures.size() >= 3,
		landmark_signatures.keys())

	var other_cfg: Dictionary = (ChartsData.TEMPLATES.first_road.gen as Dictionary).duplicate(true)
	other_cfg.merge({"scope": "hollow", "template_id": "tier_1", "tier": 1}, true)
	var other := DungeonGenScript.generate(26072026, other_cfg)
	check("later biomes do not inherit the unproven First Road kit",
		(other.get("perimeter_dressing", []) as Array).is_empty())

	print("--- First Hollow living edge: %d PASS, %d FAIL ---" % [passed, failed])
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


func _touches_room_footprint(x: int, y: int, room: Dictionary) -> bool:
	var footprint := {}
	for cell_v in room.get("footprint_cells", []):
		var cell: Dictionary = cell_v
		footprint["%d:%d" % [int(cell.x), int(cell.y)]] = true
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx != 0 or dy != 0:
				if footprint.has("%d:%d" % [x + dx, y + dy]):
					return true
	return false


func _landmark_signature(manifest: Array) -> String:
	var out := []
	for row_v in manifest:
		var row: Dictionary = row_v
		if bool(row.get("landmark", false)):
			out.append({"room_id": row.room_id, "x": row.x, "y": row.y,
				"profile": row.profile})
	return JSON.stringify(out)
