class_name MultiShot
extends ProjectileSkill

# Spec 32b — slot 3. Three arrows in a ±20° cone (40° total). Each arrow
# does 0.5× damage (D3 Demon Hunter convention from spec 30 followup — 3
# arrows × 0.5 = 1.5× total damage; preserves pack-clear value without
# eclipsing PowerShot on single targets). Applies Snared on hit (1.5s,
# 50% slow, no DoT per spec 31).
#
# Spec-34 (Spell VFX Cookbook): center arrow renders as focal, outer two
# dim+desaturate (per ProjectileSkill spawn loop). After the base fire()
# spawns the arrows, a one-shot fan-shaped cast burst at the bow ties the
# three projectiles together as a SINGLE "cone of force" cast rather than
# three coincident shots.

const TEX_SOFT_CIRCLE := preload("res://assets/vfx/soft_circle.png")

const FAN_BURST_AMOUNT := 14
const FAN_BURST_LIFETIME := 0.18
const FAN_BURST_SPEED_MIN := 4.0
const FAN_BURST_SPEED_MAX := 7.0

func _init() -> void:
	name = "MultiShot"
	cost = 25.0
	base_cd = 2.0
	damage_mult = 0.5
	projectile_count = 3
	spread_deg = 40.0
	skill_type = "multi"
	on_hit_effects = [SkillEffect.snared(1.5, 0.5)]
	recoil_amount = -0.45
	bow_pop_mult = 1.20
	sfx_key = "skill_multi"

func fire(player: Node) -> void:
	# Spawn arrows + apply recoil + play SFX via the base implementation.
	super.fire(player)
	# Spec-34: add a fan-shaped cast burst at the bow, aimed along the
	# player's current dir, with spread matching the arrow cone (40°).
	# This visually anchors the 3 arrows to the bow so the fan reads as
	# one ability, not three coincident shots.
	if player == null:
		return
	var dir: Vector3 = player.aim_dir() if player.has_method("aim_dir") \
		else Vector3.FORWARD
	var origin: Vector3 = player.arrow_origin(dir) if player.has_method("arrow_origin") \
		else player.global_position + Vector3(0.0, 1.0, 0.0)
	_spawn_fan_burst(player, origin, dir)

func _spawn_fan_burst(player: Node, origin: Vector3, dir: Vector3) -> void:
	var p := GPUParticles3D.new()
	p.name = "MultiShotFanBurst"
	p.amount = FAN_BURST_AMOUNT
	p.lifetime = FAN_BURST_LIFETIME
	p.one_shot = true
	p.explosiveness = 1.0       # all particles emit on frame 1
	p.local_coords = false
	var pm := ParticleProcessMaterial.new()
	# Direction is the player's aim; spread half-angle = arrow fan half-angle.
	pm.direction = dir
	pm.spread = spread_deg * 0.5     # 20° each side = matches arrow cone
	pm.initial_velocity_min = FAN_BURST_SPEED_MIN
	pm.initial_velocity_max = FAN_BURST_SPEED_MAX
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.4
	pm.scale_max = 0.8
	var col := Color(1.00, 0.78, 0.32)        # matches gold default head
	pm.color = col
	var grad := Gradient.new()
	grad.set_color(0, Color(col.r, col.g, col.b, 1.0))
	grad.set_color(1, Color(col.r, col.g, col.b, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = grad
	pm.color_ramp = ramp
	p.process_material = pm
	# Spec-34: textured billboard particles.
	var qmesh := QuadMesh.new()
	qmesh.size = Vector2(1.05, 1.05)                # 3x bumped from 0.35
	var qmat := StandardMaterial3D.new()
	qmat.albedo_color = col
	qmat.albedo_texture = TEX_SOFT_CIRCLE
	qmat.emission_enabled = true
	qmat.emission = col
	qmat.emission_energy_multiplier = 3.5
	qmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qmesh.material = qmat
	p.draw_pass_1 = qmesh
	player.get_parent().add_child(p)
	p.global_position = origin
	p.emitting = true
	# Auto-cleanup after lifetime + small safety margin.
	player.get_tree().create_timer(FAN_BURST_LIFETIME + 0.1).timeout.connect(
		func() -> void:
			if is_instance_valid(p):
				p.queue_free()
	)
