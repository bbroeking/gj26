extends SceneTree

# Pale Oath Town presenters are projections only.  Campaign/runtime coverage
# owns awards and escrow; this gate proves the physical Archive/Hall/Atlas/Lift
# read exactly one host-derived settlement snapshot and never mint a reward.

const CampaignData = preload("res://data/campaign.gd")
const Progression = preload("res://data/progression.gd")

var _pass := 0
var _fail := 0


func _check(name: String, ok: bool, detail = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % name)
	else:
		_fail += 1
		print("  ✗ %s %s" % [name, str(detail)])


func _initialize() -> void:
	call_deferred("_run")


func _state(cleared_pale: bool = false, rubbing_count: int = 0) -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id in [CampaignData.FIRST_KNOT, CampaignData.GOLDEN_WALLOW,
			CampaignData.SEVENTH_ROAD, CampaignData.QUEENS_SUMMIT]:
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
	var pale: Dictionary = state.chapters[CampaignData.PALE_OATH]
	pale.clue_count = rubbing_count
	pale.cleared = cleared_pale
	state.relics = ["green_root_rune", "mist_root_rune", "fang_root_rune", "crown_root_rune"]
	state.restorations = ["trophy_hall", "sallow_jetty", "skald_archive", "pale_stair"]
	if cleared_pale:
		state.relics.append("pale_root_rune")
		state.restorations.append("rootroad_lift")
		(state.threads as Array).append("past_thread")
	return CampaignData.normalize_campaign_state(state)


func _run() -> void:
	print("--- Pale Oath presentation ---")
	var game: Node = root.get_node("Game")
	var campaign_saved: Dictionary = game.campaign_state.duplicate(true)
	var materials_saved: Dictionary = game.materials.duplicate(true)
	var sources_saved: Array = game.chart_source_unlocks.duplicate()
	var recipes_saved: Array = game.known_chart_recipes.duplicate()
	var journal_saved: Dictionary = game.chart_recipe_journal.duplicate(true)
	var trades_saved: Dictionary = game.trades.duplicate(true)
	var persistence_saved := bool(game.persistence_enabled)
	game.persistence_enabled = false
	game.campaign_state = _state()
	game.materials = {}
	game.chart_source_unlocks = ["skald_pale_oath"]
	game.known_chart_recipes = []
	game.chart_recipe_journal = {"version": 1, "rumours": [], "discoveries": {}}
	game.trades.wayfinding = {"xp": Progression.xp_for_level(18), "lv": 18}
	var before_read: Dictionary = game.materials.duplicate(true)

	change_scene_to_file("res://scenes/Town.tscn")
	await process_frame
	await process_frame
	await process_frame
	var town := current_scene
	var archive := town.get_node_or_null("SkaldArchive") if town != null else null
	_check("canonical Queen plus Wayfinding 18 exposes one Pale Oath Archive folio",
		archive != null and archive.pale_folio_visible()
		and archive.pale_oath_presentation_ids().folio_id == "skald_pale_oath"
		and archive.get_prompt_text() == "[E/A] Read the Pale Oath folio")
	var read: Dictionary = archive.read_now() if archive != null else {}
	_check("host folio uses Game's atomic missing-only source transaction",
		bool(read.get("changed", false)) and game.materials != before_read
		and game.material_count("pale_wellmark") == 1
		and game.material_count("stoneground_ink") == 1)

	# Four returned ledger facts reveal the boss folio; the test does not insert
	# a Nail or settle anything.  The separate source remains the only reader.
	game.campaign_state = _state(false, 4)
	game.chart_source_unlocks = ["skald_pale_oath", "skald_pale_oath_boss"]
	game.trades.wayfinding = {"xp": Progression.xp_for_level(19), "lv": 19}
	archive.set_settlement_view(game.campaign_settlement_view())
	_check("fourth Oath-Rubbing projects a separate boss folio",
		archive.pale_boss_folio_visible()
		and archive.pale_oath_presentation_ids().boss_folio_id == "skald_pale_oath_boss"
		and "Four Oath-Rubbings" in " ".join(archive.review_pages()))
	var boss_read: Dictionary = archive.read_now()
	_check("boss folio reads its own source without duplicating the Oath Nail",
		bool(boss_read.get("changed", false)) and game.material_count("oath_nail") == 0
		and game.material_count("barrow_mark") == 1)

	game.campaign_state = _state(true, 4)
	var settled_before: Dictionary = game.campaign_state.duplicate(true)
	if town != null:
		town.call("_refresh_campaign_settlement_view")
	await process_frame
	await process_frame
	var hall := town.get_node_or_null("FirstKnotTrophyHall") if town != null else null
	var atlas := town.get_node_or_null("AtlasDeepRumourSource") if town != null else null
	var lift := town.get_node_or_null("RootroadLift") if town != null else null
	_check("one rootroad_lift projection materializes Hall, Atlas, Lift, and Hod oath-stone",
		hall != null and hall.get_node_or_null("PaleOathRecord") != null
		and hall.get_node_or_null("StarheartCoalRecord") != null
		and hall.get_node_or_null("PaleRootRune") != null
		and hall.get_node_or_null("PastThreadRecord") != null
		and hall.pale_oath_presentation_ids() == {
			"relic_id": "pale_root_rune", "restoration_id": "rootroad_lift",
			"material_record_id": "starheart_coal", "thread_record_id": "past_thread",
		}
		and atlas != null and atlas.pale_oath_settlement_visible()
		and atlas.get_node_or_null("PaleOathAtlasMark") != null
		and lift != null and lift.get_node_or_null("RootroadLiftWellhouse") != null
		and lift.get_node_or_null("HodOathstone") != null
		and lift.presentation_ids().restoration_id == "rootroad_lift"
		and game.campaign_state == settled_before)

	if town != null:
		town.free()
	await process_frame
	game.campaign_state = campaign_saved
	game.materials = materials_saved
	game.chart_source_unlocks = sources_saved
	game.known_chart_recipes = recipes_saved
	game.chart_recipe_journal = journal_saved
	game.trades = trades_saved
	game.persistence_enabled = persistence_saved
	print("--- Pale Oath presentation: %d PASS, %d FAIL ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
