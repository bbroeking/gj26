extends SceneTree

# Spec 31 — status framework + AoE helpers evals.
#   godot --headless --path godot --script res://test_statuses.gd
#
# T1 — apply_status("burn") ticks 6 × 1 dmg over 3s.
# T2 — PowerShot arrow hit applies burn via the arrow.gd dispatch.
# T3 — MultiShot arrow hit applies snared with slow_factor = 0.5.
# T4 — Critical hit applies bleed; non-crit doesn't.
# T5 — Re-applying burn refreshes to MAX duration + MAX damage_per_tick.
# T6 — Boss is immune to root + snared; takes burn at 50% reduced duration.
# T7 — AoeQuery.query_circle returns combatants strictly inside the radius.

const CombatantScript := preload("res://scripts/combatant.gd")
const BossScript := preload("res://scripts/boss.gd")
const HitstopScript := preload("res://scripts/hitstop.gd")
const SfxScript := preload("res://scripts/sfx.gd")
const ArrowScene := preload("res://scenes/Arrow.tscn")

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
	print("--- spec 31 status + AoE evals ---")
	_install_autoloads()
	await _t1_burn_ticks()
	await _t2_powershot_applies_burn()
	await _t3_multishot_applies_snared()
	await _t4_crit_applies_bleed()
	await _t5_status_refresh_rules()
	await _t6_boss_immunity()
	await _t7_query_circle()
	await _t8_blightwalker_on_death()
	await _t9_warden_heals_ally()
	await _t10_brute_ring_lifecycle()
	await _t11_cc_immune_elites()
	await _t12_execute_ring()
	print("--- status + AoE evals: %d PASS, %d FAIL ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _install_autoloads() -> void:
	var hs: Node = HitstopScript.new()
	hs.name = "Hitstop"
	root.add_child(hs)
	var sx: Node = SfxScript.new()
	sx.name = "Sfx"
	root.add_child(sx)

func _make_enemy(host: Node) -> Node:
	var e: Node = CombatantScript.new()
	host.add_child(e)
	e.add_to_group("enemy")
	e.cache_meshes()
	e.setup(100, 0.4, 1.4)
	return e

# Strip the arrow's auto-signal so only our explicit `_on_area_entered`
# call fires. All tests default-position arrows + hurtboxes at origin, so
# `await physics_frame` lets the arrow's Hitbox detect leftover enemies
# from prior tests — wrong target, manual call no-ops on `_spent=true`.
func _strip_arrow_autosignal(arrow: Node) -> void:
	var hb: Area3D = arrow.get_node_or_null("Hitbox") as Area3D
	if hb != null and hb.area_entered.is_connected(arrow._on_area_entered):
		hb.area_entered.disconnect(arrow._on_area_entered)

# ---- T10 — barrow brute spawns + frees its telegraph ring ----
func _t10_brute_ring_lifecycle() -> void:
	var host := Node3D.new()
	host.name = "T10Host"
	root.add_child(host)
	var brute := _make_enemy(host)
	brute.is_bruiser = true
	brute._telegraph_t = 0.7
	brute._spawn_brute_ring()
	var spawned: bool = brute._brute_ring != null and is_instance_valid(brute._brute_ring)
	brute._free_brute_ring()
	var cleared: bool = brute._brute_ring == null
	_check("T10", spawned and cleared,
		"brute ring spawns=%s and frees=%s" % [str(spawned), str(cleared)])

# ---- T9 — warden support heals a damaged adjacent ally ----
func _t9_warden_heals_ally() -> void:
	var host := Node3D.new()
	host.name = "T9Host"
	root.add_child(host)
	var warden := _make_enemy(host)
	warden.is_support = true
	warden.global_position = Vector3(50, 0, 50)   # clear of prior-test enemies at origin
	var ally := _make_enemy(host)
	ally.global_position = Vector3(51, 0, 50)      # within the 1.6m heal range
	ally.hp = 5
	warden._heal_t = 0.0
	var moved: bool = warden._support_tick(0.1)
	_check("T9", ally.hp == 7 and not moved,
		"warden heals adjacent ally 5→%d (moved=%s)" % [ally.hp, str(moved)])

# ---- T11 — CC-immune elites resist a 2nd root/snare in the window ----
# Data-driven (briarbound 4s, thornshelled 8s) — thornshelled used to be
# perma-rootable because the gate hardcoded "briarbound".
func _t11_cc_immune_elites() -> void:
	var host := Node3D.new()
	host.name = "T11Host"
	root.add_child(host)
	var thorn := _make_enemy(host)
	thorn.apply_elite("thornshelled")
	await physics_frame
	var t1 = thorn.apply_status("root", 3.0, 0, 1.0, 0.0)   # arms immunity
	var t2 = thorn.apply_status("root", 3.0, 0, 1.0, 0.0)   # within window → refused
	_check("T11a", t1 != null and t2 == null,
		"thornshelled: 1st root armed=%s, 2nd refused=%s" % [str(t1 != null), str(t2 == null)])
	# Regression — briarbound still immune.
	var bb := _make_enemy(host)
	bb.apply_elite("briarbound")
	await physics_frame
	var b1 = bb.apply_status("snared", 2.0, 0, 0.5, 0.0)
	var b2 = bb.apply_status("snared", 2.0, 0, 0.5, 0.0)
	_check("T11b", b1 != null and b2 == null,
		"briarbound: 1st armed=%s, 2nd refused=%s" % [str(b1 != null), str(b2 == null)])

# ---- T12 — C7 execute ring shows/hides as HP crosses 35%, gone on death ----
func _t12_execute_ring() -> void:
	var host := Node3D.new()
	host.name = "T12Host"
	root.add_child(host)
	var e := _make_enemy(host)        # setup(100) → hp_max 100
	await physics_frame
	# Explicit crit_chance 0 → deterministic damage (no crit roll).
	e.take_damage(10, Vector3.ZERO, 0.0, 0.0)   # hp 90, 0.90 > 0.35 → no ring
	_check("T12a no ring above threshold", e._execute_ring == null,
		"hp=%d ring=%s" % [int(e.hp), str(e._execute_ring != null)])
	e.take_damage(60, Vector3.ZERO, 0.0, 0.0)   # hp 30, 0.30 < 0.35 → ring
	_check("T12b ring below threshold",
		e._execute_ring != null and is_instance_valid(e._execute_ring),
		"hp=%d ring=%s" % [int(e.hp), str(e._execute_ring != null)])
	e.hp = 80                          # healed back above → ring clears
	e._update_execute_ring()
	_check("T12c ring clears when healed", e._execute_ring == null,
		"ring=%s" % str(e._execute_ring != null))
	e.take_damage(500, Vector3.ZERO, 0.0, 0.0)   # dies → frees the ring
	_check("T12d ring gone on death", e._execute_ring == null and bool(e.dead),
		"dead=%s ring=%s" % [str(e.dead), str(e._execute_ring != null)])

# ---- T8 — blightwalker elite blights nearby enemies on death ----
func _t8_blightwalker_on_death() -> void:
	var host := Node3D.new()
	host.name = "T8Host"
	root.add_child(host)
	var elite := _make_enemy(host)
	elite.apply_elite("blightwalker")
	var victim := _make_enemy(host)
	victim.global_position = elite.global_position + Vector3(1.0, 0.0, 0.0)
	await physics_frame
	elite._elite_on_death()
	_check("T8", victim.has_status("bleed"),
		"blightwalker death blights a nearby enemy=%s" % str(victim.has_status("bleed")))

# ---- T1 — burn ticks 6× ----
func _t1_burn_ticks() -> void:
	var host := Node3D.new()
	host.name = "T1Host"
	root.add_child(host)
	await physics_frame
	# Crit-off so the only damage source is the burn tick.
	CombatantScript.crit_enabled = false
	var e := _make_enemy(host)
	await physics_frame
	var hp_before: int = e.hp
	e.apply_status("burn", 3.0, 1, 1.0, 0.5)
	# Manually tick 6 fixed-interval frames. Avoids waiting 3 real seconds.
	for i in 6:
		e._tick_statuses(0.5)
	var hp_after: int = e.hp
	var lost: int = hp_before - hp_after
	_check("T1", lost == 6 and not e.has_status("burn"),
		"hp %d → %d (lost %d, expected 6); expired=%s" % [
			hp_before, hp_after, lost, str(not e.has_status("burn"))])
	CombatantScript.crit_enabled = true

# ---- T2 — PowerShot applies burn via arrow dispatch ----
func _t2_powershot_applies_burn() -> void:
	var host := Node3D.new()
	host.name = "T2Host"
	root.add_child(host)
	await physics_frame
	CombatantScript.crit_enabled = false   # deterministic
	var e := _make_enemy(host)
	await physics_frame
	var hurt: Area3D = e.get_node_or_null("Hurtbox") as Area3D
	var arrow: Node3D = ArrowScene.instantiate()
	host.add_child(arrow)
	_strip_arrow_autosignal(arrow)
	arrow.skill_type = "power"
	arrow.damage = 10
	arrow.crit_chance = 0.0
	arrow.crit_mult = 0.0
	# Spec 32b — on-hit status is now data on the arrow's `effects` array,
	# not a string match on `skill_type`. Mimic what PowerShot.fire would do.
	arrow.effects = [SkillEffect.burn(3.0, 1, 0.5)]
	await physics_frame
	# Simulate the area_entered callback directly (the test harness can't
	# trigger PhysicsServer overlap signals on a single frame).
	arrow._on_area_entered(hurt)
	_check("T2", e.has_status("burn"),
		"enemy has burn=%s" % str(e.has_status("burn")))
	CombatantScript.crit_enabled = true

# ---- T3 — MultiShot applies snared with slow_factor 0.5 ----
func _t3_multishot_applies_snared() -> void:
	var host := Node3D.new()
	host.name = "T3Host"
	root.add_child(host)
	await physics_frame
	CombatantScript.crit_enabled = false
	var e := _make_enemy(host)
	await physics_frame
	var hurt: Area3D = e.get_node_or_null("Hurtbox") as Area3D
	var arrow: Node3D = ArrowScene.instantiate()
	host.add_child(arrow)
	_strip_arrow_autosignal(arrow)
	arrow.skill_type = "multi"
	arrow.damage = 6
	arrow.crit_chance = 0.0
	arrow.crit_mult = 0.0
	# Spec 32b — on-hit status is now data on the arrow's `effects` array.
	arrow.effects = [SkillEffect.snared(1.5, 0.5)]
	await physics_frame
	arrow._on_area_entered(hurt)
	var s = e.get_status("snared")
	_check("T3",
		e.has_status("snared") and s != null and absf(s.slow_factor - 0.5) < 0.01,
		"snared=%s slow_factor=%s" % [
			str(e.has_status("snared")),
			str(s.slow_factor) if s != null else "(none)"])
	CombatantScript.crit_enabled = true

# ---- T4 — crit applies bleed; non-crit doesn't ----
func _t4_crit_applies_bleed() -> void:
	var host := Node3D.new()
	host.name = "T4Host"
	root.add_child(host)
	await physics_frame
	# Crit case: force a crit via crit_chance=1.0
	CombatantScript.crit_enabled = true
	var e_crit := _make_enemy(host)
	await physics_frame
	e_crit.take_damage(10, Vector3.FORWARD, 1.0, 0.0)
	var bled: bool = e_crit.has_status("bleed")
	# Non-crit case: crit_chance=0.0 with crit_enabled off — guaranteed normal
	CombatantScript.crit_enabled = false
	var e_nocrit := _make_enemy(host)
	await physics_frame
	e_nocrit.take_damage(10, Vector3.FORWARD, 0.0, 0.0)
	var no_bleed: bool = not e_nocrit.has_status("bleed")
	_check("T4", bled and no_bleed,
		"crit bled=%s; non-crit didn't bleed=%s" % [str(bled), str(no_bleed)])
	CombatantScript.crit_enabled = true

# ---- T5 — refresh rules: max time_left, max damage_per_tick ----
func _t5_status_refresh_rules() -> void:
	var host := Node3D.new()
	host.name = "T5Host"
	root.add_child(host)
	await physics_frame
	CombatantScript.crit_enabled = false
	var e := _make_enemy(host)
	await physics_frame
	e.apply_status("burn", 3.0, 1, 1.0, 0.5)
	# Tick once to drop time_left to 2.5.
	e._tick_statuses(0.5)
	# Re-apply with longer + stronger — should refresh to max of each.
	e.apply_status("burn", 5.0, 2, 1.0, 0.5)
	var s1 = e.get_status("burn")
	var refresh_ok: bool = absf(s1.time_left - 5.0) < 0.01 and s1.damage_per_tick == 2
	# Re-apply with shorter + weaker — should NOT shrink.
	e.apply_status("burn", 1.0, 1, 1.0, 0.5)
	var s2 = e.get_status("burn")
	var no_shrink: bool = absf(s2.time_left - 5.0) < 0.01 and s2.damage_per_tick == 2
	_check("T5", refresh_ok and no_shrink,
		"refreshed (tl=%.2f dpt=%d) and didn't shrink (tl=%.2f dpt=%d)" % [
			s1.time_left, s1.damage_per_tick, s2.time_left, s2.damage_per_tick])
	CombatantScript.crit_enabled = true

# ---- T6 — boss is immune to root + snared; burn at 50% duration ----
func _t6_boss_immunity() -> void:
	var host := Node3D.new()
	host.name = "T6Host"
	root.add_child(host)
	await physics_frame
	CombatantScript.crit_enabled = false
	var boss: Node = BossScript.new()
	host.add_child(boss)
	boss.add_to_group("enemy")
	boss.cache_meshes()
	boss.setup(200, 0.9, 3.0)
	await physics_frame
	# Lock-down attempts should bounce off.
	boss.apply_status("root", 2.0, 0, 1.0, 0.0)
	boss.apply_status("snared", 1.5, 0, 0.5, 0.0)
	var no_root: bool = not boss.has_status("root")
	var no_snare: bool = not boss.has_status("snared")
	# Damaging statuses land at HALF duration.
	boss.apply_status("burn", 3.0, 1, 1.0, 0.5)
	var burn = boss.get_status("burn")
	var burn_halved: bool = burn != null and absf(burn.time_left - 1.5) < 0.01
	_check("T6", no_root and no_snare and burn_halved,
		"no root=%s no snare=%s burn time_left=%.2f (expected 1.5)" % [
			str(no_root), str(no_snare),
			burn.time_left if burn != null else -1.0])
	CombatantScript.crit_enabled = true

# ---- T7 — query_circle returns only enemies inside the radius ----
func _t7_query_circle() -> void:
	var host := Node3D.new()
	host.name = "T7Host"
	root.add_child(host)
	await physics_frame
	# Three combatants — two inside radius 3.0 of origin, one outside.
	for pos in [Vector3.ZERO, Vector3(2.0, 0.0, 0.0), Vector3(5.0, 0.0, 0.0)]:
		var e: Node3D = CombatantScript.new()
		host.add_child(e)
		e.add_to_group("enemy_t7")     # separate group to isolate this test
		e.global_position = pos
	await physics_frame
	var found: Array = AoeQuery.query_circle(self, Vector3.ZERO, 3.0, "enemy_t7")
	_check("T7", found.size() == 2,
		"query_circle radius 3.0 from origin: %d hits (expected 2)" % found.size())
