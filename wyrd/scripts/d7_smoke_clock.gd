class_name D7SmokeClock
extends RefCounted

# D7's browser release route is long enough that its test budget needs a
# bounded simulation lease.  This object owns that lease rather than letting
# individual route helpers write Engine.time_scale.  It deliberately knows
# nothing about campaign, combat, or scene state: Game supplies the two proof
# gates and is responsible for cancelling a concurrent Hitstop before restore.

const REQUESTED_SCALE := 6.0
const FRESH_CAMPAIGN_BOUNDARY := "fresh_campaign"

var _active := false
var _prior_scale := 1.0
var _telemetry: Dictionary = {}


func begin(query_active: bool, fresh_campaign_reported: bool,
		activation_boundary: String = FRESH_CAMPAIGN_BOUNDARY) -> bool:
	if _active:
		_telemetry["double_begin_refused"] = true
		_telemetry["last_refusal"] = "already_active"
		return false
	if not query_active:
		_record_refusal("query_inactive", activation_boundary)
		return false
	if not fresh_campaign_reported or activation_boundary != FRESH_CAMPAIGN_BOUNDARY:
		_record_refusal("fresh_campaign_not_reported", activation_boundary)
		return false
	# A lease can only return to a real, already-approved baseline.  Coercing an
	# invalid value to 1.0 would both mutate an unowned clock and conceal the
	# breach that the browser receipt is meant to catch.
	var baseline := Engine.time_scale
	if not is_finite(baseline) or baseline <= 0.0:
		_record_refusal("invalid_baseline_scale", activation_boundary)
		return false
	if baseline > REQUESTED_SCALE:
		_record_refusal("baseline_scale_over_cap", activation_boundary)
		return false
	_prior_scale = baseline
	Engine.time_scale = REQUESTED_SCALE
	_active = true
	_telemetry = {
		"requested_scale": REQUESTED_SCALE,
		"observed_scale": Engine.time_scale,
		"max_observed_scale": Engine.time_scale,
		"captured_baseline_scale": _prior_scale,
		"activated_after_fresh_campaign": true,
		"owner": "d7_smoke_clock",
		"watchdog_clock": "monotonic_real_time",
		"restored_before_terminal_serialization": false,
		"restored": false,
		"terminal_scale": -1.0,
		"terminal_reason": "",
		"active": true,
		"activation_boundary": activation_boundary,
		"query_active": true,
		"fresh_campaign_reported": true,
		"double_begin_refused": false,
	}
	return is_equal_approx(float(_telemetry["observed_scale"]), REQUESTED_SCALE)


func restore(terminal_outcome: String) -> Dictionary:
	if _active:
		Engine.time_scale = _prior_scale
		_active = false
	if _telemetry.is_empty():
		var observed := _safe_positive_scale(Engine.time_scale)
		_telemetry = {
			"requested_scale": REQUESTED_SCALE,
			"observed_scale": observed,
			"max_observed_scale": observed,
			"captured_baseline_scale": observed,
			"activated_after_fresh_campaign": false,
			"owner": "d7_smoke_clock",
			"watchdog_clock": "monotonic_real_time",
			"restored_before_terminal_serialization": false,
			"restored": false,
			"terminal_scale": -1.0,
			"terminal_reason": "",
			"activation_boundary": "",
			"query_active": false,
			"fresh_campaign_reported": false,
		}
	_telemetry["active"] = false
	_telemetry["restored_before_terminal_serialization"] = true
	_telemetry["restored"] = is_equal_approx(Engine.time_scale, _prior_scale)
	_telemetry["terminal_scale"] = Engine.time_scale
	_telemetry["terminal_reason"] = terminal_outcome
	return telemetry()


func record_watchdog(name: String, duration_sec: float, ignore_time_scale: bool,
		fired: bool = false) -> void:
	_telemetry["%s_watchdog" % name] = {
		"duration_sec": duration_sec,
		"ignore_time_scale": ignore_time_scale,
		"armed": not fired,
		"fired": fired,
	}


func record_terminal_watchdog(duration_sec: float, ignore_time_scale: bool,
		attempt_token: String, generation: int, event: String) -> void:
	# The release watchdog is a separate, attempt-owned receipt.  Keep the
	# existing training receipt exact: the Web probe deliberately validates it
	# as a small fixed object.
	var receipt: Dictionary = _telemetry.get("terminal_watchdog", {}).duplicate(true)
	if receipt.is_empty() or String(receipt.get("attempt_token", "")) != attempt_token \
			or int(receipt.get("generation", -1)) != generation:
		receipt = {
			"duration_sec": duration_sec,
			"ignore_time_scale": ignore_time_scale,
			"attempt_token": attempt_token,
			"generation": generation,
			"armed": false,
			"fired": false,
			"cancelled": false,
			"stale": false,
		}
	match event:
		"armed":
			receipt["armed"] = true
		"fired":
			receipt["armed"] = false
			receipt["fired"] = true
		"cancelled":
			receipt["armed"] = false
			receipt["cancelled"] = true
		"stale":
			receipt["stale"] = true
		_:
			push_error("Unknown D7 terminal watchdog event: %s" % event)
	_telemetry["terminal_watchdog"] = receipt


func observe_current_scale() -> bool:
	# `observed_scale` is the verified activation value required by the browser
	# receipt. `max_observed_scale` is the ongoing ownership guard: hitstop's
	# sub-1x freeze is fine, but no D7 checkpoint may discover a value above the
	# one approved lease.
	var observed := Engine.time_scale
	if not is_finite(observed) or observed <= 0.0:
		_telemetry["last_refusal"] = "invalid_runtime_scale"
		return false
	var known_max := float(_telemetry.get("max_observed_scale", observed))
	_telemetry["max_observed_scale"] = maxf(known_max, observed)
	if observed > REQUESTED_SCALE:
		_telemetry["last_refusal"] = "runtime_scale_over_cap"
		return false
	return true


func is_active() -> bool:
	return _active


func prior_scale() -> float:
	return _prior_scale


func telemetry() -> Dictionary:
	return _telemetry.duplicate(true)


func _record_refusal(reason: String, activation_boundary: String) -> void:
	var raw_observed := Engine.time_scale
	# Keep telemetry JSON-safe without treating a bad value as an allowed
	# baseline.  `baseline_valid` tells consumers why no lease exists.
	var observed := raw_observed if is_finite(raw_observed) else -1.0
	_telemetry = {
		"requested_scale": REQUESTED_SCALE,
		"observed_scale": observed,
		"max_observed_scale": observed,
		"captured_baseline_scale": observed,
		"activated_after_fresh_campaign": false,
		"owner": "d7_smoke_clock",
		"watchdog_clock": "monotonic_real_time",
		"restored_before_terminal_serialization": false,
		"restored": false,
		"terminal_scale": -1.0,
		"terminal_reason": "",
		"active": false,
		"activation_boundary": activation_boundary,
		"query_active": false,
		"fresh_campaign_reported": false,
		"last_refusal": reason,
		"baseline_valid": is_finite(raw_observed) and raw_observed > 0.0 \
			and raw_observed <= REQUESTED_SCALE,
		"double_begin_refused": false,
	}


func _safe_positive_scale(value: float) -> float:
	return value if is_finite(value) and value > 0.0 else 1.0
