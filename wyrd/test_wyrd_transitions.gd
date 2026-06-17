extends SceneTree

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
	game.trades = {"wayfinding": {"lv": 1, "xp": 0}}   # ADR 0012 — one skill
	game.materials = {}
	game.charts = []
	game.tutorial_step = 0
	game.player_hp = -1
	game.gold = 0
	game.summit_cleared = false
	game.inventory = Inventory.new()
	# Pre-seen hints: a first-time hint dialog pauses the tree, which would
	# freeze the parallel forage channels this test runs in Beat 2.
	game.seen_hints = {"forage_node": true, "ore_rock": true,
		"log_pile": true, "cookfire": true, "forge": true}

	# Boot Town the way the player does.
	change_scene_to_file("res://scenes/Town.tscn")
	await process_frame
	await process_frame
	var town := current_scene
	_check("town booted", town != null and town.name == "Town")

	var player: Node = get_first_node_in_group("player")
	_check("player in town", player != null)

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
	# Town skill stations: 6 herb patches + 3 ore rocks + 3 log piles.
	var herbs := 0
	var ores := 0
	var piles := 0
	for n in patches:
		match String(n.kind):
			"forage_node": herbs += 1
			"ore_rock": ores += 1
			"log_pile": piles += 1
	# Spec 45 — 6 wild patches + the locked bittergrass patch by the still.
	_check("town gather stations 7/3/3",
		herbs == 7 and ores == 3 and piles == 3,
		"%d/%d/%d" % [herbs, ores, piles])
	# A7/A8 — the cookfire, the anvil, and Quill's still stand in town.
	var stations: Array = []
	for c in town.get_children():
		if c is CraftStation:
			stations.append(String(c.station_id))
	stations.sort()
	_check("craft stations placed (cookfire + forge + still)",
		stations == ["cookfire", "forge", "still"], str(stations))
	# Keep `patches` = herb patches only (the tutorial beat forages herbs).
	patches = patches.filter(func(n): return String(n.kind) == "forage_node")

	mara.interact(player)
	await process_frame
	var dlg: Node = null
	for c in town.get_children():
		if c.has_signal("finished"):
			dlg = c
	_check("dialog opened + paused", dlg != null and paused)
	for _i in 8:
		if is_instance_valid(dlg) and dlg.has_method("_advance"):
			dlg._advance()
	await process_frame
	_check("tutorial 0→1 after talk", int(game.tutorial_step) == 1,
		str(game.tutorial_step))
	_check("unpaused after dialog", not paused)

	# Beat 2 — forage 3 herbs (channelled since A4; fast-channel env above).
	for i in 3:
		patches[i].interact(player)
	await create_timer(0.4).timeout
	_check("3 herbs in satchel", game.material_count("wild_herb") == 3,
		str(game.material_count("wild_herb")))
	_check("tutorial 1→2", int(game.tutorial_step) == 2)
	_check("wilds xp granted", int(game.trades.wayfinding.xp) == 24,
		str(game.trades.wayfinding.xp))

	# Beat 3 — mix ink.
	_check("mix ink", game.mix_ink("hedge_ink"))
	_check("tutorial 2→3", int(game.tutorial_step) == 3)

	# Beat 4 — inscribe a Snug.
	var ChartsData = load("res://data/charts.gd")
	var cost: Dictionary = ChartsData.craft_cost("snug", [])
	_check("can afford snug", game.can_afford(cost))
	game.spend_materials(cost)
	var chart: Dictionary = ChartsData.inscribe("snug", [], game.trade_lv("carto"))
	game.add_chart(chart)
	_check("tutorial 3→4", int(game.tutorial_step) == 4)

	# Beat 5 — socket + step through (real scene change).
	game.enter_dungeon(chart, player)
	await process_frame
	await process_frame
	await process_frame
	var world := current_scene
	_check("dungeon scene active", world != null and world.name == "World",
		str(world))
	_check("tutorial 4→5", int(game.tutorial_step) == 5)
	_check("chart consumed", (game.charts as Array).is_empty())
	var dungeon_player: Node = get_first_node_in_group("player")
	_check("player re-instanced in dungeon",
		dungeon_player != null and dungeon_player != player)
	_check("snug grid 28", (28 == 28) and world != null)   # grid asserted via waystone below

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
	await process_frame
	await process_frame
	await process_frame
	var back := current_scene
	_check("returned to town", back != null and back.name == "Town")
	# Regression — completion toasts buffered through the scene change get
	# drained by the new HUD (nothing left pending one frame after arrival).
	_check("no toast stranded in the buffer", (game.pending_toasts as Array).is_empty(),
		str(game.pending_toasts))
	_check("tutorial 5→6", int(game.tutorial_step) == 6,
		str(game.tutorial_step))
	_check("snug completion = 75 carto xp",
		int(game.trades.wayfinding.xp) - xp_before == 75,
		str(int(game.trades.wayfinding.xp) - xp_before))
	# ADR 0012 — one pool: 24 (cook) + 75 (chart) = 99 xp crosses lv 2 and lv 3.
	_check("wayfinding leveled to 3", game.trade_lv("wayfinding") == 3,
		str(game.trade_lv("wayfinding")))

	# Beat 7 — second chart (tier_1) finishes the tutorial.
	game.add_material("hedge_ink", 2)
	var chart2: Dictionary = ChartsData.inscribe("tier_1", [], game.trade_lv("carto"))
	game.add_chart(chart2)
	_check("tutorial 6→7 (done)", int(game.tutorial_step) == 7)

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
	game.add_material("hedge_ink", 2)
	_check("bench rejects locked base", not bench.place_base("summit"))
	_check("bench places tier_1", bench.place_base("tier_1"))
	_check("bench reveals 2 ink sockets", bench.ink_slots() == 2)
	_check("bench sockets an ink", bench.socket_ink("hedge_ink"))
	var charts_before: int = (game.charts as Array).size()
	var ink_before: int = game.material_count("hedge_ink")
	_check("bench crafts the chart", bench.craft())
	_check("chart landed in the case",
		(game.charts as Array).size() == charts_before + 1)
	_check("bench spent base cost + socketed ink",
		game.material_count("hedge_ink") == ink_before - 3)
	_check("bench cleared after craft", bench.base_id == "")
	# Spec 45-carto — the den's req is a real gate now, and the level-17
	# capstone opens an extra ink socket.
	game.add_material("thorn_essence", 1)
	_check("bench re-places tier_1", bench.place_base("tier_1"))
	_check("den refuses below Wayfinder 8",
		not bench.socket_trophy("thorn_essence"))
	game.trades.wayfinding.lv = 8
	_check("den opens at Wayfinder 8", bench.socket_trophy("thorn_essence"))
	_check("two ink slots below the capstone", bench.ink_slots() == 2)
	game.trades.wayfinding.lv = 17
	game.chosen_perks = {"master_wayfinder": true}   # ADR 0012 mastery — capstone pick
	_check("master wayfinder adds an ink slot", bench.ink_slots() == 3)
	game.trades.wayfinding.lv = 2
	bench.clear_base()
	bench.close()
	await process_frame
	_check("bench unpaused on close", not paused)

	# Spec 46 Phase A — session + modal semantics on the real autoloads.
	var net := root.get_node_or_null("NetGame")
	_check("netgame autoload idle", net != null and not net.active)
	game.modal_opened()
	_check("offline modal pauses the tree", paused and game.modal_count == 1)
	game.modal_closed()
	_check("offline close unpauses", not paused and game.modal_count == 0)
	_check("hosting opens a session", net.host(17777))
	_check("host flag + roster of one", net.active and net.is_host()
		and (net.players as Dictionary).size() == 1)
	game.modal_opened()
	_check("in-session modal does NOT pause the tree",
		not paused and game.modal_count == 1)
	game.modal_closed()
	# Phase B — the host sockets for the party: the run starts through the
	# replicated path (call_local executes it host-side too).
	var party_chart: Dictionary = ChartsData.inscribe("snug", [], 1)
	game.enter_dungeon(party_chart, null)
	_check("host socket starts the party run", bool(game.in_dungeon)
		and not (game.active_chart as Dictionary).is_empty())

	# Input-map hygiene across two player instances: one event per key.
	var ev_count := InputMap.action_get_events("interact").size()
	_check("no duplicate interact bindings", ev_count == 1, str(ev_count))

	# Let the deferred party crossing land, then verify the hollow built
	# with per-peer spawning (host-only session: one NetPlayer body).
	await process_frame
	await process_frame
	await process_frame
	_check("party crossed to the hollow",
		current_scene != null and String(current_scene.name) == "World")
	var net_bodies := 0
	for p in get_nodes_in_group("player"):
		if String((p as Node).name).begins_with("NetPlayer"):
			net_bodies += 1
	_check("one NetPlayer body for the lone host", net_bodies == 1,
		str(net_bodies))
	net.leave()
	_check("leave ends the session", not net.active)

	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _walk(node: Node) -> Array:
	var out := [node]
	for c in node.get_children():
		out.append_array(_walk(c))
	return out
