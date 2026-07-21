extends Area3D

# Phase 3 (Plan.md) — a slow, telegraphed enemy projectile: cozy bullet-hell-lite.
# A bright emissive orb the player STRAFES around (deliberately ~5x slower than
# the player's arrow so it reads as avoidable, not zippy). Host-authoritative:
# enemy AI only ticks on the host, so projectiles only spawn there; damage routes
# through the player's take_damage (which forwards remote hits to the owner).
# Hits the player (layer 2) and walls (layer 1) only — never other enemies, so
# no friendly fire.
#
# KNOWN FOLLOW-UPS (reviewed, deferred): (1) CO-OP — the orb + its telegraph are
# host-local, not replicated, so a guest takes ranged damage with no on-screen
# orb/tell (damage itself forwards correctly via take_damage). Next step: an
# @rpc broadcasting a cosmetic, damage-less orb + telegraph to guests. (2) WALL
# tunneling — collision is Area3D-only (no raycast like arrow.gd); safe at 9 u/s
# / 60fps, but add a per-step wall raycast if low-fps tunnelling shows up.

const LIFETIME := 5.0
const RADIUS := 0.22
const PROJ_COLOR := Color(0.96, 0.42, 0.86)   # bright magenta — pops vs dark crypt

var _dir := Vector3.FORWARD
var _speed := 9.0
var _damage := 5
var _color := PROJ_COLOR
var _spawn_position := Vector3.ZERO
var _life := 0.0
var _armed := false          # don't move/collide until setup() has positioned us

func setup(from: Vector3, dir: Vector3, speed: float, damage: int,
		color: Color = PROJ_COLOR) -> void:
	_spawn_position = from
	# Configuration normally happens before add_child so _ready can build the
	# right colored material. A detached Node3D has no global transform yet.
	if is_inside_tree():
		global_position = from
	else:
		position = from
	var d := Vector3(dir.x, 0.0, dir.z)
	_dir = d.normalized() if d.length() > 0.01 else Vector3.FORWARD
	_speed = speed
	_damage = damage
	_color = color
	_armed = true

func _ready() -> void:
	if is_inside_tree():
		global_position = _spawn_position
	else:
		position = _spawn_position
	collision_layer = 0
	collision_mask = (1 << 0) | (1 << 1)   # world + player
	monitoring = true
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = RADIUS
	cs.shape = sh
	add_child(cs)
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = RADIUS
	sm.height = RADIUS * 2.0
	mi.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _color
	mat.emission_enabled = true
	mat.emission = _color
	mat.emission_energy_multiplier = 1.6
	mi.material_override = mat
	add_child(mi)
	body_entered.connect(_on_body)

func _physics_process(delta: float) -> void:
	if not _armed:
		return
	global_position += _dir * _speed * delta
	_life += delta
	if _life >= LIFETIME:
		queue_free()

func _on_body(body: Node) -> void:
	if not _armed or body == null or not is_instance_valid(body):
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(_damage, -_dir)
		queue_free()
	elif body.is_in_group("wall") or body is StaticBody3D:
		queue_free()

# A floor aim-line telegraph from the shooter toward `dir` (the readable "a shot
# is coming" tell). The combatant adds it as a child, tweens scale.z 0→1 over the
# windup, and frees it on the strike. Returned at full length; start it thin.
static func make_telegraph(dir: Vector3, length: float,
		color: Color = PROJ_COLOR) -> MeshInstance3D:
	var d := Vector3(dir.x, 0.0, dir.z)
	d = d.normalized() if d.length() > 0.01 else Vector3.FORWARD
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.16, 0.03, length)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.5)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.2
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	mi.position = Vector3(0.0, 0.06, 0.0) + d * (length * 0.5)
	mi.rotation.y = atan2(d.x, d.z)
	return mi
