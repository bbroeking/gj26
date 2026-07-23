class_name AmbientPoseDriver
extends Node

# Keeps a stationary character alive without making it march in place. The
# town cast currently shares Meshy walk sidecars but has no authored idle
# sidecars. We hold a planted section of the walk and ease through enough of
# the rig to read as breathing, cloth settling, and a change of weight at the
# game's FATE camera. A small whole-body sway keeps the motion visible without
# moving the interaction target away from its authored work area.

var _player: AnimationPlayer = null
var _clip := ""
var _center := 0.0
var _window := 0.0
var _cycle_seconds := 4.0
var _elapsed := 0.0
var _visual_root: Node3D = null
var _base_position := Vector3.ZERO
var _base_rotation := Vector3.ZERO
var _motion_active := true


func setup(player: AnimationPlayer, clip: String, visual_root: Node3D,
		center_fraction := 0.5, window_fraction := 0.055,
		cycle_seconds := 3.8, phase_fraction := 0.0) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = player
	_clip = clip
	_cycle_seconds = maxf(1.0, cycle_seconds)
	_visual_root = visual_root
	_elapsed = clampf(phase_fraction, 0.0, 1.0) * _cycle_seconds
	if _visual_root != null:
		_base_position = _visual_root.position
		_base_rotation = _visual_root.rotation
	add_to_group("ambient_character_motion")
	if _player == null or _clip == "" or not _player.has_animation(_clip):
		set_process(false)
		return
	var animation := _player.get_animation(_clip)
	if animation == null or animation.length <= 0.0:
		set_process(false)
		return
	_center = animation.length * clampf(center_fraction, 0.0, 1.0)
	_window = animation.length * clampf(window_fraction, 0.0, 0.08)
	_player.play(_clip)
	_player.seek(_center, true)
	set_process(true)


func set_motion_active(active: bool) -> void:
	if _motion_active == active:
		return
	_motion_active = active
	if _player == null or not is_instance_valid(_player) \
			or _clip == "" or not _player.has_animation(_clip):
		return
	if active:
		_player.play(_clip)
		_player.seek(_center, true)
	elif _visual_root != null and is_instance_valid(_visual_root):
		_visual_root.position = _base_position
		_visual_root.rotation = _base_rotation


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player) \
			or _clip == "" or not _player.has_animation(_clip):
		queue_free()
		return
	if not _motion_active:
		return
	if _player.current_animation != _clip:
		_player.play(_clip)
	_elapsed += delta
	var phase := sin((_elapsed / _cycle_seconds) * TAU)
	_player.seek(_center + phase * _window, true)
	if _visual_root != null and is_instance_valid(_visual_root):
		# The skeleton supplies the authored limb motion. This restrained layer
		# makes it legible at 1280x720 while leaving feet and collision planted.
		var breath := sin((_elapsed / _cycle_seconds) * TAU)
		var settle := sin((_elapsed / (_cycle_seconds * 1.7)) * TAU)
		_visual_root.position = _base_position + Vector3(0.0,
			maxf(0.0, breath) * 0.018, 0.0)
		_visual_root.rotation = _base_rotation + Vector3(
			settle * 0.012, breath * 0.018, settle * 0.014)
