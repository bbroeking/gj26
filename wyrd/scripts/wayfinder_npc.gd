class_name WayfinderNpc
extends Interactable

# Wyrd — Mara Linnet, the Wayfinder. Tutorial anchor in the Chartmaker's
# Yard. Dialog pages key off Game.tutorial_step; her first conversation
# advances step 0 → 1. Voice rules: docs/WORLD_BIBLE.md (plain-spoken,
# warm, short sentences, no fantasy-isms).

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
		if not bool(game.seen_hints.get("summit_mara", false)):
			game.seen_hints["summit_mara"] = true
			pages = _pages_summit_first()
		else:
			pages = _pages_summit_repeat()
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
				"Start small. The herb patches around the yard have a shimmer about them — you can't miss it. Pick three. Herbs make ink. Ink makes charts. Charts make the rest of your life interesting.",
			]
		1:
			return [
				"The shimmer-green patches. Around the yard, between the stones.",
				"Three will do. Crouch into them — the plants won't bite.",
			]
		2:
			return [
				"There's my bench. The mixing pot glows gold when it's ready for herbs — drag three in and watch what happens.",
				"Most people expect it to smell worse. It doesn't. Chalk and morning rain, if you're curious.",
			]
		3:
			return [
				"Now you have ink. Now you make a chart.",
				"The bench has a base socket — set the Snug chart base there. The Snug is the smallest hollow I know; every wayfinder cuts their teeth on one.",
				"Take the finished chart from the result side. Don't crease it.",
			]
		4:
			return [
				"The Waystone is in the yard. Socket your chart into it and step through.",
				"The chart is spent on the crossing — that's the price of the craft. You get one use, then it's ink again.",
				"There are things in the hollow that will notice you. F looses an arrow. Space rolls you clear of trouble. Come back in one piece.",
			]
		5:
			return [
				"You're still here. The Waystone is right there.",
				"The chart's in your satchel. Socket it, step through. I'll still be here when you get back.",
			]
		6:
			return [
				"Back, and whole. That's a better result than some.",
				"The craft settles in with every crossing — you'll feel it. Steady hands, clear eye.",
				"Try a Tier 1 next. Set the base, then pour an ink into the round socket. Watch the odds shift on the result side before you commit.",
				"That's the whole dance: ink quantity tilts the odds; you decide how far to lean. Get comfortable with it.",
			]
		7:
			return [
				"Good. You're reading the affixes now.",
				"Gold tab leans lucky — better odds, lighter trouble. Red tab leans hard — richer haul, meaner hollow.",
				"There's no wrong answer. It depends what you need and how much you trust your boots.",
			]
		_:
			return [
				"The hollows keep moving. That's why we keep charting.",
				"The fiercer things — the marked ones with the glow — carry thorn essence. Bring a trophy to my table and you can ink a named den into a chart.",
				"The Hedgemother's den first. Her trophy opens the Wallow. The Wallow opens the Roost.",
				"What the Roost master carries — that opens the Summit. That's the chart every wayfinder dies wondering about. Go find out.",
			]

func _pages_summit_first() -> Array:
	return [
		"You're back. I've been watching the waystone since the Roost chart left your case.",
		"Say it out loud — the Summit. Most wayfinders spend a season just convincing themselves the chart is real.",
		"The Hedgemother. The Boar. The Wolf. The Queen's own nest. You inked every hollow on that chain and walked each one back.",
		"There are deeper hollows — the old charts hint at them. We don't have names for what keeps them yet. But the ink is yours. When you're ready, we start drawing again.",
		"Tonight: rest. The yard isn't going anywhere.",
	]

func _pages_summit_repeat() -> Array:
	return [
		"The hollows keep moving. When you're ready, we draw the next chart.",
	]
