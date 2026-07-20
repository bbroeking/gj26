class_name OathBell
extends Interactable

var bell_id := "oath_bell_1"
var phase_index := 1
var controller: Node = null
var enabled_for_relief := false
var relieved := false


func set_controller(p_controller: Node, p_phase: int) -> void:
	var phase_changed := phase_index != p_phase
	controller = p_controller
	phase_index = p_phase
	bell_id = "oath_bell_%d" % p_phase
	# Tests and late-built encounters may attach a bell before its controller
	# assigns the authored phase. Refresh instead of leaving a phase-two/three
	# bell carrying bellpost #1 from _ready_interactable().
	if phase_changed and is_inside_tree():
		_refresh_model()


func set_enabled_for_phase(phase: int) -> void:
	enabled_for_relief = phase == phase_index and not relieved
	set_meta("pale_oath_state", "ready" if enabled_for_relief else "dormant")


func set_relieved() -> void:
	relieved = true
	enabled_for_relief = false
	set_meta("pale_oath_state", "relieved")


func get_prompt_text() -> String:
	return "[E/A] Ring the oath bell" if enabled_for_relief else "The oath bell is still"


func get_prompt_color() -> Color:
	return Color(0.82, 0.71, 0.36) if enabled_for_relief else Color(0.45, 0.48, 0.52)


func is_used() -> bool:
	# A relieved bell is permanent encounter scenery, not another action. Hiding
	# it from scanner selection keeps the nearby return Waystone unambiguous.
	return relieved


func get_collision_radius() -> float:
	return 1.35


func get_prompt_position() -> Vector3:
	return Vector3(0.0, 2.1, 0.0)


func _ready_interactable() -> void:
	add_to_group("pale_oath_bell")
	_refresh_model()


func _refresh_model() -> void:
	var old := get_node_or_null("BellpostModel")
	if old != null:
		remove_child(old)
		old.queue_free()
	var model_path := "res://models/prop_oath_bellpost_%d_v1.glb" % phase_index
	if ResourceLoader.exists(model_path):
		var packed: PackedScene = load(model_path)
		if packed != null:
			var model: Node3D = packed.instantiate()
			model.name = "BellpostModel"
			model.set_meta("bell_model_path", model_path)
			add_child(model)
			return
	var post := MeshInstance3D.new()
	post.name = "BellpostModel"
	post.set_meta("bell_model_path", model_path)
	post.mesh = CylinderMesh.new()
	post.position.y = 1.0
	add_child(post)


func interact(player: Node) -> void:
	if controller != null:
		controller.request_bell_relief(bell_id, phase_index, player as Node3D)
