extends SceneTree

# Focused Fire-in-the-Bough authority contract.  This stays pure and fast: the
# World collision integration is exercised through the injected host probe;
# the assertions lock the nonce, sender and cooldown invariants which
# must hold before a physical endpoint is ever applied.

const ThreadstepAuthority := preload("res://scripts/threadstep_authority.gd")

var _pass := 0
var _fail := 0
var _blocked := false

func _initialize() -> void:
	_run()

func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % name)
	else:
		_fail += 1
		print("  ✗ %s %s" % [name, detail])

func _probe(origin: Vector3, direction: Vector3, distance: float) -> Dictionary:
	if _blocked:
		return {"ok": false}
	return {"ok": true, "endpoint": origin + direction * distance}

func _ctx(peer: int, session_active: bool = true) -> Dictionary:
	return {"session_active": session_active, "entitled": true,
		"body_peer": peer, "probe": Callable(self, "_probe")}

func _run() -> void:
	print("--- Threadstep authority check ---")
	var auth := ThreadstepAuthority.new()
	var forward := Vector3.FORWARD

	# A blocked capsule/nav/gate probe starts no authoritative cooldown.
	_blocked = true
	var blocked: Dictionary = auth.request(2, 2, 1, forward, Vector3.ZERO, _ctx(2))
	_check("blocked probe rejects", not bool(blocked.accepted) and blocked.reason == "blocked", str(blocked))
	_check("blocked probe starts no cooldown", auth.cooldown_left(2) == 0.0)

	# New peer: a real endpoint is exactly five metres and consumes once.
	_blocked = false
	var accepted: Dictionary = auth.request(3, 3, 9, forward, Vector3(1, 0, 1), _ctx(3))
	_check("accepted request returns fixed endpoint", bool(accepted.accepted)
		and (accepted.endpoint as Vector3).distance_to(Vector3(1, 0, -4)) < 0.01, str(accepted))
	_check("accepted request starts eight-second cooldown", absf(auth.cooldown_left(3) - 8.0) < 0.01)
	var replay: Dictionary = auth.request(3, 3, 9, forward, Vector3(99, 0, 99), _ctx(3))
	_check("duplicate nonce replays without second cost", bool(replay.accepted) and bool(replay.duplicate)
		and (replay.endpoint as Vector3).distance_to(accepted.endpoint) < 0.01)

	# A second nonce cannot bypass the host-side per-peer cooldown. The owner's
	# single pending reservation independently prevents a pre-ack second send.
	var cd_a: Dictionary = auth.request(5, 5, 1, forward, Vector3.ZERO, _ctx(5))
	var cd_b: Dictionary = auth.request(5, 5, 2, forward, Vector3.ZERO, _ctx(5))
	_check("host cooldown rejects a fresh nonce", bool(cd_a.accepted)
		and not bool(cd_b.accepted) and cd_b.reason == "cooldown", str(cd_b))

	# A packet cannot borrow another player's puppet/origin, and bad vectors are
	# rejected before the probe is called.
	var spoof: Dictionary = auth.request(6, 7, 1, forward, Vector3.ZERO, _ctx(6))
	var bad_dir: Dictionary = auth.request(6, 6, 2, Vector3(9, 0, 0), Vector3.ZERO, _ctx(6))
	_check("spoofed sender is rejected", not bool(spoof.accepted) and spoof.reason == "sender_mismatch")
	_check("non-normalized direction is rejected", not bool(bad_dir.accepted) and bad_dir.reason == "bad_direction")

	# Session loss is a cancellation, not a delayed accept.  The player-side
	# pending reservation is released by PlayerController's session_ended hook.
	var lost: Dictionary = auth.request(8, 8, 1, forward, Vector3.ZERO, _ctx(8, false))
	_check("session loss rejects without cooldown", not bool(lost.accepted)
		and lost.reason == "session_lost" and auth.cooldown_left(8) == 0.0, str(lost))

	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
