extends SceneTree

# First Knot Homecoming presentation contract. Domain truth and its matrix live
# in test_homecoming_view.gd; this script only proves that Town-side presenters
# consume the projection without turning it into campaign, inventory, or save
# work.

const CampaignData = preload("res://data/campaign.gd")
const TrophyHallScript = preload("res://scripts/trophy_hall.gd")
const LivingAtlasPanelScript = preload("res://scripts/living_atlas_panel.gd")

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
	print("--- First Knot Homecoming presentation contract ---")
	var time_scale_before := Engine.time_scale
	Engine.time_scale = 0.01
	var game: Node = root.get_node("Game")
	game.persistence_enabled = false
	game.campaign_state = _cleared_state()
	game.pending_run_debrief = {}
	game.tutorial_step = 7
	game.seen_hints = {"vignette_arrival": true}
	# Simulate an earlier arrival modal owning the parchment layer. Homecoming
	# must wait rather than stack a second dialog.
	game.modal_count = 1
	# Keep the production delayed-return path, but slow timers so its music
	# callback cannot race this short isolated test's teardown.
	game.set("_returning_from_delve", true)
	var fingerprint := CampaignData.campaign_fingerprint(game.campaign_state)
	var campaign_before: Dictionary = game.campaign_state.duplicate(true)
	var materials_before: Dictionary = game.materials.duplicate(true)

	# The real adapter supplies a host/local projection; Town must consume it as
	# presentation and show the compact Hall plus the Atlas road in the same boot.
	change_scene_to_file("res://scenes/Town.tscn")
	await process_frame
	await process_frame
	await process_frame
	var town := current_scene
	var hall := town.get_node_or_null("FirstKnotTrophyHall") if town != null else null
	var atlas := town.get_node_or_null("AtlasDeepRumourSource") if town != null else null
	_check("cleared Homecoming builds one visible yard-side Trophy Hall",
		hall != null and hall.visible and hall.is_in_group("interactable"))
	_check("Hall presents Rune, durable Tusker record, and inert covered bow-rest",
		hall != null and hall.get_node_or_null("GreenRootRune") != null
			and hall.get_node_or_null("TuskerRecordPlaque") != null
			and hall.get_node_or_null("CoveredBowRest") != null
			and hall.presentation_ids() == {
				"rune_id": "green_root_rune", "tusk_record_id": "tusker_tusk",
				"covered_bow_rest_id": "covered_bow_rest",
			})
	_check("Homecoming has one controller-parity inspect verb",
		hall != null and hall.get_prompt_text() == "[E/A] Inspect the Trophy Hall"
			and _interactable_count(hall) == 1)
	_check("Atlas receives the same projection's wet-road Sallow handoff",
		atlas != null and atlas.homecoming_handoff_visible()
			and atlas.get_node_or_null("SallowWetRoadHandoff") != null)
	_check("Homecoming waits while another arrival modal owns the UI",
		get_first_node_in_group("FirstKnotHomecomingDebrief") == null
			and bool(town.get("_homecoming_waiting_for_modal")))
	game.modal_count = 0
	game.modal_changed.emit(false)
	await process_frame
	await process_frame
	var debrief := get_first_node_in_group("FirstKnotHomecomingDebrief")
	_check("local canonical event shows one warm session-only debrief",
		debrief != null)

	# Joining can begin after an offline Town has already rendered local truth.
	# The synchronous empty-snapshot signal must revoke both geometry and any
	# open local debrief before the reliable host snapshot arrives.
	var net := root.get_node("NetGame")
	var client := ENetMultiplayerPeer.new()
	client.create_client("127.0.0.1", 7777)
	net.multiplayer.multiplayer_peer = client
	net.active = true
	net._sync_homecoming_view({})
	await process_frame
	await process_frame
	_check("late guest join revokes local Hall and debrief while fail-closed",
		town.get_node_or_null("FirstKnotTrophyHall") == null
			and get_first_node_in_group("FirstKnotHomecomingDebrief") == null)
	net.active = false
	net.multiplayer.multiplayer_peer = null
	net._sync_homecoming_view({})
	await process_frame
	await process_frame
	hall = town.get_node_or_null("FirstKnotTrophyHall")
	_check("late projection refresh adds exactly one Hall",
		hall != null and town.find_children("FirstKnotTrophyHall", "", true, false).size() == 1)

	# The debrief has no acknowledgement write: it can open once in this process,
	# then close without touching campaign or materials.
	town.call("_maybe_show_first_knot_homecoming_debrief")
	await process_frame
	debrief = get_first_node_in_group("FirstKnotHomecomingDebrief")
	_check("revoked local debrief can present after leaving guest context",
		debrief != null)
	if debrief != null:
		debrief.call("_finish")
		await process_frame
	await _capture_if_requested()
	_check("Town presentation and debrief leave campaign and materials untouched",
		CampaignData.campaign_fingerprint(game.campaign_state) == fingerprint
			and game.campaign_state == campaign_before
			and game.materials == materials_before)

	if hall != null:
		hall.interact(null)
		await process_frame
		var inspect := get_first_node_in_group("TrophyHallInspectDialog")
		_check("the Hall inspect is copy-only and opens no reward path", inspect != null
			and CampaignData.campaign_fingerprint(game.campaign_state) == fingerprint
			and game.campaign_state == campaign_before
			and game.materials == materials_before)
		if inspect != null:
			inspect.call("_finish")
			await process_frame

	# The presenter also remains absent when handed the projection's truthful
	# fresh/D2-shaped invisible state; it does not reconstruct campaign facts.
	var absent: Node3D = TrophyHallScript.new()
	absent.set_homecoming_view({"visible": false, "restoration_visible": false})
	root.add_child(absent)
	await process_frame
	_check("invisible projection leaves no ruined or dormant Hall geometry",
		not absent.visible and absent.get_node_or_null("HallBack") == null)
	absent.queue_free()

	var d2_view: Dictionary = game.first_knot_homecoming_view({"d2_reprise": true})
	var d2_event: Dictionary = d2_view.get("debrief_event", {})
	_check("D2 context keeps the durable Hall but suppresses the debrief trigger",
		bool(d2_view.get("visible", false)) and bool(d2_view.get("d2_ineligible", false))
			and not bool(d2_event.get("available", true)))
	if town != null:
		town.free()
	await process_frame
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("stop_music"):
		sfx.stop_music()
		var music_player = sfx.get("_music")
		if music_player is AudioStreamPlayer:
			(music_player as AudioStreamPlayer).stream = null
			(music_player as AudioStreamPlayer).free()
			sfx.set("_music", null)
	await process_frame
	await process_frame
	await process_frame
	Engine.time_scale = time_scale_before

	print("--- Homecoming presentation: %d PASS, %d FAIL ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


func _cleared_state() -> Dictionary:
	var state := CampaignData.empty_state()
	var chapter: Dictionary = state.chapters.first_knot
	chapter.cleared = true
	chapter.clue_count = 3
	state.relics = ["green_root_rune"]
	state.restorations = ["trophy_hall"]
	return CampaignData.normalize_campaign_state(state)


func _interactable_count(node: Node) -> int:
	var count := 1 if node.is_in_group("interactable") else 0
	for child in node.get_children():
		if child.is_in_group("interactable"):
			count += 1
	return count


func _capture_if_requested() -> void:
	var path := OS.get_environment("WYRD_HOMECOMING_SHOT")
	if path == "":
		return
	if DisplayServer.get_name() == "headless":
		print("[homecoming presentation] screenshot skipped (headless renderer)")
		return
	var hall := current_scene.get_node_or_null("FirstKnotTrophyHall") \
		if current_scene != null else null
	var rig := get_first_node_in_group("camera_rig")
	if hall is Node3D and rig != null and rig.has_method("begin_cinematic") \
			and rig.has_method("apply_cinematic_frame"):
		rig.begin_cinematic()
		rig.apply_cinematic_frame({
			"focus": (hall as Node3D).global_position + Vector3(0.0, 1.1, 0.0),
			"yaw": 0.0, "pitch": 31.0, "zoom": 10.5,
		})
		await process_frame
		await process_frame
	var texture := root.get_viewport().get_texture()
	if texture == null:
		print("[homecoming presentation] screenshot skipped (headless renderer)")
		return
	var image := texture.get_image()
	if image == null:
		print("[homecoming presentation] screenshot skipped (no viewport image)")
		return
	var err := image.save_png(path)
	print("[homecoming presentation] screenshot → %s (err=%d)" % [path, err])
	var atlas_path := OS.get_environment("WYRD_HOMECOMING_ATLAS_SHOT")
	var atlas := current_scene.get_node_or_null("AtlasDeepRumourSource") \
		if current_scene != null else null
	if atlas_path != "" and atlas is Node3D and rig != null \
			and rig.has_method("apply_cinematic_frame"):
		rig.apply_cinematic_frame({
			"focus": (atlas as Node3D).global_position + Vector3(0.0, 0.1, 0.0),
			"yaw": 0.0, "pitch": 24.0, "zoom": 6.5,
		})
		await process_frame
		await process_frame
		var atlas_image := root.get_viewport().get_texture().get_image()
		var atlas_err := atlas_image.save_png(atlas_path)
		print("[homecoming presentation] Atlas screenshot → %s (err=%d)" \
			% [atlas_path, atlas_err])
