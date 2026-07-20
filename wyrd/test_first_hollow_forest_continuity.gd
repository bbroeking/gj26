extends SceneTree

# Spec 68 — First Road forest depth must remain visual-only and inherit the
# accepted wall cutaway rather than becoming a second boundary system.

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
	print("--- First Hollow forest continuity ---")
	root.size = Vector2i(1280, 720)
	var game := root.get_node("Game")
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.active_chart = FirstRoadData.make_chart("bold")
	game.in_dungeon = true
	game.tutorial_step = 5
	var layout: Dictionary = DungeonGenScript.generate(
		int(game.active_chart.seed), game.run_cfg())
	change_scene_to_file("res://scenes/World.tscn")
	for _frame in 12:
		await process_frame
	var world := current_scene
	var underlay := world.get_node_or_null("FirstHollowForestUnderlay") as MeshInstance3D
	check("production First Road builds one forest underlay", underlay != null)
	var plane := underlay.mesh as PlaneMesh if underlay != null else null
	var grid_width := float((layout.grid[0] as Array).size())
	var grid_depth := float(layout.grid.size())
	check("forest underlay extends well beyond the generated grid",
		plane != null and plane.size.x >= grid_width + 20.0
			and plane.size.y >= grid_depth + 20.0,
		plane.size if plane != null else Vector2.ZERO)
	check("forest underlay stays below the playable floor and casts no shadow",
		underlay != null and underlay.position.y < -0.1
			and underlay.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	check("forest underlay owns no collision or navigation authority",
		underlay != null and bool(underlay.get_meta("presentation_only", false))
			and _descendant_count(underlay, CollisionShape3D) == 0
			and _descendant_count(underlay, NavigationRegion3D) == 0)

	var walls := get_nodes_in_group("wall")
	var two_tiers := 0
	var far_enough := 0
	var attached := 0
	var presentation_only := 0
	for wall_v in walls:
		var wall := wall_v as Node
		var visual := wall.get_node_or_null("WallMesh") as Node3D
		if visual == null:
			continue
		var near := visual.get_node_or_null("RearFoliage0") as MeshInstance3D
		var far := visual.get_node_or_null("RearFoliage1") as MeshInstance3D
		if near != null and far != null:
			two_tiers += 1
			attached += 1 if near.get_parent() == visual and far.get_parent() == visual else 0
			far_enough += 1 if Vector2(far.position.x, far.position.z).length() >= 1.35 else 0
			presentation_only += 1 if bool(near.get_meta("presentation_only", false)) \
				and bool(far.get_meta("presentation_only", false)) else 0
	check("every living wall owns two forest-depth tiers",
		two_tiers == walls.size() and not walls.is_empty(),
		{"tiers": two_tiers, "walls": walls.size()})
	check("far canopy tier extends at least 1.35 m beyond every wall",
		far_enough == walls.size(), {"far": far_enough, "walls": walls.size()})
	check("both depth tiers remain attached to the cutaway-owned WallMesh",
		attached == walls.size(), {"attached": attached, "walls": walls.size()})
	check("exterior canopy is explicitly presentation-only",
		presentation_only == walls.size(),
		{"presentation": presentation_only, "walls": walls.size()})

	print("--- First Hollow forest continuity: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _descendant_count(root_node: Node, type) -> int:
	var count := 0
	for child in root_node.get_children():
		if is_instance_of(child, type):
			count += 1
		count += _descendant_count(child, type)
	return count
