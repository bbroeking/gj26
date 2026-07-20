extends SceneTree

# Red-capable movement-feel checkpoint. It drives the production controller
# through the target 1280×720 keyboard path rather than testing constants.
# Run: WYRD_NO_SAVE=1 godot --headless --path . --script res://test_movement_feel.gd

const CreatureAnimScript = preload("res://scripts/creature_anim.gd")
const CombatantScript = preload("res://scripts/combatant.gd")
const FirstRoadData = preload("res://data/first_road.gd")

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
	print("--- movement-feel checkpoint: 1280x720 keyboard ---")
	root.size = Vector2i(1280, 720)
	var game := root.get_node("Game")
	game.persistence_enabled = false
	game.reset_to_defaults()
	change_scene_to_file("res://scenes/Town.tscn")
	await process_frame
	await process_frame
	await physics_frame
	var player := game.local_player() as CharacterBody3D
	check("target viewport is 1280×720", root.size == Vector2i(1280, 720), root.size)

	# The three named neighbors are the social spine of the yard. Exercise their
	# production scene instances rather than the helper in isolation: each must
	# have a live Meshy rig sample and visible, deliberately out-of-phase motion.
	var ambient_drivers := get_nodes_in_group("ambient_character_motion")
	check("Mara, Hod, and Quill all have ambient rig motion",
		ambient_drivers.size() == 3, ambient_drivers.size())
	var animation_before: Dictionary = {}
	var transform_before: Dictionary = {}
	for driver in ambient_drivers:
		var ap := driver.get("_player") as AnimationPlayer
		var visual := driver.get("_visual_root") as Node3D
		animation_before[driver] = ap.current_animation_position if ap != null else -1.0
		transform_before[driver] = visual.transform if visual != null else Transform3D.IDENTITY
	await create_timer(0.72).timeout
	var rigs_advanced := true
	var bodies_shifted := true
	for driver in ambient_drivers:
		var ap := driver.get("_player") as AnimationPlayer
		var visual := driver.get("_visual_root") as Node3D
		rigs_advanced = rigs_advanced and ap != null \
			and absf(ap.current_animation_position - float(animation_before[driver])) > 0.01
		bodies_shifted = bodies_shifted and visual != null \
			and not visual.transform.is_equal_approx(transform_before[driver])
	check("all town rigs advance through an authored pose window", rigs_advanced)
	check("town motion remains visible at the model root", bodies_shifted)

	var start := player.global_position
	var frames_to_ninety := -1
	var target_speed := float(player.derived_stats.run_speed)
	Input.action_press("p_fwd")
	for frame in 60:
		await physics_frame
		var speed := Vector2(player.velocity.x, player.velocity.z).length()
		if frames_to_ninety < 0 and speed >= target_speed * 0.9:
			frames_to_ninety = frame + 1
	Input.action_release("p_fwd")
	var one_second_distance := start.distance_to(player.global_position)
	check("W reaches 90% run speed within 7 physics frames",
		frames_to_ninety > 0 and frames_to_ninety <= 7, frames_to_ninety)
	check("W covers at least 4.7 m in its first second",
		one_second_distance >= 4.7, one_second_distance)

	for _frame in 20:
		await physics_frame
	var roll_start := player.global_position
	Input.action_press("p_right")
	Input.action_press("roll")
	for _frame in 3:
		await physics_frame
	var roll_entered := int(player.get("_move")) == 2
	Input.action_release("roll")
	Input.action_release("p_right")
	var roll_frames := 3
	while int(player.get("_move")) != 0 and roll_frames < 60:
		await physics_frame
		roll_frames += 1
	var roll_distance := roll_start.distance_to(player.global_position)
	check("Space enters roll and returns control within 22 physics frames",
		roll_entered and roll_frames <= 22,
		{"entered": roll_entered, "frames": roll_frames})
	check("Space roll remains a decisive 2.7–3.2 m burst",
		roll_distance >= 2.7 and roll_distance <= 3.2, roll_distance)

	# The generic creature animator is what skeletons and other unrigged foes
	# actually use. Measure its rendered travel, not its constants.
	var visual := Node3D.new()
	root.add_child(visual)
	var creature_anim = CreatureAnimScript.new()
	creature_anim.setup(visual)
	var low := INF
	var high := -INF
	for _frame in 45:
		creature_anim.update(1.0 / 60.0, true)
		low = minf(low, visual.position.y)
		high = maxf(high, visual.position.y)
	check("generic creature stride has at least 9 cm of readable lift",
		high - low >= 0.09, high - low)
	visual.free()

	var creature := CombatantScript.new()
	var creature_mesh := Node3D.new()
	creature.add_child(creature_mesh)
	root.add_child(creature)
	creature_mesh.rotation.y = 0.0
	creature.call("_face", Vector3.FORWARD)
	var immediate_turn := absf(angle_difference(0.0, creature_mesh.rotation.y))
	var has_turn_tick := creature.has_method("_tick_facing")
	if has_turn_tick:
		creature.call("_tick_facing", 1.0 / 60.0)
	var first_turn := absf(angle_difference(0.0, creature_mesh.rotation.y))
	check("creatures flow toward a new heading instead of snapping",
		immediate_turn < 0.01 and has_turn_tick and first_turn >= 0.12 \
		and first_turn <= 0.25,
		{"immediate": immediate_turn, "first_frame": first_turn})
	creature.free()

	# Return to the original report scenario: a real Bold Road with production
	# navigation, player controller, camera, and creature body.
	game.active_chart = FirstRoadData.make_chart("bold")
	game.in_dungeon = true
	game.tutorial_step = 5
	change_scene_to_file("res://scenes/World.tscn")
	await process_frame
	await process_frame
	await process_frame
	var dungeon_player := game.local_player() as CharacterBody3D
	var enemies := get_nodes_in_group("enemy")
	check("real Bold Road populated creatures at the target viewport",
		dungeon_player != null and not enemies.is_empty(), enemies.size())
	if dungeon_player != null and not enemies.is_empty():
		var enemy := enemies[0] as CharacterBody3D
		dungeon_player.global_position = enemy.global_position + Vector3(0.0, 0.0, 4.0)
		enemy.set("_state", 1)
		var enemy_start := enemy.global_position
		var gfx := enemy.get_child(0) as Node3D
		var prior_yaw := gfx.rotation.y
		var max_yaw_step := 0.0
		for _frame in 30:
			await physics_frame
			var yaw_step := absf(angle_difference(prior_yaw, gfx.rotation.y))
			max_yaw_step = maxf(max_yaw_step, yaw_step)
			prior_yaw = gfx.rotation.y
		check("a real creature advances with bounded per-frame turning",
			enemy_start.distance_to(enemy.global_position) >= 0.3 \
			and max_yaw_step <= 0.25,
			{"distance": enemy_start.distance_to(enemy.global_position),
				"max_yaw_step": max_yaw_step})

	print("--- movement feel: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)
