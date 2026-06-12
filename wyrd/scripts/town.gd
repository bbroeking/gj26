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
	var sfx := get_node_or_null("/root/Sfx")
	if sfx != null and sfx.has_method("music"):
		sfx.music("town_theme")
	_build_ground()
	_build_bounds()
	_place_stations()
	_place_dressing()
	_place_herb_patches()
	_build_environment()
	_position_player()
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
			if OS.get_environment("WYRD_UI_SHOT") == "trades":
				var player2 := get_tree().get_first_node_in_group("player")
				if player2 != null:
					player2.toggle_trades()
			elif OS.get_environment("WYRD_UI_SHOT") in ["satchel", "charts"]:
				var player3 := get_tree().get_first_node_in_group("player")
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
				var player := get_tree().get_first_node_in_group("player")
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
			elif OS.get_environment("WYRD_UI_SHOT") == "dialog":
				var dlg: CanvasLayer = load("res://scripts/ui/dialog_panel.gd").new()
				dlg.open("Mara Linnet, the Wayfinder",
					["New boots. Good — the yard could use a pair."])
				add_child(dlg)
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
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png("/tmp/wyrd_town.png")
	print("[town] debug screenshot → /tmp/wyrd_town.png (err=%d)" % err)

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
	# Spec 45-wilds — one bittergrass patch by Quill's still, locked until
	# Wildcraft 3 (visible and coveted, like Hod's bogiron).
	var bitter: Node3D = GatherNodeScript.new()
	bitter.setup("forage_node", "bittergrass", true)
	bitter.setup_herb_tier("bittergrass")
	bitter.position = STILL_POS + Vector3(-1.6, 0.0, 1.2)
	add_child(bitter)
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
	# The woodpile by the cottage.
	for pos in LOG_PILES:
		var pile: Node3D = GatherNodeScript.new()
		pile.setup("log_pile", "logs", true)
		pile.respawn_sec = 30.0
		pile.position = pos
		add_child(pile)

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
	var player := get_tree().get_first_node_in_group("player")
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
