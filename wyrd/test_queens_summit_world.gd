extends SceneTree

# Focused presentation gate for the authored Queen chapter.  Campaign math is
# intentionally exercised elsewhere: this test locks the world-side rule that
# only the explicit canonical settlement token can reveal the non-traversable
# Pale Stair, while the old Summit handoff remains unable to do so.

const CampaignClueScript = preload("res://scripts/campaign_clue.gd")
const LayoutLoaderScript = preload("res://scripts/layout_loader.gd")
const PaleStairScript = preload("res://scripts/pale_stair.gd")
const ChartsData = preload("res://data/charts.gd")

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


func _run() -> void:
	print("--- Queen's Summit world presentation ---")
	await _test_shed_crown_thorn_presentations()
	await _test_pale_stair_visual_and_read()
	_test_explicit_world_adapter()
	_test_web_export_contract()
	print("--- Queen's Summit world: %d PASS, %d FAIL ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


func _test_shed_crown_thorn_presentations() -> void:
	var records: Dictionary = ChartsData.QUEENS_SUMMIT_SHED_CROWN_THORN_PRESENTATIONS
	var ids := ["shed_crown_thorn_1", "shed_crown_thorn_2", "shed_crown_thorn_3", "shed_crown_thorn_4"]
	var exact := records.size() == 4
	for id_v in ids:
		var id := String(id_v)
		var record: Dictionary = records.get(id, {})
		exact = exact and String(record.get("presentation", "")) == "shed_crown_thorn" \
			and not String(record.get("title", "")).is_empty() \
			and (record.get("pages", []) as Array).size() >= 2
	_check("four authored Shed Crown-Thorns have their own presentation family", exact, records)
	var clue: Node3D = CampaignClueScript.new()
	clue.setup({"id": "shed_crown_thorn_1", "presentation": "shed_crown_thorn",
		"chapter_id": "queens_summit"})
	root.add_child(clue)
	await process_frame
	_check("Crown-Thorn clue builds a snowy thorn prop and remains copy-only",
		clue.get_prompt_text() == "[E/A] Study the shed crown-thorn"
		and clue.get_node_or_null("ShedCrownThornSnow") != null
		and clue.get_node_or_null("ShedCrownThorn1") != null
		and not bool(clue.read_now().get("changed", true)))
	clue.free()


func _test_pale_stair_visual_and_read() -> void:
	_check("Pale Stair GLB exists", FileAccess.file_exists(
		"res://models/landmark_rootroad_stair_v1.glb"))
	var stair: Node3D = PaleStairScript.new()
	stair.set_campaign_settlement_view({"canonical_queen": true, "pale_stair": true})
	root.add_child(stair)
	await process_frame
	await _capture_if_requested(stair)
	var first: Dictionary = stair.read_now()
	var second: Dictionary = stair.read_now()
	_check("Pale Stair is a readable outlined landmark with its own pale light",
		stair.is_in_group("pale_stair")
		and stair.get_node_or_null("PaleStairLandmark") != null
		and stair.get_node_or_null("PaleStairLight") != null
		and stair.get_prompt_text() == "[E/A] Look down the Pale Stair")
	_check("Pale Stair reads twice without travel, collision, or state mutation",
		bool(first.get("repeatable", false)) and bool(second.get("repeatable", false))
		and String(first.get("route", "")) == "pale_oath_not_yet_walkable"
		and not bool(first.get("changed", true)) and not bool(second.get("changed", true))
		and stair.get_node_or_null("Solid") == null)
	stair.free()
	await process_frame


func _test_explicit_world_adapter() -> void:
	var loader: Node3D = LayoutLoaderScript.new()
	loader._boss_arena_center = Vector3(12.5, 0.0, 9.5)
	_check("legacy/handoff-looking tokens cannot reveal the Pale Stair",
		not loader.reveal_pale_stair_from_campaign_settlement({"pale_stair": true})
		and not loader.reveal_pale_stair_from_campaign_settlement({
			"canonical_queen": false, "pale_stair": true, "handoff_contract": "legacy_summit_handoff"})
		and loader.pale_stair_landmark() == null)
	var first: bool = loader.reveal_pale_stair_from_campaign_settlement(
		{"canonical_queen": true, "pale_stair": true})
	var landmark: Node3D = loader.pale_stair_landmark()
	var second: bool = loader.reveal_pale_stair_from_campaign_settlement(
		{"canonical_queen": true, "pale_stair": true})
	_check("canonical Queen token creates exactly one arena-local Pale Stair",
		first and second and landmark != null and landmark.name == "PaleStair"
		and landmark.position == Vector3(12.5, 0.02, 7.45)
		and loader.get_child_count() == 1)
	loader.free()
	var origin_loader: Node3D = LayoutLoaderScript.new()
	origin_loader._boss_arena_center = Vector3.ZERO
	origin_loader._boss_arena_ready = true
	_check("an origin-centred generated Queen arena may reveal its Pale Stair",
		origin_loader.reveal_pale_stair_from_campaign_settlement({
			"canonical_queen": true, "pale_stair": true})
			and origin_loader.pale_stair_landmark() != null)
	origin_loader.free()


func _test_web_export_contract() -> void:
	var preset := FileAccess.get_file_as_string("res://export_presets.cfg")
	_check("the Web export explicitly packs the Pale Stair GLB",
		preset.contains("models/landmark_rootroad_stair_v1.glb"))


func _capture_if_requested(stair: Node3D) -> void:
	var path := OS.get_environment("WYRD_QUEEN_STAIR_SHOT")
	if path == "" or DisplayServer.get_name() == "headless":
		return
	var env := WorldEnvironment.new()
	env.name = "QueenStairCaptureEnvironment"
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.035, 0.055, 0.10)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.35, 0.46, 0.68)
	env.environment.ambient_light_energy = 0.8
	env.environment.glow_enabled = true
	env.environment.glow_intensity = 1.1
	root.add_child(env)
	var key := DirectionalLight3D.new()
	key.name = "QueenStairCaptureKey"
	key.light_color = Color(0.68, 0.82, 1.0)
	key.light_energy = 2.0
	key.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	root.add_child(key)
	var camera := Camera3D.new()
	camera.name = "QueenStairCaptureCamera"
	camera.position = stair.global_position + Vector3(7.6, -9.2, 6.4)
	root.add_child(camera)
	camera.fov = 55.0
	camera.look_at(stair.global_position + Vector3(0.0, 1.05, 0.35), Vector3.UP)
	camera.current = true
	await process_frame
	await process_frame
	var image := root.get_viewport().get_texture().get_image()
	if image != null:
		var err := image.save_png(path)
		print("[queen world] Pale Stair screenshot → %s (err=%d)" % [path, err])
	camera.free()
	key.free()
	env.free()
