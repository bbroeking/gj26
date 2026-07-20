class_name SkaldArchive
extends Interactable

# Seventh Road's first-stage Archive is deliberately one physical verb: review
# the authored saga record and, for the host, read the Summit handoff at the
# same transaction seam used by every other Chart source. Campaign truth is
# injected as a read-only projection; this node never repairs or saves it.

const DialogPanelScript = preload("res://scripts/ui/dialog_panel.gd")
const SUMMIT_SOURCE_ID := "skald_queens_summit"
const PALE_OATH_SOURCE_ID := "skald_pale_oath"
const PALE_OATH_BOSS_SOURCE_ID := "skald_pale_oath_boss"

var _chapter_view: Dictionary = {}
var _queen_view: Dictionary = {}
var _pale_view: Dictionary = {}
var _folio_view: Dictionary = {}
var _settlement_snapshot_available := true
var _read_only := false
var _dialog_open := false
var _built := false


func set_settlement_view(view: Dictionary) -> void:
	_settlement_snapshot_available = bool(view.get("available", true))
	var chapters = view.get("chapters", {})
	var raw = (chapters as Dictionary).get("seventh_road", {}) \
		if chapters is Dictionary else view.get("seventh_road", {})
	_chapter_view = (raw as Dictionary).duplicate(true) if raw is Dictionary else {}
	var queen_raw = (chapters as Dictionary).get("queens_summit", {}) \
		if chapters is Dictionary else view.get("queens_summit", {})
	_queen_view = (queen_raw as Dictionary).duplicate(true) if queen_raw is Dictionary else {}
	var pale_raw = (chapters as Dictionary).get("pale_oath", {}) \
		if chapters is Dictionary else view.get("pale_oath", {})
	_pale_view = (pale_raw as Dictionary).duplicate(true) if pale_raw is Dictionary else {}
	var folios = view.get("archive_folios", {})
	_folio_view = (folios as Dictionary).duplicate(true) if folios is Dictionary else {}
	_read_only = bool(view.get("read_only", false)) or bool(view.get("guest", false)) \
		or bool(_chapter_view.get("read_only", false))
	visible = bool(view.get("available", true)) \
		and bool(_chapter_view.get("visible", false)) \
		and bool(_chapter_view.get("restoration_visible", false))
	if is_node_ready() and visible and not _built:
		_build_archive()


func get_prompt_text() -> String:
	if pale_folio_visible():
		return "[E/A] Review the host's Pale Oath folio" if _read_only \
			else "[E/A] Read the Pale Oath folio"
	return "[E/A] Review the host's Skald Archive" if _read_only \
		else "[E/A] Review the Skald Archive"


func get_prompt_color() -> Color:
	return Color(0.76, 0.84, 0.94)


func get_collision_radius() -> float:
	return 1.75


func get_collision_offset() -> Vector3:
	return Vector3(0.0, 0.8, 0.0)


func get_prompt_position() -> Vector3:
	return Vector3(0.0, 2.6, 0.0)


func get_solid_radius() -> float:
	return 1.25


func get_solid_height() -> float:
	return 1.8


func _ready_interactable() -> void:
	add_to_group("skald_archive")
	if visible:
		_build_archive()


func _build_archive() -> void:
	if _built:
		return
	_built = true
	# A compact open shelf, story-stone, and sloped lectern make the verb
	# readable from the yard without introducing an interior scene or framework.
	_add_box("ArchiveBack", Vector3(0.24, 2.25, 3.15),
		Vector3(0.0, 1.12, 0.0), Color(0.20, 0.15, 0.11))
	for z in [-1.42, 1.42]:
		_add_box("ArchivePost", Vector3(0.30, 2.45, 0.30),
			Vector3(0.28, 1.22, z), Color(0.30, 0.20, 0.12))
	for y in [0.48, 1.05, 1.62]:
		_add_box("ArchiveShelf", Vector3(0.82, 0.13, 2.82),
			Vector3(0.34, y, 0.0), Color(0.38, 0.25, 0.14))
	for y in [0.70, 1.27, 1.84]:
		for z in [-1.0, -0.58, -0.14, 0.31, 0.76, 1.08]:
			_add_box("ArchiveFolio", Vector3(0.20, 0.34, 0.11),
				Vector3(0.79, y, z), Color(0.58, 0.50, 0.34))
	_add_box("ArchiveLectern", Vector3(0.82, 0.16, 1.05),
		Vector3(1.05, 1.05, 0.0), Color(0.46, 0.31, 0.17),
		Vector3(0.0, 0.0, -0.30))
	_add_box("ArchiveLecternLeg", Vector3(0.22, 1.22, 0.22),
		Vector3(0.78, 0.55, 0.0), Color(0.30, 0.20, 0.12))
	var rune := MeshInstance3D.new()
	rune.name = "FangRootRune"
	var rune_mesh := CylinderMesh.new()
	rune_mesh.top_radius = 0.23
	rune_mesh.bottom_radius = 0.23
	rune_mesh.height = 0.07
	rune_mesh.radial_segments = 10
	rune.mesh = rune_mesh
	rune.rotation.z = PI * 0.5
	rune.position = Vector3(0.73, 2.10, 0.0)
	var rune_mat := StandardMaterial3D.new()
	rune_mat.albedo_color = Color(0.58, 0.78, 0.88)
	rune_mat.emission_enabled = true
	rune_mat.emission = Color(0.28, 0.55, 0.68)
	rune_mat.emission_energy_multiplier = 0.7
	rune_mat.roughness = 0.7
	rune.material_override = rune_mat
	add_child(rune)


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


func interact(_player: Node) -> void:
	if _dialog_open or not visible:
		return
	_dialog_open = true
	var dialog: CanvasLayer = DialogPanelScript.new()
	dialog.name = "SkaldArchiveDialog"
	dialog.add_to_group("SkaldArchiveDialog")
	dialog.open("The Skald Archive", review_pages())
	dialog.finished.connect(func() -> void:
		_dialog_open = false
		read_now())
	get_tree().current_scene.add_child(dialog)


func review_pages() -> Array:
	var count := int(_chapter_view.get("clue_count", 4))
	var target := maxi(1, int(_chapter_view.get("clue_target", 4)))
	var pages := [
		"The First Knot and Golden Wallow are set down beside %d of %d Cold Tracks." \
			% [count, target],
		"Six roads are written. The seventh is waiting for someone to stop insisting it isn't there.",
		"A pale folio marks the climb beyond the Wolf's keeping.",
	]
	if queen_settlement_visible():
		pages.append("The crown has been shed. Crown Root is set, and the Pale Stair is found—"
			+ "a road named by the Oath, but not yet walked.")
	if pale_folio_visible():
		pages.append("A pale folio has opened beneath the stair: a wellmark above an Atlas "
			+ "folio, paired cords at either hand, and Stoneground Ink to hold the line.")
	if pale_boss_folio_visible():
		pages.append("Four Oath-Rubbings have settled. A second folio names the Barrow Mark, "
			+ "the Oath Nail, and the promise beneath the rootroads.")
	if pale_settlement_visible():
		pages.append("Pale Root is set. A Past Thread is kept in the Archive, and Starheart "
			+ "Coal waits without a hand upon it. The Rootroad Lift and Hod's oath-stone stand together.")
	return pages


func queen_settlement_visible() -> bool:
	return bool(_queen_view.get("visible", false)) \
		and bool(_queen_view.get("relic_visible", false)) \
		and bool(_queen_view.get("restoration_visible", false))


# Archive folios are a projection of the host's source availability, never a
# local guest source query.  The chapter fields only determine the fourth
# rubbing / settlement copy; source eligibility remains owned by Game.
func pale_folio_visible() -> bool:
	if not queen_settlement_visible():
		return false
	var folio := _folio("pale_oath")
	if not folio.is_empty():
		return bool(folio.get("visible", false))
	if _read_only:
		return false
	var status := _host_source_status(PALE_OATH_SOURCE_ID)
	return bool(status.get("valid", false)) and bool(status.get("unlocked", false)) \
		and int(status.get("level", 0)) >= int(status.get("min_wayfinding", 18))


func pale_boss_folio_visible() -> bool:
	if not pale_folio_visible() or int(_pale_view.get("clue_count", 0)) < 4:
		return false
	var folio := _folio("pale_oath_boss")
	if not folio.is_empty():
		# The fourth rubbing reveals the physical second folio even before its
		# Wayfinding 19 transaction is actionable.
		return bool(folio.get("revealed", folio.get("visible", false)))
	return true


func pale_settlement_visible() -> bool:
	return bool(_settlement_available()) and bool(_pale_view.get("visible", false)) \
		and bool(_pale_view.get("relic_visible", false)) \
		and bool(_pale_view.get("restoration_visible", false)) \
		and String(_pale_view.get("restoration_id", "")) == "rootroad_lift"


func pale_oath_presentation_ids() -> Dictionary:
	return {
		"folio_id": PALE_OATH_SOURCE_ID if pale_folio_visible() else "",
		"boss_folio_id": PALE_OATH_BOSS_SOURCE_ID if pale_boss_folio_visible() else "",
		"relic_id": String(_pale_view.get("relic_id", "")) if pale_settlement_visible() else "",
		"thread_record_id": "past_thread" if pale_settlement_visible() else "",
		"material_record_id": "starheart_coal" if pale_settlement_visible() else "",
	}


# The presentation and interaction paths must agree on which physical folio is
# actionable. This public query is also the narrow scanner contract used by the
# cumulative D7 route: touching the Archive cannot accidentally commit a
# neighbouring eligible source.
func active_source_id() -> String:
	if _read_only:
		return ""
	if pale_boss_folio_visible():
		var boss_status := _host_source_status(PALE_OATH_BOSS_SOURCE_ID)
		if String(boss_status.get("state", "")) == "eligible":
			return PALE_OATH_BOSS_SOURCE_ID
	if pale_folio_visible():
		var pale_status := _host_source_status(PALE_OATH_SOURCE_ID)
		if String(pale_status.get("state", "")) == "eligible":
			return PALE_OATH_SOURCE_ID
	if queen_settlement_visible():
		return ""
	return SUMMIT_SOURCE_ID


func _folio(id: String) -> Dictionary:
	var raw = _folio_view.get(id, {})
	return raw as Dictionary if raw is Dictionary else {}


func _settlement_available() -> bool:
	return _settlement_snapshot_available


func _host_source_status(source_id: String) -> Dictionary:
	if _read_only:
		return {}
	var game := _game()
	if game == null or not game.has_method("chart_source_status"):
		return {}
	var raw = game.chart_source_status(source_id)
	return raw as Dictionary if raw is Dictionary else {}


# Public test/accessibility seam. Guests always receive copy only. Hosts use
# the existing atomic source transaction, which owns level gates, missing-only
# lesson supplies, signals, toast, and save.
func read_now() -> Dictionary:
	if _read_only:
		return {"ok": true, "changed": false, "read_only": true}
	var game := _game()
	if game == null or not game.has_method("read_chart_source"):
		return {"ok": false, "changed": false}
	# Queen's post-settlement page remains copy-only until the canonical source
	# reports its own Wayfinding-18 eligibility.  No presenter gate is allowed
	# to infer access from a loose Nail or a Pale Stair mesh.
	var source_id := active_source_id()
	if source_id != "":
		return game.read_chart_source(source_id)
	if pale_folio_visible():
		return {"ok": true, "changed": false, "post_queen": true,
			"source_id": PALE_OATH_SOURCE_ID}
	if queen_settlement_visible():
		return {"ok": true, "changed": false, "post_queen": true}
	return game.read_chart_source(SUMMIT_SOURCE_ID)


func _game() -> Node:
	return get_tree().root.get_node_or_null("Game") if is_inside_tree() else null
