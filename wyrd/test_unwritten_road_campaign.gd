extends SceneTree

# Pure Campaign v6 contract for The Unwritten Road. World, Table, encounter,
# town, inventory, and presentation adapt these records elsewhere.

const CampaignData = preload("res://data/campaign.gd")
const ChartsData = preload("res://data/charts.gd")

const ROOT_RUNES := [
	"green_root_rune", "mist_root_rune", "fang_root_rune", "crown_root_rune",
	"pale_root_rune", "ember_root_rune",
]
const STORY_SNAPSHOT := [
	"crown_root_rune", "ember_root_rune", "fang_root_rune", "green_root_rune",
	"map_of_nine_knots", "mist_root_rune", "pale_root_rune",
]

var _pass := 0
var _fail := 0

func _check(label: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
		print("  x %s %s" % [label, detail])

func _fire_settled() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id in [CampaignData.FIRST_KNOT, CampaignData.GOLDEN_WALLOW,
		CampaignData.SEVENTH_ROAD, CampaignData.QUEENS_SUMMIT,
		CampaignData.PALE_OATH, CampaignData.FIRE_IN_THE_BOUGH]:
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
		var ids: Array = []
		for index in int(CampaignData.CHAPTERS[chapter_id].clue_target):
			ids.append("%s-%d" % [chapter_id, index + 1])
		chapter.banked_chart_ids = ids
	state.relics = ROOT_RUNES.duplicate()
	state.threads = ["past_thread", "present_thread"]
	state.restorations = ["trophy_hall", "sallow_jetty", "skald_archive",
		"pale_stair", "rootroad_lift", "ember_kiln"]
	return CampaignData.normalize_campaign_state(state)

func _root_below_ready() -> Dictionary:
	var state := _fire_settled()
	for index in 5:
		state = CampaignData.record_successful_chart_return(state, "root_below",
			"root-below-%d" % (index + 1), 22, {}).state
	return state

func _unwritten_ready() -> Dictionary:
	var map := CampaignData.record_map_of_nine_knots(_root_below_ready(), 23)
	return map.state if bool(map.ok) else _root_below_ready()

func _unwritten_boss_draft() -> Dictionary:
	var recipe: Dictionary = ChartsData.CHART_RECIPES.unwritten_road_boss
	var grid: Dictionary = (recipe.pattern as Dictionary).duplicate(true)
	grid["s"] = String(recipe.required_seal)
	return {"grid": grid, "ink_rail": (recipe.required_inks as Array).duplicate()}

func _unwritten_preview(state: Dictionary) -> Dictionary:
	return ChartsData.preview_table(_unwritten_boss_draft(), {
		"level": 23, "huntcraft_level": 22, "wildcraft_level": 1,
		"earthcraft_level": 1, "first_snug_returned": true,
		"campaign_state": state, "known_recipe_ids": ["unwritten_road_boss"],
	})

func _run() -> void:
	print("--- Unwritten Road campaign domain ---")
	_test_v6_migration_is_additive_and_inert()
	_test_lost_waymark_ledger_and_map_ritual()
	_test_threefold_loom_map_view()
	_test_story_witness_and_final_gate()
	_test_wyrm_escrow_and_named_final_settlement()
	_test_master_forge_contract()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _init() -> void:
	call_deferred("_run")

func _test_v6_migration_is_additive_and_inert() -> void:
	var inert := true
	for source_version in [1, 2, 3, 4, 5]:
		var migrated := CampaignData.normalize_campaign_state({
			"version": source_version,
			"chapters": {CampaignData.FIRE_IN_THE_BOUGH: {
				"clue_count": 5, "cleared": true,
				"banked_chart_ids": ["fire-1", "fire-2", "fire-3", "fire-4", "fire-5"],
			}, CampaignData.UNWRITTEN_ROAD: {
				"clue_count": 5, "cleared": true,
				"banked_chart_ids": ["forged-1", "forged-2", "forged-3", "forged-4", "forged-5"],
			}},
			"materials": {"wyrm_scale": 99, "quiet_tooth": 99},
			"relics": ROOT_RUNES.duplicate(),
			"threads": ["past_thread", "present_thread", "unwritten_thread"],
			"lost_waymarks": ["lost_waymark_5"],
			"map_of_nine_knots": true,
			"road_name_id": "lantern_path",
			"restorations": ["ember_kiln", "master_forge"],
		})
		var road: Dictionary = migrated.chapters[CampaignData.UNWRITTEN_ROAD]
		inert = inert and int(migrated.version) == 6 \
			and road == {"clue_count": 0, "cleared": false, "banked_chart_ids": []} \
			and (migrated.lost_waymarks as Array).is_empty() \
			and not bool(migrated.map_of_nine_knots) \
			and String(migrated.road_name_id) == "" \
			and not (migrated.threads as Array).has("unwritten_thread") \
			and not (migrated.restorations as Array).has("master_forge") \
			and CampaignData.normalize_campaign_state(migrated) == migrated
	_check("v1-v5 normalize to inert v6 final-road state without Wyrm/Rune inference", inert)

func _test_lost_waymark_ledger_and_map_ritual() -> void:
	var fire := _fire_settled()
	var first := CampaignData.record_successful_chart_return(fire, "root_below",
		"root-first", 22, {})
	var duplicate := CampaignData.record_successful_chart_return(first.state, "root_below",
		"root-first", 23, {})
	var state: Dictionary = first.state
	for index in 4:
		state = CampaignData.record_successful_chart_return(state, "root_below",
			"root-distinct-%d" % (index + 2), 22, {}).state
	var underleveled := CampaignData.record_map_of_nine_knots(state, 22)
	var map := CampaignData.record_map_of_nine_knots(state, 23)
	var map_again := CampaignData.record_map_of_nine_knots(map.state, 23)
	_check("five distinct Root Below returns bank exact sorted Lost Waymarks once",
		String(first.clue_id) == "lost_waymark_1"
		and (state.lost_waymarks as Array) == CampaignData.UNWRITTEN_ROAD_CLUES
		and CampaignData.chapter_clue_count(state, CampaignData.UNWRITTEN_ROAD) == 5
		and not bool(duplicate.changed) and duplicate.state == first.state)
	_check("the Loom records Map of Nine Knots only at Wayfinding 23 and is idempotent",
		not bool(underleveled.ok) and bool(map.ok) and bool(map.changed)
		and bool(map.state.map_of_nine_knots) and String(map.loom_state) == "stirring"
		and bool(map_again.ok) and not bool(map_again.changed))

func _test_threefold_loom_map_view() -> void:
	var ready := _root_below_ready()
	var first_folio := CampaignData.threefold_loom_view(ready, 23, false, false)
	var waiting := CampaignData.threefold_loom_view(ready, 22, true, false, true)
	var ritual_ready := CampaignData.threefold_loom_view(ready, 23, true, false)
	var map := CampaignData.record_map_of_nine_knots(ready, 23)
	var map_recorded := CampaignData.threefold_loom_view(map.state, 23, true, true)
	var partial_record := CampaignData.threefold_loom_view(map.state, 23, true, false)
	var no_rune := ready.duplicate(true)
	(no_rune.relics as Array).erase("ember_root_rune")
	var no_rune_loom := CampaignData.threefold_loom_view(no_rune, 23, true, false)
	var no_rune_map := CampaignData.record_map_of_nine_knots(no_rune, 23)
	var no_rune_after_map: Dictionary = no_rune_map.state
	var no_rune_preview := _unwritten_preview(no_rune_after_map)
	var requirement_ids: Array = []
	var neutral_rows := true
	for row_v in ritual_ready.requirements:
		var row: Dictionary = row_v
		requirement_ids.append(String(row.id))
		neutral_rows = neutral_rows and bool(row.read_only) and row.has("met") \
			and row.has("current") and row.has("required")
	_check("the one Loom advances through a neutral first-folio Map view without a Map mutation",
		String(first_folio.phase) == "first_folio" and not bool(first_folio.can_trace)
		and String(waiting.phase) == "waiting" and bool(waiting.read_only)
		and not bool(waiting.can_trace) and String(ritual_ready.phase) == "ritual_ready"
		and bool(ritual_ready.can_trace) and not bool(ritual_ready.read_only)
		and requirement_ids == ["fire_in_the_bough", "lost_waymarks", "past_thread",
			"present_thread", "wayfinding_23"] and neutral_rows)
	_check("a recorded Map takes precedence over incomplete knowledge and remains a read-only record",
		String(map_recorded.phase) == "map_recorded" and bool(map_recorded.map_recorded)
		and bool(map_recorded.knowledge_complete) and not bool(map_recorded.can_trace)
		and String(partial_record.phase) == "map_recorded"
		and not bool(partial_record.knowledge_complete) and not bool(partial_record.can_trace))
	_check("a missing Root Rune does not block the Map ritual but blocks final witness and Table preview",
		String(no_rune_loom.phase) == "ritual_ready" and bool(no_rune_loom.can_trace)
		and bool(no_rune_map.ok) and bool(no_rune_map.changed)
		and bool(no_rune_after_map.map_of_nine_knots)
		and not bool(CampaignData.required_story_inputs(no_rune_after_map).eligible)
		and CampaignData.required_story_inputs(no_rune_after_map).missing_story_inputs == ["ember_root_rune"]
		and not bool(no_rune_preview.commit_ready)
		and no_rune_preview.missing_story_inputs == ["ember_root_rune"], str(no_rune_preview))

func _test_story_witness_and_final_gate() -> void:
	var ready := _unwritten_ready()
	var witness := CampaignData.required_story_inputs(ready)
	var no_map := ready.duplicate(true)
	no_map.map_of_nine_knots = false
	var no_rune := ready.duplicate(true)
	(no_rune.relics as Array).erase("ember_root_rune")
	_check("final witness is sorted, immutable, and names every required permanent record",
		bool(witness.eligible) and witness.required_story_inputs == STORY_SNAPSHOT
		and witness.story_input_snapshot == STORY_SNAPSHOT
		and (witness.missing_story_inputs as Array).is_empty()
		and not bool(CampaignData.required_story_inputs(no_map).eligible)
		and CampaignData.required_story_inputs(no_map).missing_story_inputs == ["map_of_nine_knots"]
		and not bool(CampaignData.required_story_inputs(no_rune).eligible)
		and CampaignData.required_story_inputs(no_rune).missing_story_inputs == ["ember_root_rune"])
	_check("Unwritten Chart requires all Waymarks, Map, Wayfinding 23, and Huntcraft 22",
		not CampaignData.can_inscribe_boss(ready, "unwritten_road_boss", 22, 23, 22)
		and not CampaignData.can_inscribe_boss(ready, "unwritten_road_boss", 23, 23, 21)
		and not CampaignData.can_inscribe_boss(no_map, "unwritten_road_boss", 23, 23, 22)
		and not CampaignData.can_inscribe_boss(no_rune, "unwritten_road_boss", 23, 23, 22)
		and CampaignData.can_inscribe_boss(ready, "unwritten_road_boss", 23, 1, 22)
		and CampaignData.boss_contract("unwritten_road_boss") == {
			"chapter_id": CampaignData.UNWRITTEN_ROAD, "boss_kind": "knot_eater",
			"seal_id": "wyrm_scale", "guaranteed": true,
			"escrow_items": {"wyrm_scale": 1},
		})

func _test_wyrm_escrow_and_named_final_settlement() -> void:
	var ready := _unwritten_ready()
	var begun := CampaignData.begin_boss_escrow(ready, "unwritten-case-a",
		CampaignData.UNWRITTEN_ROAD)
	var record: Dictionary = begun.state.escrows[begun.attempt_id]
	var entered := CampaignData.mark_escrow_in_run(begun.state, begun.attempt_id,
		"unwritten-case-a", CampaignData.UNWRITTEN_ROAD)
	var refunded := CampaignData.refund_escrow(entered.state, begun.attempt_id,
		"unwritten-case-a", CampaignData.UNWRITTEN_ROAD)
	var retry := CampaignData.begin_boss_escrow(refunded.state, "unwritten-case-b",
		CampaignData.UNWRITTEN_ROAD)
	var retry_entered := CampaignData.mark_escrow_in_run(retry.state, retry.attempt_id,
		"unwritten-case-b", CampaignData.UNWRITTEN_ROAD)
	var death := CampaignData.resolve_boss_death(retry_entered.state, retry.attempt_id,
		"unwritten-case-b", CampaignData.UNWRITTEN_ROAD)
	var bad_name := CampaignData.resolve_unwritten_road(retry_entered.state, retry.attempt_id,
		"unwritten-case-b", "not-a-road")
	var settled := CampaignData.resolve_unwritten_road(retry_entered.state, retry.attempt_id,
		"unwritten-case-b", "lantern_path")
	var settled_again := CampaignData.resolve_unwritten_road(settled.state, retry.attempt_id,
		"unwritten-case-b", "mended_way")
	_check("only Wyrm Scale is escrowed; witness is frozen and refund is exact-once",
		bool(begun.ok) and record.items == {"wyrm_scale": 1}
		and record.story_input_snapshot == STORY_SNAPSHOT
		and String(record.story_input_fingerprint) != ""
		and refunded.material_refunds == {"wyrm_scale": 1})
	_check("Knot-Eater death and invalid names cannot settle the final road",
		not bool(death.ok) and not bool(death.changed)
		and not bool(bad_name.ok) and not bool(bad_name.changed))
	_check("host naming settles once: exact Quiet Tooth, Thread, Forge, and cosmetic road",
		settled.material_awards == {"quiet_tooth": 1}
		and settled.material_set == {"wyrm_scale": 0}
		and settled.material_targets_exact == {"wyrm_scale": 0, "quiet_tooth": 1}
		and settled.thread_awards == ["unwritten_thread"]
		and settled.restoration_awards == ["master_forge"]
		and CampaignData.chapter_cleared(settled.state, CampaignData.UNWRITTEN_ROAD)
		and String(settled.state.road_name_id) == "lantern_path"
		and (settled.state.relics as Array) == ROOT_RUNES
		and bool(settled_again.ok) and not bool(settled_again.changed)
		and String(settled_again.state.road_name_id) == "lantern_path")

func _test_master_forge_contract() -> void:
	var ready := _unwritten_ready()
	var begun := CampaignData.begin_boss_escrow(ready, "unwritten-forge",
		CampaignData.UNWRITTEN_ROAD)
	var entered := CampaignData.mark_escrow_in_run(begun.state, begun.attempt_id,
		"unwritten-forge", CampaignData.UNWRITTEN_ROAD)
	var settled := CampaignData.resolve_unwritten_road(entered.state, begun.attempt_id,
		"unwritten-forge", "open_footpath")
	var low_grip := CampaignData.craft_quiet_tooth_grip(settled.state, 22,
		{"quiet_tooth": 1})
	var grip := CampaignData.craft_quiet_tooth_grip(settled.state, 23,
		{"quiet_tooth": 1})
	_check("Master Hunt consumes the exact-once Quiet Tooth only at Huntcraft 23",
		not bool(low_grip.ok) and bool(grip.ok) and grip.material_targets_exact
			== {"quiet_tooth": 0, "quiet_tooth_grip": 1})
	_check("Campaign retains only the final-road witnesses and Master Forge restoration; gear is not a campaign material output",
		(settled.state.threads as Array).has("past_thread")
		and (settled.state.threads as Array).has("present_thread")
		and (settled.state.threads as Array).has("unwritten_thread")
		and (settled.state.restorations as Array).has("master_forge")
		and String(CampaignData.settlement_view(settled.state, {"guest": true}).road_name_id)
			== "open_footpath")
