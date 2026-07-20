extends SceneTree

# D8 Slice 2 — owner-side reservation contract. Encounter reducer/network
# proofs live with KnotEaterEncounter; this mounts the shipped Player so UI
# slots, entitlement checks, Focus accounting, and reconnect behavior cannot
# drift away from the real hotbar path.

const PlayerScene := preload("res://scenes/Player.tscn")
const Progression := preload("res://data/progression.gd")
const SkillBarScript := preload("res://scripts/skill_bar.gd")
const LoadoutPanelScript := preload("res://scripts/ui/loadout_panel.gd")
const KnotEaterEncounterScript := preload("res://scripts/knot_eater_encounter.gd")

var _pass := 0
var _fail := 0


class MarkEncounterStub extends Node:
	var presses: Array = []
	var reeling := true
	func _ready() -> void:
		add_to_group("knot_eater_encounter")
	func view() -> Dictionary:
		return {"phase": "reeling" if reeling else "knots",
			"active_knot_id": "knot_1" if reeling else "",
			"mark_ready": reeling, "mark_cooldown_left_ms": 0,
			"telegraph": {"kind": "reeling" if reeling else "",
				"remaining_ms": 2000 if reeling else 0}}
	func press(verb: StringName, subject_id: StringName) -> Dictionary:
		presses.append({"verb": verb, "subject_id": subject_id})
		# The live encounter may answer asynchronously; tests feed its receipt
		# through PlayerController explicitly below.
		return {}


func _initialize() -> void:
	_run()


func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % name)
	else:
		_fail += 1
		print("  ✗ %s %s" % [name, detail])


func _run() -> void:
	print("--- Wayfinder's Mark live PlayerController check ---")
	var game := root.get_node_or_null("Game")
	if game == null:
		_check("Game autoload is present", false)
		quit(1)
		return
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.trades.huntcraft = {"xp": Progression.xp_for_level(22), "lv": 22}
	game.owned_skills = ["WayfindersMark", "PowerShot"]
	game.loadout = ["WayfindersMark", "PowerShot"]
	_check("hotbar and loadout surfaces compile with distinct Mark data",
		SkillBarScript != null and LoadoutPanelScript != null)

	var world := Node3D.new()
	world.name = "WayfindersMarkLiveWorld"
	root.add_child(world)
	var encounter := MarkEncounterStub.new()
	world.add_child(encounter)
	var player: CharacterBody3D = PlayerScene.instantiate()
	world.add_child(player)
	await physics_frame
	await physics_frame
	player.rebuild_skills()
	_check("factory equips the distinct Mark action", _skill_names(player)
		== ["BasicShot", "WayfindersMark", "PowerShot"], str(_skill_names(player)))

	player.focus = player.focus_max
	encounter.reeling = false
	_check("hotbar/preflight stay unavailable outside an authoritative Reeling window",
		String(player.wayfinders_mark_availability().reason) == "not_reeling"
		and not bool(player.prepare_wayfinders_mark_request().ok))
	encounter.reeling = true
	var request: Dictionary = player.prepare_wayfinders_mark_request()
	_check("preflight requires and reserves Huntcraft-22 equipped owner", bool(request.ok)
		and int(request.nonce) > 0 and is_equal_approx(float(request.cost), 35.0)
		and bool(request.party_trust_entitlement)
		and is_equal_approx(player._available_focus_after_reservations(), 15.0), str(request))
	player._try_skill(3)
	_check("reserved Focus blocks generic spend", is_equal_approx(player.focus, player.focus_max)
		and float(player._skill_cooldowns.get(3, 0.0)) == 0.0)
	var nonce := int(request.nonce)
	var accepted: bool = bool(player.apply_wayfinders_mark_receipt(
		{"nonce": 99, "reservation_nonce": nonce, "accepted": true}))
	var accepted_focus := float(player.focus)
	_check("matching acceptance debits exactly once and starts Mark slot cooldown", accepted
		and is_equal_approx(accepted_focus, player.focus_max - 35.0)
		and is_equal_approx(float(player._skill_cooldowns.get(2, 0.0)), 14.0))
	_check("duplicate or late receipt is inert", not player.apply_wayfinders_mark_receipt(
		{"nonce": 99, "reservation_nonce": nonce, "accepted": true})
		and is_equal_approx(player.focus, accepted_focus))

	player.focus = player.focus_max
	player._skill_cooldowns[2] = 0.0
	var rejected: Dictionary = player.prepare_wayfinders_mark_request()
	var reject_ok: bool = bool(player.apply_wayfinders_mark_receipt(
		{"nonce": int(rejected.nonce), "accepted": false, "reason": "not_reeling"}))
	_check("rejection releases with zero spend or cooldown", bool(rejected.ok) and reject_ok
		and player.wayfinders_mark_pending().is_empty()
		and is_equal_approx(player.focus, player.focus_max)
		and is_equal_approx(float(player._skill_cooldowns.get(2, 0.0)), 0.0))

	player._skill_cooldowns[2] = 1.0
	_check("owner preflight refuses a live Mark cooldown",
		not bool(player.prepare_wayfinders_mark_request().ok))
	player._skill_cooldowns[2] = 0.0
	player.focus = player.focus_max
	var invariant_request: Dictionary = player.prepare_wayfinders_mark_request()
	player.focus = 34.0
	var invariant_receipt := {"nonce": int(invariant_request.nonce), "accepted": true}
	var first_invariant_apply: bool = bool(player.apply_wayfinders_mark_receipt(invariant_receipt))
	var kept_pending: bool = not player.wayfinders_mark_pending().is_empty()
	player.focus = 35.0
	var reconciled: bool = bool(player.apply_wayfinders_mark_receipt(invariant_receipt))
	_check("accepted receipt survives a temporary Focus invariant and reconciles once",
		not first_invariant_apply and kept_pending and reconciled
		and player.wayfinders_mark_pending().is_empty() and is_zero_approx(player.focus))

	player.focus = player.focus_max
	player._skill_cooldowns[2] = 0.0
	player._try_skill(2)
	_check("hotbar dispatch presses only the Knot-Eater Mark seam", encounter.presses.size() == 1
		and String(encounter.presses[0].verb) == "mark"
		and String(encounter.presses[0].subject_id) == ""
		and not player.wayfinders_mark_pending().is_empty(), str(encounter.presses))
	var net := root.get_node_or_null("NetGame")
	if net == null:
		_check("NetGame autoload is present", false)
	else:
		net.reconnecting.emit(1, 3)
		_check("transient reconnect preserves unresolved reservation",
			not player.wayfinders_mark_pending().is_empty())
		net.session_ended.emit("test definitive end")
		_check("definitive session end cancels without debit", player.wayfinders_mark_pending().is_empty()
			and is_equal_approx(player.focus, player.focus_max))

	player.focus = 34.0
	_check("preflight refuses unreserved short Focus", not bool(player.prepare_wayfinders_mark_request().ok))

	# A setup rejection is authoritative too. Reconnecting must apply that exact
	# reservation-bearing receipt instead of silently resubmitting it into a
	# later Reeling window where it could become an unintended acceptance.
	encounter.remove_from_group("knot_eater_encounter")
	var live_encounter: Node3D = KnotEaterEncounterScript.new()
	world.add_child(live_encounter)
	live_encounter.begin_attempt("mark-reconnect-chart", "mark-reconnect-attempt")
	var now := Time.get_ticks_msec()
	var trusted := {"trusted": true, "world_ready": true,
		"chart_instance_id": "mark-reconnect-chart", "attempt_id": "mark-reconnect-attempt",
		"now_ms": now, "player_alive": true, "target_exists": true,
		"target_reeling": true}
	var owner_facts := trusted.duplicate(true)
	owner_facts.merge({"sender_id": 1, "body_peer": 1, "in_range": true,
		"has_line_of_sight": true, "entitled": true, "focus_reserved": true}, true)
	live_encounter.rules.dispatch({"kind": "survival"}, trusted)
	for index in 3:
		live_encounter.rules.dispatch({"kind": "unbind", "peer_id": 1,
			"nonce": index + 1, "anchor_id": "anchor_%d" % (index + 1)}, owner_facts)
	live_encounter.rules.dispatch({"kind": "exposure", "knot_id": "knot_1"}, trusted)
	player.focus = player.focus_max
	player._skill_cooldowns[2] = 0.0
	var reconnect_request: Dictionary = player.prepare_wayfinders_mark_request()
	var setup_rejection: Dictionary = live_encounter.rules.record_setup_rejection(
		1, 4, int(reconnect_request.get("nonce", 0)), "world_not_ready")
	live_encounter._on_reconnecting(1, 3)
	live_encounter._receive_snapshot(live_encounter.rules.snapshot_for_peer(1, now + 1))
	_check("reconnect snapshot reconciles a retained rejected Mark receipt exactly once",
		bool(reconnect_request.get("ok", false)) and not bool(setup_rejection.accepted)
		and String(setup_rejection.get("kind", "")) == "mark"
		and player.wayfinders_mark_pending().is_empty()
		and is_equal_approx(player.focus, player.focus_max)
		and is_equal_approx(float(player._skill_cooldowns.get(2, 0.0)), 0.0)
		and live_encounter._resubmitted_reservations.is_empty(),
		str({"request": reconnect_request, "receipt": setup_rejection}))

	# A host snapshot can legitimately retain the last receipt while a client
	# rebuilds its Player body. The replacement's first reservation must not
	# reuse the old body's token and accidentally accept that stale debit.
	var prior_token := int(player._wayfinders_mark_nonce)
	var replacement: CharacterBody3D = PlayerScene.instantiate()
	world.add_child(replacement)
	await physics_frame
	await physics_frame
	replacement.rebuild_skills()
	replacement.focus = replacement.focus_max
	var replacement_request: Dictionary = replacement.prepare_wayfinders_mark_request()
	_check("a recreated owner body cannot reuse a retained receipt's reservation token",
		bool(replacement_request.ok) and int(replacement_request.nonce) != prior_token,
		str({"prior": prior_token, "replacement": replacement_request}))
	replacement.cancel_wayfinders_mark("test_cleanup")
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


func _skill_names(player: CharacterBody3D) -> Array:
	var out: Array = []
	for skill in player.skills:
		out.append(String(skill.name))
	return out
