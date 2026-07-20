extends Node

# Spec 46 Phase A — the co-op session autoload ("NetGame"). Owns the ENet
# peer, the player roster, and per-peer player spawning. Host-authoritative:
# the host's roster is truth and is re-broadcast whole on every change
# (claudecraft pattern: snapshots over deltas at this scale).
#
# Offline (no peer) the game runs exactly as it always has — `active` is
# the single switch every system checks.

signal roster_changed
signal session_ended(reason: String)
signal reconnecting(attempt: int, max_attempts: int)
# Host-only proof that the same opaque session player returned on a new ENet
# peer ID. Encounter ledgers may rebind only from this token-validated edge.
signal peer_rebound(old_peer_id: int, new_peer_id: int, session_player_id: String)
signal player_body_spawned(player: Node)
# Phase 4 — a peer stepped through the exit; the party returns after the grace.
signal run_ending(who_name: String, seconds: float)
# The neutral, view-only campaign settlement snapshot.  New Town surfaces use
# this rather than growing a signal for every authored chapter.
signal settlement_view_changed
# Host-local publication boundary.  Guests use `settlement_view_changed` when
# their copied view arrives; this signal exists so host-owned transactions can
# be observed without pretending the RPC's guest-arrival notification is a
# local broadcast count.
signal settlement_view_published
# Kept for the First Knot Hall callers which shipped before the neutral seam.
signal homecoming_view_changed

const DEFAULT_PORT := 7777
const MAX_PLAYERS := 4
const PlayerScene := preload("res://scenes/Player.tscn")

# A dropped host connection gets a short grace: try to find the lantern again
# a few times before giving up (handles a transient blip while the host is up).
const RECONNECT_TRIES := 3
const RECONNECT_DELAY := 2.0

var active := false
var display_name := ""
# peer_id -> {"name": String}. On every peer; host's copy is truth.
var players: Dictionary = {}
# Host-projected First Knot Homecoming view.  This is a presentation snapshot,
# never campaign state: guests inspect it in Town and cannot reconcile their
# own save from it.
var _homecoming_view: Dictionary = {}
# Host-projected campaign settlement. Like the Homecoming compatibility view,
# this is presentation evidence only and must never be written into a guest
# save or used to settle campaign rewards.
var _settlement_view: Dictionary = {}

# reconnect state (guest only)
var _last_ip := ""
var _last_port := DEFAULT_PORT
var _leaving := false
var _reconnect_left := 0
var _session_player_id := ""
var _peer_by_session_player: Dictionary = {} # host only; token -> current peer
var _previous_local_peer_id := 0
# C-4 / C-5 — the active chart (for mid-run rejoin) + the host's external IP
# (opportunistic UPnP, for internet friend-invites; empty until/unless found).
var _active_chart: Dictionary = {}
var _external_ip := ""
var _upnp_task := -1            # WorkerThreadPool task id for the UPnP probe

func _ready() -> void:
	display_name = OS.get_environment("WYRD_DISPLAY_NAME")
	if display_name == "":
		display_name = OS.get_environment("USER")
	if display_name == "":
		display_name = "Wayfinder"
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connect_failed)
	multiplayer.server_disconnected.connect(_on_server_lost)

# Best-guess shareable IPv4 addresses for "give this to your friend" — the
# Tailscale (100.x) and LAN (192.168/10/172) addresses first, loopback and
# link-local dropped. Returns [] if none look shareable.
func local_addresses() -> Array:
	var out: Array = []
	for a in IP.get_local_addresses():
		var s := String(a)
		if ":" in s:                                       # skip IPv6
			continue
		if s.begins_with("127.") or s.begins_with("169.254."):
			continue
		out.append(s)
	out.sort_custom(func(x, y): return _addr_rank(x) < _addr_rank(y))
	if _external_ip != "":
		out.push_front(_external_ip)   # external IP first — for internet invites
	return out

func _addr_rank(s: String) -> int:
	if s.begins_with("100."):                              # Tailscale CGNAT
		return 0
	if s.begins_with("192.168.") or s.begins_with("10."):  # home LAN
		return 1
	if s.begins_with("172."):
		return 2
	return 3

func is_host() -> bool:
	return active and multiplayer.is_server()

func host(port: int = DEFAULT_PORT) -> bool:
	var peer := ENetMultiplayerPeer.new()
	if peer.create_server(port, MAX_PLAYERS - 1) != OK:
		return false
	multiplayer.multiplayer_peer = peer
	active = true
	_session_player_id = _new_session_player_id()
	_peer_by_session_player = {_session_player_id: 1}
	_previous_local_peer_id = 0
	_last_ip = ""                # the host never reconnects to itself
	_leaving = false
	players = {1: {"name": display_name}}
	roster_changed.emit()
	_try_upnp(port)              # opportunistic — external IP for internet invites
	return true

# Opportunistic UPnP port-map so the host's EXTERNAL ip can be shared for
# internet co-op (not just LAN/Tailscale). Runs off the main thread, and is a
# pure no-op on routers without UPnP — never blocks or crashes hosting.
func _try_upnp(port: int) -> void:
	# Deterministic loopback/process tests do not need to probe the user's router.
	# Production hosts leave this unset and retain the opportunistic mapping.
	if OS.get_environment("WYRD_NO_UPNP") != "":
		return
	# Short discover timeout (default is 2000ms): the host shouldn't stall on
	# startup, and the join-on-exit below is bounded by it.
	_upnp_task = WorkerThreadPool.add_task(func() -> void:
		var upnp := UPNP.new()
		if upnp.discover(900) == UPNP.UPNP_RESULT_SUCCESS:
			upnp.add_port_mapping(port)
			var ext := upnp.query_external_address()
			if ext != "" and ext != "0.0.0.0":
				call_deferred("_upnp_found", ext))

# A GDScript Callable left running in a WorkerThreadPool task aborts in
# ~WorkerThreadPool during unregister_core_types — SIGABRT on quit (it crashed
# every host→exit). Drain the probe before the engine tears down. Bounded by
# the 900ms discover timeout above.
func _drain_upnp() -> void:
	if _upnp_task != -1:
		WorkerThreadPool.wait_for_task_completion(_upnp_task)
		_upnp_task = -1

func _exit_tree() -> void:
	_drain_upnp()

func _upnp_found(ext_ip: String) -> void:
	_external_ip = ext_ip
	roster_changed.emit()        # the Lantern refreshes its address row

func join(ip: String, port: int = DEFAULT_PORT) -> bool:
	var peer := ENetMultiplayerPeer.new()
	if peer.create_client(ip, port) != OK:
		return false
	multiplayer.multiplayer_peer = peer
	active = true
	_session_player_id = _new_session_player_id()
	_peer_by_session_player.clear()
	_previous_local_peer_id = 0
	# The moment this process becomes a guest, its local campaign projection is
	# no longer authoritative. Clear and notify synchronously so an already-open
	# Town hides local Homecoming state before the host snapshot arrives.
	_clear_campaign_views()
	_last_ip = ip                # remembered so a dropped host can be re-found
	_last_port = port
	_leaving = false
	_reconnect_left = 0
	players = {}
	return true

func leave(reason: String = "You left the party.") -> void:
	_leaving = true              # an intentional exit must not auto-reconnect
	_end(reason)

func _end(reason: String) -> void:
	if not active:
		return
	active = false
	_reconnect_left = 0
	_session_player_id = ""
	_peer_by_session_player.clear()
	_previous_local_peer_id = 0
	players = {}
	_clear_campaign_views()
	multiplayer.multiplayer_peer = null
	roster_changed.emit()
	session_ended.emit(reason)

# ---- handshake + roster (host = truth) ----

func _on_connected() -> void:
	# We reached the host — introduce ourselves (and clear any reconnect run).
	_reconnect_left = 0
	_register_player.rpc_id(1, display_name, _session_player_id)

# ---- connection loss + bounded reconnect (guest side) ----

func _on_connect_failed() -> void:
	if _reconnect_left > 0:
		_try_reconnect()         # a reconnect attempt didn't catch — try again
	else:
		_end("No answer at that door.")

func _on_server_lost() -> void:
	if _leaving or _last_ip == "":
		_end("The host's lantern went out.")
		return
	# Transient drop — give it a few tries before tearing the party down.
	_reconnect_left = RECONNECT_TRIES
	_previous_local_peer_id = multiplayer.get_unique_id()
	_clear_campaign_views()
	multiplayer.multiplayer_peer = null
	_try_reconnect()

func _try_reconnect() -> void:
	if _reconnect_left <= 0:
		_end("The host's lantern went out.")
		return
	var attempt: int = RECONNECT_TRIES - _reconnect_left + 1
	_reconnect_left -= 1
	active = true
	reconnecting.emit(attempt, RECONNECT_TRIES)
	var game := get_node_or_null("/root/Game")
	if game != null and game.has_method("notify"):
		game.notify("Lost the host — trying the door again (%d/%d)…"
			% [attempt, RECONNECT_TRIES])
	get_tree().create_timer(RECONNECT_DELAY).timeout.connect(func():
		if _leaving or not active:
			return
		var peer := ENetMultiplayerPeer.new()
		if peer.create_client(_last_ip, _last_port) != OK:
			_try_reconnect()
			return
		multiplayer.multiplayer_peer = peer)

func _on_peer_connected(_id: int) -> void:
	pass   # the roster updates when the peer introduces itself

func _on_peer_disconnected(id: int) -> void:
	if multiplayer.is_server():
		players.erase(id)
		_sync_roster.rpc(players)
		_apply_roster()

@rpc("any_peer", "reliable")
func _register_player(p_name: String, session_player_id: String) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	# Tokens never enter the broadcast roster. They are opaque continuity proof,
	# not identity/account data, and live only for this hosted session.
	var claim := _claim_session_player(session_player_id, id)
	if not bool(claim.get("ok", false)):
		return
	var old_peer := int(claim.get("old_peer_id", 0))
	players[id] = {"name": p_name}
	if old_peer > 0 and old_peer != id:
		peer_rebound.emit(old_peer, id, session_player_id)
	_sync_roster.rpc(players)
	_apply_roster()
	# A Town join can happen after a chapter cleared. Send compact host
	# projections alongside the roster, never the host's mutable campaign state.
	if _homecoming_view.is_empty():
		var game_for_homecoming := get_node_or_null("/root/Game")
		if game_for_homecoming != null and game_for_homecoming.has_method("first_knot_homecoming_view"):
			_homecoming_view = game_for_homecoming.first_knot_homecoming_view()
	if not _homecoming_view.is_empty():
		_sync_homecoming_view.rpc_id(id, _homecoming_view.duplicate(true))
	if _settlement_view.is_empty():
		var game_for_settlement := get_node_or_null("/root/Game")
		if game_for_settlement != null \
				and game_for_settlement.has_method("campaign_settlement_view"):
			_settlement_view = _with_archive_folio_projection(
				game_for_settlement.campaign_settlement_view())
	if not _settlement_view.is_empty():
		_sync_settlement_view.rpc_id(id, _settlement_view.duplicate(true))
	# C-4 — a peer that joins (or rejoins after a drop) while the host is mid-
	# dungeon drops straight into the same chart; same seed → deterministic
	# rebuild, no extra data transfer.
	var game := get_node_or_null("/root/Game")
	if game != null and bool(game.in_dungeon) and not _active_chart.is_empty():
		game.notify("%s joins the delve." % p_name)
		_rejoin_run.rpc_id(id, _active_chart)


func _claim_session_player(session_player_id: String, new_peer_id: int) -> Dictionary:
	if session_player_id.length() < 24 or session_player_id.length() > 96 \
			or new_peer_id <= 0:
		return {"ok": false, "reason": "bad_session_player"}
	var old_peer := int(_peer_by_session_player.get(session_player_id, 0))
	if old_peer > 0 and old_peer != new_peer_id and players.has(old_peer):
		return {"ok": false, "reason": "session_player_connected"}
	_peer_by_session_player[session_player_id] = new_peer_id
	return {"ok": true, "old_peer_id": old_peer, "new_peer_id": new_peer_id}

@rpc("authority", "call_local", "reliable")
func _sync_roster(p_players: Dictionary) -> void:
	players = p_players
	_apply_roster()

func _apply_roster() -> void:
	roster_changed.emit()
	_reconcile_players()

# Clear both transient host projections at guest lifecycle boundaries. They
# deliberately do not outlive a join, reconnect loss, or ended session: a
# guest with no current host truth must render the campaign fail-closed.
func _clear_campaign_views() -> void:
	_homecoming_view = {}
	_settlement_view = {}
	homecoming_view_changed.emit()
	settlement_view_changed.emit()

# ---- Neutral campaign settlement projection (host -> guests) ----

func publish_settlement_view(view: Dictionary) -> void:
	if not is_host():
		return
	var next := _with_archive_folio_projection(view)
	# Several host transactions may ask to publish while a Town is rebuilding.
	# Keep the one current snapshot stable: an identical view needs neither an
	# RPC nor another local Town refresh signal.
	if next == _settlement_view:
		return
	_settlement_view = next
	settlement_view_published.emit()
	_sync_settlement_view.rpc(_settlement_view)

func settlement_view_snapshot() -> Dictionary:
	# Hosts read their real campaign state. Guests are allowed only a current
	# snapshot received from the host, and see {} until that RPC arrives.
	if not active or is_host() or _settlement_view.is_empty():
		return {}
	return _settlement_view.duplicate(true)

@rpc("authority", "call_local", "reliable")
func _sync_settlement_view(view: Dictionary) -> void:
	_settlement_view = view.duplicate(true)
	settlement_view_changed.emit()


# The neutral campaign snapshot is intentionally not a mutable source-state
# mirror.  These two tiny Archive folio descriptors are the only additional
# presentation facts a guest needs: whether the host has exposed the first
# pale folio and, after four rubbings, the second.  Guests never receive an
# action capability, components, journals, or material counts.
func _with_archive_folio_projection(view: Dictionary) -> Dictionary:
	var out := view.duplicate(true)
	var game := get_node_or_null("/root/Game")
	if game == null or not game.has_method("chart_source_status"):
		return out
	var folios: Dictionary = out.get("archive_folios", {}) as Dictionary
	folios = (folios as Dictionary).duplicate(true) if folios is Dictionary else {}
	for pair in [["pale_oath", "skald_pale_oath"],
			["pale_oath_boss", "skald_pale_oath_boss"]]:
		var key := String(pair[0])
		var source_id := String(pair[1])
		var raw = game.chart_source_status(source_id)
		if not raw is Dictionary:
			continue
		var status: Dictionary = raw
		var unlocked := bool(status.get("valid", false)) and bool(status.get("unlocked", false))
		folios[key] = {
			"source_id": source_id,
			"visible": unlocked and int(status.get("level", 0)) \
				>= int(status.get("min_wayfinding", 0)),
			# Revealed deliberately ignores the level threshold: the physical boss
			# folio appears on the fourth rubbing, while Game alone still enforces
			# the Wayfinding-19 source transaction.
			"revealed": unlocked,
			"state": String(status.get("state", "locked")),
			"min_wayfinding": int(status.get("min_wayfinding", 0)),
		}
	out["archive_folios"] = folios
	return out

# ---- First Knot Homecoming compatibility projection (host -> guests) ----

func publish_homecoming_view(view: Dictionary) -> void:
	if not is_host():
		return
	_homecoming_view = view.duplicate(true)
	_sync_homecoming_view.rpc(_homecoming_view)

func homecoming_view_snapshot() -> Dictionary:
	if not active or is_host() or _homecoming_view.is_empty():
		return {}
	return _homecoming_view.duplicate(true)

@rpc("authority", "call_local", "reliable")
func _sync_homecoming_view(view: Dictionary) -> void:
	_homecoming_view = view.duplicate(true)
	homecoming_view_changed.emit()

# ---- per-peer player bodies ----
# Each peer's scene holds one Player node per roster entry, named by peer
# id under the scene root, with authority assigned to that peer. The
# roster being identical everywhere keeps the node paths identical.

func _reconcile_players() -> void:
	var scene := get_tree().current_scene
	if scene == null or not active:
		return
	_preserve_reconnecting_local_body(scene)
	var spawn := _spawn_pos(scene)
	for id in players:
		if scene.get_node_or_null("NetPlayer%d" % int(id)) == null:
			_spawn_player(scene, int(id), spawn)
	for n in get_tree().get_nodes_in_group("player"):
		var nm := String((n as Node).name)
		if nm.begins_with("NetPlayer") \
				and not players.has(int(nm.trim_prefix("NetPlayer"))):
			(n as Node).queue_free()

func _spawn_player(scene: Node, id: int, spawn: Vector3) -> void:
	var p := PlayerScene.instantiate()
	p.name = "NetPlayer%d" % id
	p.set_multiplayer_authority(id)
	scene.add_child(p)
	p.global_position = spawn + Vector3(
		1.2 * float(players.keys().find(id)), 0.0, 0.0)
	print("[net] spawned %s for peer %d (%s)" % [p.name, id, peer_name(id)])
	player_body_spawned.emit(p)


func _preserve_reconnecting_local_body(scene: Node) -> void:
	if _previous_local_peer_id <= 0 or multiplayer.is_server() \
			or multiplayer.multiplayer_peer == null:
		return
	var new_peer_id := multiplayer.get_unique_id()
	if new_peer_id <= 1 or not players.has(new_peer_id):
		return
	_rebind_player_body(scene, _previous_local_peer_id, new_peer_id)
	_previous_local_peer_id = 0


func _rebind_player_body(scene: Node, old_peer_id: int, new_peer_id: int) -> bool:
	if scene == null or old_peer_id <= 0 or new_peer_id <= 0 \
			or scene.get_node_or_null("NetPlayer%d" % new_peer_id) != null:
		return false
	var old_body := scene.get_node_or_null("NetPlayer%d" % old_peer_id)
	if old_body == null:
		return false
	old_body.name = "NetPlayer%d" % new_peer_id
	old_body.set_multiplayer_authority(new_peer_id)
	return true

func _spawn_pos(scene: Node) -> Vector3:
	var nv = scene.get("net_spawn")
	if nv is Vector3 and nv != Vector3.ZERO:
		return nv
	var v = scene.get("PLAYER_SPAWN")
	if v is Vector3:
		return v
	return Vector3(20.0, 0.0, 26.0)

# Called by a scene's _ready when a session is live: replace the baked
# single-player body with the per-peer set.
func setup_scene(scene: Node) -> void:
	if not active:
		return
	var baked := scene.get_node_or_null("Player")
	if baked != null:
		baked.name = "BakedPlayer"          # free is deferred; avoid name clash
		baked.remove_from_group("player")
		baked.queue_free()
	_reconcile_players()

func peer_name(id: int) -> String:
	return String((players.get(id, {}) as Dictionary).get("name", "Wayfinder"))

# ==== Phase B — dungeon co-op =========================================

# -- party run flow: the host sockets a chart; the party crosses together.

func start_run(chart: Dictionary) -> void:
	if is_host():
		print("[net] run start: %s (seed %d)" % [
			String(chart.get("name", "?")), int(chart.get("seed", 0))])
		_active_chart = chart   # C-4 — remembered for a mid-run (re)join
		_run_start.rpc(chart)

# D2 — only the host changes the active Chart. Sending the full materialized
# dictionary (rather than a "next layer" delta) makes a rejoin and a deepen use
# the same deterministic rebuild input on every peer.
func deepen_run(chart: Dictionary) -> void:
	if not is_host() or chart.is_empty():
		return
	_active_chart = chart.duplicate(true)
	_run_deepen.rpc(_active_chart)

@rpc("authority", "call_local", "reliable")
func _run_deepen(chart: Dictionary) -> void:
	var game := get_node("/root/Game")
	if bool(game.in_dungeon) and game.has_method("net_deepen"):
		game.net_deepen(chart)

@rpc("authority", "call_local", "reliable")
func _run_start(chart: Dictionary) -> void:
	var game := get_node("/root/Game")
	game.net_enter(chart)

# C-4 — host → one (re)joining peer: enter the active dungeon. Guarded so a
# peer already in the dungeon isn't yanked.
@rpc("authority", "reliable")
func _rejoin_run(chart: Dictionary) -> void:
	var game := get_node("/root/Game")
	if not bool(game.in_dungeon):
		game.net_enter(chart)
	else:
		# The World was intentionally kept across a short reconnect, so no scene
		# `_ready` will repeat its handshake. Re-report the exact live identity.
		call_deferred("_report_existing_world_ready")


func _report_existing_world_ready() -> void:
	var game := get_node_or_null("/root/Game")
	if game == null or not bool(game.get("in_dungeon")):
		return
	var active_chart = game.get("active_chart")
	if not active_chart is Dictionary:
		return
	for encounter in get_tree().get_nodes_in_group("knot_eater_encounter"):
		if (encounter as Node).has_method("report_world_ready"):
			(encounter as Node).call("report_world_ready",
				String((active_chart as Dictionary).get("chart_instance_id", "")),
				String((active_chart as Dictionary).get("attempt_id", "")))


func _new_session_player_id() -> String:
	var bytes := Crypto.new().generate_random_bytes(16)
	return bytes.hex_encode() if not bytes.is_empty() else \
		"%x-%x" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]

# Any peer at an exit/abandon stone asks the host. Phase C — stepping
# through the EXIT gives the rest of the party a 5-second grace (grab
# that last pickup); tearing the chart (abandon) is immediate.
const EXIT_GRACE_SEC := 5.0
var _ending := false

func request_end(abandoned: bool) -> void:
	if is_host():
		_host_end(abandoned, multiplayer.get_unique_id())
	else:
		_end_req.rpc_id(1, abandoned)

@rpc("any_peer", "reliable")
func _end_req(abandoned: bool) -> void:
	if multiplayer.is_server():
		_host_end(abandoned, multiplayer.get_remote_sender_id())

func _host_end(abandoned: bool, who: int) -> void:
	if _ending:
		return
	# A guest cannot turn an authored additional layer into a party return.
	# The fire-keeper's own request remains the existing party-end behavior.
	var game := get_node_or_null("/root/Game")
	if not abandoned and game != null and game.has_method("can_press_deeper") \
			and bool(game.can_press_deeper()) \
			and who != multiplayer.get_unique_id():
		_end_choice_denied.rpc_id(who)
		return
	if abandoned or players.size() <= 1:
		_run_end.rpc(abandoned)
		return
	_ending = true
	_end_notice.rpc(peer_name(who))
	get_tree().create_timer(EXIT_GRACE_SEC).timeout.connect(func():
		_ending = false
		_run_end.rpc(false))

@rpc("authority", "call_local", "reliable")
func _end_notice(who_name: String) -> void:
	var game := get_node("/root/Game")
	game.notify("%s steps through the waystone — the run ends shortly."
		% who_name)
	# Phase 4 — the HUD shows a prominent countdown banner (toast above is the
	# fallback for any scene without the party HUD).
	run_ending.emit(who_name, EXIT_GRACE_SEC)

@rpc("authority", "call_local", "reliable")
func _run_end(abandoned: bool) -> void:
	var game := get_node("/root/Game")
	if not bool(game.in_dungeon):
		return
	if is_host():
		_active_chart = {}
	game.return_to_town(game.local_player(), abandoned)

@rpc("authority", "reliable")
func _end_choice_denied() -> void:
	var game := get_node_or_null("/root/Game")
	if game != null and game.has_method("notify"):
		game.notify("The fire-keeper chooses whether this Chart returns or deepens.")

# -- enemy state: the host owns every foe; guests mirror by node name.

const ENEMY_SYNC_HZ := 10.0
var _esync_accum := 0.0

func _process(delta: float) -> void:
	if not active or not multiplayer.is_server():
		return
	var game := get_node_or_null("/root/Game")
	if game == null or not bool(game.in_dungeon):
		return
	_esync_accum += delta
	if _esync_accum < 1.0 / ENEMY_SYNC_HZ:
		return
	_esync_accum = 0.0
	var batch: Dictionary = {}
	for e in get_tree().get_nodes_in_group("enemy"):
		var n := e as Node3D
		if n == null or bool((n as Node).get("dead")):
			continue
		var flags: Array = n.net_status_flags() if (n as Node).has_method("net_status_flags") else []
		batch[String(n.name)] = [n.global_position, int(n.get("hp")), flags]
	_enemy_state.rpc(batch)

var _esync_seen := false

@rpc("authority", "unreliable_ordered")
func _enemy_state(batch: Dictionary) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	if not _esync_seen:
		_esync_seen = true
		print("[net] enemy snapshots flowing (%d foes)" % batch.size())
	for nm in batch:
		var e := scene.get_node_or_null(NodePath(String(nm)))
		if e != null and e.has_method("net_apply_state"):
			var st: Array = batch[nm]
			var flags: Array = st[2] if st.size() > 2 else []
			e.net_apply_state(st[0], int(st[1]), flags)
	# A foe the host stopped sending that still lives here is dead there
	# (snapshots are set-membership, claudecraft-style).
	for e in get_tree().get_nodes_in_group("enemy"):
		var n := e as Node
		if bool(n.get("net_puppet")) and not bool(n.get("dead")) \
				and not batch.has(String(n.name)):
			if n.has_method("net_apply_state") and n is Node3D:
				n.net_apply_state((n as Node3D).global_position, 0)

# -- attribution + loot --

# Host → the killing peer: your kill, your Huntcraft xp (and Even Breath).
func kill_credit(peer: int, foe_hp_max: int) -> void:
	if is_host():
		_kill_credit.rpc_id(peer, foe_hp_max)

@rpc("authority", "reliable")
func _kill_credit(foe_hp_max: int) -> void:
	var game := get_node("/root/Game")
	game.award_xp("huntcraft", maxi(2, int(foe_hp_max / 3)))
	if game.perk_active("huntcraft", "even_breath"):
		var pl: Node = game.local_player()
		if pl != null and pl.has_method("add_focus"):
			pl.add_focus(6.0)

# Host → everyone: a foe dropped (kind, rarity); each peer rolls its OWN
# affixes locally — per-player loot instancing.
func drop_event(kind_id: String, rarity: String, pos: Vector3) -> void:
	if is_host():
		_drop_event.rpc(kind_id, rarity, pos)

@rpc("authority", "call_local", "reliable")
func _drop_event(kind_id: String, rarity: String, pos: Vector3) -> void:
	var scene := get_tree().current_scene
	if scene == null or kind_id == "":
		return
	var items = load("res://data/items.gd")
	var it: Dictionary = items.make_item(kind_id, rarity)
	if it.is_empty():
		return
	ItemPickup.spawn_scattered(scene, it, pos)

# A reprise heirloom is already a deterministic concrete item. Unlike ordinary
# boss drops it must not be rerolled per machine, but it is still spawned on
# every peer so each player owns an independent pickup / pack-full outcome.
func unique_drop_event(item: Dictionary, pos: Vector3) -> void:
	if is_host() and not item.is_empty():
		_unique_drop_event.rpc(item.duplicate(true), pos)

@rpc("authority", "call_local", "reliable")
func _unique_drop_event(item: Dictionary, pos: Vector3) -> void:
	var scene := get_tree().current_scene
	if scene == null or item.is_empty():
		return
	ItemPickup.spawn_scattered(scene, item.duplicate(true), pos)

# C-2 — Host → guests: a foe took damage; pop a matching number so guests see
# hits land (their puppet enemies don't run take_damage). NOT call_local — the
# host already showed its own via combatant._spawn_damage_number.
func dmg_event(pos: Vector3, amount: int, tier: String) -> void:
	if is_host():
		_dmg_event.rpc(pos, amount, tier)

@rpc("authority", "unreliable_ordered")
func _dmg_event(pos: Vector3, amount: int, tier: String) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var dn = load("res://scenes/DamageNumber.tscn").instantiate()
	scene.add_child(dn)
	dn.global_position = pos
	if dn.has_method("setup"):
		dn.setup(amount, tier)

# C-3 (boss telegraph replication) is DEFERRED: it presumes a host-driven
# puppet boss, but today the guest's boss runs its OWN AI (only regular
# enemies are net_puppets — layout_loader sets it on NetFoe bodies, not the
# boss). The guest therefore already telegraphs from its local boss AI; true
# host-authoritative boss sync is a larger Phase-B change. See the build log.
