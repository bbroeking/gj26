class_name AnimDriver
extends RefCounted

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
			ap.play(clip, 0.2)
	else:
		var idle := _find_clip(ap, "idle")
		if idle != "":
			if ap.current_animation != idle:
				_loopify(ap, idle)
				ap.play(idle, 0.2)
		elif ap.is_playing():
			ap.stop()

static func _loopify(ap: AnimationPlayer, clip: String) -> void:
	# glTF animations import non-looping; idle/walk should loop.
	var anim := ap.get_animation(clip)
	if anim != null:
		anim.loop_mode = Animation.LOOP_LINEAR
