extends SceneTree

# Focused Slice 1 data and source-transaction contract. Runtime World/UI
# slices consume these records; this test keeps their canonical inputs frozen.

const CampaignData = preload("res://data/campaign.gd")
const ChartsData = preload("res://data/charts.gd")
const GatherData = preload("res://data/gather.gd")
const Progression = preload("res://data/progression.gd")

var _pass := 0
var _fail := 0

func _check(label: String, ok: bool, detail = "") -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
		print("  x %s %s" % [label, str(detail)])

func _fire_cleared() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id in CampaignData.CHAPTER_ORDER:
		var chapter: Dictionary = state.chapters[chapter_id]
		if chapter_id == CampaignData.UNWRITTEN_ROAD:
			break
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
		chapter.banked_chart_ids = ["%s-%d" % [chapter_id, chapter.clue_count]]
	return CampaignData.normalize_campaign_state(state)

func _source_context(state: Dictionary, materials: Dictionary) -> Dictionary:
	return {"level": 22, "wildcraft_level": 1, "first_snug_returned": true,
		"campaign_state": state, "material_counts": materials,
		"known_recipe_ids": ["root_below"]}

func _init() -> void:
	print("--- Root Below content ---")
	_test_source_contract()
	_test_renewable_table_and_gather_contract()
	_test_affix_and_xp_contract()
	_test_waymark_records()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _test_source_contract() -> void:
	var source: Dictionary = ChartsData.CHART_SOURCES.threefold_loom_root_below
	var loose := CampaignData.empty_state()
	var loose_preview := ChartsData.preview_table({"grid": {"n": "lost_waymark_tracing",
		"c": "nine_knot_leaf", "w": "threefold_binding"}, "ink_rail": ["hedge_ink"]},
		_source_context(loose, {"nine_knot_leaf": 99, "lost_waymark_tracing": 99,
			"threefold_binding": 99, "hedge_ink": 99}))
	var canonical := _fire_cleared()
	var game = load("res://scripts/game.gd").new()
	game.persistence_enabled = false
	game.campaign_state = canonical
	game.chart_source_unlocks = ["threefold_loom_root_below"]
	game.trades.wayfinding = {"xp": Progression.xp_for_level(22), "lv": 22}
	game.materials = {"lost_waymark_tracing": 1}
	var first_read: Dictionary = game.read_chart_source("threefold_loom_root_below")
	var reread: Dictionary = game.read_chart_source("threefold_loom_root_below")
	_check("Loom source is canonically Fire-clear gated and teaches recipe knowledge",
		String(CampaignData.CHAPTERS.unwritten_road.clue_source_id) == "threefold_loom_root_below"
			and int(source.min_wayfinding) == 22
			and String(source.requires_chapter_clear) == CampaignData.FIRE_IN_THE_BOUGH
			and bool(source.grant_recipe_knowledge)
			and String(source.discovery_provenance) == "source_lesson")
	_check("loose supplies or a source-shaped draft cannot infer Root Below entitlement",
		String(loose_preview.get("recipe_id", "")) != "root_below"
			and not CampaignData.chapter_cleared(loose, CampaignData.FIRE_IN_THE_BOUGH), loose_preview)
	_check("first lesson kit is missing-only and carries no Chart, gold, Ink, or story award",
		String(source.lesson_grant_policy) == "missing_only"
			and source.lesson_components == {"nine_knot_leaf": 1,
				"lost_waymark_tracing": 1, "threefold_binding": 1}
			and source.lesson_inks == {} and not source.has("chart_awards")
			and not source.has("gold_awards") and not source.has("story_awards")
			and CampaignData.chapter_cleared(canonical, CampaignData.FIRE_IN_THE_BOUGH))
	_check("the host resolves the source exactly once; guests remain read-only",
		bool(first_read.changed) and first_read.granted == {"nine_knot_leaf": 1,
			"threefold_binding": 1} and String(first_read.recipe_granted) == "root_below"
			and not bool(reread.changed) and reread.granted == {}
			and game.materials == {"lost_waymark_tracing": 1, "nine_knot_leaf": 1,
				"threefold_binding": 1}
			and game.campaign_settlement_allowed(true, true)
			and not game.campaign_settlement_allowed(true, false), {"first": first_read, "reread": reread})
	game.free()

func _test_renewable_table_and_gather_contract() -> void:
	var root: Dictionary = ChartsData.TEMPLATES.root_below
	_check("Root Below provides renewable table stock at the locked prices",
		ChartsData.component_supply_price("nine_knot_leaf") == 10
			and ChartsData.component_supply_price("lost_waymark_tracing") == 5
			and ChartsData.component_supply_price("threefold_binding") == 7)
	_check("Root Below guarantees Waysteel and Root Sap at Trade 22",
		root.gen.required_biome_gather == ["waysteel", "root_sap"]
			and String(GatherData.ROOTROAD_ORE_TIERS.waysteel.item) == "waysteel_shard"
			and int(GatherData.ROOTROAD_ORE_TIERS.waysteel.req_lv) == 22
			and String(GatherData.ROOTROAD_HERB_TIERS.root_sap.item) == "root_sap"
			and int(GatherData.ROOTROAD_HERB_TIERS.root_sap.req_lv) == 22
			and GatherData.MATERIALS.has("waysteel_shard") and GatherData.MATERIALS.has("root_sap"))

func _test_affix_and_xp_contract() -> void:
	var affix: Dictionary = ChartsData.AFFIXES.open_thread
	var good := ChartsData.affix_presentation({"scope": "rootroads"}, {"id": "open_thread", "good": true})
	var bad := ChartsData.affix_presentation({"scope": "rootroads"}, {"id": "open_thread", "good": false})
	_check("Open Thread is Root Below's only Mythic twin and only changes speed",
		ChartsData.TEMPLATES.root_below.affix_pool == ["open_thread"]
			and String(good.name) == "Open Thread" and String(bad.name) == "Snagged Thread"
			and affix.effect == {"player_speed_mult_good": 1.08,
				"player_speed_mult_bad": 0.92, "mutates_campaign": false,
				"mutates_gather": false, "mutates_boss": false})
	_check("Root Below authored XP stays exact regardless of the speed twin",
		ChartsData.CAMPAIGN_COMPLETION_XP.root_below == [75, 75, 75, 75, 76]
			and ChartsData.completion_xp({"authored_completion_xp": 75,
				"affixes": [{"id": "open_thread", "good": true}]}) == 75
			and Progression.xp_for_level(23) == 4576)

func _test_waymark_records() -> void:
	var records: Dictionary = ChartsData.UNWRITTEN_LOST_WAYMARK_PRESENTATIONS
	var ids: Array = CampaignData.UNWRITTEN_ROAD_CLUES
	var all_authored := ids.all(func(id):
		var record: Dictionary = records.get(id, {})
		return String(record.get("presentation", "")) == "lost_waymark" \
			and not (record.get("pages", []) as Array).is_empty())
	_check("five authored Lost Waymark presentations cover every ledger id exactly once",
		records.keys().size() == 5 and records.keys().all(func(id): return ids.has(id))
			and all_authored, records)
	var source_view: Dictionary = CampaignData.settlement_view(_fire_cleared()).chapters.unwritten_road
	_check("the Atlas source projection is Fire-clear-only and remains 0/5 before returns",
		bool(source_view.source_visible) and not bool(source_view.visible)
			and int(source_view.clue_count) == 0 and int(source_view.clue_target) == 5,
		source_view)
