extends SceneTree

# Focused data contract for the Golden Wallow content. Campaign settlement and
# runtime adapters have their own suites; this locks the authored Chart/Ink
# inputs that those seams consume.

const ChartsData = preload("res://data/charts.gd")
const GatherData = preload("res://data/gather.gd")
const CampaignData = preload("res://data/campaign.gd")

var _passed := 0
var _failed := 0

func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		_passed += 1
		print("  ✓ %s" % label)
	else:
		_failed += 1
		print("  ✗ %s %s" % [label, detail])

func _first_knot_cleared() -> Dictionary:
	var state := CampaignData.empty_state()
	(state.chapters[CampaignData.FIRST_KNOT] as Dictionary).cleared = true
	(state.chapters[CampaignData.FIRST_KNOT] as Dictionary).clue_count = 3
	return CampaignData.normalize_campaign_state(state)

func _golden_ready() -> Dictionary:
	var state := _first_knot_cleared()
	for chart_id in ["shallows-a", "shallows-b", "shallows-c"]:
		state = CampaignData.record_successful_chart_return(state,
			"sallow_shallows", chart_id, 9, {}).state
	return state

func _context(level: int, state: Dictionary, materials: Dictionary) -> Dictionary:
	return {
		"level": level, "first_snug_returned": true,
		"campaign_state": state.duplicate(true),
		"material_counts": materials.duplicate(true),
		"known_recipe_ids": [],
	}

func _init() -> void:
	print("--- Golden Wallow content ---")
	_test_shallows_recipe_and_source()
	_test_mire_ink()
	_test_boss_recipe_and_seal_policy()
	print("--- %d passed, %d failed ---" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _test_shallows_recipe_and_source() -> void:
	var template: Dictionary = ChartsData.TEMPLATES.mire_shallows
	var recipe: Dictionary = ChartsData.CHART_RECIPES.sallow_shallows
	var source: Dictionary = ChartsData.CHART_SOURCES.atlas_sallow_shallows
	_check("Sallow Shallows is a short, one-layer Mire Chart",
		String(template.name) == "Sallow Shallows" and int(template.tier) == 1
			and int(template.req_carto) == 9 and String(template.scope) == "mire"
			and int(template.affix_slots) == 1 and int(template.get("max_layers", 1)) == 1
			and int((template.gen as Dictionary).get("room_count_max", 0)) == 7)
	_check("Shallows keeps the Gilded Hollow Affix name unambiguous",
		String(ChartsData.AFFIXES.gilded.name) == "Gilded Hollow"
			and String(template.name) != String(ChartsData.AFFIXES.gilded.name))
	_check("Atlas handoff owns the reachable Shallows rumour and lesson kit",
		String(recipe.rumour_id) == "atlas_sallow_shallows"
			and String(source.recipe_id) == "sallow_shallows"
			and int(source.min_wayfinding) == 9
			and bool(source.requires_first_knot_clear)
			and source.lesson_components == {"field_parchment": 1,
				"mire_reed": 1, "loop_cord": 1}
			and ChartsData.CHART_SOURCE_ORDER.has("atlas_sallow_shallows"))
	var draft := {"grid": {"n": "mire_reed", "c": "field_parchment",
		"w": "loop_cord"}, "ink_rail": ["hedge_ink"]}
	var blocked := ChartsData.preview_table(draft, _context(9,
		CampaignData.empty_state(), {"mire_reed": 1, "field_parchment": 1,
			"loop_cord": 1, "hedge_ink": 1}))
	var preview := ChartsData.preview_table(draft, _context(9, _first_knot_cleared(),
		{"mire_reed": 1, "field_parchment": 1, "loop_cord": 1, "hedge_ink": 1}))
	var chart := ChartsData.materialize_chart(preview, 9401)
	_check("Shallows Table preview needs First Knot and materializes deterministically",
		not bool(blocked.valid) and bool(preview.commit_ready)
			and String(preview.recipe_id) == "sallow_shallows"
			and String(preview.output.template_id) == "mire_shallows"
			and String(chart.recipe_id) == "sallow_shallows"
			and String(chart.scope) == "mire" and int(chart.max_layers) == 1
			and (chart.affixes as Array).size() == 1, str(preview))

func _test_mire_ink() -> void:
	var ink: Dictionary = GatherData.INK_RECIPES.mire_ink
	_check("Mire Ink is a renewable Wildcraft-10 experiment",
		GatherData.MATERIALS.has("mire_ink") and GatherData.is_ink("mire_ink")
			and GatherData.INK_RECIPE_ORDER.has("mire_ink")
			and ink.inputs == {"bittergrass": 1, "mothmint": 1, "hedge_ink": 1}
			and int(ink.get("req_wildcraft", 0)) == 10
			and String(ink.hint_key) == "still"
			and not String(ink.riddle).is_empty())
	_check("Mire Ink is a Chart Ink but Mothglow remains a separate recipe",
		ChartsData.INKS.has("mire_ink")
			and GatherData.INK_RECIPES.mothglow_ink.inputs
				!= GatherData.INK_RECIPES.mire_ink.inputs)

func _test_boss_recipe_and_seal_policy() -> void:
	var recipe: Dictionary = ChartsData.CHART_RECIPES.golden_wallow_boss
	_check("Burrow Boar's Wallow uses the authored physical recipe",
		int(recipe.req_wayfinding) == 12
			and recipe.pattern == {"n": "mire_reed", "c": "waxed_vellum", "w": "sunk_knot"}
			and recipe.required_inks == ["mire_ink"]
			and String(recipe.required_seal) == "tusker_tusk"
			and String(recipe.campaign_chapter) == CampaignData.GOLDEN_WALLOW
			and String(recipe.output.name) == "Burrow Boar's Wallow"
			and String(recipe.rumour_id) == "golden_wallow_boss")
	var state := _golden_ready()
	var draft := {"grid": {"n": "mire_reed", "c": "waxed_vellum",
		"w": "sunk_knot", "s": "tusker_tusk"}, "ink_rail": ["mire_ink"]}
	var materials := {"mire_reed": 1, "waxed_vellum": 1, "sunk_knot": 1,
		"mire_ink": 1, "tusker_tusk": 1}
	var preview := ChartsData.preview_table(draft, _context(12, state, materials))
	var chart := ChartsData.materialize_chart(preview, 9402)
	var legacy := ChartsData.resolve_chart_recipe(recipe.pattern, [], "tusker_tusk",
		_context(12, state, materials))
	var no_campaign := ChartsData.resolve_chart_recipe(recipe.pattern, [], "tusker_tusk",
		{"level": 12})
	_check("Golden preview freezes a forced Burrow Boar campaign contract",
		bool(preview.commit_ready) and String(preview.recipe_id) == "golden_wallow_boss"
			and String((preview.campaign_contract as Dictionary).boss_kind) == "burrow_boar"
			and String((preview.guaranteed[0] as Dictionary).name) == "The Burrow Boar"
			and (preview.preparation_notes as Array).has(
				"Mire Ink — mixed at Wildcraft 10.")
			and String(chart.name) == "Burrow Boar's Wallow"
			and String((chart.campaign_contract as Dictionary).boss_kind) == "burrow_boar"
			and not (chart.affixes as Array).any(func(affix):
				return String((affix as Dictionary).get("id", "")) == "burrow_boar_den"),
		str(preview))
	_check("pending Tusker blocks newly resolved legacy routes but not old adapters",
		not bool(legacy.valid) and "held" in String(legacy.reason)
			and bool(no_campaign.valid), str(legacy))
