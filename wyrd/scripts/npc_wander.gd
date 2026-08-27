class_name NpcWander
extends Node

# A deliberately small authored round for town NPCs. The interaction Area moves
# with the person, while their walk sidecar supplies the actual gait. At each
# stop NpcAttention takes over and turns them toward the nearby player.

const AnimDriverScript := preload("res://scripts/anim_driver.gd")
const WAYPOINT_RADIUS := 0.18
const TURN_LOOKAHEAD := 0.55
const STEERING_RESPONSE := 5.5
const SPEED_RESPONSE := 2.8

var _actor: Node3D
var _visual: Node
var _player: AnimationPlayer
var _ambient: Node
var _points: Array[Vector3] = []
var _point_index := 0
var _speed := 0.72
var _pause_left := 0.0
var _attention_pause := 0.0
var _walking := false
var _walk_clip := ""
var _cinematic_motion := false
var _move_direction := Vector3.ZERO
var _current_speed := 0.0
var _stride_phase := 0.0


func setup(actor: Node3D, visual: Node, walk_sidecar: PackedScene,
		local_round: Array[Vector3], speed := 0.72,
		stride_phase := 0.0) -> void:
	_actor = actor
	_visual = visual
	_speed = maxf(0.2, speed)
	_stride_phase = fposmod(stride_phase, 1.0)
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _actor == null or _visual == null:
		set_process(false)
		return
	_actor.add_to_group("wandering_npc")
	var home := _actor.global_position
	_points.append(home)
	for offset in local_round:
		_points.append(home + offset)
	_point_index = 1 if _points.size() > 1 else 0
	if _points.size() > 1:
		_move_direction = (_points[_point_index] - home).normalized()
	_current_speed = _speed
	_player = AnimDriverScript.find_anim_player(_visual)
	_walk_clip = AnimDriverScript.install_sidecar_clip(
		_visual, walk_sidecar, "walk", "town_walk")
	_ambient = _visual.get_node_or_null("AmbientPoseDriver")
	_set_walking(_points.size() > 1 and _walk_clip != "")


func pause_for_attention(seconds := 4.0) -> void:
	if _cinematic_motion:
		return
	_attention_pause = maxf(_attention_pause, seconds)
	_set_walking(false)

func set_cinematic_motion(active: bool) -> void:
	_cinematic_motion = active
	if active:
		_attention_pause = 0.0
		_pause_left = 0.0
		_set_walking(_points.size() > 1 and _walk_clip != "")

func _process(delta: float) -> void:
	if _actor == null or not is_instance_valid(_actor):
		queue_free()
		return
	if not _cinematic_motion and _attention_pause > 0.0:
		_attention_pause = maxf(0.0, _attention_pause - delta)
		_current_speed = 0.0
		_set_walking(false)
		return
	if _points.size() < 2 or _walk_clip == "":
		_set_walking(false)
		return
	if not _cinematic_motion and _pause_left > 0.0:
		_pause_left = maxf(0.0, _pause_left - delta)
		_current_speed = 0.0
		_set_walking(false)
		return
	var target := _points[_point_index]
	var delta_position := target - _actor.global_position
	delta_position.y = 0.0
	if delta_position.length() <= WAYPOINT_RADIUS:
		_point_index = (_point_index + 1) % _points.size()
		target = _points[_point_index]
		delta_position = target - _actor.global_position
		delta_position.y = 0.0
	var direction := delta_position.normalized()
	# Begin bending toward the following leg before reaching the waypoint.
	# This keeps translation and facing on one continuous arc instead of
	# arriving, swivelling in place, then departing.
	var next_index := (_point_index + 1) % _points.size()
	var next_leg := _points[next_index] - target
	next_leg.y = 0.0
	var distance_to_target := delta_position.length()
	if distance_to_target < TURN_LOOKAHEAD and next_leg.length_squared() > 0.001:
		var lookahead_t := 1.0 - distance_to_target / TURN_LOOKAHEAD
		lookahead_t = lookahead_t * lookahead_t * (3.0 - 2.0 * lookahead_t)
		# Keep enough of the inbound leg to cross the waypoint plane; a full
		# blend can cut a tight corner so aggressively that it orbits the point.
		direction = direction.lerp(next_leg.normalized(),
			lookahead_t * 0.48).normalized()
	if _move_direction.length_squared() < 0.001:
		_move_direction = direction
	else:
		_move_direction = _move_direction.lerp(direction,
			clampf(delta * STEERING_RESPONSE, 0.0, 1.0)).normalized()
	var turn_amount := absf(_move_direction.signed_angle_to(direction, Vector3.UP))
	var turn_speed_scale := lerpf(1.0, 0.78, clampf(turn_amount / 1.2, 0.0, 1.0))
	_current_speed = move_toward(_current_speed, _speed * turn_speed_scale,
		SPEED_RESPONSE * delta)
	_actor.global_position += _move_direction * _current_speed * delta
	_actor.rotation.y = lerp_angle(_actor.rotation.y,
		atan2(_move_direction.x, _move_direction.z),
		clampf(delta * STEERING_RESPONSE, 0.0, 1.0))
	_set_walking(true)


func _set_walking(active: bool) -> void:
	_actor.set_meta("npc_walking", active)
	if _walking == active:
		return
	_walking = active
	if not active and _player != null \
			and _player.current_animation == _walk_clip:
		var current_clip := _player.get_animation(_walk_clip)
		if current_clip != null and current_clip.length > 0.0:
			_stride_phase = fposmod(
				_player.current_animation_position / current_clip.length, 1.0)
	if _ambient != null and _ambient.has_method("set_motion_active"):
		_ambient.set_motion_active(not active)
	if active and _player != null and _walk_clip != "":
		_player.play(_walk_clip, 0.12)
		_player.speed_scale = 0.82
		var walk := _player.get_animation(_walk_clip)
		if walk != null and walk.length > 0.0:
			_player.seek(_stride_phase * walk.length, true)
