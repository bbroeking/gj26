extends SceneTree

# Focused regression for the D7 → Golden Wallow dispatcher handoff. The fixture
# supplies only the already-earned D7/First Knot boundary; the Shallows and
# Deep Hollow sources, every Table/Waystone/World/Far return, Mara's rain note,
# Mire Ink, and the Golden boss preview are production. Before the ownership
# transfer this reaches `shallows_table_1`, then D7's generic World branch
# fails because its stage is still `training_town`.

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
	print("--- D7 Golden Wallow dispatcher handoff ---")
	Engine.time_scale = 6.0
	var game = root.get_node_or_null("Game")
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.persistence_enabled = false
	game.web_smoke_enabled = true
	game.web_smoke_d1_enabled = false
	game.web_smoke_d3_enabled = false
	game.web_smoke_d7_enabled = true
	game.web_smoke_phase = ""
	game.web_smoke_history = []
	game.web_smoke_features = {}
	game._web_smoke_d3_stage = ""
	game._web_smoke_d3_shallows_ids = []
	game._web_smoke_d7_stage = "training_town"
	game._web_smoke_d7_training_seen_kinds = {
		"ore_rock": true, "forage_node": true, "log_pile": true}
	var golden_targets: Dictionary = game._d7_progressive_training_targets("golden_wallow")
	game._web_smoke_d7_training = {
		"targets": golden_targets,
		"forge_crafts": 1, "world_legs": 1, "continue_running": true,
	}
	game.modal_count = 0
	paused = false
	prepare_earned_handoff_fixture(game)
	check("earned handoff begins without Golden-route materials or Mara's note",
		game.material_count("waxed_vellum") == 0 and game.material_count("mire_reed") == 0
			and game.material_count("sunk_knot") == 0 and game.material_count("mothmint") == 0
			and not game.chart_source_unlocks.has("mara_sallow_reed")
			and not (game.chart_recipe_journal.get("rumours", []) as Array).has("mara_sallow_reed"))
	assert_dispatch_route_matrix(game)
	# Restore the exact earned boundary after the two negative dispatch probes.
	reset_terminal_probe(game)
	game._web_smoke_d3_stage = ""
	game._web_smoke_d7_stage = "training_town"
	game.web_smoke_d3_enabled = false

	change_scene_to_file("res://scenes/Town.tscn")
	await process_frame
	await process_frame
	var town := current_scene
	if town != null and town.has_method("_refresh_campaign_settlement_view"):
		town.call("_refresh_campaign_settlement_view")
	if town != null and town.has_method("_refresh_first_knot_homecoming_view"):
		town.call("_refresh_first_knot_homecoming_view")
	await game._wait_d3_town_control()
	await game._d7_resume_after_trade_training("golden_wallow")

	# The earned route now keeps Mara's level-12 lesson behind Shallows two and
	# three.  Give those two additional real Table/World/Far-Waystone legs their
	# own native wall budget; the release-Web marathon still has its independent
	# terminal watchdog.
	var deadline := Time.get_ticks_msec() + 120000
	while Time.get_ticks_msec() < deadline \
			and not game.web_smoke_history.has("boar_preview") \
			and game.web_smoke_phase != "failed":
		await create_timer(0.03, true).timeout
	check("earned D7 completes the Golden source, Deep Hollow, and boss-preview progression",
		game._web_smoke_d7_stage == "prior_golden_wallow"
			and game.web_smoke_d3_enabled
			and game.web_smoke_history.has("golden_source")
			and game.web_smoke_history.has("shallows_table_1")
			and game.web_smoke_history.has("shallows_world_1")
			and game.web_smoke_history.has("shallows_return_1")
			and game.web_smoke_history.has("atlas_deep_source")
			and game.web_smoke_history.has("deep_table")
			and game.web_smoke_history.has("deep_world")
			and game.web_smoke_history.has("deep_far_return")
			and game.web_smoke_history.has("mara_sallow_source")
			and game.web_smoke_history.has("golden_deep_source")
			and game.web_smoke_history.has("golden_deep_table")
			and game.web_smoke_history.has("golden_deep_world")
			and game.web_smoke_history.has("golden_deep_far_return")
			and game.web_smoke_history.has("golden_mire_note")
			and game.web_smoke_history.has("shallows_world_2")
			and game.web_smoke_history.has("shallows_world_3")
			and game.web_smoke_history.has("mire_ink")
			and game.web_smoke_history.has("boar_preview")
			and bool(game.web_smoke_features.get("d7_golden_deep_hollow_source", false))
			and bool(game.web_smoke_features.get("d7_golden_deep_hollow_table", false))
			and bool(game.web_smoke_features.get("d7_golden_mire_note", false))
			and bool(game.web_smoke_features.get("d3_mire_ink_production_controls", false))
			and bool(game.web_smoke_features.get("d3_boar_preview_contract", false))
			and game.web_smoke_phase != "failed",
		{"d7_stage": game._web_smoke_d7_stage, "d3_stage": game._web_smoke_d3_stage,
			"phase": game.web_smoke_phase, "history": game.web_smoke_history})
	check("Golden Deep Hollow follows the authored source-to-boss ordering",
		markers_appear_in_order(game.web_smoke_history, [
			"shallows_return_1", "atlas_deep_source", "golden_deep_source",
			"deep_table", "golden_deep_table", "deep_world", "golden_deep_world",
			"deep_far_return", "golden_deep_far_return",
			"shallows_return_2", "shallows_return_3", "mara_sallow_source",
			"golden_mire_note", "mire_ink", "boar_preview",
		]), game.web_smoke_history)
	var combat_receipts: Array = game.web_smoke_features.get(
		"d7_prior_saga_combat_gather_receipts", [])
	var combat_before_gather := combat_receipts.size() == 4
	for receipt_v in combat_receipts:
		var receipt: Dictionary = receipt_v
		var events: Array = receipt.get("events", [])
		combat_before_gather = combat_before_gather \
			and int(receipt.get("kills", 0)) > 0 \
			and int(receipt.get("kill_passes", 0)) == 1 \
			and bool(receipt.get("settled_before_gather", false)) \
			and not events.is_empty() and String(events[0]) == "combat_clear" \
			and (int(receipt.get("gather_candidates", 0)) == 0 \
				or (events.size() == 2 and String(events[1]) == "gather_scan"))
	check("each prior-saga World clears combat once before its first gather scanner",
		combat_before_gather
			and bool(game.web_smoke_features.get(
				"d7_prior_saga_combat_before_gather", false)), combat_receipts)

	game.web_smoke_d7_enabled = false
	game.web_smoke_d3_enabled = false
	game.web_smoke_phase = "failed"
	# The successful World dispatch has deferred D7's normal production harvest.
	# Do not free that World underneath its coroutine; disabling D7 above makes
	# its first guard return and SceneTree.quit owns final cleanup.
	Engine.time_scale = 1.0
	print("--- D7 Golden Wallow dispatcher handoff: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)


func prepare_earned_handoff_fixture(game: Node) -> void:
	game.campaign_state = CampaignData.empty_state()
	var first: Dictionary = game.campaign_state.chapters[CampaignData.FIRST_KNOT]
	first.cleared = true
	first.clue_count = int(CampaignData.CHAPTERS[CampaignData.FIRST_KNOT].clue_target)
	game.campaign_state.relics = ["green_root_rune"]
	game.campaign_state.restorations = ["trophy_hall"]
	game.trades = Progression.fresh_trade_state()
	var targets: Dictionary = game._d7_progressive_training_targets("golden_wallow")
	for trade_key_v in targets:
		var trade_key := String(trade_key_v)
		var level := int(targets[trade_key_v])
		game.trades[trade_key] = {"xp": Progression.xp_for_level(level), "lv": level}
	game.chart_source_unlocks = ChartsData.normalize_chart_source_unlocks(
		["atlas_sallow_shallows", "atlas_deep_hollow"])
	game.known_chart_recipes = ChartsData.starting_recipe_ids()
	game.chart_recipe_journal = ChartsData.fresh_recipe_journal()
	game.seen_hints = {"chart_table_snug_returned": true}
	game.discovered_inks = ["hedge_ink"]
	# The handoff starts with no Golden-route ingredients. Its ink runway, source
	# kits, and Mire Ink must all come from the physical Town/World/Table route.
	game.materials = {}
	game.charts = []
	game.gold = 0


func assert_dispatch_route_matrix(game: Node) -> void:
	# D7 stays first: an old D3 stage cannot capture a current Fire training
	# World arrival, even while its flag is stale/true.
	game.web_smoke_d3_enabled = true
	game._web_smoke_d3_stage = "shallows_1"
	game._web_smoke_d7_stage = "training_town"
	game.web_smoke_phase = "route_matrix_stale_d3"
	game._web_smoke_d7_scene_ready("World")
	check("stale Golden state cannot steal a D7 training World dispatch",
		game._web_smoke_d7_stage == "failed" and game.web_smoke_phase == "failed",
		{"stage": game._web_smoke_d7_stage, "phase": game.web_smoke_phase,
			"history": game.web_smoke_history})
	# Each matrix row represents an independent Web run. Production correctly
	# freezes the first terminal payload, so the shared test fixture must clear
	# that latch before exercising the next row.
	reset_terminal_probe(game)

	# A transferred D7 stage is likewise invalid until the D3 owner is explicitly
	# enabled. This protects the intentional D7-first precedence from a dormant
	# prior-route handler.
	game.web_smoke_d3_enabled = false
	game._web_smoke_d3_stage = "shallows_1"
	game._web_smoke_d7_stage = "prior_golden_wallow"
	game.web_smoke_phase = "route_matrix_missing_owner"
	game._web_smoke_d7_scene_ready("World")
	check("Golden stage without active D3 owner fails closed under D7",
		game._web_smoke_d7_stage == "failed" and game.web_smoke_phase == "failed",
		{"stage": game._web_smoke_d7_stage, "phase": game.web_smoke_phase,
			"history": game.web_smoke_history})


func reset_terminal_probe(game: Node) -> void:
	game.web_smoke_phase = ""
	game.web_smoke_history = []
	game._web_smoke_terminal_latched = false
	game._web_smoke_terminal_payload = {}


func markers_appear_in_order(history: Array, markers: Array) -> bool:
	var next := 0
	for marker_v in history:
		if next < markers.size() and String(marker_v) == String(markers[next]):
			next += 1
	return next == markers.size()


func shutdown_runtime() -> void:
	if current_scene != null:
		current_scene.queue_free()
		await process_frame
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("shutdown"):
		sfx.call("shutdown")
	Engine.time_scale = 1.0
	await create_timer(0.2, true, false, true).timeout
