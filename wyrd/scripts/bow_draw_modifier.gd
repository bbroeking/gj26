extends SkeletonModifier3D

# Phase 4 (Plan.md) — a procedural bow-draw for the chibi. The chibi plays
# AnimationPlayer locomotion clips (legs/idle), so this modifier runs AFTER the
# AnimationPlayer in the skeleton's modification stack and BLENDS the arm bones
# toward a raised draw-and-loose pose by `draw_amount` (0..1, driven by
# player_controller on each shot). At 0 it's a no-op and the clip plays
# untouched, so the legs keep cycling while the arms loose the bow.
#
# The pose angle is ported from the (otherwise unused) ranger_anim fire pose.

# The bow arm and string arm do different jobs. The former stays long and
# forward; the latter folds at the elbow toward the cheek. Keeping this table
# beside the canonical rig names makes the pose explicit and testable.
const DRAW_BONES := [
	{"name": "LeftArm", "axis": Vector3.RIGHT, "angle": -0.92},
	{"name": "LeftForeArm", "axis": Vector3.RIGHT, "angle": -0.12},
	{"name": "RightArm", "axis": Vector3.RIGHT, "angle": -0.72},
	{"name": "RightForeArm", "axis": Vector3.FORWARD, "angle": -2.15},
]

var draw_amount := 0.0
var _pose_bones: Array = [] # [{idx:int, target:Quaternion}], absent bones are skipped

func _ready() -> void:
	var sk := get_skeleton()
	if sk == null:
		return
	for record_v in DRAW_BONES:
		var record := record_v as Dictionary
		var idx := sk.find_bone(String(record.name))
		if idx >= 0:
			var rest := sk.get_bone_rest(idx).basis.get_rotation_quaternion()
			var delta := Quaternion(record.axis as Vector3, float(record.angle))
			_pose_bones.append({"idx": idx, "target": rest * delta})

func _process_modification() -> void:
	if draw_amount <= 0.001 or _pose_bones.is_empty():
		return
	var sk := get_skeleton()
	if sk == null:
		return
	var amt := clampf(draw_amount, 0.0, 1.0)
	for a in _pose_bones:
		var cur := sk.get_bone_pose_rotation(int(a.idx))
		sk.set_bone_pose_rotation(int(a.idx), cur.slerp(a.target, amt))
