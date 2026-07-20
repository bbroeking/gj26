class_name HearthGiantEncounter
extends Node3D

# Narrow, host-authoritative adapter for Fire's non-lethal boss interaction.
# It deliberately does not know about campaign settlement, inventory, charts,
# or refunds.  The World/Game seam supplies the immutable chart/attempt pair
# and listens to `giant_banked` only after it has finished its own escrow work.

signal chain_banked(phase_index: int, chain_id: String)
signal chain_request_rejected(reason: String)
signal recoverable_hazard(chain_id: String, damage: int)
signal giant_banked
signal snapshot_applied(snapshot_nonce: int)
# Guest-only presentation seam.  It deliberately carries no settlement data:
# the host already committed the run, while a late join merely needs the arena
# gates, boss bar, and exit Waystone to agree with the kneeling snapshot.
signal settled_snapshot_applied

const CHAIN_ORDER := ["hollow_link", "braided_link", "knot_link"]
# PlayerController's 1.5 m scanner overlaps the chain's 1.25 m interaction
# area at up to 2.75 m. Keep host authority just outside that visible envelope
# so a rendered prompt can never invite an interaction the host rejects.
const INTERACT_RANGE := 2.8
const WRONG_CHAIN_DAMAGE := 4

var giant: Node3D = null
var chains: Dictionary = {} # chain id -> HearthChain node
var chart_instance := ""
var attempt_id := ""
var bank_mask := 0
var settled := false
var current_telegraph := {"kind": "", "nonce": 0, "remaining": 0.0}
var _snapshot_nonce := 0
var _last_applied_snapshot_nonce := -1
var _last_applied_telegraph_nonce := -1
var _guest_inert := false
var _guest_world_ready := false
# Peer ids which have completed the World-ready handshake for this exact
# controller.  Host mutations are sent only to this set, so a pre-ready guest
# cannot drop a state update before it has built its Giant, chains, and gates.
var _world_ready_peers: Dictionary = {}


func _ready() -> void:
	if not multiplayer.peer_disconnected.is_connected(_on_world_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_world_peer_disconnected)


func configure(p_giant: Node3D, p_chains: Array) -> void:
	giant = p_giant
	chains.clear()
	for i in p_chains.size():
		var chain: Node3D = p_chains[i] as Node3D
		if chain == null:
			continue
		var id := String(chain.get("chain_id"))
		if id.is_empty() and i < CHAIN_ORDER.size():
			id = String(CHAIN_ORDER[i])
		chain.call("configure", id)
		if chain.has_method("set_encounter"):
			chain.call("set_encounter", self)
		chain.call("set_chain_state", "sealed")
		chains[id] = chain
	if giant != null and giant.has_signal("heat_floor_reached") \
		and not giant.is_connected("heat_floor_reached", _on_heat_floor_reached):
		giant.connect("heat_floor_reached", _on_heat_floor_reached)
	if giant != null and giant.has_signal("aggroed") \
		and not giant.is_connected("aggroed", _on_giant_aggroed):
		giant.connect("aggroed", _on_giant_aggroed)


func begin_attempt(p_chart_instance: String, p_attempt_id: String) -> bool:
	if p_chart_instance.is_empty() or p_attempt_id.is_empty():
		return false
	chart_instance = p_chart_instance
	attempt_id = p_attempt_id
	bank_mask = 0
	settled = false
	current_telegraph = {"kind": "", "nonce": 0, "remaining": 0.0}
	_snapshot_nonce = 0
	_world_ready_peers.clear()
	for id in chains:
		(chains[id] as Node).call("set_chain_state", "sealed")
	return true


func reset_for_retry() -> void:
	bank_mask = 0
	settled = false
	current_telegraph = {"kind": "", "nonce": 0, "remaining": 0.0}
	if giant != null and giant.has_method("reset_fight"):
		giant.call("reset_fight")
	for id in chains:
		(chains[id] as Node).call("set_chain_state", "sealed")
	_publish_snapshot()


func begin_guest_world_ready(p_chart_instance: String, p_attempt_id: String) -> void:
	# Fail closed: a guest's local encounter is inert until the exact host
	# identity has been acknowledged with a complete snapshot.
	chart_instance = p_chart_instance
	attempt_id = p_attempt_id
	_guest_world_ready = true
	_guest_inert = true
	_last_applied_snapshot_nonce = -1
	_last_applied_telegraph_nonce = -1
	bank_mask = 0
	settled = false
	current_telegraph = {"kind": "", "nonce": 0, "remaining": 0.0}


# World calls this only after its local scene graph has finished constructing.
# In a live session the request contains identity only; the host responds with
# the full authoritative snapshot.  Offline callers receive the same snapshot
# through `snapshot_for_world`, which keeps the transport optional in tests.
func report_world_ready(p_chart_instance: String, p_attempt_id: String) -> Dictionary:
	if _host_authority():
		return world_ready_snapshot_for_peer(multiplayer.get_unique_id(), p_chart_instance, p_attempt_id)
	begin_guest_world_ready(p_chart_instance, p_attempt_id)
	report_world_ready_rpc.rpc_id(1, p_chart_instance, p_attempt_id)
	return {}


@rpc("any_peer", "call_remote", "reliable")
func report_world_ready_rpc(p_chart_instance: String, p_attempt_id: String) -> void:
	if not _host_authority():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	var snapshot := world_ready_snapshot_for_peer(peer_id, p_chart_instance, p_attempt_id)
	if not snapshot.is_empty():
		receive_world_snapshot.rpc_id(peer_id, snapshot)


func world_ready_snapshot_for_peer(_peer_id: int, p_chart_instance: String,
		p_attempt_id: String) -> Dictionary:
	if not _host_authority() or _peer_id <= 0 or chart_instance.is_empty() \
			or attempt_id.is_empty() or p_chart_instance != chart_instance \
			or p_attempt_id != attempt_id:
		return {}
	_world_ready_peers[_peer_id] = true
	return snapshot_for_world()


@rpc("authority", "call_remote", "reliable")
func receive_world_snapshot(snapshot: Dictionary) -> void:
	apply_world_snapshot(snapshot)


func is_guest_inert() -> bool:
	return _guest_inert


func _on_heat_floor_reached(phase_index: int, _floor_hp: int) -> void:
	if not _host_authority():
		return
	var expected := _expected_chain_id()
	if expected.is_empty():
		return
	for i in CHAIN_ORDER.size():
		var id := String(CHAIN_ORDER[i])
		var state := "banked" if bank_mask & (1 << i) != 0 else \
			"ready" if id == expected else "sealed"
		if chains.has(id):
			(chains[id] as Node).call("set_chain_state", state)
	_publish_snapshot()


func _on_giant_aggroed() -> void:
	if _guest_world_ready or not _host_authority() or giant == null:
		return
	var target = giant.get("_player")
	if target is Node:
		giant.set("aggro_peer_id", (target as Node).get_multiplayer_authority())
	_publish_snapshot()


func _expected_chain_id() -> String:
	var phase := int(giant.get("heat_phase")) if giant != null else 0
	if phase < 1 or phase > CHAIN_ORDER.size():
		return ""
	return String(CHAIN_ORDER[phase - 1])


func request_chain_bank(chain_id: String, claimed_chart: String, claimed_attempt: String,
		requester: Node3D = null) -> bool:
	if _guest_inert:
		chain_request_rejected.emit("guest_inert")
		return false
	if _host_authority():
		if _net_active():
			return _host_validate_request_for_peer(chain_id, claimed_chart, claimed_attempt,
				multiplayer.get_unique_id())
		return _host_validate_and_commit(chain_id, claimed_chart, claimed_attempt, requester)
	request_chain_bank_rpc.rpc_id(1, chain_id, claimed_chart, claimed_attempt)
	return false


@rpc("any_peer", "call_remote", "reliable")
func request_chain_bank_rpc(chain_id: String, claimed_chart: String, claimed_attempt: String) -> void:
	if _host_authority():
		_host_validate_request_for_peer(chain_id, claimed_chart, claimed_attempt,
			multiplayer.get_remote_sender_id())


func _host_validate_request_for_peer(chain_id: String, claimed_chart: String,
		claimed_attempt: String, peer_id: int) -> bool:
	if not _peer_ready_for_authority(peer_id):
		return _reject("world_not_ready")
	return _host_validate_and_commit(chain_id, claimed_chart, claimed_attempt,
		_host_player_for_peer(peer_id))


func _peer_ready_for_authority(peer_id: int) -> bool:
	# Local/offline host actions do not use a handshake. Every non-host chain
	# sender does: a raw packet before the matching World-ready snapshot remains
	# inert even if a test invokes the host validator directly.
	if peer_id == multiplayer.get_unique_id():
		return true
	return peer_id > 0 and bool(_world_ready_peers.get(peer_id, false))


func _host_validate_and_commit(chain_id: String, claimed_chart: String, claimed_attempt: String,
		requester: Node3D) -> bool:
	if not _host_authority():
		return _reject("not_host")
	if settled or giant == null:
		return _reject("settled")
	if claimed_chart != chart_instance or claimed_attempt != attempt_id:
		return _reject("wrong_attempt")
	if not bool(giant.get("heat_shielded")):
		return _reject("no_heat_phase")
	var expected := _expected_chain_id()
	if expected.is_empty():
		return _reject("no_expected_chain")
	var chain: Node3D = chains.get(chain_id) as Node3D
	if chain == null:
		return _reject("unknown_chain")
	if requester == null or requester.global_position.distance_to(chain.global_position) > INTERACT_RANGE:
		return _reject("too_far")
	if chain_id != expected:
		# A wrong chain is intentionally recoverable: no bank bit, phase, or
		# prior result changes.  The caller may immediately retry the expected one.
		recoverable_hazard.emit(chain_id, WRONG_CHAIN_DAMAGE)
		_apply_modest_hazard(requester)
		_publish_snapshot()
		return _reject("wrong_chain")
	var bit: int = 1 << (int(giant.get("heat_phase")) - 1)
	if bank_mask & bit != 0 or String(chain.get("state")) == "banked":
		return _reject("already_banked")
	if not bool(giant.call("release_heat_shield", chain_id)):
		return _reject("shield_release_failed")
	bank_mask |= bit
	chain.call("set_chain_state", "banked")
	chain_banked.emit(int(giant.get("heat_phase")), chain_id)
	if int(giant.get("heat_phase")) == 3:
		settled = bool(giant.call("kneel_and_bank"))
		if settled:
			giant_banked.emit()
	_publish_snapshot()
	return true


func _apply_modest_hazard(requester: Node3D) -> void:
	if requester.has_method("take_damage"):
		requester.call("take_damage", WRONG_CHAIN_DAMAGE, Vector3.ZERO)
	else:
		requester.set_meta("hearth_chain_hazard", WRONG_CHAIN_DAMAGE)


func _reject(reason: String) -> bool:
	chain_request_rejected.emit(reason)
	return false


func set_telegraph(kind: String, nonce: int, remaining: float) -> bool:
	if not _host_authority() or nonce <= int(current_telegraph.get("nonce", 0)):
		return false
	current_telegraph = {"kind": kind, "nonce": nonce, "remaining": maxf(0.0, remaining)}
	_publish_snapshot()
	return true


func advance_telegraph(delta: float) -> void:
	if not _host_authority() or String(current_telegraph.get("kind", "")).is_empty():
		return
	current_telegraph.remaining = maxf(0.0, float(current_telegraph.remaining) - maxf(0.0, delta))
	if float(current_telegraph.remaining) <= 0.0:
		current_telegraph.kind = ""
		_publish_snapshot()


func snapshot_for_world() -> Dictionary:
	return {
		"chart_instance": chart_instance,
		"attempt_id": attempt_id,
		"snapshot_nonce": _snapshot_nonce,
		"boss": giant.call("encounter_snapshot") if giant != null else {},
		"heat_phase": int(giant.get("heat_phase")) if giant != null else 0,
		"bank_mask": bank_mask,
		"chain_order": CHAIN_ORDER.duplicate(),
		"chain_states": _chain_states(),
		"shield": bool(giant.get("heat_shielded")) if giant != null else false,
		"telegraph": current_telegraph.duplicate(true),
		"settled": settled,
		"kneeling": bool(giant.get("kneeling")) if giant != null else false,
	}


func apply_world_snapshot(snapshot: Dictionary) -> bool:
	if not _guest_world_ready:
		return false
	if String(snapshot.get("chart_instance", "")) != chart_instance \
			or String(snapshot.get("attempt_id", "")) != attempt_id:
		return false
	if not _valid_world_snapshot(snapshot):
		return false
	var nonce := int(snapshot.get("snapshot_nonce", -1))
	if nonce < _last_applied_snapshot_nonce:
		return false
	if nonce == _last_applied_snapshot_nonce:
		return true # Reliable replay is an idempotent no-op, not a state rewind.
	var was_settled := settled
	var tele: Dictionary = snapshot.get("telegraph", {}) as Dictionary
	var tele_nonce := int(tele.get("nonce", 0))
	if tele_nonce < _last_applied_telegraph_nonce:
		# A snapshot can still be current while its attack visual is stale; keep
		# the latest visual rather than rewinding it.
		tele = current_telegraph.duplicate(true)
	else:
		_last_applied_telegraph_nonce = tele_nonce
		current_telegraph = tele.duplicate(true)
	var order: Array = snapshot.get("chain_order", []) as Array
	if order != CHAIN_ORDER:
		return false
	bank_mask = int(snapshot.get("bank_mask", bank_mask))
	settled = bool(snapshot.get("settled", false))
	var states: Dictionary = snapshot.get("chain_states", {}) as Dictionary
	for id in chains:
		(chains[id] as Node).call("set_chain_state", String(states.get(id, "sealed")))
	if giant != null:
		giant.call("apply_encounter_snapshot", snapshot.get("boss", {}) as Dictionary)
	_guest_inert = false
	_last_applied_snapshot_nonce = nonce
	snapshot_applied.emit(nonce)
	if settled and not was_settled:
		settled_snapshot_applied.emit()
	return true


func _valid_world_snapshot(snapshot: Dictionary) -> bool:
	var nonce := int(snapshot.get("snapshot_nonce", -1))
	if nonce < 0:
		return false
	var order: Array = snapshot.get("chain_order", []) as Array
	if order != CHAIN_ORDER:
		return false
	var boss: Dictionary = snapshot.get("boss", {}) as Dictionary
	if boss.is_empty() or int(boss.get("hp_max", 0)) < 1:
		return false
	var phase := int(snapshot.get("heat_phase", -1))
	var shield := bool(snapshot.get("shield", false))
	var kneeling := bool(snapshot.get("kneeling", false))
	var is_settled := bool(snapshot.get("settled", false))
	if phase < 0 or phase > CHAIN_ORDER.size() \
			or int(boss.get("heat_phase", -1)) != phase \
			or bool(boss.get("heat_shielded", false)) != shield \
			or bool(boss.get("kneeling", false)) != kneeling \
			or bool(boss.get("banked_fire", false)) != is_settled:
		return false
	if kneeling != is_settled or (kneeling and (phase != 3 or shield)):
		return false
	var mask := int(snapshot.get("bank_mask", -1))
	if mask < 0 or mask > 7:
		return false
	var bank_count := 0
	for i in CHAIN_ORDER.size():
		if mask & (1 << i) != 0:
			if i != bank_count: # The immutable order is a prefix, never a set.
				return false
			bank_count += 1
	if bank_count > phase:
		return false
	if shield and (phase < 1 or bank_count != phase - 1):
		return false
	if not shield and bank_count != phase:
		return false
	var states: Dictionary = snapshot.get("chain_states", {}) as Dictionary
	if states.size() != CHAIN_ORDER.size():
		return false
	for i in CHAIN_ORDER.size():
		var id := String(CHAIN_ORDER[i])
		var expected := "banked" if i < bank_count else \
			"ready" if shield and i == phase - 1 else "sealed"
		if String(states.get(id, "")) != expected:
			return false
	var tele: Dictionary = snapshot.get("telegraph", {}) as Dictionary
	if int(tele.get("nonce", -1)) < 0 or float(tele.get("remaining", -1.0)) < 0.0:
		return false
	return true


func _publish_snapshot() -> void:
	if not _host_authority():
		return
	_snapshot_nonce += 1
	if not _net_active():
		return
	var net := get_node_or_null("/root/NetGame")
	var roster: Dictionary = net.get("players") as Dictionary if net != null else {}
	var snapshot := snapshot_for_world()
	for raw_peer in _world_ready_peers.keys():
		var peer_id := int(raw_peer)
		if peer_id <= 0 or peer_id == multiplayer.get_unique_id():
			continue
		if not roster.has(peer_id):
			_world_ready_peers.erase(peer_id)
			continue
		receive_world_snapshot.rpc_id(peer_id, snapshot)


func _on_world_peer_disconnected(peer_id: int) -> void:
	_world_ready_peers.erase(peer_id)


func _chain_states() -> Dictionary:
	var out := {}
	for id in chains:
		out[id] = String((chains[id] as Node).get("state"))
	return out


func _host_player_for_peer(peer_id: int) -> Node3D:
	if peer_id <= 0:
		return null
	for player in get_tree().get_nodes_in_group("player"):
		if player is Node3D and (player as Node).get_multiplayer_authority() == peer_id:
			return player as Node3D
	return null


func _host_authority() -> bool:
	var net := get_node_or_null("/root/NetGame")
	return net == null or not bool(net.get("active")) or multiplayer.is_server()


func _net_active() -> bool:
	var net := get_node_or_null("/root/NetGame")
	return net != null and bool(net.get("active"))
