extends SceneTree

# Spec 30/32b — skill system evals.
#   godot --headless --path godot --script res://test_skills.gd
#
# T1 — BasicShot via _try_skill(1) buffers a shot; F-fire path consumes it.
# T2 — PowerShot drains 20 Focus, spawns one arrow with skill_type="power"
#      and damage = round(base * 2.5), Burn SkillEffect bound.
# T3 — MultiShot drains 25 Focus, spawns three arrows, Snared SkillEffect.
# T4 — BrambleSnare roots enemies within 2.5m of aim point.
# T5 — cooldown_reduction affix scales skill 2-4 CDs (not slot 1).
# T6 — Focus regen rate changes with the in-combat timer.
# T7 — SkillEffect.apply writes the right status onto the target combatant.

const PlayerScene := preload("res://scenes/Player.tscn")
const CombatantScript := preload("res://scripts/combatant.gd")
const HitstopScript := preload("res://scripts/hitstop.gd")
const SfxScript := preload("res://scripts/sfx.gd")
const Items := preload("res://data/items.gd")

var _pass := 0
var _fail := 0

func _initialize() -> void:
	_run()

func _check(id: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
		print("  PASS  %s — %s" % [id, detail])
	else:
		_fail += 1
		print("  FAIL  %s — %s" % [id, detail])

func _run() -> void:
	print("--- spec 30/32b skill evals ---")
	_install_autoloads()
	await _t1_basicshot_via_slot1()
	await _t2_powershot_focus_and_damage()
	await _t3_multishot_three_arrows()
	await _t4_snare_roots_enemies()
	await _t5_cdr_affix_scales_skills()
	await _t6_focus_regen_rates()
	await _t7_skill_effect_apply()
	print("--- skill evals: %d PASS, %d FAIL ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _install_autoloads() -> void:
	var hs: Node = HitstopScript.new()
	hs.name = "Hitstop"
	root.add_child(hs)
	var sx: Node = SfxScript.new()
	sx.name = "Sfx"
	root.add_child(sx)

# ---- T1 — BasicShot via skill_1 sets the fire buffer ----
func _t1_basicshot_via_slot1() -> void:
	var host := Node3D.new()
	host.name = "T1Host"
	root.add_child(host)
	var p: Node3D = PlayerScene.instantiate()
	host.add_child(p)
	await physics_frame
	await physics_frame
	var f_before: float = p.focus
	p._try_skill(1)
	# Slot 1 routes through `_fire_buffer`; it doesn't pay Focus.
	var bufd: bool = p._fire_buffer > 0.0
	_check("T1", bufd and p.focus == f_before,
		"slot 1 sets fire buffer (%.2fs), Focus unchanged (%.1f → %.1f)"
		% [p._fire_buffer, f_before, p.focus])

# ---- T2 — PowerShot drains Focus, spawns one power arrow ----
func _t2_powershot_focus_and_damage() -> void:
	var host := Node3D.new()
	host.name = "T2Host"
	root.add_child(host)
	var p: Node3D = PlayerScene.instantiate()
	host.add_child(p)
	await physics_frame
	await physics_frame
	var f_before: float = p.focus
	var dmg_base: int = int(p.derived_stats.damage)
	var expected_dmg: int = int(round(float(dmg_base) * 2.5))
	p._try_skill(2)
	await physics_frame
	var n_arrows := _count_arrows(host)
	var got_power := false
	var got_dmg := -1
	var got_burn := false
	for n in _all_nodes(host):
		if n.has_method("get") and n.get("skill_type") != null:
			if String(n.get("skill_type")) == "power":
				got_power = true
				got_dmg = int(n.get("damage"))
				var effects = n.get("effects")
				if effects != null and effects.size() > 0:
					if String(effects[0].status_kind) == "burn":
						got_burn = true
				break
	var focus_drop: float = f_before - p.focus
	var on_cd: bool = p._skill_cooldowns[2] > 0.0
	_check("T2",
		n_arrows == 1 and got_power and got_dmg == expected_dmg \
			and got_burn and absf(focus_drop - 20.0) < 0.5 and on_cd,
		"arrows=%d power=%s burn=%s dmg=%d/%d focus_drop=%.1f cd=%.2fs"
		% [n_arrows, str(got_power), str(got_burn), got_dmg,
		   expected_dmg, focus_drop, p._skill_cooldowns[2]])

# ---- T3 — MultiShot spawns three arrows + drains 25 Focus ----
func _t3_multishot_three_arrows() -> void:
	var host := Node3D.new()
	host.name = "T3Host"
	root.add_child(host)
	var p: Node3D = PlayerScene.instantiate()
	host.add_child(p)
	await physics_frame
	await physics_frame
	var f_before: float = p.focus
	p._try_skill(3)
	await physics_frame
	var n_arrows := _count_arrows(host)
	var multi_count := 0
	var got_snared := false
	for n in _all_nodes(host):
		if n.has_method("get") and n.get("skill_type") != null:
			if String(n.get("skill_type")) == "multi":
				multi_count += 1
				var effects = n.get("effects")
				if effects != null and effects.size() > 0:
					if String(effects[0].status_kind) == "snared":
						got_snared = true
	var focus_drop: float = f_before - p.focus
	_check("T3",
		n_arrows == 3 and multi_count == 3 and got_snared \
			and absf(focus_drop - 25.0) < 0.5,
		"arrows=%d multi=%d snared=%s focus_drop=%.1f"
		% [n_arrows, multi_count, str(got_snared), focus_drop])

# ---- T4 — BrambleSnare roots nearby enemies ----
func _t4_snare_roots_enemies() -> void:
	var host := Node3D.new()
	host.name = "T4Host"
	root.add_child(host)
	var p: Node3D = PlayerScene.instantiate()
	host.add_child(p)
	await physics_frame
	await physics_frame
	var near := CombatantScript.new()
	host.add_child(near)
	near.global_position = Vector3(0.0, 0.0, 4.0)
	near.add_to_group("enemy")
	near.cache_meshes()
	near.setup(20, 0.4, 1.4)
	var far := CombatantScript.new()
	host.add_child(far)
	far.global_position = Vector3(10.0, 0.0, 0.0)
	far.add_to_group("enemy")
	far.cache_meshes()
	far.setup(20, 0.4, 1.4)
	if p.get("_mesh") != null:
		p._mesh.rotation.y = 0.0
	await physics_frame
	p._try_skill(4)
	await physics_frame
	var near_rooted: bool = near.is_rooted()
	var far_rooted: bool = far.is_rooted()
	_check("T4", near_rooted and not far_rooted,
		"near rooted=%s (4m away) far rooted=%s (10m away)"
		% [str(near_rooted), str(far_rooted)])

# ---- T5 — cooldown_reduction affix scales skill 2-4 CDs (not skill 1) ----
func _t5_cdr_affix_scales_skills() -> void:
	var host := Node3D.new()
	host.name = "T5Host"
	root.add_child(host)
	var p: Node3D = PlayerScene.instantiate()
	host.add_child(p)
	await physics_frame
	await physics_frame
	var ring: Dictionary = Items.make_item("copper_ring", "magic")
	ring.affixes = [{"id": "of_swiftness", "side": "suffix",
		"display": "of Swiftness", "stat": "cooldown_reduction", "value": 0.20}]
	p.equipment.equip(ring)
	await physics_frame
	# PowerShot base CD = 1.5; with CDR 0.20 → 1.5 / 1.2 = 1.25.
	var got_cd: float = p.skills[1].effective_cd(p)
	var expected: float = 1.5 / 1.2
	# BasicShot still scales via fire_rate (not cooldown_reduction).
	var slot1_cd: float = p.skills[0].effective_cd(p)
	_check("T5",
		absf(got_cd - expected) < 0.01 and absf(slot1_cd - 0.28) < 0.001,
		"PowerShot CD: %.3fs vs expected %.3fs; slot 1 CD unchanged at %.3fs"
		% [got_cd, expected, slot1_cd])

# ---- T6 — Focus regen rate is faster out of combat ----
func _t6_focus_regen_rates() -> void:
	var host := Node3D.new()
	host.name = "T6Host"
	root.add_child(host)
	var p: Node3D = PlayerScene.instantiate()
	host.add_child(p)
	await physics_frame
	await physics_frame
	p.focus = 0.0
	p._combat_t = 0.0
	for i in 30:
		await physics_frame
	var out_focus: float = p.focus
	p.focus = 0.0
	p._combat_t = 3.0
	for i in 30:
		await physics_frame
	var in_focus: float = p.focus
	_check("T6",
		out_focus > in_focus * 1.5 and out_focus > 3.0 and in_focus > 0.5,
		"out-of-combat regen %.2f vs in-combat %.2f (over ~0.5s each)"
		% [out_focus, in_focus])

# ---- T7 — SkillEffect.apply writes the right status onto the target ----
func _t7_skill_effect_apply() -> void:
	var host := Node3D.new()
	host.name = "T7Host"
	root.add_child(host)
	await physics_frame
	var e := CombatantScript.new()
	host.add_child(e)
	e.add_to_group("enemy")
	e.cache_meshes()
	e.setup(50, 0.4, 1.4)
	await physics_frame
	# Apply a Burn SkillEffect; verify the enemy has the "burn" status with
	# the right tick interval + damage_per_tick.
	var burn: SkillEffect = SkillEffect.burn(3.0, 1, 0.5)
	burn.apply(e)
	var st = e.get_status("burn")
	var burn_ok: bool = st != null \
		and absf(float(st.time_left) - 3.0) < 0.01 \
		and int(st.damage_per_tick) == 1 \
		and absf(float(st.tick_interval) - 0.5) < 0.01
	# Apply a Snared SkillEffect (no damage, slow_factor 0.5).
	var snare: SkillEffect = SkillEffect.snared(1.5, 0.5)
	snare.apply(e)
	var ss = e.get_status("snared")
	var snare_ok: bool = ss != null and absf(float(ss.slow_factor) - 0.5) < 0.01
	_check("T7", burn_ok and snare_ok,
		"burn applied (tl=%s dpt=%s interval=%s); snared slow=%s"
		% [
			str(st.time_left) if st != null else "(none)",
			str(st.damage_per_tick) if st != null else "(none)",
			str(st.tick_interval) if st != null else "(none)",
			str(ss.slow_factor) if ss != null else "(none)",
		])

# ---- helpers ----
func _count_arrows(host: Node) -> int:
	var n := 0
	for x in _all_nodes(host):
		if x.has_method("get") and x.get("skill_type") != null:
			n += 1
	return n

func _all_nodes(host: Node) -> Array:
	var out: Array = [host]
	for c in host.get_children():
		out.append_array(_all_nodes(c))
	return out
