extends SceneTree

# Native seam probe for D7's strict fresh-marathon training adapter.  The
# broader Web route owns the title/new-journey proof; this focused cumulative
# probe starts at its legitimate post-First-Knot boundary and drives eight
# consecutive physical Green Hollow laps through one persistent Game state:
# Town forge + Table, Waystone, the deterministic baseline resource triad,
# Combatant kills, and Far Waystone return. The fixture establishes only the
# already-earned chapter boundary/lesson, never Trade, material, Chart, or run
# outcomes for any lap.

const CampaignData = preload("res://data/campaign.gd")
const ChartsData = preload("res://data/charts.gd")
const Progression = preload("res://data/progression.gd")
const DialogPanelScript = preload("res://scripts/ui/dialog_panel.gd")

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
	print("--- D7 trade-training cumulative native seam ---")
	# The default remains the fast eight-leg seam.  The opt-in full-target probe
	# starts from the same legitimate First Knot handoff and proves that the
	# production route reaches its authored gates without a marathon of extra
	# Charts once Town Bogiron becomes the remaining road.
	var full_target_probe := not OS.get_environment("WYRD_D7_FULL_TARGET_PROBE").is_empty()
	var probe_legs := 8
	var targets := {"wayfinding": 23, "huntcraft": 23, "earthcraft": 2, "wildcraft": 2}
	if full_target_probe:
		targets = {"wayfinding": 21, "huntcraft": 21, "earthcraft": 23, "wildcraft": 14}
	# Speed only engine dwell; every scanner approach, panel action, channel,
	# combat callback, and Far Waystone interaction remains the shipped path.
	Engine.time_scale = 6.0
	var game = root.get_node_or_null("Game")
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.persistence_enabled = false
	game.web_smoke_enabled = true
	game.web_smoke_d7_enabled = true
	game.web_smoke_phase = "training_probe"
	game.web_smoke_history = []
	game.web_smoke_features = {}
	game.modal_count = 0
	paused = false
	game.tutorial_step = 7
	# Leave ore, Forge, chopping, and affix reading fresh. The production driver
	# must close each matching teaching DialogPanel through its public seam before
	# the next Town or World scanner action can continue.
	game.seen_hints = {"chart_table_snug_returned": true, "forage_node": true,
		"bench": true}
	game.known_chart_recipes = ["snug", "green_hollow"]
	game.chart_recipe_journal = ChartsData.normalize_recipe_journal(
		ChartsData.fresh_recipe_journal(), game.known_chart_recipes)
	game.gold = 500
	game.materials = {}
	game.trades = Progression.fresh_trade_state()
	game.campaign_state = CampaignData.empty_state()
	var first: Dictionary = game.campaign_state.chapters[CampaignData.FIRST_KNOT]
	first.cleared = true
	first.clue_count = int(CampaignData.CHAPTERS[CampaignData.FIRST_KNOT].clue_target)
	game.campaign_state = CampaignData.normalize_campaign_state(game.campaign_state)

	change_scene_to_file("res://scenes/Town.tscn")
	await process_frame
	await process_frame
	# Reproduce the First Knot handoff race from release Web: the Town's exact
	# Homecoming debrief owns the offline pause just as training is scheduled.
	# The process-always scheduler must enter Town control and finish this real
	# authored dialog through its public `_finish` seam before the first forge.
	var handoff_dialog: CanvasLayer = DialogPanelScript.new()
	handoff_dialog.name = "FirstKnotHomecomingDebrief"
	handoff_dialog.add_to_group("FirstKnotHomecomingDebrief")
	handoff_dialog.open("The First Knot", [
		"The rain has eased on the yard. Someone has set a small alcove by the fence, "
		+ "with room for a green mark and a hard-won record.",
		"No bells. Just the kettle, the wet road, and Bramblewood making space for you.",
	])
	current_scene.add_child(handoff_dialog)
	await process_frame
	game._d7_begin_trade_training("native_probe", targets)
	if full_target_probe:
		game._web_smoke_d7_training["stop_after_complete"] = true
	else:
		game._web_smoke_d7_training["pause_after_world_legs"] = probe_legs

	# The full route builds every real World scene; its safety cap is the 60-leg
	# contract below, while this wall-clock allowance leaves room for headless
	# navmesh construction on slower CI machines.
	var deadline := Time.get_ticks_msec() + (600000 if full_target_probe else 210000)
	while Time.get_ticks_msec() < deadline and game.web_smoke_phase != "failed" \
			and (not game.web_smoke_history.has("trade_training_probe_complete") \
				if full_target_probe else (int(game._web_smoke_d7_training.get("world_legs", 0)) < probe_legs \
					or int(game._web_smoke_d7_training.get("town_settlements", 0)) < probe_legs)):
		await create_timer(0.05, true).timeout
	# A timeout is a test outcome, never permission to free the active Town/World
	# while its production coroutine is still awaiting a scanner/UI frame. Stop
	# future D7 scheduling, mark the route failed, and give process-always work a
	# bounded chance to observe that state before assertions or scene teardown.
	if full_target_probe and not game.web_smoke_history.has("trade_training_probe_complete") \
			and game.web_smoke_phase != "failed":
		game.web_smoke_d7_enabled = false
		game.web_smoke_phase = "failed"
		game._web_smoke_d7_stage = "native_probe_timeout"
		var join_deadline := Time.get_ticks_msec() + 20000
		while Time.get_ticks_msec() < join_deadline and \
				(bool(game._web_smoke_d7_training.get("town_driver_active", false)) \
					or bool(game._web_smoke_d7_training.get("world_driver_active", false))):
			await create_timer(0.05, true).timeout
		game._web_smoke_d7_training["timeout_quiescent"] = \
			not bool(game._web_smoke_d7_training.get("town_driver_active", false)) \
				and not bool(game._web_smoke_d7_training.get("world_driver_active", false))
		await process_frame
	# The final returned World legitimately opens its debrief. Close it through
	# the production Town-control seam before asserting that every cumulative
	# return settled and the fresh Forge/chopping lessons did not leak a modal.
	if not full_target_probe:
		await game._wait_d7_town_control()

	var completed_full_targets: bool = game.trade_lv("wayfinding") >= int(targets.wayfinding) \
		and game.trade_lv("huntcraft") >= int(targets.huntcraft) \
		and game.trade_lv("earthcraft") >= int(targets.earthcraft) \
		and game.trade_lv("wildcraft") >= int(targets.wildcraft)
	var expected_laps_met: bool = game.web_smoke_history.has("trade_training_probe_complete") \
		if full_target_probe else int(game._web_smoke_d7_training.get("runs", 0)) == probe_legs
	check("%s Green Hollow route settled through the real World path" % \
		("full-target" if full_target_probe else "%d-lap" % probe_legs),
		expected_laps_met
			and (completed_full_targets if full_target_probe else true)
			and (int(game._web_smoke_d7_training.get("world_legs", 0)) <= 60 \
				if full_target_probe else int(game._web_smoke_d7_training.get("world_legs", 0)) == probe_legs)
			and int(game._web_smoke_d7_training.get("town_settlements", 0)) \
				== int(game._web_smoke_d7_training.get("world_legs", 0))
			and bool(game.web_smoke_features.get("d7_real_far_waystone", false))
			and game.web_smoke_phase != "failed" and game.modal_count == 0
			and not paused and current_scene != null and current_scene.name == "Town"
			and not is_instance_valid(handoff_dialog), {
			"stage": game._web_smoke_d7_stage,
			"phase": game.web_smoke_phase,
			"training": game._web_smoke_d7_training,
			"seen": game._web_smoke_d7_training_seen_kinds,
			"far_waystone": game._web_smoke_d7_far_waystone_detail,
		})
	check("D7 training used physical Table, forge, Waystone, and Far Waystone seams",
		bool(game.web_smoke_features.get("d7_training_real_table", false))
			and int(game._web_smoke_d7_training.get("forge_crafts", 0)) > 0
			and bool(game.web_smoke_features.get("d7_training_component_economy", false))
			and int(game._web_smoke_d7_training.get("component_gold_spent", 0)) \
				>= (1 if full_target_probe else probe_legs)
			and bool(game.web_smoke_features.get("d7_real_town_waystone", false))
			and bool(game.web_smoke_features.get("d7_real_far_waystone", false)),
		game.web_smoke_features)
	check("baseline ore, forage, and log nodes all used scanner-driven production channels",
		game.trade_lv("huntcraft") > 1 and game.trade_lv("earthcraft") > 1
			and game.trade_lv("wildcraft") > 1
			and bool(game._web_smoke_d7_training_seen_kinds.get("ore_rock", false))
			and bool(game._web_smoke_d7_training_seen_kinds.get("forage_node", false))
			and bool(game._web_smoke_d7_training_seen_kinds.get("log_pile", false)),
		{"trades": game.trades, "seen": game._web_smoke_d7_training_seen_kinds})
	check("fresh ore, Forge, chopping, and affix-reading lessons release their real modal before the next scanner action",
		game.modal_count == 0 and bool(game.seen_hints.get("forge", false))
			and bool(game.seen_hints.get("ore_rock", false))
			and bool(game.seen_hints.get("log_pile", false))
			and bool(game.seen_hints.get("affix_reading", false))
			and int(game._web_smoke_d7_training.get("forge_crafts", 0)) > 0
			and bool(game._web_smoke_d7_training_seen_kinds.get("log_pile", false)),
		{"modal_count": game.modal_count, "seen_hints": game.seen_hints,
			"training": game._web_smoke_d7_training})
	if full_target_probe:
		var earthcraft_loop: Dictionary = game._web_smoke_d7_training.get("earthcraft_town_loop", {})
		check("full-target probe finishes Earthcraft in the bounded Town Bogiron loop",
			int(earthcraft_loop.get("bogiron_bars", 0)) > 0
				and int(earthcraft_loop.get("forge_transactions", 0)) > 0
				and int(earthcraft_loop.get("elapsed_msec", 180001)) < 90000,
			earthcraft_loop)

	game.web_smoke_d7_enabled = false
	game._web_smoke_d7_stage = "native_probe_complete"
	var timeout_join_failed: bool = full_target_probe \
		and game.web_smoke_phase == "failed" \
		and not bool(game._web_smoke_d7_training.get("timeout_quiescent", true))
	if timeout_join_failed:
		# Do not free a live scene under a still-running production coroutine.
		# This intentionally leaves the failed probe intact for the harness rather
		# than converting a join failure into a use-after-free during cleanup.
		failed += 1
		print("  ✗ full-target timeout driver did not quiesce; scene teardown skipped")
	else:
		await shutdown_runtime()
	print("--- D7 trade training: %d PASS, %d FAIL ---" % [passed, failed])
	# Let the headless runner flush the summary before SceneTree.quit tears down
	# the process; the full-target probe is otherwise needlessly opaque in CI.
	await process_frame
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
