extends SceneTree

# Slice C2 world-source visual-QA harness. It loads the real Town, discovers
# the real source Interactable by stable node name, and uses its public
# `interact(player)` seam. Missing source Controls or domain state fail closed.

const TOWN_SCENE := "res://scenes/Town.tscn"
const ROUTES := {
	"atlas_deep_eligible": {
		"source_id": "atlas_deep_hollow",
		"node_name": "AtlasDeepRumourSource",
		"read": false,
		"level": 10,
		"known": ["snug", "green_hollow"],
		"kit": {"stitched_parchment": 1, "hedge_sprig": 1, "hollow_stitch": 1},
	},
	"atlas_deep_read": {
		"source_id": "atlas_deep_hollow",
		"node_name": "AtlasDeepRumourSource",
		"read": true,
		"level": 10,
		"known": ["snug", "green_hollow"],
		"kit": {"stitched_parchment": 1, "hedge_sprig": 1, "hollow_stitch": 1},
	},
	"mara_sallow_eligible": {
		"source_id": "mara_sallow_reed",
		"node_name": "MaraSallowRumourSource",
		"read": false,
		"level": 12,
		"known": ["snug", "green_hollow", "deep_hollow"],
		"kit": {"waxed_vellum": 1, "mire_reed": 1, "sunk_knot": 1},
	},
	"mara_sallow_read": {
		"source_id": "mara_sallow_reed",
		"node_name": "MaraSallowRumourSource",
		"read": true,
		"level": 12,
		"known": ["snug", "green_hollow", "deep_hollow"],
		"kit": {"waxed_vellum": 1, "mire_reed": 1, "sunk_knot": 1},
	},
}

var _route := "atlas_deep_eligible"
var _capture_path := "/tmp/wyrd_ui_atlas_deep_eligible.png"
var _manifest := {"capabilities": {}, "actions": []}


func _initialize() -> void:
	_route = OS.get_environment("WYRD_SOURCE_CAPTURE")
	if _route == "":
		_route = "atlas_deep_eligible"
	_capture_path = OS.get_environment("WYRD_CAPTURE_PATH")
	if _capture_path == "":
		_capture_path = "/tmp/wyrd_ui_%s.png" % _route
	_manifest["route"] = _route
	_manifest["image"] = _capture_path
	call_deferred("_run")


func _run() -> void:
	if not ROUTES.has(_route):
		_fail("unknown source capture route: %s" % _route)
		return
	var game := root.get_node_or_null("Game")
	if game == null:
		_fail("Game autoload missing")
		return
	if not game.has_method("chart_source_status") \
			or not game.has_method("read_chart_source"):
		_fail("C2 Game chart source API missing")
		return
	game.persistence_enabled = false
	game.reset_to_defaults()
	var fixture: Dictionary = ROUTES[_route]
	game.tutorial_step = 7
	var level := int(fixture.level)
	game.trades.wayfinding = {"xp": game.xp_for_level(level), "lv": level}
	game.known_chart_recipes = (fixture.known as Array).duplicate()
	game.materials = {}
	game.seen_hints["tier1_completed"] = true
	game.seen_hints["third_chart_choice_seen"] = true
	# Native visual fixtures begin from the durable post-completion entitlement.
	# The gameplay transition suite owns proving that real returns create it.
	game.chart_source_unlocks = [String(fixture.source_id)]

	var before: Dictionary = game.call("chart_source_status", String(fixture.source_id))
	(_manifest.capabilities as Dictionary)["status_before"] = before
	if not bool(before.get("valid", false)) or not bool(before.get("unlocked", false)) \
			or bool(before.get("heard", false)):
		_fail("fixture did not produce an eligible unread source: %s" %
			JSON.stringify(before))
		return
	if change_scene_to_file(TOWN_SCENE) != OK:
		_fail("could not load Town")
		return
	await _frames(12)
	var scene := current_scene
	var source := _find_named(scene, String(fixture.node_name))
	(_manifest.capabilities as Dictionary)["source_node"] = \
		"" if source == null else String(source.get_path())
	if source == null:
		_fail("real source node missing: %s" % fixture.node_name)
		return
	if not source.has_method("interact"):
		_fail("source has no public interact(player) seam: %s" % fixture.node_name)
		return
	var player: Node = game.local_player()
	if player == null:
		_fail("Town local player missing")
		return
	if source is Node3D and player is Node3D:
		(player as Node3D).global_position = (source as Node3D).global_position + Vector3(0.0, 0.0, 1.8)
		(_manifest.actions as Array).append("placed player beside real source")
	await _frames(8)
	if source.has_method("get_prompt_text"):
		(_manifest.capabilities as Dictionary)["prompt"] = String(source.call("get_prompt_text"))
	if source.has_method("show_prompt"):
		source.call("show_prompt", true)
		(_manifest.actions as Array).append("showed real source prompt")
		await _frames(2)
	var prompt_label := source.get_node_or_null("PromptLabel") as Label3D
	(_manifest.capabilities as Dictionary)["prompt_visible"] = \
		prompt_label != null and prompt_label.visible
	if prompt_label == null or not prompt_label.visible:
		_fail("real source prompt did not become visible")
		return

	if bool(fixture.read):
		source.call("interact", player)
		(_manifest.actions as Array).append("invoked real source Interactable")
		await _frames(8)
		var dialog := _find_named(current_scene, "ChartRumourSourceDialog")
		if dialog == null:
			for candidate in get_nodes_in_group("ChartRumourSourceDialog"):
				dialog = candidate
				break
		(_manifest.capabilities as Dictionary)["dialog"] = \
			"" if dialog == null else String(dialog.get_path())
		if dialog == null or not _has_visible_canvas(dialog):
			_fail("real ChartRumourSourceDialog was not visible after interaction")
			return
		# The real UI commits when the player finishes the dialog. Keep the dialog
		# visible for the screenshot while exercising its explicit deterministic
		# completion seam; do not call Game.read_chart_source directly here.
		if not source.has_method("read_now"):
			_fail("source has no public read_now() completion seam")
			return
		source.call("read_now")
		(_manifest.actions as Array).append("completed source read through source control")
		await _frames(2)
		var after: Dictionary = game.call("chart_source_status", String(fixture.source_id))
		(_manifest.capabilities as Dictionary)["status_after"] = after
		if not bool(after.get("heard", false)):
			_fail("source dialog opened without recording the source")
			return
		var rumour_id := String(after.get("rumour_id", ""))
		if rumour_id == "" or not (game.chart_recipe_journal.get("rumours", []) as Array).has(rumour_id):
			_fail("source read did not persist its rumour")
			return
		for material_id in (fixture.kit as Dictionary):
			if game.material_count(String(material_id)) < int(fixture.kit[material_id]):
				_fail("source read did not grant expected kit: %s" % material_id)
				return

	var image := root.get_texture().get_image()
	var error := image.save_png(_capture_path)
	if error != OK:
		_fail("could not save capture (error %d)" % error)
		return
	_write_manifest("passed", "")
	print("CHART SOURCE CAPTURE: %s -> %s" % [_route, _capture_path])
	quit(0)


func _find_named(node: Node, wanted: String) -> Node:
	if node == null:
		return null
	if String(node.name) == wanted:
		return node
	for child in node.get_children():
		var found := _find_named(child, wanted)
		if found != null:
			return found
	return null


func _has_visible_canvas(node: Node) -> bool:
	if node is CanvasItem and (node as CanvasItem).visible:
		return true
	for child in node.get_children():
		if _has_visible_canvas(child):
			return true
	return false


func _frames(count: int) -> void:
	for _index in count:
		await process_frame


func _fail(message: String) -> void:
	push_error(message)
	_write_manifest("failed", message)
	quit(2)


func _write_manifest(status: String, error: String) -> void:
	_manifest["status"] = status
	_manifest["error"] = error
	var file := FileAccess.open(_capture_path.get_basename() + ".json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_manifest, "  "))
		file.close()
