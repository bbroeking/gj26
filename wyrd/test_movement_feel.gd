extends SceneTree

# Red-capable movement-feel checkpoint. It drives the production controller
# through the target 1280×720 keyboard path rather than testing constants.
# Run: WYRD_NO_SAVE=1 godot --headless --path . --script res://test_movement_feel.gd

const CreatureAnimScript = preload("res://scripts/creature_anim.gd")
const CombatantScript = preload("res://scripts/combatant.gd")
const FirstRoadData = preload("res://data/first_road.gd")
const LayoutLoader = preload("res://scripts/layout_loader.gd")

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

	# The named neighbors must travel through the yard with a real gait—not just
	# sway at their authored spawn—and the player must remain planted at rest.
	var walkers := get_nodes_in_group("wandering_npc")
	check("Mara, Hod, and Quill all own a town round",
		walkers.size() == 3, walkers.size())
	var npc_before: Dictionary = {}
	for npc in walkers:
		npc_before[npc] = (npc as Node3D).global_position
	var player_before := player.global_position
	var player_ap := player.get("_ap") as AnimationPlayer
	var idle_before := player_ap.current_animation_position
	await create_timer(0.72).timeout
	var patrols_advanced := true
	var walking_rigs_deformed := true
	for npc in walkers:
		var wander := npc.get_node_or_null("NpcWander")
		var ap := wander.get("_player") as AnimationPlayer if wander != null else null
		var skeleton := find_skeleton(npc)
		patrols_advanced = patrols_advanced \
			and (npc as Node3D).global_position.distance_to(npc_before[npc]) > 0.2 \
			and ap != null and ap.current_animation == "town_walk" \
			and ap.current_animation_position > 0.01
		walking_rigs_deformed = walking_rigs_deformed \
			and skeleton_pose_energy(skeleton) > 0.25
	check("all three NPCs travel with their authored walk clip", patrols_advanced)
	check("walking NPC skeletons are visibly outside the T-pose",
		walking_rigs_deformed)

	# A patrol corner must be a walking turn, never the old
	# arrive → swivel in place → pause → depart sequence.
	var corner_npc := walkers[0] as Node3D
	var corner_wander := corner_npc.get_node("NpcWander")
	corner_wander.set_process(false)
	var corner_origin := corner_npc.global_position
	corner_wander.set("_points", [
		corner_origin,
		corner_origin + Vector3(0.0, 0.0, 0.34),
		corner_origin + Vector3(0.62, 0.0, 0.34),
	])
	corner_wander.set("_point_index", 1)
	corner_wander.set("_pause_left", 0.0)
	corner_wander.set("_move_direction", Vector3.FORWARD)
	corner_wander.set("_current_speed", float(corner_wander.get("_speed")))
	corner_npc.rotation.y = 0.0
	var corner_min_step := INF
	var corner_changed := false
	var corner_samples_after_change := 0
	for _sample in 24:
		var before_step := corner_npc.global_position
		corner_wander.call("_process", 0.08)
		corner_min_step = minf(corner_min_step,
			corner_npc.global_position.distance_to(before_step))
		if int(corner_wander.get("_point_index")) == 2:
			if not corner_changed:
				corner_changed = true
			else:
				corner_samples_after_change += 1
		if corner_changed and corner_samples_after_change >= 2:
			break
	check("NPC patrol corners keep walking instead of swivel-stop-go",
		corner_changed and corner_min_step > 0.015,
		{"changed": corner_changed, "minimum_step": corner_min_step,
			"pause": corner_wander.get("_pause_left")})
	corner_npc.global_position = corner_origin
	corner_wander.set_process(true)

	var paused_rigs_deformed := true
	for npc in walkers:
		var wander := npc.get_node_or_null("NpcWander")
		wander.pause_for_attention(1.0)
	await create_timer(0.12).timeout
	for npc in walkers:
		var skeleton := find_skeleton(npc)
		paused_rigs_deformed = paused_rigs_deformed \
			and skeleton_pose_energy(skeleton) > 0.25 \
			and arm_down_score(skeleton) > 0.5 \
			and knee_angle(skeleton) > 2.1
	check("paused NPCs hold an arms-down standing pose, never a seated T-pose",
		paused_rigs_deformed)
	check("stationary player stays planted in the bounded idle pose",
		player.global_position.distance_to(player_before) < 0.01 \
		and player_ap.current_animation == "player_idle_pose" \
		and absf(player_ap.current_animation_position - idle_before) < 0.2 \
		and arm_down_score(find_skeleton(player)) > 0.5 \
		and knee_angle(find_skeleton(player)) > 2.55,
		{"travel": player.global_position.distance_to(player_before),
			"clip": player_ap.current_animation,
			"arms": arm_down_score(find_skeleton(player)),
			"knee": knee_angle(find_skeleton(player))})

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
		var enemy_kind := String(enemy.get("kind"))
		var identity: Dictionary = LayoutLoader.ENEMY_KINDS.get(enemy_kind, {})
		check("a production creature carries its kind-owned projectile identity",
				not identity.is_empty() \
				and (enemy.get("projectile_color") as Color).is_equal_approx(
					identity.get("projectile_color", Color.TRANSPARENT)) \
				and is_equal_approx(float(enemy.get("proj_speed")),
					float(identity.get("proj_speed", 0.0))),
			{"kind": enemy_kind, "color": enemy.get("projectile_color")})
		dungeon_player.global_position = enemy.global_position + Vector3(0.0, 0.0, 6.0)
		enemy.set("_state", 1)
		var enemy_start := enemy.global_position
		var gfx := enemy.get_child(0) as Node3D
		var prior_yaw := gfx.rotation.y
		var max_yaw_step := 0.0
		# Universal creature projectiles add a readable opening wind-up before the
		# closing stride. The slowest tell is 0.9 s, so sample 1.5 s to measure
		# both beats without making the spawned kind decide whether the gate flakes.
		for _frame in 90:
			await physics_frame
			var yaw_step := absf(angle_difference(prior_yaw, gfx.rotation.y))
			max_yaw_step = maxf(max_yaw_step, yaw_step)
			prior_yaw = gfx.rotation.y
		check("a real creature advances with bounded per-frame turning",
			enemy_start.distance_to(enemy.global_position) >= 0.2 \
			and max_yaw_step <= 0.25,
			{"distance": enemy_start.distance_to(enemy.global_position),
				"max_yaw_step": max_yaw_step})

	# Isolate the production Combatant on open ground so this behavior check is
	# independent of a generated room wall: one ranged opening, then pursuit.
	for enemy_v in enemies:
		(enemy_v as Node).set_physics_process(false)
	dungeon_player.remove_from_group("player")
	var target := CharacterBody3D.new()
	target.add_to_group("player")
	root.add_child(target)
	target.global_position = Vector3(-100.0, 0.0, -94.0)
	var pursuer := CombatantScript.new()
	pursuer.add_child(Node3D.new())
	root.add_child(pursuer)
	pursuer.global_position = Vector3(-100.0, 0.0, -100.0)
	pursuer.kind = "rat"
	pursuer.move_speed = 2.6
	pursuer.attack_cooldown = 0.9
	pursuer.projectile_telegraph = 0.6
	pursuer.set("_state", 1)
	for _frame in 180:
		await physics_frame
	var closing_distance := pursuer.global_position.distance_to(target.global_position)
	check("a pursuer closes after its one readable projectile opening",
		closing_distance <= 3.2,
		{"kind": pursuer.kind, "distance": closing_distance})
	pursuer.queue_free()
	target.queue_free()
	dungeon_player.add_to_group("player")

	print("--- movement feel: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)


func find_skeleton(root_node: Node) -> Skeleton3D:
	if root_node is Skeleton3D:
		return root_node as Skeleton3D
	for child in root_node.get_children():
		var found := find_skeleton(child)
		if found != null:
			return found
	return null


func skeleton_pose_energy(skeleton: Skeleton3D) -> float:
	if skeleton == null:
		return 0.0
	var energy := 0.0
	for bone_idx in range(skeleton.get_bone_count()):
		energy += skeleton.get_bone_pose_rotation(bone_idx).angle_to(Quaternion.IDENTITY)
		energy += skeleton.get_bone_pose_position(bone_idx).length()
	return energy


func arm_down_score(skeleton: Skeleton3D) -> float:
	if skeleton == null:
		return -1.0
	var total := 0.0
	var count := 0
	for side in ["Left", "Right"]:
		var upper := skeleton.find_bone("%sArm" % side)
		var lower := skeleton.find_bone("%sForeArm" % side)
		if upper >= 0 and lower >= 0:
			var direction := skeleton.get_bone_global_pose(lower).origin \
				- skeleton.get_bone_global_pose(upper).origin
			if direction.length_squared() > 0.0001:
				total += direction.normalized().dot(Vector3.DOWN)
				count += 1
	return total / float(count) if count > 0 else -1.0


func knee_angle(skeleton: Skeleton3D) -> float:
	if skeleton == null:
		return -1.0
	var hip := skeleton.find_bone("LeftUpLeg")
	var knee := skeleton.find_bone("LeftLeg")
	var ankle := skeleton.find_bone("LeftFoot")
	if hip < 0 or knee < 0 or ankle < 0:
		return -1.0
	var knee_pos := skeleton.get_bone_global_pose(knee).origin
	var to_hip := skeleton.get_bone_global_pose(hip).origin - knee_pos
	var to_ankle := skeleton.get_bone_global_pose(ankle).origin - knee_pos
	return to_hip.angle_to(to_ankle)
