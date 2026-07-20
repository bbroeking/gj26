class_name WayfinderNpc
extends Interactable

# Wyrd — Mara Linnet, the Wayfinder. Tutorial anchor in the Chartmaker's
# Yard. Dialog pages key off Game.tutorial_step; her first conversation
# advances step 0 → 1. Voice rules: docs/WORLD_BIBLE.md (plain-spoken,
# warm, short sentences, no fantasy-isms).

const WANDERER_GLB := preload("res://models/npc_mara_linnet_v1_rigged.glb")
const WANDERER_WALK_GLB := preload("res://models/npc_mara_linnet_v1_walk_anim.glb")
const AnimDriverScript := preload("res://scripts/anim_driver.gd")
const DialogPanelScript = preload("res://scripts/ui/dialog_panel.gd")
const MARA_PORTRAIT := preload("res://assets/ui/portraits/mara_linnet_v2.webp")

func get_prompt_text() -> String:
	return "[E] Talk to Mara Linnet"

func get_prompt_color() -> Color:
	return Color(0.95, 0.85, 0.6)

func get_prompt_position() -> Vector3:
	return Vector3(0.0, 2.1, 0.0)

func _ready_interactable() -> void:
	add_to_group("tutorial_mara")
	var mesh := WANDERER_GLB.instantiate()
	mesh.position = Vector3.ZERO
	add_child(mesh)
	# Meshy rig exports have unreliable skinned AABBs; this authored model is
	# 1.627 m tall, so use its measured production scale instead.
	mesh.scale = Vector3.ONE * (1.7 / 1.627)
	GlbFit.unmetal(mesh)
	GlbFit.add_ink_outline(mesh)
	AnimDriverScript.play_sidecar_pose(mesh, WANDERER_WALK_GLB, "walk", 0.5, 0.0)

func interact(player: Node) -> void:
	var game := get_tree().root.get_node_or_null("Game")
	if game != null and game.has_method("record_onboarding_event"):
		game.record_onboarding_event("first_mara_conversation")
	var step := 0 if game == null else int(game.tutorial_step)
	var pages: Array
	var choices: Array = []
	var choosing_first_road := false
	var closes_first_chapter := false
	# Face the person speaking; the dialog portrait carries expression, while the
	# world model only needs the clear social read that Mara noticed them.
	if player is Node3D:
		var target := (player as Node3D).global_position
		target.y = global_position.y
		look_at(target, Vector3.UP, true)
	if game != null and game.has_method("first_road_active") \
			and bool(game.first_road_active()) \
			and String(game.seen_hints.get("first_road_profile", "")) == "":
		choosing_first_road = true
		choices = [
			"Kind Road — frail foes · few elites · lush forage",
			"Bold Road — hardy foes · an elite sign · hidden treasure",
		]
		pages = [
			"New boots. Good. A first road should tell us what sort of wayfinder wears them.",
			"The rooms will still move when the Chart opens. You are choosing what the ink makes common.",
			"Kind is not empty, and bold is not foolish. Choose the temper you want to walk.",
		]
	elif game != null and bool(game.seen_hints.get("tier1_completed", false)) \
			and not bool(game.seen_hints.get("third_chart_choice_seen", false)):
		closes_first_chapter = true
		choices = ["Seek strength", "Seek materials", "Follow the mark"]
		if game.has_second_hand_clue("inked_scrap"):
			game.seen_hints["second_hand_mara_inked"] = true
			pages = _pages_second_hand_inked()
		elif game.has_second_hand_clue("far_waystone"):
			game.seen_hints["second_hand_mara_far"] = true
			pages = _pages_second_hand_far()
		else:
			pages = _pages_first_chapter_close()
		game.save_now()
	elif game != null and game.has_second_hand_clue("inked_scrap") \
			and not bool(game.seen_hints.get("second_hand_mara_inked", false)):
		game.seen_hints["second_hand_mara_inked"] = true
		game.save_now()
		pages = _pages_second_hand_inked()
	elif game != null and game.has_second_hand_clue("far_waystone") \
			and not bool(game.seen_hints.get("second_hand_mara_far", false)):
		game.seen_hints["second_hand_mara_far"] = true
		game.save_now()
		pages = _pages_second_hand_far()
	elif game != null and bool(game.get("summit_cleared")):
		if not bool(game.seen_hints.get("summit_mara", false)):
			game.seen_hints["summit_mara"] = true
			pages = _pages_summit_first()
		else:
			pages = _pages_summit_repeat()
	else:
		pages = _pages_for(step)
	var dlg := DialogPanelScript.new()
	dlg.open("Mara Linnet, the Wayfinder", pages, MARA_PORTRAIT, choices)
	get_tree().current_scene.add_child(dlg)
	if game != null and step == 0:
		if choosing_first_road:
			dlg.choice_selected.connect(game.choose_first_road)
		else:
			dlg.finished.connect(game.advance_tutorial)
	if game != null and closes_first_chapter:
		dlg.choice_selected.connect(game.choose_onboarding_intention)
		dlg.finished.connect(game.dismiss_onboarding_intention)

func _pages_second_hand_far() -> Array:
	return [
		"A hooked hand, beside the far stone? No. I didn't put it there.",
		"A new Chart should not carry an old mark. What will you seek next?",
	]

func _pages_second_hand_inked() -> Array:
	return [
		"Your ink? Let me see. Same hand. Fresh line.",
		"Something answered the Chart. Or someone did. What will you seek next?",
	]

func _pages_first_chapter_close() -> Array:
	return [
		"You came home with the road still in your eyes. That's a beginning.",
		"The next Chart is yours to choose. What will you seek?",
	]

func _pages_for(step: int) -> Array:
	match step:
		0:
			return [
				"New boots. Good. The yard could use a pair.",
				"Bring me three wild herbs. We'll make a road small enough to learn on.",
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
				"Set the Practice Leaf in the middle, the Hedge Sprig above it, and your Hedge Ink in the first pot. Three small pieces; one kind road.",
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
				"I've set out a Field Parchment, a Loop Cord, and another Hedge Sprig. The left-hand Binding cell is awake now.",
				"Lay the same green heading over the broader page, then loop the cord beside it. Add an ink if you want to lean the road. Watch the odds shift before you commit.",
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
