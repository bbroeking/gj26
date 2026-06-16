extends Node3D

# Animation gallery / model viewer — a dev page to review every character's
# animation (or lack of one). Run it directly:
#   godot --path wyrd res://tools/animation_gallery.tscn
# Controls: ←/→ cycle character · ↑/↓ cycle clip · Space pause · [ / ] speed ·
#           Esc quit. The model turns on a slow turntable.
#
# It surfaces the current reality (animation research 2026): only the player
# chibi is rigged with clips; every enemy/boss GLB is a static skinless mesh
# (shown here as "STATIC — no rig"), which is why they slide frozen in-game.

const AnimDriver = preload("res://scripts/anim_driver.gd")
const GlbFit = preload("res://scripts/glb_fit.gd")
const CreatureAnim = preload("res://scripts/creature_anim.gd")
const EnemyProjectile = preload("res://scripts/enemy_projectile.gd")

const ENTRIES := [
	{"name": "Player — Chibi Wayfinder", "body": "res://models/player_chibi_v1_rigged.glb",
		"clips": ["res://models/player_chibi_v1_walk.glb", "res://models/player_chibi_v1_run.glb"]},
	{"name": "Player — Ranger (legacy)", "body": "res://models/_ranger_v5_walk.glb",
		"clips": ["res://models/_ranger_v5_run.glb"]},
	{"name": "Enemy — Skeleton", "body": "res://models/enemy_skeleton_v1.glb", "clips": []},
	{"name": "Enemy — Rat", "body": "res://models/enemy_rat_v1.glb", "clips": []},
	{"name": "Enemy — Ghost (ranged)", "body": "res://models/enemy_ghost_v1.glb", "clips": [], "ranged": true},
	{"name": "Enemy — Hedge Sprite", "body": "res://models/enemy_hedge_sprite_v1.glb", "clips": []},
	{"name": "Enemy — Bramble Imp", "body": "res://models/bramble_imp_v4.glb", "clips": []},
	{"name": "Enemy — Skitterling", "body": "res://models/skitterling.glb", "clips": []},
	{"name": "Boss — Hedgemother", "body": "res://models/hedgemother_v2.glb", "clips": []},
	{"name": "Boss — Burrow Boar", "body": "res://models/burrow_boar_v3.glb", "clips": []},
	{"name": "Boss — Wolf Alpha", "body": "res://models/wolf_alpha_v2.glb", "clips": []},
]

var _idx := 0
var _clip_idx := 0
var _clips: Array = []
var _ap: AnimationPlayer = null
var _ca = null               # creature_anim on static models (idle + attack demo)
var _pivot: Node3D
var _paused := false
var _speed := 1.0
var _name_lbl: Label
var _clip_lbl: Label

func _ready() -> void:
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.40, 0.43, 0.39)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.52, 0.48)
	e.ambient_light_energy = 0.5
	we.environment = e
	add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-45, -40, 0)
	key.light_energy = 1.2
	add_child(key)
	var back := DirectionalLight3D.new()
	back.rotation_degrees = Vector3(-25, 140, 0)
	back.light_energy = 0.4
	add_child(back)
	var disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.6
	cyl.bottom_radius = 1.6
	cyl.height = 0.04
	disc.mesh = cyl
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.28, 0.26, 0.23)
	disc.material_override = fmat
	disc.position.y = -0.02
	add_child(disc)
	_pivot = Node3D.new()
	add_child(_pivot)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.4, 4.0)
	add_child(cam)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	cam.make_current()
	_build_ui()
	var gi := OS.get_environment("WYRD_GALLERY_IDX")
	if gi != "":
		_idx = clampi(int(gi), 0, ENTRIES.size() - 1)
	_load_entry()
	# Dev: WYRD_GALLERY_ATTACK triggers an attack and grabs the lunge frame
	# (Phase 2 verification); WYRD_SHOT grabs a plain frame. Both then quit.
	if OS.get_environment("WYRD_GALLERY_ATTACK") != "":
		await get_tree().create_timer(0.5).timeout    # let load settle
		_do_attack()
		# Ranged → grab the aim-line telegraph mid-windup; melee → grab the lunge.
		var grab: float = 0.28 if bool(ENTRIES[_idx].get("ranged", false)) else 0.48
		await get_tree().create_timer(grab).timeout
		get_viewport().get_texture().get_image().save_png("/tmp/godot_selfshot.png")
		get_tree().quit()
	elif OS.get_environment("WYRD_SHOT") != "":
		await get_tree().create_timer(1.3).timeout
		get_viewport().get_texture().get_image().save_png("/tmp/godot_selfshot.png")
		get_tree().quit()

func _build_ui() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)
	_name_lbl = _mk_label(cl, Vector2(24, 18), 26)
	_clip_lbl = _mk_label(cl, Vector2(24, 56), 20)
	var help := _mk_label(cl, Vector2(24, 0), 16)
	help.anchor_top = 1.0
	help.anchor_bottom = 1.0
	help.offset_top = -34
	help.text = "←/→ character    ↑/↓ clip    Space pause    [ / ] speed    Esc quit"

func _mk_label(cl: CanvasLayer, pos: Vector2, size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.97, 0.94, 0.86))
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.06))
	l.add_theme_constant_override("outline_size", 6)
	cl.add_child(l)
	return l

func _load_entry() -> void:
	for c in _pivot.get_children():
		c.queue_free()
	_ap = null
	_ca = null
	_clips = []
	_clip_idx = 0
	var entry: Dictionary = ENTRIES[_idx]
	var glb = load(entry.body)
	if glb == null:
		_name_lbl.text = "[%d/%d] %s — MISSING FILE" % [_idx + 1, ENTRIES.size(), entry.name]
		_clip_lbl.text = entry.body
		return
	var inst: Node3D = glb.instantiate()
	_pivot.add_child(inst)
	await get_tree().process_frame      # let transforms settle for AABB fit
	if not is_instance_valid(inst):
		return
	_fit(inst)
	_ap = AnimDriver.find_anim_player(inst)
	if _ap == null:
		# Static enemy → give it the in-game procedural idle so the gallery
		# shows real motion, and so 'A' / WYRD_GALLERY_ATTACK can demo the tell.
		_ca = CreatureAnim.new()
		_ca.setup(inst)
	if _ap != null:
		var lib: AnimationLibrary = _ap.get_animation_library("")
		for cp in entry.clips:
			var s = load(cp)
			if s == null:
				continue
			var sinst: Node = s.instantiate()
			var sap := AnimDriver.find_anim_player(sinst)
			if sap != null:
				for cn in sap.get_animation_list():
					if not lib.has_animation(cn):
						lib.add_animation(cn, sap.get_animation(cn))
			sinst.queue_free()
		_clips = _ap.get_animation_list()
	_update_ui()
	_play_current()

func _play_current() -> void:
	if _ap == null or _clips.is_empty():
		return
	var clip := String(_clips[_clip_idx])
	var anim := _ap.get_animation(clip)
	if anim != null:
		anim.loop_mode = Animation.LOOP_LINEAR
	_ap.play(clip)
	_ap.speed_scale = _speed
	_paused = false

func _update_ui() -> void:
	var entry: Dictionary = ENTRIES[_idx]
	_name_lbl.text = "[%d/%d]  %s" % [_idx + 1, ENTRIES.size(), entry.name]
	if _ap == null:
		_clip_lbl.text = "STATIC — no rig / AnimationPlayer (slides frozen in bind pose in-game)"
	elif _clips.is_empty():
		_clip_lbl.text = "rigged but carries NO CLIPS"
	else:
		_clip_lbl.text = "clip [%d/%d]: %s    speed %.2fx%s" % [
			_clip_idx + 1, _clips.size(), String(_clips[_clip_idx]), _speed,
			"    PAUSED" if _paused else ""]

# Fit a model onto the turntable. Skinned models (chibi/ranger) have lying
# mesh AABBs (bind-pose bounds ignore the skeleton), so we trust their native
# authored scale like the game does; static meshes get GlbFit + centering.
func _fit(inst: Node3D) -> void:
	if _has_skeleton(inst):
		inst.position = Vector3.ZERO
		return
	GlbFit.normalize_height(inst, 2.0)
	var a := GlbFit.merged_aabb(inst, Transform3D.IDENTITY)
	if a.size.y > 0.001:
		inst.position = Vector3(
			-(a.position.x + a.size.x * 0.5), -a.position.y,
			-(a.position.z + a.size.z * 0.5))

func _has_skeleton(n: Node) -> bool:
	if n is Skeleton3D:
		return true
	for c in n.get_children():
		if _has_skeleton(c):
			return true
	return false

func _process(delta: float) -> void:
	if _pivot != null:
		_pivot.rotation.y += delta * 0.6
	if _ca != null:
		_ca.update(delta, false)

func _do_attack() -> void:
	if _ca == null:
		return
	_ca.attack(0.45, Vector3(0.0, 0.0, 1.0))
	get_tree().create_timer(0.45).timeout.connect(_ca.strike, CONNECT_ONE_SHOT)
	# Ranged kinds also demo the aim-line telegraph + a fired orb (Phase 3).
	if bool(ENTRIES[_idx].get("ranged", false)):
		var tg := EnemyProjectile.make_telegraph(Vector3(0.0, 0.0, 1.0), 4.0)
		_pivot.add_child(tg)
		get_tree().create_timer(0.45).timeout.connect(func():
			if is_instance_valid(tg):
				tg.queue_free()
			var pr := EnemyProjectile.new()
			add_child(pr)
			pr.setup(Vector3(0.0, 1.0, 0.4), Vector3(0.0, 0.0, 1.0), 5.0, 5),
			CONNECT_ONE_SHOT)

func _unhandled_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey) or not ev.pressed or ev.echo:
		return
	match (ev as InputEventKey).keycode:
		KEY_RIGHT:
			_idx = (_idx + 1) % ENTRIES.size()
			_load_entry()
		KEY_LEFT:
			_idx = (_idx - 1 + ENTRIES.size()) % ENTRIES.size()
			_load_entry()
		KEY_DOWN:
			if not _clips.is_empty():
				_clip_idx = (_clip_idx + 1) % _clips.size()
				_play_current()
				_update_ui()
		KEY_UP:
			if not _clips.is_empty():
				_clip_idx = (_clip_idx - 1 + _clips.size()) % _clips.size()
				_play_current()
				_update_ui()
		KEY_SPACE:
			if _ap != null:
				_paused = not _paused
				_ap.speed_scale = 0.0 if _paused else _speed
				_update_ui()
		KEY_BRACKETLEFT:
			_speed = maxf(0.1, _speed - 0.1)
			if _ap != null and not _paused:
				_ap.speed_scale = _speed
			_update_ui()
		KEY_BRACKETRIGHT:
			_speed = minf(3.0, _speed + 0.1)
			if _ap != null and not _paused:
				_ap.speed_scale = _speed
			_update_ui()
		KEY_A:
			_do_attack()         # demo the Phase 2 attack tell (static enemies)
		KEY_ESCAPE:
			get_tree().quit()
