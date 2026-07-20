extends SceneTree

# Regression seam for the D7 late-road Ink economy.  This starts at a declared
# Town-only Wayfinding-21 boundary: all pre-Fire chapters are already settled,
# but the satchel contains no Ink or raw inputs.  From that point on this test
# delegates every material and Trade mutation to the shipped GatherNode scanner
# interaction and the physical Chart Table/Copper Pot helpers.  The browser
# marathon owns the full 25/20/24 chapter shelves; this unit seam proves one
# exact physical Hedge pot and locks the authored advanced-recipes plus their
# data-derived shelf math without turning a native gate into a multi-minute
# replay.  It deliberately never writes inventory, Trade XP, Charts, or
# campaign truth after the boundary is installed.

const CampaignData = preload("res://data/campaign.gd")
const ChartsData = preload("res://data/charts.gd")
const GatherDefs = preload("res://data/gather.gd")
const Progression = preload("res://data/progression.gd")

var passed := 0
var failed := 0
var material_change_count := 0
var xp_events: Array = []


func check(label: String, ok: bool, detail = "") -> void:
	if ok:
		passed += 1
		print("  ✓ %s" % label)
	else:
		failed += 1
		print("  ✗ %s %s" % [label, str(detail)])


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	print("--- D7 renewable Ink economy native seam ---")
	var game = root.get_node_or_null("Game")
	_install_level_21_town_fixture(game)
	# The helpers are query-gated release QA drivers, but this unique stage has
	# no scene-transition branch.  It lets their normal failure reporting remain
	# visible without starting the marathon beside this focused regression.
	game.web_smoke_enabled = true
	game.web_smoke_d7_enabled = true
	game.web_smoke_phase = "ink_economy"
	game._web_smoke_d7_stage = "ink_economy"
	game._web_smoke_d7_training_seen_kinds = {}
	game.web_smoke_features = {}
	game.modal_count = 0
	paused = false
	Engine.time_scale = 1.0
	# Test-only dwell acceleration. GatherNode still owns scanner acquisition,
	# channel completion, depletion, yield, Trade XP, and respawn; this simply
	# prevents one-pot regression coverage from waiting on presentation timing.
	OS.set_environment("WYRD_FAST_CHANNEL", "1")

	change_scene_to_file("res://scenes/Town.tscn")
	await process_frame
	await process_frame
	await process_frame
	# Match the released driver: Town needs one short settle before the player
	# scanner owns its initial interactable.
	await create_timer(0.8, true).timeout
	# A completed late-story fixture projects its real Golden Wallow debrief.
	# Acknowledge that production-owned page through the same D7 control seam a
	# player/browser route uses; no campaign or inventory state is mutated here.
	await game._wait_d7_town_control()

	check("the level-21 fixture reached the authored Town table with no seeded Ink",
		get_nodes_in_group("inscribing_table").size() == 1
			and _ink_counts(game) == {"hedge_ink": 0, "refined_ink": 0,
				"stoneground_ink": 0, "ash_ink": 0}
			and game.trade_lv("wayfinding") == 21
			and game.trade_lv("earthcraft") == 3
			and game.trade_lv("wildcraft") == 1
			and game.trade_lv("huntcraft") == 1
			and CampaignData.chapter_cleared(game.campaign_state, CampaignData.PALE_OATH)
			and not CampaignData.chapter_cleared(game.campaign_state,
				CampaignData.FIRE_IN_THE_BOUGH), {
			"tables": get_nodes_in_group("inscribing_table").size(),
			"inks": _ink_counts(game), "trades": game.trades,
			"campaign": game.campaign_state,
		})
	check("the production settlement debrief was acknowledged before scanner input",
		game.modal_count == 0 and not paused
			and get_nodes_in_group("GoldenWallowSettlementDebrief").is_empty(), {
			"modal_count": game.modal_count, "paused": paused,
			"golden_debriefs": get_nodes_in_group("GoldenWallowSettlementDebrief").size(),
		})

	# The broad fixture begins at Wildcraft 1 to prove no Ink was seeded. Move
	# only to Golden's real support-Trade gate before testing its locked Town
	# patch; every XP point after this boundary must still come from GatherNode.
	game.trades.wildcraft = {"xp": Progression.xp_for_level(10), "lv": 10}
	var protected_before := _protected_state(game)
	var xp_before := _xp_state(game)
	game.materials_changed.connect(_on_materials_changed)
	game.xp_gained.connect(_on_xp_gained)

	# The chapter shelf math must stay data-derived.  At Wayfinding 21,
	# Thrifty Quill is active, so these must *not* fossilize pre-perk values.
	var queen_direct := _direct_hedge_cost(game, "summit_approach", 4,
		"queens_summit_boss")
	var queen_runway: int = int(game._d7_hedge_runway("summit_approach", 4,
		"queens_summit_boss", {"refined_ink": 5}))
	var pale_direct := _direct_hedge_cost(game, "pale_veins", 4,
		"pale_oath_boss")
	var pale_runway: int = int(game._d7_hedge_runway("pale_veins", 4, "pale_oath_boss"))
	var fire_direct := _direct_hedge_cost(game, "ashen_bough", 5,
		"fire_in_the_bough_boss")
	var fire_runway: int = int(game._d7_hedge_runway("ashen_bough", 5,
		"fire_in_the_bough_boss"))
	var refined_hedge_input := _ink_input("refined_ink", "hedge_ink")

	check("dynamic chapter runways include current Table costs and mixed-Ink inputs",
		queen_runway == queen_direct + 5 * refined_hedge_input
			and pale_runway == pale_direct
			and fire_runway == fire_direct
			and queen_runway == 25 and pale_runway == 20 and fire_runway == 24, {
			"queen": {"runway": queen_runway, "direct": queen_direct,
				"refined_hedge_input": refined_hedge_input},
			"pale": {"runway": pale_runway, "direct": pale_direct},
			"fire": {"runway": fire_runway, "direct": fire_direct},
		})

	# Tight red-capable reproduction for late Town: one authored wild-herb node,
	# one production scanner interaction.  Do not broaden this into a whole Ink
	# run until this reports the exact acquisition failure (if any).
	var herb: Node3D = _unused_wild_herb()
	var player := game.local_player() as Node3D
	var wild_before: int = int(game.material_count("wild_herb"))
	var scanner_result: bool = false
	if herb != null:
		herb.set("respawn_sec", 0.01)
		herb.set("_tier_channel", 0.01)
		scanner_result = bool(await game._d7_scanner_harvest(herb, "wild_herb", 1200))
	var scanner_ok: bool = herb != null and player != null and scanner_result \
		and game.material_count("wild_herb") > wild_before
	var scanner_detail = {} if scanner_ok else {
		"player_position": player.global_position if player != null else "missing",
		"active_target": player.get("_active_interactable") if player != null else "missing",
		"herb_position": herb.global_position if herb != null else "missing",
		"herb_used": bool(herb.call("is_used")) if herb != null else "missing",
		"scanner_result": scanner_result,
		"wild_before": wild_before, "wild_after": game.material_count("wild_herb"),
	}
	check("late-Town wild herb completes through the production scanner path",
		scanner_ok, scanner_detail)
	var mothmint_before: int = int(game.material_count("mothmint"))
	var mothmint_harvested: bool = bool(
		await game._d7_training_harvest_town("mothmint", 1))
	check("Golden's renewable Town Mothmint closes a zero-World-drop boss-Ink gap",
		mothmint_harvested and game.material_count("mothmint") >= mothmint_before + 1,
		{"before": mothmint_before, "after": game.material_count("mothmint")})
	var hedge_before: int = int(game.material_count("hedge_ink"))
	var hedge_made: bool = bool(await game._d7_training_make_hedge_ink(1))
	check("one Hedge Ink pot settles through the physical Chart Table and Copper Pot",
		hedge_made and game.material_count("hedge_ink") == hedge_before + 1
			and game.ink_discovered("hedge_ink"), _ink_counts(game))

	check("Refined, Stoneground, and Ash retain their authored renewable input contracts",
		(GatherDefs.INK_RECIPES["refined_ink"].inputs as Dictionary) == {
			"hedge_ink": 2, "bogiron_ore": 1}
			and (GatherDefs.INK_RECIPES["stoneground_ink"].inputs as Dictionary) == {
				"bogiron_ore": 2}
			and (GatherDefs.INK_RECIPES["ash_ink"].inputs as Dictionary) == {
				"logs": 2, "wild_herb": 1}, {
			"refined": GatherDefs.INK_RECIPES["refined_ink"].inputs,
			"stoneground": GatherDefs.INK_RECIPES["stoneground_ink"].inputs,
			"ash": GatherDefs.INK_RECIPES["ash_ink"].inputs,
		})

	check("the physical scanner-and-pot proof produced satchel deltas without a direct grant",
		material_change_count > 0 and game.material_count("wild_herb") > wild_before
			and game.material_count("hedge_ink") == 1, {
			"materials": game.materials, "material_changes": material_change_count,
		})

	var xp_after := _xp_state(game)
	check("all post-boundary Trade XP came from the scanner gather channels",
		_xp_delta_matches_events(xp_before, xp_after)
			and _only_gather_trade_events()
			and int(xp_after.get("wildcraft", 0)) > int(xp_before.get("wildcraft", 0))
			and int(xp_after.get("earthcraft", 0)) == int(xp_before.get("earthcraft", 0))
			and int(xp_after.get("wayfinding", 0)) == int(xp_before.get("wayfinding", 0))
			and int(xp_after.get("huntcraft", 0)) == int(xp_before.get("huntcraft", 0)), {
			"before": xp_before, "after": xp_after, "events": xp_events,
		})

	check("the Ink loop did not directly alter inventory, Charts, or campaign truth",
		_protected_state(game) == protected_before
			and game.web_smoke_phase != "failed", {
			"before": protected_before, "after": _protected_state(game),
			"phase": game.web_smoke_phase,
		})

	game.web_smoke_d7_enabled = false
	game.web_smoke_enabled = false
	await shutdown_runtime()
	print("--- D7 renewable Ink economy: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _install_level_21_town_fixture(game) -> void:
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.persistence_enabled = false
	game.tutorial_step = 7
	game.seen_hints = {"chart_table_snug_returned": true, "bench": true,
		"forage_node": true, "ore_rock": true, "log_pile": true,
		"affix_reading": true}
	game.materials = {}
	game.charts = []
	game.active_chart = {}
	game.gold = 0
	game.discovered_inks = ["hedge_ink"]
	# Ink mixing is independent of the recipe ledger.  Keep its normal
	# post-onboarding two-recipe drawer so the focused test cannot pay UI build
	# time for every late Chart while asserting an Ink-only economy seam.
	game.known_chart_recipes = ChartsData.starting_recipe_ids()
	game.chart_recipe_journal = ChartsData.normalize_recipe_journal(
		ChartsData.fresh_recipe_journal(), game.known_chart_recipes)
	game.chart_source_unlocks = []
	game.chosen_perks = {}
	game.trades = Progression.fresh_trade_state()
	game.trades["wayfinding"] = {"xp": Progression.xp_for_level(21), "lv": 21}
	# Bogiron is the first physical input for Refined/Stoneground Ink.  Its
	# production node gates at Earthcraft 3; the other support Trades begin
	# untouched so their observed XP deltas remain scanner-owned evidence.
	game.trades["earthcraft"] = {"xp": Progression.xp_for_level(3), "lv": 3}
	game.campaign_state = _settled_pre_fire_campaign()


func _settled_pre_fire_campaign() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id_v in [CampaignData.FIRST_KNOT, CampaignData.GOLDEN_WALLOW,
			CampaignData.SEVENTH_ROAD, CampaignData.QUEENS_SUMMIT, CampaignData.PALE_OATH]:
		var chapter_id := String(chapter_id_v)
		var chapter: Dictionary = state.chapters[chapter_id]
		var definition: Dictionary = CampaignData.CHAPTERS[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(definition.get("clue_target", 0))
		var relic_id := String(definition.get("relic_id", ""))
		if relic_id != "":
			(state.relics as Array).append(relic_id)
		var restoration_id := String(definition.get("restoration_id", ""))
		if restoration_id != "":
			(state.restorations as Array).append(restoration_id)
		for thread_id_v in (definition.get("thread_awards", []) as Array):
			(state.threads as Array).append(String(thread_id_v))
	return CampaignData.normalize_campaign_state(state)


func _direct_hedge_cost(game, ordinary_recipe: String, ordinary_count: int,
		boss_recipe: String) -> int:
	return ordinary_count * game._d7_chart_material_cost(ordinary_recipe, "hedge_ink") \
		+ game._d7_chart_material_cost(boss_recipe, "hedge_ink")


func _ink_input(ink_id: String, material_id: String) -> int:
	var recipe: Dictionary = GatherDefs.INK_RECIPES.get(ink_id, {})
	return int((recipe.get("inputs", {}) as Dictionary).get(material_id, 0))


func _unused_wild_herb() -> Node3D:
	for node_v in get_nodes_in_group("interactable"):
		if not node_v is Node3D or not node_v.has_method("is_used") \
				or bool(node_v.call("is_used")):
			continue
		var item_id = node_v.get("item_id")
		if item_id != null and String(item_id) == "wild_herb":
			return node_v as Node3D
	return null


func _ink_counts(game) -> Dictionary:
	return {"hedge_ink": game.material_count("hedge_ink"),
		"refined_ink": game.material_count("refined_ink"),
		"stoneground_ink": game.material_count("stoneground_ink"),
		"ash_ink": game.material_count("ash_ink")}


func _xp_state(game) -> Dictionary:
	var out := {}
	for trade_id_v in Progression.TRADE_KEYS:
		var trade_id := String(trade_id_v)
		out[trade_id] = int((game.trades.get(trade_id, {}) as Dictionary).get("xp", 0))
	return out


func _protected_state(game) -> Dictionary:
	return {
		"inventory_rows": game.inventory.rows,
		"inventory_items": game.inventory.items.duplicate(true),
		"charts": game.charts.duplicate(true),
		"active_chart": game.active_chart.duplicate(true),
		"campaign": game.campaign_state.duplicate(true),
		"known_recipes": game.known_chart_recipes.duplicate(),
		"recipe_journal": game.chart_recipe_journal.duplicate(true),
	}


func _on_materials_changed() -> void:
	material_change_count += 1


func _on_xp_gained(trade_id: String, amount: int) -> void:
	xp_events.append({"trade": trade_id, "amount": amount})


func _only_gather_trade_events() -> bool:
	if xp_events.is_empty():
		return false
	for event_v in xp_events:
		var event: Dictionary = event_v
		if String(event.get("trade", "")) not in ["earthcraft", "wildcraft"] \
				or int(event.get("amount", 0)) <= 0:
			return false
	return true


func _xp_delta_matches_events(before: Dictionary, after: Dictionary) -> bool:
	var event_totals := {}
	for trade_id_v in Progression.TRADE_KEYS:
		event_totals[String(trade_id_v)] = 0
	for event_v in xp_events:
		var event: Dictionary = event_v
		var trade_id := String(event.get("trade", ""))
		if event_totals.has(trade_id):
			event_totals[trade_id] = int(event_totals[trade_id]) + int(event.get("amount", 0))
	for trade_id_v in Progression.TRADE_KEYS:
		var trade_id := String(trade_id_v)
		if int(after.get(trade_id, 0)) - int(before.get(trade_id, 0)) \
				!= int(event_totals.get(trade_id, 0)):
			return false
	return true


func shutdown_runtime() -> void:
	if current_scene != null:
		current_scene.queue_free()
		await process_frame
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("shutdown"):
		sfx.call("shutdown")
	Engine.time_scale = 1.0
	await create_timer(0.2, true, false, true).timeout
