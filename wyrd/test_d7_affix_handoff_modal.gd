extends SceneTree

# A Tier-1 Table commit can open the real affix-reading DialogPanel just before
# the Waystone changes scene. The panel belongs to the outgoing Town, but its
# modal ownership must not survive into World after that node is freed.

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
	print("--- D7 affix dialog scene-handoff lifecycle ---")
	var game := root.get_node_or_null("Game")
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.persistence_enabled = false
	game.web_smoke_enabled = false
	game.modal_count = 0
	paused = false
	game.active_chart = {
		"chart_instance_id": "d7-affix-handoff", "template_id": "tier_1",
		"recipe_id": "green_hollow", "tier": 1, "scope": "hollow",
		"seed": 456123, "layer": 1, "max_layers": 1,
		"affixes": [{"id": "tyrannical", "good": true, "resolvedId": "tyrannical"}],
	}
	game.in_dungeon = true

	change_scene_to_file("res://scenes/Town.tscn")
	await process_frame
	await process_frame
	# This is the exact Game callback the successful affixed Table commit invokes.
	game.first_time_hint("affix_reading")
	await process_frame
	await process_frame
	check("real affix-reading lesson owns one modal before Waystone transition",
		game.modal_count == 1 and paused
			and current_scene.find_child("DialogueShell", true, false) != null)

	change_scene_to_file("res://scenes/World.tscn")
	await process_frame
	await process_frame
	await physics_frame
	check("freeing the outgoing affix lesson releases modal ownership in World",
		game.modal_count == 0 and not paused
			and current_scene.find_child("DialogueShell", true, false) == null,
		{"modal_count": game.modal_count, "paused": paused})

	if current_scene != null:
		current_scene.queue_free()
		await process_frame
	print("--- D7 affix dialog scene-handoff lifecycle: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)
