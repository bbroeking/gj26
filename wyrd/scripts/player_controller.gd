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
# Wyrd — the chibi wayfinder (Meshy rig pipeline, 2026-06-10). When the
# rigged GLB exists it replaces the Player.tscn ranger mesh wholesale;
# the ranger remains the fallback so the game never loses its body.
const CHIBI_BODY_PATH := "res://models/player_chibi_v1_rigged.glb"
const CHIBI_WALK_PATH := "res://models/player_chibi_v1_walk.glb"
const CHIBI_RUN_PATH := "res://models/player_chibi_v1_run.glb"
const CHIBI_HEIGHT := 1.25
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
const BOW_ROT_DEG := Vector3(90.0, 0.0, 0.0)  # upright in the grip

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
# Spec 46-C — the bow's hand socket + tunables (local, in socket space).
var _bow_socket: BoneAttachment3D = null
var _bow_base_pos := Vector3(0.0, 0.05, 0.0)
var _bow_draw_dir := Vector3(0.0, 0.0, 1.0)
const BOW_SOCKET_ROT := Vector3(90.0, 0.0, 0.0)
var _hand_idx := -1
var _hud: Node
var _is_chibi := false
var _bow_scale := BOW_SCALE
# Resolved clip names — Meshy rigs and the legacy ranger GLBs name their
# clips differently; _setup_clips finds them by substring.
var _clip_idle := ""
var _clip_walk := ""
var _clip_run := ""

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
# Wyrd — fired at the moment of death; layout_loader uses it to drop the
# boss arena gates and reset the encounter (no sealed-in respawns).
signal died
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
	# Spec 46 Phase A — in a co-op session only the authority's machine
	# simulates this body; everyone else's copy is a synced puppet.
	var net := get_node_or_null("/root/NetGame")
	var net_on: bool = net != null and bool(net.active)
	_is_remote = net_on and not is_multiplayer_authority()
	if net_on:
		var tag := Label3D.new()
		tag.text = String(net.peer_name(get_multiplayer_authority()))
		tag.position = Vector3(0.0, 2.35, 0.0)
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.font_size = 40
		tag.pixel_size = 0.008
		tag.modulate = Color(0.96, 0.92, 0.80)
		tag.outline_size = 10
		tag.outline_modulate = Color(0.12, 0.09, 0.06)
		add_child(tag)
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
	_bind("satchel_toggle", [KEY_M])   # Wyrd — materials + chart case view
	_bind("trades_toggle", [KEY_K])    # Wyrd — trades / skills page
	_bind("quaff", [KEY_Q])            # Wyrd A8 — drink a draught
	_bind("mute", [KEY_F10])           # spec 38 — master audio mute
	_bind("interact", [KEY_E])     # spec 29 — open chest / pray / rest
	_make_pickup_scanner()
	_make_interact_scanner()       # spec 29 — detect typed-room interactables
	# Wyrd — inventory + equipment live on the Game autoload so they survive
	# Town↔Dungeon scene changes. Fallback keeps tests + headless tools
	# (which build a bare player with no autoloads) working.
	var game := get_tree().root.get_node_or_null("Game")
	if game != null:
		inventory = game.inventory
		equipment = game.equipment
	else:
		inventory = Inventory.new()
		equipment = Equipment.new()
	equipment.changed.connect(_on_gear_changed)
	if game != null and game.has_signal("leveled_up"):
		game.leveled_up.connect(_on_leveled_up)
	_derive_stats()                # spec 27e — base values until gear changes
	if game != null:
		game.restore_player(self)  # Wyrd — carry hp across the scene change
		hp = mini(hp, hp_max)      # (the HUD hookup below reads the restored value)
	# B5 — slot 1 is always the Bow; slots 2-4 come from Game.loadout.
	rebuild_skills()

	_maybe_swap_chibi()
	_mesh = get_node_or_null("Mesh")
	if _mesh != null:
		_mesh_base_scale = _mesh.scale
		_ap = _find_anim_player(_mesh)
		_skel = _find_skeleton(_mesh)
		_setup_clips()
		_add_ink_outline(_mesh)        # the player wears the same ink rim as foes
	_attach_bow()

	# Spec 46 — puppets carry no HUD, panels, or hotbar; one set per machine.
	var scn := get_tree().current_scene
	if scn != null and not _is_remote:
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

# The chunky ink silhouette (mirrors layout_loader / combatant). Chains a
# grown back-face shell as next_pass onto each mesh's real material (duplicated
# so the shared GLB resource isn't mutated); a materialless surface gets a
# neutral plate to host the rim. Keeps the player consistent with the foes.
func _add_ink_outline(root: Node) -> void:
	for n in _all_mesh_instances(root):
		var mi := n as MeshInstance3D
		var mesh: Mesh = mi.mesh
		var painted := false
		if mesh != null:
			for s in range(mesh.get_surface_count()):
				var base := mi.get_active_material(s)
				if base is BaseMaterial3D:
					var dup := (base as BaseMaterial3D).duplicate() as BaseMaterial3D
					dup.next_pass = _ink_outline_pass()
					mi.set_surface_override_material(s, dup)
					painted = true
		if not painted:
			var fallback := StandardMaterial3D.new()
			fallback.albedo_color = Color(0.70, 0.66, 0.60)
			fallback.roughness = 0.85
			fallback.next_pass = _ink_outline_pass()
			mi.material_override = fallback

func _ink_outline_pass() -> StandardMaterial3D:
	var o := StandardMaterial3D.new()
	o.grow = true
	o.grow_amount = 0.05
	o.cull_mode = BaseMaterial3D.CULL_FRONT
	o.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	o.albedo_color = Color(0.13, 0.09, 0.06)
	return o

# Swap the ranger for the chibi wayfinder when her rigged GLB is present.
func _maybe_swap_chibi() -> void:
	if not ResourceLoader.exists(CHIBI_BODY_PATH):
		return
	var packed: PackedScene = load(CHIBI_BODY_PATH)
	if packed == null:
		return
	var old := get_node_or_null("Mesh")
	if old != null:
		old.name = "MeshLegacy"
		old.queue_free()
	var inst: Node3D = packed.instantiate()
	inst.name = "Mesh"
	# NO GlbFit here — skinned-mesh AABBs lie (bind-pose bounds ignore the
	# centimeter armature), and the rig was exported at height_meters=1.25
	# already. Trust the export.
	GlbFit.unmetal(inst)
	add_child(inst)
	_is_chibi = true
	_bow_scale = 0.32               # her bow is as chibi as she is

# Merge the walk + run clips (separate same-rig GLBs) into the body's
# AnimationPlayer, resolving clip names by substring — Meshy rigs and the
# legacy ranger GLBs name their clips differently.
func _setup_clips() -> void:
	if _ap == null:
		return
	var lib: AnimationLibrary = _ap.get_animation_library("")
	if lib == null:
		return
	_clip_idle = _find_clip_name(_ap, "idle")
	_clip_walk = _find_clip_name(_ap, "walk")
	_clip_run = _find_clip_name(_ap, "run")
	if _is_chibi:
		# The Meshy rig ships walking/running as sidecar GLBs on the same
		# skeleton; the idle export is the body. Merge what's missing.
		if _clip_walk == "" and ResourceLoader.exists(CHIBI_WALK_PATH):
			_merge_clip_by_key(lib, "walk", load(CHIBI_WALK_PATH), "walk")
			_clip_walk = "walk" if lib.has_animation("walk") else ""
		if _clip_run == "" and ResourceLoader.exists(CHIBI_RUN_PATH):
			_merge_clip_by_key(lib, "run", load(CHIBI_RUN_PATH), "run")
			_clip_run = "run" if lib.has_animation("run") else ""
	else:
		_merge_clip(lib, "walk", RANGER_WALK, CLIP_WALK)
		_merge_clip(lib, "run", RANGER_RUN, CLIP_RUN)
		_clip_walk = "walk"
		_clip_run = "run"
	# Sensible fallbacks so a missing clip degrades, never T-poses.
	if _clip_idle == "":
		_clip_idle = _clip_walk if _clip_walk != "" else _clip_run
	if _clip_walk == "":
		_clip_walk = _clip_idle
	if _clip_run == "":
		_clip_run = _clip_walk
	for nm in [_clip_idle, _clip_walk, _clip_run]:
		if nm != "" and lib.has_animation(nm):
			lib.get_animation(nm).loop_mode = Animation.LOOP_LINEAR
			# Wyrd — Meshy bakes a root SCALE key into some clips (idle:
			# 1.176) and not others (walk/run: none), so the character
			# visibly shrank the moment she moved. Scale is not an
			# intentional channel in these rigs — strip it everywhere.
			if _is_chibi:
				_strip_scale_tracks(lib.get_animation(nm))
	_ap.speed_scale = 0.85          # calmer clip pace, matches the slower move
	if _clip_idle != "":
		_ap.play(_clip_idle)

static func _strip_scale_tracks(a: Animation) -> void:
	for t in range(a.get_track_count() - 1, -1, -1):
		if a.track_get_type(t) == Animation.TYPE_SCALE_3D:
			a.remove_track(t)

func _find_clip_name(ap: AnimationPlayer, key: String) -> String:
	for nm in ap.get_animation_list():
		if String(nm).to_lower().contains(key):
			return String(nm)
	return ""

# Merge the first clip whose name contains `key` from a same-rig GLB.
func _merge_clip_by_key(lib: AnimationLibrary, into: String,
		glb: PackedScene, key: String) -> void:
	if glb == null:
		return
	var src := glb.instantiate()
	var srcap := _find_anim_player(src)
	if srcap != null:
		for nm in srcap.get_animation_list():
			if String(nm).to_lower().contains(key):
				var a: Animation = srcap.get_animation(nm).duplicate()
				a.loop_mode = Animation.LOOP_LINEAR
				lib.add_animation(into, a)
				break
	src.free()

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
	# Spec 46 Phase A — puppets only chase their synced transform.
	if _is_remote:
		_net_remote_tick(delta)
		return
	_net_send_tick(delta)
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
	# B5-wave2 — the ward's timer; bark crumbles when it runs out.
	if _ward_t > 0.0:
		_ward_t -= delta
		if _ward_t <= 0.0:
			_ward_hp = 0
	# Spec 45-wilds — Mothmint Mend: scratches close as you walk.
	var game_r := get_tree().root.get_node_or_null("Game")
	if game_r != null and hp < hp_max and not dead:
		var vr: float = float(game_r.buff_value("vigor_regen"))
		if vr > 0.0:
			_regen_accum += vr * delta
			if _regen_accum >= 1.0:
				var whole := int(_regen_accum)
				_regen_accum -= float(whole)
				hp = mini(hp + whole, hp_max)
				if _hud != null:
					_hud.set_hp(hp, hp_max)
	# Focus regen — slower while in combat (encourages a spend rhythm).
	var regen_rate: float = FOCUS_REGEN_IN if _combat_t > 0.0 else FOCUS_REGEN_OUT
	focus = clampf(focus + regen_rate * _chart_focus_mult()
		* _buff_focus_mult() * delta, 0.0, focus_max)
	if _hud != null and _hud.has_method("set_focus"):
		_hud.set_focus(focus, focus_max)
	# Spec 33a — refresh HP suffix with any active statuses (no-op if none).
	if _hud != null:
		_hud.set_hp(hp, hp_max, _status_suffix())
	# Wyrd — the dead gate moved ABOVE input handling: during the death
	# white-out the player could still grab loot, open panels, and even step
	# through the exit waystone (cancelling death and banking the run).
	if dead:
		return
	# Spec 46 — while a modal owns the keys in co-op the body just settles
	# (offline the tree pause makes this unreachable). Esc opens the lantern
	# menu when nothing else is open.
	if game_r != null and int(game_r.modal_count) > 0:
		velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 30.0 * delta)
		move_and_slide()
		return
	if Input.is_action_just_pressed("ui_cancel"):
		var menu: CanvasLayer = load("res://scripts/ui/system_menu.gd").new()
		get_tree().current_scene.add_child(menu)
		return
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
	# Toggle the satchel (Wyrd).
	if Input.is_action_just_pressed("satchel_toggle"):
		toggle_satchel()
	if Input.is_action_just_pressed("trades_toggle"):
		toggle_trades()
	# Quaff a draught (Wyrd A8 — the sustain verb).
	if Input.is_action_just_pressed("quaff"):
		_quaff()
	if Input.is_action_just_pressed("mute"):
		var game_m := get_tree().root.get_node_or_null("Game")
		if game_m != null:
			game_m.set_muted(not bool(game_m.muted))
	# Interact with the nearest chest / shrine / hearth (spec 29).
	if Input.is_action_just_pressed("interact"):
		_try_interact()
	_refresh_interact_prompt()       # spec 29 — float the [E] prompt

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
	# Wyrd roll fix — the mesh origin sits at the FEET, so a bare rotation.x
	# sweeps the body through the floor like a windscreen wiper ("broken"
	# roll). Tumble + a hop arc so the somersault reads around the waist,
	# and _play_anim holds the idle pose so limbs don't flail mid-air.
	if _mesh != null:
		if _move == Move.ROLL:
			var prog := 1.0 - _burst_t / ROLL_TIME
			_mesh.rotation.x = prog * TAU
			_mesh.position.y = sin(prog * PI) * 0.55
		else:
			_mesh.position.y = 0.0
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
		if want_fire and float(_skill_cooldowns.get(1, 0.0)) <= 0.0:
			# Spec 32b — F-key dispatches BasicShot (slot 1) via the Skill
			# module. Buffer is preserved so the snappy F-spam feel works.
			face_aim(aim_dir())        # Wyrd — square up before the arrow leaves
			skills[0].fire(self)
			_net_forward_cast(1)
			_skill_cooldowns[1] = skills[0].effective_cd(self)
			_combat_t = COMBAT_TIMER
			_fire_buffer = 0.0

func _start_burst(m: Move, dir: Vector3) -> void:
	if m == Move.ROLL:
		var sfx_r := get_node_or_null("/root/Sfx")
		if sfx_r != null:
			sfx_r.play("roll")
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
	var clip := _clip_idle
	if state == "walk":
		clip = _clip_walk
	elif state == "run" or state == "dash":
		clip = _clip_run
	# Roll keeps the idle pose — a rigid tuck reads as a somersault; the
	# run cycle mid-tumble reads as a glitch.
	if clip != "" and _ap.current_animation != clip:
		_ap.play(clip, 0.15)

# Spec 46-C — the bow is ANCHORED now: a BoneAttachment3D on the bow hand
# (BoneAttachment updates after the AnimationPlayer applies the pose, so
# the old "jittered around her hood" problem is gone — that jitter came
# from reading bone poses in _physics_process, one frame early). The
# recoil/draw motion rides as a local offset inside the socket.
func _update_bow() -> void:
	if _bow == null:
		return
	if _bow_socket != null and _mesh != null:
		var yaw: float = _mesh.rotation.y
		var fwd := Vector3(sin(yaw), 0.0, cos(yaw))
		var right := Vector3(fwd.z, 0.0, -fwd.x)
		var draw := clampf(absf(_fire_recoil) / 0.2, 0.0, 1.0)
		# Anchored at the hand; eased just clear of the hood's silhouette.
		_bow.global_position = _bow_socket.global_position \
			+ right * 0.12 + Vector3(0.0, 0.06, 0.0) \
			+ fwd * (0.05 + 0.12 * draw)
		var look := Basis.looking_at(fwd, Vector3.UP) * Basis.from_euler(
			Vector3(deg_to_rad(BOW_ROT_DEG.x), deg_to_rad(BOW_ROT_DEG.y),
				deg_to_rad(BOW_ROT_DEG.z)))
		_bow.global_rotation = look.get_euler()
		return
	# Fallback (no skeleton/hand found): the old body-offset ride.
	if _mesh == null:
		return
	var yaw: float = _mesh.rotation.y
	var fwd := Vector3(sin(yaw), 0.0, cos(yaw))
	var right := Vector3(fwd.z, 0.0, -fwd.x)
	var draw2 := clampf(absf(_fire_recoil) / 0.2, 0.0, 1.0)
	var target := global_position + Vector3(0.0, 0.60, 0.0) \
		+ right * 0.24 + fwd * (0.14 + 0.24 * draw2)
	_bow.global_position = _bow.global_position.lerp(target, 0.55)
	var look := Basis.looking_at(fwd, Vector3.UP) * Basis.from_euler(
		Vector3(deg_to_rad(BOW_ROT_DEG.x), deg_to_rad(BOW_ROT_DEG.y),
			deg_to_rad(BOW_ROT_DEG.z)))
	_bow.global_rotation = look.get_euler()

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
	# Phase B — hits landing on someone else's body here are forwarded to
	# their machine; the owner applies the real rules (ward/grit/iframes).
	if _is_remote:
		if multiplayer.is_server():
			_net_take_damage.rpc_id(get_multiplayer_authority(), amount, from_dir)
		return
	if dead or _iframe_t > 0.0:
		return
	# Spec 45-wilds — Stonebreak Tonic: bites land softer while it holds.
	var game_g := get_tree().root.get_node_or_null("Game")
	if game_g != null:
		var grit: float = clampf(float(game_g.buff_value("grit")), 0.0, 0.8)
		if grit > 0.0:
			amount = int(round(float(amount) * (1.0 - grit)))
	# B5-wave2 — Heartwood Ward soaks before vigor is touched. A fully
	# soaked hit still grants iframes (the blow landed on the bark).
	if _ward_hp > 0 and amount > 0:
		var soak: int = mini(_ward_hp, amount)
		_ward_hp -= soak
		amount -= soak
		if amount <= 0:
			_iframe_t = IFRAMES_SEC
			_combat_t = COMBAT_TIMER
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
		if _hud.has_method("hurt_vignette"):
			_hud.hurt_vignette()
		_hud.set_hp(hp, hp_max)
	if hp <= 0:
		_die()

# Death — crumple + sink + Pokémon white-out; respawn under the white.
func _die() -> void:
	dead = true
	died.emit()
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
	if _ap != null and _clip_idle != "":
		_ap.play(_clip_idle)
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
# Wyrd — soft aim assist bends the shot toward the nearest enemy in a cone:
# WASD-relative aiming without it demands pixel-perfect strafing, which is
# most of "combat feels rough."
const AIM_ASSIST_RANGE := 14.0
const AIM_ASSIST_CONE := 28.0        # degrees off the raw aim that still snaps
const AIM_ASSIST_BLEND := 0.7        # 0 = ignore enemy, 1 = hard lock

func aim_dir() -> Vector3:
	# Phase B — a host-side replay of a guest's cast aims where they aimed.
	if net_aim != Vector3.ZERO:
		return net_aim.normalized()
	var dir := _input_dir()
	if dir.length() < 0.1:
		if _mesh != null:
			var yaw: float = _mesh.rotation.y
			dir = Vector3(sin(yaw), 0.0, cos(yaw))
	dir = _soft_aim(dir.normalized())
	return dir.normalized()

func _soft_aim(dir: Vector3) -> Vector3:
	var best: Node3D = null
	var best_ang := deg_to_rad(AIM_ASSIST_CONE)
	for e in get_tree().get_nodes_in_group("enemy"):
		if not (e is Node3D) or not is_instance_valid(e):
			continue
		var ehp = e.get("hp")
		if ehp != null and int(ehp) <= 0:
			continue                  # dying body — don't magnetize to it
		var to: Vector3 = (e as Node3D).global_position - global_position
		to.y = 0.0
		var d := to.length()
		if d > AIM_ASSIST_RANGE or d < 0.5:
			continue
		var ang := dir.angle_to(to / d)
		if ang < best_ang:
			best_ang = ang
			best = e
	if best == null:
		return dir
	var to_t: Vector3 = best.global_position - global_position
	to_t.y = 0.0
	return dir.slerp(to_t.normalized(), AIM_ASSIST_BLEND)

# Snap the mesh to face where the shot actually goes — firing while strafing
# without the snap looks like the ranger shoots out of her shoulder.
func face_aim(dir: Vector3) -> void:
	if _mesh != null and dir.length() > 0.1:
		_mesh.rotation.y = atan2(dir.x, dir.z)

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
	t.tween_property(_bow, "scale", Vector3.ONE * _bow_scale * scale_mult, 0.04)
	t.tween_property(_bow, "scale", Vector3.ONE * _bow_scale, 0.13)

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
	if float(_skill_cooldowns.get(slot, 0.0)) > 0.0:
		return                   # on cooldown
	focus -= skill.cost
	_skill_cooldowns[slot] = skill.effective_cd(self)
	_combat_t = COMBAT_TIMER
	face_aim(aim_dir())          # Wyrd — square up before the skill fires
	skill.fire(self)
	_net_forward_cast(slot)

# ---- setup helpers ----
# The Meshy rig has no authored socket — the bow rides the RightHand bone
# via _update_bow(); it's parented to the player (normal scale) so it
# dodges the skeleton's internal scaling.
# ---- A6/anim-P1: the gather pose ----------------------------------------
# During a channel the bow hides, the equipped tool (if any) rides in front
# of the body toward the node, and the mesh swings on a loop. GatherNode
# drives begin/end.
var _gather_tool: Node3D = null
var _gather_tween: Tween = null

const TOOL_MODELS := {
	"bogiron_pickaxe": "res://models/weapon_bogiron_pickaxe.glb",
	"bogiron_axe": "res://models/weapon_bogiron_axe.glb",
	"cinderbloom_pickaxe": "res://models/weapon_cinderbloom_pickaxe.glb",
	"cinderbloom_axe": "res://models/weapon_cinderbloom_axe.glb",
}

func begin_gather(kind: String, node_pos: Vector3) -> void:
	if _mesh != null:
		var to := node_pos - global_position
		if to.length() > 0.01:
			_mesh.rotation.y = atan2(to.x, to.z)
	if _bow != null:
		_bow.visible = false
	# The equipped tool appears in hand (mining/chopping only).
	var slot: String = {"ore_rock": "pickaxe", "log_pile": "axe"}.get(kind, "")
	if slot != "" and equipment != null:
		var tool = equipment.get_slot(String(slot))
		if tool != null:
			var path := String(TOOL_MODELS.get(String(tool.get("kind_id", "")), ""))
			if path != "" and ResourceLoader.exists(path):
				_gather_tool = (load(path) as PackedScene).instantiate()
				add_child(_gather_tool)
				GlbFit.normalize_height(_gather_tool, 0.7)
				var yaw: float = _mesh.rotation.y if _mesh != null else 0.0
				var fwd := Vector3(sin(yaw), 0.0, cos(yaw))
				_gather_tool.position = Vector3(0, 0.55, 0) + fwd * 0.35 \
					+ Vector3(fwd.z, 0.0, -fwd.x) * 0.18
				_gather_tool.rotation.y = yaw
	# The swing: a forward lean loop (forage kneels lower, slower).
	if _mesh != null:
		_gather_tween = create_tween().set_loops()
		var depth := 0.32 if kind != "forage_node" else 0.2
		var beat := 0.5 if kind != "forage_node" else 0.7
		_gather_tween.tween_property(_mesh, "rotation:x", depth, beat * 0.4) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_gather_tween.tween_property(_mesh, "rotation:x", 0.0, beat * 0.6) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if _gather_tool != null:
			_gather_tween.parallel().tween_property(_gather_tool, "rotation:x",
				-1.1, beat * 0.4).set_trans(Tween.TRANS_QUAD)
			_gather_tween.parallel().tween_property(_gather_tool, "rotation:x",
				0.0, beat * 0.6)

func end_gather() -> void:
	if _gather_tween != null:
		_gather_tween.kill()
		_gather_tween = null
	if _mesh != null:
		_mesh.rotation.x = 0.0
	if _gather_tool != null:
		_gather_tool.queue_free()
		_gather_tool = null
	if _bow != null:
		_bow.visible = true

func _attach_bow() -> void:
	_bow = BOW_SCENE.instantiate()
	_tint(_bow, Color(0.40, 0.28, 0.18))
	# Spec 46-C — anchor at the bow hand via BoneAttachment3D (archers hold
	# the bow in the LEFT hand; the right draws). Falls back to the old
	# body-offset ride when no skeleton/hand exists.
	var hand_idx := -1
	if _skel != null:
		for bone_name in ["LeftHand", "RightHand"]:
			hand_idx = _skel.find_bone(bone_name)
			if hand_idx >= 0:
				break
		if hand_idx < 0:
			for i in _skel.get_bone_count():
				var bn := _skel.get_bone_name(i).to_lower()
				if bn.contains("hand"):
					hand_idx = i
					break
	if _skel != null and hand_idx >= 0:
		# Hybrid anchor: the BoneAttachment supplies the exact hand POINT
		# (post-animation, no jitter); the bow itself stays top_level so
		# its orientation/scale live in world space — no bone-basis or
		# rig-scale fights.
		_bow_socket = BoneAttachment3D.new()
		_bow_socket.name = "BowSocket"
		_skel.add_child(_bow_socket)
		_bow_socket.bone_name = _skel.get_bone_name(hand_idx)
		_bow_socket.add_child(_bow)
		_bow.top_level = true
		_bow.scale = Vector3.ONE * _bow_scale
	else:
		add_child(_bow)
		_bow.scale = Vector3.ONE * _bow_scale
		push_warning("player: no hand bone — bow rides the body offset")

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

# ADR 0013 — leveling Wayfinding grows base damage/HP, so a level-up must
# refresh the live combat stats (they otherwise only re-derive on equip/load).
# Grow current HP by the pool increase so the level is *felt* — but only the
# delta, so it can't be abused as a full-heal by leveling mid-run.
func _on_leveled_up(_trade: String, _new_lv: int) -> void:
	var prev_max: int = hp_max
	_derive_stats()
	var grew: int = hp_max - prev_max
	if grew > 0:
		hp = mini(hp + grew, hp_max)
		if _hud != null:
			_hud.set_hp(hp, hp_max)

# Sum every equipped item's base stat + affixes into a derived totals dict
# (HP max, damage, crit chance/mult bonus, scaled fire cooldown + move
# speeds). Combat consumers read from here instead of the consts.
# Spec 29 — shrine_buffs sum into the same dict on top of equipment, so a
# shrine boon stacks additively with whatever gear the player has on.
func _derive_stats() -> void:
	var sums := {"hp": 0, "damage": 0, "crit_chance": 0.0,
		"crit_mult": 0.0, "fire_rate": 0.0, "move_speed": 0.0,
		"cooldown_reduction": 0.0}
	# ADR 0013 — gear gives power again (reverses the 0010 freeze): every
	# equipped item's base_stat + rolled affixes flow into the sums.
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
	# B7 — Huntcraft perks ride the same sums.
	var game_h := get_tree().root.get_node_or_null("Game")
	if game_h != null:
		if game_h.perk_active("wayfinding", "steady_hands"):
			_add_stat(sums, "crit_chance", 0.05)
		if game_h.perk_active("wayfinding", "hunters_stride"):
			_add_stat(sums, "move_speed", 0.05)
		# Spec 45-hunt — the deep perks ride the same shape.
		if game_h.perk_active("wayfinding", "quick_nock"):
			_add_stat(sums, "cooldown_reduction", 0.10)
		if game_h.perk_active("wayfinding", "heavy_draw"):
			_add_stat(sums, "crit_mult", 0.25)
		# Spec 45-wilds — Crowsfoot Cordial's stride rides the buff engine.
		_add_stat(sums, "move_speed", float(game_h.buff_value("move_speed")))
	# ADR 0013 — your Wayfinding level grows base power (symmetric with the
	# den scaling, so difficulty tracks level-delta). Gear adds flat on top.
	var pf := 1.0
	if game_h != null:
		pf = pow(float(game_h.LEVEL_POWER), float(game_h.trade_lv() - 1))
	derived_stats = {
		"hp_max":              int(round(PLAYER_HP * pf)) + int(sums.hp),
		"damage":              int(round(6.0 * pf)) + int(sums.damage),
		"crit_chance":         clampf(0.20 + float(sums.crit_chance), 0.0, 1.0),
		"crit_mult_bonus":     float(sums.crit_mult),
		"fire_cooldown":       FIRE_COOLDOWN / ((1.0 + float(sums.fire_rate))
			* _chart_fire_mult()),
		"run_speed":           RUN_SPEED * (1.0 + float(sums.move_speed)) * _chart_speed_mult(),
		"walk_speed":          WALK_SPEED * (1.0 + float(sums.move_speed)) * _chart_speed_mult(),
		# Spec 30 — capped CDR for skill 2-4 cooldowns. Skill 1 (BasicShot)
		# is still scaled by `fire_rate` via `fire_cooldown` above.
		"cooldown_reduction": clampf(float(sums.cooldown_reduction), 0.0, CDR_CAP),
	}
	# Apply HP max change — clamp current HP down if max shrunk; don't auto-heal.
	hp_max = derived_stats.hp_max
	hp = mini(hp, hp_max)
	if _hud != null:
		_hud.set_hp(hp, hp_max)

# B6 — Quiver: +20% fire rate in-chart; Damp Strings: -10%.
func _chart_fire_mult() -> float:
	var game := get_tree().root.get_node_or_null("Game")
	if game == null or not bool(game.in_dungeon):
		return 1.0
	if game.affix_good("quiver"):
		return 1.2
	if game.affix_bad("quiver"):
		return 0.9
	return 1.0

# A8-full — Clearwater Philter: Focus pools half again as fast while the
# sip lasts (anywhere, unlike chart affixes).
func _buff_focus_mult() -> float:
	var game := get_tree().root.get_node_or_null("Game")
	if game == null:
		return 1.0
	return 1.0 + float(game.buff_value("focus_regen"))

# B6 — Echoing Steps: +50% focus regen in-chart; Hollow Echo: -25%.
func _chart_focus_mult() -> float:
	var game := get_tree().root.get_node_or_null("Game")
	if game == null or not bool(game.in_dungeon):
		return 1.0
	if game.affix_good("echoing"):
		return 1.5
	if game.affix_bad("echoing"):
		return 0.75
	return 1.0

# B6 — Mired Boots (sprinter's bad twin): -10% player speed in-chart.
func _chart_speed_mult() -> float:
	var game := get_tree().root.get_node_or_null("Game")
	if game != null and bool(game.in_dungeon) and game.affix_bad("sprinter"):
		return 0.9
	return 1.0

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

# ---- spec 46 Phase A: co-op body sync ----
# The authority broadcasts position/yaw/moving at NET_SEND_HZ over an
# unreliable ordered RPC; every other machine lerps its puppet toward the
# last state. Identical node paths per peer (NetGame names players by id)
# make the RPC routing free.
var _is_remote := false
var _net_accum := 0.0
var _net_has_target := false
var _net_target_pos := Vector3.ZERO
var _net_target_yaw := 0.0
var _net_moving := false
const NET_SEND_HZ := 12.0

func _net_send_tick(delta: float) -> void:
	var net := get_node_or_null("/root/NetGame")
	if net == null or not bool(net.active):
		return
	_net_accum += delta
	if _net_accum < 1.0 / NET_SEND_HZ:
		return
	_net_accum = 0.0
	var yaw: float = _mesh.rotation.y if _mesh != null else 0.0
	_net_state.rpc(global_position, yaw,
		Vector2(velocity.x, velocity.z).length() > 0.5, dead)

@rpc("authority", "unreliable_ordered")
func _net_state(pos: Vector3, yaw: float, moving: bool,
		p_dead: bool = false) -> void:
	_net_has_target = true
	_net_target_pos = pos
	_net_target_yaw = yaw
	_net_moving = moving
	# Phase B — enemies skip dead puppets; the died edge feeds party-wipe
	# checks on every machine.
	if p_dead and not dead:
		dead = true
		died.emit()
	elif not p_dead:
		dead = false

func _net_remote_tick(delta: float) -> void:
	if not _net_has_target:
		return
	var t := minf(1.0, delta * 10.0)
	global_position = global_position.lerp(_net_target_pos, t)
	if _mesh != null:
		_mesh.rotation.y = lerp_angle(_mesh.rotation.y, _net_target_yaw, t)
	# Phase B — puppets walk instead of gliding (the flag already rides
	# the state RPC).
	_play_anim("run" if _net_moving else "idle")
	if _ap != null:
		_ap.speed_scale = 1.0 if _net_moving else 0.85

# Phase B — a remote-authority body hit on the HOST forwards the damage
# to its owner, who applies the real rules (ward, grit, iframes) locally.
@rpc("any_peer", "reliable")
func _net_take_damage(amount: int, from_dir: Vector3) -> void:
	if is_multiplayer_authority():
		take_damage(amount, from_dir)

# Phase B — guests cast through the host: the host replays the skill from
# this puppet with the caster's aim + stats (trust-the-party model, v1).
@rpc("any_peer", "reliable")
func _net_cast(slot: int, aim: Vector3, stats: Dictionary) -> void:
	# Phase C — every machine replays the cast through the caster's body
	# here: REAL on the host (its enemies are truth), cosmetic on guests
	# (puppet foes take no damage). The caster never receives (no
	# call_local) — their local fire already played.
	if not _is_remote:
		return
	if slot < 1 or slot > skills.size():
		return
	net_aim = aim
	derived_stats = stats
	var sk = skills[slot - 1]
	sk.fire(self)
	net_aim = Vector3.ZERO

# Set while the host replays a guest cast — aim_dir() honors it.
var net_aim := Vector3.ZERO

# A guest's local cast is cosmetic (puppet enemies take no damage); the
# host replays it for real on this player's host-side body.
func _net_forward_cast(slot: int) -> void:
	var net := get_node_or_null("/root/NetGame")
	if net == null or not bool(net.active):
		return
	# Broadcast (host included as a sender): guests draw each other's and
	# the host's arrows; the host's copy of a guest cast is the real one.
	_net_cast.rpc(slot, aim_dir(), derived_stats)

# B5-wave2 — Heartwood Ward: a timed absorb pool soaked in take_damage.
var _ward_hp := 0
var _ward_t := 0.0
# Spec 45-wilds — Mothmint Mend's fractional heal carry.
var _regen_accum := 0.0

# Spec 45-hunt — Even Breath's kill refund lands here (combatant._die).
func add_focus(amount: float) -> void:
	focus = clampf(focus + amount, 0.0, focus_max)
	if _hud != null and _hud.has_method("set_focus"):
		_hud.set_focus(focus, focus_max)

func apply_ward(amount: int, duration: float) -> void:
	_ward_hp = amount
	_ward_t = duration
	# Bark-brown flash on the mesh sells the skin hardening.
	if _mesh != null:
		var tw := create_tween()
		tw.tween_property(_mesh, "scale", _mesh.scale * 1.08, 0.10)
		tw.tween_property(_mesh, "scale", _mesh.scale, 0.14)

# Shrine.gd calls this with the picked buff's stat + value (additive).
func apply_shrine_buff(stat: String, value) -> void:
	if shrine_buffs.has(stat):
		shrine_buffs[stat] += value
	_derive_stats()
	print("[shrine] +%s %s applied" % [str(value), stat])

# HUD buttons call these (the keybinds route here too).
# B5 — the skill factory. Rebuilds `skills` from Game.loadout; the skill
# bar rebinds so labels/icons/costs follow.
const SKILL_FACTORY := {
	"PowerShot": preload("res://scripts/skills/power_shot.gd"),
	"MultiShot": preload("res://scripts/skills/multi_shot.gd"),
	"BrambleSnare": preload("res://scripts/skills/bramble_snare.gd"),
	"PiercingBolt": preload("res://scripts/skills/piercing_bolt.gd"),
	"RainOfThorns": preload("res://scripts/skills/rain_of_thorns.gd"),
	"Thornburst": preload("res://scripts/skills/thornburst.gd"),
	"HuntersMark": preload("res://scripts/skills/hunters_mark.gd"),
	"HeartwoodWard": preload("res://scripts/skills/heartwood_ward.gd"),
	"MercyShot": preload("res://scripts/skills/mercy_shot.gd"),
}

func rebuild_skills() -> void:
	var game := get_tree().root.get_node_or_null("Game")
	var picks: Array = ["PowerShot", "MultiShot", "BrambleSnare"]
	if game != null and (game.loadout as Array).size() == 3:
		picks = game.loadout
	skills = [BasicShotScript.new()]
	for sk in picks:
		var script = SKILL_FACTORY.get(String(sk))
		if script != null:
			skills.append(script.new())
	# Re-SEED, never just clear — a bare clear() left slots 1-4 unkeyed and
	# the next cast crashed on _skill_cooldowns[slot] (the frozen-game bug).
	_skill_cooldowns.clear()
	for i in range(1, skills.size() + 1):
		_skill_cooldowns[i] = 0.0
	for layer in (get_tree().current_scene.get_children() \
			if get_tree().current_scene != null else []):
		if layer is CanvasLayer and layer.has_method("bind_to_player") \
				and layer.get("SKILL_ICON") != null:
			layer.bind_to_player(self)

func toggle_inventory() -> void:
	if _inv_root != null:
		_inv_root.toggle()

func toggle_satchel() -> void:
	# One window, no split — M opens the pack on its Satchel tab.
	if _inv_root != null:
		_inv_root.open_tab(1)

func toggle_trades() -> void:
	if _inv_root != null:
		_inv_root.open_tab(3)

# Hearth.gd calls this to refill HP before saving the checkpoint slot.
func _quaff() -> void:
	if dead:
		return
	var game := get_tree().root.get_node_or_null("Game")
	if game == null:
		return
	var amount := 0
	if hp < hp_max:
		amount = int(game.quaff_draught())
		if amount <= 0:
			return
	else:
		# A8-full — topped up: Q reaches for Quill's shelf instead.
		if not bool(game.quaff_buff_draught()):
			return
	var sfx := get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.play("quaff")
	# Anim-P1: the drink — head tips back, settles.
	if _mesh != null:
		var tw := create_tween()
		tw.tween_property(_mesh, "rotation:x", -0.35, 0.15) \
			.set_trans(Tween.TRANS_QUAD)
		tw.tween_interval(0.25)
		tw.tween_property(_mesh, "rotation:x", 0.0, 0.2)
	if amount > 0:
		hp = mini(hp + amount, hp_max)
		if _hud != null:
			_hud.set_hp(hp, hp_max)

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
	# Wyrd — a re-instanced player (Town↔Dungeon transitions) must not
	# append duplicate events onto an action that already exists.
	if InputMap.has_action(action):
		return
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
