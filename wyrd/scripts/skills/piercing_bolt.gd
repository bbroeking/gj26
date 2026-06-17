class_name PiercingBolt
extends ProjectileSkill

# B5 — a heavy line shot that punches through up to 3 enemies. The corridor
# skill: rewards lining a pack up, the counterweight to MultiShot's fan.
#
# Visual identity (Phase 1): a frost-white needle bolt — long narrow capsule,
# icy blue-white colour — distinct from PowerShot's ember-red. Per-pierce
# thread-through spark burst plays each time the bolt punches through an enemy.
# All VFX is authored procedurally here; no dependency on arrow.gd helpers.

# Frost-white needle variant: longer + narrower than PowerShot's ember brick.
# Color is near-white with a slight blue tint to read as "ice/piercing cold."
const _PIERCE_COLOR    := Color(0.82, 0.95, 1.00)
const _PIERCE_LEN      := 1.10
const _PIERCE_RAD      := 0.09
const _PIERCE_TRAIL_N  := 80
const _PIERCE_TRAIL_L  := 0.18
const _PIERCE_TRAIL_SZ := 0.055
# Soft-circle texture — same asset arrow.gd preloads; safe to preload here.
const _TEX_SOFT_CIRCLE := preload("res://assets/vfx/soft_circle.png")

func _init() -> void:
	name = "PiercingBolt"
	cost = 22.0
	base_cd = 2.4
	damage_mult = 1.6
	pierce = 3
	# "pierce" is a new skill_type value; arrow.gd's _ready falls into
	# the `else` branch (VARIANTS[variant_idx]) — the post-spawn visual
	# override below then replaces that with the frost needle identity.
	skill_type = "pierce"
	recoil_amount = -0.7
	bow_pop_mult = 1.3
	sfx_key = "skill_power"

# Override _spawn_arrow (called by ProjectileSkill.fire via self dispatch).
# Lets the parent handle damage baking, pierce_left, effects, and tree
# placement — then mutates the spawned arrow's visual to frost-white needle
# and hooks in the per-pierce thread-through spark.
func _spawn_arrow(player: Node, origin: Vector3, dir: Vector3,
		dmg: int, focal: bool = true) -> void:
	# Count children before the spawn so we can find the new arrow reliably.
	var host: Node = player.get_parent()
	if host == null:
		super._spawn_arrow(player, origin, dir, dmg, focal)
		return
	var pre_count: int = host.get_child_count()
	# Delegate to the base: handles damage, crit, effects, pierce_left, tree.
	super._spawn_arrow(player, origin, dir, dmg, focal)
	# If a new child was added it is the arrow we just spawned.
	if host.get_child_count() <= pre_count:
		return
	var arrow: Node3D = host.get_child(host.get_child_count() - 1) as Node3D
	if arrow == null:
		return
	# --- Replace the bolt visual with a frost-white needle ---
	_apply_frost_visual(arrow, focal)
	# --- Hook area_entered to fire per-pierce thread-through sparks ---
	# CONNECT_DEFERRED ensures arrow.gd's own _on_area_entered (connected in
	# _ready without DEFERRED) runs first, decrementing pierce_left before
	# our callback reads it. No CONNECT_ONE_SHOT — we need this for each pierce.
	var hb: Area3D = arrow.get_node_or_null("Hitbox") as Area3D
	if hb != null:
		hb.area_entered.connect(
			func(area: Area3D) -> void:
				_on_pierce_area(arrow, area, host),
			CONNECT_DEFERRED
		)

# Persistent per-pierce handler — connected at spawn, remains connected for
# all pierces. Emits a frost spark burst for each non-final pierce.
func _on_pierce_area(arrow: Node3D, area: Area3D, host: Node) -> void:
	if not is_instance_valid(arrow):
		return
	# Read pierce_left from the arrow AFTER arrow.gd's _on_area_entered has
	# decremented it. We connect with CONNECT_DEFERRED so arrow.gd processes
	# the hit first; by the time we run, pierce_left reflects the new count.
	# If pierce_left >= 0, the bolt is still flying — a thread-through just happened.
	var pl: int = int(arrow.get("pierce_left"))
	if pl >= 0:
		_pierce_thread(arrow.global_position, arrow.global_transform.basis.z, host)

# Build a small forward-biased frost spark burst at the pierce point.
# Quieter than arrow.gd's _explode (10 vs 30 particles, shorter life)
# — reads as "passed through", not "hit".
func _pierce_thread(at: Vector3, bolt_fwd: Vector3, host: Node) -> void:
	if host == null:
		return
	var p := GPUParticles3D.new()
	p.amount = 10
	p.lifetime = 0.28
	p.one_shot = true
	p.explosiveness = 1.0
	p.local_coords = false
	var pm := ParticleProcessMaterial.new()
	# Forward-biased: sparks spray in the bolt's travel direction.
	pm.direction = -bolt_fwd
	pm.spread = 30.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 5.0
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.4
	pm.scale_max = 0.8
	pm.color = _PIERCE_COLOR
	var grad := Gradient.new()
	grad.set_color(0, Color(_PIERCE_COLOR.r, _PIERCE_COLOR.g, _PIERCE_COLOR.b, 1.0))
	grad.set_color(1, Color(_PIERCE_COLOR.r, _PIERCE_COLOR.g, _PIERCE_COLOR.b, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = grad
	pm.color_ramp = ramp
	p.process_material = pm
	p.draw_pass_1 = _make_soft_particle(0.9, _PIERCE_COLOR, 2.0)
	host.add_child(p)
	p.global_position = at
	p.emitting = true
	host.get_tree().create_timer(0.6).timeout.connect(
		func() -> void:
			if is_instance_valid(p):
				p.queue_free()
	)

# Procedurally replace the arrow's default visual with the frost needle.
# Called immediately after the arrow is added to the tree (_ready has run).
func _apply_frost_visual(arrow: Node3D, focal: bool) -> void:
	# Remove the existing Bolt and Trail nodes built by arrow.gd's _build_visual.
	var old_bolt: Node = arrow.get_node_or_null("Bolt")
	if old_bolt != null:
		old_bolt.queue_free()
	var old_trail: Node = arrow.get_node_or_null("Trail")
	if old_trail != null:
		old_trail.queue_free()
	# Frost needle capsule — long + narrow, bright unshaded frost-white.
	var col: Color = _PIERCE_COLOR
	if not focal:
		var gray: float = (col.r + col.g + col.b) / 3.0
		col = col.lerp(Color(gray, gray, gray), 0.30)
	var mi := MeshInstance3D.new()
	mi.name = "FrostBolt"
	var cap := CapsuleMesh.new()
	cap.height = _PIERCE_LEN
	cap.radius = _PIERCE_RAD
	mi.mesh = cap
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 5.0 if focal else 3.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Slight alpha transparency so overlapping bolt + trail read as light, not clay.
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.92
	mi.material_override = mat
	mi.rotation_degrees = Vector3(90, 0, 0)
	arrow.add_child(mi)
	# Frost trail — tighter spread than the ember trail, reads as a needle cutting air.
	var p := GPUParticles3D.new()
	p.name = "FrostTrail"
	p.amount = int(_PIERCE_TRAIL_N)
	p.lifetime = _PIERCE_TRAIL_L
	p.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 10.0    # tighter than ember (18°) — reads as a cold wake, not spray
	pm.initial_velocity_min = 0.1
	pm.initial_velocity_max = 0.5
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.45
	pm.scale_max = 0.85
	pm.color = col
	var grad := Gradient.new()
	grad.set_color(0, Color(col.r, col.g, col.b, 1.0))
	grad.set_color(1, Color(col.r, col.g, col.b, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = grad
	pm.color_ramp = ramp
	p.process_material = pm
	p.draw_pass_1 = _make_soft_particle(_PIERCE_TRAIL_SZ * 10.5, col, 1.2)
	arrow.add_child(p)
	p.emitting = true

# Minimal self-contained soft-particle billboard — mirrors arrow.gd's
# _soft_particle() but lives here so this skill has no cross-file dependency.
func _make_soft_particle(size: float, color: Color, energy: float) -> Mesh:
	var m := QuadMesh.new()
	m.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.albedo_texture = _TEX_SOFT_CIRCLE
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.material = mat
	return m
