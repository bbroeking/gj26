class_name RainOfThorns
extends Skill

# B5 — a delayed thorn volley at the aim point: 0.6s telegraph disc, then
# every enemy inside takes damage and a short bleed. The zone-control nuke
# next to BrambleSnare's lockdown.

const AoeQuery = preload("res://scripts/aoe_query.gd")
const SkillEffect = preload("res://scripts/skills/skill_effect.gd")

const RADIUS := 2.6
const DELAY := 0.6
const RANGE := 9.0
const DMG_MULT := 1.8

func _init() -> void:
	name = "RainOfThorns"
	cost = 32.0
	base_cd = 5.0

func fire(player: Node) -> void:
	if player == null:
		return
	var dir: Vector3 = player.aim_dir() if player.has_method("aim_dir") \
		else Vector3.FORWARD
	var center: Vector3 = player.global_position + dir.normalized() * \
		minf(RANGE, 6.0)
	center.y = player.global_position.y
	var tree := player.get_tree()
	var dmg: int = int(round(float(player.derived_stats.damage) * DMG_MULT))
	_telegraph(player, center)
	tree.create_timer(DELAY).timeout.connect(func():
		for c in AoeQuery.query_circle(tree, center, RADIUS):
			if c != null and is_instance_valid(c) and not c.dead:
				var to: Vector3 = c.global_position - center
				to.y = 0.0
				c.take_damage(dmg, to.normalized())
				SkillEffect.bleed(2.0, 1, 0.5).apply(c))
	var sfx = player.get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.play("skill_snare")

# A thorn-green warning disc — the boss telegraph language, player-owned.
func _telegraph(player: Node, center: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = RADIUS
	cyl.bottom_radius = RADIUS
	cyl.height = 0.07
	mi.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.62, 0.22, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.7, 0.25)
	mi.position = Vector3(center.x, 0.06, center.z)
	mi.material_override = mat
	player.get_parent().add_child(mi)
	player.get_tree().create_timer(DELAY + 0.15).timeout.connect(mi.queue_free)
