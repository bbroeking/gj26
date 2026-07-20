extends SceneTree

# Focused content contract for the Seventh Road. Campaign transitions and
# runtime settlement live in their own suites; this locks the authored Chart,
# Ink, Atlas-source, clue-presentation, and legacy-Summit handoff seams.

const ChartsData = preload("res://data/charts.gd")
const GatherData = preload("res://data/gather.gd")
const CampaignData = preload("res://data/campaign.gd")
const LivingAtlasPanelScript = preload("res://scripts/living_atlas_panel.gd")
const CampaignClueScript = preload("res://scripts/campaign_clue.gd")

var _passed := 0
var _failed := 0


func _check(label: String, condition: bool, detail = "") -> void:
	if condition:
		_passed += 1
		print("  ✓ %s" % label)
	else:
		_failed += 1
		print("  ✗ %s %s" % [label, str(detail)])


func _context(level: int, state: Dictionary, materials: Dictionary,
		wildcraft_level: int = 23) -> Dictionary:
	return {
		"level": level,
		"wildcraft_level": wildcraft_level,
		"first_snug_returned": true,
		"campaign_state": state.duplicate(true),
		"material_counts": materials.duplicate(true),
		"known_recipe_ids": ["briar_maze", "seventh_road_boss", "summit_approach",
			"queens_summit_boss"],
	}


func _seventh_ready() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id in [CampaignData.FIRST_KNOT, CampaignData.GOLDEN_WALLOW]:
		(state.chapters[chapter_id] as Dictionary).cleared = true
		(state.chapters[chapter_id] as Dictionary).clue_count = int(
			CampaignData.CHAPTERS[chapter_id].clue_target)
	var seventh: Dictionary = state.chapters[CampaignData.SEVENTH_ROAD]
	seventh.clue_count = 4
	seventh.banked_chart_ids = ["cold-a", "cold-b", "cold-c", "cold-d"]
	return CampaignData.normalize_campaign_state(state)


func _seventh_cleared() -> Dictionary:
	var state := _seventh_ready()
	(state.chapters[CampaignData.SEVENTH_ROAD] as Dictionary).cleared = true
	return CampaignData.normalize_campaign_state(state)


func _init() -> void:
	print("--- Seventh Road content ---")
	_test_mothglow_and_cold_track_content()
	_test_post_golden_briar_source()
	_test_wolf_boss_chart()
	_test_summit_handoff()
	print("--- %d passed, %d failed ---" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_mothglow_and_cold_track_content() -> void:
	var mothglow: Dictionary = GatherData.INK_RECIPES.mothglow_ink
	_check("Mothglow Ink is a renewable Wildcraft-14 experiment",
		GatherData.is_ink("mothglow_ink")
			and int(mothglow.get("req_wildcraft", 0)) == 14
			and mothglow.inputs == {"mothmint": 2, "hedge_ink": 1}
			and String(mothglow.hint_key) == "still")
	var expected_ids := [
		"seventh_road_cold_track_1", "seventh_road_cold_track_2",
		"seventh_road_cold_track_3", "seventh_road_cold_track_4",
	]
	var records: Dictionary = ChartsData.SEVENTH_ROAD_COLD_TRACK_PRESENTATIONS
	var complete := records.keys() == expected_ids
	for clue_id in expected_ids:
		var record: Dictionary = records.get(clue_id, {})
		complete = complete and String(record.get("presentation", "")) == "cold_track_clue" \
			and not String(record.get("title", "")).is_empty() \
			and not (record.get("pages", []) as Array).is_empty()
		var runtime_clue := CampaignClueScript.new()
		runtime_clue.setup({"id": clue_id, "presentation": "cold_track_clue",
			"chapter_id": CampaignData.SEVENTH_ROAD})
		complete = complete and String(runtime_clue.clue_title) == String(record.title) \
			and runtime_clue._pages() == record.pages
		runtime_clue.free()
	_check("four authored Cold Track clues stay distinct from the physical Waymark",
		complete and not records.has("cold_track")
			and ChartsData.COMPONENTS.has("cold_track"), records)


func _test_post_golden_briar_source() -> void:
	var source: Dictionary = ChartsData.CHART_SOURCES.atlas_briar_knot
	_check("post-Golden Atlas source carries a missing-only Briar lesson kit",
		String(source.recipe_id) == "briar_maze"
			and String(source.rumour_id) == "atlas_briar_knot"
			and int(source.min_wayfinding) == 15
			and bool(source.requires_golden_wallow_clear)
			and String(source.lesson_grant_policy) == "missing_only"
			and source.lesson_components == {
				"thorn_rubbing": 1, "stitched_parchment": 1, "briar_knot": 1,
			}
			and ChartsData.CHART_SOURCE_ORDER.has("atlas_briar_knot"), source)
	var panel: LivingAtlasPanel = LivingAtlasPanelScript.new()
	panel.set_settlement_view({
		"available": true,
		"chapters": {"golden_wallow": {"visible": true}},
	})
	_check("restored Golden Atlas exposes the Briar source before a scene adapter runs",
		panel.active_source_id() == LivingAtlasPanelScript.BRIAR_ROAD_SOURCE_ID)
	panel.free()


func _test_wolf_boss_chart() -> void:
	var recipe: Dictionary = ChartsData.CHART_RECIPES.seventh_road_boss
	_check("Seventh Road Boss Chart owns the locked Briar arrangement",
		int(recipe.req_wayfinding) == 15
			and recipe.pattern == {
				"n": "thorn_rubbing", "c": "stitched_parchment", "w": "briar_knot",
			}
			and recipe.required_inks == ["mothglow_ink"]
			and String(recipe.required_seal) == "wightpelt"
			and String(recipe.campaign_chapter) == CampaignData.SEVENTH_ROAD
			and String(recipe.output.name) == "Wolf Alpha's Seventh Road", recipe)
	var draft := {"grid": {
		"n": "thorn_rubbing", "c": "stitched_parchment", "w": "briar_knot",
		"s": "wightpelt",
	}, "ink_rail": ["mothglow_ink"]}
	var materials := {
		"thorn_rubbing": 1, "stitched_parchment": 1, "briar_knot": 1,
		"mothglow_ink": 1, "wightpelt": 1, "hedge_ink": 3,
	}
	var below := ChartsData.preview_table(draft, _context(14, _seventh_ready(), materials))
	var below_wildcraft := ChartsData.preview_table(draft,
		_context(15, _seventh_ready(), materials, 13))
	var preview := ChartsData.preview_table(draft,
		_context(15, _seventh_ready(), materials, 14))
	var without_ink := ChartsData.preview_table({
		"grid": draft.grid, "ink_rail": [],
	}, _context(15, _seventh_ready(), materials, 14))
	var chart := ChartsData.materialize_chart(preview, 131704)
	_check("Wolf preview enforces level, required Ink, exact costs, and forced boss",
		not bool(below.valid) and not bool(below_wildcraft.valid)
			and "Wildcraft 14" in String(below_wildcraft.reason)
			and not bool(without_ink.commit_ready)
			and bool(preview.commit_ready)
			and String(preview.recipe_id) == "seventh_road_boss"
			and int(preview.costs.wightpelt) == 1
			and int(preview.costs.mothglow_ink) == 1
			and not (preview.ordinary_costs as Dictionary).has("wightpelt")
			and preview.returned_on_failure == {"wightpelt": 1}
			and String((preview.campaign_contract as Dictionary).boss_kind) == "wolf_alpha",
		preview)
	_check("materialized Seventh Road freezes Wolf without a legacy den Affix",
		String(chart.recipe_id) == "seventh_road_boss"
			and String(chart.name) == "Wolf Alpha's Seventh Road"
			and String(chart.seal_id) == "wightpelt"
			and String((chart.campaign_contract as Dictionary).boss_kind) == "wolf_alpha"
			and not (chart.affixes as Array).any(func(affix):
				return String((affix as Dictionary).get("id", "")) == "wolf_alpha_den"), chart)


func _test_summit_handoff() -> void:
	var recipe: Dictionary = ChartsData.CHART_RECIPES.queens_summit
	_check("retired Queen's Summit preserves its visible Alpha Fang legacy Seal",
		String(recipe.required_seal) == "alpha_fang"
			and String(recipe.handoff_contract) == "legacy_summit_handoff"
			and not (ChartsData.TEMPLATES.summit.base_cost as Dictionary).has("alpha_fang")
			and ChartsData.is_protected_chart_supply("alpha_fang")
			and not ChartsData.TROPHY_TO_AFFIX.has("alpha_fang")
			and not ChartsData.TABLE_RECIPE_ORDER.has("queens_summit"), recipe)
	var draft := {"grid": {
		"nw": "cold_track", "n": "cold_track", "c": "atlas_folio",
		"w": "climbing_cord", "e": "climbing_cord", "s": "alpha_fang",
	}, "ink_rail": []}
	var materials := {
		"cold_track": 2, "atlas_folio": 1, "climbing_cord": 2,
		"alpha_fang": 1, "hedge_ink": 4, "refined_ink": 1,
	}
	var live_preview := ChartsData.preview_table(draft,
		_context(16, _seventh_cleared(), materials))
	_check("normal physical Table rejects the retired Fang handoff",
		not bool(live_preview.commit_ready)
			and String(live_preview.recipe_id) != "queens_summit", live_preview)
	var legacy_preview := ChartsData.resolve_legacy_template("summit", [], "alpha_fang", {
		"level": 16, "first_snug_returned": true,
		"known_recipe_ids": ["queens_summit"], "campaign_state": _seventh_cleared(),
	})
	var chart := ChartsData.materialize_chart(legacy_preview, 161704)
	_check("explicit legacy resolver freezes the campaign-inert handoff and Fang safeguard",
		bool(legacy_preview.commit_ready)
			and int(legacy_preview.costs.alpha_fang) == 1
			and not (legacy_preview.ordinary_costs as Dictionary).has("alpha_fang")
			and legacy_preview.returned_on_failure == {"alpha_fang": 1}
			and String((legacy_preview.handoff_contract as Dictionary).contract_id)
				== "legacy_summit_handoff"
			and bool((legacy_preview.handoff_contract as Dictionary).campaign_inert)
			and String((legacy_preview.handoff_contract as Dictionary).boss_kind)
				== "hedgemother_queen", legacy_preview)
	_check("materialized legacy Summit preserves the immutable handoff without Fang Affix RNG",
		String(chart.get("recipe_id", "")) == "queens_summit"
			and String(chart.seal_id) == "alpha_fang"
			and String((chart.handoff_contract as Dictionary).contract_id)
				== "legacy_summit_handoff"
			and (chart.affixes as Array).is_empty(), chart)
	var legacy_chart := ChartsData.inscribe("summit", [], 16, "", 0.0, 161705)
	_check("already materialized legacy Summit shape remains valid",
		String(legacy_chart.template_id) == "summit"
			and String(legacy_chart.scope) == "summit"
			and (legacy_chart.affixes as Array).is_empty(), legacy_chart)
