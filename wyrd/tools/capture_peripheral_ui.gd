extends SceneTree

# Spec 59 deterministic visual-QA harness for small but high-impact overlays.
# It mounts the UI directly over title art so review does not depend on a
# dungeon layout, model imports, or player traversal.

var _capture_path := "/tmp/wyrd_peripheral_shrine.png"


func _initialize() -> void:
	_capture_path = OS.get_environment("WYRD_CAPTURE_PATH")
	if _capture_path == "":
		_capture_path = "/tmp/wyrd_peripheral_shrine.png"
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1366, 768)
	var game := root.get_node_or_null("Game")
	if game != null:
		game.persistence_enabled = false
		game.reset_to_defaults()
	var world := TextureRect.new()
	world.texture = load("res://assets/ui/menu/title_bg.webp")
	world.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	world.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	world.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(world)

	var modal: CanvasLayer = load("res://scripts/shrine_choice_modal.gd").new()
	root.add_child(modal)
	modal.setup([
		{"id": "vigor", "name": "Vigor of Bramblewood", "desc": "+20 Max HP"},
		{"id": "precision", "name": "Precision of the Glade", "desc": "+15% Crit Chance"},
		{"id": "channeling", "name": "Channeling of the Root", "desc": "+8 Focus/s regen"},
	])
	for _index in 6:
		await process_frame
	var image := root.get_texture().get_image()
	var error := image.save_png(_capture_path)
	paused = false
	if error != OK:
		push_error("Could not save %s (error %d)" % [_capture_path, error])
		quit(2)
		return
	print("PERIPHERAL CAPTURE: shrine -> %s" % _capture_path)
	quit(0)
