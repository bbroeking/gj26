class_name Stonewake
extends Node3D

# Shared visual/audio language for good Stonewake and bad Stone's Rebuke.
# The ring always telegraphs for at least a second.  Good never queries or
# hurts a player; bad includes the player in the same resolve pass.

signal telegraphed(duration: float)
signal resolved(rebuke: bool)

var rebuke := false
var radius := 4.0
var telegraph_seconds := 1.10
var _ring: MeshInstance3D = null
var _cycle: Tween = null


func setup(is_rebuke: bool, p_radius: float = 4.0) -> void:
	rebuke = is_rebuke
	radius = p_radius


func begin_cycle() -> void:
	if _ring != null:
		return
	_ring = _make_ring()
	add_child(_ring)
	telegraphed.emit(telegraph_seconds)
	var sfx := get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.play("telegraph")
	_cycle = create_tween()
	_cycle.tween_interval(telegraph_seconds)
	_cycle.tween_callback(_resolve)


func _exit_tree() -> void:
	if _cycle != null and _cycle.is_valid():
		_cycle.kill()


func _resolve() -> void:
	if _ring != null:
		_ring.queue_free()
		_ring = null
	for foe in get_tree().get_nodes_in_group("enemy"):
		if foe is Node3D and (foe as Node3D).global_position.distance_to(global_position) <= radius:
			_apply_poise_and_push(foe as Node3D)
	if rebuke:
		for player in get_tree().get_nodes_in_group("player"):
			if player is Node3D and (player as Node3D).global_position.distance_to(global_position) <= radius:
				_apply_poise_and_push(player as Node3D)
	resolved.emit(rebuke)


func _apply_poise_and_push(target: Node3D) -> void:
	var away := target.global_position - global_position
	away.y = 0.0
	if away.length_squared() < 0.01:
		away = Vector3.FORWARD
	away = away.normalized()
	if target.has_method("apply_stonewake_poise"):
		target.call("apply_stonewake_poise", 18)
	else:
		target.set_meta("stonewake_poise", int(target.get_meta("stonewake_poise", 0)) + 18)
	if target is CharacterBody3D:
		(target as CharacterBody3D).velocity += away * 7.0


func _make_ring() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "StonewakeTelegraph"
	var ring := TorusMesh.new()
	ring.inner_radius = radius * 0.88
	ring.outer_radius = radius
	mi.mesh = ring
	mi.position.y = 0.08
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.64, 0.74, 0.82, 0.72)
	mat.emission_enabled = true
	mat.emission = Color(0.42, 0.64, 0.88)
	mat.emission_energy_multiplier = 1.6
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	return mi
