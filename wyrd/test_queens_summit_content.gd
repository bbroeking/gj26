extends SceneTree

# Focused authored-content contract for the Queen's Summit. Campaign escrow,
# runtime settlement, and presentation adapters have their own acceptance
# suites; this locks the two Table roads, cost grammar, Skald reroute, clue
# copy, and frozen legacy resolver boundary.

const ChartsData = preload("res://data/charts.gd")
const CampaignData = preload("res://data/campaign.gd")

var _passed := 0
var _failed := 0


func _check(label: String, condition: bool, detail = "") -> void:
	if condition:
		_passed += 1
		print("  ✓ %s" % label)
	else:
		_failed += 1
		print("  ✗ %s %s" % [label, str(detail)])


func _seventh_cleared() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id in [CampaignData.FIRST_KNOT, CampaignData.GOLDEN_WALLOW,
			CampaignData.SEVENTH_ROAD]:
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
		var banked: Array = []
		for index in range(int(CampaignData.CHAPTERS[chapter_id].clue_target)):
			banked.append("%s-%d" % [chapter_id, index])
		chapter.banked_chart_ids = banked
	return CampaignData.normalize_campaign_state(state)


func _queen_ready() -> Dictionary:
	var state := _seventh_cleared()
	var chapter: Dictionary = state.chapters[CampaignData.QUEENS_SUMMIT]
	chapter.clue_count = int(CampaignData.CHAPTERS[CampaignData.QUEENS_SUMMIT].clue_target)
	var banked: Array = []
	for index in range(int(CampaignData.CHAPTERS[CampaignData.QUEENS_SUMMIT].clue_target)):
		banked.append("crown-%d" % index)
	chapter.banked_chart_ids = banked
	return CampaignData.normalize_campaign_state(state)


func _context(level: int, campaign_state: Dictionary) -> Dictionary:
	return {
		"level": level,
		"wildcraft_level": 23,
		"first_snug_returned": true,
		"campaign_state": campaign_state,
		"known_recipe_ids": ["summit_approach", "queens_summit_boss"],
	}


func _init() -> void:
	print("--- Queen's Summit content ---")
	_test_distinct_templates_and_table_roads()
	_test_skald_reroute_and_crown_thorn_copy()
	_test_retired_handoff_boundary()
	print("--- %d passed, %d failed ---" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_distinct_templates_and_table_roads() -> void:
	var approach_template: Dictionary = ChartsData.TEMPLATES.summit_approach
	var queen_template: Dictionary = ChartsData.TEMPLATES.summit_queen
	_check("two new Summit templates are boss-free and pay four Hedge Ink",
		int(approach_template.tier) == 3 and int(queen_template.tier) == 3
			and String(approach_template.scope) == "summit"
			and String(queen_template.scope) == "summit"
			and approach_template.base_cost == {"hedge_ink": 4}
			and queen_template.base_cost == {"hedge_ink": 4}
			and not (approach_template.gen as Dictionary).has("boss_kind")
			and not (queen_template.gen as Dictionary).has("boss_kind"),
		{"approach": approach_template, "queen": queen_template})
	var approach_draft := {"grid": {
		"nw": "cold_track", "n": "cold_track", "c": "atlas_folio",
		"w": "climbing_cord", "e": "climbing_cord",
	}, "ink_rail": ["refined_ink"]}
	var approach := ChartsData.preview_table(approach_draft,
		_context(16, _seventh_cleared()))
	_check("Crownward Ascent has the exact no-Seal road and one visible Refined Ink",
		bool(approach.commit_ready) and String(approach.recipe_id) == "summit_approach"
			and String(approach.output.template_id) == "summit_approach"
			and approach.required_inks == ["refined_ink"]
			and approach.reagent_cost == {"hedge_ink": 4, "refined_ink": 1}
			and (approach.campaign_contract as Dictionary).is_empty()
			and not (approach.guaranteed as Array).any(func(item):
				return String((item as Dictionary).get("type", "")) == "boss"), approach)
	var queen_draft := {"grid": {
		"nw": "cold_track", "n": "thorn_rubbing", "c": "atlas_folio",
		"w": "climbing_cord", "e": "climbing_cord", "s": "alpha_fang",
	}, "ink_rail": ["refined_ink"]}
	var queen := ChartsData.preview_table(queen_draft, _context(17, _queen_ready()))
	_check("Queen road has its own north Thorn, Alpha Seal, exact one-ink cost, and forced contract",
		bool(queen.commit_ready) and String(queen.recipe_id) == "queens_summit_boss"
			and String(queen.output.template_id) == "summit_queen"
			and queen.required_inks == ["refined_ink"]
			and queen.reagent_cost == {"hedge_ink": 4, "refined_ink": 1, "alpha_fang": 1}
			and int(queen.costs.refined_ink) == 1
			and not (queen.ordinary_costs as Dictionary).has("alpha_fang")
			and queen.returned_on_failure == {"alpha_fang": 1}
			and String((queen.campaign_contract as Dictionary).boss_kind) == "hedgemother_queen",
		queen)
	_check("Oath Nail is registered as the protected next Story Seal",
		ChartsData.is_chart_seal("oath_nail") and ChartsData.is_protected_chart_supply("oath_nail")
			and String(ChartsData.STORY_SEALS.oath_nail.name) == "Oath Nail"
			and int(ChartsData.STORY_SEALS.oath_nail.req_wayfinding) == 19)


func _test_skald_reroute_and_crown_thorn_copy() -> void:
	var source: Dictionary = ChartsData.CHART_SOURCES.skald_queens_summit
	_check("Skald Archive now teaches only the boss-free Crownward approach",
		String(source.recipe_id) == "summit_approach"
			and String(source.rumour_id) == "skald_crownward_ascent"
			and int(source.min_wayfinding) == 16
			and source.lesson_components == {
				"atlas_folio": 1, "cold_track": 2, "climbing_cord": 2,
			}, source)
	var expected := ["shed_crown_thorn_1", "shed_crown_thorn_2",
		"shed_crown_thorn_3", "shed_crown_thorn_4"]
	var presentations: Dictionary = ChartsData.QUEENS_SUMMIT_SHED_CROWN_THORN_PRESENTATIONS
	var complete := presentations.keys() == expected
	for clue_id in expected:
		var record: Dictionary = presentations.get(clue_id, {})
		complete = complete and String(record.get("presentation", "")) == "shed_crown_thorn" \
			and not String(record.get("title", "")).is_empty() \
			and not (record.get("pages", []) as Array).is_empty()
	_check("four authored Shed Crown-Thorn readings remain ledger-only and distinct",
		complete and not ChartsData.COMPONENTS.has("shed_crown_thorn")
			and CampaignData.QUEENS_SUMMIT_CLUES == expected, presentations)
	_check("new approach and Queen rumours are ordered while legacy crown copy remains historical",
		ChartsData.CHART_RUMOUR_ORDER.has("skald_crownward_ascent")
			and ChartsData.CHART_RUMOUR_ORDER.has("queens_summit_boss")
			and ChartsData.CHART_RUMOUR_ORDER.has("atlas_crown_road"))


func _test_retired_handoff_boundary() -> void:
	var legacy_draft := {"grid": {
		"nw": "cold_track", "n": "cold_track", "c": "atlas_folio",
		"w": "climbing_cord", "e": "climbing_cord", "s": "alpha_fang",
	}, "ink_rail": []}
	var live := ChartsData.preview_table(legacy_draft, _context(17, _seventh_cleared()))
	_check("the retired handoff cannot be newly committed through the normal Table",
		not bool(live.commit_ready) and String(live.recipe_id) != "queens_summit", live)
	var legacy := ChartsData.resolve_legacy_template("summit", [], "alpha_fang", {
		"level": 99, "first_snug_returned": true,
		"known_recipe_ids": ["queens_summit"], "campaign_state": _seventh_cleared(),
	})
	_check("the explicit legacy resolver still reconstructs the frozen handoff only",
		bool(legacy.commit_ready) and String(legacy.recipe_id) == "queens_summit"
			and String((legacy.handoff_contract as Dictionary).contract_id)
				== CampaignData.LEGACY_SUMMIT_HANDOFF
			and String(ChartsData.recipe_id_for_template("summit")) == "queens_summit"
			and not ChartsData.TABLE_RECIPE_ORDER.has("queens_summit"), legacy)
