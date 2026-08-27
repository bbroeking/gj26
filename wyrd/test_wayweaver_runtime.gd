extends SceneTree

# Focused D8 Slice 3 runtime seam. This exercises the real Player body rather
# than duplicating its reducer logic: attachment swaps stay single-socket, a
# Focus arms only in an authored presence, and the actual Basic-release helper
# consumes one transient identity without touching Game/save state.

const PlayerScene := preload("res://scenes/Player.tscn")
const ItemsData := preload("res://data/items.gd")
const Presentations := preload("res://data/weapon_presentations.gd")
const Rules := preload("res://scripts/wayweaver_thread_rules.gd")

var _pass := 0
var _fail := 0

func _initialize() -> void:
	print("--- Wayweaver player runtime check ---")
	var game: Node = root.get_node_or_null("Game")
	if game == null:
		_fail += 1
		print("  x Game autoload missing")
		quit(1)
		return
	game.persistence_enabled = false
	game.reset_to_defaults()
	var host := Node3D.new()
	root.add_child(host)
	var player: Node3D = PlayerScene.instantiate()
	host.add_child(player)
	await physics_frame
	await physics_frame

	var wayweaver := ItemsData.make_item("wayweaver", "legendary")
	game.equipment.equip(wayweaver)
	await process_frame
	_test_presentation(player, wayweaver)
	_test_thread_lifecycle(player)
	_test_real_focus_dispatch(player, game)
	_test_effect_descriptors(player)
	_test_host_echo_adapter(player, game)
	_test_remote_thread_invalidation(player, game)
	_test_weapon_loss_burns(player)

	player.queue_free()
	host.queue_free()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


func _presence(room_id := "12") -> Dictionary:
	return {"run_epoch": 9, "layer": 0, "room_id": room_id, "eligible": true}


func _test_presentation(player: Node3D, wayweaver: Dictionary) -> void:
	var resolved := Presentations.for_item(wayweaver)
	var socket := player.find_child("LeftHandWeaponSocket", true, false)
	_check("Wayweaver resolves to its own rigid GLB and rune cosmetic",
		String(resolved.scene_path) == "res://models/wayweaver_v1.glb"
			and String(resolved.rune_cosmetic) == "wayweaver_bright_strand"
			and resolved.tint == null
			and is_equal_approx(float(resolved.scale), 0.40)
			and (resolved.rotation_degrees as Vector3).is_equal_approx(Vector3.ZERO), resolved)
	var fallback := Presentations.for_item(null)
	_check("familiar bow stays chibi-sized and authored-upright",
		String(fallback.scene_path) == "res://models/prop_shortbow_v2.glb"
			and is_equal_approx(float(fallback.scale), 1.0)
			and (fallback.rotation_degrees as Vector3).is_equal_approx(Vector3.ZERO), fallback)
	_check("shortbow grip stays inside the Ranger's left palm",
		(fallback.hand_offset as Vector3).is_zero_approx(),
		{"hand_offset": fallback.hand_offset,
			"expected_palm_anchor": Vector3.ZERO})
	_check("equipping Wayweaver replaces the single existing hand child",
		socket != null and player._bow != null and String(player._weapon_presentation.scene_path)
			== "res://models/wayweaver_v1.glb" and player._bow.get_parent() == socket
			and (player._bow.scale as Vector3).is_equal_approx(Vector3.ONE * 0.40),
		{"socket": socket, "presentation": player._weapon_presentation})
	wayweaver["cosmetic_rune_id"] = "mist_root_rune"
	var game: Node = root.get_node_or_null("Game")
	game.equipment.equip(wayweaver)
	player.set_wayweaver_room_presence(_presence("rune"))
	player._arm_wayweaver_after_focus("MultiShot", true)
	var armed_style: Dictionary = player.wayweaver_strand_presentation()
	_check("equipped Rune colors the bright strand by the armed thread identity, not a stat",
		String(player._weapon_presentation.cosmetic_rune_id) == "mist_root_rune"
			and String(armed_style.thread_identity) == "fan"
			and String(armed_style.sfx) == "wayweaver_rune_mist"
			and not armed_style.has("damage"), armed_style)
	player._is_remote = true
	player._net_state(player.global_position, 0.0, false, false, -1, -1, true, "ember_root_rune")
	var remote_valid := String(player._weapon_presentation.get("cosmetic_rune_id", ""))
	player._net_state(player.global_position, 0.0, false, false, -1, -1, true, "forged_root_rune")
	var remote_invalid := String(player._weapon_presentation.get("cosmetic_rune_id", ""))
	player._is_remote = false
	game.equipment.equip(wayweaver)
	_check("remote state carries only a validated cosmetic Rune enum and fails closed",
		remote_valid == "ember_root_rune" and remote_invalid == "",
		{"valid": remote_valid, "invalid": remote_invalid})


func _test_thread_lifecycle(player: Node3D) -> void:
	player.set_wayweaver_room_presence(_presence())
	var armed: Dictionary = player._arm_wayweaver_after_focus("PowerShot", true)
	_check("real local Focus success arms its room identity", bool(armed.ok)
		and String(armed.identity) == "pierce" and player.wayweaver_thread_state().state == Rules.ARMED, armed)
	var release: Dictionary = player._consume_wayweaver_basic_release()
	var modifiers: Dictionary = player.take_wayweaver_basic_modifiers()
	_check("Basic release spends before hit resolution and grants only +1 pierce",
		bool(release.ok) and int(modifiers.pierce_bonus) == 1
			and player.wayweaver_thread_state().state == Rules.SPENT
			and String(player.wayweaver_strand_presentation().get("thread_state", "")) == Rules.SPENT,
		{"release": release, "mods": modifiers, "strand": player.wayweaver_strand_presentation()})
	_check("spent room cannot re-arm from a later Focus", not bool(player._arm_wayweaver_after_focus(
		"MultiShot", true).ok), player.wayweaver_thread_state())
	player.set_wayweaver_room_presence(_presence("13"))
	player._arm_wayweaver_after_focus("HeartwoodWard", true)
	player._wayweaver_threads.invalidate("test")
	_check("invalidation clears session-only room memory", player.wayweaver_thread_state().state == Rules.FRESH)


func _test_effect_descriptors(player: Node3D) -> void:
	player.set_wayweaver_room_presence(_presence("14"))
	player._arm_wayweaver_after_focus("BrambleSnare", true)
	var root_release: Dictionary = player._consume_wayweaver_basic_release()
	var root_modifiers: Dictionary = player.take_wayweaver_basic_modifiers()
	var root_effects: Array = root_modifiers.get("effects", [])
	_check("root echo is a first-hit primary-bolt effect with the locked duration",
		bool(root_release.ok) and root_effects.size() == 1
			and String(root_effects[0].status_kind) == "root"
			and is_equal_approx(float(root_effects[0].duration), 0.75), root_modifiers)
	player.apply_ward(30, 6.0)
	player.set_wayweaver_room_presence(_presence("15"))
	player._arm_wayweaver_after_focus("HeartwoodWard", true)
	player._emit_wayweaver_release_effect(player._consume_wayweaver_basic_release(), Vector3.FORWARD)
	_check("ward echo preserves a stronger active ward and duration", player.get_ward_hp() == 30
		and float(player._ward_t) >= 6.0, {"hp": player.get_ward_hp(), "time": player._ward_t})


func _test_real_focus_dispatch(player: Node3D, game: Node) -> void:
	game.grant_skill("PowerShot")
	game.set_loadout(["PowerShot"])
	player.rebuild_skills()
	player.focus = player.focus_max
	player.set_wayweaver_room_presence(_presence("17"))
	var before := float(player.focus)
	player._try_skill(2)
	_check("generic Focus dispatch arms only after its real debit/fire path",
		float(player.focus) < before and player.wayweaver_thread_state().state == Rules.ARMED
			and player.wayweaver_thread_state().identity == "pierce", player.wayweaver_thread_state())


func _test_host_echo_adapter(player: Node3D, game: Node) -> void:
	# The direct host adapter uses the real Player reducer and effect preparation,
	# while the pure authority suite covers forged transport payloads.
	# This is the local-host order used by `_consume_wayweaver_basic_release`:
	# one reducer spend is staged into the authority receipt, then the actual
	# Basic finds the prepared modifier. A second reducer consume would reject.
	player.set_wayweaver_room_presence(_presence("18"))
	var armed: Dictionary = player._arm_wayweaver_host_after_focus("PowerShot")
	var local_release: Dictionary = player._wayweaver_threads.consume_basic_release(
		player._wayweaver_presence, true, player._wayweaver_equipped())
	var accepted: Dictionary = player._wayweaver_begin_local_host_basic(
		local_release, 88001, Vector3.FORWARD)
	var duplicate: Dictionary = player._wayweaver_echo_host_attempt(
		player.get_multiplayer_authority(), 88001, Vector3.FORWARD)
	var modifiers: Dictionary = player.take_wayweaver_basic_modifiers()
	_check("local-host Focus then Basic consumes one reducer and applies one echo",
		bool(armed.ok) and bool(accepted.accepted) and bool(duplicate.duplicate)
			and int(modifiers.pierce_bonus) == 1
			and player.wayweaver_echo_gameplay_applications() == 1
			and player.wayweaver_thread_state().state == Rules.SPENT,
		{"accepted": accepted, "duplicate": duplicate, "mods": modifiers})
	# A host replica must consume with the same compact party-trust weapon fact
	# it used to validate; it cannot accidentally read the host player's gear.
	game.equipment.equip(ItemsData.make_item("warbow", "rare"))
	player._is_remote = true
	player._net_wayweaver_equipped = true
	player.set_wayweaver_room_presence(_presence("19"))
	var guest_arm: Dictionary = player._arm_wayweaver_host_after_focus("PowerShot")
	player._observe_wayweaver_host_basic(Vector3.FORWARD, player.derived_stats)
	var guest_receipt: Dictionary = player._wayweaver_echo_host_attempt(
		player.get_multiplayer_authority(), 88002, Vector3.FORWARD)
	_check("remote host body accepts one attested Wayweaver echo without host gear",
		bool(guest_arm.ok) and bool(guest_receipt.accepted)
			and player.wayweaver_echo_gameplay_applications() == 2,
		{"arm": guest_arm, "receipt": guest_receipt})
	player.set_wayweaver_room_presence(_presence("20"))
	# A Basic before any valid Focus must not leave a token that a later Focus
	# can borrow. The second observed Basic is the only one eligible to echo.
	player._observe_wayweaver_host_basic(Vector3.FORWARD, player.derived_stats)
	var no_armed_token: bool = player._wayweaver_host_basic_tokens.is_empty()
	var token_arm: Dictionary = player.arm_wayweaver_after_host_focus_cast("PowerShot")
	var forged: Dictionary = player._wayweaver_echo_host_attempt(
		player.get_multiplayer_authority(), 88004, Vector3.FORWARD)
	player._observe_wayweaver_host_basic(Vector3.FORWARD, player.derived_stats)
	var after_basic: Dictionary = player._wayweaver_echo_host_attempt(
		player.get_multiplayer_authority(), 88005, Vector3.FORWARD)
	_check("remote pre-Focus Basic cannot stale-correlate; later armed Basic echoes once",
		no_armed_token and bool(token_arm.ok) and String(forged.reason) == "not_basic_release"
			and bool(after_basic.accepted) and player.wayweaver_echo_gameplay_applications() == 3,
		{"forged": forged, "after_basic": after_basic})
	player.set_wayweaver_room_presence(_presence("21"))
	var mismatched_slot_arm: Dictionary = player.arm_wayweaver_after_host_focus_cast("MultiShot")
	_check("guest declared MultiShot arms fan even when host slot data differs",
		bool(mismatched_slot_arm.ok) and String(mismatched_slot_arm.identity) == "fan",
		mismatched_slot_arm)
	player.set_wayweaver_room_presence(_presence("22"))
	var threadstep_arm: Dictionary = player.arm_wayweaver_after_host_acceptance("Threadstep")
	player.set_wayweaver_room_presence(_presence("23"))
	var mark_arm: Dictionary = player.arm_wayweaver_after_host_acceptance("WayfindersMark")
	_check("host-only Threadstep and Mark acceptance adapters arm only mark identity",
		bool(threadstep_arm.ok) and String(threadstep_arm.identity) == "mark"
			and bool(mark_arm.ok) and String(mark_arm.identity) == "mark",
		{"threadstep": threadstep_arm, "mark": mark_arm})
	player._is_remote = false
	player._net_wayweaver_equipped = false
	var replay_wayweaver := ItemsData.make_item("wayweaver", "legendary")
	replay_wayweaver["cosmetic_rune_id"] = "mist_root_rune"
	game.equipment.equip(replay_wayweaver)
	var replay_sfx_before: int = player.wayweaver_rune_sfx_applications()
	player.apply_ward(0, 0.0)
	var ward_receipt := {"nonce": 88003, "accepted": true, "descriptor": {
		"identity": "ward", "effect": {"kind": "ward", "amount": 8, "duration_seconds": 4.0}}}
	player._wayweaver_echo_replay(ward_receipt, Vector3.FORWARD)
	player._wayweaver_echo_replay(ward_receipt, Vector3.FORWARD)
	_check("owner replay applies one max-preserving Ward and drops duplicate receipt",
		player.get_ward_hp() == 8 and player.wayweaver_echo_replay_applications() == 1,
		{"ward": player.get_ward_hp(), "replays": player.wayweaver_echo_replay_applications()})
	_check("one accepted host replay gives the guest owner exactly one selected-Rune sound",
		player.wayweaver_rune_sfx_applications() == replay_sfx_before + 1,
		{"before": replay_sfx_before, "after": player.wayweaver_rune_sfx_applications()})


func _test_remote_thread_invalidation(player: Node3D, game: Node) -> void:
	game.equipment.equip(ItemsData.make_item("warbow", "rare"))
	player._is_remote = true
	player.dead = false
	player._net_wayweaver_equipped = true
	player.set_wayweaver_room_presence(_presence("24"))
	var death_arm: Dictionary = player._arm_wayweaver_host_after_focus("PowerShot")
	player._net_state(Vector3.ZERO, 0.0, false, true, 30, 30, true)
	var death_cleared: bool = player.wayweaver_thread_state().state == Rules.FRESH
	# Restore a living attested puppet, arm a new room, then make the
	# Wayweaver attestation fall. This is the actual compact state-RPC edge.
	player._net_state(Vector3.ZERO, 0.0, false, false, 30, 30, true)
	player.set_wayweaver_room_presence(_presence("25"))
	var loss_arm: Dictionary = player._arm_wayweaver_host_after_focus("PowerShot")
	player._net_state(Vector3.ZERO, 0.0, false, false, 30, 30, false)
	_check("remote death and Wayweaver-loss state edges invalidate host puppet threads",
		bool(death_arm.ok) and death_cleared and bool(loss_arm.ok)
			and player.wayweaver_thread_state().state == Rules.FRESH,
		{"death": death_arm, "loss": loss_arm, "state": player.wayweaver_thread_state()})
	player._is_remote = false
	player._net_wayweaver_equipped = false
	player.dead = false
	game.equipment.equip(ItemsData.make_item("wayweaver", "legendary"))


func _test_weapon_loss_burns(player: Node3D) -> void:
	player.set_wayweaver_room_presence(_presence("16"))
	player._arm_wayweaver_after_focus("HuntersMark", true)
	var game: Node = root.get_node_or_null("Game")
	game.equipment.equip(ItemsData.make_item("warbow", "rare"))
	_check("weapon replacement burns an armed thread and restores fallback presentation",
		player.wayweaver_thread_state().state == Rules.SPENT
			and String(player._weapon_presentation.scene_path) == "res://models/prop_shortbow_v2.glb")


func _check(label: String, ok: bool, detail = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % label)
	else:
		_fail += 1
		print("  x %s %s" % [label, str(detail)])
