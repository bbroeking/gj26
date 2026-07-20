extends SceneTree

const CampaignData = preload("res://data/campaign.gd")

var _pass := 0
var _fail := 0


func _check(label: String, condition: bool, detail = "") -> void:
	if condition:
		_pass += 1
		print("  ✓ %s" % label)
	else:
		_fail += 1
		print("  ✗ %s %s" % [label, str(detail)])


func _cleared_state(include_queen: bool) -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id in CampaignData.CHAPTER_ORDER:
		if chapter_id == CampaignData.QUEENS_SUMMIT and not include_queen:
			continue
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
	state.relics = ["green_root_rune", "mist_root_rune", "fang_root_rune"]
	state.restorations = ["trophy_hall", "sallow_jetty", "skald_archive"]
	if include_queen:
		state.relics.append("crown_root_rune")
		state.restorations.append("pale_stair")
	return CampaignData.normalize_campaign_state(state)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("--- Queen's Summit co-op authority ---")
	var game: Node = root.get_node("Game")
	var net: Node = root.get_node("NetGame")
	var campaign_saved: Dictionary = game.campaign_state.duplicate(true)
	var active_saved := bool(net.active)
	var peer_saved: MultiplayerPeer = net.multiplayer.multiplayer_peer
	var settlement_saved: Dictionary = (net.get("_settlement_view") as Dictionary).duplicate(true)
	var homecoming_saved: Dictionary = (net.get("_homecoming_view") as Dictionary).duplicate(true)
	var persistence_saved := bool(game.persistence_enabled)
	game.persistence_enabled = false
	game.campaign_state = _cleared_state(true)
	var host_view: Dictionary = game.campaign_settlement_view()
	_check("host Queen projection names Crown Rune and Pale Stair",
		bool(host_view.chapters.queens_summit.visible)
			and bool(host_view.chapters.queens_summit.relic_visible)
			and String(host_view.chapters.queens_summit.relic_id) == "crown_root_rune"
			and String(host_view.chapters.queens_summit.restoration_id) == "pale_stair")

	net._sync_settlement_view(host_view)
	_check("joining as guest revokes stale settlement truth",
		net.join("127.0.0.1", 7777)
			and (net.get("_settlement_view") as Dictionary).is_empty())
	game.campaign_state = _cleared_state(false)
	var before_guest: Dictionary = game.campaign_state.duplicate(true)
	var guest_return: Dictionary = game._record_campaign_chart_return({
		"recipe_id": "summit_approach", "chart_instance_id": "guest-approach",
	})
	var guest_death: Dictionary = game.resolve_campaign_boss_death({
		"recipe_id": CampaignData.QUEENS_SUMMIT_BOSS_RECIPE,
		"chart_instance_id": "guest-queen",
		"campaign_contract": CampaignData.boss_contract(
			CampaignData.QUEENS_SUMMIT_BOSS_RECIPE),
	})
	_check("guest cannot bank Crown-Thorns or settle the Queen",
		not bool(guest_return.get("changed", false))
			and String(guest_death.get("reason", "")) == "host_only"
			and game.campaign_state == before_guest)

	net._sync_settlement_view(host_view)
	var guest_view: Dictionary = game.campaign_settlement_view()
	var queen: Dictionary = guest_view.chapters.queens_summit
	_check("guest mirrors host Queen settlement as copy-only",
		bool(queen.visible) and bool(queen.guest) and bool(queen.read_only)
			and not bool((queen.debrief_event as Dictionary).available)
			and game.campaign_state == before_guest)
	var caller_copy: Dictionary = net.settlement_view_snapshot()
	(caller_copy.chapters.queens_summit as Dictionary).visible = false
	_check("guest caller cannot mutate the host-derived Queen snapshot",
		bool((net.settlement_view_snapshot().chapters.queens_summit as Dictionary).visible))

	net._end("queen test cleanup")
	_check("session loss synchronously clears the Queen projection",
		(net.get("_settlement_view") as Dictionary).is_empty())

	game.campaign_state = campaign_saved
	game.persistence_enabled = persistence_saved
	net.active = active_saved
	net.multiplayer.multiplayer_peer = peer_saved
	net._sync_settlement_view(settlement_saved)
	net._sync_homecoming_view(homecoming_saved)
	print("--- Queen co-op: %d PASS, %d FAIL ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
