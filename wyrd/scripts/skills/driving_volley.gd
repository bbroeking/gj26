class_name DrivingVolley
extends ProjectileSkill

# Pale Oath — Huntcraft 18. Five light arrows form a close, driving fan. The
# ordinary Arrow scene remains the single owner of damage; this module adds a
# host-only collision query that applies the special, once-per-cast pressure
# through Combatant's guarded path.

const ARROW_SPEED := 50.0 # mirrors arrow.gd; keep the contact query aligned.
const CONTACT_RANGE := 8.0
const CONTACT_MASK := 1 | 8 # world blockers + Combatant hurtboxes
static var _next_cast_id := 1


func _init() -> void:
	name = "DrivingVolley"
	cost = 26.0
	base_cd = 6.0
	damage_mult = 0.4
	projectile_count = 5
	spread_deg = 60.0
	skill_type = "driving_volley"
	recoil_amount = -0.52
	bow_pop_mult = 1.30
	sfx_key = "skill_multi"


# A pure lesson decision for Game/Town to persist as its own tutorial event.
# It deliberately never replaces a configured pick: the caller may grant and
# equip only when `equip_now` is true, otherwise retain the deferred lesson.
static func lesson_loadout_plan(loadout: Array, already_owned: bool) -> Dictionary:
	var current: Array = loadout.duplicate()
	if already_owned or current.has("DrivingVolley"):
		return {"state": "already_taught", "equip_now": false, "loadout": current}
	if current.size() >= 3:
		return {"state": "deferred", "equip_now": false, "loadout": current}
	current.append("DrivingVolley")
	return {"state": "ready", "equip_now": true, "loadout": current}


func fire(player: Node) -> void:
	if player == null:
		return
	var dir: Vector3 = player.aim_dir() if player.has_method("aim_dir") else Vector3.FORWARD
	var origin: Vector3 = player.arrow_origin(dir) if player.has_method("arrow_origin") \
		else (player as Node3D).global_position + Vector3(0.0, 1.0, 0.0)
	var directions := _fan_directions(dir)
	var cast_id := _next_cast_id
	_next_cast_id += 1
	if _next_cast_id <= 0:
		_next_cast_id = 1
	var host := player.get_parent()
	if host != null and _host_owns_outcomes(player):
		var tracker := VolleyImpactTracker.new()
		tracker.name = "DrivingVolleyTracker"
		host.add_child(tracker)
		tracker.configure(origin, directions, cast_id)
	var dmg := int(round(float(player.derived_stats.damage) * damage_mult))
	for i in directions.size():
		_spawn_arrow(player, origin, directions[i], dmg, i == directions.size() / 2)
	if player.has_method("apply_recoil"):
		player.apply_recoil(recoil_amount)
	if player.has_method("bow_pop"):
		player.bow_pop(bow_pop_mult)
	var sfx := player.get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.play(sfx_key)


func _fan_directions(axis: Vector3) -> Array:
	var out: Array = []
	var half := deg_to_rad(spread_deg) * 0.5
	var step := deg_to_rad(spread_deg) / float(projectile_count - 1)
	for i in projectile_count:
		out.append(axis.rotated(Vector3.UP, -half + step * i).normalized())
	return out


func _host_owns_outcomes(player: Node) -> bool:
	var net := player.get_node_or_null("/root/NetGame")
	return net == null or not bool(net.active) or bool(net.is_host())


class VolleyImpactTracker extends Node3D:
	var _origin := Vector3.ZERO
	var _directions: Array = []
	var _travelled: Array = []
	var _finished: Array = []
	var _cast_id := 0

	func configure(origin: Vector3, directions: Array, cast_id: int) -> void:
		_origin = origin
		_directions = directions.duplicate()
		_cast_id = cast_id
		for _i in _directions.size():
			_travelled.append(0.0)
			_finished.append(false)

	func _physics_process(delta: float) -> void:
		if _cast_id <= 0 or get_world_3d() == null:
			queue_free()
			return
		var all_finished := true
		for i in _directions.size():
			if bool(_finished[i]):
				continue
			all_finished = false
			var previous: float = float(_travelled[i])
			var next: float = minf(CONTACT_RANGE, previous + ARROW_SPEED * delta)
			var query := PhysicsRayQueryParameters3D.create(
				_origin + (_directions[i] as Vector3) * previous,
				_origin + (_directions[i] as Vector3) * next, CONTACT_MASK)
			query.collide_with_areas = true
			query.collide_with_bodies = true
			var hit := get_world_3d().direct_space_state.intersect_ray(query)
			_travelled[i] = next
			if not hit.is_empty():
				_finished[i] = true # a wall or a hurtbox blocks this arrow lane.
				var collider = hit.get("collider")
				if collider is Area3D and collider.has_meta("combatant"):
					var target = collider.get_meta("combatant")
					if is_instance_valid(target) and target.has_method("apply_driving_volley_impact"):
						target.apply_driving_volley_impact(_cast_id, _directions[i])
			elif next >= CONTACT_RANGE:
				_finished[i] = true
		if all_finished:
			queue_free()
