extends SceneTree

# Spec 59 deterministic visual-QA harness for startup/system surfaces. Main
# menu owns its own WYRD_SHOT_PATH route; these modal routes mount directly so
# visual review is independent of Town and its imported world models.

const ROUTES := ["pause", "pause_dungeon", "options", "credits"]

var _route := "pause"
var _capture_path := "/tmp/wyrd_system_pause.png"


func _initialize() -> void:
	_route = OS.get_environment("WYRD_SYSTEM_CAPTURE")
	if _route == "":
		_route = "pause"
	_capture_path = OS.get_environment("WYRD_CAPTURE_PATH")
	if _capture_path == "":
		_capture_path = "/tmp/wyrd_system_%s.png" % _route
	call_deferred("_run")


func _run() -> void:
	if not ROUTES.has(_route):
		push_error("Unknown system capture route: %s" % _route)
		quit(2)
		return
	root.size = Vector2i(1366, 768)
	var game := root.get_node_or_null("Game")
	if game != null:
		game.persistence_enabled = false
		game.reset_to_defaults()
		game.tutorial_step = 7
		game.in_dungeon = _route == "pause_dungeon"

	if _route == "credits":
		var title_art := TextureRect.new()
		title_art.texture = load("res://assets/ui/menu/title_bg.webp")
		title_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		title_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		title_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(title_art)
	else:
		var world := ColorRect.new()
		world.color = Color("4b633f")
		world.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(world)
	var path: String = {
		"pause": "res://scripts/ui/pause_menu.gd",
		"pause_dungeon": "res://scripts/ui/pause_menu.gd",
		"options": "res://scripts/ui/options_menu.gd",
		"credits": "res://scripts/ui/credits_menu.gd",
	}[_route]
	var panel: Node = (load(path) as Script).new()
	root.add_child(panel)
	await _frames(5)
	await _frames(3)
	var image := root.get_texture().get_image()
	var error := image.save_png(_capture_path)
	paused = false
	if error != OK:
		push_error("Could not save %s (error %d)" % [_capture_path, error])
		quit(2)
		return
	print("SYSTEM CAPTURE: %s -> %s" % [_route, _capture_path])
	quit(0)


func _frames(count: int) -> void:
	for _index in count:
		await process_frame
