class_name ThreefoldLoomSource
extends Interactable

# The Threefold Loom is one physical source with two authored beats.  First it
# teaches Root Below; after that same folio it is the Map of Nine Knots ritual.
# This remains a deliberately thin world adapter: Game owns both rules,
# authority, saving, and every campaign mutation.

const DialogPanelScript = preload("res://scripts/ui/dialog_panel.gd")
const MapRitualPanelScript = preload("res://scripts/ui/map_ritual_panel.gd")
const SOURCE_ID := "threefold_loom_root_below"
const VALID_STATES := ["locked", "eligible", "read", "resolved"]

var _dialog_open := false
var _game_ref: Node = null
var _last_status: Dictionary = {}
# Test/integration seam only.  Production always resolves the Game autoload.
var game_override: Node = null


func get_prompt_text() -> String:
	var view := loom_view()
	# Guest prompt copy is derived exclusively from the current host projection.
	# In particular, a locally-known Root Below folio must not change the prompt
	# while the host is still at first_folio.
	if _guest_net_session():
		match String(view.get("phase", "unavailable")):
			"unavailable": return "[E/A] Wait for the fire-keeper's Loom"
			"first_folio": return "[E/A] The fire-keeper studies the Loom"
			"waiting": return "[E/A] Study the fire-keeper's stirring Loom"
			"ritual_ready": return "[E/A] Review the fire-keeper's Map of Nine Knots"
			"map_recorded": return "[E/A] Review the fire-keeper's Map of Nine Knots"
			_: return "[E/A] Wait for the fire-keeper's Loom"
	match String(view.get("phase", "first_folio")):
		"unavailable": return "[E/A] Wait for the fire-keeper's Loom"
		"waiting": return "[E/A] Study the stirring Threefold Loom"
		"ritual_ready": return "[E/A] Trace the Map of Nine Knots"
		"map_recorded": return "[E/A] Review the Map of Nine Knots"
		_:
			match String(source_status().get("state", "invalid")):
				"eligible": return "[E/A] Read the Loom's first tracing"
				"read": return "[E/A] Re-read the Loom's tracing"
				"resolved": return "[E/A] Review the Root Below folio"
				_: return "[E/A] Study the stirring Threefold Loom"


func get_prompt_color() -> Color:
	return Color(0.78, 0.66, 0.96)


func get_collision_radius() -> float:
	# Keep the scanner target discrete from Ember Kiln's broad forge radius.
	return 0.64


func get_collision_offset() -> Vector3:
	return Vector3(0.0, 0.34, 0.0)


func get_prompt_position() -> Vector3:
	return Vector3(0.0, 1.18, 0.0)


func get_solid_radius() -> float:
	return 0.26


func get_solid_height() -> float:
	return 0.62


func _ready_interactable() -> void:
	add_to_group("chart_rumour_source")
	add_to_group("threefold_loom_source")
	_build_folio()
	_game_ref = _game()
	if _game_ref != null and _game_ref.has_signal("chart_knowledge_changed"):
		_game_ref.chart_knowledge_changed.connect(refresh_source_state)
	if _game_ref != null and _game_ref.has_signal("story_changed"):
		_game_ref.story_changed.connect(refresh_source_state)
	refresh_source_state()


func _exit_tree() -> void:
	if _game_ref != null and is_instance_valid(_game_ref) \
			and _game_ref.chart_knowledge_changed.is_connected(refresh_source_state):
		_game_ref.chart_knowledge_changed.disconnect(refresh_source_state)
	if _game_ref != null and is_instance_valid(_game_ref) \
			and _game_ref.has_signal("story_changed") \
			and _game_ref.story_changed.is_connected(refresh_source_state):
		_game_ref.story_changed.disconnect(refresh_source_state)
	_game_ref = null


func _build_folio() -> void:
	# A small made-of-code folio is enough to give the otherwise inert foundation
	# a clear reading point; it introduces no asset or new station surface.
	var folio := MeshInstance3D.new()
	folio.name = "RootBelowFolio"
	var page := BoxMesh.new()
	page.size = Vector3(0.42, 0.045, 0.30)
	folio.mesh = page
	folio.position = Vector3(0.0, 0.36, 0.0)
	var page_mat := StandardMaterial3D.new()
	page_mat.albedo_color = Color(0.68, 0.60, 0.48)
	page_mat.roughness = 0.96
	page_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	folio.material_override = page_mat
	add_child(folio)
	for z in [-0.075, 0.0, 0.075]:
		var line := MeshInstance3D.new()
		line.name = "RootBelowInkLine"
		var stroke := BoxMesh.new()
		stroke.size = Vector3(0.30, 0.012, 0.016)
		line.mesh = stroke
		line.position = Vector3(-0.02, 0.390, z)
		var ink := StandardMaterial3D.new()
		ink.albedo_color = Color(0.25, 0.18, 0.34)
		ink.roughness = 1.0
		line.material_override = ink
		add_child(line)


# Copy the Game response before exposing it to UI/tests. No local save,
# campaign, component, Map, or authority rule is permitted at this boundary.
func source_status() -> Dictionary:
	var fallback := {"valid": false, "source_id": SOURCE_ID, "state": "invalid",
		"unlocked": false, "level": 1, "min_wayfinding": 22,
		"rumour_id": "", "recipe_id": "", "known": false, "heard": false}
	var game := _game()
	if game == null or not game.has_method("chart_source_status"):
		return fallback
	var raw = game.chart_source_status(SOURCE_ID)
	if not raw is Dictionary:
		return fallback
	var out := fallback.duplicate(true)
	out.merge(raw as Dictionary, true)
	if String(out.get("state", "invalid")) not in VALID_STATES:
		out.state = "invalid"
		out.valid = false
	return out


func refresh_source_state() -> void:
	_last_status = source_status().duplicate(true)
	var prompt := get_node_or_null("PromptLabel") as Label3D
	if prompt != null:
		prompt.text = get_prompt_text()
	_refresh_marker()


# One copied presentation view for the later ritual.  The Game lane publishes
# the canonical `threefold_loom_view`; `map_ritual_view` keeps this world
# adapter compatible while that API lands.  This node never derives readiness
# from campaign/material state or from NetGame.
func loom_view() -> Dictionary:
	var fallback := {
		"valid": false,
		"phase": "first_folio",
		"read_only": false,
		"can_trace": false,
		"map_recorded": false,
		"knowledge_complete": false,
		"loom_state": "dormant",
		"requirements": [],
	}
	var game := _game()
	if game == null:
		return fallback
	# In a shared session, the guest's save cannot decide whether this one
	# physical Loom is still a first folio or has become the Map ritual.  Ask
	# Game for its sanitized host snapshot before reading the local source
	# status; that status is deliberately never a guest routing gate.
	if _guest_net_session():
		var projected_raw: Variant = {}
		if game.has_method("threefold_loom_view"):
			projected_raw = game.call("threefold_loom_view")
		elif game.has_method("map_ritual_view"):
			projected_raw = game.call("map_ritual_view")
		if not projected_raw is Dictionary:
			var unavailable := fallback.duplicate(true)
			unavailable["phase"] = "unavailable"
			unavailable["read_only"] = true
			return unavailable
		var guest_view := fallback.duplicate(true)
		guest_view.merge(projected_raw as Dictionary, true)
		guest_view["read_only"] = true
		guest_view["can_trace"] = false
		guest_view["can_repair_knowledge"] = false
		return guest_view

	var source := source_status()
	# A first folio must settle before any Map-facing presentation can appear.
	if not bool(source.get("known", false)):
		return fallback
	var raw: Variant = {}
	if game.has_method("threefold_loom_view"):
		raw = game.call("threefold_loom_view")
	elif game.has_method("map_ritual_view"):
		raw = game.call("map_ritual_view")
	if not raw is Dictionary:
		return fallback
	var view := fallback.duplicate(true)
	view.merge(raw as Dictionary, true)
	var phase := String(view.get("phase", ""))
	if phase not in ["waiting", "ritual_ready", "map_recorded"]:
		phase = "map_recorded" if bool(view.get("map_recorded", false)) else \
			("ritual_ready" if bool(view.get("can_trace", false)) else "waiting")
		view["phase"] = phase
	return view


func _guest_net_session() -> bool:
	if not is_inside_tree():
		return false
	var net := get_tree().root.get_node_or_null("NetGame")
	return net != null and bool(net.get("active")) and not bool(net.call("is_host"))


func show_prompt(on: bool) -> void:
	super.show_prompt(on)
	_refresh_marker()


func _refresh_marker() -> void:
	var marker := get_node_or_null("Marker") as Label3D
	var prompt := get_node_or_null("PromptLabel") as Label3D
	if marker != null:
		marker.visible = not (prompt != null and prompt.visible)


func interact(_player: Node) -> void:
	if _dialog_open:
		return
	var view := loom_view()
	var phase := String(view.get("phase", "unavailable"))
	# Before a guest has received host truth, there is intentionally no panel,
	# requirement list, local folio read, or action. The physical Loom simply
	# waits; opening a Map panel here would reconstruct false local readiness.
	if phase == "unavailable":
		return
	# A host at its first folio remains a first folio for every guest, even if
	# the guest's own save says Root Below is known. Show only neutral host-role
	# copy; do not call source_status(), _pages(), or read_now().
	if _guest_net_session() and phase == "first_folio":
		_open_guest_first_folio_review()
		return
	if phase != "first_folio":
		_open_map_ritual(view)
		return
	var status := source_status()
	if not bool(status.get("valid", false)):
		return
	_dialog_open = true
	var dialog: CanvasLayer = DialogPanelScript.new()
	dialog.name = "ThreefoldLoomSourceDialog"
	dialog.add_to_group("ChartRumourSourceDialog")
	dialog.open("The Threefold Loom", _pages(status))
	dialog.finished.connect(func() -> void:
		_dialog_open = false
		read_now())
	get_tree().current_scene.add_child(dialog)


func _open_guest_first_folio_review() -> void:
	_dialog_open = true
	var dialog: CanvasLayer = DialogPanelScript.new()
	dialog.name = "ThreefoldLoomGuestReview"
	dialog.add_to_group("ThreefoldLoomGuestReview")
	dialog.open("The Threefold Loom", [
		"The fire-keeper has not settled the Loom's first tracing yet.",
		"Its next line will be shared here when the fire-keeper is ready.",
	])
	dialog.finished.connect(func() -> void:
		_dialog_open = false)
	get_tree().current_scene.add_child(dialog)


func _open_map_ritual(view: Dictionary) -> void:
	var existing := get_tree().get_first_node_in_group("MapRitualPanel")
	if existing != null:
		return
	var panel: CanvasLayer = MapRitualPanelScript.new()
	panel.name = "MapRitualPanel"
	panel.add_to_group("MapRitualPanel")
	panel.initial_view = view.duplicate(true)
	if game_override != null:
		panel.game_override = game_override
	get_tree().current_scene.add_child(panel)


# Explicit test seam. Game returns read-only/inert results for guests, locked
# sources, rereads, and already-known records; this adapter never branches on
# those policies or tries to top up the lesson itself.
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
	return (raw as Dictionary).duplicate(true)


func _pages(status: Dictionary) -> Array:
	match String(status.get("state", "invalid")):
		"eligible":
			return ["One tracing rests above a Nine-Knot Leaf. A Threefold Binding waits at its west hand.",
				"Mara can refill the ordinary pieces once this first lesson has settled; the Loom only remembers the arrangement."]
		"read":
			return ["The first tracing remains clear. Mara keeps the renewable paper, tracing, and binding in her supply drawer.",
				"Five returned roads will make the Loom stir toward a Map, but this folio does not make that ritual."]
		"resolved":
			return ["Root Below has kept its place in the Codex. The Loom remembers the road without taking a Map or Rune into its hands."]
		_:
			return ["The Threefold Loom has begun to stir, but its first tracing will settle only at Wayfinding %d." % int(status.get("min_wayfinding", 22))]


func _game() -> Node:
	if game_override != null:
		return game_override
	return get_tree().root.get_node_or_null("Game") if is_inside_tree() else null
