extends Node3D

# Spec 33a followup — ability-capture rig. Boots a minimal scene with the
# player + a dummy target, positions a camera, fires each of the 4 skills
# in sequence, and dumps frames to `user://captures/<ability>/<N>.png`.
# A companion shell script (`tools/capture-abilities.sh`) then stitches the
# frames into GIFs via ffmpeg and copies them into
# `docs/skills/captures/<ability>.gif` for the showcase site to embed.
#
# Run via:
#   godot --path godot --headless res://scenes/Capture.tscn
# (Headless mode renders to an offscreen viewport in Godot 4.x.)
#
# Tunables — adjust per ability if a longer/shorter clip reads better.

const PlayerScene := preload("res://scenes/Player.tscn")
const CombatantScript := preload("res://scripts/combatant.gd")
const BossScript := preload("res://scripts/boss.gd")
const HitstopScript := preload("res://scripts/hitstop.gd")
const SfxScript := preload("res://scripts/sfx.gd")

const FRAMES_PER_ABILITY := 90        # 90 frames at 60fps ≈ 1.5s of footage
const PRE_FIRE_FRAMES := 15           # idle frames before the cast
const POST_FIRE_FRAMES := 75          # cast + flight + impact + fade
const SETUP_DELAY_FRAMES := 60        # 1s pause between abilities for cleanup

# Each capture has a kind and per-kind params. The capture loop dispatches to
# the matching _capture_<kind>() function. Slugs MUST match the slugs in
# tools/capture-abilities.sh and the <video src=…> tags in
# docs/skills/index.html.
const ABILITIES := [
	# The four skills (slot fires the corresponding ability):
	{"slug": "basicshot",   "kind": "skill",  "slot": 1},
	{"slug": "powershot",   "kind": "skill",  "slot": 2},
	{"slug": "multishot",   "kind": "skill",  "slot": 3},
	{"slug": "snare",       "kind": "skill",  "slot": 4},
	# The four statuses — applied to the rooted dummy, manually ticked so
	# the visual + flash + damage numbers play out without needing the
	# dummy's _physics_process enabled.
	{"slug": "burn",        "kind": "status", "status": "burn",
		"duration": 3.0, "dpt": 1, "slow": 1.0, "tick": 0.5},
	{"slug": "bleed",       "kind": "status", "status": "bleed",
		"duration": 4.0, "dpt": 2, "slow": 1.0, "tick": 1.0},
	{"slug": "snared",      "kind": "status", "status": "snared",
		"duration": 1.5, "dpt": 0, "slow": 0.5, "tick": 0.0},
	{"slug": "root",        "kind": "status", "status": "root",
		"duration": 2.0, "dpt": 0, "slow": 1.0, "tick": 0.0},
	# The four elite modifiers — applied to the rooted dummy. Brambled
	# fires its bleed-nova mid-clip; sunlit fires its burn-pulse; the
	# others show their golden tint + feet ring + scale bump baseline.
	{"slug": "brambled",    "kind": "elite",  "modifier": "brambled"},
	{"slug": "swift",       "kind": "elite",  "modifier": "swift"},
	{"slug": "sunlit",      "kind": "elite",  "modifier": "sunlit"},
	{"slug": "briarbound",  "kind": "elite",  "modifier": "briarbound"},
	# The boss — instantiated fresh (not the dummy), telegraphs a sweep.
	{"slug": "hedgemother", "kind": "boss"},
]

var _player: Node3D
var _dummy: Node3D
var _camera: Camera3D
# Per-kind dummy position — status captures move the dummy OFF-AXIS so its
# status particles aren't occluded by the player's silhouette. Skills /
# elites / boss keep the dummy centered (their impact bursts are bigger
# than the player's body and read regardless).
var _dummy_target_pos := Vector3(0, 0, 6.0)
const DUMMY_POS_CENTERED := Vector3(0, 0, 6.0)
const DUMMY_POS_OFFAXIS := Vector3(2.2, 0, 5.0)

func _ready() -> void:
	print("[capture] capture rig booting")
	# Install the autoloads the harness may skip — but only if they aren't
	# already present (they load as real autoloads when run as a scene), and
	# deferred so root isn't mid-setup ("Parent node is busy" otherwise).
	var root := get_tree().root
	if root.get_node_or_null("Hitstop") == null:
		var hs: Node = HitstopScript.new()
		hs.name = "Hitstop"
		root.add_child.call_deferred(hs)
	if root.get_node_or_null("Sfx") == null:
		var sx: Node = SfxScript.new()
		sx.name = "Sfx"
		root.add_child.call_deferred(sx)
	# Ambient light (without the dungeon's WorldEnvironment the scene is dark).
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_energy = 0.9
	add_child(sun)
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.6, 0.65)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.ambient_light_energy = 0.6
	# Glow + filmic tonemap — without these the emission_energy_multiplier
	# values in hit_spark / arrow / boss / combatant clamp to white instead
	# of blooming. Enabling glow turns every emissive particle into actual
	# light spill and is the biggest visible-detail jump available for the
	# showcase captures. (Forward+ rendering only; this rig is.)
	env.glow_enabled = true
	env.glow_normalized = true
	env.glow_intensity = 0.8
	env.glow_bloom = 0.1
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env_node.environment = env
	add_child(env_node)
	# Floor (so arrows have somewhere to hit for ground-AoE casts).
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 0.2, 20)
	floor_shape.shape = box
	floor_shape.position = Vector3(0, -0.1, 0)
	floor_body.add_child(floor_shape)
	var floor_mesh := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(20, 20)
	floor_mesh.mesh = pm
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.55, 0.50, 0.45)
	floor_mat.roughness = 0.95
	floor_mesh.material_override = floor_mat
	floor_body.add_child(floor_mesh)
	add_child(floor_body)
	# Camera — mirror the in-game CameraRig (Diablo 3/4 behind the player).
	# Empirically this rig's player mesh faces +Z (not Godot's -Z default),
	# so arrows fire toward +Z and the dummy must sit on the +Z side. The
	# camera then goes BEHIND the player at -Z, looking +Z forward toward
	# the dummy. PITCH_DEFAULT 55°, ZOOM_DEFAULT 17, TARGET_HEIGHT 1.0 — all
	# mirrored from in-game CameraRig so the showcase reads at the same
	# angle the player sees while playing.
	const _PITCH := 28.0              # in-game default is 55 (Diablo 3/4);
	                                  # showcase wants a flatter, more
	                                  # behind-the-shoulder angle so the
	                                  # arrow flight reads horizontally,
	                                  # not as a top-down dot.
	const _ZOOM := 6.0                # in-game default is 17; showcase wants
	                                  # tight so arrow + impact spark + damage
	                                  # number all read clearly in the embed.
	const _TARGET_H := 1.0
	_camera = Camera3D.new()
	add_child(_camera)                  # MUST be in the tree before look_at()
	var _pivot := Vector3(0.0, _TARGET_H, 0.0)
	var _horiz := cos(deg_to_rad(_PITCH))
	# Camera at -Z (behind the +Z-facing player), looking forward toward +Z.
	var _offset := Vector3(
		0.0,
		sin(deg_to_rad(_PITCH)),
		-_horiz
	) * _ZOOM
	_camera.global_position = _pivot + _offset
	_camera.look_at(_pivot, Vector3.UP)
	_camera.current = true
	# Player at origin.
	_player = PlayerScene.instantiate()
	add_child(_player)
	_player.global_position = Vector3.ZERO
	# Dummy target 6m downrange. This rig's player mesh actually faces +Z
	# (verified by where the arrows fly), so the dummy goes on the +Z side
	# for impacts to land + read in the showcase.
	_dummy = CombatantScript.new()
	add_child(_dummy)
	_dummy.global_position = Vector3(0, 0, 6.0)
	_dummy.add_to_group("enemy")
	# Give the dummy a visible mesh so impacts read.
	var dmesh := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.height = 1.6
	cap.radius = 0.4
	dmesh.mesh = cap
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.42, 0.32, 0.24)
	dmesh.material_override = dmat
	_dummy.add_child(dmesh)
	_dummy.cache_meshes()
	_dummy.setup(999999, 0.4, 1.4)          # huge HP — paired with
	                                         # _keep_dummy_fresh() each frame
	                                         # to make the dummy unkillable
	# Disable the dummy's _physics_process so knockback never moves it,
	# status DOTs never tick, and AI state can't transition. Hits still
	# register because take_damage() is called directly from the arrow's
	# collision signal — it doesn't depend on _physics_process running.
	_dummy.set_physics_process(false)
	# Ensure the user://captures dir exists.
	DirAccess.make_dir_recursive_absolute("user://captures")
	# Wait a couple frames for everything to wire up, then start the cycle.
	await get_tree().process_frame
	await get_tree().process_frame
	await _capture_all_abilities()
	print("[capture] done — frames written under user://captures/<slug>/")
	get_tree().quit()

func _capture_all_abilities() -> void:
	for ability in ABILITIES:
		await _capture_one(ability)

func _capture_one(ability: Dictionary) -> void:
	var slug: String = String(ability.slug)
	var kind: String = String(ability.get("kind", "skill"))
	print("[capture] %s — %s" % [slug, kind])
	DirAccess.make_dir_recursive_absolute("user://captures/%s" % slug)
	# Reset shared state before every cycle. The four kinds each have their
	# own setup/fire phase; the pre-frames / post-frames bookkeeping is
	# identical so they share `_capture_loop()`.
	_dummy.hp = _dummy.hp_max
	# Free every status visual (queue_free + dict clear) so a bleed status
	# from a previous ability cycle doesn't leak red drops into the next
	# clip. A bare `_statuses.clear()` orphans the visual GPUParticles3D
	# nodes — they keep emitting parented to the dummy.
	if _dummy.has_method("_clear_all_statuses"):
		_dummy._clear_all_statuses()
	else:
		_dummy._statuses.clear()
	_dummy.dead = false
	# Default centered position; _capture_status overrides to off-axis.
	_dummy_target_pos = DUMMY_POS_CENTERED
	_dummy.global_position = _dummy_target_pos
	_dummy.scale = _dummy._base_scale
	# Strip any elite tint/ring from the previous cycle. apply_elite() is
	# idempotent (it bails on re-call), so we have to manually un-elite the
	# dummy here for the next cycle to apply a fresh modifier.
	_reset_elite_state(_dummy)
	if _player.get("_mesh") != null:
		_player._mesh.rotation.y = 0.0
	# Refill Focus + clear cooldowns so every ability fires immediately.
	_player.focus = _player.focus_max
	for k in _player._skill_cooldowns:
		_player._skill_cooldowns[k] = 0.0
	# Dispatch to the kind-specific path. Each returns after writing the
	# 90-frame clip; they only differ in the setup + fire stages.
	match kind:
		"skill":  await _capture_skill(slug, ability)
		"status": await _capture_status(slug, ability)
		"elite":  await _capture_elite(slug, ability)
		"boss":   await _capture_boss(slug, ability)
		_:        push_warning("[capture] unknown kind: %s" % kind)
	# Cooldown pause — clear orphan arrows + reset for the next ability.
	# Between-cycle cleanup: free transient nodes left from this ability so
	# the next clip doesn't inherit any leftover visuals (snare disc + thorns,
	# bramble seed, power AoE ring, etc). Match by name prefix.
	const TRANSIENT_PREFIXES := [
		"@Node3D@",                # default name for unnamed Node3D arrows
		"BrambleSnareVisuals",     # snare holder (disc + thorns)
		"BrambleSnareReticle",     # snare landing reticle
		"BrambleSeed",             # snare's thrown projectile
		"MultiShotFanBurst",       # multishot cast burst
	]
	for n in _all_named_any(get_tree().root, TRANSIENT_PREFIXES):
		if n != self and is_instance_valid(n):
			n.queue_free()
	for i in SETUP_DELAY_FRAMES:
		await RenderingServer.frame_post_draw

# Skill clip: pre-frames idle, then fire the indexed skill, then post-frames
# for flight + impact + fade. The original 4-skill behaviour, unchanged.
func _capture_skill(slug: String, ability: Dictionary) -> void:
	var slot: int = int(ability.slot)
	var frame_n := 0
	for i in PRE_FIRE_FRAMES:
		_keep_dummy_fresh()
		await RenderingServer.frame_post_draw
		_save_frame(slug, frame_n)
		frame_n += 1
	if slot == 1:
		_player.skills[0].fire(_player)
		_player._skill_cooldowns[1] = _player.skills[0].effective_cd(_player)
	else:
		_player.skills[slot - 1].fire(_player)
		_player._skill_cooldowns[slot] = _player.skills[slot - 1].effective_cd(_player)
		_player.focus -= float(_player.skills[slot - 1].cost)
	for i in POST_FIRE_FRAMES:
		_keep_dummy_fresh()
		await RenderingServer.frame_post_draw
		_save_frame(slug, frame_n)
		frame_n += 1

# Status clip: pre-frames idle, apply the status, then advance ticks manually
# each frame so the visual + flash + damage numbers play out without the
# dummy's _physics_process (which we keep disabled so the dummy doesn't
# move or _die).
func _capture_status(slug: String, ability: Dictionary) -> void:
	# Move dummy off-axis so its status particles aren't occluded by the
	# player's silhouette at this camera angle. Player still faces +Z; the
	# dummy is just to the side so the status visuals have a clear sightline.
	_dummy_target_pos = DUMMY_POS_OFFAXIS
	_dummy.global_position = _dummy_target_pos
	var status_kind: String = String(ability.status)
	var duration: float = float(ability.get("duration", 3.0))
	var dpt: int = int(ability.get("dpt", 0))
	var slow: float = float(ability.get("slow", 1.0))
	var tick: float = float(ability.get("tick", 0.0))
	var frame_n := 0
	for i in PRE_FIRE_FRAMES:
		_keep_dummy_fresh()
		await RenderingServer.frame_post_draw
		_save_frame(slug, frame_n)
		frame_n += 1
	_dummy.apply_status(status_kind, duration, dpt, slow, tick)
	for i in POST_FIRE_FRAMES:
		_dummy._tick_statuses(1.0 / 60.0)   # manual tick (no _physics_process)
		_keep_dummy_fresh()
		await RenderingServer.frame_post_draw
		_save_frame(slug, frame_n)
		frame_n += 1

# Elite clip: pre-frames idle, promote the dummy to elite (golden tint, scale
# bump, feet ring all appear), then trigger the modifier's signature
# behaviour mid-clip if there is one (Brambled's bleed-nova, Sunlit's
# burn-pulse). Swift + Briarbound just show the elite visual identity.
func _capture_elite(slug: String, ability: Dictionary) -> void:
	var modifier: String = String(ability.modifier)
	var frame_n := 0
	for i in PRE_FIRE_FRAMES:
		_keep_dummy_fresh()
		await RenderingServer.frame_post_draw
		_save_frame(slug, frame_n)
		frame_n += 1
	_dummy.apply_elite(modifier)
	# Capture 20 frames at the elite-baseline visual, then trigger the
	# modifier-specific FX so it lands mid-clip and has time to read.
	var trigger_frame: int = PRE_FIRE_FRAMES + 20
	for i in POST_FIRE_FRAMES:
		if frame_n == trigger_frame:
			_trigger_elite_fx(modifier)
		_keep_dummy_fresh()
		await RenderingServer.frame_post_draw
		_save_frame(slug, frame_n)
		frame_n += 1

# Boss clip: free the dummy + spawn a Hedgemother in its place (boss.gd is a
# subclass of combatant.gd with sweep/stomp telegraph attacks). Pre-frames
# show her idle, then she telegraphs a sweep — the red ground decal pulses
# during the wind-up, then snaps to full alpha at resolution.
func _capture_boss(slug: String, _ability: Dictionary) -> void:
	# Park the dummy off-screen for this cycle; we want the boss centered.
	_dummy.global_position = Vector3(50, -10, 0)
	var boss := BossScript.new()
	add_child(boss)
	boss.global_position = Vector3(0, 0, 6.0)
	boss.add_to_group("enemy")
	# Give the boss a chunky visible mesh so she reads (boss.gd just defines
	# the script — the mesh is normally attached by layout_loader; here we
	# attach a fallback so the showcase clip isn't an empty silhouette).
	var bmesh := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.height = 2.6
	cap.radius = 0.9
	bmesh.mesh = cap
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.30, 0.45, 0.32)         # mossy-green
	bmesh.material_override = bmat
	boss.add_child(bmesh)
	boss.cache_meshes()
	boss.setup(150, 0.9, 3.0)
	boss.set_physics_process(false)                     # same trick as dummy
	var frame_n := 0
	for i in PRE_FIRE_FRAMES:
		await RenderingServer.frame_post_draw
		_save_frame(slug, frame_n)
		frame_n += 1
	# Trigger the sweep telegraph. boss.gd's `_begin_attack()` builds the
	# red ground decal and starts the wind-up timer; we capture through
	# resolution so the disc pulse + snap reads on the clip.
	if boss.has_method("_begin_attack"):
		boss._begin_attack()
	for i in POST_FIRE_FRAMES:
		await RenderingServer.frame_post_draw
		_save_frame(slug, frame_n)
		frame_n += 1
	# Clean up the boss so the next cycle's dummy is the only target.
	if is_instance_valid(boss):
		boss.queue_free()
	# Restore the dummy back to its centered position for subsequent cycles.
	_dummy.global_position = Vector3(0, 0, 6.0)

# Trigger the modifier's signature FX directly. apply_elite() handles the
# visual identity (tint, ring, scale); these handlers fire the bound on-X
# behaviour without needing real combat to wire it up.
func _trigger_elite_fx(modifier: String) -> void:
	if modifier == "brambled" and _dummy.has_method("_trigger_bleed_nova"):
		_dummy._trigger_bleed_nova()
	elif modifier == "sunlit" and _dummy.has_method("_trigger_burn_pulse"):
		_dummy._trigger_burn_pulse()
	# swift + briarbound have no callable "fire" — their visual identity
	# (elite tint + ring + scale, + briarbound's purple-thorn tint) IS the
	# distinguishing thing for the showcase clip.

# Un-elite a combatant so the next capture starts from a clean baseline.
# apply_elite() is idempotent (bails on re-call), so manually undoing the
# state it sets is what lets one dummy be re-used across all 4 modifiers.
func _reset_elite_state(c: Node) -> void:
	if not is_instance_valid(c):
		return
	c.is_elite = false
	c.modifier = ""
	# Drop the elite ring if one was attached.
	if c.get("_elite_ring") != null and is_instance_valid(c._elite_ring):
		c._elite_ring.queue_free()
		c._elite_ring = null
	# Restore mesh albedo (apply_elite overrides material to gold tint).
	if c.has_method("_restore_flash"):
		c._restore_flash()
	c.scale = c._base_scale

func _keep_dummy_fresh() -> void:
	# Fully un-die the dummy each frame: snap position back, restore HP +
	# scale, kill any in-progress death tween (the combatant._die() tween
	# decays position.y by 1.6m and scale to 0.05× over 0.4s — without this
	# reset, a single hit triggers the tween and the dummy sinks + shrinks
	# out of frame before the capture window completes).
	if not is_instance_valid(_dummy):
		return
	_dummy.dead = false
	_dummy.hp = _dummy.hp_max
	_dummy.global_position = _dummy_target_pos
	_dummy.velocity = Vector3.ZERO
	_dummy.scale = _dummy._base_scale

func _save_frame(slug: String, idx: int) -> void:
	# Grab AFTER the GPU has drawn this frame, else the viewport texture is
	# empty and get_image() returns null (0 frames written).
	await RenderingServer.frame_post_draw
	var tex := get_viewport().get_texture()
	if tex == null:
		return
	var img := tex.get_image()
	if img == null:
		return
	var path := "user://captures/%s/%04d.png" % [slug, idx]
	img.save_png(path)

# Recursively collect nodes whose name starts with `prefix` (used to clear
# orphaned arrows between captures — they have names like `@Node3D@N`).
func _all_named(node: Node, prefix: String) -> Array:
	var out: Array = []
	if String(node.name).begins_with(prefix):
		out.append(node)
	for c in node.get_children():
		out.append_array(_all_named(c, prefix))
	return out

# Same as _all_named but matches any of N prefixes — used by the between-
# cycle cleanup to catch transient nodes from multiple sources.
func _all_named_any(node: Node, prefixes: Array) -> Array:
	var out: Array = []
	var name_str := String(node.name)
	for p in prefixes:
		if name_str.begins_with(String(p)):
			out.append(node)
			break
	for c in node.get_children():
		out.append_array(_all_named_any(c, prefixes))
	return out
