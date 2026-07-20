extends SceneTree

# Focused integration contract for the Pale Oath's live Game adapters.  The
# Campaign/content/presentation suites own their pure records; this suite keeps
# the source, physical Table, escrow, settlement, generation, and Lodge seams
# connected without duplicating CampaignData's state machine.

const GameScript = preload("res://scripts/game.gd")
const CampaignData = preload("res://data/campaign.gd")
const ChartsData = preload("res://data/charts.gd")
const DungeonGen = preload("res://scripts/dungeon_gen.gd")
const Progression = preload("res://data/progression.gd")

var _pass := 0
var _fail := 0


func _check(label: String, ok: bool, detail = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % label)
	else:
		_fail += 1
		print("  ✗ %s %s" % [label, str(detail)])


func _new_game() -> Node:
	var game: Node = GameScript.new()
	game._ready()
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.persistence_enabled = false
	game.materials = {}
	game.charts = []
	game.seen_hints = {"chart_table_snug_returned": true}
	return game


func _queen_prerequisite_state() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id in [CampaignData.FIRST_KNOT, CampaignData.GOLDEN_WALLOW,
			CampaignData.SEVENTH_ROAD]:
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
	var queen: Dictionary = state.chapters[CampaignData.QUEENS_SUMMIT]
	queen.clue_count = int(CampaignData.CHAPTERS[CampaignData.QUEENS_SUMMIT].clue_target)
	state.relics = ["green_root_rune", "mist_root_rune", "fang_root_rune"]
	state.restorations = ["trophy_hall", "sallow_jetty", "skald_archive"]
	return CampaignData.normalize_campaign_state(state)


func _queen_chart(chart_id: String) -> Dictionary:
	return {
		"recipe_id": CampaignData.QUEENS_SUMMIT_BOSS_RECIPE,
		"chart_instance_id": chart_id,
		"template_id": "summit_queen", "tier": 3, "scope": "summit",
		"seed": 1701, "affixes": [],
		"campaign_contract": CampaignData.boss_contract(
			CampaignData.QUEENS_SUMMIT_BOSS_RECIPE),
	}


func _settle_queen(game: Node) -> Dictionary:
	game.campaign_state = _queen_prerequisite_state()
	game.trades.wayfinding = {"xp": Progression.xp_for_level(18), "lv": 18}
	game.trades.wildcraft = {"xp": Progression.xp_for_level(19), "lv": 19}
	game.materials = {"alpha_fang": 1}
	var begun: Dictionary = game._begin_campaign_case_escrow(_queen_chart("pale-queen"),
		{"seal_id": "alpha_fang"})
	game.campaign_state = begun.state
	var chart: Dictionary = begun.chart
	game.materials.erase("alpha_fang") # The physical Table has spent the Seal.
	var entered: Dictionary = game._mark_campaign_chart_in_run(chart)
	game.campaign_state = entered.state
	return game.resolve_campaign_boss_death(chart)


func _pale_veins_chart(index: int) -> Dictionary:
	return {"recipe_id": "pale_veins", "chart_instance_id": "pale-veins-%d" % index,
		"template_id": "pale_veins", "tier": 3, "scope": "rootroads", "seed": 1800 + index,
		"affixes": []}


func _boss_draft() -> Dictionary:
	return {"grid": {"nw": "barrow_mark", "n": "pale_wellmark",
		"ne": "cold_track", "c": "atlas_folio", "w": "climbing_cord",
		"e": "climbing_cord", "s": "oath_nail"},
		"ink_rail": ["stoneground_ink"]}


func _boss_materials(nail_count: int = 1) -> Dictionary:
	return {"barrow_mark": 1, "pale_wellmark": 1, "cold_track": 1,
		"atlas_folio": 1, "climbing_cord": 2, "stoneground_ink": 1,
		"hedge_ink": 5, "oath_nail": nail_count}


func _commit_boss_chart(game: Node, seed: int) -> Dictionary:
	var preview: Dictionary = ChartsData.preview_table(_boss_draft(), game.chart_table_context())
	return game.try_inscribe_chart(_boss_draft(), String(preview.fingerprint), seed)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("--- Pale Oath Game runtime ---")
	_test_queen_authority_and_source_recovery()
	_test_archive_kit_and_real_return_folio()
	_test_physical_table_escrow_lifecycle_and_settlement()
	_test_driving_volley_lodge_does_not_overwrite_loadout()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


func _test_queen_authority_and_source_recovery() -> void:
	var game := _new_game()
	var settlement: Dictionary = _settle_queen(game)
	var source: Dictionary = game.chart_source_status("skald_pale_oath")
	_check("canonical Queen settlement alone unlocks the Pale Archive source",
		bool(settlement.get("changed", false)) and bool(source.get("unlocked", false))
			and String(source.get("state", "")) == "eligible", source)
	var recovered := _new_game()
	recovered.campaign_state = game.campaign_state.duplicate(true)
	recovered.trades.wayfinding = {"xp": Progression.xp_for_level(18), "lv": 18}
	recovered.reconcile_unresumable_campaign_attempts()
	_check("canonical Queen state recovers the Pale Archive availability",
		bool(recovered.chart_source_status("skald_pale_oath").get("unlocked", false)))
	var forged := _new_game()
	forged.trades.wayfinding = {"xp": Progression.xp_for_level(18), "lv": 18}
	forged.materials = {"oath_nail": 99}
	forged.summit_cleared = true
	forged.chart_source_unlocks = ["skald_pale_oath"]
	var blocked_status: Dictionary = forged.chart_source_status("skald_pale_oath")
	var blocked_read: Dictionary = forged.read_chart_source("skald_pale_oath")
	_check("loose Nail, legacy flag, and malformed source unlock stay fail-closed",
		not bool(blocked_status.get("unlocked", true))
			and String(blocked_status.get("state", "")) == "locked"
			and not bool(blocked_read.get("changed", true)) and forged.materials == {"oath_nail": 99},
		{"status": blocked_status, "read": blocked_read})
	game.free()
	recovered.free()
	forged.free()


func _test_archive_kit_and_real_return_folio() -> void:
	var game := _new_game()
	_settle_queen(game)
	game.materials = {"atlas_folio": 4, "climbing_cord": 1}
	var first_read: Dictionary = game.read_chart_source("skald_pale_oath")
	var after_first: Dictionary = game.materials.duplicate(true)
	var second_read: Dictionary = game.read_chart_source("skald_pale_oath")
	_check("Archive teaches a missing-only physical kit plus separate Stoneground Ink once",
		bool(first_read.get("changed", false))
			and first_read.get("granted", {}) == {"pale_wellmark": 1, "climbing_cord": 1,
				"stoneground_ink": 1}
			and game.material_count("atlas_folio") == 4 and game.material_count("climbing_cord") == 2
			and game.material_count("pale_wellmark") == 1 and game.material_count("stoneground_ink") == 1
			and not bool(second_read.get("changed", true)) and game.materials == after_first,
		{"first": first_read, "second": second_read, "materials": game.materials})
	for index in 4:
		game._record_campaign_chart_return(_pale_veins_chart(index + 1))
	var pale: Dictionary = game.campaign_state.chapters[CampaignData.PALE_OATH]
	var boss_folio: Dictionary = game.chart_source_status("skald_pale_oath_boss")
	_check("four distinct Game return transactions reveal the boss folio",
		int(pale.clue_count) == 4 and (pale.banked_chart_ids as Array).size() == 4
			and game.chart_source_unlocks.has("skald_pale_oath_boss")
			and bool(boss_folio.get("unlocked", false)) and String(boss_folio.get("state", "")) == "locked",
		{"pale": pale, "folio": boss_folio})
	game.free()


func _test_physical_table_escrow_lifecycle_and_settlement() -> void:
	var game := _new_game()
	_settle_queen(game)
	for index in 4:
		game._record_campaign_chart_return(_pale_veins_chart(index + 1))
	game.trades.wayfinding = {"xp": Progression.xp_for_level(19), "lv": 19}
	game.materials = _boss_materials()
	var committed: Dictionary = _commit_boss_chart(game, 1901)
	var chart: Dictionary = committed.get("chart", {})
	var attempt_id := String(chart.get("attempt_id", ""))
	var escrow: Dictionary = game.campaign_state.escrows.get(attempt_id, {})
	game.active_chart = chart
	var cfg: Dictionary = game.run_cfg()
	var layout: Dictionary = DungeonGen.generate(int(cfg.get("seed", 0)), cfg)
	game.active_chart = {}
	_check("physical Table commit spends the Nail into an exact case escrow and forces Jarl",
		bool(committed.get("ok", false)) and String(chart.get("recipe_id", "")) == "pale_oath_boss"
			and String(escrow.get("phase", "")) == "case" and (escrow.get("items", {}) as Dictionary) == {"oath_nail": 1}
			and game.material_count("oath_nail") == 0
			and (chart.get("campaign_contract", {}) as Dictionary) == CampaignData.boss_contract("pale_oath_boss")
			and String(cfg.get("boss_kind", "")) == "barrow_jarl"
			and String(layout.get("bossKind", "")) == "barrow_jarl", {"commit": committed, "cfg": cfg})
	var entered: Dictionary = game._mark_campaign_chart_in_run(chart)
	game.campaign_state = entered.state
	var abandoned: Dictionary = game._refund_campaign_attempt(chart)
	var abandoned_again: Dictionary = game._refund_campaign_attempt(chart)
	_check("entered Pale Oath abandon returns the Nail exactly once",
		bool(entered.get("ok", false)) and bool(abandoned.get("changed", false))
			and not bool(abandoned_again.get("changed", true)) and game.material_count("oath_nail") == 1,
		{"entered": entered, "abandoned": abandoned, "again": abandoned_again})
	game.materials = _boss_materials()
	var crash_commit: Dictionary = _commit_boss_chart(game, 1902)
	var crash_chart: Dictionary = crash_commit.get("chart", {})
	var crash_entered: Dictionary = game._mark_campaign_chart_in_run(crash_chart)
	game.campaign_state = crash_entered.state
	var recovered: Dictionary = game.reconcile_unresumable_campaign_attempts()
	var recovered_again: Dictionary = game.reconcile_unresumable_campaign_attempts()
	_check("unresumable in-run Pale escrow recovers one Nail and a terminal tombstone",
		bool(recovered.get("changed", false)) and not bool(recovered_again.get("changed", true))
			and game.material_count("oath_nail") == 1
			and String(game.campaign_state.escrows[String(crash_chart.attempt_id)].phase) == "refunded",
		{"recovered": recovered, "again": recovered_again})
	game.materials = _boss_materials()
	var final_commit: Dictionary = _commit_boss_chart(game, 1903)
	var final_chart: Dictionary = final_commit.get("chart", {})
	var final_entered: Dictionary = game._mark_campaign_chart_in_run(final_chart)
	game.campaign_state = final_entered.state
	# A malformed pre-settlement satchel is reconciled by the real Game target path.
	game.materials = {"oath_nail": 9, "starheart_coal": 7}
	var settled: Dictionary = game.resolve_campaign_boss_death(final_chart)
	var settled_again: Dictionary = game.resolve_campaign_boss_death(final_chart)
	_check("canonical Jarl settlement exact-targets Nail and Starheart and remains idempotent",
		bool(settled.get("changed", false)) and not bool(settled_again.get("changed", true))
			and game.material_count("oath_nail") == 0 and game.material_count("starheart_coal") == 1
			and CampaignData.chapter_cleared(game.campaign_state, CampaignData.PALE_OATH)
			and (game.campaign_state.relics as Array).count("pale_root_rune") == 1
			and (game.campaign_state.threads as Array).count("past_thread") == 1
			and (game.campaign_state.restorations as Array).count("rootroad_lift") == 1,
		{"settled": settled, "materials": game.materials, "state": game.campaign_state})
	game.free()


func _test_driving_volley_lodge_does_not_overwrite_loadout() -> void:
	var game := _new_game()
	game.trades.huntcraft = {"xp": Progression.xp_for_level(18), "lv": 18}
	game.owned_skills = ["PowerShot", "MultiShot", "BrambleSnare"]
	game.loadout = ["PowerShot", "MultiShot", "BrambleSnare"]
	var before: Array = game.loadout.duplicate()
	var status: Dictionary = game.driving_volley_lesson_status()
	var accepted: Dictionary = game.accept_driving_volley_lesson()
	var repeated: Dictionary = game.accept_driving_volley_lesson()
	_check("Driving Volley Lodge lesson defers without overwriting a full loadout",
		bool(status.get("available", false)) and bool(status.get("loadout_full", false))
			and bool(accepted.get("ok", false)) and bool(accepted.get("deferred", false))
			and game.skill_owned("DrivingVolley") and game.loadout == before
			and bool(game.seen_hints.get("driving_volley_lesson_completed", false))
			and not bool(repeated.get("changed", true)),
		{"status": status, "accepted": accepted, "repeated": repeated})
	game.free()
