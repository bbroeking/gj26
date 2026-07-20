class_name MaraRainNote
extends Interactable

# Slice C2 — Mara leaves this persistent note only after a completed Hollow
# unlocks its source. It may be anticipated below Wayfinding 12, then read and
# reread without borrowing Mara's tutorial or Second Hand dialog branches.

const DialogPanelScript = preload("res://scripts/ui/dialog_panel.gd")
const SOURCE_ID := "mara_sallow_reed"
const VALID_STATES := ["locked", "eligible", "read", "resolved"]

var _dialog_open := false
var _game_ref: Node = null


func get_prompt_text() -> String:
	match String(source_status().get("state", "invalid")):
		"eligible": return "[E/A] Read Mara's rain-stained note"
		"read": return "[E/A] Re-read Mara's rain-stained note"
		"resolved": return "[E/A] Read Mara's mire note"
		_: return "[E/A] Study Mara's rain-stained note"


func get_prompt_color() -> Color:
	return Color(0.64, 0.82, 0.72)


func get_collision_radius() -> float:
	return 0.9


func get_collision_offset() -> Vector3:
	return Vector3(0.0, 0.2, 0.0)


func get_prompt_position() -> Vector3:
	return Vector3(0.0, 0.72, 0.0)


func get_solid_radius() -> float:
	return 0.0


func _ready_interactable() -> void:
	add_to_group("chart_rumour_source")
	add_to_group("mara_rain_note")
	var paper := MeshInstance3D.new()
	paper.name = "RainStainedNoteVisual"
	var slab := BoxMesh.new()
	slab.size = Vector3(0.76, 0.035, 0.54)
	paper.mesh = slab
	paper.position.y = 0.03
	var paper_mat := StandardMaterial3D.new()
	paper_mat.albedo_color = Color(0.80, 0.75, 0.57)
	paper_mat.roughness = 1.0
	paper_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	paper.material_override = paper_mat
	add_child(paper)
	# Three restrained ink lines and two damp spots keep the ground prop legible.
	_add_line(Vector3(-0.05, 0.056, -0.13), Vector3(0.50, 0.016, 0.025))
	_add_line(Vector3(-0.10, 0.057, -0.02), Vector3(0.40, 0.016, 0.025))
	_add_line(Vector3(-0.02, 0.058, 0.09), Vector3(0.54, 0.016, 0.025))
	_add_damp_spot(Vector3(-0.25, 0.054, 0.15), 0.09)
	_add_damp_spot(Vector3(0.27, 0.054, -0.16), 0.07)
	_game_ref = _game()
	if _game_ref != null and _game_ref.has_signal("chart_knowledge_changed"):
		_game_ref.chart_knowledge_changed.connect(refresh_source_state)
	refresh_source_state()


func _exit_tree() -> void:
	if _game_ref != null and is_instance_valid(_game_ref) \
			and _game_ref.chart_knowledge_changed.is_connected(refresh_source_state):
		_game_ref.chart_knowledge_changed.disconnect(refresh_source_state)
	_game_ref = null


func _add_line(pos: Vector3, size: Vector3) -> void:
	var line := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	line.mesh = mesh
	line.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.28, 0.20)
	mat.roughness = 1.0
	line.material_override = mat
	add_child(line)


func _add_damp_spot(pos: Vector3, radius: float) -> void:
	var spot := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.012
	mesh.radial_segments = 12
	spot.mesh = mesh
	spot.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.34, 0.46, 0.38, 0.65)
	mat.roughness = 1.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spot.material_override = mat
	add_child(spot)


func source_status() -> Dictionary:
	var fallback := {"valid": false, "source_id": SOURCE_ID, "state": "invalid",
		"unlocked": false, "level": 1, "min_wayfinding": 12,
		"rumour_id": "", "recipe_id": "", "known": false, "heard": false}
	var game := _game()
	if game == null or not game.has_method("chart_source_status"):
		return fallback
	var raw = game.chart_source_status(SOURCE_ID)
	if not raw is Dictionary:
		return fallback
	var out := fallback.duplicate(true)
	out.merge(raw as Dictionary, true)
	if String(out.state) not in VALID_STATES:
		out.state = "invalid"
		out.valid = false
	return out


func refresh_source_state() -> void:
	var prompt := get_node_or_null("PromptLabel") as Label3D
	if prompt != null:
		prompt.text = get_prompt_text()
	_refresh_marker()


func show_prompt(on: bool) -> void:
	super.show_prompt(on)
	_refresh_marker()


func _refresh_marker() -> void:
	var marker := get_node_or_null("Marker") as Label3D
	if marker == null:
		return
	var prompt := get_node_or_null("PromptLabel") as Label3D
	var prompt_visible := prompt != null and prompt.visible
	marker.visible = not prompt_visible and String(source_status().state) in [
		"locked", "eligible"]


func interact(_player: Node) -> void:
	if _dialog_open:
		return
	var status := source_status()
	if not bool(status.valid):
		return
	_dialog_open = true
	var dialog: CanvasLayer = DialogPanelScript.new()
	dialog.name = "ChartRumourSourceDialog"
	dialog.add_to_group("ChartRumourSourceDialog")
	dialog.set_meta("chart_source_id", SOURCE_ID)
	dialog.set_meta("chart_source_owner_id", get_instance_id())
	dialog.open("Mara's Rain-Stained Note", _pages(status))
	dialog.finished.connect(func() -> void:
		_dialog_open = false
		read_now())
	get_tree().current_scene.add_child(dialog)


func read_now() -> Dictionary:
	var fallback := {"ok": false, "changed": false, "state": "invalid",
		"granted": {}, "status": source_status()}
	var game := _game()
	if game == null or not game.has_method("read_chart_source"):
		return fallback
	var raw = game.read_chart_source(SOURCE_ID)
	if not raw is Dictionary:
		return fallback
	refresh_source_state()
	return raw as Dictionary


func _pages(status: Dictionary) -> Array:
	match String(status.get("state", "invalid")):
		"eligible", "read":
			return ["A mire reed points where dry ink cannot. Wax the page and sink the binding low."]
		"resolved":
			return ["Wax, reed, and the sunken knot. Mara's old measure still keeps the wet road true."]
		_:
			return ["Rain has blurred the lower measure. A pressed reed holds its place between the folds.",
				"The rest may settle at Wayfinding %d." % int(status.get("min_wayfinding", 12))]


func _game() -> Node:
	return get_tree().root.get_node_or_null("Game") if is_inside_tree() else null
