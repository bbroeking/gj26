extends SceneTree

# D8 Slice 3 physical-town contract.  The pure mastery tests cover every
# transaction predicate; this gate proves Town projects the corresponding
# places, actions, and modal handoff without becoming a second authority.

const CampaignData = preload("res://data/campaign.gd")
const Progression = preload("res://data/progression.gd")
const MasteryPanelScript = preload("res://scripts/ui/mastery_panel.gd")

var _pass := 0
var _fail := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(label: String, ok: bool, detail = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % label)
	else:
		_fail += 1
		print("  ✗ %s %s" % [label, str(detail)])


func _frames(count := 3) -> void:
	for _frame in count:
		await process_frame


func _final_campaign() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id_v in CampaignData.CHAPTER_ORDER:
		var chapter_id := String(chapter_id_v)
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
		chapter.banked_chart_ids = ["town-mastery-%s" % chapter_id]
	state.relics = CampaignData.ROOT_RUNE_IDS.duplicate()
	state.threads = ["past_thread", "present_thread", "unwritten_thread"]
	state.restorations = ["trophy_hall", "sallow_jetty", "skald_archive", "pale_stair",
		"rootroad_lift", "ember_kiln", "master_forge"]
	state.map_of_nine_knots = true
	state.road_name_id = "lantern_path"
	return CampaignData.normalize_campaign_state(state)


func _set_trade(game: Node, trade_id: String, level: int) -> void:
	game.trades[trade_id] = {"xp": Progression.xp_for_level(level), "lv": level}


func _mastery_panel(town: Node) -> CanvasLayer:
	for child in town.get_children():
		if child is CanvasLayer and child.get_script() == MasteryPanelScript:
			return child as CanvasLayer
	return null


func _run() -> void:
	print("--- Town mastery stations ---")
	root.size = Vector2i(1366, 768)
	var game: Node = root.get_node("Game")
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.persistence_enabled = false
	game.tutorial_step = 7
	game.modal_count = 1 # keep unrelated arrival/debrief parchment out of this gate
	for trade_id in ["wayfinding", "earthcraft", "wildcraft", "huntcraft"]:
		_set_trade(game, String(trade_id), 21)

	change_scene_to_file("res://scenes/Town.tscn")
	await _frames(5)
	var town := current_scene
	_check("late-work stations remain absent before their level/campaign projections",
		town.get_node_or_null("HodMasteryStation") == null
			and town.get_node_or_null("QuillMasteryStation") == null
			and town.get_node_or_null("MasterHuntStation") == null
			and town.get_node_or_null("MasterForgeStation") == null)

	_set_trade(game, "earthcraft", 22)
	_set_trade(game, "wildcraft", 22)
	town.call("_apply_wayweaver_mastery_stations")
	await _frames()
	var hod := town.get_node_or_null("HodMasteryStation")
	var quill := town.get_node_or_null("QuillMasteryStation")
	_check("Earthcraft 22 and Wildcraft 22 reveal one physical first-link station each",
		hod != null and quill != null
			and String(hod.get("station_id")) == "hod_mastery"
			and String(hod.get("action_id")) == "waysteel_core"
			and String(quill.get("station_id")) == "quill_mastery"
			and String(quill.get("action_id")) == "root_sap_cord")
	_check("Quill's world prompt and UI title name the Rootwork station",
		quill != null and String(quill.call("get_prompt_text")).contains("Quill")
			and String(MasteryPanelScript.STATION_TITLES.quill_mastery)
				== "Quill's Rootwork Still")

	game.materials = {"waysteel_core": 1, "root_sap_cord": 1}
	town.call("_apply_wayweaver_mastery_stations")
	await _frames()
	_check("the same physical workstations advance their displayed link after a component exists",
		String(hod.get("action_id")) == "waysteel_frame"
			and String(quill.get("action_id")) == "threefold_draught")

	game.campaign_state = _final_campaign()
	for trade_id in ["wayfinding", "earthcraft", "wildcraft", "huntcraft"]:
		_set_trade(game, String(trade_id), 23)
	town.call("_refresh_campaign_settlement_view")
	town.call("_apply_wayweaver_mastery_stations")
	await _frames(5)
	var kiln := town.get_node_or_null("EmberKiln") as Node3D
	var foundation := kiln.get_node_or_null("ThreefoldLoomFoundation") as Node3D \
		if kiln != null else null
	var loom := foundation.get_node_or_null("AwakeLoomStation") if foundation != null else null
	var old_source := foundation.get_node_or_null("ThreefoldLoomSource") if foundation != null else null
	var hunt := town.get_node_or_null("MasterHuntStation")
	var forge := town.get_node_or_null("MasterForgeStation")
	_check("final settlement replaces the Loom reader with exactly the String ritual",
		loom != null and old_source == null and String(loom.get("station_id")) == "awake_loom"
			and String(loom.get("action_id")) == "wayweaver_string")
	_check("final clear and the restored master forge project the Hunt and second-hearth stations",
		hunt != null and forge != null and String(hunt.get("action_id")) == "quiet_tooth_grip"
			and String(forge.get("action_id")) == "wayweaver"
			and forge.get_node_or_null("SecondHearthGlow") != null)
	if OS.get_environment("WYRD_SHOT") != "":
		await _frames(5)
		var texture := root.get_viewport().get_texture()
		var image := texture.get_image() if texture != null else null
		if image != null:
			image.save_png("/tmp/wayweaver_town_stations.png")

	# The physical adapter opens the exact configured panel.  It is deliberately
	# allowed to be disabled here: Game owns the material and pack predicate.
	quill.call("interact", null)
	await _frames()
	var panel := _mastery_panel(town)
	_check("station interaction opens a modal for its exact station/action",
		panel != null and String(panel.get("station_id")) == "quill_mastery"
			and String(panel.get("action_id")) == "threefold_draught")
	if panel != null:
		panel.call("_close")
	await _frames()
	_check("closing the station leaves no second modal surface behind",
		_mastery_panel(town) == null)

	if current_scene != null:
		current_scene.free()
	await _frames()
	print("--- Town mastery stations: %d PASS, %d FAIL ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
