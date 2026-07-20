class_name WayweaverEchoAuthority
extends RefCounted

# D8 Slice 3 -- the deliberately narrow host ledger for a Wayweaver echo.
# It does not know about arrows, Focus, equipment inventories or rooms.  Those
# are scene facts supplied by PlayerController after the ordinary Skill path
# has succeeded.  In particular a client packet never gets to describe damage,
# a status, a pierce count, or an identity: `consume` is host-owned and returns
# the already-armed descriptor from WayweaverThreadRules.

var _peers: Dictionary = {} # peer -> {high_water, receipts}


func clear_peer(peer_id: int) -> void:
	_peers.erase(peer_id)


func rebind_peer(old_peer_id: int, new_peer_id: int) -> void:
	if old_peer_id <= 0 or new_peer_id <= 0 or old_peer_id == new_peer_id:
		return
	if _peers.has(old_peer_id):
		_peers[new_peer_id] = (_peers[old_peer_id] as Dictionary).duplicate(true)
		_peers.erase(old_peer_id)


func request(peer_id: int, sender_id: int, nonce: int, aim: Vector3,
		context: Dictionary) -> Dictionary:
	var ledger := _ledger(peer_id)
	var receipts: Dictionary = ledger.get("receipts", {}) as Dictionary
	if nonce > 0 and receipts.has(nonce):
		var replay: Dictionary = (receipts[nonce] as Dictionary).duplicate(true)
		replay["duplicate"] = true
		return replay
	var receipt := {
		"nonce": nonce, "accepted": false, "reason": "rejected",
		"duplicate": false, "descriptor": {},
	}
	# A nonce at or below the accepted/rejected high-water is never a new
	# request, even after receipts age out.  This closes replay after reconnect.
	if nonce <= 0:
		return receipt
	if nonce <= int(ledger.get("high_water", 0)):
		receipt["reason"] = "stale_nonce"
		return receipt
	if peer_id <= 0 or sender_id != peer_id:
		# Never let a forged node-path sender advance another body's ledger.
		receipt["reason"] = "sender_mismatch"
		return receipt
	if not bool(context.get("session_active", false)):
		return _remember(peer_id, nonce, receipt, "session_lost")
	if int(context.get("body_peer", -1)) != peer_id:
		# Same rule for a stale/rebound body path: no victim high-water mutation.
		receipt["reason"] = "body_mismatch"
		return receipt
	if bool(context.get("dead", true)):
		return _remember(peer_id, nonce, receipt, "dead")
	if not bool(context.get("wayweaver_equipped", false)):
		return _remember(peer_id, nonce, receipt, "weapon_missing")
	if not bool(context.get("real_basic_release", false)):
		return _remember(peer_id, nonce, receipt, "not_basic_release")
	# The host's Basic observation is a one-shot correlation record, not a
	# generic "someone fired recently" flag. Keep it attached to this body and
	# the room in which that release occurred.
	if int(context.get("basic_body_peer", -1)) != peer_id \
			or String(context.get("basic_room_key", "")) != String(context.get("room_key", "")):
		return _remember(peer_id, nonce, receipt, "basic_context_mismatch")
	if not _valid_aim(aim):
		return _remember(peer_id, nonce, receipt, "bad_aim")
	var basic_aim = context.get("basic_aim", Vector3.ZERO)
	if not basic_aim is Vector3 or not _aim_matches(aim, basic_aim as Vector3):
		return _remember(peer_id, nonce, receipt, "aim_mismatch")
	var room_key := String(context.get("room_key", ""))
	if room_key == "":
		return _remember(peer_id, nonce, receipt, "ineligible_room")
	var consume: Callable = context.get("consume", Callable())
	if not consume.is_valid():
		return _remember(peer_id, nonce, receipt, "no_host_descriptor")
	var descriptor = consume.call()
	if not descriptor is Dictionary or not bool((descriptor as Dictionary).get("ok", false)):
		return _remember(peer_id, nonce, receipt, "not_armed")
	var locked: Dictionary = descriptor as Dictionary
	# Belt-and-suspenders identity/room check: the reducer is the authority, but
	# no stale descriptor can cross a room boundary.
	if String(locked.get("identity", "")) == "" \
			or String(locked.get("room_key", room_key)) != room_key:
		return _remember(peer_id, nonce, receipt, "descriptor_mismatch")
	receipt["accepted"] = true
	receipt["reason"] = "accepted"
	receipt["descriptor"] = {
		"room_key": room_key,
		"identity": String(locked.get("identity", "")),
		"effect": (locked.get("effect", {}) as Dictionary).duplicate(true),
	}
	return _remember(peer_id, nonce, receipt)


func _valid_aim(aim: Vector3) -> bool:
	if not aim.is_finite():
		return false
	var flat := Vector3(aim.x, 0.0, aim.z)
	return flat.length() >= 0.98 and flat.length() <= 1.02 and absf(aim.y) <= 0.01


func _aim_matches(requested: Vector3, observed: Vector3) -> bool:
	if not _valid_aim(observed):
		return false
	return requested.normalized().dot(observed.normalized()) >= 0.995


func _ledger(peer_id: int) -> Dictionary:
	if not _peers.has(peer_id):
		_peers[peer_id] = {"high_water": 0, "receipts": {}}
	return _peers[peer_id] as Dictionary


func _remember(peer_id: int, nonce: int, receipt: Dictionary, reason: String = "") -> Dictionary:
	var out := receipt.duplicate(true)
	if reason != "":
		out["reason"] = reason
	var ledger := _ledger(peer_id)
	ledger["high_water"] = maxi(int(ledger.get("high_water", 0)), nonce)
	var receipts: Dictionary = ledger.get("receipts", {}) as Dictionary
	receipts[nonce] = out.duplicate(true)
	if receipts.size() > 32:
		var keys := receipts.keys()
		keys.sort()
		receipts.erase(keys[0])
	ledger["receipts"] = receipts
	_peers[peer_id] = ledger
	return out
