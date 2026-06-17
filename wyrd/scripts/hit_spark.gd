extends RefCounted

# Spec 26 — a one-shot hit-spark burst. spawn() builds a GPUParticles3D,
# fires it once, and self-frees. Built in code, no .tscn. Colour + size by
# crit tier so crits read as a bigger, brighter pop.

const TEX_SOFT_CIRCLE := preload("res://assets/vfx/soft_circle.png")

const TIER_COLOR := {
	"normal": Color(1.00, 0.90, 0.55),
	"crit":   Color(1.00, 0.80, 0.20),
	"super":  Color(0.82, 0.50, 1.00),
}

const BIOME_TINT: Dictionary = {
	"crypt":  Color(1.0,  1.0,  1.0),
	"forest": Color(0.70, 0.95, 0.60),
	"swamp":  Color(0.55, 0.80, 0.55),
}

static func spawn(parent: Node, world_pos: Vector3, tier: String, biome: String = "crypt") -> void:
	if parent == null:
		return
	var big := tier != "normal"
	var tint: Color = BIOME_TINT.get(biome, Color.WHITE)
	var col: Color = TIER_COLOR.get(tier, TIER_COLOR["normal"]) * tint

	var p := GPUParticles3D.new()
	p.amount = 26 if big else 14
	p.lifetime = 0.5
	p.one_shot = true
	p.explosiveness = 1.0

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 90.0
	mat.initial_velocity_min = 2.5
	mat.initial_velocity_max = 6.0 if big else 4.0
	mat.gravity = Vector3(0, -9.0, 0)
	mat.scale_min = 0.5
	mat.scale_max = 1.2
	mat.color = col
	p.process_material = mat

	# Spec-34: textured billboard particle (soft-circle alpha falloff) so
	# each spark reads as a glowing dot instead of a hard pixel cube.
	# Size bumped 3x per user feedback — bigger sparks read at showcase distance.
	var s := (0.12 if big else 0.09) * 12.0     # 3x bumped from 4.0
	var qmesh := QuadMesh.new()
	qmesh.size = Vector2(s, s)
	var qmat := StandardMaterial3D.new()
	qmat.albedo_color = col
	qmat.albedo_texture = TEX_SOFT_CIRCLE
	qmat.emission_enabled = true
	qmat.emission = col
	qmat.emission_energy_multiplier = 2.5
	qmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qmesh.material = qmat
	p.draw_pass_1 = qmesh

	parent.add_child(p)
	p.global_position = world_pos
	p.emitting = true
	p.get_tree().create_timer(1.2).timeout.connect(p.queue_free)
