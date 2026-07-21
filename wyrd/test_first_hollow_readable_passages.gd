extends SceneTree

# Spec 74 — generated room connections retain their physical wall truth while
# their living-wall shoulders resolve as low, deterministic passage frames.

const DungeonGenScript = preload("res://scripts/dungeon_gen.gd")
const FirstRoadData = preload("res://data/first_road.gd")
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
	call_deferred("run")


func run() -> void:
	print("--- First Hollow readable passages ---")
	var first := _layout("snug")
	var replay := _layout("snug")
	check("same seed reproduces passage ownership",
		_passage_signature(first) == _passage_signature(replay))

	var passage_rows: Array = (first.perimeter_dressing as Array).filter(
		func(row_v) -> bool:
			return row_v is Dictionary and bool((row_v as Dictionary).get("passage", false)))
	var all_real := true
	var no_landmarks := true
	var boundary := {}
	for cell_v in first.boundary_cells:
		var cell: Dictionary = cell_v
		boundary["%d:%d" % [int(cell.x), int(cell.y)]] = true
	for row_v in passage_rows:
		var row: Dictionary = row_v
		all_real = all_real and String(row.profile) == "passage_bank" \
			and boundary.has("%d:%d" % [int(row.x), int(row.y)])
		no_landmarks = no_landmarks and not bool(row.landmark)
	var mouth_receipt := _every_mouth_framed(first, passage_rows)
	check("every generated room connection owns low passage shoulders",
		not passage_rows.is_empty() and all_real and bool(mouth_receipt.valid),
		{"passage_walls": passage_rows.size(), "mouths": mouth_receipt.mouths})
	check("passage shoulders never consume room landmarks", no_landmarks)

	var ordinary := (first.perimeter_dressing as Array).filter(
		func(row_v) -> bool:
			return row_v is Dictionary and not bool((row_v as Dictionary).get("passage", false)))
	check("ordinary perimeter keeps the living-edge grammar",
		not ordinary.is_empty() and ordinary.any(func(row_v) -> bool:
			return String((row_v as Dictionary).profile) != "passage_bank"))

	var game := root.get_node("Game")
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.active_chart = FirstRoadData.make_chart("bold")
	game.in_dungeon = true
	game.tutorial_step = 5
	change_scene_to_file("res://scenes/World.tscn")
	for _frame in 12:
		await process_frame

	var realized := 0
	var compact := 0
	var physical := 0
	for wall_v in get_nodes_in_group("wall"):
		var wall := wall_v as StaticBody3D
		if wall == null or not bool(wall.get_meta("perimeter_passage", false)):
			continue
		realized += 1
		var visual := wall.get_node_or_null("WallMesh") as Node3D
		var rootstone := visual.get_node_or_null("Rootstone") as MeshInstance3D \
			if visual != null else null
		var near := visual.get_node_or_null("RearFoliage0") as MeshInstance3D \
			if visual != null else null
		var far := visual.get_node_or_null("RearFoliage1") as MeshInstance3D \
			if visual != null else null
		if rootstone != null and near != null and far != null:
			var root_mesh := rootstone.mesh as SphereMesh
			var near_mesh := near.mesh as SphereMesh
			var far_mesh := far.mesh as SphereMesh
			if root_mesh.height <= 1.001 and near_mesh.height <= 0.761 \
					and far_mesh.height <= 0.961 and visual.get_parent() == wall:
				compact += 1
		var collider: CollisionShape3D = null
		for child in wall.get_children():
			if child is CollisionShape3D:
				collider = child as CollisionShape3D
				break
		var box := collider.shape as BoxShape3D if collider != null else null
		if box != null and box.size.is_equal_approx(Vector3(1.0, 3.6, 1.0)):
			physical += 1
	check("production realizes every passage as a compact cutaway-owned bank",
		realized > 0 and compact == realized,
		{"realized": realized, "compact": compact})
	check("passage presentation preserves full wall collision",
		physical == realized, {"physical": physical, "realized": realized})

	var other := _layout("hollow")
	check("later biomes do not inherit the First Road passage kit",
		(other.get("perimeter_dressing", []) as Array).is_empty())

	print("--- First Hollow readable passages: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _layout(scope: String) -> Dictionary:
	var cfg: Dictionary = (ChartsData.TEMPLATES.first_road.gen as Dictionary).duplicate(true)
	cfg.merge({"scope": scope,
		"template_id": "first_road" if scope == "snug" else "tier_1",
		"tier": 1, "affixes": FirstRoadData.make_chart("bold").affixes}, true)
	return DungeonGenScript.generate(26072026, cfg)


func _passage_signature(layout: Dictionary) -> String:
	var rows := []
	for row_v in layout.perimeter_dressing:
		var row: Dictionary = row_v
		if bool(row.get("passage", false)):
			rows.append({"x": row.x, "y": row.y, "room_id": row.room_id,
				"profile": row.profile})
	return JSON.stringify(rows)


func _every_mouth_framed(layout: Dictionary, passage_rows: Array) -> Dictionary:
	var mouths := 0
	var valid := true
	for room_v in layout.rooms:
		var room: Dictionary = room_v
		var rx0 := int(room.x)
		var rx1 := int(room.x) + int(room.w) - 1
		var ry0 := int(room.y)
		var ry1 := int(room.y) + int(room.h) - 1
		var edge_cells := []
		for x in range(rx0, rx1 + 1):
			edge_cells.append(Vector2i(x, ry0))
			edge_cells.append(Vector2i(x, ry1))
		for y in range(ry0 + 1, ry1):
			edge_cells.append(Vector2i(rx0, y))
			edge_cells.append(Vector2i(rx1, y))
		for cell_v in edge_cells:
			var cell: Vector2i = cell_v
			if not DungeonGenScript._is_corridor_mouth(
					room, cell.x, cell.y, layout.grid):
				continue
			mouths += 1
			var framed := passage_rows.any(func(row_v) -> bool:
				var row: Dictionary = row_v
				return maxi(absi(int(row.x) - cell.x),
					absi(int(row.y) - cell.y)) <= 2)
			valid = valid and framed
	return {"valid": valid and mouths > 0, "mouths": mouths}
