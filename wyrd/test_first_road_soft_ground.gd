extends SceneTree

# Spec 69 — the production First Road keeps one authoritative visual floor but
# morphs its existing shader away from stone. A direct material probe also
# proves the shared wood-grove default does not inherit the snug-only override.

const LoaderScript = preload("res://scripts/layout_loader.gd")
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
	print("--- First Road soft ground ---")
	root.size = Vector2i(1280, 720)
	var game := root.get_node("Game")
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.active_chart = FirstRoadData.make_chart("bold")
	game.in_dungeon = true
	game.tutorial_step = 5
	change_scene_to_file("res://scenes/World.tscn")
	for _frame in 12:
		await process_frame
	var world := current_scene

	var floors := _named_descendants(world, "FloorMerged")
	check("production First Road owns one merged visual floor", floors.size() == 1,
		floors.size())
	var floor := floors[0] as MeshInstance3D if floors.size() == 1 else null
	check("merged floor remains one draw surface",
		floor != null and floor.mesh != null and floor.mesh.get_surface_count() == 1)
	var material := floor.material_override as ShaderMaterial if floor != null else null
	check("First Road ground uses broad low-grout clumps",
		material != null
		and float(material.get_shader_parameter("cell_scale")) >= 1.2
		and float(material.get_shader_parameter("cell_strength")) <= 0.14
		and float(material.get_shader_parameter("bevel")) <= 0.12)
	var dirt := material.get_shader_parameter("base_col") as Color if material != null else Color.BLACK
	var moss := material.get_shader_parameter("accent_col") as Color if material != null else Color.BLACK
	check("First Road palette separates warm dirt from green moss",
		dirt.r > dirt.g and dirt.g > dirt.b and moss.g > moss.r and moss.g > moss.b,
		{"dirt": dirt, "moss": moss})

	var probe := LoaderScript.new()
	probe.set("_scope", "briar_maze")
	var shared := probe.call("_make_floor_material", "wood_grove") as ShaderMaterial
	check("later wood-grove scopes retain the shared material",
		is_equal_approx(float(shared.get_shader_parameter("cell_strength")), 0.25)
		and is_equal_approx(float(shared.get_shader_parameter("cell_scale")), 0.95))
	probe.free()
	print("--- First Road soft ground: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _named_descendants(node: Node, wanted: String) -> Array:
	var found: Array = []
	for child in node.get_children():
		if child.name == wanted:
			found.append(child)
		found.append_array(_named_descendants(child, wanted))
	return found
