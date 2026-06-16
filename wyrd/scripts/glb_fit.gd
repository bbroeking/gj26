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

# The shared chunky ink silhouette (one source of truth for the rim across
# enemies, player, NPCs, and key props). A grown, front-culled, unshaded back
# shell hugging the model — "bold ink outlines". Chained as next_pass on a
# DUPLICATE of each surface's active material so the shared GLB resource isn't
# mutated; a materialless surface gets a neutral plate to host the rim.
const OUTLINE_INK := Color(0.13, 0.09, 0.06)
const OUTLINE_GROW := 0.05

static func ink_outline_pass() -> StandardMaterial3D:
	var o := StandardMaterial3D.new()
	o.grow = true
	o.grow_amount = OUTLINE_GROW
	o.cull_mode = BaseMaterial3D.CULL_FRONT
	o.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	o.albedo_color = OUTLINE_INK
	return o

static func add_ink_outline(root: Node) -> void:
	if root is MeshInstance3D:
		var mi := root as MeshInstance3D
		var mesh: Mesh = mi.mesh
		var painted := false
		if mesh != null:
			for s in range(mesh.get_surface_count()):
				var base := mi.get_active_material(s)
				if base is BaseMaterial3D:
					var dup := (base as BaseMaterial3D).duplicate() as BaseMaterial3D
					dup.next_pass = ink_outline_pass()
					mi.set_surface_override_material(s, dup)
					painted = true
		if not painted:
			var fb := StandardMaterial3D.new()
			fb.albedo_color = Color(0.70, 0.66, 0.60)
			fb.roughness = 0.85
			fb.next_pass = ink_outline_pass()
			mi.material_override = fb
	for c in root.get_children():
		add_ink_outline(c)

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
