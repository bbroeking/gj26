extends SceneTree

# Pure Campaign contract for the Pale Oath. Runtime, Table, Archive, boss,
# presentation, and inventory adapters consume these records elsewhere.

const CampaignData = preload("res://data/campaign.gd")

var _pass := 0
var _fail := 0

func _check(label: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
		print("  x %s %s" % [label, detail])

func _queen_cleared() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id in [CampaignData.FIRST_KNOT, CampaignData.GOLDEN_WALLOW,
		CampaignData.SEVENTH_ROAD, CampaignData.QUEENS_SUMMIT]:
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
	state.relics = ["green_root_rune", "mist_root_rune", "fang_root_rune",
		"crown_root_rune"]
	state.restorations = ["trophy_hall", "sallow_jetty", "skald_archive",
		"pale_stair"]
	return CampaignData.normalize_campaign_state(state)

func _pale_ready() -> Dictionary:
	var state := _queen_cleared()
	for index in 4:
		state = CampaignData.record_successful_chart_return(state, "pale_veins",
			"pale-veins-%d" % (index + 1), 18, {}).state
	return state

func _run() -> void:
	print("--- Pale Oath campaign domain ---")
	_test_v4_additive_migration_and_inference_guard()
	_test_oath_rubbing_ledger_and_boss_contract()
	_test_nail_escrow_settlement_and_future_protection()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _init() -> void:
	call_deferred("_run")

func _test_v4_additive_migration_and_inference_guard() -> void:
	var fresh := CampaignData.empty_state()
	var migrations_inert := true
	for source_version in [1, 2, 3]:
		var migrated := CampaignData.normalize_campaign_state({
			"version": source_version,
			"chapters": {
				CampaignData.QUEENS_SUMMIT: {"clue_count": 4, "cleared": true,
					"banked_chart_ids": ["crown-1", "crown-2", "crown-3", "crown-4"]},
			},
			"relics": ["crown_root_rune"], "restorations": ["pale_stair"],
		})
		migrations_inert = migrations_inert \
			and int(migrated.version) == 6 \
			and bool(migrated.chapters.queens_summit.cleared) \
			and migrated.chapters.pale_oath == {"clue_count": 0, "cleared": false,
				"banked_chart_ids": []} \
			and migrated.chapters.fire_in_the_bough == {"clue_count": 0, "cleared": false,
				"banked_chart_ids": []} \
			and migrated.chapters.unwritten_road == {"clue_count": 0, "cleared": false,
				"banked_chart_ids": []} \
			and migrated.threads == [] \
			and CampaignData.normalize_campaign_state(migrated) == migrated
	var no_inference := CampaignData.normalize_campaign_state({
		"version": 3, "materials": {"oath_nail": 99}, "summit_cleared": true,
		"legacy_summit_alpha_fang_credit": true,
		"relics": ["pale_root_rune"], "restorations": ["rootroad_lift"],
	})
	_check("v6 preserves Pale Oath and threads through the Unwritten Road",
		int(fresh.version) == 6
		and fresh.chapters.keys() == [CampaignData.FIRST_KNOT,
			CampaignData.GOLDEN_WALLOW, CampaignData.SEVENTH_ROAD,
			CampaignData.QUEENS_SUMMIT, CampaignData.PALE_OATH,
			CampaignData.FIRE_IN_THE_BOUGH, CampaignData.UNWRITTEN_ROAD]
		and fresh.threads == []
		and migrations_inert)
	_check("loose Nail, legacy Summit evidence, and presentation records never infer Pale truth",
		not CampaignData.chapter_cleared(no_inference, CampaignData.PALE_OATH)
		and CampaignData.chapter_clue_count(no_inference, CampaignData.PALE_OATH) == 0
		and not (no_inference.threads as Array).has("past_thread")
		and not bool(CampaignData.settlement_view(no_inference)[CampaignData.PALE_OATH]
			.get("visible", true)))

func _test_oath_rubbing_ledger_and_boss_contract() -> void:
	var blocked_prerequisite := CampaignData.next_clue_for_chart(
		CampaignData.empty_state(), "pale_veins", "pale-1", 18)
	var blocked_level := CampaignData.next_clue_for_chart(_queen_cleared(),
		"pale_veins", "pale-1", 17)
	var state := _queen_cleared()
	var first := CampaignData.record_successful_chart_return(state, "pale_veins",
		"pale-1", 18, {})
	var duplicate := CampaignData.record_successful_chart_return(first.state, "pale_veins",
		"pale-1", 23, {})
	var second := CampaignData.record_successful_chart_return(first.state, "pale_veins",
		"pale-2", 18, {})
	var third := CampaignData.record_successful_chart_return(second.state, "pale_veins",
		"pale-3", 18, {})
	var fourth := CampaignData.record_successful_chart_return(third.state, "pale_veins",
		"pale-4", 18, {"oath_nail": 0})
	_check("four distinct host-return ledger facts are the exact Oath-Rubbings",
		blocked_prerequisite.is_empty() and blocked_level.is_empty()
		and String(first.clue_id) == "oath_rubbing_1"
		and String(second.clue_id) == "oath_rubbing_2"
		and String(third.clue_id) == "oath_rubbing_3"
		and String(fourth.clue_id) == "oath_rubbing_4"
		and not bool(duplicate.changed)
		and fourth.rumour_ids == [CampaignData.PALE_OATH_RUMOUR]
		and (fourth.material_awards as Dictionary).is_empty()
		and CampaignData.chapter_clue_count(fourth.state, CampaignData.PALE_OATH) == 4)
	_check("Pale Oath contract is exact and needs only Wayfinding 19",
		not CampaignData.can_inscribe_boss(fourth.state, "pale_oath_boss", 18)
		and CampaignData.can_inscribe_boss(fourth.state, "pale_oath_boss", 19)
		and CampaignData.chapter_for_recipe("pale_veins") == CampaignData.PALE_OATH
		and CampaignData.chapter_for_recipe("pale_oath_boss") == CampaignData.PALE_OATH
		and String(CampaignData.CHAPTERS[CampaignData.PALE_OATH].clue_source_id)
			== "skald_pale_oath"
		and String(CampaignData.CHAPTERS[CampaignData.PALE_OATH].boss_source_id)
			== "skald_pale_oath_boss"
		and CampaignData.boss_contract("pale_oath_boss") == {
			"chapter_id": CampaignData.PALE_OATH, "boss_kind": "barrow_jarl",
			"seal_id": "oath_nail", "guaranteed": true,
			"escrow_items": {"oath_nail": 1},
		})

func _test_nail_escrow_settlement_and_future_protection() -> void:
	var ready := _pale_ready()
	var begun := CampaignData.begin_boss_escrow(ready, "jarl-chart-a",
		CampaignData.PALE_OATH)
	var entered := CampaignData.mark_escrow_in_run(begun.state, begun.attempt_id,
		"jarl-chart-a", CampaignData.PALE_OATH)
	var refunded := CampaignData.refund_escrow(entered.state, begun.attempt_id,
		"jarl-chart-a", CampaignData.PALE_OATH)
	var refunded_again := CampaignData.refund_escrow(refunded.state, begun.attempt_id,
		"jarl-chart-a", CampaignData.PALE_OATH)
	var crash := CampaignData.begin_boss_escrow(refunded.state, "jarl-chart-b",
		CampaignData.PALE_OATH)
	var crash_entered := CampaignData.mark_escrow_in_run(crash.state, crash.attempt_id,
		"jarl-chart-b", CampaignData.PALE_OATH)
	var recovered := CampaignData.recover_unresolved_in_run(crash_entered.state)
	var retry := CampaignData.begin_boss_escrow(recovered.state, "jarl-chart-c",
		CampaignData.PALE_OATH)
	var retry_entered := CampaignData.mark_escrow_in_run(retry.state, retry.attempt_id,
		"jarl-chart-c", CampaignData.PALE_OATH)
	var settled := CampaignData.resolve_boss_death(retry_entered.state, retry.attempt_id,
		"jarl-chart-c", CampaignData.PALE_OATH)
	var settled_again := CampaignData.resolve_boss_death(settled.state, retry.attempt_id,
		"jarl-chart-c", CampaignData.PALE_OATH)
	_check("Oath Nail uses case-to-in-run-to-single-refund across abandon and recovery",
		bool(begun.ok) and String(begun.attempt_id) == "pale_oath-1"
		and refunded.material_refunds == {"oath_nail": 1}
		and bool(refunded_again.ok) and not bool(refunded_again.changed)
		and recovered.material_refunds == {"oath_nail": 1}
		and String(recovered.state.escrows[crash.attempt_id].phase) == "refunded")
	_check("canonical Barrow settlement is exact, permanent, and consumes every Nail count",
		settled.material_awards == {"starheart_coal": 1}
		and settled.material_set == {"oath_nail": 0}
		and settled.material_targets_exact == {"oath_nail": 0, "starheart_coal": 1}
		and settled.relic_awards == ["pale_root_rune"]
		and settled.thread_awards == ["past_thread"]
		and settled.restoration_awards == ["rootroad_lift"]
		and CampaignData.chapter_cleared(settled.state, CampaignData.PALE_OATH)
		and (settled.state.threads as Array) == ["past_thread"]
		and bool(settled_again.ok) and not bool(settled_again.changed))
	_check("Starheart Coal is protected for Fire in the Bough after Pale settlement",
		not CampaignData.seal_use_allowed(settled.state, "starheart_coal", "ash_bough")
		and CampaignData.seal_use_allowed(settled.state, "starheart_coal",
			"fire_in_the_bough_boss"))
