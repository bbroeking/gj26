extends SceneTree

# Regression: a real Shallows completion returns to Town with the run debrief
# still owning the offline pause.  The D7 continuation must acknowledge that
# authored modal before it asks PlayerController's Area3D scanner to read the
# newly-unlocked Deep Hollow page of the Living Atlas.  `physics_frame` alone
# is not sufficient while the tree is paused: no scanner `area_entered` signal
# is delivered, so this test proves the actual return -> settle -> E path.

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
	print("--- D7 post-return scanner regression ---")
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
	game._web_smoke_d7_training = {
		"targets": {"wayfinding": 21, "huntcraft": 21,
			"earthcraft": 23, "wildcraft": 14},
		"forge_crafts": 1, "world_legs": 1, "continue_running": true,
	}
	game.modal_count = 0
	paused = false
	_prepare_earned_handoff_fixture(game)

	change_scene_to_file("res://scenes/Town.tscn")
	await process_frame
	await process_frame
	var town := current_scene
	if town != null and town.has_method("_refresh_campaign_settlement_view"):
		town.call("_refresh_campaign_settlement_view")
	if town != null and town.has_method("_refresh_first_knot_homecoming_view"):
		town.call("_refresh_first_knot_homecoming_view")
	await game._wait_d3_town_control()
	# This production continuation makes a physical Town gather/Table/Waystone
	# run, returns through the physical Far Waystone, then reads Deep Hollow via
	# PlayerController's strict scanner helper.  No source state is written here.
	game._d7_resume_after_trade_training("golden_wallow")

	var deadline := Time.get_ticks_msec() + 45000
	while Time.get_ticks_msec() < deadline \
			and not game.web_smoke_history.has("golden_deep_source") \
			and game.web_smoke_phase != "failed":
		await create_timer(0.03, true).timeout
	var deep_status: Dictionary = game.chart_source_status("atlas_deep_hollow")
	check("Shallows return settles its authored debrief before scanner-reading Deep Hollow",
		game.web_smoke_history.has("shallows_return_1")
			and game.web_smoke_history.has("golden_deep_source")
			and String(deep_status.get("state", "")) == "read"
			and (game.chart_recipe_journal.get("rumours", []) as Array).has("atlas_deep_hollow")
			and game.material_count("hedge_sprig") == 1
			and game.material_count("stitched_parchment") == 1
			and game.material_count("hollow_stitch") == 1
			and game.web_smoke_phase != "failed",
		{"phase": game.web_smoke_phase, "history": game.web_smoke_history,
			"deep_status": deep_status, "paused": paused, "modal_count": game.modal_count})

	# The post-source continuation may already have deferred the next physical
	# Table/World leg.  Disable QA dispatch before quitting rather than free a
	# live scene from beneath that production coroutine.
	game.web_smoke_d7_enabled = false
	game.web_smoke_d3_enabled = false
	Engine.time_scale = 1.0
	print("--- D7 post-return scanner regression: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _prepare_earned_handoff_fixture(game: Node) -> void:
	game.campaign_state = CampaignData.empty_state()
	var first: Dictionary = game.campaign_state.chapters[CampaignData.FIRST_KNOT]
	first.cleared = true
	first.clue_count = int(CampaignData.CHAPTERS[CampaignData.FIRST_KNOT].clue_target)
	game.campaign_state.relics = ["green_root_rune"]
	game.campaign_state.restorations = ["trophy_hall"]
	game.trades = Progression.fresh_trade_state()
	for record in [["wayfinding", 21], ["huntcraft", 21], ["earthcraft", 23], ["wildcraft", 14]]:
		var trade_key := String(record[0])
		var level := int(record[1])
		game.trades[trade_key] = {"xp": Progression.xp_for_level(level), "lv": level}
	game.chart_source_unlocks = ChartsData.normalize_chart_source_unlocks(
		["atlas_sallow_shallows", "atlas_deep_hollow"])
	game.known_chart_recipes = ChartsData.starting_recipe_ids()
	game.chart_recipe_journal = ChartsData.fresh_recipe_journal()
	game.seen_hints = {"chart_table_snug_returned": true}
	game.discovered_inks = ["hedge_ink"]
	game.materials = {}
	game.charts = []
	game.gold = 0
