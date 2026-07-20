class_name RootroadLift
extends Interactable

# The Pale Oath's town return remains this landmark's visibility truth. Fire in
# the Bough adds two host-only physical source transactions through Game's
# generic source adapter: ordinary folio at Wayfinding 20, furnace folio after
# Verse V. The Lift never inspects campaign dictionaries, grants supplies, or
# writes a save itself.

const DialogPanelScript = preload("res://scripts/ui/dialog_panel.gd")
const LIFT_GLB_PATH := "res://models/landmark_rootroad_lift_wellhouse_v1.glb"
const HOD_OATHSTONE_GLB_PATH := "res://models/landmark_hod_oathstone_v1.glb"
const ASHEN_SOURCE_ID := "rootroad_lift_ashen_bough"
const GIANT_SOURCE_ID := "rootroad_lift_hearth_giant"

var _view: Dictionary = {}
var _read_only := false
var _dialog_open := false
var _built := false
var _lower_landing: Node3D = null


func set_settlement_view(view: Dictionary) -> void:
	_view = view.duplicate(true)
	_read_only = bool(_view.get("read_only", false)) or bool(_view.get("guest", false))
	visible = settlement_visible()
	if is_node_ready() and visible and not _built:
		_build()
	if is_node_ready() and visible:
		_refresh_landing(false)


func settlement_visible() -> bool:
	var chapters = _view.get("chapters", {})
	var pale = (chapters as Dictionary).get("pale_oath", {}) \
		if chapters is Dictionary else _view.get("pale_oath", {})
	return bool(_view.get("available", true)) and pale is Dictionary \
		and bool((pale as Dictionary).get("visible", false)) \
		and bool((pale as Dictionary).get("relic_visible", false)) \
		and bool((pale as Dictionary).get("restoration_visible", false)) \
		and String((pale as Dictionary).get("restoration_id", "")) == "rootroad_lift"


func presentation_ids() -> Dictionary:
	return {
		"restoration_id": "rootroad_lift" if settlement_visible() else "",
		"lift_id": "rootroad_lift" if settlement_visible() else "",
		"oathstone_id": "hod_oathstone" if settlement_visible() else "",
	}


func get_prompt_text() -> String:
	if _read_only:
		return "[E/A] Inspect the host's Rootroad Lift"
	var selected := _selected_source_status()
	if String(selected.get("state", "")) in ["eligible", "read"]:
		return "[E/A] Read the furnace folio" if String(selected.get("source_id", "")) \
			== GIANT_SOURCE_ID else "[E/A] Lower the Rootroad Lift"
	return "[E/A] Inspect the Rootroad Lift"


func get_prompt_color() -> Color:
	return Color(0.96, 0.70, 0.47)


func get_collision_radius() -> float:
	return 2.2


func get_collision_offset() -> Vector3:
	return Vector3(0.0, 1.0, 0.0)


func get_prompt_position() -> Vector3:
	return Vector3(0.0, 3.0, 0.0)


func get_solid_radius() -> float:
	return 1.65


func get_solid_height() -> float:
	return 2.2


func _ready_interactable() -> void:
	add_to_group("rootroad_lift")
	if visible:
		_build()


func _build() -> void:
	if _built:
		return
	_built = true
	# The asset packet is intentionally optional while imports settle.  These
	# procedural silhouettes preserve the landmark/readability without a failed
	# GLB load becoming a Town boot error.
	_add_optional_model(LIFT_GLB_PATH, "RootroadLiftWellhouse", Vector3.ZERO, 1.35)
	_add_optional_model(HOD_OATHSTONE_GLB_PATH, "HodOathstone", Vector3(1.75, 0.0, -0.82), 0.90)
	if get_node_or_null("RootroadLiftWellhouse") == null:
		_add_box("RootroadLiftWellhouse", Vector3(1.8, 2.4, 1.8),
			Vector3(0.0, 1.2, 0.0), Color(0.24, 0.17, 0.13))
		_add_box("LiftPaleLight", Vector3(0.82, 0.08, 0.82),
			Vector3(0.0, 2.06, 0.0), Color(0.74, 0.55, 0.94))
	if get_node_or_null("HodOathstone") == null:
		_add_box("HodOathstone", Vector3(0.62, 1.55, 0.50),
			Vector3(1.75, 0.78, -0.82), Color(0.34, 0.32, 0.38))
	_add_label("RootroadLiftLabel", "ROOTROAD LIFT  ·  HOD'S OATH-STONE",
		Vector3(0.45, 2.65, 0.0), Color(1.0, 0.78, 0.61))
	_build_lower_landing()
	_refresh_landing(false)


func _build_lower_landing() -> void:
	if _lower_landing != null:
		return
	_lower_landing = Node3D.new()
	_lower_landing.name = "LiftLowerLanding"
	_lower_landing.add_to_group("rootroad_lift_lower_landing")
	add_child(_lower_landing)
	var landing_path := "res://models/biome_ashen_bough_landing_v1.glb"
	if ResourceLoader.exists(landing_path, "PackedScene"):
		var packed := ResourceLoader.load(landing_path, "PackedScene") as PackedScene
		var model := packed.instantiate() as Node3D if packed != null else null
		if model != null:
			model.name = "AshenLandingModel"
			GlbFit.normalize_height(model, 1.45)
			_lower_landing.add_child(model)
			return
	var platform := MeshInstance3D.new()
	platform.name = "AshenLandingPlatform"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.34, 0.18, 1.34)
	platform.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.31, 0.19, 0.13)
	mat.roughness = 0.94
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	platform.material_override = mat
	_lower_landing.add_child(platform)
	for x in [-0.48, 0.48]:
		var chain := MeshInstance3D.new()
		chain.name = "PaleChainL" if x < 0.0 else "PaleChainR"
		var chain_mesh := BoxMesh.new()
		chain_mesh.size = Vector3(0.07, 1.35, 0.07)
		chain.mesh = chain_mesh
		chain.position = Vector3(x, 0.72, 0.0)
		var chain_mat := StandardMaterial3D.new()
		chain_mat.albedo_color = Color(0.70, 0.58, 0.72)
		chain_mat.roughness = 0.55
		chain.material_override = chain_mat
		_lower_landing.add_child(chain)


func _game() -> Node:
	return get_node_or_null("/root/Game")


func _source_status(source_id: String) -> Dictionary:
	var game := _game()
	if game == null or not game.has_method("chart_source_status"):
		return {"valid": false, "source_id": source_id, "state": "invalid"}
	var raw = game.call("chart_source_status", source_id)
	return raw as Dictionary if raw is Dictionary else {}


func _selected_source_status() -> Dictionary:
	var boss := _source_status(GIANT_SOURCE_ID)
	if String(boss.get("state", "")) in ["eligible", "read", "resolved"]:
		return boss
	return _source_status(ASHEN_SOURCE_ID)


func source_status() -> Dictionary:
	var selected := _selected_source_status().duplicate(true)
	selected["read_only"] = _read_only
	return selected


func lower_landing_state() -> Dictionary:
	var ordinary := _source_status(ASHEN_SOURCE_ID)
	return {"lowered": String(ordinary.get("state", "")) in ["read", "resolved"],
		"position_y": _lower_landing.position.y if _lower_landing != null else 1.35}


func _refresh_landing(animate: bool) -> void:
	if _lower_landing == null:
		return
	var ordinary := _source_status(ASHEN_SOURCE_ID)
	var lowered := String(ordinary.get("state", "")) in ["read", "resolved"]
	var target_y := 0.12 if lowered else 1.35
	if animate and lowered and not is_equal_approx(_lower_landing.position.y, target_y):
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(_lower_landing, "position:y", target_y, 1.15)
	else:
		_lower_landing.position.y = target_y


func _add_optional_model(path: String, node_name: String, pos: Vector3, scale_factor: float) -> void:
	if not ResourceLoader.exists(path, "PackedScene"):
		return
	var packed := ResourceLoader.load(path, "PackedScene") as PackedScene
	if packed == null:
		return
	var instance := packed.instantiate() as Node3D
	if instance == null:
		return
	instance.name = node_name
	instance.position = pos
	instance.scale = Vector3.ONE * scale_factor
	add_child(instance)


func _add_box(node_name: String, size: Vector3, pos: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.92
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	instance.material_override = mat
	add_child(instance)


func _add_label(node_name: String, text: String, pos: Vector3, color: Color) -> void:
	var label := Label3D.new()
	label.name = node_name
	label.text = text
	label.position = pos
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = color
	label.font_size = 20
	label.pixel_size = 0.0032
	label.outline_size = 8
	label.outline_modulate = Color(0.09, 0.05, 0.04, 0.95)
	var font := WyrdUi.font_header()
	if font != null:
		label.font = font
	add_child(label)


func interact(_player: Node) -> void:
	if _dialog_open or not visible:
		return
	_dialog_open = true
	var selected := _selected_source_status()
	var source_id := String(selected.get("source_id", ASHEN_SOURCE_ID))
	var eligible := not _read_only and String(selected.get("state", "")) in ["eligible", "read"]
	var dialog: CanvasLayer = DialogPanelScript.new()
	dialog.name = "RootroadLiftDialog"
	dialog.add_to_group("RootroadLiftDialog")
	var pages := [
		"The lift's pale chain has been set true beside Hod's oath-stone.",
		"It is made ready, but the road below has not opened for walking.",
		"There is nothing to take. The old promise keeps its own account.",
	]
	if eligible and source_id == ASHEN_SOURCE_ID:
		pages = [
			"The pale chain takes your weight. Far below, an ash-warm branch answers.",
			"Mara's ordinary folio is fixed beneath the brake: Ashen Bough.",
			"The Lift lowers a landing—not a free Chart, not Ink, not makings. The Table still asks for every line.",
		]
	elif eligible and source_id == GIANT_SOURCE_ID:
		pages = [
			"Five ember verses agree. Their scorched margins fold into one furnace folio.",
			"The Hearth Giant's road takes the Starheart Coal at the Table. Nothing loose may stand in for it.",
		]
	dialog.open("The Rootroad Lift", pages)
	dialog.finished.connect(func() -> void:
		_dialog_open = false
		if not eligible:
			return
		var game := _game()
		if game == null or not game.has_method("read_chart_source"):
			return
		var result = game.call("read_chart_source", source_id)
		if result is Dictionary and bool((result as Dictionary).get("changed", false)):
			_refresh_landing(source_id == ASHEN_SOURCE_ID))
	var scene := get_tree().current_scene
	if scene != null:
		scene.add_child(dialog)
