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

	print("  [debug] /root/Game found: %s" % str(root.get_node_or_null("Game") != null))
	print("  [debug] run_cfg: %s" % str(game.run_cfg()))

	var world_scene: PackedScene = load("res://scenes/World.tscn")
	var world := world_scene.instantiate()
	root.add_child(world)
	# _ready runs when the main loop iterates; deferred calls need one more.
	await process_frame
	await process_frame

	var gather := 0
	var waystones := 0
	var bosses := 0
	var enemies := 0
	for n in _walk(world):
		if n is GatherNode:
			gather += 1
		elif n is ExitWaystone:
			waystones += 1
		elif n.get_script() == BossScript:
			bosses += 1
		elif n is CharacterBody3D and n.is_in_group("enemy"):
			enemies += 1
	_check("gather nodes spawned (3-5 ore)", gather >= 3 and gather <= 5, str(gather))
	_check("exit waystone standing", waystones == 1, str(waystones))
	_check("no boss without the den affix", bosses == 0, str(bosses))
	_check("enemies populated", enemies > 0, str(enemies))
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
	# without re-seeding, so the NEXT cast of any slot crashed out of
	# bounds. Swap, then actually fire every hotbar slot.
	if player2 != null:
		game.trades.hunt.lv = 9
		game.set_loadout(["PiercingBolt", "Thornburst", "MercyShot"])
		player2.focus = 999.0
		for s in [2, 3, 4]:
			player2._try_skill(s)
		_check("hotbar casts after a loadout swap (no crash)",
			float(player2.focus) < 999.0, str(player2.focus))
		_check("cooldown keys re-seeded for every slot",
			(player2._skill_cooldowns as Dictionary).size() == 4,
			str(player2._skill_cooldowns))
		game.set_loadout(["PowerShot", "MultiShot", "BrambleSnare"])
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

	var hunt_before: int = int(game.trades.hunt.xp)
	var prey_vigor: int = int(prey.hp_max)
	# Spec 45-hunt — Even Breath: at the cap, every kill returns 6 Focus.
	game.trades.hunt.lv = 17
	if player2 != null:
		player2.focus = 10.0
	prey.take_damage(999, Vector3.FORWARD)
	if player2 != null:
		_check("even breath refunds 6 focus on the kill",
			absf(float(player2.focus) - 16.0) < 0.01, str(player2.focus))
	var gained: int = int(game.trades.hunt.xp) - hunt_before
	_check("kill feeds Huntcraft", gained >= 2, str(gained))
	_check("hunt xp scales to vigor", gained == maxi(2, int(prey_vigor / 3.0)),
		"%d xp for %d hp" % [gained, prey_vigor])
	await process_frame

	world.free()

	# ---- B4a: the Boar's charge (windup -> line telegraph -> dodgeable dash) ----
	await _check_boar_charge()

	# ---- B4b: the Wolf's pack-lunge (chained re-aimed dashes) ----
	await _check_wolf_lunge()

	game.free()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

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
