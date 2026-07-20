extends SceneTree

# Focused pure-data contract for Fire in the Bough. Runtime integration owns
# the Lift animation, chart source transaction, Giant controller, and Skill
# authority; this test locks the data those adapters must consume.

const CampaignData = preload("res://data/campaign.gd")
const ChartsData = preload("res://data/charts.gd")
const GatherData = preload("res://data/gather.gd")
const CraftingData = preload("res://data/crafting.gd")
const Progression = preload("res://data/progression.gd")
const DungeonGen = preload("res://scripts/dungeon_gen.gd")
const GatherNode = preload("res://scripts/gather_node.gd")

var _pass := 0
var _fail := 0

func _check(label: String, ok: bool, detail = "") -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
		print("  x %s %s" % [label, str(detail)])

func _fire_open() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id in [CampaignData.FIRST_KNOT, CampaignData.GOLDEN_WALLOW,
		CampaignData.SEVENTH_ROAD, CampaignData.QUEENS_SUMMIT, CampaignData.PALE_OATH]:
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
		var banked: Array = []
		for index in int(CampaignData.CHAPTERS[chapter_id].clue_target):
			banked.append("%s-%d" % [chapter_id, index])
		chapter.banked_chart_ids = banked
	state.relics = ["green_root_rune", "mist_root_rune", "fang_root_rune",
		"crown_root_rune", "pale_root_rune"]
	state.threads = ["past_thread"]
	state.restorations = ["trophy_hall", "sallow_jetty", "skald_archive",
		"pale_stair", "rootroad_lift"]
	return CampaignData.normalize_campaign_state(state)

func _fire_ready() -> Dictionary:
	var state := _fire_open()
	for index in 5:
		state = CampaignData.record_successful_chart_return(state, "ashen_bough",
			"ash-return-%d" % index, 20, {}).state
	return state

func _context(level: int, state: Dictionary, materials: Dictionary,
		known: Array) -> Dictionary:
	return {"level": level, "wildcraft_level": 20, "first_snug_returned": true,
		"campaign_state": state, "material_counts": materials,
		"known_recipe_ids": known}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- Fire in the Bough content ---")
	_test_v5_campaign_and_escrow()
	_test_table_grammars()
	_test_lift_sources_and_provenance()
	_test_renewable_support_and_progression()
	_test_manifest_is_frozen_and_domain_separate()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _test_v5_campaign_and_escrow() -> void:
	var migrated := CampaignData.normalize_campaign_state({"version": 4,
		"chapters": {CampaignData.PALE_OATH: {"clue_count": 4, "cleared": true,
			"banked_chart_ids": ["a", "b", "c", "d"]}}})
	var open := _fire_open()
	var first := CampaignData.record_successful_chart_return(open, "ashen_bough",
		"ash-a", 20, {})
	var duplicate := CampaignData.record_successful_chart_return(first.state, "ashen_bough",
		"ash-a", 23, {})
	var ready := _fire_ready()
	var begun := CampaignData.begin_boss_escrow(ready, "giant-chart", CampaignData.FIRE_IN_THE_BOUGH)
	var entered := CampaignData.mark_escrow_in_run(begun.state, begun.attempt_id,
		"giant-chart", CampaignData.FIRE_IN_THE_BOUGH)
	var settled := CampaignData.resolve_boss_death(entered.state, begun.attempt_id,
		"giant-chart", CampaignData.FIRE_IN_THE_BOUGH)
	_check("v6 preserves Fire and appends an inert Unwritten Road",
		int(migrated.version) == 6 and migrated.chapters.fire_in_the_bough == {
			"clue_count": 0, "cleared": false, "banked_chart_ids": []}
		and migrated.chapters.unwritten_road == {
			"clue_count": 0, "cleared": false, "banked_chart_ids": []})
	_check("five distinct Ashen returns bank exact Ember Verses",
		String(first.clue_id) == "ember_verse_1" and not bool(duplicate.changed)
			and CampaignData.chapter_clue_count(ready, CampaignData.FIRE_IN_THE_BOUGH) == 5
			and CampaignData.can_inscribe_boss(ready, "fire_in_the_bough_boss", 21))
	_check("Giant settlement consumes Coal and canonicalizes the forward-only Scale",
		bool(settled.ok) and settled.material_awards == {"wyrm_scale": 1}
			and settled.material_set == {"starheart_coal": 0}
			and settled.material_targets_exact == {"starheart_coal": 0, "wyrm_scale": 1}
			and settled.relic_awards == ["ember_root_rune"]
			and settled.thread_awards == ["present_thread"]
			and settled.restoration_awards == ["ember_kiln"]
			and not CampaignData.seal_use_allowed(settled.state, "wyrm_scale", "other"))

func _test_table_grammars() -> void:
	var ordinary_materials := {"ash_mark": 1, "cinder_waymark": 1, "ember_mark": 1,
		"cinder_binding": 2, "ember_folio": 1, "ash_ink": 1, "hedge_ink": 5}
	var ordinary := ChartsData.preview_table({"grid": {"nw": "ash_mark", "n": "cinder_waymark",
		"ne": "ember_mark", "w": "cinder_binding", "c": "ember_folio"},
		"ink_rail": ["ash_ink"]}, _context(20, _fire_open(), ordinary_materials, ["ashen_bough"]))
	var deeper := ChartsData.preview_table({"grid": {"nw": "ash_mark", "n": "cinder_waymark",
		"ne": "ember_mark", "w": "cinder_binding", "c": "ember_folio", "e": "cinder_binding"},
		"ink_rail": ["ash_ink"]}, _context(21, _fire_open(), ordinary_materials, ["ashen_bough"]))
	var boss_materials := {"furnace_mark": 1, "cinder_waymark": 1, "soot_track": 1,
		"cinder_binding": 2, "ember_folio": 1, "emberleaf_ink": 1,
		"hedge_ink": 5, "starheart_coal": 1}
	var boss := ChartsData.preview_table({"grid": {"nw": "furnace_mark", "n": "cinder_waymark",
		"ne": "soot_track", "w": "cinder_binding", "c": "ember_folio", "s": "starheart_coal"},
		"ink_rail": ["emberleaf_ink"]}, _context(21, _fire_ready(), boss_materials,
		["fire_in_the_bough_boss"]))
	var boss_with_e := ChartsData.preview_table({"grid": {"nw": "furnace_mark", "n": "cinder_waymark",
		"ne": "soot_track", "w": "cinder_binding", "c": "ember_folio", "e": "cinder_binding", "s": "starheart_coal"},
		"ink_rail": ["emberleaf_ink"]}, _context(21, _fire_ready(), boss_materials,
		["fire_in_the_bough_boss"]))
	_check("ordinary Ashen grammar has Ash rail, Hedge cost, Cinderbound, and only its E variant",
		bool(ordinary.commit_ready) and ordinary.reagent_cost == {"hedge_ink": 5, "ash_ink": 1}
			and ordinary.component_cost == {"ash_mark": 1, "cinder_waymark": 1, "ember_mark": 1,
				"cinder_binding": 1, "ember_folio": 1}
			and ordinary.affix_weights.keys() == ["cinderbound"]
			and bool(deeper.commit_ready) and deeper.depth_contract.variant_id == "ashen_bough.deepening_variant"
			and int(deeper.depth_contract.max_layers) == 2, {"ordinary": ordinary, "deeper": deeper})
	_check("sealed Giant grammar is exact, affixless, and cannot match Deepening II",
		bool(boss.commit_ready) and boss.reagent_cost == {"hedge_ink": 5, "emberleaf_ink": 1,
			"starheart_coal": 1} and boss.returned_on_failure == {"starheart_coal": 1}
			and String(boss.campaign_contract.boss_kind) == "hearth_giant"
			and (boss.affix_weights as Dictionary).is_empty() and boss_with_e.recipe_id != "fire_in_the_bough_boss")
	var ordinary_component_gold := 0
	for component_id_v in ordinary.component_cost:
		ordinary_component_gold += ChartsData.component_supply_price(String(component_id_v)) \
			* int(ordinary.component_cost[component_id_v])
	_check("Pale handoff funds the first Ashen layout and each Verse funds the next",
		ordinary_component_gold == 90
			and ChartsData.completion_gold({"recipe_id": "pale_veins", "tier": 3}) == 54
			and ChartsData.completion_gold({"recipe_id": "pale_oath_boss", "tier": 3}) == 46
			and ChartsData.completion_gold({"recipe_id": "ashen_bough", "tier": 3,
				"affixes": [{"id": "cinderbound", "good": false}]}) == ordinary_component_gold,
		{"component_gold": ordinary_component_gold,
			"pale_veins": ChartsData.CAMPAIGN_COMPLETION_GOLD.pale_veins,
			"pale_handoff": ChartsData.CAMPAIGN_COMPLETION_GOLD.pale_oath_boss,
			"ashen_return": ChartsData.CAMPAIGN_COMPLETION_GOLD.ashen_bough})

func _test_lift_sources_and_provenance() -> void:
	var ordinary_source: Dictionary = ChartsData.CHART_SOURCES.rootroad_lift_ashen_bough
	var boss_source: Dictionary = ChartsData.CHART_SOURCES.rootroad_lift_hearth_giant
	var journal := ChartsData.journal_with_discovery({}, "ashen_bough", "source_lesson", ["ashen_bough"])
	_check("Lift sources teach folios without supplies and use source provenance",
		bool(ordinary_source.grant_recipe_knowledge) and String(ordinary_source.discovery_provenance) == "source_lesson"
			and ordinary_source.lesson_components == {} and ordinary_source.lesson_inks == {}
			and boss_source.requires_chapter_clue_count == {"chapter_id": CampaignData.FIRE_IN_THE_BOUGH, "count": 5}
			and String((journal.discoveries as Dictionary).ashen_bough) == "source_lesson")

func _test_renewable_support_and_progression() -> void:
	var threadstep := Progression.FOCUS_SKILLS.Threadstep
	var pack_reader := Progression.information_feature_metadata("pack_reader")
	var ashen_layout := DungeonGen.generate(202120, {
		"scope": "ashen_bough", "biome_id": "ashen_bough",
		"required_biome_gather": ["embersage", "wellwater"],
	})
	var ashen_decor: Array = ashen_layout.get("decor", [])
	var embersage_node = GatherNode.new()
	embersage_node.setup("forage_node", "embersage")
	embersage_node.setup_herb_tier("embersage")
	_check("Emberleaf is the sole disclosed Wildcraft 20 supporting gate",
		GatherData.INK_RECIPES.emberleaf_ink.inputs == {"embersage": 2, "wellwater": 1, "ash_ink": 1}
			and int(GatherData.INK_RECIPES.emberleaf_ink.req_wildcraft) == 20
			and GatherData.MATERIALS.has("embersage")
			and String(GatherData.ROOTROAD_HERB_TIERS.embersage.item) == "embersage"
			and embersage_node.herb_tier == "embersage" and embersage_node.req_lv == 20
			and ashen_decor.filter(func(d): return String(d.get("item", "")) == "embersage").size() == 2
			and not (ChartsData.CHART_RECIPES.ashen_bough as Dictionary).has("req_wildcraft")
			and not (ChartsData.CHART_RECIPES.fire_in_the_bough_boss as Dictionary).has("req_wildcraft"))
	embersage_node.free()
	_check("Kiln crafts renewable Alloy and Huntcraft metadata declares Threadstep and Pack Reader",
		CraftingData.RECIPES.starheart_alloy.inputs == {"wildgold_bar": 2, "emberglass": 2}
			and String(CraftingData.RECIPES.starheart_alloy.requires_restoration) == "ember_kiln"
			and int(threadstep.focus_cost) == 20 and float(threadstep.cooldown_sec) == 8.0
			and bool(pack_reader.elite_manifest_readable) and not bool(pack_reader.mutates_rng))

func _test_manifest_is_frozen_and_domain_separate() -> void:
	var first := ChartsData.elite_manifest_for_chart(72021, "ashen_bough")
	var again := ChartsData.elite_manifest_for_chart(72021, "ashen_bough")
	var other := ChartsData.elite_manifest_for_chart(72022, "ashen_bough")
	var chart := ChartsData.materialize_chart(ChartsData.preview_table({"grid": {"nw": "ash_mark", "n": "cinder_waymark",
		"ne": "ember_mark", "w": "cinder_binding", "c": "ember_folio"}, "ink_rail": ["ash_ink"]},
		_context(20, _fire_open(), {"ash_mark": 1, "cinder_waymark": 1, "ember_mark": 1,
		"cinder_binding": 1, "ember_folio": 1, "ash_ink": 1, "hedge_ink": 5}, ["ashen_bough"])), 72021)
	_check("ordinary Ashen Charts materialize one deterministic, zero-RNG Pack Reader manifest",
		first == again and bool(first.eligible) and String(first.slot_id) == "ashen_first_eligible"
			and String(other.seed_fingerprint) != String(first.seed_fingerprint)
			and (chart.get("elite_manifest", {}) as Dictionary) == first
			and not bool(ChartsData.elite_manifest_for_chart(72021, "pale_veins").eligible))
