extends Node3D

# Spec 16 (revised) — sizing calibration scene.
# Renders the player + every enemy at NATIVE scale on a checkerboard tile
# floor beside one wall, at the crypt camera angle. Prints each model's
# real height (skeleton rest-pose extent for rigged models — their skinned
# mesh AABB is meaningless) and saves a screenshot for side-by-side
# comparison with the reference ARPG image.
#   godot --path godot res://scenes/Calibration.tscn

const MODELS := {
	"ranger":      "res://models/npc_ranger_body_v3.glb",
	"skeleton":    "res://models/enemy_skeleton_v1_rigged.glb",
	"ghost":       "res://models/enemy_ghost_v1_rigged.glb",
	"hedgesprite": "res://models/enemy_hedge_sprite_v1_rigged.glb",
	"rat":         "res://models/enemy_rat_v1.glb",
	"hedgemother": "res://models/hedgemother_v2_rigged.glb",
}
const ORDER := ["ranger", "skeleton", "ghost", "hedgesprite", "rat", "hedgemother"]

# Per-model scale factor — tuned by eye against the reference via this
# calibration screenshot (the skinned-mesh height can't be measured
# reliably; the screenshot is the authority). These port straight into
# the game once the lineup looks proportionate.
const SCALE := {
	"ranger":      1.30,
	"skeleton":    1.45,
	"ghost":       2.00,
	"hedgesprite": 2.00,
	"rat":         0.55,
	"hedgemother": 3.75,
}

const CAM_PITCH := 52.0      # degrees above horizon
const CAM_ZOOM := 15.0
const WALL_HEIGHT := 4.5

func _ready() -> void:
	_build_floor()
	_build_wall()
	for i in ORDER.size():
		_place_model(ORDER[i], i)
	_add_light()
	_add_camera()
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().create_timer(0.6).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/godot_calib.png")
	print("[calib] screenshot → /tmp/godot_calib.png")
	get_tree().quit()

func _build_floor() -> void:
	for z in range(-1, 7):
		for x in range(-1, 13):
			var mi := MeshInstance3D.new()
			var m := PlaneMesh.new()
			m.size = Vector2(1.0, 1.0)
			mi.mesh = m
			var mat := StandardMaterial3D.new()
			var dark := (x + z) % 2 == 0
			mat.albedo_color = Color(0.40, 0.36, 0.32) if dark else Color(0.54, 0.50, 0.44)
			mi.material_override = mat
			mi.position = Vector3(x + 0.5, 0.0, z + 0.5)
			add_child(mi)

func _build_wall() -> void:
	for x in range(-1, 13):
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.0, WALL_HEIGHT, 1.0)
		mi.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.34, 0.31, 0.28)
		mi.material_override = mat
		mi.position = Vector3(x + 0.5, WALL_HEIGHT * 0.5, -0.5)
		add_child(mi)

func _place_model(key: String, slot: int) -> void:
	var path: String = MODELS[key]
	var packed: PackedScene = load(path)
	if packed == null:
		print("[calib] MISSING %s" % path)
		return
	var inst: Node3D = packed.instantiate()
	add_child(inst)
	var s: float = SCALE[key]
	inst.scale = Vector3.ONE * s
	inst.position = Vector3(slot * 2 + 1.5, 0.0, 3.0)
	print("[calib] %-12s scale = %.2f" % [key, s])

# Rigged models: the skinned mesh AABB is bogus (Meshy bakes verts at the
# origin) — use the skeleton's rest-pose Y-extent. Static models: mesh AABB.
func _model_height(node: Node) -> float:
	var skel := _find_skeleton(node)
	if skel != null:
		# Bone rest poses are in the skeleton's own (often unscaled) space —
		# transform through the skeleton's global xform for real-world Y.
		var xform := skel.global_transform
		var lo := INF
		var hi := -INF
		for b in skel.get_bone_count():
			var y: float = (xform * skel.get_bone_global_rest(b)).origin.y
			lo = min(lo, y)
			hi = max(hi, y)
		return hi - lo
	# static — merge visual AABBs
	var box := AABB()
	var got := false
	for vi in _visuals(node):
		var a: AABB = vi.global_transform * vi.get_aabb()
		if not got:
			box = a
			got = true
		else:
			box = box.merge(a)
	return box.size.y

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for c in node.get_children():
		var s := _find_skeleton(c)
		if s != null:
			return s
	return null

func _visuals(node: Node) -> Array:
	var out := []
	if node is VisualInstance3D:
		out.append(node)
	for c in node.get_children():
		out.append_array(_visuals(c))
	return out

func _add_light() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_energy = 1.1
	add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.12, 0.11, 0.13)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.58, 0.62)
	e.ambient_light_energy = 0.5
	env.environment = e
	add_child(env)

func _add_camera() -> void:
	var cam := Camera3D.new()
	cam.fov = 50.0
	add_child(cam)                       # in-tree before look_at
	var target := Vector3(ORDER.size(), 0.9, 3.0)
	var pitch := deg_to_rad(CAM_PITCH)
	cam.global_position = target + Vector3(0.0, sin(pitch), cos(pitch)) * CAM_ZOOM
	cam.look_at(target, Vector3.UP)
	cam.current = true
