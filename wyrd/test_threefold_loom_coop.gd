extends SceneTree

# D8 Slice 4 co-op contract.  This exercises the live Game and NetGame
# autoloads rather than a Boolean role fake: a guest has deliberately
# conflicting local progress, then receives the host's compact Loom snapshot.
# It also locks the one host publication boundary through the real deferred
# Town-refresh shape.

const CampaignData = preload("res://data/campaign.gd")
const ChartsData = preload("res://data/charts.gd")
const Progression = preload("res://data/progression.gd")
const LoomSourceScript = preload("res://scripts/threefold_loom_source.gd")

var _pass := 0
var _fail := 0


class DeferredTownRefresh:
	extends Node
	var game: Node
	var refresh_count := 0
	var _net: Node = null

	func bind_settlement_refresh(net: Node) -> void:
		_net = net
		if _net != null and _net.has_signal("settlement_view_changed") \
				and not _net.is_connected("settlement_view_changed", _refresh_campaign_settlement_view):
			_net.connect("settlement_view_changed", _refresh_campaign_settlement_view)

	func unbind_settlement_refresh() -> void:
		if _net != null and _net.has_signal("settlement_view_changed") \
				and _net.is_connected("settlement_view_changed", _refresh_campaign_settlement_view):
			_net.disconnect("settlement_view_changed", _refresh_campaign_settlement_view)
		_net = null

	func _refresh_campaign_settlement_view() -> void:
		refresh_count += 1
		# This deliberately uses the public getter just as Town does.  If the
		# getter republishes on a host, the NetGame signal count below catches it.
		game.campaign_settlement_view()


func _init() -> void:
	call_deferred("_run")


func _check(label: String, ok: bool, detail = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % label)
	else:
		_fail += 1
		print("  ✗ %s %s" % [label, str(detail)])


func _frames(count := 3) -> void:
	for _frame in count:
		await process_frame


func _fire_settled() -> Dictionary:
	var state := CampaignData.empty_state()
	for chapter_id_v in CampaignData.CHAPTER_ORDER:
		var chapter_id := String(chapter_id_v)
		if chapter_id == CampaignData.UNWRITTEN_ROAD:
			break
		var chapter: Dictionary = state.chapters[chapter_id]
		chapter.cleared = true
		chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
		for index in int(chapter.clue_count):
			chapter.banked_chart_ids.append("%s-%d" % [chapter_id, index + 1])
	state.relics = CampaignData.ROOT_RUNE_IDS.duplicate()
	state.threads = ["past_thread", "present_thread"]
	state.restorations = ["trophy_hall", "sallow_jetty", "skald_archive",
		"pale_stair", "rootroad_lift", "ember_kiln"]
	return CampaignData.normalize_campaign_state(state)


func _map_ready_state() -> Dictionary:
	var state := _fire_settled()
	for index in 5:
		state = CampaignData.record_successful_chart_return(state, "root_below",
			"loom-coop-%d" % (index + 1), 23, {}).state
	return state


func _prepare_ritual_ready(game: Node) -> void:
	game.campaign_state = _map_ready_state()
	game.trades = Progression.fresh_trade_state()
	game.trades.wayfinding = {"xp": Progression.xp_for_level(23), "lv": 23}
	game.chart_source_unlocks = ["threefold_loom_root_below"]
	game.known_chart_recipes = ["root_below"]
	game.chart_recipe_journal = ChartsData.journal_with_rumour(
		ChartsData.fresh_recipe_journal(), "threefold_loom_root_below",
		game.known_chart_recipes)
	game.chart_recipe_journal = ChartsData.journal_with_discovery(
		game.chart_recipe_journal, "root_below", "source_lesson",
		game.known_chart_recipes)
	game._chart_table_revision = 31


func _prepare_unread_first_folio(game: Node, level: int = 22) -> void:
	game.campaign_state = _map_ready_state()
	game.trades = Progression.fresh_trade_state()
	game.trades.wayfinding = {"xp": Progression.xp_for_level(level), "lv": level}
	game.chart_source_unlocks = ["threefold_loom_root_below"]
	game.known_chart_recipes = ChartsData.starting_recipe_ids()
	game.chart_recipe_journal = ChartsData.fresh_recipe_journal()
	game._chart_table_revision = 41


func _save_game_state(game: Node) -> Dictionary:
	return {
		"campaign": game.campaign_state.duplicate(true),
		"trades": game.trades.duplicate(true),
		"unlocks": game.chart_source_unlocks.duplicate(),
		"known": game.known_chart_recipes.duplicate(),
		"journal": game.chart_recipe_journal.duplicate(true),
		"materials": game.materials.duplicate(true),
		"revision": int(game._chart_table_revision),
		"persistence": bool(game.persistence_enabled),
	}


func _restore_game_state(game: Node, saved: Dictionary) -> void:
	game.campaign_state = saved.campaign
	game.trades = saved.trades
	game.chart_source_unlocks = saved.unlocks
	game.known_chart_recipes = saved.known
	game.chart_recipe_journal = saved.journal
	game.materials = saved.materials
	game._chart_table_revision = int(saved.revision)
	game.persistence_enabled = bool(saved.persistence)


func _run() -> void:
	print("--- Threefold Loom co-op projection ---")
	await _test_guest_snapshot_and_host_publication()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


func _test_guest_snapshot_and_host_publication() -> void:
	var game: Node = root.get_node("Game")
	var net: Node = root.get_node("NetGame")
	var game_saved := _save_game_state(game)
	var net_active_saved := bool(net.active)
	var peer_saved: MultiplayerPeer = net.multiplayer.multiplayer_peer
	var settlement_saved: Dictionary = (net.get("_settlement_view") as Dictionary).duplicate(true)
	var homecoming_saved: Dictionary = (net.get("_homecoming_view") as Dictionary).duplicate(true)
	var players_saved: Dictionary = (net.get("players") as Dictionary).duplicate(true)
	var scene_saved := current_scene
	game.persistence_enabled = false

	# Build a real host-derived snapshot, then make the local guest state say
	# exactly the opposite.  No guest-side field may leak into the returned Loom.
	_prepare_ritual_ready(game)
	var host_snapshot: Dictionary = game.campaign_settlement_view()
	var host_loom: Dictionary = (host_snapshot.get("threefold_loom", {}) as Dictionary).duplicate(true)
	var joined: bool = bool(net.join("127.0.0.1", 7777))
	game.campaign_state = CampaignData.empty_state()
	game.trades = Progression.fresh_trade_state()
	game.chart_source_unlocks = []
	game.known_chart_recipes = []
	game.chart_recipe_journal = ChartsData.fresh_recipe_journal()
	var before_snapshot: Dictionary = game.threefold_loom_view()
	_check("guest Loom fails closed before the host settlement snapshot arrives",
		joined and not bool(before_snapshot.get("valid", true))
			and String(before_snapshot.get("phase", "")) == "unavailable"
			and bool(before_snapshot.get("read_only", false))
			and not bool(before_snapshot.get("can_trace", true))
			and (before_snapshot.get("requirements", []) as Array).is_empty(), before_snapshot)

	# The real scanner must be just as fail-closed: no early Map parchment may
	# populate its fallback five rows before a host snapshot exists.
	var loom_fixture := Node3D.new()
	loom_fixture.name = "GuestLoomProjectionFixture"
	root.add_child(loom_fixture)
	current_scene = loom_fixture
	var loom: Node3D = LoomSourceScript.new()
	loom.game_override = game
	loom_fixture.add_child(loom)
	await _frames()
	var unavailable_route: Dictionary = loom.loom_view()
	loom.interact(null)
	await _frames()
	_check("pre-snapshot physical Loom is inert and never opens a requirements panel or local folio action",
		String(unavailable_route.get("phase", "")) == "unavailable"
			and bool(unavailable_route.get("read_only", false))
			and (unavailable_route.get("requirements", []) as Array).is_empty()
			and get_first_node_in_group("MapRitualPanel") == null
			and get_first_node_in_group("ChartRumourSourceDialog") == null
			and get_first_node_in_group("ThreefoldLoomGuestReview") == null,
		unavailable_route)

	net._sync_settlement_view(host_snapshot)
	var guest_local_before: Dictionary = game.campaign_state.duplicate(true)
	var guest_view: Dictionary = game.threefold_loom_view()
	_check("guest consumes only the host Loom snapshot despite conflicting local campaign, Trade, and Codex",
		guest_view == host_loom.merged({"read_only": true, "can_trace": false,
			"can_repair_knowledge": false}, true)
			and game.campaign_state == guest_local_before, {"guest": guest_view, "host": host_loom})
	# Drive the physical scanner adapter, not only Game's direct view.  The
	# local source is intentionally locked/unknown; a guest must nevertheless
	# route to the host's Map parchment rather than its own first-folio dialog.
	var routed_view: Dictionary = loom.loom_view()
	var local_source: Dictionary = loom.source_status()
	loom.interact(null)
	await _frames()
	var ritual_panel := get_first_node_in_group("MapRitualPanel")
	var folio_dialog := get_first_node_in_group("ChartRumourSourceDialog")
	_check("guest physical Threefold Loom ignores its conflicting local folio gate and opens the host-projected Map ritual",
		not bool(local_source.get("known", true))
			and String(routed_view.get("phase", "")) == String(host_loom.get("phase", ""))
			and bool(routed_view.get("read_only", false))
			and ritual_panel != null and folio_dialog == null,
		{"local_source": local_source, "routed": routed_view,
			"map_panel": ritual_panel != null, "folio_dialog": folio_dialog != null})
	if ritual_panel != null:
		ritual_panel.call("_close")
	await _frames()
	loom_fixture.queue_free()
	await _frames()
	current_scene = scene_saved
	(guest_view.requirements[0] as Dictionary)["met"] = false
	guest_view["phase"] = "waiting"
	var caller_snapshot: Dictionary = net.settlement_view_snapshot()
	(caller_snapshot.threefold_loom as Dictionary)["phase"] = "forged"
	var copied_again: Dictionary = game.threefold_loom_view()
	_check("guest Loom projection is deep-copied at both NetGame and Game boundaries",
		String(copied_again.get("phase", "")) == String(host_loom.get("phase", ""))
			and bool(((copied_again.requirements[0] as Dictionary).get("met", false))), copied_again)
	net._end("threefold Loom guest cleanup")
	var rejoined: bool = bool(net.join("127.0.0.1", 7777))
	var revoked: Dictionary = game.threefold_loom_view()
	_check("session end revokes the old Loom snapshot; a later guest session fails closed until a new host snapshot arrives",
		rejoined and (net.get("_settlement_view") as Dictionary).is_empty()
			and not bool(revoked.get("valid", true))
			and String(revoked.get("phase", "")) == "unavailable", revoked)
	net._end("threefold Loom rejoin cleanup")

	await _test_guest_first_folio_routing(game, net)
	await _test_live_first_folio_and_wayfinding_replication(game, net)

	# This is deliberately the production `_publish_campaign_settlement_view`:
	# the probe has Town's deferred getter shape, while the live NetGame signal
	# is the assertion.  It would report two events if that getter republished.
	_prepare_ritual_ready(game)
	var host_peer := ENetMultiplayerPeer.new()
	var hosted: bool = host_peer.create_server(0, 3) == OK
	if hosted:
		net.multiplayer.multiplayer_peer = host_peer
		net.active = true
		net.players = {1: {"name": "Loom Test Host"}}
		net._settlement_view = {}
		# MultiplayerAPI establishes its server role on the next engine tick.
		# Waiting here makes this an actual host-publication assertion, not a
		# coincidental offline authority path.
		await _frames(1)
		var refresh := DeferredTownRefresh.new()
		refresh.game = game
		root.add_child(refresh)
		current_scene = refresh
		refresh.bind_settlement_refresh(net)
		var publication_count := {"value": 0}
		var on_publication := func() -> void: publication_count.value += 1
		net.settlement_view_published.connect(on_publication)
		var traced: Dictionary = game.trace_threefold_loom_map()
		await _frames()
		_check("one successful host Map ritual publishes exactly once even after the deferred Town getter refreshes",
			bool(traced.get("ok", false)) and bool(traced.get("changed", false))
			and int(publication_count.value) == 1 and refresh.refresh_count == 1,
			{"result": traced, "publications": publication_count.value, "refreshes": refresh.refresh_count,
				"active": net.active, "host": net.is_host(),
				"snapshot": net.get("_settlement_view")})
		net.settlement_view_published.disconnect(on_publication)
		refresh.unbind_settlement_refresh()
		refresh.queue_free()
	else:
		_check("one successful host Map ritual publishes exactly once even after the deferred Town getter refreshes",
			false, "could not create a loopback ENet host")

	# Restore the globally shared autoloads even when an assertion fails.
	net.active = net_active_saved
	net.multiplayer.multiplayer_peer = peer_saved
	net.players = players_saved
	net._sync_settlement_view(settlement_saved)
	net._sync_homecoming_view(homecoming_saved)
	current_scene = scene_saved
	_restore_game_state(game, game_saved)
	# The level-23 replication assertion intentionally plays the normal level-up
	# cue. Release its pooled playback before this focused SceneTree exits.
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("shutdown"):
		sfx.call("shutdown")
		# AudioServer releases an MP3 playback handle asynchronously; frames alone
		# can elapse before its mix thread observes the stopped pooled player.
		await create_timer(0.15).timeout
		await _frames(3)


func _test_guest_first_folio_routing(game: Node, net: Node) -> void:
	# Deliberately invert the two saves: the host has not read Root Below, while
	# the guest's local Codex has. The real source must render only the host's
	# first_folio review and never consult the local status/pages/read action.
	_prepare_unread_first_folio(game, 22)
	var host_snapshot: Dictionary = game.campaign_settlement_view()
	var joined: bool = bool(net.join("127.0.0.1", 7777))
	_prepare_ritual_ready(game)
	net._sync_settlement_view(host_snapshot)
	var restore_scene := current_scene
	var fixture := Node3D.new()
	fixture.name = "GuestFirstFolioFixture"
	root.add_child(fixture)
	current_scene = fixture
	var loom: Node3D = LoomSourceScript.new()
	loom.game_override = game
	fixture.add_child(loom)
	await _frames()
	var local_source: Dictionary = loom.source_status()
	var projected: Dictionary = loom.loom_view()
	var prompt: String = loom.get_prompt_text()
	loom.interact(null)
	await _frames()
	var review: Node = get_first_node_in_group("ThreefoldLoomGuestReview")
	var panel: Node = get_first_node_in_group("MapRitualPanel")
	var local_dialog: Node = get_first_node_in_group("ChartRumourSourceDialog")
	_check("guest host-first-folio routing remains neutral even when the guest locally knows Root Below",
		joined and bool(local_source.get("known", false))
			and String(projected.get("phase", "")) == "first_folio"
			and bool(projected.get("read_only", false))
			and prompt.contains("fire-keeper studies")
			and review != null and panel == null and local_dialog == null,
		{"local_source": local_source, "projected": projected, "prompt": prompt,
			"review": review != null, "panel": panel != null, "local_dialog": local_dialog != null})
	if review != null and review.has_method("_finish"):
		review.call("_finish")
	await _frames()
	fixture.queue_free()
	await _frames()
	current_scene = restore_scene
	net._end("threefold Loom guest first-folio cleanup")


func _test_live_first_folio_and_wayfinding_replication(game: Node, net: Node) -> void:
	# A level-22 host has the five Map prerequisites but has not read the Loom.
	# The live source read must replicate first_folio -> waiting; the one level
	# to 23 must then replicate waiting -> ritual_ready, with no per-XP chatter.
	_prepare_unread_first_folio(game, 22)
	var host_peer := ENetMultiplayerPeer.new()
	var hosted: bool = host_peer.create_server(0, 3) == OK
	if not hosted:
		_check("live first-folio and Wayfinding Loom changes replicate only when the projection changes",
			false, "could not create a loopback ENet host")
		return
	net.multiplayer.multiplayer_peer = host_peer
	net.active = true
	net.players = {1: {"name": "Loom Replication Host"}}
	net._settlement_view = {}
	await _frames(1)
	var snapshots: Array = []
	var on_publication := func() -> void:
		snapshots.append((net.get("_settlement_view") as Dictionary).duplicate(true))
	net.settlement_view_published.connect(on_publication)
	# Establish the live first-folio baseline, then retain only mutation updates.
	game._publish_campaign_settlement_view()
	snapshots.clear()
	var read: Dictionary = game.read_chart_source("threefold_loom_root_below")
	var waiting_snapshot: Dictionary = snapshots[0].duplicate(true) if snapshots.size() == 1 else {}
	var xp_to_23 := Progression.xp_for_level(23) - Progression.xp_for_level(22)
	game.award_xp("wayfinding", xp_to_23)
	var ready_snapshot: Dictionary = snapshots[1].duplicate(true) if snapshots.size() == 2 else {}
	var emitted_phases: Array = []
	for snapshot_value in snapshots:
		var loom = (snapshot_value as Dictionary).get("threefold_loom", {})
		emitted_phases.append(String((loom as Dictionary).get("phase", "")) \
			if loom is Dictionary else "")
	net.settlement_view_published.disconnect(on_publication)
	net._end("threefold Loom host replication cleanup")

	# Consume those exact live snapshots through the real guest NetGame branch.
	var joined: bool = bool(net.join("127.0.0.1", 7777))
	game.campaign_state = CampaignData.empty_state()
	game.trades = Progression.fresh_trade_state()
	game.chart_source_unlocks = []
	game.known_chart_recipes = []
	game.chart_recipe_journal = ChartsData.fresh_recipe_journal()
	net._sync_settlement_view(waiting_snapshot)
	var guest_waiting: Dictionary = game.threefold_loom_view()
	net._sync_settlement_view(ready_snapshot)
	var guest_ready: Dictionary = game.threefold_loom_view()
	_check("live first-folio and Wayfinding Loom changes replicate only when the projection changes",
		bool(read.get("changed", false)) and emitted_phases == ["waiting", "ritual_ready"]
			and joined and String(guest_waiting.get("phase", "")) == "waiting"
			and String(guest_ready.get("phase", "")) == "ritual_ready"
			and bool(guest_waiting.get("read_only", false))
			and bool(guest_ready.get("read_only", false)),
		{"read": read, "phases": emitted_phases,
			"waiting": guest_waiting, "ready": guest_ready})
	net._end("threefold Loom guest replication cleanup")
