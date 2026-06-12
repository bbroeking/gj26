class_name Thornburst
extends Skill

# B5-wave2 — the panic button: a ring of thorns erupts from the hunter's
# boots, hurting and briefly snaring everything in arm's reach. No
# projectile; AoeQuery circle centred on the player (spec 31 pattern),
# expanding emerald ring for the read (the death-burst torus pattern).

const RADIUS := 3.2
const DMG_MULT := 1.4
const SNARE_SEC := 2.0
const SNARE_SLOW := 0.5

func _init() -> void:
	name = "Thornburst"
	cost = 30.0
	base_cd = 8.0

func fire(player: Node) -> void:
	if player == null:
		return
	var dmg: int = int(round(float(player.derived_stats.damage) * DMG_MULT))
	var hits: Array = AoeQuery.query_circle(player.get_tree(),
		player.global_position, RADIUS)
	for c in hits:
		var dir: Vector3 = c.global_position - player.global_position
		c.take_damage(dmg, dir, float(player.derived_stats.crit_chance),
			float(player.derived_stats.crit_mult_bonus))
		if c.has_method("apply_status"):
			c.apply_status("snared", SNARE_SEC, 0, SNARE_SLOW)
	_ring_vfx(player)
	if player.has_method("apply_recoil"):
		player.apply_recoil(-0.5)
	var sfx = player.get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.play("skill_snare")

# An emerald torus blooming outward to RADIUS — the AoE read.
func _ring_vfx(player: Node) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.5
	torus.outer_radius = 0.62
	ring.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.50, 0.90, 0.40, 0.9)
	ring.material_override = mat
	player.get_parent().add_child(ring)
	ring.global_position = player.global_position + Vector3(0.0, 0.25, 0.0)
	var tw := ring.create_tween()
	tw.tween_property(ring, "scale",
		Vector3(RADIUS / 0.6, 1.0, RADIUS / 0.6), 0.28) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.32)
	tw.tween_callback(ring.queue_free)
