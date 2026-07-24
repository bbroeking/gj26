class_name QuillNpc
extends Interactable

# Wyrd — Quill, the Herbalist (A8-full). Canon character from the
# prototype's npcs.js: soft-spoken, 1.62m, minds the herb beds at the
# yard's south edge. Her still brews tonics that sharpen rather than
# feed — the buff shelf beside the hearth's heal shelf. Voice rules:
# docs/WORLD_BIBLE.md (plain-spoken, warm, no fantasy-isms).

const QUILL_GLB := preload("res://models/npc_quill_v3_rigged.glb")
const QUILL_WALK_GLB := preload("res://models/npc_quill_v3_walk_anim.glb")
const AnimDriverScript := preload("res://scripts/anim_driver.gd")
const NpcAttentionScript := preload("res://scripts/npc_attention.gd")
const NpcWanderScript := preload("res://scripts/npc_wander.gd")
const QuillPanelScript = preload("res://scripts/ui/quill_panel.gd")

func get_prompt_text() -> String:
	return "[E] Quill's Still"

func get_prompt_color() -> Color:
	return Color(0.72, 0.88, 0.6)        # herb-green

func get_prompt_position() -> Vector3:
	return Vector3(0.0, 2.0, 0.0)

func get_solid_radius() -> float:
	return 0.0

func _ready_interactable() -> void:
	var mesh := QUILL_GLB.instantiate()
	add_child(mesh)
	# The Meshy export is authored at Quill's 1.62 m in-lore height already.
	mesh.scale = Vector3.ONE
	GlbFit.unmetal(mesh)
	GlbFit.add_ink_outline(mesh)
	AnimDriverScript.play_sidecar_pose(mesh, QUILL_WALK_GLB, "walk", 0.75, 0.68)
	var attention := NpcAttentionScript.new()
	attention.name = "NpcAttention"
	add_child(attention)
	attention.setup(self)
	var wander := NpcWanderScript.new()
	wander.name = "NpcWander"
	add_child(wander)
	wander.setup(self, mesh, QUILL_WALK_GLB, [
		Vector3(1.2, 0.0, -0.8), Vector3(-1.0, 0.0, 0.7),
	], 0.66)

func interact(player: Node) -> void:
	var attention := get_node_or_null("NpcAttention")
	if attention != null and attention.has_method("face_now"):
		attention.face_now(player)
	var wander := get_node_or_null("NpcWander")
	if wander != null and wander.has_method("pause_for_attention"):
		wander.pause_for_attention()
	# D15 — first visit, Quill greets you (and reacts if you've quaffed a tonic
	# already) before opening her still; after that it's straight to the shelf.
	var game := get_tree().root.get_node_or_null("Game")
	if game != null and not bool(game.seen_hints.get("quill_intro", false)):
		game.seen_hints["quill_intro"] = true
		game.save_now()
		var pages: Array
		if bool(game.seen_hints.get("tonic_quaffed", false)):
			pages = ["You've a tonic in you already — good instincts. They hold for a stretch, then fade.",
				"My still's always brewing. Take what you'll need before the deep hollows."]
		else:
			pages = ["Quill, herbalist. I brew tonics — small boons that ride with you a while.",
				"Quaff one with Q before a delve. Here's the shelf."]
		var dlg: CanvasLayer = load("res://scripts/ui/dialog_panel.gd").new()
		dlg.open("Quill, the Herbalist", pages)
		get_tree().current_scene.add_child(dlg)
		dlg.finished.connect(func():
			get_tree().current_scene.add_child(QuillPanelScript.new()))
		return
	# Quill's Still — her buy shelf (tonics + herbs), a second vendor beside Hod.
	# Kit-styled modal that does its own level-gating and modal accounting.
	var panel: CanvasLayer = QuillPanelScript.new()
	get_tree().current_scene.add_child(panel)
