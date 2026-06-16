extends RefCounted

# Procedural creature animator (supersedes rat_anim's role for the whole cast).
# Meshy can't rig our posed/quadruped/amorphous enemies, so motion is faked in
# code: a gentle idle breathing + sway so NOTHING stands frozen in bind pose,
# and a hop-bob + settle when moving. Owned by the Combatant as `_proc_anim`,
# ticked from its AI update with (delta, moving).
#
# It writes the MESH node's transform only (position.y / scale / rotation.z) —
# the Combatant body's scale-punch hit/attack feedback writes the BODY, so the
# two compose (child × parent) and never overwrite each other.

const IDLE_BREATH := 0.028   # ±2.8% vertical squash/stretch at rest (breathing)
const IDLE_SWAY := 0.05      # rad — gentle roll at rest
const IDLE_RATE := 2.0       # breaths/sway phase rad/sec

var _node: Node3D
var _base_y := 0.0
var _base_scale := Vector3.ONE
var _base_rot_z := 0.0
var _phase := 0.0            # bob phase (moving)
var _breath := 0.0           # breathing/sway phase
var _move_bob := 0.05
var _move_rate := 9.0
var _idle_rate := IDLE_RATE

func setup(node: Node3D, move_bob: float = 0.05, move_rate: float = 9.0,
		idle_rate: float = IDLE_RATE) -> void:
	_node = node
	_move_bob = move_bob
	_move_rate = move_rate
	_idle_rate = idle_rate
	# A per-creature phase offset so a room full of foes doesn't breathe in
	# lockstep — derived from the node's spawn position (deterministic, no RNG).
	if node != null:
		_base_y = node.position.y
		_base_scale = node.scale
		_base_rot_z = node.rotation.z
		_breath = absf(node.global_position.x + node.global_position.z) * 1.7

func update(delta: float, moving: bool) -> void:
	if _node == null:
		return
	if moving:
		_phase += delta * _move_rate
		_node.position.y = _base_y + absf(sin(_phase)) * _move_bob
		# Settle breathing squash + sway back to neutral while in motion.
		_node.scale = _node.scale.lerp(_base_scale, clampf(delta * 6.0, 0.0, 1.0))
		_node.rotation.z = lerp_angle(_node.rotation.z, _base_rot_z,
			clampf(delta * 6.0, 0.0, 1.0))
	else:
		_breath += delta * _idle_rate
		var b := sin(_breath) * IDLE_BREATH
		_node.position.y = _base_y + maxf(0.0, b) * 0.35   # tiny lift on the in-breath
		_node.scale = Vector3(
			_base_scale.x * (1.0 - b * 0.5),
			_base_scale.y * (1.0 + b),
			_base_scale.z * (1.0 - b * 0.5))
		_node.rotation.z = _base_rot_z + sin(_breath * 0.7) * IDLE_SWAY
