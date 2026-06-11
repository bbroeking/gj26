class_name WayfinderNpc
extends Interactable

# Wyrd — Mara Linnet, the Wayfinder. Tutorial anchor in the Chartmaker's
# Yard. Dialog pages key off Game.tutorial_step; her first conversation
# advances step 0 → 1. Voice rules: docs/WORLD_BIBLE.md (plain-spoken,
# warm, no fantasy-isms).

const WANDERER_GLB := preload("res://models/wanderer_v3.glb")
const DialogPanelScript = preload("res://scripts/ui/dialog_panel.gd")

func get_prompt_text() -> String:
	return "[E] Talk to Mara Linnet"

func get_prompt_color() -> Color:
	return Color(0.95, 0.85, 0.6)

func get_prompt_position() -> Vector3:
	return Vector3(0.0, 2.1, 0.0)

func _ready_interactable() -> void:
	var mesh := WANDERER_GLB.instantiate()
	mesh.position = Vector3.ZERO
	add_child(mesh)
	GlbFit.normalize_height(mesh, 1.7)

func interact(_player: Node) -> void:
	var game := get_tree().root.get_node_or_null("Game")
	var step := 0 if game == null else int(game.tutorial_step)
	var pages: Array
	if game != null and bool(game.get("summit_cleared")):
		pages = [
			"You charted the Summit. Say it plain — I want to hear it again.",
			"The first Hedgemother. Cartographers spent lifetimes pretending that nest wasn't real, and you inked the way in and walked back out.",
			"There'll be deeper hollows — there always are. But tonight the maps are yours, wayfinder. All of them.",
		]
	else:
		pages = _pages_for(step)
	var dlg := DialogPanelScript.new()
	dlg.open("Mara Linnet, the Wayfinder", pages)
	get_tree().current_scene.add_child(dlg)
	if game != null and step == 0:
		dlg.finished.connect(game.advance_tutorial)

func _pages_for(step: int) -> Array:
	match step:
		0:
			return [
				"New boots. Good — the yard could use a pair.",
				"I chart the hollows. Ink a place onto paper the right way and the Waystone will take you there — the chart decides what you find inside. Ore, bramble, worse things if you ink them in.",
				"Start small. Gather three wild herbs from the patches around the yard — the green shimmers, you can't miss them. Herbs make ink. Ink makes charts. Charts make the rest of your life interesting.",
			]
		1:
			return ["Three wild herbs — the shimmer-green patches around the yard. Crouch, pluck, done."]
		2:
			return ["Herbs go to ink at my table there. Three herbs to the pot. The table does the grinding; you do the pouring."]
		3:
			return ["Now inscribe a Snug. It's the smallest chart there is — a pocket cellar, no surprises. Every wayfinder's first."]
		4:
			return ["Socket it at the Waystone and step through. The chart is spent on the crossing — that's the cost of the craft.",
				"Mind the things that live in the ink. F looses an arrow; Space rolls you out of trouble."]
		5:
			return ["You're still here? The waystone on the far side won't find itself."]
		6:
			return [
				"Back, and in one piece. Feel that — the craft settles in with every crossing. That's the Wayfinder's craft.",
				"Try a Tier 1 next. It carries one affix slot — the roll can come up good or it can twin bad. Inks tilt the odds. That dance is the whole craft.",
			]
		_:
			return [
				"The hollows keep moving. That's why we keep charting.",
				"The fiercer things — the marked ones, with the glow about them — carry thorn essence. Slot one at my table and you can ink the Hedgemother's own den into a chart.",
				"Her trophies open deeper dens still: the Wallow, the Roost... and what the Roost's master carries opens the Summit. That's the chart every wayfinder dies wondering about.",
			]
