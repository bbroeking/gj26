class_name OathRubbing
extends Interactable

# Guaranteed presentation hook for each authored Pale Veins return.  The
# ledger fact is awarded by the host return path, never by inspecting this prop.

var rubbing_id := "oath_rubbing_1"


func setup(id: String) -> void:
	rubbing_id = id


func get_prompt_text() -> String:
	return "[E/A] Study the oath-rubbing"


func get_prompt_color() -> Color:
	return Color(0.78, 0.84, 0.72)


func get_solid_radius() -> float:
	return 0.0


func _ready_interactable() -> void:
	add_to_group("oath_rubbing")
	add_to_group("oath_rubbing_%s" % rubbing_id)
	var model_path := "res://models/prop_oath_rubbing_v1.glb"
	if ResourceLoader.exists(model_path):
		var packed: PackedScene = load(model_path)
		if packed != null:
			var model: Node3D = packed.instantiate()
			model.name = "OathRubbingPresentation"
			add_child(model)
			return
	var page := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.82, 0.05, 0.60)
	page.mesh = mesh
	page.position.y = 0.05
	add_child(page)


func read_now() -> Dictionary:
	return {"ok": true, "changed": false, "rubbing_id": rubbing_id, "presentation": "oath_rubbing"}


func interact(_player: Node) -> void:
	read_now()

