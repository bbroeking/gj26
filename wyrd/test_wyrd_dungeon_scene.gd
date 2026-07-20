extends SceneTree

# Wyrd slice — headless scene check of the chart-run dungeon build.
# Run: godot --headless --path wyrd --script res://test_wyrd_dungeon_scene.gd
#
# --script mode has no autoloads, so a Game node is hand-mounted at
# /root/Game with an active chart (mineral_vein good, no boss), then
# World.tscn is instantiated and the built tree inspected: gather nodes
# spawned, exit waystone standing, no boss in a boss-less chart.

const GameScript = preload("res://scripts/game.gd")
const BossScript = preload("res://scripts/boss.gd")
const Progression = preload("res://data/progression.gd")
const CampaignData = preload("res://data/campaign.gd")
const DungeonGenScript = preload("res://scripts/dungeon_gen.gd")
const CampaignClueScript = preload("res://scripts/campaign_clue.gd")
const Drops = preload("res://data/drops.gd")

var _pass := 0
var _fail := 0

func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % name)
	else:
		_fail += 1
		print("  ✗ %s %s" % [name, detail])

func _initialize() -> void:
	_run()

func _run() -> void:
	print("--- wyrd dungeon scene check ---")
	_test_campaign_clue_layout_contract()
	var kids: Array = []
	for c in root.get_children():
		kids.append(String(c.name))
	print("  [debug] root children before mount: %s" % str(kids))
	# Godot 4.6 loads project autoloads even in --script mode — reuse the
	# real Game autoload if it's there, else mount one.
	var game: Node = root.get_node_or_null("Game")
	if game == null:
		game = GameScript.new()
		game.name = "Game"
		root.add_child(game)
	game.active_chart = {
		"template_id": "tier_1", "tier": 1, "scope": "hollow",
		"name": "Tier 1 Hollow", "seed": 31337,
		"affixes": [
			{"id": "mineral_vein", "good": true, "resolvedId": "mineral_vein"},
			{"id": "festival_pace", "good": true, "resolvedId": "festival_pace"},
		],
	}
	game.in_dungeon = true
	# This suite exercises the general post-onboarding combat surface, not the
	# first authored Tier 1 lesson (which intentionally exposes two slots).
	game.tutorial_step = 7
	game.seen_hints["tier1_completed"] = true

	print("  [debug] /root/Game found: %s" % str(root.get_node_or_null("Game") != null))
	print("  [debug] run_cfg: %s" % str(game.run_cfg()))

	var world_scene: PackedScene = load("res://scenes/World.tscn")
	var world := world_scene.instantiate()
	root.add_child(world)
	# _ready runs when the main loop iterates; deferred calls need one more.
	await process_frame
	await process_frame

	var gather := 0
	var gather_kinds := {}
	var waystones := 0
	var bosses := 0
	var enemies := 0
	var chapter_clues := 0
	for n in _walk(world):
		if n is GatherNode:
			gather += 1
			var gather_kind := String(n.get("kind"))
			gather_kinds[gather_kind] = int(gather_kinds.get(gather_kind, 0)) + 1
		elif n is ExitWaystone:
			waystones += 1
		elif n.get_script() == BossScript:
			bosses += 1
		elif n is CharacterBody3D and n.is_in_group("enemy"):
			enemies += 1
		elif n.is_in_group("second_hand_clue"):
			chapter_clues += 1
	_check("Green Hollow keeps its baseline triad beneath 3-5 bonus ore",
		gather >= 6 and gather <= 8
			and int(gather_kinds.get("ore_rock", 0)) >= 4
			and int(gather_kinds.get("forage_node", 0)) >= 1
			and int(gather_kinds.get("log_pile", 0)) >= 1,
		str({"count": gather, "kinds": gather_kinds}))
	# Spec 45-gaps — two stones now: the exit + the entry abandon stone.
	_check("exit + abandon waystones standing", waystones == 2, str(waystones))
	var abandons := 0
	for n in _walk(world):
		if n is ExitWaystone and bool(n.get("abandoning")):
			abandons += 1
	_check("exactly one is the abandon stone", abandons == 1, str(abandons))
	_check("no boss without the den affix", bosses == 0, str(bosses))
	_check("enemies populated", enemies > 0, str(enemies))
	_check("Tier 1 world presents its Second Hand clue", chapter_clues == 1,
		str(chapter_clues))
	# B3 — spawned enemies carry per-kind stats, not the spec-15 defaults.
	var stat_pairs := {}
	for n in _walk(world):
		if n is CharacterBody3D and n.is_in_group("enemy") \
				and n.get_script() != BossScript:
			stat_pairs["%d/%.2f" % [int(n.damage), float(n.move_speed)]] = true
	_check("per-kind stats set (>1 damage/speed profile)",
		stat_pairs.size() > 1, str(stat_pairs.keys()))

	# Grid honored: tier_1 gen block is a 36-grid.
	var layout_kids := world.get_child_count()
	_check("dungeon built (%d children)" % layout_kids, layout_kids > 50)

	# B7/ADR 0005 — a kill feeds Huntcraft, scaled to the slain thing's vigor.
	var prey: CharacterBody3D = null
	for n in _walk(world):
		if n is CharacterBody3D and n.is_in_group("enemy") \
				and n.get_script() != BossScript:
			prey = n
			break
	# B5-wave2 — Hunter's Mark: a marked thing takes +30% (crits disabled
	# so the arithmetic is deterministic).
	# (A 2-damage probe so even the squishiest prey survives the check —
	# the kill assertions below need it alive.)
	prey.crit_enabled = false
	var hp0: int = int(prey.hp)
	prey.apply_status("marked", 8.0, 0)
	prey.take_damage(2, Vector3.FORWARD, 0.0, 0.0)
	_check("marked prey takes +30%", hp0 - int(prey.hp) == 3,
		str(hp0 - int(prey.hp)))
	# B5-wave2 — Heartwood Ward: the bark soaks before vigor.
	var player2: Node = get_first_node_in_group("player")
	# Regression (frozen-game bug): a loadout swap cleared _skill_cooldowns
	# without re-seeding. The new contract permits a variable 0–3 Focus-Skill
	# loadout, so build two owned actions then fire every built slot.
	if player2 != null:
		game.award_xp("huntcraft", Progression.xp_for_level(16))
		for skill_id in ["PiercingBolt", "Thornburst"]:
			if not game.skill_owned(skill_id):
				game.grant_skill(skill_id)
		game.set_loadout(["PiercingBolt", "Thornburst"])
		player2.focus = 999.0
		for s in [2, 3]:
			player2._try_skill(s)
		_check("hotbar casts after a loadout swap (no crash)",
			float(player2.focus) < 999.0, str(player2.focus))
		_check("cooldown keys match the variable built action set",
			(player2._skill_cooldowns as Dictionary).size() == 3,
			str(player2._skill_cooldowns))
		game.set_loadout([])
		player2.focus = float(player2.focus_max)
	if player2 != null:
		player2.apply_ward(30, 8.0)
		var php: int = int(player2.hp)
		player2._iframe_t = 0.0
		player2.take_damage(10, Vector3.FORWARD)
		_check("ward soaks the whole hit", int(player2.hp) == php
			and int(player2._ward_hp) == 20, str(player2._ward_hp))
		player2._iframe_t = 0.0
		player2.take_damage(25, Vector3.FORWARD)
		_check("overflow spills past the bark", int(player2.hp) == php - 5
			and int(player2._ward_hp) == 0,
			"%d hp, %d ward" % [int(player2.hp), int(player2._ward_hp)])
		player2.heal_to_full()
	else:
		_check("player found for ward check", false)

	var prey_vigor: int = int(prey.hp_max)
	# Spec 45-hunt — Even Breath: at the cap, every kill returns 6 Focus.
	game.award_xp("huntcraft", Progression.max_xp())
	game.chosen_perks = {"huntcraft": {"even_breath": true}}
	var hunt_before: int = int(game.trades.huntcraft.xp)
	if player2 != null:
		player2.focus = 10.0
	prey.take_damage(999, Vector3.FORWARD)
	if player2 != null:
		_check("even breath refunds 6 focus on the kill",
			absf(float(player2.focus) - 16.0) < 0.01, str(player2.focus))
	var gained: int = int(game.trades.huntcraft.xp) - hunt_before
	_check("Huntcraft XP remains capped at level 23", gained == 0
		and int(game.trades.huntcraft.xp) == Progression.max_xp(),
		"%d xp for %d hp" % [gained, prey_vigor])
	await process_frame

	world.free()
	# Slice D1 — drive the two presentation promises through the real World
	# scene and Game.run_cfg seam, rather than only inspecting generator output.
	await _test_campaign_world_contract(game)
	_test_d2_runtime_contract(game)

	# ---- B4a: the Boar's charge (windup -> line telegraph -> dodgeable dash) ----
	await _check_boar_charge()

	# ---- B4b: the Wolf's pack-lunge (chained re-aimed dashes) ----
	await _check_wolf_lunge()

	game.free()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

# D2 runtime adapter: only the immutable Chart contracts decide what the
# current layer realizes. The first reprise layer is boss-free; the terminal
# layer receives both the hard Hearth contract and the named encounter.
func _test_d2_runtime_contract(game: Node) -> void:
	var reprise := {
		"template_id": "tier_1", "recipe_id": "first_knot_reprise",
		"chart_instance_id": "d2-runtime-reprise", "tier": 1,
		"scope": "hollow", "name": "First Knot Reprise", "seed": 92371,
		"affixes": [{"id": "hedgemother_den", "good": true,
			"resolvedId": "hedgemother_den"}],
		"layer": 1, "max_layers": 2, "omens": [],
		"depth_contract": {"variant_id": "first_knot_reprise",
			"base_max_layers": 1, "max_layers": 2, "added_layer": 2,
			"hearth_layer": 2},
		"encounter_contract": {"boss_kind": "hedgemother", "boss_layer": 2,
			"reward_family_id": "first_knot_heirlooms",
			"suppress_chain_trophy": true, "reward_seed": 48621},
	}
	game.active_chart = reprise.duplicate(true)
	var layer_one_cfg: Dictionary = game.run_cfg()
	_check("D2 reprise layer one is boss-free despite a den affix",
		String(layer_one_cfg.get("boss_kind", "hedgemother")) == ""
		and not layer_one_cfg.has("required_room_roles"), str(layer_one_cfg))
	game.active_chart.layer = 2
	var layer_two_cfg: Dictionary = game.run_cfg()
	var terminal: Dictionary = DungeonGenScript.generate(92372, layer_two_cfg)
	var has_rest_focal := false
	for d_v in terminal.get("decor", []):
		if d_v is Dictionary and String((d_v as Dictionary).get("interact_role", "")) == "rest":
			has_rest_focal = true
			break
	_check("D2 terminal layer forces Hearth and Hedgemother",
		String(layer_two_cfg.get("boss_kind", "")) == "hedgemother"
		and (layer_two_cfg.get("required_room_roles", []) as Array) == ["rest"]
		and bool(terminal.get("required_roles_valid", false)) and has_rest_focal,
		str(layer_two_cfg))
	var heirloom: Dictionary = game.claim_first_knot_reprise_reward(game.active_chart)
	var duplicate: Dictionary = game.claim_first_knot_reprise_reward(game.active_chart)
	_check("D2 reprise heirloom is seeded and exact-once",
		not heirloom.is_empty() and heirloom == Drops.select_first_knot_heirloom(48621)
		and duplicate.is_empty(), str(heirloom))
	game.known_chart_recipes = ["snug"]
	game.chart_recipe_journal = {"rumours": [], "discoveries": {}}
	game.campaign_state = CampaignData.empty_state()
	(game.campaign_state.chapters.first_knot as Dictionary).cleared = true
	_check("D2 cleared First Knot backfills only the reprise entitlement",
		game._grant_first_knot_reprise_entitlement()
		and game.known_chart_recipes.has("first_knot_reprise")
		and not game._grant_first_knot_reprise_entitlement())
	game.active_chart = {}

# Slice D1 — this is intentionally generator-level evidence, not an ambient
# Second Hand assertion. The campaign contract must produce exactly one
# reachable Thorn Whisper before a World scene is even built.
func _test_campaign_clue_layout_contract() -> void:
	var layout: Dictionary = DungeonGenScript.generate(77123, {
		"template_id": "tier_1", "scope": "hollow", "tier": 1,
		"boss_kind": "", "campaign_clue": {
			"id": "thorn_whisper", "presentation": "thorn_whisper",
			"chapter_id": "first_knot",
		},
	})
	var campaign_clues: Array = layout.get("campaign_clues", [])
	var clue_ok := campaign_clues.size() == 1
	if clue_ok:
		var clue: Dictionary = campaign_clues[0]
		var room_id := int(clue.get("room_id", -1))
		var boss_id := int((layout.bossRoom as Dictionary).get("id", -1))
		var rooms: Array = layout.get("rooms", [])
		clue_ok = String(clue.get("id", "")) == "thorn_whisper" \
			and String(clue.get("presentation", "")) == "thorn_whisper" \
			and room_id > 0 and room_id != boss_id and room_id < rooms.size()
	_check("campaign contract places one non-Second-Hand Thorn Whisper",
		clue_ok, str(campaign_clues))
	var absent: Dictionary = DungeonGenScript.generate(77123, {
		"template_id": "tier_1", "scope": "hollow", "tier": 1, "boss_kind": "",
	})
	_check("ordinary Green Hollow does not invent campaign progress",
		(absent.get("campaign_clues", []) as Array).is_empty(),
		str(absent.get("campaign_clues", [])))
	var clue := CampaignClueScript.new()
	clue.setup({"id": "thorn_whisper_1", "presentation": "thorn_whisper",
		"chapter_id": "first_knot"})
	root.add_child(clue)
	await process_frame
	var before_second_hand: Array = []
	var game: Node = root.get_node_or_null("Game")
	if game != null:
		before_second_hand = (game.get("second_hand_clues") as Array).duplicate()
	var read: Dictionary = clue.read_now()
	var after_second_hand: Array = before_second_hand
	if game != null:
		after_second_hand = (game.get("second_hand_clues") as Array).duplicate()
	_check("Thorn Whisper reads as copy only, never a Second Hand truth",
		bool(read.get("ok", false)) and not bool(read.get("changed", true))
			and before_second_hand == after_second_hand, str(read))
	clue.free()


# D1 acceptance: an eligible Green Hollow visibly carries exactly one authored
# Thorn Whisper, while the sealed Chart spawns the named boss even when its
# legacy den Affix is the bad/empty twin. Reading the prop itself remains inert.
func _test_campaign_world_contract(game: Node) -> void:
	game.trades.wayfinding = {"xp": Progression.xp_for_level(4), "lv": 4}
	game.campaign_state = {
		"version": 1, "next_attempt_id": 1,
		"chapters": {"first_knot": {"clue_count": 0, "boss_rumoured": false,
			"cleared": false}}, "escrows": {}, "relics": [], "restorations": [],
	}
	game.active_chart = {
		"template_id": "tier_1", "recipe_id": "green_hollow", "tier": 1,
		"scope": "hollow", "name": "Green Hollow", "seed": 41821,
		"chart_instance_id": "dungeon-scene-green-1",
		"affixes": [],
	}
	game.in_dungeon = true
	var clue_cfg: Dictionary = game.run_cfg()
	_check("eligible Green Hollow publishes the next Thorn Whisper",
		String((clue_cfg.get("campaign_clue", {}) as Dictionary).get("clue_id", ""))
			== "thorn_whisper_1", str(clue_cfg.get("campaign_clue", {})))
	var world_scene: PackedScene = load("res://scenes/World.tscn")
	var clue_world := world_scene.instantiate()
	root.add_child(clue_world)
	await process_frame
	await process_frame
	var whispers: Array = []
	for node in _walk(clue_world):
		if node.is_in_group("campaign_clue"):
			whispers.append(node)
	var clue_ok := whispers.size() == 1 \
		and String(whispers[0].get("clue_id")) == "thorn_whisper_1"
	_check("real Green Hollow has exactly one readable Thorn Whisper", clue_ok,
		str(whispers.size()))
	var campaign_before: Dictionary = game.campaign_state.duplicate(true)
	var second_hand_before: Array = (game.second_hand_clues as Array).duplicate()
	if not whispers.is_empty():
		whispers[0].call("read_now")
	_check("reading world Whisper never mutates the campaign or Second Hand",
		game.campaign_state == campaign_before and game.second_hand_clues == second_hand_before)
	clue_world.free()
	await process_frame

	# A legacy good den Affix is still an ordinary boss run. Its death can award
	# its normal trophy, but must never rewrite the First Knot campaign ledger.
	game.trades.wayfinding = {"xp": Progression.xp_for_level(8), "lv": 8}
	game.campaign_state = CampaignData.empty_state()
	game.active_chart = {
		"template_id": "tier_1", "recipe_id": "green_hollow", "tier": 1,
		"scope": "hollow", "name": "Legacy Hedgemother Den", "seed": 41820,
		"chart_instance_id": "dungeon-scene-legacy-den",
		"affixes": [{"id": "hedgemother_den", "good": true,
			"resolvedId": "hedgemother_den"}],
	}
	var legacy_world := world_scene.instantiate()
	root.add_child(legacy_world)
	await process_frame
	await process_frame
	var legacy_boss: Node = null
	for node in _walk(legacy_world):
		if node.get_script() == BossScript:
			legacy_boss = node
	var legacy_state_before: Dictionary = game.campaign_state.duplicate(true)
	var legacy_tusks_before: int = int(game.material_count("tusker_tusk"))
	if legacy_boss != null:
		legacy_boss.emit_signal("died")
	await process_frame
	_check("legacy Hedgemother-den keeps its normal trophy but stays campaign-inert",
		game.campaign_state == legacy_state_before \
			and int(game.material_count("tusker_tusk")) == legacy_tusks_before + 1,
		str(game.campaign_state))
	legacy_world.free()
	await process_frame

	# The bad den twin is intentional: the authored contract must still create
	# Hedgemother rather than the historical Empty Throne run. Create a real
	# in-run escrow record so the boss callback exercises Game's public,
	# idempotent settlement seam rather than a handcrafted clear.
	game.campaign_state = CampaignData.empty_state()
	# Isolate the authored first-clear reward from the legacy compatibility
	# assertion above. The campaign contract targets one Tusker on its own.
	game.materials.erase("tusker_tusk")
	var first_knot: Dictionary = game.campaign_state.chapters.first_knot
	first_knot.clue_count = 3
	var contract: Dictionary = CampaignData.boss_contract("first_knot_boss")
	var campaign_chart: Dictionary = {
		"template_id": "tier_1", "recipe_id": "first_knot_boss", "tier": 1,
		"scope": "hollow", "name": "Hedgemother's Den", "seed": 41822,
		"chart_instance_id": "dungeon-scene-first-knot",
		"campaign_contract": contract,
		"affixes": [{"id": "hedgemother_den", "good": false,
			"resolvedId": "hedgemother_den__bad"}],
	}
	var begun: Dictionary = CampaignData.begin_boss_escrow(game.campaign_state,
		String(campaign_chart.chart_instance_id))
	var in_run: Dictionary = CampaignData.mark_escrow_in_run(begun.state,
		String(begun.attempt_id), String(campaign_chart.chart_instance_id))
	campaign_chart["attempt_id"] = String(begun.attempt_id)
	game.campaign_state = in_run.state
	game.active_chart = campaign_chart
	var boss_cfg: Dictionary = game.run_cfg()
	_check("campaign contract overrides the Empty Throne Affix twin",
		String(boss_cfg.get("boss_kind", "")) == "hedgemother"
			and String((boss_cfg.get("campaign_contract", {}) as Dictionary)
				.get("boss_kind", "")) == "hedgemother", str(boss_cfg))
	var boss_world := world_scene.instantiate()
	root.add_child(boss_world)
	await process_frame
	await process_frame
	var bosses: Array = []
	for node in _walk(boss_world):
		if node.get_script() == BossScript:
			bosses.append(node)
	var boss_ok := bosses.size() == 1 and String(bosses[0].kind) == "hedgemother"
	_check("sealed Chart builds one guaranteed Hedgemother encounter", boss_ok,
		str(bosses.size()))
	var tusks_before: int = int(game.material_count("tusker_tusk"))
	if not bosses.is_empty():
		bosses[0].emit_signal("died")
	await process_frame
	var cleared_once: bool = CampaignData.chapter_cleared(game.campaign_state,
		CampaignData.FIRST_KNOT) and game.material_count("tusker_tusk") == tusks_before + 1
	_check("sealed boss death settles the chapter and awards Tusker once", cleared_once,
		str(game.campaign_state))
	if not bosses.is_empty():
		bosses[0].emit_signal("died")
	await process_frame
	_check("repeated campaign boss-death signal has no second Tusker award",
		game.material_count("tusker_tusk") == tusks_before + 1,
		str(game.material_count("tusker_tusk")))
	boss_world.free()
	await process_frame

class DummyPlayer extends Node3D:
	var hits := 0
	func take_damage(_a: int, _d: Vector3) -> void:
		hits += 1

func _make_boar() -> CharacterBody3D:
	var boss: CharacterBody3D = BossScript.new()
	boss.kind = "burrow_boar"
	root.add_child(boss)
	boss.cache_meshes()
	boss.setup(80, 0.9, 2.2)
	return boss

func _check_wolf_lunge() -> void:
	var boss: CharacterBody3D = BossScript.new()
	boss.kind = "wolf_alpha"
	root.add_child(boss)
	boss.cache_meshes()
	boss.setup(55, 0.7, 1.8)
	var dummy := DummyPlayer.new()
	dummy.add_to_group("player")
	root.add_child(dummy)
	boss.global_position = Vector3(0, 0, 40)
	dummy.global_position = Vector3(4, 0, 40)
	boss._aggroed = true
	boss._atk_cd = 0.0
	await physics_frame
	await physics_frame
	_check("wolf picks the lunge", boss._pending == "lunge", boss._pending)
	_check("phase-1 chain is 2 lunges", boss._lunges_left == 2,
		str(boss._lunges_left))
	_check("lunge telegraphs a line", boss._telegraph_node != null
		and boss._telegraph_node.mesh is BoxMesh)
	# Stand still through the whole chain — every re-aimed lunge connects.
	await create_timer(3.0).timeout
	_check("standing still eats the chain (2 hits)", dummy.hits == 2,
		str(dummy.hits))
	_check("chain spent", boss._lunges_left == 0 and not boss._charging)
	boss.free()
	dummy.free()

func _check_boar_charge() -> void:
	# Case 1 — player stands in the lane: telegraph, then the dash connects once.
	var boss := _make_boar()
	var dummy := DummyPlayer.new()
	dummy.add_to_group("player")
	root.add_child(dummy)
	boss.global_position = Vector3(0, 0, 0)
	dummy.global_position = Vector3(5, 0, 0)
	boss._aggroed = true
	boss._atk_cd = 0.0
	await physics_frame
	await physics_frame
	_check("boar picks the charge", boss._pending == "charge", boss._pending)
	_check("charge telegraphs first", boss._telegraphing)
	_check("telegraph is a line", boss._telegraph_node != null
		and boss._telegraph_node.mesh is BoxMesh)
	await create_timer(2.2).timeout
	_check("standing in the lane gets hit once", dummy.hits == 1,
		str(dummy.hits))
	_check("charge ended", not boss._charging)
	boss.free()
	dummy.free()

	# Case 2 — sidestep during the windup: the lane is a snapshot, dodge works.
	var boss2 := _make_boar()
	var dummy2 := DummyPlayer.new()
	dummy2.add_to_group("player")
	root.add_child(dummy2)
	boss2.global_position = Vector3(0, 0, 20)
	dummy2.global_position = Vector3(5, 0, 20)
	boss2._aggroed = true
	boss2._atk_cd = 0.0
	await physics_frame
	await physics_frame
	dummy2.global_position = Vector3(5, 0, 24)   # step out of the lane
	await create_timer(2.2).timeout
	_check("sidestep dodges the charge", dummy2.hits == 0, str(dummy2.hits))
	boss2.free()
	dummy2.free()

func _walk(node: Node) -> Array:
	var out := [node]
	for c in node.get_children():
		out.append_array(_walk(c))
	return out
