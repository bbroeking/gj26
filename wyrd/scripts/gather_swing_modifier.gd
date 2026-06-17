extends SkeletonModifier3D

# Plan.md B1 — procedural gather arm-swing for the chibi player.
# Runs AFTER the AnimationPlayer in the skeleton's modification stack and
# blends LeftArm / RightArm toward a raised swing pose by `swing_amount`
# (0..1, driven by player_controller on each gather beat).  At 0 it is a
# no-op so the locomotion clip plays untouched — legs keep cycling while
# the arms mine / chop / pluck.
#
# Public API
#   swing_amount : float  — 0 = rest (no-op), 1 = full swing apex; the
#                           caller tweens this in a sawtooth per beat.
#   swing_angle  : float  — rotation magnitude (rad about bone's X-axis).
#                           Set by caller to MINE_ANGLE or FORAGE_ANGLE
#                           before starting the tween.
#   mode         : String — "mine" | "chop" | "forage" — convenience alias
#                           that writes swing_angle on assignment.  Optional;
#                           caller may also write swing_angle directly.
#
# Constants (inlined from data/feel.gd stubs until Plan.md B0 ships)
const MINE_ANGLE: float = -0.9    # rad — ore_rock / log_pile arc (strong swing)
const FORAGE_ANGLE: float = -0.5  # rad — forage_node pluck (gentle arc)

var swing_amount: float = 0.0
var swing_angle: float  = MINE_ANGLE

# Cache built in _ready; each entry: { idx: int, rest_q: Quaternion }
var _arms: Array = []

# ── mode convenience property ──────────────────────────────────────────────

var _mode: String = "mine"

var mode: String:
	get:
		return _mode
	set(value):
		_mode = value
		match value:
			"forage":
				swing_angle = FORAGE_ANGLE
			_:  # "mine", "chop", or anything else → heavy arc
				swing_angle = MINE_ANGLE

# ── lifecycle ──────────────────────────────────────────────────────────────

func _ready() -> void:
	var sk: Skeleton3D = get_skeleton()
	if sk == null:
		return
	for n: String in ["LeftArm", "RightArm"]:
		var idx: int = sk.find_bone(n)
		if idx >= 0:
			var rest_q: Quaternion = sk.get_bone_rest(idx).basis.get_rotation_quaternion()
			_arms.append({"idx": idx, "rest_q": rest_q})

# ── modification ───────────────────────────────────────────────────────────

func _process_modification() -> void:
	if swing_amount <= 0.001 or _arms.is_empty():
		return  # no-op — locomotion clip plays untouched
	var sk: Skeleton3D = get_skeleton()
	if sk == null:
		return
	var amt: float = clampf(swing_amount, 0.0, 1.0)
	# Recompute target each call so swing_angle changes mid-cycle take effect
	# immediately (mode may be changed by caller between beats).
	var swing_q: Quaternion = Quaternion(Vector3.RIGHT, swing_angle)
	for a: Dictionary in _arms:
		var bone_idx: int = int(a.idx)
		var rest_q: Quaternion = a.rest_q as Quaternion
		var target: Quaternion = rest_q * swing_q
		var cur: Quaternion = sk.get_bone_pose_rotation(bone_idx)
		sk.set_bone_pose_rotation(bone_idx, cur.slerp(target, amt))
