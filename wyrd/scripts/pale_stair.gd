class_name PaleStair
extends Interactable

# The Pale Stair is deliberately a settlement *presentation*, not a portal.
# Its owning world adapter creates it only after the canonical Queen contract
# has settled.  In particular, this class never reads Game campaign state: an
# old Summit handoff must not be able to infer this landmark into existence.

const STAIR_GLB := preload("res://models/landmark_rootroad_stair_v1.glb")
const DialogPanelScript = preload("res://scripts/ui/dialog_panel.gd")
const GlbFit = preload("res://scripts/glb_fit.gd")

var _dialog_open := false
var _settlement_view: Dictionary = {}


func set_campaign_settlement_view(view: Dictionary) -> void:
	# Retain only the explicit presentation token.  This class has no business
	# deciding whether a queen was canonical; LayoutLoader has already made that
	# authority decision at its narrow adapter boundary.
	_settlement_view = view.duplicate(true)


func get_prompt_text() -> String:
	return "[E/A] Look down the Pale Stair"


func get_prompt_color() -> Color:
	return Color(0.76, 0.88, 1.0)


func get_collision_radius() -> float:
	return 1.35


func get_collision_offset() -> Vector3:
	return Vector3(0.0, 0.55, 0.0)


func get_prompt_position() -> Vector3:
	return Vector3(0.0, 2.55, 0.0)


func get_solid_radius() -> float:
	# The landing remains passable: this is an invitation to the future Pale
	# Oath, not a hidden level transition or an arena blocker.
	return 0.0


func _ready_interactable() -> void:
	add_to_group("pale_stair")
	add_to_group("queen_settlement_landmark")
	var landmark: Node3D = STAIR_GLB.instantiate()
	landmark.name = "PaleStairLandmark"
	add_child(landmark)
	GlbFit.normalize_height(landmark, 3.8)
	GlbFit.unmetal(landmark)
	GlbFit.add_ink_outline(landmark)
	# The model carries a small emissive well.  This local light gives that
	# promise a readable pool at FATE camera distance without changing the
	# Summit biome's global lighting.
	var glow := OmniLight3D.new()
	glow.name = "PaleStairLight"
	glow.position = Vector3(0.0, 0.72, 0.35)
	glow.light_color = Color(0.62, 0.78, 1.0)
	glow.light_energy = 1.45
	glow.omni_range = 5.0
	glow.omni_attenuation = 1.9
	glow.light_volumetric_fog_energy = 0.7
	add_child(glow)


func interact(_player: Node) -> void:
	if _dialog_open:
		return
	_dialog_open = true
	var dialog := DialogPanelScript.new()
	dialog.name = "PaleStairDialog"
	dialog.add_to_group("PaleStairDialog")
	dialog.open("The Pale Stair", pages())
	dialog.finished.connect(func() -> void:
		_dialog_open = false
		read_now())
	get_tree().current_scene.add_child(dialog)


# Public seam for tests and accessibility tools.  The interaction is repeatable
# and intentionally copy-only: neither the current scene nor Game receives a
# travel request, inventory mutation, or chapter mutation here.
func read_now() -> Dictionary:
	return {
		"ok": true,
		"changed": false,
		"repeatable": true,
		"route": "pale_oath_not_yet_walkable",
		"settlement_token": bool(_settlement_view.get("pale_stair", false)),
	}


func pages() -> Array:
	return [
		"Root and old stone turn beneath the snow. A pale light waits below, patient as a held breath.",
		"The stair does not ask you to descend. Not yet. Its first step bears one name: the Pale Oath.",
	]
