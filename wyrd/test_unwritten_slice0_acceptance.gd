extends SceneTree

# Independent Slice 0 acceptance gate for The Unwritten Road.
#
# This file intentionally crosses the Campaign -> Chart Table -> materialized
# Chart seams.  It is not a unit test for any one adapter: a green result means
# the first D8 slice has kept the permanent-story, escrow, and progression
# contracts coherent together.  Later D8 slices own runtime World/UI/co-op
# coverage; do not turn this into a QA-driver test.

const CampaignData = preload("res://data/campaign.gd")
const ChartsData = preload("res://data/charts.gd")

const UNWRITTEN_ROAD := "unwritten_road"
const ROOT_BELOW := "root_below"
const UNWRITTEN_BOSS := "unwritten_road_boss"
const MAP_OF_NINE_KNOTS := "map_of_nine_knots"
const ROOT_RUNES := [
	"green_root_rune",
	"mist_root_rune",
	"fang_root_rune",
	"crown_root_rune",
	"pale_root_rune",
	"ember_root_rune",
]
const EXPECTED_STORY_INPUTS := [
	"crown_root_rune",
	"ember_root_rune",
	"fang_root_rune",
	"green_root_rune",
	"map_of_nine_knots",
	"mist_root_rune",
	"pale_root_rune",
]
const FIRE_CLUE_XP := [68, 69, 69, 69, 69]
const ROOT_CLUE_XP := [75, 75, 75, 75, 76]

var _pass := 0
var _fail := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("--- Unwritten Road Slice 0 acceptance ---")
	_test_v5_to_v6_is_additive_and_inert()
	if _v6_available():
		_test_lost_waymark_ledger_is_unique_and_bounded()
		_test_story_witness_blocks_every_missing_reference()
		_test_story_snapshot_is_sorted_immutable_and_non_material()
		_test_wyrm_scale_is_the_only_escrowed_story_material()
		_test_authored_xp_is_exact_and_legacy_fire_stays_legacy()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


func _check(label: String, ok: bool, detail = "") -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
		print("  x %s %s" % [label, str(detail)])


func _v6_available() -> bool:
	return int((CampaignData.empty_state() as Dictionary).get("version", 0)) >= 6 \
		and (CampaignData.CHAPTERS as Dictionary).has(UNWRITTEN_ROAD)


func _call_required(target, method_name: String, args: Array, fallback):
	# Static GDScript functions are callable through `callv`, but Script's
	# Object.has_method() deliberately does not enumerate them.  A missing public
	# seam consequently raises a test error (the desired strict red state) rather
	# than pretending the API is optional.
	var result = target.callv(method_name, args)
	return fallback if result == null else result


func _all_fire_settled() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id in ["first_knot", "golden_wallow", "seventh_road",
		"queens_summit", "pale_oath", "fire_in_the_bough"]:
		var chapter: Dictionary = (state.get("chapters", {}) as Dictionary).get(chapter_id, {})
		var chapter_def: Dictionary = (CampaignData.CHAPTERS as Dictionary).get(chapter_id, {})
		chapter["cleared"] = true
		chapter["clue_count"] = int(chapter_def.get("clue_target", 0))
		var banked: Array = []
		for index in int(chapter_def.get("clue_target", 0)):
			banked.append("%s-return-%d" % [chapter_id, index + 1])
		chapter["banked_chart_ids"] = banked
	state["relics"] = ROOT_RUNES.duplicate()
	state["threads"] = ["past_thread", "present_thread"]
	state["restorations"] = ["trophy_hall", "sallow_jetty", "skald_archive",
		"pale_stair", "rootroad_lift", "ember_kiln"]
	return CampaignData.normalize_campaign_state(state)


func _root_below_ready() -> Dictionary:
	var state := _all_fire_settled()
	for index in 5:
		var returned = CampaignData.record_successful_chart_return(state, ROOT_BELOW,
			"root-return-%d" % (index + 1), 22, {})
		state = returned.get("state", state)
	return state


func _unwritten_ready() -> Dictionary:
	var state := _root_below_ready()
	var map_transition = _call_required(CampaignData, "record_map_of_nine_knots",
		[state, 23], {})
	if map_transition is Dictionary and bool((map_transition as Dictionary).get("ok", false)):
		state = (map_transition as Dictionary).get("state", state)
	return state


func _table_draft(recipe_id: String) -> Dictionary:
	var recipe: Dictionary = (ChartsData.CHART_RECIPES as Dictionary).get(recipe_id, {})
	var grid: Dictionary = (recipe.get("pattern", {}) as Dictionary).duplicate(true)
	var seal := String(recipe.get("required_seal", ""))
	if seal != "":
		grid["s"] = seal
	return {"grid": grid, "ink_rail": (recipe.get("required_inks", []) as Array).duplicate()}


func _table_context(state: Dictionary, recipe_id: String) -> Dictionary:
	var materials := {"wyrm_scale": 1}
	return {
		"level": 23,
		"wildcraft_level": 1,
		"huntcraft_level": 22,
		"earthcraft_level": 1,
		"first_snug_returned": true,
		"campaign_state": state,
		"material_counts": materials,
		"known_recipe_ids": [recipe_id],
	}


func _unwritten_preview(state: Dictionary) -> Dictionary:
	return ChartsData.preview_table(_table_draft(UNWRITTEN_BOSS),
		_table_context(state, UNWRITTEN_BOSS))


func _story_inputs(state: Dictionary) -> Dictionary:
	var result = _call_required(CampaignData, "required_story_inputs", [state], {})
	return result if result is Dictionary else {}


func _test_v5_to_v6_is_additive_and_inert() -> void:
	var v5_fire := {
		"version": 5,
		"chapters": {
			"fire_in_the_bough": {"clue_count": 5, "cleared": true,
				"banked_chart_ids": ["fire-1", "fire-2", "fire-3", "fire-4", "fire-5"]},
		},
		# These are deliberately tempting but cannot synthesize D8 truth.
		"materials": {"wyrm_scale": 99, "lost_waymark_tracing": 99},
		"relics": ROOT_RUNES.duplicate(),
		"threads": ["past_thread", "present_thread"],
		"map_of_nine_knots": true,
		"lost_waymarks": ["forged-waymark"],
	}
	var migrated := CampaignData.normalize_campaign_state(v5_fire)
	var twice := CampaignData.normalize_campaign_state(migrated)
	var unwritten: Dictionary = (migrated.get("chapters", {}) as Dictionary).get(
		UNWRITTEN_ROAD, {})
	_check("v5 to v6 is additive, idempotent, and never infers final-road truth",
		int(migrated.get("version", 0)) == 6
		and unwritten == {"clue_count": 0, "cleared": false, "banked_chart_ids": []}
		and (migrated.get("lost_waymarks", []) as Array).is_empty()
		and not bool(migrated.get(MAP_OF_NINE_KNOTS, false))
		and migrated == twice,
		migrated)


func _test_lost_waymark_ledger_is_unique_and_bounded() -> void:
	var state := _all_fire_settled()
	var first = CampaignData.record_successful_chart_return(state, ROOT_BELOW,
		"root-first", 22, {})
	var duplicate = CampaignData.record_successful_chart_return(first.get("state", state), ROOT_BELOW,
		"root-first", 23, {})
	state = first.get("state", state)
	var returned_waymarks: Array = [String(first.get("clue_id", ""))]
	for index in 4:
		var returned = CampaignData.record_successful_chart_return(state, ROOT_BELOW,
			"root-distinct-%d" % (index + 2), 22, {})
		state = returned.get("state", state)
		returned_waymarks.append(String(returned.get("clue_id", "")))
	var ledger: Array = state.get("lost_waymarks", [])
	var sorted_ledger := ledger.duplicate()
	sorted_ledger.sort()
	var unique := {}
	for id_v in ledger:
		unique[String(id_v)] = true
	_check("five distinct Root Below returns bank all and only five unique Lost Waymarks",
		returned_waymarks.all(func(id): return id != "")
		and returned_waymarks.duplicate().size() == 5
		and unique.size() == 5
		and ledger.size() == 5
		and ledger == sorted_ledger
		and int(((state.get("chapters", {}) as Dictionary).get(UNWRITTEN_ROAD, {}) as Dictionary)
			.get("clue_count", 0)) == 5,
		{"returned": returned_waymarks, "ledger": ledger, "state": state})
	_check("a duplicate Root Below Chart cannot bank an extra Waymark or alter authored progression",
		not bool(duplicate.get("changed", true))
		and String(duplicate.get("clue_id", "")) == ""
		and (duplicate.get("state", {}) as Dictionary) == first.get("state", {}), duplicate)


func _test_story_witness_blocks_every_missing_reference() -> void:
	var ready := _unwritten_ready()
	var requirements := _story_inputs(ready)
	var ready_preview := _unwritten_preview(ready)
	var all_blocked := bool(ready_preview.get("commit_ready", false))
	var missing_ids: Array = [MAP_OF_NINE_KNOTS]
	missing_ids.append_array(ROOT_RUNES)
	for missing_id in missing_ids:
		var damaged := ready.duplicate(true)
		if missing_id == MAP_OF_NINE_KNOTS:
			damaged[MAP_OF_NINE_KNOTS] = false
		else:
			(damaged.get("relics", []) as Array).erase(missing_id)
		var proof := _story_inputs(damaged)
		var preview := _unwritten_preview(damaged)
		all_blocked = all_blocked and not bool(proof.get("eligible", true)) \
			and (proof.get("missing_story_inputs", []) as Array).has(missing_id) \
			and not bool(preview.get("commit_ready", true))
	_check("every missing Map or Root Rune blocks final eligibility at both Campaign and Table seams",
		bool(requirements.get("eligible", false))
		and requirements.get("missing_story_inputs", []) == []
		and requirements.get("required_story_inputs", []) == EXPECTED_STORY_INPUTS
		and requirements.get("story_input_snapshot", []) == EXPECTED_STORY_INPUTS
		and all_blocked,
		{"requirements": requirements, "preview": ready_preview})


func _test_story_snapshot_is_sorted_immutable_and_non_material() -> void:
	var ready := _unwritten_ready()
	var preview := _unwritten_preview(ready)
	var materialized := ChartsData.materialize_chart(preview, 820231)
	var snapshot: Array = preview.get("story_input_snapshot", [])
	var chart_snapshot: Array = materialized.get("story_input_snapshot", [])
	var fingerprint_before := String(preview.get("fingerprint", ""))
	var drifted := ready.duplicate(true)
	(drifted.get("relics", []) as Array).erase("ember_root_rune")
	var after_drift := _unwritten_preview(drifted)
	var cost_keys: Array = []
	for cost_group in [preview.get("component_cost", {}), preview.get("reagent_cost", {}),
		preview.get("ordinary_costs", {}), preview.get("costs", {})]:
		if cost_group is Dictionary:
			for id_v in (cost_group as Dictionary).keys():
				cost_keys.append(String(id_v))
	_check("final Chart freezes one sorted immutable story witness and never prices a reference",
		bool(preview.get("commit_ready", false))
		and snapshot == EXPECTED_STORY_INPUTS
		and chart_snapshot == EXPECTED_STORY_INPUTS
		and not cost_keys.any(func(id): return EXPECTED_STORY_INPUTS.has(id))
		and fingerprint_before != String(after_drift.get("fingerprint", ""))
		and not bool(after_drift.get("commit_ready", true)),
		{"preview": preview, "chart": materialized, "after_drift": after_drift})


func _test_wyrm_scale_is_the_only_escrowed_story_material() -> void:
	var ready := _unwritten_ready()
	var begun = CampaignData.begin_boss_escrow(ready, "unwritten-final-a", UNWRITTEN_ROAD)
	var attempt_id := String(begun.get("attempt_id", ""))
	var entered = CampaignData.mark_escrow_in_run(begun.get("state", ready), attempt_id,
		"unwritten-final-a", UNWRITTEN_ROAD)
	var refunded = CampaignData.refund_escrow(entered.get("state", ready), attempt_id,
		"unwritten-final-a", UNWRITTEN_ROAD)
	var retry = CampaignData.begin_boss_escrow(refunded.get("state", ready),
		"unwritten-final-b", UNWRITTEN_ROAD)
	var retry_id := String(retry.get("attempt_id", ""))
	var retry_entered = CampaignData.mark_escrow_in_run(retry.get("state", ready), retry_id,
		"unwritten-final-b", UNWRITTEN_ROAD)
	var death_rejected = CampaignData.resolve_boss_death(retry_entered.get("state", ready), retry_id,
		"unwritten-final-b", UNWRITTEN_ROAD)
	var settled = _call_required(CampaignData, "resolve_unwritten_road", [
		retry_entered.get("state", ready), retry_id, "unwritten-final-b", "lantern_path",
	], {})
	var settled_again = _call_required(CampaignData, "resolve_unwritten_road", [
		settled.get("state", ready), retry_id, "unwritten-final-b", "mended_way",
	], {})
	var escrows: Dictionary = (begun.get("state", {}) as Dictionary).get("escrows", {})
	var escrow: Dictionary = escrows.get(attempt_id, {})
	_check("Wyrm Scale alone enters escrow, refunds once, and is consumed only by canonical success",
		bool(begun.get("ok", false))
		and escrow.get("items", {}) == {"wyrm_scale": 1}
		and escrow.get("story_input_snapshot", []) == EXPECTED_STORY_INPUTS
		and refunded.get("material_refunds", {}) == {"wyrm_scale": 1}
		and not bool(death_rejected.get("ok", true))
		and not bool(death_rejected.get("changed", true))
		and settled.get("material_set", {}) == {"wyrm_scale": 0}
		and (settled.get("material_targets_exact", {}) as Dictionary).get("wyrm_scale", -1) == 0
		and not (settled.get("material_awards", {}) as Dictionary).has("wyrm_scale"),
		{"begun": begun, "refunded": refunded, "settled": settled})
	_check("Knot-Eater settlement is exact-once and awards the permanent Unwritten Thread once",
		bool(settled.get("ok", false))
		and bool(settled.get("changed", false))
		and (settled.get("thread_awards", []) as Array) == ["unwritten_thread"]
		and bool(((((settled.get("state", {}) as Dictionary).get("chapters", {}) as Dictionary)
			.get(UNWRITTEN_ROAD, {}) as Dictionary).get("cleared", false)))
		and bool(settled_again.get("ok", false))
		and not bool(settled_again.get("changed", true)), settled_again)


func _campaign_chart(recipe_id: String, reward: int, affixes: Array) -> Dictionary:
	return {"recipe_id": recipe_id, "tier": 3, "layer": 2,
		"affixes": affixes.duplicate(true), "authored_completion_xp": reward}


func _legacy_xp(chart: Dictionary) -> int:
	var good := 0
	var bad := 0
	var tyrannical := false
	for affix_v in chart.get("affixes", []):
		var affix: Dictionary = affix_v
		if bool(affix.get("good", false)):
			good += 1
			if String(affix.get("id", "")) == "tyrannical":
				tyrannical = true
		else:
			bad += 1
	var xp := int(chart.get("tier", 1)) * 75 + good * 40 + bad * 10
	xp += maxi(0, int(chart.get("layer", 1)) - 1) * 50
	return roundi(xp * 1.3) if tyrannical else xp


func _test_authored_xp_is_exact_and_legacy_fire_stays_legacy() -> void:
	var fire_rewards: Array = []
	var root_rewards: Array = []
	for index in 5:
		fire_rewards.append(_call_required(ChartsData, "campaign_completion_xp_for",
			["ashen_bough", index], -1))
		root_rewards.append(_call_required(ChartsData, "campaign_completion_xp_for",
			[ROOT_BELOW, index], -1))
	var discovery_zero = _call_required(ChartsData, "recipe_discovery_xp", [ROOT_BELOW], -1)
	var final_discovery_zero = _call_required(ChartsData, "recipe_discovery_xp", [UNWRITTEN_BOSS], -1)
	var boss_xp = _call_required(ChartsData, "campaign_completion_xp_for",
		["fire_in_the_bough_boss"], -1)
	var final_xp = _call_required(ChartsData, "campaign_completion_xp_for",
		[UNWRITTEN_BOSS], -1)
	var fire_total := 3496
	for reward in fire_rewards:
		fire_total += int(reward)
	var boss_total := fire_total + int(boss_xp)
	var root_total := boss_total
	for reward in root_rewards:
		root_total += int(reward)
	var hostile_affixes := [{"id": "tyrannical", "good": true}, {"id": "barren", "good": false}]
	var authored_fire := _campaign_chart("ashen_bough", 68, hostile_affixes)
	var authored_final := _campaign_chart(UNWRITTEN_BOSS, 0, hostile_affixes)
	var legacy_fire := authored_fire.duplicate(true)
	legacy_fire.erase("authored_completion_xp")
	_check("late authored completion XP is the frozen 20-to-23 sequence with zero discovery variance",
		ChartsData.CAMPAIGN_COMPLETION_XP.get("ashen_bough", []) == FIRE_CLUE_XP
		and ChartsData.CAMPAIGN_COMPLETION_XP.get("fire_in_the_bough_boss", -1) == 360
		and ChartsData.CAMPAIGN_COMPLETION_XP.get(ROOT_BELOW, []) == ROOT_CLUE_XP
		and ChartsData.CAMPAIGN_COMPLETION_XP.get(UNWRITTEN_BOSS, -1) == 0
		and fire_rewards == FIRE_CLUE_XP and root_rewards == ROOT_CLUE_XP
		and boss_xp == 360 and final_xp == 0
		and discovery_zero == 0 and final_discovery_zero == 0
		and fire_total == 3840 and boss_total == 4200 and root_total == 4576,
		{"fire": fire_rewards, "root": root_rewards,
			"boss": boss_xp, "final": final_xp,
			"floors": [fire_total, boss_total, root_total]})
	_check("frozen authored XP ignores Affixes while pre-v6 Fire Charts retain their legacy formula",
		ChartsData.completion_xp(authored_fire) == 68
		and ChartsData.completion_xp(authored_final) == 0
		and ChartsData.completion_xp(legacy_fire) == _legacy_xp(legacy_fire)
		and ChartsData.completion_xp(legacy_fire) != 68,
		{"authored_fire": ChartsData.completion_xp(authored_fire),
			"authored_final": ChartsData.completion_xp(authored_final),
			"legacy": ChartsData.completion_xp(legacy_fire)})
