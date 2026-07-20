extends SceneTree

# Pure Seventh Road + safe legacy-Summit handoff domain contract. Runtime,
# scenes, inventory, networking, and disk remain adapters around these records.

const CampaignData = preload("res://data/campaign.gd")

var _pass := 0
var _fail := 0

func _check(label: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
		print("  x %s %s" % [label, detail])

func _golden_cleared() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id in [CampaignData.FIRST_KNOT, CampaignData.GOLDEN_WALLOW]:
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
	state.relics = ["green_root_rune", "mist_root_rune"]
	state.restorations = ["trophy_hall", "sallow_jetty"]
	return CampaignData.normalize_campaign_state(state)

func _seventh_ready(materials: Dictionary = {}) -> Dictionary:
	var state := _golden_cleared()
	for index in 4:
		state = CampaignData.record_successful_chart_return(state, "briar_maze",
			"briar-%d" % (index + 1), 15, materials).state
	return state

func _run() -> void:
	print("--- Seventh Road campaign domain ---")
	_test_descriptor_and_additive_migration()
	_test_four_cold_track_ledger()
	_test_wolf_escrow_and_settlement()
	_test_legacy_inertia_and_projection()
	_test_summit_handoff_contract()
	_test_handoff_normalization_and_recovery()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _init() -> void:
	call_deferred("_run")

func _test_descriptor_and_additive_migration() -> void:
	var fresh := CampaignData.empty_state()
	_check("v6 preserves the Seventh Road and Queen through the Unwritten Road",
		int(fresh.version) == 6
		and fresh.chapters.keys() == [CampaignData.FIRST_KNOT,
			CampaignData.GOLDEN_WALLOW, CampaignData.SEVENTH_ROAD,
			CampaignData.QUEENS_SUMMIT, CampaignData.PALE_OATH,
			CampaignData.FIRE_IN_THE_BOUGH, CampaignData.UNWRITTEN_ROAD]
		and CampaignData.chapter_for_recipe("briar_maze") == CampaignData.SEVENTH_ROAD
		and CampaignData.chapter_for_recipe("seventh_road_boss") == CampaignData.SEVENTH_ROAD
		and CampaignData.chapter_for_recipe("summit_approach") == CampaignData.QUEENS_SUMMIT
		and CampaignData.chapter_for_recipe("queens_summit_boss") == CampaignData.QUEENS_SUMMIT)
	var migrated := CampaignData.normalize_campaign_state({
		"version": 1,
		"next_attempt_id": 7,
		"chapters": {
			CampaignData.FIRST_KNOT: {"clue_count": 3, "cleared": true},
			CampaignData.GOLDEN_WALLOW: {"clue_count": 2,
				"banked_chart_ids": ["old-shallow-b", "old-shallow-a"]},
		},
		"relics": ["mist_root_rune", "green_root_rune", "invented"],
		"restorations": ["sallow_jetty", "trophy_hall", "invented"],
	})
	_check("v1 migration is additive and preserves authored prior truth",
		int(migrated.version) == 6 and int(migrated.next_attempt_id) == 7
		and bool(migrated.chapters.first_knot.cleared)
		and migrated.chapters.golden_wallow.banked_chart_ids == ["old-shallow-a", "old-shallow-b"]
		and migrated.chapters.seventh_road == {"clue_count": 0, "cleared": false,
			"banked_chart_ids": []}
		and migrated.chapters.queens_summit == {"clue_count": 0, "cleared": false,
			"banked_chart_ids": []}
		and migrated.chapters.pale_oath == {"clue_count": 0, "cleared": false,
			"banked_chart_ids": []}
		and migrated.chapters.fire_in_the_bough == {"clue_count": 0, "cleared": false,
			"banked_chart_ids": []}
		and migrated.chapters.unwritten_road == {"clue_count": 0, "cleared": false,
			"banked_chart_ids": []}
		and migrated.threads == []
		and not bool(migrated.legacy_summit_alpha_fang_credit)
		and migrated.relics == ["green_root_rune", "mist_root_rune"]
		and migrated.restorations == ["trophy_hall", "sallow_jetty"])
	var migrated_again := CampaignData.normalize_campaign_state(migrated)
	_check("v5 migration is idempotent",
		migrated_again == migrated
		and CampaignData.campaign_fingerprint(migrated_again)
			== CampaignData.campaign_fingerprint(migrated))

func _test_four_cold_track_ledger() -> void:
	var blocked_prerequisite := CampaignData.next_clue_for_chart(
		CampaignData.empty_state(), "briar_maze", "briar-1", 15)
	var state := _golden_cleared()
	var blocked_level := CampaignData.next_clue_for_chart(state,
		"briar_maze", "briar-1", 14)
	var first_hint := CampaignData.next_clue_for_chart(state,
		"briar_maze", "briar-1", 15)
	var first := CampaignData.record_successful_chart_return(state,
		"briar_maze", "briar-1", 15, {})
	var duplicate := CampaignData.record_successful_chart_return(first.state,
		"briar_maze", "briar-1", 23, {})
	var wrong := CampaignData.record_successful_chart_return(first.state,
		"sallow_mire", "mire-legacy", 15, {})
	var empty_id := CampaignData.record_successful_chart_return(first.state,
		"briar_maze", "", 15, {})
	var second := CampaignData.record_successful_chart_return(first.state,
		"briar_maze", "briar-2", 15, {})
	var third := CampaignData.record_successful_chart_return(second.state,
		"briar_maze", "briar-3", 15, {})
	var fourth := CampaignData.record_successful_chart_return(third.state,
		"briar_maze", "briar-4", 15, {})
	var capped := CampaignData.record_successful_chart_return(fourth.state,
		"briar_maze", "briar-5", 15, {})
	_check("Seventh clues require Golden clear and Wayfinding 15",
		blocked_prerequisite.is_empty() and blocked_level.is_empty()
		and String(first_hint.presentation) == "cold_track_clue")
	_check("four physical Chart identities bank four distinct ledger-only Cold Tracks",
		String(first.clue_id) == "seventh_road_cold_track_1"
		and String(second.clue_id) == "seventh_road_cold_track_2"
		and String(third.clue_id) == "seventh_road_cold_track_3"
		and String(fourth.clue_id) == "seventh_road_cold_track_4"
		and String(CampaignData.CHAPTERS[CampaignData.SEVENTH_ROAD]
			.clue_presentation) == "cold_track_clue"
		and not bool(duplicate.changed) and not bool(wrong.changed)
		and not bool(empty_id.changed) and not bool(capped.changed)
		and fourth.rumour_ids == [CampaignData.SEVENTH_ROAD_RUMOUR]
		and fourth.material_awards == {"wightpelt": 1}
		and CampaignData.chapter_clue_count(fourth.state,
			CampaignData.SEVENTH_ROAD) == 4)
	var with_pelt := _golden_cleared()
	for index in 4:
		var result := CampaignData.record_successful_chart_return(with_pelt,
			"briar_maze", "owned-%d" % index, 15, {"wightpelt": 1})
		with_pelt = result.state
		if index == 3:
			_check("fourth clue never remints an owned Wightpelt",
				(result.material_awards as Dictionary).is_empty())
	_check("Wolf Boss Chart is clue-gated and forced",
		not CampaignData.can_inscribe_boss(third.state, "seventh_road_boss", 15, 14)
		and not CampaignData.can_inscribe_boss(fourth.state, "seventh_road_boss", 14, 14)
		and not CampaignData.can_inscribe_boss(fourth.state, "seventh_road_boss", 15, 13)
		and CampaignData.can_inscribe_boss(fourth.state, "seventh_road_boss", 15, 14)
		and CampaignData.boss_contract("seventh_road_boss") == {
			"chapter_id": CampaignData.SEVENTH_ROAD, "boss_kind": "wolf_alpha",
			"seal_id": "wightpelt", "guaranteed": true,
			"escrow_items": {"wightpelt": 1},
		})

func _test_wolf_escrow_and_settlement() -> void:
	var state := _seventh_ready()
	var begun := CampaignData.begin_boss_escrow(state, "wolf-chart-a",
		CampaignData.SEVENTH_ROAD)
	var blocked := CampaignData.begin_boss_escrow(begun.state, "wolf-chart-b",
		CampaignData.SEVENTH_ROAD)
	var case_refund := CampaignData.refund_escrow(begun.state, begun.attempt_id,
		"wolf-chart-a", CampaignData.SEVENTH_ROAD)
	var entered := CampaignData.mark_escrow_in_run(begun.state, begun.attempt_id,
		"wolf-chart-a", CampaignData.SEVENTH_ROAD)
	var refunded := CampaignData.refund_escrow(entered.state, begun.attempt_id,
		"wolf-chart-a", CampaignData.SEVENTH_ROAD)
	var refunded_again := CampaignData.refund_escrow(refunded.state, begun.attempt_id,
		"wolf-chart-a", CampaignData.SEVENTH_ROAD)
	_check("Wolf Story Seal has one open attempt and refunds only after entry",
		bool(begun.ok) and String(begun.attempt_id) == "seventh_road-1"
		and not bool(blocked.ok) and not bool(case_refund.ok)
		and refunded.material_refunds == {"wightpelt": 1}
		and bool(refunded_again.ok) and not bool(refunded_again.changed)
		and (refunded_again.material_refunds as Dictionary).is_empty())
	var retry := CampaignData.begin_boss_escrow(refunded.state, "wolf-chart-b",
		CampaignData.SEVENTH_ROAD)
	var retry_entered := CampaignData.mark_escrow_in_run(retry.state, retry.attempt_id,
		"wolf-chart-b", CampaignData.SEVENTH_ROAD)
	var settled := CampaignData.resolve_boss_death(retry_entered.state, retry.attempt_id,
		"wolf-chart-b", CampaignData.SEVENTH_ROAD)
	var settled_again := CampaignData.resolve_boss_death(settled.state, retry.attempt_id,
		"wolf-chart-b", CampaignData.SEVENTH_ROAD)
	_check("Wolf death settles Alpha Fang, Fang Rune, and Archive exactly once",
		settled.material_awards == {"alpha_fang": 1}
		and settled.relic_awards == ["fang_root_rune"]
		and settled.restoration_awards == ["skald_archive"]
		and CampaignData.chapter_cleared(settled.state, CampaignData.SEVENTH_ROAD)
		and bool(settled_again.ok) and not bool(settled_again.changed)
		and (settled_again.material_awards as Dictionary).is_empty())

func _test_legacy_inertia_and_projection() -> void:
	var inferred: Dictionary = CampaignData.infer_legacy_clear(CampaignData.empty_state(),
		{"wightpelt": {}, "alpha_fang": {}}, true).state
	_check("legacy trophies and Summit proof never infer Seventh Road",
		CampaignData.chapter_cleared(inferred, CampaignData.FIRST_KNOT)
		and not CampaignData.chapter_cleared(inferred, CampaignData.GOLDEN_WALLOW)
		and not CampaignData.chapter_cleared(inferred, CampaignData.SEVENTH_ROAD))
	var ready := _seventh_ready()
	_check("canonical Wightpelt is reserved throughout the Seventh journey",
		not CampaignData.seal_use_allowed(_golden_cleared(), "wightpelt", "wolf_alpha_den")
		and CampaignData.seal_use_allowed(ready, "wightpelt", "seventh_road_boss"))
	var begun := CampaignData.begin_boss_escrow(ready, "wolf-projection",
		CampaignData.SEVENTH_ROAD)
	var entered := CampaignData.mark_escrow_in_run(begun.state, begun.attempt_id,
		"wolf-projection", CampaignData.SEVENTH_ROAD)
	var cleared: Dictionary = CampaignData.resolve_boss_death(entered.state, begun.attempt_id,
		"wolf-projection", CampaignData.SEVENTH_ROAD).state
	var view := CampaignData.settlement_view(cleared, {"guest": true})
	_check("generic settlement exposes read-only 4/4 Archive truth",
		bool(view.seventh_road.visible) and bool(view.seventh_road.relic_visible)
		and String(view.seventh_road.restoration_id) == "skald_archive"
		and int(view.seventh_road.clue_count) == 4
		and int(view.seventh_road.clue_target) == 4
		and bool(view.seventh_road.guest) and bool(view.seventh_road.read_only)
		and not bool(view.seventh_road.debrief_event.available))

func _test_summit_handoff_contract() -> void:
	var exact := {
		"contract_id": "legacy_summit_handoff",
		"boss_kind": "hedgemother_queen",
		"seal_id": "alpha_fang",
		"guaranteed": true,
		"escrow_items": {"alpha_fang": 1},
		"campaign_inert": true,
	}
	_check("only queens_summit owns the exact non-campaign handoff",
		CampaignData.handoff_contract("queens_summit") == exact
		and CampaignData.handoff_contract("summit").is_empty()
		and CampaignData.handoff_contract("seventh_road_boss").is_empty())
	var state := CampaignData.empty_state()
	var newly_begun := CampaignData.begin_handoff_escrow(state, "summit-chart-new",
		"queens_summit")
	var frozen := CampaignData.normalize_campaign_state({
		"version": 2, "next_attempt_id": 2,
		"escrows": {"legacy_summit_handoff-1": {
			"chart_instance_id": "summit-chart-a", "kind": "handoff",
			"contract_id": "legacy_summit_handoff", "phase": "case",
			"items": {"alpha_fang": 1},
		}},
	})
	var before := CampaignData.campaign_fingerprint(frozen)
	var entered := CampaignData.mark_handoff_in_run(frozen, "legacy_summit_handoff-1",
		"summit-chart-a", "queens_summit")
	var wrong := CampaignData.resolve_handoff(entered.state, "legacy_summit_handoff-1",
		"summit-chart-a", "seventh_road_boss")
	var consumed := CampaignData.resolve_handoff(entered.state, "legacy_summit_handoff-1",
		"summit-chart-a", "queens_summit")
	var consumed_again := CampaignData.resolve_handoff(consumed.state, "legacy_summit_handoff-1",
		"summit-chart-a", "queens_summit")
	_check("new handoff commits are retired, while a frozen case still consumes its entered Fang tombstone",
		not bool(newly_begun.ok) and not CampaignData.can_inscribe_handoff(state, "queens_summit")
		and bool(entered.changed) and not bool(wrong.ok)
		and bool(consumed.ok) and bool(consumed.changed)
		and bool(consumed_again.ok) and not bool(consumed_again.changed)
		and String(consumed.state.escrows["legacy_summit_handoff-1"].phase) == "consumed")
	_check("handoff consumption is campaign-inert",
		CampaignData.chapter_clue_count(consumed.state, CampaignData.FIRST_KNOT) == 0
		and CampaignData.chapter_clue_count(consumed.state, CampaignData.QUEENS_SUMMIT) == 0
		and (consumed.state.relics as Array).is_empty()
		and (consumed.state.restorations as Array).is_empty()
		and CampaignData.campaign_fingerprint(consumed.state) != before)
	var seventh_cleared := _seventh_ready()
	var queen_gate := CampaignData.begin_boss_escrow(seventh_cleared, "wolf-gate",
		CampaignData.SEVENTH_ROAD)
	var queen_ready: Dictionary = CampaignData.resolve_boss_death(
		CampaignData.mark_escrow_in_run(queen_gate.state, queen_gate.attempt_id,
			"wolf-gate", CampaignData.SEVENTH_ROAD).state,
		queen_gate.attempt_id, "wolf-gate", CampaignData.SEVENTH_ROAD).state
	_check("Alpha Fang is reserved for the authored Queen boss, never the retired handoff",
		CampaignData.seal_use_allowed(queen_ready, "alpha_fang", "queens_summit_boss")
		and not CampaignData.seal_use_allowed(queen_ready, "alpha_fang", "queens_summit")
		and not CampaignData.seal_use_allowed(queen_ready, "alpha_fang", "summit"))

func _test_handoff_normalization_and_recovery() -> void:
	var normalized := CampaignData.normalize_campaign_state({
		"version": 1,
		"next_attempt_id": 1,
		"escrows": {
			"legacy_summit_handoff-8": {
				"attempt_id": "forged-id",
				"chart_instance_id": "summit-recover",
				"kind": "handoff",
				"contract_id": "legacy_summit_handoff",
				"phase": "in_run",
				"items": {"alpha_fang": 99, "invented": 1},
			},
			"future-handoff-99": {
				"chart_instance_id": "unknown", "kind": "handoff",
				"contract_id": "future_handoff", "phase": "in_run",
			},
		},
	})
	var record: Dictionary = normalized.escrows["legacy_summit_handoff-8"]
	_check("normalization retains only the authored handoff and repairs its payload",
		normalized.escrows.keys() == ["legacy_summit_handoff-8"]
		and int(normalized.next_attempt_id) == 9
		and record == {
			"attempt_id": "legacy_summit_handoff-8",
			"chart_instance_id": "summit-recover",
			"kind": "handoff",
			"contract_id": "legacy_summit_handoff",
			"phase": "in_run",
			"items": {"alpha_fang": 1},
		})
	var recovered := CampaignData.recover_unresolved_in_run(normalized)
	var recovered_again := CampaignData.recover_unresolved_in_run(recovered.state)
	_check("load recovery refunds Alpha Fang exactly once and keeps a tombstone",
		recovered.material_refunds == {"alpha_fang": 1}
		and recovered.refunded_attempt_ids == ["legacy_summit_handoff-8"]
		and String(recovered.state.escrows["legacy_summit_handoff-8"].phase) == "refunded"
		and not bool(recovered_again.changed)
		and (recovered_again.material_refunds as Dictionary).is_empty())
	var retry := CampaignData.begin_handoff_escrow(recovered.state,
		"summit-after-recovery", "queens_summit")
	_check("a refunded frozen handoff remains a tombstone and cannot begin a replacement",
		not bool(retry.ok) and String(retry.attempt_id) == "")
