extends SkeletonModifier3D

# Phase 4 (Plan.md) — a procedural bow-draw for the chibi. The chibi plays
# AnimationPlayer locomotion clips (legs/idle), so this modifier runs AFTER the
# AnimationPlayer in the skeleton's modification stack and BLENDS the arm bones
# toward a raised draw-and-loose pose by `draw_amount` (0..1, driven by
# player_controller on each shot). At 0 it's a no-op and the clip plays
# untouched, so the legs keep cycling while the arms loose the bow.
#
# The pose angle is ported from the (otherwise unused) ranger_anim fire pose.

const DRAW_ANGLE := -1.0   # rad about the bone's X — raise the arm (ranger fire pose)

var draw_amount := 0.0
var _arms: Array = []      # [{idx:int, target:Quaternion}], skipped if a bone is absent

func _ready() -> void:
	var sk := get_skeleton()
	if sk == null:
		return
	var draw_q := Quaternion(Vector3.RIGHT, DRAW_ANGLE)
	for n in ["LeftArm", "RightArm"]:
		var idx := sk.find_bone(n)
		if idx >= 0:
			var rest := sk.get_bone_rest(idx).basis.get_rotation_quaternion()
			_arms.append({"idx": idx, "target": rest * draw_q})

func _process_modification() -> void:
	if draw_amount <= 0.001 or _arms.is_empty():
		return
	var sk := get_skeleton()
	if sk == null:
		return
	var amt := clampf(draw_amount, 0.0, 1.0)
	for a in _arms:
		var cur := sk.get_bone_pose_rotation(int(a.idx))
		sk.set_bone_pose_rotation(int(a.idx), cur.slerp(a.target, amt))
