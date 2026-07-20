extends SceneTree

# Slice D8 / Root Below — world-generation acceptance. The authored road must
# never lose its one clue or its two signature materials to a seed or Affix
# twin, while the two earlier Rootroad biomes keep their exact resource sets.

const CampaignData = preload("res://data/campaign.gd")
const ChartsData = preload("res://data/charts.gd")
const DungeonGenScript = preload("res://scripts/dungeon_gen.gd")
const CampaignClueScript = preload("res://scripts/campaign_clue.gd")

var _pass := 0
var _fail := 0


func _check(label: String, ok: bool, detail = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % label)
	else:
		_fail += 1
		print("  ✗ %s %s" % [label, str(detail)])


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("--- Root Below generation ---")
	_test_fifty_seed_twin_contract()
	_test_no_sixth_waymark()
	_test_rootroad_compatibility()
	await _test_lost_waymark_presentation()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


func _root_below_config(good: bool, clue: Dictionary = {
		"clue_id": "lost_waymark_1", "presentation": "lost_waymark",
		"chapter_id": "unwritten_road"}) -> Dictionary:
	var cfg: Dictionary = (ChartsData.TEMPLATES.root_below.gen as Dictionary).duplicate(true)
	cfg["template_id"] = "root_below"
	cfg["scope"] = "rootroads"
	cfg["tier"] = 3
	cfg["boss_kind"] = ""
	cfg["affixes"] = [{"id": "open_thread", "good": good,
		"resolvedId": "open_thread" if good else "snagged_thread"}]
	cfg["campaign_clue"] = clue.duplicate(true)
	return cfg


func _test_fifty_seed_twin_contract() -> void:
	var all_valid := true
	var twins_identical := true
	var failures: Array = []
	for offset in 50:
		var seed_value := 220001 + offset
		var open_layout: Dictionary = DungeonGenScript.generate(seed_value,
			_root_below_config(true))
		var snagged_layout: Dictionary = DungeonGenScript.generate(seed_value,
			_root_below_config(false))
		var open_ok := _root_below_layout_valid(open_layout)
		var snagged_ok := _root_below_layout_valid(snagged_layout)
		if not open_ok or not snagged_ok:
			all_valid = false
			if failures.size() < 4:
				failures.append({"seed": seed_value, "open": open_ok,
					"snagged": snagged_ok})
		if _guarantee_signature(open_layout) != _guarantee_signature(snagged_layout):
			twins_identical = false
			if failures.size() < 4:
				failures.append({"seed": seed_value,
					"open_signature": _guarantee_signature(open_layout),
					"snagged_signature": _guarantee_signature(snagged_layout)})
	_check("50 seeds each guarantee one reachable Waymark, Waysteel, and Root Sap",
		all_valid, failures)
	_check("Open Thread and Snagged Thread preserve identical guarantee identities",
		twins_identical, failures)


func _root_below_layout_valid(layout: Dictionary) -> bool:
	if layout.is_empty() or not bool(layout.get("required_content_valid", false)) \
			or not bool(layout.get("required_resources_valid", false)) \
			or not bool(layout.get("required_campaign_clue_valid", false)) \
			or String(layout.get("bossKind", "not-empty")) != "":
		return false
	var clues: Array = layout.get("campaign_clues", [])
	if clues.size() != 1 or String((clues[0] as Dictionary).get("id", "")) \
			!= "lost_waymark_1":
		return false
	var boss_room_id := int((layout.get("bossRoom", {}) as Dictionary).get("id", -1))
	var clue_room_id := int((clues[0] as Dictionary).get("room_id", -1))
	if clue_room_id <= 0 or clue_room_id == boss_room_id \
			or not _reachable(layout, clue_room_id):
		return false
	for item_id in ["waysteel_shard", "root_sap"]:
		var matches := _decor_for_item(layout, item_id)
		if matches.size() != 1:
			return false
		var room_id := int((matches[0] as Dictionary).get("room_id", -1))
		if room_id <= 0 or room_id == boss_room_id or not _reachable(layout, room_id):
			return false
	return true


func _decor_for_item(layout: Dictionary, item_id: String) -> Array:
	var out: Array = []
	for row_v in layout.get("decor", []):
		if row_v is Dictionary and String((row_v as Dictionary).get("item", "")) == item_id:
			out.append(row_v)
	return out


func _reachable(layout: Dictionary, target_room_id: int) -> bool:
	var room_count := (layout.get("rooms", []) as Array).size()
	if target_room_id < 0 or target_room_id >= room_count:
		return false
	var adjacency: Array = []
	for _index in room_count:
		adjacency.append([])
	for edge_v in layout.get("room_edges", []):
		var edge: Array = edge_v
		var a := int(edge[0])
		var b := int(edge[1])
		(adjacency[a] as Array).append(b)
		(adjacency[b] as Array).append(a)
	var seen := {0: true}
	var queue: Array[int] = [0]
	while not queue.is_empty():
		var current: int = queue.pop_front()
		if current == target_room_id:
			return true
		for next_v in adjacency[current]:
			var next_id := int(next_v)
			if not seen.has(next_id):
				seen[next_id] = true
				queue.append(next_id)
	return false


func _guarantee_signature(layout: Dictionary) -> Array:
	var signature: Array = []
	for clue_v in layout.get("campaign_clues", []):
		var clue: Dictionary = clue_v
		signature.append("clue:%s:%d:%d:%d" % [String(clue.get("id", "")),
			int(clue.get("x", -1)), int(clue.get("y", -1)),
			int(clue.get("room_id", -1))])
	for item_id in ["waysteel_shard", "root_sap"]:
		for row_v in _decor_for_item(layout, item_id):
			var row: Dictionary = row_v
			signature.append("resource:%s:%d:%d:%d" % [item_id,
				int(row.get("x", -1)), int(row.get("y", -1)),
				int(row.get("room_id", -1))])
	signature.sort()
	return signature


func _fire_cleared() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id_v in CampaignData.CHAPTER_ORDER:
		var chapter_id := String(chapter_id_v)
		if chapter_id == CampaignData.UNWRITTEN_ROAD:
			break
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
		chapter.banked_chart_ids = ["%s-%d" % [chapter_id, chapter.clue_count]]
	return CampaignData.normalize_campaign_state(state)


func _test_no_sixth_waymark() -> void:
	var state := _fire_cleared()
	for index in 5:
		var result: Dictionary = CampaignData.record_successful_chart_return(state,
			"root_below", "root-return-%d" % (index + 1), 22, {})
		state = result.state
	var next: Dictionary = CampaignData.next_clue_for_chart(state, "root_below",
		"root-return-6", 23)
	var layout: Dictionary = DungeonGenScript.generate(229999,
		_root_below_config(true, next))
	_check("five returns expose no sixth Lost Waymark in policy or generated layout",
		next.is_empty() and (layout.get("campaign_clues", []) as Array).is_empty()
			and bool(layout.get("required_campaign_clue_valid", false)),
		{"next": next, "clues": layout.get("campaign_clues", [])})


func _test_rootroad_compatibility() -> void:
	var pale: Dictionary = DungeonGenScript.generate(230001, {
		"scope": "rootroads", "tier": 3, "boss_kind": "",
		"required_biome_gather": ["wildgold", "wellwater"],
	})
	var ashen: Dictionary = DungeonGenScript.generate(230002, {
		"scope": "ashen_bough", "tier": 3, "boss_kind": "",
		"required_biome_gather": ["embersage", "wellwater"],
	})
	var pale_ok := _item_count(pale, "wildgold_ore") == 1 \
		and _item_count(pale, "wellmoss") == 2 \
		and _item_count(pale, "wellwater") == 1 \
		and _item_count(pale, "embersage") == 0 \
		and _item_count(pale, "waysteel_shard") == 0 \
		and _item_count(pale, "root_sap") == 0
	var ashen_ok := _item_count(ashen, "wildgold_ore") == 1 \
		and _item_count(ashen, "wellmoss") == 2 \
		and _item_count(ashen, "wellwater") == 1 \
		and _item_count(ashen, "embersage") == 2 \
		and _item_count(ashen, "waysteel_shard") == 0 \
		and _item_count(ashen, "root_sap") == 0
	_check("Pale Veins keeps its 1 Wildgold / 2 Wellmoss / 1 Wellwater contract",
		pale_ok, pale.get("required_resource_manifest", []))
	_check("Ashen Bough keeps Pale resources plus exactly two Embersage",
		ashen_ok, ashen.get("required_resource_manifest", []))


func _item_count(layout: Dictionary, item_id: String) -> int:
	return _decor_for_item(layout, item_id).size()


func _test_lost_waymark_presentation() -> void:
	var clue = CampaignClueScript.new()
	clue.setup({"id": "lost_waymark_1", "presentation": "lost_waymark",
		"chapter_id": "unwritten_road"})
	root.add_child(clue)
	await process_frame
	var read: Dictionary = clue.read_now()
	var visual_ok := clue.is_in_group("lost_waymark_clue") \
		and clue.get_node_or_null("LostWaymarkBed") != null \
		and clue.get_node_or_null("LostWaymarkLine1") != null \
		and clue.get_node_or_null("LostWaymarkLooseLine") != null
	_check("Lost Waymark has authored copy-only dialog and a readable world fallback",
		visual_ok and String(clue.clue_title) != "" and not clue._pages().is_empty() \
			and clue.get_prompt_text() == "[E/A] Read the lost Waymark" \
			and bool(read.ok) and not bool(read.changed), read)
	clue.queue_free()
	await process_frame
