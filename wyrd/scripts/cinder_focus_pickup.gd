class_name CinderFocusPickup
extends Interactable

# One physical presentation for the host-owned nonce claim. The vent validates
# sender/proximity and grants Focus; this node never mutates the resource.

var vent: Node = null
var vent_nonce := 0
var claim_requested := false


func configure(p_vent: Node, p_nonce: int) -> void:
	vent = p_vent
	vent_nonce = p_nonce
	if vent != null and vent.has_signal("focus_pickup_claim_resolved") \
			and not vent.is_connected("focus_pickup_claim_resolved", _on_claim_resolved):
		vent.connect("focus_pickup_claim_resolved", _on_claim_resolved)
	if vent != null and vent.has_signal("focus_pickup_cleared") \
			and not vent.is_connected("focus_pickup_cleared", _on_pickup_cleared):
		vent.connect("focus_pickup_cleared", _on_pickup_cleared)


func get_prompt_text() -> String:
	return "[E/A] Catch the banked breath"


func get_prompt_color() -> Color:
	return Color(1.0, 0.58, 0.20)


func get_collision_radius() -> float:
	return 1.25


func get_solid_radius() -> float:
	return 0.0


func get_prompt_position() -> Vector3:
	return Vector3(0.0, 1.05, 0.0)


func is_used() -> bool:
	return vent == null or not is_instance_valid(vent) \
		or bool((vent.get("pickup") as Dictionary).get("claimed", false))


func _ready_interactable() -> void:
	add_to_group("cinder_focus_pickup")
	var orb := MeshInstance3D.new()
	orb.name = "BankedBreath"
	var mesh := SphereMesh.new()
	mesh.radius = 0.18
	mesh.height = 0.36
	mesh.radial_segments = 10
	mesh.rings = 6
	orb.mesh = mesh
	orb.position.y = 0.42
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.38, 0.10)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.26, 0.06)
	mat.emission_energy_multiplier = 2.0
	orb.material_override = mat
	add_child(orb)


func interact(player: Node) -> void:
	if claim_requested or is_used() or not vent.has_method("request_focus_pickup"):
		return
	if bool(vent.call("request_focus_pickup", vent_nonce, player as Node3D)):
		# A remote call only means the request left this client.  Keep the orb
		# until the host's nonce acknowledgement resolves it; otherwise packet
		# loss looks like a spent pickup without a Focus award.
		claim_requested = not is_used()
		if is_used():
			show_prompt(false)
			queue_free()


func _on_claim_resolved(nonce: int, accepted: bool) -> void:
	if nonce != vent_nonce:
		return
	claim_requested = false
	if accepted:
		show_prompt(false)
		queue_free()


func _on_pickup_cleared(nonce: int) -> void:
	if nonce == vent_nonce:
		show_prompt(false)
		queue_free()
