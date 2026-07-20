extends SceneTree

# D8 Slice 2 transport/authority contract.  This is deliberately an in-process
# deterministic harness: it exercises the host adapter and guest mirror seams,
# but does NOT claim a two-process ENet proof.  The RPC runtime's sender ID is
# tested by the Rules identity boundary; a real host/guest ENet smoke remains a
# browser/native integration gate.

const Encounter := preload("res://scripts/knot_eater_encounter.gd")
const Rules := preload("res://scripts/knot_eater_rules.gd")

var passed := 0
var failed := 0


class PeerAvatar extends CharacterBody3D:
	var dead := false
	var pending: Dictionary = {}
	var applied_receipts := 0
	var cancel_reason := ""

	func wayfinders_mark_pending() -> Dictionary:
		return pending.duplicate(true)
	func apply_wayfinders_mark_receipt(receipt: Dictionary) -> bool:
		if pending.is_empty() or int(receipt.get("reservation_nonce", -1)) \
				!= int(pending.get("nonce", -2)):
			return false
		pending.clear()
		applied_receipts += 1
		return true
	func cancel_wayfinders_mark(reason: String) -> void:
		pending.clear()
		cancel_reason = reason


class AuthoredAnchor extends Node3D:
	var anchor_id := ""
	var state := "bound"
	func set_state(next_state: String) -> void: state = next_state


class AuthoredKnot extends Node3D:
	var knot_id := ""
	var state := "sealed"
	func set_state(next_state: String) -> void: state = next_state


func _initialize() -> void:
	call_deferred("_run")


func _check(label: String, ok: bool, detail = "") -> void:
	if ok:
		passed += 1
		print("  ✓ %s" % label)
	else:
		failed += 1
		print("  ✗ %s %s" % [label, str(detail)])


func _player_facts(peer_id: int, now_ms: int, extra: Dictionary = {}) -> Dictionary:
	var facts := {
		"world_ready": true,
		"chart_instance_id": "coop-chart",
		"attempt_id": "coop-attempt",
		"now_ms": now_ms,
		"sender_id": peer_id,
		"body_peer": peer_id,
		"entitled": true,
		"focus_reserved": true,
		"player_alive": true,
		"target_exists": true,
		"target_reeling": true,
		"in_range": true,
		"has_line_of_sight": true,
	}
	for key in extra:
		facts[key] = extra[key]
	return facts


func _trusted(now_ms: int) -> Dictionary:
	return _player_facts(1, now_ms, {"trusted": true})


func _to_reeling(rules: RefCounted, peer_id: int = 2) -> Dictionary:
	rules.dispatch({"kind": "survival"}, _trusted(0))
	for index in 3:
		rules.dispatch({"kind": "unbind", "peer_id": peer_id, "nonce": index + 1,
			"anchor_id": "anchor_%d" % (index + 1)}, _player_facts(peer_id, 10 + index))
	return rules.dispatch({"kind": "exposure", "knot_id": "knot_1"}, _trusted(1000000))


func _to_naming(rules: RefCounted, peer_id: int = 2) -> void:
	rules.dispatch({"kind": "survival"}, _trusted(0))
	for index in 3:
		rules.dispatch({"kind": "unbind", "peer_id": peer_id, "nonce": index + 1,
			"anchor_id": "anchor_%d" % (index + 1)}, _player_facts(peer_id, 10 + index))
	for index in 3:
		var now_ms := 100 + index * 15000
		var exposed: Dictionary = rules.dispatch({"kind": "exposure", "knot_id": "knot_%d" % (index + 1)}, _trusted(now_ms))
		rules.dispatch({"kind": "mark", "peer_id": peer_id, "nonce": index + 4,
			"knot_id": "knot_%d" % (index + 1), "reel_nonce": int(exposed.get("reel_nonce", 0))},
			_player_facts(peer_id, now_ms + 1))


func _fixture() -> Dictionary:
	var world := Node3D.new()
	world.name = "KnotEaterCoopAuthorityWorld"
	root.add_child(world)
	var controller: Node3D = Encounter.new()
	world.add_child(controller)
	var remote := PeerAvatar.new()
	remote.name = "RemoteWayfinder"
	remote.set_multiplayer_authority(2)
	remote.add_to_group("player")
	world.add_child(remote)
	var contender := PeerAvatar.new()
	contender.name = "SecondRemoteWayfinder"
	contender.set_multiplayer_authority(3)
	contender.add_to_group("player")
	world.add_child(contender)
	var anchors: Array = []
	var knots: Array = []
	for index in 3:
		var anchor := AuthoredAnchor.new()
		anchor.anchor_id = "anchor_%d" % (index + 1)
		world.add_child(anchor)
		anchors.append(anchor)
		var knot := AuthoredKnot.new()
		knot.knot_id = "knot_%d" % (index + 1)
		world.add_child(knot)
		knots.append(knot)
	await process_frame
	controller.configure(null, anchors, knots)
	controller.begin_attempt("coop-chart", "coop-attempt")
	# Joining peers are denied until their exact world-ready handshake completes.
	controller._ready_peers.erase(2)
	controller._ready_peers.erase(3)
	return {"world": world, "controller": controller, "remote": remote, "contender": contender}


func _free_fixture(fixture: Dictionary) -> void:
	var world := fixture.get("world") as Node
	if world != null and is_instance_valid(world):
		world.queue_free()
	await process_frame


func _run() -> void:
	print("--- Knot-Eater co-op authority/transport check (in-process; no ENet claim) ---")
	await _host_adapter_and_race()
	_snapshot_mirrors_and_reconnect()
	await _guest_naming_is_host_only()
	print("--- %d passed, %d failed ---" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _host_adapter_and_race() -> void:
	var net := root.get_node_or_null("NetGame")
	if net != null:
		var saved_players: Dictionary = net.players.duplicate(true)
		var saved_sessions: Dictionary = net._peer_by_session_player.duplicate(true)
		var token_a: String = net._new_session_player_id()
		var token_b: String = net._new_session_player_id()
		net.players = {}
		net._peer_by_session_player = {token_a: 2}
		var rebound_claim: Dictionary = net._claim_session_player(token_a, 7)
		net.players = {7: {"name": "connected"}}
		var borrowed_claim: Dictionary = net._claim_session_player(token_a, 8)
		_check("NetGame's opaque session token is unique, rebinds a disconnected peer, and cannot borrow a connected body",
			token_a.length() >= 24 and token_a != token_b
			and bool(rebound_claim.get("ok", false))
			and int(rebound_claim.get("old_peer_id", 0)) == 2
			and not bool(borrowed_claim.get("ok", true))
			and borrowed_claim.get("reason") == "session_player_connected",
			{"rebound": rebound_claim, "borrowed": borrowed_claim})
		net.players = saved_players
		net._peer_by_session_player = saved_sessions
		var body_scene := Node3D.new()
		root.add_child(body_scene)
		var preserved_body := PeerAvatar.new()
		preserved_body.name = "NetPlayer2"
		preserved_body.set_multiplayer_authority(2)
		preserved_body.pending = {"nonce": 9101, "reserved": 35.0}
		body_scene.add_child(preserved_body)
		var body_rebound: bool = net._rebind_player_body(body_scene, 2, 7)
		_check("reconnect renumbers the same local Player body so its live Focus reservation survives",
			body_rebound and preserved_body.name == "NetPlayer7"
			and preserved_body.get_multiplayer_authority() == 7
			and int(preserved_body.wayfinders_mark_pending().nonce) == 9101)
		body_scene.free()
	else:
		_check("NetGame autoload is present for reconnect identity", false)
	var fixture := await _fixture()
	var controller: Node3D = fixture.controller
	var before_ready: Dictionary = controller._host_press(2, "unbind", "anchor_1")
	var private_public: Dictionary = controller.press(&"expose", &"knot_1")
	_check("host fails closed before a remote peer reports the exact world-ready context",
		not bool(before_ready.get("accepted", false)) and before_ready.get("reason") == "world_not_ready")
	_check("the public encounter facade rejects private survival/exposure verbs",
		not bool(private_public.get("accepted", false)) and private_public.get("reason") == "private_verb")

	var identity_rules := Rules.new("coop-chart", "coop-attempt")
	var sender_spoof: Dictionary = identity_rules.dispatch({"kind": "unbind", "peer_id": 2, "nonce": 1,
		"anchor_id": "anchor_1"}, _player_facts(2, 1, {"sender_id": 3}))
	var body_spoof: Dictionary = identity_rules.dispatch({"kind": "unbind", "peer_id": 2, "nonce": 2,
		"anchor_id": "anchor_1"}, _player_facts(2, 2, {"body_peer": 3}))
	_check("rules bind each player command to both transport sender and resolved body authority",
		sender_spoof.get("reason") == "sender_mismatch" and body_spoof.get("reason") == "body_mismatch",
		{"sender": sender_spoof, "body": body_spoof})

	controller._ready_peers[2] = true
	var packet_exposure: Dictionary = controller._host_press(2, "expose", "knot_1")
	_check("the any-peer transport boundary also rejects private exposure",
		not bool(packet_exposure.get("accepted", false))
		and packet_exposure.get("reason") == "private_verb", packet_exposure)
	# This is the authoritative scene timer's private transition.  It is not
	# callable through press(), as asserted above.
	controller._refresh(controller.rules.dispatch({"kind": "survival"}, controller._trusted_facts()))
	for index in 3:
		controller._host_press(2, "unbind", "anchor_%d" % (index + 1))
	_check("coordinator resolves the remote actor from its authority and advances only valid authored anchors",
		String(controller.view().get("phase", "")) == Rules.PHASE_KNOTS
		and int(controller.view().get("anchor_mask", 0)) == Rules.ALL_THREE, controller.view())
	# Exposure is a host-owned cadence/timer transition, so test it only through
	# the trusted scene adapter rather than a packet-shaped public command.
	controller._refresh(controller.rules.dispatch({"kind": "exposure", "knot_id": "knot_1"}, controller._trusted_facts()))

	controller._ready_peers[3] = true
	var attestation := {"nonce": 41, "entitled": true, "focus_reserved": true}
	var accepted: Dictionary = controller._host_press(2, "mark", "", attestation)
	var raced: Dictionary = controller._host_press(3, "mark", "", {"nonce": 77,
		"entitled": true, "focus_reserved": true})
	var success_count := int(bool(accepted.get("accepted", false))) + int(bool(raced.get("accepted", false)))
	_check("a remote owner attestation can spend one 35-Focus Mark receipt, while a simultaneous peer loses the same Reeling window",
		success_count == 1 and bool(accepted.get("accepted", false))
		and int(accepted.get("focus_spend", 0)) == Rules.MARK_COST
		and not bool(raced.get("accepted", false)) and int(raced.get("focus_spend", 0)) == 0,
		{"accepted": accepted, "raced": raced})
	controller._on_peer_disconnected(2)
	var during_reconnect: Dictionary = controller._host_press(2, "mark", "", attestation)
	# NetGame emits this only after the reconnecting socket proves the same
	# opaque session token. The new transport ID must inherit, not recreate, the
	# rules ledger; it remains unready until the World handshake follows.
	controller._on_peer_rebound(2, 7, "session-token-test")
	var before_world_ready: Dictionary = controller._host_press(7, "mark", "", attestation)
	controller._ready_peers[7] = true # exact report_world_ready restores transport readiness.
	var rejoined: Dictionary = controller._snapshot_for_peer(7)
	_check("token-proven reconnect rebinds the accepted receipt and it outranks later setup rejection",
		bool(during_reconnect.get("accepted", false))
		and bool(during_reconnect.get("duplicate", false))
		and during_reconnect.get("kind") == "mark"
		and int(during_reconnect.get("reservation_nonce", 0)) == 41
		and int(during_reconnect.get("focus_spend", -1)) == Rules.MARK_COST
		and bool(before_world_ready.get("accepted", false))
		and int((rejoined.get("receipt", {}) as Dictionary).get("nonce", 0)) == int(accepted.get("nonce", 0))
		and int((rejoined.get("receipt", {}) as Dictionary).get("peer_id", 0)) == 7
		and int((rejoined.get("receipt", {}) as Dictionary).get("reservation_nonce", 0)) == 41
		and int((rejoined.get("receipt", {}) as Dictionary).get("focus_spend", 0)) == Rules.MARK_COST,
		{"during_reconnect": during_reconnect, "rejoined": rejoined})
	controller._on_peer_disconnected(3)
	var gated: Dictionary = controller._host_press(3, "mark", "", {"nonce": 88,
		"entitled": true, "focus_reserved": true})
	controller._on_peer_rebound(3, 8, "other-session-token")
	controller._ready_peers[8] = true
	var gated_snapshot: Dictionary = controller._snapshot_for_peer(8)
	_check("a dropped reservation-bearing World-not-ready rejection survives rebind in the peer ledger",
		gated.get("reason") == "world_not_ready" and int(gated.get("focus_spend", -1)) == 0
		and int((gated_snapshot.receipt as Dictionary).get("peer_id", 0)) == 8
		and int((gated_snapshot.receipt as Dictionary).get("reservation_nonce", 0)) == 88
		and String((gated_snapshot.receipt as Dictionary).get("reason", "")) == "world_not_ready",
		{"gated": gated, "snapshot": gated_snapshot})
	await _free_fixture(fixture)


func _snapshot_mirrors_and_reconnect() -> void:
	var host := Rules.new("coop-chart", "coop-attempt")
	var exposed: Dictionary = _to_reeling(host, 2)
	var receipt: Dictionary = host.dispatch({"kind": "mark", "peer_id": 2, "nonce": 11,
		"knot_id": "knot_1", "reel_nonce": int(exposed.get("reel_nonce", 0))}, _player_facts(2, 1000001))
	var peer_two: Dictionary = host.snapshot_for_peer(2, 1000002)
	var peer_three: Dictionary = host.snapshot_for_peer(3, 1000002)
	var peer_four: Dictionary = host.snapshot_for_peer(4, 1000002)
	_check("host snapshots scope Mark receipts to the owning peer rather than broadcasting its Focus spend",
		peer_two.get("receipt", {}) == receipt
		and (peer_three.get("receipt", {}) as Dictionary).is_empty()
		and (peer_four.get("receipt", {}) as Dictionary).is_empty())

	# A disconnect removes a peer from publication readiness, not from the host's
	# receipt ledger. Its matching rejoin snapshot must still settle the same
	# owner-local reservation exactly once.
	var reconnect_snapshot := host.snapshot_for_peer(2, 1000003)
	_check("an unresolved owner receipt survives the host-side reconnect boundary",
		reconnect_snapshot.get("receipt", {}) == receipt)

	var reeling_host := Rules.new("coop-chart", "coop-attempt")
	_to_reeling(reeling_host, 2)
	var reeling_snapshot := reeling_host.snapshot(1000500)
	var guest_mirror := Rules.new("coop-chart", "coop-attempt")
	var applied := guest_mirror.apply_snapshot(reeling_snapshot, 100)
	var stale_rejected := not guest_mirror.apply_snapshot(reeling_snapshot, 100)
	_check("guest mirrors reconstruct Reeling from remaining time on their local clock and reject stale packets",
		applied and stale_rejected
		and int((guest_mirror.view(200).get("telegraph", {}) as Dictionary).get("remaining_ms", -1)) == 2400)

	var settled_host := Rules.new("coop-chart", "coop-attempt")
	_to_naming(settled_host, 2)
	var named: Dictionary = settled_host.dispatch({"kind": "name", "peer_id": 1,
		"nonce": 1, "road_name_id": "lantern_path"},
		_player_facts(1, 50000, {"is_host": true}))
	var effect := named.get("pending_effect", {}) as Dictionary
	settled_host.dispatch({"kind": "settlement_result",
		"effect_id": effect.get("effect_id", ""),
		"road_name_id": "lantern_path", "ok": true}, _trusted(50001))
	var mirror_world := Node3D.new()
	root.add_child(mirror_world)
	var mirror_controller: Node3D = Encounter.new()
	mirror_world.add_child(mirror_controller)
	var mirror_anchors: Array = []
	var mirror_knots: Array = []
	for index in 3:
		var anchor := AuthoredAnchor.new(); anchor.anchor_id = "anchor_%d" % (index + 1)
		mirror_world.add_child(anchor); mirror_anchors.append(anchor)
		var knot := AuthoredKnot.new(); knot.knot_id = "knot_%d" % (index + 1)
		mirror_world.add_child(knot); mirror_knots.append(knot)
	mirror_controller.configure(null, mirror_anchors, mirror_knots)
	mirror_controller.begin_attempt("coop-chart", "coop-attempt")
	var settled_edges := [0]
	mirror_controller.settled.connect(func(): settled_edges[0] += 1)
	var settled_snapshot := settled_host.snapshot_for_peer(4, 50002)
	mirror_controller._receive_snapshot(settled_snapshot)
	mirror_controller._receive_snapshot(settled_snapshot)
	_check("passive/late guest snapshots refresh every actor and edge-emit terminal presentation once",
		mirror_anchors.all(func(actor): return String(actor.state) == "unbound")
		and mirror_knots.all(func(actor): return String(actor.state) == "marked")
		and settled_edges[0] == 1 and bool(mirror_controller.view().settled),
		{"settled_edges": settled_edges[0], "view": mirror_controller.view()})
	mirror_world.free()

	var accepted_host := Rules.new("coop-chart", "coop-attempt")
	_to_knots_for_peer(accepted_host, 1)
	var accepted_exposure: Dictionary = accepted_host.dispatch(
		{"kind": "exposure", "knot_id": "knot_1"}, _trusted(60000))
	accepted_host.dispatch({"kind": "mark", "peer_id": 1, "nonce": 4,
		"reservation_nonce": 9201, "knot_id": "knot_1",
		"reel_nonce": int(accepted_exposure.reel_nonce)}, _player_facts(1, 60001))
	accepted_host.dispatch({"kind": "reset_for_retry"}, _trusted(60002))
	var accepted_mirror := _reset_mirror_fixture(9201)
	(accepted_mirror.controller as Node)._receive_snapshot(
		accepted_host.snapshot_for_peer(1, 60003))
	var accepted_owner := accepted_mirror.owner as PeerAvatar
	_check("wipe snapshot applies a retained accepted receipt before resetting the guest ritual",
		accepted_owner.applied_receipts == 1 and accepted_owner.pending.is_empty()
		and accepted_owner.cancel_reason == "")
	(accepted_mirror.world as Node).free()

	var unmatched_host := Rules.new("coop-chart", "coop-attempt")
	_to_knots_for_peer(unmatched_host, 1)
	unmatched_host.dispatch({"kind": "reset_for_retry"}, _trusted(61000))
	var unmatched_mirror := _reset_mirror_fixture(9301)
	(unmatched_mirror.controller as Node)._receive_snapshot(
		unmatched_host.snapshot_for_peer(1, 61001))
	var unmatched_owner := unmatched_mirror.owner as PeerAvatar
	_check("wipe snapshot releases an unmatched lost-window reservation without spending",
		unmatched_owner.applied_receipts == 0 and unmatched_owner.pending.is_empty()
		and unmatched_owner.cancel_reason == "encounter_reset")
	(unmatched_mirror.world as Node).free()


func _guest_naming_is_host_only() -> void:
	var fixture := await _fixture()
	var controller: Node3D = fixture.controller
	var naming_rules := Rules.new("coop-chart", "coop-attempt")
	_to_naming(naming_rules, 2)
	controller.rules = naming_rules
	controller._ready_peers[2] = true
	# The real controller's nonce generator is monotonic across the same rules
	# instance.  This fixture deliberately swaps in a prebuilt naming state.
	controller._intent_nonces[2] = 6
	var guest_name: Dictionary = controller._host_press(2, "name", "lantern_path")
	_check("a guest can never stage the road-name settlement effect through the coordinator",
		not bool(guest_name.get("accepted", false)) and guest_name.get("reason") == "host_only"
		and String(naming_rules.view().get("phase", "")) == Rules.PHASE_NAMING, guest_name)
	await _free_fixture(fixture)


func _to_knots_for_peer(rules: RefCounted, peer_id: int) -> void:
	rules.dispatch({"kind": "survival"}, _trusted(0))
	for index in 3:
		rules.dispatch({"kind": "unbind", "peer_id": peer_id, "nonce": index + 1,
			"anchor_id": "anchor_%d" % (index + 1)},
			_player_facts(peer_id, 10 + index))


func _reset_mirror_fixture(reservation_nonce: int) -> Dictionary:
	var world := Node3D.new()
	root.add_child(world)
	var owner := PeerAvatar.new()
	owner.name = "ResetMirrorOwner"
	owner.add_to_group("player")
	owner.set_multiplayer_authority(1)
	owner.pending = {"nonce": reservation_nonce, "reserved": 35.0}
	world.add_child(owner)
	var controller: Node3D = Encounter.new()
	world.add_child(controller)
	controller.configure(null, [], [])
	controller.begin_attempt("coop-chart", "coop-attempt")
	_to_knots_for_peer(controller.rules, 1)
	return {"world": world, "owner": owner, "controller": controller}
