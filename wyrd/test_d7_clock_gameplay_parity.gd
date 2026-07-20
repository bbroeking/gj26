extends SceneTree

# Spec 56 §10.1 — focused gameplay parity for D7's release-only 6x clock.
#
# This deliberately does not compare timers, frame counts, wall time, or the
# clock lease receipt.  It runs the same *production* representative path at
# each scale and compares only gameplay truth after the same simulation steps:
#
#   fresh-campaign report → real Player scanner receipt → Fire World settlement
#   → live Player status/cooldown/Threadstep result.
#
# The full D7 Web marathon remains the exported acceptance route.  Running it
# twice in a headless unit test would neither exercise the Web gate nor finish
# within a useful test budget.  This harness therefore owns the narrower
# requirement from §10.1: clock scale must not change the ordered Game report
# history/actual receipt, Hearth Giant floors and chain ledger, Player status
# duration/cooldown/Threadstep outcome, or canonical Fire settlement truth.

const CampaignData := preload("res://data/campaign.gd")
const Progression := preload("res://data/progression.gd")
const PlayerScene := preload("res://scenes/Player.tscn")
const PaleStairScript := preload("res://scripts/pale_stair.gd")

var _passed := 0
var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(label: String, ok: bool, detail: Variant = {}) -> void:
	if ok:
		_passed += 1
		print("  ✓ %s" % label)
	else:
		_failed += 1
		print("  ✗ %s %s" % [label, str(detail)])


func _run() -> void:
	print("--- D7 1x/6x production gameplay parity ---")
	var original_scale := Engine.time_scale
	var game := root.get_node_or_null("Game")
	if game == null:
		_check("Game autoload is present", false)
		await _finish(original_scale)
		return

	var one_x: Dictionary = await _run_production_path(game, 1.0)
	var six_x: Dictionary = await _run_production_path(game, 6.0)
	_check("both scale runs completed every production leg", bool(one_x.get("ok", false))
		and bool(six_x.get("ok", false)), {"one_x": one_x, "six_x": six_x})
	if bool(one_x.get("ok", false)) and bool(six_x.get("ok", false)):
		var normalized_one := one_x.get("snapshot", {}) as Dictionary
		var normalized_six := six_x.get("snapshot", {}) as Dictionary
		_check("1x and 6x preserve normalized D7 gameplay truth", normalized_one == normalized_six,
			{"one_x": normalized_one, "six_x": normalized_six})
		_check("phase history and actual scanner receipt came from Game/Player production seams",
			(normalized_one.get("phases", []) as Array) == ["fresh_campaign", "pale_stair_receipt", "fire_settlement", "complete"]
				and String((normalized_one.get("receipt", {}) as Dictionary).get("status", "")) == "actual"
				and bool((normalized_one.get("receipt", {}) as Dictionary).get("same_target", false))
				and bool((normalized_one.get("receipt", {}) as Dictionary).get("pale_stair_script", false))
				and String((normalized_one.get("receipt", {}) as Dictionary).get("expected_name", "")) == "D7ParityPaleStair"
				and String((normalized_one.get("receipt", {}) as Dictionary).get("actual_name", "")) == "D7ParityPaleStair",
			normalized_one)
		_check("Hearth Giant path records every heat floor, recoverable wrong bank, and all three real banks",
			(normalized_one.get("hearth", {}) as Dictionary).get("floor_fractions", []) == [0.75, 0.5, 0.25]
				and bool((normalized_one.get("hearth", {}) as Dictionary).get("wrong_recoverable", false))
				and (normalized_one.get("hearth", {}) as Dictionary).get("bank_masks", []) == [1, 3, 7]
				and bool((normalized_one.get("hearth", {}) as Dictionary).get("settled", false)),
			normalized_one.get("hearth", {}))
		_check("live Player retains equal status, cooldown, and Threadstep result",
			bool((normalized_one.get("player", {}) as Dictionary).get("threadstep_accepted", false))
				and int((normalized_one.get("player", {}) as Dictionary).get("burn_damage", 0)) == 2
				and not bool((normalized_one.get("player", {}) as Dictionary).get("burn_active", true))
				and is_equal_approx(float((normalized_one.get("player", {}) as Dictionary).get("cooldown", -1.0)), 7.0),
			normalized_one.get("player", {}))
		_check("canonical Fire settlement remains exact at both scales",
			bool((normalized_one.get("fire", {}) as Dictionary).get("cleared", false))
				and int((normalized_one.get("fire", {}) as Dictionary).get("wyrm_scale", 0)) == 1
				and int((normalized_one.get("fire", {}) as Dictionary).get("starheart_coal", -1)) == 0
				and bool((normalized_one.get("fire", {}) as Dictionary).get("ember_rune", false))
				and bool((normalized_one.get("fire", {}) as Dictionary).get("present_thread", false))
				and bool((normalized_one.get("fire", {}) as Dictionary).get("ember_kiln", false)),
			normalized_one.get("fire", {}))
	await _finish(original_scale)


func _run_production_path(game: Node, scale: float) -> Dictionary:
	# Each pass starts from a fresh mutable Game state.  The prior-chapter and
	# Fire-escrow fixtures below are the exact bounded prerequisites accepted by
	# test_fire_in_the_bough_world.gd; no outcome is injected.
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.persistence_enabled = false
	game.web_smoke_enabled = false
	# Game's report/history seam is production code, but the full D7 dispatcher
	# must remain off in this focused fixture: it correctly owns and rejects any
	# World that was not launched by its 50+ minute marathon.
	game.web_smoke_d7_enabled = false
	game.web_smoke_d5_enabled = false
	game.web_smoke_phase = ""
	game.web_smoke_history = []
	game.web_smoke_features = {}
	# This focused test models two independent smoke attempts on one autoload.
	# Production resets the latch in `_configure_web_smoke`; mirror that exact
	# attempt boundary here so the first pass's terminal payload cannot suppress
	# the second pass's otherwise-identical report history.
	game._web_smoke_terminal_latched = false
	game._web_smoke_terminal_payload = {}
	game.modal_count = 0
	paused = false
	Engine.time_scale = scale

	_record_game_phase(game, "fresh_campaign")
	# Mount the controller fixture before Town replaces the script tree's active
	# scene. This is the same empty-World3D ownership boundary as the established
	# live Threadstep test, rather than a navigation map left behind by Town.
	var player_truth: Dictionary = await _live_player_truth(game)
	if not bool(player_truth.get("ok", false)):
		await _cleanup_scene_and_audio()
		return {"ok": false, "reason": "live player", "scale": scale,
			"player": player_truth}
	var receipt: Dictionary = await _real_pale_stair_receipt(game)
	if receipt.is_empty() or bool(receipt.get("failed", false)):
		await _cleanup_scene_and_audio()
		return {"ok": false, "reason": "scanner receipt", "scale": scale,
			"receipt": receipt}
	_record_game_phase(game, "pale_stair_receipt")

	var hearth_truth: Dictionary = await _real_fire_world_settlement(game)
	if not bool(hearth_truth.get("ok", false)):
		await _cleanup_scene_and_audio()
		return {"ok": false, "reason": "fire world", "scale": scale,
			"hearth": hearth_truth}
	_record_game_phase(game, "fire_settlement")
	_record_game_phase(game, "complete")

	var snapshot := {
		"phases": (game.web_smoke_history as Array).duplicate(),
		"receipt": receipt,
		"hearth": hearth_truth.get("hearth", {}),
		"player": player_truth.get("player", {}),
		"fire": hearth_truth.get("fire", {}),
	}
	await _cleanup_scene_and_audio()
	return {"ok": true, "snapshot": snapshot}


func _real_pale_stair_receipt(game: Node) -> Dictionary:
	change_scene_to_file("res://scenes/Town.tscn")
	await process_frame
	await process_frame
	var scene := current_scene
	var player := game.local_player() as Node3D
	if scene == null or player == null:
		return {}
	var stair: Node3D = PaleStairScript.new()
	stair.name = "D7ParityPaleStair"
	stair.set_campaign_settlement_view({"canonical_queen": true, "pale_stair": true})
	scene.add_child(stair)
	stair.global_position = player.global_position + Vector3(2.0, 0.0, 0.0)
	await physics_frame
	await process_frame
	# This deliberately uses the shipped scanner/InputMap driver.  Calling the
	# stair read directly would bypass the receipt under comparison.
	player.set("_active_interactable", null)
	var opened := bool(await game._d5_scanner_interact(stair))
	var raw: Dictionary = player.call("last_interact_receipt") if opened else {}
	var expected_type: String = raw.get("expected").get_class() if raw.get("expected") != null else ""
	var actual_type: String = raw.get("actual").get_class() if raw.get("actual") != null else ""
	var expected_name: String = String(raw.get("expected").name) if raw.get("expected") != null else ""
	var actual_name: String = String(raw.get("actual").name) if raw.get("actual") != null else ""
	var pale_stair_script: bool = raw.get("expected") != null and raw.get("actual") != null \
		and raw.get("expected").get_script() == PaleStairScript \
		and raw.get("actual").get_script() == PaleStairScript
	var same_target: bool = raw.get("expected") == raw.get("actual")
	var dialog := get_first_node_in_group("PaleStairDialog")
	if dialog != null and dialog.has_method("_finish"):
		dialog.call("_finish")
	await process_frame
	if is_instance_valid(stair):
		stair.queue_free()
	await process_frame
	if not opened or String(raw.get("status", "")) != "actual" \
			or expected_type.is_empty() or actual_type.is_empty() or not same_target:
		return {"failed": true, "opened": opened, "raw": raw,
			"phase": game.web_smoke_phase, "stage": game._web_smoke_d5_stage}
	# Object IDs and instance references vary by pass; preserve only the receipt
	# truth that is meaningful across scale, never a clock/timestamp surrogate.
	return {
		"status": String(raw.get("status", "")),
		"expected_type": expected_type,
		"actual_type": actual_type,
		"expected_name": expected_name,
		"actual_name": actual_name,
		"pale_stair_script": pale_stair_script,
		"same_target": same_target,
	}


func _live_player_truth(game: Node) -> Dictionary:
	game.owned_skills = ["Threadstep"]
	game.loadout = ["Threadstep"]
	var host := Node3D.new()
	host.name = "D7ParityPlayerHost"
	root.add_child(host)
	_build_navigation(host)
	_add_probe_wall(host, Vector3(0.0, 0.9, -2.5))
	var player: CharacterBody3D = PlayerScene.instantiate()
	host.add_child(player)
	var nav_synced := await _wait_for_navigation_map_sync(host, 1500)
	player.rebuild_skills()
	player.global_position = Vector3(10.0, 0.0, 0.0)
	player.focus = player.focus_max
	var focus_before := float(player.focus)
	var probe_before: Dictionary = player._threadstep_probe(player.global_position,
		Vector3.FORWARD, float(player.THREADSTEP_MAX_DISTANCE))
	var threadstep_accepted := bool(player.try_threadstep(Vector3.FORWARD))
	var endpoint := Vector3(10.0, 0.0, 0.0) + Vector3.FORWARD * float(player.THREADSTEP_MAX_DISTANCE)
	var endpoint_reached := player.global_position.distance_to(endpoint) < 0.01
	var focus_spent := int(round(focus_before - float(player.focus)))
	# These are ordinary controller ticks over one *simulation* second.  Keeping
	# the simulated duration fixed is what parity means when the runner's wall
	# time is deliberately accelerated; no field below contains elapsed time.
	var hp_before := int(player.hp)
	player.apply_status("burn", 1.0, 1, 1.0, 0.5)
	player._physics_process(0.5)
	player._physics_process(0.5)
	var cooldown := _threadstep_cooldown(player)
	var truth := {
		"ok": nav_synced and bool(probe_before.get("ok", false)) and threadstep_accepted and endpoint_reached,
		"player": {
			"threadstep_accepted": threadstep_accepted,
			"focus_spent": focus_spent,
			"endpoint_reached": endpoint_reached,
			"cooldown": cooldown,
			"burn_damage": hp_before - int(player.hp),
			"burn_active": player.has_status("burn"),
		},
		"debug": {"nav_synced": nav_synced,
			"nav_iteration": _navigation_map_iteration(host),
			"endpoint": player.global_position, "probe": probe_before,
			"probe_diagnostic": _probe_diagnostic(player)},
	}
	host.queue_free()
	# NavigationServer unregisters its region on a later physics edge. Drain it
	# before the other scale builds its fresh map; otherwise an old region can
	# make a valid five-metre segment look like a detour on the second pass.
	for _frame in 3:
		await physics_frame
	return truth


func _real_fire_world_settlement(game: Node) -> Dictionary:
	game.campaign_state = _prior_pale_state()
	game.materials = {}
	game.trades.wayfinding = {"xp": Progression.xp_for_level(21), "lv": 21}
	game.trades.huntcraft = {"xp": Progression.xp_for_level(21), "lv": 21}
	var fire: Dictionary = game.campaign_state.chapters[CampaignData.FIRE_IN_THE_BOUGH]
	fire.clue_count = 5
	for i in 5:
		fire.banked_chart_ids.append("d7-parity-verse-%d" % i)
	game.campaign_state = CampaignData.normalize_campaign_state(game.campaign_state)
	game._sync_campaign_chart_sources()

	var chart_id := "d7-parity-fire-chart"
	var begun: Dictionary = CampaignData.begin_boss_escrow(game.campaign_state, chart_id,
		CampaignData.FIRE_IN_THE_BOUGH)
	if not bool(begun.get("ok", false)):
		return {"ok": false, "reason": "escrow", "begun": begun}
	var entered: Dictionary = CampaignData.mark_escrow_in_run(begun.state,
		String(begun.attempt_id), chart_id, CampaignData.FIRE_IN_THE_BOUGH)
	game.campaign_state = entered.state
	game.materials = {"starheart_coal": 3}
	game.active_chart = {
		"template_id": "fire_in_the_bough_boss", "recipe_id": "fire_in_the_bough_boss",
		"chart_instance_id": chart_id, "attempt_id": String(begun.attempt_id),
		"tier": 3, "scope": "ashen_bough", "name": "Fire in the Bough",
		"seed": 212300, "affixes": [],
		"campaign_contract": CampaignData.boss_contract("fire_in_the_bough_boss"),
	}
	game.in_dungeon = true
	var packed: PackedScene = load("res://scenes/World.tscn")
	var world := packed.instantiate() if packed != null else null
	if world == null:
		return {"ok": false, "reason": "World instantiate"}
	root.add_child(world)
	await process_frame
	await process_frame
	await physics_frame
	var giant: Node3D = null
	for enemy in get_nodes_in_group("enemy"):
		if String(enemy.get("kind")) == "hearth_giant":
			giant = enemy as Node3D
			break
	var controller := world.get_node_or_null("HearthGiantEncounter")
	var player := game.local_player() as Node3D
	if giant == null or controller == null or player == null:
		world.queue_free()
		await process_frame
		return {"ok": false, "reason": "Fire fixture nodes"}

	var floors: Array = []
	var floor_fractions: Array = []
	var masks: Array = []
	var wrong_recoverable := false
	var banks_ok := true
	for phase in 3:
		giant.take_damage(99999, Vector3.FORWARD)
		floors.append(int(giant.get("hp")))
		floor_fractions.append(snappedf(float(giant.get("hp")) / float(giant.get("hp_max")), 0.01))
		var expected_id := String(controller.CHAIN_ORDER[phase])
		if phase == 0:
			var wrong_id := String(controller.CHAIN_ORDER[1])
			var wrong_chain: Node3D = controller.chains[wrong_id]
			player.global_position = wrong_chain.global_position
			var mask_before := int(controller.bank_mask)
			wrong_recoverable = not bool(controller.request_chain_bank(wrong_id, chart_id,
				String(begun.attempt_id), player)) and int(controller.bank_mask) == mask_before
		var expected_chain: Node3D = controller.chains[expected_id]
		player.global_position = expected_chain.global_position
		banks_ok = bool(controller.request_chain_bank(expected_id, chart_id,
			String(begun.attempt_id), player)) and banks_ok
		masks.append(int(controller.bank_mask))
		await process_frame
	await process_frame
	var state: Dictionary = game.campaign_state
	var fire_chapter: Dictionary = state.chapters[CampaignData.FIRE_IN_THE_BOUGH]
	var hearth := {
		"floors": floors,
		"floor_fractions": floor_fractions,
		"wrong_recoverable": wrong_recoverable,
		"bank_masks": masks,
		"settled": banks_ok and bool(giant.get("kneeling")) and bool(controller.settled),
	}
	var settlement := {
		"cleared": bool(fire_chapter.get("cleared", false)),
		"wyrm_scale": game.material_count("wyrm_scale"),
		"starheart_coal": game.material_count("starheart_coal"),
		"ember_rune": (state.relics as Array).has("ember_root_rune"),
		"present_thread": (state.threads as Array).has("present_thread"),
		"ember_kiln": (state.restorations as Array).has("ember_kiln"),
	}
	world.queue_free()
	# The generated Fire layout contributes hundreds of navigation regions.
	# NavigationServer removes those on later physics edges, not when queue_free
	# is called. Drain their real teardown before the next scale owns a fresh
	# controller map; otherwise its valid local region can query the retiring
	# Fire map instead.
	for _frame in 16:
		await physics_frame
	return {"ok": bool(hearth.settled) and bool(settlement.cleared),
		"hearth": hearth, "fire": settlement}


func _prior_pale_state() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id in [CampaignData.FIRST_KNOT, CampaignData.GOLDEN_WALLOW,
			CampaignData.SEVENTH_ROAD, CampaignData.QUEENS_SUMMIT, CampaignData.PALE_OATH]:
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
		for i in int(chapter.clue_count):
			chapter.banked_chart_ids.append("d7-parity-%s-%d" % [chapter_id, i])
	state.relics = ["green_root_rune", "mist_root_rune", "fang_root_rune",
		"crown_root_rune", "pale_root_rune"]
	state.threads = ["past_thread"]
	state.restorations = ["trophy_hall", "sallow_jetty", "skald_archive",
		"pale_stair", "rootroad_lift"]
	return CampaignData.normalize_campaign_state(state)


func _build_navigation(host: Node3D) -> void:
	var navmesh := NavigationMesh.new()
	navmesh.vertices = PackedVector3Array([
		Vector3(-2.0, 0.05, -8.0), Vector3(-2.0, 0.05, 8.0),
		Vector3(22.0, 0.05, 8.0), Vector3(22.0, 0.05, -8.0),
	])
	navmesh.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	var region := NavigationRegion3D.new()
	region.name = "D7ParityNavigation"
	region.navigation_mesh = navmesh
	host.add_child(region)
	var floor := StaticBody3D.new()
	floor.name = "D7ParityNavigationFloor"
	floor.position = Vector3(10.0, -0.5, 0.0)
	var floor_collision := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(48.0, 1.0, 24.0)
	floor_collision.shape = floor_shape
	floor.add_child(floor_collision)
	host.add_child(floor)


func _add_probe_wall(host: Node3D, position: Vector3) -> void:
	# Mirrors the established live Threadstep fixture: the wall is deliberately
	# far from the accepted x=10 lane but makes the World3D collision registration
	# explicit while retaining the controller's real capsule query.
	var wall := StaticBody3D.new()
	wall.name = "D7ParityThreadstepWall"
	wall.position = position
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.2, 1.8, 0.6)
	collision.shape = shape
	wall.add_child(collision)
	host.add_child(wall)


func _navigation_map_iteration(host: Node3D) -> int:
	var world := host.get_world_3d()
	if world == null:
		return -1
	var nav_map: RID = world.navigation_map
	if not nav_map.is_valid():
		return -1
	return NavigationServer3D.map_get_iteration_id(nav_map)


func _wait_for_navigation_map_sync(host: Node3D, timeout_ms: int) -> bool:
	var deadline_ms := Time.get_ticks_msec() + maxi(1, timeout_ms)
	var observed_iteration := -1
	# Navigation registration is asynchronous; use real time only for this
	# readiness guard, never as a gameplay result or normalized snapshot field.
	while Time.get_ticks_msec() < deadline_ms:
		await physics_frame
		var iteration := _navigation_map_iteration(host)
		if iteration <= 0:
			continue
		if observed_iteration >= 0 and iteration > observed_iteration:
			var world := host.get_world_3d()
			var nav_map: RID = world.navigation_map if world != null else RID()
			if nav_map.is_valid():
				var origin := Vector3(10.0, 0.0, 0.0)
				var endpoint := origin + Vector3.FORWARD * 5.0
				# A retiring generated World can bump the shared map revision before
				# this fixture's region registers. Require actual closest points on
				# both ends of the real five-metre lane, not a guessed frame count.
				if NavigationServer3D.map_get_closest_point(nav_map, origin).distance_to(origin) <= 0.18 \
						and NavigationServer3D.map_get_closest_point(nav_map, endpoint).distance_to(endpoint) <= 0.18:
					return true
		observed_iteration = iteration
	return false


func _threadstep_cooldown(player: Node) -> float:
	for i in range(1, player.skills.size() + 1):
		if String(player.skills[i - 1].name) == "Threadstep":
			return float(player._skill_cooldowns.get(i, -1.0))
	return -1.0


func _record_game_phase(game: Node, phase: String) -> void:
	# Scene-ready callbacks must not be allowed to start an unrelated D5/D7
	# release driver while this focused test mounts its own Town and World. The
	# report itself remains the shipped Game method and is the only writer of the
	# phase history being compared.
	game.web_smoke_enabled = true
	game.web_smoke_report(phase)
	game.web_smoke_enabled = false


func _probe_diagnostic(player: CharacterBody3D) -> Dictionary:
	var world := player.get_world_3d()
	if world == null:
		return {"world": false}
	var nav_map: RID = world.navigation_map
	if not nav_map.is_valid():
		return {"map": false}
	var origin := player.global_position
	var endpoint := origin + Vector3.FORWARD * float(player.THREADSTEP_MAX_DISTANCE)
	var nav_origin := NavigationServer3D.map_get_closest_point(nav_map, origin)
	var nav_endpoint := NavigationServer3D.map_get_closest_point(nav_map, endpoint)
	var max_sample_distance := 0.0
	for i in range(1, 25):
		var sample := origin.lerp(endpoint, float(i) / 25.0)
		max_sample_distance = maxf(max_sample_distance,
			sample.distance_to(NavigationServer3D.map_get_closest_point(nav_map, sample)))
	var path := NavigationServer3D.map_get_path(nav_map, nav_origin, nav_endpoint, true)
	var path_length := 0.0
	for i in range(1, path.size()):
		path_length += path[i - 1].distance_to(path[i])
	return {"iteration": NavigationServer3D.map_get_iteration_id(nav_map),
		"origin_distance": origin.distance_to(nav_origin),
		"endpoint_distance": endpoint.distance_to(nav_endpoint),
		"sample_distance": max_sample_distance,
		"path_size": path.size(), "path_length": path_length,
		"test_move": player.test_move(player.global_transform, endpoint - origin)}


func _cleanup_scene_and_audio() -> void:
	if current_scene != null and is_instance_valid(current_scene):
		current_scene.queue_free()
	await process_frame
	# Timers are process-always so cleanup remains correct while a production
	# dialog is yielding or after a 6x pass.
	await create_timer(0.05, true, false, true).timeout


func _finish(original_scale: float) -> void:
	Engine.time_scale = original_scale
	var game := root.get_node_or_null("Game")
	if game != null:
		game.web_smoke_enabled = false
		game.web_smoke_d7_enabled = false
		game.web_smoke_d5_enabled = false
		game.modal_count = 0
	paused = false
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("shutdown"):
		sfx.call("shutdown")
	await create_timer(0.15, true, false, true).timeout
	print("--- D7 1x/6x production gameplay parity: %d PASS, %d FAIL ---" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)
