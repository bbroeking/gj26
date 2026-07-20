class_name KnotEaterAnchor
extends Interactable

@export var anchor_id := ""
var encounter: Node
var state := "bound"

func configure(id: String, controller: Node) -> void:
	anchor_id = id
	encounter = controller

func _ready_interactable() -> void:
	add_to_group("knot_eater_anchor")
	_build_shape()

func interact(_player: Node) -> void:
	if encounter != null and state == "bound":
		encounter.call("press", &"unbind", StringName(anchor_id))

func get_prompt_text() -> String:
	return "[E/A] Unbind old anchor" if state == "bound" else "[E/A] Anchor unbound"

func is_used() -> bool:
	return state == "unbound"

func set_state(next_state: String) -> void:
	state = next_state
	monitorable = state != "unbound"
	monitoring = state != "unbound"
	visible = state != "unbound"
	var prompt := get_node_or_null("PromptLabel") as Label3D
	if prompt != null: prompt.text = get_prompt_text()

func _build_shape() -> void:
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.22
	cylinder.bottom_radius = 0.38
	cylinder.height = 1.6
	mesh.mesh = cylinder
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.32, 0.22, 0.16)
	mat.emission_enabled = true
	mat.emission = Color(0.52, 0.34, 0.16)
	mesh.material_override = mat
	mesh.position.y = 0.8
	add_child(mesh)
