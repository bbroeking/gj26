extends Node

# Spec 14 — global hitstop. A brief freeze on a hit sells the impact.
# Registered as an autoload (see project.godot) so any script can call
# `Hitstop.freeze(seconds)`.

var _active := false
var _token := 0
var _restore_scale := 1.0

const FREEZE_SCALE := 0.0001

# A hitstop must restore the clock it inherited, not assume the normal game
# clock.  The Web D7 smoke lease deliberately runs at 6x; restoring to 1x from
# a combat hit would silently corrupt the rest of that proof run.
func _valid_scale(value: float) -> bool:
	return is_finite(value) and value > 0.0

func _captured_scale() -> float:
	return Engine.time_scale if _valid_scale(Engine.time_scale) else 1.0

# Freeze the game for `seconds` (real time, regardless of time_scale).
# Spec 46 Phase B — in a co-op session this must NOT touch time_scale:
# the host's frozen clock would stall the simulation for every peer.
# In-session hits keep the other 5 feedback channels; offline keeps the
# full freeze feel.
func freeze(seconds: float) -> void:
	var net := get_node_or_null("/root/NetGame")
	if net != null and bool(net.active):
		return
	if seconds <= 0.0 or not is_finite(seconds):
		return
	# Only the first overlapping hit captures the caller's clock. Later hits
	# extend the same freeze window and must not capture FREEZE_SCALE itself.
	if not _active:
		_restore_scale = _captured_scale()
		_active = true
	_token += 1
	var my := _token
	Engine.time_scale = FREEZE_SCALE
	# Timer with ignore_time_scale=true so it still fires under the freeze.
	var t := get_tree().create_timer(seconds, true, false, true)
	t.timeout.connect(_finish_freeze.bind(my))

func _finish_freeze(my: int) -> void:
	# Only the most recent freeze restores — rapid hits don't end early.
	if my == _token:
		Engine.time_scale = _restore_scale
		_active = false
		_restore_scale = 1.0

# The D7 owned-clock terminal path needs to stop any active freeze before it
# serializes its receipt. Bumping the generation makes all already-created
# real-time timers stale, so none can revive an old scale after this return.
func cancel_and_restore(scale: float) -> void:
	# A bad caller must not strand the game at FREEZE_SCALE. Prefer the captured
	# owner baseline, which is still valid until this terminal cancellation.
	var target := scale if _valid_scale(scale) else _restore_scale
	if not _valid_scale(target):
		target = 1.0
	_token += 1
	_active = false
	_restore_scale = 1.0
	Engine.time_scale = target

func _exit_tree() -> void:
	# A scene/test teardown can remove the autoload while a real-time timer is
	# pending. Restore the captured baseline synchronously and invalidate it.
	if _active:
		cancel_and_restore(_restore_scale)

func is_active() -> bool:
	return _active
