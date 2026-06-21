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
	# D15 — first visit, Hod greets you before opening his shelf; after that it's
	# straight to the wares.
	var game := get_tree().root.get_node_or_null("Game")
	if game != null and not bool(game.seen_hints.get("hod_intro", false)):
		game.seen_hints["hod_intro"] = true
		game.save_now()
		var dlg: CanvasLayer = load("res://scripts/ui/dialog_panel.gd").new()
		dlg.open("Old Hod Tenter", [
			"Hrm. New face. Hod Tenter — I keep the forge and a shelf of honest stock.",
			"Bring me ore and I'll smelt it; bring gold and I'll sell what saves a life. Have a look."])
		get_tree().current_scene.add_child(dlg)
		dlg.finished.connect(func():
			get_tree().current_scene.add_child(VendorPanelScript.new()))
		return
	var panel := VendorPanelScript.new()
	get_tree().current_scene.add_child(panel)
