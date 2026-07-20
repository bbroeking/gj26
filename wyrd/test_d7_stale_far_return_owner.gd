extends SceneTree

# A SceneTreeTimer outlives its originating World.  This regression puts a
# delayed D7 return on physical World A, then opens a second physical World B
# under the same repeating `training_world` stage.  The old return must fail
# closed: it may fail strict D7 observably, but it may never spend/return B.

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


func _chart(id: String, seed: int) -> Dictionary:
	return {
		"chart_instance_id": id, "template_id": "tier_1",
		"recipe_id": "green_hollow", "tier": 1, "scope": "hollow",
		"name": "Green Hollow", "seed": seed, "layer": 1, "max_layers": 1,
		"affixes": [],
	}


func _open_world(chart: Dictionary) -> void:
	var game = root.get_node_or_null("Game")
	game.active_chart = chart.duplicate(true)
	game.in_dungeon = true
	change_scene_to_packed(load("res://scenes/World.tscn"))
	await process_frame
	await process_frame
	await physics_frame


func run() -> void:
	print("--- D7 stale Far Waystone owner token ---")
	var game = root.get_node_or_null("Game")
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.persistence_enabled = false
	game.web_smoke_enabled = true
	# The test owns D7's scene changes directly; enabling the dispatcher would
	# otherwise start the full training route when World B becomes ready.
	game.web_smoke_d7_enabled = false
	game.web_smoke_phase = "d7_stale_return_probe"
	game.web_smoke_features = {}
	game.modal_count = 0
	paused = false
	game.tutorial_step = 7
	game.seen_hints = {"chart_table_snug_returned": true, "forage_node": true,
		"affix_reading": true, "ore_rock": true, "log_pile": true}
	game._web_smoke_d7_stage = "training_world"

	await _open_world(_chart("d7-owner-a", 104729))
	var token_a: Dictionary = game._d7_capture_world_owner_token("regression_a")
	game._d7_schedule_far_waystone_return(0.25, "regression_a", token_a)

	# Deliberately retain the same stage: only world generation/instance and
	# Chart identity distinguish the old callback from the later training leg.
	await _open_world(_chart("d7-owner-b", 130363))
	var token_b: Dictionary = game._d7_capture_world_owner_token("regression_b")
	game.web_smoke_d7_enabled = true
	# This models the scene-ready deferred driver from A finally reaching the
	# queue after B is live. It must use its immutable A token rather than
	# recapturing B at execution time.
	game._d7_drive_trade_training_world.bind(token_a).call_deferred()
	await process_frame
	var driver_detail: Dictionary = game._web_smoke_d7_far_waystone_detail
	check("deferred World-A driver rejects World-B rather than self-blessing it",
		game.web_smoke_phase == "failed"
			and String(driver_detail.get("status", "")) == "stale_return_rejected"
			and current_scene != null and current_scene.name == "World"
			and String(game.active_chart.get("chart_instance_id", "")) == "d7-owner-b", driver_detail)

	# A valid World can have two callbacks queued before either yields. The first
	# claim owns the physical Far Waystone press; the second must fail before it
	# can interact with the same chart.
	var first_claim: bool = game._d7_claim_far_waystone_return(token_b)
	var second_claim: bool = game._d7_claim_far_waystone_return(token_b)
	var duplicate_detail: Dictionary = game._web_smoke_d7_far_waystone_detail
	check("one World generation permits only one Far Waystone return claim",
		first_claim and not second_claim and game.web_smoke_phase == "failed"
			and String(duplicate_detail.get("status", "")) == "stale_return_rejected"
			and String(duplicate_detail.get("boundary", "")) == "far_waystone_duplicate_claim"
			and current_scene != null and current_scene.name == "World"
			and String(game.active_chart.get("chart_instance_id", "")) == "d7-owner-b", duplicate_detail)

	# The Giant settles its escrow while still in one World, then changes route
	# phase before returning. That is an authorized same-World stage rebind, not
	# a new owner generation and not a loophole for a stale World-A callback.
	game._web_smoke_d7_stage = "giant_return"
	var giant_return_token: Dictionary = game._d7_rebind_world_owner_stage(token_b, "giant_return")
	check("Giant same-World settlement can derive an authorized return-stage token",
		int(giant_return_token.get("world_generation", -1)) == int(token_b.get("world_generation", -2))
			and int(giant_return_token.get("world_instance_id", -1)) == int(token_b.get("world_instance_id", -2))
			and String(giant_return_token.get("chart_instance_id", "")) == "d7-owner-b"
			and String(giant_return_token.get("stage", "")) == "giant_return"
			and game._d7_world_owner_valid(giant_return_token, "giant_stage_regression", false), giant_return_token)
	await create_timer(0.5, true).timeout

	var detail: Dictionary = game._web_smoke_d7_far_waystone_detail
	check("distinct physical Worlds receive distinct immutable D7 owner tokens",
		int(token_a.get("world_generation", -1)) != int(token_b.get("world_generation", -1))
			and int(token_a.get("world_instance_id", -1)) != int(token_b.get("world_instance_id", -1))
			and String(token_a.get("chart_instance_id", "")) == "d7-owner-a"
			and String(token_b.get("chart_instance_id", "")) == "d7-owner-b", {"a": token_a, "b": token_b})
	check("stale delayed Far Waystone return fails strict D7 without returning later World B",
		game.web_smoke_phase == "failed"
			and String(detail.get("status", "")) == "stale_return_rejected"
			and current_scene != null and current_scene.name == "World"
			and String(game.active_chart.get("chart_instance_id", "")) == "d7-owner-b"
			and not bool(detail.get("player", {}).get("dead", true)), detail)

	game.web_smoke_d7_enabled = false
	if current_scene != null:
		current_scene.queue_free()
		await process_frame
	print("--- D7 stale Far Waystone owner token: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)
