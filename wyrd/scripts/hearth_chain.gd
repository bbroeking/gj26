class_name HearthChain
extends Interactable

# A chain is intentionally a tiny, dumb presentation object.  All authority
# and all progression state live in HearthGiantEncounter.

@export var chain_id := ""
var state := "sealed" # sealed | ready | banked
var encounter: Node = null


func set_encounter(p_encounter: Node) -> void:
	encounter = p_encounter


func configure(p_chain_id: String) -> void:
	chain_id = p_chain_id


func set_chain_state(next_state: String) -> void:
	if next_state in ["sealed", "ready", "banked"]:
		state = next_state
		set_meta("hearth_chain_state", state)
		_refresh_visual()


func get_prompt_text() -> String:
	var title := chain_id.replace("_", " ").capitalize()
	return "[E/A] Bank %s" % title if state == "ready" else \
		"[E/A] %s is banked" % title if state == "banked" else \
		"[E/A] Inspect %s" % title


func get_prompt_color() -> Color:
	return Color(1.0, 0.48, 0.18) if state == "ready" else Color(0.72, 0.58, 0.48)


func is_used() -> bool:
	# A banked link remains as readable world-state and collision, but no longer
	# competes for the player's one interaction verb. In the compact Giant arena
	# an inert banked prompt could otherwise steal the nearby exit Waystone.
	return state == "banked"


func get_collision_radius() -> float:
	return 1.25


func get_solid_radius() -> float:
	return 0.42


func get_solid_height() -> float:
	return 1.6


func _ready_interactable() -> void:
	add_to_group("hearth_chain")
	_build_fallback()
	_refresh_visual()


func interact(player: Node) -> void:
	# A sealed wrong chain is still a meaningful, recoverable choice during a
	# heat phase; the encounter controller owns deciding whether this chain is
	# expected and applying its modest hazard. Only a banked chain is inert.
	if encounter == null or state == "banked" \
			or not encounter.has_method("request_chain_bank"):
		return
	encounter.call("request_chain_bank", chain_id,
		String(encounter.get("chart_instance")), String(encounter.get("attempt_id")),
		player as Node3D)


func _build_fallback() -> void:
	if get_node_or_null("ChainShape") != null:
		return
	var link_root := Node3D.new()
	link_root.name = "ChainShape"
	add_child(link_root)
	var paths := {
		"hollow_link": "res://models/prop_hollow_link_chain_v1.glb",
		"braided_link": "res://models/prop_braided_link_chain_v1.glb",
		"knot_link": "res://models/prop_knot_link_chain_v1.glb",
	}
	var path := String(paths.get(chain_id, ""))
	if path != "" and ResourceLoader.exists(path, "PackedScene"):
		var packed := ResourceLoader.load(path, "PackedScene") as PackedScene
		var model := packed.instantiate() as Node3D if packed != null else null
		if model != null:
			model.name = "ChainModel"
			GlbFit.normalize_height(model, 1.55)
			link_root.add_child(model)
			return
	var count := 4 if chain_id == "hollow_link" else 5 if chain_id == "braided_link" else 6
	for i in count:
		var link := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.10
		torus.outer_radius = 0.23
		torus.rings = 8
		torus.ring_segments = 5
		link.mesh = torus
		link.position = Vector3(0.0, 0.28 + float(i) * 0.23, 0.0)
		link.rotation.x = PI * 0.5
		link.rotation.y = PI * 0.5 if i % 2 else 0.0
		link_root.add_child(link)


func _refresh_visual() -> void:
	if not is_node_ready():
		return
	var color := Color(1.0, 0.38, 0.10) if state == "ready" else \
		Color(0.38, 0.30, 0.26) if state == "banked" else Color(0.20, 0.17, 0.17)
	for node in find_children("*", "MeshInstance3D", true, false):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.62
		if state == "ready":
			mat.emission_enabled = true
			mat.emission = color
			mat.emission_energy_multiplier = 1.35
		(node as MeshInstance3D).material_override = mat
	var prompt := get_node_or_null("PromptLabel") as Label3D
	if prompt != null:
		prompt.text = get_prompt_text()
