class_name RainOfThorns
extends Skill

# B5 — a delayed thorn volley at the aim point: 0.6s telegraph disc, then
# every enemy inside takes damage and a short bleed. The zone-control nuke
# next to BrambleSnare's lockdown.
#
# Spec-34 4-beat VFX stack (overhead-arrival identity — calls DOWN, not erupts):
#   Beat 1 — Landing reticle: amber ring snaps to ground at cast time
#   Beat 2 — Fill: amber disc grows from pinprick to RADIUS over FILL_SEC
#   Beat 3 — Impact: disc snaps thorn-green, 6 thorn prisms spring up, burst
#   Beat 4 — Wither: thorns retract + disc alpha-out over WITHER_SEC
#
# Phase 1 correctness fixes (2026-06-16):
#   - CAST_RANGE / MAX_RANGE replace the misleading RANGE+minf pattern
#   - crit_chance / crit_mult_bonus forwarded to take_damage
#   - bleed dpt scales off player.derived_stats.damage * 0.10
#   - SFX key corrected to skill_rain_of_thorns
#
# Balance: 32 Focus / 5s CD / 1.8× damage / 0.6s delay — the delay lowers
# effective value vs. Thornburst; compensated by the bleed secondary damage
# (~11% of base hit at damage=50). Playtest sign-off pending (Phase 3).

const AoeQuery   := preload("res://scripts/aoe_query.gd")
const SkillEffect := preload("res://scripts/skills/skill_effect.gd")

# ---------- tune constants ----------
const RADIUS    := 2.6
const DELAY     := 0.6
const DMG_MULT  := 1.8

# Phase 1: rename — CAST_RANGE is the effective throw distance used in fire();
# MAX_RANGE is reserved for a future upgrade tier (9.0 m outer cap).
const CAST_RANGE := 6.0
const MAX_RANGE  := 9.0

# ---------- VFX timing ----------
const FILL_SEC        := 0.40   # disc grow window (2/3 of DELAY)
const IMPACT_SNAP_SEC := 0.10   # snap + thorn appear
const WITHER_BODY_SEC := 0.15   # pause between snap and wither start
const WITHER_SEC      := 0.25   # thorn retract + disc fade

# ---------- VFX identity ----------
const THORN_COUNT     := 6
const AMBER_COLOR     := Color(0.95, 0.55, 0.15, 0.40)
const AMBER_EMIT      := Color(0.95, 0.55, 0.15)
const THORN_DISC_COLOR := Color(0.30, 0.65, 0.25, 0.55)
const RETICLE_COLOR   := Color(0.95, 0.70, 0.20)
const THORN_BASE_COLOR := Color(0.12, 0.06, 0.04)

# ---------- preloads (never inside _draw) ----------
const TEX_RETICLE_RING := preload("res://assets/vfx/reticle_ring.png")
const VINE_GROW_SHADER := preload("res://assets/vfx/vine_grow.gdshader")

func _init() -> void:
	name = "RainOfThorns"
	cost = 32.0
	base_cd = 5.0

func fire(player: Node) -> void:
	if player == null:
		return

	# Phase 3: cast recoil (no-op on mock players)
	if player.has_method("apply_recoil"):
		player.apply_recoil(-0.3)

	var dir: Vector3 = player.aim_dir() if player.has_method("aim_dir") \
		else Vector3.FORWARD
	var center: Vector3 = player.global_position + dir.normalized() * CAST_RANGE
	center.y = player.global_position.y
	var tree := player.get_tree()
	var dmg: int = int(round(float(player.derived_stats.damage) * DMG_MULT))

	# Build the full 4-beat VFX holder; capture disc material ref for later beats.
	var disc_mat_ref: StandardMaterial3D = StandardMaterial3D.new()
	var holder: Node3D = _telegraph(player, center, disc_mat_ref)

	# Detonation timer
	tree.create_timer(DELAY).timeout.connect(func() -> void:
		# Beat 3 impact VFX
		_on_detonate(holder, disc_mat_ref, player)
		# Apply damage + bleed to every enemy in range
		for c: Node in AoeQuery.query_circle(tree, center, RADIUS):
			if c != null and is_instance_valid(c) and not c.dead:
				var to: Vector3 = c.global_position - center
				to.y = 0.0
				# Phase 1: forward crit stats to take_damage
				c.take_damage(dmg, to.normalized(),
					float(player.derived_stats.crit_chance),
					float(player.derived_stats.crit_mult_bonus))
				# Phase 1: bleed scales off attack damage
				var dpt: int = maxi(1, int(float(player.derived_stats.damage) * 0.10))
				SkillEffect.bleed(2.0, dpt, 0.5).apply(c)
		# Schedule Beat 4 wither
		tree.create_timer(IMPACT_SNAP_SEC + WITHER_BODY_SEC).timeout.connect(
			func() -> void: _wither(holder, disc_mat_ref)
		)
	)

	# Phase 1: correct SFX key
	var sfx: Node = player.get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.play("skill_rain_of_thorns")

# ---------- VFX builder — returns holder Node3D ----------
# All beats are children of the holder so they outlive any mid-delay player
# death and vanish together on queue_free.
func _telegraph(player: Node, center: Vector3,
		disc_mat_ref: StandardMaterial3D) -> Node3D:
	var holder := Node3D.new()
	holder.name = "RainOfThornsVisuals"
	holder.position = center
	player.get_parent().add_child(holder)

	# Beat 1: landing reticle
	_spawn_landing_reticle(player, holder)

	# Beat 2: fill disc — populate disc_mat_ref in-place so fire() can share it
	_spawn_fill_disc(holder, disc_mat_ref)

	return holder

# ---------- Beat 1 — landing reticle ----------
# Thin amber emissive ring on the ground at cast time. Identical purpose to
# BrambleSnare's _spawn_landing_reticle but amber-tinted (overhead-arrival
# identity) and fades exactly when the disc reaches full size.
func _spawn_landing_reticle(player: Node, holder: Node3D) -> void:
	var ring := MeshInstance3D.new()
	ring.name = "RainReticle"
	var pm := PlaneMesh.new()
	pm.size = Vector2(RADIUS * 2.2, RADIUS * 2.2)
	ring.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = RETICLE_COLOR
	mat.albedo_texture = TEX_RETICLE_RING
	mat.emission_enabled = true
	mat.emission = RETICLE_COLOR
	mat.emission_energy_multiplier = 4.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring.material_override = mat
	# Holder origin is at center with y = ground level; sit ring slightly above
	ring.position = Vector3(0.0, 0.05, 0.0)
	holder.add_child(ring)
	# Pop-in: scale from pinprick to full over 80ms with BACK ease
	ring.scale = Vector3(0.1, 1.0, 0.1)
	var pop := ring.create_tween()
	pop.tween_property(ring, "scale", Vector3.ONE, 0.08) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# 6 Hz pulse for the full DELAY window so the reticle reads as live
	var pulse_loops: int = maxi(1, int(DELAY * 6.0))
	var pulse_tw := ring.create_tween().set_loops(pulse_loops)
	pulse_tw.tween_property(mat, "emission_energy_multiplier",
		6.5, 0.083).set_delay(0.10)
	pulse_tw.tween_property(mat, "emission_energy_multiplier",
		3.5, 0.083)
	# Fade out as the disc fills — starts at DELAY - 0.20s
	var fade_at: float = maxf(0.05, DELAY - 0.20)
	player.get_tree().create_timer(fade_at).timeout.connect(func() -> void:
		if not is_instance_valid(ring):
			return
		var out_tw := ring.create_tween()
		out_tw.set_parallel(true)
		out_tw.tween_property(mat, "albedo_color:a", 0.0, 0.20)
		out_tw.tween_property(mat, "emission_energy_multiplier", 0.0, 0.20)
		out_tw.chain().tween_callback(ring.queue_free)
	)

# ---------- Beat 2 — telegraph fill disc ----------
# Amber cylinder grows from a pinprick to RADIUS over FILL_SEC.
# disc_mat_ref is a shared StandardMaterial3D already created by fire(); this
# function configures and returns it so Beat 3 can mutate the color in place.
func _spawn_fill_disc(holder: Node3D,
		disc_mat: StandardMaterial3D) -> MeshInstance3D:
	var disc := MeshInstance3D.new()
	disc.name = "RainDisc"
	var cyl := CylinderMesh.new()
	cyl.top_radius = RADIUS
	cyl.bottom_radius = RADIUS
	cyl.height = 0.06
	disc.mesh = cyl
	# Configure the passed-in material so callers share the same reference
	disc_mat.albedo_color = AMBER_COLOR
	disc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disc_mat.emission_enabled = true
	disc_mat.emission = AMBER_EMIT
	disc_mat.emission_energy_multiplier = 2.0
	disc.material_override = disc_mat
	# Position at holder origin (holder.position == center already)
	disc.position = Vector3(0.0, 0.06, 0.0)
	holder.add_child(disc)
	# Grow from pinprick → full scale over FILL_SEC
	disc.scale = Vector3(0.02, 1.0, 0.02)
	var fill_tw := disc.create_tween()
	fill_tw.tween_property(disc, "scale", Vector3.ONE, FILL_SEC) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return disc

# ---------- Beat 3 — impact: snap + thorn-ring + emission burst ----------
func _on_detonate(holder: Node3D, disc_mat: StandardMaterial3D,
		player: Node) -> void:
	if not is_instance_valid(holder):
		return
	# Snap disc color from amber to thorn-green
	disc_mat.albedo_color = THORN_DISC_COLOR
	disc_mat.emission = Color(THORN_DISC_COLOR.r, THORN_DISC_COLOR.g,
		THORN_DISC_COLOR.b)
	# Emission burst: 1.5 → 5.0 → 1.5 over IMPACT_SNAP_SEC
	var burst_tw := holder.create_tween()
	burst_tw.tween_property(disc_mat, "emission_energy_multiplier",
		5.0, IMPACT_SNAP_SEC * 0.5)
	burst_tw.tween_property(disc_mat, "emission_energy_multiplier",
		1.5, IMPACT_SNAP_SEC * 0.5)
	# Ring of THORN_COUNT thorns around the perimeter
	_spawn_thorns(holder)
	# Camera micro-kick — graceful if shake node absent or WYRD_SHAKE="0"
	if OS.get_environment("WYRD_SHAKE") != "0":
		var cam_parent: Node = player.get_node_or_null("/root/CameraShake")
		if cam_parent != null and cam_parent.has_method("add_trauma"):
			cam_parent.add_trauma(0.04)

# Spawn THORN_COUNT prisms around the perimeter using vine_grow.gdshader
func _spawn_thorns(holder: Node3D) -> void:
	for i: int in THORN_COUNT:
		var angle: float = TAU * float(i) / float(THORN_COUNT)
		var radius: float = RADIUS * 0.92
		var pos := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		var thorn := _make_thorn(pos, angle)
		holder.add_child(thorn)
		thorn.scale = Vector3.ONE
		var snap := thorn.create_tween()
		snap.tween_property(thorn.material_override,
				"shader_parameter/growth", 1.0, IMPACT_SNAP_SEC) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

# Build a single thorn prism with vine_grow.gdshader (growth starts at 0).
# Matches BrambleSnare's _make_thorn geometry + shader setup, amber-accented
# edge color to distinguish from BrambleSnare's pure-green read.
func _make_thorn(pos: Vector3, angle: float) -> MeshInstance3D:
	var thorn := MeshInstance3D.new()
	thorn.name = "Thorn"
	var pm := PrismMesh.new()
	pm.size = Vector3(0.20, 0.95, 0.20)
	pm.left_to_right = 0.5
	thorn.mesh = pm
	var mat := ShaderMaterial.new()
	mat.shader = VINE_GROW_SHADER
	mat.set_shader_parameter("base_color", THORN_BASE_COLOR)
	mat.set_shader_parameter("edge_color", Color(0.65, 0.90, 0.20))  # amber-green
	mat.set_shader_parameter("growth", 0.0)
	mat.set_shader_parameter("edge_width", 0.12)
	mat.set_shader_parameter("edge_energy", 6.0)
	mat.set_shader_parameter("body_energy", 0.8)
	thorn.material_override = mat
	thorn.position = pos
	thorn.rotation = Vector3(0.0, -angle + PI * 0.5, deg_to_rad(8.0))
	return thorn

# ---------- Beat 4 — wither ----------
# Thorns retract (growth 1 → 0) + disc alpha-out in parallel; queue_free holder.
func _wither(holder: Node3D, disc_mat: StandardMaterial3D) -> void:
	if not is_instance_valid(holder):
		return
	var tw := holder.create_tween()
	tw.set_parallel(true)
	tw.tween_property(disc_mat, "albedo_color:a", 0.0, WITHER_SEC)
	tw.tween_property(disc_mat, "emission_energy_multiplier", 0.0, WITHER_SEC)
	_wither_subtree(holder, tw)
	tw.chain().tween_callback(holder.queue_free)

# Recurse the holder subtree and retract every vine-grow ShaderMaterial.
# Copied verbatim from bramble_snare.gd — no BrambleSnare-specific logic.
func _wither_subtree(node: Node, tw: Tween) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		var mat: Material = mi.material_override
		if mat is ShaderMaterial:
			tw.tween_property(mat, "shader_parameter/growth",
				0.0, WITHER_SEC).set_trans(Tween.TRANS_CUBIC) \
				.set_ease(Tween.EASE_IN)
	for child: Node in node.get_children():
		_wither_subtree(child, tw)
