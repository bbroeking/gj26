extends SceneTree

# Focused content contract for the level-18/19 Pale Oath foundations. Runtime
# escrow/settlement, boss behavior, and Archive presentation are intentionally
# owned by their integration suites; this locks the pure authored data seam.

const ChartsData = preload("res://data/charts.gd")
const GatherData = preload("res://data/gather.gd")
const CraftingData = preload("res://data/crafting.gd")
const Progression = preload("res://data/progression.gd")
const CampaignData = preload("res://data/campaign.gd")
const DungeonGen = preload("res://scripts/dungeon_gen.gd")

var _passed := 0
var _failed := 0


func _check(label: String, condition: bool, detail = "") -> void:
	if condition:
		_passed += 1
		print("  ✓ %s" % label)
	else:
		_failed += 1
		print("  ✗ %s %s" % [label, str(detail)])


func _oath_ready() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id in [CampaignData.FIRST_KNOT, CampaignData.GOLDEN_WALLOW,
			CampaignData.SEVENTH_ROAD, CampaignData.QUEENS_SUMMIT]:
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
		var banked: Array = []
		for i in range(int(CampaignData.CHAPTERS[chapter_id].clue_target)):
			banked.append("%s-%d" % [chapter_id, i])
		chapter.banked_chart_ids = banked
	var oath: Dictionary = state.chapters[CampaignData.PALE_OATH]
	oath.clue_count = int(CampaignData.CHAPTERS[CampaignData.PALE_OATH].clue_target)
	var oath_banked: Array = []
	for i in range(int(CampaignData.CHAPTERS[CampaignData.PALE_OATH].clue_target)):
		oath_banked.append("oath-%d" % i)
	oath.banked_chart_ids = oath_banked
	return CampaignData.normalize_campaign_state(state)


func _context(level: int, state: Dictionary, materials: Dictionary) -> Dictionary:
	return {"level": level, "wildcraft_level": 1, "first_snug_returned": true,
		"campaign_state": state, "material_counts": materials,
		"known_recipe_ids": ["pale_veins", "pale_oath_boss"]}


func _init() -> void:
	print("--- Pale Oath content ---")
	_test_chart_grammars()
	_test_archive_sources_and_ledger_boundary()
	_test_trade_data_and_information_boundary()
	_test_rootroads_generation_metadata()
	_test_icons()
	print("--- %d passed, %d failed ---" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_chart_grammars() -> void:
	var veins_template: Dictionary = ChartsData.TEMPLATES.pale_veins
	var boss_template: Dictionary = ChartsData.TEMPLATES.pale_oath_boss
	_check("rootroad templates have the authored Hedge Ink and Affix limits",
		String(veins_template.scope) == "rootroads"
			and veins_template.base_cost == {"hedge_ink": 5}
			and int(veins_template.affix_slots) == 1
			and String(boss_template.scope) == "rootroads"
			and boss_template.base_cost == {"hedge_ink": 5}
			and int(boss_template.affix_slots) == 0, {"veins": veins_template, "boss": boss_template})
	var veins_draft := {"grid": {"n": "pale_wellmark", "c": "atlas_folio",
		"w": "climbing_cord", "e": "climbing_cord"}, "ink_rail": ["stoneground_ink"]}
	var veins_materials := {"pale_wellmark": 1, "atlas_folio": 1,
		"climbing_cord": 2, "stoneground_ink": 1, "hedge_ink": 5}
	var veins := ChartsData.preview_table(veins_draft,
		_context(18, _oath_ready(), veins_materials))
	_check("Pale Veins exact grid takes one Stoneground rail and five Hedge Ink",
		bool(veins.commit_ready) and String(veins.recipe_id) == "pale_veins"
			and veins.reagent_cost == {"hedge_ink": 5, "stoneground_ink": 1}
			and veins.component_cost == {"pale_wellmark": 1, "atlas_folio": 1,
				"climbing_cord": 2} and (veins.bias_inks as Array).is_empty()
			and (veins.campaign_contract as Dictionary).is_empty(), veins)
	var forged_veins := ChartsData.preview_table(veins_draft,
		_context(18, CampaignData.empty_state(), veins_materials))
	_check("forged recipe knowledge cannot bypass the canonical Queen-clear prerequisite",
		not bool(forged_veins.commit_ready) and String(forged_veins.reason).contains("previous chapter"),
		forged_veins)
	var boss_draft := {"grid": {"nw": "barrow_mark", "n": "pale_wellmark",
		"ne": "cold_track", "c": "atlas_folio", "w": "climbing_cord",
		"e": "climbing_cord", "s": "oath_nail"}, "ink_rail": ["stoneground_ink"]}
	var boss_materials := {"barrow_mark": 1, "pale_wellmark": 1, "cold_track": 1,
		"atlas_folio": 1, "climbing_cord": 2, "stoneground_ink": 1,
		"hedge_ink": 5, "oath_nail": 1}
	var boss := ChartsData.preview_table(boss_draft,
		_context(19, _oath_ready(), boss_materials))
	_check("Pale Oath exact grid protects only the Nail and forces the Jarl contract",
		bool(boss.commit_ready) and String(boss.recipe_id) == "pale_oath_boss"
			and boss.reagent_cost == {"hedge_ink": 5, "stoneground_ink": 1,
				"oath_nail": 1}
			and int(boss.output.affix_slots) == 0
			and boss.returned_on_failure == {"oath_nail": 1}
			and String((boss.campaign_contract as Dictionary).boss_kind) == "barrow_jarl", boss)
	var queen_only := _oath_ready()
	var incomplete_oath: Dictionary = queen_only.chapters[CampaignData.PALE_OATH]
	incomplete_oath.clue_count = 0
	incomplete_oath.banked_chart_ids = []
	var forged_boss := ChartsData.preview_table(boss_draft,
		_context(19, CampaignData.normalize_campaign_state(queen_only), boss_materials))
	_check("boss folio cannot bypass four canonical Oath-Rubbings through known-recipe save data",
		not bool(forged_boss.commit_ready) and String(forged_boss.reason).contains("authored signs"),
		forged_boss)


func _test_archive_sources_and_ledger_boundary() -> void:
	var source: Dictionary = ChartsData.CHART_SOURCES.skald_pale_oath
	var boss_source: Dictionary = ChartsData.CHART_SOURCES.skald_pale_oath_boss
	_check("Pale Archive source is canonical-Queen-gated and tops up one complete veins attempt",
		String(source.requires_chapter_clear) == CampaignData.QUEENS_SUMMIT
			and String(source.lesson_grant_policy) == "missing_only"
			and source.lesson_components == {"pale_wellmark": 1, "atlas_folio": 1,
				"climbing_cord": 2}
			and source.lesson_inks == {"stoneground_ink": 1}, source)
	_check("boss folio waits for four ledger rubbings and cannot mint an Oath Nail",
		String(boss_source.requires_chapter_clear) == CampaignData.QUEENS_SUMMIT
			and boss_source.requires_chapter_clue_count == {"chapter_id": CampaignData.PALE_OATH,
				"count": 4} and String(boss_source.lesson_grant_policy) == "missing_only"
			and not (boss_source.lesson_components as Dictionary).has("oath_nail"), boss_source)
	_check("Oath-Rubbings remain campaign ledger facts, never components or materials",
		CampaignData.PALE_OATH_CLUES == ["oath_rubbing_1", "oath_rubbing_2",
			"oath_rubbing_3", "oath_rubbing_4"]
			and not ChartsData.COMPONENTS.has("oath_rubbing")
			and not GatherData.MATERIALS.has("oath_rubbing_1"))
	_check("Pale Wellmark is renewable while the Oath Nail remains a protected Seal",
		ChartsData.component_supply_price("pale_wellmark") > 0
			and ChartsData.is_chart_seal("oath_nail")
			and ChartsData.is_protected_chart_supply("oath_nail"))


func _test_trade_data_and_information_boundary() -> void:
	_check("Wildgold and well gather tiers open at the authored Trade levels",
		int(GatherData.ROOTROAD_ORE_TIERS.wildgold.req_lv) == 18
			and not bool(GatherData.ROOTROAD_ORE_TIERS.wildgold.get("starter_requires_tool", true))
			and int(GatherData.ROOTROAD_HERB_TIERS.wellmoss.req_lv) == 18
			and int(GatherData.ROOTROAD_HERB_TIERS.wellwater.req_lv) == 19)
	_check("level-18/19 support recipes exist without a Chart campaign gate",
		int(CraftingData.RECIPES.wellmoss_salve.req_lv) == 18
			and int(CraftingData.RECIPES.wellwater_philter.req_lv) == 19
			and int(CraftingData.RECIPES.wildgold_bar.req_lv) == 19
			and CraftingData.ROOTROAD_STILL_RECIPES == ["wellmoss_salve", "wellwater_philter"]
			and not (ChartsData.CHART_RECIPES.pale_veins as Dictionary).has("req_earthcraft")
			and not (ChartsData.CHART_RECIPES.pale_oath_boss as Dictionary).has("req_wildcraft"))
	var trophy_sense := Progression.information_feature_metadata("trophy_sense")
	_check("Trophy Sense is deterministic presentation metadata only",
		int(trophy_sense.level) == 19 and bool(trophy_sense.elite_modifier_readable)
			and bool(trophy_sense.target_plate_reward_tier_floor)
			and bool(trophy_sense.seeded_ordinary_trophy_sigil)
			and not bool(trophy_sense.mutates_rng) and not bool(trophy_sense.mutates_drops)
			and not bool(trophy_sense.mutates_campaign_clues)
			and not bool(trophy_sense.mutates_boss_access), trophy_sense)


func _test_rootroads_generation_metadata() -> void:
	var generated := DungeonGen.generate(18019, {"scope": "rootroads", "tier": 3,
		"required_biome_gather": ["wildgold", "wellwater"]})
	var kinds := {}
	for decor_v in generated.decor:
		var decor: Dictionary = decor_v
		kinds[String(decor.get("item", ""))] = true
	_check("rootroads generation includes deterministic Wildgold, Wellmoss, and Pale Wellwater",
		kinds.has("wildgold_ore") and kinds.has("wellmoss") and kinds.has("wellwater"), kinds)
	var stonewake: Dictionary = ChartsData.AFFIXES.stonewake
	_check("Stonewake twins are rootroad encounter data without reward or clue mutation",
		String(stonewake.scope) == "rootroads" and float(stonewake.telegraph_sec) >= 1.0
			and bool((stonewake.effect as Dictionary).enemy_knockback)
			and bool((stonewake.effect as Dictionary).player_safe_when_good)
			and bool((stonewake.effect as Dictionary).player_damage_and_displace_when_bad), stonewake)


func _test_icons() -> void:
	var icon_paths := [
		"res://assets/ui/components/pale_wellmark.png",
		"res://assets/ui/components/barrow_mark.png",
		"res://assets/ui/items/oath_nail.png", "res://assets/ui/items/wildgold_ore.png",
		"res://assets/ui/items/wildgold_bar.png", "res://assets/ui/items/wellmoss.png",
		"res://assets/ui/items/wellmoss_salve.png", "res://assets/ui/items/wellwater.png",
		"res://assets/ui/items/wellwater_philter.png",
		"res://assets/ui/affixes/stonewake.png", "res://assets/ui/icons/trophy_sense.png",
		"res://assets/ui/items/starheart_coal.png",
		"res://assets/ui/items/pale_root_rune.png",
		"res://assets/ui/items/past_thread.png",
		"res://assets/ui/icons/skill_driving_volley.png",
	]
	var complete := true
	for path in icon_paths:
		complete = complete and ResourceLoader.exists(path) and FileAccess.file_exists(path + ".import")
	_check("new components, materials, Affix, and Trade metadata use imported PNG art", complete,
		icon_paths)
	_check("Pale settlement awards and Driving Volley bind distinct production icons",
		GatherData.material_icon_path("starheart_coal") ==
			"res://assets/ui/items/starheart_coal.png"
		and CampaignData.story_icon_path("pale_root_rune") ==
			"res://assets/ui/items/pale_root_rune.png"
		and CampaignData.story_icon_path("past_thread") ==
			"res://assets/ui/items/past_thread.png",
		{"material": GatherData.material_icon_path("starheart_coal"),
			"rune": CampaignData.story_icon_path("pale_root_rune"),
			"thread": CampaignData.story_icon_path("past_thread")})
