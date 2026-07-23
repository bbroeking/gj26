class_name NpcWander
extends Node

# A deliberately small authored round for town NPCs. The interaction Area moves
# with the person, while their walk sidecar supplies the actual gait. At each
# stop NpcAttention takes over and turns them toward the nearby player.

const AnimDriverScript := preload("res://scripts/anim_driver.gd")

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


func setup(actor: Node3D, visual: Node, walk_sidecar: PackedScene,
		local_round: Array[Vector3], speed := 0.72) -> void:
	_actor = actor
	_visual = visual
	_speed = maxf(0.2, speed)
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
	_player = AnimDriverScript.find_anim_player(_visual)
	_walk_clip = AnimDriverScript.install_sidecar_clip(
		_visual, walk_sidecar, "walk", "town_walk")
	_ambient = _visual.get_node_or_null("AmbientPoseDriver")
	_set_walking(_points.size() > 1 and _walk_clip != "")


func pause_for_attention(seconds := 4.0) -> void:
	_attention_pause = maxf(_attention_pause, seconds)
	_set_walking(false)


func _process(delta: float) -> void:
	if _actor == null or not is_instance_valid(_actor):
		queue_free()
		return
	if _attention_pause > 0.0:
		_attention_pause = maxf(0.0, _attention_pause - delta)
		_set_walking(false)
		return
	if _points.size() < 2 or _walk_clip == "":
		_set_walking(false)
		return
	if _pause_left > 0.0:
		_pause_left = maxf(0.0, _pause_left - delta)
		_set_walking(false)
		return
	var target := _points[_point_index]
	var delta_position := target - _actor.global_position
	delta_position.y = 0.0
	if delta_position.length() <= 0.12:
		_point_index = (_point_index + 1) % _points.size()
		_pause_left = 1.15
		_set_walking(false)
		return
	var direction := delta_position.normalized()
	_actor.global_position = _actor.global_position.move_toward(
		target, _speed * delta)
	_actor.rotation.y = lerp_angle(_actor.rotation.y,
		atan2(direction.x, direction.z), clampf(delta * 8.0, 0.0, 1.0))
	_set_walking(true)


func _set_walking(active: bool) -> void:
	_actor.set_meta("npc_walking", active)
	if _walking == active:
		return
	_walking = active
	if _ambient != null and _ambient.has_method("set_motion_active"):
		_ambient.set_motion_active(not active)
	if active and _player != null and _walk_clip != "":
		_player.play(_walk_clip, 0.12)
		_player.speed_scale = 0.82
