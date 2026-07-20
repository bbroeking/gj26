extends SceneTree

# Rendered movement checkpoint: drives the production Bold Road at 1280×720
# with WASD + Space and saves a short frame sequence for visual review.
# Run from `wyrd/` with a writable output directory:
# WYRD_NO_SAVE=1 WYRD_MOVEMENT_CAPTURE_DIR=/tmp/wayfinder-motion \
#   godot --path . --script res://tools/capture_movement_checkpoint.gd

const FirstRoadData = preload("res://data/first_road.gd")


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	root.size = Vector2i(1280, 720)
	var output := OS.get_environment("WYRD_MOVEMENT_CAPTURE_DIR")
	if output == "":
		output = "/tmp/wayfinder-movement-checkpoint"
	DirAccess.make_dir_recursive_absolute(output)
	var game := root.get_node("Game")
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.active_chart = FirstRoadData.make_chart("bold")
	game.in_dungeon = true
	game.tutorial_step = 5
	change_scene_to_file("res://scenes/World.tscn")
	for _frame in 8:
		await process_frame
	var player := game.local_player() as CharacterBody3D
	var elite: CharacterBody3D = null
	for candidate in get_nodes_in_group("enemy"):
		if bool(candidate.get("is_elite")):
			elite = candidate as CharacterBody3D
			break
	if player == null or elite == null:
		push_error("movement capture could not find player + elite")
		quit(1)
		return
	player.global_position = elite.global_position + Vector3(0.0, 0.0, 5.5)
	for candidate in get_nodes_in_group("enemy"):
		candidate.set("_state", 1)
	for _frame in 24:
		await process_frame

	Input.action_press("p_left")
	var captured := 0
	for frame in 72:
		if frame == 22:
			Input.action_release("p_left")
			Input.action_press("p_back")
		if frame == 30:
			Input.action_press("roll")
		if frame == 33:
			Input.action_release("roll")
		if frame == 48:
			Input.action_release("p_back")
			Input.action_press("p_right")
		await process_frame
		if frame % 2 == 0:
			var image := root.get_texture().get_image()
			image.save_png("%s/frame_%03d.png" % [output, captured])
			captured += 1
	Input.action_release("p_left")
	Input.action_release("p_back")
	Input.action_release("p_right")
	Input.action_release("roll")
	print("[movement-capture] %d frames at 1280x720 → %s" % [captured, output])
	quit(0)
