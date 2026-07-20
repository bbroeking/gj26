extends SceneTree

# Regression for the cumulative D7 chapter boundaries. A real returned-Chart
# debrief owns Town input when each next chapter source becomes available. The
# D7 handoff must close that *specific* production debrief, wait for stable
# control, then make a receipt-proven scanner read of the next Atlas/Archive
# source. D4–D6 retain their standalone fixed-fixture tests; this covers only
# their fresh D7 ownership transfer.

const CampaignData = preload("res://data/campaign.gd")
const ChartsData = preload("res://data/charts.gd")
const Progression = preload("res://data/progression.gd")

var passed := 0
var failed := 0


func check(label: String, ok: bool, detail = "") -> void:
	if ok:
		passed += 1
		print("  ✓ %s" % label)
	else:
		failed += 1
		print("  ✗ %s %s" % [label, str(detail)])


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	print("--- D7 prior-saga debrief handoffs ---")
	Engine.time_scale = 6.0
	# One process owns one physical handoff. After the source read the real
	# driver immediately begins its next renewable making loop, so chaining cases
	# in one SceneTree would tear a live coroutine down beneath the next Town.
	# Run the three exact regressions with `WYRD_D7_HANDOFF_CASE=seventh|queens|pale`.
	var route := OS.get_environment("WYRD_D7_HANDOFF_CASE")
	match route:
		"seventh": await _run_case("Golden Wallow → Briar Atlas", route,
			"atlas_briar_knot", "seventh_source")
		"queens": await _run_case("Seventh Road → Queen Archive", route,
			"skald_queens_summit", "queens_source")
		"pale": await _run_case("Queen's Summit → Pale Archive", route,
			"skald_pale_oath", "pale_source")
		_:
			failed += 1
			print("  ✗ set WYRD_D7_HANDOFF_CASE to seventh, queens, or pale")
	Engine.time_scale = 1.0
	print("--- D7 prior-saga debrief handoffs: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _run_case(label: String, route: String, source_id: String, marker: String) -> void:
	var game = root.get_node_or_null("Game")
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.persistence_enabled = false
	game.web_smoke_enabled = true
	game.web_smoke_d1_enabled = false
	game.web_smoke_d3_enabled = false
	game.web_smoke_d4_enabled = false
	game.web_smoke_d5_enabled = false
	game.web_smoke_d6_enabled = false
	game.web_smoke_d7_enabled = true
	game.web_smoke_phase = ""
	game.web_smoke_history = []
	game.web_smoke_features = {}
	game.modal_count = 0
	paused = false
	_prepare_prior_boundary(game, route)
	# This is the actual Town return panel, not a synthetic member of the group.
	# Its deferred Town callback reliably reproduces the paused/modal boundary
	# that browser r11 exposed at Golden → Briar.
	game.pending_run_debrief = {
		"found": "a true road mark", "rose": "+0 Wayfinding XP · Wayfinding 23",
		"opened": "the next page", "template_id": "hollow", "preparation": false,
	}
	change_scene_to_file("res://scenes/Town.tscn")
	for _frame in 6:
		await process_frame
	var debrief := get_first_node_in_group("run_debrief")
	check("%s begins behind Town's real return debrief" % label,
		debrief != null and paused and game.modal_count == 1,
		{"debrief": debrief, "paused": paused, "modal_count": game.modal_count})
	# The D7 scene dispatcher deliberately ignores this probe stage while Town
	# schedules its return UI. Transfer to the real chapter owner only after the
	# modal is demonstrably present, matching the deferred settlement handoff.
	match route:
		"seventh": game._web_smoke_d7_stage = "prior_seventh_road"
		"queens": game._web_smoke_d7_stage = "prior_queens_summit"
		"pale": game._web_smoke_d7_stage = "prior_pale_oath"
	match route:
		"seventh": game._d7_begin_seventh_road_from_earned_state.call_deferred()
		"queens": game._d7_begin_queens_summit_from_earned_state.call_deferred()
		"pale": game._d7_begin_pale_oath_from_earned_state.call_deferred()
	var deadline := Time.get_ticks_msec() + 16000
	while Time.get_ticks_msec() < deadline and not game.web_smoke_history.has(marker) \
			and game.web_smoke_phase != "failed":
		await create_timer(0.03, true).timeout
	var source_status: Dictionary = game.chart_source_status(source_id)
	var receipt: Dictionary = game.web_smoke_features.get(
		"d7_prior_source_receipt_%s" % source_id, {}) as Dictionary
	check("%s releases the exact debrief before its receipt-proven source read" % label,
		game.web_smoke_history.has(marker) and String(source_status.get("state", "")) == "read"
			and _source_receipt_matches(receipt, route) and _lesson_settled(game, route)
			and game.modal_count == 0 and not paused
			and game.web_smoke_phase != "failed",
		{"history": game.web_smoke_history, "status": source_status,
			"receipt": receipt,
			"paused": paused, "modal_count": game.modal_count,
			"phase": game.web_smoke_phase})
	if route == "seventh":
		var support_receipts: Array = game.web_smoke_features.get(
			"d7_support_trade_receipts", [])
		var seventh_receipt: Dictionary = {}
		for raw_receipt in support_receipts:
			var candidate: Dictionary = raw_receipt
			if String(candidate.get("label", "")) == "seventh_road":
				seventh_receipt = candidate
				break
		check("Golden 2016/EC1 reaches Briar through the Town Forge without a practice Green",
			int((game.trades.wayfinding as Dictionary).get("xp", -1)) == 2016
				and game.trade_lv("earthcraft") >= 3
				and int(seventh_receipt.get("wayfinding_xp", -1)) == 2016
				and int((seventh_receipt.get("before", {}) as Dictionary).get(
					"earthcraft", 0)) == 1
				and not game.web_smoke_history.has("trade_training_start")
				and not bool(game.web_smoke_features.get("d7_training_real_table", false)),
			{"trades": game.trades, "support": seventh_receipt,
				"history": game.web_smoke_history,
				"training": game._web_smoke_d7_training})
	# The process exits after this focused probe; do not free a live production
	# coroutine just to run another case in the same SceneTree.
	game.web_smoke_d7_enabled = false


func _lesson_settled(game: Node, route: String) -> bool:
	var rumours: Array = game.chart_recipe_journal.get("rumours", []) as Array
	match route:
		"seventh":
			return rumours.has("atlas_briar_knot") \
				and game.material_count("thorn_rubbing") == 1 \
				and game.material_count("stitched_parchment") == 1 \
				and game.material_count("briar_knot") == 1
		"queens":
			return rumours.has("skald_crownward_ascent") \
				and game.material_count("cold_track") == 2 \
				and game.material_count("atlas_folio") == 1 \
				and game.material_count("climbing_cord") == 2
		"pale":
			return rumours.has("skald_pale_oath") \
				and game.material_count("pale_wellmark") == 1 \
				and game.material_count("atlas_folio") == 1 \
				and game.material_count("climbing_cord") == 2 \
				and game.material_count("stoneground_ink") >= 1
	return false


func _source_receipt_matches(receipt: Dictionary, route: String) -> bool:
	var expected_name := "AtlasDeepRumourSource" if route == "seventh" else "SkaldArchive"
	var snapshot: Dictionary = receipt.get("receipt", {}) as Dictionary
	var actual: Dictionary = snapshot.get("actual", {}) as Dictionary
	var expected: Dictionary = snapshot.get("expected", {}) as Dictionary
	return String(snapshot.get("status", "")) == "actual" \
		and String(actual.get("name", "")) == expected_name \
		and String(expected.get("name", "")) == expected_name \
		and String((receipt.get("target", {}) as Dictionary).get("name", "")) == expected_name


func _prepare_prior_boundary(game: Node, route: String) -> void:
	game.campaign_state = CampaignData.empty_state()
	var chapter_order := [CampaignData.FIRST_KNOT]
	if route == "seventh":
		chapter_order.append(CampaignData.GOLDEN_WALLOW)
	elif route == "queens":
		chapter_order.append_array([CampaignData.GOLDEN_WALLOW, CampaignData.SEVENTH_ROAD])
	else:
		chapter_order.append_array([CampaignData.GOLDEN_WALLOW, CampaignData.SEVENTH_ROAD,
			CampaignData.QUEENS_SUMMIT])
	# Keep scene-ready inert until the real production return debrief has been
	# rendered.  The test itself then invokes the same deferred handoff method.
	game._web_smoke_d7_stage = "prior_saga_handoff_probe"
	for chapter_id in chapter_order:
		var chapter: Dictionary = game.campaign_state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
	game.campaign_state.relics = ["green_root_rune", "mist_root_rune"]
	game.campaign_state.restorations = ["trophy_hall", "sallow_jetty"]
	if route == "queens" or route == "pale":
		game.campaign_state.relics.append("fang_root_rune")
		game.campaign_state.restorations.append("skald_archive")
	if route == "pale":
		game.campaign_state.relics.append("crown_root_rune")
		game.campaign_state.restorations.append("pale_stair")
	game.trades = Progression.fresh_trade_state()
	for trade_key in ["wayfinding", "wildcraft", "huntcraft", "earthcraft"]:
		game.trades[trade_key] = {"xp": Progression.xp_for_level(23), "lv": 23}
	# Reproduce the production Golden → Seventh boundary: the authored Golden
	# settlement is exactly WF15 / 2016, while Briar's new EC3 support gate is
	# still unearned. The real handoff must use Town gathering + Forge work, not
	# a generic Green practice Chart that adds 85 Wayfinding XP.
	if route == "seventh":
		game.trades.wayfinding = {"xp": 2016, "lv": 15}
		game.trades.earthcraft = Progression.fresh_trade_record()
	# These are only already-cleared chapter entitlements. The test must still
	# perform the source transaction itself (and starts with none of its lesson
	# materials or rumours), exactly as the cumulative D7 handoff does.
	var prior_sources := ["atlas_sallow_shallows"]
	if route == "seventh":
		prior_sources.append("atlas_briar_knot")
	elif route == "queens":
		prior_sources.append_array(["atlas_briar_knot", "skald_queens_summit"])
	else:
		prior_sources.append_array(["atlas_briar_knot", "skald_queens_summit",
			"skald_pale_oath"])
	game.chart_source_unlocks = ChartsData.normalize_chart_source_unlocks(prior_sources)
	game.known_chart_recipes = ChartsData.starting_recipe_ids()
	game.chart_recipe_journal = ChartsData.fresh_recipe_journal()
	game.seen_hints = {"vignette_arrival": true, "chart_table_snug_returned": true}
	game.discovered_inks = ["hedge_ink", "mire_ink", "mothglow_ink", "refined_ink",
		"stoneground_ink"]
	game.materials = {}
	game.charts = []
	game.gold = 2000
	game._sync_campaign_chart_sources()
