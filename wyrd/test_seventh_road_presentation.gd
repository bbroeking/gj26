extends SceneTree

const CampaignData = preload("res://data/campaign.gd")
const Progression = preload("res://data/progression.gd")

var _pass := 0
var _fail := 0


func _check(name: String, ok: bool, detail = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % name)
	else:
		_fail += 1
		print("  ✗ %s %s" % [name, str(detail)])


func _initialize() -> void:
	call_deferred("_run")


func _seventh_state() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id in CampaignData.CHAPTER_ORDER:
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
	state.relics = ["green_root_rune", "mist_root_rune", "fang_root_rune"]
	state.restorations = ["trophy_hall", "sallow_jetty", "skald_archive"]
	return CampaignData.normalize_campaign_state(state)


func _run() -> void:
	print("--- Seventh Road settlement presentation ---")
	var game: Node = root.get_node("Game")
	var campaign_saved: Dictionary = game.campaign_state.duplicate(true)
	var materials_saved: Dictionary = game.materials.duplicate(true)
	var source_saved: Array = game.chart_source_unlocks.duplicate()
	var trades_saved: Dictionary = game.trades.duplicate(true)
	var modal_saved := int(game.modal_count)
	game.persistence_enabled = false
	game.campaign_state = _seventh_state()
	game.materials = {"alpha_fang": 1}
	game.chart_source_unlocks = []
	game.trades.wayfinding = {"xp": Progression.xp_for_level(16), "lv": 16}
	game.modal_count = 1
	game.tutorial_step = 7
	game.seen_hints = {"vignette_arrival": true}
	game.reconcile_unresumable_campaign_attempts()
	var campaign_before: Dictionary = game.campaign_state.duplicate(true)

	change_scene_to_file("res://scenes/Town.tscn")
	await process_frame
	await process_frame
	await process_frame
	var town := current_scene
	var hall := town.get_node_or_null("FirstKnotTrophyHall") if town != null else null
	var atlas := town.get_node_or_null("AtlasDeepRumourSource") if town != null else null
	var archive := town.get_node_or_null("SkaldArchive") if town != null else null
	_check("Trophy Hall projects one Alpha Fang and Fang Root record",
		hall != null and hall.get_node_or_null("SeventhRoadRecord") != null
		and hall.get_node_or_null("AlphaFangRecord") != null
		and hall.get_node_or_null("FangRootRune") != null
		and hall.seventh_presentation_ids() == {
			"relic_id": "fang_root_rune", "restoration_id": "skald_archive",
			"material_record_id": "alpha_fang",
		})
	_check("Living Atlas paints the pale Seventh Road settlement mark",
		atlas != null and atlas.seventh_road_settlement_visible()
		and atlas.get_node_or_null("SeventhRoadAtlasMark") != null)
	_check("Skald Archive is one visible review Interactable",
		archive != null and archive.visible
		and archive.get_node_or_null("ArchiveBack") != null
		and archive.get_node_or_null("ArchiveLectern") != null
		and archive.get_node_or_null("FangRootRune") != null
		and archive.get_prompt_text() == "[E/A] Review the Skald Archive")
	_check("Archive review reflects the authoritative four-track ledger",
		"4 of 4 Cold Tracks" in " ".join(archive.review_pages()))
	_check("Seventh settlement unlocks the Archive Summit source only",
		game.chart_source_unlocks.has("skald_queens_summit")
		and String(game.chart_source_status("skald_queens_summit").state) == "eligible")

	var read: Dictionary = archive.read_now()
	_check("host Archive read grants the missing-only Summit lesson",
		bool(read.get("changed", false))
		and game.material_count("atlas_folio") == 1
		and game.material_count("cold_track") == 2
		and game.material_count("climbing_cord") == 2)
	await _capture_if_requested(archive)
	var materials_after_read: Dictionary = game.materials.duplicate(true)
	var guest_view := CampaignData.settlement_view(game.campaign_state,
		{"guest": true, "read_only": true})
	archive.set_settlement_view(guest_view)
	var guest_read: Dictionary = archive.read_now()
	_check("guest Archive inspection is copy-only",
		bool(guest_read.get("read_only", false))
		and not bool(guest_read.get("changed", false))
		and game.materials == materials_after_read
		and game.campaign_state == campaign_before)

	archive.set_settlement_view({"available": false, "chapters": {}})
	hall.set_settlement_view({"available": false, "chapters": {}})
	atlas.set_settlement_view({"available": false, "chapters": {}})
	await process_frame
	await process_frame
	_check("revoked projection removes Seventh records without latching local truth",
		not archive.visible
		and hall.get_node_or_null("SeventhRoadRecord") == null
		and atlas.get_node_or_null("SeventhRoadAtlasMark") == null)

	if town != null:
		town.free()
	await process_frame
	game.campaign_state = campaign_saved
	game.materials = materials_saved
	game.chart_source_unlocks = source_saved
	game.trades = trades_saved
	game.modal_count = modal_saved
	print("--- Seventh presentation: %d PASS, %d FAIL ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


func _capture_if_requested(archive: Node) -> void:
	var path := OS.get_environment("WYRD_SEVENTH_ARCHIVE_SHOT")
	if path == "" or DisplayServer.get_name() == "headless":
		return
	var rig := get_first_node_in_group("camera_rig")
	if archive is Node3D and rig != null and rig.has_method("begin_cinematic") \
			and rig.has_method("apply_cinematic_frame"):
		rig.begin_cinematic()
		rig.apply_cinematic_frame({
			"focus": (archive as Node3D).global_position + Vector3(0.0, 1.05, 0.0),
			"yaw": 18.0, "pitch": 13.0, "zoom": 4.8,
		})
		await process_frame
		await process_frame
	var texture := root.get_viewport().get_texture()
	if texture == null:
		return
	var image := texture.get_image()
	if image != null:
		var err := image.save_png(path)
		print("[seventh presentation] Archive screenshot → %s (err=%d)" % [path, err])
