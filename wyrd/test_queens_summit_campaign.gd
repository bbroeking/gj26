extends SceneTree

# Pure Queen's Summit campaign-domain contract.  Runtime, Table, save,
# networking, Town, and inventory each adapt these records elsewhere.

const CampaignData = preload("res://data/campaign.gd")

var _pass := 0
var _fail := 0

func _check(label: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
		print("  x %s %s" % [label, detail])

func _seventh_cleared() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id in [CampaignData.FIRST_KNOT, CampaignData.GOLDEN_WALLOW,
		CampaignData.SEVENTH_ROAD]:
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
	state.relics = ["green_root_rune", "mist_root_rune", "fang_root_rune"]
	state.restorations = ["trophy_hall", "sallow_jetty", "skald_archive"]
	return CampaignData.normalize_campaign_state(state)

func _queen_ready() -> Dictionary:
	var state := _seventh_cleared()
	for index in 4:
		state = CampaignData.record_successful_chart_return(state,
			"summit_approach", "approach-%d" % (index + 1), 16, {}).state
	return state

func _legacy_handoff(phase: String = "in_run") -> Dictionary:
	return {
		"version": 2,
		"next_attempt_id": 4,
		"escrows": {
			"legacy_summit_handoff-3": {
				"chart_instance_id": "frozen-summit",
				"kind": "handoff",
				"contract_id": CampaignData.LEGACY_SUMMIT_HANDOFF,
				"phase": phase,
			},
		},
	}

func _run() -> void:
	print("--- Queen's Summit campaign domain ---")
	_test_descriptor_and_v3_migration()
	_test_crown_thorn_ledger_and_contract()
	_test_queen_escrow_settlement_and_seal_policy()
	_test_legacy_handoff_exclusion_and_credit()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _init() -> void:
	call_deferred("_run")

func _test_descriptor_and_v3_migration() -> void:
	var fresh := CampaignData.empty_state()
	_check("v6 preserves the authored Queen chapter through the Unwritten Road",
		int(fresh.version) == 6
		and fresh.chapters.keys() == [CampaignData.FIRST_KNOT,
			CampaignData.GOLDEN_WALLOW, CampaignData.SEVENTH_ROAD,
			CampaignData.QUEENS_SUMMIT, CampaignData.PALE_OATH,
			CampaignData.FIRE_IN_THE_BOUGH, CampaignData.UNWRITTEN_ROAD]
		and fresh.chapters.queens_summit == {"clue_count": 0,
			"cleared": false, "banked_chart_ids": []}
		and fresh.chapters.pale_oath == {"clue_count": 0,
			"cleared": false, "banked_chart_ids": []}
		and fresh.chapters.fire_in_the_bough == {"clue_count": 0,
			"cleared": false, "banked_chart_ids": []}
		and fresh.chapters.unwritten_road == {"clue_count": 0,
			"cleared": false, "banked_chart_ids": []}
		and fresh.threads == []
		and CampaignData.chapter_for_recipe("summit_approach") == CampaignData.QUEENS_SUMMIT
		and CampaignData.chapter_for_recipe("queens_summit_boss") == CampaignData.QUEENS_SUMMIT
		and CampaignData.chapter_for_recipe("queens_summit") == "")
	var migrated := CampaignData.normalize_campaign_state({
		"version": 2,
		"chapters": {
			CampaignData.SEVENTH_ROAD: {"clue_count": 4, "cleared": true,
				"banked_chart_ids": ["briar-1", "briar-2", "briar-3", "briar-4"]},
		},
		"relics": ["fang_root_rune", "invented"],
		"restorations": ["skald_archive", "invented"],
	})
	_check("v2 to v6 normalization preserves Queen truth and adds inert later states",
		int(migrated.version) == 6
		and bool(migrated.chapters.seventh_road.cleared)
		and migrated.chapters.queens_summit == {"clue_count": 0,
			"cleared": false, "banked_chart_ids": []}
		and migrated.chapters.pale_oath == {"clue_count": 0,
			"cleared": false, "banked_chart_ids": []}
		and migrated.chapters.fire_in_the_bough == {"clue_count": 0,
			"cleared": false, "banked_chart_ids": []}
		and migrated.chapters.unwritten_road == {"clue_count": 0,
			"cleared": false, "banked_chart_ids": []}
		and migrated.threads == []
		and migrated.relics == ["fang_root_rune"]
		and migrated.restorations == ["skald_archive"]
		and not bool(migrated.legacy_summit_alpha_fang_credit)
		and CampaignData.normalize_campaign_state(migrated) == migrated)
	var no_queen_truth: Dictionary = CampaignData.infer_legacy_clear(CampaignData.empty_state(),
		{"alpha_fang": {}, "oath_nail": {}}, true).state
	_check("summit flags, loose seals, old charts, and legacy deaths never infer Queen truth",
		not CampaignData.chapter_cleared(no_queen_truth, CampaignData.QUEENS_SUMMIT)
		and CampaignData.chapter_clue_count(no_queen_truth, CampaignData.QUEENS_SUMMIT) == 0
		and not (no_queen_truth.relics as Array).has("crown_root_rune")
		and not (no_queen_truth.restorations as Array).has("pale_stair"))

func _test_crown_thorn_ledger_and_contract() -> void:
	var blocked_prerequisite := CampaignData.next_clue_for_chart(
		CampaignData.empty_state(), "summit_approach", "approach-1", 16)
	var state := _seventh_cleared()
	var blocked_level := CampaignData.next_clue_for_chart(state,
		"summit_approach", "approach-1", 15)
	var first := CampaignData.record_successful_chart_return(state,
		"summit_approach", "approach-1", 16, {})
	var duplicate := CampaignData.record_successful_chart_return(first.state,
		"summit_approach", "approach-1", 23, {})
	var second := CampaignData.record_successful_chart_return(first.state,
		"summit_approach", "approach-2", 16, {})
	var third := CampaignData.record_successful_chart_return(second.state,
		"summit_approach", "approach-3", 16, {})
	var fourth := CampaignData.record_successful_chart_return(third.state,
		"summit_approach", "approach-4", 16, {})
	_check("four distinct Crownward returns bank only the four Shed Crown-Thorns",
		blocked_prerequisite.is_empty() and blocked_level.is_empty()
		and String(first.clue_id) == "shed_crown_thorn_1"
		and String(second.clue_id) == "shed_crown_thorn_2"
		and String(third.clue_id) == "shed_crown_thorn_3"
		and String(fourth.clue_id) == "shed_crown_thorn_4"
		and String(CampaignData.CHAPTERS[CampaignData.QUEENS_SUMMIT].clue_presentation)
			== "shed_crown_thorn"
		and not bool(duplicate.changed)
		and fourth.rumour_ids == [CampaignData.QUEENS_SUMMIT_RUMOUR]
		and (fourth.material_awards as Dictionary).is_empty()
		and CampaignData.chapter_clue_count(fourth.state, CampaignData.QUEENS_SUMMIT) == 4)
	_check("Queen contract is exact and is gated at Wayfinding 17",
		not CampaignData.can_inscribe_boss(fourth.state, "queens_summit_boss", 16)
		and CampaignData.can_inscribe_boss(fourth.state, "queens_summit_boss", 17)
		and CampaignData.boss_contract("queens_summit_boss") == {
			"chapter_id": CampaignData.QUEENS_SUMMIT,
			"boss_kind": "hedgemother_queen", "seal_id": "alpha_fang",
			"guaranteed": true, "escrow_items": {"alpha_fang": 1},
		})

func _test_queen_escrow_settlement_and_seal_policy() -> void:
	var state := _queen_ready()
	var begun := CampaignData.begin_boss_escrow(state, "queen-chart-a",
		CampaignData.QUEENS_SUMMIT)
	var entered := CampaignData.mark_escrow_in_run(begun.state, begun.attempt_id,
		"queen-chart-a", CampaignData.QUEENS_SUMMIT)
	var refunded := CampaignData.refund_escrow(entered.state, begun.attempt_id,
		"queen-chart-a", CampaignData.QUEENS_SUMMIT)
	var retry := CampaignData.begin_boss_escrow(refunded.state, "queen-chart-b",
		CampaignData.QUEENS_SUMMIT)
	var retry_entered := CampaignData.mark_escrow_in_run(retry.state, retry.attempt_id,
		"queen-chart-b", CampaignData.QUEENS_SUMMIT)
	var settled := CampaignData.resolve_boss_death(retry_entered.state, retry.attempt_id,
		"queen-chart-b", CampaignData.QUEENS_SUMMIT)
	var settled_again := CampaignData.resolve_boss_death(settled.state, retry.attempt_id,
		"queen-chart-b", CampaignData.QUEENS_SUMMIT)
	_check("Queen escrow refunds only Alpha Fang and canonical death settles once",
		bool(begun.ok) and String(begun.attempt_id) == "queens_summit-1"
		and refunded.material_refunds == {"alpha_fang": 1}
		and settled.material_awards == {"oath_nail": 1}
		and settled.relic_awards == ["crown_root_rune"]
		and settled.restoration_awards == ["pale_stair"]
		and CampaignData.chapter_cleared(settled.state, CampaignData.QUEENS_SUMMIT)
		and bool(settled_again.ok) and not bool(settled_again.changed))
	_check("Alpha Fang and post-Queen Oath Nail are protected on their exact routes",
		not CampaignData.seal_use_allowed(_seventh_cleared(), "alpha_fang", "queens_summit")
		and CampaignData.seal_use_allowed(_seventh_cleared(), "alpha_fang", "queens_summit_boss")
		and not CampaignData.seal_use_allowed(settled.state, "oath_nail", "summit")
		and CampaignData.seal_use_allowed(settled.state, "oath_nail", "pale_oath_boss"))
	var view := CampaignData.settlement_view(settled.state, {"guest": true})
	var queen_view: Dictionary = view[CampaignData.QUEENS_SUMMIT]
	_check("Queen settlement projection is guest-read-only Crown Rune and Pale Stair truth",
		bool(queen_view.visible) and bool(queen_view.relic_visible)
		and String(queen_view.relic_id) == "crown_root_rune"
		and String(queen_view.restoration_id) == "pale_stair"
		and bool(queen_view.guest) and not bool(queen_view.debrief_event.available))

func _test_legacy_handoff_exclusion_and_credit() -> void:
	var legacy_open := CampaignData.normalize_campaign_state(_legacy_handoff("in_run"))
	var queen_ready := _queen_ready()
	queen_ready.escrows = legacy_open.escrows.duplicate(true)
	queen_ready.next_attempt_id = legacy_open.next_attempt_id
	var cross_blocked := CampaignData.begin_boss_escrow(queen_ready, "queen-blocked",
		CampaignData.QUEENS_SUMMIT)
	var legacy_entered_again := CampaignData.mark_handoff_in_run(legacy_open,
		"legacy_summit_handoff-3", "frozen-summit", "queens_summit")
	var legacy_refunded := CampaignData.refund_handoff_escrow(legacy_entered_again.state,
		"legacy_summit_handoff-3", "frozen-summit", "queens_summit")
	_check("open frozen legacy handoff excludes new Queen escrow but keeps old phase validation",
		not CampaignData.can_inscribe_boss(queen_ready, "queens_summit_boss", 17)
		and not bool(cross_blocked.ok)
		and bool(legacy_entered_again.ok) and not bool(legacy_entered_again.changed)
		and legacy_refunded.material_refunds == {"alpha_fang": 1}
		and not CampaignData.can_inscribe_handoff(legacy_open, "queens_summit")
		and not bool(CampaignData.begin_handoff_escrow(legacy_open,
			"new-legacy-chart", "queens_summit").ok))
	var consumed_raw := _legacy_handoff("consumed")
	var credit := CampaignData.apply_legacy_summit_alpha_fang_credit(consumed_raw, {})
	var credit_again := CampaignData.apply_legacy_summit_alpha_fang_credit(credit.state, {})
	var already_owned := CampaignData.apply_legacy_summit_alpha_fang_credit(
		_legacy_handoff("consumed"), {"alpha_fang": 1})
	_check("only one consumed v2 legacy handoff receives a durable exact-Fang credit",
		bool(credit.changed) and bool(credit.eligible)
		and credit.material_set == {"alpha_fang": 1}
		and bool(credit.state.legacy_summit_alpha_fang_credit)
		and not bool(credit_again.changed)
		and bool(already_owned.changed) and (already_owned.material_set as Dictionary).is_empty()
		and bool(already_owned.state.legacy_summit_alpha_fang_credit))
	var no_credit := true
	for phase in ["case", "in_run", "refunded"]:
		var transition := CampaignData.apply_legacy_summit_alpha_fang_credit(
			_legacy_handoff(phase), {})
		no_credit = no_credit and not bool(transition.changed) and not bool(transition.eligible)
	_check("case, in-run, refunded, and merely old Summit state never qualify for the credit",
		no_credit
		and not bool(CampaignData.apply_legacy_summit_alpha_fang_credit(
			{"version": 2, "escrows": {}}, {}).changed)
		and not bool(CampaignData.apply_legacy_summit_alpha_fang_credit(
			{"version": 3, "escrows": _legacy_handoff("consumed").escrows}, {}).changed))
