extends SceneTree

const Rules := preload("res://scripts/knot_eater_rules.gd")
var passed := 0
var failed := 0

func _initialize() -> void:
	print("--- Knot-Eater pure rules ---")
	_happy_path_and_settlement()
	_illegal_and_receipts()
	_snapshot_and_replay()
	print("--- %d passed, %d failed ---" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _check(label: String, ok: bool, detail = "") -> void:
	if ok:
		passed += 1
		print("  ✓ %s" % label)
	else:
		failed += 1
		print("  ✗ %s %s" % [label, str(detail)])

func _facts(now: int, extra: Dictionary = {}) -> Dictionary:
	var out := {"world_ready": true, "chart_instance_id": "chart-a", "attempt_id": "attempt-a", "now_ms": now,
		"sender_id": 9, "body_peer": 9, "in_range": true, "has_line_of_sight": true,
		"entitled": true, "focus_reserved": true, "player_alive": true,
		"target_exists": true, "target_reeling": true}
	for key in extra: out[key] = extra[key]
	return out

func _trusted(now: int) -> Dictionary:
	return _facts(now, {"trusted": true})

func _to_knots(rules: RefCounted, first_nonce: int = 1) -> void:
	rules.dispatch({"kind": "survival"}, _trusted(0))
	for index in 3:
		rules.dispatch({"kind": "unbind", "peer_id": 9, "nonce": first_nonce + index, "anchor_id": "anchor_%d" % (index + 1)}, _facts(10 + index))

func _mark_one(rules: RefCounted, knot: int, nonce: int, now: int) -> Dictionary:
	var exposed: Dictionary = rules.dispatch({"kind": "exposure", "knot_id": "knot_%d" % knot}, _trusted(now))
	return rules.dispatch({"kind": "mark", "peer_id": 9, "nonce": nonce, "knot_id": "knot_%d" % knot, "reel_nonce": int(exposed.reel_nonce)}, _facts(now + 1))

func _happy_path_and_settlement() -> void:
	var r := Rules.new("chart-a", "attempt-a")
	_to_knots(r)
	var first := _mark_one(r, 1, 4, 100)
	var second := _mark_one(r, 2, 5, 15000)
	var third := _mark_one(r, 3, 6, 30000)
	_check("three authored anchors and knots reach naming", r.view(30001).phase == "naming" and int(r.view(0).anchor_mask) == 7 and int(r.view(0).knot_mask) == 7)
	_check("every accepted Mark returns exact no-mutation Focus receipt", bool(first.accepted) and int(first.focus_spend) == 35 and int(first.focus_delta) == -35 and first.spend_receipt == {"resource": "focus", "amount": 35, "nonce": 4} and bool(second.accepted) and bool(third.accepted), first)
	var guest_name: Dictionary = r.dispatch({"kind": "name", "peer_id": 9, "nonce": 7, "road_name_id": "lantern_path"}, _facts(30002))
	var named: Dictionary = r.dispatch({"kind": "name", "peer_id": 9, "nonce": 8, "road_name_id": "lantern_path"}, _facts(30002, {"is_host": true}))
	var effect: Dictionary = named.pending_effect
	_check("only host name stages one idempotent pending effect", not bool(guest_name.accepted) and guest_name.reason == "host_only" and bool(named.accepted) and r.view(0).phase == "settling" and not effect.is_empty(), named)
	var wrong_retry: Dictionary = r.dispatch({"kind": "name", "peer_id": 9,
		"nonce": 9, "road_name_id": "mended_way"}, _facts(30003, {"is_host": true}))
	var exact_retry: Dictionary = r.dispatch({"kind": "name", "peer_id": 9,
		"nonce": 10, "road_name_id": "lantern_path"}, _facts(30003, {"is_host": true}))
	_check("pending settlement retries only the exact accepted road name",
		wrong_retry.reason == "road_name_mismatch" and bool(exact_retry.accepted)
		and exact_retry.reason == "pending_replay" and exact_retry.pending_effect == effect)
	var bad: Dictionary = r.dispatch({"kind": "settlement_result", "effect_id": effect.effect_id, "road_name_id": "mended_way", "ok": true}, _trusted(30003))
	var done: Dictionary = r.dispatch({"kind": "settlement_result", "effect_id": effect.effect_id, "road_name_id": "lantern_path", "ok": true}, _trusted(30004))
	_check("only matching durable result settles; different-name tombstone cannot", not bool(bad.accepted) and bool(done.accepted) and r.view(0).settled and r.view(0).road_name_id == "lantern_path", bad)

func _illegal_and_receipts() -> void:
	var r := Rules.new("chart-a", "attempt-a")
	var early: Dictionary = r.dispatch({"kind": "mark", "peer_id": 9, "nonce": 1, "knot_id": "knot_1", "reel_nonce": 1}, _facts(0))
	var spoof: Dictionary = r.dispatch({"kind": "unbind", "peer_id": 9, "nonce": 2, "anchor_id": "anchor_1"}, _facts(0, {"sender_id": 8}))
	_check("illegal phase and sender/body spoof are rejected", early.reason == "wrong_phase" and spoof.reason == "sender_mismatch")
	_to_knots(r, 3)
	var exposed: Dictionary = r.dispatch({"kind": "exposure", "knot_id": "knot_1"}, _trusted(100))
	var wrong_reel: Dictionary = r.dispatch({"kind": "mark", "peer_id": 9, "nonce": 6, "knot_id": "knot_1", "reel_nonce": 0}, _facts(101))
	var far: Dictionary = r.dispatch({"kind": "mark", "peer_id": 9, "nonce": 7, "knot_id": "knot_1", "reel_nonce": int(exposed.reel_nonce)}, _facts(102, {"in_range": false}))
	var blocked: Dictionary = r.dispatch({"kind": "mark", "peer_id": 9, "nonce": 8, "knot_id": "knot_1", "reel_nonce": int(exposed.reel_nonce)}, _facts(103, {"has_line_of_sight": false}))
	var good: Dictionary = r.dispatch({"kind": "mark", "peer_id": 9, "nonce": 9, "knot_id": "knot_1", "reel_nonce": int(exposed.reel_nonce)}, _facts(104))
	var replay: Dictionary = r.dispatch({"kind": "mark", "peer_id": 9, "nonce": 9, "knot_id": "knot_1", "reel_nonce": int(exposed.reel_nonce)}, _facts(105, {"in_range": false}))
	var expired := r.dispatch({"kind": "exposure", "knot_id": "knot_2"}, _trusted(15000))
	var late: Dictionary = r.dispatch({"kind": "mark", "peer_id": 9, "nonce": 10, "knot_id": "knot_2", "reel_nonce": int(expired.reel_nonce)}, _facts(18000))
	var timed: Dictionary = r.dispatch({"kind": "time"}, _trusted(18000))
	_check("reel nonce, range, LOS and 3s expiry are ordered rejections", wrong_reel.reason == "reel_nonce_mismatch" and far.reason == "out_of_range" and blocked.reason == "no_line_of_sight" and late.reason == "reel_expired" and timed.reason == "expired" and r.view(18000).phase == "knots")
	_check("duplicate nonce is stable and does not spend twice", bool(good.accepted) and bool(replay.accepted) and bool(replay.duplicate) and int(replay.focus_spend) == 35)
	for nonce in range(11, 45):
		r.dispatch({"kind": "name", "peer_id": 9, "nonce": nonce, "road_name_id": "lantern_path"}, _facts(18001, {"is_host": true}))
	var old: Dictionary = r.dispatch({"kind": "mark", "peer_id": 9, "nonce": 2, "knot_id": "knot_2", "reel_nonce": 2}, _facts(18002))
	_check("high-water rejects evicted/too-old nonce", old.reason == "too_old")
	var death_before := r.view(18002)
	var death: Dictionary = r.dispatch({"kind": "death"}, _trusted(18003))
	_check("boss death is fully inert", death.reason == "boss_death_inert" and death.focus_spend == 0 and r.view(18002) == death_before)
	var gates := Rules.new("chart-a", "attempt-a")
	var wrong_world: Dictionary = gates.dispatch({"kind": "unbind", "peer_id": 9, "nonce": 1, "anchor_id": "anchor_1"}, _facts(0, {"world_ready": false}))
	var wrong_chart: Dictionary = gates.dispatch({"kind": "unbind", "peer_id": 9, "nonce": 2, "anchor_id": "anchor_1"}, _facts(0, {"chart_instance_id": "chart-b"}))
	_to_knots(gates, 3)
	var gate_exposed: Dictionary = gates.dispatch({"kind": "exposure", "knot_id": "knot_1"}, _trusted(100))
	var unentitled: Dictionary = gates.dispatch({"kind": "mark", "peer_id": 9, "nonce": 6, "knot_id": "knot_1", "reel_nonce": int(gate_exposed.reel_nonce)}, _facts(101, {"entitled": false}))
	var unreserved: Dictionary = gates.dispatch({"kind": "mark", "peer_id": 9, "nonce": 7, "knot_id": "knot_1", "reel_nonce": int(gate_exposed.reel_nonce)}, _facts(101, {"focus_reserved": false}))
	var gate_good: Dictionary = gates.dispatch({"kind": "mark", "peer_id": 9, "nonce": 8, "knot_id": "knot_1", "reel_nonce": int(gate_exposed.reel_nonce)}, _facts(101))
	var next_exposed: Dictionary = gates.dispatch({"kind": "exposure", "knot_id": "knot_2"}, _trusted(102))
	var cooldown: Dictionary = gates.dispatch({"kind": "mark", "peer_id": 9, "nonce": 9, "knot_id": "knot_2", "reel_nonce": int(next_exposed.reel_nonce)}, _facts(103))
	_check("identity, reservation, and 14-second cooldown rejects spend exactly zero", wrong_world.reason == "identity_mismatch" and wrong_chart.reason == "identity_mismatch" and unentitled.reason == "not_entitled" and unreserved.reason == "focus_not_reserved" and bool(gate_good.accepted) and cooldown.reason == "cooldown" and int(unentitled.focus_spend) == 0 and int(cooldown.focus_spend) == 0)
	var split_nonce := Rules.new("chart-a", "attempt-a")
	_to_knots(split_nonce, 1)
	var split_exposed: Dictionary = split_nonce.dispatch(
		{"kind": "exposure", "knot_id": "knot_1"}, _trusted(200))
	var split_mark: Dictionary = split_nonce.dispatch({"kind": "mark", "peer_id": 9,
		"nonce": 4, "reservation_nonce": 1, "knot_id": "knot_1",
		"reel_nonce": int(split_exposed.reel_nonce)}, _facts(201))
	_check("encounter ordering and owner reservation nonces remain distinct",
		bool(split_mark.accepted) and int(split_mark.nonce) == 4
		and int(split_mark.reservation_nonce) == 1
		and split_nonce.snapshot_for_peer(9, 202).receipt == split_mark, split_mark)

func _snapshot_and_replay() -> void:
	var host := Rules.new("chart-a", "attempt-a")
	_to_knots(host)
	var exposed: Dictionary = host.dispatch({"kind": "exposure", "knot_id": "knot_1"}, _trusted(10))
	var accepted := host.dispatch({"kind": "mark", "peer_id": 9, "nonce": 4, "knot_id": "knot_1", "reel_nonce": int(exposed.reel_nonce)}, _facts(11))
	var peer_view: Dictionary = host.snapshot_for_peer(9, 12)
	var other_view: Dictionary = host.snapshot_for_peer(10, 12)
	_check("peer reconnect receives only its unresolved stable receipt", peer_view.receipt == accepted and (other_view.receipt as Dictionary).is_empty())
	var mirror := Rules.new("chart-a", "attempt-a")
	var snap := host.snapshot(12)
	var malformed := snap.duplicate(true); malformed.active_knot_id = "knot_2"
	var wrong_id := snap.duplicate(true); wrong_id.chart_instance_id = "elsewhere"
	var dead_phase := snap.duplicate(true); dead_phase.phase = "died"
	_check("snapshot rejects malformed, death, and identity states atomically",
		not mirror.apply_snapshot(malformed) and not mirror.apply_snapshot(dead_phase)
		and not mirror.apply_snapshot(wrong_id) and mirror.view(0).phase == "gnawing")
	_check("valid snapshot applies once and stale snapshot is rejected", mirror.apply_snapshot(snap) and not mirror.apply_snapshot(snap) and mirror.view(0).phase == host.view(0).phase)
	var reeling_host := Rules.new("chart-a", "attempt-a")
	_to_knots(reeling_host)
	reeling_host.dispatch({"kind": "exposure", "knot_id": "knot_1"},
		_trusted(1000000))
	var reeling_mirror := Rules.new("chart-a", "attempt-a")
	var reeling_snapshot: Dictionary = reeling_host.snapshot(1000500)
	_check("guest Reeling time uses remaining duration, not the host clock origin",
		reeling_mirror.apply_snapshot(reeling_snapshot, 100)
		and int((reeling_mirror.view(200).telegraph as Dictionary).remaining_ms) == 2400)
	var replay := Rules.new("chart-a", "attempt-a")
	_check("accepted transition replay is deterministic", replay.replay(host.accepted_transitions()) and replay.snapshot(12) == host.snapshot(12))
	var continuity := Rules.new("chart-a", "attempt-a")
	_to_knots(continuity)
	var continuity_exposed: Dictionary = continuity.dispatch(
		{"kind": "exposure", "knot_id": "knot_1"}, _trusted(100))
	var continuity_receipt: Dictionary = continuity.dispatch({"kind": "mark",
		"peer_id": 9, "nonce": 4, "reservation_nonce": 7001,
		"knot_id": "knot_1", "reel_nonce": int(continuity_exposed.reel_nonce)},
		_facts(101))
	var reset: Dictionary = continuity.dispatch({"kind": "reset_for_retry"},
		_trusted(102))
	var rebound := continuity.rebind_peer(9, 12)
	var rebound_snapshot: Dictionary = continuity.snapshot_for_peer(12, 103)
	_check("wipe reset preserves exact receipt/cooldown and token-proven rebind moves it",
		bool(reset.accepted) and String(continuity.view(103).phase) == "gnawing"
		and bool(rebound) and int(rebound_snapshot.receipt.peer_id) == 12
		and int(rebound_snapshot.receipt.reservation_nonce) == 7001
		and int(rebound_snapshot.receipt.focus_spend) == 35
		and int(rebound_snapshot.mark_cooldown_left_ms) > 0
		and (continuity.snapshot_for_peer(9, 103).receipt as Dictionary).is_empty(),
		{"receipt": continuity_receipt, "snapshot": rebound_snapshot})
