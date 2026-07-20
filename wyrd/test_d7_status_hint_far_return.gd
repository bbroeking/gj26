extends SceneTree

# D7 regression: a real status lesson may arrive from combat timing after a
# successful World gather.  The production driver must finish only that exact
# authored DialogPanel before it scanner-targets the real Far Waystone.

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
	print("--- D7 status hint before Far Waystone ---")
	Engine.time_scale = 6.0
	var game = root.get_node_or_null("Game")
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.persistence_enabled = false
	game.web_smoke_enabled = true
	# Enable the D7 driver only after World has loaded. This focused test owns
	# the gather/status/return sequence itself and must not launch the full
	# chapter driver from the scene-ready hook.
	game.web_smoke_d7_enabled = false
	game.web_smoke_phase = "status_hint_far_return_probe"
	game.web_smoke_features = {}
	game._web_smoke_d7_training = {"world_status_hints_finished": []}
	game.modal_count = 0
	paused = false
	game.tutorial_step = 7
	# Status bleed intentionally remains unseen; ordinary World lessons are not
	# part of this timing regression.
	game.seen_hints = {"chart_table_snug_returned": true, "forage_node": true,
		"affix_reading": true, "ore_rock": true, "log_pile": true}
	game.trades = Progression.fresh_trade_state()
	for record in [["wayfinding", 10], ["huntcraft", 8], ["earthcraft", 6], ["wildcraft", 6]]:
		var trade_key := String(record[0])
		var level := int(record[1])
		game.trades[trade_key] = {"xp": Progression.xp_for_level(level), "lv": level}
	game.active_chart = {
		"chart_instance_id": "d7-status-return", "template_id": "tier_1",
		"recipe_id": "green_hollow", "tier": 1, "scope": "hollow",
		# This is deliberately multi-fold. The real first press opens the Far
		# Waystone choice (`_used == false`), then the driver's real "Return
		# safely" button press marks the exact stone used before Town's deferred
		# scene transition. That is the fast-Web boundary this regression owns.
		"name": "Green Hollow", "seed": 396698890, "layer": 1, "max_layers": 2,
		"affixes": [{"id": "bramble_bloom", "good": true,
			"resolvedId": "bramble_bloom__good"}],
	}
	game.in_dungeon = true

	change_scene_to_packed(load("res://scenes/World.tscn"))
	await process_frame
	await process_frame
	await physics_frame
	var owner_token: Dictionary = game._d7_capture_world_owner_token("status_hint_regression")
	var target: Node3D = null
	for node_v in get_nodes_in_group("interactable"):
		if node_v is Node3D and str(node_v.get("kind")) == "forage_node" \
				and not bool(node_v.call("is_used")):
			target = node_v as Node3D
			break
	var player := game.local_player() as Node3D
	var before: int = game.material_count(String(target.get("item_id"))) if target != null else -1
	var harvested := false
	var status_edge := {"applied": false}
	if target != null:
		# Hold the real channel open long enough to land PlayerController's actual
		# bleed callback during it. The paused lesson then reproduces the release
		# edge: scanner reports zero material delta before its normal timeout.
		target.set("_tier_channel", 5.0)
		var status_timer := create_timer(0.5, true)
		status_timer.timeout.connect(func() -> void:
			if bool(target.get("_channeling")) and player != null and player.has_method("apply_status"):
				game.web_smoke_d7_enabled = true
				player.call("apply_status", "bleed", 2.0, 0, 1.0, 0.0)
				status_edge["applied"] = true)
		harvested = await game._d7_scanner_harvest(target, String(target.get("item_id")), 1200)
	var after: int = game.material_count(String(target.get("item_id"))) if target != null else -1
	check("real bleed opens during an active gather and leaves the scanner with zero yield",
		target != null and bool(status_edge.get("applied", false)) and not harvested and after == before,
		{"target": game._d7_interactable_snapshot(target), "harvest": game._web_smoke_d7_last_harvest_detail})

	# This is PlayerController's real status path: it marks the authored hint as
	# seen and opens its exact DialogPanel. No dialog is fabricated by the test.
	await process_frame
	var expected_pages: Array = (game.SKILL_HINTS.status_bleed as Array)[1]
	var status_dialog: Node = null
	for child in current_scene.get_children():
		if child != null and child.has_node("DialogueShell") \
				and String(child.get("_speaker")) == "Mara Linnet, the Wayfinder" \
				and (child.get("_pages") as Array) == expected_pages:
			status_dialog = child
			break
	check("real bleed status opens only the authored status-bleed lesson",
		status_dialog != null and game.seen_hints.get("status_bleed", false)
			and game.modal_count == 1 and paused,
		game._d7_world_modal_snapshot())

	var released: bool = await game._d7_finish_pending_world_status_hints(owner_token)
	check("D7 acknowledges only the exact status lesson before interpreting the gather result",
		released and not is_instance_valid(status_dialog)
			and bool(game.web_smoke_features.get("d7_world_status_hints", false))
			and game.modal_count == 0 and not paused,
		{"finished": game._web_smoke_d7_training.get("world_status_hints_finished", []),
			"modal": game._d7_world_modal_snapshot()})

	var far_waystone: Node3D = game._find_d2_exit_waystone() as Node3D
	check("multi-fold Far Waystone begins unused, so its choice still needs the owner guard",
		far_waystone != null and not bool(far_waystone.call("is_used"))
			and not game._d7_far_waystone_return_committed(far_waystone),
		game._d7_interactable_snapshot(far_waystone))
	# Model the one Web-only deferred frame: the exact production stone has
	# committed the safe choice, but `current_scene` has not yet changed. The
	# helper must accept this receipt without consulting the now-cleared Chart;
	# reset it before the real UI sequence below.
	var chart_before_receipt: Dictionary = game.active_chart.duplicate(true)
	if far_waystone != null:
		far_waystone.set("_used", true)
	game.active_chart = {}
	var receipt_before_town: bool = far_waystone != null \
		and current_scene != null and current_scene.name == "World" \
		and game.active_chart.is_empty() \
		and game._d7_far_waystone_return_committed(far_waystone)
	game.active_chart = chart_before_receipt
	if far_waystone != null:
		far_waystone.set("_used", false)
	check("exact used Far Waystone receipt commits after Chart clear before deferred Town swap",
		receipt_before_town, game._d7_interactable_snapshot(far_waystone))

	var returned: bool = await game._d7_return_through_far_waystone(owner_token)
	await process_frame
	await process_frame
	await game._wait_d7_town_control()
	var finished: Array = game._web_smoke_d7_training.get("world_status_hints_finished", [])
	check("D7 then physically settles multi-fold Far Waystone safe return",
		returned and finished.has("status_bleed") and not is_instance_valid(status_dialog)
			and bool(game.web_smoke_features.get("d7_world_status_hints", false))
			and bool(game.web_smoke_features.get("d7_real_far_waystone", false))
			and String(game._web_smoke_d7_far_waystone_detail.get("settled_by", "")) == "stone_used"
			and game.active_chart.is_empty()
			and game.modal_count == 0 and not paused,
		{"finished": finished, "far_waystone": game._web_smoke_d7_far_waystone_detail,
			"modal": game._d7_world_modal_snapshot()})

	game.web_smoke_d7_enabled = false
	if current_scene != null:
		current_scene.queue_free()
		await process_frame
	Engine.time_scale = 1.0
	print("--- D7 status hint before Far Waystone: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)
