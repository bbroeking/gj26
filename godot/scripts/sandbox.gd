extends Node3D

# Spec 23 — movement sandbox. A flat open arena (no dungeon) for tuning the
# character's walk / run / dash / roll / fire feel in isolation. Builds the
# ground, lighting, and a few dummy targets; the Player + CameraRig + HUD
# are scene children. Run: godot --path godot res://scenes/Sandbox.tscn

const CombatantScript = preload("res://scripts/combatant.gd")

const DEBUG_SHOT := false   # true → save /tmp/godot_selfshot.png after load

func _ready() -> void:
	_build_ground()
	_build_lighting()
	_build_dummies()
	_place_player()
	if DEBUG_SHOT:
		get_tree().create_timer(2.0).timeout.connect(_debug_shot)

func _debug_shot() -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/godot_selfshot.png")
	print("[sandbox] debug shot → /tmp/godot_selfshot.png")

func _build_ground() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1          # LAYER_WORLD
	body.collision_mask = 0
	var size := Vector3(60.0, 1.0, 60.0)
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.46, 0.43, 0.38)
	mat.roughness = 0.97
	mi.material_override = mat
	mi.position = Vector3(0, -0.5, 0)
	body.add_child(mi)
	var shape := BoxShape3D.new()
	shape.size = size
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0, -0.5, 0)
	body.add_child(col)
	add_child(body)

func _build_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -38, 0)
	sun.light_color = Color(1, 0.95, 0.88)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.58, 0.62, 0.70)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.70, 0.70, 0.78)
	e.ambient_light_energy = 0.55
	we.environment = e
	add_child(we)

# Three dummy targets — Combatants, so arrows hit them and the hit feedback
# (flash, damage numbers, knockback) reads. Placed beyond aggro range so
# they stay put until the player walks over to fire-test.
func _build_dummies() -> void:
	for s in [Vector3(-7, 0, 15), Vector3(0, 0, 17), Vector3(7, 0, 15)]:
		var body: CharacterBody3D = CombatantScript.new()
		body.position = s
		body.collision_layer = 4          # LAYER_ENEMIES
		body.collision_mask = 1 | 2
		body.add_to_group("enemy")
		var mi := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.4
		cap.height = 1.6
		mi.mesh = cap
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.68, 0.32, 0.32)
		mi.material_override = mat
		mi.position = Vector3(0, 0.8, 0)
		body.add_child(mi)
		var shape := CapsuleShape3D.new()
		shape.radius = 0.4
		shape.height = 1.6
		var col := CollisionShape3D.new()
		col.shape = shape
		col.position = Vector3(0, 0.8, 0)
		body.add_child(col)
		add_child(body)
		body.cache_meshes()
		body.setup(200, 0.4, 1.6)

func _place_player() -> void:
	var p := get_node_or_null("Player")
	if p != null and p is Node3D:
		(p as Node3D).position = Vector3(0, 1.0, 0)
		if p.has_method("set_spawn"):
			p.set_spawn(Vector3(0, 1.0, 0))
