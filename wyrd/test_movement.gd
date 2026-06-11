extends SceneTree

# Spec 23 — movement eval harness. Drives the player via simulated input
# and checks dash / roll / fire / state transitions.
#   godot --headless --path godot --script res://test_movement.gd

const PlayerScene := preload("res://scenes/Player.tscn")

var _pass := 0
var _fail := 0

func _initialize() -> void:
	_run()

func _check(id: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
		print("  PASS  %s — %s" % [id, detail])
	else:
		_fail += 1
		print("  FAIL  %s — %s" % [id, detail])

func _count_name(node: Node, substr: String) -> int:
	var n := 0
	if String(node.name).contains(substr):
		n += 1
	for c in node.get_children():
		n += _count_name(c, substr)
	return n

func _run() -> void:
	print("--- spec 23 movement evals ---")
	var host := Node3D.new()
	root.add_child(host)
	var p: Node3D = PlayerScene.instantiate()
	host.add_child(p)
	await physics_frame
	await physics_frame          # _ready done — input actions bound

	# M-fire — a fire press spawns an arrow.
	Input.action_press("fire")
	for i in 4:
		await physics_frame
	Input.action_release("fire")
	_check("M-fire", _count_name(host, "Arrow") >= 1, "fire press spawned an arrow")
	for i in 6:
		await physics_frame

	# M1 — dash covers ground (DASH_SPEED × DASH_TIME ≈ 2.7 m).
	Input.action_press("p_fwd")
	await physics_frame
	var p0: Vector3 = p.global_position
	Input.action_press("dash")
	await physics_frame
	Input.action_release("dash")
	for i in 16:
		await physics_frame
	var moved := Vector2(p.global_position.x - p0.x, p.global_position.z - p0.z).length()
	_check("M1", moved > 2.0, "dash covered %.2f m (XZ)" % moved)
	Input.action_release("p_fwd")
	for i in 12:
		await physics_frame

	# M2 — dash returns to NORMAL (enum: NORMAL=0).
	_check("M2", p._move == 0, "state back to NORMAL after dash (%d)" % p._move)

	# M3 — roll grants an i-frame window.
	Input.action_press("roll")
	await physics_frame
	Input.action_release("roll")
	await physics_frame
	_check("M3", p._iframe_t > 0.0, "roll granted i-frames (%.2f s left)" % p._iframe_t)

	# M4 — roll returns to NORMAL once its window ends.
	for i in 45:
		await physics_frame
	_check("M4", p._move == 0, "state back to NORMAL after roll (%d)" % p._move)

	# M5 — dash on cooldown can't immediately re-trigger.
	Input.action_press("dash")
	await physics_frame
	Input.action_release("dash")
	for i in 14:
		await physics_frame
	var cd_ok: bool = p._dash_cd > 0.0
	Input.action_press("dash")          # mid-cooldown — should be ignored
	await physics_frame
	Input.action_release("dash")
	_check("M5", cd_ok and p._move == 0, "dash respects its cooldown")

	print("--- movement evals: %d PASS, %d FAIL ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
