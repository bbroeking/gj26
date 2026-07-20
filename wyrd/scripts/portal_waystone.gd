class_name PortalWaystone
extends Interactable

# Wyrd — the town Waystone. E opens the chart-socket panel; choosing a
# chart crosses into its dungeon. The cairn GLB + a cool standing glow.

const CAIRN_GLB := preload("res://models/waypoint_cairn_v2.glb")
const WaystonePanelScript = preload("res://scripts/ui/waystone_panel.gd")

func get_prompt_text() -> String:
	return "[E] Socket a chart"

func get_prompt_color() -> Color:
	return Color(0.7, 0.85, 1.0)

func get_collision_radius() -> float:
	return 1.8

func get_prompt_position() -> Vector3:
	return Vector3(0.0, 2.6, 0.0)

func _ready_interactable() -> void:
	add_to_group("tutorial_waystone")
	var cairn := CAIRN_GLB.instantiate()
	add_child(cairn)
	GlbFit.normalize_height(cairn, 2.4)
	GlbFit.add_ink_outline(cairn)
	var glow := OmniLight3D.new()
	glow.position = Vector3(0.0, 1.8, 0.0)
	glow.light_color = Color(0.55, 0.75, 1.0)
	glow.light_energy = 2.0
	glow.omni_range = 7.0
	add_child(glow)

func interact(player: Node) -> void:
	var panel := WaystonePanelScript.new()
	panel.player = player
	get_tree().current_scene.add_child(panel)
