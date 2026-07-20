extends SceneTree

const CampaignData = preload("res://data/campaign.gd")
const Progression = preload("res://data/progression.gd")
const DungeonGen = preload("res://scripts/dungeon_gen.gd")

var _pass := 0
var _fail := 0


func _check(label: String, condition: bool, detail = "") -> void:
	if condition:
		_pass += 1
		print("  ✓ %s" % label)
	else:
		_fail += 1
		print("  ✗ %s %s" % [label, str(detail)])


func _new_game() -> Node:
	var game: Node = load("res://scripts/game.gd").new()
	game._ready()
	game.persistence_enabled = false
	game.materials = {}
	game.campaign_state = CampaignData.empty_state()
	game.trades.wayfinding = {"xp": Progression.xp_for_level(17), "lv": 17}
	game.trades.wildcraft = {"xp": Progression.xp_for_level(17), "lv": 17}
	for chapter_id in [CampaignData.FIRST_KNOT, CampaignData.GOLDEN_WALLOW,
			CampaignData.SEVENTH_ROAD]:
		var chapter: Dictionary = game.campaign_state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
	game.campaign_state = CampaignData.normalize_campaign_state(game.campaign_state)
	for index in 4:
		var transition := CampaignData.record_successful_chart_return(
			game.campaign_state, "summit_approach", "approach-%d" % index, 17,
			game.materials)
		game.campaign_state = transition.state
	return game


func _queen_chart(chart_id: String) -> Dictionary:
	return {
		"recipe_id": CampaignData.QUEENS_SUMMIT_BOSS_RECIPE,
		"chart_instance_id": chart_id,
		"template_id": "summit_queen",
		"tier": 3,
		"scope": "summit",
		"seed": 1718,
		"affixes": [],
		"campaign_contract": CampaignData.boss_contract(
			CampaignData.QUEENS_SUMMIT_BOSS_RECIPE),
	}


func _init() -> void:
	print("--- Queen's Summit runtime ---")
	_test_refund_and_retry()
	_test_canonical_queen_settlement()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


func _test_refund_and_retry() -> void:
	var game := _new_game()
	game.materials = {"alpha_fang": 1}
	var chart := _queen_chart("queen-refund")
	var begun: Dictionary = game._begin_campaign_case_escrow(chart,
		{"seal_id": "alpha_fang"})
	game.campaign_state = begun.state
	chart = begun.chart
	game.materials.erase("alpha_fang")
	var entered: Dictionary = game._mark_campaign_chart_in_run(chart)
	game.campaign_state = entered.state
	chart = entered.chart
	var refunded: Dictionary = game._refund_campaign_attempt(chart)
	var repeated: Dictionary = game._refund_campaign_attempt(chart)
	_check("Queen abandon refunds one Alpha Fang and keeps a terminal tombstone",
		bool(refunded.get("changed", false))
			and not bool(repeated.get("changed", false))
			and game.material_count("alpha_fang") == 1
			and String(game.campaign_state.escrows[String(chart.attempt_id)].phase)
				== "refunded")
	var retry := _queen_chart("queen-retry")
	var retry_begun: Dictionary = game._begin_campaign_case_escrow(retry,
		{"seal_id": "alpha_fang"})
	_check("a refunded Queen attempt permits one fresh escrow identity",
		bool(retry_begun.get("ok", false))
			and String(retry_begun.chart.attempt_id) != String(chart.attempt_id))
	game.free()


func _test_canonical_queen_settlement() -> void:
	var game := _new_game()
	game.materials = {"alpha_fang": 1, "oath_nail": 3}
	var chart := _queen_chart("queen-clear")
	var begun: Dictionary = game._begin_campaign_case_escrow(chart,
		{"seal_id": "alpha_fang"})
	game.campaign_state = begun.state
	chart = begun.chart
	game.materials.erase("alpha_fang")
	var entered: Dictionary = game._mark_campaign_chart_in_run(chart)
	game.campaign_state = entered.state
	chart = entered.chart
	game.active_chart = chart
	var cfg: Dictionary = game.run_cfg()
	var layout := DungeonGen.generate(int(cfg.seed), cfg)
	game.active_chart = {}
	_check("only the immutable campaign contract forces the Summit Queen",
		String(cfg.get("boss_kind", "")) == "hedgemother_queen"
			and (cfg.get("campaign_contract", {}) as Dictionary) \
				== chart.campaign_contract
			and String(layout.get("bossKind", "")) == "hedgemother_queen"
			and (layout.get("handoff_contract", {}) as Dictionary).is_empty(), cfg)
	var settled: Dictionary = game.resolve_campaign_boss_death(chart)
	var duplicate: Dictionary = game.resolve_campaign_boss_death(chart)
	var view: Dictionary = game.campaign_settlement_view()
	_check("canonical Queen death settles Nail, Crown Rune, and Pale Stair once",
		bool(settled.get("changed", false))
			and not bool(duplicate.get("changed", false))
			and game.material_count("oath_nail") == 1
			and (game.campaign_state.relics as Array).has("crown_root_rune")
			and (game.campaign_state.restorations as Array).has("pale_stair")
			and bool(game.summit_cleared)
			and bool((view.chapters.queens_summit as Dictionary).visible))
	_check("the settled Oath Nail is reserved for the future Pale Oath",
		CampaignData.seal_use_allowed(game.campaign_state, "oath_nail",
			"pale_oath_boss")
			and not CampaignData.seal_use_allowed(game.campaign_state,
				"oath_nail", "queens_summit_boss"))
	game.free()
