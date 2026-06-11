extends "res://scripts/combatant.gd"

# Spec 17 — the Hedgemother boss. Extends Combatant (HP, hurtbox, flash,
# knockback, death, nav chase) and replaces the simple melee AI with a
# 3-phase machine + telegraphed AoE attacks. FATE/Diablo conventions:
# a sealed arena, escalating phases, danger shown before it lands.

signal aggroed
signal phase_changed(phase: int)
signal boss_hp_changed(cur: int, mx: int)

# ---- phase + attack tunables ----
const PHASE2_FRAC := 0.66          # HP fraction → phase 2
const PHASE3_FRAC := 0.33          # HP fraction → phase 3
const ENGAGE_RANGE := 9.0          # start attacking inside this
const APPROACH_RANGE := 3.0        # closer than this → don't bother chasing
const SWEEP_RADIUS := 3.6          # thorn-sweep — radial, centred on her
const STOMP_RADIUS := 2.3          # root-stomp — targeted at the player's spot
const BOSS_DAMAGE := 8

var _phase := 1
var _aggroed := false
var _atk_cd := 1.5
var _telegraphing := false
var _tele_t := 0.0
var _tele_total := 0.6
var _pending := "sweep"            # "sweep" | "stomp"
var _stomp_point := Vector3.ZERO
var _telegraph_node: MeshInstance3D
var _atk_count := 0

# Spec 31 — Hedgemother status immunity table.
# - Fully immune to lock-down statuses (root, snared) — the player can't
#   keep the boss permanently locked at range. apply_status returns null.
# - Takes damaging statuses (burn, bleed) at REDUCED_DURATION × duration —
#   you can SEE her burn, but it's a layer not a strategy.
# - Boss bar tags her name " — Unyielding" so the player learns *why* their
#   snare didn't take.
const IMMUNE_KINDS := ["root", "snared"]
const REDUCED_DURATION := {"burn": 0.5, "bleed": 0.5}

func apply_status(kind: String, duration: float, dpt: int,
		slow_factor: float = 1.0, tick_interval: float = 0.0) -> StatusEffect:
	if kind in IMMUNE_KINDS:
		return null
	var mult: float = float(REDUCED_DURATION.get(kind, 1.0))
	return super.apply_status(kind, duration * mult, dpt, slow_factor, tick_interval)

# Cooldown / telegraph length per phase — later phases hit faster with a
# shorter (more dangerous) wind-up.
func _phase_cooldown() -> float:
	return [2.6, 1.9, 1.3][_phase - 1]

func _phase_telegraph() -> float:
	return [0.75, 0.6, 0.46][_phase - 1]

# Boss doesn't get shoved around by arrows; emit HP for the boss bar.
# Signature matches the spec-27e Combatant.take_damage (optional crit args).
func take_damage(amount: int, from_dir: Vector3,
		crit_chance: float = -1.0, crit_mult_bonus: float = -1.0) -> void:
	super(amount, from_dir, crit_chance, crit_mult_bonus)
	_knockback = Vector3.ZERO
	boss_hp_changed.emit(hp, hp_max)

# Override the combatant AI with the boss phase machine.
func _tick_ai(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			velocity = Vector3.ZERO
			return
	var to := _player.global_position - global_position
	to.y = 0.0
	var dist := to.length()

	# Phase by HP gate.
	var frac := float(hp) / float(max(1, hp_max))
	var np := 1
	if frac <= PHASE3_FRAC:
		np = 3
	elif frac <= PHASE2_FRAC:
		np = 2
	if np != _phase:
		_phase = np
		phase_changed.emit(_phase)

	# Aggro — wakes when the player enters the arena.
	if not _aggroed:
		velocity.x = 0.0
		velocity.z = 0.0
		if dist < AGGRO_RADIUS:
			_aggroed = true
			aggroed.emit()
		return

	# Mid-telegraph — hold position, pulse the decal, resolve on time-out.
	if _telegraphing:
		velocity.x = 0.0
		velocity.z = 0.0
		_tele_t -= delta
		if _telegraph_node != null:
			var u: float = 1.0 - clampf(_tele_t / _tele_total, 0.0, 1.0)
			var m := _telegraph_node.material_override as StandardMaterial3D
			if m != null:
				m.albedo_color.a = 0.30 + 0.45 * u
		if _tele_t <= 0.0:
			_resolve_attack()
			_telegraphing = false
			_atk_cd = _phase_cooldown()
		return

	_atk_cd = max(0.0, _atk_cd - delta)
	if dist <= ENGAGE_RANGE and _atk_cd <= 0.0:
		_begin_attack()
		return

	# Otherwise close the distance (reuses Combatant's nav chase).
	if dist > APPROACH_RANGE:
		_chase_move(delta)
		AnimDriverScript.update(self, true)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		_face(to.normalized())

func _begin_attack() -> void:
	_atk_count += 1
	# Phase 1 — thorn-sweep only. Phase 2-3 — alternate with root-stomp.
	if _phase == 1:
		_pending = "sweep"
	else:
		_pending = "stomp" if _atk_count % 2 == 0 else "sweep"
	_tele_total = _phase_telegraph()
	_tele_t = _tele_total
	_telegraphing = true
	var center := global_position
	var radius := SWEEP_RADIUS
	if _pending == "stomp":
		_stomp_point = _player.global_position    # snapshot — dodgeable
		center = _stomp_point
		radius = STOMP_RADIUS
	_telegraph_node = _make_telegraph(center, radius)

func _resolve_attack() -> void:
	if _telegraph_node != null:
		_telegraph_node.queue_free()
		_telegraph_node = null
	if _player == null or not _player.has_method("take_damage"):
		return
	var center := global_position if _pending == "sweep" else _stomp_point
	var radius := SWEEP_RADIUS if _pending == "sweep" else STOMP_RADIUS
	var pp: Vector3 = _player.global_position
	var flat := Vector2(pp.x - center.x, pp.z - center.z)
	if flat.length() <= radius:
		var dir := pp - global_position
		dir.y = 0.0
		if dir.length() < 0.01:
			dir = Vector3.FORWARD
		_player.take_damage(BOSS_DAMAGE, dir.normalized())

# A flat glowing disc on the floor — the danger zone, shown before the hit.
func _make_telegraph(center: Vector3, radius: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = 0.08
	mi.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.26, 0.13, 0.30)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.3, 0.1)
	mat.emission_energy_multiplier = 1.2
	mi.material_override = mat
	mi.position = Vector3(center.x, 0.07, center.z)
	var host: Node = get_parent()
	if host == null:
		host = get_tree().root
	host.add_child(mi)
	return mi
