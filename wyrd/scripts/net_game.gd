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
# Phase 4 — a peer stepped through the exit; the party returns after the grace.
signal run_ending(who_name: String, seconds: float)

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

# reconnect state (guest only)
var _last_ip := ""
var _last_port := DEFAULT_PORT
var _leaving := false
var _reconnect_left := 0
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
	players = {}
	multiplayer.multiplayer_peer = null
	roster_changed.emit()
	session_ended.emit(reason)

# ---- handshake + roster (host = truth) ----

func _on_connected() -> void:
	# We reached the host — introduce ourselves (and clear any reconnect run).
	_reconnect_left = 0
	_register_player.rpc_id(1, display_name)

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
func _register_player(p_name: String) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	players[id] = {"name": p_name}
	_sync_roster.rpc(players)
	_apply_roster()
	# C-4 — a peer that joins (or rejoins after a drop) while the host is mid-
	# dungeon drops straight into the same chart; same seed → deterministic
	# rebuild, no extra data transfer.
	var game := get_node_or_null("/root/Game")
	if game != null and bool(game.in_dungeon) and not _active_chart.is_empty():
		game.notify("%s joins the delve." % p_name)
		_rejoin_run.rpc_id(id, _active_chart)

@rpc("authority", "call_local", "reliable")
func _sync_roster(p_players: Dictionary) -> void:
	players = p_players
	_apply_roster()

func _apply_roster() -> void:
	roster_changed.emit()
	_reconcile_players()

# ---- per-peer player bodies ----
# Each peer's scene holds one Player node per roster entry, named by peer
# id under the scene root, with authority assigned to that peer. The
# roster being identical everywhere keeps the node paths identical.

func _reconcile_players() -> void:
	var scene := get_tree().current_scene
	if scene == null or not active:
		return
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
	game.return_to_town(game.local_player(), abandoned)

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
	# ADR 0012 — combat gives no skill XP; Even Breath still refunds Focus.
	if game.perk_active("wayfinding", "even_breath"):
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
	var ang := randf() * TAU
	var kick := Vector3(cos(ang), 0.0, sin(ang)) * randf_range(0.4, 1.0)
	ItemPickup.spawn(scene, it, pos + kick)

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
