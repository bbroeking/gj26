class_name TrophyHall
extends Interactable

# First Knot Homecoming's whole physical payoff is deliberately small: one
# yard-side alcove, not a new interior or a second reward system.  This node is
# a read-only projection of Game.first_knot_homecoming_view(); it never asks
# Game about campaign, inventory, or save state itself.

const DialogPanelScript = preload("res://scripts/ui/dialog_panel.gd")
const WAYWEAVER_GLB := preload("res://models/wayweaver_v1.glb")

var _view: Dictionary = {}
var _settlement_view: Dictionary = {}
var _dialog_open := false
var _built := false
var _golden_built := false
var _seventh_built := false
var _queen_built := false
var _pale_oath_built := false


func set_homecoming_view(view: Dictionary) -> void:
	_view = view.duplicate(true)
	visible = bool(_view.get("visible", false)) \
		and bool(_view.get("restoration_visible", false))
	if is_node_ready() and visible and not _built:
		_build_alcove()


func set_settlement_view(view: Dictionary) -> void:
	_settlement_view = view.duplicate(true)
	if is_node_ready() and _built:
		_reconcile_golden_wallow_record()
		_reconcile_seventh_road_record()
		_reconcile_queens_summit_record()
		_reconcile_pale_oath_record()
		_reconcile_wayweaver_mount()


func presentation_ids() -> Dictionary:
	return {
		"rune_id": String(_view.get("rune_id", "")),
		"tusk_record_id": String(_view.get("tusk_record_id", "")),
		"covered_bow_rest_id": String(_view.get("covered_bow_rest_id", "")),
	}


func golden_presentation_ids() -> Dictionary:
	var golden := _golden_view()
	return {
		"relic_id": String(golden.get("relic_id", "")),
		"restoration_id": String(golden.get("restoration_id", "")),
		"material_record_id": "wightpelt" if bool(golden.get("visible", false)) else "",
	}


func seventh_presentation_ids() -> Dictionary:
	var seventh := _seventh_view()
	return {
		"relic_id": String(seventh.get("relic_id", "")),
		"restoration_id": String(seventh.get("restoration_id", "")),
		"material_record_id": "alpha_fang" if bool(seventh.get("visible", false)) else "",
	}


func queens_summit_presentation_ids() -> Dictionary:
	var queen := _queen_view()
	return {
		"relic_id": String(queen.get("relic_id", "")),
		"restoration_id": String(queen.get("restoration_id", "")),
		# This is a Hall account, never a loose/claimable item.
		"material_record_id": "oath_nail" if bool(queen.get("visible", false)) else "",
	}


func pale_oath_presentation_ids() -> Dictionary:
	var pale := _pale_oath_view()
	var visible := _pale_oath_record_should_show()
	return {
		"relic_id": String(pale.get("relic_id", "")) if visible else "",
		"restoration_id": String(pale.get("restoration_id", "")) if visible else "",
		# All three are fixed Hall accounts, never loose rewards or inventory.
		"material_record_id": "starheart_coal" if visible else "",
		"thread_record_id": "past_thread" if visible else "",
	}


func get_prompt_text() -> String:
	return "[E/A] Inspect the Trophy Hall"


func get_prompt_color() -> Color:
	return Color(0.83, 0.76, 0.47)


func get_collision_radius() -> float:
	return 1.65


func get_collision_offset() -> Vector3:
	return Vector3(0.0, 0.8, 0.0)


func get_prompt_position() -> Vector3:
	return Vector3(0.0, 2.45, 0.0)


func get_solid_radius() -> float:
	return 1.2


func get_solid_height() -> float:
	return 1.7


func _ready_interactable() -> void:
	if visible:
		_build_alcove()


func _build_alcove() -> void:
	if _built:
		return
	_built = true
	# Three posts, a low plinth, and a roof make a humble open-sided honouring
	# place.  Keeping it procedural avoids a one-use GLB/interior pipeline.
	_add_box("HallBack", Vector3(0.22, 2.2, 3.4), Vector3(0.0, 1.1, 0.0),
		Color(0.22, 0.15, 0.09))
	for z in [-1.55, 1.55]:
		_add_box("HallPost", Vector3(0.28, 2.35, 0.28), Vector3(0.68, 1.18, z),
			Color(0.28, 0.18, 0.10))
	# Two shallow roof planes give the alcove a storybook gable instead of a
	# single modern-looking slab.
	_add_box("HallRoofLeft", Vector3(0.98, 0.16, 3.75),
		Vector3(-0.15, 2.38, 0.0), Color(0.19, 0.13, 0.08),
		Vector3(0.0, 0.0, -0.30))
	_add_box("HallRoofRight", Vector3(0.98, 0.16, 3.75),
		Vector3(0.70, 2.38, 0.0), Color(0.24, 0.16, 0.09),
		Vector3(0.0, 0.0, 0.30))
	_add_box("HallHeader", Vector3(0.24, 0.28, 3.38),
		Vector3(0.18, 2.10, 0.0), Color(0.31, 0.20, 0.11))
	_add_box("HallPlinth", Vector3(1.25, 0.36, 3.15), Vector3(0.46, 0.18, 0.0),
		Color(0.36, 0.28, 0.18))
	if bool(_view.get("rune_visible", false)):
		_build_green_root_rune()
	if bool(_view.get("tusk_record_visible", false)):
		_build_tusker_record()
	if bool(_view.get("covered_bow_rest_visible", false)):
		_build_covered_bow_rest()
	_reconcile_golden_wallow_record()
	_reconcile_seventh_road_record()
	_reconcile_queens_summit_record()
	_reconcile_pale_oath_record()
	_reconcile_wayweaver_mount()


func _build_green_root_rune() -> void:
	var rune := MeshInstance3D.new()
	rune.name = "GreenRootRune"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.30
	mesh.bottom_radius = 0.30
	mesh.height = 0.08
	mesh.radial_segments = 12
	rune.mesh = mesh
	rune.rotation.z = PI * 0.5
	rune.position = Vector3(0.15, 1.45, -1.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.32, 0.66, 0.29)
	mat.roughness = 0.7
	mat.emission_enabled = true
	mat.emission = Color(0.16, 0.48, 0.18)
	mat.emission_energy_multiplier = 0.65
	rune.material_override = mat
	add_child(rune)
	_add_label("RuneLabel", "Green Root Rune", Vector3(0.18, 1.12, -1.0),
		Color(0.68, 0.90, 0.59), 28)


func _build_tusker_record() -> void:
	_add_box("TuskerRecordPlaque", Vector3(0.10, 0.78, 0.92),
		Vector3(0.16, 1.18, 0.0), Color(0.48, 0.36, 0.20))
	# A paired ivory mark, set into the plaque, reads as a kept account rather
	# than loot.  Nothing here is an ItemPickup or calls an inventory method.
	for z in [-0.16, 0.16]:
		var tusk := MeshInstance3D.new()
		tusk.name = "TuskerRecordMark"
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.045
		mesh.bottom_radius = 0.10
		mesh.height = 0.38
		mesh.radial_segments = 8
		tusk.mesh = mesh
		tusk.rotation.z = PI * 0.5
		tusk.position = Vector3(0.09, 1.31, z)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.83, 0.76, 0.58)
		mat.roughness = 0.85
		tusk.material_override = mat
		add_child(tusk)
	_add_label("TuskerRecordLabel", "Tusker record", Vector3(0.18, 0.69, 0.0),
		Color(0.91, 0.81, 0.58), 27)


func _build_covered_bow_rest() -> void:
	# A narrow wall-rest under a soft, uneven cloth reads as something being
	# kept for later without previewing the legendary or turning it into loot.
	if get_node_or_null("CoveredBowRest") != null:
		if get_node_or_null("WayweaverMountCovered") == null:
			var existing_mount := Node3D.new()
			existing_mount.name = "WayweaverMountCovered"
			add_child(existing_mount)
		return
	var mount := Node3D.new()
	mount.name = "WayweaverMountCovered"
	add_child(mount)
	_add_box("BowRestSpine", Vector3(0.14, 1.20, 0.18),
		Vector3(0.11, 1.08, 1.04), Color(0.24, 0.16, 0.10))
	_add_box("CoveredBowRest", Vector3(0.24, 0.92, 0.72),
		Vector3(0.18, 1.24, 1.04), Color(0.39, 0.48, 0.38))
	_add_box("CoveredBowFoldLeft", Vector3(0.25, 0.68, 0.16),
		Vector3(0.20, 1.08, 0.78), Color(0.31, 0.40, 0.32),
		Vector3(0.10, 0.0, 0.0))
	_add_box("CoveredBowFoldRight", Vector3(0.25, 0.76, 0.16),
		Vector3(0.20, 1.04, 1.30), Color(0.45, 0.52, 0.40),
		Vector3(-0.10, 0.0, 0.0))
	_add_box("BowRestLeg", Vector3(0.16, 0.54, 0.16),
		Vector3(0.14, 0.48, 1.04), Color(0.29, 0.19, 0.11))


func _wayweaver_mount_view() -> Dictionary:
	var raw = _settlement_view.get("wayweaver_mount", {})
	return raw as Dictionary if raw is Dictionary else {}


func _wayweaver_mount_state() -> String:
	var state := String(_wayweaver_mount_view().get("state", "covered"))
	return state if state in ["covered", "empty", "full"] else "covered"


func _reconcile_wayweaver_mount() -> void:
	# Hall geometry is strictly a consumer of `set_settlement_view`: it cannot
	# award a bow, infer equipment, or write a save.  `covered` intentionally
	# reuses the old First Knot bow-rest until the final campaign clear.
	match _wayweaver_mount_state():
		"covered":
			_remove_wayweaver_mount_nodes(["WayweaverMountEmpty", "WayweaverMountFull"])
			if bool(_view.get("covered_bow_rest_visible", false)):
				_build_covered_bow_rest()
		"empty":
			_remove_wayweaver_mount_nodes(_covered_mount_node_names() + ["WayweaverMountFull"])
			_build_empty_wayweaver_mount()
		"full":
			_remove_wayweaver_mount_nodes(_covered_mount_node_names() + ["WayweaverMountEmpty"])
			_build_full_wayweaver_mount()


func _covered_mount_node_names() -> Array[String]:
	return ["WayweaverMountCovered", "BowRestSpine", "CoveredBowRest",
		"CoveredBowFoldLeft", "CoveredBowFoldRight", "BowRestLeg"]


func _remove_wayweaver_mount_nodes(node_names: Array) -> void:
	for node_name in node_names:
		var node := get_node_or_null(node_name)
		if node != null:
			node.queue_free()


func _build_empty_wayweaver_mount() -> void:
	if get_node_or_null("WayweaverMountEmpty") != null:
		return
	var mount := Node3D.new()
	mount.name = "WayweaverMountEmpty"
	mount.position = Vector3(0.14, 0.0, 1.04)
	add_child(mount)
	_mount_box(mount, "EmptyRestSpine", Vector3(0.14, 1.18, 0.18),
		Vector3.ZERO + Vector3(0.0, 1.08, 0.0), Color(0.24, 0.16, 0.10))
	_mount_box(mount, "EmptyRestArms", Vector3(0.22, 0.13, 0.72),
		Vector3(0.0, 1.20, 0.0), Color(0.40, 0.29, 0.17))
	_mount_box(mount, "EmptyRestLeg", Vector3(0.16, 0.54, 0.16),
		Vector3(0.0, 0.48, 0.0), Color(0.29, 0.19, 0.11))
	_mount_label(mount, "EmptyMountLabel", "A rest made ready", Vector3(0.03, 0.72, 0.0),
		Color(0.78, 0.68, 0.46), 20)


func _build_full_wayweaver_mount() -> void:
	if get_node_or_null("WayweaverMountFull") != null:
		return
	var mount := Node3D.new()
	mount.name = "WayweaverMountFull"
	mount.position = Vector3(0.14, 0.0, 1.04)
	add_child(mount)
	_mount_box(mount, "FullMountRest", Vector3(0.22, 0.14, 0.76),
		Vector3(0.0, 0.72, 0.0), Color(0.39, 0.29, 0.17))
	var bow := WAYWEAVER_GLB.instantiate()
	bow.name = "WayweaverDisplay"
	if bow is Node3D:
		(bow as Node3D).position = Vector3(0.0, 1.10, 0.0)
		(bow as Node3D).rotation_degrees = Vector3(0.0, 0.0, -90.0)
		(bow as Node3D).scale = Vector3(0.50, 0.50, 0.50)
	mount.add_child(bow)
	var rune_id := String(_wayweaver_mount_view().get("cosmetic_rune_id", ""))
	if rune_id != "":
		_mount_label(mount, "WayweaverMountRuneLabel", rune_id.replace("_", " ").capitalize(),
			Vector3(0.03, 0.48, 0.0), Color(0.62, 0.86, 0.84), 18)
	_mount_label(mount, "FullMountLabel", "Wayweaver", Vector3(0.03, 0.32, 0.0),
		Color(0.78, 0.82, 0.68), 22)


func _mount_box(parent: Node3D, node_name: String, size: Vector3, pos: Vector3,
		color: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	instance.material_override = mat
	parent.add_child(instance)


func _mount_label(parent: Node3D, node_name: String, text: String, pos: Vector3,
		color: Color, font_size: int) -> void:
	var label := Label3D.new()
	label.name = node_name
	label.text = text
	label.position = pos
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = color
	label.font_size = font_size
	label.pixel_size = 0.004
	label.outline_size = 8
	label.outline_modulate = Color(0.08, 0.06, 0.04, 0.9)
	var font := WyrdUi.font_header()
	if font != null:
		label.font = font
	parent.add_child(label)


func _golden_view() -> Dictionary:
	var chapters = _settlement_view.get("chapters", {})
	var raw = (chapters as Dictionary).get("golden_wallow", {}) \
		if chapters is Dictionary else _settlement_view.get("golden_wallow", {})
	return raw as Dictionary if raw is Dictionary else {}


func _seventh_view() -> Dictionary:
	var chapters = _settlement_view.get("chapters", {})
	var raw = (chapters as Dictionary).get("seventh_road", {}) \
		if chapters is Dictionary else _settlement_view.get("seventh_road", {})
	return raw as Dictionary if raw is Dictionary else {}


func _queen_view() -> Dictionary:
	var chapters = _settlement_view.get("chapters", {})
	var raw = (chapters as Dictionary).get("queens_summit", {}) \
		if chapters is Dictionary else _settlement_view.get("queens_summit", {})
	return raw as Dictionary if raw is Dictionary else {}


func _pale_oath_view() -> Dictionary:
	var chapters = _settlement_view.get("chapters", {})
	var raw = (chapters as Dictionary).get("pale_oath", {}) \
		if chapters is Dictionary else _settlement_view.get("pale_oath", {})
	return raw as Dictionary if raw is Dictionary else {}


func _golden_record_should_show() -> bool:
	var golden := _golden_view()
	return bool(_settlement_view.get("available", true)) \
		and bool(golden.get("visible", false)) \
		and bool(golden.get("relic_visible", false))


func _reconcile_golden_wallow_record() -> void:
	if _golden_record_should_show():
		_build_golden_wallow_record()
		return
	if not _golden_built:
		return
	for node_name in ["GoldenWallowRecord", "WightpeltPlaque", "WightpeltRecord",
			"MistRootRune", "GoldenWallowRecordLabel"]:
		var node := get_node_or_null(node_name)
		if node != null:
			node.queue_free()
	_golden_built = false


func _build_golden_wallow_record() -> void:
	if _golden_built:
		return
	if not _golden_record_should_show():
		return
	_golden_built = true
	var record := Node3D.new()
	record.name = "GoldenWallowRecord"
	add_child(record)
	_add_box("WightpeltPlaque", Vector3(0.10, 0.74, 0.86),
		Vector3(0.16, 1.15, 1.48), Color(0.36, 0.28, 0.20))
	# The pelt is an account in the Hall, not a second inventory pickup.
	_add_box("WightpeltRecord", Vector3(0.16, 0.48, 0.58),
		Vector3(0.08, 1.30, 1.48), Color(0.72, 0.68, 0.58),
		Vector3(0.0, 0.0, 0.08))
	var rune := MeshInstance3D.new()
	rune.name = "MistRootRune"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.19
	mesh.bottom_radius = 0.19
	mesh.height = 0.07
	mesh.radial_segments = 12
	rune.mesh = mesh
	rune.rotation.z = PI * 0.5
	rune.position = Vector3(0.03, 1.62, 1.48)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.36, 0.82, 0.68)
	mat.roughness = 0.65
	mat.emission_enabled = true
	mat.emission = Color(0.18, 0.58, 0.46)
	mat.emission_energy_multiplier = 0.75
	rune.material_override = mat
	add_child(rune)
	_add_label("GoldenWallowRecordLabel", "Mist Root · Wightpelt",
		Vector3(0.18, 0.67, 1.48), Color(0.61, 0.90, 0.76), 23)


func _seventh_record_should_show() -> bool:
	var seventh := _seventh_view()
	return bool(_settlement_view.get("available", true)) \
		and bool(seventh.get("visible", false)) \
		and bool(seventh.get("relic_visible", false))


func _reconcile_seventh_road_record() -> void:
	if _seventh_record_should_show():
		_build_seventh_road_record()
		return
	if not _seventh_built:
		return
	for node_name in ["SeventhRoadRecord", "AlphaFangPlaque", "AlphaFangRecord",
			"FangRootRune", "SeventhRoadRecordLabel"]:
		var node := get_node_or_null(node_name)
		if node != null:
			node.queue_free()
	_seventh_built = false


func _build_seventh_road_record() -> void:
	if _seventh_built or not _seventh_record_should_show():
		return
	_seventh_built = true
	var record := Node3D.new()
	record.name = "SeventhRoadRecord"
	add_child(record)
	_add_box("AlphaFangPlaque", Vector3(0.10, 0.70, 0.82),
		Vector3(0.15, 1.14, -1.48), Color(0.31, 0.29, 0.27))
	var fang := MeshInstance3D.new()
	fang.name = "AlphaFangRecord"
	var fang_mesh := CylinderMesh.new()
	fang_mesh.top_radius = 0.025
	fang_mesh.bottom_radius = 0.11
	fang_mesh.height = 0.48
	fang_mesh.radial_segments = 8
	fang.mesh = fang_mesh
	fang.rotation.z = PI * 0.5
	fang.position = Vector3(0.06, 1.25, -1.48)
	var ivory := StandardMaterial3D.new()
	ivory.albedo_color = Color(0.78, 0.82, 0.80)
	ivory.roughness = 0.82
	fang.material_override = ivory
	add_child(fang)
	var rune := MeshInstance3D.new()
	rune.name = "FangRootRune"
	var rune_mesh := CylinderMesh.new()
	rune_mesh.top_radius = 0.18
	rune_mesh.bottom_radius = 0.18
	rune_mesh.height = 0.07
	rune_mesh.radial_segments = 10
	rune.mesh = rune_mesh
	rune.rotation.z = PI * 0.5
	rune.position = Vector3(0.02, 1.61, -1.48)
	var rune_mat := StandardMaterial3D.new()
	rune_mat.albedo_color = Color(0.58, 0.78, 0.88)
	rune_mat.emission_enabled = true
	rune_mat.emission = Color(0.28, 0.55, 0.68)
	rune_mat.emission_energy_multiplier = 0.75
	rune_mat.roughness = 0.66
	rune.material_override = rune_mat
	add_child(rune)
	_add_label("SeventhRoadRecordLabel", "Fang Root · Alpha",
		Vector3(0.18, 0.67, -1.48), Color(0.70, 0.86, 0.94), 22)


func _queen_record_should_show() -> bool:
	var queen := _queen_view()
	return bool(_settlement_view.get("available", true)) \
		and bool(queen.get("visible", false)) \
		and bool(queen.get("relic_visible", false)) \
		and bool(queen.get("restoration_visible", false))


func _reconcile_queens_summit_record() -> void:
	if _queen_record_should_show():
		_build_queens_summit_record()
		return
	if not _queen_built:
		return
	for node_name in ["QueensSummitRecord", "OathNailPlaque", "OathNailRecord",
			"CrownRootRune", "QueensSummitRecordLabel"]:
		var node := get_node_or_null(node_name)
		if node != null:
			node.queue_free()
	_queen_built = false


func _build_queens_summit_record() -> void:
	if _queen_built or not _queen_record_should_show():
		return
	_queen_built = true
	var record := Node3D.new()
	record.name = "QueensSummitRecord"
	add_child(record)
	_add_box("OathNailPlaque", Vector3(0.10, 0.70, 0.82),
		Vector3(0.15, 1.14, 2.48), Color(0.25, 0.29, 0.36))
	# The Oath Nail is deliberately fixed into a plaque: the Hall shows a
	# remembered covenant, not a second Story Seal that a player could claim.
	var nail := MeshInstance3D.new()
	nail.name = "OathNailRecord"
	var nail_mesh := CylinderMesh.new()
	nail_mesh.top_radius = 0.035
	nail_mesh.bottom_radius = 0.085
	nail_mesh.height = 0.52
	nail_mesh.radial_segments = 7
	nail.mesh = nail_mesh
	nail.rotation.z = PI * 0.5
	nail.position = Vector3(0.06, 1.26, 2.48)
	var nail_mat := StandardMaterial3D.new()
	nail_mat.albedo_color = Color(0.70, 0.78, 0.88)
	nail_mat.roughness = 0.75
	nail_mat.emission_enabled = true
	nail_mat.emission = Color(0.34, 0.50, 0.76)
	nail_mat.emission_energy_multiplier = 0.38
	nail.material_override = nail_mat
	add_child(nail)
	var rune := MeshInstance3D.new()
	rune.name = "CrownRootRune"
	var rune_mesh := CylinderMesh.new()
	rune_mesh.top_radius = 0.19
	rune_mesh.bottom_radius = 0.19
	rune_mesh.height = 0.07
	rune_mesh.radial_segments = 12
	rune.mesh = rune_mesh
	rune.rotation.z = PI * 0.5
	rune.position = Vector3(0.02, 1.62, 2.48)
	var rune_mat := StandardMaterial3D.new()
	rune_mat.albedo_color = Color(0.78, 0.72, 0.94)
	rune_mat.emission_enabled = true
	rune_mat.emission = Color(0.54, 0.38, 0.82)
	rune_mat.emission_energy_multiplier = 0.72
	rune_mat.roughness = 0.66
	rune.material_override = rune_mat
	add_child(rune)
	_add_label("QueensSummitRecordLabel", "Crown Root · Oath Nail",
		Vector3(0.18, 0.67, 2.48), Color(0.82, 0.76, 0.96), 22)


func _pale_oath_record_should_show() -> bool:
	var pale := _pale_oath_view()
	# One `rootroad_lift` truth owns this whole display.  Do not make a second
	# restored-Hod flag out of the oath-stone or allow a loose Starheart Coal to
	# counterfeit a canonical Barrow settlement.
	return bool(_settlement_view.get("available", true)) \
		and bool(pale.get("visible", false)) \
		and bool(pale.get("relic_visible", false)) \
		and bool(pale.get("restoration_visible", false)) \
		and String(pale.get("restoration_id", "")) == "rootroad_lift"


func _reconcile_pale_oath_record() -> void:
	if _pale_oath_record_should_show():
		_build_pale_oath_record()
		return
	if not _pale_oath_built:
		return
	for node_name in ["PaleOathRecord", "StarheartCoalPlaque", "StarheartCoalRecord",
			"PaleRootRune", "PastThreadRecord", "PaleOathRecordLabel"]:
		var node := get_node_or_null(node_name)
		if node != null:
			node.queue_free()
	_pale_oath_built = false


func _build_pale_oath_record() -> void:
	if _pale_oath_built or not _pale_oath_record_should_show():
		return
	_pale_oath_built = true
	var record := Node3D.new()
	record.name = "PaleOathRecord"
	add_child(record)
	_add_box("StarheartCoalPlaque", Vector3(0.10, 0.70, 0.82),
		Vector3(0.15, 1.14, -2.48), Color(0.20, 0.16, 0.18))
	var coal := MeshInstance3D.new()
	coal.name = "StarheartCoalRecord"
	var coal_mesh := SphereMesh.new()
	coal_mesh.radius = 0.15
	coal_mesh.height = 0.26
	coal.mesh = coal_mesh
	coal.position = Vector3(0.07, 1.30, -2.48)
	var coal_mat := StandardMaterial3D.new()
	coal_mat.albedo_color = Color(0.22, 0.18, 0.25)
	coal_mat.emission_enabled = true
	coal_mat.emission = Color(0.78, 0.40, 0.18)
	coal_mat.emission_energy_multiplier = 0.85
	coal_mat.roughness = 0.78
	coal.material_override = coal_mat
	add_child(coal)
	var rune := MeshInstance3D.new()
	rune.name = "PaleRootRune"
	var rune_mesh := CylinderMesh.new()
	rune_mesh.top_radius = 0.18
	rune_mesh.bottom_radius = 0.18
	rune_mesh.height = 0.07
	rune_mesh.radial_segments = 12
	rune.mesh = rune_mesh
	rune.rotation.z = PI * 0.5
	rune.position = Vector3(0.02, 1.61, -2.48)
	var rune_mat := StandardMaterial3D.new()
	rune_mat.albedo_color = Color(0.80, 0.76, 0.94)
	rune_mat.emission_enabled = true
	rune_mat.emission = Color(0.53, 0.42, 0.82)
	rune_mat.emission_energy_multiplier = 0.72
	rune_mat.roughness = 0.66
	rune.material_override = rune_mat
	add_child(rune)
	_add_box("PastThreadRecord", Vector3(0.12, 0.12, 0.46),
		Vector3(0.04, 1.04, -2.48), Color(0.72, 0.64, 0.90),
		Vector3(0.0, 0.0, 0.34))
	_add_label("PaleOathRecordLabel", "Pale Root · Past Thread · Starheart",
		Vector3(0.18, 0.67, -2.48), Color(0.88, 0.78, 0.96), 19)


func _add_box(node_name: String, size: Vector3, pos: Vector3, color: Color,
		rotation := Vector3.ZERO) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = pos
	instance.rotation = rotation
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	instance.material_override = mat
	add_child(instance)


func _add_label(node_name: String, text: String, pos: Vector3, color: Color,
		font_size: int) -> void:
	var label := Label3D.new()
	label.name = node_name
	label.text = text
	label.position = pos
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = color
	label.font_size = font_size
	label.pixel_size = 0.004
	label.outline_size = 10
	label.outline_modulate = Color(0.08, 0.06, 0.04, 0.9)
	var font := WyrdUi.font_header()
	if font != null:
		label.font = font
	add_child(label)


func interact(_player: Node) -> void:
	if _dialog_open:
		return
	_dialog_open = true
	var dialog: CanvasLayer = DialogPanelScript.new()
	dialog.name = "TrophyHallInspectDialog"
	dialog.add_to_group("TrophyHallInspectDialog")
	var pages := [
		"A green root-mark keeps its quiet place beside the Tusker record. "
		+ "The old bow-rest is covered against the weather.",
		"There is nothing to take. The yard has only made room to remember.",
	]
	if _golden_built:
		pages.append("Mist Root glows beside the Wightpelt account. Beyond the yard, "
			+ "the restored Sallow Jetty has begun to take Mire Charts again.")
	if _queen_built:
		pages.append("Crown Root and the Oath Nail are set behind the last plaque. "
			+ "Nothing is waiting here to be taken; the Pale Stair has only been found.")
	if _pale_oath_built:
		pages.append("Pale Root, a Past Thread, and Starheart Coal are kept together. "
			+ "The coal is a record for the road ahead, not a thing to take.")
	dialog.open("The Trophy Hall", pages)
	dialog.finished.connect(func() -> void: _dialog_open = false)
	var scene := get_tree().current_scene
	if scene != null:
		scene.add_child(dialog)
