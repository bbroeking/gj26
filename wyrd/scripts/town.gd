extends Node3D

# Wyrd — the Chartmaker's Yard, Bramblewood's edge. The town hub: a grassy
# clearing with the Wayfinder, the Inscribing Table, the Waystone, herb
# patches, and storybook dressing. Built in code (layout_loader pattern) so
# the .tscn stays a thin shell of environment + player + camera + HUD.

const GatherNodeScript = preload("res://scripts/gather_node.gd")
const WayfinderScript = preload("res://scripts/wayfinder_npc.gd")
const InscribingTableScript = preload("res://scripts/inscribing_table.gd")
const CraftStationScript = preload("res://scripts/craft_station.gd")
const PortalWaystoneScript = preload("res://scripts/portal_waystone.gd")
const VendorScript = preload("res://scripts/vendor_npc.gd")
const QuillScript = preload("res://scripts/quill_npc.gd")

const OAK_GLB := preload("res://models/oak_v4.glb")
const WELL_GLB := preload("res://models/well_v2.glb")
const SIGNPOST_GLB := preload("res://models/signpost_v2.glb")
# Meshy storybook cottage (2026-06-10 environment pass) — replaced the
# blocky cottage_v3 placeholder.
const COTTAGE_GLB := preload("res://models/building_cottage_v1.glb")
const STALL_GLB := preload("res://models/prop_market_stall_v1.glb")
const FORGE_GLB := preload("res://models/forge_v2.glb")
const TOWER_GLB := preload("res://models/chartmaker_tower.glb")

const YARD := 40.0                    # clearing is YARD × YARD meters
const LAYER_WORLD := 1

# Net co-op: peers fan into a small arc just behind the solo spawn.
# net_game.gd:_spawn_pos reads this before falling back to PLAYER_SPAWN.
var net_spawn: Vector3 = Vector3(20.0, 0.0, 27.2)

# Fixed placements — hand-laid so the yard reads the same every visit.
const PLAYER_SPAWN := Vector3(20.0, 0.0, 26.0)
const WAYFINDER_POS := Vector3(20.0, 0.0, 17.0)
const TABLE_POS := Vector3(15.5, 0.0, 15.0)
const WAYSTONE_POS := Vector3(27.0, 0.0, 12.0)
const WELL_POS := Vector3(13.0, 0.0, 22.0)
const SIGNPOST_POS := Vector3(23.5, 0.0, 24.0)
# Buildings line the north edge so the yard stays open for play.
const COTTAGE_POS := Vector3(8.0, 0.0, 8.5)
const FORGE_POS := Vector3(33.0, 0.0, 9.5)
const TOWER_POS := Vector3(20.5, 0.0, 5.5)   # the Chartmaker's tower — the landmark
# A8-full — the herbalist's corner, by the south-west herb beds.
const QUILL_POS := Vector3(11.0, 0.0, 29.5)
const STILL_POS := Vector3(13.0, 0.0, 30.5)
const HERB_PATCHES := [
	Vector3(10.0, 0.0, 12.0), Vector3(9.0, 0.0, 27.0),
	Vector3(17.0, 0.0, 31.0), Vector3(30.0, 0.0, 24.0),
	Vector3(31.0, 0.0, 17.0), Vector3(24.0, 0.0, 8.0),
]
# Town skill stations (2026-06-10) — every gather verb is practicable in
# the yard: Hod's spoil heap gives mining, the woodpile gives chopping.
const ORE_ROCKS := [
	Vector3(35.5, 0.0, 13.0), Vector3(36.5, 0.0, 15.0), Vector3(34.5, 0.0, 16.5),
]
const LOG_PILES := [
	Vector3(11.0, 0.0, 6.5), Vector3(13.0, 0.0, 7.5), Vector3(5.5, 0.0, 12.0),
]
const OAKS := [
	Vector3(5.0, 0.0, 6.0), Vector3(34.0, 0.0, 5.5), Vector3(36.0, 0.0, 30.0),
	Vector3(5.5, 0.0, 33.0), Vector3(12.0, 0.0, 5.0), Vector3(28.5, 0.0, 34.0),
]

func _ready() -> void:
	# B7 — arrival beat: if we're returning from a delve, delay music and ease
	# the camera in. On cold boot play music immediately (existing behaviour).
	# game.gd._returning_from_delve is set in return_to_town before scene change;
	# reading via get() is null-safe if the flag doesn't exist yet.
	var game_node: Node = get_node_or_null("/root/Game")
	var returning: bool = game_node != null and game_node.get("_returning_from_delve") == true
	if returning:
		game_node.set("_returning_from_delve", false)
		# Delay the town music so the player savours the beat, then play.
		get_tree().create_timer(0.3).timeout.connect(func() -> void:
			var sfx2 := get_node_or_null("/root/Sfx")
			if sfx2 != null and sfx2.has_method("music"):
				sfx2.music("town_theme")
			if sfx2 != null and sfx2.has_method("play"):
				sfx2.play("town_arrival_swell")
		)
		# Nudge the camera to a slightly pulled-out zoom; it lerps back naturally.
		var rig: Node = get_tree().get_first_node_in_group("camera_rig")
		if rig != null:
			var z_def: Variant = rig.get("ZOOM_DEFAULT")
			if z_def != null:
				rig.set("_zoom_target", float(z_def) + 4.0)
	else:
		var sfx := get_node_or_null("/root/Sfx")
		if sfx != null and sfx.has_method("music"):
			sfx.music("town_theme")
	_build_ground()
	_build_bounds()
	_place_stations()
	_place_dressing()
	_place_herb_patches()
	_build_environment()
	# B7 — Living Atlas board: reflect progression state and wire leveled_up.
	_on_board_update()
	if game_node != null and game_node.has_signal("leveled_up"):
		game_node.leveled_up.connect(func(_t: String, _lv: int) -> void:
			_on_board_update())
	# B7 — ambient life: jittered bird + fire SFX timers (silent stubs until
	# audio drops; graceful no-op via sfx.play missing-key path).
	_schedule_ambient("town_ambient_birds", 8.0, 15.0, 0.12)
	_schedule_ambient("town_fire_crackle", 6.0, 10.0, 0.18)
	# Spec 46 Phase A — in a co-op session the baked single-player body is
	# replaced by one player per peer; offline keeps the shipped path.
	if NetGame.active:
		NetGame.setup_scene(self)
	else:
		_position_player()
	# Dev: WYRD_NET=host | join:<ip[:port]> — light/join a fire at boot.
	var net_env := OS.get_environment("WYRD_NET")
	if net_env == "host" and not NetGame.active:
		NetGame.host()
		NetGame.setup_scene(self)
	elif net_env.begins_with("join:") and not NetGame.active:
		var addr := net_env.trim_prefix("join:")
		var port := NetGame.DEFAULT_PORT
		if ":" in addr:
			port = int(addr.split(":")[1])
			addr = addr.split(":")[0]
		NetGame.join(addr, port)
		NetGame.roster_changed.connect(func():
			NetGame.setup_scene(self), CONNECT_ONE_SHOT)
	# Dev: WYRD_NET_RUN=<sec> — a hosting boot sockets a Tier 1 chart after
	# N seconds (the two-process dungeon co-op smoke test).
	if OS.get_environment("WYRD_NET_RUN") != "" and net_env == "host":
		var delay := float(OS.get_environment("WYRD_NET_RUN"))
		get_tree().create_timer(delay).timeout.connect(func():
			var game := get_tree().root.get_node_or_null("Game")
			if game == null:
				return
			# WYRD_NET_RUN_BOSS=<trophy_id> forces a boss den (e.g.
			# thorn_essence → hedgemother_den) for co-op boss-fight testing.
			var trophy := OS.get_environment("WYRD_NET_RUN_BOSS")
			var chart: Dictionary = load("res://data/charts.gd") \
				.inscribe("tier_1", [], 9, trophy)
			game.enter_dungeon(chart, null))
	# Dev: WYRD_SHOT=1 godot ... → save /tmp/wyrd_town.png after the scene
	# settles (layout_loader's DEBUG_SHOT pattern).
	if OS.get_environment("WYRD_SHOT") != "":
		get_tree().create_timer(2.0).timeout.connect(_debug_screenshot)
	# Dev: WYRD_UI_SHOT=1 — pop the Inscribing Table panel (with sample
	# satchel contents) before the screenshot fires, for UI iteration.
	if OS.get_environment("WYRD_UI_SHOT") != "":
		get_tree().create_timer(0.8).timeout.connect(func():
			var game := get_tree().root.get_node_or_null("Game")
			if game != null:
				game.add_material("wild_herb", 4)
				game.add_material("hedge_ink", 3)
				game.add_material("bogiron_ore", 2)
				game.add_material("thorn_essence", 1)
				game.add_material("hearth_draught", 3)
				game.add_material("quickroot_tonic", 2)
			if OS.get_environment("WYRD_UI_SHOT") == "trades":
				var player2: Node = game.local_player()
				if player2 != null:
					player2.toggle_trades()
			elif OS.get_environment("WYRD_UI_SHOT") in ["satchel", "charts"]:
				var player3: Node = game.local_player()
				var tab := 1 if OS.get_environment("WYRD_UI_SHOT") == "satchel" else 2
				if player3 != null and player3._inv_root != null:
					player3._inv_root.open_tab(tab)
			elif OS.get_environment("WYRD_UI_SHOT") == "vendor":
				var vpanel: CanvasLayer = load("res://scripts/ui/vendor_panel.gd").new()
				add_child(vpanel)
			elif OS.get_environment("WYRD_UI_SHOT") == "hud":
				pass   # bare HUD — globes, skill bar, quest plate
			elif OS.get_environment("WYRD_UI_SHOT") == "pack":
				var items_data = load("res://data/items.gd")
				for spec in [["shortbow", "rare"], ["leather_helm", "magic"],
						["leather_boots", "normal"], ["copper_ring", "unique"]]:
					var it: Dictionary = items_data.make_item(spec[0], spec[1])
					var fit: Dictionary = game.inventory.find_first_fit(it)
					if not fit.is_empty():
						game.inventory.try_place(it, fit.pos, fit.rotated)
				game.equipment.slots["chest"] = items_data.make_item("leather_chest", "magic")
				var player: Node = game.local_player()
				if player != null:
					player.toggle_inventory()
			elif OS.get_environment("WYRD_UI_SHOT") in ["cook", "smith"]:
				var sid := "cookfire" \
					if OS.get_environment("WYRD_UI_SHOT") == "cook" else "forge"
				if game != null:
					game.add_material("bogiron_ore", 4)
				var cpanel: CanvasLayer = load("res://scripts/ui/craft_panel.gd").new()
				cpanel.station_id = sid
				add_child(cpanel)
			elif OS.get_environment("WYRD_UI_SHOT") == "lantern":
				var lm: CanvasLayer = load("res://scripts/ui/system_menu.gd").new()
				add_child(lm)
			elif OS.get_environment("WYRD_UI_SHOT") == "dialog":
				var dlg: CanvasLayer = load("res://scripts/ui/dialog_panel.gd").new()
				dlg.open("Mara Linnet, the Wayfinder",
					["New boots — good. The yard's paths won't walk themselves, and "
					+ "the deeper dens don't forgive soft soles. Inscribe a chart when "
					+ "you're ready and I'll read what the brambles have to say."],
					null, ["Tell me about charts.", "Not just yet."])
				add_child(dlg)
			elif OS.get_environment("WYRD_UI_SHOT") == "loadout":
				add_child(load("res://scripts/ui/loadout_panel.gd").new())
			elif OS.get_environment("WYRD_UI_SHOT") == "credits":
				add_child(load("res://scripts/ui/credits_menu.gd").new())
			elif OS.get_environment("WYRD_UI_SHOT") == "options":
				add_child(load("res://scripts/ui/options_menu.gd").new())
			elif OS.get_environment("WYRD_UI_SHOT") == "enchant":
				# The Charm Table — stage equipped gear + reagents + a learned
				# rare charm so every column renders.
				var items_e = load("res://data/items.gd")
				if game != null:
					game.equipment.slots["weapon"] = items_e.make_item("shortbow", "rare")
					game.equipment.slots["ring"] = items_e.make_item("copper_ring", "magic")
					var bow_e = game.equipment.slots["weapon"]
					bow_e.enchants = ["emberbind"]
					game.add_material("glimmerdust", 6)
					game.add_material("emberglass", 4)
					game.add_material("dewthread", 5)
					game.discover_enchant("galebrand")
					game.equipment.changed.emit()
				add_child(load("res://scripts/ui/enchant_panel.gd").new())
			else:
				# "table"/"bench"/anything else — the crafting bench (spec 42).
				# "bench_staged" pre-fills it for visual iteration.
				var panel: CanvasLayer = load("res://scripts/ui/crafting_bench.gd").new()
				add_child(panel)
				if OS.get_environment("WYRD_UI_SHOT") == "bench_staged" and game != null:
					game.add_material("hedge_ink", 3)
					game.add_material("thorn_essence", 1)
					panel.place_base.call_deferred("tier_1")
					panel.socket_ink.call_deferred("hedge_ink")
					panel.socket_trophy.call_deferred("thorn_essence")
					panel.pot_add.call_deferred("wild_herb")
					panel.pot_add.call_deferred("wild_herb"))

func _debug_screenshot() -> void:
	var path := OS.get_environment("WYRD_SHOT_PATH")
	if path == "":
		path = "/tmp/wyrd_town.png"
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(path)
	print("[town] debug screenshot → %s (err=%d)" % [path, err])

func _build_ground() -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(YARD, YARD)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	# Mottled storybook meadow (TownEnvironment owns the shader) — the flat
	# single-green plane was most of why the yard read as an empty field.
	mi.material_override = TownEnvironment.ground_material()
	mi.position = Vector3(YARD * 0.5, 0.0, YARD * 0.5)
	add_child(mi)
	var body := StaticBody3D.new()
	body.name = "Ground"
	body.collision_layer = LAYER_WORLD
	body.collision_mask = 0
	var shape := BoxShape3D.new()
	shape.size = Vector3(YARD, 0.2, YARD)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(YARD * 0.5, -0.1, YARD * 0.5)
	body.add_child(col)
	add_child(body)

# Invisible walls at the clearing edge so nobody walks off the world.
func _build_bounds() -> void:
	var body := StaticBody3D.new()
	body.name = "Bounds"
	body.collision_layer = LAYER_WORLD
	body.collision_mask = 0
	for side in 4:
		var shape := BoxShape3D.new()
		shape.size = Vector3(YARD + 2.0, 4.0, 1.0)
		var col := CollisionShape3D.new()
		col.shape = shape
		match side:
			0: col.position = Vector3(YARD * 0.5, 2.0, -0.5)
			1: col.position = Vector3(YARD * 0.5, 2.0, YARD + 0.5)
			2:
				col.position = Vector3(-0.5, 2.0, YARD * 0.5)
				col.rotation.y = PI / 2.0
			3:
				col.position = Vector3(YARD + 0.5, 2.0, YARD * 0.5)
				col.rotation.y = PI / 2.0
		body.add_child(col)
	add_child(body)

func _place_stations() -> void:
	var npc: Node3D = WayfinderScript.new()
	npc.position = WAYFINDER_POS
	npc.rotation.y = PI            # face the spawn
	add_child(npc)
	var table: Node3D = InscribingTableScript.new()
	table.position = TABLE_POS
	add_child(table)
	var stone: Node3D = PortalWaystoneScript.new()
	stone.position = WAYSTONE_POS
	add_child(stone)
	# Hod minds his counter just south of the forge.
	var hod: Node3D = VendorScript.new()
	hod.position = FORGE_POS + Vector3(-1.5, 0.0, 3.0)
	hod.rotation.y = PI * 0.85     # face the yard
	add_child(hod)
	# A8-lite — the cookfire by the cottage door (herbs + log → draught).
	var hearth: Node3D = CraftStationScript.new()
	hearth.setup("cookfire")
	hearth.position = COTTAGE_POS + Vector3(2.8, 0.0, 2.6)
	add_child(hearth)
	# A7-lite — Hod's anvil beside the forge (ore → bar → gear).
	var anvil: Node3D = CraftStationScript.new()
	anvil.setup("forge")
	anvil.position = FORGE_POS + Vector3(1.6, 0.0, 3.2)
	add_child(anvil)
	# A8-full — Quill minds the herb corner, her still at her elbow.
	var quill: Node3D = QuillScript.new()
	quill.position = QUILL_POS
	quill.rotation.y = -PI * 0.3           # face the yard
	add_child(quill)
	var still: Node3D = CraftStationScript.new()
	still.setup("still")
	still.position = STILL_POS
	add_child(still)

func _place_dressing() -> void:
	# (The old 6-oak scatter is gone — TownEnvironment's treeline ring
	# encloses the clearing instead.)
	_place_glb(WELL_GLB, WELL_POS, 1.6, 0.9)
	_place_glb(SIGNPOST_GLB, SIGNPOST_POS, 1.9, 0.4)
	# Buildings — the yard reads as Bramblewood's edge, not an empty field.
	_place_glb(COTTAGE_GLB, COTTAGE_POS, 4.5, 3.0)
	_place_glb(FORGE_GLB, FORGE_POS, 4.0, 2.8)
	_place_glb(TOWER_GLB, TOWER_POS, 7.5, 2.2)
	# Hod's market stall — his counter, between the forge and the yard.
	_place_glb(STALL_GLB, FORGE_POS + Vector3(-3.8, 0.0, 3.2), 2.2, 1.2)
	# B7 — Living Atlas board: a parchment quad on the Tower's south wall.
	# _on_board_update() lights it with emissive proportional to Wayfinding lv.
	var board := MeshInstance3D.new()
	var bm := QuadMesh.new()
	bm.size = Vector2(0.8, 0.6)
	board.mesh = bm
	board.name = "AtlasBoard"
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.88, 0.82, 0.65)   # parchment
	bmat.roughness = 0.9
	bmat.emission_enabled = true
	bmat.emission = Color(0.9, 0.85, 0.6)
	bmat.emission_energy_multiplier = 0.0
	board.material_override = bmat
	board.position = Vector3(20.5, 1.6, 8.0)
	board.rotation.x = -0.12   # tilt toward the yard slightly
	add_child(board)

# The density pass: paths, treeline, grass, flowers, scatter dressing.
func _build_environment() -> void:
	var env := TownEnvironment.new()
	env.setup(YARD, Vector3(20.0, 0.0, 21.0),
		# Everything grass must keep clear of...
		[PLAYER_SPAWN, WAYFINDER_POS, TABLE_POS, WAYSTONE_POS, WELL_POS,
			SIGNPOST_POS, COTTAGE_POS, FORGE_POS, TOWER_POS,
			FORGE_POS + Vector3(-1.5, 0.0, 3.0),
			COTTAGE_POS + Vector3(2.8, 0.0, 2.6),
			FORGE_POS + Vector3(1.6, 0.0, 3.2),
			QUILL_POS, STILL_POS],
		# ...but only the stations a footpath would actually wear in.
		[PLAYER_SPAWN, WAYFINDER_POS, TABLE_POS, WAYSTONE_POS,
			FORGE_POS + Vector3(-1.5, 0.0, 3.0), COTTAGE_POS, STILL_POS])
	add_child(env)

func _place_herb_patches() -> void:
	for pos in HERB_PATCHES:
		var node: Node3D = GatherNodeScript.new()
		node.setup("forage_node", "wild_herb", true)   # town patches regrow
		node.position = pos
		add_child(node)
		# B7 — connect regrew if gather_node.gd exposes it (deferred if not yet).
		if node.has_signal("regrew"):
			node.regrew.connect(_on_node_regrew)
	# Spec 45-wilds — one bittergrass patch by Quill's still, locked until
	# Wildcraft 3 (visible and coveted, like Hod's bogiron).
	var bitter: Node3D = GatherNodeScript.new()
	bitter.setup("forage_node", "bittergrass", true)
	bitter.setup_herb_tier("bittergrass")
	bitter.position = STILL_POS + Vector3(-1.6, 0.0, 1.2)
	add_child(bitter)
	if bitter.has_signal("regrew"):
		bitter.regrew.connect(_on_node_regrew)
	# Hod's spoil heap — A6 tiers: two copper starters and one bogiron
	# vein that stands locked until Earthcraft 3 (visible, coveted).
	var heap_tiers := ["copper", "copper", "bogiron"]
	for i in ORE_ROCKS.size():
		var rock: Node3D = GatherNodeScript.new()
		rock.setup("ore_rock", "copper_ore", true)
		rock.setup_ore_tier(heap_tiers[mini(i, heap_tiers.size() - 1)])
		rock.respawn_sec = 40.0        # ore is slower than herbs by design
		rock.position = ORE_ROCKS[i]
		add_child(rock)
		if rock.has_signal("regrew"):
			rock.regrew.connect(_on_node_regrew)
	# The woodpile by the cottage.
	for pos in LOG_PILES:
		var pile: Node3D = GatherNodeScript.new()
		pile.setup("log_pile", "logs", true)
		pile.respawn_sec = 30.0
		pile.position = pos
		add_child(pile)
		if pile.has_signal("regrew"):
			pile.regrew.connect(_on_node_regrew)

func _place_glb(packed: PackedScene, pos: Vector3, target_h: float,
		collider_radius: float) -> void:
	var inst: Node3D = packed.instantiate()
	GlbFit.normalize_height(inst, target_h)
	_unmetal(inst)
	if collider_radius > 0.0:
		var body := StaticBody3D.new()
		body.position = pos
		body.collision_layer = LAYER_WORLD
		body.collision_mask = 0
		var shape := CylinderShape3D.new()
		shape.radius = collider_radius
		shape.height = target_h
		var col := CollisionShape3D.new()
		col.shape = shape
		col.position = Vector3(0.0, target_h * 0.5, 0.0)
		body.add_child(col)
		body.add_child(inst)
		add_child(body)
	else:
		inst.position = pos
		add_child(inst)

func _position_player() -> void:
	var game := get_node_or_null("/root/Game")
	var player: Node = game.local_player() if game != null else null
	if player != null and player is Node3D:
		(player as Node3D).position = PLAYER_SPAWN
		if player.has_method("set_spawn"):
			player.set_spawn(PLAYER_SPAWN)

# ---- GLB fixups (layout_loader pattern) ----

func _unmetal(root: Node) -> void:
	for vi in _all_visual_instances(root):
		if vi is MeshInstance3D:
			var m: Mesh = (vi as MeshInstance3D).mesh
			if m == null:
				continue
			for s in range(m.get_surface_count()):
				var mat := m.surface_get_material(s)
				if mat is BaseMaterial3D:
					(mat as BaseMaterial3D).metallic = 0.0
					(mat as BaseMaterial3D).metallic_specular = 0.2

func _all_visual_instances(node: Node) -> Array:
	var out := []
	if node is VisualInstance3D:
		out.append(node)
	for c in node.get_children():
		out.append_array(_all_visual_instances(c))
	return out

# ---- B7 — ambient life helpers ----

# Called when a gather node regrows. Plays the pop SFX and spawns a leaf
# mote burst. Wired in _place_herb_patches() via has_signal() guard so it
# compiles even before gather_node.gd exposes the regrew signal.
func _on_node_regrew(pos: Vector3) -> void:
	var sfx := get_node_or_null("/root/Sfx")
	if sfx != null and sfx.has_method("play"):
		sfx.play("regrow_pop")
	_spawn_regrow_motes(pos)
	print("[town] regrow pop at (%.1f, %.1f)" % [pos.x, pos.z])

# Six cheap procedural leaf-motes that back-out upward and free themselves.
# Pure MeshInstance3D + tweens — no texture load, no scene required.
func _spawn_regrow_motes(origin: Vector3) -> void:
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = int(origin.x * 1000.0 + origin.z)
	for i in 6:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.045
		sm.height = 0.09
		sm.radial_segments = 5
		sm.rings = 2
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.42, 0.72, 0.35)
		mat.roughness = 1.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA   # so the fade renders
		mi.mesh = sm
		mi.material_override = mat
		mi.position = origin + Vector3(
			rng2.randf_range(-0.3, 0.3), 0.1, rng2.randf_range(-0.3, 0.3))
		add_child(mi)
		var t := create_tween()
		t.tween_property(mi, "position:y", origin.y + 0.8, 0.4) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		# Fade via the 3D material's albedo alpha — MeshInstance3D has no modulate.
		t.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.35).set_delay(0.1)
		t.chain().tween_callback(mi.queue_free)

# Living Atlas board: update emissive energy to reflect Wayfinding level
# and summit state. Pulses with a back-out overshoot on new unlocks.
func _on_board_update() -> void:
	var board: Node = get_node_or_null("AtlasBoard")
	var game3: Node = get_node_or_null("/root/Game")
	if board == null or game3 == null:
		return
	var lv: int = int(game3.call("trade_lv", "wayfinding"))
	var cleared: bool = game3.get("summit_cleared") == true
	var base_e: float = clampf(float(lv - 1) / 10.0, 0.0, 1.0)
	if cleared:
		base_e = 1.2
	var mat: StandardMaterial3D = (board as MeshInstance3D).material_override as StandardMaterial3D
	if mat == null:
		return
	if base_e > 0.0:
		# Pulse: overshoot then settle so the board visibly reacts to each tier.
		var captured_mat := mat
		var peak := base_e * 2.0
		var settle := base_e
		var fn := func(v: float) -> void:
			if is_instance_valid(captured_mat):
				captured_mat.emission_energy_multiplier = v
		var t := create_tween()
		t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_method(fn, peak, settle, 0.6)
	else:
		mat.emission_energy_multiplier = 0.0
	print("[town] board updated: lv=%d cleared=%s energy=%.2f" % [lv, cleared, base_e])

# Jittered ambient SFX timer — loops at a random interval in [min_sec, max_sec].
# Graceful no-op if the audio file is missing (sfx.play already handles it).
func _schedule_ambient(key: String, min_sec: float, max_sec: float,
		_vol_scale: float) -> void:
	var rng3 := RandomNumberGenerator.new()
	rng3.seed = 26 + key.hash()
	var delay := rng3.randf_range(min_sec, max_sec)
	if not is_inside_tree():
		return
	get_tree().create_timer(delay).timeout.connect(func() -> void:
		var sfx4 := get_node_or_null("/root/Sfx")
		if sfx4 != null and sfx4.has_method("play"):
			sfx4.play(key)
		_schedule_ambient(key, min_sec, max_sec, _vol_scale)
	)
