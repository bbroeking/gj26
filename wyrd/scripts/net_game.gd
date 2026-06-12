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

const DEFAULT_PORT := 7777
const MAX_PLAYERS := 4
const PlayerScene := preload("res://scenes/Player.tscn")

var active := false
var display_name := ""
# peer_id -> {"name": String}. On every peer; host's copy is truth.
var players: Dictionary = {}

func _ready() -> void:
	display_name = OS.get_environment("USER")
	if display_name == "":
		display_name = "Wayfinder"
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(func(): _end("No answer at that door."))
	multiplayer.server_disconnected.connect(func(): _end("The host's lantern went out."))

func is_host() -> bool:
	return active and multiplayer.is_server()

func host(port: int = DEFAULT_PORT) -> bool:
	var peer := ENetMultiplayerPeer.new()
	if peer.create_server(port, MAX_PLAYERS - 1) != OK:
		return false
	multiplayer.multiplayer_peer = peer
	active = true
	players = {1: {"name": display_name}}
	roster_changed.emit()
	return true

func join(ip: String, port: int = DEFAULT_PORT) -> bool:
	var peer := ENetMultiplayerPeer.new()
	if peer.create_client(ip, port) != OK:
		return false
	multiplayer.multiplayer_peer = peer
	active = true
	players = {}
	return true

func leave(reason: String = "You left the party.") -> void:
	_end(reason)

func _end(reason: String) -> void:
	if not active:
		return
	active = false
	players = {}
	multiplayer.multiplayer_peer = null
	roster_changed.emit()
	session_ended.emit(reason)

# ---- handshake + roster (host = truth) ----

func _on_connected() -> void:
	# We reached the host — introduce ourselves.
	_register_player.rpc_id(1, display_name)

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
