extends SceneTree

# D7 owned-clock contract — Hitstop must return the clock it borrowed. This
# focused script deliberately uses real-time timers so it remains valid while
# the game is frozen at FREEZE_SCALE.
#   WYRD_NO_SAVE=1 godot --headless --path . --script res://test_hitstop_time_scale_ownership.gd

const HitstopScript := preload("res://scripts/hitstop.gd")
const NetGameScript := preload("res://scripts/net_game.gd")

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

func _real_wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout

func _near(a: float, b: float) -> bool:
	return is_equal_approx(a, b)

func _run() -> void:
	print("--- D7 hitstop time-scale ownership ---")
	var hs: Node = HitstopScript.new()
	hs.name = "Hitstop"
	root.add_child(hs)
	await process_frame

	# Baseline 1x remains the existing combat contract.
	Engine.time_scale = 1.0
	hs.freeze(0.18)
	_check("H1", hs.is_active() and Engine.time_scale < 0.01,
		"1x clock enters hitstop at %.4f" % Engine.time_scale)
	await _real_wait(0.22)
	_check("H2", not hs.is_active() and _near(Engine.time_scale, 1.0),
		"1x clock restores to %.2f" % Engine.time_scale)

	# The leased D7 proof clock is the important regression: 6x must survive a
	# complete freeze exactly, not be reset to the historical hard-coded 1x.
	Engine.time_scale = 6.0
	hs.freeze(0.18)
	_check("H3", hs.is_active() and Engine.time_scale < 0.01,
		"6x clock enters hitstop at %.4f" % Engine.time_scale)
	await _real_wait(0.22)
	_check("H4", not hs.is_active() and _near(Engine.time_scale, 6.0),
		"6x clock restores to %.2f" % Engine.time_scale)

	# The early timer is deliberately allowed to fire while the later generation
	# remains active. It must be stale and cannot restore the borrowed 6x clock.
	Engine.time_scale = 6.0
	hs.freeze(0.05)
	await _real_wait(0.015)
	hs.freeze(0.10)
	await _real_wait(0.06)
	_check("H5", hs.is_active() and Engine.time_scale < 0.01,
		"stale first timer cannot end newer freeze (scale %.4f)" % Engine.time_scale)
	await _real_wait(0.08)
	_check("H6", not hs.is_active() and _near(Engine.time_scale, 6.0),
		"latest overlap restores captured 6x clock (%.2f)" % Engine.time_scale)

	# Terminal cancellation restores synchronously and invalidates the pending
	# timer. Waiting past the original deadline proves no stale callback wins.
	hs.freeze(0.18)
	await process_frame
	hs.cancel_and_restore(6.0)
	_check("H7", not hs.is_active() and _near(Engine.time_scale, 6.0),
		"terminal cancel restores 6x synchronously (%.2f)" % Engine.time_scale)
	await _real_wait(0.22)
	_check("H8", not hs.is_active() and _near(Engine.time_scale, 6.0),
		"cancelled timer stays stale (%.2f)" % Engine.time_scale)
	# Invalid terminal input cannot strand the world in hitstop: it falls back
	# to the captured valid baseline and still invalidates its pending callback.
	hs.freeze(0.18)
	hs.cancel_and_restore(NAN)
	_check("H9", not hs.is_active() and _near(Engine.time_scale, 6.0),
		"invalid terminal scale falls back to captured 6x (%.2f)" % Engine.time_scale)
	await _real_wait(0.22)
	_check("H10", not hs.is_active() and _near(Engine.time_scale, 6.0),
		"invalid-cancelled timer stays stale (%.2f)" % Engine.time_scale)

	# Co-op still owns no global time-scale; its hit feedback remains visual.
	var net: Node = root.get_node_or_null("NetGame")
	var net_fixture := false
	if net == null:
		net = NetGameScript.new()
		net.name = "NetGame"
		root.add_child(net)
		net_fixture = true
	var was_net_active := bool(net.active)
	net.active = true
	await process_frame
	hs.freeze(0.04)
	await _real_wait(0.06)
	_check("H11", not hs.is_active() and _near(Engine.time_scale, 6.0),
		"co-op hitstop is a clock no-op (%.2f)" % Engine.time_scale)
	net.active = was_net_active
	if net_fixture:
		net.queue_free()
	await process_frame

	# Removing Hitstop during a freeze is another terminal path. _exit_tree must
	# restore the captured owner scale without needing the real-time callback.
	hs.freeze(0.20)
	await process_frame
	hs.queue_free()
	await process_frame
	_check("H12", _near(Engine.time_scale, 6.0),
		"teardown restores captured 6x clock (%.2f)" % Engine.time_scale)
	await _real_wait(0.24)
	_check("H13", _near(Engine.time_scale, 6.0),
		"teardown-invalidated callback stays harmless (%.2f)" % Engine.time_scale)

	Engine.time_scale = 1.0
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
