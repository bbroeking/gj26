extends SceneTree

# Golden Wallow uses the neutral campaign settlement projection in shared Town.
# Run: WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_golden_wallow_coop.gd

const CampaignData = preload("res://data/campaign.gd")

var _pass := 0
var _fail := 0

func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % name)
	else:
		_fail += 1
		print("  ✗ %s %s" % [name, detail])

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- Golden Wallow co-op settlement projection ---")
	_test_host_guest_settlement_snapshot()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _golden_cleared_state() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id in [CampaignData.FIRST_KNOT, CampaignData.GOLDEN_WALLOW]:
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = 3
	state.relics = ["green_root_rune", "mist_root_rune"]
	state.restorations = ["trophy_hall", "sallow_jetty"]
	return CampaignData.normalize_campaign_state(state)

func _test_host_guest_settlement_snapshot() -> void:
	var game: Node = root.get_node("Game")
	var net: Node = root.get_node("NetGame")
	var campaign_saved: Dictionary = game.campaign_state.duplicate(true)
	var active_saved := bool(net.active)
	var peer_saved: MultiplayerPeer = net.multiplayer.multiplayer_peer
	var settlement_saved: Dictionary = (net.get("_settlement_view") as Dictionary).duplicate(true)
	var homecoming_saved: Dictionary = (net.get("_homecoming_view") as Dictionary).duplicate(true)
	var signals := {"settlement": 0, "homecoming": 0}
	var on_settlement := func() -> void: signals.settlement += 1
	var on_homecoming := func() -> void: signals.homecoming += 1
	net.settlement_view_changed.connect(on_settlement)
	net.homecoming_view_changed.connect(on_homecoming)

	game.campaign_state = _golden_cleared_state()
	var host_before: Dictionary = game.campaign_state.duplicate(true)
	var host_view: Dictionary = game.campaign_settlement_view()
	var host_golden: Dictionary = host_view.golden_wallow
	_check("Host derives Golden settlement without mutating campaign",
		bool(host_golden.visible) and bool(host_golden.relic_visible)
		and String(host_golden.restoration_id) == "sallow_jetty"
		and game.campaign_state == host_before, str(host_view))

	net._sync_settlement_view(host_view)
	_check("Offline/host snapshot reads fail closed", net.settlement_view_snapshot().is_empty())

	_check("Joining clears stale neutral and Homecoming projections",
		net.join("127.0.0.1", 7777)
		and (net.get("_settlement_view") as Dictionary).is_empty()
		and (net.get("_homecoming_view") as Dictionary).is_empty()
		and int(signals.settlement) >= 2 and int(signals.homecoming) >= 1)
	game.campaign_state = CampaignData.empty_state()
	var unavailable: Dictionary = game.campaign_settlement_view()
	_check("Guest fails closed before the host snapshot",
		not bool(unavailable.available) and bool(unavailable.guest)
		and bool(unavailable.read_only), str(unavailable))

	net._sync_settlement_view(host_view)
	var guest_before: Dictionary = game.campaign_state.duplicate(true)
	var guest_view: Dictionary = game.campaign_settlement_view()
	var nested_golden: Dictionary = guest_view.chapters.golden_wallow
	var nested_event: Dictionary = nested_golden.debrief_event
	_check("Guest consumes host settlement read-only without reconciling save",
		bool(guest_view.golden_wallow.visible) and bool(guest_view.guest)
		and bool(guest_view.read_only) and bool(nested_golden.guest)
		and bool(nested_golden.read_only) and not bool(nested_event.available)
		and game.campaign_state == guest_before,
		str(guest_view))
	var caller_copy: Dictionary = net.settlement_view_snapshot()
	(caller_copy.golden_wallow as Dictionary).visible = false
	_check("Guest snapshot cannot be mutated through caller copy",
		bool((net.settlement_view_snapshot() as Dictionary).golden_wallow.visible))

	net._end("test cleanup")
	_check("Session end clears neutral snapshot and notifies listeners",
		(net.get("_settlement_view") as Dictionary).is_empty()
		and int(signals.settlement) >= 4)
	net.settlement_view_changed.disconnect(on_settlement)
	net.homecoming_view_changed.disconnect(on_homecoming)
	game.campaign_state = campaign_saved
	net.active = active_saved
	net.multiplayer.multiplayer_peer = peer_saved
	net._sync_settlement_view(settlement_saved)
	net._sync_homecoming_view(homecoming_saved)
