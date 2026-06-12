class_name CraftStation
extends Interactable

# Wyrd — a crafting station (the Cottage Hearth cookfire / Hod's Anvil).
# E opens the recipe panel for the station; the first use earns the
# one-time trade hint in the right neighbor's voice. Bodies are procedural
# primitives in the town palette (no GLBs yet — same fallback style as
# GatherNode).

const CraftingDefs = preload("res://data/crafting.gd")
const CraftPanelScript = preload("res://scripts/ui/craft_panel.gd")

var station_id := "cookfire"

func setup(p_station: String) -> void:
	station_id = p_station

func get_prompt_text() -> String:
	return "[E] %s" % String(CraftingDefs.station(station_id).get("prompt", "Craft"))

func get_prompt_color() -> Color:
	return Color(0.95, 0.78, 0.5)        # ember orange

func get_collision_radius() -> float:
	return 1.6

func get_prompt_position() -> Vector3:
	return Vector3(0.0, 1.7, 0.0)

func _ready_interactable() -> void:
	match station_id:
		"cookfire":
			_build_cookfire()
		"forge":
			_build_anvil()
		"still":
			_build_still()

func interact(_player: Node) -> void:
	var game := get_tree().root.get_node_or_null("Game")
	if game != null:
		game.first_time_hint(station_id)
	var panel: CanvasLayer = CraftPanelScript.new()
	panel.station_id = station_id
	get_tree().current_scene.add_child(panel)

# ---- bodies ----
func _build_cookfire() -> void:
	# Stone ring + crossed logs + a warm ember light.
	for i in 7:
		var ang := TAU * float(i) / 7.0
		var stone := _prim(_rock_mesh(0.14), Color(0.52, 0.48, 0.44),
			Vector3(cos(ang) * 0.42, 0.08, sin(ang) * 0.42))
		stone.rotation.y = ang
	for i in 3:
		var log_part := _prim(_log_mesh(), Color(0.40, 0.28, 0.18),
			Vector3(0.0, 0.16, 0.0))
		log_part.rotation.y = TAU * float(i) / 3.0
		log_part.rotation.z = 0.35
	var pot := _prim(_pot_mesh(), Color(0.30, 0.30, 0.34), Vector3(0.0, 0.42, 0.0))
	pot.scale = Vector3(1.0, 0.7, 1.0)
	var ember := OmniLight3D.new()
	ember.position = Vector3(0.0, 0.5, 0.0)
	ember.light_color = Color(1.0, 0.62, 0.3)
	ember.light_energy = 1.6
	ember.omni_range = 3.5
	add_child(ember)

func _build_anvil() -> void:
	_prim(_box_mesh(Vector3(0.5, 0.42, 0.5)), Color(0.38, 0.30, 0.24),
		Vector3(0.0, 0.21, 0.0))                       # stump
	_prim(_box_mesh(Vector3(0.78, 0.2, 0.32)), Color(0.32, 0.33, 0.38),
		Vector3(0.0, 0.52, 0.0))                       # anvil body
	var horn := _prim(_box_mesh(Vector3(0.26, 0.12, 0.2)), Color(0.32, 0.33, 0.38),
		Vector3(0.5, 0.5, 0.0))
	horn.rotation.z = 0.18
	var glow := OmniLight3D.new()
	glow.position = Vector3(0.0, 0.9, 0.0)
	glow.light_color = Color(1.0, 0.55, 0.25)
	glow.light_energy = 1.1
	glow.omni_range = 3.0
	add_child(glow)

# A8-full — Quill's copper still: bench, pot belly, swan-neck, catch-flask.
func _build_still() -> void:
	_prim(_box_mesh(Vector3(0.95, 0.5, 0.7)), Color(0.46, 0.36, 0.26),
		Vector3(0.0, 0.25, 0.0))                       # work bench
	var belly := _prim(_pot_mesh(), Color(0.74, 0.46, 0.28),
		Vector3(-0.18, 0.72, 0.0))                     # copper belly
	belly.scale = Vector3(1.15, 1.15, 1.15)
	var neck := _prim(_log_mesh(), Color(0.74, 0.46, 0.28),
		Vector3(0.12, 0.92, 0.0))                      # swan-neck spout
	neck.rotation.z = -0.85
	neck.scale = Vector3(0.55, 0.8, 0.55)
	var flask := _prim(_pot_mesh(), Color(0.62, 0.78, 0.66),
		Vector3(0.34, 0.62, 0.0))                      # catch-flask
	flask.scale = Vector3(0.5, 0.6, 0.5)
	var herbs := _prim(_rock_mesh(0.12), Color(0.45, 0.62, 0.34),
		Vector3(-0.35, 0.56, 0.22))                    # a bundle drying
	herbs.scale = Vector3(1.0, 0.6, 1.0)
	var glow := OmniLight3D.new()
	glow.position = Vector3(0.0, 0.8, 0.0)
	glow.light_color = Color(0.7, 0.95, 0.65)
	glow.light_energy = 0.9
	glow.omni_range = 2.6
	add_child(glow)

func _prim(mesh: Mesh, color: Color, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	return mi

func _rock_mesh(r: float) -> Mesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 1.5
	m.radial_segments = 6
	m.rings = 3
	return m

func _log_mesh() -> Mesh:
	var m := BoxMesh.new()
	m.size = Vector3(0.62, 0.1, 0.1)
	return m

func _pot_mesh() -> Mesh:
	var m := SphereMesh.new()
	m.radius = 0.22
	m.height = 0.4
	m.radial_segments = 10
	m.rings = 5
	return m

func _box_mesh(size: Vector3) -> Mesh:
	var m := BoxMesh.new()
	m.size = size
	return m
