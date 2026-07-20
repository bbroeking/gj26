extends SceneTree

# D8 Slice 4 Game authority gate.  Campaign owns the pure Map policy; this
# focuses on the one live transaction that must couple its accepted record to
# the final Codex knowledge without accidentally paying any ordinary reward.

const CampaignData = preload("res://data/campaign.gd")
const ChartsData = preload("res://data/charts.gd")
const Progression = preload("res://data/progression.gd")

class RitualCountingGame:
	extends "res://scripts/game.gd"
	var save_calls := 0
	var publish_calls := 0
	var notify_calls := 0

	func save_now() -> bool:
		save_calls += 1
		return true

	func _publish_campaign_settlement_view() -> void:
		publish_calls += 1

	func notify(_message: String) -> void:
		notify_calls += 1


var _pass := 0
var _fail := 0
var _story_signals := 0
var _knowledge_signals := 0


func _check(label: String, ok: bool, detail = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % label)
	else:
		_fail += 1
		print("  ✗ %s %s" % [label, str(detail)])


func _init() -> void:
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
			chapter.banked_chart_ids.append("%s-%d" % [chapter_id, index + 1])
	state.relics = CampaignData.ROOT_RUNE_IDS.duplicate()
	state.threads = ["past_thread", "present_thread"]
	state.restorations = ["trophy_hall", "sallow_jetty", "skald_archive",
		"pale_stair", "rootroad_lift", "ember_kiln"]
	return CampaignData.normalize_campaign_state(state)


func _map_ready_state() -> Dictionary:
	var state := _fire_settled()
	for index in 5:
		state = CampaignData.record_successful_chart_return(state, "root_below",
			"loom-map-%d" % (index + 1), 23, {}).state
	return state


func _prepare(game: Node, mapped: bool = false) -> void:
	game.campaign_state = _map_ready_state()
	if mapped:
		game.campaign_state = CampaignData.record_map_of_nine_knots(
			game.campaign_state, 23).state
	game.trades = Progression.fresh_trade_state()
	game.trades.wayfinding = {"xp": Progression.xp_for_level(23), "lv": 23}
	game.materials = {"hedge_ink": 7, "wyrm_scale": 1}
	game.gold = 44
	game.charts = [{"chart_instance_id": "untouched"}]
	game.inventory = Inventory.new()
	game.inventory.items = [{"kind_id": "warbow", "rarity": "rare"}]
	game.chart_source_unlocks = ["threefold_loom_root_below"]
	game.known_chart_recipes = ["root_below"]
	game.chart_recipe_journal = ChartsData.journal_with_rumour(
		ChartsData.fresh_recipe_journal(), "threefold_loom_root_below",
		game.known_chart_recipes)
	game.chart_recipe_journal = ChartsData.journal_with_discovery(
		game.chart_recipe_journal, "root_below", "source_lesson",
		game.known_chart_recipes)
	game._chart_table_revision = 19


func _on_story_changed() -> void:
	_story_signals += 1


func _on_knowledge_changed() -> void:
	_knowledge_signals += 1


func _connect_counts(game: Node) -> void:
	_story_signals = 0
	_knowledge_signals = 0
	game.story_changed.connect(_on_story_changed)
	game.chart_knowledge_changed.connect(_on_knowledge_changed)


func _disconnect_counts(game: Node) -> void:
	if game.story_changed.is_connected(_on_story_changed):
		game.story_changed.disconnect(_on_story_changed)
	if game.chart_knowledge_changed.is_connected(_on_knowledge_changed):
		game.chart_knowledge_changed.disconnect(_on_knowledge_changed)


func _run() -> void:
	print("--- Threefold Loom Game transaction ---")
	_test_fresh_record_and_complete_repeat()
	_test_trusted_map_knowledge_repair()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


func _test_fresh_record_and_complete_repeat() -> void:
	var game := RitualCountingGame.new()
	_prepare(game)
	_connect_counts(game)
	var before_materials: Dictionary = game.materials.duplicate(true)
	var before_gold := int(game.gold)
	var before_charts: Array = game.charts.duplicate(true)
	var before_threads: Array = game.campaign_state.threads.duplicate()
	var before_waymarks: Array = game.campaign_state.lost_waymarks.duplicate()
	var before_runes: Array = game.campaign_state.relics.duplicate()
	var before_trades: Dictionary = game.trades.duplicate(true)
	var before_items: Array = game.inventory.items.duplicate(true)
	var view_before: Dictionary = game.threefold_loom_view()
	var first: Dictionary = game.trace_threefold_loom_map()
	var discoveries: Dictionary = game.chart_recipe_journal.discoveries
	var settlement: Dictionary = game.campaign_settlement_view()
	_check("fresh ritual atomically records the Map and final source lesson",
		String(view_before.get("phase", "")) == "ritual_ready"
			and bool(view_before.get("can_trace", false))
			and bool(first.get("ok", false)) and bool(first.get("changed", false))
			and bool(first.get("map_awarded", false))
			and bool(first.get("knowledge_repaired", false))
			and bool(game.campaign_state.map_of_nine_knots)
			and game.known_chart_recipes.has(CampaignData.UNWRITTEN_ROAD_BOSS_RECIPE)
			and (game.chart_recipe_journal.rumours as Array).has(
				CampaignData.UNWRITTEN_ROAD_RUMOUR)
			and String(discoveries.get(CampaignData.UNWRITTEN_ROAD_BOSS_RECIPE, ""))
				== "source_lesson"
			and (settlement.get("threefold_loom", {}) as Dictionary).get("phase", "")
				== "map_recorded", {"result": first, "settlement": settlement})
	_check("Map ritual never changes ordinary inventory, economy, Threads, or Waymarks",
		game.materials == before_materials and int(game.gold) == before_gold
			and game.charts == before_charts and game.campaign_state.threads == before_threads
			and game.campaign_state.lost_waymarks == before_waymarks
			and game.campaign_state.relics == before_runes and game.trades == before_trades
			and game.inventory.items == before_items,
		{"materials": game.materials, "gold": game.gold,
			"threads": game.campaign_state.threads, "waymarks": game.campaign_state.lost_waymarks,
			"runes": game.campaign_state.relics, "trades": game.trades,
			"items": game.inventory.items})
	_check("fresh ritual has one revision, conditional signals, save, toast, and publish",
		int(game._chart_table_revision) == 20 and _story_signals == 1
			and _knowledge_signals == 1 and game.save_calls == 1
			and game.publish_calls == 1 and game.notify_calls == 1,
		{"revision": game._chart_table_revision, "story": _story_signals,
			"knowledge": _knowledge_signals, "save": game.save_calls,
			"publish": game.publish_calls, "notify": game.notify_calls})
	var repeat: Dictionary = game.trace_threefold_loom_map()
	_check("complete Map repeat is a true no-op",
		bool(repeat.get("ok", false)) and not bool(repeat.get("changed", true))
			and int(game._chart_table_revision) == 20 and _story_signals == 1
			and _knowledge_signals == 1 and game.save_calls == 1
			and game.publish_calls == 1 and game.notify_calls == 1, repeat)
	_disconnect_counts(game)
	game.free()


func _test_trusted_map_knowledge_repair() -> void:
	var game := RitualCountingGame.new()
	_prepare(game, true)
	_connect_counts(game)
	var before_campaign: Dictionary = game.campaign_state.duplicate(true)
	var before_materials: Dictionary = game.materials.duplicate(true)
	var view_before: Dictionary = game.threefold_loom_view()
	var repaired: Dictionary = game.trace_threefold_loom_map()
	_check("trusted v6 Map exposes only the narrow knowledge repair CTA",
		String(view_before.get("phase", "")) == "map_recorded"
			and bool(view_before.get("map_recorded", false))
			and not bool(view_before.get("knowledge_complete", true))
			and bool(view_before.get("can_repair_knowledge", false))
			and not bool(view_before.get("can_trace", true)), view_before)
	_check("Map repair preserves Campaign while converging the complete final Codex record",
		bool(repaired.get("ok", false)) and bool(repaired.get("changed", false))
			and not bool(repaired.get("map_awarded", true))
			and bool(repaired.get("knowledge_repaired", false))
			and game.campaign_state == before_campaign and game.materials == before_materials
			and game.known_chart_recipes.has(CampaignData.UNWRITTEN_ROAD_BOSS_RECIPE)
			and String((game.chart_recipe_journal.discoveries as Dictionary).get(
				CampaignData.UNWRITTEN_ROAD_BOSS_RECIPE, "")) == "source_lesson", repaired)
	_check("knowledge-only repair signals only Codex and still owns one boundary",
		int(game._chart_table_revision) == 20 and _story_signals == 0
			and _knowledge_signals == 1 and game.save_calls == 1
			and game.publish_calls == 1 and game.notify_calls == 1,
		{"revision": game._chart_table_revision, "story": _story_signals,
			"knowledge": _knowledge_signals, "save": game.save_calls,
			"publish": game.publish_calls, "notify": game.notify_calls})
	_disconnect_counts(game)
	game.free()
