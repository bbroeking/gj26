class_name ThreadstepAuthority
extends RefCounted

# Fire in the Bough — the small, deterministic host ledger behind Threadstep.
#
# This deliberately contains no Node/RPC calls.  PlayerController owns the
# transport and collision query, while this class owns the facts that must not
# be inferred from a client packet: sender/body binding, cooldown, and
# idempotent nonce results. Focus remains owner-local under the current party
# architecture: the client reserves it before sending and consumes it only on
# a matching acceptance. The only client payload passed to `request` is a
# nonce and a direction.

const COST := 20.0
const COOLDOWN := 8.0
const MAX_DISTANCE := 5.0
const GRACE_SECONDS := 0.22

var _now := 0.0
# peer id -> {"cooldown_until": float, "results": Dictionary}
var _peers: Dictionary = {}


func tick(delta: float) -> void:
	_now = maxf(0.0, _now + maxf(0.0, delta))


func clear_peer(peer_id: int) -> void:
	_peers.erase(peer_id)


func request(peer_id: int, sender_id: int, nonce: int, direction: Vector3,
		origin: Vector3, context: Dictionary) -> Dictionary:
	# Replay is intentionally checked before every mutable condition. A dropped
	# ack can be retried without a second debit, grace, or endpoint calculation.
	var ledger := _ledger(peer_id)
	var prior: Dictionary = ledger.get("results", {}).get(nonce, {})
	if not prior.is_empty():
		var replay := prior.duplicate(true)
		replay.duplicate = true
		return replay
	var result := {"nonce": nonce, "accepted": false, "reason": "rejected",
		"endpoint": origin, "duplicate": false}
	if peer_id <= 0 or sender_id != peer_id:
		return _remember(peer_id, nonce, result, "sender_mismatch")
	if nonce <= 0:
		return _remember(peer_id, nonce, result, "bad_nonce")
	if not bool(context.get("session_active", false)):
		return _remember(peer_id, nonce, result, "session_lost")
	if not bool(context.get("entitled", false)):
		return _remember(peer_id, nonce, result, "not_entitled")
	if int(context.get("body_peer", -1)) != peer_id:
		return _remember(peer_id, nonce, result, "body_mismatch")
	if float(ledger.get("cooldown_until", 0.0)) > _now:
		return _remember(peer_id, nonce, result, "cooldown")
	if not _valid_direction(direction):
		return _remember(peer_id, nonce, result, "bad_direction")
	var probe: Callable = context.get("probe", Callable())
	if not probe.is_valid():
		return _remember(peer_id, nonce, result, "no_world_probe")
	var checked = probe.call(origin, direction.normalized(), MAX_DISTANCE)
	if not (checked is Dictionary) or not bool((checked as Dictionary).get("ok", false)):
		return _remember(peer_id, nonce, result, "blocked")
	var endpoint: Vector3 = (checked as Dictionary).get("endpoint", origin)
	if not endpoint.is_finite() or endpoint.distance_to(origin) > MAX_DISTANCE + 0.02:
		return _remember(peer_id, nonce, result, "bad_endpoint")
	ledger.cooldown_until = _now + COOLDOWN
	_peers[peer_id] = ledger
	result.accepted = true
	result.reason = "accepted"
	result.endpoint = endpoint
	result.grace_seconds = GRACE_SECONDS
	return _remember(peer_id, nonce, result)


func cooldown_left(peer_id: int) -> float:
	var ledger := _ledger(peer_id)
	return maxf(0.0, float(ledger.get("cooldown_until", 0.0)) - _now)


func _valid_direction(direction: Vector3) -> bool:
	if not direction.is_finite():
		return false
	var flat := Vector3(direction.x, 0.0, direction.z)
	return flat.length() >= 0.98 and flat.length() <= 1.02 and absf(direction.y) <= 0.01


func _ledger(peer_id: int) -> Dictionary:
	if not _peers.has(peer_id):
		_peers[peer_id] = {"cooldown_until": 0.0, "results": {}}
	return _peers[peer_id] as Dictionary


func _remember(peer_id: int, nonce: int, result: Dictionary, reason: String = "") -> Dictionary:
	var out := result.duplicate(true)
	if reason != "":
		out.reason = reason
	var ledger := _ledger(peer_id)
	var results: Dictionary = ledger.get("results", {})
	# Invalid nonces are not retained: otherwise a malicious negative nonce
	# could grow the replay ledger forever. Valid nonces get one durable answer.
	if nonce > 0:
		results[nonce] = out.duplicate(true)
		if results.size() > 32:
			var oldest := results.keys()
			oldest.sort()
			results.erase(oldest[0])
		ledger.results = results
		_peers[peer_id] = ledger
	return out
