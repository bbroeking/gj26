extends StaticBody3D

# Spec 26 follow-up — a destructible prop. Same `take_damage(amount, dir)`
# shape as Combatant (so arrow.gd's hurtbox-meta path "just works"), but a
# one-shot break: any hit shatters it into a particle burst and frees it.
# layout_loader wires this onto kinds listed in DECOR_BREAKABLE.

var hp := 1
var dead := false
var _break_color := Color(0.65, 0.45, 0.30)
var _burst_height := 0.5

# Called from layout_loader after the body is in the tree.
func setup(hp_in: int, break_color: Color, hurt_radius: float, hurt_height: float) -> void:
	hp = hp_in
	_break_color = break_color
	_burst_height = hurt_height * 0.5
	var hurt := Area3D.new()
	hurt.name = "Hurtbox"
	hurt.collision_layer = 8     # LAYER_HURTBOX — same as Combatant
	hurt.collision_mask = 0
	hurt.monitorable = true
	hurt.monitoring = false
	var shape := CapsuleShape3D.new()
	shape.radius = hurt_radius
	shape.height = hurt_height
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0.0, hurt_height * 0.5, 0.0)
	hurt.add_child(col)
	add_child(hurt)
	hurt.set_meta("combatant", self)

# Duck-typed to match Combatant's interface — arrow.gd just calls take_damage.
func take_damage(_amount: int, _from_dir: Vector3) -> void:
	if dead:
		return
	hp -= 1
	if hp <= 0:
		_break()

func _break() -> void:
	dead = true
	_burst()
	queue_free()

# Sphere-burst of shards in the break colour, parented to the world so it
# outlives the queue_free.
func _burst() -> void:
	var host := get_parent()
	if host == null:
		return
	var p := GPUParticles3D.new()
	p.amount = 24
	p.lifetime = 0.6
	p.one_shot = true
	p.explosiveness = 1.0
	p.local_coords = false

	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 5.0
	pm.gravity = Vector3(0, -9.0, 0)
	pm.scale_min = 0.5
	pm.scale_max = 1.2
	pm.color = _break_color
	p.process_material = pm

	var pmesh := BoxMesh.new()
	pmesh.size = Vector3(0.12, 0.12, 0.12)
	var pbm := StandardMaterial3D.new()
	pbm.albedo_color = _break_color
	pbm.roughness = 0.9
	pmesh.material = pbm
	p.draw_pass_1 = pmesh

	host.add_child(p)
	p.global_position = global_position + Vector3(0.0, _burst_height, 0.0)
	p.emitting = true
	p.get_tree().create_timer(1.5).timeout.connect(p.queue_free)
