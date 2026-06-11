class_name ProjectileSkill
extends Skill

# Spec 32b — data-driven default fire() for projectile-shaped skills.
# Concrete subclasses (BasicShot, PowerShot, MultiShot) just set the data
# fields in `_init()`; the firing logic stays here. Skills that aren't
# projectile-shaped (BrambleSnare) extend Skill directly and override fire().

const ArrowScene := preload("res://scenes/Arrow.tscn")

var damage_mult: float = 1.0
var projectile_count: int = 1
var spread_deg: float = 0.0          # total cone width (e.g. 40 → ±20°)
var skill_type: String = "basic"
var on_hit_effects: Array = []       # Array[SkillEffect]
var recoil_amount: float = -0.4       # negative → back-lean on the mesh
var bow_pop_mult: float = 1.22
var sfx_key: String = "fire"

# Default fire: aim, snap mesh rotation, spawn N arrows in a cone, apply
# recoil + SFX + bow-pop. Damage is `derived_stats.damage * damage_mult`
# rounded; each arrow gets the same on_hit_effects array.
func fire(player: Node) -> void:
	if player == null:
		return
	var dir: Vector3 = player.aim_dir() if player.has_method("aim_dir") \
		else Vector3.FORWARD
	var mesh = player.get("_mesh")
	if mesh != null:
		mesh.rotation.y = atan2(dir.x, dir.z)
	var origin: Vector3 = player.arrow_origin(dir) if player.has_method("arrow_origin") \
		else player.global_position + Vector3(0.0, 1.0, 0.0)
	var dmg: int = int(round(float(player.derived_stats.damage) * damage_mult))
	if projectile_count == 1:
		_spawn_arrow(player, origin, dir, dmg, true)
	else:
		# Spread the arrows symmetrically across `spread_deg`. With count=3
		# and spread=40°, arrows fly at -20°, 0°, +20° from the aim axis.
		# Spec-34 (cookbook): the center arrow is focal (full brightness);
		# the outer arrows are non-focal (dimmer + desaturated) so the eye
		# reads the fan as ONE ability rather than three coequal projectiles.
		var half := deg_to_rad(spread_deg) * 0.5
		var step := deg_to_rad(spread_deg) / float(projectile_count - 1)
		var center_i: int = projectile_count / 2
		for i in projectile_count:
			var angle: float = -half + i * step
			var rotated := dir.rotated(Vector3.UP, angle).normalized()
			_spawn_arrow(player, origin, rotated, dmg, i == center_i)
	if player.has_method("apply_recoil"):
		player.apply_recoil(recoil_amount)
	if player.has_method("bow_pop"):
		player.bow_pop(bow_pop_mult)
	var sfx = player.get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.play(sfx_key)

# Spawn one arrow, bake damage + crit + effects + skill_type, add to the
# player's parent (so the arrow outlives any mid-frame player respawn).
# `focal` controls the cookbook hierarchy — center arrows render bright,
# outer arrows desaturate + dim. Single-arrow skills always pass true.
func _spawn_arrow(player: Node, origin: Vector3, dir: Vector3, dmg: int,
		focal: bool = true) -> void:
	var arrow = ArrowScene.instantiate()
	arrow.damage = dmg
	arrow.crit_chance = float(player.derived_stats.crit_chance)
	arrow.crit_mult = float(player.derived_stats.crit_mult_bonus)
	arrow.skill_type = skill_type
	arrow.effects = on_hit_effects
	arrow.focal = focal
	player.get_parent().add_child(arrow)
	arrow.global_position = origin
	arrow.look_at(origin + dir, Vector3.UP)
