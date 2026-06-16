extends RefCounted

# Procedural creature animator (supersedes rat_anim's role for the whole cast).
# Meshy can't rig our posed/quadruped/amorphous enemies, so motion is faked in
# code: gentle idle breathing + sway so NOTHING stands frozen, a hop-bob when
# moving, and (Plan.md Phase 2) an attack tell — anticipation wind-back → lunge
# → settle. Owned by the Combatant as `_proc_anim`, ticked with (delta, moving);
# the combatant calls attack()/strike() to drive the melee/ranged tell.
#
# Writes the MESH node's transform only (position / scale / rotation.z). The
# Combatant body's scale-punch (hit-react) writes the BODY, so the two compose
# and never overwrite each other. The mesh's facing (rotation.y) is owned by
# `_face` — we leave it alone and offset position in WORLD-flat space (the body
# is unrotated, so body-local ≈ world), using the attack direction the combatant
# passes in.

const IDLE_BREATH := 0.028   # ±2.8% vertical squash/stretch at rest (breathing)
const IDLE_SWAY := 0.05      # rad — gentle roll at rest
const IDLE_RATE := 2.0       # breaths/sway phase rad/sec
# Attack tell (Phase 2)
const ATK_WINDBACK := 0.16   # metres pulled back during anticipation
const ATK_LUNGE := 0.34      # metres lunged forward on the strike
const ATK_STRIKE_SEC := 0.16 # lunge-and-settle duration
# Juice (Phase 5)
const SPAWN_TIME := 0.28     # pop-in duration on spawn (overshoot)
const LEAN_ANGLE := 0.12     # rad — forward lean while moving (~7°)

var _node: Node3D
var _base_pos := Vector3.ZERO
var _base_scale := Vector3.ONE
var _base_rot_z := 0.0
var _phase := 0.0            # bob phase (moving)
var _breath := 0.0           # breathing/sway phase
var _move_bob := 0.05
var _move_rate := 9.0
var _idle_rate := IDLE_RATE
# attack state
var _attacking := false
var _atk_windup := 0.0
var _atk_t := 0.0            # windup countdown
var _strike_t := 0.0
var _atk_dir := Vector3.ZERO
# juice (Phase 5)
var _spawn_t := 0.0          # counts 0→SPAWN_TIME; pop-in while < SPAWN_TIME
var _lean := 0.0
var _base_rot_x := 0.0

func setup(node: Node3D, move_bob: float = 0.05, move_rate: float = 9.0,
		idle_rate: float = IDLE_RATE) -> void:
	_node = node
	_move_bob = move_bob
	_move_rate = move_rate
	_idle_rate = idle_rate
	if node != null:
		_base_pos = node.position
		_base_scale = node.scale
		_base_rot_z = node.rotation.z
		_base_rot_x = node.rotation.x
		# Phase 5 — start tiny so update() pops the creature in over SPAWN_TIME.
		_spawn_t = 0.0
		node.scale = _base_scale * 0.01
		# Per-creature phase offset so a room doesn't breathe in lockstep
		# (deterministic, RNG-free).
		_breath = absf(node.global_position.x + node.global_position.z) * 1.7

# Begin the attack tell: wind back over `windup` seconds, away from `dir` (the
# world direction TO the target). The combatant calls strike() at windup-end.
func attack(windup: float, dir: Vector3) -> void:
	_atk_windup = maxf(0.05, windup)
	_atk_t = _atk_windup
	_atk_dir = Vector3(dir.x, 0.0, dir.z).normalized()
	_strike_t = 0.0
	_attacking = true

# The blow lands — snap into the lunge.
func strike() -> void:
	_atk_t = 0.0
	_strike_t = ATK_STRIKE_SEC

func update(delta: float, moving: bool) -> void:
	if _node == null:
		return
	if _spawn_t < SPAWN_TIME:
		# Phase 5 — pop in with an overshoot (squash/stretch on arrival).
		_spawn_t += delta
		_node.scale = _base_scale * _back_out(clampf(_spawn_t / SPAWN_TIME, 0.0, 1.0))
		_node.position = _base_pos
		return
	if _attacking:
		if _atk_t > 0.0:
			# Anticipation — ease-in pull back (away from target) + squash down.
			_atk_t -= delta
			var w: float = 1.0 - clampf(_atk_t / _atk_windup, 0.0, 1.0)   # 0→1
			var e := w * w                                               # ease-in
			_node.position = _base_pos - _atk_dir * (ATK_WINDBACK * e)
			var sq := 0.12 * e
			_node.scale = Vector3(_base_scale.x * (1.0 + sq * 0.5),
				_base_scale.y * (1.0 - sq), _base_scale.z * (1.0 + sq * 0.5))
			_node.rotation.z = _base_rot_z
			return
		elif _strike_t > 0.0:
			# Strike — ease-out lunge toward target + stretch, settling to base.
			_strike_t -= delta
			var s := clampf(_strike_t / ATK_STRIKE_SEC, 0.0, 1.0)        # 1→0
			_node.position = _base_pos + _atk_dir * (ATK_LUNGE * s)
			var st := 0.14 * s
			_node.scale = Vector3(_base_scale.x * (1.0 - st * 0.5),
				_base_scale.y * (1.0 + st), _base_scale.z * (1.0 - st * 0.5))
			_node.rotation.z = _base_rot_z
			return
		else:
			_attacking = false   # done — fall through to idle/moving (restores base)
	if moving:
		_phase += delta * _move_rate
		_node.position = _base_pos + Vector3(0.0, absf(sin(_phase)) * _move_bob, 0.0)
		_node.scale = _node.scale.lerp(_base_scale, clampf(delta * 6.0, 0.0, 1.0))
		_node.rotation.z = lerp_angle(_node.rotation.z, _base_rot_z,
			clampf(delta * 6.0, 0.0, 1.0))
		_lean = lerpf(_lean, LEAN_ANGLE, clampf(delta * 8.0, 0.0, 1.0))  # lean into travel
	else:
		_breath += delta * _idle_rate
		var b := sin(_breath) * IDLE_BREATH
		_node.position = _base_pos + Vector3(0.0, maxf(0.0, b) * 0.35, 0.0)
		_node.scale = Vector3(
			_base_scale.x * (1.0 - b * 0.5),
			_base_scale.y * (1.0 + b),
			_base_scale.z * (1.0 - b * 0.5))
		_node.rotation.z = _base_rot_z + sin(_breath * 0.7) * IDLE_SWAY
		_lean = lerpf(_lean, 0.0, clampf(delta * 8.0, 0.0, 1.0))         # straighten at rest
	_node.rotation.x = _base_rot_x + _lean

# Back-out easing (overshoot past 1.0 then settle) for the spawn pop-in.
func _back_out(t: float) -> float:
	var c := 1.70158
	var u := t - 1.0
	return 1.0 + u * u * ((c + 1.0) * u + c)
