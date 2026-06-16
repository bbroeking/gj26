class_name VendorNpc
extends Interactable

# Wyrd — Old Hod Tenter, the smith. Stands by his forge; E opens the
# buy/sell counter. Gear sold to him melts down for gold; his shelf stocks
# raw materials and inks at convenience-tax prices. Voice: cozy gruff
# (src/data/npcs.js).

const HOD_GLB := preload("res://models/npc_hod_v3.glb")
const VendorPanelScript = preload("res://scripts/ui/vendor_panel.gd")

func get_prompt_text() -> String:
	return "[E] Trade with Old Hod"

func get_prompt_color() -> Color:
	return Color(0.95, 0.8, 0.5)         # forge-warm

func get_prompt_position() -> Vector3:
	return Vector3(0.0, 2.1, 0.0)

func _ready_interactable() -> void:
	var mesh := HOD_GLB.instantiate()
	add_child(mesh)
	GlbFit.normalize_height(mesh, 1.72)   # his in-lore height
	GlbFit.unmetal(mesh)
	GlbFit.add_ink_outline(mesh)

func interact(_player: Node) -> void:
	var panel := VendorPanelScript.new()
	get_tree().current_scene.add_child(panel)
