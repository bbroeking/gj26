extends SceneTree

# Focused native regression for the strict D7 fresh-marathon opening. It starts
# at the shipped title, presses the real New Journey control through the
# query-gated driver, and waits until the First Knot is settled and the
# first production source of Golden Wallow is reached. The test deliberately never
# writes Trade XP, materials, Charts, campaign, source, or settlement results:
# every one is owned by the released UI, World, and campaign callbacks.

const CampaignData = preload("res://data/campaign.gd")
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
	print("--- D7 fresh First Knot native seam ---")
	var game = root.get_node_or_null("Game")
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.persistence_enabled = false
	# These are only the release-driver switches. The title, UI controls,
	# gathering, Chart commits, World runs, boss death, and settlement remain
	# production-owned.
	game.web_smoke_enabled = true
	game.web_smoke_d1_enabled = false
	game.web_smoke_d7_enabled = true
	game.web_smoke_phase = ""
	game.web_smoke_history = []
	game.web_smoke_features = {}
	game._web_smoke_d1_stage = ""
	game._web_smoke_d7_stage = ""
	game._web_smoke_d7_training = {}
	game._web_smoke_d7_training_seen_kinds = {}
	game.modal_count = 0
	paused = false
	# Test-only dwell acceleration: all rewards still flow through normal
	# channels, UI commits, World callbacks, and the campaign resolver.
	Engine.time_scale = 4.0

	# MainMenu notifies Game only after it has built the visible controls. D7
	# then presses that same Begin a New Journey button a player uses.
	change_scene_to_file("res://scenes/Main.tscn")
	await process_frame
	await process_frame

	var deadline := Time.get_ticks_msec() + 180000
	while Time.get_ticks_msec() < deadline \
			and not game.web_smoke_history.has("golden_source") \
			and game.web_smoke_phase != "failed":
		await create_timer(0.05, true).timeout

	var first: Dictionary = (game.campaign_state.get("chapters", {}) as Dictionary).get(
		CampaignData.FIRST_KNOT, {})
	var first_knotted := CampaignData.chapter_cleared(game.campaign_state,
		CampaignData.FIRST_KNOT) \
		and int(first.get("clue_count", 0)) == int(
			CampaignData.CHAPTERS[CampaignData.FIRST_KNOT].clue_target) \
		and (game.campaign_state.get("relics", []) as Array).has("green_root_rune") \
		and (game.campaign_state.get("restorations", []) as Array).has("trophy_hall")
	check("fresh title path settled First Knot through its campaign callback", first_knotted, {
		"stage": game._web_smoke_d7_stage,
		"phase": game.web_smoke_phase,
		"chapter": first,
		"relics": game.campaign_state.get("relics", []),
		"restorations": game.campaign_state.get("restorations", []),
	})
	check("fresh path used the released first-chapter UI and World seams",
		bool(game.web_smoke_features.get("d7_real_title_new_journey", false)) \
			and bool(game.web_smoke_features.get("d1_world_interact_table", false)) \
			and bool(game.web_smoke_features.get("d1_production_ink_mixing", false)) \
			and bool(game.web_smoke_features.get("d1_green_table_commit", false)) \
			and bool(game.web_smoke_features.get("d1_world_campaign_boss", false)) \
			and bool(game.web_smoke_features.get("d1_boss_death_host_resolver", false)) \
			and bool(game.web_smoke_features.get("d1_homecoming_hall_projection", false)) \
			and bool(game.web_smoke_features.get("d1_homecoming_copy_only", false)),
		game.web_smoke_features)
	var unique_green_ids := {}
	for chart_id_v in game._web_smoke_d1_green_ids:
		unique_green_ids[String(chart_id_v)] = true
	var d7_handoff_history := [
		"first_knot_complete",
		"golden_source",
	]
	var handoff_history_cursor := 0
	var d7_handoff_ordered := true
	for handoff_phase in d7_handoff_history:
		var handoff_phase_index: int = game.web_smoke_history.find(handoff_phase,
			handoff_history_cursor)
		if handoff_phase_index < 0:
			d7_handoff_ordered = false
			break
		handoff_history_cursor = handoff_phase_index + 1
	check("three distinct physical Green Hollows banked the authored clue ledger",
		game._web_smoke_d1_green_ids.size() == 3 \
			and unique_green_ids.size() == 3 \
			and (first.get("banked_chart_ids", []) as Array).size() == 3,
		{"green_ids": game._web_smoke_d1_green_ids, "chapter": first})
	var first_knot_ledger: Dictionary = {}
	for ledger_v in game.web_smoke_features.get("d7_progressive_level_ledger", []):
		var ledger := ledger_v as Dictionary
		if String(ledger.get("label", "")) == "first_knot_settlement":
			first_knot_ledger = ledger
			break
	check("First Knot reaches Golden's WF9 entry through support-only Wildcraft preparation",
		game._web_smoke_d7_stage == "prior_golden_wallow" \
			and d7_handoff_ordered \
			and not game.web_smoke_history.has("trade_training_start") \
			and game._d7_progressive_training_targets("golden_wallow") == {
				"wayfinding": 9, "huntcraft": 1, "earthcraft": 1, "wildcraft": 10} \
			and int(((first_knot_ledger.get("trades", {}) as Dictionary).get(
				"wayfinding", {}) as Dictionary).get("level", 0)) == 9 \
			and int(((first_knot_ledger.get("trades", {}) as Dictionary).get(
				"wayfinding", {}) as Dictionary).get("xp", -1)) == 768 \
			and game.chart_recipe_known("green_hollow") \
			and game.trades != Progression.fresh_trade_state(), {
		"stage": game._web_smoke_d7_stage,
		"phase": game.web_smoke_phase,
		"expected_handoff": d7_handoff_history,
		"history": game.web_smoke_history,
		"training": game._web_smoke_d7_training,
			"trades": game.trades,
			"known": game.known_chart_recipes,
		})
	check("the strict route did not report a failure or leave a boss escrow open",
		game.web_smoke_phase != "failed" \
			and not CampaignData.has_open_escrow(game.campaign_state, CampaignData.FIRST_KNOT), {
			"phase": game.web_smoke_phase,
			"history": game.web_smoke_history,
			"escrows": game.campaign_state.get("escrows", {}),
			"active_chart": game.active_chart,
		})

	# Stop precisely at the native source boundary. This is only release-driver
	# evidence, never saved or gameplay state.
	game.web_smoke_d7_enabled = false
	game.web_smoke_d1_enabled = false
	game.web_smoke_phase = "failed"
	await create_timer(0.9, true, false, true).timeout
	await shutdown_runtime()
	print("--- D7 fresh First Knot: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)


func shutdown_runtime() -> void:
	if current_scene != null:
		current_scene.queue_free()
		await process_frame
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("shutdown"):
		sfx.call("shutdown")
	Engine.time_scale = 1.0
	await create_timer(0.2, true, false, true).timeout
