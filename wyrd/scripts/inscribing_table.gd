class_name InscribingTable
extends Interactable

# Wyrd — the Inscribing Table in the Chartmaker's Yard. E opens the
# mix-ink / inscribe-chart panel. The chartmaker stone GLB is the body;
# the compass sits on top as the work-in-progress dressing.

const STONE_GLB := preload("res://models/chartmaker_stone_v2.glb")
const COMPASS_GLB := preload("res://models/cartographer_compass.glb")
const CraftingBenchScript = preload("res://scripts/ui/crafting_bench.gd")

func get_prompt_text() -> String:
	return "[E] Use the Inscribing Table"

func get_prompt_color() -> Color:
	return Color(0.9, 0.8, 1.0)          # ink violet

func get_collision_radius() -> float:
	return 1.6

func get_prompt_position() -> Vector3:
	return Vector3(0.0, 2.0, 0.0)

func _ready_interactable() -> void:
	var stone := STONE_GLB.instantiate()
	add_child(stone)
	GlbFit.normalize_height(stone, 1.1)
	GlbFit.add_ink_outline(stone)
	var compass := COMPASS_GLB.instantiate()
	add_child(compass)
	GlbFit.normalize_height(compass, 0.35)
	compass.position = Vector3(0.0, 1.12, 0.0)
	var glow := OmniLight3D.new()
	glow.position = Vector3(0.0, 1.5, 0.0)
	glow.light_color = Color(0.8, 0.65, 1.0)
	glow.light_energy = 1.4
	glow.omni_range = 4.0
	add_child(glow)

func interact(_player: Node) -> void:
	# Spec 42 — the bench replaces the menu panel. Post-tutorial visitors
	# get the one-time hint; during the tutorial Mara is the guide.
	var game := get_tree().root.get_node_or_null("Game")
	if game != null and int(game.tutorial_step) >= 7:
		game.first_time_hint("bench")
	var panel := CraftingBenchScript.new()
	get_tree().current_scene.add_child(panel)
