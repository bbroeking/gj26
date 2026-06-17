extends SceneTree

# Spec 14 Section E — fluid-combat eval harness.
# Headless, deterministic. Drives the combat systems directly and prints
# PASS/FAIL per metric + a summary.
#   godot --headless --path godot --script res://test_combat.gd

const CombatantScript := preload("res://scripts/combatant.gd")
const ArrowScene := preload("res://scenes/Arrow.tscn")
const HitstopScript := preload("res://scripts/hitstop.gd")
const PlayerScene := preload("res://scenes/Player.tscn")
const BossScript := preload("res://scripts/boss.gd")

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

# Build a combatant under a host node, ready to be hit.
func _make_enemy(host: Node3D, hp: int) -> Node3D:
	var c: Node3D = CombatantScript.new()
	host.add_child(c)
	c.global_position = Vector3(0, 0, 0)
	c.cache_meshes()
	c.setup(hp, 0.5, 1.6)
	return c

# Build an arrow whose hitbox already overlaps the enemy's hurtbox.
func _make_arrow(host: Node3D, at: Vector3) -> Node3D:
	var a: Node3D = ArrowScene.instantiate()
	host.add_child(a)
	a.global_position = at
	return a

func _run() -> void:
	print("--- spec 14 combat evals ---")
	# Autoloads don't register under --script — stand up Hitstop at /root.
	var hs: Node = HitstopScript.new()
	hs.name = "Hitstop"
	root.add_child(hs)
	var host := Node3D.new()
	root.add_child(host)
	await physics_frame
	await physics_frame

	# Spec 26 — crits make damage non-deterministic; disable harness-wide so
	# the damage/phase evals stay exact. The E10 crit eval re-enables locally.
	CombatantScript.crit_enabled = false

	# ---- E2/E3/E5/E6/E8 — one arrow into one enemy ----
	var enemy := _make_enemy(host, 30)
	var hp0: int = enemy.hp
	var arrow := _make_arrow(host, Vector3(0, 0.8, 0))
	# let the hit resolve, then capture the damage number before it fades
	for i in 8:
		await physics_frame
	var dn_count := _count_class(host, "Label3D")
	# let the hitstop end and the knockback slide finish
	for i in 32:
		await physics_frame
	var hp1: int = enemy.hp if is_instance_valid(enemy) else hp0
	_check("E2", hp0 - hp1 == 6, "HP %d→%d (expected -6)" % [hp0, hp1])
	_check("E3", hp0 - hp1 == 6, "single hit — exactly one damage event")
	_check("E6", dn_count >= 1, "damage number spawned")
	# knockback — enemy should have shifted
	var moved := false
	if is_instance_valid(enemy):
		moved = (enemy as Node3D).global_position.length() > 0.05
	_check("E5", moved, "enemy knocked back %.3f m" % (
		(enemy as Node3D).global_position.length() if is_instance_valid(enemy) else 0.0))
	# arrow cleanup
	await physics_frame
	_check("E8", _count_node_name(host, "Arrow") == 0, "arrows remaining = %d" % _count_node_name(host, "Arrow"))

	# ---- E10 — crits land and scale damage (spec 26) ----
	CombatantScript.crit_enabled = true
	var ce := _make_enemy(host, 100000)
	var crit_seen := false
	for i in 80:
		var before: int = ce.hp
		ce.take_damage(6, Vector3(0, 0, 1))
		if before - ce.hp > 6:
			crit_seen = true
		await physics_frame
	CombatantScript.crit_enabled = false
	_check("E10", crit_seen, "a crit eventually rolled (>6 damage)")

	# ---- E4 — hitstop fired ----
	# Hitstop autoload sets Engine.time_scale low during the freeze window.
	# We can't observe the past freeze, so fire a fresh hit and sample.
	var e2 := _make_enemy(host, 30)
	_make_arrow(host, Vector3(0, 0.8, 0))
	await physics_frame
	await physics_frame
	var froze := Engine.time_scale < 0.5
	_check("E4", froze, "Engine.time_scale during hit = %.4f (expect <0.5)" % Engine.time_scale)
	# wait out the freeze, confirm it restores
	var waited := 0.0
	while Engine.time_scale < 0.5 and waited < 1.0:
		await physics_frame
		waited += 1.0 / 60.0
	_check("E4b", Engine.time_scale >= 0.99, "time_scale restored to %.2f" % Engine.time_scale)

	# ---- E7 — death ---- (far from the origin clutter so the arrow is
	# unambiguous about which hurtbox it hits)
	var weak := _make_enemy(host, 6)   # one arrow's damage
	weak.global_position = Vector3(40, 0, 0)
	await physics_frame
	_make_arrow(host, Vector3(40, 0.8, 0))
	var died := false
	for i in 90:
		await physics_frame
		if not is_instance_valid(weak) or weak.dead:
			died = true
			break
	_check("E7", died, "low-HP enemy entered death state")

	# ---- E9 — frame budget over a 10-arrow volley ----
	var volley_host := Node3D.new()
	root.add_child(volley_host)
	for i in 10:
		var en := _make_enemy(volley_host, 100)
		en.global_position = Vector3(i * 3.0, 0, 0)
		var ar := _make_arrow(volley_host, Vector3(i * 3.0, 0.8, 0))
	var t0 := Time.get_ticks_usec()
	for i in 30:
		await physics_frame
	var avg_ms := (Time.get_ticks_usec() - t0) / 30000.0
	# Threshold is 20 ms (~50 fps), not the spec's 16.6 — the physics tick
	# interval is itself 16.67 ms, so "< 16.6" is below the measurement
	# floor. 20 ms cleanly catches a real frame-time tank.
	_check("E9", avg_ms < 20.0, "avg physics frame %.2f ms over a 10-enemy volley" % avg_ms)

	# ---- Section F — enemy AI + player HP (spec 15) ----
	await _test_section_f()

	# ---- Section G — Hedgemother boss (spec 17) ----
	await _test_section_g()

	# ---- Section H — HitFeedback adapter (spec 32c) ----
	await _test_section_h()

	# ---- Section I — Elite modifier system (spec 32) ----
	await _test_section_i()

	print("--- evals: %d PASS, %d FAIL ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

# Spec 32 — Section I verifies the elite modifier system: apply_elite stats,
# Briarbound CC-immunity, Brambled death-nova.
func _test_section_i() -> void:
	var host := Node3D.new()
	host.name = "IHost"
	root.add_child(host)
	await physics_frame
	# I1 — apply_elite("brambled") bumps HP + scale + sets role/is_elite.
	var e1: Node3D = _make_enemy(host, 20)
	var base_hp_max: int = e1.hp_max
	var base_scale_x: float = e1.scale.x
	e1.apply_elite("brambled")
	var bumped_hp: bool = e1.hp_max == int(round(float(base_hp_max) * 1.25))
	var bumped_scale: bool = absf(e1.scale.x - base_scale_x * 1.25) < 0.001
	var role_elite: bool = String(e1.role) == "elite"
	var is_elite: bool = e1.is_elite
	_check("I1",
		bumped_hp and bumped_scale and role_elite and is_elite,
		"hp %d→%d (×1.25=%d), scale %.2f→%.2f, role=%s, is_elite=%s"
		% [base_hp_max, e1.hp_max, int(round(float(base_hp_max) * 1.25)),
		   base_scale_x, e1.scale.x, e1.role, str(is_elite)])

	# I2 — Briarbound CC-immune: first snare lands, second is rejected.
	var e2: Node3D = _make_enemy(host, 30)
	e2.apply_elite("briarbound")
	var s1 = e2.apply_status("snared", 1.5, 0, 0.5, 0.0)
	var first_landed: bool = e2.has_status("snared")
	# Clear the snared status to test the gate (not the dedupe).
	e2._statuses.erase("snared")
	var s2 = e2.apply_status("snared", 1.5, 0, 0.5, 0.0)
	var second_blocked: bool = (s2 == null) and not e2.has_status("snared")
	_check("I2",
		first_landed and second_blocked,
		"first snare landed=%s; second snare blocked=%s (within %ss window)"
		% [str(first_landed), str(second_blocked),
		   str(Elites.MODIFIERS["briarbound"]["cc_immune_window"])])

	# I3 — Brambled death-nova: kill the elite, nearby enemy gets bleed.
	var bramble_host := Node3D.new()
	bramble_host.name = "BrambleHost"
	root.add_child(bramble_host)
	await physics_frame
	var elite: Node3D = _make_enemy(bramble_host, 10)
	elite.global_position = Vector3(0, 0, 0)
	elite.add_to_group("enemy")
	elite.apply_elite("brambled")
	var neighbour: Node3D = _make_enemy(bramble_host, 10)
	neighbour.global_position = Vector3(1.5, 0, 0)  # 1.5m away — inside the 2.5m nova
	neighbour.add_to_group("enemy")
	var faraway: Node3D = _make_enemy(bramble_host, 10)
	faraway.global_position = Vector3(5.0, 0, 0)    # outside the nova
	faraway.add_to_group("enemy")
	await physics_frame
	# Kill the elite via take_damage (with enough damage to overshoot).
	elite.take_damage(999, Vector3.FORWARD)
	await physics_frame
	var neighbour_bleeds: bool = neighbour.has_status("bleed")
	var faraway_clean: bool = not faraway.has_status("bleed")
	_check("I3",
		neighbour_bleeds and faraway_clean,
		"neighbour (1.5m) bleeds=%s; faraway (5m) clean=%s"
		% [str(neighbour_bleeds), str(faraway_clean)])

# Spec 32c — H1 verifies HitFeedback.tick_pulse paints the mesh in the
# status-themed colour, and the gate against a live hit-flash works.
func _test_section_h() -> void:
	var host := Node3D.new()
	host.name = "HHost"
	root.add_child(host)
	await physics_frame
	var e: Node3D = _make_enemy(host, 50)
	# Give the enemy a fake mesh so apply_flash has something to override.
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	var bm := BoxMesh.new()
	bm.size = Vector3(0.5, 1.0, 0.5)
	mi.mesh = bm
	e.add_child(mi)
	e.cache_meshes()
	await physics_frame
	# Burn pulse — overrides the mesh material to the burn colour.
	HitFeedback.tick_pulse(e, "burn")
	var pulsed: bool = e._flash_t > 0.0
	# Pulse with an active hit-flash should be suppressed.
	e._flash_t = 0.0
	e._saved.clear()
	e.apply_flash(HitFeedback.FLASH_SEC, Color.WHITE)
	var pre_pulse_flash: float = e._flash_t
	HitFeedback.tick_pulse(e, "burn")
	# When a hit-flash is active, tick_pulse should NOT touch _flash_t.
	# But apply_flash with default color won't change material (already set).
	# The actual gate: _saved is non-empty when flash active, so the pulse
	# call returns early. _flash_t stays at FLASH_SEC.
	var suppressed: bool = absf(e._flash_t - pre_pulse_flash) < 0.001
	_check("H1", pulsed and suppressed,
		"burn pulse fired (flash_t > 0)=%s; pulse suppressed during hit-flash=%s"
		% [str(pulsed), str(suppressed)])

func _make_boss(host: Node3D, hp: int) -> Node3D:
	var b: Node3D = BossScript.new()
	host.add_child(b)
	b.global_position = Vector3.ZERO
	b.cache_meshes()
	b.setup(hp, 0.9, 3.0)
	return b

func _test_section_g() -> void:
	# Full isolation — free every prior section's host (and its leftover
	# enemies/players) so only the boss + its target exist. The Hitstop
	# autoload is a plain Node, not Node3D, so it survives.
	for c in root.get_children():
		if c is Node3D:
			c.queue_free()
	await physics_frame
	await physics_frame
	var ghost := Node3D.new()
	root.add_child(ghost)

	# G1/G2 — HP-gated phases. A far stand-in player keeps the boss un-aggroed
	# while still letting _tick_ai run its phase computation.
	var farp := Node3D.new()
	farp.add_to_group("player")
	ghost.add_child(farp)
	farp.global_position = Vector3(80, 0, 0)
	await physics_frame
	var boss := _make_boss(ghost, 100)
	boss.take_damage(45, Vector3(1, 0, 0))     # 100 → 55 HP (55%)
	for i in 6:
		await physics_frame
	_check("G1", boss._phase == 2, "phase at 55%% HP = %d (expect 2)" % boss._phase)
	boss.take_damage(30, Vector3(1, 0, 0))     # 55 → 25 HP (25%)
	for i in 6:
		await physics_frame
	_check("G2", boss._phase == 3, "phase at 25%% HP = %d (expect 3)" % boss._phase)

	# G3 — death.
	boss.take_damage(9999, Vector3(1, 0, 0))
	await physics_frame
	_check("G3", boss.dead, "boss entered death state at 0 HP")
	boss.queue_free()
	farp.queue_free()
	await physics_frame

	# G4 — a telegraphed attack damages a nearby player.
	var gp: Node3D = PlayerScene.instantiate()
	ghost.add_child(gp)
	gp.global_position = Vector3(4, 0, 0)
	if gp.has_method("set_spawn"):
		gp.set_spawn(Vector3(4, 0, 0))
	await physics_frame
	var boss2 := _make_boss(ghost, 300)
	var hp0: int = gp.hp
	var hit := false
	for i in 260:
		await physics_frame
		if gp.hp < hp0:
			hit = true
			break
	# Only the boss exists now — any damage is the boss's (BOSS_DAMAGE 8).
	_check("G4", hit and hp0 - gp.hp >= 8,
		"boss telegraphed attack hit the player (HP %d→%d)" % [hp0, gp.hp])

func _test_section_f() -> void:
	var host := Node3D.new()
	root.add_child(host)
	await physics_frame

	# Player for the AI to chase — 6 m out (inside AGGRO_RADIUS 7).
	var player: Node3D = PlayerScene.instantiate()
	host.add_child(player)
	player.global_position = Vector3(6, 0, 0)
	if player.has_method("set_spawn"):
		player.set_spawn(Vector3(6, 0, 0))
	await physics_frame
	await physics_frame

	# F1 — aggro: enemy at origin wakes when the player is within range.
	var e := _make_enemy(host, 100)
	e.global_position = Vector3(0, 0, 0)
	for i in 4:
		await physics_frame
	# State enum: IDLE=0, CHASE=1, ATTACK=2.
	_check("F1", e._state != 0, "enemy left IDLE (state=%d)" % e._state)

	# F1b — chain aggro: a fresh lead enemy wakes (player in range) and alerts a
	# grouped IDLE peer 8 m away (out of its OWN aggro range of the player, so it
	# can only wake via the chain); a peer 20 m away stays asleep.
	var lead := _make_enemy(host, 100)
	lead.global_position = Vector3(0, 0, 0)
	var near := _make_enemy(host, 100)
	near.global_position = Vector3(0, 0, -8)
	near.add_to_group("enemy")
	var far_peer := _make_enemy(host, 100)
	far_peer.global_position = Vector3(0, 0, -20)
	far_peer.add_to_group("enemy")
	for i in 5:
		await physics_frame
	_check("F1b-chain-wakes-near", near._state != 0,
		"near peer chained to CHASE (state=%d)" % near._state)
	_check("F1b-far-stays-idle", far_peer._state == 0,
		"far peer still IDLE (state=%d)" % far_peer._state)

	# F2 — chase: enemy closes distance. Measured over a short 15-frame
	# window so the enemy is still chasing — not yet in attack range
	# (where it stops + knocks the player back, confounding the metric).
	var d_start := e.global_position.distance_to(player.global_position)
	for i in 15:
		await physics_frame
	var d_end := e.global_position.distance_to(player.global_position)
	_check("F2", d_end < d_start - 0.2, "enemy closed %.2f→%.2f m" % [d_start, d_end])

	# F3 — enemy attack damages the player. By now the enemy has reached
	# attack range; wait out a telegraph + cooldown and watch HP fall.
	var hp_before: int = player.hp
	for i in 150:
		await physics_frame
		if player.hp < hp_before:
			break
	_check("F3", player.hp < hp_before, "player HP %d→%d (enemy hit landed)" % [hp_before, player.hp])

	# F4 — i-frames: a second hit inside the window is ignored.
	var weak: Node3D = PlayerScene.instantiate()
	host.add_child(weak)
	weak.global_position = Vector3(40, 0, 0)
	await physics_frame
	var h0: int = weak.hp
	weak.take_damage(5, Vector3(1, 0, 0))
	weak.take_damage(5, Vector3(1, 0, 0))   # same frame — should be i-framed
	_check("F4", h0 - weak.hp == 5, "two rapid hits dealt %d (expect 5)" % (h0 - weak.hp))

	# F5 — death: HP to 0 → dead state.
	weak.take_damage(999, Vector3(1, 0, 0))
	# i-frames may swallow it — wait them out then hit again if still alive.
	await physics_frame
	if not weak.dead and weak.hp > 0:
		await create_timer(0.7).timeout
		weak.take_damage(999, Vector3(1, 0, 0))
	await physics_frame
	_check("F5", weak.dead, "player entered death state at 0 HP")

	# F6 — respawn: after DEATH_PAUSE, HP restored + back at spawn.
	await create_timer(1.6).timeout
	_check("F6", not weak.dead and weak.hp == weak.hp_max,
		"respawned: dead=%s hp=%d/%d" % [str(weak.dead), weak.hp, weak.hp_max])

	# F7 — pathfinding: an L-shaped navmesh forces a route around the corner.
	# Free the F1-F6 players first — the chaser finds its target via the
	# "player" group, and those PlayerScene instances fell off the (no-floor)
	# test world. F7 uses a plain non-falling Node3D stand-in instead.
	if is_instance_valid(player):
		player.queue_free()
	if is_instance_valid(weak):
		weak.queue_free()
	await physics_frame
	var nhost := Node3D.new()
	root.add_child(nhost)
	# L: row (0..4, 0) + column (4, 1..4)
	var tiles: Array = []
	for x in range(0, 5):
		tiles.append(Vector2i(x, 0))
	for z in range(1, 5):
		tiles.append(Vector2i(4, z))
	_build_test_navmesh(nhost, tiles)
	for i in 6:
		await physics_frame
	var navplayer := Node3D.new()
	navplayer.add_to_group("player")
	nhost.add_child(navplayer)
	navplayer.global_position = Vector3(4.5, 0, 4.5)   # far arm of the L
	await physics_frame
	var chaser := _make_enemy(nhost, 200)
	chaser.global_position = Vector3(0.5, 0, 0.5)        # near arm
	for i in 20:
		await physics_frame
	var straight := chaser.global_position.distance_to(navplayer.global_position)
	var path_len := 0.0
	if chaser._agent != null:
		var path: PackedVector3Array = chaser._agent.get_current_navigation_path()
		for i in range(1, path.size()):
			path_len += path[i].distance_to(path[i - 1])
	# A routed path bends around the corner — longer than the straight line.
	_check("F7", path_len > straight * 1.15,
		"nav path %.1f m vs straight %.1f m (routes around the corner)" % [path_len, straight])

func _build_test_navmesh(host: Node, tiles: Array) -> void:
	var verts := PackedVector3Array()
	var index := {}
	var nav := NavigationMesh.new()
	var polys: Array = []
	for t in tiles:
		var poly := PackedInt32Array()
		for c in [Vector2i(t.x, t.y), Vector2i(t.x, t.y + 1),
				Vector2i(t.x + 1, t.y + 1), Vector2i(t.x + 1, t.y)]:
			if not index.has(c):
				index[c] = verts.size()
				verts.append(Vector3(c.x, 0.05, c.y))
			poly.append(index[c])
		polys.append(poly)
	nav.vertices = verts
	for p in polys:
		nav.add_polygon(p)
	var region := NavigationRegion3D.new()
	region.navigation_mesh = nav
	host.add_child(region)

func _count_class(node: Node, cls: String) -> int:
	var n := 0
	if node.is_class(cls):
		n += 1
	for c in node.get_children():
		n += _count_class(c, cls)
	return n

func _count_node_name(node: Node, substr: String) -> int:
	var n := 0
	if String(node.name).contains(substr):
		n += 1
	for c in node.get_children():
		n += _count_node_name(c, substr)
	return n
