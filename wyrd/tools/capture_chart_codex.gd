extends SceneTree

# Slice C visual-QA harness. It renders the real Chart Table controller/view
# against deterministic Game state without adding capture-only branches to
# gameplay code. Public Slice C seams are feature-detected so the routes remain
# useful while the Codex implementation lands in parallel.

const BenchScript = preload("res://scripts/ui/crafting_bench.gd")
const ChartsData = preload("res://data/charts.gd")

const ROUTES := [
	"codex_index",
	"codex_rumoured",
	"codex_attemptable",
	"codex_known_ghost",
	"codex_stage_all_sufficient",
	"codex_stage_all_insufficient",
	"codex_guest",
	"codex_deep_rumoured_kit",
	"codex_sallow_rumoured_kit",
]

var _route := "codex_index"
var _capture_path := "/tmp/wyrd_ui_codex_index.png"
var _host: Node
var _bench: CanvasLayer
var _view: Control
var _capabilities := {}
var _actions: Array[String] = []


func _initialize() -> void:
	_route = OS.get_environment("WYRD_CODEX_CAPTURE")
	if _route == "":
		_route = "codex_index"
	_capture_path = OS.get_environment("WYRD_CAPTURE_PATH")
	if _capture_path == "":
		_capture_path = "/tmp/wyrd_ui_%s.png" % _route
	call_deferred("_run")


func _run() -> void:
	if not ROUTES.has(_route):
		push_error("Unknown Codex capture route: %s" % _route)
		quit(2)
		return
	var game := root.get_node_or_null("Game")
	if game == null:
		push_error("Codex capture requires the Game autoload")
		quit(2)
		return
	game.persistence_enabled = false
	game.reset_to_defaults()
	if not _configure_game(game):
		_write_manifest()
		quit(2)
		return

	_host = Node.new()
	_host.name = "CodexCaptureHost"
	root.add_child(_host)
	_bench = BenchScript.new()
	_host.add_child(_bench)
	await _frames(5)
	var panel := _bench.get_node_or_null("ChartTablePanel") as Panel
	_view = panel.get_node_or_null("ChartTableView") as Control if panel != null else null
	if panel == null or _view == null:
		push_error("Codex capture could not build the Chart Table")
		quit(2)
		return

	_capabilities.merge({
		"codex_pages": _bench.has_method("codex_pages"),
		"open_codex_page": _bench.has_method("open_codex_page"),
		"close_codex_page": _bench.has_method("close_codex_page"),
		"selected_codex_page": _bench.has_method("selected_codex_page"),
		"stage_codex_ghost": _bench.has_method("stage_codex_ghost"),
		"stage_all_known_recipe": _bench.has_method("stage_all_known_recipe"),
	}, true)
	if _bench.has_method("codex_pages"):
		var states := {}
		for page_v in _bench.call("codex_pages"):
			var page: Dictionary = page_v
			states[String(page.get("recipe_id", page.get("id", "")))] = \
				String(page.get("state", "unknown"))
		_capabilities["codex_states"] = states
	_open_codex_index()
	await _frames(3)
	await _drive_route()
	await _frames(5)

	var image := root.get_texture().get_image()
	var error := image.save_png(_capture_path)
	if error != OK:
		push_error("Could not save %s (error %d)" % [_capture_path, error])
		quit(2)
		return
	_write_manifest()
	print("CODEX CAPTURE: %s -> %s" % [_route, _capture_path])
	print("CODEX CAPABILITIES: %s" % JSON.stringify(_capabilities))
	if not _actions.is_empty():
		print("CODEX ACTIONS: %s" % ", ".join(_actions))
	if _route == "codex_guest":
		var net := root.get_node_or_null("NetGame")
		if net != null and bool(net.get("active")):
			net.leave("Codex capture complete.")
	_host.queue_free()
	await _frames(3)
	quit(0)


func _configure_game(game: Node) -> bool:
	game.tutorial_step = 7
	game.seen_hints["chart_table_snug_returned"] = true
	game.trades.wayfinding = {"xp": game.xp_for_level(23), "lv": 23}
	game.materials = {}
	game.known_chart_recipes = ["snug"]
	if _route not in ["codex_deep_rumoured_kit", "codex_sallow_rumoured_kit"]:
		_seed_rumours(game, ["deep_hollow", "briar_maze"])
	match _route:
		"codex_index", "codex_rumoured", "codex_attemptable":
			game.materials = {
				"field_parchment": 1,
				"hedge_sprig": 1,
				"loop_cord": 1,
			}
		"codex_known_ghost", "codex_guest":
			game.known_chart_recipes = ["snug", "green_hollow", "deep_hollow"]
			game.materials = {
				"stitched_parchment": 1,
				"hedge_sprig": 1,
				"hollow_stitch": 1,
				"hedge_ink": 3,
			}
		"codex_stage_all_sufficient":
			game.known_chart_recipes = ["snug", "green_hollow"]
			game.materials = {
				"field_parchment": 1,
				"hedge_sprig": 1,
				"loop_cord": 1,
				"hedge_ink": 2,
			}
		"codex_stage_all_insufficient":
			game.known_chart_recipes = ["snug", "green_hollow"]
			game.materials = {
				"field_parchment": 1,
				"hedge_sprig": 1,
				"hedge_ink": 2,
			}
		"codex_deep_rumoured_kit":
			game.known_chart_recipes = ["snug", "green_hollow"]
			game.trades.wayfinding = {"xp": game.xp_for_level(10), "lv": 10}
			game.chart_source_unlocks = ["atlas_deep_hollow"]
			if not _read_chart_source(game, "atlas_deep_hollow", {
				"stitched_parchment": 1,
				"hedge_sprig": 1,
				"hollow_stitch": 1,
			}):
				return false
		"codex_sallow_rumoured_kit":
			game.known_chart_recipes = ["snug", "green_hollow", "deep_hollow"]
			game.trades.wayfinding = {"xp": game.xp_for_level(12), "lv": 12}
			game.chart_source_unlocks = ["mara_sallow_reed"]
			if not _read_chart_source(game, "mara_sallow_reed", {
				"waxed_vellum": 1,
				"mire_reed": 1,
				"sunk_knot": 1,
			}):
				return false
	if _route == "codex_guest":
		var net := root.get_node_or_null("NetGame")
		if net != null and net.has_method("join"):
			_capabilities["guest_session_started"] = bool(net.join("127.0.0.1", 19999))
	return true


func _read_chart_source(game: Node, source_id: String,
		expected_kit: Dictionary) -> bool:
	# C2 fixtures exercise the public source transaction. They do not seed the
	# journal or kit independently: a capture is invalid unless the same API used
	# by the in-world source records both atomically.
	if not game.has_method("chart_source_status") \
			or not game.has_method("read_chart_source"):
		_capabilities["source_error"] = "C2 Game source API unavailable"
		push_error(String(_capabilities.source_error))
		return false
	var before: Dictionary = game.call("chart_source_status", source_id)
	var result: Dictionary = game.call("read_chart_source", source_id)
	var after: Dictionary = game.call("chart_source_status", source_id)
	_capabilities["source_id"] = source_id
	_capabilities["source_status_before"] = before
	_capabilities["source_read_result"] = result
	_capabilities["source_status_after"] = after
	if not bool(result.get("ok", false)) or not bool(result.get("changed", false)):
		_capabilities["source_error"] = "source read did not change fresh state"
		push_error("%s: %s" % [_capabilities.source_error, JSON.stringify(result)])
		return false
	var rumour_id := String(after.get("rumour_id", before.get("rumour_id", "")))
	if rumour_id == "" or not (game.chart_recipe_journal.get("rumours", []) as Array).has(rumour_id):
		_capabilities["source_error"] = "source rumour was not persisted"
		push_error(String(_capabilities.source_error))
		return false
	for material_id in expected_kit:
		if game.material_count(String(material_id)) < int(expected_kit[material_id]):
			_capabilities["source_error"] = "source kit was incomplete: %s" % material_id
			push_error(String(_capabilities.source_error))
			return false
	_capabilities["source_expected_kit"] = expected_kit.duplicate()
	return true


func _seed_rumours(game: Node, recipe_ids: Array) -> void:
	# Prefer an eventual explicit journal property. The seen-hint aliases keep
	# older/provisional implementations renderable without prescribing their
	# persistence schema.
	if game.has_method("hear_chart_rumour"):
		for recipe_id_v in recipe_ids:
			var recipe: Dictionary = ChartsData.CHART_RECIPES.get(String(recipe_id_v), {})
			var rumour_id := String(recipe.get("rumour_id", ""))
			if rumour_id != "":
				game.call("hear_chart_rumour", rumour_id)
	for property in game.get_property_list():
		var name := String((property as Dictionary).get("name", ""))
		if name not in ["rumoured_chart_recipes", "chart_recipe_rumours"]:
			continue
		var current = game.get(name)
		if current is Array:
			game.set(name, recipe_ids.duplicate())
		elif current is Dictionary:
			var journal := {}
			for recipe_id in recipe_ids:
				journal[String(recipe_id)] = true
			game.set(name, journal)
	for recipe_id_v in recipe_ids:
		var recipe_id := String(recipe_id_v)
		var recipe: Dictionary = ChartsData.CHART_RECIPES.get(recipe_id, {})
		var rumour_id := String(recipe.get("rumour_id", ""))
		if rumour_id != "":
			game.seen_hints[rumour_id] = true
			game.seen_hints["chart_rumour_%s" % rumour_id] = true


func _open_codex_index() -> void:
	if _view.has_method("set_source_mode"):
		_view.call("set_source_mode", "codex")
		_actions.append("opened Codex index through ChartTableView")
	elif _bench.has_method("set_source_mode"):
		_bench.call("set_source_mode", "codex")
		_actions.append("opened Codex index through controller fallback")


func _drive_route() -> void:
	match _route:
		"codex_index":
			return
		"codex_rumoured":
			await _open_recipe("deep_hollow")
		"codex_attemptable":
			await _open_recipe("green_hollow")
		"codex_known_ghost", "codex_guest":
			await _open_recipe("deep_hollow")
		"codex_stage_all_sufficient", "codex_stage_all_insufficient":
			await _open_recipe("green_hollow")
			await _stage_all()
		"codex_deep_rumoured_kit":
			await _open_recipe("deep_hollow")
		"codex_sallow_rumoured_kit":
			await _open_recipe("sallow_mire")


func _open_recipe(recipe_id: String) -> void:
	if _bench.has_method("open_codex_page"):
		_capabilities["open_recipe_result"] = bool(
			_bench.call("open_codex_page", recipe_id))
		_actions.append("opened %s through controller" % recipe_id)
		await _frames(2)
		return
	var button := _find_button("CodexPage_%s" % recipe_id, recipe_id)
	if button != null:
		button.pressed.emit()
		_actions.append("opened %s through focusable Codex page" % recipe_id)
		await _frames(2)
	else:
		_actions.append("Codex page hook unavailable; captured index fallback")


func _stage_all() -> void:
	if _bench.has_method("stage_all_known_recipe"):
		_capabilities["stage_all_result"] = bool(
			_bench.call("stage_all_known_recipe"))
		_actions.append("invoked Stage All through controller")
		await _frames(2)
		return
	var button := _find_button("CodexStageAllButton", "stage all")
	if button != null:
		button.pressed.emit()
		_actions.append("invoked Stage All through focusable control")
		await _frames(2)
	else:
		_actions.append("Stage All hook unavailable; captured known-page fallback")


func _find_button(exact_name: String, text_fragment: String) -> Button:
	var by_name := _view.find_child(exact_name, true, false) as Button
	if by_name != null:
		return by_name
	var wanted := text_fragment.to_lower().replace("_", " ")
	for node in _walk(_view):
		if node is Button and wanted in String((node as Button).text).to_lower():
			return node as Button
	return null


func _walk(node: Node) -> Array:
	var out: Array = [node]
	for child in node.get_children():
		out.append_array(_walk(child))
	return out


func _frames(count: int) -> void:
	for _index in count:
		await process_frame


func _write_manifest() -> void:
	var manifest_path := _capture_path.get_basename() + ".json"
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write Codex capture manifest: %s" % manifest_path)
		return
	file.store_string(JSON.stringify({
		"route": _route,
		"image": _capture_path,
		"capabilities": _capabilities,
		"actions": _actions,
	}, "  "))
	file.close()
