class_name CampaignClue
extends Interactable

# Slice D1 — a short, authored campaign clue placed by DungeonGen's dedicated
# `campaign_clues` channel. It intentionally never calls Second Hand APIs:
# campaign facts belong to Game/CampaignData, while marginal marks remain
# optional atmosphere. Reading this prop is deliberately copy-only: successful
# non-abandoned return banks the bounded clue, not this dialog.

const DialogPanelScript = preload("res://scripts/ui/dialog_panel.gd")
const ChartsData = preload("res://data/charts.gd")

var clue_id := ""
var presentation := "thorn_whisper"
var chapter_id := ""
var clue_title := ""
var clue_pages: Array = []
var _dialog_open := false


func setup(record: Dictionary) -> void:
	clue_id = String(record.get("id", ""))
	presentation = String(record.get("presentation", "thorn_whisper"))
	chapter_id = String(record.get("chapter_id", ""))
	var authored := _authored_record()
	if authored is Dictionary and not (authored as Dictionary).is_empty():
		clue_title = String((authored as Dictionary).get("title", ""))
		clue_pages = ((authored as Dictionary).get("pages", []) as Array).duplicate()


func _authored_record() -> Dictionary:
	# Presentation records belong to their Chart-data family, never to the
	# physical Table component they might resemble.  That keeps a read-only
	# Crown-Thorn from being mistaken for an inventory item or campaign reward.
	if presentation == "cold_track_clue":
		return (ChartsData.SEVENTH_ROAD_COLD_TRACK_PRESENTATIONS.get(clue_id, {}) as Dictionary)
	if presentation == "shed_crown_thorn":
		return (ChartsData.QUEENS_SUMMIT_SHED_CROWN_THORN_PRESENTATIONS.get(clue_id, {}) as Dictionary)
	if presentation == "lost_waymark":
		return (ChartsData.UNWRITTEN_LOST_WAYMARK_PRESENTATIONS.get(clue_id, {}) as Dictionary)
	return {}


func get_prompt_text() -> String:
	if presentation == "cold_track_clue":
		return "[E/A] Study the cold track"
	if presentation == "shed_crown_thorn":
		return "[E/A] Study the shed crown-thorn"
	if presentation == "lost_waymark":
		return "[E/A] Read the lost Waymark"
	return "[E/A] Read the thorn whisper"


func get_prompt_color() -> Color:
	if presentation == "cold_track_clue":
		return Color(0.64, 0.83, 0.92)
	if presentation == "shed_crown_thorn":
		return Color(0.78, 0.87, 1.0)
	if presentation == "lost_waymark":
		return Color(0.88, 0.76, 0.45)
	return Color(0.88, 0.63, 0.31)


func get_collision_radius() -> float:
	return 1.0


func get_collision_offset() -> Vector3:
	return Vector3(0.0, 0.15, 0.0)


func get_prompt_position() -> Vector3:
	return Vector3(0.0, 0.72, 0.0)


func get_solid_radius() -> float:
	return 0.0


func _ready_interactable() -> void:
	add_to_group("campaign_clue")
	add_to_group("campaign_clue_%s" % clue_id)
	if presentation == "cold_track_clue":
		_build_cold_track()
		return
	if presentation == "shed_crown_thorn":
		_build_shed_crown_thorn()
		return
	if presentation == "lost_waymark":
		add_to_group("lost_waymark_clue")
		_build_lost_waymark()
		return
	var page := MeshInstance3D.new()
	page.name = "ThornWhisperPage"
	var page_mesh := BoxMesh.new()
	page_mesh.size = Vector3(0.86, 0.035, 0.62)
	page.mesh = page_mesh
	page.position.y = 0.03
	var paper := StandardMaterial3D.new()
	paper.albedo_color = Color(0.76, 0.63, 0.42)
	paper.roughness = 1.0
	paper.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	page.material_override = paper
	add_child(page)
	# Three thorn-like ink strokes make the object readable before a player is
	# close enough to read its label, without requiring a new art asset.
	for stroke in [
		{"p": Vector3(-0.20, 0.055, -0.11), "s": Vector3(0.46, 0.014, 0.027), "r": -0.25},
		{"p": Vector3(-0.06, 0.056, 0.02), "s": Vector3(0.39, 0.014, 0.027), "r": 0.16},
		{"p": Vector3(0.05, 0.057, 0.15), "s": Vector3(0.43, 0.014, 0.027), "r": -0.42},
	]:
		_add_thorn_stroke(stroke.p, stroke.s, float(stroke.r))


func _build_cold_track() -> void:
	# The clue is a small roadside patch whose seventh print leaves the written
	# road. It reads at play-camera distance without turning ledger evidence into
	# a collectible or relying on the physical `cold_track` Table component.
	var bed := MeshInstance3D.new()
	bed.name = "ColdTrackBed"
	var bed_mesh := CylinderMesh.new()
	bed_mesh.top_radius = 0.72
	bed_mesh.bottom_radius = 0.78
	bed_mesh.height = 0.05
	bed_mesh.radial_segments = 12
	bed.mesh = bed_mesh
	bed.position.y = 0.025
	var bed_mat := StandardMaterial3D.new()
	bed_mat.albedo_color = Color(0.36, 0.43, 0.44)
	bed_mat.roughness = 1.0
	bed_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	bed.material_override = bed_mat
	add_child(bed)
	for index in 7:
		var print := MeshInstance3D.new()
		print.name = "ColdTrackPrint%d" % (index + 1)
		var print_mesh := SphereMesh.new()
		print_mesh.radius = 0.09 if index < 6 else 0.12
		print_mesh.height = 0.045
		print.mesh = print_mesh
		var side := -1.0 if index % 2 == 0 else 1.0
		var drift := 0.0 if index < 6 else 0.28
		print.position = Vector3(side * (0.15 + drift), 0.062,
			-0.45 + float(index) * 0.15)
		var frost := StandardMaterial3D.new()
		frost.albedo_color = Color(0.64, 0.82, 0.87) if index < 6 \
			else Color(0.80, 0.94, 0.96)
		frost.emission_enabled = index == 6
		frost.emission = Color(0.34, 0.66, 0.72)
		frost.emission_energy_multiplier = 0.65
		frost.roughness = 0.75
		print.material_override = frost
		add_child(print)


func _build_shed_crown_thorn() -> void:
	# The Summit clue is a little piece of frozen thorn-crown caught in old
	# snow.  It is deliberately scenery only: the four authoritative returns,
	# rather than interacting with this prop, bank the Crown-Thorn ledger.
	var snow := MeshInstance3D.new()
	snow.name = "ShedCrownThornSnow"
	var snow_mesh := CylinderMesh.new()
	snow_mesh.top_radius = 0.68
	snow_mesh.bottom_radius = 0.76
	snow_mesh.height = 0.08
	snow_mesh.radial_segments = 10
	snow.mesh = snow_mesh
	snow.position.y = 0.04
	var snow_mat := StandardMaterial3D.new()
	snow_mat.albedo_color = Color(0.74, 0.83, 0.92)
	snow_mat.roughness = 0.94
	snow_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	snow.material_override = snow_mat
	add_child(snow)
	for index in 5:
		var thorn := MeshInstance3D.new()
		thorn.name = "ShedCrownThorn%d" % (index + 1)
		var thorn_mesh := CylinderMesh.new()
		thorn_mesh.top_radius = 0.022
		thorn_mesh.bottom_radius = 0.075
		thorn_mesh.height = 0.46 + 0.04 * float(index % 2)
		thorn_mesh.radial_segments = 6
		thorn.mesh = thorn_mesh
		var angle := -0.85 + 0.42 * float(index)
		thorn.position = Vector3(0.38 * sin(angle), 0.24,
			0.18 * cos(angle))
		thorn.rotation.z = angle * 0.72
		var frost := StandardMaterial3D.new()
		frost.albedo_color = Color(0.30, 0.39, 0.50) if index < 4 else Color(0.62, 0.79, 1.0)
		frost.roughness = 0.76
		frost.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		frost.emission_enabled = index == 4
		frost.emission = Color(0.32, 0.64, 1.0)
		frost.emission_energy_multiplier = 0.7
		thorn.material_override = frost
		add_child(thorn)


func _build_lost_waymark() -> void:
	# A route scored into dark rootwood, with a deliberate gap and one loose,
	# luminous final segment. It is a readable copy in the world—not loot.
	var bed := MeshInstance3D.new()
	bed.name = "LostWaymarkBed"
	var bed_mesh := CylinderMesh.new()
	bed_mesh.top_radius = 0.74
	bed_mesh.bottom_radius = 0.81
	bed_mesh.height = 0.07
	bed_mesh.radial_segments = 10
	bed.mesh = bed_mesh
	bed.position.y = 0.035
	var bed_mat := StandardMaterial3D.new()
	bed_mat.albedo_color = Color(0.25, 0.15, 0.08)
	bed_mat.roughness = 0.96
	bed_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	bed.material_override = bed_mat
	add_child(bed)
	var segments := [
		{"p": Vector3(-0.38, 0.078, -0.23), "r": -0.18},
		{"p": Vector3(-0.13, 0.079, -0.09), "r": 0.44},
		{"p": Vector3(0.05, 0.080, 0.10), "r": 0.86},
	]
	for index in segments.size():
		var segment: Dictionary = segments[index]
		_add_waymark_segment("LostWaymarkLine%d" % (index + 1),
			segment.p, float(segment.r), false)
	# The empty span between line three and this loose stroke is the road's
	# unanswered turn; the glow keeps it legible at the play camera distance.
	_add_waymark_segment("LostWaymarkLooseLine", Vector3(0.39, 0.086, 0.31),
		1.08, true)


func _add_waymark_segment(node_name: String, pos: Vector3, yaw: float,
		loose: bool) -> void:
	var line := MeshInstance3D.new()
	line.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.34 if not loose else 0.29, 0.018, 0.055)
	line.mesh = mesh
	line.position = pos
	line.rotation.y = yaw
	var ink := StandardMaterial3D.new()
	ink.albedo_color = Color(0.73, 0.62, 0.34) if not loose \
		else Color(1.0, 0.79, 0.34)
	ink.roughness = 0.82
	ink.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	ink.emission_enabled = loose
	ink.emission = Color(0.90, 0.58, 0.14)
	ink.emission_energy_multiplier = 0.75
	line.material_override = ink
	add_child(line)


func _add_thorn_stroke(pos: Vector3, size: Vector3, yaw: float) -> void:
	var stroke := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	stroke.mesh = mesh
	stroke.position = pos
	stroke.rotation.y = yaw
	var ink := StandardMaterial3D.new()
	ink.albedo_color = Color(0.30, 0.10, 0.08)
	ink.roughness = 1.0
	stroke.material_override = ink
	add_child(stroke)


func interact(_player: Node) -> void:
	if _dialog_open or clue_id == "":
		return
	_dialog_open = true
	var dialog := DialogPanelScript.new()
	dialog.name = "CampaignClueDialog"
	dialog.add_to_group("CampaignClueDialog")
	var fallback := "A Cold Track" if presentation == "cold_track_clue" \
		else "A Shed Crown-Thorn" if presentation == "shed_crown_thorn" \
		else "A Lost Waymark" if presentation == "lost_waymark" else "A Thorn Whisper"
	dialog.open(clue_title if clue_title != "" else fallback, _pages())
	dialog.finished.connect(func() -> void:
		_dialog_open = false
		read_now())
	get_tree().current_scene.add_child(dialog)


# Public test/accessibility seam. This is intentionally inert; the campaign
# ledger advances on a successful return, so a player can never
# lose progression by overlooking a side-room prop or duplicate it by rereads.
func read_now() -> Dictionary:
	return {"ok": clue_id != "", "changed": false, "clue_id": clue_id}


func _pages() -> Array:
	if not clue_pages.is_empty():
		return clue_pages.duplicate()
	if presentation == "cold_track_clue":
		return [
			"Six prints keep to the road. The seventh steps where no road is drawn.",
			"The cold has not covered the track. It has kept it for someone.",
		]
	if presentation == "shed_crown_thorn":
		return [
			"A thorn of ice has shed from a crown too heavy for any living head.",
			"Its point leans uphill. The snow remembers the way even when the road does not.",
		]
	if presentation == "lost_waymark":
		return [
			"A pale mark waits beneath the root, its line still open.",
			"The Loom remembers the road without taking it from you.",
		]
	return [
		"Three thorn strokes point toward the hollow's old heart.",
		"The bramble remembers a name it has not said aloud.",
	]
