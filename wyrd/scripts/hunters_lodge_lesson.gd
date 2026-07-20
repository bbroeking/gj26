class_name HuntersLodgeLesson
extends Interactable

# Thin presentation adapter for the Huntcraft 18/20 Lodge lessons. Game owns
# which lesson is pending and the skill-planner transaction; this marker
# never grants, equips, writes a hint, or chooses a hotbar slot itself.

const DialogPanelScript = preload("res://scripts/ui/dialog_panel.gd")

var _status: Dictionary = {}
var _dialog_open := false


func refresh() -> void:
	_status = lesson_status()
	visible = bool(_status.get("pending", _status.get("available", false)))
	var prompt := get_node_or_null("PromptLabel") as Label3D
	if prompt != null:
		prompt.text = get_prompt_text()


func lesson_status() -> Dictionary:
	var game := get_tree().root.get_node_or_null("Game") if is_inside_tree() else null
	if game == null or not game.has_method("hunters_lodge_lesson_status"):
		return {"pending": false, "available": false, "read_only": true}
	var raw = game.hunters_lodge_lesson_status()
	return raw as Dictionary if raw is Dictionary else {"pending": false, "available": false}


func get_prompt_text() -> String:
	if bool(_status.get("read_only", false)):
		return "[E/A] Read the host's Lodge lesson"
	return "[E/A] Take the Lodge lesson"


func get_prompt_color() -> Color:
	return Color(0.84, 0.70, 0.38)


func get_collision_radius() -> float:
	return 1.35


func get_collision_offset() -> Vector3:
	return Vector3(0.0, 0.7, 0.0)


func get_prompt_position() -> Vector3:
	return Vector3(0.0, 1.85, 0.0)


func get_solid_radius() -> float:
	return 0.75


func get_solid_height() -> float:
	return 1.2


func _ready_interactable() -> void:
	add_to_group("hunters_lodge_lesson")
	_add_marker()
	refresh()


func _add_marker() -> void:
	var post := MeshInstance3D.new()
	post.name = "LodgeLessonPost"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.10
	mesh.bottom_radius = 0.13
	mesh.height = 1.35
	mesh.radial_segments = 8
	post.mesh = mesh
	post.position = Vector3(0.0, 0.68, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.31, 0.20, 0.11)
	mat.roughness = 0.95
	post.material_override = mat
	add_child(post)
	var sign := Label3D.new()
	sign.name = "LodgeLessonSign"
	sign.text = "HUNTER'S LODGE\nROAD, BREATH, BOWSTRING"
	sign.position = Vector3(0.0, 1.42, 0.04)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.no_depth_test = true
	sign.modulate = Color(0.92, 0.78, 0.49)
	sign.font_size = 18
	sign.pixel_size = 0.0034
	sign.outline_size = 7
	sign.outline_modulate = Color(0.08, 0.05, 0.03, 0.95)
	var font := WyrdUi.font_header()
	if font != null:
		sign.font = font
	add_child(sign)


func interact(_player: Node) -> void:
	if _dialog_open or not visible:
		return
	_dialog_open = true
	var dialog: CanvasLayer = DialogPanelScript.new()
	dialog.name = "HuntersLodgeLessonDialog"
	dialog.add_to_group("HuntersLodgeLessonDialog")
	var pages := [
		"Five arrows leave together, close enough to share one breath.",
		"A practice bramble waits nearby. The Lodge will only offer the lesson; your kit remains your own.",
	]
	if String(_status.get("lesson_id", "")) == "threadstep":
		pages = [
			"Ash runs ahead of a quick foot, but stone and shut doors still keep their say.",
			"Threadstep holds one breath of Focus until the road answers safe. A barred step costs nothing.",
		]
	if String(_status.get("lesson_id", "")) == "wayfinders_mark":
		pages = [
			"A knot answers no loose arrow. Hold your breath of Focus until the road says whose hand may name it.",
			"When the old binding reels, set your mark close and clear. A false mark costs nothing; a true one changes the road.",
		]
	if bool(_status.get("read_only", false)):
		pages.append("The host keeps the lesson's choice. This page is yours to read.")
	dialog.open("The Hunter's Lodge", pages)
	dialog.finished.connect(func() -> void:
		_dialog_open = false
		accept_now())
	var scene := get_tree().current_scene
	if scene != null:
		scene.add_child(dialog)


func accept_now() -> Dictionary:
	if bool(_status.get("read_only", false)):
		return {"ok": true, "changed": false, "read_only": true}
	var game := get_tree().root.get_node_or_null("Game") if is_inside_tree() else null
	if game == null or not game.has_method("accept_hunters_lodge_lesson"):
		return {"ok": false, "changed": false}
	var raw = game.accept_hunters_lodge_lesson()
	refresh()
	var town := get_tree().current_scene
	if town != null and town.has_method("_apply_driving_volley_lesson"):
		town.call("_apply_driving_volley_lesson")
	return raw as Dictionary if raw is Dictionary else {"ok": false, "changed": false}
