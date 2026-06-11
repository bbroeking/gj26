class_name GlbFit
extends RefCounted

# Wyrd — GLB sizing helper. Meshy/AI GLBs arrive at wildly different native
# sizes AND carry internal node transforms, so a naive get_aabb() merge
# under-measures them. merged_aabb walks the tree accumulating each node's
# transform; normalize_height scales the root so the whole visual stands
# target_h meters tall.

static func normalize_height(root: Node3D, target_h: float) -> void:
	var aabb := merged_aabb(root, Transform3D.IDENTITY)
	if aabb.size.y > 0.01:
		root.scale = root.scale * (target_h / aabb.size.y)

# Meshy GLB materials carry a metallic value the Compatibility renderer
# blows out into chrome — zero it so they render matte (layout_loader's
# _unmetal, shared).
static func unmetal(root: Node) -> void:
	if root is MeshInstance3D:
		var m: Mesh = (root as MeshInstance3D).mesh
		if m != null:
			for s in range(m.get_surface_count()):
				var mat := m.surface_get_material(s)
				if mat is BaseMaterial3D:
					(mat as BaseMaterial3D).metallic = 0.0
					(mat as BaseMaterial3D).metallic_specular = 0.2
	for c in root.get_children():
		unmetal(c)

static func merged_aabb(node: Node, xform: Transform3D) -> AABB:
	var local := xform
	if node is Node3D:
		local = xform * (node as Node3D).transform
	var aabb := AABB()
	var has := false
	if node is VisualInstance3D:
		aabb = local * (node as VisualInstance3D).get_aabb()
		has = true
	for c in node.get_children():
		var child := merged_aabb(c, local)
		if child.size != Vector3.ZERO:
			aabb = child if not has else aabb.merge(child)
			has = true
	return aabb
