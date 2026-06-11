class_name AoeQuery
extends RefCounted

# Spec 31 — reusable AoE shape queries. Static helpers; no state. Returns
# a plain Array of Node3D combatants in the given group hit by the shape.
# All shapes are full-damage-inside / nothing-outside (no spatial falloff)
# per the genre research — all three reference games agree (FATE / D3 / PoE2).

# Every combatant inside a circle centred on `center` with the given radius.
# `tree` lets the caller pass the active SceneTree (script callers can hand
# theirs in directly).
static func query_circle(tree: SceneTree, center: Vector3, radius: float,
		group: String = "enemy") -> Array:
	var out: Array = []
	if tree == null:
		return out
	for n in tree.get_nodes_in_group(group):
		if not is_instance_valid(n) or not n is Node3D:
			continue
		if (n as Node3D).global_position.distance_to(center) < radius:
			out.append(n)
	return out

# Every combatant inside a cone — origin at the caster, opens toward `dir`
# (normalised), `range_m` deep, `half_angle_deg` to each side of the axis.
# Sketched in spec 31 for the future melee/cleave skill; no caller in v1.
static func query_cone(tree: SceneTree, origin: Vector3, dir: Vector3,
		range_m: float, half_angle_deg: float,
		group: String = "enemy") -> Array:
	var out: Array = []
	if tree == null or dir.length() < 0.001:
		return out
	var axis := dir.normalized()
	var cos_half := cos(deg_to_rad(half_angle_deg))
	for n in tree.get_nodes_in_group(group):
		if not is_instance_valid(n) or not n is Node3D:
			continue
		var to := (n as Node3D).global_position - origin
		to.y = 0.0
		var d := to.length()
		if d > range_m or d < 0.001:
			continue
		var cos_ang := to.normalized().dot(axis)
		if cos_ang >= cos_half:
			out.append(n)
	return out

# Caster-centred expanding circle. Spec 31 reserves the signature for the
# future Whisp Burst defensive skill; no in-game caller yet.
static func query_nova(tree: SceneTree, center: Vector3, radius: float,
		group: String = "enemy") -> Array:
	return query_circle(tree, center, radius, group)
