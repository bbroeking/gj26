extends Node

# Spec 14 — global hitstop. A brief freeze on a hit sells the impact.
# Registered as an autoload (see project.godot) so any script can call
# `Hitstop.freeze(seconds)`.

var _active := false
var _token := 0

# Freeze the game for `seconds` (real time, regardless of time_scale).
func freeze(seconds: float) -> void:
	_token += 1
	var my := _token
	_active = true
	Engine.time_scale = 0.0001
	# Timer with ignore_time_scale=true so it still fires under the freeze.
	var t := get_tree().create_timer(seconds, true, false, true)
	await t.timeout
	# Only the most recent freeze restores — rapid hits don't end early.
	if my == _token:
		Engine.time_scale = 1.0
		_active = false

func is_active() -> bool:
	return _active
