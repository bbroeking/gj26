extends SceneTree

const CampaignData = preload("res://data/campaign.gd")
const Progression = preload("res://data/progression.gd")
const SkaldArchive = preload("res://scripts/skald_archive.gd")

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


func _queen_state() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id in [CampaignData.FIRST_KNOT, CampaignData.GOLDEN_WALLOW,
			CampaignData.SEVENTH_ROAD, CampaignData.QUEENS_SUMMIT]:
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
	state.relics = ["green_root_rune", "mist_root_rune", "fang_root_rune", "crown_root_rune"]
	state.restorations = ["trophy_hall", "sallow_jetty", "skald_archive", "pale_stair"]
	return CampaignData.normalize_campaign_state(state)


func _run() -> void:
	print("--- Pale Oath co-op projection ---")
	var game: Node = root.get_node("Game")
	var net: Node = root.get_node("NetGame")
	var campaign_saved: Dictionary = game.campaign_state.duplicate(true)
	var materials_saved: Dictionary = game.materials.duplicate(true)
	var sources_saved: Array = game.chart_source_unlocks.duplicate()
	var trades_saved: Dictionary = game.trades.duplicate(true)
	var journal_saved: Dictionary = game.chart_recipe_journal.duplicate(true)
	var persistence_saved := bool(game.persistence_enabled)
	var active_saved := bool(net.active)
	var peer_saved: MultiplayerPeer = net.multiplayer.multiplayer_peer
	var settlement_saved: Dictionary = (net.get("_settlement_view") as Dictionary).duplicate(true)
	game.persistence_enabled = false
	game.campaign_state = _queen_state()
	game.materials = {}
	game.chart_source_unlocks = ["skald_pale_oath"]
	game.trades.wayfinding = {"xp": Progression.xp_for_level(18), "lv": 18}
	game.chart_recipe_journal = {"version": 1, "rumours": [], "discoveries": {}}
	var host_view: Dictionary = net._with_archive_folio_projection(game.campaign_settlement_view())
	_check("host projection carries only a pale folio descriptor, not source authority",
		bool(host_view.archive_folios.pale_oath.visible)
		and not host_view.has("materials") and not host_view.has("chart_source_unlocks"))

	_check("joining clears stale Pale Oath projection before a host snapshot arrives",
		net.join("127.0.0.1", 7777) and (net.get("_settlement_view") as Dictionary).is_empty())
	game.campaign_state = CampaignData.empty_state()
	var guest_before: Dictionary = game.campaign_state.duplicate(true)
	var materials_before: Dictionary = game.materials.duplicate(true)
	net._sync_settlement_view(host_view)
	var guest_view: Dictionary = game.campaign_settlement_view()
	var archive: Node3D = SkaldArchive.new()
	archive.set_settlement_view(guest_view)
	root.add_child(archive)
	await process_frame
	var guest_read: Dictionary = archive.read_now()
	_check("guest mirrors host folio prose but cannot source, grant, or save",
		archive.pale_folio_visible() and archive.get_prompt_text() == "[E/A] Review the host's Pale Oath folio"
		and bool(guest_read.get("read_only", false)) and not bool(guest_read.get("changed", true))
		and game.campaign_state == guest_before and game.materials == materials_before)
	var caller_copy: Dictionary = net.settlement_view_snapshot()
	(caller_copy.archive_folios.pale_oath as Dictionary).visible = false
	_check("guest caller cannot mutate host-projected Pale folio visibility",
		bool((net.settlement_view_snapshot().archive_folios.pale_oath as Dictionary).visible))

	archive.free()
	net._end("pale oath test cleanup")
	_check("session end synchronously revokes Pale Oath projection",
		(net.get("_settlement_view") as Dictionary).is_empty())
	game.campaign_state = campaign_saved
	game.materials = materials_saved
	game.chart_source_unlocks = sources_saved
	game.trades = trades_saved
	game.chart_recipe_journal = journal_saved
	game.persistence_enabled = persistence_saved
	net.active = active_saved
	net.multiplayer.multiplayer_peer = peer_saved
	net._sync_settlement_view(settlement_saved)
	print("--- Pale Oath co-op: %d PASS, %d FAIL ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
