extends SceneTree

# D8 Slice 1 root integration gate.  Focused suites own the individual data,
# generator, Loom, Codex, and Atlas records; this harness proves their real
# source -> physical Table -> Waystone -> World -> return economy as one loop.

const CampaignData = preload("res://data/campaign.gd")
const ChartsData = preload("res://data/charts.gd")
const Progression = preload("res://data/progression.gd")
const LoomSourceScript = preload("res://scripts/threefold_loom_source.gd")

const ROOT_DRAFT := {
	"grid": {"n": "lost_waymark_tracing", "c": "nine_knot_leaf",
		"w": "threefold_binding"},
	"ink_rail": ["hedge_ink"],
}
const RUN_SEEDS := [221101, 221102, 221103, 221104, 221105]

var _pass := 0
var _fail := 0


func _check(label: String, ok: bool, detail = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % label)
	else:
		_fail += 1
		print("  ✗ %s %s" % [label, str(detail)])


func _initialize() -> void:
	call_deferred("_run")


func _fire_settled() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id_v in CampaignData.CHAPTER_ORDER:
		var chapter_id := String(chapter_id_v)
		if chapter_id == CampaignData.UNWRITTEN_ROAD:
			break
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
		for index in int(chapter.clue_count):
			chapter.banked_chart_ids.append("%s-settled-%d" % [chapter_id, index])
	state.relics = ["green_root_rune", "mist_root_rune", "fang_root_rune",
		"crown_root_rune", "pale_root_rune", "ember_root_rune"]
	state.threads = ["past_thread", "present_thread"]
	state.restorations = ["trophy_hall", "sallow_jetty", "skald_archive",
		"pale_stair", "rootroad_lift", "ember_kiln"]
	return CampaignData.normalize_campaign_state(state)


func _prepare_game(game: Node, hedge_ink: int = 5) -> void:
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.persistence_enabled = false
	game.campaign_state = _fire_settled()
	game.trades.wayfinding = {"xp": 4200, "lv": 22}
	game.trades.earthcraft = {"xp": Progression.xp_for_level(22), "lv": 22}
	game.trades.wildcraft = {"xp": Progression.xp_for_level(22), "lv": 22}
	game.materials = {"hedge_ink": hedge_ink}
	game.gold = 0
	game.charts = []
	game.known_chart_recipes = []
	game.chart_recipe_journal = ChartsData.fresh_recipe_journal()
	game.chart_source_unlocks = []
	game.seen_hints = {"chart_table_snug_returned": true}
	game.tutorial_step = 7
	game.modal_count = 0
	game._sync_campaign_chart_sources()


func _inscribe(game: Node, seed_value: int) -> Dictionary:
	var preview := ChartsData.preview_table(ROOT_DRAFT, game.chart_table_context())
	if not bool(preview.get("commit_ready", false)):
		return {"ok": false, "preview": preview}
	return game.try_inscribe_chart(ROOT_DRAFT, String(preview.fingerprint), seed_value)


func _wait_for_scene(scene_name: String, max_frames: int = 360) -> bool:
	for _frame in max_frames:
		await process_frame
		if current_scene != null and String(current_scene.name) == scene_name:
			await process_frame
			await physics_frame
			return true
	return false


func _close_town_debriefs() -> void:
	for _round in 40:
		var dialogs: Array = []
		for group_name in ["run_debrief", "FirstKnotHomecomingDebrief",
				"GoldenWallowSettlementDebrief"]:
			dialogs.append_array(get_nodes_in_group(group_name))
		if dialogs.is_empty() and not paused:
			return
		for dialog in dialogs:
			if dialog != null and is_instance_valid(dialog) and dialog.has_method("_finish"):
				dialog.call("_finish")
		await process_frame


func _world_guarantees() -> Dictionary:
	var clue_count := 0
	for clue in get_nodes_in_group("campaign_clue"):
		if String(clue.get("chapter_id")) == CampaignData.UNWRITTEN_ROAD \
				and String(clue.get("clue_id")).begins_with("lost_waymark_"):
			clue_count += 1
	var resource_counts := {"waysteel_shard": 0, "root_sap": 0}
	if current_scene != null:
		for node in current_scene.find_children("*", "GatherNode", true, false):
			var item_id := String(node.get("item_id"))
			if resource_counts.has(item_id):
				resource_counts[item_id] = int(resource_counts[item_id]) + 1
	return {"clues": clue_count, "resources": resource_counts}


func _buy_next_kit(game: Node) -> bool:
	return bool(game.buy_chart_component("nine_knot_leaf")) \
		and bool(game.buy_chart_component("lost_waymark_tracing")) \
		and bool(game.buy_chart_component("threefold_binding"))


func _test_abandon_spends_ordinary_components() -> void:
	var game = load("res://scripts/game.gd").new()
	_prepare_game(game, 1)
	game.known_chart_recipes = ["root_below"]
	game.materials.merge({"nine_knot_leaf": 1, "lost_waymark_tracing": 1,
		"threefold_binding": 1}, true)
	var before_state: Dictionary = game.campaign_state.duplicate(true)
	var before_xp := int(game.trades.wayfinding.xp)
	var committed := _inscribe(game, 221099)
	var chart: Dictionary = committed.get("chart", {})
	game.active_chart = game._freeze_campaign_clue(chart)
	game.in_dungeon = true
	game.return_to_town(null, true)
	_check("abandon grants no XP or Waymark and does not refund ordinary Chart stock",
		bool(committed.get("ok", false))
			and int(game.trades.wayfinding.xp) == before_xp
			and game.campaign_state == before_state
			and game.material_count("nine_knot_leaf") == 0
			and game.material_count("lost_waymark_tracing") == 0
			and game.material_count("threefold_binding") == 0
			and game.material_count("hedge_ink") == 0,
		{"commit": committed, "materials": game.materials})
	game.free()


func _run() -> void:
	print("--- Root Below playable loop ---")
	_test_abandon_spends_ordinary_components()
	var game: Node = root.get_node("Game")
	_prepare_game(game)

	var loom := LoomSourceScript.new()
	loom.name = "RootBelowIntegrationLoom"
	root.add_child(loom)
	await process_frame
	var source_status: Dictionary = loom.source_status()
	var source_read: Dictionary = loom.read_now()
	_check("the production Loom controller opens the canonical lesson and exact first kit",
		String(source_status.get("state", "")) == "eligible"
			and bool(source_read.get("changed", false))
			and String(source_read.get("recipe_granted", "")) == "root_below"
			and source_read.get("granted", {}) == {"nine_knot_leaf": 1,
				"lost_waymark_tracing": 1, "threefold_binding": 1}
			and game.gold == 0, {"status": source_status, "read": source_read})
	loom.queue_free()
	await process_frame

	var xp_rewards: Array = []
	var gold_rewards: Array = []
	var returned_charts: Array = []
	var every_world_guaranteed := true
	var world_failures: Array = []
	for index in RUN_SEEDS.size():
		var before_xp := int(game.trades.wayfinding.xp)
		var before_gold := int(game.gold)
		var committed := _inscribe(game, int(RUN_SEEDS[index]))
		var chart: Dictionary = committed.get("chart", {})
		if not bool(committed.get("ok", false)):
			every_world_guaranteed = false
			world_failures.append({"run": index + 1, "commit": committed})
			break
		returned_charts.append(chart.duplicate(true))
		game.enter_dungeon(chart, game.local_player())
		if not await _wait_for_scene("World"):
			every_world_guaranteed = false
			world_failures.append({"run": index + 1, "reason": "World did not load"})
			break
		var guarantees := _world_guarantees()
		var world_ok: bool = int(guarantees.clues) == 1 \
			and guarantees.resources == {"waysteel_shard": 1, "root_sap": 1}
		every_world_guaranteed = every_world_guaranteed and world_ok
		if not world_ok:
			world_failures.append({"run": index + 1, "guarantees": guarantees})
		game.return_to_town(game.local_player(), false)
		if not await _wait_for_scene("Town"):
			every_world_guaranteed = false
			world_failures.append({"run": index + 1, "reason": "Town did not load"})
			break
		await _close_town_debriefs()
		xp_rewards.append(int(game.trades.wayfinding.xp) - before_xp)
		gold_rewards.append(int(game.gold) - before_gold)
		if index < RUN_SEEDS.size() - 1 and not _buy_next_kit(game):
			every_world_guaranteed = false
			world_failures.append({"run": index + 1, "reason": "paid refill failed",
				"gold": game.gold, "materials": game.materials.duplicate(true)})
			break

	var road: Dictionary = game.campaign_state.chapters[CampaignData.UNWRITTEN_ROAD]
	var atlas_view: Dictionary = game.campaign_settlement_view().chapters.unwritten_road
	_check("five physical Charts cross the production Waystone with all World guarantees",
		every_world_guaranteed and returned_charts.size() == 5,
		world_failures)
	_check("five normal returns pay the exact authored XP and one unique Waymark each",
		xp_rewards == [75, 75, 75, 75, 76]
			and int(game.trades.wayfinding.xp) == Progression.xp_for_level(23)
			and int(game.trades.wayfinding.lv) == 23
			and int(road.clue_count) == 5
			and (road.banked_chart_ids as Array).size() == 5
			and game.campaign_state.lost_waymarks == CampaignData.UNWRITTEN_ROAD_CLUES,
		{"xp": xp_rewards, "trade": game.trades.wayfinding, "road": road})
	_check("zero starting gold funds four real 22g refills and leaves the locked 52g runway",
		gold_rewards == [28, 28, 28, 28, 28] and int(game.gold) == 52,
		{"rewards": gold_rewards, "gold": game.gold, "materials": game.materials})
	_check("the Atlas projection reaches 5/5 without creating a Map or sixth clue",
		int(atlas_view.clue_count) == 5 and int(atlas_view.clue_target) == 5
			and not bool(game.campaign_state.map_of_nine_knots)
			and CampaignData.next_clue_for_chart(game.campaign_state, "root_below",
				"root-return-six", 23).is_empty(), atlas_view)

	var first_chart: Dictionary = returned_charts[0] if not returned_charts.is_empty() else {}
	var replay: Dictionary = game._freeze_campaign_clue(first_chart)
	var campaign_before_replay: Dictionary = game.campaign_state.duplicate(true)
	var replay_transition: Dictionary = game._record_campaign_chart_return(replay)
	_check("a returned Chart identity cannot mint a sixth Waymark or replay authored XP",
		not replay.has("authored_completion_xp")
			and game._completion_xp_for_successful_return(replay)
				== ChartsData.legacy_completion_xp(replay)
			and not bool(replay_transition.get("changed", false))
			and game.campaign_state == campaign_before_replay,
		{"replay": replay, "transition": replay_transition})

	if current_scene != null:
		current_scene.queue_free()
	await process_frame
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("shutdown"):
		sfx.call("shutdown")
	Engine.time_scale = 1.0
	paused = false
	await create_timer(0.25, true, false, true).timeout
	print("--- Root Below playable: %d PASS, %d FAIL ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
