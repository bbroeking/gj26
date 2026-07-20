class_name RootroadGatherNode
extends "res://scripts/gather_node.gd"

# Uses the same channel, gates, XP, and host-owned material path as GatherNode;
# only the Rootroads visual is specialized.  This prevents a Pale Veins
# Wildgold/Wellmoss spawn from silently rendering as a legacy ore/bush prop.

const GlbFit = preload("res://scripts/glb_fit.gd")

const ROOTROAD_PROP := {
	"wildgold": "res://models/prop_wildgold_vein_v1.glb",
	"wellmoss": "res://models/prop_wellmoss_patch_v1.glb",
	"wellwater": "res://models/landmark_pale_well_v1.glb",
	# A dedicated botanical GLB can replace this readable primitive later.
	"embersage": "",
	# Root Below launches with deterministic silhouettes; production GLBs may
	# replace them without changing node setup, gathering, or test seams.
	"waysteel": "",
	"root_sap": "",
}


func _ready_interactable() -> void:
	_body = Node3D.new()
	_body.name = "RootroadGatherBody"
	add_child(_body)
	var tier := ore_tier if ore_tier != "" else herb_tier
	var path := String(ROOTROAD_PROP.get(tier, ""))
	if path != "" and ResourceLoader.exists(path):
		var packed: PackedScene = load(path)
		if packed != null:
			var prop: Node3D = packed.instantiate()
			prop.name = "Rootroad_%s" % tier
			GlbFit.normalize_height(prop, 0.86 if tier != "wellwater" else 1.15)
			GlbFit.unmetal(prop)
			GlbFit.add_ink_outline(prop)
			_body.add_child(prop)
			return
	if tier == "waysteel":
		_build_waysteel_fallback()
		return
	if tier == "root_sap":
		_build_root_sap_fallback()
		return
	_build_primitive()


func _build_waysteel_fallback() -> void:
	var stone := _add_mesh(_rock_mesh(0.52, 0.66), Color(0.16, 0.21, 0.22),
		Vector3(0.0, 0.28, 0.0))
	stone.name = "WaysteelStone"
	for index in 3:
		var shard_mesh := CylinderMesh.new()
		shard_mesh.top_radius = 0.025
		shard_mesh.bottom_radius = 0.095
		shard_mesh.height = 0.48 - float(index) * 0.06
		shard_mesh.radial_segments = 5
		var shard := _add_mesh(shard_mesh, Color(0.38, 0.78, 0.78),
			Vector3(-0.19 + float(index) * 0.19, 0.55,
				0.02 - float(index % 2) * 0.12))
		shard.name = "WaysteelShard%d" % (index + 1)
		shard.rotation.z = -0.28 + float(index) * 0.25
	var glow := OmniLight3D.new()
	glow.name = "WaysteelGlow"
	glow.light_color = Color(0.37, 0.82, 0.82)
	glow.light_energy = 0.42
	glow.omni_range = 2.4
	glow.position = Vector3(0.0, 0.52, 0.0)
	_body.add_child(glow)


func _build_root_sap_fallback() -> void:
	var root_mesh := CylinderMesh.new()
	root_mesh.top_radius = 0.23
	root_mesh.bottom_radius = 0.35
	root_mesh.height = 0.78
	root_mesh.radial_segments = 7
	var root := _add_mesh(root_mesh, Color(0.29, 0.16, 0.08),
		Vector3(0.0, 0.36, 0.0))
	root.name = "RootSapRoot"
	root.rotation.z = 0.34
	var wound_mesh := SphereMesh.new()
	wound_mesh.radius = 0.13
	wound_mesh.height = 0.05
	wound_mesh.radial_segments = 7
	wound_mesh.rings = 3
	var wound := _add_mesh(wound_mesh, Color(0.95, 0.52, 0.12),
		Vector3(0.16, 0.48, 0.0))
	wound.name = "RootSapWound"
	wound.rotation.z = PI / 2.0
	for index in 3:
		var drop_mesh := SphereMesh.new()
		drop_mesh.radius = 0.075 - float(index) * 0.012
		drop_mesh.height = 0.14 - float(index) * 0.02
		drop_mesh.radial_segments = 7
		drop_mesh.rings = 4
		var drop := _add_mesh(drop_mesh, Color(1.0, 0.58, 0.10),
			Vector3(0.18 + float(index) * 0.035,
				0.36 - float(index) * 0.11, 0.0))
		drop.name = "RootSapDrop%d" % (index + 1)


func _rock_mesh(radius: float, height: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 7
	mesh.rings = 4
	return mesh
