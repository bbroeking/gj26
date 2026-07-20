class_name KnotEaterRules
extends RefCounted

# Pure, boss-scoped Knot-Eater authority.  This file intentionally knows no
# Nodes, RPCs, player resources, CampaignData, or save state.
#
# Coordinator API (locked):
#   dispatch(command, facts) -> receipt/result
#     command.kind: survival | exposure | time | death | unbind | mark | name
#       | settlement_result. Player commands carry peer_id + nonce; mark also
#       carries knot_id + reel_nonce; name carries road_name_id.
#     facts: trusted/world_ready/chart_instance_id/attempt_id/now_ms plus host
#       probes (sender_id, body_peer, in_range, has_line_of_sight) as relevant.
#   view(now_ms), snapshot(now_ms), snapshot_for_peer(peer_id, now_ms),
#   apply_snapshot(snapshot), replay(transitions).
# Trusted scene adapters, rather than a client, make survival/exposure/time/
# death/settlement_result. `mark` returns a 35-Focus receipt; it never debits.

const PHASE_GNAWING := "gnawing"
const PHASE_ANCHORS := "anchors"
const PHASE_KNOTS := "knots"
const PHASE_REELING := "reeling"
const PHASE_NAMING := "naming"
const PHASE_SETTLING := "settling"
const PHASE_SETTLED := "settled"
const PHASES := [PHASE_GNAWING, PHASE_ANCHORS, PHASE_KNOTS, PHASE_REELING,
	PHASE_NAMING, PHASE_SETTLING, PHASE_SETTLED]
const ANCHOR_IDS := ["anchor_1", "anchor_2", "anchor_3"]
const KNOT_IDS := ["knot_1", "knot_2", "knot_3"]
const ROAD_CHOICES := ["lantern_path", "mended_way", "open_footpath"]
const ALL_THREE := 7
const MARK_COST := 35
const MARK_COOLDOWN_MS := 14000
const REEL_WINDOW_MS := 3000
const RECEIPT_LIMIT := 32
const AUDIT_LIMIT := 96

var chart_instance_id: String
var attempt_id: String
var _phase := PHASE_GNAWING
var _revision := 0
var _anchor_mask := 0
var _knot_mask := 0
var _active_knot_id := ""
var _reel_nonce := 0
var _reel_expires_at_ms := 0
var _pending_effect: Dictionary = {}
var _road_name_id := ""
var _peer_ledgers: Dictionary = {} # peer -> { high_water, receipts, latest }
var _audit: Array = []
var _accepted_transitions: Array = []
var _last_applied_snapshot_revision := -1


func _init(p_chart_instance_id: String = "", p_attempt_id: String = "") -> void:
	chart_instance_id = p_chart_instance_id
	attempt_id = p_attempt_id


func dispatch(command: Dictionary, facts: Dictionary = {}) -> Dictionary:
	var kind := String(command.get("kind", command.get("type", "")))
	if kind.is_empty():
		return _result(false, "bad_command")
	if kind in ["unbind", "mark", "name"]:
		return _dispatch_player(kind, command, facts)
	if not _trusted_identity(facts):
		return _result(false, "identity_mismatch")
	match kind:
		"survival", "survived":
			if _phase != PHASE_GNAWING:
				return _result(false, "wrong_phase")
			_phase = PHASE_ANCHORS
			_accept_transition(command, facts, false)
			return _result(true, "accepted")
		"exposure", "expose":
			return _expose(command, facts)
		"time", "tick":
			return _tick(command, facts)
		"death", "died":
			# The boss has a permanent positive damage floor.  Damage/death events
			# are presentation diagnostics only: they must not advance, clear, or
			# invalidate a live naming/settlement transition.
			return _result(false, "boss_death_inert")
		"settlement_result":
			return _settlement_result(command, facts)
		"reset_for_retry":
			return _reset_for_retry(command, facts)
		_:
			return _result(false, "bad_command")


func view(now_ms: int = 0) -> Dictionary:
	var remaining := maxi(0, _reel_expires_at_ms - now_ms) if _phase == PHASE_REELING else 0
	return {
		"chart_instance_id": chart_instance_id, "attempt_id": attempt_id,
		"revision": _revision, "phase": _phase, "anchor_mask": _anchor_mask,
		"knot_mask": _knot_mask, "active_knot_id": _active_knot_id,
		"reel_nonce": _reel_nonce, "telegraph": {"kind": "reeling" if _phase == PHASE_REELING else "", "nonce": _reel_nonce, "remaining_ms": remaining},
		"mark_ready": _phase == PHASE_REELING and remaining > 0,
		"naming_choices": ROAD_CHOICES.duplicate(), "settling": _phase == PHASE_SETTLING,
		"settled": _phase == PHASE_SETTLED, "road_name_id": _road_name_id,
		"pending_effect": _pending_effect.duplicate(true),
	}


func snapshot(now_ms: int = 0) -> Dictionary:
	var out := view(now_ms)
	out["schema"] = "knot_eater_rules/v1"
	out["reel_expires_at_ms"] = _reel_expires_at_ms
	return out


func snapshot_for_peer(peer_id: int, now_ms: int = 0) -> Dictionary:
	var out := snapshot(now_ms)
	var ledger := _peer_ledgers.get(peer_id, {}) as Dictionary
	out["peer_id"] = peer_id
	out["mark_ready"] = _phase == PHASE_REELING and now_ms < _reel_expires_at_ms \
		and now_ms >= int(ledger.get("cooldown_until_ms", 0))
	out["mark_cooldown_left_ms"] = maxi(0, int(ledger.get("cooldown_until_ms", 0)) - now_ms)
	out["receipt"] = (ledger.get("latest", {}) as Dictionary).duplicate(true)
	return out


# Guest mirrors use this atomic boundary.  A malformed or stale packet leaves
# every local field untouched and returns false.
func apply_snapshot(raw: Dictionary, local_now_ms: int = -1) -> bool:
	if not _valid_snapshot(raw):
		return false
	var incoming_revision := int(raw.get("revision", -1))
	if incoming_revision <= _last_applied_snapshot_revision:
		return false
	_phase = String(raw.phase)
	_revision = incoming_revision
	_anchor_mask = int(raw.anchor_mask)
	_knot_mask = int(raw.knot_mask)
	_active_knot_id = String(raw.active_knot_id)
	_reel_nonce = int(raw.reel_nonce)
	# Host and guest processes do not share a monotonic clock origin. Production
	# mirrors pass their local receipt time so a Reeling window is reconstructed
	# from the transmitted remaining duration rather than a host tick value.
	if _phase == PHASE_REELING and local_now_ms >= 0:
		var telegraph := raw.get("telegraph", {}) as Dictionary
		_reel_expires_at_ms = local_now_ms + maxi(0,
			int(telegraph.get("remaining_ms", 0)))
	else:
		_reel_expires_at_ms = int(raw.reel_expires_at_ms)
	_pending_effect = (raw.get("pending_effect", {}) as Dictionary).duplicate(true)
	_road_name_id = String(raw.get("road_name_id", ""))
	_last_applied_snapshot_revision = incoming_revision
	return true


# Replays only transitions this module accepted.  It is deliberately not save
# data.  Return false atomically on malformed records or a non-accepting replay.
func replay(transitions: Array) -> bool:
	var rebuilt = get_script().new(chart_instance_id, attempt_id)
	for item in transitions:
		if not (item is Dictionary):
			return false
		var record := item as Dictionary
		var command = record.get("command", {})
		var facts = record.get("facts", {})
		if not (command is Dictionary) or not (facts is Dictionary):
			return false
		var result: Dictionary = rebuilt.dispatch(command as Dictionary, facts as Dictionary)
		if not bool(result.get("accepted", false)):
			return false
	_phase = rebuilt._phase
	_revision = rebuilt._revision
	_anchor_mask = rebuilt._anchor_mask
	_knot_mask = rebuilt._knot_mask
	_active_knot_id = rebuilt._active_knot_id
	_reel_nonce = rebuilt._reel_nonce
	_reel_expires_at_ms = rebuilt._reel_expires_at_ms
	_pending_effect = rebuilt._pending_effect.duplicate(true)
	_road_name_id = rebuilt._road_name_id
	_peer_ledgers = rebuilt._peer_ledgers.duplicate(true)
	_audit = rebuilt._audit.duplicate(true)
	_accepted_transitions = rebuilt._accepted_transitions.duplicate(true)
	return true


func accepted_transitions() -> Array:
	return _accepted_transitions.duplicate(true)


# A reconnect may receive a new transient ENet peer ID. The transport adapter
# proves the stable session-player token before asking this boss-scoped ledger
# to move. Receipts are rewritten to the new sender identity; Focus reservation
# IDs remain owner-opaque and unchanged.
func rebind_peer(old_peer_id: int, new_peer_id: int) -> bool:
	if old_peer_id <= 0 or new_peer_id <= 0:
		return false
	if old_peer_id == new_peer_id:
		return true
	if _peer_ledgers.has(new_peer_id):
		return false
	if not _peer_ledgers.has(old_peer_id):
		return true
	var ledger := (_peer_ledgers[old_peer_id] as Dictionary).duplicate(true)
	var receipts := ledger.get("receipts", {}) as Dictionary
	for raw_nonce in receipts.keys():
		var receipt := (receipts[raw_nonce] as Dictionary).duplicate(true)
		receipt["peer_id"] = new_peer_id
		receipts[raw_nonce] = receipt
	ledger["receipts"] = receipts
	var latest := (ledger.get("latest", {}) as Dictionary).duplicate(true)
	if not latest.is_empty():
		latest["peer_id"] = new_peer_id
	ledger["latest"] = latest
	_peer_ledgers.erase(old_peer_id)
	_peer_ledgers[new_peer_id] = ledger
	return true


# World-readiness is a transport gate, but a reservation-bearing terminal
# answer still needs the same peer-specific reconnect durability as a gameplay
# receipt. The adapter supplies its next encounter nonce; this method never
# accepts a Mark or mutates phase/masks.
func record_setup_rejection(peer_id: int, nonce: int, reservation_nonce: int,
		reason: String) -> Dictionary:
	if peer_id <= 0 or nonce <= 0 or reservation_nonce <= 0 \
			or reason not in ["world_not_ready", "not_ready"]:
		return _result(false, "bad_setup_receipt", peer_id, nonce)
	var ledger := _ledger(peer_id)
	var receipts := ledger.get("receipts", {}) as Dictionary
	for raw_nonce in receipts.keys():
		var prior := receipts[raw_nonce] as Dictionary
		if int(prior.get("reservation_nonce", 0)) == reservation_nonce:
			var replayed := prior.duplicate(true)
			replayed["kind"] = "mark"
			replayed["duplicate"] = true
			ledger["latest"] = replayed.duplicate(true)
			_peer_ledgers[peer_id] = ledger
			_revision += 1
			return replayed
	var receipt := _result(false, reason, peer_id, nonce)
	receipt["reservation_nonce"] = reservation_nonce
	receipt["kind"] = "mark"
	return _remember(peer_id, nonce, receipt)


func _dispatch_player(kind: String, command: Dictionary, facts: Dictionary) -> Dictionary:
	var peer_id := int(command.get("peer_id", facts.get("peer_id", 0)))
	var nonce := int(command.get("nonce", 0))
	if peer_id <= 0 or nonce <= 0:
		return _result(false, "bad_nonce", peer_id, nonce)
	var ledger := _ledger(peer_id)
	var receipts := ledger.get("receipts", {}) as Dictionary
	if receipts.has(nonce):
		var prior := (receipts[nonce] as Dictionary).duplicate(true)
		prior["duplicate"] = true
		return prior
	if nonce <= int(ledger.get("high_water", 0)):
		return _result(false, "too_old", peer_id, nonce)
	if not _player_identity(facts, peer_id):
		return _remember(peer_id, nonce, _result(false, "identity_mismatch", peer_id, nonce))
	if int(facts.get("sender_id", peer_id)) != peer_id:
		return _remember(peer_id, nonce, _result(false, "sender_mismatch", peer_id, nonce))
	if int(facts.get("body_peer", peer_id)) != peer_id:
		return _remember(peer_id, nonce, _result(false, "body_mismatch", peer_id, nonce))
	var result: Dictionary
	match kind:
		"unbind": result = _unbind(peer_id, command, facts)
		"mark": result = _mark(peer_id, command, facts)
		"name": result = _name(peer_id, command, facts)
		_: result = _result(false, "bad_command", peer_id, nonce)
	if kind == "mark":
		# Encounter ordering and owner resource reconciliation intentionally use
		# different nonce domains. Preserve both in every accepted or rejected
		# receipt so reconnect never confuses an earlier unbind with a Mark debit.
		result["reservation_nonce"] = int(command.get("reservation_nonce", 0))
		result["kind"] = "mark"
	return _remember(peer_id, nonce, result)


func _unbind(peer_id: int, command: Dictionary, facts: Dictionary) -> Dictionary:
	if _phase != PHASE_ANCHORS:
		return _result(false, "wrong_phase", peer_id, int(command.nonce))
	var index := _index_for(command.get("anchor_id", command.get("target_id", "")), ANCHOR_IDS)
	if index < 0:
		return _result(false, "bad_anchor", peer_id, int(command.nonce))
	var bit := 1 << index
	if (_anchor_mask & bit) != 0:
		return _result(false, "anchor_already_unbound", peer_id, int(command.nonce))
	_anchor_mask |= bit
	if _anchor_mask == ALL_THREE:
		_phase = PHASE_KNOTS
	_accept_transition(command, facts, true)
	return _result(true, "accepted", peer_id, int(command.nonce))


func _expose(command: Dictionary, facts: Dictionary) -> Dictionary:
	if _phase != PHASE_KNOTS or _anchor_mask != ALL_THREE:
		return _result(false, "wrong_phase")
	var index := _index_for(command.get("knot_id", command.get("target_id", "")), KNOT_IDS)
	if index < 0 or (_knot_mask & (1 << index)) != 0:
		return _result(false, "bad_knot")
	_reel_nonce += 1
	_active_knot_id = String(KNOT_IDS[index])
	_reel_expires_at_ms = int(facts.get("now_ms", 0)) + REEL_WINDOW_MS
	_phase = PHASE_REELING
	_accept_transition(command, facts, false)
	return _result(true, "accepted").merged({"active_knot_id": _active_knot_id, "reel_nonce": _reel_nonce}, true)


func _tick(command: Dictionary, facts: Dictionary) -> Dictionary:
	if _phase != PHASE_REELING:
		return _result(true, "accepted")
	if int(facts.get("now_ms", command.get("now_ms", 0))) < _reel_expires_at_ms:
		return _result(true, "accepted")
	_phase = PHASE_KNOTS
	_active_knot_id = ""
	_accept_transition(command, facts, false)
	return _result(true, "expired")


func _mark(peer_id: int, command: Dictionary, facts: Dictionary) -> Dictionary:
	var nonce := int(command.nonce)
	# Focus is owner-local under party trust.  These attestations are injected by
	# the owner/transport adapter; no player resource is read or mutated here.
	if not bool(facts.get("entitled", false)):
		return _result(false, "not_entitled", peer_id, nonce)
	if not bool(facts.get("focus_reserved", false)):
		return _result(false, "focus_not_reserved", peer_id, nonce)
	if not bool(facts.get("player_alive", false)):
		return _result(false, "player_dead", peer_id, nonce)
	if not bool(facts.get("target_exists", false)):
		return _result(false, "target_missing", peer_id, nonce)
	if not bool(facts.get("target_reeling", false)):
		return _result(false, "target_not_reeling", peer_id, nonce)
	if _phase != PHASE_REELING:
		return _result(false, "wrong_phase", peer_id, nonce)
	var now_ms := int(facts.get("now_ms", 0))
	if now_ms >= _reel_expires_at_ms:
		return _result(false, "reel_expired", peer_id, nonce)
	if String(command.get("knot_id", command.get("target_id", ""))) != _active_knot_id:
		return _result(false, "target_mismatch", peer_id, nonce)
	if int(command.get("reel_nonce", -1)) != _reel_nonce:
		return _result(false, "reel_nonce_mismatch", peer_id, nonce)
	if not bool(facts.get("in_range", false)):
		return _result(false, "out_of_range", peer_id, nonce)
	if not bool(facts.get("has_line_of_sight", false)):
		return _result(false, "no_line_of_sight", peer_id, nonce)
	var ledger := _ledger(peer_id)
	if now_ms < int(ledger.get("cooldown_until_ms", 0)):
		return _result(false, "cooldown", peer_id, nonce)
	var index := _index_for(_active_knot_id, KNOT_IDS)
	if index < 0:
		return _result(false, "bad_knot", peer_id, nonce)
	_knot_mask |= 1 << index
	ledger["cooldown_until_ms"] = now_ms + MARK_COOLDOWN_MS
	_peer_ledgers[peer_id] = ledger
	_phase = PHASE_NAMING if _knot_mask == ALL_THREE else PHASE_KNOTS
	_active_knot_id = ""
	_accept_transition(command, facts, true)
	var receipt := _result(true, "accepted", peer_id, nonce)
	receipt["focus_spend"] = MARK_COST
	receipt["focus_delta"] = -MARK_COST
	receipt["spend_receipt"] = {"resource": "focus", "amount": MARK_COST, "nonce": nonce}
	return receipt


func _name(peer_id: int, command: Dictionary, facts: Dictionary) -> Dictionary:
	var nonce := int(command.nonce)
	if not bool(facts.get("is_host", false)):
		return _result(false, "host_only", peer_id, nonce)
	var choice := String(command.get("road_name_id", command.get("name_id", "")))
	# A failed durable adapter call leaves the accepted effect pending. The host
	# may retry that exact choice; a different button can never overwrite it.
	if _phase == PHASE_SETTLING:
		if choice != String(_pending_effect.get("road_name_id", "")):
			return _result(false, "road_name_mismatch", peer_id, nonce)
		return _result(true, "pending_replay", peer_id, nonce).merged(
			{"pending_effect": _pending_effect.duplicate(true)}, true)
	if _phase != PHASE_NAMING or _knot_mask != ALL_THREE:
		return _result(false, "wrong_phase", peer_id, nonce)
	if not ROAD_CHOICES.has(choice):
		return _result(false, "bad_road_name", peer_id, nonce)
	_pending_effect = {"effect_id": "%s:%s:%d" % [chart_instance_id, attempt_id, _revision + 1],
		"road_name_id": choice, "chart_instance_id": chart_instance_id, "attempt_id": attempt_id}
	_phase = PHASE_SETTLING
	_accept_transition(command, facts, true)
	return _result(true, "accepted", peer_id, nonce).merged({"pending_effect": _pending_effect.duplicate(true)}, true)


func _settlement_result(command: Dictionary, facts: Dictionary) -> Dictionary:
	if _phase == PHASE_SETTLED:
		return _result(false, "already_settled")
	if _phase != PHASE_SETTLING or _pending_effect.is_empty():
		return _result(false, "wrong_phase")
	if String(command.get("effect_id", "")) != String(_pending_effect.effect_id):
		return _result(false, "effect_mismatch")
	if String(command.get("road_name_id", "")) != String(_pending_effect.road_name_id):
		return _result(false, "road_name_mismatch")
	if not bool(command.get("ok", command.get("changed", false))):
		return _result(false, "settlement_failed")
	_phase = PHASE_SETTLED
	_road_name_id = String(_pending_effect.road_name_id)
	_pending_effect = {}
	_accept_transition(command, facts, false)
	return _result(true, "accepted")


func _reset_for_retry(command: Dictionary, facts: Dictionary) -> Dictionary:
	if _phase == PHASE_SETTLED:
		return _result(false, "already_settled")
	_phase = PHASE_GNAWING
	_anchor_mask = 0
	_knot_mask = 0
	_active_knot_id = ""
	_reel_nonce = 0
	_reel_expires_at_ms = 0
	_pending_effect = {}
	_road_name_id = ""
	# Peer receipt/high-water/cooldown ledgers intentionally survive. A wipe
	# cannot make an accepted Mark free or strand a dropped acknowledgement.
	_accept_transition(command, facts, false)
	return _result(true, "reset")


func _trusted_identity(facts: Dictionary) -> bool:
	return bool(facts.get("trusted", false)) and bool(facts.get("world_ready", false)) \
		and String(facts.get("chart_instance_id", "")) == chart_instance_id \
		and String(facts.get("attempt_id", "")) == attempt_id


func _player_identity(facts: Dictionary, _peer_id: int) -> bool:
	return bool(facts.get("world_ready", false)) \
		and String(facts.get("chart_instance_id", "")) == chart_instance_id \
		and String(facts.get("attempt_id", "")) == attempt_id


func _ledger(peer_id: int) -> Dictionary:
	if not _peer_ledgers.has(peer_id):
		_peer_ledgers[peer_id] = {"high_water": 0, "receipts": {}, "latest": {}, "cooldown_until_ms": 0}
	return _peer_ledgers[peer_id] as Dictionary


func _remember(peer_id: int, nonce: int, result: Dictionary) -> Dictionary:
	var out := result.duplicate(true)
	var ledger := _ledger(peer_id)
	var receipts := ledger.get("receipts", {}) as Dictionary
	receipts[nonce] = out.duplicate(true)
	if receipts.size() > RECEIPT_LIMIT:
		var keys := receipts.keys()
		keys.sort()
		receipts.erase(keys[0])
	ledger["receipts"] = receipts
	ledger["high_water"] = maxi(int(ledger.get("high_water", 0)), nonce)
	ledger["latest"] = out.duplicate(true)
	_peer_ledgers[peer_id] = ledger
	_revision += 1
	return out


func _accept_transition(command: Dictionary, facts: Dictionary, player: bool) -> void:
	_revision += 1
	var item := {"command": command.duplicate(true), "facts": facts.duplicate(true)}
	_audit.append(item)
	if _audit.size() > AUDIT_LIMIT:
		_audit.pop_front()
	if player:
		_accepted_transitions.append(item)
	else:
		# Trusted steps are needed to reproduce the reducer too; they are private
		# audit facts, not player transitions.
		_accepted_transitions.append(item)


func _result(accepted: bool, reason: String, peer_id: int = 0, nonce: int = 0) -> Dictionary:
	return {"accepted": accepted, "reason": reason, "peer_id": peer_id, "nonce": nonce,
		"duplicate": false, "focus_spend": 0, "focus_delta": 0}


func _index_for(raw, ids: Array) -> int:
	if raw is int:
		var number := int(raw)
		return number if number >= 0 and number < ids.size() else -1
	var value := String(raw)
	var index := ids.find(value)
	if index >= 0:
		return index
	# Adapters sometimes carry 1-based authored object IDs.
	if value.is_valid_int():
		var number := int(value)
		if number >= 1 and number <= ids.size():
			return number - 1
	return -1


func _valid_snapshot(raw: Dictionary) -> bool:
	if String(raw.get("schema", "")) != "knot_eater_rules/v1" \
		or String(raw.get("chart_instance_id", "")) != chart_instance_id \
		or String(raw.get("attempt_id", "")) != attempt_id:
		return false
	var phase := String(raw.get("phase", ""))
	var anchors := int(raw.get("anchor_mask", -1))
	var knots := int(raw.get("knot_mask", -1))
	var active := String(raw.get("active_knot_id", ""))
	var reel_nonce := int(raw.get("reel_nonce", -1))
	if int(raw.get("revision", -1)) < 0 or phase not in PHASES or anchors < 0 or anchors > ALL_THREE or knots < 0 or knots > ALL_THREE or reel_nonce < 0:
		return false
	if phase in [PHASE_KNOTS, PHASE_REELING, PHASE_NAMING, PHASE_SETTLING, PHASE_SETTLED] and anchors != ALL_THREE:
		return false
	if phase == PHASE_GNAWING and (anchors != 0 or knots != 0):
		return false
	if phase == PHASE_ANCHORS and knots != 0:
		return false
	if phase == PHASE_REELING:
		var telegraph = raw.get("telegraph", {})
		if not telegraph is Dictionary \
				or int((telegraph as Dictionary).get("remaining_ms", -1)) < 0 \
				or not KNOT_IDS.has(active) \
				or (knots & (1 << KNOT_IDS.find(active))) != 0 \
				or reel_nonce <= 0 \
				or int(raw.get("reel_expires_at_ms", -1)) < 0:
			return false
	elif not active.is_empty():
		return false
	if phase in [PHASE_NAMING, PHASE_SETTLING, PHASE_SETTLED] and knots != ALL_THREE:
		return false
	var pending = raw.get("pending_effect", {})
	if not (pending is Dictionary):
		return false
	if phase == PHASE_SETTLING:
		if String((pending as Dictionary).get("effect_id", "")).is_empty() or not ROAD_CHOICES.has(String((pending as Dictionary).get("road_name_id", ""))):
			return false
	elif not (pending as Dictionary).is_empty():
		return false
	var road := String(raw.get("road_name_id", ""))
	if phase == PHASE_SETTLED:
		return ROAD_CHOICES.has(road)
	return road.is_empty()
