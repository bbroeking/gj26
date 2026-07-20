class_name PracticeBramble
extends "res://scripts/combatant.gd"

# Harmless first-return target for the Power Shot lesson. It reuses the normal
# arrow hurtbox contract, but never chases, attacks, drops loot, or dies into
# the economy. A Power Shot makes it burst into leaves and records the lesson.

const BRAMBLE_GLB := preload("res://models/withered_bramble_v2.glb")
const LEAF_TEX := preload("res://assets/vfx/soft_circle.png")

var _completed := false

func _ready() -> void:
	name = "PowerShotPracticeBramble"
	add_to_group("power_shot_practice")
	collision_layer = 0
	collision_mask = 0
	var mesh := BRAMBLE_GLB.instantiate()
	add_child(mesh)
	GlbFit.normalize_height(mesh, 1.35)
	cache_meshes()
	setup(999999, 0.55, 1.35)
	hp = hp_max
	# Combatant's movement/AI is unnecessary here; the Area3D hurtbox remains
	# active and receives arrows even with physics processing disabled.
	set_physics_process(false)

func on_projectile_skill_hit(skill_type: String) -> void:
	if _completed or skill_type != "power":
		return
	_completed = true
	var game := get_node_or_null("/root/Game")
	if game != null and game.has_method("complete_power_shot_practice"):
		game.complete_power_shot_practice()
	_burst_into_leaves()

func _burst_into_leaves() -> void:
	var leaves := GPUParticles3D.new()
	leaves.amount = 18
	leaves.lifetime = 0.9
	leaves.one_shot = true
	leaves.explosiveness = 0.92
	leaves.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 70.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 4.2
	pm.gravity = Vector3(0.0, -4.0, 0.0)
	pm.scale_min = 0.08
	pm.scale_max = 0.18
	pm.color = Color(0.52, 0.68, 0.25, 0.95)
	leaves.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.16, 0.10)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = LEAF_TEX
	mat.albedo_color = Color(0.55, 0.72, 0.27, 0.92)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	quad.material = mat
	leaves.draw_pass_1 = quad
	get_parent().add_child(leaves)
	leaves.global_position = global_position + Vector3(0.0, 0.7, 0.0)
	leaves.emitting = true
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE * 1.18, 0.08) \
		.set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "scale", Vector3.ZERO, 0.22) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.finished.connect(queue_free)
	get_tree().create_timer(1.1).timeout.connect(leaves.queue_free)
