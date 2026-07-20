extends SceneTree

# D8 Slice 2 — production road-naming modal contract. Campaign durability and
# encounter authority have separate suites; this mounts the actual CanvasLayer
# so its three authored inputs, blocking behavior, retry copy, and modal
# accounting cannot regress behind direct method-only tests.

const RoadNamingPanel := preload("res://scripts/ui/road_naming_panel.gd")

var passed := 0
var failed := 0


class EncounterStub extends Node:
	var presses: Array = []
	var settle_next := false
	var settled := false

	func press(verb: StringName, subject_id: StringName) -> Dictionary:
		presses.append({"verb": String(verb), "subject_id": String(subject_id)})
		if settle_next:
			settled = true
		return {"accepted": settle_next}

	func view() -> Dictionary:
		return {"settled": settled}


func _initialize() -> void:
	call_deferred("_run")


func _check(label: String, ok: bool, detail = "") -> void:
	if ok:
		passed += 1
		print("  ✓ %s" % label)
	else:
		failed += 1
		print("  ✗ %s %s" % [label, str(detail)])


func _run() -> void:
	print("--- Road naming production modal ---")
	var game := root.get_node_or_null("Game")
	if game == null:
		_check("Game autoload is present", false)
		quit(1)
		return
	game.persistence_enabled = false
	game.modal_count = 0
	paused = false
	var scene := Node.new()
	scene.name = "RoadNamingPanelTestScene"
	root.add_child(scene)
	current_scene = scene
	var encounter := EncounterStub.new()
	scene.add_child(encounter)
	var panel: CanvasLayer = RoadNamingPanel.new()
	panel.name = "RoadNamingPanel"
	panel.configure(encounter)
	scene.add_child(panel)
	await process_frame

	var labels: Array = []
	var choice_buttons: Array[Button] = []
	for node in panel.find_children("RoadChoice_*", "Button", true, false):
		labels.append(String((node as Button).text))
		choice_buttons.append(node as Button)
		# Choice-card labels are real children, so the Button's own text stays
		# empty. Read the stable authored name from its id for this legacy check.
	labels = choice_buttons.map(func(button: Button):
		return button.name.trim_prefix("RoadChoice_").replace("_", " ").capitalize())
	_check("modal presents exactly the three authored cosmetic road names",
		labels == ["Lantern Path", "Mended Way", "Open Footpath"], labels)
	var shell := panel.find_child("SystemShell", true, false) as Control
	var close := panel.find_child("CloseButton", true, false) as Button
	var card_anatomy := choice_buttons.size() == 3
	for button in choice_buttons:
		card_anatomy = card_anatomy \
			and button.theme_type_variation == &"ChoiceCardButton" \
			and button.find_child("RoadChoiceIcon", true, false) is TextureRect \
			and (button.find_child("RoadChoiceIcon", true, false) as TextureRect).texture != null
	_check("naming uses the shared painterly choice-card folio",
		shell != null and close != null and not close.visible and card_anatomy)
	_check("the first authored road owns keyboard/controller focus",
		not choice_buttons.is_empty() and root.gui_get_focus_owner() == choice_buttons[0])
	_check("opening the blocking modal accounts once and pauses offline play",
		int(game.modal_count) == 1 and paused)

	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	panel._unhandled_input(escape)
	_check("Escape cannot dismiss the irreversible naming choice",
		is_instance_valid(panel) and not panel.is_queued_for_deletion())

	panel._choose("lantern_path")
	_check("a failed durable attempt stays open with retry guidance",
		is_instance_valid(panel) and not panel.is_queued_for_deletion()
			and String(panel._status.text) == "The road will not take that name yet."
			and encounter.presses == [{"verb": "name", "subject_id": "lantern_path"}],
		{"presses": encounter.presses, "status": panel._status.text})

	encounter.settle_next = true
	panel._choose("lantern_path")
	await process_frame
	_check("only a settled read model closes and balances modal accounting",
		not is_instance_valid(panel) and int(game.modal_count) == 0 and not paused
			and encounter.presses.size() == 2)

	current_scene = null
	scene.queue_free()
	await process_frame
	print("--- %d passed, %d failed ---" % [passed, failed])
	quit(1 if failed > 0 else 0)
