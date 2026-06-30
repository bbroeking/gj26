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
const FOLLOW_SPEED := 6.0          # Spec 36 (Batch B) — relaxed from 8.0; cozy follow with momentum
# Spec 36 (Batch B) — lead targeting. Camera pivot nudges ahead of the
# player along velocity so the camera reads as alive, not glued. Lead scales
# with horizontal speed and is capped so sprint doesn't overshoot the frame.
const LEAD_FACTOR := 0.25          # seconds of velocity-ahead to lead by
const MAX_LEAD := 1.8              # max world units the pivot can lead
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

	# Place the camera on a sphere around the pivot, then look at the pivot.
	# pitch is the angle above the horizon — higher pitch = more overhead.
	var horiz := cos(_pitch)
	var offset := Vector3(
		sin(_yaw) * horiz,
		sin(_pitch),
		cos(_yaw) * horiz
	) * _zoom
	_camera.global_position = global_position + offset
	_camera.look_at(global_position, Vector3.UP)

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

# A hit requests a shake impulse — the strongest pending wins.
func shake(amount: float) -> void:
	_shake_amt = maxf(_shake_amt, amount)

# Fade any wall between the camera and the player so the player is never
# hidden — the classic ARPG cut-away. Walls are in the "wall" group with a
# per-wall alpha-capable material (see layout_loader._place_wall).
var _occluding := {}

func _update_wall_occlusion() -> void:
	if _player == null or _camera == null:
		return
	var space := get_world_3d().direct_space_state
	var to := _player.global_position + Vector3(0.0, 1.0, 0.0)
	var origin := _camera.global_position
	var dir := (to - origin).normalized()
	var now_occ := {}
	for _i in 10:
		var q := PhysicsRayQueryParameters3D.create(origin, to)
		q.collision_mask = 1   # world layer
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			break
		var col = hit.get("collider")
		if col != null and col is Node and (col as Node).is_in_group("wall"):
			now_occ[col] = true
			origin = (hit.position as Vector3) + dir * 0.15
		else:
			break
	for w in now_occ:
		if not _occluding.has(w):
			_set_wall_alpha(w, 0.25)
	for w in _occluding:
		if not now_occ.has(w) and is_instance_valid(w):
			_set_wall_alpha(w, 1.0)
	_occluding = now_occ

func _set_wall_alpha(wall: Node, a: float) -> void:
	# Walls are now crypt wall GLBs (spec 24) — fade every mesh instance
	# under them via GeometryInstance3D.transparency (a=1 opaque → 0).
	var glb := wall.get_node_or_null("WallMesh")
	if glb != null:
		_apply_transparency(glb, 1.0 - a)

func _apply_transparency(n: Node, t: float) -> void:
	if n is GeometryInstance3D:
		(n as GeometryInstance3D).transparency = t
	for c in n.get_children():
		_apply_transparency(c, t)
