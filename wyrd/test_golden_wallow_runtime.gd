extends SceneTree

# Focused Game-adapter contract for the second authored campaign chapter.
# Domain detail belongs in Campaign; this suite proves Game neither hard-codes
# First Knot semantics nor lets legacy/forged paths settle Golden Wallow.

const CampaignData = preload("res://data/campaign.gd")
const Progression = preload("res://data/progression.gd")

var _pass := 0
var _fail := 0

func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % name)
	else:
		_fail += 1
		print("  ✗ %s %s" % [name, detail])

func _new_game() -> Node:
	var game: Node = load("res://scripts/game.gd").new()
	game._ready() # WYRD_NO_SAVE keeps this isolated from the real save.
	game.materials = {}
	game.campaign_state = CampaignData.empty_state()
	return game

func _level(game: Node, level: int) -> void:
	game.trades.wayfinding = {"xp": Progression.xp_for_level(level), "lv": level}

func _clear_first_knot(state: Dictionary) -> void:
	var first: Dictionary = state.chapters[CampaignData.FIRST_KNOT]
	first.clue_count = 3
	first.cleared = true

func _golden_chart(chart_id: String) -> Dictionary:
	return {
		"recipe_id": CampaignData.GOLDEN_WALLOW_BOSS_RECIPE,
		"chart_instance_id": chart_id,
		"template_id": "mire",
		"seed": 1201,
		"affixes": [],
		"campaign_contract": CampaignData.boss_contract(
			CampaignData.GOLDEN_WALLOW_BOSS_RECIPE),
	}

func _first_chart(chart_id: String) -> Dictionary:
	return {
		"recipe_id": CampaignData.FIRST_KNOT_BOSS_RECIPE,
		"chart_instance_id": chart_id,
		"template_id": "tier_1",
		"seed": 801,
		"affixes": [],
		"campaign_contract": CampaignData.boss_contract(
			CampaignData.FIRST_KNOT_BOSS_RECIPE),
	}

func _init() -> void:
	print("--- Golden Wallow Game runtime adapter ---")
	_test_mire_ink_trade_gate()
	_test_host_clue_returns_and_seal_guard()
	_test_boss_settlement_and_legacy_inertia()
	_test_refund_and_recovery()
	_test_first_knot_wrapper_remains_valid()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _test_mire_ink_trade_gate() -> void:
	print("[Mire Ink Wildcraft gate]")
	var game := _new_game()
	var inputs := {"bittergrass": 1, "mothmint": 1, "hedge_ink": 1}
	game.materials = inputs.duplicate(true)
	game.trades.wildcraft = {"xp": Progression.xp_for_level(9), "lv": 9}
	var before: Dictionary = game.materials.duplicate(true)
	var locked: Dictionary = game.try_pot_mix(inputs)
	_check("exact Mire Ink pot waits intact below Wildcraft 10",
		String(locked.get("outcome", "")) == "locked"
		and int(locked.get("required_wildcraft", 0)) == 10
		and game.materials == before and not game.ink_discovered("mire_ink"))
	game.trades.wildcraft = {"xp": Progression.xp_for_level(10), "lv": 10}
	var mixed: Dictionary = game.try_pot_mix(inputs)
	_check("Wildcraft 10 discovers Mire Ink and spends its exact makings",
		String(mixed.get("outcome", "")) == "discovery"
		and game.ink_discovered("mire_ink") and game.material_count("mire_ink") == 1
		and game.material_count("bittergrass") == 0
		and game.material_count("mothmint") == 0
		and game.material_count("hedge_ink") == 0)
	game.free()

func _test_host_clue_returns_and_seal_guard() -> void:
	print("[Golden clue returns + Seal guard]")
	var game := _new_game()
	_level(game, 12)
	_clear_first_knot(game.campaign_state)
	var shallow := {"recipe_id": "sallow_shallows", "template_id": "mire",
		"chart_instance_id": "shallows-1", "seed": 901, "affixes": []}
	var cfg_before: Dictionary
	game.active_chart = shallow
	cfg_before = game.run_cfg()
	game.active_chart = {}
	game._record_campaign_chart_return(shallow)
	var after_one := CampaignData.campaign_fingerprint(game.campaign_state)
	game._record_campaign_chart_return(shallow)
	var wrong := shallow.duplicate(true)
	wrong.recipe_id = "sallow_mire"
	wrong.chart_instance_id = "shallows-wrong"
	game._record_campaign_chart_return(wrong)
	var after_inert_returns := CampaignData.campaign_fingerprint(game.campaign_state)
	var shallow_two := shallow.duplicate(true)
	shallow_two.chart_instance_id = "shallows-2"
	var shallow_three := shallow.duplicate(true)
	shallow_three.chart_instance_id = "shallows-3"
	game._record_campaign_chart_return(shallow_two)
	game._record_campaign_chart_return(shallow_three)
	_check("host-only policy rejects a guest settlement",
		not game.campaign_settlement_allowed(true, false))
	_check("Sallow Shallows publishes the next Gilt Bristle without mutation",
		String((cfg_before.get("campaign_clue", {}) as Dictionary).get("clue_id", ""))
			== "gilt_bristle_1"
		and CampaignData.chapter_clue_count(CampaignData.empty_state(),
			CampaignData.GOLDEN_WALLOW) == 0)
	_check("wrong and repeated Shallows returns are inert",
		CampaignData.chapter_clue_count(game.campaign_state,
			CampaignData.GOLDEN_WALLOW) == 3
		and after_one == after_inert_returns)
	_check("third distinct return supplies one missing Tusker and Golden rumour",
		game.material_count("tusker_tusk") == 1
		and (game.chart_recipe_journal.rumours as Array).has(
			CampaignData.GOLDEN_WALLOW_RUMOUR))
	var forbidden_legacy := {"recipe_id": "green_hollow", "template_id": "tier_1",
		"chart_instance_id": "forged-tusk-use", "seed": 902, "affixes": []}
	var forbidden: Dictionary = game._begin_campaign_case_escrow(forbidden_legacy,
		{"seal_id": "tusker_tusk"})
	_check("pending Tusker cannot commit to a legacy road",
		not bool(forbidden.get("ok", false))
		and CampaignData.seal_use_allowed(game.campaign_state, "tusker_tusk",
			"golden_wallow_boss"))
	game.add_chart({"recipe_id": "green_hollow", "seal_id": "tusker_tusk",
		"template_id": "tier_1", "seed": 904, "affixes": []})
	_check("direct compatibility add cannot bypass the pending Tusker guard",
		game.charts.is_empty())
	game.free()

func _test_boss_settlement_and_legacy_inertia() -> void:
	print("[Golden Boss settlement]")
	var game := _new_game()
	_level(game, 12)
	_clear_first_knot(game.campaign_state)
	var golden: Dictionary = game.campaign_state.chapters[CampaignData.GOLDEN_WALLOW]
	golden.clue_count = 3
	game.materials["tusker_tusk"] = 1
	var chart := _golden_chart("golden-clear")
	var case_result: Dictionary = game._begin_campaign_case_escrow(chart,
		{"seal_id": "tusker_tusk"})
	game.campaign_state = case_result.state
	chart = case_result.chart
	game.materials.erase("tusker_tusk")
	var run_result: Dictionary = game._mark_campaign_chart_in_run(chart)
	game.campaign_state = run_result.state
	chart = run_result.chart
	game.active_chart = chart
	var cfg: Dictionary = game.run_cfg()
	game.active_chart = {}
	var clear_result: Dictionary = game.resolve_campaign_boss_death(chart)
	var duplicate: Dictionary = game.resolve_campaign_boss_death(chart)
	_check("Golden Boss config forces Burrow Boar from immutable contract",
		String(cfg.get("boss_kind", "")) == "burrow_boar"
		and (cfg.get("campaign_contract", {}) as Dictionary) == chart.campaign_contract)
	_check("Golden boss death awards Wightpelt, Mist Rune, and Jetty exactly once",
		bool(clear_result.get("changed", false))
		and game.material_count("wightpelt") == 1
		and (game.campaign_state.relics as Array).has("mist_root_rune")
		and (game.campaign_state.restorations as Array).has("sallow_jetty")
		and not bool(duplicate.get("changed", false)))
	_check("settled Wightpelt is reserved for Seventh Road, not a legacy Wolf Chart",
		not CampaignData.seal_use_allowed(game.campaign_state, "wightpelt",
			"legacy_wolf_chart"))
	var settled := CampaignData.campaign_fingerprint(game.campaign_state)
	var legacy_boor := {"template_id": "mire", "seed": 903,
		"affixes": [{"id": "burrow_boar_den", "good": true}]}
	var legacy_run: Dictionary = game._mark_campaign_chart_in_run(legacy_boor)
	var legacy_death: Dictionary = game.resolve_campaign_boss_death(legacy_boor)
	_check("legacy Boar stays playable and campaign-inert",
		bool(legacy_run.get("ok", false)) and not legacy_run.chart.has("attempt_id")
		and String(legacy_death.get("reason", "")) == "not_campaign_boss"
		and CampaignData.campaign_fingerprint(game.campaign_state) == settled)
	game.free()

func _test_refund_and_recovery() -> void:
	print("[Golden escrow refund + recovery]")
	var game := _new_game()
	_level(game, 12)
	_clear_first_knot(game.campaign_state)
	var golden: Dictionary = game.campaign_state.chapters[CampaignData.GOLDEN_WALLOW]
	golden.clue_count = 3
	game.materials["tusker_tusk"] = 1
	var chart := _golden_chart("golden-refund")
	var case_result: Dictionary = game._begin_campaign_case_escrow(chart,
		{"seal_id": "tusker_tusk"})
	game.campaign_state = case_result.state
	chart = case_result.chart
	game.materials.erase("tusker_tusk")
	var run_result: Dictionary = game._mark_campaign_chart_in_run(chart)
	game.campaign_state = run_result.state
	chart = run_result.chart
	var refund: Dictionary = game._refund_campaign_attempt(chart)
	var repeated_refund: Dictionary = game._refund_campaign_attempt(chart)
	_check("Golden abandon refunds Tusker once and leaves Mire Ink spent",
		bool(refund.get("changed", false)) and game.material_count("tusker_tusk") == 1
		and not bool(repeated_refund.get("changed", false))
		and String(game.campaign_state.escrows[String(chart.attempt_id)].phase) == "refunded")
	var recovery_chart := _golden_chart("golden-recovery")
	var recovery_case: Dictionary = game._begin_campaign_case_escrow(recovery_chart,
		{"seal_id": "tusker_tusk"})
	game.campaign_state = recovery_case.state
	recovery_chart = recovery_case.chart
	game.materials.erase("tusker_tusk")
	var recovery_run: Dictionary = game._mark_campaign_chart_in_run(recovery_chart)
	game.campaign_state = recovery_run.state
	var recovered: Dictionary = game.reconcile_unresumable_campaign_attempts()
	_check("Golden interrupted run recovers one Tusker terminal tombstone",
		bool(recovered.get("changed", false)) and game.material_count("tusker_tusk") == 1
		and String(game.campaign_state.escrows[String(recovery_chart.attempt_id)].phase)
			== "refunded")
	game.free()

func _test_first_knot_wrapper_remains_valid() -> void:
	print("[First Knot compatibility]")
	var game := _new_game()
	_level(game, 8)
	var first: Dictionary = game.campaign_state.chapters[CampaignData.FIRST_KNOT]
	first.clue_count = 3
	game.materials["thorn_essence"] = 1
	var chart := _first_chart("first-regression")
	var case_result: Dictionary = game._begin_campaign_case_escrow(chart,
		{"seal_id": "thorn_essence"})
	game.campaign_state = case_result.state
	chart = case_result.chart
	var run_result: Dictionary = game._mark_campaign_chart_in_run(chart)
	game.campaign_state = run_result.state
	chart = run_result.chart
	var clear_result: Dictionary = game.resolve_campaign_boss_death(chart)
	_check("First Knot still uses its original boss wrapper and settlement",
		bool(case_result.get("ok", false)) and bool(run_result.get("ok", false))
		and bool(clear_result.get("changed", false))
		and CampaignData.chapter_cleared(game.campaign_state, CampaignData.FIRST_KNOT)
		and (game.campaign_state.restorations as Array).has("trophy_hall"))
	game.free()
