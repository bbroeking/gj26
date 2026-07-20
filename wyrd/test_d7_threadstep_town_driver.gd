extends SceneTree

# Focused regression for the final D7 Town action. The production scanner must
# open the physical Lodge lesson, accept it, then prove both rejected and valid
# Threadstep requests without relying on the 14-minute marathon watchdog.

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
	print("--- D7 Threadstep Town driver ---")
	Engine.time_scale = 6.0
	var game := root.get_node_or_null("Game")
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.persistence_enabled = false
	game.web_smoke_enabled = true
	game.web_smoke_d7_enabled = true
	game.web_smoke_phase = "threadstep_probe"
	game.trades.huntcraft = {"xp": Progression.xp_for_level(23), "lv": 23}
	game.seen_hints["driving_volley_lesson_completed"] = true
	game.seen_hints.erase("threadstep_lesson_completed")
	game.grant_skill("PowerShot")
	game.grant_skill("Threadstep")
	game.set_loadout(["PowerShot"])
	change_scene_to_file("res://scenes/Town.tscn")
	await process_frame
	await physics_frame
	await process_frame
	var town := root.get_node_or_null("Town")
	current_scene = town
	for _frame in 12:
		await physics_frame
	var player := game.local_player() as Node3D
	if player != null:
		player.set("focus", 100.0)
	var completed: bool = await game._d7_drive_threadstep(town)
	check("physical Lodge and authoritative Threadstep path complete",
		completed and bool(game.web_smoke_features.get("d7_threadstep_accepted", false))
			and bool(game.web_smoke_features.get("d7_threadstep_blocked", false))
			and game.modal_count == 0 and not paused,
		{"completed": completed, "phase": game.web_smoke_phase,
			"modal_count": game.modal_count, "paused": paused,
			"loadout": game.loadout,
			"status": game.hunters_lodge_lesson_status(),
			"town": town, "lodge": town.get_node_or_null("HuntersLodgeLesson") if town != null else null})
	print("--- Threadstep Town: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)
