class_name KnotEaterKnot
extends Interactable

@export var knot_id := ""
var encounter: Node
var state := "sealed" # sealed | ready | marked

func configure(id: String, controller: Node) -> void:
	knot_id = id
	encounter = controller

func _ready_interactable() -> void:
	add_to_group("knot_eater_knot")
	monitorable = false
	monitoring = false
	_build_shape()
	_refresh()

func interact(_player: Node) -> void:
	pass # host cadence owns exposure; never a scanner intent

func get_prompt_text() -> String:
	return "The knot is Reeling" if state == "ready" else \
		"Knot named" if state == "marked" else "The knot is sleeping"

func set_state(next_state: String) -> void:
	state = next_state
	_refresh()

func _build_shape() -> void:
	var mesh := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.28
	torus.outer_radius = 0.52
	torus.rings = 10
	torus.ring_segments = 8
	mesh.mesh = torus
	mesh.name = "KnotShape"
	mesh.position.y = 0.62
	add_child(mesh)

func _refresh() -> void:
	var mesh := get_node_or_null("KnotShape") as MeshInstance3D
	if mesh == null:
		return
	var mat := StandardMaterial3D.new()
	var color := Color(0.18, 0.14, 0.11) if state == "sealed" else \
		Color(0.96, 0.55, 0.22) if state == "ready" else Color(0.30, 0.48, 0.30)
	mat.albedo_color = color
	mat.emission_enabled = state == "ready"
	mat.emission = color
	mesh.material_override = mat
