extends SceneTree

class EncounterStub extends Node:
	func press(_verb: StringName, _subject_id: StringName) -> Dictionary:
		return {"accepted": false}

	func view() -> Dictionary:
		return {"settled": false}


func _initialize() -> void:
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
	var encounter := EncounterStub.new()
	root.add_child(encounter)
	var panel: CanvasLayer = load("res://scripts/ui/road_naming_panel.gd").new()
	panel.configure(encounter)
	root.add_child(panel)
	for _index in 5:
		await process_frame
	var path := OS.get_environment("WYRD_CAPTURE_PATH")
	if path == "":
		path = "/tmp/wyrd_road_naming.png"
	var image := root.get_texture().get_image()
	var error := image.save_png(path)
	paused = false
	if error != OK:
		push_error("Could not save %s (error %d)" % [path, error])
		quit(2)
		return
	print("ROAD NAMING CAPTURE: %s" % path)
	quit(0)
