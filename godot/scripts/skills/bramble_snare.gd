class_name BrambleSnare
extends Skill

# Spec 32b — slot 4. AoE root at aim_dir * SNARE_REACH, 2.5m radius. Extends
# Skill directly (not ProjectileSkill) — no arrow, no projectile_count. Owns
# its own fire() with the AoeQuery.query_circle pattern from spec 31.
#
# Spec-34 (Spell VFX Cookbook): rebuilt from the single-cylinder-alpha-fade
# pattern into the cookbook's 5-beat AoE structure. The principle: an AoE
# without a fairness window feels unfair (FFXIV's older telegraphs were
# routinely criticized for being instant). The fix is a 250-400ms telegraph
# growth before the effect actually lands — players in motion have a chance
# to exit. Once snapped, sustained brambles + an outward wither beat (not
# linear alpha fade) sells the spell as a thing that *happened* and *ended*.
#
# Beats (totals to 2.7s of visual; root effect applies for 2.0s starting at
# the snap, so the visual outlasts the root by ~0.4s during wither):
#   1. WINDUP        — player anim, deferred (needs anim rig)
#   2. TELEGRAPH_FILL — amber disc grows 0 → SNARE_RADIUS over 0.30s
#   3. THORN_SNAP    — disc snaps to emerald, 10 bramble spikes spring up
#   4. BODY          — sustained emerald + thorns for 2.0s
#   5. WITHER        — brambles curl down + disc alpha-out over 0.30s

const SNARE_RADIUS := 2.5
const SNARE_REACH := 4.0
const SNARE_DURATION := 2.0

# Cookbook timing — TELEGRAPH_FILL exceeds the 250ms reaction baseline so
# the AoE is dodgeable; the rest is visual polish that doesn't gate gameplay.
const TELEGRAPH_FILL_SEC := 0.30
const THORN_SNAP_SEC := 0.10
const WITHER_SEC := 0.30
const THORN_COUNT := 10

# Trace/harvest identity (per AAA creative-spell research): every BrambleSnare
# leaves N glowing thornwood pods inside the AoE that the player can walk
# through to collect. Visible decoration that turns "AoE that slows" into
# "cultivation that leaves a small economy on the field." Per the cookbook
# "third thing" framework — neither archetype (snare) nor element (nature)
# implies a harvestable resource; that's what makes it signature.
const THORNWOOD_POD_COUNT := 5
const THORNWOOD_POD_COLOR := Color(0.55, 0.95, 0.30)
const THORNWOOD_POD_GLOW := Color(0.85, 1.0, 0.55)

# Seed projectile — flies from the bow to the snare's landing point over
# SEED_FLIGHT_SEC, arcing upward at the apex (parabolic). On arrival, the
# 5-beat AoE plays at the landing point. This swaps the old instant-cast
# behavior for a thrown-projectile pattern (cookbook anticipation beat).
const SEED_FLIGHT_SEC := 0.40
const SEED_ARC_HEIGHT := 1.2          # how high the seed lobs at apex
const SEED_COLOR := Color(0.55, 0.85, 0.30)
const SEED_TRAIL_COUNT := 14

# AoE landing reticle — appears at cast time, persists through seed flight,
# fades when the actual telegraph disc takes over. Thin emissive ring on
# the ground so the player knows the AoE radius before anything lands.
const RETICLE_RING_WIDTH := 0.08       # thickness of the ring (m)
const RETICLE_COLOR := Color(0.55, 1.00, 0.45)
const RETICLE_FADE_OUT := 0.20         # how long it takes to fade once telegraph starts

const TEX_SOFT_CIRCLE := preload("res://assets/vfx/soft_circle.png")
const VINE_GROW_SHADER := preload("res://assets/vfx/vine_grow.gdshader")

const TELEGRAPH_COLOR := Color(0.95, 0.65, 0.20, 0.55)  # amber warning
const ACTIVE_COLOR := Color(0.30, 0.65, 0.25, 0.70)     # emerald root
const THORN_BASE_COLOR := Color(0.12, 0.06, 0.04)
const THORN_RIM_COLOR := Color(0.15, 0.32, 0.10)

func _init() -> void:
	name = "BrambleSnare"
	cost = 30.0
	base_cd = 4.0

func fire(player: Node) -> void:
	if player == null:
		return
	var dir: Vector3 = player.aim_dir() if player.has_method("aim_dir") \
		else Vector3.FORWARD
	var mesh = player.get("_mesh")
	if mesh != null:
		mesh.rotation.y = atan2(dir.x, dir.z)
	var aim: Vector3 = player.global_position + dir * SNARE_REACH
	aim.y = 0.05
	var origin: Vector3 = player.arrow_origin(dir) if player.has_method("arrow_origin") \
		else player.global_position + Vector3(0.0, 1.0, 0.0)
	# Spec-34 (variety research): landing reticle. Snap a bright green ring
	# onto the ground at the AoE's destination the INSTANT the cast key is
	# pressed — before the seed even leaves the bow. Player sees where the
	# spell will land immediately (Diablo/PoE/D4 standard). The reticle
	# stays visible through seed flight + telegraph, then the actual
	# telegraph disc takes over visually inside it.
	_spawn_landing_reticle(player, aim)
	# Throw the seed — it lobs from the bow toward the landing point. When
	# the seed arrives, _on_seed_land triggers the AoE.
	_spawn_seed_projectile(player, origin, aim)
	if player.has_method("apply_recoil"):
		player.apply_recoil(-0.25)
	var sfx = player.get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.play("skill_snare")

# Spec-34 variety research: AoE landing reticle. A thin emissive green
# ring snaps onto the ground at the landing position the instant fire()
# is called — telegraphs the AoE radius BEFORE the seed flight begins.
# Player commits to a cast and immediately knows where it will land.
# Reticle persists through SEED_FLIGHT_SEC, then fades over RETICLE_FADE_OUT
# as the actual telegraph disc takes over the same visual space.
func _spawn_landing_reticle(player: Node, landing: Vector3) -> void:
	# Spec-34: ground-flat textured quad. (Godot's Decal node projects
	# with sampling artifacts on high-contrast ring textures, so we use
	# a PlaneMesh + alpha texture lying flat just above the floor — same
	# visual read as a decal without the projection aliasing.) The ring
	# texture has a soft alpha gradient on both edges so it doesn't fight
	# the lit floor underneath.
	var ring := MeshInstance3D.new()
	ring.name = "BrambleSnareReticle"
	var pm := PlaneMesh.new()
	pm.size = Vector2(SNARE_RADIUS * 2.2, SNARE_RADIUS * 2.2)
	ring.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = RETICLE_COLOR
	mat.albedo_texture = preload("res://assets/vfx/reticle_ring.png")
	mat.emission_enabled = true
	mat.emission = RETICLE_COLOR
	mat.emission_energy_multiplier = 4.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = false
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring.material_override = mat
	# PlaneMesh defaults face +Y so it's already flat. Just sit it
	# slightly above the floor to beat z-fighting.
	ring.global_position = Vector3(landing.x, 0.05, landing.z)
	player.get_parent().add_child(ring)
	# Pop-in: scale from a pinprick to full over 80ms with BACK ease.
	ring.scale = Vector3(0.1, 1.0, 0.1)
	var pop := ring.create_tween()
	pop.tween_property(ring, "scale", Vector3.ONE, 0.08) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Gentle 6Hz pulse on emission so the reticle reads as live, not static.
	var pulse_loops: int = int((SEED_FLIGHT_SEC + TELEGRAPH_FILL_SEC) * 6.0)
	var pulse_tw := ring.create_tween().set_loops(maxi(1, pulse_loops))
	pulse_tw.tween_property(mat, "emission_energy_multiplier",
		6.5, 0.083).set_delay(0.10)
	pulse_tw.tween_property(mat, "emission_energy_multiplier",
		3.5, 0.083)
	# Fade out when the actual telegraph disc takes over.
	var fade_at := SEED_FLIGHT_SEC + TELEGRAPH_FILL_SEC - RETICLE_FADE_OUT
	player.get_tree().create_timer(maxf(0.05, fade_at)).timeout.connect(
		func() -> void:
			if not is_instance_valid(ring):
				return
			var out_tw := ring.create_tween()
			out_tw.set_parallel(true)
			out_tw.tween_property(mat, "albedo_color:a", 0.0, RETICLE_FADE_OUT)
			out_tw.tween_property(mat, "emission_energy_multiplier",
				0.0, RETICLE_FADE_OUT)
			out_tw.chain().tween_callback(ring.queue_free)
	)

# Build a small emissive seed that arcs from `origin` to `landing` over
# SEED_FLIGHT_SEC. Uses a manual position tween (linear horizontal +
# parabolic vertical) so the arc is visible without setting up a path.
# On landing, calls _on_seed_land which kicks off the 5-beat AoE.
func _spawn_seed_projectile(player: Node, origin: Vector3, landing: Vector3) -> void:
	var seed := MeshInstance3D.new()
	seed.name = "BrambleSeed"
	var sm := SphereMesh.new()
	sm.radius = 0.14
	sm.height = 0.28
	seed.mesh = sm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = SEED_COLOR
	smat.emission_enabled = true
	smat.emission = SEED_COLOR
	smat.emission_energy_multiplier = 3.5
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	seed.material_override = smat
	player.get_parent().add_child(seed)
	seed.global_position = origin
	# Trail particles streaming off the seed during flight.
	var trail := GPUParticles3D.new()
	trail.amount = SEED_TRAIL_COUNT
	trail.lifetime = 0.22
	trail.local_coords = false
	var tpm := ParticleProcessMaterial.new()
	tpm.direction = Vector3(0, 0, 1)
	tpm.spread = 25.0
	tpm.initial_velocity_min = 0.1
	tpm.initial_velocity_max = 0.4
	tpm.gravity = Vector3.ZERO
	tpm.scale_min = 0.4
	tpm.scale_max = 0.8
	tpm.color = SEED_COLOR
	var tgrad := Gradient.new()
	tgrad.set_color(0, Color(SEED_COLOR.r, SEED_COLOR.g, SEED_COLOR.b, 1.0))
	tgrad.set_color(1, Color(SEED_COLOR.r, SEED_COLOR.g, SEED_COLOR.b, 0.0))
	var tramp := GradientTexture1D.new()
	tramp.gradient = tgrad
	tpm.color_ramp = tramp
	trail.process_material = tpm
	# Spec-34: textured billboard particles for the seed's trail.
	var tqmesh := QuadMesh.new()
	tqmesh.size = Vector2(0.9, 0.9)                 # 3x bumped from 0.3
	var tqmat := StandardMaterial3D.new()
	tqmat.albedo_color = SEED_COLOR
	tqmat.albedo_texture = TEX_SOFT_CIRCLE
	tqmat.emission_enabled = true
	tqmat.emission = SEED_COLOR
	tqmat.emission_energy_multiplier = 1.8
	tqmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tqmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tqmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	tqmesh.material = tqmat
	trail.draw_pass_1 = tqmesh
	trail.emitting = true
	seed.add_child(trail)
	# Manual arc tween — interpolate position over SEED_FLIGHT_SEC with a
	# parabolic Y offset on top of the linear horizontal interp.
	_animate_seed_arc(seed, origin, landing, player, landing)

func _animate_seed_arc(seed: MeshInstance3D, origin: Vector3, landing: Vector3,
		player: Node, aim_world: Vector3) -> void:
	var elapsed: float = 0.0
	var tree := player.get_tree()
	# We tick on `process_frame` for smooth per-frame motion. The closure
	# captures elapsed by reference via an Array wrapper.
	var t_ref: Array = [0.0]
	var tick_cb := func() -> void:
		if not is_instance_valid(seed):
			return
		t_ref[0] += tree.get_root().get_process_delta_time()
		var t: float = clampf(t_ref[0] / SEED_FLIGHT_SEC, 0.0, 1.0)
		# Linear horizontal interpolation + parabolic vertical lob.
		var pos := origin.lerp(landing, t)
		pos.y += SEED_ARC_HEIGHT * sin(t * PI)
		seed.global_position = pos
	# Bind via signal so it runs each idle frame until landing.
	var sig: Callable = tick_cb
	tree.process_frame.connect(sig)
	# Schedule landing after SEED_FLIGHT_SEC.
	tree.create_timer(SEED_FLIGHT_SEC).timeout.connect(func() -> void:
		if tree.process_frame.is_connected(sig):
			tree.process_frame.disconnect(sig)
		if is_instance_valid(seed):
			seed.queue_free()
		_on_seed_land(player, aim_world)
	)

# Called by the seed projectile's landing timer. Identical to the original
# fire() body — kicks off the 5-beat AoE + applies the root after the
# telegraph fairness window.
func _on_seed_land(player: Node, aim: Vector3) -> void:
	if not is_instance_valid(player):
		return
	var holder: Node3D = _spawn_snare_visuals(player, aim)
	var tree := player.get_tree()
	tree.create_timer(TELEGRAPH_FILL_SEC).timeout.connect(func() -> void:
		# Spec-34 cookbook: each enemy caught is visibly TIED to the snare
		# center with a thorn-rope tether (the "third thing" — the move
		# that shifts the spell's read from 'AoE that slows' to 'the archer
		# binds'). Spawn the rope at the moment root applies — the player
		# sees the tether snap into existence as the catch lands.
		for enemy in AoeQuery.query_circle(tree, aim, SNARE_RADIUS):
			if enemy.has_method("apply_root"):
				enemy.apply_root(SNARE_DURATION)
				if is_instance_valid(holder) and enemy is Node3D:
					_spawn_tether(holder, enemy)
	)

# Build the 5-beat visual stack on a holder node. The holder's children
# share its lifetime — when the wither tween calls queue_free on the
# holder, the disc + every thorn vanish together. Returns the holder so
# _on_seed_land can attach per-enemy thorn-rope tethers as children.
func _spawn_snare_visuals(player: Node, aim: Vector3) -> Node3D:
	var holder := Node3D.new()
	holder.name = "BrambleSnareVisuals"
	holder.position = aim
	player.get_parent().add_child(holder)
	var disc := _make_ground_disc()
	holder.add_child(disc)
	var disc_mat: StandardMaterial3D = disc.material_override
	# BEAT 2 — TELEGRAPH_FILL: disc grows from a pinprick to full radius
	# with an amber warning color. CUBIC ease-out reads as a confident
	# expansion rather than a linear ramp.
	disc.scale = Vector3(0.05, 1.0, 0.05)
	var fill_tw := disc.create_tween()
	fill_tw.tween_property(disc, "scale", Vector3.ONE, TELEGRAPH_FILL_SEC) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# BEAT 3 — THORN_SNAP: color flips to emerald, 10 thorn spikes pop up
	# around the perimeter with a BACK ease so they overshoot slightly
	# before settling — the universal "thing-just-appeared" cue.
	fill_tw.tween_callback(func() -> void:
		disc_mat.albedo_color = ACTIVE_COLOR
		disc_mat.emission = Color(ACTIVE_COLOR.r, ACTIVE_COLOR.g, ACTIVE_COLOR.b)
		_spawn_thorns(holder)
	)
	# BEAT 4 — BODY: a subtle 4Hz pulse on disc emission energy so it
	# doesn't read as a static decal. The pulse runs concurrently with
	# the root effect's SNARE_DURATION.
	var pulse_tw := disc.create_tween().set_loops(int(SNARE_DURATION * 4.0))
	pulse_tw.tween_property(disc_mat, "emission_energy_multiplier",
		3.2, 0.125).set_delay(TELEGRAPH_FILL_SEC + THORN_SNAP_SEC)
	pulse_tw.tween_property(disc_mat, "emission_energy_multiplier",
		1.8, 0.125)
	# BEAT 5 — WITHER: schedule the dissipation. Thorns scale-y → 0 with
	# a CUBIC ease-in (slow-then-fast curl-down), disc alpha-outs in
	# parallel, holder queue_frees on completion so nothing leaks.
	var body_end := TELEGRAPH_FILL_SEC + THORN_SNAP_SEC + SNARE_DURATION
	player.get_tree().create_timer(body_end).timeout.connect(
		func() -> void: _wither(holder, disc_mat)
	)
	return holder

func _make_ground_disc() -> MeshInstance3D:
	var disc := MeshInstance3D.new()
	disc.name = "SnareDisc"
	var dm := CylinderMesh.new()
	dm.top_radius = SNARE_RADIUS
	dm.bottom_radius = SNARE_RADIUS
	dm.height = 0.06
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

func _spawn_thorns(holder: Node3D) -> void:
	# Spec-34 AAA session 1: thorns now grow via dissolve shader (base → tip
	# sweep with bright emissive edge) instead of scale-popping in. Each
	# thorn's `growth` uniform tweens 0 → 1 over THORN_SNAP_SEC with a
	# CUBIC ease-out — reads as a vine materializing from the ground.
	for i in THORN_COUNT:
		var angle: float = TAU * float(i) / float(THORN_COUNT)
		var radius: float = SNARE_RADIUS * 0.92
		var pos := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		var thorn := _make_thorn(pos, angle)
		holder.add_child(thorn)
		# Final scale is set; growth tween drives the visible "appearing".
		thorn.scale = Vector3.ONE
		var snap := thorn.create_tween()
		snap.tween_property(thorn.material_override,
				"shader_parameter/growth", 1.0, THORN_SNAP_SEC) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# Central anchor thorn — larger, slightly delayed so the eye reads
	# "the perimeter grew, then the center anchored." Same dissolve shader.
	var center := _make_thorn(Vector3.ZERO, 0.0)
	center.scale = Vector3(1.4, 1.4, 1.4)
	holder.add_child(center)
	var center_tw := center.create_tween()
	center_tw.tween_property(center.material_override,
			"shader_parameter/growth", 1.0, THORN_SNAP_SEC * 1.2) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT) \
		.set_delay(THORN_SNAP_SEC * 0.3)
	# Trace/harvest identity — scatter THORNWOOD_POD_COUNT glowing pods
	# inside the AoE. They appear at snap with a brief delay-cascade so
	# they read as "the snare deposited them" rather than "they were
	# always there." Player walks through them (or they remain after
	# wither) to collect thornwood.
	_spawn_thornwood_pods(holder)

func _spawn_thornwood_pods(holder: Node3D) -> void:
	# Scatter pods inside the AoE on a deterministic pattern (low randomness
	# so two captures of the same spell look similar). One central pod plus
	# THORNWOOD_POD_COUNT-1 around it on a ring at 60% of the snare radius.
	var inner_radius: float = SNARE_RADIUS * 0.55
	for i in THORNWOOD_POD_COUNT:
		var pos: Vector3
		if i == 0:
			pos = Vector3(0.1, 0.0, -0.2)         # central, slightly offset
		else:
			var a: float = TAU * float(i) / float(THORNWOOD_POD_COUNT - 1)
			# Small per-pod jitter so they're not on a perfect ring
			var r: float = inner_radius * (0.7 + (float(i) * 0.07))
			pos = Vector3(cos(a) * r, 0.0, sin(a) * r)
		var pod := _make_thornwood_pod()
		holder.add_child(pod)
		pod.position = pos
		# Pop-in: scale 0 → 1 with BACK ease, delayed per-pod so they
		# read as "appearing one by one" rather than "all at once."
		pod.scale = Vector3(0.1, 0.1, 0.1)
		var pop := pod.create_tween()
		pop.tween_property(pod, "scale", Vector3.ONE, 0.18) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT) \
			.set_delay(THORN_SNAP_SEC + (i * 0.04))
		# Idle bob: gentle vertical pulse so the pod reads as alive +
		# interactive, not static decoration. ~1.5 Hz, very subtle.
		var bob := pod.create_tween().set_loops(99)
		bob.tween_property(pod, "position:y", 0.15, 0.33) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT) \
			.set_delay(THORN_SNAP_SEC + 0.3)
		bob.tween_property(pod, "position:y", 0.0, 0.33) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _make_thornwood_pod() -> MeshInstance3D:
	# A small glowing egg-shape — leaf-wrapped seed pod. Cookbook would
	# call this "the trace" — the visible interactable left by the spell
	# that turns it from one-shot AoE into a small economy on the field.
	var pod := MeshInstance3D.new()
	pod.name = "ThornwoodPod"
	var sm := SphereMesh.new()
	sm.radius = 0.18
	sm.height = 0.42                          # elongated (egg, not ball)
	pod.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = THORNWOOD_POD_COLOR
	mat.emission_enabled = true
	mat.emission = THORNWOOD_POD_GLOW
	mat.emission_energy_multiplier = 3.2
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.rim_enabled = true
	mat.rim = 0.6
	mat.rim_tint = 0.0
	pod.material_override = mat
	return pod

func _make_thorn(pos: Vector3, angle: float) -> MeshInstance3D:
	var thorn := MeshInstance3D.new()
	thorn.name = "Thorn"
	# Tapered prism — narrow at the top, wider at base = thorn shape.
	var pm := PrismMesh.new()
	pm.size = Vector3(0.20, 0.95, 0.20)
	pm.left_to_right = 0.5            # symmetric taper
	thorn.mesh = pm
	# Spec-34 AAA session 1: ShaderMaterial wrapping vine_grow.gdshader.
	# Tweening the `growth` uniform 0 → 1 over THORN_SNAP_SEC makes the
	# thorn MATERIALIZE from base to tip rather than scale-popping in.
	# Bright emissive front sweeps along the dissolve boundary so the
	# eye reads it as a vine growing, not a polygon appearing.
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
	# Tilt thorns slightly outward (8° lean away from center) so they fan
	# instead of standing rigidly straight — reads more organic.
	thorn.rotation = Vector3(0.0, -angle + PI * 0.5, deg_to_rad(8.0))
	return thorn

# Spec-34 cookbook signature move: spawn a thorny rope from the snare
# center (holder position) to a caught enemy. The rope is N segmented
# thorn prisms along the line, each slightly rotated/scaled so the line
# reads as organic vine rather than a stretched cylinder. Parented to
# the holder so it withers + queue_frees together with the disc.
#
# Identity shift: with the tether, BrambleSnare reads as "the archer
# BINDS this target to the spot" rather than "the AoE happens to also
# slow this target". (Hades 2 Melinoë Cast pattern — third thing.)
const TETHER_SEGMENTS := 7
const TETHER_LIFT := 0.55           # arc apex height above the ground line

func _spawn_tether(holder: Node3D, target: Node3D) -> void:
	if not is_instance_valid(holder) or not is_instance_valid(target):
		return
	var tether := Node3D.new()
	tether.name = "Tether"
	holder.add_child(tether)
	# Compute the line from holder center to target body-center, then
	# stagger N segments along it with a parabolic Y lift so the rope
	# arcs slightly instead of running flat through the floor.
	var start_local := Vector3.ZERO                                  # holder origin
	var end_local: Vector3 = (target.global_position - holder.global_position) \
		+ Vector3(0.0, 0.5, 0.0)                                     # aim at enemy chest
	for i in TETHER_SEGMENTS:
		var t: float = float(i + 1) / float(TETHER_SEGMENTS + 1)     # 1/8 … 7/8
		var pos := start_local.lerp(end_local, t)
		pos.y += TETHER_LIFT * sin(t * PI)                           # parabolic arc
		var seg := MeshInstance3D.new()
		seg.name = "TetherSeg"
		var pm := PrismMesh.new()
		# Bigger + brighter than the perimeter thorns so the tether reads
		# as the SIGNATURE move, not just more decoration. The perimeter
		# thorns are scenery; the tethers are the per-target bind.
		pm.size = Vector3(0.26, 0.58, 0.26)
		pm.left_to_right = 0.5
		seg.mesh = pm
		# Spec-34 AAA session 1: same vine-grow dissolve as the thorns.
		# Tether segments materialize base → tip; the per-segment cascade
		# delay below (t * 0.04) now drives a "rope racing toward the
		# enemy" read instead of "thorns popping in sequence".
		var mat := ShaderMaterial.new()
		mat.shader = VINE_GROW_SHADER
		mat.set_shader_parameter("base_color", Color(0.20, 0.55, 0.18))
		mat.set_shader_parameter("edge_color", Color(0.55, 1.00, 0.40))
		mat.set_shader_parameter("growth", 0.0)
		mat.set_shader_parameter("edge_width", 0.18)
		mat.set_shader_parameter("edge_energy", 8.0)
		mat.set_shader_parameter("body_energy", 1.6)
		seg.material_override = mat
		seg.position = pos
		# Random per-segment rotation so the rope reads as twisted vine,
		# not a stretched cylinder — alternating Z tilt + Y yaw jitter.
		seg.rotation = Vector3(
			0.0,
			randf_range(-0.3, 0.3),
			(0.2 if i % 2 == 0 else -0.2) + randf_range(-0.15, 0.15)
		)
		tether.add_child(seg)
		# Spec-34 AAA session 1: drive the vine-grow shader's `growth`
		# uniform 0 → 1 instead of scale. The per-segment cascade delay
		# (t * 0.06 — bumped from 0.04 for a more readable chain) makes
		# the tether materialize from center outward toward the enemy,
		# with each segment's hot edge sweeping through it before the
		# next segment lights up. Reads as a rope RACING to the target.
		seg.scale = Vector3.ONE
		var snap_tw := seg.create_tween()
		snap_tw.tween_property(seg.material_override,
				"shader_parameter/growth", 1.0, THORN_SNAP_SEC * 1.5) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT) \
			.set_delay(t * 0.06)

# BEAT 5 dissipation. Spec-34 AAA session 1: thorns + tether segments
# wither via the SAME vine-grow shader, but with `growth` tweened
# 1 → 0 — vines retract from tip back to base (the dissolve front
# sweeps the OTHER direction). Disc alpha + emission fade in parallel.
# The shader's edge band glows hot as the wither passes, so the
# disappearance reads as the vines pulling themselves back.
func _wither(holder: Node3D, disc_mat: StandardMaterial3D) -> void:
	if not is_instance_valid(holder):
		return
	var tw := holder.create_tween()
	tw.set_parallel(true)
	tw.tween_property(disc_mat, "albedo_color:a", 0.0, WITHER_SEC)
	tw.tween_property(disc_mat, "emission_energy_multiplier",
		0.0, WITHER_SEC)
	# Recursively wither every vine-grow ShaderMaterial in the holder
	# subtree — covers thorns + tether segments + center anchor in one pass.
	_wither_subtree(holder, tw)
	tw.chain().tween_callback(holder.queue_free)

func _wither_subtree(node: Node, tw: Tween) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var mat = mi.material_override
		if mat is ShaderMaterial:
			tw.tween_property(mat, "shader_parameter/growth",
				0.0, WITHER_SEC).set_trans(Tween.TRANS_CUBIC) \
				.set_ease(Tween.EASE_IN)
	for child in node.get_children():
		_wither_subtree(child, tw)
