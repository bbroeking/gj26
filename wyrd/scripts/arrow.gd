extends Node3D

# Spec 13/14/26 — a loosed projectile, now a glowing bolt + particle trail
# + on-impact burst. Single-hit kinematic; moves down its -Z; the Hitbox
# damages the first enemy hurtbox it overlaps.
#
# Spec 26 follow-up — 4 visual VARIANTS the player can cycle live with
# number keys 1-4 (player_controller writes Arrow.variant_idx).

const SPEED := 50.0          # spec 29 — +47% so arrows feel zippy, not floaty
const LIFETIME := 2.5
const DAMAGE_BASE := 6
const WORLD_LAYER_MASK := 1
const TEX_SOFT_CIRCLE := preload("res://assets/vfx/soft_circle.png")
const TEX_EMBER := preload("res://assets/vfx/ember.png")

# Spec-34: build a textured billboard QuadMesh for use as a particle draw
# pass. Replaces the previous BoxMesh-cube pattern — particles now have
# soft alpha falloff and read as glowing dots / embers instead of pixels.
static func _soft_particle(size: float, color: Color, energy: float,
		tex: Texture2D = TEX_SOFT_CIRCLE) -> Mesh:
	var m := QuadMesh.new()
	m.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.albedo_texture = tex
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.material = mat
	return m

# Spec-34 cookbook: PowerShot impact radius — the burn applies to every
# enemy within this distance of the impact point, turning the skill into a
# true heavy-AoE burst instead of single-target. Small enough that it's a
# bonus (a clumped pack catches the spread) rather than a free clear.
const POWER_AOE_RADIUS := 1.8

# Spec-34 variety research move #5 (Zoe Q growth): PowerShot bolt scales
# from POWER_SCALE_MIN to POWER_SCALE_MAX (multipliers on its baked-in
# 2.5× ready-state) over POWER_GROWTH_SEC. Reads as the bolt visibly
# growing into a threat as it travels.
const POWER_SCALE_MIN := 0.6
const POWER_SCALE_MAX := 1.4
const POWER_GROWTH_SEC := 0.50

# Spec 27e — per-shot combat values, set by the player before add_child.
# `crit_chance` / `crit_mult` of -1.0 means "use combatant's defaults."
var damage: int = DAMAGE_BASE
var crit_chance: float = -1.0
var crit_mult: float = -1.0
# Spec 30 — which skill spawned this arrow. Affects visual scale.
# "basic" / "power" / "multi"; the snare skill doesn't spawn arrows.
var skill_type: String = "basic"

# Spec 32b — on-hit effects, set by the firing Skill before add_child.
# Each effect's `apply(target)` is called once after the arrow's damage
# resolves on the hit combatant. Replaces the spec 31 `match skill_type:`
# string-typed dispatch with data-driven on-hit consequences.
var effects: Array = []
# B5-wave2 — MercyShot's clean kill: ×execute_mult when the target's vigor
# fraction is already under execute_below. Defaults are a no-op.
var execute_mult: float = 1.0
var execute_below: float = 0.0
# Spec-34 cookbook (MultiShot focal hierarchy): the center arrow of a fan
# is "focal" (full brightness); the outer arrows are non-focal (~75%
# saturation, dimmer head emission, smaller trail particles) so the eye
# reads three coordinated arrows as a SINGLE ability instead of three
# identical projectiles competing for attention. Default true so all
# non-MultiShot arrows stay at full brightness.
var focal: bool = true

# Four shooting effects to try, picked by the static variant_idx.
const VARIANTS := [
	{"name": "gold",    "color": Color(1.00, 0.78, 0.32), "len": 0.60,
		"rad": 0.15, "trail_n": 60, "trail_life": 0.22, "trail_size": 0.09},
	{"name": "emerald", "color": Color(0.45, 1.00, 0.50), "len": 0.55,
		"rad": 0.13, "trail_n": 80, "trail_life": 0.30, "trail_size": 0.07},
	{"name": "frost",   "color": Color(0.55, 0.85, 1.00), "len": 0.65,
		"rad": 0.12, "trail_n": 100, "trail_life": 0.18, "trail_size": 0.06},
	{"name": "violet",  "color": Color(0.85, 0.40, 1.00), "len": 0.72,
		"rad": 0.18, "trail_n": 50, "trail_life": 0.28, "trail_size": 0.13},
]
# Spec-34 (Spell VFX Cookbook): PowerShot owns its own variant — deep
# ember-red so it reads as the heavy-damage skill instead of "BasicShot
# but bigger" (Riot loudness principle). Indexed separately from
# VARIANTS so the per-key picker doesn't surface it.
const POWERSHOT_VARIANT := {
	"name": "ember", "color": Color(1.00, 0.32, 0.10), "len": 0.85,
	"rad": 0.22, "trail_n": 100, "trail_life": 0.35, "trail_size": 0.14
}
static var variant_idx := 0       # player_controller flips this on 1-4

var _age := 0.0
var _spent := false
var _variant: Dictionary = VARIANTS[0]
var _power_base_scale: Vector3 = Vector3.ONE      # base for Zoe Q growth

func _ready() -> void:
	# Spec-34 — PowerShot forces its own ember variant + heavier scale.
	# The cookbook calls this "visual loudness must match gameplay loudness":
	# 2.5× damage on a 5× cooldown deserves its own color identity, not
	# the player's current variant_idx scaled up by 40%.
	if skill_type == "power":
		_variant = POWERSHOT_VARIANT
	else:
		_variant = VARIANTS[clampi(variant_idx, 0, VARIANTS.size() - 1)]
	var hb := get_node_or_null("Hitbox")
	if hb != null:
		(hb as Area3D).area_entered.connect(_on_area_entered)
	_build_visual()
	if skill_type == "power":
		# Spec-34 variety move #5 (Zoe Q): PowerShot bolt starts at
		# POWER_SCALE_MIN × of its full size, grows to POWER_SCALE_MAX
		# over POWER_GROWTH_SEC. The "this one matters" telegraph —
		# the bolt visibly grows into a threat as it flies. Driven by
		# the per-frame scale update in _physics_process below.
		scale = scale * 2.5 * POWER_SCALE_MIN
		_power_base_scale = scale

# Bright unshaded capsule along travel + a world-space particle trail.
func _build_visual() -> void:
	var col: Color = _variant.color
	# Spec-34: outer arrows in a fan desaturate by lerping toward gray + drop
	# emission so the center stays the focal point (Beardilocks "Hot Point").
	if not focal:
		var gray: float = (col.r + col.g + col.b) / 3.0
		col = col.lerp(Color(gray, gray, gray), 0.30)
	var mi := MeshInstance3D.new()
	mi.name = "Bolt"
	var cap := CapsuleMesh.new()
	cap.height = _variant.len * (1.0 if focal else 0.85)
	cap.radius = _variant.rad * (1.0 if focal else 0.85)
	mi.mesh = cap
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 4.0 if focal else 2.4
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	mi.rotation_degrees = Vector3(90, 0, 0)
	add_child(mi)

	var p := GPUParticles3D.new()
	p.name = "Trail"
	p.amount = int(_variant.trail_n)
	p.lifetime = _variant.trail_life
	p.local_coords = false

	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 18.0
	pm.initial_velocity_min = 0.1
	pm.initial_velocity_max = 0.6
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.55
	pm.scale_max = 1.0
	pm.color = col
	var grad := Gradient.new()
	grad.set_color(0, Color(col.r, col.g, col.b, 1.0))
	grad.set_color(1, Color(col.r, col.g, col.b, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = grad
	pm.color_ramp = ramp
	p.process_material = pm

	# Spec-34: trail now uses VFX.soft_particle_mesh — a textured billboard
	# QuadMesh with soft-circle alpha falloff (replaces the BoxMesh cube).
	# Emission stays at 1.5 (dimmer than head 4.0) so the head wins focal.
	var ts: float = _variant.trail_size
	p.draw_pass_1 = _soft_particle(ts * 10.5, col, 1.5)   # 3x bumped from 3.5
	add_child(p)
	p.emitting = true

# B5 — Piercing Bolt: arrows with pierce_left keep flying through targets
# (each pierce decrements; hits the same enemy once via _pierced).
var pierce_left := 0
var _pierced: Array = []

func _on_area_entered(area: Area3D) -> void:
	if _spent:
		return
	if area != null and area.has_meta("combatant"):
		var c = area.get_meta("combatant")
		if c != null and is_instance_valid(c) and not c.dead \
				and not _pierced.has(c):
			if pierce_left > 0:
				pierce_left -= 1
				_pierced.append(c)
			else:
				_spent = true
			var fwd := -global_transform.basis.z
			var dealt: int = damage
			if execute_mult > 1.0 and float(c.get("hp_max")) > 0.0 \
					and float(c.get("hp")) / float(c.get("hp_max")) < execute_below:
				dealt = int(round(float(damage) * execute_mult))
			c.take_damage(dealt, fwd, crit_chance, crit_mult)
			# Spec 32b — on-hit effects are data on the arrow. Each Skill
			# attached its list before spawn; we iterate and apply. Done
			# AFTER take_damage so a fatal hit dies cleanly (apply on dead
			# is a no-op).
			for e in effects:
				if e != null:
					e.apply(c)
			# Spec-34 cookbook: PowerShot lands with extra weight. The
			# combatant's HitFeedback already fires tier-scaled freeze +
			# shake; here we ADD on top so even a non-crit PowerShot has
			# 100ms total freeze (cookbook anchor) and a stronger camera
			# kick than any BasicShot crit. Hitstop takes the max of any
			# overlapping freeze, so this floors PowerShot's impact weight.
			if skill_type == "power":
				var hs := get_node_or_null("/root/Hitstop")
				if hs != null and hs.has_method("freeze"):
					hs.freeze(0.10)
				var cr := get_tree().get_first_node_in_group("camera_rig")
				if cr != null and cr.has_method("shake"):
					cr.shake(0.22)
				# Impact-AoE ember burst: PowerShot's burn applies not just
				# to the single hit target but to every enemy within
				# POWER_AOE_RADIUS of the impact point. The ember-burst
				# visual lands at the impact spot regardless of nearby
				# enemy count so the cast reads as an AoE even on solo
				# targets (in the showcase capture rig, that's exactly
				# the case — one dummy, but the visual still plays).
				_spawn_power_aoe_burst(global_position)
				for nearby in AoeQuery.query_circle(get_tree(),
						global_position, POWER_AOE_RADIUS):
					if nearby == c or not is_instance_valid(nearby):
						continue
					for e in effects:
						if e != null:
							e.apply(nearby)
			_explode(global_position)
			if _spent:
				queue_free()

func _physics_process(delta: float) -> void:
	if _spent:
		return
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	# Spec-34 Zoe Q growth — for PowerShot only, lerp the bolt scale from
	# POWER_SCALE_MIN to POWER_SCALE_MAX over POWER_GROWTH_SEC. Visible
	# threat ramp without any UI element.
	if skill_type == "power":
		var growth_t: float = clampf(_age / POWER_GROWTH_SEC, 0.0, 1.0)
		var mult: float = lerpf(POWER_SCALE_MIN, POWER_SCALE_MAX, growth_t)
		# _power_base_scale is the initial scale captured AFTER the 2.5×
		# bake-in × POWER_SCALE_MIN — multiplying back through divides out
		# the min so the final scale is base * mult / POWER_SCALE_MIN.
		scale = _power_base_scale * (mult / POWER_SCALE_MIN)
	var step := SPEED * delta
	var forward := -global_transform.basis.z
	var from := global_position
	var to := from + forward * step
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = WORLD_LAYER_MASK
	var hit := space.intersect_ray(query)
	if hit:
		global_position = hit.position
		_explode(hit.position)
		queue_free()
		return
	global_position = to

# Sphere-burst at the impact point, parented to the world to outlive us.
# Spec-34 cookbook: PowerShot impact-AoE visual. A larger, slower, redder
# burst on top of the standard _explode, plus a brief ember-ring decal on
# the ground. This is what makes a solo-target PowerShot still READ as an
# AoE — the visual fans out to POWER_AOE_RADIUS regardless of how many
# nearby enemies actually caught the burn.
func _spawn_power_aoe_burst(at: Vector3) -> void:
	var host := get_parent()
	if host == null:
		return
	# Wide ember spray — bigger amount + slower velocity + longer life
	# than _explode, so it reads as a "spread" instead of a "pop".
	var p := GPUParticles3D.new()
	p.amount = 36
	p.lifetime = 0.9
	p.one_shot = true
	p.explosiveness = 1.0
	p.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 0.4, 0)             # mostly horizontal, slight rise
	pm.spread = 90.0
	pm.flatness = 0.6                              # bias toward the floor plane
	pm.initial_velocity_min = 4.0
	pm.initial_velocity_max = 8.0
	pm.gravity = Vector3(0, -3.0, 0)               # embers settle
	pm.scale_min = 0.5
	pm.scale_max = 1.1
	var ember := Color(1.00, 0.40, 0.12)
	pm.color = ember
	var grad := Gradient.new()
	grad.set_color(0, Color(ember.r, ember.g, ember.b, 1.0))
	grad.set_color(1, Color(ember.r, ember.g, ember.b, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = grad
	pm.color_ramp = ramp
	p.process_material = pm
	# Spec-34: ember textured billboard particles, white hot core fading
	# through orange to red at the edge (ember.png texture).
	p.draw_pass_1 = _soft_particle(1.65, ember, 3.8, TEX_EMBER)  # 3x bumped from 0.55
	host.add_child(p)
	p.global_position = at
	p.emitting = true
	host.get_tree().create_timer(p.lifetime + 0.2).timeout.connect(
		func() -> void:
			if is_instance_valid(p):
				p.queue_free()
	)
	# Ember-ring ground decal — a flat disc that flashes then fades.
	# Anchors the AoE visually on the ground so the player reads
	# "something happened *here*" beyond just floating sparks.
	var ring := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = POWER_AOE_RADIUS
	rm.bottom_radius = POWER_AOE_RADIUS
	rm.height = 0.04
	ring.mesh = rm
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(1.00, 0.50, 0.18, 0.55)
	rmat.emission_enabled = true
	rmat.emission = Color(1.00, 0.50, 0.18)
	rmat.emission_energy_multiplier = 2.4
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = rmat
	host.add_child(ring)
	ring.global_position = Vector3(at.x, 0.05, at.z)
	ring.scale = Vector3(0.1, 1.0, 0.1)
	var tw := ring.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector3.ONE, 0.18) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(rmat, "albedo_color:a", 0.0, 0.40)
	tw.tween_property(rmat, "emission_energy_multiplier", 0.0, 0.40)
	tw.chain().tween_callback(ring.queue_free)

func _explode(at: Vector3) -> void:
	var host := get_parent()
	if host == null:
		return
	var col: Color = _variant.color
	var p := GPUParticles3D.new()
	p.amount = 30
	p.lifetime = 0.5
	p.one_shot = true
	p.explosiveness = 1.0
	p.local_coords = false

	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 3.0
	pm.initial_velocity_max = 7.0
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.7
	pm.scale_max = 1.5
	pm.color = col
	var grad := Gradient.new()
	grad.set_color(0, Color(col.r, col.g, col.b, 1.0))
	grad.set_color(1, Color(col.r, col.g, col.b, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = grad
	pm.color_ramp = ramp
	p.process_material = pm
	# Spec-34: textured billboard particles for the impact burst.
	p.draw_pass_1 = _soft_particle(1.5, col, 3.5)         # 3x bumped from 0.5
	host.add_child(p)
	p.global_position = at
	p.emitting = true
	p.get_tree().create_timer(1.2).timeout.connect(p.queue_free)
