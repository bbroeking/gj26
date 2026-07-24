class_name AnimDriver
extends RefCounted

const AmbientPoseDriverScript := preload("res://scripts/ambient_pose_driver.gd")

# Spec 11 — animation helper for the Meshy-rigged cast.
# The rigged GLBs each carry one clip ("Armature|Idle|baselayer").
# Clip lookup is by case-insensitive substring so it survives Meshy
# naming its clips differently per model.

# Walk through a node subtree and return the first AnimationPlayer.
static func find_anim_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root
	for c in root.get_children():
		var found := find_anim_player(c)
		if found != null:
			return found
	return null

# First clip whose name contains `substr` (case-insensitive), or "".
static func _find_clip(ap: AnimationPlayer, substr: String) -> String:
	for clip_name in ap.get_animation_list():
		if String(clip_name).to_lower().contains(substr):
			return String(clip_name)
	return ""

# Start the idle clip, looped. Call once on spawn.
static func play_idle(root: Node) -> void:
	var ap := find_anim_player(root)
	if ap == null:
		return
	var clip := _find_clip(ap, "idle")
	if clip == "":
		var list := ap.get_animation_list()
		if list.is_empty():
			return
		clip = String(list[0])
	_loopify(ap, clip)
	ap.play(clip)
	# AnimationPlayer does not evaluate a newly played clip until its next
	# process tick. Force the authored pose now so the first rendered frame can
	# never expose Meshy's raw T-pose bind skeleton.
	ap.advance(0.0)

# Merge a same-rig sidecar and hold a natural pose from it. Meshy's automatic
# rig output is a T-pose clip; a paused mid-stride frame gives stationary town
# NPCs a relaxed, readable stance without making them march in place.
static func play_sidecar_pose(root: Node, sidecar: PackedScene,
		key: String, pose_fraction := 0.75, phase_fraction := 0.0,
		window_fraction := 0.02) -> void:
	var ap := find_anim_player(root)
	if ap == null or sidecar == null:
		play_idle(root)
		return
	var lib := ap.get_animation_library("")
	if lib == null:
		play_idle(root)
		return
	var source := sidecar.instantiate()
	var source_ap := find_anim_player(source)
	var pose: Animation = null
	if source_ap != null:
		for clip_name in source_ap.get_animation_list():
			if String(clip_name).to_lower().contains(key.to_lower()):
				pose = source_ap.get_animation(clip_name).duplicate()
				break
	source.free()
	if pose == null:
		play_idle(root)
		return
	const POSE_CLIP := "town_idle_pose"
	if lib.has_animation(POSE_CLIP):
		lib.remove_animation(POSE_CLIP)
	lib.add_animation(POSE_CLIP, pose)
	var existing := root.get_node_or_null("AmbientPoseDriver")
	if existing != null:
		existing.queue_free()
	var driver := AmbientPoseDriverScript.new()
	driver.name = "AmbientPoseDriver"
	root.add_child(driver)
	driver.setup(ap, POSE_CLIP, root as Node3D, pose_fraction, window_fraction, 3.8,
		phase_fraction)


# Add a complete same-rig sidecar clip to an existing model. Patrol drivers use
# this for actual locomotion while AmbientPoseDriver owns the planted pauses.
static func install_sidecar_clip(root: Node, sidecar: PackedScene,
		key: String, clip_name: String) -> String:
	var ap := find_anim_player(root)
	if ap == null or sidecar == null:
		return ""
	var lib := ap.get_animation_library("")
	if lib == null:
		return ""
	var source := sidecar.instantiate()
	var source_ap := find_anim_player(source)
	var animation: Animation = null
	if source_ap != null:
		for source_name in source_ap.get_animation_list():
			if String(source_name).to_lower().contains(key.to_lower()):
				animation = source_ap.get_animation(source_name).duplicate()
				break
	source.free()
	if animation == null:
		return ""
	animation.loop_mode = Animation.LOOP_LINEAR
	if lib.has_animation(clip_name):
		lib.remove_animation(clip_name)
	lib.add_animation(clip_name, animation)
	return clip_name

# Walk/idle switch with a short crossfade.
#   moving  → a "walk" clip (or "run" if there's no walk)
#   still   → an "idle" clip if one exists, else STOP (rest in bind pose)
# — so a character with only walk/run clips (the Ranger) doesn't fall back
# to running-in-place while standing still.
static func update(root: Node, moving: bool) -> void:
	var ap := find_anim_player(root)
	if ap == null:
		return
	if moving:
		var clip := _find_clip(ap, "walk")
		if clip == "":
			clip = _find_clip(ap, "run")
		if clip != "" and ap.current_animation != clip:
			_loopify(ap, clip)
			ap.play(clip, 0.08)
	else:
		var idle := _find_clip(ap, "idle")
		if idle != "":
			if ap.current_animation != idle:
				_loopify(ap, idle)
				ap.play(idle, 0.08)
				ap.advance(0.0)
		elif ap.is_playing():
			ap.stop()

static func _loopify(ap: AnimationPlayer, clip: String) -> void:
	# glTF animations import non-looping; idle/walk should loop.
	var anim := ap.get_animation(clip)
	if anim != null:
		anim.loop_mode = Animation.LOOP_LINEAR
