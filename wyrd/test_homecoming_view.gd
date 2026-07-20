extends SceneTree

# First Knot Homecoming domain/adapter contract.
# Run: WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_homecoming_view.gd

const CampaignData = preload("res://data/campaign.gd")
const GameScript = preload("res://scripts/game.gd")

var _pass := 0
var _fail := 0

func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % name)
	else:
		_fail += 1
		print("  ✗ %s %s" % [name, detail])

func _cleared_state() -> Dictionary:
	var state := CampaignData.empty_state()
	var chapter: Dictionary = state.chapters[CampaignData.FIRST_KNOT]
	chapter.cleared = true
	chapter.clue_count = 3
	state.relics = ["green_root_rune"]
	state.restorations = ["trophy_hall"]
	return CampaignData.normalize_campaign_state(state)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- First Knot Homecoming view ---")
	_test_domain_matrix()
	_test_game_adapter_and_guest_snapshot()
	_test_reprise_return_outcomes()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _test_domain_matrix() -> void:
	var legacy: Dictionary = CampaignData.infer_legacy_clear(CampaignData.empty_state(),
		{"tusker_tusk": {"slot": 1}}, true).state
	var rows: Array = [
		{
			"name": "fresh", "state": CampaignData.empty_state(), "context": {},
			"cleared": false, "visible": false, "rune": false, "tusk": false,
			"debrief": false,
		},
		{
			"name": "malformed", "state": {"chapters": "no", "relics": {},
				"restorations": "no", "escrows": []}, "context": {},
			"cleared": false, "visible": false, "rune": false, "tusk": false,
			"debrief": false,
		},
		{
			"name": "partial clear does not synthesize hall", "state": {
				"chapters": {CampaignData.FIRST_KNOT: {"cleared": true,
					"clue_count": 3}}, "relics": [], "restorations": []},
			"context": {}, "cleared": true, "visible": false, "rune": false,
			"tusk": false, "debrief": false,
		},
		{
			"name": "canonical clear", "state": _cleared_state(), "context": {},
			"cleared": true, "visible": true, "rune": true, "tusk": true,
			"debrief": true,
		},
		{
			"name": "legacy normalized clear", "state": legacy, "context": {},
			"cleared": true, "visible": true, "rune": true, "tusk": true,
			"debrief": true,
		},
		{
			"name": "guest inspection", "state": _cleared_state(),
			"context": {"guest": true}, "cleared": true, "visible": true,
			"rune": true, "tusk": true, "debrief": false,
		},
		{
			"name": "Reprise keeps restoration but is ineligible", "state": _cleared_state(),
			"context": {"d2_reprise": true}, "cleared": true, "visible": true,
			"rune": true, "tusk": true, "debrief": false,
		},
	]
	for row_v in rows:
		var row: Dictionary = row_v
		var state: Dictionary = (row.state as Dictionary).duplicate(true)
		var context: Dictionary = (row.context as Dictionary).duplicate(true)
		var state_before := state.duplicate(true)
		var context_before := context.duplicate(true)
		var view := CampaignData.first_knot_homecoming_view(state, context)
		var event: Dictionary = view.debrief_event
		var label := String(row.name)
		_check("%s has stable schema" % label,
			view.chapter_id == CampaignData.FIRST_KNOT
			and view.has("available") and view.has("covered_bow_rest_visible")
			and view.has("atlas_handoff_visible") and view.debrief_event_key
				== "first_knot_homecoming")
		_check("%s derives expected truth" % label,
			bool(view.cleared) == bool(row.cleared)
			and bool(view.visible) == bool(row.visible)
			and bool(view.rune_visible) == bool(row.rune)
			and bool(view.tusk_record_visible) == bool(row.tusk)
			and bool(event.available) == bool(row.debrief), str(view))
		_check("%s inspection is deeply non-mutating" % label,
			state == state_before and context == context_before)
		# The returned nested event must not alias a later query or caller state.
		event.available = not bool(event.available)
		var repeat := CampaignData.first_knot_homecoming_view(state, context)
		_check("%s result is deep-copy safe" % label,
			(repeat.debrief_event as Dictionary).available == bool(row.debrief))

	var read_only := CampaignData.first_knot_homecoming_view(_cleared_state(),
		{"read_only": true, "acknowledged_event_keys": ["first_knot_homecoming"]})
	_check("explicit read-only acknowledgement suppresses event",
		bool(read_only.read_only) and not bool((read_only.debrief_event as Dictionary).available))

func _test_game_adapter_and_guest_snapshot() -> void:
	var game: Node = root.get_node("Game")
	var net: Node = root.get_node("NetGame")
	var campaign_saved: Dictionary = game.campaign_state.duplicate(true)
	var net_active_saved := bool(net.active)
	var snapshot_saved: Dictionary = (net.get("_homecoming_view") as Dictionary).duplicate(true)
	var peer_saved: MultiplayerPeer = net.multiplayer.multiplayer_peer
	var host_truth := _cleared_state()
	game.campaign_state = host_truth.duplicate(true)
	var host_before: Dictionary = game.campaign_state.duplicate(true)
	var host_view: Dictionary = game.first_knot_homecoming_view()
	_check("Game host adapter returns campaign projection",
		bool(host_view.visible) and bool((host_view.debrief_event as Dictionary).available))
	_check("Game host adapter does not mutate campaign", game.campaign_state == host_before)

	net._sync_homecoming_view(host_view)
	var join_signal := {"count": 0}
	var on_join_view_changed := func() -> void: join_signal.count += 1
	net.homecoming_view_changed.connect(on_join_view_changed)
	_check("join immediately revokes stale local/host projection",
		net.join("127.0.0.1", 7777)
			and (net.get("_homecoming_view") as Dictionary).is_empty()
			and int(join_signal.count) == 1)
	net.homecoming_view_changed.disconnect(on_join_view_changed)
	net._sync_homecoming_view(host_view)
	_check("guest fixture is active and non-host", game.net_active() and not net.is_host())
	game.campaign_state = CampaignData.empty_state() # proves guest ignores local state
	var guest_before: Dictionary = game.campaign_state.duplicate(true)
	var guest_view: Dictionary = game.first_knot_homecoming_view()
	_check("Game guest consumes host snapshot read-only",
		bool(guest_view.visible) and bool(guest_view.guest) and bool(guest_view.read_only)
		and not bool((guest_view.debrief_event as Dictionary).available)
		and game.campaign_state == guest_before, str(guest_view))
	net._sync_homecoming_view({})
	var unavailable: Dictionary = game.first_knot_homecoming_view()
	_check("Game guest fails closed before snapshot",
		not bool(unavailable.available) and not bool(unavailable.visible)
		and bool(unavailable.guest) and bool(unavailable.read_only), str(unavailable))
	game.campaign_state = campaign_saved
	net.active = net_active_saved
	net.multiplayer.multiplayer_peer = peer_saved
	net._sync_homecoming_view(snapshot_saved)
	game.campaign_state = host_truth.duplicate(true)
	game._homecoming_return_was_d2_reprise = true
	var reprise_arrival: Dictionary = game.first_knot_homecoming_view()
	_check("Game return-source flag suppresses Reprise event but keeps Hall",
		bool(reprise_arrival.visible) and bool(reprise_arrival.d2_ineligible)
		and not bool((reprise_arrival.debrief_event as Dictionary).available))
	game.clear_first_knot_homecoming_return_context()
	_check("Game return-source clear is session-only", not bool(
		game.first_knot_homecoming_view().d2_ineligible))
	game.campaign_state = campaign_saved

func _test_reprise_return_outcomes() -> void:
	for abandoned in [false, true]:
		var game := GameScript.new()
		game.persistence_enabled = false
		game.campaign_state = _cleared_state()
		var campaign_before: Dictionary = game.campaign_state.duplicate(true)
		game.active_chart = {
			"recipe_id": "first_knot_reprise",
			"template_id": "hollow",
			"tier": 1,
			"seed": 7717,
			"affixes": [],
		}
		game.return_to_town(null, abandoned)
		var view: Dictionary = game.first_knot_homecoming_view()
		var outcome := "abandoned" if abandoned else "completed"
		_check("%s Reprise return stays Homecoming-ineligible" % outcome,
			bool(view.visible) and bool(view.d2_ineligible)
			and not bool((view.debrief_event as Dictionary).available), str(view))
		_check("%s Reprise return leaves full campaign state unchanged" % outcome,
			game.campaign_state == campaign_before, str(game.campaign_state))
		game.free()
