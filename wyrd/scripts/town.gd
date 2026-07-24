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
const DialogPanelScript = preload("res://scripts/ui/dialog_panel.gd")
const MicroCutsceneScript = preload("res://scripts/ui/micro_cutscene.gd")
const PracticeBrambleScript = preload("res://scripts/practice_bramble.gd")
const LivingAtlasPanelScript = preload("res://scripts/living_atlas_panel.gd")
const MaraRainNoteScript = preload("res://scripts/mara_rain_note.gd")
const TrophyHallScript = preload("res://scripts/trophy_hall.gd")
const SallowJettyScript = preload("res://scripts/sallow_jetty.gd")
const SkaldArchiveScript = preload("res://scripts/skald_archive.gd")
const RootroadLiftScript = preload("res://scripts/rootroad_lift.gd")
const HuntersLodgeLessonScript = preload("res://scripts/hunters_lodge_lesson.gd")
const MasteryStationScript = preload("res://scripts/mastery_station.gd")

const OAK_GLB := preload("res://models/oak_v4.glb")
const WELL_GLB := preload("res://models/well_v2.glb")
const SIGNPOST_GLB := preload("res://models/signpost_v2.glb")
# Exterior-only Meshy town set (2026-07-17). These are facade/landmark shells;
# the town has no interior scene transitions.
const COTTAGE_GLB := preload("res://models/building_mauds_hearth_v1.glb")
const FORGE_GLB := preload("res://models/building_hods_smithy_v1.glb")
const TOWER_GLB := preload("res://models/building_chartmaker_tower_v1.glb")
const FIRST_ROAD_LAMP_GLB := preload("res://models/memorial_lantern_v2.glb")

const YARD := 40.0                    # clearing is YARD × YARD meters
const LAYER_WORLD := 1
# Spec 77 — Town keeps the shared FATE camera, but gathers the north yard into
# the playable frame. A camera-relative forward bias keeps the ranger low in
# frame through player orbit instead of pinning the view to world north.
const TOWN_CAMERA_PITCH := 38.0
const TOWN_CAMERA_ZOOM := 20.5
const TOWN_CAMERA_FORWARD_FRAME := 3.5

# Net co-op: peers fan into a small arc just behind the solo spawn.
# net_game.gd:_spawn_pos reads this before falling back to PLAYER_SPAWN.
var net_spawn: Vector3 = Vector3(20.0, 0.0, 27.2)

# Fixed placements — hand-laid so the yard reads the same every visit.
const PLAYER_SPAWN := Vector3(20.0, 0.0, 26.0)
const WAYFINDER_POS := Vector3(20.0, 0.0, 17.0)
const TABLE_POS := Vector3(15.5, 0.0, 15.0)
const RAIN_NOTE_POS := Vector3(17.6, 0.0, 14.3)
const WAYSTONE_POS := Vector3(27.0, 0.0, 12.0)
const PRACTICE_POS := Vector3(20.0, 0.0, 12.0)
const FIRST_ROAD_LAMP_POS := Vector3(23.3, 0.0, 18.8)
const WELL_POS := Vector3(13.0, 0.0, 22.0)
const SIGNPOST_POS := Vector3(23.5, 0.0, 24.0)
# Spec 78 — the three existing exteriors form one north-yard working edge. The
# modest southward staging brings their lower facades into the accepted camera
# without taking the central crossing or adding another landmark.
const COTTAGE_POS := Vector3(10.5, 0.0, 10.0)
const FORGE_POS := Vector3(31.5, 0.0, 10.0)
const TOWER_POS := Vector3(20.5, 0.0, 8.5)   # the Chartmaker's tower — the landmark
const COTTAGE_RADIUS := 3.2
const FORGE_RADIUS := 3.3
const TOWER_RADIUS := 2.4
const COTTAGE_HEIGHT := 5.0
const FORGE_HEIGHT := 5.0
const TOWER_HEIGHT := 8.5
# A8-full — the herbalist's corner, by the south-west herb beds.
const QUILL_POS := Vector3(11.0, 0.0, 29.5)
const STILL_POS := Vector3(13.0, 0.0, 30.5)
# First Knot's small outdoor alcove sits at the west edge of the yard. It is
# only placed from the authoritative Homecoming projection, never as dormant
# ruined geometry that would imply a restoration before it exists.
const TROPHY_HALL_POS := Vector3(8.0, 0.0, 19.5)
# Golden Wallow restores a wet-road launch at the south-east yard edge. The
# authored model points inward so its landing remains inside the walkable yard.
const SALLOW_JETTY_POS := Vector3(34.0, 0.0, 31.5)
# The Seventh Road restores a small open archive opposite the wet-road Jetty.
# Its inward-facing lectern keeps the yard's central paths unobstructed.
const SKALD_ARCHIVE_POS := Vector3(6.5, 0.0, 25.0)
# The final Pale Oath settlement restores one rooted landmark: the Lift and
# Hod's oath-stone share this position and one `rootroad_lift` projection.
const ROOTROAD_LIFT_POS := Vector3(34.0, 0.0, 23.0)
const EMBER_KILN_POS := Vector3(29.8, 0.0, 29.0)
const HUNTERS_LODGE_POS := Vector3(27.6, 0.0, 18.8)
# D8's mastered work remains in the yard: the small stations deliberately use
# the familiar work corners rather than opening another interior or a second
# inventory authority.  Their visibility is only a presentation projection;
# Game rechecks every trade, campaign, material, and placement fact on commit.
const HOD_MASTERY_POS := FORGE_POS + Vector3(3.25, 0.0, 2.35)
const QUILL_MASTERY_POS := STILL_POS + Vector3(1.72, 0.0, 0.70)
const MASTER_HUNT_POS := HUNTERS_LODGE_POS + Vector3(-0.60, 0.0, 2.15)
const MASTER_FORGE_POS := FORGE_POS + Vector3(3.85, 0.0, -0.62)
const AWAKE_LOOM_LOCAL_POS := Vector3(0.86, 0.0, 0.18)
const HERB_PATCHES := [
	Vector3(10.0, 0.0, 12.0), Vector3(9.0, 0.0, 27.0),
	Vector3(17.0, 0.0, 31.0), Vector3(30.0, 0.0, 24.0),
	Vector3(31.0, 0.0, 17.0), Vector3(24.0, 0.0, 8.0),
]
# Town skill stations (2026-06-10) — every gather verb is practicable in
# the yard: Hod's spoil heap gives mining, the woodpile gives chopping.
const ORE_ROCKS := [
	FORGE_POS + Vector3(5.0, 0.0, 5.0),
	FORGE_POS + Vector3(6.0, 0.0, 7.0),
	FORGE_POS + Vector3(4.0, 0.0, 8.5),
]
const LOG_PILES := [
	COTTAGE_POS + Vector3(1.5, 0.0, -1.5),
	COTTAGE_POS + Vector3(3.5, 0.0, -0.5),
	Vector3(5.5, 0.0, 12.0),
]
const OAKS := [
	Vector3(5.0, 0.0, 6.0), Vector3(34.0, 0.0, 5.5), Vector3(36.0, 0.0, 30.0),
	Vector3(5.5, 0.0, 33.0), Vector3(12.0, 0.0, 5.0), Vector3(28.5, 0.0, 34.0),
]

var _micro_cutscene: CanvasLayer = null
var _arrival_cover: CanvasLayer = null
var _arrival_cover_rect: ColorRect = null
var _pending_tutorial_vignette := -1
var _homecoming_view: Dictionary = {}
var _homecoming_waiting_for_modal := false
var _settlement_view: Dictionary = {}
var _settlement_waiting_for_modal := false
static var _session_homecoming_debriefs: Dictionary = {}
static var _session_settlement_debriefs: Dictionary = {}

func _ready() -> void:
	_apply_town_tonal_grade(OS.get_environment("WYRD_FORCE_TOWN_WEB_GRADE"))
	_apply_town_camera_profile()
	# B7 — arrival beat: if we're returning from a delve, delay music and ease
	# the camera in. On cold boot play music immediately (existing behaviour).
	# game.gd._returning_from_delve is set in return_to_town before scene change;
	# reading via get() is null-safe if the flag doesn't exist yet.
	var game_node: Node = get_node_or_null("/root/Game")
	if _should_cover_first_arrival(game_node):
		_build_first_arrival_cover()
	if game_node != null and game_node.has_method("record_onboarding_event"):
		game_node.record_onboarding_event("town_scene_ready")
	if game_node != null and int(game_node.get("_onboarding_progress_msec")) == -1 \
			and game_node.has_method("mark_onboarding_progress"):
		game_node.mark_onboarding_progress()
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
	_place_first_road_payoff()
	_place_dressing()
	_place_herb_patches()
	# Homecoming has one owner for truth. Cache one presentation view and pass
	# that exact projection to each visual surface built in this Town instance.
	_settlement_view = _campaign_settlement_view()
	_homecoming_view = _first_knot_homecoming_view()
	_apply_first_knot_homecoming()
	_apply_campaign_settlement()
	_apply_wayweaver_mastery_stations()
	_apply_driving_volley_lesson()
	# Build paths only after campaign projections exist. The old order carved
	# roads toward every possible late-game landmark even on a fresh save,
	# producing a web of empty paths and making the town feel asset-spammed.
	_build_environment()
	if NetGame.has_signal("homecoming_view_changed") \
			and not NetGame.homecoming_view_changed.is_connected(\
				_refresh_first_knot_homecoming_view):
		NetGame.homecoming_view_changed.connect(_refresh_first_knot_homecoming_view)
	if NetGame.has_signal("settlement_view_changed") \
			and not NetGame.settlement_view_changed.is_connected(\
				_refresh_campaign_settlement_view):
		NetGame.settlement_view_changed.connect(_refresh_campaign_settlement_view)
	# B7 — Living Atlas board: reflect progression state and wire leveled_up.
	_on_board_update()
	if game_node != null and game_node.has_method("web_smoke_scene_ready"):
		game_node.web_smoke_scene_ready("Town")
	if game_node != null and game_node.has_signal("leveled_up"):
		game_node.leveled_up.connect(func(_t: String, _lv: int) -> void:
			_on_board_update()
			_apply_wayweaver_mastery_stations())
	if game_node != null and game_node.has_signal("crafted"):
		# A mastery conversion can advance Core→Frame or Cord→Draught while
		# this Town remains loaded.  Refreshing is view-only; the station panel
		# itself still calls the sole Game transaction wrapper.
		game_node.crafted.connect(func(_station_id: String) -> void:
			_apply_wayweaver_mastery_stations())
	if game_node != null and game_node.has_signal("tutorial_changed"):
		game_node.tutorial_changed.connect(_on_tutorial_vignette_step)
	if game_node != null and game_node.has_signal("modal_changed"):
		game_node.modal_changed.connect(_on_tutorial_modal_changed)
	# B7 — ambient life: jittered bird + fire SFX timers (silent stubs until
	# audio drops; graceful no-op via sfx.play missing-key path).
	_schedule_ambient("town_ambient_birds", 8.0, 15.0, 0.12)
	_schedule_ambient("town_fire_crackle", 6.0, 10.0, 0.18)
	_position_player()
	if _arrival_cover != null:
		_reveal_first_arrival.call_deferred()
	else:
		_maybe_play_arrival_vignette.call_deferred()
	_show_pending_run_debrief.call_deferred()
	_maybe_show_first_knot_homecoming_debrief.call_deferred()
	_maybe_show_golden_wallow_debrief.call_deferred()
	if OS.get_environment("WYRD_DEV_FIRST_ROAD") == "choice":
		get_tree().create_timer(0.7).timeout.connect(func() -> void:
			var mara: Node = get_tree().get_first_node_in_group("tutorial_mara")
			var game := get_node_or_null("/root/Game")
			var player: Node = game.local_player() if game != null else null
			if mara != null and player != null:
				mara.interact(player)
				get_tree().create_timer(0.2).timeout.connect(func() -> void:
					for child in get_children():
						if child.has_method("_advance"):
							child.call("_advance")
							child.call("_advance")
							break))
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
				# Deterministic full-HUD state for visual QA: four runtime Skills,
				# Focus, one draught, and all shortcut affordances disclosed.
				if game != null:
					game.tutorial_step = 7
					game.seen_hints["tier1_completed"] = true
					game.owned_skills = ["PowerShot", "BrambleSnare", "MultiShot"]
					game.loadout = ["PowerShot", "BrambleSnare", "MultiShot"]
					game.add_material("hearth_draught", 2)
					var hud_player: Node = game.local_player()
					if hud_player != null and hud_player.has_method("rebuild_skills"):
						hud_player.rebuild_skills()
					game.tutorial_changed.emit(game.tutorial_step)
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
			elif OS.get_environment("WYRD_UI_SHOT") == "dialog":
				var dlg: CanvasLayer = load("res://scripts/ui/dialog_panel.gd").new()
				dlg.open("Mara Linnet, the Wayfinder",
					["New boots — good. The yard's paths won't walk themselves, and "
					+ "the deeper dens don't forgive soft soles. Inscribe a chart when "
					+ "you're ready and I'll read what the brambles have to say."],
					WayfinderScript.MARA_PORTRAIT,
					["Tell me about charts.", "Not just yet."])
				add_child(dlg)
			elif OS.get_environment("WYRD_UI_SHOT") == "loadout":
				add_child(load("res://scripts/ui/loadout_panel.gd").new())
			elif OS.get_environment("WYRD_UI_SHOT") == "quill":
				add_child(load("res://scripts/ui/quill_panel.gd").new())
			elif OS.get_environment("WYRD_UI_SHOT") == "credits":
				add_child(load("res://scripts/ui/credits_menu.gd").new())
			elif OS.get_environment("WYRD_UI_SHOT") == "options":
				add_child(load("res://scripts/ui/options_menu.gd").new())
			elif OS.get_environment("WYRD_UI_SHOT") == "feedback":
				add_child(load("res://scripts/ui/feedback_menu.gd").new())
			elif OS.get_environment("WYRD_UI_SHOT") == "creature_codex":
				var pause: CanvasLayer = load("res://scripts/ui/pause_menu.gd").new()
				add_child(pause)
				var codex: CanvasLayer = load( \
					"res://scripts/ui/creature_codex_panel.gd").new()
				codex.name = "CreatureCodexPanel"
				pause.add_child(codex)
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
			elif OS.get_environment("WYRD_UI_SHOT") in ["waystone", "waystone_empty"]:
				# Deterministic Waystone states for the UI-reference capture loop.
				# The populated state uses a real chart so the folio exercises the
				# same labels, affixes, difficulty, and traversal action as play.
				if game != null and OS.get_environment("WYRD_UI_SHOT") == "waystone":
					game.charts.clear()
					game.seen_hints["affix_reading"] = true
					var chart_data = load("res://data/charts.gd")
					game.add_chart(chart_data.inscribe(
						"tier_1", ["hedge_ink"], 9, "thorn_essence"))
					game.add_chart(chart_data.inscribe(
						"mire", ["hedge_ink", "refined_ink"], 18, ""))
					game.add_chart(chart_data.inscribe("snug", [], 9, ""))
				elif game != null:
					game.charts.clear()
				var waystone_panel: CanvasLayer = load( \
					"res://scripts/ui/waystone_panel.gd").new()
				waystone_panel.player = game.local_player() if game != null else null
				add_child(waystone_panel)
			else:
				# "table"/"bench"/anything else — the crafting bench (spec 42).
				# "bench_staged" pre-fills a Chart; "bench_mix" captures the
				# dedicated copper-pot workspace.
				if OS.get_environment("WYRD_UI_SHOT") == "bench_mix" and game != null:
					game.tutorial_step = 2
				var panel: CanvasLayer = load("res://scripts/ui/crafting_bench.gd").new()
				add_child(panel)
				if OS.get_environment("WYRD_UI_SHOT") == "bench_staged" and game != null:
					game.seen_hints["chart_table_snug_returned"] = true
					if not game.known_chart_recipes.has("green_hollow"):
						game.known_chart_recipes.append("green_hollow")
					game.add_material("field_parchment", 1)
					game.add_material("hedge_sprig", 1)
					game.add_material("loop_cord", 1)
					game.add_material("hedge_ink", 4)
					game.add_material("thorn_essence", 1)
					panel.call_deferred("_refresh_preview")
					panel.place_component.call_deferred("c", "field_parchment")
					panel.place_component.call_deferred("n", "hedge_sprig")
					panel.place_component.call_deferred("w", "loop_cord")
					panel.place_ink.call_deferred("hedge_ink", 0)
					panel.pot_add.call_deferred("wild_herb")
					panel.pot_add.call_deferred("wild_herb"))


func _apply_town_tonal_grade(force_web: String = "") -> bool:
	var world_environment := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world_environment == null or world_environment.environment == null:
		return false
	var env := world_environment.environment.duplicate() as Environment
	if not TownEnvironment.apply_tonal_grade(env, OS.has_feature("web"), force_web):
		return false
	world_environment.environment = env
	return true

static func town_camera_profile() -> Dictionary:
	return {
		"pitch": TOWN_CAMERA_PITCH,
		"zoom": TOWN_CAMERA_ZOOM,
		"framing_forward": TOWN_CAMERA_FORWARD_FRAME,
	}

static func north_landmark_layout() -> Dictionary:
	return {
		"cottage": {
			"position": COTTAGE_POS,
			"radius": COTTAGE_RADIUS,
			"height": COTTAGE_HEIGHT,
			"supports": [
				COTTAGE_POS + Vector3(2.8, 0.0, 2.6),
				COTTAGE_POS + Vector3(2.0, 0.0, 1.5),
				LOG_PILES[0], LOG_PILES[1],
			],
		},
		"tower": {
			"position": TOWER_POS,
			"radius": TOWER_RADIUS,
			"height": TOWER_HEIGHT,
			"supports": [TOWER_POS + Vector3(0.0, 1.6, 1.0)],
		},
		"forge": {
			"position": FORGE_POS,
			"radius": FORGE_RADIUS,
			"height": FORGE_HEIGHT,
			"supports": [
				FORGE_POS + Vector3(-1.5, 0.0, 3.0),
				FORGE_POS + Vector3(1.6, 0.0, 3.2),
				FORGE_POS + Vector3(-0.5, 0.0, 4.5),
				ORE_ROCKS[0], ORE_ROCKS[1], ORE_ROCKS[2],
			],
		},
	}

func _apply_town_camera_profile() -> void:
	var rig := get_node_or_null("CameraRig")
	if rig == null:
		rig = get_tree().get_first_node_in_group("camera_rig")
	if rig != null and rig.has_method("apply_play_profile"):
		var profile := town_camera_profile()
		rig.apply_play_profile(float(profile.pitch), float(profile.zoom),
			float(profile.framing_forward))

static func _town_camera_focus(world_position: Vector3) -> Vector3:
	return world_position + Vector3(0.0, 1.0, -TOWN_CAMERA_FORWARD_FRAME)

func _show_pending_run_debrief() -> void:
	var game := get_node_or_null("/root/Game")
	if game == null or (game.pending_run_debrief as Dictionary).is_empty():
		return
	var debrief: Dictionary = (game.pending_run_debrief as Dictionary).duplicate(true)
	var choices: Array = []
	if bool(debrief.get("preparation", false)):
		choices = ["Take a Hearth Draught", "Take a pot of Hedge Ink"]
	var dlg: CanvasLayer = DialogPanelScript.new()
	dlg.add_to_group("run_debrief")
	dlg.open("Chart Returned", [game.run_debrief_text(debrief)], null, choices)
	if not choices.is_empty():
		dlg.choice_selected.connect(func(index: int) -> void:
			game.claim_first_return_preparation(index))
	dlg.finished.connect(game.clear_pending_run_debrief)
	add_child(dlg)

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
	# Threadstep's host authority requires a synchronized navigation surface in
	# every playable map. Town is a hand-built flat clearing rather than a baked
	# dungeon, so register its authored walkable square directly; the player's
	# capsule sweep still rejects buildings, props, and the boundary walls.
	var nav_mesh := NavigationMesh.new()
	nav_mesh.vertices = PackedVector3Array([
		Vector3(0.0, 0.05, 0.0), Vector3(0.0, 0.05, YARD),
		Vector3(YARD, 0.05, YARD), Vector3(YARD, 0.05, 0.0),
	])
	nav_mesh.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	var nav_region := NavigationRegion3D.new()
	nav_region.name = "TownNavigation"
	nav_region.navigation_mesh = nav_mesh
	add_child(nav_region)

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
	var game := get_node_or_null("/root/Game")
	# The rain-stained note is a persistent physical source once a completed
	# Hollow has unlocked it. Before Wayfinding 12 it offers anticipation only.
	if game != null and game.has_method("chart_source_status"):
		var rain_status = game.chart_source_status("mara_sallow_reed")
		if rain_status is Dictionary and bool((rain_status as Dictionary).get("valid", false)) \
				and bool((rain_status as Dictionary).get("unlocked", false)):
			var note: Node3D = MaraRainNoteScript.new()
			note.name = "MaraSallowRumourSource"
			note.position = RAIN_NOTE_POS
			note.rotation.y = -0.18
			add_child(note)
	if game != null and int(game.tutorial_step) == 6 \
			and not bool(game.seen_hints.get("power_shot_practiced", false)):
		var practice: Node3D = PracticeBrambleScript.new()
		practice.position = PRACTICE_POS
		add_child(practice)
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


func _place_first_road_payoff() -> void:
	var game := get_node_or_null("/root/Game")
	if game == null or not bool(game.seen_hints.get("first_road_completed", false)):
		return
	var lamp := FIRST_ROAD_LAMP_GLB.instantiate()
	lamp.name = "FirstRoadLamp"
	lamp.add_to_group("first_road_payoff")
	GlbFit.normalize_height(lamp, 2.4)
	var bounds := GlbFit.merged_aabb(lamp, Transform3D.IDENTITY)
	lamp.position = FIRST_ROAD_LAMP_POS - Vector3(0.0, bounds.position.y, 0.0)
	_unmetal(lamp)
	add_child(lamp)
	var light := OmniLight3D.new()
	light.name = "FirstRoadGlow"
	light.position = FIRST_ROAD_LAMP_POS + Vector3(0.0, 1.65, 0.0)
	light.light_color = Color(1.0, 0.68, 0.28)
	light.light_energy = 0.65
	light.omni_range = 3.8
	add_child(light)
	var label := Label3D.new()
	label.name = "FirstRoadLampLabel"
	label.text = "THE FIRST ROAD"
	label.position = FIRST_ROAD_LAMP_POS + Vector3(0.0, 2.7, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 20
	label.pixel_size = 0.004
	label.modulate = Color(1.0, 0.82, 0.48)
	label.outline_size = 7
	label.outline_modulate = Color(0.08, 0.04, 0.02, 0.92)
	add_child(label)

func _place_dressing() -> void:
	# (The old 6-oak scatter is gone — TownEnvironment's treeline ring
	# encloses the clearing instead.)
	_place_glb(WELL_GLB, WELL_POS, 1.6, 0.9)
	_place_glb(SIGNPOST_GLB, SIGNPOST_POS, 1.9, 0.4)
	# One strong exterior per town function. The old market stall duplicated and
	# obscured the smithy's open forge; the new buildings carry their own readable
	# door, sign, hearth, and shopfront details.
	_place_glb(COTTAGE_GLB, COTTAGE_POS, COTTAGE_HEIGHT, COTTAGE_RADIUS)
	_place_glb(FORGE_GLB, FORGE_POS, FORGE_HEIGHT, FORGE_RADIUS)
	_place_glb(TOWER_GLB, TOWER_POS, TOWER_HEIGHT, TOWER_RADIUS)
	# B7/C2 — same tower-wall parchment, now a real rereadable Interactable.
	var board: Node3D = LivingAtlasPanelScript.new()
	board.name = "AtlasDeepRumourSource"
	board.position = TOWER_POS + Vector3(0.0, 1.6, 1.0)
	add_child(board)


func _homecoming_context() -> Dictionary:
	# Co-op role is presentation context, not a campaign inference. The Game
	# projection remains the sole authority for what a guest is allowed to see.
	var guest := NetGame.active and not NetGame.is_host()
	var context := {
		"read_only": guest,
		"guest": guest,
	}
	# A later canonical settlement supersedes the earlier arrival beat in a
	# fresh process. The permanent Hall remains; only its old debrief is quiet.
	var golden := _settlement_chapter("golden_wallow")
	if bool(golden.get("cleared", false)):
		context["seen_event_keys"] = ["first_knot_homecoming"]
	return context


func _campaign_settlement_view() -> Dictionary:
	var fallback := {"available": false, "read_only": true, "guest": false,
		"chapters": {}, "first_knot": {}, "golden_wallow": {}}
	var game := get_node_or_null("/root/Game")
	if game == null or not game.has_method("campaign_settlement_view"):
		return fallback
	var raw = game.campaign_settlement_view(_homecoming_context())
	if not raw is Dictionary:
		return fallback
	return (raw as Dictionary).duplicate(true)


func _settlement_chapter(chapter_id: String) -> Dictionary:
	var chapters = _settlement_view.get("chapters", {})
	var raw = (chapters as Dictionary).get(chapter_id, {}) \
		if chapters is Dictionary else _settlement_view.get(chapter_id, {})
	return raw as Dictionary if raw is Dictionary else {}


func _first_knot_homecoming_view() -> Dictionary:
	var fallback := {
		"visible": false, "restoration_visible": false, "rune_visible": false,
		"tusk_record_visible": false, "covered_bow_rest_visible": false,
		"atlas_handoff_visible": false, "debrief_event": {},
		"debrief_event_key": "", "d2_ineligible": true,
	}
	var game := get_node_or_null("/root/Game")
	if game == null or not game.has_method("first_knot_homecoming_view"):
		return fallback
	var raw = game.first_knot_homecoming_view(_homecoming_context())
	if not raw is Dictionary:
		return fallback
	var projection := fallback.duplicate(true)
	projection.merge(raw as Dictionary, true)
	return projection


func _apply_first_knot_homecoming() -> void:
	var board := get_node_or_null("AtlasDeepRumourSource")
	if board != null and board.has_method("set_homecoming_view"):
		board.set_homecoming_view(_homecoming_view)
	var existing := get_node_or_null("FirstKnotTrophyHall")
	if not bool(_homecoming_view.get("visible", false)) \
			or not bool(_homecoming_view.get("restoration_visible", false)):
		if existing != null:
			existing.queue_free()
		return
	if existing != null:
		if existing.has_method("set_homecoming_view"):
			existing.set_homecoming_view(_homecoming_view)
		if existing.has_method("set_settlement_view"):
			existing.set_settlement_view(_settlement_view)
		return
	var hall: Node3D = TrophyHallScript.new()
	hall.name = "FirstKnotTrophyHall"
	hall.position = TROPHY_HALL_POS
	hall.rotation.y = -PI * 0.5
	hall.set_homecoming_view(_homecoming_view)
	hall.set_settlement_view(_settlement_view)
	add_child(hall)


func _apply_campaign_settlement() -> void:
	var board := get_node_or_null("AtlasDeepRumourSource")
	if board != null and board.has_method("set_settlement_view"):
		board.set_settlement_view(_settlement_view)
	var hall := get_node_or_null("FirstKnotTrophyHall")
	if hall != null and hall.has_method("set_settlement_view"):
		hall.set_settlement_view(_settlement_view)
	_apply_skald_archive()
	_apply_rootroad_lift()
	_apply_ember_kiln()
	_apply_wayweaver_mastery_stations()
	var golden := _settlement_chapter("golden_wallow")
	var existing := get_node_or_null("SallowJetty")
	var should_show := bool(_settlement_view.get("available", false)) \
		and bool(golden.get("visible", false)) \
		and bool(golden.get("restoration_visible", false))
	if not should_show:
		if existing != null:
			existing.queue_free()
		return
	if existing != null:
		if existing.has_method("set_settlement_view"):
			existing.set_settlement_view(_settlement_view)
		return
	var jetty: Node3D = SallowJettyScript.new()
	jetty.name = "SallowJetty"
	jetty.position = SALLOW_JETTY_POS
	jetty.rotation.y = PI
	jetty.set_settlement_view(_settlement_view)
	add_child(jetty)


func _apply_skald_archive() -> void:
	var seventh := _settlement_chapter("seventh_road")
	var existing := get_node_or_null("SkaldArchive")
	var should_show := bool(_settlement_view.get("available", false)) \
		and bool(seventh.get("visible", false)) \
		and bool(seventh.get("restoration_visible", false))
	if not should_show:
		if existing != null:
			existing.queue_free()
		return
	if existing != null:
		if existing.has_method("set_settlement_view"):
			existing.set_settlement_view(_settlement_view)
		return
	var archive: Node3D = SkaldArchiveScript.new()
	archive.name = "SkaldArchive"
	archive.position = SKALD_ARCHIVE_POS
	archive.rotation.y = -PI * 0.5
	archive.set_settlement_view(_settlement_view)
	add_child(archive)


func _apply_rootroad_lift() -> void:
	var pale := _settlement_chapter("pale_oath")
	var existing := get_node_or_null("RootroadLift")
	# Do not infer either presentation from a loose Rune, Thread, or Coal. The
	# one campaign restoration owns both the physical Lift and Hod's stone.
	var should_show := bool(_settlement_view.get("available", false)) \
		and bool(pale.get("visible", false)) \
		and bool(pale.get("relic_visible", false)) \
		and bool(pale.get("restoration_visible", false)) \
		and String(pale.get("restoration_id", "")) == "rootroad_lift"
	if not should_show:
		if existing != null:
			existing.queue_free()
		return
	if existing != null:
		if existing.has_method("set_settlement_view"):
			existing.set_settlement_view(_settlement_view)
		return
	var lift: Node3D = RootroadLiftScript.new()
	lift.name = "RootroadLift"
	lift.position = ROOTROAD_LIFT_POS
	lift.rotation.y = PI
	lift.set_settlement_view(_settlement_view)
	add_child(lift)


func _apply_ember_kiln() -> void:
	var fire := _settlement_chapter("fire_in_the_bough")
	var existing := get_node_or_null("EmberKiln")
	# The kiln is a settlement projection only. A loose Wyrm Scale, Rune, or
	# Thread cannot infer it, and the derived Loom foundation has no station.
	var should_show := bool(_settlement_view.get("available", false)) \
		and bool(fire.get("visible", false)) \
		and bool(fire.get("restoration_visible", false)) \
		and String(fire.get("restoration_id", "")) == "ember_kiln"
	if not should_show:
		if existing != null:
			existing.queue_free()
		return
	if existing != null:
		return
	var kiln: Node3D = CraftStationScript.new()
	kiln.name = "EmberKiln"
	kiln.position = EMBER_KILN_POS
	kiln.rotation.y = -PI * 0.25
	kiln.setup("ember_kiln")
	add_child(kiln)


# ---- D8 Wayweaver mastery stations -----------------------------------------
#
# These are intentionally only physical adapters.  The campaign settlement
# projection decides whether a restored landmark exists; local Trade level
# decides whether its corresponding late-work surface is shown.  No node here
# examines materials to grant a component, mutates Campaign, or bypasses
# Game.wayweaver_preview/commit_wayweaver.

func _apply_wayweaver_mastery_stations() -> void:
	var game := get_node_or_null("/root/Game")
	if game == null:
		return
	var hod_ready := _mastery_trade_level(game, "earthcraft") >= 22
	var quill_ready := _mastery_trade_level(game, "wildcraft") >= 22
	_reconcile_mastery_station("HodMasteryStation", self, hod_ready,
		"hod_mastery", _next_hod_mastery_action(game), HOD_MASTERY_POS)
	_reconcile_mastery_station("QuillMasteryStation", self, quill_ready,
		"quill_mastery", _next_quill_mastery_action(game), QUILL_MASTERY_POS)

	# The final settlement is the only town truth that wakes the Loom, unlocks
	# the Hunt conversion, and lights the second hearth.  The settlement view is
	# host-projected in co-op, so a guest never infers this from local materials.
	var final_chapter := _settlement_chapter("unwritten_road")
	var final_cleared := bool(_settlement_view.get("available", false)) \
		and bool(final_chapter.get("visible", false)) \
		and bool(final_chapter.get("cleared", false))
	var loom_awake := final_cleared and String(_settlement_view.get("loom_state", "")) == "awake"
	_apply_awake_loom_station(loom_awake)
	_reconcile_mastery_station("MasterHuntStation", self, final_cleared,
		"master_hunt", "quiet_tooth_grip", MASTER_HUNT_POS)
	var forge_restored := final_cleared \
		and bool(final_chapter.get("restoration_visible", false)) \
		and String(final_chapter.get("restoration_id", "")) == "master_forge"
	_reconcile_mastery_station("MasterForgeStation", self, forge_restored,
		"master_forge", "wayweaver", MASTER_FORGE_POS)


func _mastery_trade_level(game: Node, trade_id: String) -> int:
	var records = game.get("trades")
	if not records is Dictionary:
		return 0
	var record = (records as Dictionary).get(trade_id, 0)
	return int((record as Dictionary).get("lv", record.get("level", 0))) \
		if record is Dictionary else int(record)


# Selection is presentation only.  It makes the one physical station read as
# the next link in its 3+2 chain; a stale action is harmless because Game
# computes the pure plan again immediately before it changes materials.
func _next_hod_mastery_action(game: Node) -> String:
	return "waysteel_frame" if _mastery_material_count(game, "waysteel_core") > 0 \
		or _mastery_material_count(game, "waysteel_frame") > 0 else "waysteel_core"


func _next_quill_mastery_action(game: Node) -> String:
	return "threefold_draught" if _mastery_material_count(game, "root_sap_cord") > 0 \
		or _mastery_material_count(game, "wayweaver_string") > 0 else "root_sap_cord"


func _mastery_material_count(game: Node, material_id: String) -> int:
	if game.has_method("material_count"):
		return int(game.call("material_count", material_id))
	var held = game.get("materials")
	return int((held as Dictionary).get(material_id, 0)) if held is Dictionary else 0


func _reconcile_mastery_station(node_name: String, parent: Node,
		should_show: bool, station_id: String, action_id: String,
		position: Vector3) -> void:
	var existing := parent.get_node_or_null(node_name) as Node3D
	if not should_show:
		if existing != null:
			existing.queue_free()
		return
	if existing == null:
		var station: Node3D = MasteryStationScript.new()
		station.name = node_name
		station.set("station_id", station_id)
		station.set("action_id", action_id)
		station.position = position
		parent.add_child(station)
		_decorate_mastery_station(station, station_id)
		return
	existing.set("station_id", station_id)
	existing.set("action_id", action_id)
	var prompt := existing.get_node_or_null("PromptLabel") as Label3D
	if prompt != null and existing.has_method("get_prompt_text"):
		prompt.text = String(existing.call("get_prompt_text"))


# The Loom keeps its same foundation and source position.  Once it is awake,
# replace just the reading point with the one string ritual; no duplicate
# source, generic craft panel, or parallel component authority remains.
func _apply_awake_loom_station(should_show: bool) -> void:
	var kiln := get_node_or_null("EmberKiln") as Node3D
	var foundation := kiln.get_node_or_null("ThreefoldLoomFoundation") as Node3D \
		if kiln != null else null
	if foundation == null:
		return
	var source := foundation.get_node_or_null("ThreefoldLoomSource")
	if should_show:
		if source != null:
			source.queue_free()
		_reconcile_mastery_station("AwakeLoomStation", foundation, true,
			"awake_loom", "wayweaver_string", AWAKE_LOOM_LOCAL_POS)
		return
	_reconcile_mastery_station("AwakeLoomStation", foundation, false,
		"awake_loom", "wayweaver_string", AWAKE_LOOM_LOCAL_POS)


# A tiny procedural landmark makes each new interaction legible at yard scale
# without inventing a second asset pipeline.  It is visual only; the station
# body/prompt/collision continue to come from MasteryStation/Interactable.
func _decorate_mastery_station(station: Node3D, station_id: String) -> void:
	var post := MeshInstance3D.new()
	post.name = "MasteryPost"
	var post_mesh := CylinderMesh.new()
	post_mesh.top_radius = 0.12
	post_mesh.bottom_radius = 0.16
	post_mesh.height = 1.30
	post_mesh.radial_segments = 8
	post.mesh = post_mesh
	post.position = Vector3(0.0, 0.65, 0.0)
	post.material_override = _mastery_material(Color(0.25, 0.16, 0.10))
	station.add_child(post)
	var work := MeshInstance3D.new()
	work.name = "MasteryWork"
	var work_mesh := BoxMesh.new()
	work_mesh.size = Vector3(0.78, 0.18, 0.52)
	work.mesh = work_mesh
	work.position = Vector3(0.0, 1.15, 0.0)
	var colors := {
		"hod_mastery": Color(0.40, 0.47, 0.52),
		"quill_mastery": Color(0.42, 0.67, 0.50),
		"awake_loom": Color(0.62, 0.50, 0.82),
		"master_hunt": Color(0.66, 0.50, 0.28),
		"master_forge": Color(0.92, 0.35, 0.14),
	}
	work.material_override = _mastery_material(colors.get(station_id, Color(0.70, 0.56, 0.25)))
	station.add_child(work)
	var sign := Label3D.new()
	sign.name = "MasteryStationSign"
	sign.text = {
		"hod_mastery": "HOD'S\nMASTER FORGE",
		"quill_mastery": "QUILL'S\nROOTWORK",
		"awake_loom": "AWAKE\nLOOM",
		"master_hunt": "MASTER\nHUNT",
		"master_forge": "SECOND\nHEARTH",
	}.get(station_id, "MASTERWORK")
	sign.position = Vector3(0.0, 1.50, 0.04)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.no_depth_test = true
	sign.modulate = Color(0.92, 0.79, 0.50)
	sign.font_size = 18
	sign.pixel_size = 0.0034
	sign.outline_size = 7
	sign.outline_modulate = Color(0.08, 0.05, 0.03, 0.95)
	var font := WyrdUi.font_header()
	if font != null:
		sign.font = font
	station.add_child(sign)
	if station_id == "master_forge":
		var glow := OmniLight3D.new()
		glow.name = "SecondHearthGlow"
		glow.position = Vector3(0.0, 0.85, 0.0)
		glow.light_color = Color(1.0, 0.36, 0.12)
		glow.light_energy = 1.45
		glow.omni_range = 3.4
		station.add_child(glow)


func _mastery_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	return material


# Huntcraft's authored lessons are Game-owned planner transactions. Town mounts
# one shared marker for the earliest pending Lodge page; neither the marker nor
# this projection grants, equips, or chooses a hotbar Skill.
func _apply_driving_volley_lesson() -> void:
	var game := get_node_or_null("/root/Game")
	var status: Dictionary = {}
	if game != null and game.has_method("hunters_lodge_lesson_status"):
		var raw = game.hunters_lodge_lesson_status()
		status = raw as Dictionary if raw is Dictionary else {}
	var pending := bool(status.get("pending", status.get("available", false)))
	var marker := get_node_or_null("HuntersLodgeLesson")
	var bramble := get_node_or_null("DrivingVolleyPracticeBramble")
	if not pending:
		if marker != null:
			marker.queue_free()
		if bramble != null:
			bramble.queue_free()
		return
	if marker == null:
		var lesson: Node3D = HuntersLodgeLessonScript.new()
		lesson.name = "HuntersLodgeLesson"
		lesson.position = HUNTERS_LODGE_POS
		add_child(lesson)
	else:
		marker.call("refresh")
	if bramble == null and get_tree().get_first_node_in_group("power_shot_practice") == null:
		var practice: Node3D = PracticeBrambleScript.new()
		practice.name = "DrivingVolleyPracticeBramble"
		practice.position = HUNTERS_LODGE_POS + Vector3(-2.0, 0.0, 0.8)
		add_child(practice)
		# PracticeBramble assigns its old tutorial name in _ready; reclaim a
		# stable Town-owned mount name after that compatibility setup completes.
		practice.call_deferred("set_name", "DrivingVolleyPracticeBramble")


func _refresh_campaign_settlement_view() -> void:
	var next := _campaign_settlement_view()
	var golden = (next.get("chapters", {}) as Dictionary).get("golden_wallow", {}) \
		if next.get("chapters", {}) is Dictionary else next.get("golden_wallow", {})
	var event = (golden as Dictionary).get("debrief_event", {}) \
		if golden is Dictionary else {}
	if not bool(next.get("available", false)) or bool(next.get("guest", false)) \
			or not bool((event as Dictionary).get("available", false)):
		var dialog := get_tree().get_first_node_in_group("GoldenWallowSettlementDebrief")
		if dialog != null and dialog.has_method("_finish"):
			dialog.call("_finish")
	_settlement_view = next
	_apply_campaign_settlement()


func _maybe_show_golden_wallow_debrief() -> void:
	var game := get_node_or_null("/root/Game")
	if game != null and int(game.get("modal_count")) > 0:
		_settlement_waiting_for_modal = true
		return
	var golden := _settlement_chapter("golden_wallow")
	var event: Dictionary = golden.get("debrief_event", {})
	var event_key := String(golden.get("debrief_event_key", ""))
	if event_key == "" or not bool(event.get("available", false)) \
			or bool(_settlement_view.get("guest", false)) \
			or bool(_settlement_view.get("read_only", false)) \
			or _session_settlement_debriefs.has(event_key):
		return
	_session_settlement_debriefs[event_key] = true
	var dialog: CanvasLayer = DialogPanelScript.new()
	dialog.name = "GoldenWallowSettlementDebrief"
	dialog.add_to_group("GoldenWallowSettlementDebrief")
	dialog.open("The Golden Wallow", [
		"The Wightpelt has been entered in the Hall, and a mist-green root-mark "
		+ "now burns where the old wet road meets the yard.",
		"Beyond the reeds, the Sallow Jetty is sound again. Bring it a held Mire Chart, "
		+ "and it will launch you straight into the wet roads.",
	])
	add_child(dialog)


func _refresh_first_knot_homecoming_view() -> void:
	# Guest Towns can finish building before the reliable host snapshot arrives.
	# Re-query the one public adapter when NetGame publishes it; never fall back
	# to the guest's local campaign state.
	var next_view := _first_knot_homecoming_view()
	var next_event: Dictionary = next_view.get("debrief_event", {})
	if not bool(next_view.get("available", false)) \
			or bool(next_view.get("guest", false)) \
			or not bool(next_event.get("available", false)):
		# Joining can begin after an offline Town already scheduled its local
		# debrief. Revoke that presentation immediately; otherwise a guest could
		# keep reading local truth while waiting for the host snapshot.
		var dialog := get_tree().get_first_node_in_group("FirstKnotHomecomingDebrief")
		if dialog != null:
			var old_key := String(_homecoming_view.get("debrief_event_key", ""))
			if old_key != "":
				_session_homecoming_debriefs.erase(old_key)
			if dialog.has_method("_finish"):
				dialog.call("_finish")
	_homecoming_view = next_view
	_apply_first_knot_homecoming()


func _maybe_show_first_knot_homecoming_debrief() -> void:
	var game := get_node_or_null("/root/Game")
	if game != null and int(game.get("modal_count")) > 0:
		# The ordinary Chart-return debrief owns the first arrival beat. Wait for
		# its modal to close instead of stacking two parchment pages.
		_homecoming_waiting_for_modal = true
		return
	var event: Dictionary = _homecoming_view.get("debrief_event", {})
	var event_key := String(_homecoming_view.get("debrief_event_key", ""))
	if event_key == "" or not bool(event.get("available", false)) \
			or bool(_homecoming_view.get("d2_ineligible", false)) \
			or _session_homecoming_debriefs.has(event_key):
		# A Reprise has already received its cached permanent Hall/Atlas view, but
		# must never carry its transient return source into a later Town visit.
		if bool(_homecoming_view.get("d2_ineligible", false)):
			_clear_first_knot_homecoming_return_context()
		return
	# The acknowledgement is session-local only: never write Game, Campaign, or
	# SaveGame.  A reconnect or fresh process may present the same warm return.
	_session_homecoming_debriefs[event_key] = true
	var dialog: CanvasLayer = DialogPanelScript.new()
	dialog.name = "FirstKnotHomecomingDebrief"
	dialog.add_to_group("FirstKnotHomecomingDebrief")
	dialog.open("The First Knot", [
		"The rain has eased on the yard. Someone has set a small alcove by the fence, "
		+ "with room for a green mark and a hard-won record.",
		"No bells. Just the kettle, the wet road, and Bramblewood making space for you.",
	])
	dialog.finished.connect(_clear_first_knot_homecoming_return_context)
	add_child(dialog)


func _clear_first_knot_homecoming_return_context() -> void:
	var game := get_node_or_null("/root/Game")
	if game != null and game.has_method("clear_first_knot_homecoming_return_context"):
		# Session-only cleanup: no campaign, inventory, or save mutation.
		game.clear_first_knot_homecoming_return_context()

# The density pass: paths, treeline, grass, flowers, scatter dressing.
func _build_environment() -> void:
	var env := TownEnvironment.new()
	var station_clear: Array = [PLAYER_SPAWN, WAYFINDER_POS, TABLE_POS,
		WAYSTONE_POS, WELL_POS, RAIN_NOTE_POS, SIGNPOST_POS, COTTAGE_POS,
		FORGE_POS, TOWER_POS, FORGE_POS + Vector3(-1.5, 0.0, 3.0),
		COTTAGE_POS + Vector3(2.8, 0.0, 2.6),
		FORGE_POS + Vector3(1.6, 0.0, 3.2), QUILL_POS, STILL_POS]
	# Core circulation is deliberately sparse: one arrival route and one branch
	# per landmark cluster. Mara and the worktable sit on the plaza itself.
	var spokes: Array = [PLAYER_SPAWN, COTTAGE_POS, TOWER_POS, FORGE_POS,
		WAYSTONE_POS, STILL_POS]
	var treeline_breaks: Array = []
	var optional_landmarks := [
		["FirstKnotTrophyHall", TROPHY_HALL_POS, false],
		["SallowJetty", SALLOW_JETTY_POS, true],
		["SkaldArchive", SKALD_ARCHIVE_POS, true],
		["RootroadLift", ROOTROAD_LIFT_POS, true],
		["HodMasteryStation", HOD_MASTERY_POS, false],
		["QuillMasteryStation", QUILL_MASTERY_POS, false],
		["MasterHuntStation", MASTER_HUNT_POS, false],
		["MasterForgeStation", MASTER_FORGE_POS, false],
		["HuntersLodgeLesson", HUNTERS_LODGE_POS, true],
	]
	for landmark in optional_landmarks:
		if get_node_or_null(String(landmark[0])) == null:
			continue
		var pos: Vector3 = landmark[1]
		station_clear.append(pos)
		spokes.append(pos)
		if bool(landmark[2]):
			treeline_breaks.append(pos)
	env.setup(YARD, Vector3(20.0, 0.0, 21.0), station_clear, spokes,
		treeline_breaks, {
			"cottage": COTTAGE_POS,
			"forge": FORGE_POS,
		})
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
	# Golden Wallow's boss Ink must not depend on a lucky Mire forage roll.
	# The matching renewable patch is visible beside Quill's still from the
	# beginning, but GatherNode keeps it honestly locked until Wildcraft 10.
	var mothmint: Node3D = GatherNodeScript.new()
	mothmint.name = "MothmintPatch"
	mothmint.setup("forage_node", "mothmint", true)
	mothmint.setup_herb_tier("mothmint")
	mothmint.position = STILL_POS + Vector3(1.6, 0.0, 1.2)
	add_child(mothmint)
	if mothmint.has_signal("regrew"):
		mothmint.regrew.connect(_on_node_regrew)
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
	# Meshy exteriors are centered on their origin, unlike the older handmade
	# props whose origins sat at ground level. Ground every asset after scaling
	# so exterior shells do not spend their lower half under the meadow.
	var fitted_bounds := GlbFit.merged_aabb(inst, Transform3D.IDENTITY)
	inst.position.y -= fitted_bounds.position.y
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
		# Dev capture: stand in the north yard so all three exterior landmarks
		# share the gameplay-camera frame. Normal play always uses PLAYER_SPAWN.
		var spawn := Vector3(20.0, 0.0, 15.0) \
			if OS.get_environment("WYRD_SHOT_TOWN_ASSETS") != "" else PLAYER_SPAWN
		(player as Node3D).position = spawn
		if player.has_method("set_spawn"):
			player.set_spawn(spawn)

# ---- first-session storybook vignettes ----

func _should_cover_first_arrival(game: Node) -> bool:
	return _vignettes_allowed(game) and int(game.tutorial_step) == 0 \
		and not bool(game.seen_hints.get("vignette_arrival", false))


func _build_first_arrival_cover() -> void:
	# This cover is created before Town's synchronous construction work. The
	# title screen remains visible while the scene changes; Town's first complete
	# frame is then deliberately covered until its GPU work has been submitted.
	# The camera vignette only starts after that barrier, so a shader/upload hitch
	# cannot eat the opening pan.
	_arrival_cover = CanvasLayer.new()
	_arrival_cover.name = "FirstArrivalCover"
	_arrival_cover.layer = 100
	add_child(_arrival_cover)
	_arrival_cover_rect = ColorRect.new()
	_arrival_cover_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_arrival_cover_rect.color = Color(0.10, 0.075, 0.045, 1.0)
	_arrival_cover_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_arrival_cover.add_child(_arrival_cover_rect)
	var label := Label.new()
	label.text = "Opening the way…"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.96, 0.89, 0.70))
	var body_font := WyrdUi.font_body()
	if body_font != null:
		label.add_theme_font_override("font", body_font)
	_arrival_cover_rect.add_child(label)


func _reveal_first_arrival() -> void:
	# `frame_post_draw` is the release barrier missing from the old flow. It
	# proves a complete Town frame (including the expensive first shader/texture
	# upload) reached the renderer before any authored camera time is consumed.
	await RenderingServer.frame_post_draw
	if _arrival_cover_rect != null and is_instance_valid(_arrival_cover_rect):
		var tween := create_tween()
		tween.tween_property(_arrival_cover_rect, "modulate:a", 0.0, 0.20) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tween.finished
	if _arrival_cover != null and is_instance_valid(_arrival_cover):
		_arrival_cover.queue_free()
	_arrival_cover = null
	_arrival_cover_rect = null
	_maybe_play_arrival_vignette()

func _on_tutorial_vignette_step(step: int) -> void:
	if step not in [2, 4, 7]:
		return
	_pending_tutorial_vignette = step
	_try_pending_tutorial_vignette.call_deferred()

func _on_tutorial_modal_changed(is_open: bool) -> void:
	if not is_open and _pending_tutorial_vignette >= 0:
		_try_pending_tutorial_vignette.call_deferred()
	if not is_open and _homecoming_waiting_for_modal:
		_homecoming_waiting_for_modal = false
		_maybe_show_first_knot_homecoming_debrief.call_deferred()
	if not is_open and _settlement_waiting_for_modal:
		_settlement_waiting_for_modal = false
		_maybe_show_golden_wallow_debrief.call_deferred()

func _maybe_play_arrival_vignette() -> void:
	var game := get_node_or_null("/root/Game")
	if not _vignettes_allowed(game) or int(game.tutorial_step) != 0:
		if game != null and game.has_method("record_onboarding_event"):
			game.record_onboarding_event("control_ready")
		return
	if bool(game.seen_hints.get("vignette_arrival", false)):
		game.record_onboarding_event("control_ready")
		return
	var rig := get_tree().get_first_node_in_group("camera_rig")
	if rig == null or not rig.has_method("cinematic_frame"):
		return
	# Town's deferred arrival can run before CameraRig's first follow tick. Use
	# the authored spawn frame instead of capturing a not-yet-snapped origin.
	var home: Dictionary = {
		"focus": _town_camera_focus(PLAYER_SPAWN),
		"yaw": 0.0, "pitch": TOWN_CAMERA_PITCH, "zoom": TOWN_CAMERA_ZOOM,
		"duration": 1.0, "caption": "Go and say hello.",
	}
	var player: Node = game.local_player()
	var actor_track := _arrival_actor_track(player)
	_play_tutorial_vignette("vignette_arrival", [
		{"focus": PLAYER_SPAWN + Vector3(0.0, 1.0, 0.0),
			"yaw": 0.0, "pitch": 32.0, "zoom": 10.5, "duration": 0.8,
			"caption": "The wagon road ends here."},
		{"focus": Vector3(20.0, 1.0, 21.0),
			"yaw": 0.0, "pitch": 35.0, "zoom": 15.0, "duration": 1.5,
			"caption": "Bramblewood begins."},
		{"focus": (WAYFINDER_POS + WAYSTONE_POS) * 0.5 + Vector3(0.0, 1.0, 0.0),
			"yaw": 0.0, "pitch": 36.0, "zoom": 13.5, "duration": 1.6,
			"caption": "Mara Linnet keeps the Chartmaker's Yard."},
		home,
	], actor_track)

func _arrival_actor_track(player: Node) -> Dictionary:
	if not player is Node3D:
		return {}
	return {
		"actor": player,
		"start": PLAYER_SPAWN + Vector3(0.0, 0.0, 5.5),
		"end": PLAYER_SPAWN,
		"duration": 4.4,
	}

func _try_pending_tutorial_vignette() -> void:
	var game := get_node_or_null("/root/Game")
	if _pending_tutorial_vignette < 0 or not _vignettes_allowed(game):
		_pending_tutorial_vignette = -1
		return
	if _micro_cutscene != null and is_instance_valid(_micro_cutscene):
		return
	if int(game.modal_count) > 0:
		return
	var step := _pending_tutorial_vignette
	_pending_tutorial_vignette = -1
	if int(game.tutorial_step) != step:
		return
	var rig := get_tree().get_first_node_in_group("camera_rig")
	if rig == null or not rig.has_method("cinematic_frame"):
		return
	var home: Dictionary = rig.cinematic_frame()
	home["duration"] = 0.9
	var frames: Array
	var hint_id: String
	if step == 2:
		hint_id = "vignette_ink_table"
		if bool(game.seen_hints.get(hint_id, false)):
			return
		home["caption"] = "Mara's table is ready."
		frames = [
			{"focus": TABLE_POS + Vector3(0.0, 0.9, 0.0),
				"yaw": -0.35, "pitch": 34.0, "zoom": 10.5, "duration": 1.2,
				"caption": "Three herbs make one pot of Hedge Ink."},
			home,
		]
	elif step == 4:
		hint_id = "vignette_waystone"
		if bool(game.seen_hints.get(hint_id, false)):
			return
		home["caption"] = "Take the finished Chart with you."
		frames = [
			{"focus": WAYSTONE_POS + Vector3(0.0, 1.2, 0.0),
				"yaw": 0.30, "pitch": 33.0, "zoom": 11.5, "duration": 1.25,
				"caption": "A finished Chart wakes the Waystone."},
			home,
		]
	else:
		hint_id = "vignette_tier1_waystone"
		if bool(game.seen_hints.get(hint_id, false)):
			return
		home["caption"] = "Read the resolved Affix before you cross."
		frames = [
			{"focus": WAYSTONE_POS + Vector3(0.0, 1.2, 0.0),
				"yaw": 0.30, "pitch": 33.0, "zoom": 11.5, "duration": 1.25,
				"caption": "The Waystone shows what the ink became."},
			home,
		]
	_play_tutorial_vignette(hint_id, frames)

func _play_tutorial_vignette(hint_id: String, frames: Array,
		actor_track: Dictionary = {}) -> void:
	var game := get_node_or_null("/root/Game")
	var rig := get_tree().get_first_node_in_group("camera_rig")
	if game == null or rig == null or frames.is_empty():
		return
	game.seen_hints[hint_id] = true
	if game.has_method("record_onboarding_recovery"):
		game.record_onboarding_recovery(hint_id)
	var player: Node = game.local_player()
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	_micro_cutscene = MicroCutsceneScript.new()
	_micro_cutscene.finished.connect(func(_skipped: bool) -> void:
		# Persist after the animated beat, not on its first frame. A synchronous
		# save at vignette start could turn a cold filesystem write into a visible
		# camera hitch.
		game.save_now()
		if hint_id == "vignette_arrival" and game.has_method("record_onboarding_event"):
			game.record_onboarding_event("control_ready")
		_micro_cutscene = null
		_try_pending_tutorial_vignette.call_deferred())
	add_child(_micro_cutscene)
	_micro_cutscene.play(rig, frames, actor_track)

func _vignettes_allowed(game: Node) -> bool:
	if game == null or DisplayServer.get_name() == "headless":
		return false
	if bool(game.get("web_smoke_enabled")):
		return false
	for env_name in ["WYRD_SHOT", "WYRD_UI_SHOT", "WYRD_DEV_CHART", "WYRD_DEV_FIRST_ROAD",
			"WYRD_DEV_BOSS", "WYRD_DEV_LEVEL"]:
		if OS.get_environment(env_name) != "":
			return false
	return true

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
	var board: Node = get_node_or_null("AtlasDeepRumourSource")
	var game3: Node = get_node_or_null("/root/Game")
	_apply_driving_volley_lesson()
	if board == null or game3 == null:
		return
	var lv: int = int(game3.call("trade_lv", "wayfinding"))
	var cleared: bool = game3.get("summit_cleared") == true
	if board.has_method("set_progress"):
		board.set_progress(lv, cleared)
	print("[town] board updated: lv=%d cleared=%s" % [lv, cleared])

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
