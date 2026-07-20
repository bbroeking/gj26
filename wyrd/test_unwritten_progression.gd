extends SceneTree

# D8 Slice 0 — the late Wayfinding lane is authored data, not a QA shortcut.
# This intentionally stays pure: it runs the shipped Trade progression helper
# against frozen Chart rewards and never instantiates Game, writes a save, or
# edits a live Trade record.

const CampaignData = preload("res://data/campaign.gd")
const ChartsData = preload("res://data/charts.gd")
const GameScript = preload("res://scripts/game.gd")
const Progression = preload("res://data/progression.gd")

var _pass := 0
var _fail := 0

func _check(label: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % label)
	else:
		_fail += 1
		print("  ✗ %s %s" % [label, detail])

func _init() -> void:
	print("--- Unwritten Road authored progression ---")
	_test_authored_registry_and_discovery_policy()
	_test_exact_level_20_to_23_lane()
	_test_materialized_reward_and_legacy_fallback()
	_test_runtime_claim_guards()
	_test_preinscribed_clue_rebind_order()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _test_authored_registry_and_discovery_policy() -> void:
	var expected := {
		"ashen_bough": [68, 69, 69, 69, 69],
		"fire_in_the_bough_boss": [360],
		"root_below": [75, 75, 75, 75, 76],
		"unwritten_road_boss": [0],
	}
	var matches := true
	for recipe_id_v in expected:
		var recipe_id := String(recipe_id_v)
		var rewards: Array = expected[recipe_id]
		for index in rewards.size():
			var clue_index := index if rewards.size() > 1 else -1
			matches = matches and ChartsData.campaign_completion_xp_for(recipe_id,
				clue_index) == int(rewards[index])
	_check("campaign registry owns every exact D8 reward", matches,
		str(ChartsData.CAMPAIGN_COMPLETION_XP))
	_check("story discoveries are zero except the authored Green prologue bridge",
		ChartsData.recipe_discovery_xp("ashen_bough") == 0
			and ChartsData.recipe_discovery_xp("fire_in_the_bough_boss") == 0
			and ChartsData.recipe_discovery_xp("root_below") == 0
			and ChartsData.recipe_discovery_xp("unwritten_road_boss") == 0
			and ChartsData.recipe_discovery_xp("green_hollow") == 93
			and ChartsData.recipe_discovery_xp("queens_summit") == 50)
	_check("future recipe aliases remain compatibility-only lookup names",
		ChartsData.campaign_completion_xp_for("root_below_chart", 4) == 76
			and ChartsData.campaign_completion_xp_for("unwritten_chart") == 0)

func _award(record: Dictionary, amount: int) -> Dictionary:
	return Progression.award_trade_xp(record, amount)

func _test_exact_level_20_to_23_lane() -> void:
	var record := Progression.normalize_trade_record({"xp": 3496})
	var ashen: Array = []
	for index in 5:
		var reward := ChartsData.campaign_completion_xp_for("ashen_bough", index)
		ashen.append(reward)
		record = _award(record, reward)
	_check("five Ashen clue Charts carry 3496 to 3840 at Wayfinding 21",
		ashen == [68, 69, 69, 69, 69] and int(record.xp) == 3840
			and int(record.lv) == 21, str({"rewards": ashen, "record": record}))
	record = _award(record,
		ChartsData.campaign_completion_xp_for("fire_in_the_bough_boss"))
	_check("Hearth Giant carries 3840 to 4200 at Wayfinding 22",
		int(record.xp) == 4200 and int(record.lv) == 22, str(record))
	var root_below: Array = []
	for index in 5:
		var reward := ChartsData.campaign_completion_xp_for("root_below", index)
		root_below.append(reward)
		record = _award(record, reward)
	_check("five Root Below clue Charts carry 4200 to the level-23 cap",
		root_below == [75, 75, 75, 75, 76] and int(record.xp) == 4576
			and int(record.lv) == 23, str({"rewards": root_below, "record": record}))
	record = _award(record,
		ChartsData.campaign_completion_xp_for("unwritten_road_boss"))
	_check("Unwritten final return is an explicit zero and cannot overflow level 23",
		int(record.xp) == 4576 and int(record.lv) == 23, str(record))

func _fire_ready_state() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id_v in CampaignData.CHAPTER_ORDER:
		var chapter_id := String(chapter_id_v)
		if chapter_id == CampaignData.FIRE_IN_THE_BOUGH:
			break
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
	return CampaignData.normalize_campaign_state(state)

func _test_materialized_reward_and_legacy_fallback() -> void:
	var ashen_preview := {
		"commit_ready": true, "recipe_id": "ashen_bough",
		"output": {"template_id": "ashen_bough", "name": "Ashen Bough"},
		"wayfinding_level": 20, "campaign_state_snapshot": _fire_ready_state(),
	}
	var ashen := ChartsData.materialize_chart(ashen_preview, 22001)
	var ashen_reward := ChartsData.authored_completion_reward(ashen)
	_check("eligible Ashen clue freezes its first authored reward on the Chart",
		int(ashen.get("authored_completion_xp", -1)) == 68
			and String(ashen_reward.kind) == "clue"
			and String(ashen_reward.clue_id) == "ember_verse_1"
			and ChartsData.completion_xp(ashen) == 68, str(ashen))
	var affixed := ashen.duplicate(true)
	affixed["affixes"] = [{"id": "tyrannical", "good": true},
		{"id": "cinderbound", "good": false}]
	_check("frozen campaign XP is independent of the materialized Affixes",
		ChartsData.completion_xp(affixed) == 68, str(affixed))
	var legacy_fire := ashen.duplicate(true)
	legacy_fire.erase("authored_completion_xp")
	legacy_fire.erase("authored_completion_reward")
	legacy_fire["tier"] = 3
	legacy_fire["affixes"] = [{"id": "tyrannical", "good": true}]
	_check("pre-v6 Fire Chart without the field retains legacy completion math",
		ChartsData.completion_xp(legacy_fire) == ChartsData.legacy_completion_xp(legacy_fire)
			and ChartsData.completion_xp(legacy_fire) == 345, str(legacy_fire))
	var fire_preview := {
		"commit_ready": true, "recipe_id": "fire_in_the_bough_boss",
		"output": {"template_id": "fire_in_the_bough_boss", "name": "Fire in the Bough"},
		"wayfinding_level": 21,
		"campaign_contract": CampaignData.boss_contract("fire_in_the_bough_boss"),
	}
	var fire := ChartsData.materialize_chart(fire_preview, 22002)
	_check("eligible Fire Boss freezes 360 rather than the generic tier reward",
		int(fire.get("authored_completion_xp", -1)) == 360
			and String(ChartsData.authored_completion_reward(fire).kind) == "boss"
			and ChartsData.completion_xp(fire) == 360, str(fire))

func _new_runtime_game() -> Node:
	var game: Node = GameScript.new()
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.persistence_enabled = false
	return game

func _test_runtime_claim_guards() -> void:
	var game := _new_runtime_game()
	game.campaign_state = _fire_ready_state()
	game.trades.wayfinding = {"xp": 3496, "lv": 20}
	var preview := {
		"commit_ready": true, "recipe_id": "ashen_bough",
		"output": {"template_id": "ashen_bough", "name": "Ashen Bough"},
		"wayfinding_level": 20,
		"campaign_state_snapshot": game.campaign_state.duplicate(true),
	}
	var frozen: Dictionary = game._freeze_campaign_clue(
		ChartsData.materialize_chart(preview, 22003))
	var first_xp: int = game._completion_xp_for_successful_return(frozen)
	var returned: Dictionary = CampaignData.record_successful_chart_return(game.campaign_state,
		"ashen_bough", String(frozen.get("chart_instance_id", "")), 21, {})
	game.campaign_state = returned.state
	var replay_xp: int = game._completion_xp_for_successful_return(frozen)
	var memory: Dictionary = frozen.duplicate(true)
	memory["campaign_inert"] = true
	var memory_xp: int = game._completion_xp_for_successful_return(memory)
	var ordinary: Dictionary = ChartsData.inscribe("ashen_bough", [], 20, "", 0.0, 22004)
	var ordinary_xp: int = game._completion_xp_for_successful_return(ordinary)
	var before_abandon := int(game.trades.wayfinding.xp)
	game.active_chart = frozen.duplicate(true)
	game.return_to_town(null, true)
	_check("only the current eligible clue receives frozen XP; replay, Memory, and ordinary Charts fall back",
		first_xp == 68
			and replay_xp == ChartsData.legacy_completion_xp(frozen)
			and memory_xp == ChartsData.legacy_completion_xp(memory)
			and ordinary_xp == ChartsData.legacy_completion_xp(ordinary)
			and replay_xp != 68 and memory_xp != 68 and ordinary_xp != 68,
		str({"first": first_xp, "replay": replay_xp, "memory": memory_xp,
			"ordinary": ordinary_xp}))
	_check("abandoning a frozen campaign Chart grants no Wayfinding XP",
		int(game.trades.wayfinding.xp) == before_abandon,
		str({"before": before_abandon, "after": game.trades.wayfinding}))
	game.free()

func _root_below_ready_state() -> Dictionary:
	var state := _fire_ready_state()
	var fire: Dictionary = state.chapters[CampaignData.FIRE_IN_THE_BOUGH]
	fire.cleared = true
	fire.clue_count = int(CampaignData.CHAPTERS[CampaignData.FIRE_IN_THE_BOUGH].clue_target)
	var banked: Array = []
	for index in int(fire.clue_count):
		banked.append("fire-settled-%d" % (index + 1))
	fire.banked_chart_ids = banked
	state.relics = ["green_root_rune", "mist_root_rune", "fang_root_rune",
		"crown_root_rune", "pale_root_rune", "ember_root_rune"]
	state.threads = ["past_thread", "present_thread"]
	return CampaignData.normalize_campaign_state(state)

func _test_preinscribed_clue_rebind_order() -> void:
	var game := _new_runtime_game()
	game.campaign_state = _root_below_ready_state()
	game.trades.wayfinding = {"xp": 4200, "lv": 22}
	var charts: Array = []
	for index in 5:
		var preview := {
			"commit_ready": true, "recipe_id": "root_below",
			"output": {"template_id": "root_below", "name": "Root Below"},
			"wayfinding_level": 22,
			"campaign_state_snapshot": game.campaign_state.duplicate(true),
		}
		charts.append(ChartsData.materialize_chart(preview, 23000 + index))
	var return_order := [2, 0, 4, 1, 3]
	var rebound_rewards: Array = []
	var rebound_clues: Array = []
	var first_returned: Dictionary = {}
	for order_index in return_order.size():
		var chart: Dictionary = charts[return_order[order_index]]
		var rebound: Dictionary = game._freeze_campaign_clue(chart)
		if order_index == 0:
			first_returned = rebound.duplicate(true)
		rebound_rewards.append(int(rebound.get("authored_completion_xp", -1)))
		rebound_clues.append(String((rebound.get("campaign_clue", {}) as Dictionary)
			.get("clue_id", "")))
		var returned: Dictionary = CampaignData.record_successful_chart_return(
			game.campaign_state, "root_below",
			String(rebound.get("chart_instance_id", "")), 22, {})
		game.campaign_state = returned.state
	var duplicate: Dictionary = game._freeze_campaign_clue(first_returned)
	_check("distinct pre-inscribed Root Below Charts rebind exact rewards in either return order",
		rebound_rewards == [75, 75, 75, 75, 76]
			and rebound_clues == ["lost_waymark_1", "lost_waymark_2",
				"lost_waymark_3", "lost_waymark_4", "lost_waymark_5"],
		str({"order": return_order, "rewards": rebound_rewards,
			"clues": rebound_clues}))
	_check("the already-returned Chart ID cannot rebind or replay authored XP",
		not duplicate.has("authored_completion_xp")
			and (duplicate.get("campaign_clue", {}) as Dictionary).is_empty()
			and game._completion_xp_for_successful_return(duplicate)
				== ChartsData.legacy_completion_xp(duplicate), str(duplicate))
	game.free()
