extends SceneTree

# Fire in the Bough — live Threadstep controller coverage.  The compact
# ledger tests in test_threadstep.gd lock the host's deterministic facts; this
# harness mounts the shipped Player scene in a real World3D so the request,
# capsule sweep, navigation segment, acknowledgement, cancellation, and grace
# paths cannot drift apart.

const PlayerScene := preload("res://scenes/Player.tscn")

var _pass := 0
var _fail := 0


func _initialize() -> void:
	_run()


func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % name)
	else:
		_fail += 1
		print("  ✗ %s %s" % [name, detail])


func _run() -> void:
	print("--- Threadstep live PlayerController check ---")
	var game := root.get_node_or_null("Game")
	if game == null:
		_check("Game autoload is present", false)
		quit(1)
		return
	game.persistence_enabled = false
	game.reset_to_defaults()
	# This test is about the authenticated movement path, not the authored Lodge
	# lesson.  Give the real runtime bar its already-earned Threadstep marker.
	game.owned_skills = ["Threadstep"]
	game.loadout = ["Threadstep"]

	var world := Node3D.new()
	world.name = "ThreadstepLiveWorld"
	root.add_child(world)
	_build_navmesh(world)
	_add_wall(world, Vector3(0.0, 0.9, -2.5))
	var player: CharacterBody3D = PlayerScene.instantiate()
	world.add_child(player)
	# NavigationRegion3D registers asynchronously with World3D.  Do not use a
	# guessed frame count here: the controller must reject while the map's first
	# sync is incomplete, and this real-wall-bounded helper observes the
	# NavigationServer's documented iteration ID before accepted-path coverage.
	var nav_synced: bool = await _wait_for_navigation_map_sync(world, 1500)
	_check("navigation map completes its first synchronization", nav_synced,
		"iteration=%d" % _navigation_map_iteration(world))
	player.rebuild_skills()
	_check("real Player scene equips Threadstep", _skill_names(player) == ["BasicShot", "Threadstep"],
		str(_skill_names(player)))

	# The wall exercises CharacterBody3D.test_move against the shipped capsule;
	# a live navmap is also present so this is not the pure injected-probe case.
	player.global_position = Vector3.ZERO
	player.focus = player.focus_max
	var wall_before: float = float(player.focus)
	var wall_started: bool = bool(player.try_threadstep(Vector3.FORWARD))
	_check("blocked capsule spends nothing", wall_started and is_equal_approx(player.focus, wall_before)
		and not player.threadstep_pending() and _threadstep_cd(player) == 0.0,
		"focus %.1f, pending=%s, cooldown=%.2f" % [player.focus,
		str(player.threadstep_pending()), _threadstep_cd(player)])

	# Start outside the nav region with no collision obstacle.  This verifies the
	# controller's actual closest-point/segment rejection rather than a fake
	# authority probe and, like a capsule block, must release without a debit.
	player.global_position = Vector3(30.0, 0.0, 0.0)
	player.focus = player.focus_max
	var gap_before: float = float(player.focus)
	var gap_started: bool = bool(player.try_threadstep(Vector3.FORWARD))
	_check("navigation gap spends nothing", gap_started and is_equal_approx(player.focus, gap_before)
		and not player.threadstep_pending() and _threadstep_cd(player) == 0.0,
		"focus %.1f, pending=%s, cooldown=%.2f" % [player.focus,
		str(player.threadstep_pending()), _threadstep_cd(player)])

	# The offline owner follows the same host-attempt → acknowledgement method
	# synchronously.  It is the real controller acknowledgement, not a direct
	# Focus mutation, and duplicate acknowledgement must find no reservation.
	player.global_position = Vector3(10.0, 0.0, 0.0)
	player.focus = player.focus_max
	var accepted_origin := player.global_position
	var accepted: bool = bool(player.try_threadstep(Vector3.FORWARD))
	var accepted_nonce: int = int(player._threadstep_nonce)
	var accepted_focus: float = float(player.focus)
	var accepted_endpoint: Vector3 = accepted_origin + Vector3.FORWARD * float(player.THREADSTEP_MAX_DISTANCE)
	var accepted_once: bool = accepted and is_equal_approx(accepted_focus, float(player.focus_max) - float(player.THREADSTEP_COST)) \
		and player.global_position.distance_to(accepted_endpoint) < 0.01 \
		and not player.threadstep_pending() and is_equal_approx(_threadstep_cd(player), player.THREADSTEP_COOLDOWN)
	player._threadstep_ack(accepted_nonce, true, accepted_endpoint, "duplicate")
	_check("accepted host acknowledgement moves and spends exactly once", accepted_once
		and is_equal_approx(player.focus, accepted_focus) and player.global_position.distance_to(accepted_endpoint) < 0.01,
		"focus %.1f, endpoint %s, cooldown %.2f" % [player.focus, str(player.global_position), _threadstep_cd(player)])

	# A forged/stale acknowledgement has no matching reservation.  Feed it a
	# hostile endpoint as well: neither Focus nor position may change until the
	# exact current nonce arrives from the authenticated host transport.
	player.focus = player.focus_max
	player.global_position = Vector3(10.0, 0.0, 0.0)
	player._threadstep_pending = {"nonce": 91, "reserved": player.THREADSTEP_COST}
	var spoof_origin := player.global_position
	player._threadstep_ack(90, true, Vector3(999.0, 0.0, 999.0), "spoof")
	player._threadstep_ack(89, false, Vector3(-999.0, 0.0, -999.0), "stale")
	_check("spoofed, stale, and mismatched acknowledgements cannot consume", player.threadstep_pending()
		and is_equal_approx(player.focus, player.focus_max) and player.global_position == spoof_origin,
		"focus %.1f, pending=%s, endpoint=%s" % [player.focus,
		str(player.threadstep_pending()), str(player.global_position)])

	# Both transport-loss signals are wired during PlayerController._ready.
	# They release an owner reservation but never turn it into a refund/debit.
	var net := root.get_node_or_null("NetGame")
	if net == null:
		_check("NetGame autoload is present", false)
	else:
		net.reconnecting.emit(1, 3)
		_check("reconnect releases owner reservation", not player.threadstep_pending()
			and is_equal_approx(player.focus, player.focus_max))
		player._threadstep_pending = {"nonce": 92, "reserved": player.THREADSTEP_COST}
		net.session_ended.emit("test transport loss")
		_check("session end releases owner reservation", not player.threadstep_pending()
			and is_equal_approx(player.focus, player.focus_max))

	# Grace blocks only cinder damage/statuses.  An ordinary hit still lands in
	# the same 0.22-second window, proving it is not a generic invulnerability.
	var hp_before: int = int(player.hp)
	var cinder_harmed: bool = bool(player.apply_cinder_damage(3, Vector3.BACK))
	var cinder_status: Variant = player.apply_status("cinder_slow", 1.0, 0, 0.5, 0.0)
	player.take_damage(2, Vector3.BACK)
	_check("cinder grace is narrow", player.threadstep_cinder_grace_active()
		and not cinder_harmed and cinder_status == null and player.hp == hp_before - 2,
		"grace=%s, cinder_harmed=%s, hp %d→%d" % [str(player.threadstep_cinder_grace_active()),
		str(cinder_harmed), hp_before, player.hp])

	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


func _skill_names(player: CharacterBody3D) -> Array:
	var names: Array = []
	for skill in player.skills:
		names.append(String(skill.name))
	return names


func _threadstep_cd(player: CharacterBody3D) -> float:
	for i in range(1, player.skills.size() + 1):
		if String(player.skills[i - 1].name) == "Threadstep":
			return float(player._skill_cooldowns.get(i, 0.0))
	return -1.0


func _navigation_map_iteration(host: Node3D) -> int:
	var world := host.get_world_3d()
	if world == null:
		return -1
	var nav_map: RID = world.navigation_map
	if not nav_map.is_valid():
		return -1
	return NavigationServer3D.map_get_iteration_id(nav_map)


func _wait_for_navigation_map_sync(host: Node3D, timeout_ms: int) -> bool:
	var deadline_ms := Time.get_ticks_msec() + maxi(1, timeout_ms)
	var observed_iteration := -1
	# A SceneTree script reaches this setup before its new World3D is attached to
	# the renderer/physics world.  Yield one physics edge before asking Node3D
	# for that World3D; doing the getter earlier itself emits a server diagnostic.
	while Time.get_ticks_msec() < deadline_ms:
		await physics_frame
		var iteration := _navigation_map_iteration(host)
		if iteration <= 0:
			continue
		# The first readable iteration can belong to the pre-region map.  Require
		# one subsequent synchronized map revision, which is the registration edge
		# of the NavigationRegion built immediately before this wait.
		if observed_iteration >= 0 and iteration > observed_iteration:
			return true
		observed_iteration = iteration
	return false


func _build_navmesh(host: Node3D) -> void:
	var nav := NavigationMesh.new()
	nav.vertices = PackedVector3Array([
		Vector3(-2.0, 0.05, -8.0), Vector3(-2.0, 0.05, 8.0),
		Vector3(22.0, 0.05, 8.0), Vector3(22.0, 0.05, -8.0),
	])
	nav.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	var region := NavigationRegion3D.new()
	region.name = "ThreadstepNav"
	region.navigation_mesh = nav
	host.add_child(region)


func _add_wall(host: Node3D, position: Vector3) -> void:
	var wall := StaticBody3D.new()
	wall.name = "ThreadstepCapsuleWall"
	wall.position = position
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.2, 1.8, 0.6)
	collision.shape = shape
	wall.add_child(collision)
	host.add_child(wall)
