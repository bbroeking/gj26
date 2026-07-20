extends SceneTree

# Focused Fire encounter contract.  This is intentionally a pure world seam:
# campaign escrow and NetGame transport remain outside the controller and are
# tested by their owners.  Here we lock the rules a transport adapter must not
# be able to bypass.

const CombatantScript = preload("res://scripts/combatant.gd")
const GiantScript = preload("res://scripts/hearth_giant.gd")
const EncounterScript = preload("res://scripts/hearth_giant_encounter.gd")
const ChainScript = preload("res://scripts/hearth_chain.gd")
const VentScript = preload("res://scripts/cinderbound_vent.gd")

var passed := 0
var failed := 0


class FocusDummy extends Node3D:
	var hp := 30
	var focus := 0.0
	var poise_pressure := 0.0
	var hits: Array[int] = []
	func take_damage(amount: int, _from_dir: Vector3) -> void:
		hp -= amount
		hits.append(amount)


class SlowDummy extends FocusDummy:
	var slow_kind := ""
	var slow_seconds := 0.0
	var slow_factor := 1.0
	func apply_status(kind: String, seconds: float, _damage: int, factor: float) -> Dictionary:
		slow_kind = kind
		slow_seconds = seconds
		slow_factor = factor
		return {"kind": kind}


func check(label: String, ok: bool, detail := "") -> void:
	if ok:
		passed += 1
		print("  ✓ %s" % label)
	else:
		failed += 1
		print("  ✗ %s %s" % [label, detail])


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	print("--- Fire in the Bough encounter authority ---")
	CombatantScript.crit_enabled = false
	await test_heat_floors_and_chain_order()
	await test_giant_state_clips()
	await test_snapshot_lifecycle()
	await test_settled_snapshot_presentation()
	await test_cinderbound_authority()
	await _shutdown_runtime()
	print("--- Fire encounter: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _shutdown_runtime() -> void:
	# `quit()` tears down a --script SceneTree before its autoload audio pool
	# and real-time hitstop timers naturally drain. Release/drain them here so
	# ObjectDB reporting remains a real leak signal.
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("shutdown"):
		sfx.call("shutdown")
	Engine.time_scale = 1.0
	await create_timer(0.25, true, false, true).timeout
	await process_frame


func _encounter_fixture() -> Dictionary:
	var giant: Node3D = GiantScript.new()
	giant.name = "HearthGiant"
	root.add_child(giant)
	giant.setup(100, 0.85, 2.8)
	var controller: Node3D = EncounterScript.new()
	root.add_child(controller)
	var chain_nodes: Array = []
	for id in EncounterScript.CHAIN_ORDER:
		var chain: Node3D = ChainScript.new()
		chain.configure(id)
		root.add_child(chain)
		chain.global_position = Vector3.ZERO
		chain_nodes.append(chain)
	controller.configure(giant, chain_nodes)
	controller.begin_attempt("chart-fire-1", "attempt-fire-1")
	var player := FocusDummy.new()
	root.add_child(player)
	player.global_position = Vector3.ZERO
	return {"giant": giant, "controller": controller, "chains": chain_nodes, "player": player}


func _free_fixture(fixture: Dictionary) -> void:
	for item in [fixture.giant, fixture.controller, fixture.player] + fixture.chains:
		if is_instance_valid(item):
			item.queue_free()


func test_heat_floors_and_chain_order() -> void:
	var f := _encounter_fixture()
	var giant: Node3D = f.giant
	var controller: Node3D = f.controller
	var player: Node3D = f.player
	giant.take_damage(999, Vector3.FORWARD)
	check("post-multiplier combat damage stops at the 75% heat floor", giant.hp == 75 \
		and giant.heat_phase == 1 and giant.heat_shielded and not giant.dead)
	giant.take_damage(999, Vector3.FORWARD)
	giant._apply_tick_damage(999)
	check("a raised heat shield holds its current floor against direct and status damage", \
		giant.hp == 75 and giant.heat_phase == 1 and giant.heat_shielded and not giant.dead)
	player.global_position = Vector3(2.7, 0.0, 0.0)
	var knot_chain: Node3D = f.chains[2]
	knot_chain.interact(player)
	check("a prompted wrong authored chain makes one recoverable hazard without clearing progress", \
		controller.bank_mask == 0 and giant.heat_phase == 1 \
		and int(player.get("hp")) == 26)
	var hollow_chain: Node3D = f.chains[0]
	hollow_chain.interact(player)
	var first: bool = int(controller.bank_mask) == 1
	giant.take_damage(999, Vector3.FORWARD)
	var second: bool = controller.request_chain_bank("braided_link", "chart-fire-1", "attempt-fire-1", player)
	giant.take_damage(999, Vector3.FORWARD)
	var third: bool = controller.request_chain_bank("knot_link", "chart-fire-1", "attempt-fire-1", player)
	check("immutable Hollow, Braided, Knot banking releases each shield then kneels the Giant", \
		first and second and third and controller.bank_mask == 7 and controller.settled \
		and giant.kneeling and giant.banked_fire and not giant.dead \
		and (controller.chains.values() as Array).all(func(chain):
			return bool(chain.call("is_used"))),
		str({"mask": controller.bank_mask, "phase": giant.heat_phase, "kneeling": giant.kneeling}))
	var post_kneel_deaths := {"count": 0}
	giant.died.connect(func(): post_kneel_deaths.count += 1)
	giant.take_damage(999, Vector3.FORWARD)
	giant._apply_tick_damage(999)
	giant.net_apply_state(giant.global_position, 0)
	check("a kneeling Giant is permanently nonlethal against direct, status, and net damage", \
		giant.hp > 0 and not giant.dead and int(post_kneel_deaths.count) == 0)
	# An exact identity is part of the authority proof, not a presentation hint.
	check("stale Chart or attempt identity cannot bank a chain", \
		not controller.request_chain_bank("knot_link", "wrong-chart", "attempt-fire-1", player))
	_free_fixture(f)
	await process_frame


func _giant_animation_player(giant: Node) -> AnimationPlayer:
	var player := AnimationPlayer.new()
	var library := AnimationLibrary.new()
	for state in ["Idle", "Attack", "Hit", "HeatShield", "ChainReact", "Kneel"]:
		var animation := Animation.new()
		animation.length = 0.2
		library.add_animation("HearthGiant_%s" % state, animation)
	player.add_animation_library("", library)
	giant.add_child(player)
	return player


func test_giant_state_clips() -> void:
	var f := _encounter_fixture()
	var giant: Node3D = f.giant
	var controller: Node3D = f.controller
	var player: Node3D = f.player
	var animation_player := _giant_animation_player(giant)
	giant.take_damage(10, Vector3.FORWARD)
	var hit_clip := animation_player.current_animation
	giant._begin_attack()
	var attack_clip := animation_player.current_animation
	giant.reset_fight()
	giant.take_damage(999, Vector3.FORWARD)
	var shield_clip := animation_player.current_animation
	controller.request_chain_bank("hollow_link", "chart-fire-1", "attempt-fire-1", player)
	var chain_clip := animation_player.current_animation
	giant.take_damage(999, Vector3.FORWARD)
	controller.request_chain_bank("braided_link", "chart-fire-1", "attempt-fire-1", player)
	giant.take_damage(999, Vector3.FORWARD)
	controller.request_chain_bank("knot_link", "chart-fire-1", "attempt-fire-1", player)
	check("Hearth Giant consumes authored Attack/Hit/HeatShield/ChainReact/Kneel clips at state transitions", \
		hit_clip.contains("Hit") and attack_clip.contains("Attack") \
		and shield_clip.contains("HeatShield") and chain_clip.contains("ChainReact") \
		and animation_player.current_animation.contains("Kneel"),
		str({"hit": hit_clip, "attack": attack_clip, "shield": shield_clip,
			"chain": chain_clip, "kneel": animation_player.current_animation}))
	_free_fixture(f)
	await process_frame


func test_snapshot_lifecycle() -> void:
	var host := _encounter_fixture()
	var host_giant: Node3D = host.giant
	host_giant.take_damage(999, Vector3.FORWARD)
	host.controller.set_telegraph("cinder_swing", 7, 0.8)
	var snapshot: Dictionary = host.controller.snapshot_for_world()
	var pre_ready_rejected: bool = not host.controller._peer_ready_for_authority(77)
	var denied_ready: Dictionary = host.controller.world_ready_snapshot_for_peer(77,
		"other-chart", "attempt-fire-1")
	var ready_snapshot: Dictionary = host.controller.world_ready_snapshot_for_peer(77,
		"chart-fire-1", "attempt-fire-1")
	host.controller.set_telegraph("cinder_swing", 8, 0.5)
	var pushed_snapshot: Dictionary = host.controller.snapshot_for_world()
	var ready_peer_tracked := bool(host.controller._world_ready_peers.get(77, false))
	host.controller._on_world_peer_disconnected(77)
	check("World-ready transport binds the exact Chart/attempt before tracking a peer for pushes", \
		pre_ready_rejected and denied_ready.is_empty() and not ready_snapshot.is_empty()
		and ready_peer_tracked and not host.controller._world_ready_peers.has(77)
		and int(pushed_snapshot.snapshot_nonce) > int(ready_snapshot.snapshot_nonce))
	var guest_giant: Node3D = GiantScript.new()
	guest_giant.net_puppet = true
	root.add_child(guest_giant)
	guest_giant.setup(100, 0.85, 2.8)
	var guest: Node3D = EncounterScript.new()
	root.add_child(guest)
	var guest_chains: Array = []
	for id in EncounterScript.CHAIN_ORDER:
		var chain: Node3D = ChainScript.new()
		chain.configure(id)
		root.add_child(chain)
		guest_chains.append(chain)
	guest.configure(guest_giant, guest_chains)
	guest.begin_guest_world_ready("chart-fire-1", "attempt-fire-1")
	check("guest stays inert until a matching World-ready snapshot is applied", \
		guest.is_guest_inert() and not guest.apply_world_snapshot({"chart_instance": "other", "attempt_id": "attempt-fire-1"}))
	var applied: bool = guest.apply_world_snapshot(snapshot)
	var malformed := snapshot.duplicate(true)
	malformed.snapshot_nonce = int(snapshot.snapshot_nonce) + 1
	malformed.chain_states.hollow_link = "banked"
	var stale := snapshot.duplicate(true)
	stale.snapshot_nonce = int(snapshot.snapshot_nonce) - 1
	stale.telegraph.nonce = 1
	check("matching snapshot atomically mirrors boss/heat/chains; malformed or stale payloads cannot mutate it", \
		applied and not guest.is_guest_inert() and guest_giant.hp == 75 \
		and guest_giant.heat_shielded and guest.current_telegraph.nonce == 7 \
		and not guest.apply_world_snapshot(malformed) and not guest.apply_world_snapshot(stale) \
		and guest.current_telegraph.nonce == 7 and guest.apply_world_snapshot(snapshot))
	_free_fixture(host)
	for node in [guest_giant, guest] + guest_chains:
		if is_instance_valid(node): node.queue_free()
	await process_frame


func test_settled_snapshot_presentation() -> void:
	var host := _encounter_fixture()
	for chain_id in EncounterScript.CHAIN_ORDER:
		host.giant.take_damage(999, Vector3.FORWARD)
		host.controller.request_chain_bank(chain_id, "chart-fire-1", "attempt-fire-1", host.player)
	var settled_snapshot: Dictionary = host.controller.snapshot_for_world()
	var guest := _encounter_fixture()
	guest.controller.begin_guest_world_ready("chart-fire-1", "attempt-fire-1")
	var settled_events := {"count": 0}
	guest.controller.settled_snapshot_applied.connect(func(): settled_events.count += 1)
	var applied: bool = guest.controller.apply_world_snapshot(settled_snapshot)
	var replayed: bool = guest.controller.apply_world_snapshot(settled_snapshot)
	check("a settled World-ready snapshot emits one guest-safe presentation event without rerunning settlement", \
		applied and replayed and guest.controller.settled and guest.giant.kneeling \
		and int(settled_events.count) == 1,
		str({"applied": applied, "replayed": replayed, "settled": guest.controller.settled,
			"kneeling": guest.giant.kneeling, "events": settled_events,
			"valid": guest.controller._valid_world_snapshot(settled_snapshot),
			"snapshot": settled_snapshot}))
	_free_fixture(host)
	_free_fixture(guest)
	await process_frame


func test_cinderbound_authority() -> void:
	var vent: Node3D = VentScript.new()
	root.add_child(vent)
	var enemy := FocusDummy.new()
	root.add_child(enemy)
	enemy.global_position = Vector3(1, 0, 0)
	var staggered := CombatantScript.new()
	root.add_child(staggered)
	staggered.global_position = Vector3(1.5, 0, 0)
	staggered.setup(30, 0.5, 1.4)
	staggered._state = CombatantScript.State.ATTACK
	var claimant := FocusDummy.new()
	root.add_child(claimant)
	claimant.global_position = Vector3(8, 0, 0)
	claimant.add_to_group("player")
	claimant.set_multiplayer_authority(2)
	var borrowed := FocusDummy.new()
	root.add_child(borrowed)
	borrowed.global_position = Vector3.ZERO
	borrowed.add_to_group("player")
	borrowed.set_multiplayer_authority(3)
	vent.arm_world("cinderbound", "attempt-fire-1", Vector3.ZERO)
	var nonce: int = vent.begin_vent("cinderbound", "attempt-fire-1", Vector3.ZERO, [enemy, staggered])
	check("Cinderbound exposes exactly a 1.25 second three-pip host telegraph", \
		nonce == 1 and vent.telegraph_view().remaining == 1.25 and vent.telegraph_view().pips == 3)
	vent.advance(1.25)
	var pickup_view: Dictionary = vent.telegraph_view()
	var denied_vent_ready: Dictionary = vent.world_ready_visual_for_peer(44, "wrong-attempt")
	var late_join_view: Dictionary = vent.world_ready_visual_for_peer(44, "attempt-fire-1")
	var far: bool = vent._host_claim_for_peer(nonce, 2)
	claimant.global_position = Vector3.ZERO
	var claimed: bool = vent._host_claim_for_peer(nonce, 2)
	var duplicate: bool = vent._host_claim_for_peer(nonce, 2)
	check("good vent damages and converts Cinder Poise into an observable stagger/interrupt", \
		 enemy.hp == 23 and enemy.poise_pressure == 1.0 and not far and claimed and not duplicate \
		and claimant.focus == VentScript.FOCUS_AMOUNT and staggered.hp == 23 \
		and staggered.cinder_poise_break_active() and staggered._state == CombatantScript.State.IDLE)
	claimant.remove_from_group("player")
	borrowed.remove_from_group("player")
	var client_owner := FocusDummy.new()
	root.add_child(client_owner)
	client_owner.add_to_group("player")
	var pickup_visual := VentScript.new()
	root.add_child(pickup_visual)
	var visual_spawns := {"count": 0}
	pickup_visual.focus_pickup_spawned.connect(func(_pickup_nonce: int, _position: Vector3):
		visual_spawns.count += 1)
	var pickup_visible := pickup_visual.apply_visual_snapshot(late_join_view)
	pickup_visual.receive_focus_claim(nonce, true, VentScript.FOCUS_AMOUNT, "accepted")
	pickup_visual.receive_focus_claim(nonce, true, VentScript.FOCUS_AMOUNT, "duplicate")
	vent._on_world_peer_disconnected(44)
	check("late World-ready Cinder replay restores one extant pickup; its host ack grants owner-local Focus once", \
		denied_vent_ready.is_empty() and not late_join_view.is_empty() \
		and pickup_visible and int(visual_spawns.count) == 1 and pickup_visual.pickup.is_empty() \
		and not vent._world_ready_peers.has(44) \
		and client_owner.focus == VentScript.FOCUS_AMOUNT,
		str({"visible": pickup_visible, "spawns": visual_spawns,
			"pickup": pickup_visual.pickup, "focus": client_owner.focus}))
	var guest_visual := VentScript.new()
	root.add_child(guest_visual)
	var visual_ok := guest_visual.apply_visual_snapshot({"active": true, "nonce": 9, "outcome": "cinderbound", "remaining": 0.4})
	var visual_stale := guest_visual.apply_visual_snapshot({"active": true, "nonce": 8, "outcome": "cinders_rebuke", "remaining": 1.0})
	check("guest Cinderbound transport applies visuals only and ignores stale vent nonces", \
		visual_ok and not visual_stale and guest_visual.active_nonce == 9 and guest_visual.pickup.is_empty())
	var target := SlowDummy.new()
	root.add_child(target)
	var bad_nonce: int = vent.begin_vent("cinders_rebuke", "attempt-fire-1", Vector3.ZERO, [], target)
	vent.advance(1.25)
	check("Cinder's Rebuke resolves host-side as damage plus a consumed movement slow", \
		bad_nonce == 2 and target.hp == 25 and target.slow_kind == "cinder_slow" \
		and target.slow_seconds == 1.4 and target.slow_factor == 0.60)
	var escaped := SlowDummy.new()
	root.add_child(escaped)
	var escaped_nonce: int = vent.begin_vent("cinders_rebuke", "attempt-fire-1", Vector3.ZERO, [], escaped)
	escaped.global_position = Vector3(3.0, 0.0, 0.0)
	vent.advance(1.25)
	check("Cinder's Rebuke rechecks the target radius when its telegraph resolves", \
		escaped_nonce == 3 and escaped.hp == 30 and escaped.slow_kind.is_empty())
	for node in [vent, pickup_visual, guest_visual, enemy, staggered, claimant, borrowed, client_owner, target, escaped]:
		if is_instance_valid(node): node.queue_free()
	await process_frame
