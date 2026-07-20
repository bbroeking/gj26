extends SceneTree

# Focused world seam tests.  Campaign/table/reward truth is intentionally not
# injected here: this suite locks the generated-world presentation and the
# structural rule that no Jarl `died` signal can happen before host relief.

const LayoutLoaderScript = preload("res://scripts/layout_loader.gd")
const OathboundGuardScript = preload("res://scripts/oathbound_guard.gd")
const OathBellScript = preload("res://scripts/oath_bell.gd")
const JarlScript = preload("res://scripts/barrow_jarl.gd")
const ControllerScript = preload("res://scripts/barrow_jarl_controller.gd")
const StonewakeScript = preload("res://scripts/stonewake.gd")

var passed := 0
var failed := 0


func check(label: String, ok: bool, detail := "") -> void:
	if ok:
		passed += 1
		print("  ✓ %s" % label)
	else:
		failed += 1
		print("  ✗ %s %s" % [label, detail])


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	print("--- Pale Oath world foundation ---")
	test_assets_and_rootroad_registry()
	test_final_character_assets()
	await test_bell_relief_contract()
	await test_guard_lifecycle_damage_authority_and_bells()
	await test_stonewake_telegraph()
	print("--- Pale Oath world: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)


func test_assets_and_rootroad_registry() -> void:
	var paths := [
		"res://models/biome_rootroads_roots_v1.glb", "res://models/landmark_pale_well_v1.glb",
		"res://models/prop_wildgold_vein_v1.glb", "res://models/prop_wellmoss_patch_v1.glb",
		"res://models/landmark_rootroad_lift_wellhouse_v1.glb", "res://models/landmark_hod_oathstone_v1.glb",
		"res://models/prop_oath_bellpost_1_v1.glb", "res://models/prop_oath_bellpost_2_v1.glb",
		"res://models/prop_oath_bellpost_3_v1.glb", "res://models/prop_oath_rubbing_v1.glb",
		"res://models/settlement_pale_oath_display_v1.glb",
	]
	var exists := true
	for path in paths:
		exists = exists and FileAccess.file_exists(path)
	check("deterministic rootroad assets ship in the project", exists)
	check("pale_veins resolves to the rootroads biome", LayoutLoaderScript.SCOPE_BIOME.get("pale_veins") == "rootroads")
	check("rootroad IDs consume dedicated props", LayoutLoaderScript.ROOTROAD_ID_MODEL.has("wildgold_vein") \
		and LayoutLoaderScript.ROOTROAD_ID_MODEL.has("wellmoss_patch") \
		and LayoutLoaderScript.ROOTROAD_ID_MODEL.has("rootroad_lift"))


func _first_animation_player(root_node: Node) -> AnimationPlayer:
	if root_node is AnimationPlayer:
		return root_node as AnimationPlayer
	for child in root_node.get_children():
		var found := _first_animation_player(child)
		if found != null:
			return found
	return null


func _character_rig_contract(path: String, required_clips: Array[String]) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return false
	var instance: Node = packed.instantiate()
	var skeletons := 0
	var skinned_meshes := 0
	var stack: Array[Node] = [instance]
	while not stack.is_empty():
		var node: Node = stack.pop_back() as Node
		if node is Skeleton3D:
			skeletons += 1
		if node is MeshInstance3D and (node as MeshInstance3D).skin != null:
			skinned_meshes += 1
		for child in node.get_children():
			stack.append(child)
	var anim: AnimationPlayer = _first_animation_player(instance)
	var clips_ok: bool = anim != null
	if anim != null:
		var available: PackedStringArray = anim.get_animation_list()
		for required in required_clips:
			clips_ok = clips_ok and available.has(required)
	instance.free()
	return skeletons == 1 and skinned_meshes == 1 and clips_ok


func test_final_character_assets() -> void:
	const JARL := "res://models/boss_barrow_jarl_v1.glb"
	const OATHBOUND := "res://models/enemy_oathbound_v1.glb"
	check("Barrow Jarl production path replaces the temporary silhouette", \
		String(LayoutLoaderScript.BOSS_KINDS["barrow_jarl"].get("model", "")) == JARL \
		and not String(LayoutLoaderScript.BOSS_KINDS["barrow_jarl"].get("name", "")).contains("temporary"))
	check("Barrow Jarl ships one skinned armature and every encounter state clip", \
		_character_rig_contract(JARL, ["Jarl_Idle", "Jarl_Walk", "Jarl_Attack", "Jarl_Hit", \
			"Jarl_Shield", "Jarl_Reeling", "Jarl_Relief", "Jarl_Kneel", "Jarl_Defeat"]))
	check("Oathbound guard ships one skinned armature and relief clips", \
		_character_rig_contract(OATHBOUND, ["Oathbound_Idle", "Oathbound_Walk", "Oathbound_Attack", \
			"Oathbound_Hit", "Oathbound_Shield", "Oathbound_Reeling", "Oathbound_Relief", "Oathbound_Defeat"]))


func test_bell_relief_contract() -> void:
	var jarl: Node3D = JarlScript.new()
	jarl.hp_max = 100
	jarl.hp = 100
	root.add_child(jarl)
	var controller: Node3D = ControllerScript.new()
	root.add_child(controller)
	var guards: Array = []
	var bells: Array = []
	var player := Node3D.new()
	root.add_child(player)
	for i in 3:
		var guard: Node3D = OathboundGuardScript.new()
		guard.hp_max = 20
		guard.hp = 20
		root.add_child(guard)
		guards.append(guard)
		var bell: Node3D = OathBellScript.new()
		bell.position = Vector3(float(i) * 3.0, 0, 0)
		root.add_child(bell)
		bells.append(bell)
	controller.configure(jarl, guards, bells)
	jarl.set_relief_controller(controller)
	jarl.vow_shielded = true
	jarl.take_damage(999, Vector3.FORWARD)
	check("vow shield blocks lethal Jarl damage", jarl.hp == 100 and not bool(jarl.get("dead")))
	jarl.vow_shielded = false
	jarl.take_damage(999, Vector3.FORWARD)
	check("Jarl clamps burst damage at the first 75 percent relief phase", jarl.hp == 75 \
		and jarl.relief_phase == 1 and jarl.vow_shielded)
	var reliefs := true
	for i in 3:
		jarl.relief_phase = i + 1
		guards[i].reeling = true
		player.global_position = bells[i].global_position
		reliefs = reliefs and controller.request_bell_relief("oath_bell_%d" % (i + 1), i + 1, player)
	check("matching reliefs resolve all bells into scanner-inert world state",
		reliefs and controller.all_reliefs_complete() and bells.all(func(bell):
			return bool(bell.call("is_used"))))
	var canonical_death_seen := [false]
	jarl.died.connect(func() -> void: canonical_death_seen[0] = true, CONNECT_ONE_SHOT)
	jarl.take_damage(999, Vector3.FORWARD)
	var death_deadline_ms := Time.get_ticks_msec() + 3000
	while not bool(canonical_death_seen[0]) and Time.get_ticks_msec() < death_deadline_ms:
		await process_frame
	check("completed reliefs resolve the authored kneel into one canonical Jarl death",
		bool(canonical_death_seen[0]) and jarl.dead)
	for n in [jarl, controller, player] + guards + bells:
		if is_instance_valid(n): n.queue_free()
	await process_frame


func _collision_shapes_match(node: Node, disabled: bool) -> bool:
	for child in node.get_children():
		if child is CollisionShape3D and (child as CollisionShape3D).disabled != disabled:
			return false
		if not _collision_shapes_match(child, disabled):
			return false
	return true


func _guard_is_fully_dormant(guard: Node3D) -> bool:
	var hurt := guard.get_node_or_null("Hurtbox") as Area3D
	return not guard.is_physics_processing() and guard.collision_layer == 0 \
		and guard.collision_mask == 0 and hurt != null and hurt.collision_layer == 0 \
		and not hurt.monitorable and _collision_shapes_match(guard, true)


func _bell_model_path(bell: Node) -> String:
	var model := bell.get_node_or_null("BellpostModel")
	return String(model.get_meta("bell_model_path", "")) if model != null else ""


func test_guard_lifecycle_damage_authority_and_bells() -> void:
	var jarl: Node3D = JarlScript.new()
	jarl.hp_max = 100
	jarl.hp = 100
	root.add_child(jarl)
	var controller: Node3D = ControllerScript.new()
	root.add_child(controller)
	var guards: Array = []
	var bells: Array = []
	for i in 3:
		var guard: Node3D = OathboundGuardScript.new()
		guard.collision_layer = 4
		guard.collision_mask = 3
		root.add_child(guard)
		guard.setup(20, 0.45, 1.6)
		guards.append(guard)
		var bell: Node3D = OathBellScript.new()
		bell.position = Vector3(float(i) * 4.0, 0, 0)
		root.add_child(bell)
		bells.append(bell)
	controller.configure(jarl, guards, bells)
	jarl.set_relief_controller(controller)
	await process_frame
	await physics_frame
	var dormant := true
	for guard in guards:
		dormant = dormant and _guard_is_fully_dormant(guard as Node3D)
	check("dormant Oathbound suspend AI, physics, body, and hurtbox collision", dormant)
	var authored_models := true
	for i in bells.size():
		authored_models = authored_models and _bell_model_path(bells[i]) \
			== "res://models/prop_oath_bellpost_%d_v1.glb" % (i + 1)
	check("each late-configured Oath Bell refreshes to its authored phase model", authored_models)

	# The live signal path, rather than a test-only arm call, must wake exactly
	# one guard. This catches a future reorder around the Jarl/controller wire.
	jarl.relief_phase = 1
	jarl.relief_phase_started.emit(1)
	await process_frame
	await physics_frame
	var armed: Node3D = guards[0]
	var armed_hurt := armed.get_node_or_null("Hurtbox") as Area3D
	check("only the signalled phase guard wakes with its collision contract restored",
		armed.is_physics_processing() and armed.collision_layer == 4 and armed.collision_mask == 3 \
			and armed_hurt != null and armed_hurt.collision_layer == 8 and armed_hurt.monitorable \
			and _collision_shapes_match(armed, false) and _guard_is_fully_dormant(guards[1]) \
			and _guard_is_fully_dormant(guards[2]))

	# A resolved super-crit plus Mark must still stop at one Vigor rather than
	# allowing the ordinary Combatant terminal path to run.
	armed.apply_status("marked", 4.0, 0, 1.0, 0.0)
	armed.take_damage(20, Vector3.FORWARD, 1.0, 3.0)
	check("crit and marked amplification clamp an Oathbound into Reeling",
		int(armed.hp) == 1 and bool(armed.get("reeling")) and not bool(armed.get("dead")) \
			and not armed.is_physics_processing(), str({"hp": armed.hp, "reeling": armed.reeling}))

	# Peer 2 calls the host from far away while peer 3 stands on the bell. The
	# sender-bound lookup must reject that borrowed proximity, then accept peer 2
	# only after its own replicated body reaches the bell.
	var distant := Node3D.new()
	distant.add_to_group("player")
	distant.set_multiplayer_authority(2)
	root.add_child(distant)
	distant.global_position = Vector3(40, 0, 0)
	var nearby := Node3D.new()
	nearby.add_to_group("player")
	nearby.set_multiplayer_authority(3)
	root.add_child(nearby)
	nearby.global_position = bells[0].global_position
	var borrowed: bool = controller._host_validate_request_for_peer("oath_bell_1", 1, 2)
	distant.global_position = bells[0].global_position
	var own_proximity: bool = controller._host_validate_request_for_peer("oath_bell_1", 1, 2)
	await process_frame
	await physics_frame
	check("host bell validation binds proximity to the RPC sender, then relief deactivates the guard",
		not borrowed and own_proximity and bool(controller.completed[0]) \
			and _guard_is_fully_dormant(armed),
		str({"borrowed": borrowed, "own": own_proximity, "completed": controller.completed}))

	# Arm a separate guard and let the real physics status loop deliver a lethal
	# bleed tick. This guards the path that bypassed the old raw-hit clamp.
	jarl.relief_phase = 2
	jarl.relief_phase_started.emit(2)
	var tick_guard: Node3D = guards[1]
	tick_guard.apply_status("bleed", 2.0, 999, 1.0, 0.01)
	# Call the real status clock with a deterministic elapsed slice: this reaches
	# Combatant._apply_tick_damage through the same loop used by physics, without
	# relying on the headless runner's first-frame delta.
	tick_guard._tick_statuses(0.02)
	check("a live status tick clamps the next Oathbound into Reeling instead of death",
		int(tick_guard.hp) == 1 and bool(tick_guard.get("reeling")) \
			and not bool(tick_guard.get("dead")) and not tick_guard.is_physics_processing(),
		str({"hp": tick_guard.hp, "reeling": tick_guard.reeling, "dead": tick_guard.dead}))
	for n in [jarl, controller, distant, nearby] + guards + bells:
		if is_instance_valid(n): n.queue_free()
	await process_frame


func test_stonewake_telegraph() -> void:
	var wake: Node3D = StonewakeScript.new()
	wake.setup(false, 3.0)
	root.add_child(wake)
	wake.begin_cycle()
	check("Stonewake exposes a marked ring before resolution", wake.get_node_or_null("StonewakeTelegraph") != null \
		and wake.telegraph_seconds >= 1.0)
	wake.queue_free()
	await process_frame
