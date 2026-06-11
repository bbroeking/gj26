extends CharacterBody3D

# Spec 07 / 13 / 23 — the player Ranger.
# Camera-relative movement with a walk/run/dash/roll state machine, the bow
# + arrow firing, HP/death. Animation is clip-based (spec 23 — the Meshy
# v5 Ranger ships working idle/walk/run clips); the bow rides the RightHand
# bone each frame.

const BOW_SCENE := preload("res://models/prop_bow_v1.glb")
const ARROW_SCENE := preload("res://scenes/Arrow.tscn")
const ArrowScript := preload("res://scripts/arrow.gd")  # static variant_idx
const InventoryPanelScene := preload("res://scenes/InventoryPanel.tscn")  # spec 27c
const SkillBarScene := preload("res://scenes/SkillBar.tscn")              # spec 30
const StatusEffectScript := preload("res://scripts/status_effect.gd")     # spec 33a
const RANGER_WALK := preload("res://models/_ranger_v5_walk.glb")
const RANGER_RUN := preload("res://models/_ranger_v5_run.glb")
# Spec 32b — concrete skill classes; instantiated in _ready as the player's
# loadout. Skill modules own their own firing logic; the player just
# dispatches via `_try_skill(slot)`.
const BasicShotScript := preload("res://scripts/skills/basic_shot.gd")
const PowerShotScript := preload("res://scripts/skills/power_shot.gd")
const MultiShotScript := preload("res://scripts/skills/multi_shot.gd")
const BrambleSnareScript := preload("res://scripts/skills/bramble_snare.gd")

# ---- locomotion (always-run; Shift walks) ----
# Speeds dialled down ~25% for a calmer overall game pace (spec 23 tuning).
const RUN_SPEED := 4.0
const WALK_SPEED := 2.0
const ACCEL := 12.0
# Spec 36 (Batch B) — split decel rates. Single ACCEL did both speed-up and
# stop, so stops felt skiddy and direction-reversals felt delayed. Now:
#  - speed-up keeps ACCEL=12 (cozy weight on start)
#  - stop uses DECEL — slightly snappier so releasing input reads deliberate
#  - reverse uses TURN_DECEL — much snappier so W→S is instant, not laggy
const DECEL := 20.0
const TURN_DECEL := 28.0
const GRAVITY := 22.0

# Spec 36 — foot-slide fix. Anim playback was a static `speed_scale = 0.85`,
# so foot-slide was visible at every speed except the calibrated one. Now
# scale per-frame by ground speed, clamped so the cycle never goes cartoonish.
# WALK_REF_SPEED chosen so the run clip preserves its existing 0.85x feel at
# RUN_SPEED (4.0 / 0.85 ≈ 4.7).
const WALK_REF_SPEED := 4.7

# ---- dash: a fast reposition burst, no i-frames ----
const DASH_SPEED := 11.0
const DASH_TIME := 0.18
const DASH_COOLDOWN := 0.7

# ---- roll: a dodge — burst + i-frame window + a tumble ----
const ROLL_SPEED := 6.5
const ROLL_TIME := 0.45
const ROLL_IFRAMES := 0.27   # Spec 36 — was 0.4 (89% of ROLL_TIME, effectively full invuln); 0.27 ≈ 60%, leaves a punishable recovery tail
const ROLL_COOLDOWN := 0.85

# ---- weapon ----
const FIRE_COOLDOWN := 0.28         # spec 26 — snappier cadence
const ARROW_SPAWN_FWD := 0.3
const INPUT_BUFFER_SEC := 0.15
const BOW_SCALE := 0.5
const BOW_ROT_DEG := Vector3(0.0, 0.0, 0.0)   # bow orientation fine-tune

# ---- survival (spec 15) ----
const PLAYER_HP := 30
const IFRAMES_SEC := 0.6
const HIT_KNOCKBACK := 4.5
const DEATH_PAUSE := 1.2

# ---- clip names in the Meshy GLBs ----
const CLIP_IDLE := "Armature|Idle|baselayer"
const CLIP_WALK := "Armature|walking_man|baselayer"
const CLIP_RUN := "Armature|running|baselayer"

enum Move { NORMAL, DASH, ROLL }

var _mesh: Node3D
var _ap: AnimationPlayer
var _skel: Skeleton3D
var _bow: Node3D
var _hand_idx := -1
var _hud: Node

var _move: Move = Move.NORMAL
var _burst_dir := Vector3.FORWARD
var _burst_t := 0.0
var _dash_cd := 0.0
var _roll_cd := 0.0

var _fire_buffer := 0.0
var _fire_recoil := 0.0       # back-lean on the mesh after a shot

var hp := PLAYER_HP
var hp_max := PLAYER_HP
var dead := false
var _iframe_t := 0.0
var _spawn_pos := Vector3.ZERO
var _mesh_base_scale := Vector3.ONE

# Spec 27b — ground-pickup state.
const PICKUP_LAYER := 16
var _overlapping_pickups: Array = []
# Spec 27c — real Tetris inventory + the UI panel.
var inventory: Inventory
var _inv_root: Control
# Spec 27d — equipment slots + a player-level signal for the stats pass.
signal gear_changed
var equipment: Equipment
# Spec 27e — derived combat stats (totals applied by `_derive_stats()`).
var derived_stats: Dictionary = {}
# Spec 29 — interactable scanner state. Shrines/chests/hearths sit on
# INTERACT_LAYER; we scan for them with a second Area3D (mirror of the
# pickup scanner) and the focused one shows its floating prompt while E grabs.
const INTERACT_LAYER := 32
var _overlapping_interactables: Array = []
var _active_interactable: Node = null
# Spec 29 — shrine-granted buffs sum on top of equipment in _derive_stats().
# Stat keys mirror the equipment sums dict.
var shrine_buffs: Dictionary = {"hp": 0, "damage": 0, "crit_chance": 0.0,
	"crit_mult": 0.0, "fire_rate": 0.0, "move_speed": 0.0,
	"cooldown_reduction": 0.0}
# Spec 30/32b — 4-skill hotbar + single regen "Focus" resource. Skills live
# behind the `Skill` module hierarchy in scripts/skills/; the player just
# instantiates the loadout and dispatches `_try_skill(slot)`.
const FOCUS_MAX := 50.0
const FOCUS_REGEN_OUT := 10.0       # per second when no enemy has hit recently
const FOCUS_REGEN_IN := 3.0         # per second while in combat
const COMBAT_TIMER := 3.0           # in-combat for this many seconds after a hit / skill
const CDR_CAP := 0.80               # cooldown reduction hard ceiling (mirrored on Skill)
var focus: float = FOCUS_MAX
var focus_max: float = FOCUS_MAX
var _combat_t: float = 0.0          # > 0 means "in combat" (used by Focus regen)
var _skill_cooldowns: Dictionary = {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0}
# Spec 33a — player-side status framework, mirrors Combatant's. Keyed by
# kind string ("burn" / "bleed" / "snared" / "root"); values are
# StatusEffect RefCounteds. Sunlit elite + future enemy modifiers apply
# statuses to the player through `apply_status`.
var _statuses: Dictionary = {}
# Spec 32b — the player's current loadout (4 Skill instances). Instantiated
# in _ready. Slot N reads `skills[N-1]`. F-key fires `skills[0]`.
var skills: Array = []

func _ready() -> void:
	add_to_group("player")
	_bind("p_fwd",   [KEY_W, KEY_UP])
	_bind("p_back",  [KEY_S, KEY_DOWN])
	_bind("p_left",  [KEY_A, KEY_LEFT])
	_bind("p_right", [KEY_D, KEY_RIGHT])
	_bind("fire",    [KEY_F])
	_bind("walk",    [KEY_SHIFT])
	# Spec 36 — bindings flipped to industry standard (Space = defensive verb).
	# Every shipped ARPG with a dodge (PoE 2, Lost Ark, Hades, post-SOTE
	# Elden Ring) puts roll on Space; dash goes to the near-thumb modifier.
	_bind("dash",    [KEY_CTRL])
	_bind("roll",    [KEY_SPACE])
	# Spec 30 — 1-4 are now skill slots (was bolt-variant cycling in spec 26).
	# BasicShot stays bound to F as well so the muscle memory survives.
	_bind("skill_1", [KEY_1])
	_bind("skill_2", [KEY_2])
	_bind("skill_3", [KEY_3])
	_bind("skill_4", [KEY_4])
	_bind("grab",    [KEY_G])      # spec 27b — pick up overlapping loot
	_bind("inv_toggle", [KEY_I])   # spec 27c — open / close the inventory
	_bind("interact", [KEY_E])     # spec 29 — open chest / pray / rest
	_make_pickup_scanner()
	_make_interact_scanner()       # spec 29 — detect typed-room interactables
	inventory = Inventory.new()    # spec 27c — Tetris grid for picked-up loot
	equipment = Equipment.new()    # spec 27d — 5-slot equipment
	equipment.changed.connect(_on_gear_changed)
	_derive_stats()                # spec 27e — base values until gear changes
	# Spec 32b — instantiate the player's current skill loadout. Future
	# class-paths (spec 34) replace this with a class-specific factory.
	skills = [
		BasicShotScript.new(),
		PowerShotScript.new(),
		MultiShotScript.new(),
		BrambleSnareScript.new(),
	]

	_mesh = get_node_or_null("Mesh")
	if _mesh != null:
		_mesh_base_scale = _mesh.scale
		_ap = _find_anim_player(_mesh)
		_skel = _find_skeleton(_mesh)
		_setup_clips()
	_attach_bow()

	var scn := get_tree().current_scene
	if scn != null:
		_hud = scn.get_node_or_null("PlayerHUD")
		# Spec 27c — instance the inventory panel for this scene. Deferred —
		# the scene is mid-_ready while we're a child of it.
		var ip := InventoryPanelScene.instantiate()
		scn.add_child.call_deferred(ip)
		_inv_root = ip.get_node_or_null("Root")
		if _inv_root != null:
			_inv_root.set_inventory.call_deferred(inventory)
			_inv_root.set_equipment.call_deferred(equipment)
		# Spec 30 — instance the 4-skill hotbar, bind to this player.
		var sb := SkillBarScene.instantiate()
		scn.add_child.call_deferred(sb)
		sb.bind_to_player.call_deferred(self)
	if _hud != null:
		_hud.set_hp.call_deferred(hp, hp_max)
		_hud.set_focus.call_deferred(focus, focus_max)

# Merge the walk + run clips (separate Meshy GLBs) into the idle GLB's
# AnimationPlayer — they share the rig, so the Animations transfer.
func _setup_clips() -> void:
	if _ap == null:
		return
	var lib: AnimationLibrary = _ap.get_animation_library("")
	if lib == null:
		return
	if lib.has_animation(CLIP_IDLE):
		lib.get_animation(CLIP_IDLE).loop_mode = Animation.LOOP_LINEAR
	_merge_clip(lib, "walk", RANGER_WALK, CLIP_WALK)
	_merge_clip(lib, "run", RANGER_RUN, CLIP_RUN)
	_ap.speed_scale = 0.85          # calmer clip pace, matches the slower move
	_ap.play(CLIP_IDLE)

func _merge_clip(lib: AnimationLibrary, into: String, glb: PackedScene, clip: String) -> void:
	var src := glb.instantiate()
	var srcap := _find_anim_player(src)
	if srcap != null and srcap.has_animation(clip):
		var a: Animation = srcap.get_animation(clip)
		a.loop_mode = Animation.LOOP_LINEAR
		lib.add_animation(into, a)
	src.free()

func set_spawn(pos: Vector3) -> void:
	_spawn_pos = pos

func _physics_process(delta: float) -> void:
	_iframe_t = maxf(0.0, _iframe_t - delta)
	_dash_cd = maxf(0.0, _dash_cd - delta)
	_roll_cd = maxf(0.0, _roll_cd - delta)
	_fire_buffer = maxf(0.0, _fire_buffer - delta)
	# Spec 30/32b — combat timer + per-skill cooldowns. Slot 1's cooldown is
	# the canonical one for BasicShot now (no more separate `_fire_cd`).
	_combat_t = maxf(0.0, _combat_t - delta)
	for k in _skill_cooldowns:
		_skill_cooldowns[k] = maxf(0.0, _skill_cooldowns[k] - delta)
	# Spec 33a — player-side status framework tick.
	_tick_statuses(delta)
	# Focus regen — slower while in combat (encourages a spend rhythm).
	var regen_rate: float = FOCUS_REGEN_IN if _combat_t > 0.0 else FOCUS_REGEN_OUT
	focus = clampf(focus + regen_rate * delta, 0.0, focus_max)
	if _hud != null and _hud.has_method("set_focus"):
		_hud.set_focus(focus, focus_max)
	# Spec 33a — refresh HP suffix with any active statuses (no-op if none).
	if _hud != null:
		_hud.set_hp(hp, hp_max, _status_suffix())
	if Input.is_action_just_pressed("fire"):
		_fire_buffer = INPUT_BUFFER_SEC
	# Spec 30 — 1-4 fire skills (was bolt cycling in spec 26).
	for i in range(1, 5):
		if Input.is_action_just_pressed("skill_%d" % i):
			_try_skill(i)
	# Grab any overlapping loot (spec 27b).
	if Input.is_action_just_pressed("grab"):
		_try_grab()
	# Toggle the inventory panel (spec 27c).
	if Input.is_action_just_pressed("inv_toggle") and _inv_root != null:
		_inv_root.toggle()
	# Interact with the nearest chest / shrine / hearth (spec 29).
	if Input.is_action_just_pressed("interact"):
		_try_interact()
	_refresh_interact_prompt()       # spec 29 — float the [E] prompt
	if dead:
		return

	var dir := _input_dir()

	match _move:
		Move.NORMAL:
			if Input.is_action_just_pressed("dash") and _dash_cd <= 0.0:
				_start_burst(Move.DASH, dir)
			elif Input.is_action_just_pressed("roll") and _roll_cd <= 0.0:
				_start_burst(Move.ROLL, dir)
			else:
				var spd: float = derived_stats.walk_speed \
					if Input.is_action_pressed("walk") else derived_stats.run_speed
				# Spec 33a — Snared / Root cuts player movement. Root is the
				# only true immobilizer; slow_product floors at 0.25 so
				# slows can't fully freeze.
				if has_status("root"):
					spd = 0.0
				else:
					spd *= _status_slow_product()
				# Spec 36 (Batch B) — pick the rate by intent:
				#  - no input  → DECEL  (releasing to stop)
				#  - reversing → TURN_DECEL (current vs target velocity oppose)
				#  - otherwise → ACCEL  (speeding up or maintaining)
				var current_v := Vector2(velocity.x, velocity.z)
				var target_v := Vector2(dir.x * spd, dir.z * spd)
				var rate: float
				if target_v.length() < 0.01:
					rate = DECEL
				elif current_v.length() > 0.5 and current_v.dot(target_v) < 0.0:
					rate = TURN_DECEL
				else:
					rate = ACCEL
				velocity.x = lerpf(velocity.x, target_v.x, rate * delta)
				velocity.z = lerpf(velocity.z, target_v.y, rate * delta)
		Move.DASH, Move.ROLL:
			# Spec 36 — recovery-cancel window. In the last 30% of the burst,
			# a fresh dash/roll input re-starts a burst. Active frames (first
			# 70%) stay committed; recovery is interruptible. Souls/PoE/DMC
			# pattern — refusing it made the locomotion suite feel jail-stiff.
			var total := DASH_TIME if _move == Move.DASH else ROLL_TIME
			var in_recovery := _burst_t / total < 0.30
			if in_recovery and Input.is_action_just_pressed("dash") and _dash_cd <= 0.0:
				_start_burst(Move.DASH, dir)
			elif in_recovery and Input.is_action_just_pressed("roll") and _roll_cd <= 0.0:
				_start_burst(Move.ROLL, dir)
			var bspd := DASH_SPEED if _move == Move.DASH else ROLL_SPEED
			velocity.x = _burst_dir.x * bspd
			velocity.z = _burst_dir.z * bspd
			_burst_t -= delta
			if _burst_t <= 0.0:
				_move = Move.NORMAL

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()

	var face := _burst_dir if _move != Move.NORMAL else dir
	if face.length() > 0.1 and _mesh != null:
		var look := atan2(face.x, face.z)
		var rate := 18.0 if _move != Move.NORMAL else 10.0
		_mesh.rotation.y = lerp_angle(_mesh.rotation.y, look, rate * delta)

	# Mesh local-X rotation — the roll tumble, or the fire recoil back-lean.
	if _mesh != null:
		if _move == Move.ROLL:
			_mesh.rotation.x = (1.0 - _burst_t / ROLL_TIME) * TAU
		else:
			_fire_recoil = lerpf(_fire_recoil, 0.0, 9.0 * delta)
			_mesh.rotation.x = _fire_recoil

	_play_anim(_anim_state(dir))
	# Spec 36 — foot-slide fix: scale anim playback to ground speed so the
	# stride matches the distance covered. Idle keeps the existing 0.85 base
	# pace (no visual change at rest); only locomotion is velocity-driven.
	if _ap != null:
		var hspeed := Vector2(velocity.x, velocity.z).length()
		if hspeed > 0.1:
			_ap.speed_scale = clamp(hspeed / WALK_REF_SPEED, 0.5, 1.3)
		else:
			_ap.speed_scale = 0.85
	_update_bow()

	if _move == Move.NORMAL:
		var want_fire := _fire_buffer > 0.0 or Input.is_action_pressed("fire")
		if want_fire and _skill_cooldowns[1] <= 0.0:
			# Spec 32b — F-key dispatches BasicShot (slot 1) via the Skill
			# module. Buffer is preserved so the snappy F-spam feel works.
			skills[0].fire(self)
			_skill_cooldowns[1] = skills[0].effective_cd(self)
			_combat_t = COMBAT_TIMER
			_fire_buffer = 0.0

func _start_burst(m: Move, dir: Vector3) -> void:
	_move = m
	_burst_dir = dir.normalized() if dir.length() > 0.1 else _facing_dir()
	if m == Move.DASH:
		_burst_t = DASH_TIME
		_dash_cd = DASH_COOLDOWN
	else:
		_burst_t = ROLL_TIME
		_roll_cd = ROLL_COOLDOWN
		_iframe_t = maxf(_iframe_t, ROLL_IFRAMES)

# Play the clip for the movement state (crossfaded).
func _play_anim(state: String) -> void:
	if _ap == null:
		return
	var clip := CLIP_IDLE
	if state == "walk":
		clip = "walk"
	elif state == "run" or state == "dash" or state == "roll":
		clip = "run"
	if _ap.current_animation != clip:
		_ap.play(clip, 0.15)

# Ride the bow on the RightHand bone (world-space, so it dodges the Meshy
# skeleton's internal scale).
func _update_bow() -> void:
	if _bow == null or _skel == null or _hand_idx < 0:
		return
	var hand := _skel.global_transform * _skel.get_bone_global_pose(_hand_idx)
	_bow.global_position = hand.origin
	var rot := Basis(hand.basis.get_rotation_quaternion()) * Basis.from_euler(
		Vector3(deg_to_rad(BOW_ROT_DEG.x), deg_to_rad(BOW_ROT_DEG.y), deg_to_rad(BOW_ROT_DEG.z)))
	_bow.global_rotation = rot.get_euler()

func _input_dir() -> Vector3:
	var iz := 0.0
	var ix := 0.0
	if Input.is_action_pressed("p_fwd"):
		iz += 1.0
	if Input.is_action_pressed("p_back"):
		iz -= 1.0
	if Input.is_action_pressed("p_right"):
		ix += 1.0
	if Input.is_action_pressed("p_left"):
		ix -= 1.0
	var cam := get_viewport().get_camera_3d()
	var d := Vector3.ZERO
	if cam != null:
		var b := cam.global_transform.basis
		var fwd := -b.z
		fwd.y = 0.0
		var right := b.x
		right.y = 0.0
		d = fwd.normalized() * iz + right.normalized() * ix
	else:
		d = Vector3(ix, 0.0, -iz)
	return d.normalized()

func _facing_dir() -> Vector3:
	if _mesh == null:
		return Vector3.FORWARD
	var y: float = _mesh.rotation.y
	return Vector3(sin(y), 0.0, cos(y))

func _anim_state(dir: Vector3) -> String:
	if _move == Move.DASH:
		return "dash"
	if _move == Move.ROLL:
		return "roll"
	if dir.length() > 0.1:
		return "walk" if Input.is_action_pressed("walk") else "run"
	return "idle"

# ---- combat / survival ----
func take_damage(amount: int, from_dir: Vector3) -> void:
	if dead or _iframe_t > 0.0:
		return
	hp -= amount
	_iframe_t = IFRAMES_SEC
	_combat_t = COMBAT_TIMER       # spec 30 — getting hit puts us in combat
	var flat := Vector3(from_dir.x, 0.0, from_dir.z)
	if flat.length() > 0.001:
		var imp := flat.normalized() * HIT_KNOCKBACK
		velocity.x += imp.x
		velocity.z += imp.z
	var hs := get_node_or_null("/root/Hitstop")
	if hs != null:
		hs.freeze(0.07)
	if _hud != null:
		_hud.flash()
		_hud.set_hp(hp, hp_max)
	if hp <= 0:
		_die()

# Death — crumple + sink + Pokémon white-out; respawn under the white.
func _die() -> void:
	dead = true
	velocity = Vector3.ZERO
	if _ap != null:
		_ap.pause()
	if _mesh != null:
		var t := create_tween()
		t.set_parallel(true)
		var squashed := Vector3(_mesh_base_scale.x * 1.18,
			_mesh_base_scale.y * 0.3, _mesh_base_scale.z * 1.18)
		t.tween_property(_mesh, "scale", squashed, 0.45)
		t.tween_property(_mesh, "position:y", -1.1, 0.5)
		t.tween_property(_mesh, "rotation:x", 0.4, 0.4)
	if _hud != null and _hud.has_method("whiteout_in"):
		_hud.whiteout_in()
	await get_tree().create_timer(DEATH_PAUSE).timeout
	if _mesh != null:
		_mesh.scale = _mesh_base_scale
		_mesh.position = Vector3.ZERO
		_mesh.rotation.x = 0.0
	if _ap != null:
		_ap.play(CLIP_IDLE)
	# Spec 29 — checkpoint-aware respawn. A Hearth in a rest room writes the
	# slot; on death we restart there at full HP instead of the entrance.
	global_position = _respawn_position()
	velocity = Vector3.ZERO
	_move = Move.NORMAL
	hp = hp_max
	_iframe_t = IFRAMES_SEC
	dead = false
	if _hud != null:
		_hud.set_hp(hp, hp_max)
		if _hud.has_method("whiteout_out"):
			_hud.whiteout_out()

# ---- Spec 32b: public helpers Skill subclasses call into ----

# Shared aim direction. Held movement direction first; falls back to the
# mesh's facing if no movement input. Public so Skill.fire() can read it.
func aim_dir() -> Vector3:
	var dir := _input_dir()
	if dir.length() < 0.1:
		if _mesh != null:
			var yaw: float = _mesh.rotation.y
			dir = Vector3(sin(yaw), 0.0, cos(yaw))
	return dir.normalized()

# Arrow spawn origin — bow tip if rigged, else mid-chest. ARROW_SPAWN_FWD
# nudges it out past the player capsule so it doesn't self-collide.
func arrow_origin(dir: Vector3) -> Vector3:
	var o := global_position + Vector3(0.0, 1.0, 0.0)
	if _bow != null:
		o = _bow.global_position
	return o + dir * ARROW_SPAWN_FWD

# Bow quick-flex pop on fire — `scale_mult` scales the BOW_SCALE briefly.
func bow_pop(scale_mult: float) -> void:
	if _bow == null:
		return
	var t := create_tween()
	t.tween_property(_bow, "scale", Vector3.ONE * BOW_SCALE * scale_mult, 0.04)
	t.tween_property(_bow, "scale", Vector3.ONE * BOW_SCALE, 0.13)

# Set the mesh back-lean amount used by `_physics_process` to drive the
# fire-recoil animation. Negative values lean back (the existing convention).
func apply_recoil(amount: float) -> void:
	_fire_recoil = amount

# Spec 32b — skill dispatcher. Slot 1 routes through the F-fire buffer
# (preserves the snappy "press 1 a tick early" feel); slots 2-4 fire
# immediately if off cooldown AND Focus ≥ cost. Failed checks are silent
# no-ops — the SkillBar's grey-out tells the player why.
func _try_skill(slot: int) -> void:
	if dead or _move != Move.NORMAL:
		return
	if slot < 1 or slot > skills.size():
		return
	var skill = skills[slot - 1]
	if focus < skill.cost:
		return                   # not enough Focus
	if slot == 1:
		_fire_buffer = INPUT_BUFFER_SEC
		return
	if _skill_cooldowns[slot] > 0.0:
		return                   # on cooldown
	focus -= skill.cost
	_skill_cooldowns[slot] = skill.effective_cd(self)
	_combat_t = COMBAT_TIMER
	skill.fire(self)

# ---- setup helpers ----
# The Meshy rig has no authored socket — the bow rides the RightHand bone
# via _update_bow(); it's parented to the player (normal scale) so it
# dodges the skeleton's internal scaling.
func _attach_bow() -> void:
	_bow = BOW_SCENE.instantiate()
	add_child(_bow)
	_bow.scale = Vector3.ONE * BOW_SCALE
	_tint(_bow, Color(0.40, 0.28, 0.18))
	if _skel != null:
		_hand_idx = _skel.find_bone("RightHand")
		if _hand_idx < 0:
			push_warning("player: RightHand bone not found — bow won't track")

func _tint(root: Node, color: Color) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	for vi in _all_mesh_instances(root):
		vi.material_override = m

func _all_mesh_instances(node: Node) -> Array:
	var out := []
	if node is MeshInstance3D:
		out.append(node)
	for c in node.get_children():
		out.append_array(_all_mesh_instances(c))
	return out

func _find_anim_player(node: Node) -> AnimationPlayer:
	if node == null:
		return null
	if node is AnimationPlayer:
		return node
	for c in node.get_children():
		var f := _find_anim_player(c)
		if f != null:
			return f
	return null

func _find_skeleton(node: Node) -> Skeleton3D:
	if node == null:
		return null
	if node is Skeleton3D:
		return node
	for c in node.get_children():
		var f := _find_skeleton(c)
		if f != null:
			return f
	return null

# Spec 27d/e/f — re-emit Equipment's `changed`, re-derive combat stats,
# and play the equip SFX.
func _on_gear_changed() -> void:
	_derive_stats()
	gear_changed.emit()
	var sfx := get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.play("equip")

# Sum every equipped item's base stat + affixes into a derived totals dict
# (HP max, damage, crit chance/mult bonus, scaled fire cooldown + move
# speeds). Combat consumers read from here instead of the consts.
# Spec 29 — shrine_buffs sum into the same dict on top of equipment, so a
# shrine boon stacks additively with whatever gear the player has on.
func _derive_stats() -> void:
	var sums := {"hp": 0, "damage": 0, "crit_chance": 0.0,
		"crit_mult": 0.0, "fire_rate": 0.0, "move_speed": 0.0,
		"cooldown_reduction": 0.0}
	if equipment != null:
		for slot in Equipment.SLOT_ORDER:
			var it = equipment.get_slot(slot)
			if it == null:
				continue
			_add_stat(sums, String(it.get("base_stat", "")), it.get("base_value", 0))
			for a in it.get("affixes", []):
				_add_stat(sums, String(a.get("stat", "")), a.get("value", 0))
	for k in shrine_buffs:
		_add_stat(sums, String(k), shrine_buffs[k])
	derived_stats = {
		"hp_max":              PLAYER_HP + int(sums.hp),
		"damage":              6 + int(sums.damage),
		"crit_chance":         clampf(0.20 + float(sums.crit_chance), 0.0, 1.0),
		"crit_mult_bonus":     float(sums.crit_mult),
		"fire_cooldown":       FIRE_COOLDOWN / (1.0 + float(sums.fire_rate)),
		"run_speed":           RUN_SPEED * (1.0 + float(sums.move_speed)),
		"walk_speed":          WALK_SPEED * (1.0 + float(sums.move_speed)),
		# Spec 30 — capped CDR for skill 2-4 cooldowns. Skill 1 (BasicShot)
		# is still scaled by `fire_rate` via `fire_cooldown` above.
		"cooldown_reduction": clampf(float(sums.cooldown_reduction), 0.0, CDR_CAP),
	}
	# Apply HP max change — clamp current HP down if max shrunk; don't auto-heal.
	hp_max = derived_stats.hp_max
	hp = mini(hp, hp_max)
	if _hud != null:
		_hud.set_hp(hp, hp_max)

static func _add_stat(sums: Dictionary, stat: String, value) -> void:
	if sums.has(stat):
		sums[stat] += value

# ---- Spec 27b: ground-pickup scanner + grab ----
func _make_pickup_scanner() -> void:
	var ps := Area3D.new()
	ps.name = "PickupScanner"
	ps.collision_layer = 0
	ps.collision_mask = PICKUP_LAYER
	ps.monitorable = false
	ps.monitoring = true
	var sh := CollisionShape3D.new()
	var sp := SphereShape3D.new()
	sp.radius = 1.1
	sh.shape = sp
	sh.position = Vector3(0.0, 0.9, 0.0)
	ps.add_child(sh)
	add_child(ps)
	ps.area_entered.connect(_on_pickup_entered)
	ps.area_exited.connect(_on_pickup_exited)

func _on_pickup_entered(a: Area3D) -> void:
	if a != null and not _overlapping_pickups.has(a):
		_overlapping_pickups.append(a)

func _on_pickup_exited(a: Area3D) -> void:
	_overlapping_pickups.erase(a)

func _try_grab() -> void:
	if _overlapping_pickups.is_empty():
		return
	# Spec 32a — find nearest, hand off the full take transaction to the
	# pickup. inventory-fit, place, VFX, SFX, log all live behind try_take.
	var best: ItemPickup = null
	var best_d := INF
	for p in _overlapping_pickups:
		if not is_instance_valid(p) or not p is ItemPickup:
			continue
		var d := global_position.distance_to((p as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = p
	if best == null:
		return
	if best.try_take(self):
		_overlapping_pickups.erase(best)

# ---- Spec 29: interactable scanner + try-interact + helpers ----
func _make_interact_scanner() -> void:
	var ps := Area3D.new()
	ps.name = "InteractScanner"
	ps.collision_layer = 0
	ps.collision_mask = INTERACT_LAYER
	ps.monitorable = false
	ps.monitoring = true
	var sh := CollisionShape3D.new()
	var sp := SphereShape3D.new()
	sp.radius = 1.5
	sh.shape = sp
	sh.position = Vector3(0.0, 0.9, 0.0)
	ps.add_child(sh)
	add_child(ps)
	ps.area_entered.connect(_on_interact_entered)
	ps.area_exited.connect(_on_interact_exited)

func _on_interact_entered(a: Area3D) -> void:
	if a != null and not _overlapping_interactables.has(a):
		_overlapping_interactables.append(a)

func _on_interact_exited(a: Area3D) -> void:
	_overlapping_interactables.erase(a)
	if a == _active_interactable:
		if a != null and is_instance_valid(a) and a.has_method("show_prompt"):
			a.show_prompt(false)
		_active_interactable = null

# Each tick — pick the nearest non-used overlapping interactable and show its
# prompt; hide the old one if it changed.
func _refresh_interact_prompt() -> void:
	var best: Node = null
	var best_d := INF
	for n in _overlapping_interactables:
		if not is_instance_valid(n):
			continue
		if n.has_method("is_used") and n.is_used():
			continue
		var d := global_position.distance_to((n as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = n
	if best != _active_interactable:
		if _active_interactable != null and is_instance_valid(_active_interactable) \
				and _active_interactable.has_method("show_prompt"):
			_active_interactable.show_prompt(false)
		_active_interactable = best
		if best != null and best.has_method("show_prompt"):
			best.show_prompt(true)

func _try_interact() -> void:
	if _active_interactable == null or not is_instance_valid(_active_interactable):
		return
	if not _active_interactable.has_method("interact"):
		return
	_active_interactable.interact(self)
	# Hide the prompt right away; _refresh_interact_prompt will pick the next.
	if _active_interactable.has_method("show_prompt"):
		_active_interactable.show_prompt(false)
	_active_interactable = null

# Shrine.gd calls this with the picked buff's stat + value (additive).
func apply_shrine_buff(stat: String, value) -> void:
	if shrine_buffs.has(stat):
		shrine_buffs[stat] += value
	_derive_stats()
	print("[shrine] +%s %s applied" % [str(value), stat])

# Hearth.gd calls this to refill HP before saving the checkpoint slot.
func heal_to_full() -> void:
	hp = hp_max
	if _hud != null:
		_hud.set_hp(hp, hp_max)

# Spec 29 — checkpoint-aware respawn position. Falls back to dungeon entry
# (the spec 15 default) when no Hearth has been visited yet.
func _respawn_position() -> Vector3:
	var cp := get_node_or_null("/root/Checkpoint")
	if cp != null and cp.has_method("has_checkpoint") and cp.has_checkpoint():
		var slot: Dictionary = cp.read()
		return slot.get("pos", _spawn_pos)
	return _spawn_pos

func _bind(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)

# ---- Spec 33a: player-side status framework ----
# Ports the spec 31 Combatant framework onto the player. Sunlit elite + future
# enemy modifiers apply statuses via `apply_status`. Tick loop drains them
# and applies per-status damage. HUD suffix surfaces active statuses textually.

# Storybook-flavoured words for the HP-bar suffix. Status kinds not listed
# here surface as the raw kind ("frozen", "shocked" etc. in future specs).
const STATUS_WORD := {
	"burn":   "burning",
	"bleed":  "bleeding",
	"snared": "snared",
	"root":   "rooted",
}

func apply_status(kind: String, duration: float, dpt: int,
		slow_factor: float = 1.0, tick_interval: float = 0.0):
	if dead:
		return null
	var existing = _statuses.get(kind, null)
	if existing != null:
		# Highest-wins refresh — same rule as Combatant's apply_status.
		existing.time_left = maxf(existing.time_left, duration)
		existing.damage_per_tick = maxi(existing.damage_per_tick, dpt)
		existing.slow_factor = minf(existing.slow_factor, slow_factor)
		return existing
	var s = StatusEffectScript.new()
	s.kind = kind
	s.time_left = duration
	s.tick_interval = tick_interval
	s.next_tick = tick_interval
	s.damage_per_tick = dpt
	s.slow_factor = slow_factor
	_statuses[kind] = s
	return s

func has_status(kind: String) -> bool:
	return _statuses.has(kind)

func get_status(kind: String):
	return _statuses.get(kind, null)

# Per-frame status tick — single tick per status per frame (no while-loop
# catch-up). Matches Combatant's tick model.
func _tick_statuses(delta: float) -> void:
	if _statuses.is_empty():
		return
	var kinds: Array = _statuses.keys()
	for kind in kinds:
		if not _statuses.has(kind):
			continue
		var s = _statuses[kind]
		s.time_left -= delta
		if s.tick_interval > 0.0 and s.damage_per_tick > 0:
			s.next_tick -= delta
			if s.next_tick <= 0.0:
				s.next_tick = s.tick_interval
				_apply_tick_damage(s.damage_per_tick)
				if dead:
					return
		if s.time_left <= 0.0:
			_statuses.erase(kind)

# Direct HP reduction from a status tick. Bypasses i-frames (DoT ticks
# shouldn't be dodged by a roll); skips the take_damage crit/feedback pipe
# (the tick is a passive drain, not an impact).
func _apply_tick_damage(amount: int) -> void:
	if dead or amount <= 0:
		return
	hp -= amount
	if _hud != null:
		_hud.flash()
	if hp <= 0:
		_die()

# Product of all active slow_factors, clamped to ≥ 0.25 (root is the only
# true immobilizer; soft slows can't compound to a freeze).
func _status_slow_product() -> float:
	var p := 1.0
	for kind in _statuses:
		p *= float(_statuses[kind].slow_factor)
	return clampf(p, 0.25, 1.0)

# HP-bar text suffix for active statuses ("burning", "burning · snared", "").
# Status order follows dict insertion order — stable enough for v1.
func _status_suffix() -> String:
	if _statuses.is_empty():
		return ""
	var words: Array = []
	for kind in _statuses:
		var w := String(STATUS_WORD.get(kind, kind))
		if not words.has(w):
			words.append(w)
	if words.is_empty():
		return ""
	return " — " + " · ".join(words)
