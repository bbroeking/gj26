class_name SecondHandClue
extends Interactable

# Spec 55 — two world presentations of one unexplained hooked hand. The
# generator decides where it appears; this Interactable owns only the readable
# object, the short observation, and the public Game story-state call.

const DialogPanelScript = preload("res://scripts/ui/dialog_panel.gd")

var clue_id := ""
var presentation := "etched_stone"

func setup(id: String, kind: String) -> void:
	clue_id = id
	presentation = kind

func get_prompt_text() -> String:
	return "[E] Read the mark"

func get_prompt_color() -> Color:
	return Color(0.76, 0.88, 0.94) if presentation == "etched_stone" \
		else Color(0.74, 0.36, 0.28)

func get_prompt_position() -> Vector3:
	return Vector3(0.0, 0.62, 0.0)

func get_collision_radius() -> float:
	return 0.9

func get_collision_offset() -> Vector3:
	return Vector3(0.0, 0.2, 0.0)

func get_solid_radius() -> float:
	return 0.0

func _ready_interactable() -> void:
	add_to_group("second_hand_clue")
	var base := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = Vector3(0.92, 0.06, 0.68)
	base.mesh = slab
	base.position.y = 0.04
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.48, 0.52, 0.50) if presentation == "etched_stone" \
		else Color(0.82, 0.70, 0.51)
	mat.roughness = 1.0
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	base.material_override = mat
	add_child(base)
	# The same three-stroke hook appears on both surfaces. Simple geometry keeps
	# it legible under Compatibility rendering and at the shipped camera.
	var ink := Color(0.18, 0.20, 0.19) if presentation == "etched_stone" \
		else Color(0.42, 0.12, 0.10)
	_add_stroke(Vector3(-0.12, 0.085, -0.08), Vector3(0.07, 0.025, 0.40), 0.0, ink)
	_add_stroke(Vector3(0.01, 0.087, 0.10), Vector3(0.30, 0.025, 0.07), -0.28, ink)
	_add_stroke(Vector3(0.13, 0.089, 0.21), Vector3(0.07, 0.025, 0.20), 0.66, ink)

func _add_stroke(pos: Vector3, size: Vector3, yaw: float, color: Color) -> void:
	var stroke := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	stroke.mesh = box
	stroke.position = pos
	stroke.rotation.y = yaw
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	stroke.material_override = mat
	add_child(stroke)

func interact(_player: Node) -> void:
	var game := get_tree().root.get_node_or_null("Game")
	var is_new := game != null and bool(game.observe_second_hand(clue_id))
	var pages: Array
	if presentation == "etched_stone":
		pages = [
			"A hooked hand, cut into the stone beside the Waystone.",
			"It might be old. It might have been waiting.",
		] if is_new else ["The hooked hand is still here. No clearer than before."]
	else:
		pages = [
			"A scrap of your Chart lies folded under the dust.",
			"The hooked hand is drawn across it in your own wet ink. You did not draw it.",
		] if is_new else ["Your ink. The same hooked hand. Still no answer."]
	var dlg := DialogPanelScript.new()
	dlg.open("A Mark in the Margin", pages)
	get_tree().current_scene.add_child(dlg)
