class_name LivingAtlasPanel
extends Interactable

# Slice C2 — the tower-wall Living Atlas is a real, rereadable world source.
# Game owns every unlock, rumour, component, signal, toast, and save decision;
# this adapter owns only the parchment, anticipation/read copy, and dialog timing.

const DialogPanelScript = preload("res://scripts/ui/dialog_panel.gd")
const SOURCE_ID := "atlas_deep_hollow"
const WET_ROAD_SOURCE_ID := "atlas_sallow_shallows"
const BRIAR_ROAD_SOURCE_ID := "atlas_briar_knot"
const VALID_STATES := ["locked", "eligible", "read", "resolved"]

var _paper: MeshInstance3D
var _paper_material: StandardMaterial3D
var _dialog_open := false
var _status: Dictionary = {}
var _game_ref: Node = null
var _homecoming_view: Dictionary = {}
var _wet_road: Node3D = null
var _settlement_view: Dictionary = {}
var _golden_mark: Node3D = null
var _seventh_mark: Node3D = null
var _queen_mark: Node3D = null
var _pale_oath_mark: Node3D = null
var _unwritten_road_mark: Node3D = null


func get_prompt_text() -> String:
	match String(source_status().get("state", "invalid")):
		"eligible":
			match active_source_id():
				WET_ROAD_SOURCE_ID: return "[E/A] Read the wet-road Atlas mark"
				BRIAR_ROAD_SOURCE_ID: return "[E/A] Read the thorn-road Atlas mark"
				_: return "[E/A] Read the faded Atlas panel"
		"read":
			match active_source_id():
				WET_ROAD_SOURCE_ID: return "[E/A] Re-read the wet-road mark"
				BRIAR_ROAD_SOURCE_ID: return "[E/A] Re-read the thorn-road mark"
				_: return "[E/A] Re-read the faded Atlas panel"
		"resolved": return "[E/A] Read the Living Atlas"
		_: return "[E/A] Read the quiet Living Atlas"


func get_prompt_color() -> Color:
	return Color(0.95, 0.85, 0.60)


func get_collision_radius() -> float:
	return 1.35


func get_collision_offset() -> Vector3:
	return Vector3(0.0, 0.0, 0.0)


func get_prompt_position() -> Vector3:
	return Vector3(0.0, 0.72, 0.0)


func get_solid_radius() -> float:
	return 0.0


# Before the first Tier 1 completion the parchment is town dressing only. Once
# Game unlocks the source it becomes readable forever, including resolved copy.
func is_used() -> bool:
	var status := source_status()
	return not bool(status.valid) or not bool(status.unlocked)


func _ready_interactable() -> void:
	add_to_group("chart_rumour_source")
	add_to_group("living_atlas_panel")
	_paper = MeshInstance3D.new()
	_paper.name = "AtlasBoardVisual"
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.8, 0.6)
	_paper.mesh = mesh
	_paper.rotation.x = -0.12
	_paper_material = StandardMaterial3D.new()
	_paper_material.albedo_color = Color(0.88, 0.82, 0.65)
	_paper_material.roughness = 0.9
	_paper_material.emission_enabled = true
	_paper_material.emission = Color(0.9, 0.85, 0.6)
	_paper_material.emission_energy_multiplier = 0.0
	_paper.material_override = _paper_material
	add_child(_paper)
	_game_ref = _game()
	if _game_ref != null and _game_ref.has_signal("chart_knowledge_changed"):
		_game_ref.chart_knowledge_changed.connect(refresh_source_state)
	refresh_source_state()
	_apply_homecoming_handoff()
	_apply_golden_settlement_mark()
	_apply_seventh_road_mark()
	_apply_queens_summit_mark()
	_apply_pale_oath_mark()
	_apply_unwritten_road_mark()


# Homecoming's road mark is a pure visual overlay. Town provides the same
# authoritative projection it gives the Trophy Hall; the Atlas never reads
# campaign state to decide whether Sallow should be named.
func set_homecoming_view(view: Dictionary) -> void:
	_homecoming_view = view.duplicate(true)
	if is_node_ready():
		_apply_homecoming_handoff()


func set_settlement_view(view: Dictionary) -> void:
	_settlement_view = view.duplicate(true)
	if is_node_ready():
		_apply_golden_settlement_mark()
		_apply_seventh_road_mark()
		_apply_queens_summit_mark()
		_apply_pale_oath_mark()
		_apply_unwritten_road_mark()
		refresh_source_state()


func homecoming_handoff_visible() -> bool:
	return bool(_homecoming_view.get("atlas_handoff_visible", false))


func golden_settlement_visible() -> bool:
	var chapters = _settlement_view.get("chapters", {})
	var golden = (chapters as Dictionary).get("golden_wallow", {}) \
		if chapters is Dictionary else _settlement_view.get("golden_wallow", {})
	return bool(_settlement_view.get("available", true)) and golden is Dictionary \
		and bool((golden as Dictionary).get("visible", false))


func seventh_road_settlement_visible() -> bool:
	var chapters = _settlement_view.get("chapters", {})
	var seventh = (chapters as Dictionary).get("seventh_road", {}) \
		if chapters is Dictionary else _settlement_view.get("seventh_road", {})
	return bool(_settlement_view.get("available", true)) and seventh is Dictionary \
		and bool((seventh as Dictionary).get("visible", false))


func queens_summit_settlement_visible() -> bool:
	var chapters = _settlement_view.get("chapters", {})
	var queen = (chapters as Dictionary).get("queens_summit", {}) \
		if chapters is Dictionary else _settlement_view.get("queens_summit", {})
	return bool(_settlement_view.get("available", true)) and queen is Dictionary \
		and bool((queen as Dictionary).get("visible", false)) \
		and bool((queen as Dictionary).get("relic_visible", false)) \
		and bool((queen as Dictionary).get("restoration_visible", false))


func pale_oath_settlement_visible() -> bool:
	var chapters = _settlement_view.get("chapters", {})
	var pale = (chapters as Dictionary).get("pale_oath", {}) \
		if chapters is Dictionary else _settlement_view.get("pale_oath", {})
	return bool(_settlement_view.get("available", true)) and pale is Dictionary \
		and bool((pale as Dictionary).get("visible", false)) \
		and bool((pale as Dictionary).get("relic_visible", false)) \
		and bool((pale as Dictionary).get("restoration_visible", false)) \
		and String((pale as Dictionary).get("restoration_id", "")) == "rootroad_lift"


# D8's Road mark is deliberately derived from one neutral projection only.
# CampaignData will expose `source_visible` after canonical Fire settlement;
# this presenter never reads Fire, a local save, a source unlock, or a Loom
# ritual to reconstruct that fact. Once visible, the same mark honestly shows
# the ledger's 0/5 through 5/5 progress without mutating it.
func unwritten_road_settlement_visible() -> bool:
	var chapters = _settlement_view.get("chapters", {})
	var road = (chapters as Dictionary).get("unwritten_road", {}) \
		if chapters is Dictionary else _settlement_view.get("unwritten_road", {})
	return bool(_settlement_view.get("available", true)) and road is Dictionary \
		and bool((road as Dictionary).get("source_visible", false))


func unwritten_road_progress() -> Dictionary:
	var chapters = _settlement_view.get("chapters", {})
	var road = (chapters as Dictionary).get("unwritten_road", {}) \
		if chapters is Dictionary else _settlement_view.get("unwritten_road", {})
	if not road is Dictionary:
		return {"visible": false, "clue_count": 0, "clue_target": 5}
	return {"visible": unwritten_road_settlement_visible(),
		"clue_count": clampi(int((road as Dictionary).get("clue_count", 0)), 0,
			maxi(1, int((road as Dictionary).get("clue_target", 5)))),
		"clue_target": maxi(1, int((road as Dictionary).get("clue_target", 5)))}


func _apply_homecoming_handoff() -> void:
	if _wet_road != null and is_instance_valid(_wet_road):
		_wet_road.queue_free()
		_wet_road = null
	if not homecoming_handoff_visible():
		return
	_wet_road = Node3D.new()
	_wet_road.name = "SallowWetRoadHandoff"
	var road := MeshInstance3D.new()
	road.name = "WetRoadMark"
	var road_mesh := QuadMesh.new()
	road_mesh.size = Vector2(0.64, 0.13)
	road.mesh = road_mesh
	# Keep the new road on the parchment itself. The earlier below-board mark
	# read like a caption attached to the tower rather than a changed Atlas.
	road.position = Vector3(0.0, -0.08, 0.012)
	var road_mat := StandardMaterial3D.new()
	road_mat.albedo_color = Color(0.20, 0.38, 0.34)
	road_mat.roughness = 0.95
	road_mat.emission_enabled = true
	road_mat.emission = Color(0.10, 0.28, 0.25)
	road_mat.emission_energy_multiplier = 0.25
	road.material_override = road_mat
	_wet_road.add_child(road)
	var label := Label3D.new()
	label.name = "SallowHandoffLabel"
	label.text = "WET ROAD  →  SALLOW SHALLOWS"
	label.position = Vector3(0.0, -0.20, 0.016)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = Color(0.70, 0.88, 0.80)
	label.font_size = 25
	label.pixel_size = 0.0035
	label.outline_size = 8
	label.outline_modulate = Color(0.06, 0.08, 0.07, 0.95)
	var font := WyrdUi.font_header()
	if font != null:
		label.font = font
	_wet_road.add_child(label)
	add_child(_wet_road)


func _apply_golden_settlement_mark() -> void:
	if _golden_mark != null and is_instance_valid(_golden_mark):
		_golden_mark.queue_free()
		_golden_mark = null
	if not golden_settlement_visible():
		return
	_golden_mark = Node3D.new()
	_golden_mark.name = "GoldenWallowAtlasMark"
	var label := Label3D.new()
	label.name = "JettyRelitLabel"
	label.text = "MIST ROOT SET  ·  JETTY RELIT"
	label.position = Vector3(0.0, 0.17, 0.018)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = Color(0.48, 0.92, 0.73)
	label.font_size = 23
	label.pixel_size = 0.0034
	label.outline_size = 8
	label.outline_modulate = Color(0.04, 0.08, 0.07, 0.95)
	var font := WyrdUi.font_header()
	if font != null:
		label.font = font
	_golden_mark.add_child(label)
	add_child(_golden_mark)


func _apply_seventh_road_mark() -> void:
	if _seventh_mark != null and is_instance_valid(_seventh_mark):
		_seventh_mark.queue_free()
		_seventh_mark = null
	if not seventh_road_settlement_visible():
		return
	_seventh_mark = Node3D.new()
	_seventh_mark.name = "SeventhRoadAtlasMark"
	var line := MeshInstance3D.new()
	line.name = "PaleSeventhLine"
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.52, 0.055)
	line.mesh = mesh
	line.position = Vector3(0.0, 0.04, 0.019)
	line.rotation.z = -0.16
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.48, 0.72, 0.82)
	mat.emission_enabled = true
	mat.emission = Color(0.23, 0.50, 0.62)
	mat.emission_energy_multiplier = 0.45
	mat.roughness = 0.8
	line.material_override = mat
	_seventh_mark.add_child(line)
	var label := Label3D.new()
	label.name = "SeventhRoadLabel"
	label.text = "FANG ROOT SET  ·  SEVENTH ROAD HELD"
	label.position = Vector3(0.0, 0.27, 0.020)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = Color(0.66, 0.84, 0.93)
	label.font_size = 21
	label.pixel_size = 0.0032
	label.outline_size = 8
	label.outline_modulate = Color(0.04, 0.07, 0.09, 0.95)
	var font := WyrdUi.font_header()
	if font != null:
		label.font = font
	_seventh_mark.add_child(label)
	add_child(_seventh_mark)


func _apply_queens_summit_mark() -> void:
	if _queen_mark != null and is_instance_valid(_queen_mark):
		_queen_mark.queue_free()
		_queen_mark = null
	if not queens_summit_settlement_visible():
		return
	_queen_mark = Node3D.new()
	_queen_mark.name = "QueensSummitAtlasMark"
	var line := MeshInstance3D.new()
	line.name = "CrownwardLine"
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.46, 0.048)
	line.mesh = mesh
	line.position = Vector3(0.0, -0.13, 0.021)
	line.rotation.z = 0.20
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.76, 0.66, 0.94)
	mat.emission_enabled = true
	mat.emission = Color(0.48, 0.32, 0.78)
	mat.emission_energy_multiplier = 0.52
	mat.roughness = 0.8
	line.material_override = mat
	_queen_mark.add_child(line)
	var label := Label3D.new()
	label.name = "QueensSummitLabel"
	label.text = "CROWN ROOT SET  ·  PALE STAIR FOUND"
	label.position = Vector3(0.0, -0.31, 0.022)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = Color(0.84, 0.76, 1.0)
	label.font_size = 20
	label.pixel_size = 0.0031
	label.outline_size = 8
	label.outline_modulate = Color(0.06, 0.04, 0.09, 0.95)
	var font := WyrdUi.font_header()
	if font != null:
		label.font = font
	_queen_mark.add_child(label)
	add_child(_queen_mark)


func _apply_pale_oath_mark() -> void:
	if _pale_oath_mark != null and is_instance_valid(_pale_oath_mark):
		_pale_oath_mark.queue_free()
		_pale_oath_mark = null
	if not pale_oath_settlement_visible():
		return
	_pale_oath_mark = Node3D.new()
	_pale_oath_mark.name = "PaleOathAtlasMark"
	var line := MeshInstance3D.new()
	line.name = "RootroadLiftLine"
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.50, 0.048)
	line.mesh = mesh
	line.position = Vector3(0.0, -0.47, 0.023)
	line.rotation.z = -0.24
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.88, 0.58, 0.42)
	mat.emission_enabled = true
	mat.emission = Color(0.65, 0.28, 0.16)
	mat.emission_energy_multiplier = 0.56
	mat.roughness = 0.8
	line.material_override = mat
	_pale_oath_mark.add_child(line)
	var label := Label3D.new()
	label.name = "PaleOathLabel"
	label.text = "PALE ROOT  ·  PAST THREAD  ·  STARHEART  ·  LIFT RESTORED"
	label.position = Vector3(0.0, -0.64, 0.024)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = Color(1.0, 0.76, 0.62)
	label.font_size = 18
	label.pixel_size = 0.0030
	label.outline_size = 8
	label.outline_modulate = Color(0.10, 0.05, 0.04, 0.95)
	var font := WyrdUi.font_header()
	if font != null:
		label.font = font
	_pale_oath_mark.add_child(label)
	add_child(_pale_oath_mark)


func _apply_unwritten_road_mark() -> void:
	if _unwritten_road_mark != null and is_instance_valid(_unwritten_road_mark):
		# Atlas settlement snapshots can refresh in the same frame. Free this
		# purely visual child now so the rebuilt mark retains its stable authored
		# name instead of becoming an anonymous duplicate beside a queued node.
		_unwritten_road_mark.free()
		_unwritten_road_mark = null
	var progress := unwritten_road_progress()
	if not bool(progress.get("visible", false)):
		return
	_unwritten_road_mark = Node3D.new()
	_unwritten_road_mark.name = "UnwrittenRoadAtlasMark"
	var line := MeshInstance3D.new()
	line.name = "UnwrittenRoadLine"
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.58, 0.045)
	line.mesh = mesh
	line.position = Vector3(0.0, -0.75, 0.025)
	line.rotation.z = 0.12
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.70, 0.60, 0.94)
	mat.emission_enabled = true
	mat.emission = Color(0.38, 0.26, 0.68)
	mat.emission_energy_multiplier = 0.52
	mat.roughness = 0.82
	line.material_override = mat
	_unwritten_road_mark.add_child(line)
	var label := Label3D.new()
	label.name = "UnwrittenRoadLabel"
	label.text = "UNWRITTEN ROAD  ·  %d/%d WAYMARKS" % [
		int(progress.get("clue_count", 0)), int(progress.get("clue_target", 5))]
	label.position = Vector3(0.0, -0.91, 0.026)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = Color(0.84, 0.77, 1.0)
	label.font_size = 19
	label.pixel_size = 0.0030
	label.outline_size = 8
	label.outline_modulate = Color(0.07, 0.04, 0.11, 0.95)
	var font := WyrdUi.font_header()
	if font != null:
		label.font = font
	_unwritten_road_mark.add_child(label)
	add_child(_unwritten_road_mark)


func _exit_tree() -> void:
	# Autoload signals outlive Town. Disconnect explicitly so a source from a
	# retired scene cannot be called during the next Chart's return transaction.
	if _game_ref != null and is_instance_valid(_game_ref) \
			and _game_ref.chart_knowledge_changed.is_connected(refresh_source_state):
		_game_ref.chart_knowledge_changed.disconnect(refresh_source_state)
	_game_ref = null


# Town retains one progression call site while this node owns the material.
func set_progress(level: int, summit_cleared: bool = false) -> void:
	if _paper_material == null:
		return
	var energy := clampf(float(level - 1) / 10.0, 0.0, 1.0)
	if summit_cleared:
		energy = 1.2
	if energy <= 0.0 or not is_inside_tree():
		_paper_material.emission_energy_multiplier = energy
		return
	var captured := _paper_material
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(value: float) -> void:
		if is_instance_valid(captured):
			captured.emission_energy_multiplier = value,
		energy * 2.0, energy, 0.6)


func source_status() -> Dictionary:
	var source_id := active_source_id()
	var fallback_level := 15 if source_id == BRIAR_ROAD_SOURCE_ID else 6
	var fallback := {"valid": false, "source_id": source_id, "state": "invalid",
		"unlocked": false, "level": 1, "min_wayfinding": fallback_level,
		"rumour_id": "", "recipe_id": "", "known": false, "heard": false}
	var game := _game()
	if game == null or not game.has_method("chart_source_status"):
		return fallback
	var raw = game.chart_source_status(source_id)
	if not raw is Dictionary:
		return fallback
	var out := fallback.duplicate(true)
	out.merge(raw as Dictionary, true)
	if String(out.state) not in VALID_STATES:
		out.state = "invalid"
		out.valid = false
	return out


func active_source_id() -> String:
	var game := _game()
	# Golden Wallow's settlement visibly relights the road beyond the Mire. The
	# same Atlas therefore becomes the reachable Briar source immediately; it
	# may anticipate Wayfinding 15 without silently teaching the recipe.
	if golden_settlement_visible():
		return BRIAR_ROAD_SOURCE_ID
	if game == null or not game.has_method("chart_source_status"):
		return WET_ROAD_SOURCE_ID if homecoming_handoff_visible() else SOURCE_ID
	var briar = game.chart_source_status(BRIAR_ROAD_SOURCE_ID)
	if briar is Dictionary and bool((briar as Dictionary).get("unlocked", false)):
		return BRIAR_ROAD_SOURCE_ID
	var wet = game.chart_source_status(WET_ROAD_SOURCE_ID)
	if wet is Dictionary and bool((wet as Dictionary).get("unlocked", false)) \
			and String((wet as Dictionary).get("state", "invalid")) != "resolved":
		return WET_ROAD_SOURCE_ID
	return SOURCE_ID


func refresh_source_state() -> void:
	_status = source_status()
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
	# A heard or resolved page stays rereadable without advertising unfinished work.
	var status := source_status()
	marker.visible = not prompt_visible and bool(status.unlocked) \
		and String(status.state) in ["locked", "eligible"]


func interact(_player: Node) -> void:
	if _dialog_open:
		return
	var status := source_status()
	if not bool(status.valid) or not bool(status.unlocked):
		return
	_dialog_open = true
	var dialog: CanvasLayer = DialogPanelScript.new()
	dialog.name = "ChartRumourSourceDialog"
	dialog.add_to_group("ChartRumourSourceDialog")
	# The shared dialog group is presentation discovery only. Strict route
	# drivers bind acknowledgement to the physical source that opened it.
	dialog.set_meta("chart_source_id", active_source_id())
	dialog.set_meta("chart_source_owner_id", get_instance_id())
	dialog.open("The Living Atlas", _pages(status))
	dialog.finished.connect(func() -> void:
		_dialog_open = false
		read_now())
	get_tree().current_scene.add_child(dialog)


# Explicit test/accessibility seam. Game safely treats locked/repeat/resolved
# calls as copy-only and owns the successful read transaction.
func read_now() -> Dictionary:
	var fallback := {"ok": false, "changed": false, "state": "invalid",
		"granted": {}, "status": source_status()}
	var game := _game()
	if game == null or not game.has_method("read_chart_source"):
		return fallback
	var raw = game.read_chart_source(active_source_id())
	if not raw is Dictionary:
		return fallback
	refresh_source_state()
	return raw as Dictionary


func _pages(status: Dictionary) -> Array:
	if String(status.get("source_id", "")) == BRIAR_ROAD_SOURCE_ID:
		match String(status.get("state", "invalid")):
			"eligible", "read":
				return ["A thorn rubbing sits above a sewn page. A Briar Knot pulls the road through six familiar turnings.",
					"Beyond them, the Atlas has left a seventh line pale and unfinished."]
			"resolved":
				return ["The Briar Maze has kept its place. Cold signs found there may tell Mara why the seventh line will not settle."]
			_:
				return ["A thorn-road has surfaced beyond the relit Jetty.",
					"Its knot may settle at Wayfinding %d." % int(status.get("min_wayfinding", 15))]
	if String(status.get("source_id", "")) == WET_ROAD_SOURCE_ID:
		match String(status.get("state", "invalid")):
			"eligible", "read":
				return ["A mire reed points above a field page. A looped cord keeps the short wet road from wandering.",
					"Mara has left the last choice to the Table: one ordinary Hedge Ink, and whatever Affix answers."]
			"resolved":
				return ["The Sallow Shallows have kept their place. Three returned roads will tell the Atlas what roots beneath them."]
			_:
				return ["A wet mark waits beyond the First Knot. It will settle at Wayfinding 9."]
	match String(status.get("state", "invalid")):
		"eligible", "read":
			return ["The hedge stays true, but the page is sewn and the road is stitched deep."]
		"resolved":
			return ["The sewn page and Hollow Stitch sit clear now. The deeper road has kept its place."]
		_:
			if not bool(status.get("unlocked", false)):
				return ["The old panels are quiet. No deeper road has found its place yet."]
			return ["A faded panel has surfaced, but its stitching is still hard to read.",
				"It may settle at Wayfinding %d." % int(status.get("min_wayfinding", 6))]


func _game() -> Node:
	return get_tree().root.get_node_or_null("Game") if is_inside_tree() else null
