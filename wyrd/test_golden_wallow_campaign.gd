extends SceneTree

# Golden Wallow pure-domain contract.  No Game, scene, save, or networking
# adapter participates here: this locks the two-chapter state machine before
# runtime/content wiring consumes it.

const CampaignData = preload("res://data/campaign.gd")

var _pass := 0
var _fail := 0

func _check(label: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
		print("  x %s %s" % [label, detail])

func _first_knot_cleared() -> Dictionary:
	var state := CampaignData.empty_state()
	var chapter: Dictionary = state.chapters[CampaignData.FIRST_KNOT]
	chapter.cleared = true
	chapter.clue_count = 3
	state.relics = ["green_root_rune"]
	state.restorations = ["trophy_hall"]
	return CampaignData.normalize_campaign_state(state)

func _run() -> void:
	print("--- Golden Wallow campaign domain ---")
	_test_descriptor_and_migration()
	_test_clue_ledger_and_boss_contract()
	_test_escrow_and_settlement()
	_test_seal_policy_and_projection()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _init() -> void:
	call_deferred("_run")

func _test_descriptor_and_migration() -> void:
	var fresh := CampaignData.empty_state()
	_check("authored chapters start empty in authored order",
		fresh.chapters.keys() == [CampaignData.FIRST_KNOT,
			CampaignData.GOLDEN_WALLOW, CampaignData.SEVENTH_ROAD,
			CampaignData.QUEENS_SUMMIT, CampaignData.PALE_OATH,
			CampaignData.FIRE_IN_THE_BOUGH, CampaignData.UNWRITTEN_ROAD]
		and CampaignData.chapter_for_recipe("sallow_shallows") == CampaignData.GOLDEN_WALLOW
		and CampaignData.chapter_for_recipe("golden_wallow_boss") == CampaignData.GOLDEN_WALLOW
		and CampaignData.chapter_for_recipe("mire") == "")
	var legacy: Dictionary = CampaignData.infer_legacy_clear(
		fresh, {"wightpelt": {"slot": 1}}, true).state
	_check("legacy proof can infer only First Knot, never Golden Wallow",
		CampaignData.chapter_cleared(legacy, CampaignData.FIRST_KNOT)
		and not CampaignData.chapter_cleared(legacy, CampaignData.GOLDEN_WALLOW)
		and CampaignData.chapter_clue_count(legacy, CampaignData.GOLDEN_WALLOW) == 0)
	var normalized := CampaignData.normalize_campaign_state({
		"chapters": {CampaignData.FIRST_KNOT: {"clue_count": 2},
			CampaignData.GOLDEN_WALLOW: {"clue_count": 1,
				"banked_chart_ids": ["shallow-a"]}},
		"relics": ["green_root_rune", "mist_root_rune", "invented"],
		"restorations": ["trophy_hall", "sallow_jetty", "invented"],
	})
	_check("normalization preserves both explicit chapter records and filters authored awards",
		normalized.chapters.first_knot.banked_chart_ids == ["legacy-banked-first-knot-1", "legacy-banked-first-knot-2"]
		and normalized.chapters.golden_wallow.banked_chart_ids == ["shallow-a"]
		and normalized.relics == ["green_root_rune", "mist_root_rune"]
		and normalized.restorations == ["trophy_hall", "sallow_jetty"])

func _test_clue_ledger_and_boss_contract() -> void:
	var blocked := CampaignData.next_clue_for_chart(CampaignData.empty_state(),
		"sallow_shallows", "shallow-a", 9)
	_check("Golden clues require a cleared First Knot", blocked.is_empty())
	var state := _first_knot_cleared()
	var first := CampaignData.record_successful_chart_return(state,
		"sallow_shallows", "shallow-a", 9, {})
	var duplicate := CampaignData.record_successful_chart_return(first.state,
		"sallow_shallows", "shallow-a", 12, {})
	var wrong_recipe := CampaignData.record_successful_chart_return(first.state,
		"sallow_mire", "mire-a", 12, {})
	var second := CampaignData.record_successful_chart_return(first.state,
		"sallow_shallows", "shallow-b", 9, {})
	var third := CampaignData.record_successful_chart_return(second.state,
		"sallow_shallows", "shallow-c", 9, {})
	_check("three distinct Shallows returns bank stable Gilt Bristles once",
		String(first.clue_id) == "gilt_bristle_1"
		and not bool(duplicate.changed) and not bool(wrong_recipe.changed)
		and String(second.clue_id) == "gilt_bristle_2"
		and String(third.clue_id) == "gilt_bristle_3"
		and third.material_awards == {"tusker_tusk": 1}
		and CampaignData.chapter_clue_count(third.state, CampaignData.GOLDEN_WALLOW) == 3)
	_check("Golden Boss Chart is level-gated and forced to the Burrow Boar",
		not CampaignData.can_inscribe_boss(third.state, "golden_wallow_boss", 11)
		and CampaignData.can_inscribe_boss(third.state, "golden_wallow_boss", 12)
		and CampaignData.boss_contract("golden_wallow_boss") == {
			"chapter_id": CampaignData.GOLDEN_WALLOW, "boss_kind": "burrow_boar",
			"seal_id": "tusker_tusk", "guaranteed": true,
			"escrow_items": {"tusker_tusk": 1},
		})

func _test_escrow_and_settlement() -> void:
	var state := _first_knot_cleared()
	for id in ["shallow-a", "shallow-b", "shallow-c"]:
		state = CampaignData.record_successful_chart_return(state,
			"sallow_shallows", id, 9, {}).state
	var begun := CampaignData.begin_boss_escrow(state, "golden-chart-a",
		CampaignData.GOLDEN_WALLOW)
	var entered := CampaignData.mark_escrow_in_run(begun.state, begun.attempt_id,
		"golden-chart-a", CampaignData.GOLDEN_WALLOW)
	var refunded := CampaignData.refund_escrow(entered.state, begun.attempt_id,
		"golden-chart-a", CampaignData.GOLDEN_WALLOW)
	var recovered := CampaignData.recover_unresolved_in_run(entered.state)
	_check("Golden case/in-run/refund and crash recovery preserve exact Tusker escrow",
		bool(begun.ok) and String(begun.attempt_id) == "golden_wallow-1"
		and bool(entered.changed) and refunded.material_refunds == {"tusker_tusk": 1}
		and recovered.material_refunds == {"tusker_tusk": 1}
		and String(recovered.state.escrows[begun.attempt_id].phase) == "refunded")
	var retry := CampaignData.begin_boss_escrow(refunded.state, "golden-chart-b",
		CampaignData.GOLDEN_WALLOW)
	var retry_entered := CampaignData.mark_escrow_in_run(retry.state, retry.attempt_id,
		"golden-chart-b", CampaignData.GOLDEN_WALLOW)
	var settled := CampaignData.resolve_boss_death(retry_entered.state, retry.attempt_id,
		"golden-chart-b", CampaignData.GOLDEN_WALLOW)
	var settled_again := CampaignData.resolve_boss_death(settled.state, retry.attempt_id,
		"golden-chart-b", CampaignData.GOLDEN_WALLOW)
	_check("Golden Boar death settles Wightpelt, Mist Rune, and Jetty exactly once",
		settled.material_awards == {"wightpelt": 1}
		and settled.relic_awards == ["mist_root_rune"]
		and settled.restoration_awards == ["sallow_jetty"]
		and CampaignData.chapter_cleared(settled.state, CampaignData.GOLDEN_WALLOW)
		and bool(settled_again.ok) and not bool(settled_again.changed))

func _test_seal_policy_and_projection() -> void:
	var first_pending := CampaignData.empty_state()
	(first_pending.chapters.first_knot as Dictionary).clue_count = 3
	_check("pending First Knot seal rejects newly committed legacy routes",
		not CampaignData.seal_use_allowed(first_pending, "thorn_essence", "tier_1")
		and CampaignData.seal_use_allowed(first_pending, "thorn_essence", "first_knot_boss"))
	var golden_pending := _first_knot_cleared()
	for id in ["shallow-a", "shallow-b", "shallow-c"]:
		golden_pending = CampaignData.record_successful_chart_return(golden_pending,
			"sallow_shallows", id, 9, {}).state
	_check("pending Golden Tusker can only seal the Wallow",
		not CampaignData.seal_use_allowed(golden_pending, "tusker_tusk", "mire")
		and CampaignData.seal_use_allowed(golden_pending, "tusker_tusk", "golden_wallow_boss"))
	var cleared := golden_pending
	var begun := CampaignData.begin_boss_escrow(cleared, "settlement-chart", CampaignData.GOLDEN_WALLOW)
	var entered := CampaignData.mark_escrow_in_run(begun.state, begun.attempt_id,
		"settlement-chart", CampaignData.GOLDEN_WALLOW)
	cleared = CampaignData.resolve_boss_death(entered.state, begun.attempt_id,
		"settlement-chart", CampaignData.GOLDEN_WALLOW).state
	var view := CampaignData.settlement_view(cleared, {"guest": true})
	_check("settlement projection is read-only and exposes Golden Jetty truth",
		bool((view.golden_wallow as Dictionary).visible)
		and bool((view.golden_wallow as Dictionary).relic_visible)
		and String((view.golden_wallow as Dictionary).restoration_id) == "sallow_jetty"
		and bool((view.golden_wallow as Dictionary).guest)
		and not bool(((view.golden_wallow as Dictionary).debrief_event as Dictionary).available))
	_check("campaign-awarded Wightpelt stays reserved for Seventh Road",
		not CampaignData.seal_use_allowed(cleared, "wightpelt", "wolf_alpha_den")
		and CampaignData.seal_use_allowed(cleared, "wightpelt", "seventh_road_boss"))
