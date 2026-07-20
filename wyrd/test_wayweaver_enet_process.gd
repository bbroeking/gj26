extends SceneTree

# D8 external-process acceptance harness.  Run this script twice through
# tools/run_wayweaver_enet_process.sh: once as a loopback host and once as a
# guest.  The two processes own independent Game/NetGame autoloads and use
# the shipped PlayerController RPCs on matching NetPlayer node paths.
#
# This is intentionally not an in-process multiplayer mock.  The only test
# seam is RoomPresence: the harness has no World/LayoutLoader, so it supplies
# an otherwise-authoritative, eligible room to each real Player body.

const ItemsData := preload("res://data/items.gd")
const ThreadRules := preload("res://scripts/wayweaver_thread_rules.gd")

const HOST_READY := "host-ready"
const GUEST_FORGED_SENT := "guest-forged-sent"
const HOST_FORGED_OBSERVED := "host-forged-observed"
const GUEST_FOCUS_SENT := "guest-focus-sent"
const HOST_FOCUS_OBSERVED := "host-focus-observed"
const GUEST_CAST_SENT := "guest-cast-sent"
const GUEST_ECHO_COMPLETE := "guest-echo-complete"
const HOST_ECHO_COMPLETE := "host-echo-complete"
const GUEST_DUPLICATE_COMPLETE := "guest-duplicate-complete"
const HOST_ARM_LOSS := "host-arm-loss"
const GUEST_WEAPON_LOST := "guest-weapon-lost"
const HOST_LOSS_COMPLETE := "host-loss-complete"
const GUEST_CLOSED := "guest-closed"

var _role := ""
var _port := 0
var _state_dir := ""
var _scene: Node3D
var _net: Node
var _game: Node
var _failed := false
var _finishing := false


func _initialize() -> void:
	_role = OS.get_environment("WYRD_WAYWEAVER_ENET_ROLE")
	_port = int(OS.get_environment("WYRD_WAYWEAVER_ENET_PORT"))
	_state_dir = OS.get_environment("WYRD_WAYWEAVER_ENET_STATE_DIR")
	if _role not in ["host", "guest"] or _port <= 0 or _state_dir == "":
		_fail("missing role, port, or shared state directory")
		_finish()
		return
	_scene = Node3D.new()
	_scene.name = "WayweaverENetHarness"
	root.add_child(_scene)
	current_scene = _scene
	_net = root.get_node_or_null("NetGame")
	_game = root.get_node_or_null("Game")
	if _net == null or _game == null:
		_fail("required NetGame/Game autoload absent")
		_finish()
		return
	_game.persistence_enabled = false
	_game.reset_to_defaults()
	call_deferred("_run")


func _run() -> void:
	if _role == "host":
		await _run_host()
	else:
		await _run_guest()
	_finish()


func _run_host() -> void:
	if not bool(_net.host(_port)):
		_fail("could not bind loopback ENet port %d" % _port)
		return
	_net.setup_scene(_scene)
	# A bare SceneTree has no Town's frame choreography. Keep the host's unused
	# local body quiet until the guest has created its matching host replica so
	# this gate never masks a genuine RPC failure behind a startup-path race.
	var host_body: Node = _body(1)
	if host_body != null:
		host_body.process_mode = Node.PROCESS_MODE_DISABLED
	print("ENET_D8_HOST_LISTENING port=%d" % _port)
	if not await _wait_until(func(): return (_net.players as Dictionary).size() == 2, 10.0,
			"guest roster registration"):
		return
	var guest_id := _guest_peer_id()
	var guest_body: Node = _body(guest_id)
	if guest_body == null:
		_fail("host did not spawn guest-owned production body")
		return
	if not await _wait_until(func(): return bool(guest_body._net_wayweaver_equipped), 5.0,
			"guest Wayweaver equipment attestation"):
		return
	# Invalid cosmetic enum must never survive the compact state RPC.  This also
	# demonstrates that the host validates the remote-owned body rather than
	# reading its own equipment record.
	_expect(String(guest_body._net_wayweaver_rune_id) == "",
		"invalid guest Rune enum neutralized in host attestation")
	guest_body.set_wayweaver_room_presence(_presence("enet-a"))
	_write_marker(HOST_READY)
	if not await _wait_for_marker(GUEST_FORGED_SENT, 5.0):
		return
	await create_timer(0.20).timeout
	_expect(int(guest_body.wayweaver_echo_gameplay_applications()) == 0,
		"pre-Basic forged request produces no host gameplay")
	print("ENET_D8_HOST_FORGED_OBSERVED")
	_write_marker(HOST_FORGED_OBSERVED)
	if not await _wait_for_marker(GUEST_FOCUS_SENT, 5.0):
		return
	if not await _wait_until(func(): return String(guest_body.wayweaver_thread_state().get(
			"state", "")) == ThreadRules.ARMED, 3.0, "guest Focus host arm"):
		return
	print("ENET_D8_HOST_FOCUS_OBSERVED")
	_write_marker(HOST_FOCUS_OBSERVED)
	if not await _wait_for_marker(GUEST_CAST_SENT, 6.0):
		return
	if not await _wait_until(func(): return int(guest_body.wayweaver_echo_gameplay_applications()) == 1,
			5.0, "one host echo application"):
		return
	_expect(String(guest_body.wayweaver_thread_state().get("state", "")) == ThreadRules.SPENT,
		"host remote reducer spends exactly its armed room")
	_write_marker(HOST_ECHO_COMPLETE)
	if not await _wait_for_marker(GUEST_DUPLICATE_COMPLETE, 5.0):
		return
	# Allow the duplicate request one full reliable round trip.  The ledger must
	# replay its receipt but never add another gameplay application.
	await create_timer(0.35).timeout
	_expect(int(guest_body.wayweaver_echo_gameplay_applications()) == 1,
		"forged and duplicate echo requests add no host gameplay")
	guest_body.set_wayweaver_room_presence(_presence("enet-loss"))
	var arm: Dictionary = guest_body.arm_wayweaver_after_host_focus_cast("MultiShot")
	_expect(bool(arm.get("ok", false)),
		"host reducer accepts guest Focus identity, not host loadout")
	_write_marker(HOST_ARM_LOSS)
	if not await _wait_for_marker(GUEST_WEAPON_LOST, 5.0):
		return
	if not await _wait_until(func(): return not bool(guest_body._net_wayweaver_equipped), 5.0,
			"guest weapon-loss attestation"):
		return
	_expect(String(guest_body.wayweaver_thread_state().get("state", "")) == ThreadRules.FRESH,
		"remote weapon-loss state edge invalidates host reducer")
	_write_marker(HOST_LOSS_COMPLETE)
	if not await _wait_for_marker(GUEST_CLOSED, 5.0):
		return
	if not _failed:
		print("ENET_D8_HOST_PASS attested=1 focus=fan basic_before_echo=1 echo=1 replay=1 loss_invalidated=1")


func _run_guest() -> void:
	if not bool(_net.join("127.0.0.1", _port)):
		_fail("could not create loopback ENet client")
		return
	if not await _wait_until(func(): return (_net.players as Dictionary).size() == 2, 10.0,
			"host roster snapshot"):
		return
	# setup_scene is normally called by Town's one-shot roster listener.  The
	# test harness has no Town, so it invokes NetGame's same public scene seam.
	_net.setup_scene(_scene)
	var local_peer_id := _net.multiplayer.get_unique_id()
	var me: Node = _body(local_peer_id)
	if me == null:
		if not await _wait_until(func(): return _body(local_peer_id) != null, 3.0,
				"guest local production body"):
			return
		me = _body(local_peer_id)
	var invalid_rune_wayweaver := ItemsData.make_item("wayweaver", "legendary")
	invalid_rune_wayweaver["cosmetic_rune_id"] = "forged_root_rune"
	_game.equipment.equip(invalid_rune_wayweaver)
	_game.grant_skill("MultiShot")
	_game.set_loadout(["MultiShot"])
	me.rebuild_skills()
	me.focus = me.focus_max
	me.set_wayweaver_room_presence(_presence("enet-a"))
	if not await _wait_for_marker(HOST_READY, 8.0):
		return
	# This direct packet is deliberately sent before Focus/Basic.  It travels on
	# the same dedicated production RPC and must not produce an effect.
	me._wayweaver_echo_request.rpc_id(1, 700001, Vector3.FORWARD)
	await create_timer(0.25).timeout
	_write_marker(GUEST_FORGED_SENT)
	if not await _wait_for_marker(HOST_FORGED_OBSERVED, 5.0):
		return
	# The ordinary input dispatcher is the acceptance path: debit/fire then the
	# generic Focus RPC.  Host's remote body must derive `fan` from this declared
	# identity even though the host's local loadout remains unrelated.
	me._try_skill(2)
	if not await _wait_until(func(): return String(me.wayweaver_thread_state().get("state", "")) == ThreadRules.ARMED,
			2.0, "guest local Focus arm"):
		return
	_write_marker(GUEST_FOCUS_SENT)
	if not await _wait_for_marker(HOST_FOCUS_OBSERVED, 5.0):
		return
	# Slot 1 buffers then releases from PlayerController._physics_process. That
	# real release spends the local mirror, fires Basic, forwards `_net_cast`,
	# then forwards the nonce-only dedicated request in reliable order.
	me._try_skill(1)
	print("ENET_D8_GUEST_BASIC_BUFFER move=%s dead=%s remote=%s owner=%s self=%s buffer=%s cooldown=%s skills=%s" % [
		str(me._move), str(me.dead), str(me._is_remote), str(me.get_multiplayer_authority()),
		str(_net.multiplayer.get_unique_id()), str(me._fire_buffer), str(me._skill_cooldowns), str(me.skills.size())])
	# SceneTree `--script` harnesses do not automatically schedule child physics
	# callbacks. Advance the real PlayerController input tick once; this is the
	# shipped buffered Basic branch above, not a test-only cast helper.
	me._physics_process(1.0 / 60.0)
	if not await _wait_until(func(): return not (me._wayweaver_echo_pending as Dictionary).is_empty(),
			2.0, "guest real Basic release"):
		return
	var nonce := int((me._wayweaver_echo_pending as Dictionary).get("nonce", 0))
	_expect(nonce > 0, "Basic release created a dedicated echo nonce")
	_write_marker(GUEST_CAST_SENT)
	if not await _wait_for_marker(HOST_ECHO_COMPLETE, 6.0):
		return
	if not await _wait_until(func(): return _guest_echo_received(me), 5.0,
		"accepted receipt and one replay on guest owner"):
		return
	_expect(String(me.wayweaver_thread_state().get("state", "")) == ThreadRules.SPENT,
		"guest real Basic spends the local transient mirror")
	# Replay the already accepted nonce through the actual guest->host RPC.
	# The host ledger must return its stored receipt without a second effect.
	me._wayweaver_echo_request.rpc_id(1, nonce, me.aim_dir())
	await create_timer(0.25).timeout
	_expect(int(me.wayweaver_echo_replay_applications()) == 1,
		"duplicate receipt is idempotent on guest")
	_write_marker(GUEST_DUPLICATE_COMPLETE)
	if not await _wait_for_marker(HOST_ARM_LOSS, 5.0):
		return
	_game.equipment.equip(ItemsData.make_item("warbow", "rare"))
	if not await _wait_until(func(): return not bool(me.wayweaver_equipped()), 2.0,
			"guest local weapon replacement"):
		return
	# As above, explicitly advance the production replication tick in this
	# script-only tree so the host observes the exact `_net_state` loss edge.
	me._net_send_tick(1.0 / 6.0)
	_write_marker(GUEST_WEAPON_LOST)
	if not await _wait_for_marker(HOST_LOSS_COMPLETE, 5.0):
		return
	# Close deliberately while the host is still serving.  This prevents NetGame's
	# reconnect machinery from mistaking an acceptance-test shutdown for a lost
	# host and keeps the two-process gate's logs meaningful.
	_net.leave("D8 ENet guest complete")
	await create_timer(0.12).timeout
	_write_marker(GUEST_CLOSED)
	if not _failed:
		print("ENET_D8_GUEST_PASS input_focus=1 input_basic=1 receipt=1 replay=1 duplicate=0")


func _presence(room_id: String) -> Dictionary:
	return {"run_epoch": 91, "layer": 0, "room_id": room_id, "eligible": true}


func _guest_peer_id() -> int:
	for raw_id in (_net.players as Dictionary).keys():
		var id := int(raw_id)
		if id != 1:
			return id
	return 0


func _body(peer_id: int) -> Node:
	return _scene.get_node_or_null("NetPlayer%d" % peer_id)


func _guest_echo_received(player: Node) -> bool:
	return (player._wayweaver_echo_pending as Dictionary).is_empty() \
		and int(player.wayweaver_echo_replay_applications()) == 1


func _marker_path(name: String) -> String:
	return _state_dir.path_join(name)


func _write_marker(name: String) -> void:
	var f := FileAccess.open(_marker_path(name), FileAccess.WRITE)
	if f == null:
		_fail("cannot write marker %s" % name)
		return
	f.store_string("ok\n")
	f.close()


func _wait_for_marker(name: String, timeout_sec: float) -> bool:
	return await _wait_until(func(): return FileAccess.file_exists(_marker_path(name)), timeout_sec,
		"marker %s" % name)


func _wait_until(predicate: Callable, timeout_sec: float, label: String) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if predicate.call():
			return true
		await create_timer(0.03).timeout
	_fail("timed out waiting for %s" % label)
	return false


func _expect(ok: bool, label: String) -> void:
	if ok:
		print("ENET_D8_OK role=%s %s" % [_role, label])
	else:
		_fail(label)


func _fail(label: String) -> void:
	_failed = true
	push_error("ENET_D8_FAIL role=%s %s" % [_role, label])
	print("ENET_D8_FAIL role=%s %s" % [_role, label])


func _finish() -> void:
	if _finishing:
		return
	_finishing = true
	if _net != null and bool(_net.active):
		_net.leave("D8 ENet harness complete")
	# PlayerController exercises rune-release audio on the accepted host echo.
	# Explicitly drain the existing Sfx pool before the SceneTree exits; its
	# AudioStreamPlayback handles otherwise outlive a short-lived test process.
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("shutdown"):
		sfx.shutdown()
	# Free the real Player/arrow tree before terminating the script main loop.
	# Immediate quit otherwise reports live GLB/ENet resources even after a
	# successful test, hiding actual diagnostics in the runner log.
	if _scene != null and is_instance_valid(_scene):
		_scene.free()
	# ENet and AudioServer release their queued handles on subsequent main-loop
	# turns after `leave()` / Sfx.shutdown(). Allow a bounded drain before quit.
	create_timer(0.20).timeout.connect(_quit_clean)


func _quit_clean() -> void:
	quit(1 if _failed else 0)
