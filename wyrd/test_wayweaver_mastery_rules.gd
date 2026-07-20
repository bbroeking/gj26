extends SceneTree

# Focused D8 Slice 3 contract: the data policy is deterministic, has no hidden
# mutation, spends the five authored source pairs exactly, and never turns the
# final legendary into a material.

const CampaignData = preload("res://data/campaign.gd")
const GatherData = preload("res://data/gather.gd")
const ItemsData = preload("res://data/items.gd")
const Rules = preload("res://data/wayweaver_mastery.gd")

var _pass := 0
var _fail := 0

func _init() -> void:
	print("--- Wayweaver mastery rules ---")
	_test_fixed_sources_and_five_pair_budget()
	_test_exact_component_chains_and_one_per_chain()
	_test_component_gates()
	_test_every_final_predicate_and_placement_gate()
	_test_final_item_plan_and_purity()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _check(label: String, ok: bool, detail = "") -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
		print("  x %s %s" % [label, str(detail)])

func _ready_campaign() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id_v in CampaignData.CHAPTER_ORDER:
		var chapter_id := String(chapter_id_v)
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
		chapter.banked_chart_ids = ["mastery-%s" % chapter_id]
	state.relics = CampaignData.ROOT_RUNE_IDS.duplicate()
	state.threads = Rules.REQUIRED_THREADS.duplicate()
	state.restorations = ["master_forge"]
	state.map_of_nine_knots = true
	state.road_name_id = "lantern_path"
	return CampaignData.normalize_campaign_state(state)

func _facts(materials := {}) -> Dictionary:
	return {
		"campaign_state": _ready_campaign(),
		"trades": {"wayfinding": {"lv": 23}, "earthcraft": {"lv": 23},
			"wildcraft": {"lv": 23}, "huntcraft": {"lv": 23}},
		"materials": materials.duplicate(true),
		"ownership": {"pack": [], "equipment": {"weapon": null}},
		"pack": {"wayweaver_fit": {"pos": Vector2i(0, 0), "rotated": false},
			"displaced_weapon_fit": {"pos": Vector2i(0, 0), "rotated": false}},
	}

func _apply_delta(materials: Dictionary, delta: Dictionary) -> Dictionary:
	var out := materials.duplicate(true)
	for id_v in delta.keys():
		var id := String(id_v)
		out[id] = int(out.get(id, 0)) + int(delta[id_v])
	return out

func _test_fixed_sources_and_five_pair_budget() -> void:
	var waysteel: Dictionary = GatherData.ROOTROAD_ORE_TIERS.waysteel
	var root_sap: Dictionary = GatherData.ROOTROAD_HERB_TIERS.root_sap
	_check("both Root Below sources are fixed one-yield and bypass only gather multipliers",
		int(waysteel.fixed_yield) == 1 and int(root_sap.fixed_yield) == 1
			and waysteel.bypass_gather_perks == ["keen_eye", "sturdy_swings"]
			and root_sap.bypass_gather_perks == ["keen_eye", "sturdy_swings"]
			and Rules.source_contract("waysteel") == {"item": "waysteel_shard", "fixed_yield": 1,
				"bypass_gather_perks": ["keen_eye", "sturdy_swings"]},
		{"waysteel": waysteel, "root_sap": root_sap})
	_check("the declared five-pair budget stays exact despite every perk being represented",
		Rules.mastery_budget() == {"waysteel_shard": 5, "root_sap": 5}
			and Rules.BYPASSED_MASTERY_PERKS == ["keen_eye", "sturdy_swings", "smiths_thrift", "second_pour"],
		Rules.mastery_budget())

func _test_exact_component_chains_and_one_per_chain() -> void:
	var facts := _facts({"waysteel_shard": 5, "root_sap": 5, "quiet_tooth": 1})
	var expected := {
		Rules.WAYSTEEL_CORE: {"waysteel_shard": -3, Rules.WAYSTEEL_CORE: 1},
		Rules.WAYSTEEL_FRAME: {Rules.WAYSTEEL_CORE: -1, "waysteel_shard": -2, Rules.WAYSTEEL_FRAME: 1},
		Rules.ROOT_SAP_CORD: {"root_sap": -3, Rules.ROOT_SAP_CORD: 1},
		Rules.THREEFOLD_DRAUGHT: {"root_sap": -2, Rules.THREEFOLD_DRAUGHT: 1},
		Rules.WAYWEAVER_STRING: {Rules.ROOT_SAP_CORD: -1, Rules.THREEFOLD_DRAUGHT: -1, Rules.WAYWEAVER_STRING: 1},
		Rules.QUIET_TOOTH_GRIP: {"quiet_tooth": -1, Rules.QUIET_TOOTH_GRIP: 1},
	}
	var plans := {}
	for action_id_v in expected.keys():
		var action_id := String(action_id_v)
		# Dependents are tested after their inputs have been materialized below.
		if action_id == Rules.WAYSTEEL_FRAME or action_id == Rules.WAYWEAVER_STRING:
			continue
		plans[action_id] = Rules.preview(action_id, facts)
		_check("%s has its exact authored material delta" % action_id,
			bool(plans[action_id].commit_ready) and plans[action_id].material_delta == expected[action_id]
				and int(plans[action_id].trade_xp) == 0 and not bool(plans[action_id].uses_generic_craft), plans[action_id])
	# Advance only copies in the test, proving plans themselves do not mutate.
	facts.materials = _apply_delta(facts.materials, (plans[Rules.WAYSTEEL_CORE] as Dictionary).material_delta)
	plans[Rules.WAYSTEEL_FRAME] = Rules.preview(Rules.WAYSTEEL_FRAME, facts)
	facts.materials = _apply_delta(facts.materials, (plans[Rules.WAYSTEEL_FRAME] as Dictionary).material_delta)
	facts.materials = _apply_delta(facts.materials, (plans[Rules.ROOT_SAP_CORD] as Dictionary).material_delta)
	facts.materials = _apply_delta(facts.materials, (plans[Rules.THREEFOLD_DRAUGHT] as Dictionary).material_delta)
	plans[Rules.WAYWEAVER_STRING] = Rules.preview(Rules.WAYWEAVER_STRING, facts)
	facts.materials = _apply_delta(facts.materials, (plans[Rules.WAYWEAVER_STRING] as Dictionary).material_delta)
	facts.materials = _apply_delta(facts.materials, (plans[Rules.QUIET_TOOTH_GRIP] as Dictionary).material_delta)
	_check("the two 3+2 chains consume exactly five shards and five sap",
		int(facts.materials.get("waysteel_shard", 0)) == 0 and int(facts.materials.get("root_sap", 0)) == 0
			and plans[Rules.WAYSTEEL_FRAME].material_delta == expected[Rules.WAYSTEEL_FRAME]
			and plans[Rules.WAYWEAVER_STRING].material_delta == expected[Rules.WAYWEAVER_STRING], facts.materials)
	for action_id_v in expected.keys():
		var action_id := String(action_id_v)
		var output := String((Rules.RECIPES[action_id] as Dictionary).material_output)
		var duplicate_facts := _facts({output: 1, "waysteel_shard": 5, "root_sap": 5,
			Rules.WAYSTEEL_CORE: 1, Rules.ROOT_SAP_CORD: 1, Rules.THREEFOLD_DRAUGHT: 1,
			"quiet_tooth": 1})
		var duplicate := Rules.preview(action_id, duplicate_facts)
		_check("%s is one-per-chain" % action_id,
			not bool(duplicate.commit_ready) and (duplicate.missing_predicates as Array).has("one_per_chain.%s" % output), duplicate)

func _test_component_gates() -> void:
	var cases := [
		{"action": Rules.WAYSTEEL_CORE, "material": "waysteel_shard", "gate": "trade.earthcraft>=22", "trade": "earthcraft", "low": 21},
		{"action": Rules.ROOT_SAP_CORD, "material": "root_sap", "gate": "trade.wildcraft>=22", "trade": "wildcraft", "low": 21},
		{"action": Rules.WAYWEAVER_STRING, "material": Rules.ROOT_SAP_CORD, "gate": "trade.wildcraft>=23", "trade": "wildcraft", "low": 22},
		{"action": Rules.QUIET_TOOTH_GRIP, "material": "quiet_tooth", "gate": "trade.huntcraft>=23", "trade": "huntcraft", "low": 22},
	]
	var all_trade_gates := true
	for case_v in cases:
		var case: Dictionary = case_v
		var materials := {"waysteel_shard": 3, "root_sap": 3, Rules.ROOT_SAP_CORD: 1,
			Rules.THREEFOLD_DRAUGHT: 1, "quiet_tooth": 1}
		var facts := _facts(materials)
		facts.trades[String(case.trade)] = {"lv": int(case.low)}
		var preview := Rules.preview(String(case.action), facts)
		all_trade_gates = all_trade_gates and not bool(preview.commit_ready) \
			and (preview.missing_predicates as Array).has(String(case.gate))
	_check("each station's authored late-Trade gate is data-owned", all_trade_gates, cases)
	var dormant_loom := _facts({Rules.ROOT_SAP_CORD: 1, Rules.THREEFOLD_DRAUGHT: 1})
	(dormant_loom.campaign_state.chapters[CampaignData.UNWRITTEN_ROAD] as Dictionary).cleared = false
	var no_final_clear := _facts({"quiet_tooth": 1})
	(no_final_clear.campaign_state.chapters[CampaignData.UNWRITTEN_ROAD] as Dictionary).cleared = false
	var loom_preview := Rules.preview(Rules.WAYWEAVER_STRING, dormant_loom)
	var grip_preview := Rules.preview(Rules.QUIET_TOOTH_GRIP, no_final_clear)
	_check("the Loom must be awake and Master Hunt requires the final clear",
		not bool(loom_preview.commit_ready) and (loom_preview.missing_predicates as Array).has("threefold_loom_awake")
			and not bool(grip_preview.commit_ready) and (grip_preview.missing_predicates as Array).has("unwritten_road_cleared"),
		{"loom": loom_preview, "grip": grip_preview})

func _test_every_final_predicate_and_placement_gate() -> void:
	var materials := {Rules.WAYSTEEL_FRAME: 1, Rules.WAYWEAVER_STRING: 1, Rules.QUIET_TOOTH_GRIP: 1}
	var ready := _facts(materials)
	var cases: Array = []
	var no_clear := ready.duplicate(true)
	(no_clear.campaign_state.chapters[CampaignData.UNWRITTEN_ROAD] as Dictionary).cleared = false
	cases.append({"id": "unwritten_road_cleared", "facts": no_clear})
	var no_forge := ready.duplicate(true)
	no_forge.campaign_state.restorations = []
	cases.append({"id": "master_forge_restored", "facts": no_forge})
	for story_id_v in CampaignData.UNWRITTEN_REQUIRED_STORY_INPUTS:
		var story_id := String(story_id_v)
		var missing_story := ready.duplicate(true)
		if story_id == "map_of_nine_knots":
			missing_story.campaign_state.map_of_nine_knots = false
		else:
			(missing_story.campaign_state.relics as Array).erase(story_id)
		cases.append({"id": "story.%s" % story_id, "facts": missing_story})
	for thread_id_v in Rules.REQUIRED_THREADS:
		var thread_id := String(thread_id_v)
		var missing_thread := ready.duplicate(true)
		(missing_thread.campaign_state.threads as Array).erase(thread_id)
		cases.append({"id": "thread.%s" % thread_id, "facts": missing_thread})
	for trade_id_v in Rules.ALL_TRADES:
		var trade_id := String(trade_id_v)
		var low_trade := ready.duplicate(true)
		low_trade.trades[trade_id] = {"lv": 22}
		cases.append({"id": "trade.%s>=23" % trade_id, "facts": low_trade})
	for material_id_v in materials.keys():
		var material_id := String(material_id_v)
		var missing_material := ready.duplicate(true)
		missing_material.materials[material_id] = 0
		cases.append({"id": "materials.%s>=1" % material_id, "facts": missing_material})
	var all_missing := true
	for case_v in cases:
		var case: Dictionary = case_v
		var preview := Rules.preview(Rules.WAYWEAVER, case.facts, Rules.KEEP)
		all_missing = all_missing and not bool(preview.commit_ready) \
			and (preview.missing_predicates as Array).has(String(case.id))
	_check("every campaign, witness, thread, Trade, and component predicate blocks the Forge", all_missing, cases)
	var duplicate_pack := ready.duplicate(true)
	duplicate_pack.ownership.pack = [{"kind_id": Rules.WAYWEAVER}]
	var duplicate_equipment := ready.duplicate(true)
	duplicate_equipment.ownership.equipment.weapon = {"kind_id": Rules.WAYWEAVER}
	var no_keep_fit := ready.duplicate(true)
	no_keep_fit.pack.wayweaver_fit = {}
	var occupied_equip := ready.duplicate(true)
	occupied_equip.ownership.equipment.weapon = {"kind_id": "warbow", "category": "weapon"}
	occupied_equip.pack.displaced_weapon_fit = {}
	var empty_equip := ready.duplicate(true)
	empty_equip.pack.wayweaver_fit = {}
	var uniqueness_and_placement := not bool(Rules.preview(Rules.WAYWEAVER, duplicate_pack, Rules.KEEP).commit_ready) \
		and not bool(Rules.preview(Rules.WAYWEAVER, duplicate_equipment, Rules.KEEP).commit_ready) \
		and not bool(Rules.preview(Rules.WAYWEAVER, no_keep_fit, Rules.KEEP).commit_ready) \
		and not bool(Rules.preview(Rules.WAYWEAVER, occupied_equip, Rules.EQUIP).commit_ready) \
		and bool(Rules.preview(Rules.WAYWEAVER, empty_equip, Rules.EQUIP).commit_ready)
	_check("uniqueness scans pack and equipment; keep/equip enforce their distinct placement rules",
		uniqueness_and_placement, {"pack": duplicate_pack, "equipment": duplicate_equipment})
	var invalid_choice := Rules.preview(Rules.WAYWEAVER, ready, "drop")
	_check("only the explicit keep/equip choice can commit", not bool(invalid_choice.commit_ready)
		and (invalid_choice.missing_predicates as Array).has("final_choice"), invalid_choice)

func _test_final_item_plan_and_purity() -> void:
	var facts := _facts({Rules.WAYSTEEL_FRAME: 1, Rules.WAYWEAVER_STRING: 1, Rules.QUIET_TOOTH_GRIP: 1})
	var before := facts.duplicate(true)
	var keep := Rules.preview(Rules.WAYWEAVER, facts, Rules.KEEP)
	var repeat := Rules.preview(Rules.WAYWEAVER, facts, Rules.KEEP)
	var commit := Rules.commit_plan(Rules.WAYWEAVER, facts, Rules.KEEP)
	var item: Dictionary = keep.item_output
	var kind: Dictionary = ItemsData.KINDS[Rules.WAYWEAVER]
	_check("final plan is stable, pure, and consumes only Frame, String, and Grip",
		facts == before and keep == repeat and keep == commit
			and keep.material_delta == {Rules.WAYSTEEL_FRAME: -1, Rules.WAYWEAVER_STRING: -1,
				Rules.QUIET_TOOTH_GRIP: -1}
			and not (keep.material_delta as Dictionary).has(Rules.WAYWEAVER), keep)
	_check("the final output is a non-sellable legendary 2x4 weapon descriptor, never a material",
		bool(keep.commit_ready) and item.kind_id == Rules.WAYWEAVER and item.rarity == "legendary"
			and item.size == Vector2i(2, 4) and not bool(item.sellable)
			and int(item.base_value) == 11 and int(kind.base_value) == 11
			and int(kind.base_value) <= int(ItemsData.KINDS.warbow.base_value)
			and not GatherData.MATERIALS.has(Rules.WAYWEAVER) and not bool(kind.icon_placeholder)
			and String(kind.icon_path) == "res://assets/ui/items/wayweaver.png"
			and ResourceLoader.exists(String(kind.icon_path))
			and String(ItemsData.make_item(Rules.WAYWEAVER, "legendary").rarity) == "legendary", item)
	var all_component_icons := true
	for material_id in ["waysteel_shard", Rules.WAYSTEEL_CORE, Rules.WAYSTEEL_FRAME,
			"root_sap", Rules.ROOT_SAP_CORD, Rules.THREEFOLD_DRAUGHT,
			Rules.WAYWEAVER_STRING, "quiet_tooth", Rules.QUIET_TOOTH_GRIP]:
		var path := GatherData.material_icon_path(String(material_id))
		all_component_icons = all_component_icons and path != "" \
			and ResourceLoader.exists(path)
	_check("every Wayweaver mastery input and output has shared authored icon art",
		all_component_icons)
