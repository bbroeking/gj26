class_name OathboundGuard
extends "res://scripts/combatant.gd"

# Combat actor for the Blender-authored Oathbound family.  The imported GLB is
# a real skinned rig with Idle/Walk/Attack/Hit/Shield/Reeling/Relief/Defeat
# clips; this script remains the sole owner of vow and relief game truth.

signal reeled(guard_index: int)

var guard_index := 0
var reeling := false
var vow_active := false
var _active_collision_layer := 0
var _active_collision_mask := 0
var _collision_contract_captured := false


func _play_visual_clip(fragment: String) -> void:
	var player := AnimDriverScript.find_anim_player(self)
	if player == null:
		return
	for clip in player.get_animation_list():
		if String(clip).to_lower().contains(fragment.to_lower()):
			if player.current_animation != String(clip):
				player.play(String(clip), 0.08)
			return


func arm_vow(index: int) -> void:
	guard_index = index
	vow_active = true
	reeling = false
	hp = hp_max
	visible = true
	set_process(true)
	set_physics_process(true)
	_set_encounter_collision_enabled(true)
	set_meta("pale_oath_state", "armed")
	_play_visual_clip("shield")


func set_vow_dormant() -> void:
	vow_active = false
	reeling = false
	velocity = Vector3.ZERO
	_state = State.IDLE
	_clear_all_statuses()
	visible = false
	set_process(false)
	set_physics_process(false)
	_set_encounter_collision_enabled(false)
	set_meta("pale_oath_state", "dormant")


func relieve() -> bool:
	if not reeling:
		return false
	vow_active = false
	reeling = false
	velocity = Vector3.ZERO
	_state = State.IDLE
	_clear_all_statuses()
	_play_visual_clip("relief")
	visible = false
	set_process(false)
	set_physics_process(false)
	_set_encounter_collision_enabled(false)
	set_meta("pale_oath_state", "relieved")
	return true


# A woken Oathbound accepts ordinary Combatant damage resolution so crits,
# marked damage, and every Skill share one path.  The base-class floor hook
# below handles the post-multiplier amount; this gate only keeps dormant,
# relieved, and already-Reeling guards inert.
func take_damage(amount: int, from_dir: Vector3,
		crit_chance: float = -1.0, crit_mult_bonus: float = -1.0) -> void:
	if dead or not vow_active or reeling:
		return
	super(amount, from_dir, crit_chance, crit_mult_bonus)
	if not reeling:
		_play_visual_clip("hit")


# The Oathbound can never enter Combatant._die.  This covers direct weapon
# hits, resolved crit/marked amplification, status ticks, and net snapshots.
func _damage_floor() -> int:
	return 1


func _on_damage_floor_reached() -> void:
	if not vow_active or reeling:
		return
	reeling = true
	velocity = Vector3.ZERO
	_state = State.IDLE
	# Reeling is a bell-interaction state, not an invisible enemy turn.  The
	# body remains collidable/readable, but no AI, movement, or status ticking
	# can continue while the player rings the matching bell.
	set_process(false)
	set_physics_process(false)
	set_meta("pale_oath_state", "reeling")
	_play_visual_clip("reeling")
	reeled.emit(guard_index)


func _set_encounter_collision_enabled(enabled: bool) -> void:
	if not _collision_contract_captured:
		_active_collision_layer = collision_layer
		_active_collision_mask = collision_mask
		_collision_contract_captured = true
	collision_layer = _active_collision_layer if enabled else 0
	collision_mask = _active_collision_mask if enabled else 0
	var hurt := get_node_or_null("Hurtbox") as Area3D
	if hurt != null:
		hurt.collision_layer = LAYER_HURTBOX if enabled else 0
		hurt.collision_mask = 0
		hurt.monitorable = enabled
		hurt.monitoring = false
	_set_collision_shapes_enabled(self, enabled)


func _set_collision_shapes_enabled(node: Node, enabled: bool) -> void:
	for child in node.get_children():
		if child is CollisionShape3D:
			(child as CollisionShape3D).set_deferred("disabled", not enabled)
		_set_collision_shapes_enabled(child, enabled)
