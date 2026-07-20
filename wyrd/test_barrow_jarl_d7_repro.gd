extends SceneTree

# Focused D7 diagnostic harness. It exercises the production interaction seam
# OathBell.interact -> BarrowJarlController.request_bell_relief, rather than
# directly mutating controller.completed.  Keep this test narrow until the
# browser-only phase-three failure is explained.

const JarlScript = preload("res://scripts/barrow_jarl.gd")
const ControllerScript = preload("res://scripts/barrow_jarl_controller.gd")
const GuardScript = preload("res://scripts/oathbound_guard.gd")
const BellScript = preload("res://scripts/oath_bell.gd")

var _pass := 0
var _fail := 0


# Reproduces the D6 driver's unguarded last Input edge: it changes the scanner
# owner after `_d6_scanner_interact` proved the intended bell but before
# PlayerController consumes the pressed action. A real overlapping Area can
# produce the same owner change; this deterministic probe makes the gap
# observable without a browser marathon.
class FinalEdgeRetarget:
	extends Node
	var player: Node3D
	var competitor: Node3D
	var fired := false

	func _ready() -> void:
		pass

	func _physics_process(_delta: float) -> void:
		if fired or player == null or competitor == null \
				or not is_instance_valid(player) or not is_instance_valid(competitor):
			return
		if Input.is_action_pressed(&"interact"):
			fired = true
			player.set("_active_interactable", competitor)
			# Force the scanner's own nearest-target reducer to agree with the
			# retarget if another script refreshes before PlayerController consumes
			# the same just-pressed edge.
			player.set("_overlapping_interactables", [competitor])
			set_physics_process(false)


class FirstEdgeStun:
	extends Node
	var player: Node3D
	var fired := false

	func _physics_process(_delta: float) -> void:
		if fired or player == null or not is_instance_valid(player):
			return
		if Input.is_action_pressed(&"interact"):
			fired = true
			# PlayerController decrements this at the opening of its physics tick,
			# then declines the interaction while it remains positive.
			player.set("_stun_t", 0.10)
			set_physics_process(false)


func _check(label: String, ok: bool, detail: Dictionary) -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % label)
	else:
		_fail += 1
		print("  ✗ %s %s" % [label, str(detail)])


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("--- Barrow Jarl D7 host-controller repro ---")
	await _direct_host_controller_seam()
	await _scanner_input_host_controller_seam()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


func _direct_host_controller_seam() -> void:
	var jarl: Node3D = JarlScript.new()
	jarl.hp_max = 100
	jarl.hp = 100
	root.add_child(jarl)
	var controller: Node3D = ControllerScript.new()
	root.add_child(controller)
	var player := Node3D.new()
	root.add_child(player)
	var guards: Array = []
	var bells: Array = []
	for index in 3:
		var guard: Node3D = GuardScript.new()
		guard.hp_max = 20
		guard.hp = 20
		root.add_child(guard)
		guards.append(guard)
		var bell: Node3D = BellScript.new()
		bell.position = Vector3(float(index) * 4.0, 0.0, 0.0)
		root.add_child(bell)
		bells.append(bell)
	controller.configure(jarl, guards, bells)
	jarl.set_relief_controller(controller)
	await process_frame
	await physics_frame

	for phase in 3:
		jarl.take_damage(int(jarl.hp) + 1, Vector3.FORWARD)
		await process_frame
		var guard: Node3D = guards[phase]
		var bell: Node3D = bells[phase]
		guard.take_damage(int(guard.hp) + 1, Vector3.FORWARD)
		await process_frame
		player.global_position = bell.global_position
		# The real Interactable path owns the call into the authoritative host
		# controller; no direct request_bell_relief call is allowed in this repro.
		bell.interact(player)
		await process_frame
		var completed: Array = controller.completed
		var accepted := bool(completed[phase]) and not bool(jarl.vow_shielded)
		_check("phase %d rings matching bell through the host controller" % (phase + 1),
			accepted,
			{"relief_phase": jarl.relief_phase, "completed": completed,
				"shield": jarl.vow_shielded, "reeling": guard.reeling,
				"guard_active": guard.vow_active, "bell_enabled": bell.enabled_for_relief,
				"bell_relieved": bell.relieved,
				"distance": player.global_position.distance_to(bell.global_position)})

	for node in [jarl, controller, player] + guards + bells:
		if is_instance_valid(node):
			node.queue_free()
	await process_frame


# This second loop is the actual shipped D6 route: real Town Player scanner,
# expected-target receipt, fabricated InputMap action, OathBell.interact, then
# the host controller. It is still self-contained and normally completes in a
# few seconds instead of asking a browser marathon to reach the Pale Oath.
func _scanner_input_host_controller_seam() -> void:
	var game = root.get_node_or_null("Game")
	if game == null:
		_check("Game autoload is present for the scanner seam", false, {})
		return
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.persistence_enabled = false
	game.web_smoke_enabled = false
	game.modal_count = 0
	paused = false
	change_scene_to_file("res://scenes/Town.tscn")
	await process_frame
	await process_frame
	var scene := current_scene
	var player := game.local_player() as Node3D
	if scene == null or player == null:
		_check("Town supplies the shipped Player scanner", false,
			{"scene": scene, "player": player})
		return
	var anchor := player.global_position + Vector3(18.0, 0.0, 18.0)
	var jarl: Node3D = JarlScript.new()
	jarl.hp_max = 100
	jarl.hp = 100
	jarl.position = anchor + Vector3(0.0, 0.0, 5.0)
	scene.add_child(jarl)
	# This probe exercises thresholds/controller state, not combat AI. The real
	# production World supplies the rig child that AI's facing code expects.
	jarl.set_physics_process(false)
	var controller: Node3D = ControllerScript.new()
	scene.add_child(controller)
	var guards: Array = []
	var bells: Array = []
	for index in 3:
		var guard: Node3D = GuardScript.new()
		guard.hp_max = 20
		guard.hp = 20
		guard.position = anchor + Vector3(float(index) * 4.0, 0.0, 2.5)
		scene.add_child(guard)
		guards.append(guard)
		var bell: Node3D = BellScript.new()
		bell.position = anchor + Vector3(float(index) * 4.0, 0.0, 0.0)
		scene.add_child(bell)
		bells.append(bell)
	controller.configure(jarl, guards, bells)
	jarl.set_relief_controller(controller)
	var commits: Array = []
	var rejections: Array = []
	controller.relief_committed.connect(func(phase_index: int, bell_id: String) -> void:
		commits.append({"phase": phase_index, "bell_id": bell_id}))
	controller.bell_request_rejected.connect(func(reason: String) -> void:
		rejections.append(reason))
	await physics_frame
	await process_frame

	for phase in 3:
		jarl.take_damage(int(jarl.hp) + 1, Vector3.FORWARD)
		await process_frame
		var guard: Node3D = guards[phase]
		var bell: Node3D = bells[phase]
		guard.take_damage(int(guard.hp) + 1, Vector3.FORWARD)
		await process_frame
		var retarget: FinalEdgeRetarget = null
		var stun: FirstEdgeStun = null
		if phase == 0:
			stun = FirstEdgeStun.new()
			stun.player = player
			stun.process_physics_priority = -200
			scene.add_child(stun)
		if phase == 2:
			# The browser had already reported reliefs 1 and 2. At the third
			# release edge, make a dormant *wrong* bell own the press. The expected
			# target guard must refuse before the host receives that mutation.
			retarget = FinalEdgeRetarget.new()
			retarget.player = player
			retarget.competitor = bells[0] as Node3D
			retarget.process_physics_priority = -100
			scene.add_child(retarget)
		var scanner_accepted: bool = await game._d6_scanner_interact(bell)
		var receipt: Dictionary = player.call("last_interact_receipt") \
			if player.has_method("last_interact_receipt") else {}
		var action_detail: Dictionary = game._web_smoke_d6_last_bell_action_detail
		var completed: Array = controller.completed
		var accepted := scanner_accepted and bool(completed[phase]) and not bool(jarl.vow_shielded)
		if phase == 0:
			_check("a first-edge stun retries boundedly into one exact host bell commit",
				accepted and stun != null and stun.fired and commits == [{"phase": 1, "bell_id": "oath_bell_1"}]
					and rejections.is_empty() and receipt.get("actual") == bell
					and int(action_detail.get("attempt", -1)) == 2
					and float(action_detail.get("action_distance", INF)) <= 2.25,
				{"scanner": scanner_accepted, "stun_fired": stun != null and stun.fired,
					"receipt": receipt, "commits": commits, "rejections": rejections,
					"action_detail": action_detail})
		elif phase == 1:
			_check("phase %d scanner/InputMap reaches the same host bell relief" % (phase + 1),
				accepted and commits == [{"phase": 1, "bell_id": "oath_bell_1"},
					{"phase": 2, "bell_id": "oath_bell_2"}] and rejections.is_empty()
					and receipt.get("actual") == bell,
				{"scanner": scanner_accepted, "receipt": receipt,
					"relief_phase": jarl.relief_phase, "completed": completed,
					"shield": jarl.vow_shielded, "reeling": guard.reeling,
					"commits": commits, "rejections": rejections,
					"action_detail": action_detail})
		else:
			# This must fail closed before a wrong bell can reach the host. Before
			# the fix, this route produced the browser's completed=false/shield=true
			# symptom after accepting any actual interaction.
			_check("phase 3 fails closed when a final scanner retarget owns the press",
				not scanner_accepted and not bool(completed[phase]) and bool(jarl.vow_shielded)
					and receipt.get("actual") != bell
					and commits == [{"phase": 1, "bell_id": "oath_bell_1"},
						{"phase": 2, "bell_id": "oath_bell_2"}]
					and rejections.is_empty(),
				{"retarget_fired": retarget != null and retarget.fired,
					"scanner": scanner_accepted, "receipt": receipt,
					"relief_phase": jarl.relief_phase, "completed": completed,
					"shield": jarl.vow_shielded, "reeling": guard.reeling,
					"commits": commits, "rejections": rejections,
					"action_detail": action_detail,
					"distance_to_intended": player.global_position.distance_to(bell.global_position),
					"distance_to_actual": player.global_position.distance_to((bells[0] as Node3D).global_position)})
		if retarget != null and is_instance_valid(retarget):
			retarget.queue_free()
		if stun != null and is_instance_valid(stun):
			stun.queue_free()

	for node in [jarl, controller] + guards + bells:
		if is_instance_valid(node):
			node.queue_free()
	await process_frame
