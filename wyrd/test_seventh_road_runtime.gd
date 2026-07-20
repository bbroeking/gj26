extends SceneTree

# Game/Dungeon adapters for the authored Wolf chapter and the deliberately
# campaign-inert Summit Alpha Fang handoff.

const CampaignData = preload("res://data/campaign.gd")
const Progression = preload("res://data/progression.gd")
const DungeonGen = preload("res://scripts/dungeon_gen.gd")

var _pass := 0
var _fail := 0


func _check(name: String, ok: bool, detail = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % name)
	else:
		_fail += 1
		print("  ✗ %s %s" % [name, str(detail)])


func _new_game() -> Node:
	var game: Node = load("res://scripts/game.gd").new()
	game._ready()
	game.materials = {}
	game.campaign_state = CampaignData.empty_state()
	return game


func _set_level(game: Node, trade: String, level: int) -> void:
	game.trades[trade] = {"xp": Progression.xp_for_level(level), "lv": level}


func _clear_prior_chapters(state: Dictionary) -> void:
	for chapter_id in [CampaignData.FIRST_KNOT, CampaignData.GOLDEN_WALLOW]:
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
		chapter.cleared = true


func _wolf_chart(chart_id: String) -> Dictionary:
	return {
		"recipe_id": CampaignData.SEVENTH_ROAD_BOSS_RECIPE,
		"chart_instance_id": chart_id,
		"template_id": "briar",
		"tier": 2,
		"scope": "briar",
		"seed": 1501,
		"affixes": [],
		"campaign_contract": CampaignData.boss_contract(
			CampaignData.SEVENTH_ROAD_BOSS_RECIPE),
	}


func _summit_chart(chart_id: String) -> Dictionary:
	return {
		"recipe_id": "queens_summit",
		"chart_instance_id": chart_id,
		"template_id": "summit",
		"tier": 3,
		"scope": "summit",
		"seed": 1701,
		"affixes": [],
		"handoff_contract": CampaignData.handoff_contract("queens_summit"),
	}


func _install_frozen_handoff(game: Node, chart: Dictionary,
		attempt_number: int) -> Dictionary:
	var out := chart.duplicate(true)
	var attempt_id := "%s-%d" % [CampaignData.LEGACY_SUMMIT_HANDOFF,
		attempt_number]
	var state := CampaignData.normalize_campaign_state(game.campaign_state)
	state.escrows[attempt_id] = {
		"attempt_id": attempt_id,
		"chart_instance_id": String(out.chart_instance_id),
		"kind": "handoff",
		"contract_id": CampaignData.LEGACY_SUMMIT_HANDOFF,
		"phase": "case",
		"items": {"alpha_fang": 1},
	}
	state.next_attempt_id = maxi(int(state.next_attempt_id), attempt_number + 1)
	game.campaign_state = CampaignData.normalize_campaign_state(state)
	out["attempt_id"] = attempt_id
	return out


func _init() -> void:
	print("--- Seventh Road Game/runtime adapters ---")
	_test_mothglow_gate_and_clues()
	_test_wolf_contract_and_settlement()
	_test_handoff_refund_and_consumption()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


func _test_mothglow_gate_and_clues() -> void:
	var game := _new_game()
	_set_level(game, "wayfinding", 15)
	_set_level(game, "wildcraft", 13)
	_clear_prior_chapters(game.campaign_state)
	game.materials = {"mothmint": 2, "hedge_ink": 1}
	var before: Dictionary = game.materials.duplicate(true)
	var locked: Dictionary = game.try_pot_mix(before)
	_check("Mothglow exact pot stays intact below Wildcraft 14",
		String(locked.get("outcome", "")) == "locked"
		and int(locked.get("required_wildcraft", 0)) == 14
		and game.materials == before)
	_set_level(game, "wildcraft", 14)
	var mixed: Dictionary = game.try_pot_mix(before)
	_check("Wildcraft 14 discovers Mothglow through production mixing",
		String(mixed.get("outcome", "")) == "discovery"
		and game.material_count("mothglow_ink") == 1)
	var first_chart := {"recipe_id": "briar_maze", "template_id": "briar",
		"chart_instance_id": "briar-1", "seed": 1301, "affixes": []}
	var frozen_chart: Dictionary = game._freeze_campaign_clue(first_chart)
	game.active_chart = frozen_chart
	var clue: Dictionary = game.run_cfg().get("campaign_clue", {})
	# A replicated Chart remains the generation authority even if this peer's
	# local campaign ledger points at a different clue.
	(game.campaign_state.chapters[CampaignData.SEVENTH_ROAD] as Dictionary).clue_count = 3
	var frozen_again: Dictionary = game.run_cfg().get("campaign_clue", {})
	(game.campaign_state.chapters[CampaignData.SEVENTH_ROAD] as Dictionary).clue_count = 0
	game.active_chart = {}
	for index in 4:
		var chart := first_chart.duplicate(true)
		chart.chart_instance_id = "briar-%d" % (index + 1)
		game._record_campaign_chart_return(chart)
	_check("four distinct Briar returns bank four authored Cold Tracks",
		String(clue.get("clue_id", "")) == "seventh_road_cold_track_1"
		and frozen_again == clue
		and String(clue.get("presentation", "")) == "cold_track_clue"
		and CampaignData.chapter_clue_count(game.campaign_state,
			CampaignData.SEVENTH_ROAD) == 4
		and game.material_count("wightpelt") == 1)
	game.free()


func _test_wolf_contract_and_settlement() -> void:
	var game := _new_game()
	_set_level(game, "wayfinding", 15)
	_set_level(game, "wildcraft", 14)
	_clear_prior_chapters(game.campaign_state)
	(game.campaign_state.chapters[CampaignData.SEVENTH_ROAD] as Dictionary) \
		.clue_count = 4
	game.materials["wightpelt"] = 1
	game.materials["alpha_fang"] = 3
	var chart := _wolf_chart("seventh-clear")
	var case_result: Dictionary = game._begin_campaign_case_escrow(chart,
		{"seal_id": "wightpelt"})
	game.campaign_state = case_result.state
	chart = case_result.chart
	game.materials.erase("wightpelt")
	var run_result: Dictionary = game._mark_campaign_chart_in_run(chart)
	game.campaign_state = run_result.state
	chart = run_result.chart
	game.active_chart = chart
	var cfg: Dictionary = game.run_cfg()
	var layout := DungeonGen.generate(int(cfg.get("seed", -1)), cfg)
	game.active_chart = {}
	_check("Wolf contract survives Game and generator as a forced boss",
		String(cfg.get("boss_kind", "")) == "wolf_alpha"
		and (cfg.get("campaign_contract", {}) as Dictionary) == chart.campaign_contract
		and String(layout.get("bossKind", "")) == "wolf_alpha",
		cfg)
	var cleared: Dictionary = game.resolve_campaign_boss_death(chart)
	var repeated: Dictionary = game.resolve_campaign_boss_death(chart)
	_check("real Wolf resolver settles Fang, Rune, and Archive exactly once",
		bool(cleared.get("changed", false))
		and not bool(repeated.get("changed", false))
		and game.material_count("alpha_fang") == 1
		and (game.campaign_state.relics as Array).has("fang_root_rune")
		and (game.campaign_state.restorations as Array).has("skald_archive"))
	_check("Wolf settlement unlocks only the real Archive Summit source",
		(game.chart_source_unlocks as Array).has("skald_queens_summit")
		and not bool(game.summit_cleared))
	game.free()


func _test_handoff_refund_and_consumption() -> void:
	var game := _new_game()
	_set_level(game, "wayfinding", 17)
	var chart := _install_frozen_handoff(game,
		_summit_chart("summit-refund"), 40)
	var run_result: Dictionary = game._mark_campaign_chart_in_run(chart)
	game.campaign_state = run_result.state
	chart = run_result.chart
	var refund: Dictionary = game._refund_campaign_attempt(chart)
	var duplicate_refund: Dictionary = game._refund_campaign_attempt(chart)
	_check("Summit handoff abandon refunds Alpha Fang once",
		bool(refund.get("changed", false))
		and not bool(duplicate_refund.get("changed", false))
		and game.material_count("alpha_fang") == 1
		and String(game.campaign_state.escrows[String(chart.attempt_id)].phase)
			== "refunded")
	var retry := _install_frozen_handoff(game,
		_summit_chart("summit-consume"), 41)
	game.materials.erase("alpha_fang")
	var retry_run: Dictionary = game._mark_campaign_chart_in_run(retry)
	game.campaign_state = retry_run.state
	retry = retry_run.chart
	game.active_chart = retry
	var cfg: Dictionary = game.run_cfg()
	var layout := DungeonGen.generate(int(cfg.get("seed", -1)), cfg)
	game.active_chart = {}
	_check("Summit handoff freezes the Queen without a campaign contract",
		String(cfg.get("boss_kind", "")) == "hedgemother_queen"
		and (cfg.get("handoff_contract", {}) as Dictionary) == retry.handoff_contract
		and String(layout.get("bossKind", "")) == "hedgemother_queen"
		and (layout.get("campaign_contract", {}) as Dictionary).is_empty())
	var consumed: Dictionary = game.resolve_handoff_boss_death(retry)
	var repeated: Dictionary = game.resolve_handoff_boss_death(retry)
	_check("Queen death consumes the handoff once and mints no campaign truth",
		bool(consumed.get("changed", false))
		and not bool(repeated.get("changed", false))
		and String(game.campaign_state.escrows[String(retry.attempt_id)].phase)
			== "consumed"
		and not CampaignData.chapter_cleared(game.campaign_state,
			CampaignData.SEVENTH_ROAD)
		and not (game.campaign_state.relics as Array).has("crown_root_rune")
		and not bool(game.summit_cleared))
	game.free()
