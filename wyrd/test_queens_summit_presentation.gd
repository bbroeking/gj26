extends SceneTree

# Queen's Summit settlement presenters consume only CampaignData's generic
# projection.  This gate proves their new props are visual accounts, not a
# second inventory/reward path, and that a guest receives the host's copy-only
# projection without presenters consulting local campaign state.

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


func _queen_state() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id in CampaignData.CHAPTER_ORDER:
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
	state.relics = ["green_root_rune", "mist_root_rune", "fang_root_rune", "crown_root_rune"]
	state.restorations = ["trophy_hall", "sallow_jetty", "skald_archive", "pale_stair"]
	return CampaignData.normalize_campaign_state(state)


func _run() -> void:
	print("--- Queen's Summit settlement presentation ---")
	var game: Node = root.get_node("Game")
	var campaign_saved: Dictionary = game.campaign_state.duplicate(true)
	var materials_saved: Dictionary = game.materials.duplicate(true)
	var source_saved: Array = game.chart_source_unlocks.duplicate()
	var trades_saved: Dictionary = game.trades.duplicate(true)
	var modal_saved := int(game.modal_count)
	game.persistence_enabled = false
	game.campaign_state = _queen_state()
	# The Oath Nail may exist in the real satchel; none of the checks below rely
	# on that fact, and the Hall must never mint a second copy.
	game.materials = {"oath_nail": 1}
	game.chart_source_unlocks = []
	game.trades.wayfinding = {"xp": Progression.xp_for_level(17), "lv": 17}
	game.modal_count = 1
	game.tutorial_step = 7
	game.seen_hints = {"vignette_arrival": true}
	game.reconcile_unresumable_campaign_attempts()
	var campaign_before: Dictionary = game.campaign_state.duplicate(true)
	var materials_before: Dictionary = game.materials.duplicate(true)
	var source_before: Array = game.chart_source_unlocks.duplicate()

	change_scene_to_file("res://scenes/Town.tscn")
	await process_frame
	await process_frame
	await process_frame
	var town := current_scene
	var hall := town.get_node_or_null("FirstKnotTrophyHall") if town != null else null
	var atlas := town.get_node_or_null("AtlasDeepRumourSource") if town != null else null
	var archive := town.get_node_or_null("SkaldArchive") if town != null else null
	_check("Trophy Hall projects one Crown Root Rune and non-loot Oath Nail record",
		hall != null and hall.get_node_or_null("QueensSummitRecord") != null
		and hall.get_node_or_null("CrownRootRune") != null
		and hall.get_node_or_null("OathNailRecord") != null
		and hall.queens_summit_presentation_ids() == {
			"relic_id": "crown_root_rune", "restoration_id": "pale_stair",
			"material_record_id": "oath_nail",
		})
	_check("Living Atlas names the final settled landmark",
		atlas != null and atlas.queens_summit_settlement_visible()
		and atlas.get_node_or_null("QueensSummitAtlasMark") != null
		and (atlas.get_node_or_null("QueensSummitAtlasMark/QueensSummitLabel") as Label3D).text
			== "CROWN ROOT SET  ·  PALE STAIR FOUND")
	_check("Skald Archive appends the post-Queen Pale Oath page",
		archive != null and archive.visible and archive.queen_settlement_visible()
		and "Pale Stair is found" in " ".join(archive.review_pages()))
	var host_read: Dictionary = archive.read_now()
	_check("post-Queen Archive reread is copy-only and does not mutate host truth",
		bool(host_read.get("post_queen", false)) and not bool(host_read.get("changed", true))
		and game.campaign_state == campaign_before and game.materials == materials_before
		and game.chart_source_unlocks == source_before)
	await _capture_if_requested(hall, atlas)

	var guest_view := CampaignData.settlement_view(game.campaign_state,
		{"guest": true, "read_only": true})
	hall.set_settlement_view(guest_view)
	atlas.set_settlement_view(guest_view)
	archive.set_settlement_view(guest_view)
	# The presenters duplicate their inputs. Mutating the caller-owned snapshot
	# afterwards cannot latch a fake local campaign state into their displays.
	var guest_chapters: Dictionary = guest_view.chapters
	var guest_queen: Dictionary = guest_chapters.queens_summit
	guest_queen.visible = false
	var guest_read: Dictionary = archive.read_now()
	_check("guest projection remains visible but its Archive inspection is read-only",
		hall.get_node_or_null("CrownRootRune") != null
		and atlas.get_node_or_null("QueensSummitAtlasMark") != null
		and archive.visible and archive.get_prompt_text() == "[E/A] Review the host's Skald Archive"
		and bool(guest_read.get("read_only", false)) and not bool(guest_read.get("changed", true))
		and game.campaign_state == campaign_before and game.materials == materials_before)

	var revoked := {"available": false, "read_only": true, "guest": false, "chapters": {}}
	hall.set_settlement_view(revoked)
	atlas.set_settlement_view(revoked)
	archive.set_settlement_view(revoked)
	await process_frame
	await process_frame
	_check("revoked generic projection removes Queen records without latching truth",
		hall.get_node_or_null("QueensSummitRecord") == null
		and hall.get_node_or_null("CrownRootRune") == null
		and hall.get_node_or_null("OathNailRecord") == null
		and atlas.get_node_or_null("QueensSummitAtlasMark") == null
		and not archive.visible
		and game.campaign_state == campaign_before and game.materials == materials_before)

	var host_view := CampaignData.settlement_view(game.campaign_state)
	hall.set_settlement_view(host_view)
	atlas.set_settlement_view(host_view)
	archive.set_settlement_view(host_view)
	await process_frame
	await process_frame
	_check("reapplying canonical projection restores exactly one Queen record per surface",
		hall.find_children("CrownRootRune", "", true, false).size() == 1
		and hall.find_children("OathNailRecord", "", true, false).size() == 1
		and atlas.find_children("QueensSummitAtlasMark", "", true, false).size() == 1
		and archive.visible and "Pale Stair is found" in " ".join(archive.review_pages()))

	if town != null:
		town.free()
	await process_frame
	game.campaign_state = campaign_saved
	game.materials = materials_saved
	game.chart_source_unlocks = source_saved
	game.trades = trades_saved
	game.modal_count = modal_saved
	print("--- Queen presentation: %d PASS, %d FAIL ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


func _capture_if_requested(hall: Node, atlas: Node) -> void:
	var path := OS.get_environment("WYRD_QUEEN_TOWN_SHOT")
	if path == "" or DisplayServer.get_name() == "headless":
		return
	var rig := get_first_node_in_group("camera_rig")
	if hall is Node3D and atlas is Node3D and rig != null \
			and rig.has_method("begin_cinematic") and rig.has_method("apply_cinematic_frame"):
		rig.begin_cinematic()
		rig.apply_cinematic_frame({
			# The Hall is the compact Queen proof; the Atlas label sits behind it
			# in the same north yard.  A single focused frame is more useful than
			# a wide Town overview where both become unreadable.
			"focus": (hall as Node3D).global_position + Vector3(0.0, 1.05, 0.0),
			"yaw": 188.0, "pitch": 14.0, "zoom": 5.0,
		})
		await process_frame
		await process_frame
	var texture := root.get_viewport().get_texture()
	if texture == null:
		return
	var image := texture.get_image()
	if image != null:
		var err := image.save_png(path)
		print("[queen presentation] Town screenshot → %s (err=%d)" % [path, err])
