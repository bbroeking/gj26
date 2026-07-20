extends SceneTree

# Spec 62 — the production camera must cut a readable aperture around the
# player, not merely clear one pencil-thin ray to their center.

const FirstRoadData = preload("res://data/first_road.gd")
const DungeonGenScript = preload("res://scripts/dungeon_gen.gd")

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
	print("--- Hollow readability: 1280x720 Bold Road ---")
	root.size = Vector2i(1280, 720)
	var game := root.get_node("Game")
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.active_chart = FirstRoadData.make_chart("bold")
	game.in_dungeon = true
	game.tutorial_step = 5
	var expected_layout: Dictionary = DungeonGenScript.generate(
		int(game.active_chart.seed), game.run_cfg())
	change_scene_to_file("res://scenes/World.tscn")
	for _frame in 12:
		await process_frame
	var player := game.local_player() as CharacterBody3D
	var elite: CharacterBody3D = null
	for candidate in get_nodes_in_group("enemy"):
		if bool(candidate.get("is_elite")):
			elite = candidate as CharacterBody3D
			break
	var rig := get_first_node_in_group("camera_rig")
	var walls := get_nodes_in_group("wall")
	check("production scene builds only the authored floor boundary",
		walls.size() == expected_layout.boundary_cells.size(),
		{"rendered": walls.size(), "boundary": expected_layout.boundary_cells.size()})
	var natural_visuals := 0
	var profile_ids := {}
	var landmark_visuals := 0
	var landmark_collision_ok := true
	for wall_v in walls:
		var wall := wall_v as Node
		var visual := wall.get_node_or_null("WallMesh")
		if visual is Node3D and not visual is MeshInstance3D \
				and visual.get_node_or_null("Rootstone") is MeshInstance3D:
			natural_visuals += 1
			profile_ids[String(visual.get_meta("perimeter_profile", ""))] = true
			if bool(visual.get_meta("landmark", false)):
				landmark_visuals += 1
				var has_wall_collision := false
				for child in wall.get_children():
					if child is CollisionShape3D:
						has_wall_collision = true
						break
				landmark_collision_ok = landmark_collision_ok \
					and visual.get_node_or_null("PerimeterLandmark") is Node3D \
					and has_wall_collision
	check("First Hollow boundary uses compound natural silhouettes",
		natural_visuals == walls.size() and not walls.is_empty(),
		{"natural": natural_visuals, "walls": walls.size()})
	check("production Bold Road realizes at least five edge profiles",
		profile_ids.size() >= 5, profile_ids.keys())
	check("every generated room realizes one colliding-wall landmark root",
		landmark_visuals == expected_layout.rooms.size() and landmark_collision_ok,
		{"landmarks": landmark_visuals, "rooms": expected_layout.rooms.size(),
			"collision_ok": landmark_collision_ok})
	check("production Bold Road supplies player, elite, and camera",
		player != null and elite != null and rig != null)
	if player != null and elite != null and rig != null:
		player.global_position = elite.global_position + Vector3(0.0, 0.0, 5.5)
		for _frame in 20:
			await process_frame
		var occluding: Dictionary = rig.get("_occluding")
		var strongly_cut := 0
		for wall in occluding:
			var mesh := (wall as Node).get_node_or_null("WallMesh") as Node3D
			if mesh != null and mesh.scale.y <= 0.2 and mesh.position.y < -1.0:
				strongly_cut += 1
		check("camera protects a multi-wall aperture around the player",
			occluding.size() >= 3, occluding.size())
		check("cutaway walls lower to a readable solid boundary",
			not occluding.is_empty() and strongly_cut == occluding.size(),
			{"cut": strongly_cut, "occluding": occluding.size()})
		var former_walls := occluding.keys()
		rig.set("_yaw", float(rig.get("_yaw")) + PI)
		for _frame in 4:
			await process_frame
		var restored := 0
		for wall in former_walls:
			if not is_instance_valid(wall):
				continue
			var mesh := (wall as Node).get_node_or_null("WallMesh") as Node3D
			if mesh != null and is_equal_approx(mesh.scale.y, 1.0) \
					and is_zero_approx(mesh.position.y):
				restored += 1
		check("walls restore when they leave the protected aperture",
			restored > 0, {"restored": restored, "former": former_walls.size()})
		var started_us := Time.get_ticks_usec()
		for _sample in 120:
			rig.call("_update_wall_occlusion")
		var average_us := float(Time.get_ticks_usec() - started_us) / 120.0
		check("cutaway scan stays below a 1.5 ms CPU budget",
			average_us < 1500.0, average_us)
	print("--- Hollow readability: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)
