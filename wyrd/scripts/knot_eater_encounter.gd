class_name KnotEaterEncounter
extends Node3D

# Scene/transport adapter around the pure KnotEaterRules.  This is the only
# player-facing seam: callers may express an intent but cannot supply a peer,
# target, Chart identity, positions, line of sight, or settlement facts.
const Rules := preload("res://scripts/knot_eater_rules.gd")
const NamingPanel := preload("res://scripts/ui/road_naming_panel.gd")
const MARK_RANGE := 12.0
const ANCHOR_RANGE := 3.2
const GNAWING_SECONDS := 6.0

signal snapshot_applied
signal settled
var rules: RefCounted
var boss: Node3D
var anchors: Dictionary = {}
var knots: Dictionary = {}
var chart_instance_id := ""
var attempt_id := ""
var _ready_peers: Dictionary = {}
var _intent_nonces: Dictionary = {}
var _gate_receipts: Dictionary = {} # peer -> reservation-bearing setup rejection
var _last_snapshot_revision := -1
var _mirror_mark_ready := false
var _mirror_mark_cooldown_left_ms := 0
var _gnawing_left := -1.0
var _exposure_retry_left := 0.0
var _settled_emitted := false
var _reconnect_reconcile_pending := false
var _resubmitted_reservations: Dictionary = {}

func _ready() -> void:
	add_to_group("knot_eater_encounter")
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	var net := get_node_or_null("/root/NetGame")
	if net != null and net.has_signal("peer_rebound") \
			and not net.peer_rebound.is_connected(_on_peer_rebound):
		net.peer_rebound.connect(_on_peer_rebound)
	if net != null and net.has_signal("reconnecting") \
			and not net.reconnecting.is_connected(_on_reconnecting):
		net.reconnecting.connect(_on_reconnecting)

func configure(p_boss: Node3D, p_anchors: Array, p_knots: Array) -> void:
	boss = p_boss
	if boss != null and boss.has_signal("aggroed") and not boss.aggroed.is_connected(_on_boss_aggroed):
		boss.aggroed.connect(_on_boss_aggroed)
	anchors.clear()
	knots.clear()
	for node in p_anchors:
		if node != null:
			anchors[str(node.get("anchor_id"))] = node
	for node in p_knots:
		if node != null:
			knots[str(node.get("knot_id"))] = node

func begin_attempt(chart_id: String, attempt: String) -> bool:
	if chart_id.is_empty() or attempt.is_empty():
		return false
	chart_instance_id = chart_id
	attempt_id = attempt
	rules = Rules.new(chart_id, attempt)
	_ready_peers.clear()
	_intent_nonces.clear()
	_gate_receipts.clear()
	_last_snapshot_revision = -1
	_mirror_mark_ready = false
	_mirror_mark_cooldown_left_ms = 0
	_gnawing_left = -1.0
	_exposure_retry_left = 0.0
	_settled_emitted = false
	_reconnect_reconcile_pending = false
	_resubmitted_reservations.clear()
	_ready_peers[multiplayer.get_unique_id()] = true
	_refresh()
	return true

func view() -> Dictionary:
	if rules == null:
		return {}
	if _host():
		return _snapshot_for_peer(multiplayer.get_unique_id())
	var model: Dictionary = rules.view(Time.get_ticks_msec())
	model["mark_ready"] = _mirror_mark_ready
	model["mark_cooldown_left_ms"] = _mirror_mark_cooldown_left_ms
	return model

func press(verb: StringName, subject_id: StringName) -> Dictionary:
	# Only player intents cross this boundary. Survival and exposure are trusted
	# host scene transitions, never packets a guest can manufacture.
	if String(verb) not in ["unbind", "mark", "name"]:
		return {"accepted": false, "reason": "private_verb"}
	if rules == null:
		return _mark_gate_receipt("not_ready", {}, _local_player()) if String(verb) == "mark" \
			else {"accepted": false, "reason": "not_ready"}
	if _net_active() and not _host():
		var attestation := {}
		if String(verb) == "mark":
			var owner := _local_player()
			var pending: Dictionary = owner.call("wayfinders_mark_pending") if owner != null \
				and owner.has_method("wayfinders_mark_pending") else {}
			attestation = {"nonce": int(pending.get("nonce", 0)),
				"entitled": bool(pending.get("party_trust_entitlement", false)),
				"focus_reserved": float(pending.get("reserved", 0.0)) >= 35.0}
		_press_request.rpc_id(1, String(verb), String(subject_id), attestation)
		return {}
	return _host_press(multiplayer.get_unique_id(), String(verb), String(subject_id), {})

@rpc("any_peer", "reliable")
func _press_request(verb: String, subject_id: String, attestation: Dictionary = {}) -> void:
	if not _host():
		return
	var sender := multiplayer.get_remote_sender_id()
	var receipt := _host_press(sender, verb, subject_id, attestation)
	_receive_receipt.rpc_id(sender, receipt)

@rpc("authority", "call_remote", "reliable")
func _receive_receipt(receipt: Dictionary) -> void:
	var reservation_nonce := int(receipt.get("reservation_nonce", 0))
	if reservation_nonce > 0:
		_resubmitted_reservations.erase(reservation_nonce)
	var player := _local_player()
	if player != null and player.has_method("apply_wayfinders_mark_receipt") \
			and (reservation_nonce > 0 \
				or String(receipt.get("kind", "")) == "mark" \
				or int(receipt.get("focus_spend", 0)) == Rules.MARK_COST):
		player.call("apply_wayfinders_mark_receipt", receipt)
	_refresh(receipt)

func _host_press(peer_id: int, verb: String, subject_id: String, attestation: Dictionary = {}) -> Dictionary:
	if not _host() or not bool(_ready_peers.get(peer_id, peer_id == multiplayer.get_unique_id())):
		if verb == "mark":
			return _remember_gate_receipt(peer_id,
				_mark_gate_receipt("world_not_ready", attestation))
		return {"accepted": false, "reason": "world_not_ready"}
	# Defense in depth for the any-peer RPC. Trusted survival, exposure, ticking,
	# and settlement completion are dispatched by this coordinator directly and
	# can never be selected by a packet body.
	if verb not in ["unbind", "mark", "name"]:
		return {"accepted": false, "reason": "private_verb"}
	var command := {"kind": verb, "peer_id": peer_id, "nonce": _next_nonce(peer_id)}
	var facts := _trusted_facts(peer_id)
	match verb:
		"unbind":
			var anchor = anchors.get(subject_id)
			var owner := _player_for_peer(peer_id)
			if anchor == null or not _in_anchor_range(owner, anchor) or not _has_line_of_sight(owner, anchor):
				return {"accepted": false, "reason": "anchor_unreachable"}
			command["anchor_id"] = subject_id
		"mark":
			var player := _player_for_peer(peer_id)
			var pending: Dictionary = attestation.duplicate(true) if not attestation.is_empty() else \
				(player.call("wayfinders_mark_pending") if player != null and player.has_method("wayfinders_mark_pending") else {})
			var reservation_nonce := int(pending.get("reservation_nonce", pending.get("nonce", 0)))
			if pending.is_empty() or reservation_nonce <= 0:
				return {"accepted": false, "reason": "focus_not_reserved", "kind": "mark"}
			# The encounter nonce orders every verb in one peer ledger. The owner
			# reservation nonce is a separate reconciliation key and survives in
			# peer-specific receipts/snapshots.
			command["reservation_nonce"] = reservation_nonce
			var model: Dictionary = rules.view(Time.get_ticks_msec())
			command["knot_id"] = String(model.get("active_knot_id", ""))
			command["reel_nonce"] = int(model.get("reel_nonce", 0))
			facts["entitled"] = bool(pending.get("party_trust_entitlement", pending.get("entitled", false)))
			facts["focus_reserved"] = float(pending.get("reserved", 0.0)) >= 35.0 or bool(pending.get("focus_reserved", false))
			facts["player_alive"] = player != null and not bool(player.get("dead"))
			facts["target_exists"] = knots.has(String(command.knot_id))
			facts["target_reeling"] = String(model.get("active_knot_id", "")) == String(command.knot_id)
			facts["in_range"] = _in_range(player, knots.get(String(command.knot_id)))
			facts["has_line_of_sight"] = _has_line_of_sight(player, knots.get(String(command.knot_id)))
		"name":
			command["road_name_id"] = subject_id
			facts["is_host"] = peer_id == multiplayer.get_unique_id()
	var receipt: Dictionary = rules.dispatch(command, facts)
	receipt["kind"] = verb
	# Mark bypasses PlayerController's generic cast transport.  Once the host
	# reducer accepts this exact intent, arm that host Player body's transient
	# Wayweaver mirror; rejected/late requests must never create an identity.
	if verb == "mark" and bool(receipt.get("accepted", false)):
		var mark_owner := _player_for_peer(peer_id)
		if mark_owner != null and mark_owner.has_method("arm_wayweaver_after_host_acceptance"):
			mark_owner.call("arm_wayweaver_after_host_acceptance", "WayfindersMark")
	if verb == "mark":
		_gate_receipts.erase(peer_id)
	if verb == "mark" and peer_id == multiplayer.get_unique_id():
		_receive_receipt(receipt)
	_refresh(receipt)
	if verb == "name" and bool(receipt.get("accepted", false)):
		_commit_settlement(receipt)
	return receipt

func _process(_delta: float) -> void:
	if rules == null or not _host():
		return
	if String(rules.view(Time.get_ticks_msec()).get("phase", "")) == Rules.PHASE_GNAWING and _gnawing_left >= 0.0:
		_gnawing_left -= _delta
		if _gnawing_left <= 0.0:
			_refresh(rules.dispatch({"kind": "survival"}, _trusted_facts()))
		return
	var tick: Dictionary = rules.dispatch({"kind": "tick"}, _trusted_facts())
	if String(tick.get("reason", "")) == "expired":
		_refresh(tick)
	if String(rules.view(Time.get_ticks_msec()).get("phase", "")) == Rules.PHASE_KNOTS:
		_exposure_retry_left -= _delta
		if _exposure_retry_left <= 0.0:
			_exposure_retry_left = 3.2
			for knot_id in Rules.KNOT_IDS:
				if (int(rules.view(Time.get_ticks_msec()).get("knot_mask", 0)) & (1 << Rules.KNOT_IDS.find(knot_id))) == 0:
					_refresh(rules.dispatch({"kind": "exposure", "knot_id": knot_id}, _trusted_facts()))
					break

func _refresh(_result: Dictionary = {}) -> void:
	if rules == null:
		return
	var model: Dictionary = rules.view(Time.get_ticks_msec())
	if boss != null and boss.has_method("set_ritual_pacified"):
		boss.call("set_ritual_pacified", String(model.phase) in [
			Rules.PHASE_NAMING, Rules.PHASE_SETTLING, Rules.PHASE_SETTLED])
	for id in anchors:
		if (anchors[id] as Node).has_method("set_state"):
			(anchors[id] as Node).call("set_state", "unbound" if int(model.anchor_mask) & (1 << Rules.ANCHOR_IDS.find(id)) else "bound")
	for id in knots:
		var bit := 1 << Rules.KNOT_IDS.find(id)
		var state := "marked" if int(model.knot_mask) & bit else "ready" if String(model.active_knot_id) == id else "sealed"
		if (knots[id] as Node).has_method("set_state"):
			(knots[id] as Node).call("set_state", state)
	if String(model.phase) == Rules.PHASE_NAMING and _host():
		_show_naming_panel()
	if _host():
		_publish()

func _show_naming_panel() -> void:
	if get_tree().current_scene == null or get_tree().current_scene.find_child("RoadNamingPanel", true, false) != null:
		return
	var panel: CanvasLayer = NamingPanel.new()
	panel.name = "RoadNamingPanel"
	panel.configure(self)
	get_tree().current_scene.add_child(panel)

func report_world_ready(chart_id: String, attempt: String) -> Dictionary:
	if _host():
		if chart_id != chart_instance_id or attempt != attempt_id: return {}
		_ready_peers[multiplayer.get_unique_id()] = true
		return _snapshot_for_peer(multiplayer.get_unique_id())
	_report_world_ready.rpc_id(1, chart_id, attempt)
	return {}

@rpc("any_peer", "reliable")
func _report_world_ready(chart_id: String, attempt: String) -> void:
	if not _host() or chart_id != chart_instance_id or attempt != attempt_id: return
	var peer := multiplayer.get_remote_sender_id()
	_ready_peers[peer] = true
	_receive_snapshot.rpc_id(peer, _snapshot_for_peer(peer))

@rpc("authority", "call_remote", "reliable")
func _receive_snapshot(snapshot: Dictionary) -> void:
	if rules == null:
		return
	var player := _local_player()
	var pending_before: Dictionary = {}
	if player != null and player.has_method("wayfinders_mark_pending"):
		pending_before = player.call("wayfinders_mark_pending")
	var receipt = snapshot.get("receipt", {})
	var matching_authoritative_receipt := receipt is Dictionary \
		and not (receipt as Dictionary).is_empty() \
		and int((receipt as Dictionary).get("reservation_nonce", 0)) > 0 \
		and int((receipt as Dictionary).get("reservation_nonce", 0)) \
			== int(pending_before.get("nonce", 0))
	var previous_model: Dictionary = rules.view(Time.get_ticks_msec())
	var was_settled := bool(previous_model.get("settled", false))
	var previous_phase := String(previous_model.get("phase", ""))
	if not rules.apply_snapshot(snapshot, Time.get_ticks_msec()):
		return
	_last_snapshot_revision = int(snapshot.get("revision", -1))
	_mirror_mark_ready = bool(snapshot.get("mark_ready", false))
	_mirror_mark_cooldown_left_ms = int(snapshot.get("mark_cooldown_left_ms", 0))
	if receipt is Dictionary and not (receipt as Dictionary).is_empty():
		_receive_receipt(receipt)
	else:
		_refresh()
	var reset_edge := previous_phase != Rules.PHASE_GNAWING \
		and String(rules.view(Time.get_ticks_msec()).get("phase", "")) == Rules.PHASE_GNAWING
	if reset_edge and player != null and player.has_method("wayfinders_mark_pending") \
			and not (player.call("wayfinders_mark_pending") as Dictionary).is_empty() \
			and player.has_method("cancel_wayfinders_mark"):
		# A matching accepted receipt was applied above. Anything still pending
		# belonged to the discarded ritual window and must release without spend.
		player.call("cancel_wayfinders_mark", "encounter_reset")
	if _reconnect_reconcile_pending and not matching_authoritative_receipt and player != null \
			and player.has_method("wayfinders_mark_pending"):
		var pending: Dictionary = player.call("wayfinders_mark_pending")
		if not pending.is_empty():
			var reservation_nonce := int(pending.get("nonce", 0))
			if not _resubmitted_reservations.has(reservation_nonce):
				_resubmitted_reservations[reservation_nonce] = true
				call_deferred("press", &"mark", &"")
	_reconnect_reconcile_pending = false
	if not was_settled and bool(rules.view(Time.get_ticks_msec()).get("settled", false)):
		_emit_settled_once()
	snapshot_applied.emit()

func _publish() -> void:
	if not _net_active(): return
	for raw_peer in _ready_peers.keys():
		var peer := int(raw_peer)
		if peer > 0 and peer != multiplayer.get_unique_id():
			_receive_snapshot.rpc_id(peer, _snapshot_for_peer(peer))

func _commit_settlement(receipt: Dictionary) -> void:
	var effect: Dictionary = receipt.get("pending_effect", {})
	var game := get_node_or_null("/root/Game")
	var result: Dictionary = game.call("resolve_unwritten_road_settlement", effect) if game != null \
		and game.has_method("resolve_unwritten_road_settlement") else {"ok": false}
	var final: Dictionary = rules.dispatch({"kind": "settlement_result", "effect_id": effect.get("effect_id", ""),
		"road_name_id": effect.get("road_name_id", ""), "ok": bool(result.get("ok", false)), "changed": bool(result.get("changed", false))}, _trusted_facts())
	_refresh(final)
	if bool(final.get("accepted", false)):
		_emit_settled_once()


func reset_for_retry() -> bool:
	if not _host() or rules == null or bool(rules.view().get("settled", false)):
		return false
	var result: Dictionary = rules.dispatch({"kind": "reset_for_retry"}, _trusted_facts())
	if not bool(result.get("accepted", false)):
		return false
	_gnawing_left = -1.0
	_exposure_retry_left = 0.0
	_settled_emitted = false
	if boss != null and boss.has_method("reset_fight"):
		boss.call("reset_fight")
	_reconcile_local_reset_reservation()
	_refresh(result)
	return true

func _trusted_facts(peer_id: int = 1) -> Dictionary:
	return {"trusted": true, "world_ready": bool(_ready_peers.get(peer_id, peer_id == multiplayer.get_unique_id())), "chart_instance_id": chart_instance_id, "attempt_id": attempt_id,
		"now_ms": Time.get_ticks_msec(), "sender_id": peer_id, "body_peer": peer_id}
func _next_nonce(peer: int) -> int:
	_intent_nonces[peer] = int(_intent_nonces.get(peer, 0)) + 1
	return int(_intent_nonces[peer])
func _snapshot_for_peer(peer: int) -> Dictionary:
	var snapshot: Dictionary = rules.snapshot_for_peer(peer, Time.get_ticks_msec())
	var gate := _gate_receipts.get(peer, {}) as Dictionary
	if gate.is_empty():
		return snapshot
	var authoritative := snapshot.get("receipt", {}) as Dictionary
	# An accepted authoritative Mark for this same reservation always outranks a
	# later setup rejection. Otherwise the newest reservation-bearing gate reply
	# must survive until this peer's ready snapshot.
	if bool(authoritative.get("accepted", false)) \
			and int(authoritative.get("reservation_nonce", 0)) \
			== int(gate.get("reservation_nonce", -1)):
		return snapshot
	snapshot["receipt"] = gate.duplicate(true)
	return snapshot
func _remember_gate_receipt(peer: int, receipt: Dictionary) -> Dictionary:
	var stored := receipt.duplicate(true)
	stored["peer_id"] = peer
	var reservation_nonce := int(stored.get("reservation_nonce", 0))
	if rules != null and reservation_nonce > 0:
		stored = rules.record_setup_rejection(peer, _next_nonce(peer),
			reservation_nonce, String(stored.get("reason", "world_not_ready")))
		stored["kind"] = "mark"
		return stored
	_gate_receipts[peer] = stored
	return stored
func _mark_gate_receipt(reason: String, attestation: Dictionary = {}, player: Node = null) -> Dictionary:
	var pending := attestation
	if pending.is_empty() and player != null and player.has_method("wayfinders_mark_pending"):
		pending = player.call("wayfinders_mark_pending")
	return {"accepted": false, "reason": reason, "kind": "mark",
		"reservation_nonce": int(pending.get("reservation_nonce", pending.get("nonce", 0))),
		"focus_spend": 0, "focus_delta": 0}
func _emit_settled_once() -> void:
	if _settled_emitted:
		return
	_settled_emitted = true
	settled.emit()
func _reconcile_local_reset_reservation() -> void:
	var player := _local_player()
	if player == null or not player.has_method("wayfinders_mark_pending"):
		return
	var pending: Dictionary = player.call("wayfinders_mark_pending")
	if pending.is_empty():
		return
	var snapshot := _snapshot_for_peer(multiplayer.get_unique_id())
	var receipt := snapshot.get("receipt", {}) as Dictionary
	if int(receipt.get("reservation_nonce", -1)) == int(pending.get("nonce", -2)):
		player.call("apply_wayfinders_mark_receipt", receipt)
	elif player.has_method("cancel_wayfinders_mark"):
		player.call("cancel_wayfinders_mark", "encounter_reset")
func _player_for_peer(peer: int) -> Node3D:
	for player in get_tree().get_nodes_in_group("player"):
		if player is Node3D and (player as Node).get_multiplayer_authority() == peer: return player
	return null
func _local_player() -> Node3D: return _player_for_peer(multiplayer.get_unique_id())
func _in_range(player: Node3D, target: Node) -> bool: return player != null and target is Node3D and player.global_position.distance_to((target as Node3D).global_position) <= MARK_RANGE
func _in_anchor_range(player: Node3D, target: Node) -> bool: return player != null and target is Node3D and player.global_position.distance_to((target as Node3D).global_position) <= ANCHOR_RANGE
func _has_line_of_sight(player: Node3D, target: Node) -> bool:
	if not _in_range(player, target): return false
	var query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP, (target as Node3D).global_position + Vector3.UP, 1)
	query.exclude = [player.get_rid()]
	if get_world_3d() == null: return true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var collider = hit.get("collider")
	return hit.is_empty() or collider == target or (collider is Node and target.is_ancestor_of(collider as Node))
func _on_boss_aggroed() -> void:
	if _host() and rules != null and String(rules.view(Time.get_ticks_msec()).get("phase", "")) == Rules.PHASE_GNAWING:
		_gnawing_left = GNAWING_SECONDS
func _host() -> bool:
	var net := get_node_or_null("/root/NetGame")
	return net == null or not bool(net.get("active")) or bool(net.is_host())
func _net_active() -> bool:
	var net := get_node_or_null("/root/NetGame")
	return net != null and bool(net.get("active"))
func _on_peer_disconnected(peer: int) -> void: _ready_peers.erase(peer)
func _on_peer_rebound(old_peer: int, new_peer: int, _session_player_id: String) -> void:
	if not _host() or rules == null or old_peer == new_peer:
		return
	if not rules.rebind_peer(old_peer, new_peer):
		return
	_ready_peers.erase(old_peer) # the new World/body must report ready itself.
	if _intent_nonces.has(old_peer):
		_intent_nonces[new_peer] = _intent_nonces[old_peer]
		_intent_nonces.erase(old_peer)
	if _gate_receipts.has(old_peer):
		var gate := (_gate_receipts[old_peer] as Dictionary).duplicate(true)
		gate["peer_id"] = new_peer
		_gate_receipts[new_peer] = gate
		_gate_receipts.erase(old_peer)
func _on_reconnecting(_attempt: int, _max_attempts: int) -> void:
	_reconnect_reconcile_pending = true
