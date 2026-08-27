extends SceneTree

# Skill runtime + progression contract. Retains the legacy dispatch, swap,
# gate, mastery, ward, and pierce coverage while adapting it to ADR-0016:
# Basic Shot is innate; 0–3 owned Huntcraft Skills are independently equipped.

const PlayerScene := preload("res://scenes/Player.tscn")
const GameScript := preload("res://scripts/game.gd")
const Progression := preload("res://data/progression.gd")
const PowerShotScript := preload("res://scripts/skills/power_shot.gd")
const LoadoutPanelScript := preload("res://scripts/ui/loadout_panel.gd")

var _pass := 0
var _fail := 0

func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % name)
	else:
		_fail += 1
		print("  ✗ %s %s" % [name, detail])

func _initialize() -> void:
	_run()

func _run() -> void:
	print("--- Skill runtime check ---")
	var game: Node = root.get_node_or_null("Game")
	if game == null:
		game = GameScript.new()
		game.name = "Game"
		root.add_child(game)
	var host := Node3D.new()
	host.name = "Host"
	root.add_child(host)
	var player: Node3D = PlayerScene.instantiate()
	host.add_child(player)
	await physics_frame
	await physics_frame
	game.persistence_enabled = false
	game.reset_to_defaults()
	player.rebuild_skills()

	_test_fresh_basic_only(game, player)
	await _test_basic_release_timing(player, host)
	_test_onboarding(game, player)
	_test_dispatch(player)
	_test_loadout_swap(game, player)
	_test_gates(game, player)
	_test_mastery_choice(game, player)
	_test_unowned_cast_rejected(game, player)
	_test_variable_loadout(game, player)
	_test_transient_gear_grant(game, player)
	_test_legacy_migrated_picks(game, player)
	_test_driving_volley_lodge_lesson(game)
	_test_threadstep_lodge_lesson(game)
	_test_wayfinders_mark_lodge_lesson(game)
	_test_planned_skills_rejected(game, player)
	_test_ui_focus_contract(player)
	_test_ward(player)
	_test_pierce(player)
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


func _skill_names(player: Node) -> Array:
	var out: Array = []
	for skill in player.skills:
		out.append(String(skill.name))
	return out

func _award_to(game: Node, trade_key: String, level: int) -> void:
	var current_xp := int(game.trades[trade_key].xp)
	var wanted_xp := Progression.xp_for_level(level)
	if wanted_xp > current_xp:
		game.award_xp(trade_key, wanted_xp - current_xp)

func _ensure_owned(game: Node, skill_id: String) -> bool:
	if game.skill_owned(skill_id):
		return true
	return game.grant_skill(skill_id)

func _test_fresh_basic_only(game: Node, player: Node3D) -> void:
	print("[fresh Basic Shot]")
	_check("fresh save owns no Focus Skills", (game.owned_skills as Array).is_empty(),
		str(game.owned_skills))
	_check("fresh player builds Basic Shot only", _skill_names(player) == ["BasicShot"],
		str(_skill_names(player)))
	_check("fresh cooldowns contain Basic Shot only", player._skill_cooldowns == {1: 0.0},
		str(player._skill_cooldowns))
	var before: float = float(player.focus)
	player._try_skill(2)
	_check("missing slot 2 cannot cast", float(player.focus) == before
		and not (player._skill_cooldowns as Dictionary).has(2))
	player._try_skill(1)
	_check("Basic Shot buffers without Focus", float(player._fire_buffer) > 0.0
		and float(player.focus) == before)


func _test_basic_release_timing(player: Node3D, host: Node) -> void:
	print("[Basic release animation]")
	var grip_shape_found := false
	var grip_shape_value := 0.0
	for candidate in player._mesh.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := candidate as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		for shape_index in mesh_instance.mesh.get_blend_shape_count():
			if String(mesh_instance.mesh.get_blend_shape_name(shape_index)) == "BowGrip_L":
				grip_shape_found = true
				grip_shape_value = mesh_instance.get_blend_shape_value(shape_index)
	_check("Ranger GLB exposes the authored palm socket and closed bow grip",
		player._skel.find_bone("Socket_Hand_L") >= 0
			and player._bow_socket.bone_name == "Socket_Hand_L"
			and grip_shape_found
			and grip_shape_value >= 0.99,
		str({"socket": player._bow_socket.bone_name,
			"grip_shape_found": grip_shape_found,
			"grip_shape_value": grip_shape_value}))
	# Clear the buffer asserted above and drive the release seam directly. The
	# projectile must not exist during the authored nock beat, then must appear
	# exactly when the pending release resolves.
	player._fire_buffer = 0.0
	player._bow_draw_t = 0.0
	player._update_bow()
	var socket_rotation_before: Vector3 = player._bow_socket.rotation
	var relative_basis_before: Basis = player._bow_socket.global_basis.orthonormalized().inverse() \
		* player._bow.global_basis.orthonormalized()
	player._bow_socket.rotation.z += deg_to_rad(25.0)
	player._update_bow()
	var relative_basis_after: Basis = player._bow_socket.global_basis.orthonormalized().inverse() \
		* player._bow.global_basis.orthonormalized()
	var hand_follow_error: float = relative_basis_before.get_rotation_quaternion().angle_to(
		relative_basis_after.get_rotation_quaternion())
	_check("bow keeps a fixed angle to the ranger's hand",
		hand_follow_error <= deg_to_rad(0.5),
		"relative rotation drift=%.2f degrees" % rad_to_deg(hand_follow_error))
	player._bow_socket.rotation = socket_rotation_before
	player._update_bow()
	var wrist_idx: int = player._skel.find_bone("LeftHand")
	var wrist_world: Vector3 = player._skel.global_transform \
		* player._skel.get_bone_global_pose(wrist_idx).origin
	var carry_hand_axis: Vector3 = (
		player._bow_socket.global_position - wrist_world).normalized()
	var carry_long_axis: Vector3 = player._bow.global_basis.y.normalized()
	var carry_string_axis: Vector3 = player._bow.global_basis.x.normalized()
	var uppermost_string_axis: Vector3 = (
		Vector3.UP - carry_hand_axis * Vector3.UP.dot(carry_hand_axis)).normalized()
	_check("lowered arm carries the bow parallel to the hand with its string uppermost",
		carry_long_axis.dot(carry_hand_axis) >= 0.99
			and carry_string_axis.dot(uppermost_string_axis) >= 0.99,
		str({"hand_axis": carry_hand_axis,
			"long_axis": carry_long_axis, "string_axis": carry_string_axis}))
	var before := host.get_children().filter(func(child: Node) -> bool:
		return child.name == "Arrow").size()
	player._begin_basic_release()
	player._update_bow()
	var full_draw_long_axis: Vector3 = player._bow.global_basis.y.normalized()
	_check("the draw keeps the bow parallel to the hand",
		full_draw_long_axis.dot(carry_hand_axis) >= 0.99,
		str({"hand_axis": carry_hand_axis, "long_axis": full_draw_long_axis}))
	_check("Basic Shot begins with a visible nock pose",
		bool(player._basic_release_pending)
			and float(player._bow_draw_t) > 0.0
			and player._bow_modifier != null
			and float(player._bow_modifier.draw_amount) > 0.99)
	await physics_frame
	await process_frame
	var palm_anchor: Vector3 = player._bow_socket.global_position
	var grip_error: float = player._bow.global_position.distance_to(palm_anchor)
	_check("bow grip remains seated in the left-palm socket during draw",
		player._bow.get_parent() == player._bow_socket
			and (player._weapon_presentation.hand_offset as Vector3).is_zero_approx()
			and grip_error <= 0.01,
		str({"parent": player._bow.get_parent(),
			"offset": player._weapon_presentation.hand_offset,
			"grip_error": grip_error}))
	var anticipation := float(player.get_script().get_script_constant_map().get(
		"BOW_ANTICIPATION_TIME", 0.07))
	var during := host.get_children().filter(func(child: Node) -> bool:
		return child.name == "Arrow").size()
	_check("arrow does not spawn before the ranger enters the draw", during == before,
		"before=%d during=%d" % [before, during])
	await create_timer(anticipation + 0.03).timeout
	var after := host.get_children().filter(func(child: Node) -> bool:
		return child.name == "Arrow").size()
	_check("arrow appears on the release beat",
		not bool(player._basic_release_pending) and after == before + 1,
		"before=%d after=%d" % [before, after])

# ---- retained onboarding disclosure coverage, now driven by real ownership ----
func _test_onboarding(game: Node, player: Node3D) -> void:
	print("[onboarding]")
	game.reset_to_defaults()
	game.tutorial_step = 0
	player.rebuild_skills()
	_check("fresh journey exposes only the Bow", _skill_names(player) == ["BasicShot"])
	var before: float = float(player.focus)
	player._try_skill(2)
	_check("untaught Focus Skill cannot cast", float(player.focus) == before
		and not (player._skill_cooldowns as Dictionary).has(2))
	# Advance through the real tutorial path. The first-return lesson grants and
	# equips Power Shot while Huntcraft is still level 1.
	for _step in 6:
		game.advance_tutorial()
	player.rebuild_skills()
	_check("first return grants Power Shot at Huntcraft 1", game.trade_lv("huntcraft") == 1
		and game.skill_owned("PowerShot") and game.loadout == ["PowerShot"])
	_check("tutorial-owned Power Shot builds below its level gate", _skill_names(player)
		== ["BasicShot", "PowerShot"], str(_skill_names(player)))
	player.focus = player.focus_max
	var tutorial_focus: float = float(player.focus)
	player._try_skill(2)
	_check("tutorial-owned Power Shot dispatches at Huntcraft 1",
		float(player.focus) < tutorial_focus and float(player._skill_cooldowns.get(2, 0.0)) > 0.0)
	game.tutorial_step = 7
	game.seen_hints["tier1_completed"] = true
	_award_to(game, "huntcraft", 6)
	game.set_loadout(["PowerShot", "BrambleSnare", "MultiShot"])
	player.rebuild_skills()
	_check("post-lesson loadout shows only the three equipped Skills",
		_skill_names(player) == ["BasicShot", "PowerShot", "BrambleSnare", "MultiShot"],
		str(_skill_names(player)))

# ---- retained dispatch checks on a full explicitly-owned loadout ----
func _test_dispatch(player: Node3D) -> void:
	print("[dispatch]")
	_check("slot 1 is Bow and equipped loadout fills 2–4",
		_skill_names(player) == ["BasicShot", "PowerShot", "BrambleSnare", "MultiShot"],
		str(_skill_names(player)))
	var seeded := true
	for i in range(1, 5):
		seeded = seeded and player._skill_cooldowns.has(i) \
			and float(player._skill_cooldowns[i]) == 0.0
	_check("cooldown keys 1–4 seed at 0 for a full bar", seeded, str(player._skill_cooldowns))
	var focus_before: float = player.focus
	player._try_skill(1)
	_check("slot 1 buffers a free shot", float(player._fire_buffer) > 0.0
		and float(player.focus) == focus_before and float(player._skill_cooldowns[1]) == 0.0)
	var cost2: float = float(player.skills[1].cost)
	focus_before = player.focus
	player._try_skill(2)
	_check("slot 2 pays Focus, seeds CD, and enters combat",
		absf((focus_before - float(player.focus)) - cost2) < 0.01
			and float(player._skill_cooldowns[2]) > 0.0 and float(player._combat_t) > 0.0)
	focus_before = player.focus
	player._try_skill(2)
	_check("recast on cooldown is a no-op", float(player.focus) == focus_before)
	player.focus = 5.0
	player._try_skill(4)
	_check("short Focus is a no-op", float(player.focus) == 5.0
		and float(player._skill_cooldowns[4]) == 0.0)

# ---- retained frozen-hotbar regression: full swap, then every slot casts ----
func _test_loadout_swap(game: Node, player: Node3D) -> void:
	print("[loadout swap]")
	_award_to(game, "huntcraft", 15)
	var ok: bool = game.set_loadout(["PiercingBolt", "RainOfThorns", "Thornburst"])
	player.rebuild_skills()
	_check("swap to three owned late Skills lands", ok and _skill_names(player) == ["BasicShot",
		"PiercingBolt", "RainOfThorns", "Thornburst"], str(_skill_names(player)))
	var reseeded: bool = player._skill_cooldowns.size() == 4
	for i in range(1, 5):
		reseeded = reseeded and player._skill_cooldowns.has(i) \
			and float(player._skill_cooldowns[i]) == 0.0
	_check("full swap re-seeds each cooldown key", reseeded, str(player._skill_cooldowns))
	for slot in range(2, 5):
		player.focus = player.focus_max
		var cost: float = float(player.skills[slot - 1].cost)
		var before: float = float(player.focus)
		player._try_skill(slot)
		_check("slot %d (%s) consumes Focus after full swap" % [slot,
			String(player.skills[slot - 1].name)], absf((before - float(player.focus)) - cost) < 0.01
			and float(player._skill_cooldowns[slot]) > 0.0)

# ---- retained validation coverage, adapted for 0–3 owned entries ----
func _test_gates(game: Node, player: Node3D) -> void:
	print("[loadout gates]")
	game.reset_to_defaults()
	player.rebuild_skills()
	_check("rejects an unowned Power Shot", not game.set_loadout(["PowerShot"]))
	_award_to(game, "huntcraft", 2)
	_check("rejects duplicates", not game.set_loadout(["PowerShot", "PowerShot"]))
	_check("accepts a one-Skill loadout", game.set_loadout(["PowerShot"]))
	_check("rejects a Skill outside the registry", not game.set_loadout(["FoxFire"]))
	_check("failed swaps leave the configured action alone", game.loadout == ["PowerShot"],
		str(game.loadout))
	_award_to(game, "huntcraft", 16)
	var ok: bool = game.set_loadout(["HuntersMark", "HeartwoodWard", "MercyShot"])
	player.rebuild_skills()
	player.focus = player.focus_max
	var before: float = float(player.focus)
	player._try_skill(2)
	_check("Huntcraft 16 opens late owned Skills and slot 2 pays", ok
		and absf((before - float(player.focus)) - float(player.skills[1].cost)) < 0.01)

# ---- retained mastery coverage, now per Trade with automatic single tiers ----
func _test_mastery_choice(game: Node, _player: Node3D) -> void:
	print("[mastery]")
	game.reset_to_defaults()
	game.chosen_perks = {}
	var fired := {"trade": "", "level": 0}
	game.mastery_choice_ready.connect(func(trade, level):
		fired.trade = trade
		fired.level = level, CONNECT_ONE_SHOT)
	_award_to(game, "huntcraft", 5)
	_check("Huntcraft XP reaches level 5", int(game.trades.huntcraft.lv) == 5,
		str(game.trades.huntcraft))
	_check("single-perk Huntcraft tier needs no choice prompt", int(fired.level) == 0)
	_check("level-5 Huntcraft perk activates automatically",
		game.perk_active("huntcraft", "steady_hands"))
	_check("unreached Huntcraft movement perk stays inactive",
		not game.perk_active("huntcraft", "hunters_stride"))
	_check("no Huntcraft choice tier is pending at level 5",
		not game.pending_mastery_levels().any(func(entry):
			return String(entry.trade) == "huntcraft" and int(entry.level) == 5))
	_check("choosing an automatic perk is rejected", not game.choose_perk("steady_hands"))
	_award_to(game, "huntcraft", 12)
	_check("quick nock activates at Huntcraft 12", game.perk_active("huntcraft", "quick_nock"))
	_check("other Trade perks stay isolated", not game.perk_active("wayfinding", "steady_hands"))
	_check("legacy empty Trade key cannot activate a perk", not game.perk_active("", "steady_hands"))
	_check("trade-aware tier lookup rejects an invalid Trade", not game.tier_chosen("hunt", 5))

func _test_unowned_cast_rejected(game: Node, player: Node3D) -> void:
	print("[unowned cast guard]")
	game.reset_to_defaults()
	player.rebuild_skills()
	# Simulate a stale local module after a save/gear change. Dispatch must read
	# entitlement state, not trust the array installed by a stale UI event.
	player.skills = [player.skills[0], PowerShotScript.new()]
	player._skill_cooldowns = {1: 0.0, 2: 0.0}
	var before: float = float(player.focus)
	player._try_skill(2)
	_check("stale unowned Focus Skill cannot dispatch", float(player.focus) == before
		and float(player._skill_cooldowns.get(2, 0.0)) == 0.0)

func _test_variable_loadout(game: Node, player: Node3D) -> void:
	print("[variable loadout]")
	game.reset_to_defaults()
	_award_to(game, "huntcraft", 6)
	_check("Huntcraft grants Power, Bramble, and Multi ownership",
		game.skill_owned("PowerShot") and game.skill_owned("BrambleSnare")
		and game.skill_owned("MultiShot"), str(game.owned_skills))
	_check("two-entry loadout is valid", game.set_loadout(["PowerShot", "BrambleSnare"]))
	player.rebuild_skills()
	_check("runtime actions exactly match a two-entry loadout",
		_skill_names(player) == ["BasicShot", "PowerShot", "BrambleSnare"],
		str(_skill_names(player)))
	_check("cooldowns exactly match the variable action set",
		player._skill_cooldowns == {1: 0.0, 2: 0.0, 3: 0.0}, str(player._skill_cooldowns))
	player.focus = player.focus_max
	var before: float = float(player.focus)
	player._try_skill(4)
	_check("absent slot 4 cannot dispatch", float(player.focus) == before
		and not (player._skill_cooldowns as Dictionary).has(4))
	_check("unowned Mercy Shot cannot equip", not game.set_loadout(["MercyShot"]))

func _test_transient_gear_grant(game: Node, player: Node3D) -> void:
	print("[transient gear Skill]")
	game.reset_to_defaults()
	_award_to(game, "huntcraft", 6)
	game.set_loadout(["PowerShot", "BrambleSnare", "MultiShot"])
	player.rebuild_skills()
	_check("full persistent bar is established", _skill_names(player)
		== ["BasicShot", "PowerShot", "BrambleSnare", "MultiShot"])
	var owned_before := (game.owned_skills as Array).duplicate()
	game.equipment.slots["weapon"] = {"enchants": ["galebrand"]}
	game.equipment.changed.emit()
	_check("Galecall displaces the last persistent runtime action", _skill_names(player)
		== ["BasicShot", "PowerShot", "BrambleSnare", "Galecall"], str(_skill_names(player)))
	_check("gear overlay does not mutate the permanent loadout",
		game.loadout == ["PowerShot", "BrambleSnare", "MultiShot"], str(game.loadout))
	_check("gear Skill never becomes a permanent entitlement",
		not game.skill_owned("Galecall") and game.owned_skills == owned_before)
	game.equipment.slots["weapon"] = null
	game.equipment.changed.emit()
	_check("removing gear restores the original persistent bar", _skill_names(player)
		== ["BasicShot", "PowerShot", "BrambleSnare", "MultiShot"],
		str(_skill_names(player)))

func _test_legacy_migrated_picks(game: Node, player: Node3D) -> void:
	print("[legacy Skill migration]")
	var migrated := Progression.normalize_save_to_v2({
		"version": 1,
		"trades": {"wayfinding": {"xp": 0}},
		"loadout": ["Power Shot", "Galecall", "MultiShot"],
	})
	_check("legacy equipped Focus Skills become owned", migrated.owned_skills
		== ["PowerShot", "MultiShot"], str(migrated.owned_skills))
	_check("legacy loadout preserves only persistent valid picks", migrated.loadout
		== ["PowerShot", "MultiShot"], str(migrated.loadout))
	game.reset_to_defaults()
	game.trades = (migrated.trades as Dictionary).duplicate(true)
	game.owned_skills = (migrated.owned_skills as Array).duplicate()
	game.loadout = (migrated.loadout as Array).duplicate()
	player.rebuild_skills()
	_check("migrated level-1 owned Skills build without a new level gate",
		game.trade_lv("huntcraft") == 1
		and _skill_names(player) == ["BasicShot", "PowerShot", "MultiShot"],
		str(_skill_names(player)))
	player.focus = player.focus_max
	var before: float = float(player.focus)
	player._try_skill(2)
	_check("migrated low-level Power Shot dispatches", float(player.focus) < before
		and float(player._skill_cooldowns.get(2, 0.0)) > 0.0)

func _test_planned_skills_rejected(game: Node, player: Node3D) -> void:
	print("[late Skill boundary]")
	game.reset_to_defaults()
	game.owned_skills = ["DrivingVolley", "Threadstep", "WayfindersMark"]
	game.loadout = ["DrivingVolley", "Threadstep", "WayfindersMark"]
	player.rebuild_skills()
	_check("implemented Fire Skills and Wayfinder's Mark enter the runtime bar",
		_skill_names(player) == ["BasicShot", "DrivingVolley", "Threadstep", "WayfindersMark"],
		str(_skill_names(player)))
	_check("the full late loadout receives exactly four runtime cooldown keys",
		player._skill_cooldowns == {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0},
		str(player._skill_cooldowns))


func _test_driving_volley_lodge_lesson(game: Node) -> void:
	print("[Driving Volley Lodge lesson]")
	game.reset_to_defaults()
	_award_to(game, "huntcraft", 18)
	game.set_loadout(["PowerShot"])
	var ready: Dictionary = game.driving_volley_lesson_status()
	var accepted: Dictionary = game.accept_driving_volley_lesson()
	_check("Huntcraft 18 exposes one Lodge lesson and equips into a free slot",
		bool(ready.available) and bool(accepted.ok) and bool(accepted.equipped)
			and game.loadout == ["PowerShot", "DrivingVolley"]
			and bool(game.seen_hints.get("driving_volley_lesson_completed", false)),
		str(accepted))
	var repeat: Dictionary = game.accept_driving_volley_lesson()
	_check("completed Lodge lesson is idempotent", not bool(repeat.changed))
	game.reset_to_defaults()
	_award_to(game, "huntcraft", 18)
	var full := ["PowerShot", "BrambleSnare", "MultiShot"]
	game.set_loadout(full)
	var deferred: Dictionary = game.accept_driving_volley_lesson()
	_check("full loadout is preserved and the lesson defers equipment",
		bool(deferred.ok) and bool(deferred.deferred) and not bool(deferred.equipped)
			and game.loadout == full and game.skill_owned("DrivingVolley"), str(deferred))


func _test_threadstep_lodge_lesson(game: Node) -> void:
	print("[Threadstep Lodge lesson]")
	game.reset_to_defaults()
	_award_to(game, "huntcraft", 20)
	# Finish the earlier authored page so the shared Lodge projects Threadstep.
	game.seen_hints["driving_volley_lesson_completed"] = true
	game.set_loadout(["PowerShot"])
	var ready: Dictionary = game.hunters_lodge_lesson_status()
	var accepted: Dictionary = game.accept_hunters_lodge_lesson()
	_check("Huntcraft 20 exposes and equips Threadstep through the shared Lodge",
		String(ready.get("lesson_id", "")) == "threadstep" and bool(accepted.ok)
			and bool(accepted.equipped) and game.loadout == ["PowerShot", "Threadstep"]
			and bool(game.seen_hints.get("threadstep_lesson_completed", false)),
		str(accepted))
	var repeat: Dictionary = game.accept_threadstep_lesson()
	_check("completed Threadstep lesson is idempotent", not bool(repeat.changed))
	game.reset_to_defaults()
	_award_to(game, "huntcraft", 20)
	game.seen_hints["driving_volley_lesson_completed"] = true
	var full := ["PowerShot", "BrambleSnare", "MultiShot"]
	game.set_loadout(full)
	var deferred: Dictionary = game.accept_threadstep_lesson()
	_check("full loadout preserves its choices and defers Threadstep",
		bool(deferred.ok) and bool(deferred.deferred) and not bool(deferred.equipped)
			and game.loadout == full and game.skill_owned("Threadstep"), str(deferred))


func _test_wayfinders_mark_lodge_lesson(game: Node) -> void:
	print("[Wayfinder's Mark Lodge lesson]")
	game.reset_to_defaults()
	_award_to(game, "huntcraft", 22)
	_check("Huntcraft 22 does not silently grant Wayfinder's Mark",
		not game.skill_owned("WayfindersMark"), str(game.owned_skills))
	game.seen_hints["driving_volley_lesson_completed"] = true
	game.seen_hints["threadstep_lesson_completed"] = true
	game.set_loadout(["PowerShot"])
	var ready: Dictionary = game.hunters_lodge_lesson_status()
	var accepted: Dictionary = game.accept_hunters_lodge_lesson()
	_check("the next physical Lodge page grants and equips Mark into a free slot",
		String(ready.get("lesson_id", "")) == "wayfinders_mark"
			and bool(accepted.ok) and bool(accepted.equipped)
			and game.skill_owned("WayfindersMark")
			and game.loadout == ["PowerShot", "WayfindersMark"]
			and bool(game.seen_hints.get("wayfinders_mark_lesson_completed", false)),
		str(accepted))
	var repeat: Dictionary = game.accept_wayfinders_mark_lesson()
	_check("completed Wayfinder's Mark lesson is idempotent", not bool(repeat.changed))
	game.reset_to_defaults()
	_award_to(game, "huntcraft", 22)
	game.seen_hints["driving_volley_lesson_completed"] = true
	game.seen_hints["threadstep_lesson_completed"] = true
	var full := ["PowerShot", "BrambleSnare", "MultiShot"]
	game.set_loadout(full)
	var deferred: Dictionary = game.accept_wayfinders_mark_lesson()
	_check("a full loadout preserves its choices and defers Wayfinder's Mark",
		bool(deferred.ok) and bool(deferred.deferred) and not bool(deferred.equipped)
			and game.loadout == full and game.skill_owned("WayfindersMark"), str(deferred))

func _test_ui_focus_contract(player: Node3D) -> void:
	print("[UI Focus contract]")
	var mismatches: Array = []
	for raw_skill in LoadoutPanelScript.FOCUS:
		var skill_id := String(raw_skill)
		var script = player.SKILL_FACTORY.get(skill_id)
		if script == null:
			mismatches.append("%s has UI data but no runtime factory" % skill_id)
			continue
		var runtime_skill = script.new()
		if int(runtime_skill.cost) != int(LoadoutPanelScript.FOCUS[skill_id]):
			mismatches.append("%s UI=%d runtime=%d" % [skill_id,
				int(LoadoutPanelScript.FOCUS[skill_id]), int(runtime_skill.cost)])
	_check("UI Focus values match implemented runtime Skill costs",
		mismatches.is_empty(), str(mismatches))

# ---- retained C8 ward coverage ----
func _test_ward(player: Node3D) -> void:
	player.apply_ward(30, 5.0)
	_check("ward applied → frac 1.0", is_equal_approx(player.get_ward_frac(), 1.0),
		str(player.get_ward_frac()))
	player.set("_iframe_t", 0.0)
	player.take_damage(10, Vector3.ZERO)
	_check("ward soaks → ward_hp 20, frac ~0.67",
		player.get_ward_hp() == 20 and absf(player.get_ward_frac() - 0.667) < 0.02,
		"hp=%d frac=%.2f" % [player.get_ward_hp(), player.get_ward_frac()])
	player.set("_iframe_t", 0.0)
	player.take_damage(50, Vector3.ZERO)
	_check("ward breaks → ward_hp 0, frac 0",
		player.get_ward_hp() == 0 and player.get_ward_frac() == 0.0)

# ---- retained C9 penetration coverage ----
func _test_pierce(player: Node3D) -> void:
	var items_data = load("res://data/items.gd")
	var item: Dictionary = items_data.make_item("copper_ring", "magic")
	item.affixes = [{"stat": "bonus_pierce", "value": 2, "side": "suffix",
		"id": "of_penetration", "display": "of Penetration"}]
	player.equipment.slots["ring"] = item
	player._derive_stats()
	_check("of_penetration → +2 bonus_pierce",
		int(player.derived_stats.get("bonus_pierce", 0)) == 2,
		str(player.derived_stats.get("bonus_pierce", -1)))
	var affixes = load("res://data/affixes.gd")
	_check("pierce affix reads cleanly",
		"pierce" in affixes.format_affix(item.affixes[0]).to_lower(),
		affixes.format_affix(item.affixes[0]))
