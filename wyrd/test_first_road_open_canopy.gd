extends SceneTree

# Spec 70 — the First Road keeps both forest-depth tiers, but their visual
# envelope must frame the FATE-camera stage rather than becoming another wall.

const FirstRoadData = preload("res://data/first_road.gd")

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
	print("--- First Road open canopy ---")
	var game := root.get_node("Game")
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.active_chart = FirstRoadData.make_chart("bold")
	game.in_dungeon = true
	game.tutorial_step = 5
	change_scene_to_file("res://scenes/World.tscn")
	for _frame in 12:
		await process_frame

	var walls := get_nodes_in_group("wall")
	var complete := 0
	var compact := 0
	var attached := 0
	var presentation_only := 0
	for wall_v in walls:
		var wall := wall_v as Node
		var visual := wall.get_node_or_null("WallMesh") as Node3D
		if visual == null:
			continue
		var near := visual.get_node_or_null("RearFoliage0") as MeshInstance3D
		var far := visual.get_node_or_null("RearFoliage1") as MeshInstance3D
		if near == null or far == null:
			continue
		complete += 1
		attached += 1 if near.get_parent() == visual and far.get_parent() == visual else 0
		presentation_only += 1 if bool(near.get_meta("presentation_only", false)) \
			and bool(far.get_meta("presentation_only", false)) else 0
		var near_mesh := near.mesh as SphereMesh
		var far_mesh := far.mesh as SphereMesh
		if near_mesh != null and far_mesh != null \
				and near_mesh.radius <= 0.451 and near_mesh.height <= 1.181 \
				and far_mesh.radius <= 0.581 and far_mesh.height <= 1.551 \
				and near.scale.x <= 1.101 and near.scale.z <= 1.101 \
				and far.scale.x <= 1.101 and far.scale.z <= 1.101:
			compact += 1

	check("every living wall retains two forest tiers",
		complete == walls.size() and not walls.is_empty(),
		{"tiers": complete, "walls": walls.size()})
	check("both tiers remain under cutaway-owned WallMesh",
		attached == walls.size(), {"attached": attached, "walls": walls.size()})
	check("both tiers remain explicitly presentation-only",
		presentation_only == walls.size(),
		{"presentation": presentation_only, "walls": walls.size()})
	check("forest shoulder respects the compact visual envelope",
		compact == walls.size(), {"compact": compact, "walls": walls.size()})
	var camera_source := FileAccess.get_file_as_string("res://scripts/camera_rig.gd")
	check("continuous camera protects the wider opaque combat stage",
		camera_source.contains("CUTAWAY_RADIUS_PX := Vector2(255.0, 170.0)")
			and camera_source.contains("CUTAWAY_WALL_SCALE_Y := 0.14")
			and camera_source.contains("CUTAWAY_WALL_OFFSET_Y := -1.55"))

	print("--- First Road open canopy: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)
