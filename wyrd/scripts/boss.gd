extends "res://scripts/combatant.gd"

# Spec 17 — the Hedgemother boss. Extends Combatant (HP, hurtbox, flash,
# knockback, death, nav chase) and replaces the simple melee AI with a
# 3-phase machine + telegraphed AoE attacks. FATE/Diablo conventions:
# a sealed arena, escalating phases, danger shown before it lands.

signal aggroed
signal phase_changed(phase: int)
signal boss_hp_changed(cur: int, mx: int)
# C10 — the Queen of Thorns calls a thorn-guard when cornered (phase 3).
signal summon_wave(count: int)
const QUEEN_SUMMON_COUNT := 3
var _summoned := false

# ---- phase + attack tunables ----
const PHASE2_FRAC := 0.66          # HP fraction → phase 2
const PHASE3_FRAC := 0.33          # HP fraction → phase 3
const ENGAGE_RANGE := 9.0          # start attacking inside this
const APPROACH_RANGE := 3.0        # closer than this → don't bother chasing
const SWEEP_RADIUS := 3.6          # thorn-sweep — radial, centred on her
const STOMP_RADIUS := 2.3          # root-stomp — targeted at the player's spot
# Wyrd — per-kind: layout_loader sets this from BOSS_KINDS (boar hits
# heavier, wolf lighter, the Queen hardest).
# `damage` now lives on Combatant (B3) — layout_loader sets the per-boss
# value from BOSS_KINDS; 8 was the old hedgemother default.

# B4a — which BOSS_KINDS entry this is; layout_loader sets it. The Boar
# swaps the radial sweep for a line-telegraphed charge you dodge sideways.
var kind := "hedgemother"

const CHARGE_RANGE := 8.0
const CHARGE_WIDTH := 1.7
const CHARGE_SPEED := 11.0
const CHARGE_HIT_RADIUS := 1.3

# B4b — the Wolf's pack-lunge: a chain of short re-aimed dashes. Each
# lunge re-telegraphs at the player's CURRENT position with a snappier
# windup — keep moving or the pack-rhythm catches you.
const LUNGE_RANGE := 4.5
const LUNGE_WIDTH := 1.3
const LUNGE_SPEED := 13.0
const LUNGE_RETELEGRAPH := 0.32

var _charging := false
var _charge_t := 0.0
var _charge_dir := Vector3.FORWARD
var _charge_hit := false
var _charge_speed := CHARGE_SPEED
var _lunges_left := 0

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

# Wyrd — player death resets the encounter instead of leaving the arena
# sealed forever (the run's only exit spawns on her death). Full heal,
# de-aggro, telegraph cancelled; layout_loader drops the gates alongside.
func reset_fight() -> void:
	_aggroed = false
	_telegraphing = false
	_charging = false
	_lunges_left = 0
	_atk_cd = 1.5
	_atk_count = 0
	_phase = 1
	_summoned = false
	hp = hp_max
	if _telegraph_node != null:
		_telegraph_node.queue_free()
		_telegraph_node = null
	boss_hp_changed.emit(hp, hp_max)

# C10 — the Queen's phase-3 thorn-guard: fires once when she's cornered. Called
# from _tick_ai (host/offline only); the adds spawn host-side in layout_loader.
func _maybe_summon() -> void:
	if kind == "hedgemother_queen" and _phase >= 3 and not _summoned:
		_summoned = true
		summon_wave.emit(QUEEN_SUMMON_COUNT)

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
		_player = _nearest_player()   # co-op: target the nearest peer, not the first
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
		_maybe_summon()        # host/offline only — runs from _tick_ai
		if _net_broadcasting():
			_net_boss_phase.rpc(_phase)

	# Aggro — wakes when the player enters the arena.
	if not _aggroed:
		velocity.x = 0.0
		velocity.z = 0.0
		if dist < AGGRO_RADIUS:
			_aggroed = true
			aggroed.emit()
			if _net_broadcasting():
				_net_boss_aggro.rpc()
		return

	# B4a — mid-charge: barrel along the line; walls or the timer end it.
	# One hit per charge, and only if the player is caught in the corridor.
	if _charging:
		_charge_t -= delta
		velocity.x = _charge_dir.x * _charge_speed
		velocity.z = _charge_dir.z * _charge_speed
		_face(_charge_dir)
		if not _charge_hit and _player != null:
			var flat := Vector2(_player.global_position.x - global_position.x,
				_player.global_position.z - global_position.z)
			if flat.length() <= CHARGE_HIT_RADIUS \
					and _player.has_method("take_damage"):
				_charge_hit = true
				_player.take_damage(damage, _charge_dir)
		if _charge_t <= 0.0 or is_on_wall():
			_charging = false
			velocity.x = 0.0
			velocity.z = 0.0
			if _lunges_left > 0:
				_begin_lunge(LUNGE_RETELEGRAPH)   # B4b — re-aim, dash again
			else:
				_atk_cd = _phase_cooldown()
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
	# Hedgemother family: phase 1 thorn-sweep, later phases alternate with
	# root-stomp. The Boar (B4a): the charge IS the signature — phase 1 is
	# charge-only, later phases alternate charge with stomp.
	if kind == "wolf_alpha":
		# B4b — the whole attack is the lunge chain; phases add lunges.
		_lunges_left = [2, 3, 4][_phase - 1]
		_begin_lunge(_phase_telegraph())
		return
	if kind == "burrow_boar":
		_pending = "charge" if _phase == 1 or _atk_count % 2 == 1 else "stomp"
	elif _phase == 1:
		_pending = "sweep"
	else:
		_pending = "stomp" if _atk_count % 2 == 0 else "sweep"
	_tele_total = _phase_telegraph()
	_tele_t = _tele_total
	_telegraphing = true
	_play_sfx("telegraph")
	if _pending == "charge":
		# Snapshot the line at windup start — sidestep to dodge.
		var dir := _player.global_position - global_position
		dir.y = 0.0
		_charge_dir = dir.normalized() if dir.length() > 0.01 else Vector3.FORWARD
		_telegraph_node = _make_line_telegraph(global_position, _charge_dir,
			CHARGE_RANGE, CHARGE_WIDTH)
		if _net_broadcasting():
			_net_boss_telegraph.rpc(true, global_position, _charge_dir,
				CHARGE_RANGE, CHARGE_WIDTH, _tele_total)
		return
	var center := global_position
	var radius := SWEEP_RADIUS
	if _pending == "stomp":
		_stomp_point = _player.global_position    # snapshot — dodgeable
		center = _stomp_point
		radius = STOMP_RADIUS
	_telegraph_node = _make_telegraph(center, radius)
	if _net_broadcasting():
		_net_boss_telegraph.rpc(false, center, Vector3.ZERO, 0.0, radius, _tele_total)

func _begin_lunge(windup: float) -> void:
	_pending = "lunge"
	_tele_total = windup
	_tele_t = windup
	_telegraphing = true
	_play_sfx("telegraph")
	var dir := _player.global_position - global_position
	dir.y = 0.0
	_charge_dir = dir.normalized() if dir.length() > 0.01 else Vector3.FORWARD
	_telegraph_node = _make_line_telegraph(global_position, _charge_dir,
		LUNGE_RANGE, LUNGE_WIDTH)
	if _net_broadcasting():
		_net_boss_telegraph.rpc(true, global_position, _charge_dir,
			LUNGE_RANGE, LUNGE_WIDTH, _tele_total)

func _resolve_attack() -> void:
	if _telegraph_node != null:
		_telegraph_node.queue_free()
		_telegraph_node = null
	# B4a — the charge resolves as movement, not an instant hit: the dash
	# itself carries the damage (one touch per charge).
	if _pending == "charge":
		_charging = true
		_charge_hit = false
		_charge_speed = CHARGE_SPEED
		_charge_t = CHARGE_RANGE / CHARGE_SPEED
		_play_sfx("charge")
		return
	if _pending == "lunge":
		_charging = true
		_charge_hit = false
		_charge_speed = LUNGE_SPEED
		_charge_t = LUNGE_RANGE / LUNGE_SPEED
		_lunges_left -= 1
		_play_sfx("lunge")
		return
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
		_player.take_damage(damage, dir.normalized())

# B4a — a glowing lane on the floor: the charge corridor, origin → range.
func _make_line_telegraph(origin: Vector3, dir: Vector3, length: float,
		width: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(width, 0.08, length)
	mi.mesh = box
	mi.material_override = _telegraph_material()
	var center := origin + dir * (length * 0.5)
	mi.position = Vector3(center.x, 0.07, center.z)
	mi.rotation.y = atan2(dir.x, dir.z)
	var host: Node = get_parent()
	if host == null:
		host = get_tree().root
	host.add_child(mi)
	return mi

func _telegraph_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.26, 0.13, 0.30)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.3, 0.1)
	mat.emission_energy_multiplier = 1.2
	return mat

# A flat glowing disc on the floor — the danger zone, shown before the hit.
func _make_telegraph(center: Vector3, radius: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = 0.08
	mi.mesh = cyl
	mi.material_override = _telegraph_material()
	mi.position = Vector3(center.x, 0.07, center.z)
	var host: Node = get_parent()
	if host == null:
		host = get_tree().root
	host.add_child(mi)
	return mi

func _play_sfx(key: String) -> void:
	var sfx := get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.play(key)

# ---- C-3: boss host-authority — cosmetic replay on guests --------------------
# The boss is a net_puppet on guests (combatant._physics_process early-returns,
# so its _tick_ai never runs there). Pos+hp already replicate via the enemy
# snapshot batch; these RPCs replay the rest cosmetically so guests get the boss
# bar, arena gates, phase tint, and dodgeable telegraphs. Same pattern as the
# player's _net_cast. The boss node is "NetFoe<N>" at an identical path on every
# peer (deterministic build), so node-targeted RPC routes correctly.

func _net_broadcasting() -> bool:
	# Only the host (authority over the boss node) broadcasts; these calls sit
	# inside _tick_ai, which puppets never reach, but guard anyway.
	var netb := get_node_or_null("/root/NetGame")
	return netb != null and bool(netb.active) and multiplayer.is_server()

# Guest boss-bar HP tracks the host via the snapshot (the host emits
# boss_hp_changed from take_damage; the guest takes no damage, so mirror it here).
func net_apply_state(pos: Vector3, p_hp: int, flags: Array = []) -> void:
	super(pos, p_hp, flags)
	boss_hp_changed.emit(hp, hp_max)

@rpc("authority", "call_remote", "reliable")
func _net_boss_aggro() -> void:
	if not _aggroed:
		_aggroed = true
		aggroed.emit()        # bar shows + arena gates raise (wired in layout_loader)

@rpc("authority", "call_remote", "reliable")
func _net_boss_phase(p: int) -> void:
	if p != _phase:
		_phase = p
		phase_changed.emit(p)

@rpc("authority", "call_remote", "unreliable_ordered")
func _net_boss_telegraph(is_line: bool, a: Vector3, b: Vector3,
		length: float, width_or_radius: float, dur: float) -> void:
	# Cosmetic-only — the host already resolved the real hit. Show the same decal
	# for the telegraph window so the guest can dodge, then free it (the AI that
	# pulses/frees the host's copy doesn't run here).
	var mi: MeshInstance3D = _make_line_telegraph(a, b, length, width_or_radius) 		if is_line else _make_telegraph(a, width_or_radius)
	var tw := create_tween()
	tw.tween_interval(maxf(0.05, dur))
	tw.tween_callback(func():
		if is_instance_valid(mi):
			mi.queue_free())
