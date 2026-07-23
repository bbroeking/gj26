class_name NpcAttention
extends Node

# Gives the town cast a social read: nearby NPCs turn toward the local player,
# and Mara keeps the new arrival in view throughout onboarding. This node runs
# while dialogue and storybook vignettes pause gameplay so the people in the
# live scene do not freeze into display-piece poses behind the UI.

var _actor: Node3D
var _attention_radius := 9.0
var _always_during_onboarding := false
var _turn_speed := 5.0
var _home_yaw := 0.0


func setup(actor: Node3D, attention_radius := 9.0,
		always_during_onboarding := false, turn_speed := 5.0) -> void:
	_actor = actor
	_attention_radius = maxf(1.0, attention_radius)
	_always_during_onboarding = always_during_onboarding
	_turn_speed = maxf(1.0, turn_speed)
	_home_yaw = actor.rotation.y if actor != null else 0.0
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _actor != null:
		_actor.add_to_group("player_facing_npc")


func face_now(player: Node) -> void:
	if _actor == null or not is_instance_valid(_actor) or not player is Node3D:
		return
	var direction := (player as Node3D).global_position - _actor.global_position
	direction.y = 0.0
	if direction.length_squared() > 0.001:
		_actor.rotation.y = atan2(direction.x, direction.z)


func _process(delta: float) -> void:
	if _actor == null or not is_instance_valid(_actor):
		queue_free()
		return
	if bool(_actor.get_meta("npc_walking", false)):
		return
	var game := get_node_or_null("/root/Game")
	var player: Node = game.local_player() if game != null \
		and game.has_method("local_player") else null
	if not player is Node3D:
		return
	var direction := (player as Node3D).global_position - _actor.global_position
	direction.y = 0.0
	var onboarding := game != null and int(game.get("tutorial_step")) < 7
	var attentive := direction.length_squared() \
		<= _attention_radius * _attention_radius \
		or (_always_during_onboarding and onboarding)
	var wanted := atan2(direction.x, direction.z) \
		if attentive and direction.length_squared() > 0.001 else _home_yaw
	_actor.rotation.y = lerp_angle(_actor.rotation.y, wanted,
		clampf(_turn_speed * delta, 0.0, 1.0))
