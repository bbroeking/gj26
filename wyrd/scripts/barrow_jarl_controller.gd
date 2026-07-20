class_name BarrowJarlController
extends Node3D

# Narrow world/RPC adapter for three Oathbound reliefs.  It owns no campaign
# rewards; callers listen to the Jarl's canonical `died` only after this local
# encounter state validates every bell.

signal relief_committed(phase_index: int, bell_id: String)
signal bell_request_rejected(reason: String)

var jarl: Node = null
var guards: Array = []
var bells: Array = []
var completed: Array[bool] = [false, false, false]


func configure(p_jarl: Node, p_guards: Array, p_bells: Array) -> void:
	jarl = p_jarl
	guards = p_guards
	bells = p_bells
	if jarl != null and jarl.has_signal("relief_phase_started"):
		jarl.relief_phase_started.connect(_on_relief_phase_started)
	for guard in guards:
		if guard != null and guard.has_method("set_vow_dormant"):
			guard.set_vow_dormant()
	for i in bells.size():
		var bell = bells[i]
		if bell != null and bell.has_method("set_controller"):
			bell.set_controller(self, i + 1)


func _on_relief_phase_started(phase_index: int) -> void:
	_apply_relief_phase(phase_index)
	if _net_active() and _host_authority():
		_net_relief_phase.rpc(phase_index)


func _apply_relief_phase(phase_index: int) -> void:
	if phase_index < 1 or phase_index > guards.size():
		return
	for i in guards.size():
		var guard = guards[i]
		if guard == null:
			continue
		if i == phase_index - 1 and guard.has_method("arm_vow"):
			guard.arm_vow(phase_index)
		elif not completed[i] and guard.has_method("set_vow_dormant"):
			guard.set_vow_dormant()
	for bell in bells:
		if bell != null and bell.has_method("set_enabled_for_phase"):
			bell.set_enabled_for_phase(phase_index)


@rpc("authority", "call_remote", "reliable")
func _net_relief_phase(phase_index: int) -> void:
	_apply_relief_phase(phase_index)


func request_bell_relief(bell_id: String, claimed_phase: int, requester: Node3D = null) -> bool:
	# Offline and host play validate locally.  A guest has no authority to mutate
	# the Jarl and only sends this small request to the host; no Game/NetGame edit
	# is required for that seam.
	if _host_authority():
		if _net_active():
			return _host_validate_request_for_peer(bell_id, claimed_phase,
					multiplayer.get_unique_id())
		return _host_validate_and_commit(bell_id, claimed_phase, requester)
	request_bell_relief_rpc.rpc_id(1, bell_id, claimed_phase)
	return false


@rpc("any_peer", "call_remote", "reliable")
func request_bell_relief_rpc(bell_id: String, claimed_phase: int) -> void:
	if not _host_authority():
		return
	# Bind the proximity proof to the actual RPC sender.  The host never accepts
	# a client-supplied position and never borrows a different peer's nearby body.
	_host_validate_request_for_peer(bell_id, claimed_phase,
		multiplayer.get_remote_sender_id())


func _host_validate_request_for_peer(bell_id: String, claimed_phase: int,
		peer_id: int) -> bool:
	return _host_validate_and_commit(bell_id, claimed_phase,
		_host_player_for_peer(peer_id))


func _host_validate_and_commit(bell_id: String, claimed_phase: int, requester: Node3D) -> bool:
	var phase := int(claimed_phase)
	if jarl == null or phase < 1 or phase > 3 or phase != int(jarl.get("relief_phase")):
		bell_request_rejected.emit("wrong_phase")
		return false
	if completed[phase - 1]:
		bell_request_rejected.emit("already_relieved")
		return false
	var bell = _bell_for_phase(phase)
	var guard = guards[phase - 1] if phase - 1 < guards.size() else null
	if bell == null or String(bell.get("bell_id")) != bell_id:
		bell_request_rejected.emit("wrong_bell")
		return false
	if guard == null or not bool(guard.get("reeling")):
		bell_request_rejected.emit("guard_not_reeling")
		return false
	if requester == null or requester.global_position.distance_to(bell.global_position) > 2.25:
		bell_request_rejected.emit("too_far")
		return false
	_apply_relief_commit(phase, bell_id)
	if _net_active() and _host_authority():
		_net_relief_committed.rpc(phase, bell_id)
	relief_committed.emit(phase, bell_id)
	return true


func _apply_relief_commit(phase: int, bell_id: String) -> void:
	var bell = _bell_for_phase(phase)
	var guard = guards[phase - 1] if phase - 1 < guards.size() else null
	completed[phase - 1] = true
	if guard != null and guard.has_method("relieve"):
		guard.relieve()
	if bell != null and String(bell.get("bell_id")) == bell_id and bell.has_method("set_relieved"):
		bell.set_relieved()
	if jarl != null and jarl.has_method("release_vow_shield"):
		jarl.release_vow_shield(phase)


@rpc("authority", "call_remote", "reliable")
func _net_relief_committed(phase: int, bell_id: String) -> void:
	if phase < 1 or phase > 3 or completed[phase - 1]:
		return
	_apply_relief_commit(phase, bell_id)
	relief_committed.emit(phase, bell_id)


func all_reliefs_complete() -> bool:
	return completed.size() == 3 and completed.all(func(v): return v)


func _bell_for_phase(phase: int):
	return bells[phase - 1] if phase - 1 < bells.size() else null


func _host_player_for_peer(peer_id: int) -> Node3D:
	if peer_id <= 0:
		return null
	for p in get_tree().get_nodes_in_group("player"):
		if p is Node3D and (p as Node).get_multiplayer_authority() == peer_id:
				return p as Node3D
	return null


func _host_authority() -> bool:
	var net := get_node_or_null("/root/NetGame")
	return net == null or not bool(net.get("active")) or multiplayer.is_server()


func _net_active() -> bool:
	var net := get_node_or_null("/root/NetGame")
	return net != null and bool(net.get("active"))
