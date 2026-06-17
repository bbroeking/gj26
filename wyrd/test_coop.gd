extends SceneTree

# Co-op (C-3 boss host-authority) — the guest-side cosmetic-replay logic. The
# boss is a net_puppet on guests, so its _tick_ai never runs there; pos+hp ride
# the enemy snapshot, and these replay methods reproduce the rest (boss bar,
# arena gates, phase, dodgeable telegraphs). End-to-end host→guest transport is
# the same NetPlayer/_net_cast mechanism verified live; this locks the receive
# side deterministically.
# Run: WYRD_NO_SAVE=1 godot --headless --path . --script res://test_coop.gd

const BossScript := preload("res://scripts/boss.gd")

var _pass := 0
var _fail := 0

func _check(id: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
		print("  ✗ %s %s" % [id, detail])

func _init() -> void:
	_run()

func _run() -> void:
	print("--- co-op evals (C-3 boss replay) ---")
	await _test_boss_replay()
	print("--- coop evals: %d PASS, %d FAIL ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _count_meshes(n: Node) -> int:
	var c := 0
	for ch in n.get_children():
		if ch is MeshInstance3D:
			c += 1
		c += _count_meshes(ch)
	return c

func _test_boss_replay() -> void:
	var host := Node3D.new()
	host.name = "BossHost"
	root.add_child(host)
	var boss = BossScript.new()
	boss.name = "NetFoeTest"
	host.add_child(boss)
	boss.cache_meshes()
	boss.setup(100, 0.6, 2.0)     # hp_max = 100
	boss.net_puppet = true        # simulate a guest's puppet boss
	await physics_frame
	await physics_frame

	# Capture the signals the boss bar + arena gates are wired to (Dictionary so
	# the lambda's mutation escapes — GDScript captures primitives by value).
	var got := {"aggro": false, "phase": 0, "hp": -1}
	boss.aggroed.connect(func(): got.aggro = true)
	boss.phase_changed.connect(func(p: int): got.phase = p)
	boss.boss_hp_changed.connect(func(cur: int, _mx: int): got.hp = cur)

	# 1) aggro replay → drives bossbar.show_boss + _raise_gates on the guest.
	boss._net_boss_aggro()
	_check("C3 aggro replay fires aggroed", got.aggro == true,
		"aggroed=%s" % str(got.aggro))

	# 2) phase replay → bossbar.set_phase + phase tint.
	boss._net_boss_phase(3)
	_check("C3 phase replay fires phase_changed(3)", got.phase == 3,
		"phase=%d" % got.phase)

	# 3) hp via snapshot → boss bar HP tracks the host (net_apply_state override).
	boss.net_apply_state(boss.global_position, 42)
	_check("C3 snapshot hp drives boss bar", got.hp == 42 and int(boss.hp) == 42,
		"hp=%d emit=%d" % [int(boss.hp), got.hp])

	# 4) telegraph replay → a dodgeable decal appears (disc).
	var before := _count_meshes(host)
	boss._net_boss_telegraph(false, boss.global_position, Vector3.ZERO, 0.0, 2.5, 0.2)
	await physics_frame
	var after := _count_meshes(host)
	_check("C3 telegraph decal shown", after > before,
		"meshes %d -> %d" % [before, after])

	# 5) ...and it auto-frees after its window (the host's AI isn't here to clear it).
	await create_timer(0.35).timeout
	var cleaned := _count_meshes(host)
	_check("C3 telegraph auto-frees", cleaned == before,
		"meshes after window=%d (expected %d)" % [cleaned, before])

	# 6) a non-networked boss must NOT broadcast (offline / solo guard).
	_check("C3 offline does not broadcast", not boss._net_broadcasting())
