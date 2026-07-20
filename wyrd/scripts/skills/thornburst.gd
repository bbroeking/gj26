class_name Thornburst
extends Skill

# B5-wave2 — the panic button: a ring of thorns erupts from the hunter's
# boots, hurting and briefly snaring everything in arm's reach. No
# projectile; AoeQuery circle centred on the player (spec 31 pattern).
#
# Spec-34 treatment (VFX Cookbook 4-beat burst):
#   Beat 1 — Anticipation flash (0.08 s): player mesh emissive green pulse
#   Beat 2 — Telegraph disc (0.12 s): amber CylinderMesh scales 0 → 1
#   Beat 3 — Snap (0.10 s): emerald, thorn ring erupts, damage fires
#   Beat 4 — Wither (0.25 s): thorns retract tip-to-base, disc alpha-out

const RADIUS := 3.2
const DMG_MULT := 1.4
const SNARE_SEC := 2.0
const SNARE_SLOW := 0.5

# Timing constants (local until feel.gd tunables land in Plan.md Part B0)
const TELEGRAPH_COLOR  := Color(0.95, 0.65, 0.20, 0.55)  # amber
const ACTIVE_COLOR     := Color(0.30, 0.65, 0.25, 0.70)  # emerald
const THORN_BASE_COLOR := Color(0.12, 0.06, 0.04)
const ANTICIPATE_SEC   := 0.08
const TELEGRAPH_SEC    := 0.12
const SNAP_SEC         := 0.10
const WITHER_SEC       := 0.25
const OUTER_COUNT      := 8
const INNER_COUNT      := 4
const VINE_GROW_SHADER := preload("res://assets/vfx/vine_grow.gdshader")

# Mastery upgrade hooks — set by the mastery system to tier up the skill
var snare_duration_bonus: float = 0.0
var radius_bonus: float = 0.0

func _init() -> void:
	name = "Thornburst"
	cost = 30.0
	base_cd = 8.0

func fire(player: Node) -> void:
	if player == null:
		return
	var dmg: int = int(round(float(player.derived_stats.damage) * DMG_MULT))
	var radius: float = RADIUS + radius_bonus
	# Squash punch — coil before erupt; fires same tick as recoil
	_squash_punch(player)
	# Recoil fires first — squash-in anticipation before eruption
	if player.has_method("apply_recoil"):
		player.apply_recoil(-0.5)
	# Cast wind-up cue SFX ("drawing in" feel)
	var sfx: Node = player.get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.play("skill_snare")
	_burst_vfx(player, radius, dmg)

# ---- Beat orchestrator ------------------------------------------------

func _burst_vfx(player: Node, radius: float, dmg: int) -> void:
	# Beat 1 — anticipation flash on the player mesh
	_anticipation_flash(player)
	# Beat 2 — amber disc grows from a pinprick at player feet
	var holder := Node3D.new()
	holder.position = player.global_position + Vector3(0.0, 0.05, 0.0)
	player.get_parent().add_child(holder)
	var disc: MeshInstance3D = _make_burst_disc(radius)
	holder.add_child(disc)
	disc.scale = Vector3(0.05, 1.0, 0.05)
	var fill_tw: Tween = disc.create_tween()
	fill_tw.tween_property(disc, "scale", Vector3.ONE, TELEGRAPH_SEC) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# Beat 3 — snap: emerald, thorns spring up, damage fires
	fill_tw.tween_callback(func() -> void:
		if not is_instance_valid(holder):
			return
		var disc_mat: StandardMaterial3D = disc.material_override as StandardMaterial3D
		if disc_mat != null:
			disc_mat.albedo_color = ACTIVE_COLOR
			disc_mat.emission = Color(ACTIVE_COLOR.r, ACTIVE_COLOR.g, ACTIVE_COLOR.b)
		_spawn_burst_thorns(holder, radius)
		# AoE fires here — visual and damage land together
		var tree: SceneTree = player.get_tree()
		for c in AoeQuery.query_circle(tree, player.global_position, radius):
			var dir: Vector3 = (c as Node3D).global_position - player.global_position
			c.take_damage(dmg, dir, float(player.derived_stats.crit_chance),
				float(player.derived_stats.crit_mult_bonus))
			if c.has_method("apply_status"):
				c.apply_status("snared", SNARE_SEC + snare_duration_bonus, 0, SNARE_SLOW)
		var sfx: Node = player.get_node_or_null("/root/Sfx")
		if sfx != null:
			sfx.play("thornburst_impact")
	)
	# Beat 4 — the delay belongs to the effect holder, rather than the
	# SceneTree.  A chart can tear down its World while the skill is still in
	# flight; a SceneTreeTimer would outlive that World and invoke a closure
	# whose holder/disc captures have been freed.  A holder-bound Tween dies
	# with the holder, so teardown simply cancels the cosmetic tail.
	var wither_delay: Tween = holder.create_tween()
	wither_delay.tween_interval(TELEGRAPH_SEC + SNAP_SEC)
	wither_delay.tween_callback(_begin_wither.bind(holder, disc))


func _begin_wither(holder: Node3D, disc: MeshInstance3D) -> void:
	if not is_instance_valid(holder):
		return
	var tw: Tween = holder.create_tween()
	tw.set_parallel(true)
	if is_instance_valid(disc):
		var disc_mat: StandardMaterial3D = disc.material_override as StandardMaterial3D
		if disc_mat != null:
			tw.tween_property(disc_mat, "albedo_color:a", 0.0, WITHER_SEC)
			tw.tween_property(disc_mat, "emission_energy_multiplier", 0.0, WITHER_SEC)
	_wither_subtree(holder, tw)
	tw.chain().tween_callback(holder.queue_free)

# ---- Beat 1 helpers ---------------------------------------------------

# Brief emissive green pulse on the player mesh — distinct from a hit-flash
# (green vs white) so the eye reads it as a cast, not a wound.
func _anticipation_flash(player: Node) -> void:
	if player.has_method("apply_flash"):
		player.apply_flash(ANTICIPATE_SEC, Color(0.4, 1.0, 0.4))

# 0.12 s squash-in punch on the player mesh — "coiling" anticipation.
# Finishes before Beat 3 snap at ~0.20 s so "coil then erupt" reads correctly.
func _squash_punch(player: Node) -> void:
	var mesh_raw = player.get("_mesh")
	if mesh_raw == null or not (mesh_raw is Node3D):
		return
	var mesh: Node3D = mesh_raw as Node3D
	var raw_base = player.get("_mesh_base_scale")
	var base: Vector3 = Vector3.ONE
	if raw_base != null and raw_base is Vector3:
		base = raw_base as Vector3
	var squashed: Vector3 = Vector3(base.x * 1.08, base.y * 0.88, base.z * 1.08)
	var tw: Tween = mesh.create_tween()
	tw.tween_property(mesh, "scale", squashed, 0.06) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(mesh, "scale", base, 0.06) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ---- Beat 2 helpers ---------------------------------------------------

# Amber emissive disc at player feet — parameterised radius (unlike
# BrambleSnare's fixed SNARE_RADIUS version).
func _make_burst_disc(radius: float) -> MeshInstance3D:
	var disc := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = radius
	dm.bottom_radius = radius
	dm.height = 0.05
	disc.mesh = dm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = TELEGRAPH_COLOR
	mat.emission_enabled = true
	mat.emission = Color(TELEGRAPH_COLOR.r, TELEGRAPH_COLOR.g, TELEGRAPH_COLOR.b)
	mat.emission_energy_multiplier = 2.4
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disc.material_override = mat
	return disc

# ---- Beat 3 helpers ---------------------------------------------------

# Outer ring (8 thorns at 90% radius) + inner ring (4 thorns at 40%
# radius, offset 45°) — inner ring reads as "erupted from boots."
func _spawn_burst_thorns(holder: Node3D, radius: float) -> void:
	for i in OUTER_COUNT:
		var angle: float = TAU * float(i) / float(OUTER_COUNT)
		var pos := Vector3(cos(angle) * radius * 0.90, 0.0, sin(angle) * radius * 0.90)
		var thorn: MeshInstance3D = _make_burst_thorn(pos, angle, 1.0)
		holder.add_child(thorn)
		var snap_tw: Tween = thorn.create_tween()
		snap_tw.tween_property(thorn.material_override,
				"shader_parameter/growth", 1.0, SNAP_SEC) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for i in INNER_COUNT:
		var angle: float = TAU * float(i) / float(INNER_COUNT) + PI * 0.25
		var pos := Vector3(cos(angle) * radius * 0.40, 0.0, sin(angle) * radius * 0.40)
		var thorn: MeshInstance3D = _make_burst_thorn(pos, angle, 0.75)
		holder.add_child(thorn)
		var snap_tw: Tween = thorn.create_tween()
		snap_tw.tween_property(thorn.material_override,
				"shader_parameter/growth", 1.0, SNAP_SEC) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

# Single thorn spike — tapered PrismMesh + vine_grow dissolve shader.
# Copied from BrambleSnare._make_thorn; scale_f shrinks inner ring thorns.
func _make_burst_thorn(pos: Vector3, angle: float, scale_f: float) -> MeshInstance3D:
	var thorn := MeshInstance3D.new()
	thorn.name = "Thorn"
	var pm := PrismMesh.new()
	pm.size = Vector3(0.20 * scale_f, 0.95 * scale_f, 0.20 * scale_f)
	pm.left_to_right = 0.5
	thorn.mesh = pm
	var mat := ShaderMaterial.new()
	mat.shader = VINE_GROW_SHADER
	mat.set_shader_parameter("base_color", THORN_BASE_COLOR)
	mat.set_shader_parameter("edge_color", Color(0.50, 1.00, 0.40))
	mat.set_shader_parameter("growth", 0.0)
	mat.set_shader_parameter("edge_width", 0.12)
	mat.set_shader_parameter("edge_energy", 6.0)
	mat.set_shader_parameter("body_energy", 0.8)
	thorn.material_override = mat
	thorn.position = pos
	# Tilt outward 8° so thorns fan instead of standing rigidly straight
	thorn.rotation = Vector3(0.0, -angle + PI * 0.5, deg_to_rad(8.0))
	return thorn

# ---- Beat 4 helpers ---------------------------------------------------

# Recursively wither every vine_grow ShaderMaterial in the holder subtree —
# growth 1 → 0 makes vines retract tip-to-base (dissolve sweeps in reverse).
# Verbatim copy from BrambleSnare._wither_subtree; duplication is intentional
# until impl-system-combat-juice-vfx extracts a shared VFX helper module.
func _wither_subtree(node: Node, tw: Tween) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		var mat: Material = mi.material_override
		if mat is ShaderMaterial:
			tw.tween_property(mat, "shader_parameter/growth",
				0.0, WITHER_SEC).set_trans(Tween.TRANS_CUBIC) \
				.set_ease(Tween.EASE_IN)
	for child in node.get_children():
		_wither_subtree(child, tw)
