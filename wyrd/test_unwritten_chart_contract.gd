extends SceneTree

# Pure D8 Chart/Table witness contract. Campaign owns permanent story truth;
# this harness locks the data seam that makes it visible, fresh, and non-costed.

const CampaignData = preload("res://data/campaign.gd")
const ChartsData = preload("res://data/charts.gd")

const ROOT_RUNES := ["green_root_rune", "mist_root_rune", "fang_root_rune",
	"crown_root_rune", "pale_root_rune", "ember_root_rune"]
const STORY_SNAPSHOT := ["crown_root_rune", "ember_root_rune", "fang_root_rune",
	"green_root_rune", "map_of_nine_knots", "mist_root_rune", "pale_root_rune"]

var _pass := 0
var _fail := 0

func _check(label: String, ok: bool, detail = "") -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
		print("  x %s %s" % [label, str(detail)])

func _fire_settled() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id in [CampaignData.FIRST_KNOT, CampaignData.GOLDEN_WALLOW,
		CampaignData.SEVENTH_ROAD, CampaignData.QUEENS_SUMMIT,
		CampaignData.PALE_OATH, CampaignData.FIRE_IN_THE_BOUGH]:
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
		var banked: Array = []
		for index in int(CampaignData.CHAPTERS[chapter_id].clue_target):
			banked.append("%s-%d" % [chapter_id, index + 1])
		chapter.banked_chart_ids = banked
	state.relics = ROOT_RUNES.duplicate()
	state.threads = ["past_thread", "present_thread"]
	return CampaignData.normalize_campaign_state(state)

func _unwritten_ready() -> Dictionary:
	var state := _fire_settled()
	for index in 5:
		state = CampaignData.record_successful_chart_return(state, "root_below",
			"root-below-%d" % index, 22, {}).state
	var map := CampaignData.record_map_of_nine_knots(state, 23)
	return map.state if bool(map.ok) else state

func _draft(recipe_id: String) -> Dictionary:
	var recipe: Dictionary = ChartsData.CHART_RECIPES[recipe_id]
	var grid: Dictionary = (recipe.pattern as Dictionary).duplicate(true)
	grid["s"] = String(recipe.required_seal)
	return {"grid": grid, "ink_rail": (recipe.required_inks as Array).duplicate()}

func _context(state: Dictionary, level := 23, hunt := 22) -> Dictionary:
	return {"level": level, "huntcraft_level": hunt, "wildcraft_level": 1,
		"earthcraft_level": 1, "first_snug_returned": true,
		"campaign_state": state, "known_recipe_ids": ["unwritten_road_boss"]}

func _preview(state: Dictionary, level := 23, hunt := 22) -> Dictionary:
	return ChartsData.preview_table(_draft("unwritten_road_boss"),
		_context(state, level, hunt))

func _test_authored_grammar() -> void:
	var final: Dictionary = ChartsData.CHART_RECIPES.unwritten_road_boss
	var root: Dictionary = ChartsData.CHART_RECIPES.root_below
	_check("D8 recipes and renewable component grammar are explicit and ordered",
		ChartsData.TEMPLATES.has("root_below")
		and ChartsData.TEMPLATES.has("unwritten_road_boss")
		and final.pattern == {"nw": "lost_waymark_tracing", "n": "lost_waymark_tracing",
			"ne": "lost_waymark_tracing", "w": "threefold_binding",
			"c": "nine_knot_leaf", "e": "threefold_binding"}
		and root.pattern == {"n": "lost_waymark_tracing", "c": "nine_knot_leaf",
			"w": "threefold_binding"}
		and final.required_inks == ["hedge_ink"]
		and final.required_seal == "wyrm_scale"
		and final.required_story_inputs == STORY_SNAPSHOT
		and ChartsData.CHART_RECIPE_ORDER.has("root_below")
		and ChartsData.CHART_RECIPE_ORDER.has("unwritten_road_boss")
		and ChartsData.CHART_RUMOURS.has("threefold_loom_root_below")
		and ChartsData.CHART_RUMOURS.has("unwritten_road_boss"), final)

func _test_preview_witness_and_cost_boundary() -> void:
	var preview := _preview(_unwritten_ready())
	var rows: Array = preview.story_witnesses
	var labels: Array = []
	for row_v in rows:
		labels.append(String((row_v as Dictionary).label))
	var forbidden := STORY_SNAPSHOT.duplicate()
	var cost_ids: Array = []
	for costs_v in [preview.component_cost, preview.reagent_cost,
		preview.ordinary_costs, preview.costs]:
		for id_v in (costs_v as Dictionary).keys():
			cost_ids.append(String(id_v))
	_check("final preview projects two Rune witnesses and a Map row without pricing references",
		bool(preview.commit_ready)
		and preview.story_input_snapshot == STORY_SNAPSHOT
		and labels == ["Older Roads · 3/3", "Deeper Roads · 3/3", "Map of Nine Knots · 1/1"]
		and preview.component_cost == {"lost_waymark_tracing": 3,
			"threefold_binding": 2, "nine_knot_leaf": 1}
		and preview.reagent_cost == {"hedge_ink": 1, "wyrm_scale": 1}
		and preview.ordinary_costs == {"lost_waymark_tracing": 3,
			"threefold_binding": 2, "nine_knot_leaf": 1, "hedge_ink": 1}
		and not cost_ids.any(func(id): return forbidden.has(id)), preview)

func _test_every_campaign_gate_stays_pure() -> void:
	var ready := _unwritten_ready()
	var cases: Array = []
	var no_fire := ready.duplicate(true)
	(no_fire.chapters as Dictionary)[CampaignData.FIRE_IN_THE_BOUGH].cleared = false
	cases.append(_preview(no_fire))
	var no_clue := ready.duplicate(true)
	(no_clue.chapters as Dictionary)[CampaignData.UNWRITTEN_ROAD].clue_count = 4
	(no_clue.chapters as Dictionary)[CampaignData.UNWRITTEN_ROAD].banked_chart_ids.pop_back()
	cases.append(_preview(no_clue))
	cases.append(_preview(ready, 22, 22))
	cases.append(_preview(ready, 23, 21))
	var no_map := ready.duplicate(true)
	no_map.map_of_nine_knots = false
	cases.append(_preview(no_map))
	var no_rune := ready.duplicate(true)
	(no_rune.relics as Array).erase("ember_root_rune")
	cases.append(_preview(no_rune))
	var all_blocked := true
	for preview_v in cases:
		var preview: Dictionary = preview_v
		all_blocked = all_blocked and not bool(preview.commit_ready) \
			and (preview.component_cost as Dictionary).is_empty() \
			and (preview.reagent_cost as Dictionary).is_empty()
	_check("Fire, clues, levels, Huntcraft, Map, and each Rune gate commit before any spend",
		all_blocked and (_preview(no_map).missing_story_inputs as Array).has("map_of_nine_knots")
			and (_preview(no_rune).missing_story_inputs as Array).has("ember_root_rune"), cases)

func _test_materialized_snapshot_is_frozen() -> void:
	var preview := _preview(_unwritten_ready())
	var chart := ChartsData.materialize_chart(preview, 230023)
	(preview.story_input_snapshot as Array).clear()
	_check("materialized final Chart owns a sorted immutable story snapshot",
		chart.story_input_snapshot == STORY_SNAPSHOT
		and String(chart.story_input_fingerprint) != ""
		and String(chart.story_witness_fingerprint) != "", chart)

func _init() -> void:
	print("--- Unwritten Chart/Table witness ---")
	_test_authored_grammar()
	_test_preview_witness_and_cost_boundary()
	_test_every_campaign_gate_stays_pure()
	_test_materialized_snapshot_is_frozen()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
