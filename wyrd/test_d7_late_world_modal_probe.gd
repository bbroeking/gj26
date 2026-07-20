extends SceneTree

# Targeted reproduction probe for Chrome r7's late D7 World failure.  It loads
# the exact reported Green Hollow seed/affix at the reported late Trade levels,
# then sends one real strict scanner/InputMap harvest to the authored
# Bittergrass node.  No run result, material, or UI state is fabricated.

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
	print("--- D7 late World modal probe ---")
	Engine.time_scale = 6.0
	var game = root.get_node_or_null("Game")
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.persistence_enabled = false
	game.web_smoke_enabled = false
	game.web_smoke_d7_enabled = false
	game.modal_count = 0
	paused = false
	game.tutorial_step = 7
	game.seen_hints = {"chart_table_snug_returned": true, "forage_node": true,
		"affix_reading": true, "ore_rock": true, "log_pile": true}
	game.trades = Progression.fresh_trade_state()
	for record in [["wayfinding", 23], ["huntcraft", 19], ["earthcraft", 14], ["wildcraft", 20]]:
		var trade_key := String(record[0])
		var level := int(record[1])
		game.trades[trade_key] = {"xp": Progression.xp_for_level(level), "lv": level}
	game.active_chart = {
		"chart_instance_id": "r7-50-green-hollow", "template_id": "tier_1",
		"recipe_id": "green_hollow", "tier": 1, "scope": "hollow",
		"name": "Green Hollow", "seed": 396698890, "layer": 1, "max_layers": 1,
		"affixes": [{"id": "bramble_bloom", "good": true,
			"resolvedId": "bramble_bloom__good"}],
	}
	game.in_dungeon = true

	change_scene_to_packed(load("res://scenes/World.tscn"))
	await process_frame
	await process_frame
	await physics_frame
	var enemy_snapshot: Array = []
	var has_briarbound := false
	for enemy_v in get_nodes_in_group("enemy"):
		if enemy_v is Node3D:
			if str(enemy_v.get("modifier")) == "briarbound":
				has_briarbound = true
			enemy_snapshot.append({"name": String((enemy_v as Node).name),
				"kind": str(enemy_v.get("kind")), "modifier": str(enemy_v.get("modifier")),
				"position": (enemy_v as Node3D).global_position})
	print("  [enemies] %s" % str(enemy_snapshot))
	var target: Node3D = null
	for node_v in get_nodes_in_group("interactable"):
		if node_v is Node3D and str(node_v.get("kind")) == "forage_node" \
					and str(node_v.get("item_id")) == "bittergrass":
			target = node_v as Node3D
			break
	check("reported seed materializes an authored Bittergrass forage target", target != null,
		{"interactables": get_nodes_in_group("interactable").size()})
	if target != null:
		var before: int = game.material_count("bittergrass")
		var harvested: bool = await game._d7_scanner_harvest(target, "bittergrass", 1200)
		await process_frame
		var after: int = game.material_count("bittergrass")
		var player := game.local_player() as Node3D
		var receipt: Dictionary = game._d7_interaction_receipt_snapshot(player)
		var modal: Array = game._d7_world_modal_snapshot()
		var harvest_detail: Dictionary = game._web_smoke_d7_last_harvest_detail
		var post_receipt: Dictionary = harvest_detail.get("post_receipt", {})
		var press_receipt: Dictionary = post_receipt.get("receipt", {})
		var expected: Dictionary = press_receipt.get("expected", {})
		var actual: Dictionary = press_receipt.get("actual", {})
		var settled: Dictionary = harvest_detail.get("settle", {})
		var settled_target: Dictionary = settled.get("target", {})
		var channel_t := float(settled_target.get("channel_t", 0.0))
		var channel_len := float(settled_target.get("channel_len", 0.0))
		var target_path := str(target.get_path())
		print("  [diagnostic] %s" % str({"harvested": harvested,
			"material": {"before": before, "after": after, "delta": after - before},
			"paused": paused, "modal_count": game.modal_count, "modal": modal,
			"receipt": receipt, "target": game._d7_interactable_snapshot(target),
			"harvest_detail": harvest_detail}))
		check("reported seed keeps the strict press on Bittergrass, then cancels its channel without yield or modal",
			bool(post_receipt.get("press_accepted", false)) \
				and str(press_receipt.get("status", "")) == "actual" \
				and str(expected.get("path", "")) == target_path \
				and str(actual.get("path", "")) == target_path \
				and not bool(settled_target.get("channeling", true)) \
				and channel_t > 0.0 and channel_t < channel_len \
				and bool(settled_target.get("valid", false)) \
				and not bool(settled_target.get("used", true)) \
				and after - before == 0 and not harvested \
				and game.modal_count == 0 and not paused and has_briarbound,
			{"modal": modal, "receipt": receipt, "target": game._d7_interactable_snapshot(target),
				"harvest_detail": harvest_detail, "enemies": enemy_snapshot})

	game.web_smoke_d7_enabled = false
	if current_scene != null:
		current_scene.queue_free()
		await process_frame
	Engine.time_scale = 1.0
	print("--- D7 late World modal probe: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)
