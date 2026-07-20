class_name CinderboundVent
extends Node3D

# Host-only resolution for the Ashen Bough affix.  This module makes no
# campaign calls: an encounter may listen to its signals, but a vent never
# banks clues, changes a Chart, or touches settlement state.

signal vent_started(nonce: int, outcome: String)
signal vent_resolved(nonce: int, outcome: String)
signal focus_pickup_spawned(nonce: int, position: Vector3)
signal focus_pickup_cleared(nonce: int)
signal focus_claimed(nonce: int, peer_id: int, amount: float)
signal focus_pickup_claim_resolved(nonce: int, accepted: bool)
signal focus_request_rejected(reason: String)

const TELEGRAPH_SECONDS := 1.25
const TELEGRAPH_PIPS := 3
const EFFECT_RADIUS := 2.7
const PICKUP_RANGE := 2.25
const FOCUS_AMOUNT := 18.0
const GOOD_DAMAGE := 7
const BAD_DAMAGE := 5

var attempt_id := ""
var _next_nonce := 0
var active := false
var active_nonce := 0
var active_outcome := ""
var remaining := 0.0
var vent_position := Vector3.ZERO
var pickup := {} # { nonce, position, claimed }
var _nearby_enemies: Array = []
var _bad_target: Node3D = null
var _last_visual_nonce := -1
var _world_armed := false
var _world_outcome := ""
var _world_attempt := ""
var _last_broadcast_pip := -1
var _pip_meshes: Array = []
var _local_claim_results: Dictionary = {} # nonce -> true, owner-local only
var _last_claim_reason := ""
var _world_ready_peers: Dictionary = {}


func _ready() -> void:
	add_to_group("cinderbound_vent")
	_build_pips()
	if not multiplayer.peer_disconnected.is_connected(_on_world_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_world_peer_disconnected)
	set_process(true)


func arm_world(outcome: String, p_attempt_id: String, p_position: Vector3) -> bool:
	if outcome not in ["cinderbound", "cinders_rebuke"] or p_attempt_id == "":
		return false
	_world_outcome = outcome
	_world_attempt = p_attempt_id
	attempt_id = p_attempt_id
	vent_position = p_position
	global_position = p_position
	_world_armed = true
	return true


# Like the Giant encounter, Cinder waits for the locally built World to report
# ready. This lets a late join reconstruct an already-resolved good vent and
# its still-claimable nonce pickup without ever replaying damage or Focus.
func report_world_ready(p_attempt_id: String) -> Dictionary:
	if _host_authority():
		return world_ready_visual_for_peer(multiplayer.get_unique_id(), p_attempt_id)
	world_ready_visual_rpc.rpc_id(1, p_attempt_id)
	return {}


@rpc("any_peer", "call_remote", "reliable")
func world_ready_visual_rpc(p_attempt_id: String) -> void:
	if not _host_authority():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	var view := world_ready_visual_for_peer(peer_id, p_attempt_id)
	if not view.is_empty():
		receive_visual_snapshot.rpc_id(peer_id, view)


func world_ready_visual_for_peer(peer_id: int, p_attempt_id: String) -> Dictionary:
	if not _host_authority() or peer_id <= 0 or _world_attempt.is_empty() \
			or p_attempt_id != _world_attempt:
		return {}
	_world_ready_peers[peer_id] = true
	return telegraph_view()


func _process(delta: float) -> void:
	if _host_authority() and _world_armed and not active and pickup.is_empty():
		var target := _nearest_player(3.2)
		if target != null:
			var nearby: Array = []
			for enemy in get_tree().get_nodes_in_group("enemy"):
				if enemy is Node3D and (enemy as Node3D).global_position.distance_to(global_position) \
						<= EFFECT_RADIUS:
					nearby.append(enemy)
			var nonce := begin_vent(_world_outcome, _world_attempt, global_position,
				nearby, target)
			if nonce > 0:
				_broadcast_visual()
	if _host_authority() and active:
		advance(delta)
		var pip := ceili(remaining / (TELEGRAPH_SECONDS / float(TELEGRAPH_PIPS)))
		if pip != _last_broadcast_pip:
			_last_broadcast_pip = pip
			_broadcast_visual()
	_refresh_pips()


func begin_vent(outcome: String, p_attempt_id: String, p_position: Vector3,
		nearby_enemies: Array = [], bad_target: Node3D = null) -> int:
	if not _host_authority() or outcome not in ["cinderbound", "cinders_rebuke"] \
		or p_attempt_id.is_empty() or active:
		return 0
	attempt_id = p_attempt_id
	_next_nonce += 1
	active_nonce = _next_nonce
	active_outcome = outcome
	remaining = TELEGRAPH_SECONDS
	vent_position = p_position
	_nearby_enemies = nearby_enemies.duplicate()
	_bad_target = bad_target
	active = true
	vent_started.emit(active_nonce, active_outcome)
	return active_nonce


func advance(delta: float) -> void:
	if not _host_authority() or not active:
		return
	remaining = maxf(0.0, remaining - maxf(0.0, delta))
	if remaining <= 0.0:
		_resolve_active_vent()


func _resolve_active_vent() -> void:
	if not active:
		return
	var nonce := active_nonce
	var outcome := active_outcome
	active = false
	if outcome == "cinderbound":
		for enemy in _nearby_enemies:
			if enemy is Node3D and is_instance_valid(enemy) \
				and (enemy as Node3D).global_position.distance_to(vent_position) <= EFFECT_RADIUS:
				if enemy.has_method("take_damage"):
					enemy.call("take_damage", GOOD_DAMAGE, Vector3.ZERO)
				if enemy.has_method("apply_cinder_poise_break"):
					enemy.call("apply_cinder_poise_break")
				elif enemy.get("poise_pressure") != null:
					# Compatibility fallback for a presentation-only enemy. Combatants
					# consume the dedicated method above as an actual stagger/interrupt.
					enemy.set("poise_pressure", float(enemy.get("poise_pressure")) + 1.0)
		pickup = {"nonce": nonce, "position": vent_position, "claimed": false}
		focus_pickup_spawned.emit(nonce, vent_position)
	else:
		# The target is selected when the three-pip tell begins, but it must still
		# be standing in the authored radius when the fire lands. A player who
		# leaves the ring during the 1.25-second warning takes neither damage nor
		# the movement slow.
		if _bad_target != null and is_instance_valid(_bad_target) \
				and _bad_target.global_position.distance_to(vent_position) <= EFFECT_RADIUS:
			var applied := true
			if _bad_target.has_method("apply_cinder_damage"):
				applied = bool(_bad_target.call("apply_cinder_damage", BAD_DAMAGE, Vector3.ZERO))
			elif _bad_target.has_method("take_damage"):
				_bad_target.call("take_damage", BAD_DAMAGE, Vector3.ZERO)
			if applied:
				# PlayerController consumes this through its ordinary status slow
				# product, so Cinder's Rebuke affects movement rather than leaving
				# a display-only metadata marker. The marker remains a bounded
				# fallback for simple test dummies and presentation-only actors.
				if _bad_target.has_method("apply_status"):
					_bad_target.call("apply_status", "cinder_slow", 1.4, 0, 0.60)
				_bad_target.set_meta("cinders_rebuke_slow_seconds", 1.4)
	vent_resolved.emit(nonce, outcome)
	_broadcast_visual()


func request_focus_pickup(nonce: int, requester: Node3D = null) -> bool:
	if _host_authority():
		if _net_active():
			return _host_claim_for_peer(nonce, multiplayer.get_unique_id())
		return _host_claim(nonce, requester, 1)
	if pickup.is_empty() or int(pickup.get("nonce", -1)) != nonce \
			or bool(pickup.get("claimed", false)):
		return false
	request_focus_pickup_rpc.rpc_id(1, nonce)
	# This only confirms the owner-local request left the client.  The host's
	# reliable nonce acknowledgement is the sole confirmation that grants Focus.
	return true


@rpc("any_peer", "call_remote", "reliable")
func request_focus_pickup_rpc(nonce: int) -> void:
	if _host_authority():
		_host_claim_for_peer(nonce, multiplayer.get_remote_sender_id())


func _host_claim_for_peer(nonce: int, peer_id: int) -> bool:
	var accepted := _host_claim(nonce, _host_player_for_peer(peer_id), peer_id)
	if _net_active() and peer_id > 0 and peer_id != multiplayer.get_unique_id():
		receive_focus_claim.rpc_id(peer_id, nonce, accepted,
			FOCUS_AMOUNT if accepted else 0.0, _last_claim_reason)
	return accepted


func _host_claim(nonce: int, requester: Node3D, peer_id: int = 1) -> bool:
	_last_claim_reason = ""
	if not _host_authority():
		return _reject("not_host")
	if pickup.is_empty() or int(pickup.get("nonce", -1)) != nonce:
		return _reject("unknown_pickup")
	if bool(pickup.get("claimed", false)):
		return _reject("already_claimed")
	if requester == null or requester.global_position.distance_to(pickup.position) > PICKUP_RANGE:
		return _reject("too_far")
	# Claim before granting.  Re-entrant signals and duplicate reliable RPCs
	# see the claimed bit and cannot mint a second Focus award.
	pickup.claimed = true
	# Focus remains local to its owner.  The host does not maintain a Focus
	# ledger for remote players and therefore never mutates a remote puppet's
	# resource; it sends the accepted nonce back to that player instead.
	if not _net_active() or peer_id == multiplayer.get_unique_id():
		if requester.has_method("add_focus"):
			requester.call("add_focus", FOCUS_AMOUNT)
		elif requester.get("focus") != null:
			requester.set("focus", float(requester.get("focus")) + FOCUS_AMOUNT)
	focus_claimed.emit(nonce, peer_id, FOCUS_AMOUNT)
	_broadcast_visual()
	return true


func telegraph_view() -> Dictionary:
	return {"active": active, "nonce": active_nonce, "outcome": active_outcome,
		"remaining": remaining, "pips": TELEGRAPH_PIPS, "attempt_id": attempt_id,
		"pickup_active": not pickup.is_empty() and not bool(pickup.get("claimed", false)),
		"pickup_nonce": int(pickup.get("nonce", 0)),
		"pickup_position": pickup.get("position", Vector3.ZERO)}


# Transport adapters may mirror this compact view to guests.  It never calls
# resolution, damages anything, or creates a pickup; a guest receives only the
# three-pip visual and rejects a stale packet rather than rewinding a tell.
func apply_visual_snapshot(view: Dictionary) -> bool:
	var nonce := int(view.get("nonce", -1))
	var snapshot_attempt := String(view.get("attempt_id", ""))
	if nonce < 0 or nonce < _last_visual_nonce or (not snapshot_attempt.is_empty() \
			and not _world_attempt.is_empty() and snapshot_attempt != _world_attempt):
		return false
	# A duplicate start packet must never resurrect an already-resolved tell.
	if nonce == _last_visual_nonce and not active and bool(view.get("active", false)):
		return false
	var pickup_active := bool(view.get("pickup_active", false))
	var pickup_nonce := int(view.get("pickup_nonce", -1))
	var raw_position = view.get("pickup_position", Vector3.ZERO)
	if pickup_active and (pickup_nonce <= 0 or not (raw_position is Vector3)):
		return false
	var same_nonce := nonce == _last_visual_nonce
	_last_visual_nonce = nonce
	active = bool(view.get("active", false))
	active_nonce = nonce
	active_outcome = String(view.get("outcome", ""))
	var snapshot_remaining := maxf(0.0, float(view.get("remaining", 0.0)))
	remaining = minf(remaining, snapshot_remaining) if active and same_nonce \
		and remaining > 0.0 else snapshot_remaining
	if pickup_active:
		var prior_nonce := int(pickup.get("nonce", -1))
		pickup = {"nonce": pickup_nonce, "position": raw_position,
			"claimed": false, "visual_only": true}
		if prior_nonce != pickup_nonce:
			focus_pickup_spawned.emit(pickup_nonce, raw_position)
	elif not pickup.is_empty():
		var cleared_nonce := int(pickup.get("nonce", -1))
		pickup = {}
		if cleared_nonce > 0:
			focus_pickup_cleared.emit(cleared_nonce)
	_refresh_pips()
	return true


@rpc("authority", "call_remote", "reliable")
func receive_visual_snapshot(view: Dictionary) -> void:
	apply_visual_snapshot(view)


# The Cinderbound pickup is authoritative at the host, but Focus itself is
# deliberately owner-local.  This acknowledgement carries no client-provided
# amount or position and is idempotent by pickup nonce.
@rpc("authority", "call_remote", "reliable")
func receive_focus_claim(nonce: int, accepted: bool, amount: float, _reason: String) -> void:
	# A host never calls this RPC locally. Keeping the guard session-scoped also
	# lets headless contract tests exercise the owner-side acknowledgement with
	# the same nonce matcher used by a real guest.
	if _net_active() and _host_authority():
		return
	if accepted:
		if _local_claim_results.has(nonce):
			return
		_local_claim_results[nonce] = true
		if not pickup.is_empty() and int(pickup.get("nonce", -1)) == nonce:
			pickup = {}
			focus_pickup_cleared.emit(nonce)
		var owner := _owner_local_player()
		if owner != null:
			if owner.has_method("add_focus"):
				owner.call("add_focus", amount)
			elif owner.get("focus") != null:
				owner.set("focus", float(owner.get("focus")) + amount)
	focus_pickup_claim_resolved.emit(nonce, accepted)


func _broadcast_visual() -> void:
	if _net_active() and _host_authority():
		var net := get_node_or_null("/root/NetGame")
		var roster: Dictionary = net.get("players") as Dictionary if net != null else {}
		var view := telegraph_view()
		for raw_peer in _world_ready_peers.keys():
			var peer_id := int(raw_peer)
			if peer_id <= 0 or peer_id == multiplayer.get_unique_id():
				continue
			if not roster.has(peer_id):
				_world_ready_peers.erase(peer_id)
				continue
			receive_visual_snapshot.rpc_id(peer_id, view)


func _nearest_player(max_distance: float) -> Node3D:
	var best: Node3D = null
	var best_d := max_distance
	for player in get_tree().get_nodes_in_group("player"):
		if not player is Node3D or bool((player as Node).get("dead")):
			continue
		var distance := (player as Node3D).global_position.distance_to(global_position)
		if distance <= best_d:
			best = player as Node3D
			best_d = distance
	return best


func _build_pips() -> void:
	for i in TELEGRAPH_PIPS:
		var pip := MeshInstance3D.new()
		pip.name = "VentPip%d" % (i + 1)
		var mesh := SphereMesh.new()
		mesh.radius = 0.10
		mesh.height = 0.20
		mesh.radial_segments = 8
		mesh.rings = 4
		pip.mesh = mesh
		pip.position = Vector3((float(i) - 1.0) * 0.28, 0.20, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.38, 0.10)
		mat.emission_enabled = true
		mat.emission = mat.albedo_color
		mat.emission_energy_multiplier = 1.8
		pip.material_override = mat
		add_child(pip)
		_pip_meshes.append(pip)
	_refresh_pips()


func _refresh_pips() -> void:
	var lit := ceili(remaining / (TELEGRAPH_SECONDS / float(TELEGRAPH_PIPS))) if active else 0
	for i in _pip_meshes.size():
		(_pip_meshes[i] as MeshInstance3D).visible = i < lit


func _reject(reason: String) -> bool:
	_last_claim_reason = reason
	focus_request_rejected.emit(reason)
	return false


func _host_player_for_peer(peer_id: int) -> Node3D:
	if peer_id <= 0:
		return null
	for player in get_tree().get_nodes_in_group("player"):
		if player is Node3D and (player as Node).get_multiplayer_authority() == peer_id:
			return player as Node3D
	return null


func _owner_local_player() -> Node3D:
	for player in get_tree().get_nodes_in_group("player"):
		if player is Node3D and (player as Node).is_multiplayer_authority():
			return player as Node3D
	return null


func _on_world_peer_disconnected(peer_id: int) -> void:
	_world_ready_peers.erase(peer_id)


func _host_authority() -> bool:
	var net := get_node_or_null("/root/NetGame")
	return net == null or not bool(net.get("active")) or multiplayer.is_server()


func _net_active() -> bool:
	var net := get_node_or_null("/root/NetGame")
	return net != null and bool(net.get("active"))
