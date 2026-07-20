extends SceneTree

# Direct story-caption capture. The tiny rig implements only the camera seam
# MicroCutscene owns, keeping this visual route independent of Town models.

class CaptureRig extends Node:
	var frame := {"focus": Vector3.ZERO, "yaw": 0.0, "pitch": 38.0, "zoom": 16.5}

	func cinematic_frame() -> Dictionary:
		return frame.duplicate(true)

	func begin_cinematic() -> void:
		pass

	func apply_cinematic_frame(next: Dictionary) -> void:
		frame = next.duplicate(true)

	func end_cinematic() -> void:
		pass


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
	var rig := CaptureRig.new()
	root.add_child(rig)
	var vignette: CanvasLayer = load("res://scripts/ui/micro_cutscene.gd").new()
	root.add_child(vignette)
	vignette.play(rig, [{
		"focus": Vector3.ZERO, "yaw": 0.0, "pitch": 35.0, "zoom": 15.0,
		"duration": 60.0, "caption": "Bramblewood begins.",
	}])
	for _index in 5:
		await process_frame
	var path := OS.get_environment("WYRD_CAPTURE_PATH")
	if path == "":
		path = "/tmp/wyrd_peripheral_vignette.png"
	var image := root.get_texture().get_image()
	var error := image.save_png(path)
	paused = false
	if error != OK:
		push_error("Could not save %s (error %d)" % [path, error])
		quit(2)
		return
	print("VIGNETTE CAPTURE: %s" % path)
	quit(0)
