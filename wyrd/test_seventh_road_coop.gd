extends SceneTree

const CampaignData = preload("res://data/campaign.gd")

var _pass := 0
var _fail := 0


func _check(name: String, ok: bool, detail = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % name)
	else:
		_fail += 1
		print("  ✗ %s %s" % [name, str(detail)])


func _init() -> void:
	call_deferred("_run")


func _cleared_state() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id in CampaignData.CHAPTER_ORDER:
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
	state.relics = ["green_root_rune", "mist_root_rune", "fang_root_rune"]
	state.restorations = ["trophy_hall", "sallow_jetty", "skald_archive"]
	return CampaignData.normalize_campaign_state(state)


func _run() -> void:
	print("--- Seventh Road co-op projection ---")
	var game: Node = root.get_node("Game")
	var net: Node = root.get_node("NetGame")
	var campaign_saved: Dictionary = game.campaign_state.duplicate(true)
	var materials_saved: Dictionary = game.materials.duplicate(true)
	var sources_saved: Array = game.chart_source_unlocks.duplicate()
	var journal_saved: Dictionary = game.chart_recipe_journal.duplicate(true)
	var recipes_saved: Array = game.known_chart_recipes.duplicate()
	var trades_saved: Dictionary = game.trades.duplicate(true)
	var persistence_saved := bool(game.persistence_enabled)
	var active_saved := bool(net.active)
	var peer_saved: MultiplayerPeer = net.multiplayer.multiplayer_peer
	var settlement_saved: Dictionary = (net.get("_settlement_view") as Dictionary).duplicate(true)
	var homecoming_saved: Dictionary = (net.get("_homecoming_view") as Dictionary).duplicate(true)
	# Closures capture scalar locals by value in GDScript; keep the probe in a
	# reference container so the lifecycle assertion observes emitted signals.
	var signal_count := [0]
	var on_settlement := func() -> void: signal_count[0] += 1
	net.settlement_view_changed.connect(on_settlement)

	game.campaign_state = _cleared_state()
	var host_before: Dictionary = game.campaign_state.duplicate(true)
	var host_view: Dictionary = game.campaign_settlement_view()
	_check("host projection includes Archive and Fang Rune without mutation",
		bool(host_view.seventh_road.visible)
		and bool(host_view.seventh_road.relic_visible)
		and String(host_view.seventh_road.restoration_id) == "skald_archive"
		and int(host_view.seventh_road.clue_count) == 4
		and game.campaign_state == host_before)
	_check("shared-campaign policy keeps clue, escrow, and settlement host-only",
		game.campaign_settlement_allowed(true, true)
		and not game.campaign_settlement_allowed(true, false))

	net._sync_settlement_view(host_view)
	_check("offline or host-side snapshot reads fail closed",
		net.settlement_view_snapshot().is_empty())
	_check("join clears stale Archive and Homecoming truth",
		net.join("127.0.0.1", 7777)
		and (net.get("_settlement_view") as Dictionary).is_empty()
		and (net.get("_homecoming_view") as Dictionary).is_empty())
	game.campaign_state = CampaignData.empty_state()
	var unavailable: Dictionary = game.campaign_settlement_view()
	_check("guest fails closed before host projection arrives",
		not bool(unavailable.available) and bool(unavailable.guest)
		and bool(unavailable.read_only))

	game.persistence_enabled = false
	game.chart_source_unlocks = ["skald_queens_summit"]
	game.known_chart_recipes.erase("queens_summit")
	game.chart_recipe_journal = {"version": 1, "rumours": [], "discoveries": {}}
	game.trades.wayfinding = {"xp": 0, "lv": 16}
	game.materials = {}
	var guest_source_before := {
		"materials": game.materials.duplicate(true),
		"journal": game.chart_recipe_journal.duplicate(true),
	}
	var guest_read: Dictionary = game.read_chart_source("skald_queens_summit")
	_check("guest Atlas and Archive sources are copy-only",
		not bool(guest_read.get("ok", true))
		and bool(guest_read.get("read_only", false))
		and game.materials == guest_source_before.materials
		and game.chart_recipe_journal == guest_source_before.journal)

	net._sync_settlement_view(host_view)
	var guest_before: Dictionary = game.campaign_state.duplicate(true)
	var guest_view: Dictionary = game.campaign_settlement_view()
	var guest_seventh: Dictionary = guest_view.chapters.seventh_road
	_check("guest mirrors Archive truth read-only with no local campaign repair",
		bool(guest_view.seventh_road.visible) and bool(guest_view.guest)
		and bool(guest_seventh.guest) and bool(guest_seventh.read_only)
		and not bool((guest_seventh.debrief_event as Dictionary).available)
		and game.campaign_state == guest_before)
	var caller_copy: Dictionary = net.settlement_view_snapshot()
	(caller_copy.seventh_road as Dictionary).visible = false
	_check("caller mutation cannot alter host-derived Archive snapshot",
		bool((net.settlement_view_snapshot() as Dictionary).seventh_road.visible))

	var signals_before_end := int(signal_count[0])
	net._end("test cleanup")
	_check("session end synchronously revokes Archive projection",
		(net.get("_settlement_view") as Dictionary).is_empty()
		and int(signal_count[0]) > signals_before_end)

	net.settlement_view_changed.disconnect(on_settlement)
	game.campaign_state = campaign_saved
	game.materials = materials_saved
	game.chart_source_unlocks = sources_saved
	game.chart_recipe_journal = journal_saved
	game.known_chart_recipes = recipes_saved
	game.trades = trades_saved
	game.persistence_enabled = persistence_saved
	net.active = active_saved
	net.multiplayer.multiplayer_peer = peer_saved
	net._sync_settlement_view(settlement_saved)
	net._sync_homecoming_view(homecoming_saved)
	print("--- Seventh co-op: %d PASS, %d FAIL ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
