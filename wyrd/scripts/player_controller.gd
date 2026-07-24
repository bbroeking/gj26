extends CharacterBody3D

# Spec 07 / 13 / 23 — the player Ranger.
# Camera-relative movement with a walk/run/dash/roll state machine, the bow
# + arrow firing, HP/death. Animation is clip-based (spec 23 — the Meshy
# v5 Ranger ships working idle/walk/run clips); the bow rides the RightHand
# bone each frame.

const BOW_SCENE := preload("res://models/prop_bow_v1.glb")
const BowDrawModifier := preload("res://scripts/bow_draw_modifier.gd")  # Phase 4
const GatherSwingModifier := preload("res://scripts/gather_swing_modifier.gd")  # Plan.md B1
const ARROW_SCENE := preload("res://scenes/Arrow.tscn")
const ArrowScript := preload("res://scripts/arrow.gd")  # static variant_idx
const WeaponPresentations := preload("res://data/weapon_presentations.gd")
const WayweaverRuneCosmetics := preload("res://data/wayweaver_rune_cosmetics.gd")
const InventoryPanelScene := preload("res://scenes/InventoryPanel.tscn")  # spec 27c
const SkillBarScene := preload("res://scenes/SkillBar.tscn")              # spec 30
const StatusEffectScript := preload("res://scripts/status_effect.gd")     # spec 33a
const RANGER_BODY_PATH := "res://models/npc_ranger_v5_rigged.glb"
const RANGER_WALK_PATH := "res://models/ranger_walk_anim_v1.glb"
const RANGER_RUN_PATH := "res://models/ranger_run_anim_v1.glb"
# Wyrd — the chibi wayfinder (Meshy rig pipeline, 2026-06-10). When the
# rigged GLB exists it replaces the Player.tscn ranger mesh wholesale;
# the ranger remains the fallback so the game never loses its body.
const CHIBI_BODY_PATH := "res://models/player_chibi_v1_rigged.glb"
const CHIBI_WALK_PATH := "res://models/player_chibi_walk_anim_v1.glb"
const CHIBI_RUN_PATH := "res://models/player_chibi_run_anim_v1.glb"
const CHIBI_DASH_PATH := "res://models/player_chibi_dash_anim_v1.glb"
const CHIBI_HEIGHT := 1.25
# Spec 32b — concrete skill classes; instantiated in _ready as the player's
# loadout. Skill modules own their own firing logic; the player just
# dispatches via `_try_skill(slot)`.
const BasicShotScript := preload("res://scripts/skills/basic_shot.gd")
const EnchantDefs := preload("res://data/enchants.gd")
const PowerShotScript := preload("res://scripts/skills/power_shot.gd")
const MultiShotScript := preload("res://scripts/skills/multi_shot.gd")
const BrambleSnareScript := preload("res://scripts/skills/bramble_snare.gd")
const ThreadstepAuthority := preload("res://scripts/threadstep_authority.gd")
const WayfindersMarkScript := preload("res://scripts/skills/wayfinders_mark.gd")
const WayweaverThreadRules := preload("res://scripts/wayweaver_thread_rules.gd")
const WayweaverEchoAuthority := preload("res://scripts/wayweaver_echo_authority.gd")
const RoomPresenceScript := preload("res://scripts/room_presence.gd")
const SkillEffectScript := preload("res://scripts/skills/skill_effect.gd")
const AmbientPoseDriverScript := preload("res://scripts/ambient_pose_driver.gd")

# ---- locomotion (always-run; Shift walks) ----
# Cozy belongs in the world, not in input latency. The First Road playtest
# restored an ARPG cadence while keeping Shift-walk for deliberate town motion.
const RUN_SPEED := 5.2
const WALK_SPEED := 2.6
const ACCEL := 28.0
# Spec 36 (Batch B) — split decel rates. Single ACCEL did both speed-up and
# stop, so stops felt skiddy and direction-reversals felt delayed. Now:
#  - speed-up keeps ACCEL=12 (cozy weight on start)
#  - stop uses DECEL — slightly snappier so releasing input reads deliberate
#  - reverse uses TURN_DECEL — much snappier so W→S is instant, not laggy
const DECEL := 34.0
const TURN_DECEL := 44.0
const GRAVITY := 22.0

# Spec 36 — foot-slide fix. Anim playback was a static `speed_scale = 0.85`,
# so foot-slide was visible at every speed except the calibrated one. Now
# scale per-frame by ground speed, clamped so the cycle never goes cartoonish.
# WALK_REF_SPEED matches the responsive-road run speed so stride cadence stays
# proportional without making the faster controller look hurried.
const WALK_REF_SPEED := 5.2

# ---- dash: a fast reposition burst, no i-frames ----
const DASH_SPEED := 11.0
const DASH_TIME := 0.18
const DASH_COOLDOWN := 0.7

# ---- roll: a dodge — burst + i-frame window + a tumble ----
const ROLL_SPEED := 9.0
const ROLL_TIME := 0.32
const ROLL_IFRAMES := 0.18   # 56% of the faster roll; recovery remains punishable
const ROLL_COOLDOWN := 0.55

# ---- weapon ----
const FIRE_COOLDOWN := 0.28         # spec 26 — snappier cadence
const BOW_DRAW_TIME := 0.22         # Phase 4 — arm draw-and-loose duration on a shot
const BOW_ANTICIPATION_TIME := 0.07 # visible nock before the Basic arrow exists
const ARROW_SPAWN_FWD := 0.3
const INPUT_BUFFER_SEC := 0.15
const BOW_SCALE := 0.5
const BOW_ROT_DEG := Vector3.ZERO  # authored glTF is already upright

# ---- survival (spec 15) ----
const PLAYER_HP := 30
const IFRAMES_SEC := 0.6
const HIT_KNOCKBACK := 4.5
const DEATH_PAUSE := 1.2
# Phase 1 — "getting hit" feel (Plan.md). One block so playtest tuning is fast.
const STUN_SEC := 0.10        # micro-stun input-lock on a hit (≤0.15 = no stunlock)
const FLINCH_SEC := 0.16      # mesh squash flinch
const BLINK_PERIOD := 0.12    # i-frame blink on/off period (the "I'm safe" tell)

# ---- clip names in the Meshy GLBs ----
const CLIP_IDLE := "Armature|Idle|baselayer"
const CLIP_WALK := "Armature|walking_man|baselayer"
const CLIP_RUN := "Armature|running|baselayer"

enum Move { NORMAL, DASH, ROLL }

var _mesh: Node3D
var _ap: AnimationPlayer
var _skel: Skeleton3D
var _bow_draw_t := 0.0       # Phase 4 — bow-draw timer (set on each shot)
var _basic_release_pending := false
var _bow_modifier: SkeletonModifier3D = null
var _gather_modifier: SkeletonModifier3D = null   # Plan.md B1 — gather arm-swing
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
var _weapon_presentation: Dictionary = {}
var _wayweaver_strand_style: Dictionary = {} # presentation-only, never saved

# D8 Slice 3 — Wayweaver's thread is intentionally owned by this live Player
# body, never Game/save data.  World will feed the authored room identity via
# `set_wayweaver_room_presence`; until that happens this fails closed.
var _wayweaver_threads: WayweaverThreadRules
var _wayweaver_presence: Dictionary = {}
var _wayweaver_basic_modifiers: Dictionary = {}
var _wayweaver_echo_authority: WayweaverEchoAuthority
var _wayweaver_echo_pending: Dictionary = {}
var _wayweaver_echo_gameplay_applications := 0 # transient test/diagnostic edge, never saved
var _wayweaver_echo_replayed_nonces: Dictionary = {} # receipt nonce -> true, session only
var _wayweaver_echo_replay_applications := 0
var _wayweaver_rune_sfx_applications := 0 # transient presentation receipt count
var _wayweaver_host_basic_tokens: Array = [] # FIFO {aim, peer_id, room_key}; exactly one real Basic each
var _wayweaver_host_basic_pending: Dictionary = {} # remote Basic deferred one message/frame for its echo
var _wayweaver_host_local_release: Dictionary = {} # one host-owner reducer result, consumed by the authority receipt
static var _wayweaver_echo_nonce_seed := 0
# Resolved clip names — Meshy rigs and the legacy ranger GLBs name their
# clips differently; _setup_clips finds them by substring.
var _clip_idle := ""
var _clip_walk := ""
var _clip_run := ""
var _clip_dash := ""
var _idle_pose_driver: Node = null
var _cinematic_walk_active := false
var _cinematic_ap_process_mode := Node.PROCESS_MODE_INHERIT

var _move: Move = Move.NORMAL
var _burst_dir := Vector3.FORWARD
var _burst_t := 0.0
var _dash_cd := 0.0
var _roll_cd := 0.0

var _fire_buffer := 0.0
var _fire_recoil := 0.0       # back-lean on the mesh after a shot

# Animation-feel tunables (defaults = shipped values). Overridable per capture
# via env vars so option variants can be filmed without editing code — see
# _read_anim_env(). Gameplay is unaffected when the env vars are unset.
var _arc_up := 0.24           # bow rise on the draw (picked: S1 "balanced")
var _arc_fwd := 0.32          # bow reach-forward on the draw
var _shot_recoil := -0.6      # mesh back-lean on a shot (read by projectile_skill)
var _roll_hop := 0.88         # somersault hop height (picked: R3 "big tumble")
var _roll_dust_n := 18        # roll dust particle count

func _read_anim_env() -> void:
	if OS.get_environment("ARC_UP") != "":
		_arc_up = float(OS.get_environment("ARC_UP"))
	if OS.get_environment("ARC_FWD") != "":
		_arc_fwd = float(OS.get_environment("ARC_FWD"))
	if OS.get_environment("RECOIL") != "":
		_shot_recoil = float(OS.get_environment("RECOIL"))
	if OS.get_environment("ROLL_HOP") != "":
		_roll_hop = float(OS.get_environment("ROLL_HOP"))
	if OS.get_environment("ROLL_DUST") != "":
		_roll_dust_n = int(OS.get_environment("ROLL_DUST"))

var hp := PLAYER_HP
var hp_max := PLAYER_HP
var dead := false
var _iframe_t := 0.0
var _stun_t := 0.0            # Phase 1 — micro-stun input lock
var _flinch_t := 0.0          # Phase 1 — mesh flinch squash
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
# The exact Interactable that consumed the most recent released InputMap action.
# It is transient scanner telemetry, not save/gameplay state; QA adapters use it
# to prove an input did not retarget across overlapping prompts.
var _last_interacted: Node = null
# A one-shot, opt-in expectation used by the strict D7 release driver. It is
# checked inside `_try_interact`, at the same input boundary that calls an
# Interactable. Normal play never arms it and therefore retains identical
# nearest-prompt behavior.
var _expected_interact: Node = null
var _expected_interact_armed := false
var _last_interact_receipt: Dictionary = {"status": "idle"}
# Spec 29 — shrine-granted buffs sum on top of equipment in _derive_stats().
# Stat keys mirror the equipment sums dict.
var shrine_buffs: Dictionary = {"hp": 0, "damage": 0, "crit_chance": 0.0,
	"crit_mult": 0.0, "fire_rate": 0.0, "move_speed": 0.0,
	"cooldown_reduction": 0.0}
# Spec 30/32b — a staged Skill bar + single regen "Focus" resource. Skills live
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
var _skill_cooldowns: Dictionary = {1: 0.0}
# Spec 33a — player-side status framework, mirrors Combatant's. Keyed by
# kind string ("burn" / "bleed" / "snared" / "root"); values are
# StatusEffect RefCounteds. Sunlit elite + future enemy modifiers apply
# statuses to the player through `apply_status`.
var _statuses: Dictionary = {}
var _hp_regen_accum := 0.0   # fractional HP banked from the hp_regen stat (vigorous affix)
# Spec 32b / ADR-0016 — the player's current runtime actions. Basic Shot is
# fixed in slot 1; the remaining 0–3 actions are only the Game loadout entries
# the player presently owns (or is temporarily granted by equipped gear).
# Slot N reads `skills[N-1]`. F-key fires `skills[0]`.
var skills: Array = []
# Fire in the Bough — Threadstep owns a reservation until a host ack resolves
# it.  It is deliberately separate from `_skill_cooldowns`: no generic Skill
# may debit the reserved Focus or start the cooldown before host acceptance.
var _threadstep_authority: ThreadstepAuthority
var _threadstep_pending: Dictionary = {}
var _threadstep_nonce := 0
var _threadstep_grace_t := 0.0
const THREADSTEP_COST := 20.0
const THREADSTEP_COOLDOWN := 8.0
const THREADSTEP_MAX_DISTANCE := 5.0
# D8 — Mark is an encounter-owned request, not a generic projectile cast.
# The owner holds this Focus locally until the sender-bound host receipt says
# otherwise, exactly like the party-trust model used by Threadstep.
const WAYFINDERS_MARK_COST := 35.0
const WAYFINDERS_MARK_COOLDOWN := 14.0
const WAYFINDERS_MARK_RANGE := 12.0
const WAYFINDERS_MARK_REELING_SEC := 3.0
var _wayfinders_mark_pending: Dictionary = {}
# Owner reservation IDs must outlive a particular Player node. The host keeps
# peer receipts across reconnect/body recreation, so restarting this counter at
# one could let an old accepted receipt match a new reservation. Monotonic
# process time is opaque to the host and remains stable for the live request.
static var _wayfinders_mark_nonce_seed := 0
var _wayfinders_mark_nonce := 0
var _wayfinders_mark_last_cancel_reason := ""
# Skills-on-items: on-hit SkillEffects from bound enchants, rebuilt in
# _derive_stats and appended to every shot's effects (ProjectileSkill).
var _enchant_hit_effects: Array = []

func _ready() -> void:
	add_to_group("player")
	_threadstep_authority = ThreadstepAuthority.new()
	_wayweaver_threads = WayweaverThreadRules.new()
	_wayweaver_echo_authority = WayweaverEchoAuthority.new()
	_read_anim_env()   # dev: per-capture animation-feel overrides (no-op if unset)
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
	if net != null and net.has_signal("session_ended"):
		net.session_ended.connect(_on_threadstep_session_ended)
		net.session_ended.connect(_on_wayfinders_mark_session_ended)
	if net != null and net.has_signal("reconnecting"):
		net.reconnecting.connect(_on_threadstep_reconnecting)
		net.reconnecting.connect(_on_wayfinders_mark_reconnecting)
	if net != null and net.has_signal("peer_rebound"):
		net.peer_rebound.connect(_on_wayweaver_peer_rebound)
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
	_bind("interact", [KEY_E], [JOY_BUTTON_A]) # spec 29/C2 — world interact parity
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
	if game != null and game.has_signal("wayweaver_cosmetic_changed"):
		game.wayweaver_cosmetic_changed.connect(_on_wayweaver_cosmetic_changed)
	if game != null and game.has_signal("leveled_up"):
		game.leveled_up.connect(_on_leveled_up)
	if game != null and game.has_signal("perks_changed"):
		game.perks_changed.connect(_derive_stats)   # mastery pick re-derives crit/move/CDR
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
		if _skel != null:
			# Phase 4 — a bow-draw modifier runs after the AnimationPlayer so the
			# arms can loose the bow over the playing locomotion clip.
			_bow_modifier = BowDrawModifier.new()
			_skel.add_child(_bow_modifier)
			# Plan.md B1 — gather arm-swing rides the same after-AnimationPlayer slot.
			_gather_modifier = GatherSwingModifier.new()
			_skel.add_child(_gather_modifier)
		_setup_clips()
		# Evaluate the authored idle before the first render. Waiting for the
		# first physics tick exposes the Meshy bind T-pose during Town's arrival
		# cutscene on a cold start.
		_play_anim("idle")
		if _ap != null:
			_ap.advance(0.0)
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
		# Defer through the player, not a callable that captures the player as an
		# argument. A fast co-op scene transition can free this body before the
		# message queue drains; a deferred call owned by the freed body is safely
		# discarded instead of invoking SkillBar with a null Object.
		call_deferred("_finish_skill_bar_setup", sb)
	if _hud != null:
		_hud.set_hp.call_deferred(hp, hp_max)
		_hud.set_focus.call_deferred(focus, focus_max)

func _finish_skill_bar_setup(sb: CanvasLayer) -> void:
	if is_instance_valid(sb) and is_inside_tree():
		sb.bind_to_player(self)

# The chunky ink silhouette (mirrors layout_loader / combatant). The overlay
# preserves every mesh's real material and avoids shared-GLB `next_pass`
# teardown errors in Godot's Compatibility renderer.
func _add_ink_outline(root: Node) -> void:
	for n in _all_mesh_instances(root):
		(n as MeshInstance3D).material_overlay = _ink_outline_pass()

func _ink_outline_pass() -> StandardMaterial3D:
	var o := StandardMaterial3D.new()
	o.grow = true
	o.grow_amount = 0.05
	o.cull_mode = BaseMaterial3D.CULL_FRONT
	o.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	o.albedo_color = Color(0.13, 0.09, 0.06)
	return o

# Instantiate the chibi Wayfinder when her rigged GLB is present, otherwise the
# legacy ranger. Player.tscn intentionally owns no model dependency: this keeps
# Web exports from packing both complete bodies when only one ships.
func _maybe_swap_chibi() -> void:
	var body_path := CHIBI_BODY_PATH if ResourceLoader.exists(CHIBI_BODY_PATH) \
		else RANGER_BODY_PATH
	if not ResourceLoader.exists(body_path):
		return
	var packed: PackedScene = load(body_path)
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
	_is_chibi = body_path == CHIBI_BODY_PATH

# Merge the locomotion clips (separate same-rig GLBs) into the body's
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
	_clip_dash = _find_clip_name(_ap, "runfast")
	if _is_chibi:
		# The Meshy rig ships walking/running as sidecar GLBs on the same
		# skeleton. The body export's nominal Idle is its rig bind/T-pose, so
		# merge the authored walk before choosing the stationary fallback.
		if _clip_walk == "" and ResourceLoader.exists(CHIBI_WALK_PATH):
			_merge_clip_by_key(lib, "walk", load(CHIBI_WALK_PATH), "walk")
			_clip_walk = "walk" if lib.has_animation("walk") else ""
		if _clip_run == "" and ResourceLoader.exists(CHIBI_RUN_PATH):
			_merge_clip_by_key(lib, "run", load(CHIBI_RUN_PATH), "run")
			_clip_run = "run" if lib.has_animation("run") else ""
		if _clip_dash == "" and ResourceLoader.exists(CHIBI_DASH_PATH):
			_merge_clip_by_key(lib, "dash", load(CHIBI_DASH_PATH), "runfast")
			_clip_dash = "dash" if lib.has_animation("dash") else ""
		# Derive a planted pose clip from the authored walk. It is deliberately
		# a separate Animation resource: aliasing idle to "walk" made a stopped
		# player run in place and also left AnimationPlayer paused on locomotion.
		if _clip_walk != "":
			const PLAYER_IDLE_POSE := "player_idle_pose"
			if lib.has_animation(PLAYER_IDLE_POSE):
				lib.remove_animation(PLAYER_IDLE_POSE)
			lib.add_animation(PLAYER_IDLE_POSE,
				lib.get_animation(_clip_walk).duplicate())
			_clip_idle = PLAYER_IDLE_POSE
	else:
		if _clip_walk == "" and ResourceLoader.exists(RANGER_WALK_PATH):
			_merge_clip_by_key(lib, "walk", load(RANGER_WALK_PATH), "walk")
			_clip_walk = "walk" if lib.has_animation("walk") else ""
		if _clip_run == "" and ResourceLoader.exists(RANGER_RUN_PATH):
			_merge_clip_by_key(lib, "run", load(RANGER_RUN_PATH), "run")
			_clip_run = "run" if lib.has_animation("run") else ""
	# Sensible fallbacks so a missing clip degrades, never T-poses.
	if _clip_idle == "":
		_clip_idle = _clip_walk if _clip_walk != "" else _clip_run
	if _clip_walk == "":
		_clip_walk = _clip_idle
	if _clip_run == "":
		_clip_run = _clip_walk
	if _clip_dash == "":
		_clip_dash = _clip_run
	for nm in [_clip_idle, _clip_walk, _clip_run, _clip_dash]:
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
	if _is_chibi and _clip_idle != "":
		_idle_pose_driver = AmbientPoseDriverScript.new()
		_idle_pose_driver.name = "PlayerIdlePoseDriver"
		_mesh.add_child(_idle_pose_driver)
		_idle_pose_driver.setup(_ap, _clip_idle, null, 0.75, 0.02, 4.4, 0.0)

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

func begin_cinematic_walk(direction: Vector3) -> void:
	if _ap == null or _mesh == null:
		return
	_cinematic_walk_active = true
	_cinematic_ap_process_mode = _ap.process_mode
	_ap.process_mode = Node.PROCESS_MODE_ALWAYS
	if _idle_pose_driver != null and _idle_pose_driver.has_method("set_motion_active"):
		_idle_pose_driver.set_motion_active(false)
	var flat_direction := Vector3(direction.x, 0.0, direction.z)
	if flat_direction.length_squared() > 0.001:
		_mesh.rotation.y = atan2(flat_direction.x, flat_direction.z)
	if _clip_walk != "":
		_ap.play(_clip_walk, 0.08)
		_ap.speed_scale = 0.90
		# Apply a real gait pose before the first cinematic frame is drawn.
		# AnimationPlayer otherwise exposes the imported bind pose for one frame
		# while the arrival cover fades away.
		_ap.advance(0.20)

func end_cinematic_walk() -> void:
	if not _cinematic_walk_active:
		return
	_cinematic_walk_active = false
	if _ap != null:
		_ap.speed_scale = 1.0
		_ap.process_mode = _cinematic_ap_process_mode
	_play_anim("idle")

func _physics_process(delta: float) -> void:
	# The host advances every peer's authoritative Threadstep ledger, including
	# remote puppets which return early below.  A guest only needs its pending
	# reservation and waits for an acknowledgement.
	var thread_net := get_node_or_null("/root/NetGame")
	if _threadstep_authority != null and (thread_net == null or not bool(thread_net.active)
			or bool(thread_net.is_host())):
		_threadstep_authority.tick(delta)
	_threadstep_grace_t = maxf(0.0, _threadstep_grace_t - delta)
	# Spec 46 Phase A — puppets only chase their synced transform.
	if _is_remote:
		_net_remote_tick(delta)
		return
	_net_send_tick(delta)
	_iframe_t = maxf(0.0, _iframe_t - delta)
	_stun_t = maxf(0.0, _stun_t - delta)
	_flinch_t = maxf(0.0, _flinch_t - delta)
	_bow_draw_t = maxf(0.0, _bow_draw_t - delta)   # Phase 4 — bow-draw decays 1→0
	if _bow_modifier != null:
		_bow_modifier.draw_amount = _bow_draw_t / BOW_DRAW_TIME
	# Phase 1 — i-frame blink ("I'm briefly safe") + flinch squash on the mesh.
	# Always writes base x squash so it self-restores; skipped while dead (the
	# death tween owns the mesh).
	if _mesh != null and not dead:
		_mesh.visible = _iframe_t <= 0.0 \
			or fmod(_iframe_t, BLINK_PERIOD) > BLINK_PERIOD * 0.5
		var fl := _flinch_t / FLINCH_SEC
		var sq := 0.22 * fl
		_mesh.scale = Vector3(
			_mesh_base_scale.x * (1.0 + sq * 0.5),
			_mesh_base_scale.y * (1.0 - sq),
			_mesh_base_scale.z * (1.0 + sq * 0.5))
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
	# Items — hp_regen (vigorous affix) heals slowly over time, in integer steps.
	if not dead and hp < hp_max:
		var rg := float(derived_stats.get("hp_regen", 0.0))
		if rg > 0.0:
			_hp_regen_accum += rg * delta
			while _hp_regen_accum >= 1.0 and hp < hp_max:
				hp += 1
				_hp_regen_accum -= 1.0
			if _hud != null:
				_hud.set_hp(hp, hp_max, _status_suffix())
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
	# Phase 1 — micro-stun: a hit briefly locks input. Knockback still carries
	# (velocity settles through move_and_slide), then control returns.
	if _stun_t > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)
		move_and_slide()
		return
	var modal_cancel_guarded := game_r != null \
		and game_r.has_method("modal_owns_cancel_release") \
		and bool(game_r.modal_owns_cancel_release())
	if Input.is_action_just_pressed("ui_cancel") and not modal_cancel_guarded:
		# A UI panel (pack, charm table, vendor…) owns Esc while open — let it
		# dismiss itself instead of stacking the pause menu on top of it.
		var g := get_node_or_null("/root/Game")
		if g != null and int(g.modal_count) > 0:
			return
		var menu: CanvasLayer = load("res://scripts/ui/pause_menu.gd").new()
		get_tree().current_scene.add_child(menu)
		return
	if Input.is_action_just_pressed("fire"):
		_fire_buffer = INPUT_BUFFER_SEC
	# Spec 30 — 1-4 fire the currently built actions. _try_skill makes absent,
	# unowned, and hidden slots harmless no-ops.
	for i in range(1, 5):
		if Input.is_action_just_pressed("skill_%d" % i):
			_try_skill(i)
	# Grab any overlapping loot (spec 27b).
	if Input.is_action_just_pressed("grab"):
		_try_grab()
	# Toggle the inventory panel (spec 27c).
	if Input.is_action_just_pressed("inv_toggle") and _inv_root != null \
			and (game_r == null or not game_r.has_method("onboarding_surface_available") \
			or bool(game_r.onboarding_surface_available("gear"))):
		_inv_root.toggle()
	# Toggle the satchel (Wyrd).
	if Input.is_action_just_pressed("satchel_toggle") \
			and (game_r == null or not game_r.has_method("onboarding_surface_available") \
			or bool(game_r.onboarding_surface_available("satchel"))):
		toggle_satchel()
	if Input.is_action_just_pressed("trades_toggle") \
			and (game_r == null or not game_r.has_method("onboarding_surface_available") \
			or bool(game_r.onboarding_surface_available("trades"))):
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
	if dir.length_squared() > 0.01 and game_r != null \
			and game_r.has_method("record_onboarding_event"):
		game_r.record_onboarding_event("first_movement")

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
			_mesh.position.y = sin(prog * PI) * _roll_hop
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
		if want_fire and not _basic_release_pending \
				and float(_skill_cooldowns.get(1, 0.0)) <= 0.0:
			_begin_basic_release()


func _begin_basic_release() -> void:
	# Give the eye one short nock/draw beat. Previously the Arrow was added to
	# the scene before the modifier could affect a rendered skeleton frame, so
	# the projectile visibly led the ranger's hands.
	_basic_release_pending = true
	_fire_buffer = 0.0
	face_aim(aim_dir())
	_bow_draw_t = BOW_DRAW_TIME
	if _bow_modifier != null:
		_bow_modifier.draw_amount = 1.0
	get_tree().create_timer(BOW_ANTICIPATION_TIME).timeout.connect(
		_release_basic_shot, CONNECT_ONE_SHOT)


func _release_basic_shot() -> void:
	_basic_release_pending = false
	if dead or _move != Move.NORMAL \
			or float(_skill_cooldowns.get(1, 0.0)) > 0.0 or skills.is_empty():
		return
	face_aim(aim_dir())
	# A real Basic release, rather than an input buffer or aim preview, is the
	# sole point that may spend an armed Wayweaver thread. The reducer spends it
	# even if the bolt later misses.
	var wayweaver_echo := _consume_wayweaver_basic_release()
	skills[0].fire(self)
	_emit_wayweaver_release_effect(wayweaver_echo, aim_dir())
	var game_lesson := get_tree().root.get_node_or_null("Game")
	if game_lesson != null and game_lesson.has_method(
			"record_onboarding_combat_action"):
		game_lesson.record_onboarding_combat_action("basic_shot")
	_net_forward_cast(1)
	_skill_cooldowns[1] = skills[0].effective_cd(self)
	_combat_t = COMBAT_TIMER

func _start_burst(m: Move, dir: Vector3) -> void:
	if m == Move.ROLL:
		var game_lesson := get_tree().root.get_node_or_null("Game")
		if game_lesson != null and game_lesson.has_method(
				"record_onboarding_combat_action"):
			game_lesson.record_onboarding_combat_action("roll")
		var sfx_r := get_node_or_null("/root/Sfx")
		if sfx_r != null:
			sfx_r.play("roll")
		_spawn_roll_dust()   # kick up dust so the dodge reads + has weight
	_move = m
	_burst_dir = dir.normalized() if dir.length() > 0.1 else _facing_dir()
	if m == Move.DASH:
		_burst_t = DASH_TIME
		_dash_cd = DASH_COOLDOWN
	else:
		_burst_t = ROLL_TIME
		_roll_cd = ROLL_COOLDOWN
		_iframe_t = maxf(_iframe_t, ROLL_IFRAMES)

const TEX_DUST := preload("res://assets/vfx/soft_circle.png")

# A quick low dust puff at the feet on a roll — sells the burst + gives the
# dodge weight so it reads from the top-down camera, not just a bare tumble.
func _spawn_roll_dust() -> void:
	var host := get_parent()
	if host == null:
		return
	var p := GPUParticles3D.new()
	p.amount = _roll_dust_n
	p.lifetime = 0.5
	p.one_shot = true
	p.explosiveness = 0.9
	p.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.0, 0.3, 0.0)
	pm.spread = 85.0
	pm.flatness = 0.75                     # hug the ground plane
	pm.initial_velocity_min = 1.2
	pm.initial_velocity_max = 3.2
	pm.gravity = Vector3(0.0, -2.0, 0.0)
	pm.scale_min = 0.6
	pm.scale_max = 1.3
	var dust := Color(0.74, 0.68, 0.56)
	pm.color = dust
	var grad := Gradient.new()
	grad.set_color(0, Color(dust.r, dust.g, dust.b, 0.7))
	grad.set_color(1, Color(dust.r, dust.g, dust.b, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = grad
	pm.color_ramp = ramp
	p.process_material = pm
	var qm := QuadMesh.new()
	qm.size = Vector2(0.38, 0.38)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = dust
	mat.albedo_texture = TEX_DUST
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.material = mat
	p.draw_pass_1 = qm
	host.add_child(p)
	p.global_position = global_position + Vector3(0.0, 0.1, 0.0)
	p.emitting = true
	get_tree().create_timer(0.9).timeout.connect(p.queue_free)

# Play the clip for the movement state (crossfaded).
func _play_anim(state: String) -> void:
	if _ap == null:
		return
	var planted := state in ["idle", "roll"]
	if _idle_pose_driver != null \
			and _idle_pose_driver.has_method("set_motion_active"):
		_idle_pose_driver.set_motion_active(planted)
	if planted and _idle_pose_driver != null:
		return
	var clip := _clip_idle
	if state == "walk":
		clip = _clip_walk
	elif state == "run":
		clip = _clip_run
	elif state == "dash":
		clip = _clip_dash
	# Roll keeps the idle pose — a rigid tuck reads as a somersault; the
	# run cycle mid-tumble reads as a glitch.
	if clip != "" and _ap.current_animation != clip:
		# The burst is only 180 ms, so a locomotion-sized crossfade would hide
		# nearly the whole authored dash pose.
		_ap.play(clip, 0.04 if state == "dash" else 0.08)

# Spec 46-C — the bow is ANCHORED now: a BoneAttachment3D on the bow hand
# (BoneAttachment updates after the AnimationPlayer applies the pose, so
# the old "jittered around her hood" problem is gone — that jitter came
# from reading bone poses in _physics_process, one frame early). The
# recoil/draw motion rides as a local offset inside the socket.
func _update_bow() -> void:
	if _bow == null:
		return
	var hand_offset: Vector3 = _weapon_presentation.get("hand_offset",
		Vector3(0.12, 0.06, 0.05)) as Vector3
	var draw_forward := float(_weapon_presentation.get("draw_forward", _arc_fwd))
	var rot_deg: Vector3 = _weapon_presentation.get("rotation_degrees", BOW_ROT_DEG) as Vector3
	if _bow_socket != null and _mesh != null:
		var yaw: float = _mesh.rotation.y
		var fwd := Vector3(sin(yaw), 0.0, cos(yaw))
		var right := Vector3(fwd.z, 0.0, -fwd.x)
		var draw := clampf(_bow_draw_t / BOW_DRAW_TIME, 0.0, 1.0)
		# Anchored at the hand; eased just clear of the hood's silhouette.
		# On the draw the bow arcs UP + forward toward the aim so the shot reads
		# from the top-down camera (a small side-lift was near-invisible there).
		_bow.global_position = _bow_socket.global_position \
			+ right * hand_offset.x + Vector3(0.0, hand_offset.y + _arc_up * draw, 0.0) \
			+ fwd * (hand_offset.z + draw_forward * draw)
		var look := Basis.looking_at(fwd, Vector3.UP) * Basis.from_euler(
			Vector3(deg_to_rad(rot_deg.x), deg_to_rad(rot_deg.y),
				deg_to_rad(rot_deg.z)))
		_bow.global_rotation = look.get_euler()
		return
	# Fallback (no skeleton/hand found): the old body-offset ride.
	if _mesh == null:
		return
	var yaw: float = _mesh.rotation.y
	var fwd := Vector3(sin(yaw), 0.0, cos(yaw))
	var right := Vector3(fwd.z, 0.0, -fwd.x)
	var draw2 := clampf(_bow_draw_t / BOW_DRAW_TIME, 0.0, 1.0)
	var target := global_position + Vector3(0.0, 0.60, 0.0) \
		+ right * 0.24 + fwd * (0.14 + 0.24 * draw2)
	_bow.global_position = _bow.global_position.lerp(target, 0.55)
	var look := Basis.looking_at(fwd, Vector3.UP) * Basis.from_euler(
		Vector3(deg_to_rad(rot_deg.x), deg_to_rad(rot_deg.y),
			deg_to_rad(rot_deg.z)))
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
		# C8 — bark soaks (ward_absorb) or shatters (ward_break) audibly.
		var _wsfx := get_node_or_null("/root/Sfx")
		if _wsfx != null:
			_wsfx.play("ward_break" if _ward_hp <= 0 else "ward_absorb")
		if amount <= 0:
			_iframe_t = IFRAMES_SEC
			_combat_t = COMBAT_TIMER
			return
	hp -= amount
	_iframe_t = IFRAMES_SEC
	_stun_t = STUN_SEC            # Phase 1 — micro-stun input lock
	_flinch_t = FLINCH_SEC        # Phase 1 — mesh flinch
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
	_invalidate_wayweaver_threads("death")
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

# Bow quick-flex on fire. Compress the limbs across their curve instead of
# swelling the entire weapon uniformly (which made the bow appear to grow).
func bow_pop(scale_mult: float) -> void:
	if _bow == null:
		return
	var flex := clampf(1.0 - (scale_mult - 1.0) * 0.35, 0.84, 1.0)
	var t := create_tween()
	t.tween_property(_bow, "scale",
		Vector3(_bow_scale * flex, _bow_scale, _bow_scale), 0.04)
	t.tween_property(_bow, "scale", Vector3.ONE * _bow_scale, 0.13)

# Set the mesh back-lean amount used by `_physics_process` to drive the
# fire-recoil animation. Negative values lean back (the existing convention).
func apply_recoil(amount: float) -> void:
	_fire_recoil = amount
	_bow_draw_t = BOW_DRAW_TIME   # Phase 4 — arms snap into the draw, then settle

# Spec 32b — skill dispatcher. Slot 1 routes through the F-fire buffer
# (preserves the snappy "press 1 a tick early" feel); slots 2-4 fire
# immediately if off cooldown AND Focus ≥ cost. Failed checks are silent
# no-ops — the SkillBar's grey-out tells the player why.
func _try_skill(slot: int) -> void:
	if dead or _move != Move.NORMAL:
		return
	var game := get_tree().root.get_node_or_null("Game")
	if slot < 1 or slot > skills.size():
		return
	var skill = skills[slot - 1]
	# A stale UI/input event must never fire an entitlement that was removed
	# between rebuilding the bar and pressing its key (notably gear grants).
	if not _skill_is_currently_usable(game, String(skill.name)):
		return
	# Threadstep has a host-authoritative request/ack protocol; it must bypass
	# this generic debit/replication path completely.
	if String(skill.name) == "Threadstep":
		try_threadstep(aim_dir())
		return
	# Mark is a sender-bound encounter intent; it must never enter `_net_cast`
	# or the generic debit path.
	if String(skill.name) == "WayfindersMark":
		try_wayfinders_mark()
		return
	if _available_focus_after_reservations() < skill.cost:
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
	_arm_wayweaver_after_focus(String(skill.name), true)
	_net_forward_cast(slot)

func _skill_is_currently_usable(game: Node, skill_id: String) -> bool:
	if skill_id == "BasicShot":
		return true
	if game == null:
		return false
	# Ownership is the durable entitlement. Huntcraft level decides when Game
	# grants a Skill; it must not revoke a tutorial/migrated grant afterward.
	if game.has_method("skill_owned") and bool(game.skill_owned(skill_id)):
		return true
	if game.has_method("granted_skills") and (game.granted_skills() as Array).has(skill_id):
		return true
	if game.has_method("available_skills"):
		return (game.available_skills() as Array).has(skill_id)
	return false


# ---- D8 Slice 3: session-only Wayweaver thread --------------------------
# World owns the deterministic RoomPresence calculation.  It calls this small
# adapter whenever the player crosses authored room bounds; Player owns only
# its own transient reducer and never writes the presence into Game/save data.
func set_wayweaver_room_presence(presence: Dictionary) -> Dictionary:
	if _wayweaver_threads == null:
		_wayweaver_threads = WayweaverThreadRules.new()
	_wayweaver_presence = presence.duplicate(true)
	var state := _wayweaver_threads.observe_presence(_wayweaver_presence)
	_refresh_wayweaver_strand()
	return state


func wayweaver_thread_state() -> Dictionary:
	if _wayweaver_threads == null:
		return {"state": WayweaverThreadRules.FRESH, "identity": ""}
	return _wayweaver_threads.state_for(_wayweaver_presence)


func wayweaver_equipped() -> bool:
	return _wayweaver_equipped()


func _wayweaver_equipped() -> bool:
	return equipment != null and WeaponPresentations.is_wayweaver(equipment.get_slot("weapon"))


# The owner keeps a transient mirror so a real release burns its own room
# opportunity immediately.  The echo itself still comes only from the host's
# dedicated receipt below; generic cast replication never carries an effect.
func _wayweaver_local_runtime_enabled() -> bool:
	return not _is_remote


func _arm_wayweaver_after_focus(skill_id: String, succeeded: bool,
		host_accepted: bool = true) -> Dictionary:
	if not _wayweaver_local_runtime_enabled() or _wayweaver_threads == null:
		return {"ok": false, "reason": "network_echo_pending"}
	var result := _wayweaver_threads.arm_after_focus(_wayweaver_presence, skill_id,
		succeeded, _wayweaver_equipped(), host_accepted)
	_refresh_wayweaver_strand()
	return result


# Host-side mirror for a guest's already-accepted Focus cast.  This bypasses
# the local-owner gate because the host's copy is a net puppet by design.
func _arm_wayweaver_host_after_focus(skill_id: String) -> Dictionary:
	if _wayweaver_threads == null:
		return {"ok": false, "reason": "no_thread_reducer"}
	var result := _wayweaver_threads.arm_after_focus(_wayweaver_presence, skill_id,
		true, _wayweaver_host_weapon_ready(), true)
	_refresh_wayweaver_strand()
	return result


# Narrow scene-facing adapter for host-authoritative Focus Skills which do not
# travel through `_net_cast` (Threadstep and Wayfinder's Mark).
func arm_wayweaver_after_host_acceptance(skill_id: String) -> Dictionary:
	return _arm_wayweaver_host_after_focus(skill_id)


func arm_wayweaver_after_host_focus_cast(skill_id: String) -> Dictionary:
	if skill_id == "BasicShot" or not SKILL_FACTORY.has(skill_id):
		return {"ok": false, "reason": "invalid_focus_identity"}
	return _arm_wayweaver_host_after_focus(skill_id)


func _consume_wayweaver_basic_release() -> Dictionary:
	if not _wayweaver_local_runtime_enabled() or _wayweaver_threads == null:
		return {}
	var net := get_node_or_null("/root/NetGame")
	if net != null and bool(net.active):
		# The owner consumes its transient copy even if transport later rejects:
		# a real Basic release is the irreversible room opportunity.  The host
		# independently consumes its own reducer and is the sole effect source.
		var local_release := _wayweaver_threads.consume_basic_release(_wayweaver_presence,
			true, _wayweaver_equipped())
		if not bool(local_release.get("ok", false)):
			return {}
		_refresh_wayweaver_strand()
		_wayweaver_echo_nonce_seed = maxi(_wayweaver_echo_nonce_seed + 1,
			int(Time.get_ticks_usec() & 0x7fffffff))
		var nonce := _wayweaver_echo_nonce_seed
		_wayweaver_echo_pending = {"nonce": nonce, "aim": aim_dir()}
		var aim := aim_dir()
		if bool(net.is_host()):
			# The local host is the actual Basic boundary.  It has already spent its
			# one reducer before the Skill fires below; hand that *same* descriptor
			# to the host receipt rather than attempting to spend the reducer twice.
			_wayweaver_begin_local_host_basic(local_release, nonce, aim)
		# Guests wait until `_net_forward_cast(1)` has placed the genuine Basic
		# ahead of this request on the same reliable sender channel.
		return {}
	var released := _wayweaver_threads.consume_basic_release(_wayweaver_presence,
		true, _wayweaver_equipped())
	if not bool(released.get("ok", false)):
		return {}
	_refresh_wayweaver_strand()
	_prepare_wayweaver_basic_modifiers(released)
	return released


func _wayweaver_begin_local_host_basic(released: Dictionary, nonce: int, aim: Vector3) -> Dictionary:
	if not bool(released.get("ok", false)) or nonce <= 0:
		return {"accepted": false, "reason": "not_armed"}
	_wayweaver_host_local_release = released.duplicate(true)
	_wayweaver_host_basic_tokens.append(_wayweaver_host_basic_token(aim))
	var receipt := _wayweaver_echo_host_attempt(get_multiplayer_authority(), nonce, aim)
	# Rejection still burns the owner's actual release, but cannot leak its
	# descriptor into a later request.
	_wayweaver_host_local_release.clear()
	return receipt


# Called exactly once by ProjectileSkill while firing the genuine Basic Shot.
# Fan effects are separate echo arrows; root/mark and pierce modify only the
# primary bolt and are therefore naturally first-hit / post-damage effects.
func take_wayweaver_basic_modifiers() -> Dictionary:
	var out := _wayweaver_basic_modifiers.duplicate(true)
	_wayweaver_basic_modifiers.clear()
	return out


func _prepare_wayweaver_basic_modifiers(released: Dictionary) -> void:
	_wayweaver_basic_modifiers.clear()
	_play_wayweaver_rune_release_sfx()
	var effect: Dictionary = released.get("effect", {}) as Dictionary
	match String(effect.get("kind", "")):
		"pierce":
			_wayweaver_basic_modifiers = {"pierce_bonus": int(effect.get("additional_pierces", 0))}
		"root":
			_wayweaver_basic_modifiers = {"effects": [SkillEffectScript.root(
				float(effect.get("duration_seconds", 0.75)))]}
		"mark":
			_wayweaver_basic_modifiers = {"effects": [SkillEffectScript.marked(
				float(effect.get("duration_seconds", 2.0)))]}


func _play_wayweaver_rune_release_sfx() -> void:
	if not _wayweaver_equipped():
		return
	if _wayweaver_strand_style.is_empty():
		_refresh_wayweaver_strand()
	var rune_id := String(_wayweaver_strand_style.get("rune_id", ""))
	if rune_id == "":
		return
	_wayweaver_rune_sfx_applications += 1
	var sfx := get_node_or_null("/root/Sfx")
	if sfx != null and sfx.has_method("play_tuned"):
		sfx.play_tuned(String(_wayweaver_strand_style.get("sfx", "wayweaver_rune_green")),
			float(_wayweaver_strand_style.get("sfx_pitch", 1.0)))


func wayweaver_rune_sfx_applications() -> int:
	return _wayweaver_rune_sfx_applications


func _emit_wayweaver_release_effect(released: Dictionary, direction: Vector3) -> void:
	if released.is_empty():
		return
	var effect: Dictionary = released.get("effect", {}) as Dictionary
	match String(effect.get("kind", "")):
		"fan":
			_emit_wayweaver_fan(effect, direction)
		"ward":
			apply_ward_max_preserving(int(effect.get("amount", 8)),
				float(effect.get("duration_seconds", 4.0)))


func _emit_wayweaver_fan(effect: Dictionary, axis: Vector3) -> void:
	var host := get_parent()
	if host == null:
		return
	var origin := arrow_origin(axis)
	var damage := maxi(1, int(round(float(derived_stats.get("damage", 0))
		* float(effect.get("damage_multiplier", 0.25)))))
	for angle_v in effect.get("angles_degrees", []):
		var direction := axis.rotated(Vector3.UP, deg_to_rad(float(angle_v))).normalized()
		var arrow := ARROW_SCENE.instantiate()
		arrow.damage = damage
		arrow.crit_chance = 0.0
		arrow.crit_mult = 0.0
		arrow.can_crit = false
		arrow.pierce_left = 0
		arrow.execute_mult = 1.0
		arrow.execute_below = 0.0
		arrow.effects = []
		arrow.skill_type = "wayweaver_echo"
		arrow.focal = false
		arrow.owner_peer = get_multiplayer_authority() if is_inside_tree() \
			and multiplayer.has_multiplayer_peer() else 0
		host.add_child(arrow)
		arrow.global_position = origin
		arrow.look_at(origin + direction, Vector3.UP)


# ---- D8 Slice 3: dedicated host echo path ---------------------------------
# This is intentionally separate from `_net_cast`: the latter remains an old
# party-trust skill presentation path, while this request carries only a
# nonce+aim.  Identity/effect are made by the host reducer from its armed room.
func _wayweaver_echo_host_context(owner_id: int) -> Dictionary:
	var net := get_node_or_null("/root/NetGame")
	var connected := net == null or not bool(net.active) or (net.players as Dictionary).has(owner_id)
	var token := _wayweaver_host_basic_token_front()
	return {
		"session_active": connected,
		"body_peer": get_multiplayer_authority(),
		"dead": dead,
		"wayweaver_equipped": _wayweaver_host_weapon_ready(),
		"real_basic_release": not token.is_empty(),
		"basic_aim": token.get("aim", Vector3.ZERO),
		"basic_body_peer": int(token.get("peer_id", -1)),
		"basic_room_key": String(token.get("room_key", "")),
		"room_key": RoomPresenceScript.room_key(_wayweaver_presence),
		"consume": Callable(self, "_consume_wayweaver_host_descriptor"),
	}


func _consume_wayweaver_host_descriptor() -> Dictionary:
	if not _wayweaver_host_local_release.is_empty():
		var staged := _wayweaver_host_local_release.duplicate(true)
		_wayweaver_host_local_release.clear()
		_refresh_wayweaver_strand()
		return staged
	if _wayweaver_threads == null:
		return {}
	var released := _wayweaver_threads.consume_basic_release(_wayweaver_presence, true,
		_wayweaver_host_weapon_ready())
	_refresh_wayweaver_strand()
	return released


func _wayweaver_host_weapon_ready() -> bool:
	# A host's replica of another player's body is `_is_remote`; use the same
	# compact party-trust attestation in validation AND reducer consumption.
	# Reading the host's Game.equipment here would make a guest's valid echo fail
	# unless the host also happened to equip Wayweaver.
	return _net_wayweaver_equipped if _is_remote else _wayweaver_equipped()


@rpc("any_peer", "reliable")
func _wayweaver_echo_request(nonce: int, aim: Vector3) -> void:
	var net := get_node_or_null("/root/NetGame")
	if net == null or not bool(net.active) or not bool(net.is_host()):
		return
	_wayweaver_echo_host_attempt(multiplayer.get_remote_sender_id(), nonce, aim)


func _wayweaver_echo_host_attempt(sender_id: int, nonce: int, aim: Vector3) -> Dictionary:
	if _wayweaver_echo_authority == null:
		_wayweaver_echo_authority = WayweaverEchoAuthority.new()
	var owner_id := get_multiplayer_authority()
	var receipt := _wayweaver_echo_authority.request(owner_id, sender_id, nonce, aim,
		_wayweaver_echo_host_context(owner_id))
	# Only an accepted receipt spends the exact observed Basic token. A spoofed
	# aim/nonced request cannot steal a genuine release from its owner; a missing
	# follower request is retired by the deferred host Basic flush below.
	if bool(receipt.get("accepted", false)) and not bool(receipt.get("duplicate", false)):
		_wayweaver_pop_host_basic_token()
	if bool(receipt.get("accepted", false)) and not bool(receipt.get("duplicate", false)):
		_apply_wayweaver_echo_host(receipt, aim)
		_wayweaver_echo_replay.rpc(receipt.duplicate(true), aim)
	if owner_id == multiplayer.get_unique_id():
		_wayweaver_echo_receipt(receipt)
	else:
		_wayweaver_echo_receipt.rpc_id(owner_id, receipt)
	return receipt


func _apply_wayweaver_echo_host(receipt: Dictionary, aim: Vector3) -> void:
	var descriptor: Dictionary = receipt.get("descriptor", {}) as Dictionary
	var released := {"ok": true, "identity": String(descriptor.get("identity", "")),
		"effect": (descriptor.get("effect", {}) as Dictionary).duplicate(true),
		"room_key": String(descriptor.get("room_key", ""))}
	_prepare_wayweaver_basic_modifiers(released)
	_wayweaver_echo_gameplay_applications += 1
	_flush_wayweaver_host_basic()
	# Fan/ward have no dependency on an enemy hit and can replay as immediate
	# release cosmetics. Pierce/root/mark decorate the host's next real Basic.
	_emit_wayweaver_release_effect(released, aim)


func wayweaver_echo_gameplay_applications() -> int:
	return _wayweaver_echo_gameplay_applications


func _observe_wayweaver_host_basic(aim: Vector3, stats: Dictionary) -> void:
	# A pre-Focus Basic can never be paired with a later Focus.  We only mint a
	# short-lived correlation token when this body is armed *at this release*.
	var state := wayweaver_thread_state()
	var token: Dictionary = {}
	if String(state.get("state", "")) == WayweaverThreadRules.ARMED \
			and _wayweaver_host_weapon_ready() and not dead:
		token = _wayweaver_host_basic_token(aim)
		_wayweaver_host_basic_tokens.append(token)
	# Only guest replicas defer the actual host-side Basic. Local host fire is
	# already executing in the caller and has synchronously consumed its token.
	if not _is_remote:
		return
	if not _wayweaver_host_basic_pending.is_empty():
		_flush_wayweaver_host_basic()
	_wayweaver_host_basic_pending = {"aim": aim, "stats": stats.duplicate(true), "token": token}
	call_deferred("_flush_wayweaver_host_basic")


func _flush_wayweaver_host_basic() -> void:
	if _wayweaver_host_basic_pending.is_empty():
		return
	var pending := _wayweaver_host_basic_pending.duplicate(true)
	_wayweaver_host_basic_pending.clear()
	net_aim = pending.get("aim", Vector3.FORWARD)
	derived_stats = pending.get("stats", derived_stats)
	BasicShotScript.new().fire(self)
	net_aim = Vector3.ZERO
	# If the reliable echo follower did not arrive in the same turn, this was
	# still the armed room's real Basic Shot. Burn its descriptor and remove the
	# correlation token so it cannot arm an echo after a later Focus or room hop.
	var token: Dictionary = pending.get("token", {}) as Dictionary
	if not token.is_empty() and _wayweaver_host_basic_token_front() == token:
		_wayweaver_pop_host_basic_token()
		_consume_wayweaver_host_descriptor()


func _wayweaver_host_basic_token(aim: Vector3) -> Dictionary:
	return {
		"aim": aim.normalized(),
		"peer_id": get_multiplayer_authority(),
		"room_key": RoomPresenceScript.room_key(_wayweaver_presence),
	}


func _wayweaver_host_basic_token_front() -> Dictionary:
	return (_wayweaver_host_basic_tokens[0] as Dictionary).duplicate(true) \
		if not _wayweaver_host_basic_tokens.is_empty() else {}


func _wayweaver_pop_host_basic_token() -> void:
	if not _wayweaver_host_basic_tokens.is_empty():
		_wayweaver_host_basic_tokens.pop_front()


@rpc("any_peer", "call_remote", "reliable")
func _wayweaver_echo_replay(receipt: Dictionary, aim: Vector3) -> void:
	# A Player node belongs to its owning peer, so an authority RPC would reject
	# a valid host replay on a guest-owned body. Bind this broad transport class
	# explicitly to host peer 1, matching Threadstep's acknowledgement rule.
	var net := get_node_or_null("/root/NetGame")
	var sender := multiplayer.get_remote_sender_id()
	if net != null and bool(net.active) and sender != 0 and sender != 1:
		return
	if not bool(receipt.get("accepted", false)):
		return
	var nonce := int(receipt.get("nonce", 0))
	if nonce <= 0 or _wayweaver_echo_replayed_nonces.has(nonce):
		return
	_wayweaver_echo_replayed_nonces[nonce] = true
	_wayweaver_echo_replay_applications += 1
	# The host has already played its accepted descriptor inside `_prepare`.
	# A guest owner instead receives this one host-authored receipt; it is the
	# only safe audio boundary for its selected, attested Rune.
	if not _is_remote:
		_play_wayweaver_rune_release_sfx()
	# Remote machines replay the independently visible release effects. The
	# owner-local body receives Ward here (its damage authority remains local);
	# host gameplay has already been applied exactly once and primary modifiers
	# are never prepared on a puppet because `_net_cast` can arrive in either order.
	var descriptor: Dictionary = receipt.get("descriptor", {}) as Dictionary
	var effect: Dictionary = descriptor.get("effect", {}) as Dictionary
	match String(effect.get("kind", "")):
		"fan": _emit_wayweaver_fan(effect, aim)
		"ward": apply_ward_max_preserving(int(effect.get("amount", 8)),
			float(effect.get("duration_seconds", 4.0)))


@rpc("any_peer", "reliable")
func _wayweaver_echo_receipt(receipt: Dictionary) -> void:
	var net := get_node_or_null("/root/NetGame")
	var sender := multiplayer.get_remote_sender_id()
	if net != null and bool(net.active) and sender != 0 and sender != 1:
		return
	if _wayweaver_echo_pending.is_empty() \
			or int(receipt.get("nonce", -1)) != int(_wayweaver_echo_pending.get("nonce", -2)):
		return
	_wayweaver_echo_pending.clear()


func wayweaver_echo_replay_applications() -> int:
	return _wayweaver_echo_replay_applications


func _on_wayweaver_peer_rebound(old_peer_id: int, new_peer_id: int, _token: String) -> void:
	if _wayweaver_echo_authority != null:
		_wayweaver_echo_authority.rebind_peer(old_peer_id, new_peer_id)

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
	# The swing: a forward lean + arm-swing loop (forage kneels lower, slower).
	if _mesh != null:
		_gather_tween = create_tween().set_loops()
		var depth := 0.32 if kind != "forage_node" else 0.2
		var beat := 0.5 if kind != "forage_node" else 0.7
		if _gather_modifier != null:
			_gather_modifier.mode = "forage" if kind == "forage_node" else "mine"
		# Down-stroke — body leans, arm swings, tool bites; all parallel.
		_gather_tween.tween_property(_mesh, "rotation:x", depth, beat * 0.4) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		if _gather_modifier != null:
			_gather_tween.parallel().tween_property(_gather_modifier,
				"swing_amount", 1.0, beat * 0.4).set_trans(Tween.TRANS_QUAD)
		if _gather_tool != null:
			_gather_tween.parallel().tween_property(_gather_tool, "rotation:x",
				-1.1, beat * 0.4).set_trans(Tween.TRANS_QUAD)
		# Up-stroke — everything eases back to rest.
		_gather_tween.tween_property(_mesh, "rotation:x", 0.0, beat * 0.6) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if _gather_modifier != null:
			_gather_tween.parallel().tween_property(_gather_modifier,
				"swing_amount", 0.0, beat * 0.6).set_trans(Tween.TRANS_QUAD)
		if _gather_tool != null:
			_gather_tween.parallel().tween_property(_gather_tool, "rotation:x",
				0.0, beat * 0.6)

func end_gather() -> void:
	if _gather_tween != null:
		_gather_tween.kill()
		_gather_tween = null
	if _gather_modifier != null:
		_gather_modifier.swing_amount = 0.0   # arm returns to rest
	if _mesh != null:
		_mesh.rotation.x = 0.0
	if _gather_tool != null:
		_gather_tool.queue_free()
		_gather_tool = null
	if _bow != null:
		_bow.visible = true

func _attach_bow() -> void:
	# Spec 46-C — anchor at the bow hand via BoneAttachment3D (archers hold
	# the bow in the LEFT hand; the right draws). Falls back to the old
	# body-offset ride when no skeleton/hand exists.
	if _bow_socket == null and _skel != null:
		var hand_idx := -1
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
		if hand_idx >= 0:
			# Hybrid anchor: the BoneAttachment supplies the exact hand POINT
			# (post-animation, no jitter); the bow itself stays top_level so
			# its orientation/scale live in world space — no bone-basis or
			# rig-scale fights.
			_bow_socket = BoneAttachment3D.new()
			_bow_socket.name = "LeftHandWeaponSocket"
			_skel.add_child(_bow_socket)
			_bow_socket.bone_name = _skel.get_bone_name(hand_idx)
	_replace_weapon_presentation()


# The existing LeftHand socket stays alive across equipment changes.  Only its
# child is replaced, preventing duplicate bows / attachment leaks.  The data
# resolver is intentionally the only place that knows Wayweaver's GLB and
# transform; non-Wayweaver weapons preserve the familiar brown fallback.
func _replace_weapon_presentation() -> void:
	if _bow != null and is_instance_valid(_bow):
		_bow.queue_free()
	_bow = null
	var equipped = _weapon_presentation_item()
	_weapon_presentation = WeaponPresentations.for_item(equipped)
	var scene_path := String(_weapon_presentation.get("scene_path", ""))
	var packed: PackedScene = load(scene_path) if scene_path != "" and ResourceLoader.exists(scene_path) else null
	if packed == null:
		_weapon_presentation = WeaponPresentations.for_item(null)
		packed = BOW_SCENE
	_bow = packed.instantiate() as Node3D
	if _bow == null:
		return
	var tint = _weapon_presentation.get("tint", null)
	if tint is Color:
		_tint(_bow, tint as Color)
	_bow_scale = float(_weapon_presentation.get("scale", BOW_SCALE))
	if _bow_socket != null:
		_bow_socket.add_child(_bow)
		_bow.top_level = true
	else:
		add_child(_bow)
		push_warning("player: no hand bone — weapon rides the body offset")
	_bow.scale = Vector3.ONE * _bow_scale
	_refresh_wayweaver_strand()


func _weapon_presentation_item():
	# A remote Player has no right to read or mutate its owner's inventory. Its
	# compact 12 Hz state attestation provides the sole Wayweaver/rune visual
	# record, while every gameplay validation still uses the host's own seams.
	if _is_remote:
		if not _net_wayweaver_equipped:
			return null
		return {"kind_id": "wayweaver", "cosmetic_rune_id": _net_wayweaver_rune_id}
	return equipment.get_slot("weapon") if equipment != null else null


func _wayweaver_equipped_rune_id() -> String:
	if not _wayweaver_equipped() or equipment == null:
		return ""
	var equipped = equipment.get_slot("weapon")
	if not equipped is Dictionary:
		return ""
	var rune_id := String((equipped as Dictionary).get("cosmetic_rune_id", ""))
	return rune_id if WayweaverRuneCosmetics.is_valid_rune(rune_id) else ""


# The GLB has one explicit LivingStrand material (slot 3).  The rest of the
# bow keeps the Blender-authored palette; this is a narrowly scoped color seam
# rather than an equipment/stat shader. A tiny particle plume makes a chosen
# Rune legible in motion without adding a new rig or texture dependency.
func _refresh_wayweaver_strand() -> void:
	_wayweaver_strand_style.clear()
	if _bow == null or not is_instance_valid(_bow) or not _wayweaver_presentation_equipped():
		return
	var thread := wayweaver_thread_state()
	var rune_id := String(_weapon_presentation.get("cosmetic_rune_id", ""))
	_wayweaver_strand_style = WayweaverRuneCosmetics.strand_style(rune_id,
		String(thread.get("state", WayweaverThreadRules.FRESH)),
		String(thread.get("identity", "")))
	# Rule/runtime tests inspect the descriptor above. Avoid allocating ephemeral
	# imported-material overrides in Godot's dummy headless renderer; native/Web
	# builds continue through the actual material and particle presentation.
	if OS.has_feature("headless"):
		return
	var color: Color = _wayweaver_strand_style.get("strand_color", Color.WHITE) as Color
	var emission := float(_wayweaver_strand_style.get("strand_emission", 1.0))
	var requested_slot := int(_weapon_presentation.get("strand_material_slot", -1))
	for mesh_v in _all_mesh_instances(_bow):
		var mesh := mesh_v as MeshInstance3D
		if mesh == null or mesh.mesh == null or requested_slot < 0 \
				or requested_slot >= mesh.mesh.get_surface_count():
			continue
		var active := mesh.get_active_material(requested_slot)
		var strand := active.duplicate() as StandardMaterial3D if active != null else StandardMaterial3D.new()
		if strand == null:
			strand = StandardMaterial3D.new()
		strand.albedo_color = color
		strand.emission_enabled = true
		strand.emission = color
		strand.emission_energy_multiplier = emission
		mesh.set_surface_override_material(requested_slot, strand)
	_build_wayweaver_strand_particles(_wayweaver_strand_style)


func _wayweaver_presentation_equipped() -> bool:
	return _net_wayweaver_equipped if _is_remote else _wayweaver_equipped()


func _build_wayweaver_strand_particles(style: Dictionary) -> void:
	var old := _bow.get_node_or_null("WayweaverStrandParticles") if _bow != null else null
	if old != null:
		old.queue_free()
	# The headless test renderer cannot allocate the particle draw material.
	# The underlying strand descriptor/material is still exercised there; the
	# optional motes are a live renderer-only flourish.
	if OS.has_feature("headless"):
		return
	if _bow == null or String(style.get("rune_id", "")) == "":
		return
	var particles := GPUParticles3D.new()
	particles.name = "WayweaverStrandParticles"
	particles.amount = 12
	particles.lifetime = 1.15
	particles.visibility_aabb = AABB(Vector3(-0.4, -0.4, -0.8), Vector3(0.8, 0.8, 1.6))
	particles.position = Vector3(-0.14, 0.0, 0.18)
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 1.0, 0.0)
	process.spread = 55.0
	process.gravity = Vector3(0.0, 0.10, 0.0)
	process.initial_velocity_min = 0.03
	process.initial_velocity_max = 0.13
	process.scale_min = 0.012
	process.scale_max = 0.028
	process.color = style.get("particle_color", Color.WHITE) as Color
	particles.process_material = process
	var sparkle := QuadMesh.new()
	sparkle.size = Vector2(0.055, 0.055)
	var sparkle_mat := StandardMaterial3D.new()
	sparkle_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sparkle_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sparkle_mat.albedo_color = style.get("particle_color", Color.WHITE) as Color
	sparkle.material = sparkle_mat
	particles.draw_pass_1 = sparkle
	_bow.add_child(particles)


func wayweaver_strand_presentation() -> Dictionary:
	return _wayweaver_strand_style.duplicate(true)

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
	var wayweaver_still_equipped := _wayweaver_equipped()
	if not wayweaver_still_equipped and _wayweaver_threads != null:
		_wayweaver_threads.on_weapon_lost()
		_wayweaver_basic_modifiers.clear()
	_replace_weapon_presentation()
	_derive_stats()
	# A skill-grant charm changes the live action set. Rebuild immediately so
	# the hotbar cannot keep a Galecall/Wyrdvolley key after its gear came off.
	rebuild_skills()
	gear_changed.emit()
	var sfx := get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.play("equip")


func _on_wayweaver_cosmetic_changed(_rune_id: String) -> void:
	# The signal is Game's post-commit notice. Only the live equipped unique
	# needs a redraw; a packed bow is persisted/projected but stays unseen.
	if _wayweaver_equipped():
		_replace_weapon_presentation()

# Skills-on-items: on-hit charms appended to every shot (read by
# ProjectileSkill._spawn_arrow). Cached in _derive_stats so the per-shot path
# stays allocation-light.
func get_enchant_hit_effects() -> Array:
	return _enchant_hit_effects

# Build a SkillEffect from an enchant's `effect` data dict (data/enchants.gd).
func _build_hit_effect(fx: Dictionary) -> SkillEffect:
	match String(fx.get("status", "")):
		"burn":
			return SkillEffect.burn(float(fx.get("dur", 2.0)),
				int(fx.get("dpt", 1)), float(fx.get("interval", 0.5)))
		"bleed":
			return SkillEffect.bleed(float(fx.get("dur", 2.5)),
				int(fx.get("dpt", 1)), float(fx.get("interval", 0.7)))
		"snared":
			return SkillEffect.snared(float(fx.get("dur", 1.0)),
				float(fx.get("slow", 0.7)))
		"marked":
			return SkillEffect.marked(float(fx.get("dur", 3.0)))
	return null

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
		"cooldown_reduction": 0.0, "hp_regen": 0.0, "bonus_pierce": 0}
	# ADR 0013 — gear gives power again (reverses the 0010 freeze): every
	# equipped item's base_stat + rolled affixes flow into the sums.
	var hit_fx: Array = []
	if equipment != null:
		for slot in Equipment.SLOT_ORDER:
			var it = equipment.get_slot(slot)
			if it == null:
				continue
			_add_stat(sums, String(it.get("base_stat", "")), it.get("base_value", 0))
			for a in it.get("affixes", []):
				_add_stat(sums, String(a.get("stat", "")), a.get("value", 0))
			# Skills-on-items: stat charms sum like an affix; on-hit charms are
			# collected here and ride every shot (ProjectileSkill._spawn_arrow
			# reads get_enchant_hit_effects). skill_grant charms are handled by
			# Game.granted_skills / the loadout, not here.
			for eid in it.get("enchants", []):
				var edef: Dictionary = EnchantDefs.get_def(String(eid))
				if edef.is_empty():
					continue
				match String(edef.get("kind", "")):
					"stat":
						_add_stat(sums, String(edef.get("stat", "")), edef.get("value", 0))
					"on_hit":
						var fx = _build_hit_effect(edef.get("effect", {}))
						if fx != null:
							hit_fx.append(fx)
	_enchant_hit_effects = hit_fx
	for k in shrine_buffs:
		_add_stat(sums, String(k), shrine_buffs[k])
	# B7 — Huntcraft perks ride the same sums.
	var game_h := get_tree().root.get_node_or_null("Game")
	if game_h != null:
		if game_h.perk_active("huntcraft", "steady_hands"):
			_add_stat(sums, "crit_chance", 0.05)
		if game_h.perk_active("huntcraft", "hunters_stride"):
			_add_stat(sums, "move_speed", 0.05)
		# Spec 45-hunt — the deep perks ride the same shape.
		if game_h.perk_active("huntcraft", "quick_nock"):
			_add_stat(sums, "cooldown_reduction", 0.10)
		if game_h.perk_active("huntcraft", "heavy_draw"):
			_add_stat(sums, "crit_mult", 0.25)
		# Spec 45-wilds — Crowsfoot Cordial's stride rides the buff engine.
		_add_stat(sums, "move_speed", float(game_h.buff_value("move_speed")))
		# ADR 0013 — the Ledger (boss trophies, power source #3) sums flat on top.
		var led = game_h.get("ledger")
		if led != null:
			var lsums: Dictionary = led.sum_stats()
			for lk in lsums:
				_add_stat(sums, String(lk), lsums[lk])
	# ADR 0016 — Huntcraft grows base combat power (symmetric with the
	# den scaling, so difficulty tracks level-delta). Gear adds flat on top.
	var pf := 1.0
	if game_h != null:
		pf = pow(float(game_h.LEVEL_POWER), float(game_h.trade_lv("huntcraft") - 1))
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
		"hp_regen":            float(sums.hp_regen),
		# C9 — extra targets pierced (of_penetration affix / iron_tip perk).
		"bonus_pierce":        int(round(float(sums.get("bonus_pierce", 0)))),
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

# Chart speed twins stack multiplicatively so a Root Below thread never
# disables the existing Sprinter/Mired Boots contract.
func _chart_speed_mult() -> float:
	var game := get_tree().root.get_node_or_null("Game")
	if game == null or not bool(game.in_dungeon):
		return 1.0
	var mult := 1.0
	if game.affix_bad("sprinter"):
		mult *= 0.9
	if game.affix_good("open_thread"):
		mult *= 1.08
	elif game.affix_bad("open_thread"):
		mult *= 0.92
	return mult

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
	var expected := _expected_interact
	var expected_was_armed := _expected_interact_armed
	_expected_interact = null
	_expected_interact_armed = false
	# An armed expectation is fail-closed. In particular, its target may have
	# been freed by a scene/Area update between arming and this physics edge; that
	# must never silently fall through to whichever prompt became active.
	if expected_was_armed and (expected == null or not is_instance_valid(expected)):
		_last_interact_receipt = {"status": "refused_expected_invalid", "expected": expected}
		return
	if _active_interactable == null or not is_instance_valid(_active_interactable):
		_last_interact_receipt = {"status": "refused_no_active", "expected": expected,
			"armed": expected_was_armed}
		return
	if expected_was_armed and _active_interactable != expected:
		_last_interact_receipt = {"status": "refused_target_mismatch",
			"expected": expected, "actual": _active_interactable}
		return
	if not _active_interactable.has_method("interact"):
		_last_interact_receipt = {"status": "refused_not_interactable",
			"expected": expected, "actual": _active_interactable}
		return
	_last_interacted = _active_interactable
	_last_interact_receipt = {"status": "actual", "expected": expected,
		"actual": _active_interactable}
	_active_interactable.interact(self)
	# Hide the prompt right away; _refresh_interact_prompt will pick the next.
	if _active_interactable.has_method("show_prompt"):
		_active_interactable.show_prompt(false)
	_active_interactable = null


func clear_last_interacted() -> void:
	_last_interacted = null


func last_interacted() -> Node:
	return _last_interacted if _last_interacted != null and is_instance_valid(_last_interacted) else null


func arm_expected_interact(target: Node) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	_expected_interact = target
	_expected_interact_armed = true
	_last_interact_receipt = {"status": "armed", "expected": target}
	return true


func clear_expected_interact() -> void:
	_expected_interact = null
	_expected_interact_armed = false


func last_interact_receipt() -> Dictionary:
	return _last_interact_receipt.duplicate()

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
var _net_wayweaver_equipped := false # party-trust equipment attestation for host echo validation
var _net_wayweaver_rune_id := "" # bounded visual attestation; never a stats source
const NET_SEND_HZ := 12.0

func _net_send_tick(delta: float) -> void:
	var net := get_node_or_null("/root/NetGame")
	if net == null or not bool(net.active):
		return
	# Don't RPC until the ENet handshake completes — a guest's local player
	# ticks the instant it boots, ~1s before the peer actually connects, which
	# otherwise spams "RPC via a peer which is not connected". (The host's server
	# peer reports CONNECTED, so it's unaffected.)
	var mp := multiplayer
	if mp == null or mp.multiplayer_peer == null \
			or mp.multiplayer_peer.get_connection_status() \
				!= MultiplayerPeer.CONNECTION_CONNECTED:
		return
	_net_accum += delta
	if _net_accum < 1.0 / NET_SEND_HZ:
		return
	_net_accum = 0.0
	var yaw: float = _mesh.rotation.y if _mesh != null else 0.0
	_net_state.rpc(global_position, yaw,
		Vector2(velocity.x, velocity.z).length() > 0.5, dead, hp, hp_max,
		_wayweaver_equipped(), _wayweaver_equipped_rune_id())

@rpc("authority", "unreliable_ordered")
func _net_state(pos: Vector3, yaw: float, moving: bool,
		p_dead: bool = false, p_hp: int = -1, p_hp_max: int = -1,
		p_wayweaver_equipped: bool = false, p_wayweaver_rune_id: String = "") -> void:
	_net_has_target = true
	_net_target_pos = pos
	_net_target_yaw = yaw
	_net_moving = moving
	var prior_dead := dead
	var prior_equipped := _net_wayweaver_equipped
	var prior_rune := _net_wayweaver_rune_id
	_net_wayweaver_equipped = p_wayweaver_equipped
	_net_wayweaver_rune_id = p_wayweaver_rune_id if WayweaverRuneCosmetics.is_valid_rune(p_wayweaver_rune_id) else ""
	if _is_remote and (prior_equipped != _net_wayweaver_equipped or prior_rune != _net_wayweaver_rune_id):
		_replace_weapon_presentation()
	# Phase 4 — mirror hp onto the remote body so the party HP frame can read
	# every peer's health (the local body keeps its own real hp).
	if p_hp >= 0:
		hp = p_hp
		if p_hp_max > 0:
			hp_max = p_hp_max
	# Phase B — enemies skip dead puppets; the died edge feeds party-wipe
	# checks on every machine.
	if p_dead and not dead:
		dead = true
		died.emit()
	elif not p_dead:
		dead = false
	# A puppet's thread is host-side combat authority.  Do not let an old
	# attestation survive either a death edge or Wayweaver being removed.
	if _is_remote and ((p_dead and not prior_dead) \
			or (prior_equipped and not _net_wayweaver_equipped)):
		_invalidate_wayweaver_threads("remote_death" if p_dead else "remote_weapon_loss")

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
func _net_cast(slot: int, aim: Vector3, stats: Dictionary, cast_skill_id: String = "") -> void:
	# Phase C — every machine replays the cast through the caster's body
	# here: REAL on the host (its enemies are truth), cosmetic on guests
	# (puppet foes take no damage). The caster never receives (no
	# call_local) — their local fire already played.
	if not _is_remote:
		return
	# On the host this body belongs to exactly one peer.  The old generic path
	# is retained for ordinary Skills, but it may not be used to arm another
	# body's Wayweaver reducer through a spoofed node path.
	var net := get_node_or_null("/root/NetGame")
	var host_replay := net != null and bool(net.active) and bool(net.is_host())
	if host_replay:
		var sender := multiplayer.get_remote_sender_id()
		if sender != get_multiplayer_authority():
			return
	var declared := cast_skill_id
	if declared == "":
		if slot < 1 or slot > skills.size():
			return
		declared = String(skills[slot - 1].name)
	if declared != "BasicShot" and not SKILL_FACTORY.has(declared):
		return
	var game := get_tree().root.get_node_or_null("Game")
	# A remote host body must not read the host's loadout to decide a guest's
	# party-trust action. The explicit factory identity is still finite and the
	# sender/body binding above remains mandatory on the host.
	if not _is_remote and not _skill_is_currently_usable(game, declared):
		return
	net_aim = aim
	derived_stats = stats
	if host_replay and declared == "BasicShot":
		_observe_wayweaver_host_basic(aim, stats)
		net_aim = Vector3.ZERO
		return
	var sk = BasicShotScript.new() if declared == "BasicShot" else (SKILL_FACTORY.get(declared) as GDScript).new()
	sk.fire(self)
	if host_replay and declared != "BasicShot":
		arm_wayweaver_after_host_focus_cast(declared)
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
	var skill_id := String(skills[slot - 1].name) if slot >= 1 and slot <= skills.size() else ""
	var aim := aim_dir()
	_net_cast.rpc(slot, aim, derived_stats, skill_id)
	# The host sees the genuine Basic first and creates one sender-bound token;
	# same-channel reliable ordering then lets the echo consume that one release.
	if slot == 1 and not _wayweaver_echo_pending.is_empty():
		var nonce := int(_wayweaver_echo_pending.get("nonce", 0))
		if nonce > 0:
			_wayweaver_echo_request.rpc_id(1, nonce, aim)

# ---- Fire in the Bough: Threadstep authority --------------------------------
#
# Unlike ordinary Skills this is a two-phase movement request.  The client
# reserves Focus first, sends only `(nonce, normalized direction)`, and does
# not move, spend, or start its cooldown until this exact nonce returns from
# the host.  Do not route this through `_net_cast`.

func _threadstep_available_focus() -> float:
	return _available_focus_after_reservations()


# Reservations are owner-local and additive.  Every generic Skill uses this
# same balance, so it can never spend Focus the encounter is waiting to settle.
func _available_focus_after_reservations() -> float:
	return maxf(0.0, focus - float(_threadstep_pending.get("reserved", 0.0)) \
		- float(_wayfinders_mark_pending.get("reserved", 0.0)))


# Narrow D8 coordinator interface ------------------------------------------------
#
# The encounter gets only an owner-local capability attestation from this
# adapter. It never receives Focus, player position, target data, Chart facts,
# or a caller-supplied peer identity; its own scene/transport adapter supplies
# those to KnotEaterRules.
func prepare_wayfinders_mark_request() -> Dictionary:
	var result := {"ok": false, "nonce": 0, "cost": WAYFINDERS_MARK_COST,
		"party_trust_entitlement": false, "reason": "not_ready"}
	if dead or _move != Move.NORMAL:
		result.reason = "movement_or_death"
		return result
	if not _wayfinders_mark_pending.is_empty():
		result.reason = "pending"
		return result
	var game := get_tree().root.get_node_or_null("Game")
	if game == null or not game.has_method("trade_lv") or int(game.trade_lv("huntcraft")) < 22:
		result.reason = "huntcraft_22_required"
		return result
	# Mark is durable, never a transient gear grant.  Requiring ownership and an
	# equipped runtime instance prevents an old/stale UI button from borrowing
	# an entitlement it no longer has.
	if not game.has_method("skill_owned") or not bool(game.skill_owned("WayfindersMark")) \
			or not _skill_is_currently_usable(game, "WayfindersMark") \
			or not _wayfinders_mark_equipped():
		result.reason = "not_equipped"
		return result
	if _wayfinders_mark_cooldown_left() > 0.01:
		result.reason = "cooldown"
		return result
	if _available_focus_after_reservations() < WAYFINDERS_MARK_COST:
		result.reason = "insufficient_focus"
		return result
	var encounter_state := _wayfinders_mark_encounter_availability()
	if not bool(encounter_state.get("available", false)):
		result.reason = String(encounter_state.get("reason", "not_reeling"))
		return result
	_wayfinders_mark_nonce_seed = maxi(_wayfinders_mark_nonce_seed + 1,
		int(Time.get_ticks_usec()))
	_wayfinders_mark_nonce = _wayfinders_mark_nonce_seed
	_wayfinders_mark_pending = {
		"nonce": _wayfinders_mark_nonce,
		"reserved": WAYFINDERS_MARK_COST,
		"cost": WAYFINDERS_MARK_COST,
		"party_trust_entitlement": true,
	}
	_wayfinders_mark_last_cancel_reason = ""
	return {"ok": true, "nonce": _wayfinders_mark_nonce,
		"cost": WAYFINDERS_MARK_COST, "party_trust_entitlement": true}


func wayfinders_mark_pending() -> Dictionary:
	return _wayfinders_mark_pending.duplicate(true)


func wayfinders_mark_availability() -> Dictionary:
	var state := {"available": false, "pending": not _wayfinders_mark_pending.is_empty(),
		"cost": WAYFINDERS_MARK_COST, "cooldown_sec": WAYFINDERS_MARK_COOLDOWN,
		"range_m": WAYFINDERS_MARK_RANGE, "reeling_sec": WAYFINDERS_MARK_REELING_SEC,
		"reason": "not_ready"}
	if bool(state.pending):
		state.reason = "pending"
		return state
	if dead or _move != Move.NORMAL:
		state.reason = "movement_or_death"
		return state
	var game := get_tree().root.get_node_or_null("Game")
	if game == null or not game.has_method("trade_lv") or int(game.trade_lv("huntcraft")) < 22:
		state.reason = "huntcraft_22_required"
		return state
	if not game.has_method("skill_owned") or not bool(game.skill_owned("WayfindersMark")) \
			or not _skill_is_currently_usable(game, "WayfindersMark") \
			or not _wayfinders_mark_equipped():
		state.reason = "not_equipped"
		return state
	if _wayfinders_mark_cooldown_left() > 0.01:
		state.reason = "cooldown"
		return state
	if _available_focus_after_reservations() < WAYFINDERS_MARK_COST:
		state.reason = "insufficient_focus"
		return state
	var encounter_state := _wayfinders_mark_encounter_availability()
	state.available = bool(encounter_state.get("available", false))
	state.reason = String(encounter_state.get("reason", "not_reeling"))
	return state


func _wayfinders_mark_encounter_availability() -> Dictionary:
	var tree := get_tree()
	var encounter := tree.get_first_node_in_group("knot_eater_encounter") \
		if tree != null else null
	if encounter == null or not encounter.has_method("view"):
		return {"available": false, "reason": "encounter_unavailable"}
	var raw = encounter.call("view")
	if not raw is Dictionary:
		return {"available": false, "reason": "encounter_unavailable"}
	var model := raw as Dictionary
	var telegraph := model.get("telegraph", {}) as Dictionary
	if String(model.get("phase", "")) != "reeling" \
			or String(model.get("active_knot_id", "")).is_empty() \
			or String(telegraph.get("kind", "")) != "reeling" \
			or int(telegraph.get("remaining_ms", 0)) <= 0:
		return {"available": false, "reason": "not_reeling"}
	if int(model.get("mark_cooldown_left_ms", 0)) > 0:
		return {"available": false, "reason": "encounter_cooldown"}
	if not bool(model.get("mark_ready", false)):
		return {"available": false, "reason": "mark_unavailable"}
	return {"available": true, "reason": "ready"}


func _wayfinders_mark_equipped() -> bool:
	for skill in skills:
		if skill != null and String(skill.name) == "WayfindersMark":
			return true
	return false


func _wayfinders_mark_cooldown_left() -> float:
	for i in range(1, skills.size() + 1):
		if String(skills[i - 1].name) == "WayfindersMark":
			return float(_skill_cooldowns.get(i, 0.0))
	return 0.0


# The coordinator returns a stable, sender-bound receipt. Only the exact live
# nonce can mutate owner Focus/cooldown; duplicates, stale snapshots, and a
# receipt for another player remain inert.
func apply_wayfinders_mark_receipt(receipt: Dictionary) -> bool:
	if _wayfinders_mark_pending.is_empty() or receipt.is_empty():
		return false
	# `nonce` orders all encounter intents; `reservation_nonce` belongs to this
	# owner's Focus hold. Legacy/focused receipts without the newer field keep
	# the fallback so the narrow Player contract remains backwards compatible.
	var nonce := int(receipt.get("reservation_nonce", receipt.get("nonce", -1)))
	if nonce <= 0 or nonce != int(_wayfinders_mark_pending.get("nonce", -2)):
		return false
	var accepted := bool(receipt.get("accepted", receipt.get("ok", false)))
	if not accepted:
		_wayfinders_mark_pending.clear()
		_wayfinders_mark_last_cancel_reason = String(receipt.get("reason", "rejected"))
		return true
	# The reservation protects this normal path from generic casts. Fail closed
	# if some unrelated mutation violated that invariant instead of spending a
	# partial amount or starting a misleading cooldown.
	if focus < WAYFINDERS_MARK_COST:
		_wayfinders_mark_last_cancel_reason = "focus_invariant"
		return false # retain the reservation so the same stable receipt can reconcile.
	_wayfinders_mark_pending.clear()
	focus -= WAYFINDERS_MARK_COST
	_combat_t = COMBAT_TIMER
	for i in range(1, skills.size() + 1):
		if String(skills[i - 1].name) == "WayfindersMark":
			_skill_cooldowns[i] = WAYFINDERS_MARK_COOLDOWN
			break
	# A Mark arms only after this exact accepted receipt has consumed the
	# reservation. Rejected, stale, and duplicate receipts returned above never
	# reach the local thread reducer.
	_arm_wayweaver_after_focus("WayfindersMark", true, true)
	return true


func cancel_wayfinders_mark(reason: String) -> void:
	if _wayfinders_mark_pending.is_empty():
		return
	_wayfinders_mark_pending.clear()
	_wayfinders_mark_last_cancel_reason = reason


func try_wayfinders_mark() -> bool:
	var request := prepare_wayfinders_mark_request()
	if not bool(request.get("ok", false)):
		return false
	var tree := get_tree()
	var encounter := tree.get_first_node_in_group("knot_eater_encounter") if tree != null else null
	if encounter == null or not encounter.has_method("press"):
		cancel_wayfinders_mark("encounter_unavailable")
		return false
	# `WayfindersMark.fire` owns the scene-group lookup and cancels this
	# reservation if the current World cannot receive the intent.
	for skill in skills:
		if skill != null and String(skill.name) == "WayfindersMark":
			skill.fire(self)
			return true
	cancel_wayfinders_mark("not_equipped")
	return false


func threadstep_pending() -> bool:
	return not _threadstep_pending.is_empty()


func threadstep_cinder_grace_active() -> bool:
	return _threadstep_grace_t > 0.0


# Cinder systems call this rather than `take_damage` directly.  Threadstep's
# brief grace is intentionally scoped to cinder harm, never to ordinary hits.
func apply_cinder_damage(amount: int, from_dir: Vector3) -> bool:
	if threadstep_cinder_grace_active():
		return false
	take_damage(amount, from_dir)
	return true


func try_threadstep(requested_direction: Vector3) -> bool:
	if dead or _move != Move.NORMAL or not _threadstep_pending.is_empty():
		return false
	var game := get_tree().root.get_node_or_null("Game")
	if not _skill_is_currently_usable(game, "Threadstep"):
		return false
	if _threadstep_available_focus() < THREADSTEP_COST:
		return false
	var direction := Vector3(requested_direction.x, 0.0, requested_direction.z)
	if not direction.is_finite() or direction.length() < 0.01:
		return false
	direction = direction.normalized()
	var net := get_node_or_null("/root/NetGame")
	if net != null and bool(net.active):
		var peer := multiplayer
		if peer == null or peer.multiplayer_peer == null \
				or peer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
			return false
	_threadstep_nonce += 1
	if _threadstep_nonce <= 0:
		_threadstep_nonce = 1
	var nonce := _threadstep_nonce
	_threadstep_pending = {"nonce": nonce, "reserved": THREADSTEP_COST}
	if net == null or not bool(net.active):
		_threadstep_host_attempt(get_multiplayer_authority(), nonce, direction)
	elif bool(net.is_host()):
		_threadstep_host_attempt(get_multiplayer_authority(), nonce, direction)
	else:
		_threadstep_request.rpc_id(1, nonce, direction)
	return true


func _threadstep_host_context(peer_id: int) -> Dictionary:
	var game := get_tree().root.get_node_or_null("Game")
	var net := get_node_or_null("/root/NetGame")
	var connected := net == null or not bool(net.active) or (net.players as Dictionary).has(peer_id)
	var local_peer := multiplayer.get_unique_id() if multiplayer.multiplayer_peer != null else 1
	return {
		"session_active": connected,
		# Remote owners are covered by the existing trust-the-party entitlement
		# model. Reusing the host's personal loadout would incorrectly reject a
		# guest merely because the host chose another Skill.
		"entitled": _skill_is_currently_usable(game, "Threadstep") \
			if peer_id == local_peer else true,
		"body_peer": get_multiplayer_authority(),
		"probe": Callable(self, "_threadstep_probe"),
	}


@rpc("any_peer", "reliable")
func _threadstep_request(nonce: int, direction: Vector3) -> void:
	var net := get_node_or_null("/root/NetGame")
	if net == null or not bool(net.active) or not bool(net.is_host()):
		return
	_threadstep_host_attempt(multiplayer.get_remote_sender_id(), nonce, direction)


func _threadstep_host_attempt(sender_id: int, nonce: int, direction: Vector3) -> void:
	var net := get_node_or_null("/root/NetGame")
	# In a networked game this node's authority is the sole peer allowed to
	# request a step through it.  This prevents a guest from borrowing another
	# puppet's origin merely by targeting its replicated node path.
	var owner_id := get_multiplayer_authority()
	var result: Dictionary = _threadstep_authority.request(owner_id, sender_id,
		nonce, direction, global_position, _threadstep_host_context(owner_id))
	if bool(result.get("accepted", false)) and not bool(result.get("duplicate", false)):
		_threadstep_apply_host_endpoint(result.get("endpoint", global_position))
		# The host reducer is distinct from the owner's transient mirror.  It
		# arms only after the authoritative movement endpoint was accepted.
		arm_wayweaver_after_host_acceptance("Threadstep")
	# Every valid nonce receives exactly one stable answer; replay calls receive
	# the same answer and the owner-side matcher makes repeats a no-op.
	if net != null and bool(net.active) and owner_id != multiplayer.get_unique_id():
		_threadstep_ack.rpc_id(owner_id, nonce, bool(result.get("accepted", false)),
			result.get("endpoint", global_position), String(result.get("reason", "rejected")))
	else:
		_threadstep_ack(nonce, bool(result.get("accepted", false)),
			result.get("endpoint", global_position), String(result.get("reason", "rejected")))


func _threadstep_apply_host_endpoint(raw_endpoint: Vector3) -> void:
	var endpoint := raw_endpoint as Vector3
	global_position = endpoint
	# Remote host bodies otherwise lerp back to their pre-step network target on
	# the next frame. Updating both values keeps host collision truth and guest
	# presentation on the same endpoint until the normal state tick arrives.
	_net_target_pos = endpoint
	velocity = Vector3.ZERO


@rpc("any_peer", "reliable")
func _threadstep_ack(nonce: int, accepted: bool, endpoint: Vector3, _reason: String) -> void:
	# Remote player bodies are owned by their player, not by the host.  The host
	# therefore cannot use an `authority` RPC here: Godot would treat a valid
	# host acknowledgement as if it came from the guest body owner.  Accept the
	# transport class broadly, then bind the actual sender to peer 1 ourselves.
	# A zero sender is Godot's local direct host call; it is not a remote peer.
	# Offline/direct calls deliberately retain the same nonce matcher below.
	var net := get_node_or_null("/root/NetGame")
	var sender_id := multiplayer.get_remote_sender_id()
	if net != null and bool(net.active) and sender_id != 0 and sender_id != 1:
		return
	if _threadstep_pending.is_empty() or int(_threadstep_pending.get("nonce", -1)) != nonce:
		return # duplicate, late, or spoofed acknowledgement: no state change.
	_threadstep_pending.clear()
	if not accepted:
		return
	# Reservation made this debit safe: generic Skills cannot consume the held
	# twenty Focus while the request is live.
	if focus < THREADSTEP_COST:
		return # fail closed if an external mutation violated the reservation.
	focus -= THREADSTEP_COST
	_threadstep_grace_t = ThreadstepAuthority.GRACE_SECONDS
	_combat_t = COMBAT_TIMER
	global_position = endpoint
	_net_target_pos = endpoint
	velocity = Vector3.ZERO
	for i in range(1, skills.size() + 1):
		if String(skills[i - 1].name) == "Threadstep":
			_skill_cooldowns[i] = THREADSTEP_COOLDOWN
			break
	# Threadstep has no generic `fire` path: its accepted host endpoint is the
	# only successful cast boundary that can arm an identity thread.
	_arm_wayweaver_after_focus("Threadstep", true, true)


func _threadstep_probe(origin: Vector3, direction: Vector3, distance: float) -> Dictionary:
	if distance < 0.0 or distance > THREADSTEP_MAX_DISTANCE + 0.001:
		return {"ok": false}
	var endpoint := origin + direction * distance
	endpoint.y = origin.y
	var world := get_world_3d()
	if world == null:
		return {"ok": false}
	var nav_map: RID = world.navigation_map
	# NavigationServer queues region registration until its physics-frame sync.
	# Querying closest points or paths before that sync can itself emit a server
	# diagnostic and returns an incomplete map.  Threadstep is authoritative
	# movement, so it must reject rather than infer that empty state is safe.
	if not nav_map.is_valid() or NavigationServer3D.map_get_iteration_id(nav_map) <= 0:
		return {"ok": false}
	# CharacterBody3D.test_move sweeps the body's actual capsule, so this is not
	# a ray that can slip a body through a thin wall, closed door, or arena gate.
	if test_move(global_transform, endpoint - global_position):
		return {"ok": false}
	var nav_origin := NavigationServer3D.map_get_closest_point(nav_map, origin)
	var nav_endpoint := NavigationServer3D.map_get_closest_point(nav_map, endpoint)
	if nav_origin.distance_to(origin) > 0.35 or nav_endpoint.distance_to(endpoint) > 0.35:
		return {"ok": false}
	# Endpoint-only navigation checks permit a short blink across a void when
	# each bank happens to have a close nav point. Sample the entire fixed
	# segment and reject a detour: Threadstep is a five-metre capsule move,
	# never a pathfinder teleport around a gate or over a navigation gap.
	var samples := maxi(2, ceili(distance / 0.20))
	for i in range(1, samples):
		var sample := origin.lerp(endpoint, float(i) / float(samples))
		var nav_sample := NavigationServer3D.map_get_closest_point(nav_map, sample)
		if nav_sample.distance_to(sample) > 0.18:
			return {"ok": false}
	var path := NavigationServer3D.map_get_path(nav_map, nav_origin, nav_endpoint, true)
	if path.size() < 2:
		return {"ok": false}
	var path_length := 0.0
	for i in range(1, path.size()):
		path_length += path[i - 1].distance_to(path[i])
	if path_length > distance + 0.35:
		return {"ok": false}
	return {"ok": true, "endpoint": endpoint}


func _on_threadstep_session_ended(_reason: String) -> void:
	# A live reservation never silently times out. Connection loss is the one
	# cancellation edge that releases it without an acknowledgement.
	_threadstep_pending.clear()
	_invalidate_wayweaver_threads("session_ended")


func _on_threadstep_reconnecting(_attempt: int, _max_attempts: int) -> void:
	# A reconnect attempt follows a broken transport, not an active host session.
	# Release the owner-local reservation immediately so a lost accept/reject
	# cannot lock twenty Focus until the reconnect grace finally expires.
	_threadstep_pending.clear()
	_invalidate_wayweaver_threads("reconnect")


func _on_wayfinders_mark_session_ended(reason: String) -> void:
	# A definitive session end has no encounter snapshot left to reconcile.
	cancel_wayfinders_mark(reason if reason != "" else "session_ended")
	_invalidate_wayweaver_threads("session_ended")


func _on_wayfinders_mark_reconnecting(_attempt: int, _max_attempts: int) -> void:
	# Unlike Threadstep, a live Mark reservation survives transient reconnect.
	# KnotEaterEncounter's peer snapshot carries the unresolved receipt back to
	# this owner, which then calls apply_wayfinders_mark_receipt exactly once.
	_invalidate_wayweaver_threads("reconnect")


func _invalidate_wayweaver_threads(reason: String) -> void:
	if _wayweaver_threads != null:
		_wayweaver_threads.invalidate(reason)
	_wayweaver_presence.clear()
	_wayweaver_basic_modifiers.clear()
	_wayweaver_echo_pending.clear()
	_wayweaver_echo_replayed_nonces.clear()
	_wayweaver_host_basic_tokens.clear()
	_wayweaver_host_basic_pending.clear()
	_wayweaver_host_local_release.clear()
	_refresh_wayweaver_strand()

# B5-wave2 — Heartwood Ward: a timed absorb pool soaked in take_damage.
var _ward_hp := 0
var _ward_t := 0.0
var _ward_max := 1            # C8 — last applied absorb, for the hotbar arc
# Spec 45-wilds — Mothmint Mend's fractional heal carry.
var _regen_accum := 0.0

# Spec 45-hunt — Even Breath's kill refund lands here (combatant._die).
func add_focus(amount: float) -> void:
	focus = clampf(focus + amount, 0.0, focus_max)
	if _hud != null and _hud.has_method("set_focus"):
		_hud.set_focus(focus, focus_max)

func apply_ward(amount: int, duration: float) -> void:
	_ward_hp = amount
	_ward_max = maxi(1, amount)
	_ward_t = duration
	# Bark-brown flash on the mesh sells the skin hardening.
	if _mesh != null:
		var tw := create_tween()
		tw.tween_property(_mesh, "scale", _mesh.scale * 1.08, 0.10)
		tw.tween_property(_mesh, "scale", _mesh.scale, 0.14)


# Wayweaver's ward echo never erases a stronger existing Heartwood Ward.  It
# grants the modest eight only when that improves the remaining absorb pool,
# while the longer of the two durations remains visible to the HUD.
func apply_ward_max_preserving(amount: int, duration: float) -> void:
	if amount <= 0 or duration <= 0.0:
		return
	_ward_hp = maxi(_ward_hp, amount)
	_ward_max = maxi(_ward_max, _ward_hp)
	_ward_t = maxf(_ward_t, duration)

# C8 — the hotbar ward arc reads these (skill_bar pushes get_ward_frac to the
# HeartwoodWard slot each frame).
func get_ward_hp() -> int:
	return _ward_hp

func get_ward_frac() -> float:
	return clampf(float(_ward_hp) / float(maxi(1, _ward_max)), 0.0, 1.0)

# Shrine.gd calls this with the picked buff's stat + value (additive).
func apply_shrine_buff(stat: String, value) -> void:
	if shrine_buffs.has(stat):
		shrine_buffs[stat] += value
	_derive_stats()
	print("[shrine] +%s %s applied" % [str(value), stat])

# HUD buttons call these (the keybinds route here too).
# B5 / ADR-0016 — the Skill factory. Rebuilds `skills` from the variable
# Game.loadout; the bar rebinds so labels/icons/costs follow.
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
	"DrivingVolley": preload("res://scripts/skills/driving_volley.gd"),
	"Threadstep": preload("res://scripts/skills/threadstep.gd"),
	"WayfindersMark": WayfindersMarkScript,
	# Skills-on-items: granted ONLY by a bound weapon enchant (not in
	# Game.SKILL_POOL). Registered here so rebuild_skills can build them when
	# the player slots a granted skill (Game.available_skills).
	"Galecall": preload("res://scripts/skills/galecall.gd"),
	"Wyrdvolley": preload("res://scripts/skills/wyrdvolley.gd"),
}

func rebuild_skills() -> void:
	var game := get_tree().root.get_node_or_null("Game")
	var persistent_picks: Array = []
	if game != null and game.get("loadout") is Array:
		for raw_skill in (game.loadout as Array):
			var skill_id := String(raw_skill)
			if persistent_picks.size() >= 3:
				break
			# Game decides whether the entitlement exists; the local factory only
			# decides whether this client has an implementation it can instantiate.
			if _skill_is_currently_usable(game, skill_id) and SKILL_FACTORY.has(skill_id):
				persistent_picks.append(skill_id)
	# Gear grants are runtime actions only: they never write Game.owned_skills or
	# Game.loadout. A full permanent bar yields its last runtime slot to the grant;
	# removing the gear rebuilds the untouched persistent selection.
	var picks := persistent_picks.duplicate()
	if game != null and game.has_method("granted_skills"):
		for raw_grant in (game.granted_skills() as Array):
			var granted := String(raw_grant)
			if picks.has(granted) or not _skill_is_currently_usable(game, granted) \
					or not SKILL_FACTORY.has(granted):
				continue
			if picks.size() >= 3:
				picks.pop_back()
			picks.append(granted)
	skills = [BasicShotScript.new()]
	for raw_skill in picks:
		var skill_id := String(raw_skill)
		var script = SKILL_FACTORY.get(skill_id)
		if script == null:
			# Do not substitute an unearned Bow here: a missing implementation is
			# an unavailable action, not permission to fill a hidden key slot.
			push_warning("rebuild_skills: no SKILL_FACTORY entry for '%s'" % skill_id)
			continue
		skills.append(script.new())
	# Re-SEED the exact variable action set. A bare clear() left an existing
	# action unkeyed and the next cast crashed (the frozen-game bug).
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

func _bind(action: String, keys: Array, joy_buttons: Array = []) -> void:
	# Wyrd — a re-instanced player (Town↔Dungeon transitions) must not
	# append duplicate events onto an action that already exists. Still fill a
	# missing device binding when project settings already define the action.
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var existing := InputMap.action_get_events(action)
	for k in keys:
		var already_bound := existing.any(func(event):
			return event is InputEventKey \
				and (event as InputEventKey).physical_keycode == int(k))
		if already_bound:
			continue
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
	for button in joy_buttons:
		var already_bound := existing.any(func(event):
			return event is InputEventJoypadButton \
				and (event as InputEventJoypadButton).button_index == int(button))
		if already_bound:
			continue
		var ev := InputEventJoypadButton.new()
		ev.button_index = int(button)
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
	"marked": "marked",
}

func apply_status(kind: String, duration: float, dpt: int,
		slow_factor: float = 1.0, tick_interval: float = 0.0):
	if dead:
		return null
	# Threadstep's grace is narrowly cinder-only.  Other burns, roots, arrows,
	# and direct damage continue to resolve normally during the 0.22-second
	# window; Fire's Cinderbound controller supplies the cinder-prefixed kinds.
	if threadstep_cinder_grace_active() and kind.begins_with("cinder"):
		return null
	# D14 — first time a bleed / movement-lock lands, explain it.
	var game_h = get_tree().root.get_node_or_null("Game")
	if game_h != null and game_h.has_method("first_time_hint"):
		if kind == "bleed":
			game_h.first_time_hint("status_bleed")
		elif kind == "snared" or kind == "root":
			game_h.first_time_hint("status_slow")
	var existing = _statuses.get(kind, null)
	if existing != null:
		# Highest-wins refresh — same rule as Combatant's apply_status.
		existing.time_left = maxf(existing.time_left, duration)
		existing.damage_per_tick = maxi(existing.damage_per_tick, dpt)
		existing.slow_factor = minf(existing.slow_factor, slow_factor)
		existing.duration = maxf(existing.duration, duration)
		_update_pips()
		return existing
	var s = StatusEffectScript.new()
	s.kind = kind
	s.time_left = duration
	s.duration = duration
	s.tick_interval = tick_interval
	s.next_tick = tick_interval
	s.damage_per_tick = dpt
	s.slow_factor = slow_factor
	_statuses[kind] = s
	_update_pips()
	return s

# Serialise active statuses for the HUD pip row + push to the HUD.
func _build_pip_list() -> Array:
	var out: Array = []
	for kind in _statuses:
		var s = _statuses[kind]
		var frac := 1.0
		if float(s.duration) > 0.0:
			frac = clampf(float(s.time_left) / float(s.duration), 0.0, 1.0)
		out.append({"kind": kind, "frac": frac})
	return out

func _update_pips() -> void:
	if _hud != null and _hud.has_method("update_pips"):
		_hud.update_pips(_build_pip_list())

func has_status(kind: String) -> bool:
	return _statuses.has(kind)

func get_status(kind: String):
	return _statuses.get(kind, null)

# Clear a status immediately — a Quickroot Tonic shakes off root/snare.
func cleanse_status(kind: String) -> void:
	if _statuses.erase(kind):
		_update_pips()

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
	_update_pips()   # animate the drain arcs + drop any expired pips

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
