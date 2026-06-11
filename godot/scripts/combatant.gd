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
const LEASH_RADIUS := 11.0          # past this, give up and idle
const ATTACK_RANGE := 1.8
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
# Spec 27b — drop context. layout_loader sets these per-spawn.
var role := "combat"
var depth := 0
# Spec 32 — elite state. is_elite=true gates the modifier dispatch in _die +
# _tick_ai; modifier is a key into Elites.MODIFIERS. _move_mult /
# _attack_speed_mult default to 1.0 (no-op for non-elites; Swift bumps).
# _cc_immune_until is a Time.get_ticks_msec() / 1000.0 timestamp gating
# Briarbound's root/snared immunity.
var is_elite: bool = false
var modifier: String = ""
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

# Spec 31 — status visual + apply-text palettes.
const STATUS_COLOR := {
	"burn":   Color(1.00, 0.55, 0.18),
	"bleed":  Color(0.85, 0.20, 0.20),
	"snared": Color(0.45, 0.65, 0.30),
	"root":   Color(0.30, 0.65, 0.25),
}
const APPLY_TEXT := {
	"burn":   "singed!",
	"bleed":  "bleeding!",
	"snared": "snared!",
	"root":   "rooted!",
}
# Bleed-on-crit damage fraction — total bleed damage ≈ 25% of crit damage,
# spread across 4 ticks at 1 s = ~6.25% per tick.
const BLEED_TICK_FRACTION := 0.0625
const STATUS_PARTICLE_CAP := 2          # max concurrent GPUParticles3D per enemy

var _state: State = State.IDLE
var _player: Node3D
var _proc_anim                     # optional procedural animator (spec 21 rat)
var _agent: NavigationAgent3D
var _repath_t := 0.0
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

	# Spec 31 — bleed-on-crit. Only enemy combatants bleed (the player has
	# `take_damage` too, but isn't in the enemy group — keeps the friendly-fire
	# / self-bleed surface out of v1). Bleeds tick ~25% of crit dmg over 4s.
	if (tier == "crit" or tier == "super") and is_in_group("enemy"):
		var bleed_dpt := maxi(1, int(round(float(dmg) * BLEED_TICK_FRACTION)))
		apply_status("bleed", 4.0, bleed_dpt, 1.0, 1.0)

	hp -= dmg
	_spawn_damage_number(dmg, tier)
	_react_t = REACT_SEC
	# A hit also wakes an idle enemy.
	if _state == State.IDLE:
		_state = State.CHASE
	# Spec 32c — all 6 feedback channels (flash, knockback, hitstop, spark,
	# shake, SFX) fire through one seam now.
	HitFeedback.play_hit(self, tier, from_dir)
	if hp <= 0:
		_die()

func _physics_process(delta: float) -> void:
	if dead:
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
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			velocity = Vector3.ZERO
			return
	# Spec 30/31 — rooted enemies don't chase or attack. Knockback still
	# applies (it's added after this tick) so the player can shoot them around.
	if has_status("root"):
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var to := _player.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	_attack_cd = max(0.0, _attack_cd - delta)
	var moving := false

	match _state:
		State.IDLE:
			velocity.x = 0.0
			velocity.z = 0.0
			if dist < AGGRO_RADIUS:
				_state = State.CHASE
		State.CHASE:
			if dist > LEASH_RADIUS:
				_state = State.IDLE
			elif dist <= ATTACK_RANGE and _attack_cd <= 0.0:
				_state = State.ATTACK
				_telegraph_t = TELEGRAPH_SEC
				_did_hit = false
				velocity.x = 0.0
				velocity.z = 0.0
			else:
				_chase_move(delta)
				moving = true
		State.ATTACK:
			velocity.x = 0.0
			velocity.z = 0.0
			_telegraph_t -= delta
			if _telegraph_t <= 0.0 and not _did_hit:
				_did_hit = true
				if dist <= ATTACK_RANGE * 1.4 and _player.has_method("take_damage"):
					_player.take_damage(ENEMY_DAMAGE, -to.normalized())
					# Spec 32 — elite on_attack dispatch (e.g. Sunlit burn pulse).
					if is_elite and modifier != "":
						_elite_on_attack()
				# Spec 32 — Swift elites attack faster.
				_attack_cd = ATTACK_COOLDOWN / _attack_speed_mult
				_state = State.CHASE

	AnimDriverScript.update(self, moving)
	# Procedural animator (the rat — spec 21) runs alongside the clip driver.
	if _proc_anim != null:
		_proc_anim.update(delta, moving)

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
	velocity.x = step.x * MOVE_SPEED * slow * _move_mult
	velocity.z = step.z * MOVE_SPEED * slow * _move_mult
	_face(step)

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
	# hit-react + attack telegraph both express as a scale punch
	var punch := 0.0
	if _react_t > 0.0:
		_react_t -= delta
		punch = 0.18 * (_react_t / REACT_SEC)
	elif _state == State.ATTACK and _telegraph_t > 0.0:
		punch = 0.22 * (1.0 - _telegraph_t / TELEGRAPH_SEC)
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
	# Spec 32 — Briarbound elite is CC-immune for `cc_immune_window` seconds
	# after the FIRST root/snared lands. The first call goes through (and
	# arms the immunity); subsequent root/snared within the window return
	# null. Burn/bleed are unaffected.
	if is_elite and modifier == "briarbound" and (kind == "root" or kind == "snared"):
		var now: float = float(Time.get_ticks_msec()) / 1000.0
		if now < _cc_immune_until:
			return null
		var window: float = float(Elites.MODIFIERS["briarbound"].get("cc_immune_window", 4.0))
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

# Spec 31 — release every status visual + clear the dict. Called from _die()
# so visuals don't outlive the body.
func _clear_all_statuses() -> void:
	for kind in _statuses.keys():
		var s: StatusEffect = _statuses[kind]
		if s.visual != null and is_instance_valid(s.visual):
			s.visual.queue_free()
	_statuses.clear()

func _die() -> void:
	dead = true
	# Spec 31 — clear every status visual on death (was just the root disc
	# in spec 30; now generalised).
	_clear_all_statuses()
	_restore_flash()
	# Spec 32 — elite on_death dispatch (Brambled bleed-nova). Fires BEFORE
	# queue_free so AoeQuery sees us as a valid position source.
	if is_elite and modifier != "":
		_elite_on_death()
	var sfx := get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.play("death")
	_spawn_drops()                       # spec 27b — loot before we sink
	# Spec 32 — clear the elite feet-ring so it doesn't outlive the body.
	if _elite_ring != null and is_instance_valid(_elite_ring):
		_elite_ring.queue_free()
		_elite_ring = null
	var t := create_tween()
	t.tween_property(self, "position:y", position.y - 1.6, DEATH_SEC)
	t.parallel().tween_property(self, "scale", _base_scale * 0.05, DEATH_SEC)
	t.tween_callback(queue_free)
	died.emit()

# Roll the drop pile + drop each item as an ItemPickup beside the corpse.
# Parented to our parent so the pickups outlive our queue_free.
func _spawn_drops() -> void:
	var pile: Array = Drops.roll_drop(role, depth)
	if pile.is_empty():
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
	# Feet-ring particle — persistent visual signal.
	_elite_ring = _make_elite_ring(tint)
	add_child(_elite_ring)

# Walk _meshes and overlay each with a fresh golden material. Distinct from
# `apply_flash` because there's no _flash_t timer; the tint is permanent
# until the elite dies.
func _apply_elite_tint(tint: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.emission_enabled = true
	mat.emission = tint
	mat.emission_energy_multiplier = 0.6
	for mi in _meshes:
		if mi is MeshInstance3D:
			(mi as MeshInstance3D).material_override = mat

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
