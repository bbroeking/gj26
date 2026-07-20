class_name D7ControlStability
extends RefCounted

# A strict D7 control handoff does not need hundreds of milliseconds of real
# wall-clock silence.  It needs repeated observations that the same scene owns
# control and that no modal/pause has reclaimed it.  Game places one process
# frame and one physics frame between observations; this tracker owns the
# consecutive/owner-reset contract and exposes a diagnostic receipt.

const REQUIRED_OBSERVATIONS := 3

var _owner_key := ""
var _consecutive := 0
var _max_consecutive := 0
var _resets := 0


func observe(owner_key: String, control_ready: bool) -> bool:
	if owner_key == "" or not control_ready:
		reset()
		return false
	if _owner_key != owner_key:
		if _owner_key != "" or _consecutive > 0:
			_resets += 1
		_owner_key = owner_key
		_consecutive = 0
	_consecutive += 1
	_max_consecutive = maxi(_max_consecutive, _consecutive)
	return _consecutive >= REQUIRED_OBSERVATIONS


func reset() -> void:
	if _owner_key != "" or _consecutive > 0:
		_resets += 1
	_owner_key = ""
	_consecutive = 0


func receipt() -> Dictionary:
	return {
		"required_observations": REQUIRED_OBSERVATIONS,
		"owner_key": _owner_key,
		"consecutive_observations": _consecutive,
		"max_consecutive_observations": _max_consecutive,
		"resets": _resets,
		"process_observation_between_checks": true,
		"physics_observation_between_checks": true,
	}
