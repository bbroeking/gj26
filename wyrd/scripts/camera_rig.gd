extends Node3D

# Spec 09 (rev) — third-person camera rig.
# A standalone pivot node (NOT parented to the player) so the follow can be
# smoothed. The camera is positioned explicitly on a sphere around the pivot
# and uses look_at() — so it ALWAYS faces the player, at any pitch. (The
# earlier SpringArm rig pointed the camera away from the player at steep
# top-down angles.)
#
#   - smooth follow: pivot eases toward the player each frame
#   - orbit: right-mouse-drag yaw + pitch, Q/E keyboard yaw
#   - zoom: scroll wheel adjusts camera distance

# ============================================================
# TUNABLES
# ============================================================
const FOLLOW_SPEED := 12.0         # responsive ARPG follow; atmosphere supplies the softness
# Spec 36 (Batch B) — lead targeting. Camera pivot nudges ahead of the
# player along velocity so the camera reads as alive, not glued. Lead scales
# with horizontal speed and is capped so sprint doesn't overshoot the frame.
const LEAD_FACTOR := 0.14          # enough look-ahead without a rubber-band pivot
const MAX_LEAD := 1.0              # keep the player anchored during reversals
const ORBIT_SENSITIVITY := 0.006   # radians per pixel of mouse drag
const KEY_YAW_SPEED := 2.2         # radians/sec for Q/E
# Wyrd — FATE (2005) framing. The trick is a LOW pitch + a NARROW telephoto
# FOV (35°, set on the Camera in CameraRig.tscn): you look across the world
# toward a horizon instead of down at a map, perspective compresses, the
# character reads big, and the frame holds less peripheral clutter. Zoom
# distance went UP at the same time — with the long lens the character is
# still ~80% larger on screen than the original 17 m / 50° setup.
const PITCH_MIN := 25.0            # degrees above the horizon
const PITCH_MAX := 70.0            # kept off 90° so look_at never degenerates
const PITCH_DEFAULT := 38.0        # FATE's low 3/4 — silhouettes, not rooftops
const ZOOM_MIN := 8.0
const ZOOM_MAX := 22.0
const ZOOM_STEP := 2.0
const ZOOM_DEFAULT := 16.5         # playtest: pulled back so zones feel less cramped
const ZOOM_LERP := 10.0
const TARGET_HEIGHT := 1.0         # look at the player's mid-height
# ============================================================

var _player: Node3D
var _camera: Camera3D
var _yaw := 0.0
var _pitch := deg_to_rad(PITCH_DEFAULT)
var _zoom := ZOOM_DEFAULT
var _zoom_target := ZOOM_DEFAULT
var _orbiting := false
var _snapped := false
var _shake_amt := 0.0           # spec 26 — current screen-shake amplitude
var _cinematic_active := false
var _pre_cinematic_process_mode := Node.PROCESS_MODE_INHERIT

func _ready() -> void:
	_camera = $Camera
	add_to_group("camera_rig")   # combatant finds the rig to request shakes
	# Wyrd — keyboard yaw moved to Z/C: E now belongs to "interact" (the old
	# E double-bind made every chest-open also whip the camera).
	_bind("cam_yaw_left", KEY_Z)
	_bind("cam_yaw_right", KEY_C)
	# Spec 46 — follow the LOCAL player (in co-op the first in the group may
	# be a friend's puppet). Deferred: NetGame spawns players after scene
	# _ready, so retry until one with our authority exists.
	_acquire_player.call_deferred()

func _acquire_player() -> void:
	for p in get_tree().get_nodes_in_group("player"):
		var net := get_node_or_null("/root/NetGame")
		if net == null or not bool(net.active) \
				or (p as Node).is_multiplayer_authority():
			_player = p
			return
	if is_inside_tree():
		get_tree().create_timer(0.2).timeout.connect(_acquire_player)

func _bind(action: String, key: Key) -> void:
	# Wyrd — a re-instanced rig (Town↔Dungeon transitions) must not append
	# duplicate events onto an action that already exists.
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	InputMap.action_add_event(action, ev)

func _unhandled_input(event: InputEvent) -> void:
	if _cinematic_active:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_orbiting = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_target = clampf(_zoom_target - ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_target = clampf(_zoom_target + ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
	elif event is InputEventMouseMotion and _orbiting:
		_yaw -= event.relative.x * ORBIT_SENSITIVITY
		_pitch = clampf(
			_pitch + event.relative.y * ORBIT_SENSITIVITY,
			deg_to_rad(PITCH_MIN), deg_to_rad(PITCH_MAX))

func _process(delta: float) -> void:
	if _player == null:
		var game := get_node_or_null("/root/Game")
		_player = game.local_player() if game != null else null   # follow LOCAL peer
		if _player == null:
			return
	if _camera == null:
		return
	if _cinematic_active:
		_place_camera()
		_update_wall_occlusion()
		return

	# Pivot = player mid-height, nudged ahead by velocity for lead.
	# Spec 36 (Batch B) — leading makes the camera read as alive, not glued.
	var lead := Vector3.ZERO
	if _player is CharacterBody3D:
		var pv: Vector3 = (_player as CharacterBody3D).velocity
		pv.y = 0.0
		lead = pv * LEAD_FACTOR
		if lead.length() > MAX_LEAD:
			lead = lead.normalized() * MAX_LEAD
	var pivot := _player.global_position + Vector3(0.0, TARGET_HEIGHT, 0.0) + lead
	if not _snapped:
		global_position = pivot
		_snapped = true
	else:
		global_position = global_position.lerp(pivot, FOLLOW_SPEED * delta)

	# Keyboard yaw.
	if Input.is_action_pressed("cam_yaw_left"):
		_yaw += KEY_YAW_SPEED * delta
	if Input.is_action_pressed("cam_yaw_right"):
		_yaw -= KEY_YAW_SPEED * delta

	_zoom = lerpf(_zoom, _zoom_target, ZOOM_LERP * delta)

	_place_camera()

	# Screen shake (spec 26) — jitter the camera position after look_at,
	# decaying fast. Re-derived from `offset` each frame, so it never builds up.
	if _shake_amt > 0.005:
		_camera.global_position += Vector3(
			randf_range(-1.0, 1.0), randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)) * _shake_amt
		_shake_amt = lerpf(_shake_amt, 0.0, 14.0 * delta)
	else:
		_shake_amt = 0.0

	_update_wall_occlusion()

# ---- onboarding micro-cutscene camera seam ----

func cinematic_frame() -> Dictionary:
	return {
		"focus": global_position,
		"yaw": _yaw,
		"pitch": rad_to_deg(_pitch),
		"zoom": _zoom,
	}

func begin_cinematic() -> void:
	if _cinematic_active:
		return
	_cinematic_active = true
	_orbiting = false
	_pre_cinematic_process_mode = process_mode
	# Game.modal_opened pauses offline play. The borrowed camera must keep
	# moving while the rest of the scene holds still.
	process_mode = Node.PROCESS_MODE_ALWAYS

func apply_cinematic_frame(frame: Dictionary) -> void:
	global_position = frame.get("focus", global_position)
	_yaw = float(frame.get("yaw", _yaw))
	_pitch = deg_to_rad(clampf(float(frame.get("pitch", rad_to_deg(_pitch))),
		PITCH_MIN, PITCH_MAX))
	_zoom = clampf(float(frame.get("zoom", _zoom)), ZOOM_MIN, ZOOM_MAX)
	_zoom_target = _zoom
	if _camera != null:
		_place_camera()

func end_cinematic() -> void:
	if not _cinematic_active:
		return
	_cinematic_active = false
	process_mode = _pre_cinematic_process_mode
	# The last frame is authored back on the player. Keep the smoothed follow
	# warm instead of forcing a second snap on the next process tick.
	_snapped = true

func _place_camera() -> void:
	if _camera == null:
		return
	# Place the camera on a sphere around the pivot, then look at the pivot.
	# Pitch is the angle above the horizon — higher pitch = more overhead.
	var horiz := cos(_pitch)
	var offset := Vector3(
		sin(_yaw) * horiz,
		sin(_pitch),
		cos(_yaw) * horiz
	) * _zoom
	_camera.global_position = global_position + offset
	_camera.look_at(global_position, Vector3.UP)

# A hit requests a shake impulse — the strongest pending wins.
func shake(amount: float) -> void:
	_shake_amt = maxf(_shake_amt, amount)

# Fade walls that overlap a protected screen-space aperture around the player.
# A single world-space ray was too narrow: it could report a clear line to the
# player's center while tall nearby tiles still covered their silhouette and
# the combat lane on screen. Walls are in the "wall" group with a per-wall
# alpha-capable material (see layout_loader._place_wall).
# The low FATE angle projects neighboring natural-wall crowns into the same
# foreground band. Protect a wider stage than the ranger's body alone so the
# edge frames nearby combat instead of forming two tall shoulders around it.
const CUTAWAY_RADIUS_PX := Vector2(255.0, 170.0)
const CUTAWAY_WALL_SCALE_Y := 0.14
const CUTAWAY_WALL_OFFSET_Y := -1.55
var _occluding := {}
var _wall_candidates: Array = []

func _update_wall_occlusion() -> void:
	if _player == null or _camera == null or not is_instance_valid(_player) \
			or not is_instance_valid(_camera) or not _player.is_inside_tree() \
			or not _camera.is_inside_tree():
		return
	var now_occ := {}
	if _wall_candidates.is_empty():
		_wall_candidates = get_tree().get_nodes_in_group("wall")
	var player_focus := _player.global_position + Vector3(0.0, 0.9, 0.0)
	var player_local := _camera.to_local(player_focus)
	var player_screen := _camera.unproject_position(player_focus)
	for wall in _wall_candidates:
		if not is_instance_valid(wall) or not (wall is Node3D) \
				or not (wall as Node3D).is_inside_tree():
			continue
		var wall_node := wall as Node3D
		var wall_focus := wall_node.global_position
		var wall_local := _camera.to_local(wall_focus)
		# Camera forward is -Z. Only cut geometry between camera and player.
		if wall_local.z <= player_local.z or wall_local.z >= 0.0:
			continue
		# Test the projected wall silhouette, not only its center. Tall walls can
		# cover the player even when their center lies well above the aperture.
		var wall_bottom := _camera.unproject_position(
			wall_focus + Vector3(0.0, -1.8, 0.0))
		var wall_top := _camera.unproject_position(
			wall_focus + Vector3(0.0, 1.8, 0.0))
		var wall_rect := Rect2(wall_bottom, Vector2.ZERO).expand(wall_top).grow(42.0)
		var aperture_rect := Rect2(player_screen - CUTAWAY_RADIUS_PX,
			CUTAWAY_RADIUS_PX * 2.0)
		if wall_rect.intersects(aperture_rect):
			now_occ[wall] = true
	for w in now_occ:
		if not _occluding.has(w):
			_set_wall_cutaway(w, true)
	for w in _occluding:
		if not now_occ.has(w) and is_instance_valid(w):
			_set_wall_cutaway(w, false)
	_occluding = now_occ

func _set_wall_cutaway(wall: Node, cut: bool) -> void:
	# Keep the solid collision and a low visual boundary. Transparency exposed
	# the floorless wall cell as a black hole; lowering the box preserves the
	# room outline while opening the combat read.
	var mesh := wall.get_node_or_null("WallMesh") as Node3D
	if mesh == null:
		return
	mesh.scale.y = CUTAWAY_WALL_SCALE_Y if cut else 1.0
	mesh.position.y = CUTAWAY_WALL_OFFSET_Y if cut else 0.0
