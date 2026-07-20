extends SceneTree

# D8 Slice 2 — production-scene acceptance coverage.  The reducer has its own
# exhaustive unit suite; this test mounts the shipped encounter adapter with
# the real Player, anchor, knot, and boss scripts so their physical/UI seams
# cannot silently drift from authority or Focus accounting.

const Encounter := preload("res://scripts/knot_eater_encounter.gd")
const KnotEater := preload("res://scripts/knot_eater.gd")
const Anchor := preload("res://scripts/knot_eater_anchor.gd")
const Knot := preload("res://scripts/knot_eater_knot.gd")
const PlayerScene := preload("res://scenes/Player.tscn")
const Progression := preload("res://data/progression.gd")

var passed := 0
var failed := 0


func check(label: String, ok: bool, detail: String = "") -> void:
	if ok:
		passed += 1
		print("  ✓ %s" % label)
	else:
		failed += 1
		print("  ✗ %s %s" % [label, detail])


func _initialize() -> void:
	await _run()


func _run() -> void:
	print("--- Knot-Eater production encounter acceptance ---")
	var game := root.get_node_or_null("Game")
	if game == null:
		check("Game autoload is present", false)
		quit(1)
		return
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.trades.huntcraft = {"xp": Progression.xp_for_level(22), "lv": 22}
	game.owned_skills = ["WayfindersMark"]
	game.loadout = ["WayfindersMark"]

	var world := Node3D.new()
	world.name = "KnotEaterEncounterAcceptanceWorld"
	root.add_child(world)
	var controller: Node3D = Encounter.new()
	world.add_child(controller)
	var player: CharacterBody3D = PlayerScene.instantiate()
	player.name = "EncounterOwner"
	player.position = Vector3.ZERO
	world.add_child(player)
	var eater: CharacterBody3D = KnotEater.new()
	eater.name = "KnotEater"
	eater.position = Vector3(0.0, 0.0, 7.0)
	world.add_child(eater)
	var anchors: Array = _build_anchors(world)
	var knots: Array = _build_knots(world)
	await physics_frame
	await physics_frame
	player.rebuild_skills()
	eater.setup(100, 0.5, 1.4)
	controller.configure(eater, anchors, knots)

	check("attempt begins in production Gnawing phase",
		controller.begin_attempt("chart-a", "attempt-a")
		and String(controller.view().phase) == "gnawing")
	var private_survival: Dictionary = controller.press(&"survival", &"")
	var private_exposure: Dictionary = controller.press(&"expose", &"knot_1")
	check("public press rejects private survival and exposure verbs",
		String(private_survival.reason) == "private_verb"
		and String(private_exposure.reason) == "private_verb")

	# Only boss aggro starts this private survival timer; no player packet can
	# skip it.  Calling _process directly keeps the acceptance check instant.
	eater.aggroed.emit()
	controller._process(5.9)
	check("boss aggro starts a six-second Gnawing survival timer",
		String(controller.view().phase) == "gnawing")
	controller._process(0.2)
	check("trusted host survival opens the physical anchor phase",
		String(controller.view().phase) == "anchors")

	player.global_position = Vector3(20.0, 0.0, 0.0)
	var too_far: Dictionary = controller.press(&"unbind", &"anchor_1")
	check("anchor unbind requires the owner body to be in range",
		not bool(too_far.accepted) and String(too_far.reason) == "anchor_unreachable")
	player.global_position = Vector3.ZERO
	var visible_anchor := anchors[0] as Node3D
	check("nearby anchor has clear production LOS",
		controller._in_anchor_range(player, visible_anchor)
		and controller._has_line_of_sight(player, visible_anchor))
	for id in [&"anchor_1", &"anchor_2", &"anchor_3"]:
		controller.press(&"unbind", id)
	var all_unbound := true
	for anchor in anchors:
		all_unbound = all_unbound and String(anchor.state) == "unbound" \
			and bool(anchor.is_used()) and not bool(anchor.monitoring) and not bool(anchor.visible)
	check("three valid physical anchor unbinds refresh their actor state",
		String(controller.view().phase) == "knots" and int(controller.view().anchor_mask) == 7
		and all_unbound)

	# Exposure is a host cadence, not an interactable scanner action.
	controller._process(3.3)
	check("host cadence exposes the first knot and refreshes its actor",
		String(controller.view().phase) == "reeling"
		and String(controller.view().active_knot_id) == "knot_1"
		and String((knots[0] as Node).get("state")) == "ready")

	for i in range(3):
		if i > 0:
			# Deterministic focused seam: production cooldown is 14 seconds, while
			# this acceptance test must prove all three distinct valid windows without
			# waiting 28 seconds.  Reset both owner UI cooldown and host ledger only.
			player._skill_cooldowns[2] = 0.0
			player.focus = player.focus_max
			_reset_host_mark_cooldown(controller, player.get_multiplayer_authority())
			controller._process(3.3)
		# Keep the owner's actual body beside each target; this makes the Mark
		# proof about the production reach/LOS adapter rather than incidental
		# collision from an already-unbound anchor prop.
		player.global_position = (knots[i] as Node3D).global_position + Vector3(0.8, 0.0, 0.8)
		var request: Dictionary = player.prepare_wayfinders_mark_request()
		var focus_before := float(player.focus)
		var receipt: Dictionary = controller.press(&"mark", &"")
		var marked_id := "knot_%d" % (i + 1)
		check("Mark %d reserves then debits exactly 35 Focus with its 14-second cooldown" % (i + 1),
			bool(request.ok) and bool(receipt.accepted)
			and is_equal_approx(float(player.focus), focus_before - 35.0)
			and player.wayfinders_mark_pending().is_empty()
			and is_equal_approx(float(player._skill_cooldowns.get(2, 0.0)), 14.0), str(receipt))
		check("Mark %d advances only the active physical knot" % (i + 1),
			String((knots[i] as Node).get("state")) == "marked"
			and (i == 2 or String(controller.view().phase) == "knots"), str(controller.view()))

	check("three real Mark receipts reach naming with all actor states refreshed",
		String(controller.view().phase) == "naming" and int(controller.view().knot_mask) == 7
		and String((knots[0] as Node).get("state")) == "marked"
		and String((knots[1] as Node).get("state")) == "marked"
		and String((knots[2] as Node).get("state")) == "marked")
	check("naming pacifies the nonlethal boss before the blocking choice",
		bool(eater._ritual_pacified) and eater.velocity == Vector3.ZERO)

	eater.hp = 2
	eater.hp_max = 100
	eater.take_damage(100, Vector3.FORWARD)
	check("positive damage floor keeps the Knot-Eater alive", not eater.dead and eater.hp == 1)
	var inert_death: Dictionary = controller.rules.dispatch({"kind": "death"}, controller._trusted_facts())
	check("boss death intent is inert and cannot disturb naming",
		not bool(inert_death.accepted) and String(inert_death.reason) == "boss_death_inert"
		and String(controller.view().phase) == "naming")
	var reset_ok: bool = bool(controller.reset_for_retry())
	var actors_reset := true
	for anchor in anchors:
		actors_reset = actors_reset and String(anchor.state) == "bound" \
			and not bool(anchor.is_used()) and bool(anchor.monitoring) and bool(anchor.visible)
	for knot in knots:
		actors_reset = actors_reset and String(knot.state) == "sealed"
	check("party retry resets reducer, physical actors, cadence, and boss together",
		reset_ok and String(controller.view().phase) == "gnawing" and actors_reset
		and not bool(eater._ritual_pacified) and eater.hp == eater.hp_max)
	eater.hp = 2
	eater.apply_status("burn", 1.0, 50, 1.0, 0.1)
	eater._tick_statuses(0.2)
	check("status damage shares the permanent positive floor", eater.hp == 1 and not eater.dead)
	eater.hp = 2
	eater.net_apply_state(eater.global_position, 0, ["burn"])
	check("replicated damage snapshots share the permanent positive floor",
		eater.hp == 1 and not eater.dead)

	print("--- %d passed, %d failed ---" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _build_anchors(world: Node3D) -> Array:
	var positions := [Vector3(-1.5, 0.0, 0.0), Vector3(0.0, 0.0, 1.5), Vector3(1.5, 0.0, -1.5)]
	var out: Array = []
	for i in range(3):
		var anchor: Area3D = Anchor.new()
		anchor.name = "Anchor%d" % (i + 1)
		anchor.anchor_id = "anchor_%d" % (i + 1)
		anchor.position = positions[i]
		world.add_child(anchor)
		out.append(anchor)
	return out


func _build_knots(world: Node3D) -> Array:
	var positions := [Vector3(4.0, 0.0, 4.0), Vector3(-4.0, 0.0, 4.0), Vector3(4.0, 0.0, -4.0)]
	var out: Array = []
	for i in range(3):
		var knot: Area3D = Knot.new()
		knot.name = "Knot%d" % (i + 1)
		knot.knot_id = "knot_%d" % (i + 1)
		knot.position = positions[i]
		world.add_child(knot)
		out.append(knot)
	return out


func _reset_host_mark_cooldown(controller: Node, peer_id: int) -> void:
	var ledger: Dictionary = controller.rules._peer_ledgers.get(peer_id, {}).duplicate(true)
	ledger["cooldown_until_ms"] = 0
	controller.rules._peer_ledgers[peer_id] = ledger
