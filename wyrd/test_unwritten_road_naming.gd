extends SceneTree

# D8 Slice 2 — the real Game settlement seam for the Knot-Eater's final naming
# action. CampaignData supplies canonical in-run fixtures; only Game applies the
# durable campaign, material, Thread, restoration, projection, and save effects.

const CampaignData := preload("res://data/campaign.gd")
const SaveGame := preload("res://scripts/save_game.gd")

const ROAD_CHOICES := ["lantern_path", "mended_way", "open_footpath"]
const ROOT_RUNES := [
	"green_root_rune", "mist_root_rune", "fang_root_rune", "crown_root_rune",
	"pale_root_rune", "ember_root_rune",
]

var _pass := 0
var _fail := 0


func _initialize() -> void:
	await _run()


func _check(label: String, ok: bool, detail = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % label)
	else:
		_fail += 1
		print("  ✗ %s %s" % [label, str(detail)])


func _run() -> void:
	print("--- Unwritten Road naming settlement ---")
	var game := root.get_node_or_null("Game")
	if game == null:
		_check("real Game autoload is mounted", false)
		quit(1)
		return
	game.persistence_enabled = false

	var mechanical_results: Array = []
	for index in ROAD_CHOICES.size():
		var road_name := String(ROAD_CHOICES[index])
		var fixture := _mount_fresh_attempt(game, "naming-%d" % (index + 1))
		_check("%s fixture is a canonical live Unwritten attempt" % road_name,
			bool(fixture.get("ok", false)), fixture)
		if not bool(fixture.get("ok", false)):
			continue
		var effect := _effect(fixture, road_name, index + 1)
		var settled: Dictionary = game.resolve_unwritten_road_settlement(effect)
		var mechanics := _mechanical_result(game, settled)
		mechanical_results.append(mechanics)
		_check("%s applies the exact final-road consequences" % road_name,
			bool(settled.get("ok", false)) and bool(settled.get("changed", false))
				and mechanics == _expected_mechanics(),
			{"transition": settled, "mechanics": mechanics})
		_check("%s persists only its cosmetic road choice" % road_name,
			String(game.campaign_state.get("road_name_id", "")) == road_name
				and String((game.campaign_state.escrows as Dictionary)[fixture.attempt_id]
					.get("road_name_id", "")) == road_name,
			game.campaign_state)

		var state_after: Dictionary = game.campaign_state.duplicate(true)
		var materials_after: Dictionary = game.materials.duplicate(true)
		var same_replay: Dictionary = game.resolve_unwritten_road_settlement(effect)
		_check("%s same-name replay is acknowledged without rewards" % road_name,
			bool(same_replay.get("ok", false)) and not bool(same_replay.get("changed", true))
				and same_replay.get("material_awards", {}) == {}
				and same_replay.get("material_targets_exact", {}) == {}
				and same_replay.get("thread_awards", []) == []
				and same_replay.get("restoration_awards", []) == []
				and game.campaign_state == state_after and game.materials == materials_after,
			same_replay)

		var other_name := String(ROAD_CHOICES[(index + 1) % ROAD_CHOICES.size()])
		var conflicting_effect := effect.duplicate(true)
		conflicting_effect["road_name_id"] = other_name
		var conflicting: Dictionary = game.resolve_unwritten_road_settlement(conflicting_effect)
		_check("%s cannot be overwritten by %s" % [road_name, other_name],
			not bool(conflicting.get("ok", true))
				and not bool(conflicting.get("changed", true))
				and String(conflicting.get("reason", "")) == "road_name_mismatch"
				and game.campaign_state == state_after and game.materials == materials_after,
			conflicting)

	_check("all three authored names are mechanically identical",
		mechanical_results.size() == ROAD_CHOICES.size()
			and mechanical_results.all(func(result): return result == mechanical_results[0]),
		mechanical_results)
	_test_settlement_save_roundtrip(game)
	_test_malformed_effects(game)

	game.persistence_enabled = false
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


func _mount_fresh_attempt(game: Node, suffix: String) -> Dictionary:
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.persistence_enabled = false
	var ready := _unwritten_ready()
	var chart_id := "unwritten-%s" % suffix
	var begun: Dictionary = CampaignData.begin_boss_escrow(ready, chart_id,
		CampaignData.UNWRITTEN_ROAD)
	if not bool(begun.get("ok", false)):
		return {"ok": false, "reason": "begin_failed", "transition": begun}
	var attempt_id := String(begun.get("attempt_id", ""))
	var entered: Dictionary = CampaignData.mark_escrow_in_run(begun.state, attempt_id,
		chart_id, CampaignData.UNWRITTEN_ROAD)
	if not bool(entered.get("ok", false)):
		return {"ok": false, "reason": "enter_failed", "transition": entered}
	game.campaign_state = entered.state
	# Deliberate duplicate physical counts prove exact targets rather than merely
	# observing the canonical values already present in a fresh satchel.
	game.materials = {"wyrm_scale": 2, "quiet_tooth": 3}
	game.active_chart = {
		"recipe_id": CampaignData.UNWRITTEN_ROAD_BOSS_RECIPE,
		"chart_instance_id": chart_id,
		"attempt_id": attempt_id,
		"campaign_contract": CampaignData.boss_contract(
			CampaignData.UNWRITTEN_ROAD_BOSS_RECIPE),
	}
	var record: Dictionary = game.campaign_state.escrows[attempt_id]
	return {
		"ok": String(record.get("phase", "")) == "in_run"
			and String(record.get("chart_instance_id", "")) == chart_id
			and String((game.active_chart.campaign_contract as Dictionary)
				.get("chapter_id", "")) == CampaignData.UNWRITTEN_ROAD,
		"chart_id": chart_id,
		"attempt_id": attempt_id,
	}


func _effect(fixture: Dictionary, road_name: String, serial: int) -> Dictionary:
	return {
		"effect_id": "%s:%s:%d" % [fixture.chart_id, fixture.attempt_id, serial],
		"chart_instance_id": String(fixture.chart_id),
		"attempt_id": String(fixture.attempt_id),
		"road_name_id": road_name,
	}


func _mechanical_result(game: Node, transition: Dictionary) -> Dictionary:
	return {
		"material_awards": transition.get("material_awards", {}),
		"material_targets_exact": transition.get("material_targets_exact", {}),
		"wyrm_scale": game.material_count("wyrm_scale"),
		"quiet_tooth": game.material_count("quiet_tooth"),
		"unwritten_thread": (game.campaign_state.threads as Array).has("unwritten_thread"),
		"master_forge": (game.campaign_state.restorations as Array).has("master_forge"),
		"cleared": CampaignData.chapter_cleared(game.campaign_state,
			CampaignData.UNWRITTEN_ROAD),
		"active_chart_settled": bool(game.active_chart.get(
			"campaign_completion_boss_settled", false)),
	}


func _expected_mechanics() -> Dictionary:
	return {
		"material_awards": {"quiet_tooth": 1},
		"material_targets_exact": {"wyrm_scale": 0, "quiet_tooth": 1},
		"wyrm_scale": 0,
		"quiet_tooth": 1,
		"unwritten_thread": true,
		"master_forge": true,
		"cleared": true,
		"active_chart_settled": true,
	}


func _test_settlement_save_roundtrip(game: Node) -> void:
	var json_text: String = SaveGame._snapshot_json(game)
	var parsed = JSON.parse_string(json_text)
	var decoded: Dictionary = SaveGame._decode(parsed) if parsed is Dictionary else {}
	game.reset_to_defaults()
	if not decoded.is_empty():
		SaveGame._restore_into(SaveGame._migrate(decoded), game)
	_check("named final settlement survives the production save/restore schema",
		String(game.campaign_state.get("road_name_id", "")) == "open_footpath"
		and CampaignData.chapter_cleared(game.campaign_state, CampaignData.UNWRITTEN_ROAD)
		and (game.campaign_state.threads as Array).has("unwritten_thread")
		and (game.campaign_state.restorations as Array).has("master_forge")
		and game.material_count("wyrm_scale") == 0
		and game.material_count("quiet_tooth") == 1,
		{"state": game.campaign_state, "materials": game.materials})


func _test_malformed_effects(game: Node) -> void:
	var fixture := _mount_fresh_attempt(game, "malformed")
	_check("malformed-effect fixture is live", bool(fixture.get("ok", false)), fixture)
	if not bool(fixture.get("ok", false)):
		return
	var state_before: Dictionary = game.campaign_state.duplicate(true)
	var materials_before: Dictionary = game.materials.duplicate(true)
	var empty: Dictionary = game.resolve_unwritten_road_settlement({})
	var forged := _effect(fixture, "lantern_path", 1)
	forged["effect_id"] = "forged-effect"
	var malformed: Dictionary = game.resolve_unwritten_road_settlement(forged)
	var wrong_identity := _effect(fixture, "lantern_path", 2)
	wrong_identity["chart_instance_id"] = "other-chart"
	wrong_identity["effect_id"] = "other-chart:%s:2" % fixture.attempt_id
	var mismatched: Dictionary = game.resolve_unwritten_road_settlement(wrong_identity)
	_check("empty and malformed effects fail closed",
		not bool(empty.get("ok", true)) and String(empty.get("reason", "")) == "bad_effect"
			and not bool(malformed.get("ok", true))
			and String(malformed.get("reason", "")) == "identity_mismatch",
		{"empty": empty, "malformed": malformed})
	_check("Chart/attempt identity mismatch cannot settle or award",
		not bool(mismatched.get("ok", true))
			and String(mismatched.get("reason", "")) == "identity_mismatch"
			and game.campaign_state == state_before and game.materials == materials_before,
		mismatched)


func _unwritten_ready() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id in [CampaignData.FIRST_KNOT, CampaignData.GOLDEN_WALLOW,
		CampaignData.SEVENTH_ROAD, CampaignData.QUEENS_SUMMIT,
		CampaignData.PALE_OATH, CampaignData.FIRE_IN_THE_BOUGH]:
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
		var banked: Array = []
		for index in int(CampaignData.CHAPTERS[chapter_id].clue_target):
			banked.append("%s-%d" % [chapter_id, index + 1])
		chapter.banked_chart_ids = banked
	state.relics = ROOT_RUNES.duplicate()
	state.threads = ["past_thread", "present_thread"]
	state.restorations = ["trophy_hall", "sallow_jetty", "skald_archive",
		"pale_stair", "rootroad_lift", "ember_kiln"]
	state = CampaignData.normalize_campaign_state(state)
	for index in 5:
		state = CampaignData.record_successful_chart_return(state, "root_below",
			"root-below-naming-%d" % (index + 1), 22, {}).state
	var mapped: Dictionary = CampaignData.record_map_of_nine_knots(state, 23)
	return mapped.state if bool(mapped.get("ok", false)) else state
