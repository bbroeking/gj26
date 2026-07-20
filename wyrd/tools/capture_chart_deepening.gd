extends SceneTree

# Native 1366×768 visual route for Slice D2. It drives the real Chart Table
# controller against deterministic Game state; it does not add a capture-only
# gameplay branch or calculate a preview locally.

const BenchScript = preload("res://scripts/ui/crafting_bench.gd")
const CampaignData = preload("res://data/campaign.gd")

const ROUTES := ["deepening_green", "deepening_sallow", "first_knot_reprise"]

var _route := "deepening_green"
var _capture_path := "/tmp/wyrd_ui_deepening_green.png"


func _initialize() -> void:
	_route = OS.get_environment("WYRD_D2_CAPTURE")
	if _route == "":
		_route = "deepening_green"
	_capture_path = OS.get_environment("WYRD_CAPTURE_PATH")
	if _capture_path == "":
		_capture_path = "/tmp/wyrd_ui_%s.png" % _route
	call_deferred("_run")


func _run() -> void:
	if not ROUTES.has(_route):
		push_error("Unknown D2 capture route: %s" % _route)
		quit(2)
		return
	var game := root.get_node_or_null("Game")
	if game == null:
		push_error("D2 capture requires the Game autoload")
		quit(2)
		return
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.tutorial_step = 7
	game.seen_hints["chart_table_snug_returned"] = true
	_configure(game)

	var host := Node.new()
	root.add_child(host)
	var bench: CanvasLayer = BenchScript.new()
	host.add_child(bench)
	await _frames(5)
	_stage_route(bench)
	await _frames(5)
	# The live preview is intentionally scrollable because it lists every Affix.
	# Native D2 evidence centers the new promise rather than relying on a tiny
	# thumbnail or a separate capture-only label.
	var preview_body := bench.find_child("PreviewBody", true, false) as RichTextLabel
	if preview_body != null:
		preview_body.scroll_to_line(11 if _route == "first_knot_reprise" else 5)
		await _frames(2)
	var image := root.get_texture().get_image()
	var error := image.save_png(_capture_path)
	if error != OK:
		push_error("Could not save %s (error %d)" % [_capture_path, error])
		quit(2)
		return
	print("D2 CHART TABLE CAPTURE: %s -> %s" % [_route, _capture_path])
	host.queue_free()
	await _frames(2)
	quit(0)


func _configure(game: Node) -> void:
	match _route:
		"deepening_green":
			game.trades.wayfinding = {"xp": game.xp_for_level(17), "lv": 17}
			game.known_chart_recipes = ["snug", "green_hollow"]
			game.materials = {"field_parchment": 1, "hedge_sprig": 1,
				"loop_cord": 2, "hedge_ink": 1}
		"deepening_sallow":
			game.trades.wayfinding = {"xp": game.xp_for_level(17), "lv": 17}
			game.known_chart_recipes = ["snug", "sallow_mire"]
			game.materials = {"waxed_vellum": 1, "mire_reed": 1,
				"sunk_knot": 2, "hedge_ink": 1}
		"first_knot_reprise":
			game.trades.wayfinding = {"xp": game.xp_for_level(21), "lv": 21}
			game.known_chart_recipes = ["snug", "first_knot_reprise"]
			game.materials = {"field_parchment": 1, "hedge_sprig": 1,
				"loop_cord": 2, "thorn_essence": 1, "hedge_ink": 2}
			var campaign: Dictionary = CampaignData.empty_state()
			var chapter: Dictionary = campaign.chapters.first_knot
			chapter.cleared = true
			game.campaign_state = campaign


func _stage_route(bench: CanvasLayer) -> void:
	match _route:
		"deepening_green":
			bench.place_component("c", "field_parchment")
			bench.place_component("n", "hedge_sprig")
			bench.place_component("w", "loop_cord")
			bench.activate_supply("loop_cord") # real supply click selects east well
		"deepening_sallow":
			bench.place_component("c", "waxed_vellum")
			bench.place_component("n", "mire_reed")
			bench.place_component("w", "sunk_knot")
			bench.activate_supply("sunk_knot")
		"first_knot_reprise":
			bench.place_component("c", "field_parchment")
			bench.place_component("n", "hedge_sprig")
			bench.place_component("w", "loop_cord")
			bench.activate_supply("loop_cord")
			bench.place_component("s", "thorn_essence")
			bench.place_ink("hedge_ink", 0)


func _frames(count: int) -> void:
	for _index in count:
		await process_frame
