extends SceneTree

# Golden settlement presentation contract: Town renders the generic projection,
# keeps it copy-only, and removes transient host truth when the view disappears.

const CampaignData = preload("res://data/campaign.gd")

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
	call_deferred("_run")


func _golden_state() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id in [CampaignData.FIRST_KNOT, CampaignData.GOLDEN_WALLOW]:
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = 3
	state.relics = ["green_root_rune", "mist_root_rune"]
	state.restorations = ["trophy_hall", "sallow_jetty"]
	return CampaignData.normalize_campaign_state(state)


func _run() -> void:
	print("--- Golden Wallow settlement presentation ---")
	var game: Node = root.get_node("Game")
	var net: Node = root.get_node("NetGame")
	var campaign_saved: Dictionary = game.campaign_state.duplicate(true)
	var materials_saved: Dictionary = game.materials.duplicate(true)
	var charts_saved: Array = game.charts.duplicate(true)
	var source_saved: Array = game.chart_source_unlocks.duplicate()
	var modal_saved := int(game.modal_count)
	game.persistence_enabled = false
	game.campaign_state = _golden_state()
	game.materials = {"wightpelt": 1}
	game.charts = []
	game.chart_source_unlocks = []
	game.modal_count = 1
	game.tutorial_step = 7
	game.seen_hints = {"vignette_arrival": true}
	game.reconcile_unresumable_campaign_attempts()
	var fingerprint := CampaignData.campaign_fingerprint(game.campaign_state)
	var campaign_before: Dictionary = game.campaign_state.duplicate(true)
	var materials_before: Dictionary = game.materials.duplicate(true)

	change_scene_to_file("res://scenes/Town.tscn")
	await process_frame
	await process_frame
	await process_frame
	var town := current_scene
	var hall := town.get_node_or_null("FirstKnotTrophyHall") if town != null else null
	var atlas := town.get_node_or_null("AtlasDeepRumourSource") if town != null else null
	var jetty := town.get_node_or_null("SallowJetty") if town != null else null
	_check("Golden settlement keeps the Hall and adds its second chapter record",
		hall != null and hall.get_node_or_null("GoldenWallowRecord") != null
			and hall.get_node_or_null("MistRootRune") != null
			and hall.get_node_or_null("WightpeltRecord") != null
			and hall.golden_presentation_ids() == {
				"relic_id": "mist_root_rune", "restoration_id": "sallow_jetty",
				"material_record_id": "wightpelt",
			})
	_check("Living Atlas acknowledges the relit wet road",
		atlas != null and atlas.golden_settlement_visible()
			and atlas.get_node_or_null("GoldenWallowAtlasMark") != null)
	_check("Sallow Jetty instantiates the authored GLB as one semantic launch point",
		jetty != null and jetty.visible
			and jetty.get_node_or_null("SallowJettyModel") != null
			and jetty.get_prompt_text() == "[E/A] Launch a held Mire Chart"
			and jetty.launch_verb() == "Launch held Mire Chart"
			and jetty.restoration_ids() == {
				"restoration_id": "sallow_jetty", "relic_id": "mist_root_rune",
			})
	_check("First Knot migration exposes the copy-only Shallows Atlas lesson",
		game.chart_source_unlocks.has("atlas_sallow_shallows")
			and bool(game.chart_source_status("atlas_sallow_shallows").unlocked))
	await _capture_if_requested(jetty)

	# The Jetty filters only held Mire roads; choosing/launching remains Game's
	# existing authority and is not exercised by this presentation test.
	game.charts = [
		{"recipe_id": "green_hollow", "template_id": "tier_1", "scope": "hollow"},
		{"recipe_id": "sallow_shallows", "template_id": "mire_shallows", "scope": "mire"},
	]
	_check("Jetty selects only held Mire Charts", jetty.launchable_chart_indices() == [1])
	game.charts = []
	jetty.interact(null)
	_check("empty Jetty feedback cannot mint or spend settlement rewards",
		CampaignData.campaign_fingerprint(game.campaign_state) == fingerprint
			and game.campaign_state == campaign_before and game.materials == materials_before)

	# A generic snapshot can disappear while the compatibility Homecoming Hall
	# remains. Its Golden pieces must be reversible, not latched from local truth.
	hall.set_settlement_view({"available": false, "chapters": {}})
	atlas.set_settlement_view({"available": false, "chapters": {}})
	await process_frame
	await process_frame
	_check("hidden generic settlement removes only Golden Hall and Atlas records",
		hall.get_node_or_null("HallBack") != null
			and hall.get_node_or_null("GoldenWallowRecord") == null
			and atlas.get_node_or_null("GoldenWallowAtlasMark") == null)
	hall.set_settlement_view(game.campaign_settlement_view())
	atlas.set_settlement_view(game.campaign_settlement_view())
	await process_frame
	_check("restored host projection rebuilds one Golden record",
		hall.find_children("GoldenWallowRecord", "", true, false).size() == 1)

	_check("Golden debrief waits behind the active parchment modal",
		get_first_node_in_group("GoldenWallowSettlementDebrief") == null
			and bool(town.get("_settlement_waiting_for_modal")))
	game.modal_count = 0
	game.modal_changed.emit(false)
	await process_frame
	await process_frame
	var debrief := get_first_node_in_group("GoldenWallowSettlementDebrief")
	_check("canonical host gets one session-only Golden debrief", debrief != null)
	town.call("_maybe_show_golden_wallow_debrief")
	await process_frame
	_check("repeat presentation cannot stack a second Golden debrief",
		get_nodes_in_group("GoldenWallowSettlementDebrief").size() == 1)
	if debrief != null:
		debrief.call("_finish")
		await process_frame

	_check("all Golden presenters leave campaign and materials untouched",
		CampaignData.campaign_fingerprint(game.campaign_state) == fingerprint
			and game.campaign_state == campaign_before and game.materials == materials_before)

	if town != null:
		town.free()
	await process_frame
	game.campaign_state = campaign_saved
	game.materials = materials_saved
	game.charts = charts_saved
	game.chart_source_unlocks = source_saved
	game.modal_count = modal_saved
	net.active = false
	print("--- Golden presentation: %d PASS, %d FAIL ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


func _capture_if_requested(jetty: Node) -> void:
	var path := OS.get_environment("WYRD_GOLDEN_JETTY_SHOT")
	if path == "" or DisplayServer.get_name() == "headless":
		return
	var rig := get_first_node_in_group("camera_rig")
	if jetty is Node3D and rig != null and rig.has_method("begin_cinematic") \
			and rig.has_method("apply_cinematic_frame"):
		rig.begin_cinematic()
		rig.apply_cinematic_frame({
			"focus": (jetty as Node3D).global_position + Vector3(0.0, 1.0, -2.0),
			"yaw": 18.0, "pitch": 31.0, "zoom": 12.5,
		})
		await process_frame
		await process_frame
	var texture := root.get_viewport().get_texture()
	if texture == null:
		return
	var image := texture.get_image()
	if image != null:
		var err := image.save_png(path)
		print("[golden presentation] Jetty screenshot → %s (err=%d)" % [path, err])
