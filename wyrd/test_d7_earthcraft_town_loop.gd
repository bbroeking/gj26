extends SceneTree

# Focused late-state D7 throughput regression.  The fixture establishes only
# the reported Earthcraft-6 boundary; the remaining copper, XP, and outputs
# must come from Town GatherNodes, the player scanner/InputMap path, and Hod's
# real Forge rows.  It never writes material, XP, or a Chart result after setup.

const Progression = preload("res://data/progression.gd")
const CraftStationScript = preload("res://scripts/craft_station.gd")

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
	print("--- D7 Earthcraft Town loop ---")
	Engine.time_scale = 6.0
	var game = root.get_node_or_null("Game")
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.persistence_enabled = false
	game.web_smoke_enabled = true
	game.web_smoke_d7_enabled = true
	game.web_smoke_phase = "earthcraft_town_probe"
	game.web_smoke_history = []
	game.web_smoke_features = {}
	game.modal_count = 0
	paused = false
	game.tutorial_step = 7
	# These first-use lessons belong to earlier physical training evidence.  This
	# focused late-state test must measure the remaining mining + Forge path, not
	# a fresh DialogPanel acknowledgement.
	game.seen_hints = {"chart_table_snug_returned": true, "ore_rock": true,
		"forge": true, "forage_node": true, "log_pile": true, "affix_reading": true}
	game.materials = {}
	game.trades = Progression.fresh_trade_state()
	for record in [["wayfinding", 23], ["huntcraft", 23], ["wildcraft", 23], ["earthcraft", 6]]:
		var trade_key := String(record[0])
		var level := int(record[1])
		game.trades[trade_key] = {"xp": Progression.xp_for_level(level), "lv": level}
	game._web_smoke_d7_training = {"forge_crafts": 0}

	change_scene_to_file("res://scenes/Town.tscn")
	await process_frame
	await process_frame
	var started := Time.get_ticks_msec()
	var completed: bool = await game._d7_training_forge_copper({"earthcraft": 23})
	var elapsed := Time.get_ticks_msec() - started
	var evidence: Dictionary = game._web_smoke_d7_training.get("earthcraft_town_loop", {})
	print("  [EC6→23] %s" % str({
		"elapsed_msec": elapsed,
		"xp_before": evidence.get("xp_before", -1),
		"xp_after": evidence.get("xp_after", -1),
		"level_after": game.trade_lv("earthcraft"),
		"bogiron_nodes_requested": evidence.get("bogiron_nodes_requested", -1),
		"bogiron_bars": evidence.get("bogiron_bars", -1),
		"forge_transactions": evidence.get("forge_transactions", -1),
	}))
	check("Earthcraft 6 reaches 23 through renewable Town Bogiron and real Forge rows",
		completed and game.trade_lv("earthcraft") >= 23
			and int(evidence.get("xp_delta", 0)) > 0
			and int(evidence.get("bogiron_nodes_requested", 0)) > 0
			and int(evidence.get("bogiron_bars", 0)) > 0
			and int(evidence.get("forge_transactions", 0)) > 0
			and game.material_count("bogiron_bar") > 0
			and int(game._web_smoke_d7_training.get("forge_crafts", 0)) \
				== int(evidence.get("forge_transactions", -1))
			and elapsed < 90000 and not paused and game.modal_count == 0,
		{"elapsed_msec": elapsed, "trades": game.trades, "materials": game.materials,
			"evidence": evidence})
	check("the late Town loop records its physical throughput telemetry",
		bool(game.web_smoke_features.get("d7_training_earthcraft_town_loop", false))
			and int(evidence.get("elapsed_msec", -1)) >= 0,
		evidence)

	# A player may return to Town with a legitimate ore surplus.  That should
	# reduce mining, not strand the driver waiting for a gather that it does not
	# need; every XP point here still comes from Hod's real Bogiron Bar rows.
	game.materials = {"bogiron_ore": 108}
	game.trades["earthcraft"] = {"xp": Progression.xp_for_level(18), "lv": 18}
	game._web_smoke_d7_training = {"forge_crafts": 0}
	var surplus_started := Time.get_ticks_msec()
	var surplus_completed: bool = await game._d7_training_forge_copper({"earthcraft": 20})
	var surplus_elapsed := Time.get_ticks_msec() - surplus_started
	var surplus: Dictionary = game._web_smoke_d7_training.get("earthcraft_town_loop", {})
	check("preexisting Bogiron surplus finishes through Forge rows without forced mining",
		surplus_completed and game.trade_lv("earthcraft") >= 20
			and int(surplus.get("bogiron_nodes_requested", -1)) == 0
			and int(surplus.get("bogiron_bars", 0)) >= 54
			and int(surplus.get("forge_transactions", 0)) >= 54
			and int(surplus.get("xp_delta", 0)) >= 640
			and surplus_elapsed < 30000 and not paused and game.modal_count == 0,
		{"elapsed_msec": surplus_elapsed, "trades": game.trades,
			"materials": game.materials, "evidence": surplus})

	# The post-Fire path uses the same two-stage CraftPanel contract. Supply a
	# focused legitimate input fixture, mount the real CraftStation beside the
	# player, and let the D7 scanner + recipe-row + primary-action driver perform
	# every Forge conversion and the final Kiln transaction.
	# Carry forward Bogiron Bars already earned during training. The post-clear
	# chain must consume them instead of demanding redundant raw ore.
	game.materials = {"bogiron_bar": 2, "wildgold_ore": 4, "logs": 4}
	game.trades["earthcraft"] = {"xp": Progression.xp_for_level(20), "lv": 20}
	if not (game.campaign_state.restorations as Array).has("ember_kiln"):
		(game.campaign_state.restorations as Array).append("ember_kiln")
	var kiln: Node3D = CraftStationScript.new()
	kiln.name = "D7FocusedEmberKiln"
	kiln.setup("ember_kiln")
	var player := game.local_player() as Node3D
	kiln.position = player.position + Vector3(4.0, 0.0, 0.0)
	current_scene.add_child(kiln)
	await physics_frame
	await physics_frame
	var alloy_before: int = game.material_count("starheart_alloy")
	var fire_inputs_completed: bool = await game._d7_craft_starheart_alloy(kiln)
	# Earthcraft 20 has Smith's Thrift, so a valid transaction may return raw
	# ore or logs. Assert the consumed intermediate chain and final output, not
	# the randomized raw-input remainder.
	check("Fire inputs and Starheart Alloy use recipe selection plus the real primary actions",
		fire_inputs_completed
			and game.material_count("starheart_alloy") == alloy_before + 1
			and game.material_count("bogiron_bar") == 0
			and game.material_count("wildgold_bar") == 0
			and game.material_count("emberglass") == 0
			and not paused and game.modal_count == 0,
		{"materials": game.materials, "modal_count": game.modal_count,
			"paused": paused})

	game.web_smoke_d7_enabled = false
	if current_scene != null:
		current_scene.queue_free()
		await process_frame
	Engine.time_scale = 1.0
	print("--- D7 Earthcraft Town loop: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)
