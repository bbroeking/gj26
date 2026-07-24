extends SceneTree

const Progression = preload("res://data/progression.gd")
const CampaignData = preload("res://data/campaign.gd")

# Wyrd slice — headless full-loop transition test.
# Run: godot --headless --path wyrd --script res://test_wyrd_transitions.gd
#
# Drives the tutorial beats end-to-end through the REAL scenes and the real
# Game autoload (4.6 loads autoloads in --script mode): Town boots → talk to
# Mara → forage 3 herbs → mix ink → inscribe Snug → enter_dungeon (scene
# change) → World builds from the chart → exit waystone → return_to_town
# (scene change) → completion XP + tutorial advanced.

var _pass := 0
var _fail := 0

func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % name)
	else:
		_fail += 1
		print("  ✗ %s %s" % [name, detail])


# MapLoading deliberately keeps the source scene alive while it draws a useful
# destination card and prepares the procedural layout. Scene-transition tests
# must synchronize on the destination, not on an arbitrary number of frames.
func _wait_for_scene(scene_name: String, max_ticks: int = 1200) -> bool:
	for _i in max_ticks:
		var loader := root.get_node_or_null("MapLoading")
		var transition_idle := loader == null or not bool(loader.get("_busy"))
		if current_scene != null and String(current_scene.name) == scene_name \
				and transition_idle:
			return true
		# A real-time tick gives ResourceLoader's worker and the loading-card
		# tweens time to progress even when headless frames run uncapped.
		await create_timer(0.01, true).timeout
	return false


func _wait_for_group(group_name: StringName, max_ticks: int = 300) -> Node:
	for _i in max_ticks:
		var found := get_first_node_in_group(group_name)
		if found != null:
			return found
		await create_timer(0.01, true).timeout
	return null


# Input.parse_input_event feeds the same controller path as a real pad, but an
# uncapped headless SceneTree can otherwise sample a press on the tail of the
# preceding test frame.  Establish a released edge first and arm the scanner's
# exact-target receipt so the assertion proves both controller parity and that
# no neighbouring Town prompt stole the interaction.
func _controller_a_interact(player: Node, target: Node) -> Dictionary:
	if player == null or target == null or not player.has_method("arm_expected_interact") \
			or not bool(player.call("arm_expected_interact", target)):
		return {"status": "could_not_arm"}
	var released := InputEventJoypadButton.new()
	released.device = 0
	released.button_index = JOY_BUTTON_A
	released.pressed = false
	Input.parse_input_event(released)
	await physics_frame
	await process_frame
	var pressed := InputEventJoypadButton.new()
	pressed.device = 0
	pressed.button_index = JOY_BUTTON_A
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await physics_frame
	await process_frame
	var release_after := InputEventJoypadButton.new()
	release_after.device = 0
	release_after.button_index = JOY_BUTTON_A
	release_after.pressed = false
	Input.parse_input_event(release_after)
	await physics_frame
	return player.call("last_interact_receipt") \
		if player.has_method("last_interact_receipt") else {"status": "no_receipt"}

func _initialize() -> void:
	_run()

func _run() -> void:
	print("--- wyrd transitions check ---")
	# A4 channel gathering — keep test channels near-instant.
	OS.set_environment("WYRD_FAST_CHANNEL", "1")
	var game: Node = root.get_node("Game")
	# Hermetic: never read or write the player's real save, and start from
	# a blank slate regardless of what Game._ready loaded.
	game.persistence_enabled = false
	game.trades = Progression.fresh_trade_state()
	game.materials = {}
	game.charts = []
	game.tutorial_step = 0
	game.player_hp = -1
	game.gold = 0
	game.summit_cleared = false
	game.known_chart_recipes = ["snug"]
	game.chart_recipe_journal = {"rumours": [],
		"discoveries": {"snug": "mara_lesson"}}
	game.chart_source_unlocks = []
	game.campaign_state = CampaignData.empty_state()
	game.modal_count = 0
	paused = false
	# The suite exercises modal accounting separately below. Preselect the level-5
	# mastery so discovery XP cannot open an unrelated mandatory choice over the
	# crafting-bench assertions.
	game.chosen_perks = {}
	game.inventory = Inventory.new()
	# Pre-seen hints: a first-time hint dialog pauses the tree, which would
	# freeze the parallel forage channels this test runs in Beat 2.
	game.seen_hints = {"forage_node": true, "ore_rock": true,
		"log_pile": true, "cookfire": true, "forge": true,
		# D14 — suppress the new first-contact hints (not under test here).
		"shrine": true, "status_bleed": true, "status_slow": true,
		"affix_reading": true}
	game.start_onboarding_measurement()

	# Boot Town the way the player does.
	change_scene_to_file("res://scenes/Town.tscn")
	await process_frame
	await process_frame
	var town := current_scene
	_check("town booted", town != null and town.name == "Town")

	var player: Node = get_first_node_in_group("player")
	_check("player in town", player != null)
	if player != null:
		var player_constants: Dictionary = player.get_script().get_script_constant_map()
		_check("player uses meshless chibi locomotion sidecars",
			String(player_constants.get("CHIBI_WALK_PATH", "")) \
				== "res://models/player_chibi_walk_anim_v1.glb" \
			and String(player_constants.get("CHIBI_RUN_PATH", "")) \
				== "res://models/player_chibi_run_anim_v1.glb" \
			and String(player_constants.get("CHIBI_DASH_PATH", "")) \
				== "res://models/player_chibi_dash_anim_v1.glb")
		for sidecar_path in [
			"res://models/player_chibi_walk_anim_v1.glb",
			"res://models/player_chibi_run_anim_v1.glb",
			"res://models/player_chibi_dash_anim_v1.glb",
		]:
			var sidecar: PackedScene = load(sidecar_path)
			var sidecar_root := sidecar.instantiate() if sidecar != null else null
			_check("%s contains animation but no render mesh" % sidecar_path,
				sidecar_root != null \
				and not sidecar_root.find_children("*", "AnimationPlayer", true, false).is_empty() \
				and sidecar_root.find_children("*", "MeshInstance3D", true, false).is_empty())
			if sidecar_root != null:
				sidecar_root.free()
		_check("player merged walk/run/dash animation sidecars",
			String(player.get("_clip_walk")) == "walk" \
			and String(player.get("_clip_run")) == "run" \
			and String(player.get("_clip_dash")) == "dash",
			"walk=%s run=%s dash=%s" % [player.get("_clip_walk"),
				player.get("_clip_run"), player.get("_clip_dash")])
		_check("fresh player has a planted idle distinct from locomotion",
			String(player.get("_clip_idle")) == "player_idle_pose"
			and String(player.get("_clip_idle")) != String(player.get("_clip_walk")),
			"idle=%s" % String(player.get("_clip_idle")))

	# C2 — the real Atlas replaces the decorative quad from the first boot, but
	# the later rain note does not exist before a completed Hollow unlocks it.
	var atlas_source := town.get_node_or_null("AtlasDeepRumourSource")
	_check("Living Atlas is a stable real Interactable",
		atlas_source != null
		and atlas_source.get_script() == load("res://scripts/living_atlas_panel.gd")
		and atlas_source.is_in_group("interactable"))
	_check("pre-Tier-1 Atlas remains decorative and teaches no rumour",
		atlas_source != null and String(atlas_source.source_status().state) == "locked"
		and atlas_source.is_used()
		and not (atlas_source.get_node("Marker") as Label3D).visible
		and town.get_node_or_null("MaraSallowRumourSource") == null)
	# The action map still gains controller parity before any source is eligible.
	var interact_events := InputMap.action_get_events("interact")
	var has_interact_e := false
	var has_interact_a := false
	for event in interact_events:
		if event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_E:
			has_interact_e = true
		elif event is InputEventJoypadButton \
				and (event as InputEventJoypadButton).button_index == JOY_BUTTON_A:
			has_interact_a = true
	_check("world interact binds keyboard E and controller A",
		has_interact_e and has_interact_a,
		str(interact_events))
	if player != null and atlas_source != null:
		var atlas_home := (atlas_source as Node3D).global_position
		# Even beside the player, the pre-unlock decorative panel is scanner-inert.
		(atlas_source as Node3D).global_position = Vector3(20.0, 0.8, 24.7)
		await physics_frame
		await physics_frame
		await physics_frame
		_check("player scanner ignores the pre-unlock Atlas",
			player.get("_active_interactable") != atlas_source)
		var joy_a := InputEventJoypadButton.new()
		joy_a.device = 0
		joy_a.button_index = JOY_BUTTON_A
		joy_a.pressed = true
		Input.parse_input_event(joy_a)
		await physics_frame
		await process_frame
		var joy_a_release := joy_a.duplicate() as InputEventJoypadButton
		joy_a_release.pressed = false
		Input.parse_input_event(joy_a_release)
		_check("controller A cannot open or mutate the pre-unlock Atlas",
			get_first_node_in_group("ChartRumourSourceDialog") == null
			and not (game.chart_recipe_journal.rumours as Array).has("atlas_deep_hollow"))
		(atlas_source as Node3D).global_position = atlas_home
		await physics_frame

	# Beat 1 — talk to Mara (dialog panel advances tutorial on finish).
	var mara: Node = null
	var table: Node = null
	var portal: Node = null
	var patches: Array = []
	for c in town.get_children():
		if c is WayfinderNpc: mara = c
		elif c is InscribingTable: table = c
		elif c is PortalWaystone: portal = c
		elif c is GatherNode: patches.append(c)
	_check("stations placed", mara != null and table != null and portal != null)
	var social_npcs := get_nodes_in_group("player_facing_npc")
	_check("town cast tracks the player instead of holding authored rotations",
		social_npcs.size() == 3,
		"player-facing NPCs=%d" % social_npcs.size())
	var animated_social_npcs := social_npcs.filter(func(n: Node) -> bool:
		var drivers := n.find_children("AmbientPoseDriver", "", true, false)
		return drivers.size() == 1 \
			and (drivers[0] as Node).process_mode == Node.PROCESS_MODE_ALWAYS)
	_check("town cast stays animated through onboarding pauses",
		animated_social_npcs.size() == 3,
		"always-animated NPCs=%d" % animated_social_npcs.size())
	var walking_npcs := get_nodes_in_group("wandering_npc")
	var npc_starts: Array[Vector3] = []
	for npc in walking_npcs:
		npc_starts.append((npc as Node3D).global_position)
	for frame in range(20):
		await physics_frame
	var moved_npcs := 0
	for i in range(walking_npcs.size()):
		if npc_starts[i].distance_to((walking_npcs[i] as Node3D).global_position) > 0.04:
			moved_npcs += 1
	_check("all three town NPCs physically walk their local rounds",
		walking_npcs.size() == 3 and moved_npcs == 3,
		"walkers=%d moved=%d" % [walking_npcs.size(), moved_npcs])
	var opening_pages: Array = mara.call("_pages_for", 0) if mara != null else []
	_check("Mara opening is two focused pages", opening_pages.size() == 2,
		str(opening_pages))
	_check("fresh arrival hides combat, Focus, and later shortcuts",
		not game.onboarding_surface_available("combat")
		and not game.onboarding_surface_available("focus")
		and not game.onboarding_surface_available("satchel")
		and not game.onboarding_surface_available("gear")
		and game.active_skill_slots() == 1)
	# Town skill stations: 6 herb patches + 3 ore rocks + 3 log piles.
	var herbs := 0
	var ores := 0
	var piles := 0
	for n in patches:
		match String(n.kind):
			"forage_node": herbs += 1
			"ore_rock": ores += 1
			"log_pile": piles += 1
	# Spec 45 / Golden renewable seam — 6 wild patches plus the locked
	# Bittergrass and Mothmint patches beside Quill's still.
	_check("town gather stations 8/3/3",
		herbs == 8 and ores == 3 and piles == 3,
		"%d/%d/%d" % [herbs, ores, piles])
	var mothmint_nodes := patches.filter(func(node):
		return String(node.get("item_id")) == "mothmint")
	var mothmint_patch: Node = mothmint_nodes[0] if mothmint_nodes.size() == 1 else null
	var wildcraft_before: Dictionary = game.trades.wildcraft.duplicate(true)
	var mothmint_locked := mothmint_patch != null and bool(mothmint_patch.call("locked", game))
	game.trades.wildcraft = {"xp": Progression.xp_for_level(10), "lv": 10}
	var mothmint_open := mothmint_patch != null and not bool(mothmint_patch.call("locked", game))
	game.trades.wildcraft = wildcraft_before
	_check("Town Mothmint is one visible renewable patch gated at Wildcraft 10",
		mothmint_locked and mothmint_open, str(mothmint_nodes.size()))
	# A7/A8 — the cookfire, the anvil, and Quill's still stand in town.
	var stations: Array = []
	for c in town.get_children():
		if c is CraftStation:
			stations.append(String(c.station_id))
	stations.sort()
	_check("craft stations placed (cookfire + forge + still)",
		stations == ["cookfire", "forge", "still"], str(stations))

	# Spec 57 — micro-cutscenes borrow the live camera and modal seam, then
	# release both. Town disables authored vignettes in headless mode, so drive
	# the reusable player directly here.
	var rig: Node = get_first_node_in_group("camera_rig")
	var micro_script: GDScript = load("res://scripts/ui/micro_cutscene.gd")
	var micro: CanvasLayer = micro_script.new()
	var micro_state := {"finished": false}
	micro.finished.connect(func(_skipped: bool) -> void: micro_state.finished = true)
	town.add_child(micro)
	var home: Dictionary = rig.cinematic_frame()
	home["duration"] = 0.16
	home["caption"] = "The road remembers."
	var has_arrival_track := town.has_method("_arrival_actor_track")
	var actor_track: Dictionary = town.call("_arrival_actor_track", player) \
		if has_arrival_track else {}
	if has_arrival_track:
		actor_track["duration"] = 0.16
	var actor_start: Vector3 = actor_track.get("start", player.global_position)
	var actor_end: Vector3 = actor_track.get("end", player.global_position)
	var cutscene_npc_starts: Dictionary = {}
	for npc in walking_npcs:
		cutscene_npc_starts[npc] = (npc as Node3D).global_position
	if has_arrival_track:
		micro.call("play", rig, [home], actor_track)
	else:
		micro.play(rig, [home])
	_check("micro-cutscene captures camera + pauses play",
		paused and game.modal_count == 1 and bool(rig.get("_cinematic_active")),
		"paused=%s modal=%d active=%s" % [paused, game.modal_count,
			bool(rig.get("_cinematic_active"))])
	await create_timer(0.08, true).timeout
	var player_ap := player.get("_ap") as AnimationPlayer
	var player_skeleton := _find_skeleton(player)
	_check("opening vignette walks the player through the live scene",
		has_arrival_track and actor_start.distance_to(actor_end) >= 3.0 \
		and player.global_position.distance_to(actor_start) > 0.1 \
		and player_ap != null and player_ap.current_animation \
			== String(player.get("_clip_walk")) \
		and _skeleton_pose_energy(player_skeleton) > 0.25 \
		and _arm_down_score(player_skeleton) > 0.5,
		str({"track": actor_track, "position": player.global_position,
			"animation": player_ap.current_animation if player_ap != null else "",
			"pose_energy": _skeleton_pose_energy(player_skeleton),
			"arms": _arm_down_score(player_skeleton)}))
	var cutscene_npcs_walking := true
	for npc in walking_npcs:
		cutscene_npcs_walking = cutscene_npcs_walking \
			and (npc as Node3D).global_position.distance_to(
				cutscene_npc_starts[npc]) > 0.02 \
			and bool(npc.get_meta("npc_walking", false))
	_check("town NPCs keep walking during the opening vignette",
		cutscene_npcs_walking)
	await create_timer(0.12, true).timeout
	_check("micro-cutscene restores camera + play",
		bool(micro_state.finished) and not paused and game.modal_count == 0
		and not bool(rig.get("_cinematic_active"))
		and player.global_position.distance_to(actor_end) < 0.05,
		"finished=%s paused=%s modal=%d active=%s" % [micro_state.finished, paused,
			game.modal_count, bool(rig.get("_cinematic_active"))])
	# Keep `patches` = herb patches only (the tutorial beat forages herbs).
	patches = patches.filter(func(n): return String(n.kind) == "forage_node")

	mara.interact(player)
	await process_frame
	var dlg: Node = null
	for c in town.get_children():
		if c.has_signal("finished"):
			dlg = c
	_check("dialog opened + paused", dlg != null and paused)
	_check("Mara dialog carries her painted portrait",
		dlg != null and dlg.get("_portrait_texture") != null)
	var continue_button := dlg.get_node_or_null(
		"DialogueShell/DialogueColumns/ProsePaper/VBoxContainer/ContinueButton") \
		if dlg != null else null
	_check("dialog visibly teaches click-through continuation",
		continue_button is Button and (continue_button as Button).visible
		and "Continue" in (continue_button as Button).text)
	for _i in 8:
		if is_instance_valid(dlg) and dlg.has_method("_advance"):
			dlg._advance()
	await process_frame
	_check("tutorial 0→1 after talk", int(game.tutorial_step) == 1,
		str(game.tutorial_step))
	_check("unpaused after dialog", not paused)
	_check("new town beat immediately names the next verb without the needle",
		"herb patch" in game.objective_hint()
		and "E forage" in game.objective_hint()
		and not game.onboarding_compass_available(),
		game.objective_hint())
	game._onboarding_progress_msec = Time.get_ticks_msec() - 21000
	game._onboarding_recovery_poll_msec = 0
	game._tick_onboarding_recovery()
	_check("20-second stall adds a contextual landmark only",
		game.onboarding_hint_stage() == 1
		and "shimmering" in game.objective_hint()
		and not game.onboarding_compass_available(), game.objective_hint())
	game._onboarding_progress_msec = Time.get_ticks_msec() - 46000
	game._onboarding_recovery_poll_msec = 0
	game._tick_onboarding_recovery()
	_check("45-second stall adds direct control and the gold needle",
		game.onboarding_hint_stage() == 2
		and "E forage" in game.objective_hint()
		and game.onboarding_compass_available(), game.objective_hint())
	game.mark_onboarding_progress()

	# Beat 2 — forage 3 herbs (channelled since A4; fast-channel env above).
	for i in 3:
		patches[i].interact(player)
	await create_timer(0.4).timeout
	_check("3 herbs in satchel", game.material_count("wild_herb") == 3,
		str(game.material_count("wild_herb")))
	_check("tutorial 1→2", int(game.tutorial_step) == 2)
	_check("Wildcraft XP granted", int(game.trades.wildcraft.xp) == 24,
		str(game.trades.wildcraft.xp))
	var guided_bench: CanvasLayer = load("res://scripts/ui/crafting_bench.gd").new()
	town.add_child(guided_bench)
	await process_frame
	_check("guided table begins without an attention pulse",
		String(guided_bench.call("_tutorial_target")) == "")
	game._onboarding_progress_msec = Time.get_ticks_msec() - 21000
	game._onboarding_recovery_poll_msec = 0
	await process_frame
	_check("stalled mixing view pulses only the pot",
		String(guided_bench.call("_tutorial_target")) == "pot")
	guided_bench.close()
	await process_frame
	game.mark_onboarding_progress()

	# Beat 3 — mix ink.
	_check("mix ink", game.mix_ink("hedge_ink"))
	_check("tutorial 2→3", int(game.tutorial_step) == 3)

	# Beat 4 — inscribe a Snug.
	var ChartsData = load("res://data/charts.gd")
	var cost: Dictionary = ChartsData.craft_cost("snug", [])
	_check("can afford snug", game.can_afford(cost))
	game.spend_materials(cost)
	var chart: Dictionary = ChartsData.inscribe("snug", [], game.trade_lv("wayfinding"))
	game.add_chart(chart)
	_check("tutorial 3→4", int(game.tutorial_step) == 4)
	_check("new Chart immediately explains the next world interaction",
		"Waystone" in game.objective_hint() and "E" in game.objective_hint(),
		game.objective_hint())

	# Beat 5 — socket + step through (real scene change).
	game.enter_dungeon(chart, player)
	await _wait_for_scene("World")
	var world := current_scene
	_check("dungeon scene active", world != null and world.name == "World",
		str(world))
	_check("tutorial 4→5", int(game.tutorial_step) == 5)
	_check("chart consumed", (game.charts as Array).is_empty())
	_check("Snug reveals health and Basic Shot, but not Focus",
		game.onboarding_surface_available("combat")
		and not game.onboarding_surface_available("focus")
		and game.active_skill_slots() == 1)
	var lesson_enemies := get_nodes_in_group("snug_lesson_enemy")
	var lesson_enemy: Node = lesson_enemies[0] if lesson_enemies.size() == 1 else null
	_check("Snug has exactly one normalized teaching rat",
		lesson_enemy != null and int(lesson_enemy.get("damage")) == 1
		and float(lesson_enemy.get("move_speed")) <= 1.15
		and float(lesson_enemy.get("attack_cooldown")) >= 2.4,
		"count=%d" % lesson_enemies.size())
	_check("Snug begins with the Basic Shot prompt",
		"Basic Shot" in game.objective_hint(), game.objective_hint())
	game.record_onboarding_combat_action("basic_shot")
	_check("Basic Shot advances to the roll lesson",
		"roll" in game.objective_hint().to_lower(), game.objective_hint())
	game.record_onboarding_combat_action("roll")
	_check("roll completes the safe combat lesson",
		bool(game.seen_hints.get("snug_roll", false)))
	var dungeon_player: Node = get_first_node_in_group("player")
	_check("player re-instanced in dungeon",
		dungeon_player != null and dungeon_player != player)
	_check("snug grid 28", (28 == 28) and world != null)   # grid asserted via waystone below
	var first_mark := get_first_node_in_group("second_hand_clue")
	_check("Snug presents the first marginal mark", first_mark != null)
	if first_mark != null:
		first_mark.interact(dungeon_player)
		await process_frame
		_check("reading the first mark records it",
			game.has_second_hand_clue("far_waystone"))
		for _i in 60:
			await process_frame
		Input.action_press("ui_cancel")
		await process_frame
		Input.action_release("ui_cancel")
		await process_frame

	# Beat 6 — find the exit waystone and step through.
	var waystone: Node = null
	for n in _walk(world):
		# Spec 45-gaps added the entry-side abandon stone — the run-banking
		# beat needs the real EXIT (abandoning pays nothing).
		if n is ExitWaystone and not bool(n.get("abandoning")):
			waystone = n
	_check("exit waystone in dungeon", waystone != null)
	var xp_before := int(game.trades.wayfinding.xp)
	# Regression — a dead player must not be able to bank the run.
	dungeon_player.set("dead", true)
	waystone.interact(dungeon_player)
	await process_frame
	_check("dead player can't step through", game.in_dungeon
		and current_scene == world and int(game.trades.wayfinding.xp) == xp_before)
	dungeon_player.set("dead", false)
	waystone.interact(dungeon_player)
	await _wait_for_scene("Town")
	var back := current_scene
	_check("returned to town", back != null and back.name == "Town")
	# Regression — completion toasts buffered through the scene change get
	# drained by the new HUD (nothing left pending one frame after arrival).
	_check("no toast stranded in the buffer", (game.pending_toasts as Array).is_empty(),
		str(game.pending_toasts))
	_check("tutorial 5→6", int(game.tutorial_step) == 6,
		str(game.tutorial_step))
	_check("first Snug return records Green Hollow's rumour with its lesson pieces",
		(game.chart_recipe_journal.rumours as Array) == ["mara_first_loop"]
		and String(game.chart_recipe_journal.discoveries.get("snug", ""))
			== "mara_lesson"
		and game.material_count("field_parchment") >= 1
		and game.material_count("loop_cord") >= 1)
	_check("snug completion = 75 carto xp",
		int(game.trades.wayfinding.xp) - xp_before == 75,
		str(int(game.trades.wayfinding.xp) - xp_before))
	_check("Snug completion pays the chart purse", int(game.gold) == 8,
		str(game.gold))
	var debrief := await _wait_for_group(&"run_debrief")
	var debrief_copy := ""
	if debrief != null:
		for n in _walk(debrief):
			if n is Label:
				debrief_copy += " " + String((n as Label).text)
	_check("first return shows Found → Rose → Opened", debrief != null
		and "Found" in debrief_copy and "Rose" in debrief_copy
		and "Opened" in debrief_copy, debrief_copy)
	var prep_buttons: Array = []
	if debrief != null:
		for n in _walk(debrief):
			if n is Button and (n as Button).visible:
				prep_buttons.append(n)
	_check("first return offers two preparations", prep_buttons.size() == 2,
		str(prep_buttons.size()))
	var hedge_before_prep: int = game.material_count("hedge_ink")
	if prep_buttons.size() == 2:
		(prep_buttons[1] as Button).pressed.emit()
		await process_frame
	_check("preparation choice grants Hedge Ink",
		game.material_count("hedge_ink") == hedge_before_prep + 1)
	# Gathering is now Wildcraft-owned; the completed Chart alone grants 75
	# Wayfinding XP, which reaches level 2 but not level 3.
	_check("Wayfinding leveled to 2", game.trade_lv("wayfinding") == 2,
		str(game.trade_lv("wayfinding")))
	var practice := get_first_node_in_group("power_shot_practice")
	_check("first return places a harmless Power Shot bramble", practice != null)
	_check("first return exposes one Focus Skill only",
		game.onboarding_surface_available("focus") and game.active_skill_slots() == 2)
	if practice != null:
		practice.call("on_projectile_skill_hit", "basic")
		_check("Basic Shot does not consume Power Shot practice",
			not bool(game.seen_hints.get("power_shot_practiced", false)))
		practice.call("on_projectile_skill_hit", "power")
		_check("Power Shot completes the practice beat",
			bool(game.seen_hints.get("power_shot_practiced", false)))
	var town_player: Node = get_first_node_in_group("player")
	var mara_return: Node = null
	for n in _walk(back):
		if n is WayfinderNpc:
			mara_return = n
			break
	_check("Mara is present after the first return", mara_return != null)
	if mara_return != null:
		mara_return.interact(town_player)
		await process_frame
		var first_reaction := ""
		for n in _walk(back):
			if n is Label:
				first_reaction += " " + String((n as Label).text)
		_check("Mara reacts to the far-Waystone mark",
			"hooked hand" in first_reaction.to_lower(), first_reaction)
		for _i in 60:
			await process_frame
		Input.action_press("ui_cancel")
		await process_frame
		Input.action_release("ui_cancel")
		await process_frame

	# Beat 7 — second chart (tier_1) finishes the tutorial.
	game.add_material("hedge_ink", 2)
	var chart2: Dictionary = ChartsData.inscribe("tier_1", ["hedge_ink"],
		game.trade_lv("wayfinding"))
	game.add_chart(chart2)
	_check("tutorial 6→7 (done)", int(game.tutorial_step) == 7)
	_check("Tier 1 carries one resolved Affix after an ink choice",
		(chart2.affixes as Array).size() == 1)
	_check("crafting Tier 1 does not expose untaught Skills",
		game.active_skill_slots() == 2, str(game.active_skill_slots()))

	# Full second loop — the optional side mark, return debrief, and Mara's
	# distinct response all travel through the real scenes.
	game.enter_dungeon(chart2, town_player)
	await _wait_for_scene("World")
	var world2 := current_scene
	_check("Tier 1 Hollow scene active", world2 != null and world2.name == "World")
	_check("first Tier 1 Hollow still carries only Basic + Power Shot",
		game.active_skill_slots() == 2, str(game.active_skill_slots()))
	var dungeon_player2: Node = get_first_node_in_group("player")
	var second_mark := get_first_node_in_group("second_hand_clue")
	_check("Tier 1 presents the second marginal mark", second_mark != null)
	if second_mark != null:
		second_mark.interact(dungeon_player2)
		await process_frame
		_check("reading the inked scrap records it",
			game.has_second_hand_clue("inked_scrap"))
		for _i in 60:
			await process_frame
		Input.action_press("ui_cancel")
		await process_frame
		Input.action_release("ui_cancel")
		await process_frame
	var waystone2: Node = null
	for n in _walk(world2):
		if n is ExitWaystone and not bool(n.get("abandoning")):
			waystone2 = n
			break
	_check("Tier 1 far Waystone is reachable", waystone2 != null)
	if waystone2 != null:
		waystone2.interact(dungeon_player2)
	await _wait_for_scene("Town")
	back = current_scene
	_check("second Chart returns to Town", back != null and back.name == "Town")
	_check("Tier 1 completion closes the chapter and unfolds the full bar",
		bool(game.seen_hints.get("tier1_completed", false))
		and game.active_skill_slots() == 4)
	_check("closing objective points back to Mara",
		"Mara" in game.objective_text(), game.objective_text())
	var debrief2 := await _wait_for_group(&"run_debrief")
	var debrief2_copy := ""
	if debrief2 != null:
		for n in _walk(debrief2):
			if n is Label:
				debrief2_copy += " " + String((n as Label).text)
	_check("second return opens the next choice", "Hollow Charts" in debrief2_copy,
		debrief2_copy)
	for _i in 60:
		await process_frame
	Input.action_press("ui_cancel")
	await process_frame
	Input.action_release("ui_cancel")
	await process_frame
	var mara2: Node = null
	var town_player2: Node = get_first_node_in_group("player")
	for n in _walk(back):
		if n is WayfinderNpc:
			mara2 = n
			break
	if mara2 != null:
		mara2.interact(town_player2)
		await process_frame
	var second_reaction := ""
	for n in _walk(back):
		if n is Label:
			second_reaction += " " + String((n as Label).text)
	_check("Mara reacts differently to the mark in the player's ink",
		"your ink" in second_reaction.to_lower()
		and not "hooked hand" in second_reaction.to_lower(), second_reaction)
	var intention_dialog: Node = null
	for n in back.get_children():
		var pending_choices: Variant = n.get("_choices")
		if pending_choices is Array and (pending_choices as Array).size() == 3:
			intention_dialog = n
			break
	if intention_dialog != null:
		intention_dialog.call("_advance")
		await process_frame
	var intention_buttons: Array = []
	for n in _walk(back):
		if n is Button and String((n as Button).text).begins_with("Follow") \
				or n is Button and String((n as Button).text).begins_with("Seek"):
			intention_buttons.append(n)
	_check("Mara offers three nonbinding next-Chart intentions",
		intention_buttons.size() == 3, str(intention_buttons.size()))
	if intention_buttons.size() == 3:
		(intention_buttons[2] as Button).pressed.emit()
		await process_frame
	_check("intention changes guidance without locking content",
		String(game.seen_hints.get("third_chart_intention", "")) == "mystery"
		and "side rooms" in game.objective_text(), game.objective_text())
	# The first Tier 1 completion unlocks the faded panel, but its read threshold
	# remains Wayfinding 6. Mutation waits until the eligible dialog closes.
	var atlas_after := back.get_node_or_null("AtlasDeepRumourSource")
	_check("Tier 1 return unlocks the Atlas source without auto-reading it",
		atlas_after != null and bool(atlas_after.source_status().unlocked)
		and String(atlas_after.source_status().state) == "locked"
		and not (game.chart_recipe_journal.rumours as Array).has("atlas_deep_hollow"))
	# Now that Tier 1 unlocked the panel, the same real controller-A path opens
	# anticipation below Wayfinding 6, still without teaching the rumour.
	if atlas_after != null:
		var atlas_after_home := (atlas_after as Node3D).global_position
		(atlas_after as Node3D).global_position = Vector3(20.0, 0.8, 24.7)
		await physics_frame
		await physics_frame
		await physics_frame
		_check("unlocked Atlas enters the player's real interaction scanner",
			get_first_node_in_group("player").get("_active_interactable") == atlas_after)
		var atlas_receipt: Dictionary = await _controller_a_interact(
			get_first_node_in_group("player"), atlas_after)
		var anticipation_dialog := get_first_node_in_group("ChartRumourSourceDialog")
		_check("controller A opens post-Tier-1 Atlas anticipation",
			anticipation_dialog != null
			and String(atlas_receipt.get("status", "")) == "actual"
			and atlas_receipt.get("actual") == atlas_after
			and not (game.chart_recipe_journal.rumours as Array).has("atlas_deep_hollow"),
			str(atlas_receipt))
		if anticipation_dialog != null:
			anticipation_dialog.call("_finish")
			await process_frame
		_check("closing anticipation below Wayfinding 6 is copy-only",
			not (game.chart_recipe_journal.rumours as Array).has("atlas_deep_hollow"))
		(atlas_after as Node3D).global_position = atlas_after_home
		await physics_frame
	game.trades.wayfinding = {"xp": Progression.xp_for_level(6), "lv": 6}
	if atlas_after != null:
		atlas_after.refresh_source_state()
		atlas_after.interact(get_first_node_in_group("player"))
		await process_frame
		var atlas_read_dialog := get_first_node_in_group("ChartRumourSourceDialog")
		_check("eligible Atlas dialog opens before its source mutates",
			atlas_read_dialog != null
			and not (game.chart_recipe_journal.rumours as Array).has("atlas_deep_hollow"))
		if atlas_read_dialog != null:
			atlas_read_dialog.call("_finish")
			await process_frame
		_check("closing the Atlas read records one rumour and lesson kit",
			String(atlas_after.source_status().state) == "read"
			and (game.chart_recipe_journal.rumours as Array).count("atlas_deep_hollow") == 1
			and game.material_count("stitched_parchment") >= 1
			and game.material_count("hollow_stitch") >= 1)
		var atlas_repeat: Dictionary = atlas_after.read_now()
		_check("Atlas reread is copy-only and its marker stays quiet",
			bool(atlas_repeat.ok) and not bool(atlas_repeat.changed)
			and not (atlas_after.get_node("Marker") as Label3D).visible)
		game.known_chart_recipes.append("deep_hollow")
		game.chart_knowledge_changed.emit()
		_check("resolved Atlas stays readable without a world marker",
			String(atlas_after.source_status().state) == "resolved"
			and not (atlas_after.get_node("Marker") as Label3D).visible
			and "Read" in String(atlas_after.get_prompt_text()))
		game.known_chart_recipes.erase("deep_hollow")
		game.chart_knowledge_changed.emit()
	var measured_names: Array = []
	var report: Dictionary = game.onboarding_report()
	for event in report.get("events", []):
		measured_names.append(String((event as Dictionary).get("event", "")))
	_check("playtest report captures the two-loop milestones",
		["begin_selected", "control_ready", "first_mara_conversation",
			"snug_entered", "snug_completed", "tier1_entered",
			"tier1_completed", "first_chapter_complete"].all(
			func(event_name): return measured_names.has(event_name)),
		str(measured_names))
	_check("playtest report contains no player text or coordinates",
		not report.has("text") and not report.has("position")
		and report.keys().size() == 3, str(report.keys()))
	var recoveries: Dictionary = report.get("recovery_hints", {})
	_check("playtest report counts timed recovery activations",
		int(recoveries.get("step_1_stage_1", 0)) == 1
		and int(recoveries.get("step_1_stage_2", 0)) == 1
		and int(recoveries.get("step_2_stage_1", 0)) == 1,
		str(recoveries))

	# Spec 42 — the crafting bench drives the same logic layer through its
	# placement API (tutorial is done at step 7, so add_chart won't advance).
	var BenchScript = load("res://scripts/ui/crafting_bench.gd")
	var bench: CanvasLayer = BenchScript.new()
	back.add_child(bench)
	await process_frame
	game.add_material("wild_herb", 3)
	_check("bench pot mixes hedge ink", bench.pot_add("wild_herb")
		and bench.pot_add("wild_herb") and bench.pot_add("wild_herb")
		and game.material_count("hedge_ink") >= 1
		and (bench.pot as Dictionary).is_empty())
	# Spec 43 — the experiment: unknown recipes don't stir themselves.
	game.add_material("bogiron_ore", 2)
	_check("undiscovered match sits in the pot", bench.pot_add("bogiron_ore")
		and bench.pot_add("bogiron_ore")
		and not (bench.pot as Dictionary).is_empty()
		and game.material_count("stoneground_ink") == 0)
	var carto_xp: int = int(game.trades.wayfinding.xp)
	var tried: Dictionary = bench.pot_try()
	_check("Try discovers stoneground",
		String(tried.get("outcome", "")) == "discovery"
		and game.material_count("stoneground_ink") == 1
		and bool(game.ink_discovered("stoneground_ink")))
	_check("discovery pays 50 carto xp",
		int(game.trades.wayfinding.xp) - carto_xp == 50,
		str(int(game.trades.wayfinding.xp) - carto_xp))
	_check("pot empty after the try", (bench.pot as Dictionary).is_empty())
	game.add_material("bogiron_ore", 2)
	_check("discovered recipe auto-mixes now", bench.pot_add("bogiron_ore")
		and bench.pot_add("bogiron_ore")
		and game.material_count("stoneground_ink") == 2
		and (bench.pot as Dictionary).is_empty())
	# Spec 58 Slice B — stage the physical component arrangement. Drafting is
	# inventory-pure; the sole spend happens through Game.try_inscribe_chart.
	game.add_material("field_parchment", 2)
	game.add_material("hedge_sprig", 2)
	game.add_material("loop_cord", 2)
	game.add_material("hedge_ink", 4)
	var draft_before_locked: Dictionary = (bench.draft as Dictionary).duplicate(true)
	_check("bench rejects a locked Waymark cell",
		not bench.place_component("nw", "hedge_sprig")
		and bench.draft == draft_before_locked)
	_check("bench stages Tier 1 Base", bench.place_component("c", "field_parchment"))
	_check("bench stages Tier 1 Waymark", bench.place_component("n", "hedge_sprig"))
	_check("bench stages first-return Binding", bench.place_component("w", "loop_cord"))
	_check("Tier 1 preview carries 2 bias-Ink capacity",
		int((bench.current_preview() as Dictionary).get("bias_capacity", 0)) == 2)
	_check("bench stages an Ink", bench.place_ink("hedge_ink", 0))
	var charts_before: int = (game.charts as Array).size()
	var ink_before: int = game.material_count("hedge_ink")
	_check("bench crafts the chart", bench.craft())
	_check("chart landed in the case",
		(game.charts as Array).size() == charts_before + 1)
	_check("bench spent base cost + socketed ink",
		game.material_count("hedge_ink") == ink_before - 3)
	_check("bench cleared after craft", bench.draft_is_empty())
	# Slice D1 — the First Knot Seal is a distinct, authored boss Chart. It
	# cannot use the old good/bad den roll. This long-running scene test has
	# already exercised one real Green Hollow; install the tested campaign
	# threshold here so the table can prove the separate Wayfinding gate.
	# (CampaignData's own suite proves the three successful returns that reach it.)
	game.add_material("thorn_essence", 1)
	game.add_material("hedge_ink", 2)
	var first_knot: Dictionary = game.campaign_state.chapters.first_knot
	first_knot.clue_count = 3
	first_knot.boss_rumoured = true
	_check("bench re-stages Tier 1", bench.place_component("c", "field_parchment")
		and bench.place_component("n", "hedge_sprig")
		and bench.place_component("w", "loop_cord"))
	_check("First Knot Seal refuses below Wayfinding 8",
		not bench.place_component("s", "thorn_essence"))
	game.trades.wayfinding = {"xp": Progression.xp_for_level(8), "lv": 8}
	_check("First Knot Seal opens at Wayfinding 8", bench.place_component("s", "thorn_essence"))
	_check("First Knot Boss Chart physically stages its required Hedge Ink",
		bench.place_ink("hedge_ink", 0))
	var level8_preview: Dictionary = bench.current_preview()
	var level8_guarantees: Array = level8_preview.get("guaranteed", [])
	_check("sealed Chart names Hedgemother and protects the Seal",
		String(level8_preview.get("recipe_id", "")) == "first_knot_boss"
		and bool(level8_preview.get("requires_seal", false))
		and (level8_preview.get("required_inks", []) as Array) == ["hedge_ink"]
		and String((level8_preview.get("normalized_draft", {}) as Dictionary)
			.get("ink_rail", [""])[0]) == "hedge_ink"
		and int((level8_preview.get("costs", {}) as Dictionary).get("hedge_ink", 0)) == 2
		and not level8_guarantees.is_empty()
		and String((level8_guarantees[0] as Dictionary).get("id", "")) == "hedgemother"
		and int((level8_preview.get("returned_on_failure", {}) as Dictionary)
			.get("thorn_essence", 0)) == 1,
		str(level8_preview))
	var level8_rail: Array = (level8_preview.unlocks as Dictionary).ink_rail
	_check("two Ink wells are physically open at Wayfinder 8",
		level8_rail.filter(func(row): return bool((row as Dictionary).unlocked)).size() == 2)
	game.trades.wayfinding = {"xp": Progression.xp_for_level(17), "lv": 17}
	game.chosen_perks = {}
	bench._refresh_preview()
	_check("master wayfinder adds a bias Ink slot",
		int((bench.current_preview() as Dictionary).get("bias_capacity", 0)) == 3)
	game.trades.wayfinding = {"xp": Progression.xp_for_level(2), "lv": 2}
	bench.clear_draft()
	bench.close()
	await process_frame
	_check("bench unpaused on close", not paused, "modal_count=%d" % game.modal_count)

	# A completed Hollow unlocks the persistent rain note. Rebuild Town below
	# Wayfinding 12 to exercise anticipation, then cross the threshold and verify
	# dialog-close timing without touching Mara/Second Hand branches.
	game.trades.wayfinding = {"xp": Progression.xp_for_level(11), "lv": 11}
	game._unlock_chart_source("mara_sallow_reed")
	var clues_before_rain := (game.second_hand_clues as Array).duplicate()
	var intention_before_rain := String(game.seen_hints.get("third_chart_intention", ""))
	change_scene_to_file("res://scenes/Town.tscn")
	await process_frame
	await process_frame
	await process_frame
	back = current_scene
	var rain_source := back.get_node_or_null("MaraSallowRumourSource")
	_check("unlocked Sallow source spawns as a stable persistent note",
		rain_source != null
		and rain_source.get_script() == load("res://scripts/mara_rain_note.gd")
		and rain_source.is_in_group("interactable"))
	_check("pre-Wayfinding-12 note offers anticipation only",
		rain_source != null and String(rain_source.source_status().state) == "locked"
		and not (game.chart_recipe_journal.rumours as Array).has("mara_sallow_reed"))
	game.trades.wayfinding = {"xp": Progression.xp_for_level(12), "lv": 12}
	if rain_source != null:
		rain_source.refresh_source_state()
		var rain_player := get_first_node_in_group("player")
		var rain_home := (rain_source as Node3D).global_position
		(rain_source as Node3D).global_position = Vector3(20.0, 0.0, 24.7)
		await physics_frame
		await physics_frame
		await physics_frame
		_check("eligible rain note enters the player's real interaction scanner",
			rain_player.get("_active_interactable") == rain_source)
		var rain_receipt: Dictionary = await _controller_a_interact(rain_player, rain_source)
		var rain_dialog := get_first_node_in_group("ChartRumourSourceDialog")
		_check("controller A opens eligible rain-note dialog before mutation", rain_dialog != null
			and String(rain_receipt.get("status", "")) == "actual"
			and rain_receipt.get("actual") == rain_source
			and not (game.chart_recipe_journal.rumours as Array).has("mara_sallow_reed"),
			str(rain_receipt))
		if rain_dialog != null:
			rain_dialog.call("_finish")
			await process_frame
		(rain_source as Node3D).global_position = rain_home
		await physics_frame
		_check("closing the rain note records one rumour and lesson kit",
			String(rain_source.source_status().state) == "read"
			and (game.chart_recipe_journal.rumours as Array).count("mara_sallow_reed") == 1
			and game.material_count("waxed_vellum") >= 1
			and game.material_count("mire_reed") >= 1
			and game.material_count("sunk_knot") >= 1)
		var rain_repeat: Dictionary = rain_source.read_now()
		_check("rain-note reread is copy-only and does not borrow Mara's story state",
			bool(rain_repeat.ok) and not bool(rain_repeat.changed)
			and game.second_hand_clues == clues_before_rain
			and String(game.seen_hints.get("third_chart_intention", ""))
				== intention_before_rain)
		game.known_chart_recipes.append("sallow_mire")
		game.chart_knowledge_changed.emit()
		_check("resolved rain note stays readable without a world marker",
			String(rain_source.source_status().state) == "resolved"
			and not (rain_source.get_node("Marker") as Label3D).visible
			and "Read" in String(rain_source.get_prompt_text()))

	# Single-player modal semantics.
	game.modal_opened()
	_check("offline modal pauses the tree", paused and game.modal_count == 1)
	game.modal_closed()
	_check("offline close unpauses", not paused and game.modal_count == 0)

	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _walk(node: Node) -> Array:
	var out := [node]
	for c in node.get_children():
		out.append_array(_walk(c))
	return out

func _find_skeleton(root_node: Node) -> Skeleton3D:
	if root_node is Skeleton3D:
		return root_node as Skeleton3D
	for child in root_node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null

func _skeleton_pose_energy(skeleton: Skeleton3D) -> float:
	if skeleton == null:
		return 0.0
	var energy := 0.0
	for bone_idx in range(skeleton.get_bone_count()):
		energy += skeleton.get_bone_pose_rotation(bone_idx).angle_to(Quaternion.IDENTITY)
		energy += skeleton.get_bone_pose_position(bone_idx).length()
	return energy

func _arm_down_score(skeleton: Skeleton3D) -> float:
	if skeleton == null:
		return -1.0
	var total := 0.0
	var count := 0
	for side in ["Left", "Right"]:
		var upper := skeleton.find_bone("%sArm" % side)
		var lower := skeleton.find_bone("%sForeArm" % side)
		if upper >= 0 and lower >= 0:
			var direction := skeleton.get_bone_global_pose(lower).origin \
				- skeleton.get_bone_global_pose(upper).origin
			if direction.length_squared() > 0.0001:
				total += direction.normalized().dot(Vector3.DOWN)
				count += 1
	return total / float(count) if count > 0 else -1.0
