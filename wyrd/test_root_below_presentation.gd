extends SceneTree

# Root Below's physical Loom and Atlas are presentation adapters. This gate
# proves their one narrow seam: canonical Fire settlement makes the source and
# 0/5 Atlas road visible; Game owns the first lesson, Codex knowledge, Mara's
# ordinary refill, and every later Map ritual.

const CampaignData = preload("res://data/campaign.gd")
const ChartsData = preload("res://data/charts.gd")
const Progression = preload("res://data/progression.gd")
const CraftingBenchScript = preload("res://scripts/ui/crafting_bench.gd")

var _pass := 0
var _fail := 0


func _check(label: String, ok: bool, detail = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % label)
	else:
		_fail += 1
		print("  ✗ %s %s" % [label, str(detail)])


func _initialize() -> void:
	call_deferred("_run")


func _fire_settled(waymarks: int = 0) -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id_v in CampaignData.CHAPTER_ORDER:
		var chapter_id := String(chapter_id_v)
		if chapter_id == CampaignData.UNWRITTEN_ROAD:
			break
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
		for index in int(chapter.clue_count):
			chapter.banked_chart_ids.append("%s-%d" % [chapter_id, index])
	var road: Dictionary = state.chapters[CampaignData.UNWRITTEN_ROAD]
	road.clue_count = clampi(waymarks, 0,
		int(CampaignData.CHAPTERS[CampaignData.UNWRITTEN_ROAD].clue_target))
	for index in int(road.clue_count):
		road.banked_chart_ids.append("unwritten-road-%d" % index)
	state.relics = ["green_root_rune", "mist_root_rune", "fang_root_rune",
		"crown_root_rune", "pale_root_rune", "ember_root_rune"]
	state.threads = ["past_thread", "present_thread"]
	state.restorations = ["trophy_hall", "sallow_jetty", "skald_archive",
		"pale_stair", "rootroad_lift", "ember_kiln"]
	return CampaignData.normalize_campaign_state(state)


func _root_below_ghost() -> Dictionary:
	return {"grid": {"n": "lost_waymark_tracing", "c": "nine_knot_leaf",
		"w": "threefold_binding"}, "ink_rail": ["hedge_ink"]}


func _run() -> void:
	print("--- Root Below presentation ---")
	var game: Node = root.get_node("Game")
	var campaign_saved: Dictionary = game.campaign_state.duplicate(true)
	var materials_saved: Dictionary = game.materials.duplicate(true)
	var sources_saved: Array = game.chart_source_unlocks.duplicate()
	var recipes_saved: Array = game.known_chart_recipes.duplicate()
	var journal_saved: Dictionary = game.chart_recipe_journal.duplicate(true)
	var trades_saved: Dictionary = game.trades.duplicate(true)
	var gold_saved := int(game.gold)
	var tutorial_saved := int(game.tutorial_step)
	var modal_saved := int(game.modal_count)
	var persistence_saved := bool(game.persistence_enabled)
	game.persistence_enabled = false
	game.campaign_state = _fire_settled()
	# One tracing is already held: the lesson must top up only the two missing
	# pieces, while ordinary Hedge Ink remains a normal table supply.
	game.materials = {"lost_waymark_tracing": 1, "hedge_ink": 1}
	game.gold = 100
	game.chart_source_unlocks = []
	game.known_chart_recipes = []
	game.chart_recipe_journal = ChartsData.fresh_recipe_journal()
	game.trades.wayfinding = {"xp": Progression.xp_for_level(22), "lv": 22}
	game.tutorial_step = 7
	game.modal_count = 1 # keep settlement debrief copy outside this source gate
	game._sync_campaign_chart_sources()
	var campaign_before: Dictionary = game.campaign_state.duplicate(true)
	var codex_before := ChartsData.codex_entry("root_below", game.chart_table_context())

	change_scene_to_file("res://scenes/Town.tscn")
	await process_frame
	await process_frame
	await process_frame
	var town := current_scene
	var kiln := town.get_node_or_null("EmberKiln") as Node3D if town != null else null
	var foundation := kiln.get_node_or_null("ThreefoldLoomFoundation") as Node3D \
		if kiln != null else null
	var loom := foundation.get_node_or_null("ThreefoldLoomSource") as Node3D \
		if foundation != null else null
	var atlas := town.get_node_or_null("AtlasDeepRumourSource") if town != null else null
	var scanner_gap := 0.0
	if kiln != null and loom != null and kiln.has_method("get_collision_radius") \
			and loom.has_method("get_collision_radius"):
		scanner_gap = kiln.global_position.distance_to(loom.global_position) \
			- float(kiln.call("get_collision_radius")) \
			- float(loom.call("get_collision_radius"))
	_check("settled Ember Kiln mounts exactly one readable Loom on its foundation",
		kiln != null and foundation != null and loom != null
			and loom.is_in_group("threefold_loom_source")
			and foundation.find_children("ThreefoldLoomSource", "", true, false).size() == 1)
	_check("the Loom is a distinct scanner and solid target outside D7 Kiln range",
		scanner_gap > 0.01 and loom != null and int(loom.get("collision_layer")) == 32
			and float(loom.call("get_solid_radius")) > 0.0,
		{"scanner_gap": scanner_gap})
	_check("generic Codex keeps Root Below unknown before the authored lesson",
		String(codex_before.get("state", "")) == "unknown"
			and (codex_before.get("ghost_draft", {}) as Dictionary).is_empty(), codex_before)

	var status := loom.call("source_status") as Dictionary if loom != null else {}
	_check("canonical Fire settlement and Wayfinding 22 make only the Loom lesson eligible",
		String(status.get("state", "")) == "eligible"
			and String(status.get("source_id", "")) == "threefold_loom_root_below"
			and String(status.get("recipe_id", "")) == "root_below", status)
	var caller_copy := status.duplicate(true)
	caller_copy["state"] = "locked"
	_check("the source exposes a copied Game status rather than mutable local truth",
		String((loom.call("source_status") as Dictionary).get("state", "")) == "eligible")
	var net: Node = root.get_node_or_null("NetGame")
	var net_active_before := bool(net.get("active")) if net != null else false
	var peer_before = net.multiplayer.multiplayer_peer if net != null else null
	var guest_materials: Dictionary = game.materials.duplicate(true)
	var guest_read: Dictionary = {}
	if net != null:
		var guest_peer := ENetMultiplayerPeer.new()
		guest_peer.create_client("127.0.0.1", 7777)
		net.multiplayer.multiplayer_peer = guest_peer
		net.set("active", true)
		guest_read = loom.call("read_now") as Dictionary if loom != null else {}
		net.set("active", net_active_before)
		net.multiplayer.multiplayer_peer = peer_before
	_check("guest Loom inspection is host-authoritative and mutation-free",
		bool(guest_read.get("read_only", false)) and not bool(guest_read.get("changed", false))
			and game.materials == guest_materials, guest_read)
	var first_read := loom.call("read_now") as Dictionary if loom != null else {}
	var codex_after := ChartsData.codex_entry("root_below", game.chart_table_context())
	_check("host Loom read applies Game's missing-only source lesson once",
		bool(first_read.get("changed", false))
			and first_read.get("granted", {}) == {"nine_knot_leaf": 1,
				"threefold_binding": 1}
			and String(first_read.get("recipe_granted", "")) == "root_below"
			and String((game.chart_recipe_journal.discoveries as Dictionary)
				.get("root_below", "")) == "source_lesson", first_read)
	_check("the generic Codex now owns Root Below's exact ghost pattern",
		String(codex_after.get("state", "")) == "known"
			and String(codex_after.get("provenance", "")) == "source_lesson"
			and String(codex_after.get("source", "")) == "Read from an authored world source"
			and codex_after.get("ghost_draft", {}) == _root_below_ghost(), codex_after)

	var bench: CanvasLayer = CraftingBenchScript.new()
	town.add_child(bench)
	await process_frame
	await process_frame
	bench.call("open_codex_page", "root_below")
	var staged := bool(bench.call("stage_all_known_recipe"))
	_check("the ordinary Chart Table stages the known Root Below ghost without a Map ritual",
		staged and bench.get("draft") == _root_below_ghost()
			and not (bench.get("draft") as Dictionary).get("grid", {}).has("s"),
		bench.get("draft"))
	bench.call("close")
	await process_frame

	# Re-reading cannot replenish the lesson. Once a normal table use has spent
	# a piece, Mara's priced supply drawer — not the Loom — performs the refill.
	game.materials["nine_knot_leaf"] = 0
	var no_refill := loom.call("read_now") as Dictionary if loom != null else {}
	var gold_before_refill := int(game.gold)
	var mara_refill: bool = bool(game.buy_chart_component("nine_knot_leaf", 1))
	_check("Loom rereads stay inert; Mara refills its ordinary component at the authored price",
		not bool(no_refill.get("changed", false)) and game.material_count("nine_knot_leaf") == 1
			and mara_refill and int(game.gold) == gold_before_refill
				- ChartsData.component_supply_price("nine_knot_leaf"), no_refill)

	var atlas_before: Dictionary = game.campaign_state.duplicate(true)
	var mark := atlas.get_node_or_null("UnwrittenRoadAtlasMark") if atlas != null else null
	var label := mark.get_node_or_null("UnwrittenRoadLabel") as Label3D if mark != null else null
	_check("Living Atlas reads the settlement projection as the initial 0/5 Road mark",
		atlas != null and atlas.unwritten_road_settlement_visible() and mark != null
			and label != null and label.text == "UNWRITTEN ROAD  ·  0/5 WAYMARKS")
	game.campaign_state = _fire_settled(5)
	var five_before: Dictionary = game.campaign_state.duplicate(true)
	if town != null:
		town.call("_refresh_campaign_settlement_view")
	await process_frame
	await process_frame
	mark = atlas.get_node_or_null("UnwrittenRoadAtlasMark") if atlas != null else null
	label = mark.get_node_or_null("UnwrittenRoadLabel") as Label3D if mark != null else null
	_check("Atlas updates the same stable mark through 5/5 without writing campaign truth",
		mark != null and label != null and label.text == "UNWRITTEN ROAD  ·  5/5 WAYMARKS"
			and game.campaign_state == five_before and atlas_before != game.campaign_state,
		{"label": label.text if label != null else "", "view": game.campaign_settlement_view()})

	# D8 Slice 4 keeps this same physical source after the folio has settled.
	# Reaching Map readiness changes the panel it opens, never the number of
	# Loom scanners, foundations, or Town interaction authorities.
	game.trades.wayfinding = {"xp": Progression.xp_for_level(23), "lv": 23}
	if loom != null:
		loom.call("interact", null)
		loom.call("interact", null)
	await process_frame
	await process_frame
	var ritual_panel := get_first_node_in_group("MapRitualPanel")
	var ritual_button := ritual_panel.find_child("TraceMapButton", true, false) as Button \
		if ritual_panel != null else null
	_check("the Town retains one Loom scanner and opens one explicit Map panel at ritual readiness",
		foundation != null and foundation.find_children("ThreefoldLoomSource", "", true, false).size() == 1
			and get_nodes_in_group("threefold_loom_source").size() == 1
			and ritual_panel != null and ritual_button != null and not ritual_button.disabled)
	if ritual_panel != null and ritual_panel.has_method("_close"):
		ritual_panel.call("_close")
	await process_frame

	if town != null:
		town.free()
	await process_frame
	game.campaign_state = campaign_saved
	game.materials = materials_saved
	game.chart_source_unlocks = sources_saved
	game.known_chart_recipes = recipes_saved
	game.chart_recipe_journal = journal_saved
	game.trades = trades_saved
	game.gold = gold_saved
	game.tutorial_step = tutorial_saved
	game.modal_count = modal_saved
	game.persistence_enabled = persistence_saved
	_check("Loom and Atlas presentation never change the initial canonical Fire settlement",
		campaign_before == _fire_settled())
	print("--- Root Below presentation: %d PASS, %d FAIL ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
