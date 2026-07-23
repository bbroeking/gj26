class_name VendorNpc
extends Interactable

# Wyrd — Old Hod Tenter, the smith. Stands by his forge; E opens the
# buy/sell counter. Gear sold to him melts down for gold; his shelf stocks
# raw materials and inks at convenience-tax prices. Voice: cozy gruff
# (src/data/npcs.js).

const HOD_GLB := preload("res://models/npc_hod_tenter_v1_rigged.glb")
const HOD_WALK_GLB := preload("res://models/npc_hod_tenter_v1_walk_anim.glb")
const AnimDriverScript := preload("res://scripts/anim_driver.gd")
const NpcAttentionScript := preload("res://scripts/npc_attention.gd")
const NpcWanderScript := preload("res://scripts/npc_wander.gd")
const VendorPanelScript = preload("res://scripts/ui/vendor_panel.gd")

func get_prompt_text() -> String:
	return "[E] Trade with Old Hod"

func get_prompt_color() -> Color:
	return Color(0.95, 0.8, 0.5)         # forge-warm

func get_prompt_position() -> Vector3:
	return Vector3(0.0, 2.1, 0.0)

func get_solid_radius() -> float:
	return 0.0

func _ready_interactable() -> void:
	var mesh := HOD_GLB.instantiate()
	add_child(mesh)
	# Measured production height is 1.336 m; avoid skinned-AABB normalization.
	mesh.scale = Vector3.ONE * (1.72 / 1.336)
	GlbFit.unmetal(mesh)
	GlbFit.add_ink_outline(mesh)
	AnimDriverScript.play_sidecar_pose(mesh, HOD_WALK_GLB, "walk", 0.5, 0.34)
	var attention := NpcAttentionScript.new()
	attention.name = "NpcAttention"
	add_child(attention)
	attention.setup(self)
	var wander := NpcWanderScript.new()
	wander.name = "NpcWander"
	add_child(wander)
	wander.setup(self, mesh, HOD_WALK_GLB, [
		Vector3(1.0, 0.0, 0.8), Vector3(-0.8, 0.0, 1.0),
	], 0.62)

func interact(player: Node) -> void:
	var attention := get_node_or_null("NpcAttention")
	if attention != null and attention.has_method("face_now"):
		attention.face_now(player)
	var wander := get_node_or_null("NpcWander")
	if wander != null and wander.has_method("pause_for_attention"):
		wander.pause_for_attention()
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
