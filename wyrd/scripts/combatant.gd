extends CharacterBody3D

# Spec 14/15 — an enemy. Holds HP + a hurtbox (takes arrow hits, spec 14),
# AND a 3-state AI that chases and attacks the player (spec 15).
# layout_loader builds it via CombatantScript.new().

const DamageNumberScene := preload("res://scenes/DamageNumber.tscn")
const AnimDriverScript := preload("res://scripts/anim_driver.gd")
const HitSparkScript := preload("res://scripts/hit_spark.gd")
const Drops = preload("res://data/drops.gd")                     # spec 27b
const StatusEffectScript := preload("res://scripts/status_effect.gd")  # spec 31
const Elites = preload("res://data/elites.gd")                   # spec 32
const EnemyProjectile = preload("res://scripts/enemy_projectile.gd")  # Phase 3
const TEX_SOFT_CIRCLE := preload("res://assets/vfx/soft_circle.png")  # spec-34
const TEX_EMBER := preload("res://assets/vfx/ember.png")              # spec-34

# ---- hit-feedback tunables (spec 14) ----
const HITSTOP_SEC := 0.09
const FLASH_SEC := 0.12
const KNOCKBACK := 0.6
const KNOCKBACK_DECAY := 12.0
const REACT_SEC := 0.18
const DEATH_SEC := 0.4
const LAYER_HURTBOX := 8

# ---- crit tunables (spec 26) ----
const CRIT_CHANCE := 0.20         # incl. super — a roll under this crits
const SUPER_CRIT_CHANCE := 0.04   # a roll under this is a super-crit (×3)
static var crit_enabled := true   # test seam — evals toggle this off

# ---- AI tunables (spec 15) ----
const AGGRO_RADIUS := 7.0
# B6 wave 2 — fog_of_hedge scales perception per spawn.
var aggro_radius := AGGRO_RADIUS
const LEASH_RADIUS := 11.0          # past this, give up and idle
const ATTACK_RANGE := 1.8
const RANGED_RANGE := 8.0            # Phase 3 — ranged enemies fire from afar
const RANGED_MIN := 4.0              # ...but keep this standoff — point-blank orbs are undodgeable
const ENEMY_DAMAGE := 5
const ATTACK_COOLDOWN := 1.5
const TELEGRAPH_SEC := 0.35
const MOVE_SPEED := 1.8        # dialled down with the player (spec 23 tuning)
const CHASE_REPATH := 0.25     # re-target the nav path 4×/sec

signal died

enum State { IDLE, CHASE, ATTACK }

var hp := 10
var hp_max := 10
var dead := false
# B3 — per-kind stats. layout_loader sets these from ENEMY_KINDS at spawn;
# the defaults keep dev spawns / old saves on the spec-15 values.
var damage := ENEMY_DAMAGE
var move_speed := MOVE_SPEED
var attack_cooldown := ATTACK_COOLDOWN
# Spec 27b — drop context. layout_loader sets these per-spawn.
var role := "combat"
var depth := 0
# Spec 32 — elite state. is_elite=true gates the modifier dispatch in _die +
# _tick_ai; modifier is a key into Elites.MODIFIERS. _move_mult /
# _attack_speed_mult default to 1.0 (no-op for non-elites; Swift bumps).
# _cc_immune_until is a Time.get_ticks_msec() / 1000.0 timestamp gating
# Briarbound's root/snared immunity.
# B6 — bursting chart affix: this corpse pops on death (2m, 6 dmg to
# kin; Volatile also hits the player).
var burst_on_death := false
# Phase 3 — ranged attack (a ghost lobs slow spectral orbs you strafe around).
var is_ranged := false
var proj_speed := 9.0
var proj_damage := 5
var _aim_dir := Vector3.FORWARD
var _ranged_tele: Node3D = null
var burst_hits_player := false
var is_elite: bool = false
var modifier: String = ""
var is_support := false        # warden archetype — follows + heals allies, no attack
var _heal_t := 0.0
const HEAL_INTERVAL := 4.0
const HEAL_AMOUNT := 2
var is_bruiser := false         # barrow brute — telegraphed AoE floor-ring strike
var _brute_ring: MeshInstance3D = null
const BRUTE_TELEGRAPH := 0.7    # longer tell — "get out of the circle"
const BRUTE_RING_MULT := 1.6    # AoE radius = ATTACK_RANGE * this
var _move_mult: float = 1.0
var _attack_speed_mult: float = 1.0
var _cc_immune_until: float = 0.0
var _elite_ring: GPUParticles3D = null
# Spec 31 — active status effects on this combatant, keyed by kind string.
# `_root_t` from spec 30 lives in here now (`_statuses["root"]`). Each value
# is a StatusEffect RefCounted; ticking + visual cleanup happens in
# `_tick_statuses` / `_die`. The spec 30 root-disc visual is owned by the
# StatusEffect itself.
var _statuses: Dictionary = {}
# Phase 3 (co-op) — cosmetic status visuals mirrored onto a PUPPET foe from the
# host's snapshot (kind -> visual Node3D). The host owns the real DoT/slow.
var _net_status_vis: Dictionary = {}

# C7 — Mercy Shot execute cue: an amber ring under a foe low enough that Mercy
# Shot will finish it (×3 dmg). Mirrors mercy_shot.execute_below.
const EXECUTE_RING_BELOW := 0.35
var _execute_ring: MeshInstance3D = null

# Spec 31 — status visual + apply-text palettes.
const STATUS_COLOR := {
	"burn":   Color(1.00, 0.55, 0.18),
	"bleed":  Color(0.85, 0.20, 0.20),
	"snared": Color(0.45, 0.65, 0.30),
	"root":   Color(0.30, 0.65, 0.25),
	"marked": Color(1.00, 0.82, 0.30),
}
const APPLY_TEXT := {
	"burn":   "singed!",
	"bleed":  "bleeding!",
	"snared": "snared!",
	"root":   "rooted!",
	"marked": "marked!",
}
# B5-wave2 — Hunter's Mark: a marked thing takes +30% from every hit.
const MARKED_MULT := 1.3
# Bleed-on-crit damage fraction — total bleed damage ≈ 25% of crit damage,
# spread across 4 ticks at 1 s = ~6.25% per tick.
const BLEED_TICK_FRACTION := 0.0625
const STATUS_PARTICLE_CAP := 2          # max concurrent GPUParticles3D per enemy

var _state: State = State.IDLE
var _player: Node3D
var _proc_anim                     # optional procedural animator (spec 21 rat)
var _agent: NavigationAgent3D
var _repath_t := 0.0
var _spawn_pos := Vector3.ZERO   # IDLE wander anchor (set lazily on first tick)
var _wander_t := 0.0
const WANDER_REPATH := 2.5
var _attack_cd := 0.0
var _telegraph_t := 0.0
var _did_hit := false

var _knockback := Vector3.ZERO
var _flash_t := 0.0
var _react_t := 0.0
var _meshes: Array = []
var _saved: Dictionary = {}
var _flash_mat: StandardMaterial3D
var _base_scale := Vector3.ONE

func setup(max_hp: int, hurt_radius: float, hurt_height: float) -> void:
	hp_max = max_hp
	hp = max_hp
	_base_scale = scale

	var hurt := Area3D.new()
	hurt.name = "Hurtbox"
	hurt.collision_layer = LAYER_HURTBOX
	hurt.collision_mask = 0
	hurt.monitorable = true
	hurt.monitoring = false
	var shape := CapsuleShape3D.new()
	shape.radius = hurt_radius
	shape.height = hurt_height
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0.0, hurt_height * 0.5, 0.0)
	hurt.add_child(col)
	add_child(hurt)
	hurt.set_meta("combatant", self)

	# Navigation agent — chase routes around walls (spec 19).
	var agent := NavigationAgent3D.new()
	agent.name = "NavAgent"
	agent.radius = hurt_radius
	agent.avoidance_enabled = false
	agent.path_desired_distance = 0.5
	agent.target_desired_distance = 0.5
	add_child(agent)
	_agent = agent

	_flash_mat = StandardMaterial3D.new()
	_flash_mat.albedo_color = Color(1, 1, 1)
	_flash_mat.emission_enabled = true
	_flash_mat.emission = Color(1, 1, 1)
	_flash_mat.emission_energy_multiplier = 2.0

func cache_meshes() -> void:
	_meshes.clear()
	_collect(self)

func _collect(n: Node) -> void:
	if n is MeshInstance3D:
		_meshes.append(n)
	for c in n.get_children():
		_collect(c)

# ---- taking a hit (spec 14) ----
func take_damage(amount: int, from_dir: Vector3,
		crit_chance: float = -1.0, crit_mult_bonus: float = -1.0) -> void:
	if dead:
		return
	# Phase B — puppets carry no truth: a guest's local arrow striking a
	# mirror body is cosmetic; the host's replay deals the real damage and
	# the hp lands back via snapshot.
	if net_puppet:
		HitFeedback.play_hit(self, "normal", from_dir)
		return
	# Crit roll (spec 26/27e) — the attacker can override crit chance + the
	# bonus added on top of the base crit/super-crit multipliers. -1 = use
	# this combatant's defaults (backward-compatible — old call sites unchanged).
	var cc: float = crit_chance if crit_chance >= 0.0 else CRIT_CHANCE
	var bonus: float = crit_mult_bonus if crit_mult_bonus >= 0.0 else 0.0
	var tier := "normal"
	if crit_enabled:
		var roll := randf()
		if roll < SUPER_CRIT_CHANCE:
			tier = "super"
		elif roll < cc:
			tier = "crit"
	var dmg: int = amount
	if tier == "crit":
		dmg = int(round(float(amount) * (2.0 + bonus)))
	elif tier == "super":
		dmg = int(round(float(amount) * (3.0 + bonus)))
	# B5-wave2 — Hunter's Mark amplifies everything that lands while it holds.
	if has_status("marked"):
		dmg = int(round(float(dmg) * MARKED_MULT))

	# Spec 31 — bleed-on-crit. Only enemy combatants bleed (the player has
	# `take_damage` too, but isn't in the enemy group — keeps the friendly-fire
	# / self-bleed surface out of v1). Bleeds tick ~25% of crit dmg over 4s.
	if (tier == "crit" or tier == "super") and is_in_group("enemy"):
		var bleed_dpt := maxi(1, int(round(float(dmg) * BLEED_TICK_FRACTION)))
		apply_status("bleed", 4.0, bleed_dpt, 1.0, 1.0)

	hp -= dmg
	_spawn_damage_number(dmg, tier)
	# Co-op (C-2) — guests' puppet enemies never run take_damage, so they'd
	# see no damage popups. The host broadcasts the number to them.
	var netd := get_node_or_null("/root/NetGame")
	if netd != null and bool(netd.active) and netd.is_host():
		netd.dmg_event(global_position + Vector3(0.0, 2.0, 0.0), dmg, tier)
	_react_t = REACT_SEC
	# A hit also wakes an idle enemy.
	if _state == State.IDLE:
		_state = State.CHASE
	# Spec 32c — all 6 feedback channels (flash, knockback, hitstop, spark,
	# shake, SFX) fire through one seam now.
	HitFeedback.play_hit(self, tier, from_dir)
	if hp <= 0:
		_die()
	else:
		_update_execute_ring()

# C7 — show/hide the amber execute ring as HP crosses EXECUTE_RING_BELOW. A
# child of the body so it follows; driven from take_damage (host) and
# net_apply_state (guests), freed in _clear_all_statuses on death.
func _update_execute_ring() -> void:
	var low: bool = not dead and hp_max > 0 \
		and float(hp) / float(hp_max) < EXECUTE_RING_BELOW
	if low and _execute_ring == null:
		var mi := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.45
		torus.outer_radius = 0.58
		mi.mesh = torus
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.95, 0.72, 0.22, 0.7)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.7, 0.2)
		mat.emission_energy_multiplier = 1.4
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mi.material_override = mat
		mi.position = Vector3(0.0, 0.12, 0.0)
		add_child(mi)
		_execute_ring = mi
		var tw := mi.create_tween().set_loops()
		tw.tween_property(mat, "emission_energy_multiplier", 2.6, 0.5).set_trans(Tween.TRANS_SINE)
		tw.tween_property(mat, "emission_energy_multiplier", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
	elif not low and _execute_ring != null:
		if is_instance_valid(_execute_ring):
			_execute_ring.queue_free()
		_execute_ring = null

# Phase B — co-op helpers. A puppet is a guest-side mirror of a host
# enemy: identical (seed-built) body, no AI/physics of its own — it lerps
# to the host's snapshots and dies when they say so.
var net_puppet := false
var net_target_pos := Vector3.ZERO
var net_target_hp := -1
var last_hit_peer := 0   # who landed the latest hit (kill attribution)

func _nearest_player() -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for p in get_tree().get_nodes_in_group("player"):
		# `== true` is null-safe: a "player"-group stand-in without a `dead`
		# property returns null from get(), and bool(null) is a hard error.
		if not p is Node3D or (p as Node).get("dead") == true:
			continue
		var d := global_position.distance_squared_to((p as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = p
	return best

func net_apply_state(pos: Vector3, p_hp: int, flags: Array = []) -> void:
	net_target_pos = pos
	net_target_hp = p_hp
	if p_hp < hp:
		HitFeedback.play_hit(self, "normal", Vector3.ZERO)
		# Phase C — guests see the numbers their (and others') hits land.
		_spawn_damage_number(hp - p_hp, "normal")
	hp = p_hp
	if hp <= 0 and not dead:
		_die()			# _die clears every visual, including _net_status_vis
	elif not dead:
		# Phase 3 — mirror the host's active statuses (cosmetic only).
		_net_apply_status_vis(flags)
		_update_execute_ring()   # C7 — guests see the execute cue too

func _physics_process(delta: float) -> void:
	if dead:
		return
	if net_puppet:
		# Mirror body: chase the host's snapshot, nothing else.
		if net_target_pos != Vector3.ZERO:
			global_position = global_position.lerp(net_target_pos,
				minf(1.0, delta * 8.0))
		return
	# Spec 31 — status framework tick (replaces the spec 30 root-only branch).
	_tick_statuses(delta)
	_tick_feedback(delta)
	_tick_ai(delta)
	# Knockback rides on top of the AI velocity.
	velocity.x += _knockback.x
	velocity.z += _knockback.z
	velocity.y = 0.0
	move_and_slide()
	_knockback = _knockback.lerp(Vector3.ZERO, KNOCKBACK_DECAY * delta)

# ---- AI state machine (spec 15) ----
func _tick_ai(delta: float) -> void:
	# Phase B — chase the NEAREST living player (co-op: never cache one
	# body forever; offline: the loop returns the only player).
	_player = _nearest_player()
	if _player == null:
		velocity = Vector3.ZERO
		return
	# Spec 30/31 — rooted enemies don't chase or attack. Knockback still
	# applies (it's added after this tick) so the player can shoot them around.
	if has_status("root"):
		velocity.x = 0.0
		velocity.z = 0.0
		# Rooting a ranged caster mid-windup interrupts the cast — free the
		# aim-line and reset, so rooting a charging ghost is rewarded.
		if _state == State.ATTACK and _ranged_tele != null and is_instance_valid(_ranged_tele):
			_ranged_tele.queue_free()
			_ranged_tele = null
			_did_hit = false
			_state = State.CHASE
		if _state == State.ATTACK and _brute_ring != null:
			_free_brute_ring()       # rooting a brute mid-windup cancels the strike
			_did_hit = false
			_state = State.CHASE
		return
	var to := _player.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	_attack_cd = max(0.0, _attack_cd - delta)
	var moving := false

	match _state:
		State.IDLE:
			if _spawn_pos == Vector3.ZERO:
				_spawn_pos = global_position
			if dist < aggro_radius:
				velocity.x = 0.0
				velocity.z = 0.0
				_state = State.CHASE
				_alert_nearby(aggro_radius * 1.4)   # wake the pack
			else:
				# Shuffle around the spawn cell so nothing stands frozen. Slow,
				# bounded (±2 m), nav-guarded (a no-op with no baked navmesh).
				_wander_t -= delta
				if _wander_t <= 0.0:
					_wander_t = WANDER_REPATH
					if _agent != null:
						_agent.target_position = _spawn_pos + Vector3(
							randf_range(-2.0, 2.0), 0.0, randf_range(-2.0, 2.0))
				if _agent != null and not _agent.is_navigation_finished():
					var nd: Vector3 = _agent.get_next_path_position() - global_position
					nd.y = 0.0
					if nd.length() > 0.3:
						var sw := move_speed * 0.4
						velocity.x = nd.normalized().x * sw
						velocity.z = nd.normalized().z * sw
						_face(nd.normalized())
						moving = true
					else:
						velocity.x = 0.0
						velocity.z = 0.0
				else:
					velocity.x = 0.0
					velocity.z = 0.0
		State.CHASE:
			if dist > LEASH_RADIUS:
				_state = State.IDLE
			elif is_support:
				moving = _support_tick(delta)   # warden heals, never attacks
			elif is_ranged and dist < RANGED_MIN:
				# Ranged kiter — keep a fair standoff so shots stay dodgeable
				# (never a point-blank orb the player can't outrun). Back off,
				# still facing, so it can fire once it has the distance.
				var away := -to.normalized()
				velocity.x = away.x * move_speed
				velocity.z = away.z * move_speed
				_face(to.normalized())
				moving = true
			elif dist <= (RANGED_RANGE if is_ranged else ATTACK_RANGE) and _attack_cd <= 0.0:
				_state = State.ATTACK
				# Phase 2 — telegraph scales with the attack's weight so heavy,
				# slow hitters tell longer (fairer to read). Drives the damage
				# timing, the wind-back animation, and (ranged) the aim-line tell.
				_telegraph_t = clampf(attack_cooldown * 0.3, 0.32, 0.6)
				if is_ranged:
					_telegraph_t = maxf(_telegraph_t, 0.6)   # ranged reads longer
				if is_bruiser:
					_telegraph_t = BRUTE_TELEGRAPH           # heavy AoE tells longest
				_did_hit = false
				velocity.x = 0.0
				velocity.z = 0.0
				_aim_dir = to.normalized()                   # locked aim for the shot
				if _proc_anim != null and _proc_anim.has_method("attack"):
					_proc_anim.attack(_telegraph_t, _aim_dir)
				if is_ranged:
					_spawn_ranged_telegraph(_aim_dir, dist)
				if is_bruiser:
					_spawn_brute_ring()
			else:
				_chase_move(delta)
				moving = true
		State.ATTACK:
			velocity.x = 0.0
			velocity.z = 0.0
			_telegraph_t -= delta
			if _telegraph_t <= 0.0 and not _did_hit:
				_did_hit = true
				if _proc_anim != null and _proc_anim.has_method("strike"):
					_proc_anim.strike()    # Phase 2 — the lunge / throw
				if is_ranged:
					_fire_projectile(_aim_dir)
				elif _player.has_method("take_damage"):
					# Bruiser lands anyone still inside the (bigger) ring; others
					# get the normal melee reach.
					var hit_range: float = (ATTACK_RANGE * BRUTE_RING_MULT) \
						if is_bruiser else (ATTACK_RANGE * 1.4)
					if dist <= hit_range:
						_player.take_damage(damage, -to.normalized())
				if is_bruiser:
					_free_brute_ring()
				# Spec 32 — elite on_attack dispatch (fires for melee + ranged).
				if is_elite and modifier != "":
					_elite_on_attack()
				# Spec 32 — Swift elites attack faster.
				_attack_cd = attack_cooldown / _attack_speed_mult
				_state = State.CHASE

	AnimDriverScript.update(self, moving)
	# Procedural animator (the rat — spec 21) runs alongside the clip driver.
	if _proc_anim != null:
		_proc_anim.update(delta, moving)

# Chain aggro — waking one wakes the pack. When this enemy first spots the
# player, nearby IDLE peers also give chase, so a room threatens as a group.
# Only IDLE peers flip (CHASE/ATTACK are already awake); dead bodies and net
# puppets are skipped (the host drives puppet state in co-op). Runs host-side
# only — _physics_process returns early for net puppets, so this never fires
# on a guest.
func _alert_nearby(radius: float) -> void:
	for peer in get_tree().get_nodes_in_group("enemy"):
		if peer == self or not is_instance_valid(peer):
			continue
		if peer.get("dead") == true or peer.get("net_puppet") == true:
			continue   # null-safe (bool(null) is a hard error)
		if int(peer.get("_state")) != State.IDLE:
			continue
		if global_position.distance_to((peer as Node3D).global_position) <= radius:
			peer.set("_state", State.CHASE)

# Warden support tick — follow the nearest living NON-support ally and heal it
# on a timer when adjacent. Returns whether it moved (for the locomotion anim).
func _support_tick(delta: float) -> bool:
	_heal_t = maxf(0.0, _heal_t - delta)
	var ally := _nearest_ally(6.0)
	if ally == null:
		velocity.x = 0.0
		velocity.z = 0.0
		return false
	var ato: Vector3 = (ally as Node3D).global_position - global_position
	ato.y = 0.0
	if ato.length() <= 1.6:
		velocity.x = 0.0
		velocity.z = 0.0
		if ato.length() > 0.01:
			_face(ato.normalized())
		if _heal_t <= 0.0:
			_heal_t = HEAL_INTERVAL
			ally.call("_heal_direct", HEAL_AMOUNT)
		return false
	var step := ato.normalized()
	velocity.x = step.x * move_speed
	velocity.z = step.z * move_speed
	_face(step)
	return true

# Nearest living, non-support enemy within `radius` (so wardens don't trail
# each other). Skips dead bodies and net puppets.
func _nearest_ally(radius: float) -> Node3D:
	var best: Node3D = null
	var best_d := radius * radius
	for peer in get_tree().get_nodes_in_group("enemy"):
		if peer == self or not is_instance_valid(peer):
			continue
		if peer.get("dead") == true or peer.get("is_support") == true \
				or peer.get("net_puppet") == true:
			continue
		var d := global_position.distance_squared_to((peer as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = peer
	return best

# Heal `amount`, clamped to hp_max. Floats a small green "+N" (reuses the
# elite-label pipe). Public so a warden can call it on an ally.
func _heal_direct(amount: int) -> void:
	if dead or amount <= 0:
		return
	var before := hp
	hp = mini(hp + amount, hp_max)
	if hp > before:
		_spawn_elite_label("+%d" % (hp - before), Color(0.40, 0.85, 0.45))

# Barrow Brute — an expanding orange floor-ring that grows to full over the
# telegraph, telling the player to step out of the AoE before the strike lands.
func _spawn_brute_ring() -> void:
	_free_brute_ring()
	var disc := MeshInstance3D.new()
	disc.name = "BruteRing"
	var dm := CylinderMesh.new()
	var r := ATTACK_RANGE * BRUTE_RING_MULT
	dm.top_radius = r
	dm.bottom_radius = r
	dm.height = 0.06
	disc.mesh = dm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.35, 0.10, 0.5)
	mat.emission_enabled = true
	mat.emission = Color(0.95, 0.35, 0.10)
	mat.emission_energy_multiplier = 1.8
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disc.material_override = mat
	disc.position = Vector3(0.0, 0.05, 0.0)
	disc.scale = Vector3(0.05, 1.0, 0.05)
	add_child(disc)
	_brute_ring = disc
	var tw := disc.create_tween()
	tw.tween_property(disc, "scale", Vector3(1.0, 1.0, 1.0), maxf(_telegraph_t, 0.1))

func _free_brute_ring() -> void:
	if _brute_ring != null and is_instance_valid(_brute_ring):
		_brute_ring.queue_free()
	_brute_ring = null

# Move toward the player along the nav path — straight-line fallback when
# no path is available (no navmesh, not yet computed, off-mesh). Reused by
# boss.gd (spec 17).
func _chase_move(delta: float) -> void:
	if _player == null:
		return
	var to := _player.global_position - global_position
	to.y = 0.0
	_repath_t -= delta
	if _repath_t <= 0.0:
		_repath_t = CHASE_REPATH
		if _agent != null:
			_agent.target_position = _player.global_position
	var step := to.normalized()
	if _agent != null:
		var nd := _agent.get_next_path_position() - global_position
		nd.y = 0.0
		if nd.length() > 0.15:
			step = nd.normalized()
	# Spec 31/32 — soft slows multiply (cap 0.25×); Swift elites speed up by
	# `_move_mult`. Both compose: `MOVE_SPEED * slow * _move_mult`.
	var slow := _slow_product()
	velocity.x = step.x * move_speed * slow * _move_mult
	velocity.z = step.z * move_speed * slow * _move_mult
	_face(step)

# Phase 3 — ranged: a floor aim-line tell during the windup, freed on the shot.
func _spawn_ranged_telegraph(dir: Vector3, length: float) -> void:
	if _ranged_tele != null and is_instance_valid(_ranged_tele):
		_ranged_tele.queue_free()
	var tg := EnemyProjectile.make_telegraph(dir, clampf(length, 2.0, RANGED_RANGE))
	add_child(tg)
	_ranged_tele = tg
	# Grow the aim-line over the windup so it reads as a charging shot, not a
	# constant beam (F1) — and a "filling up" cue for when it fires.
	tg.scale.z = 0.05
	var tw := tg.create_tween()
	tw.tween_property(tg, "scale:z", 1.0, maxf(0.08, _telegraph_t))

func _fire_projectile(dir: Vector3) -> void:
	if _ranged_tele != null and is_instance_valid(_ranged_tele):
		_ranged_tele.queue_free()
		_ranged_tele = null
	var scene := get_parent()
	if scene == null:
		return
	var proj := EnemyProjectile.new()
	scene.add_child(proj)
	proj.setup(global_position + Vector3(0.0, 0.6, 0.0) + dir.normalized() * 0.5,
		dir, proj_speed, proj_damage)

func _face(dir: Vector3) -> void:
	if dir.length() < 0.01:
		return
	var gfx := get_child(0)   # the GLB instance
	if gfx is Node3D:
		(gfx as Node3D).rotation.y = atan2(dir.x, dir.z)

# ---- feedback ticks (spec 14) ----
func _tick_feedback(delta: float) -> void:
	if _flash_t > 0.0:
		_flash_t -= delta
		if _flash_t <= 0.0:
			_restore_flash()
	# Hit-react scale-punch on the BODY (the attack tell is now the mesh
	# wind-back/lunge in creature_anim — Phase 2).
	var punch := 0.0
	if _react_t > 0.0:
		_react_t -= delta
		punch = 0.18 * (_react_t / REACT_SEC)
	scale = _base_scale * (1.0 + punch)

# Spec 32c — public mesh-flash entry point. HitFeedback calls this for both
# hit flashes (white, FLASH_SEC) and status tick pulses (status-themed
# colour with alpha, PULSE_DURATION). Reuses `_flash_mat` for the white
# default; allocates a fresh material for coloured pulses so they don't
# clobber the canonical white-flash material.
func apply_flash(duration: float = FLASH_SEC, color: Color = Color.WHITE) -> void:
	if not _saved.is_empty():
		return
	_flash_t = duration
	var mat: StandardMaterial3D
	if color == Color.WHITE:
		mat = _flash_mat
	else:
		mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.5
		if color.a < 1.0:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for mi in _meshes:
		_saved[mi] = (mi as MeshInstance3D).material_override
		(mi as MeshInstance3D).material_override = mat

# Spec 32c — public knockback entry point. HitFeedback calls this with the
# tier-multiplied strength. Direction is flattened to the XZ plane.
func apply_knockback(dir: Vector3, strength: float) -> void:
	var flat := Vector3(dir.x, 0.0, dir.z)
	if flat.length() > 0.001:
		_knockback = flat.normalized() * strength * KNOCKBACK_DECAY

func _restore_flash() -> void:
	for mi in _saved:
		if is_instance_valid(mi):
			(mi as MeshInstance3D).material_override = _saved[mi]
	_saved.clear()

func _spawn_damage_number(amount: int, tier: String = "normal") -> void:
	var dn := DamageNumberScene.instantiate()
	var host: Node = get_parent()
	if host == null:
		host = get_tree().root
	host.add_child(dn)
	dn.global_position = global_position + Vector3(0.0, 2.0, 0.0)
	dn.setup(amount, tier)

# ---- Spec 31: status framework ----
# Apply (or extend) a status. Highest-wins + refresh-duration stacking
# (D3 model): if the kind is already active, take max(time_left, duration)
# and max(damage_per_tick, dpt). slow_factor takes the MIN (stronger slow
# wins). Returns the (possibly extended) StatusEffect; null if dead.
func apply_status(kind: String, duration: float, dpt: int,
		slow_factor: float = 1.0, tick_interval: float = 0.0) -> StatusEffect:
	if dead:
		return null
	# Spec 32 — a CC-immune elite resists root/snared for `cc_immune_window`
	# seconds after the FIRST one lands. The first call goes through (and arms
	# the immunity); subsequent root/snared within the window return null.
	# Burn/bleed are unaffected. Data-driven: ANY modifier that declares a
	# `cc_immune_window` qualifies (briarbound 4s, thornshelled 8s) — not just
	# a hardcoded briarbound (that bug let thornshelled be perma-rooted).
	if is_elite and (kind == "root" or kind == "snared") \
			and Elites.MODIFIERS.get(modifier, {}).has("cc_immune_window"):
		var now: float = float(Time.get_ticks_msec()) / 1000.0
		if now < _cc_immune_until:
			return null
		var window: float = float(Elites.MODIFIERS[modifier]["cc_immune_window"])
		_cc_immune_until = now + window
	var existing: StatusEffect = _statuses.get(kind, null)
	if existing != null:
		existing.time_left = maxf(existing.time_left, duration)
		existing.damage_per_tick = maxi(existing.damage_per_tick, dpt)
		existing.slow_factor = minf(existing.slow_factor, slow_factor)
		return existing
	var s := StatusEffectScript.new()
	s.kind = kind
	s.time_left = duration
	s.tick_interval = tick_interval
	s.next_tick = tick_interval
	s.damage_per_tick = dpt
	s.slow_factor = slow_factor
	# Visual: skip the particle (but keep the status) if we already have
	# STATUS_PARTICLE_CAP particle systems active. Root's disc isn't a
	# particle system, so it doesn't count against the cap.
	var particle_count := 0
	for k in _statuses:
		var ev = _statuses[k].visual
		if ev != null and ev is GPUParticles3D:
			particle_count += 1
	if kind == "root" or particle_count < STATUS_PARTICLE_CAP:
		s.visual = _make_status_visual(kind)
		if s.visual != null:
			add_child(s.visual)
	_statuses[kind] = s
	_spawn_apply_text(kind)
	return s

func has_status(kind: String) -> bool:
	return _statuses.has(kind)

# Phase 3 (co-op) — the host snapshots these so puppet foes mirror the visuals.
func net_status_flags() -> Array:
	return _statuses.keys()

# Reconcile a PUPPET's cosmetic status visuals to the host's active set: add
# visuals for new kinds (respecting the particle cap), free ones that left.
func _net_apply_status_vis(kinds: Array) -> void:
	for k in _net_status_vis.keys():
		if not (k in kinds):
			var v = _net_status_vis[k]
			if is_instance_valid(v):
				v.queue_free()
			_net_status_vis.erase(k)
	for kk in kinds:
		var kind := String(kk)
		if _net_status_vis.has(kind):
			continue
		var particle_count := 0
		for ek in _net_status_vis:
			if _net_status_vis[ek] is GPUParticles3D:
				particle_count += 1
		if kind == "root" or particle_count < STATUS_PARTICLE_CAP:
			var vis := _make_status_visual(kind)
			if vis != null:
				add_child(vis)
				_net_status_vis[kind] = vis

func get_status(kind: String) -> StatusEffect:
	return _statuses.get(kind, null)

# Spec 30 alias — preserves `is_rooted()` callers from earlier specs.
func is_rooted() -> bool:
	return has_status("root")

# Spec 30 alias — Bramble Snare still calls `apply_root(d)` from
# player_controller; now just routes through the unified status pipe.
func apply_root(duration: float) -> void:
	apply_status("root", duration, 0, 1.0, 0.0)

# Per-frame status tick. Single tick per status per frame (no while-loop
# catch-up) — accepts the lag-loss tradeoff to avoid double-fires when
# delta == tick_interval. Snapshots the keys so a tick-triggered _die()
# can mutate _statuses safely.
func _tick_statuses(delta: float) -> void:
	if _statuses.is_empty():
		return
	var kinds: Array = _statuses.keys()
	for kind in kinds:
		if not _statuses.has(kind):
			continue
		var s: StatusEffect = _statuses[kind]
		s.time_left -= delta
		if s.tick_interval > 0.0 and s.damage_per_tick > 0:
			s.next_tick -= delta
			if s.next_tick <= 0.0:
				s.next_tick = s.tick_interval
				_apply_tick_damage(s.damage_per_tick)
				if dead:
					return
				# Spec 32c — soft mesh tint pulse on tick (closes the spec
				# 31 deferred followup). Suppressed if a hit-flash is active.
				HitFeedback.tick_pulse(self, kind)
		if s.time_left <= 0.0:
			if s.visual != null and is_instance_valid(s.visual):
				s.visual.queue_free()
			_statuses.erase(kind)

# Product of all slow_factors; clamped so stacking never freezes (only Root
# truly immobilizes — soft slows are always "creeping" at minimum).
func _slow_product() -> float:
	var p := 1.0
	for kind in _statuses:
		p *= float(_statuses[kind].slow_factor)
	return clampf(p, 0.25, 1.0)

# Direct hp reduction — skips crit roll / knockback / hitstop. Used by DoT
# ticks so Burn doesn't randomly super-crit (which would also bleed-on-crit
# and create a positive-feedback loop).
func _apply_tick_damage(amount: int) -> void:
	if dead or amount <= 0:
		return
	hp -= amount
	_spawn_damage_number(amount, "normal")
	# Spec 32c — the white flash is handled by HitFeedback.tick_pulse in the
	# status caller (so coloured pulses for burn/bleed land correctly).
	# Just bump _flash_t here so _tick_feedback decays correctly even if no
	# pulse fires for this status kind.
	if _flash_t < FLASH_SEC * 0.5:
		_flash_t = FLASH_SEC * 0.5
	if hp <= 0:
		_die()

# Spawn the matching visual node for a status. Root reuses the spec 30
# emerald disc; the others spawn a small particle system.
func _make_status_visual(kind: String) -> Node3D:
	if kind == "root":
		return _make_root_disc()
	return _make_status_particle(kind)

func _make_root_disc() -> MeshInstance3D:
	var disc := MeshInstance3D.new()
	disc.name = "RootDisc"
	var dm := CylinderMesh.new()
	dm.top_radius = 0.55
	dm.bottom_radius = 0.55
	dm.height = 0.06
	disc.mesh = dm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.65, 0.25, 0.70)
	mat.emission_enabled = true
	mat.emission = Color(0.30, 0.65, 0.25)
	mat.emission_energy_multiplier = 1.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disc.material_override = mat
	disc.position = Vector3(0.0, 0.04, 0.0)
	return disc

# Small ambient particle above the head (or at feet for Snared) in the
# status's signature colour. Cheap GPUParticles3D — 12 box particles,
# upward drift, gradient fade. Matches the spec 26 arrow-trail aesthetic.
func _make_status_particle(kind: String) -> GPUParticles3D:
	# Spec-34 cookbook: each status needs its own motion language so they
	# don't all read as "drifting cubes of color X". Burn rises (heat), bleed
	# FALLS (gravity drops), snared ORBITS the feet (vines wrap), root is a
	# disc (separate path). The kind-keyed parameters here change direction,
	# gravity, spread, mesh shape, and emit position — same particle module,
	# four distinct silhouettes.
	var col: Color = STATUS_COLOR.get(kind, Color.WHITE)
	var p := GPUParticles3D.new()
	p.name = "%sParticle" % kind.capitalize()
	p.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.color = col
	pm.gravity = Vector3.ZERO
	var grad := Gradient.new()
	grad.set_color(0, Color(col.r, col.g, col.b, 0.95))
	grad.set_color(1, Color(col.r, col.g, col.b, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = grad
	pm.color_ramp = ramp
	# Per-kind tuning — direction, motion, position, shape.
	# Spec-34: every base mesh_size is 3x bumped per user feedback —
	# status effects need to read at-a-glance from the showcase distance.
	var mesh_size := Vector3(0.24, 0.24, 0.24)            # 3x bumped from 0.08
	match kind:
		"burn":
			# Heat rises — fast upward drift, wide spread, dense embers
			# with size variation for layered fire feel (big embers +
			# small sub-sparkles, simulating sub-emitters in one stream).
			p.amount = 36                              # ×2.25 for density
			p.lifetime = 0.85
			p.position = Vector3(0.0, 2.0, 0.0)
			pm.direction = Vector3(0, 1, 0)
			pm.spread = 35.0
			pm.initial_velocity_min = 0.5
			pm.initial_velocity_max = 1.6
			pm.scale_min = 0.25                        # WIDER size range — small
			pm.scale_max = 1.1                          # sparkles + big embers
			pm.angular_velocity_min = -60.0            # ember tumble adds life
			pm.angular_velocity_max = 60.0
		"bleed":
			# Droplets FALL from chest height — gravity pulls them down,
			# narrow spread, elongated mesh reads as a drop not a cube.
			# Higher count + scatter range so the wound reads as messy.
			p.amount = 28                              # ×1.75
			p.lifetime = 1.1
			p.position = Vector3(0.0, 1.6, 0.0)
			pm.direction = Vector3(0, -1, 0)         # downward emission
			pm.spread = 22.0                          # slight scatter
			pm.initial_velocity_min = 0.35
			pm.initial_velocity_max = 1.1
			pm.gravity = Vector3(0, -5.5, 0)          # accelerates fall
			pm.scale_min = 0.5
			pm.scale_max = 1.4                         # bigger top, range wider
			mesh_size = Vector3(0.30, 0.96, 0.30)     # 3x bumped — taller droplet
		"snared":
			# Vines wrap the feet — emit at ankle height in a HORIZONTAL ring
			# (no upward velocity), wide horizontal spread, large flat shape.
			# More count + per-particle rotation for organic tangle feel.
			p.amount = 32                              # ×1.8
			p.lifetime = 1.2
			p.position = Vector3(0.0, 0.15, 0.0)
			pm.direction = Vector3(1, 0, 0)           # horizontal
			pm.spread = 180.0                          # all directions in plane
			pm.flatness = 1.0                          # FORCE planar (no Y)
			pm.initial_velocity_min = 0.30
			pm.initial_velocity_max = 0.85
			pm.scale_min = 0.55
			pm.scale_max = 1.45                        # wider range
			pm.angular_velocity_min = -120.0           # tendril twist
			pm.angular_velocity_max = 120.0
			mesh_size = Vector3(0.66, 0.21, 0.66)     # 3x bumped — wider flat tendril
		_:
			# Fallback (root, etc) — keep the legacy upward drift behavior.
			p.amount = 12
			p.lifetime = 0.8
			p.position = Vector3(0.0, 2.2, 0.0)
			pm.direction = Vector3(0, 1, 0)
			pm.spread = 25.0
			pm.initial_velocity_min = 0.3
			pm.initial_velocity_max = 0.8
			pm.scale_min = 0.4
			pm.scale_max = 0.7
	p.process_material = pm
	# Spec-34: textured billboard particles. Inline build (Godot's parser
	# can't resolve static methods on preloaded scripts without class_name
	# being globally-registered via an editor pass).
	var s: float = maxf(mesh_size.x, mesh_size.z) * 3.0
	var qsize := Vector2(s, s)
	if kind == "bleed":
		qsize = Vector2(mesh_size.x * 3.0, mesh_size.y * 2.0)
	var tex: Texture2D = TEX_EMBER if kind == "burn" else TEX_SOFT_CIRCLE
	var qmesh := QuadMesh.new()
	qmesh.size = qsize
	var qmat := StandardMaterial3D.new()
	qmat.albedo_color = col
	qmat.albedo_texture = tex
	qmat.emission_enabled = true
	qmat.emission = col
	qmat.emission_energy_multiplier = 3.0
	qmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qmesh.material = qmat
	p.draw_pass_1 = qmesh
	p.emitting = true
	return p

# Italic-ish apply-text floats once when a status lands (not every tick).
# Reuses the DamageNumber spawn pipe with the new setup_apply variant.
func _spawn_apply_text(kind: String) -> void:
	var label: String = APPLY_TEXT.get(kind, "")
	if label == "":
		return
	var col: Color = STATUS_COLOR.get(kind, Color.WHITE)
	var dn := DamageNumberScene.instantiate()
	var host: Node = get_parent()
	if host == null:
		host = get_tree().root
	host.add_child(dn)
	dn.global_position = global_position + Vector3(0.0, 2.4, 0.0)
	if dn.has_method("setup_apply"):
		dn.setup_apply(label, col)

# Float the elite modifier's name once on promotion, in its label_color.
func _spawn_elite_label(text: String, col: Color) -> void:
	var dn := DamageNumberScene.instantiate()
	var host: Node = get_parent()
	if host == null:
		host = get_tree().root
	host.add_child(dn)
	dn.global_position = global_position + Vector3(0.0, 2.7, 0.0)
	if dn.has_method("setup_apply"):
		dn.setup_apply(text, col)

# Spec 31 — release every status visual + clear the dict. Called from _die()
# so visuals don't outlive the body.
func _clear_all_statuses() -> void:
	for kind in _statuses.keys():
		var s: StatusEffect = _statuses[kind]
		if s.visual != null and is_instance_valid(s.visual):
			s.visual.queue_free()
	_statuses.clear()
	for k in _net_status_vis.keys():
		var v = _net_status_vis[k]
		if is_instance_valid(v):
			v.queue_free()
	_net_status_vis.clear()
	# C7 — the execute ring dies with the foe.
	if _execute_ring != null and is_instance_valid(_execute_ring):
		_execute_ring.queue_free()
	_execute_ring = null

func _die() -> void:
	dead = true
	# Spec 31 — clear every status visual on death (was just the root disc
	# in spec 30; now generalised).
	_clear_all_statuses()
	_restore_flash()
	# Phase 3 — a ghost killed mid-windup shouldn't paint a "shot incoming"
	# aim-line on its own corpse through the death tween.
	if _ranged_tele != null and is_instance_valid(_ranged_tele):
		_ranged_tele.queue_free()
		_ranged_tele = null
	# Spec 32 — elite on_death dispatch (Brambled bleed-nova). Fires BEFORE
	# queue_free so AoeQuery sees us as a valid position source.
	if is_elite and modifier != "":
		_elite_on_death()
	# B6 — Bursting: the corpse pops, scorching kin (and the player when
	# the chart rolled Volatile).
	if burst_on_death:
		_death_burst()
	# B7/ADR 0005 — the kill feeds Huntcraft, scaled to the slain thing's
	# vigor (elites and bosses are worth their weight).
	var game := get_tree().root.get_node_or_null("Game")
	var netd := get_node_or_null("/root/NetGame")
	var in_session: bool = netd != null and bool(netd.active)
	if game != null and not net_puppet:
		# Phase B — the kill pays its KILLER: in co-op the host credits the
		# peer whose arrow landed last; offline (and host kills) stay local.
		if in_session and last_hit_peer != 0 \
				and last_hit_peer != multiplayer.get_unique_id():
			netd.kill_credit(last_hit_peer, hp_max)
		else:
			pass  # ADR 0012 — combat gives no skill XP; kills no longer award it
			# Spec 45-hunt — Even Breath: a clean kill steadies the hunter.
			if game.perk_active("wayfinding", "even_breath"):
				var pl := _nearest_player()   # the peer who was fighting it
				if pl != null and pl.has_method("add_focus"):
					pl.add_focus(6.0)
	var sfx := get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.play("death")
	_spawn_drops()                       # spec 27b — loot before we sink
	# Slice B — a cozy ember-pop on EVERY kill (not just bursting elites):
	# a one-shot particle burst + an expanding warm ground-ring, so a felled
	# foe reads as a soft puff of leaves/embers rather than a silent shrink.
	_kill_burst()
	# Spec 32 — clear the elite feet-ring so it doesn't outlive the body.
	if _elite_ring != null and is_instance_valid(_elite_ring):
		_elite_ring.queue_free()
		_elite_ring = null
	_free_brute_ring()   # a brute that dies mid-windup drops its telegraph ring
	var t := create_tween()
	t.tween_property(self, "position:y", position.y - 1.6, DEATH_SEC)
	t.parallel().tween_property(self, "scale", _base_scale * 0.05, DEATH_SEC)
	t.tween_callback(queue_free)
	died.emit()

# Roll the drop pile + drop each item as an ItemPickup beside the corpse.
# Parented to our parent so the pickups outlive our queue_free.
func _spawn_drops() -> void:
	if net_puppet:
		return   # the host's drop events carry per-player rolls instead
	# C11 — elites with a reward_tier_bonus lift the rarity floor of their drops.
	var tier_bonus: int = 0
	if is_elite:
		tier_bonus = int(Elites.MODIFIERS.get(modifier, {}).get("reward_tier_bonus", 0))
	# Enchant economy — reagents drop to the satchel and elites/bosses teach the
	# rare/unique charms. Awarded straight to the shared Game (not the per-player
	# pickup pipe), so it sits ahead of the co-op early-return below.
	_award_enchant_loot(role, depth, tier_bonus)
	var pile: Array = Drops.roll_drop(role, depth, tier_bonus)
	if pile.is_empty():
		return
	# Phase B — co-op loot is instanced per player: the host broadcasts
	# kind+rarity and every peer rolls its own affixes locally (the
	# claudecraft tap-rights model, made cozier).
	var netd := get_node_or_null("/root/NetGame")
	if netd != null and bool(netd.active) and multiplayer.is_server():
		for it in pile:
			netd.drop_event(String(it.get("kind_id", "")),
				String(it.get("rarity", "normal")), global_position)
		return
	var host := get_parent()
	if host == null:
		return
	var center := global_position
	for i in pile.size():
		# Spec 27f — stagger multi-drops over ~80ms each so a boss kill
		# reads as a small loot cascade, not all at once. Single drops
		# (combat/treasure/shrine) still spawn instantly.
		if i == 0:
			_spawn_one_pickup(host, pile[i], center)
		else:
			get_tree().create_timer(i * 0.08).timeout.connect(
				_spawn_one_pickup.bind(host, pile[i], center))

# Reagent + charm-discovery payout. Routed to the shared Game satchel /
# discovered set. Skipped under live co-op for now (reagents aren't instanced
# per-player yet — they're also craftable at the bench, so no one is gated).
func _award_enchant_loot(role: String, depth: int, tier_bonus: int) -> void:
	var game := get_node_or_null("/root/Game")
	if game == null:
		return
	var netd := get_node_or_null("/root/NetGame")
	if netd != null and bool(netd.active):
		return
	var reagents: Dictionary = Drops.roll_reagents(role, depth, tier_bonus)
	for mid in reagents:
		game.add_material(String(mid), int(reagents[mid]))
	for eid in Drops.roll_enchant_discovery(role, depth, tier_bonus):
		if game.has_method("discover_enchant"):
			game.discover_enchant(String(eid))

func _spawn_one_pickup(host: Node, it: Dictionary, center: Vector3) -> void:
	if not is_instance_valid(host):
		return
	# Spec 32a — the loot pipe lives behind ItemPickup.spawn now.
	var ang := randf() * TAU
	var kick := Vector3(cos(ang), 0.0, sin(ang)) * randf_range(0.4, 1.0)
	ItemPickup.spawn(host, it, center + kick)

# ---- Spec 32: elite promotion + modifier dispatch ----

# Promote this combatant to an elite of the given modifier. Mutates: hp_max,
# hp, scale, mesh material_overrides (persistent golden tint), role (for the
# drops pipe), modifier-specific fields (_move_mult / _attack_speed_mult /
# _cc_immune_until). Idempotent — if already elite, returns without re-applying.
func apply_elite(modifier_key: String) -> void:
	if is_elite or modifier_key == "" or not Elites.MODIFIERS.has(modifier_key):
		return
	var mod: Dictionary = Elites.MODIFIERS[modifier_key]
	is_elite = true
	modifier = modifier_key
	role = "elite"                                       # drives the drops pipe
	# HP boost
	var hp_mult: float = float(mod.get("hp_mult", 1.0))
	hp_max = int(round(float(hp_max) * hp_mult))
	hp = hp_max
	# Scale boost — multiplied on top of the visual scale set at spawn.
	var scale_mult: float = float(mod.get("scale_mult", 1.0))
	scale = scale * scale_mult
	_base_scale = scale                                  # so hit-react punch returns here
	# Modifier-specific stat tweaks
	_move_mult = float(mod.get("move_mult", 1.0))
	_attack_speed_mult = float(mod.get("attack_speed_mult", 1.0))
	# Persistent golden tint — _saved is empty here, so apply_flash on hit
	# will save THIS golden material and restore it after the flash. The
	# tint survives every hit thanks to the spec 32c restoration path.
	var tint: Color = mod.get("tint", Color(1.0, 0.92, 0.55))
	_apply_elite_tint(tint)
	# Feet-ring particle — persistent visual signal, in the modifier's own
	# ring_color so each elite kind reads distinctly (Batch-4 elite tints).
	_elite_ring = _make_elite_ring(mod.get("ring_color", tint))
	add_child(_elite_ring)
	# Float the modifier name on promotion so the kind is legible at a glance.
	_spawn_elite_label(String(mod.get("name", modifier_key)),
		mod.get("label_color", tint))

# Walk _meshes and overlay each with a fresh golden material. Distinct from
# `apply_flash` because there's no _flash_t timer; the tint is permanent
# until the elite dies.
func _apply_elite_tint(tint: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.emission_enabled = true
	mat.emission = tint
	mat.emission_energy_multiplier = 0.6
	# Keep the chunky ink silhouette on promoted elites — the golden override
	# would otherwise drop the rim that layout_loader painted on the base kind.
	mat.next_pass = _ink_outline_pass()
	for mi in _meshes:
		if mi is MeshInstance3D:
			(mi as MeshInstance3D).material_override = mat

# The shared inverted-hull ink rim (mirrors layout_loader._make_outline_pass).
func _ink_outline_pass() -> StandardMaterial3D:
	var o := StandardMaterial3D.new()
	o.grow = true
	o.grow_amount = 0.05
	o.cull_mode = BaseMaterial3D.CULL_FRONT
	o.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	o.albedo_color = Color(0.13, 0.09, 0.06)
	return o

# Slow-spinning golden ring at the elite's feet. Cheap GPUParticles3D — 8
# box particles in a tight ring, low velocity.
func _make_elite_ring(tint: Color) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "EliteRing"
	p.amount = 8
	p.lifetime = 1.8
	p.local_coords = false
	p.position = Vector3(0.0, 0.05, 0.0)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_radius = 0.55
	pm.emission_ring_inner_radius = 0.45
	pm.emission_ring_axis = Vector3(0, 1, 0)
	pm.emission_ring_height = 0.02
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 8.0
	pm.initial_velocity_min = 0.05
	pm.initial_velocity_max = 0.15
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.4
	pm.scale_max = 0.7
	pm.color = tint
	var grad := Gradient.new()
	grad.set_color(0, Color(tint.r, tint.g, tint.b, 0.9))
	grad.set_color(1, Color(tint.r, tint.g, tint.b, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = grad
	pm.color_ramp = ramp
	p.process_material = pm
	var pmesh := BoxMesh.new()
	pmesh.size = Vector3(0.06, 0.06, 0.06)
	var pbm := StandardMaterial3D.new()
	pbm.albedo_color = tint
	pbm.emission_enabled = true
	pbm.emission = tint
	pbm.emission_energy_multiplier = 2.0
	pbm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pbm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pmesh.material = pbm
	p.draw_pass_1 = pmesh
	p.emitting = true
	return p

# Dispatch the modifier's on_death behaviour. Called from _die before the
# tween + queue_free so AoeQuery still sees us as a valid position source.
func _elite_on_death() -> void:
	var mod: Dictionary = Elites.MODIFIERS.get(modifier, {})
	match String(mod.get("on_death", "")):
		"bleed_nova":
			_trigger_bleed_nova()
		"blight_pool":
			_trigger_blight_pool()

# Brambled elite — on death, every enemy within 2.5m takes a Bleed
# (4s / 1s ticks / 1 dpt). Self is excluded (we're dying anyway).
func _trigger_bleed_nova() -> void:
	var center := global_position
	for enemy in AoeQuery.query_circle(get_tree(), center, 2.5, "enemy"):
		if enemy == self:
			continue
		if enemy.has_method("apply_status"):
			enemy.apply_status("bleed", 4.0, 1, 1.0, 1.0)
	# Brief emerald disc visual — same pattern as Bramble Snare, half-second.
	var disc := MeshInstance3D.new()
	disc.name = "BleedNovaDisc"
	var dm := CylinderMesh.new()
	dm.top_radius = 2.5
	dm.bottom_radius = 2.5
	dm.height = 0.06
	disc.mesh = dm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.20, 0.20, 0.45)
	mat.emission_enabled = true
	mat.emission = Color(0.85, 0.20, 0.20)
	mat.emission_energy_multiplier = 1.8
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disc.material_override = mat
	disc.position = center
	var host := get_parent()
	if host != null:
		host.add_child(disc)
		var tw := disc.create_tween()
		tw.tween_property(mat, "albedo_color:a", 0.0, 0.5)
		tw.tween_callback(disc.queue_free)

# Dispatch the modifier's on_attack behaviour. Called from _tick_ai after
# the player.take_damage call lands.
func _elite_on_attack() -> void:
	var mod: Dictionary = Elites.MODIFIERS.get(modifier, {})
	match String(mod.get("on_attack", "")):
		"burn_pulse":
			_trigger_burn_pulse()
		"spine_burst":
			_trigger_spine_burst()

# Sunlit elite — every melee swing applies Burn (3s / 0.5s ticks / 1 dpt = 6
# total ≈ same damage budget as PowerShot's burn on enemies). Spec 33a put
# the player status framework in place; this is the real DoT now (not the
# +3 immediate stand-in from spec 32).
func _trigger_burn_pulse() -> void:
	if _player == null:
		return
	if global_position.distance_to(_player.global_position) <= 2.5:
		if _player.has_method("apply_status"):
			_player.apply_status("burn", 3.0, 1, 1.0, 0.5)

# Thornshelled elite — its armour sheds spines on every swing, so the struck
# player also takes a short Bleed (the tank's chip-damage threat).
func _trigger_spine_burst() -> void:
	if _player == null:
		return
	if global_position.distance_to(_player.global_position) <= 2.8:
		if _player.has_method("apply_status"):
			_player.apply_status("bleed", 2.0, 1, 1.0, 0.5)

# Blightwalker elite — on death it bursts a toxic blight: every enemy AND the
# player within 2.6m festers with a long Bleed, under a teal disc that lingers.
func _trigger_blight_pool() -> void:
	var center := global_position
	for enemy in AoeQuery.query_circle(get_tree(), center, 2.6, "enemy"):
		if enemy != self and enemy.has_method("apply_status"):
			enemy.apply_status("bleed", 5.0, 1, 1.0, 1.0)
	if _player != null and _player.has_method("apply_status") \
			and _player.global_position.distance_to(center) <= 2.6:
		_player.apply_status("bleed", 5.0, 1, 1.0, 1.0)
	var disc := MeshInstance3D.new()
	disc.name = "BlightPoolDisc"
	var dm := CylinderMesh.new()
	dm.top_radius = 2.6
	dm.bottom_radius = 2.6
	dm.height = 0.05
	disc.mesh = dm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.75, 0.62, 0.45)
	mat.emission_enabled = true
	mat.emission = Color(0.30, 0.75, 0.62)
	mat.emission_energy_multiplier = 1.6
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disc.material_override = mat
	disc.position = center
	var host := get_parent()
	if host != null:
		host.add_child(disc)
		var tw := disc.create_tween()
		tw.tween_interval(1.5)
		tw.tween_property(mat, "albedo_color:a", 0.0, 1.0)
		tw.tween_callback(disc.queue_free)

# B6 — the bursting affix's corpse pop: 6 damage to enemies within 2m
# (skipping other corpses); Volatile also catches the player. A short
# ember ring sells the radius.
func _death_burst() -> void:
	const BURST_RADIUS := 2.0
	const BURST_DMG := 6
	for other in AoeQuery.query_circle(get_tree(), global_position, BURST_RADIUS):
		if other == self or other == null or not is_instance_valid(other):
			continue
		if bool(other.get("dead")):
			continue
		var dir: Vector3 = other.global_position - global_position
		dir.y = 0.0
		other.take_damage(BURST_DMG, dir.normalized())
	if burst_hits_player:
		var player := _nearest_player()
		if player != null and player.has_method("take_damage") \
				and player.global_position.distance_to(global_position) <= BURST_RADIUS:
			var pdir: Vector3 = player.global_position - global_position
			pdir.y = 0.0
			player.take_damage(BURST_DMG, pdir.normalized())
	# The visual: an expanding ember ring at the corpse.
	var mi := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.3
	torus.outer_radius = 0.42
	mi.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.55, 0.2, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.5, 0.15)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	mi.position = global_position + Vector3(0, 0.2, 0)
	get_parent().add_child(mi)
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE * (BURST_RADIUS / 0.42), 0.25) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.25)
	tw.tween_callback(mi.queue_free)

# Slice B — the cozy kill-burst. Fired from _die() on every death. Two parts,
# both parented to OUR parent so they outlive the body's queue_free:
#   1. a one-shot GPUParticles3D ember/leaf pop (template: hit_spark.gd) — warm
#      gold/cream sparks that fountain up and settle, short and soft;
#   2. an expanding warm ground-ring (recipe: layout_loader._death_burst /
#      our own _death_burst torus) — a single ripple that fades.
# Kept short and warm so it reads as a puff of embers, not a violent gib.
const KILL_BURST_COLOR := Color(1.0, 0.82, 0.45)        # warm gold-cream embers
const KILL_RING_COLOR := Color(0.85, 0.50, 0.28, 0.7)   # soft terracotta ripple
func _kill_burst() -> void:
	var host := get_parent()
	if host == null:
		host = get_tree().root
	var center := global_position + Vector3(0.0, 0.5, 0.0)
	# --- 1. ember pop (one-shot particle fountain) ---
	var p := GPUParticles3D.new()
	p.amount = 20
	p.lifetime = 0.6
	p.one_shot = true
	p.explosiveness = 1.0
	p.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 75.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 4.5
	pm.gravity = Vector3(0, -7.5, 0)         # gentle settle, not a hard spray
	pm.scale_min = 0.5
	pm.scale_max = 1.2
	pm.color = KILL_BURST_COLOR
	var grad := Gradient.new()
	grad.set_color(0, Color(KILL_BURST_COLOR.r, KILL_BURST_COLOR.g,
		KILL_BURST_COLOR.b, 0.95))
	grad.set_color(1, Color(KILL_BURST_COLOR.r, KILL_BURST_COLOR.g,
		KILL_BURST_COLOR.b, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = grad
	pm.color_ramp = ramp
	p.process_material = pm
	# Textured billboard spark — soft-circle alpha falloff (matches hit_spark
	# and the status particles); 3x size convention from spec-34.
	var qmesh := QuadMesh.new()
	qmesh.size = Vector2(0.10 * 12.0, 0.10 * 12.0)
	var qmat := StandardMaterial3D.new()
	qmat.albedo_color = KILL_BURST_COLOR
	qmat.albedo_texture = TEX_SOFT_CIRCLE
	qmat.emission_enabled = true
	qmat.emission = KILL_BURST_COLOR
	qmat.emission_energy_multiplier = 2.5
	qmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qmesh.material = qmat
	p.draw_pass_1 = qmesh
	host.add_child(p)
	p.global_position = center
	p.emitting = true
	p.get_tree().create_timer(1.4).timeout.connect(p.queue_free)
	# --- 2. expanding warm ground-ring (a single fading ripple) ---
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.22
	torus.outer_radius = 0.34
	ring.mesh = torus
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = KILL_RING_COLOR
	rmat.emission_enabled = true
	rmat.emission = Color(KILL_RING_COLOR.r, KILL_RING_COLOR.g, KILL_RING_COLOR.b)
	rmat.emission_energy_multiplier = 1.4
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = rmat
	ring.position = global_position + Vector3(0.0, 0.12, 0.0)
	host.add_child(ring)
	var rtw := ring.create_tween()
	rtw.tween_property(ring, "scale", Vector3.ONE * 4.5, 0.35) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rtw.parallel().tween_property(rmat, "albedo_color:a", 0.0, 0.35)
	rtw.tween_callback(ring.queue_free)
