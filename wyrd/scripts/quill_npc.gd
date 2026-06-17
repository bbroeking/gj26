class_name QuillNpc
extends Interactable

# Wyrd — Quill, the Herbalist (A8-full). Canon character from the
# prototype's npcs.js: soft-spoken, 1.62m, minds the herb beds at the
# yard's south edge. Her still brews tonics that sharpen rather than
# feed — the buff shelf beside the hearth's heal shelf. Voice rules:
# docs/WORLD_BIBLE.md (plain-spoken, warm, no fantasy-isms).

const QUILL_GLB := preload("res://models/npc_quill_v2.glb")
const DialogPanelScript = preload("res://scripts/ui/dialog_panel.gd")
const QuillPanelScript = preload("res://scripts/ui/quill_panel.gd")

func get_prompt_text() -> String:
	return "[E] Quill's Still"

func get_prompt_color() -> Color:
	return Color(0.72, 0.88, 0.6)        # herb-green

func get_prompt_position() -> Vector3:
	return Vector3(0.0, 2.0, 0.0)

func _ready_interactable() -> void:
	var mesh := QUILL_GLB.instantiate()
	add_child(mesh)
	GlbFit.normalize_height(mesh, 1.62)   # her in-lore height (npcs.js)
	GlbFit.unmetal(mesh)
	GlbFit.add_ink_outline(mesh)

func interact(_player: Node) -> void:
	# Quill's Still — her buy shelf (tonics + herbs), a second vendor beside Hod.
	# Kit-styled modal that does its own level-gating and modal accounting.
	var panel: CanvasLayer = QuillPanelScript.new()
	get_tree().current_scene.add_child(panel)
