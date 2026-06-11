extends RefCounted

# Spec 18/23 — state-driven procedural animation for the Ranger.
# The baked GLB clips are broken, so every pose is computed here and applied
# to the skeleton each frame. Owned + ticked by player_controller with the
# current movement state ("idle"/"walk"/"run"/"dash"/"roll"); the roll
# *tumble* is the player_controller's job (it spins the whole Mesh node).

const SWING := 0.55         # rad — thigh fore/aft swing
const KNEE := 0.7           # rad — lower-leg bend
const ARM_SWING := 0.4      # rad — arm counter-swing
const WALK_CYCLE := 7.0     # phase rad/sec — walk
const RUN_CYCLE := 12.0     # phase rad/sec — run
const FIRE_POSE_TIME := 0.28

var _skel: Skeleton3D
var _bone := {}
var _rest := {}
var _phase := 0.0
var _amp := 0.0             # leg-cycle amplitude, eases 0↔1
var _lean := 0.0            # spine forward lean
var _fire_t := 0.0

func setup(skel: Skeleton3D) -> void:
	_skel = skel
	if skel == null:
		return
	for n in ["LeftUpLeg", "RightUpLeg", "LeftLeg", "RightLeg",
			"LeftArm", "RightArm", "Spine"]:
		var idx := skel.find_bone(n)
		if idx >= 0:
			_bone[n] = idx
			_rest[n] = skel.get_bone_rest(idx).basis.get_rotation_quaternion()

# A fire press — runs a brief upper-body draw pose over the locomotion.
func trigger_fire() -> void:
	_fire_t = FIRE_POSE_TIME

func update(delta: float, state: String) -> void:
	if _skel == null:
		return
	_fire_t = maxf(0.0, _fire_t - delta)

	var cycling := state == "walk" or state == "run"
	_amp = lerpf(_amp, 1.0 if cycling else 0.0, minf(1.0, delta * 9.0))
	if cycling:
		_phase += delta * (WALK_CYCLE if state == "walk" else RUN_CYCLE)

	# Spine lean — leaning hard into a dash, a touch into a run.
	var lean_target := 0.0
	if state == "dash":
		lean_target = 0.5
	elif state == "run":
		lean_target = 0.16
	_lean = lerpf(_lean, lean_target, minf(1.0, delta * 12.0))
	_pose("Spine", _lean)

	# Legs.
	if state == "roll":
		_pose("LeftUpLeg", 1.1)
		_pose("RightUpLeg", 1.1)
		_pose("LeftLeg", 1.2)
		_pose("RightLeg", 1.2)
	elif state == "dash":
		_pose("LeftUpLeg", 0.6)
		_pose("RightUpLeg", -0.5)
		_pose("LeftLeg", 0.3)
		_pose("RightLeg", 0.2)
	else:
		var sw := SWING * _amp
		_pose("LeftUpLeg", sin(_phase) * sw)
		_pose("RightUpLeg", sin(_phase + PI) * sw)
		_pose("LeftLeg", maxf(0.0, -sin(_phase)) * KNEE * _amp)
		_pose("RightLeg", maxf(0.0, -sin(_phase + PI)) * KNEE * _amp)

	# Arms — a fire draw pose overrides; else counter-swing / tuck.
	if _fire_t > 0.0:
		_pose("LeftArm", -1.0)
		_pose("RightArm", -1.0)
	elif state == "dash" or state == "roll":
		_pose("LeftArm", 0.4)
		_pose("RightArm", 0.4)
	else:
		_pose("LeftArm", sin(_phase + PI) * ARM_SWING * _amp)
		_pose("RightArm", sin(_phase) * ARM_SWING * _amp)

# One-shot collapsed heap pose for death (spec 23 — crumple). Called once;
# player_controller stops ticking update() while dead, so the pose holds.
func collapse() -> void:
	_pose("LeftUpLeg", 1.35)
	_pose("RightUpLeg", 1.35)
	_pose("LeftLeg", 1.5)
	_pose("RightLeg", 1.5)
	_pose("Spine", 0.6)
	_pose("LeftArm", 0.8)
	_pose("RightArm", 0.8)

func _pose(name: String, angle: float) -> void:
	if not _bone.has(name):
		return
	var q := Quaternion(Vector3.RIGHT, angle)
	_skel.set_bone_pose_rotation(_bone[name], _rest[name] * q)
