extends CanvasLayer

# Autoloaded scene-transition authority. Every playable map crosses this seam,
# so the destination card is guaranteed for Town entry, Chart entry, return,
# network entry, and deeper layers instead of being hand-wired per doorway.

const MapLoadingScreen = preload("res://scripts/ui/map_loading_screen.gd")

var _screen: Control
var _busy := false


func _ready() -> void:
	# Destination scenes may immediately open a dialogue/debrief and pause the
	# offline tree. The persistent transition layer must still finish its fade
	# and release `_busy`, otherwise the player lands beneath a frozen card and
	# every following travel request is rejected.
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120
	_screen = MapLoadingScreen.new()
	_screen.name = "MapLoadingScreen"
	add_child(_screen)
	if OS.get_environment("WYRD_SHOT_DUNGEON_LOADING_PATH") != "":
		_debug_dungeon_preview.call_deferred()


func travel_to(scene_path: String) -> void:
	if _busy or scene_path == "":
		return
	_busy = true
	var game := get_node_or_null("/root/Game")
	await _screen.show_card(MapLoadingScreen.card_for(scene_path, game))
	_screen.set_progress(0.05)
	await get_tree().process_frame
	if game != null and game.has_method("prepare_map_layout"):
		var layout: Dictionary = game.prepare_map_layout(scene_path)
		if not layout.is_empty() and _screen.has_method("set_layout_summary"):
			_screen.set_layout_summary(layout)
	_screen.set_progress(0.32)
	var status := ResourceLoader.load_threaded_get_status(scene_path)
	if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		ResourceLoader.load_threaded_request(scene_path)
	status = ResourceLoader.load_threaded_get_status(scene_path)
	var progress: Array = []
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		status = ResourceLoader.load_threaded_get_status(scene_path, progress)
		if not progress.is_empty():
			_screen.set_progress(clampf(float(progress[0]), 0.05, 0.92))
		await get_tree().process_frame
	await _screen.finish_progress()
	var packed: PackedScene = null
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		packed = ResourceLoader.load_threaded_get(scene_path) as PackedScene
	if packed != null:
		get_tree().change_scene_to_packed(packed)
	else:
		get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await get_tree().process_frame
	await _screen.fade_out()
	_busy = false


func preview(scene_path: String, progress: float = 0.68) -> void:
	var game := get_node_or_null("/root/Game")
	await _screen.show_card(MapLoadingScreen.card_for(scene_path, game))
	_screen.set_progress(progress)


func _debug_dungeon_preview() -> void:
	var game := get_node_or_null("/root/Game")
	if game == null:
		return
	game.active_chart = {
		"template_id": "hollow", "tier": 2, "scope": "hollow",
		"layer": 1, "max_layers": 2, "seed": 18472,
		"affixes": [
			{"id": "bramble_bloom", "good": true},
			{"id": "frenzied", "good": false},
		],
	}
	await preview(game.DUNGEON_SCENE, 0.68)
	var layout: Dictionary = game.prepare_map_layout(game.DUNGEON_SCENE)
	_screen.set_layout_summary(layout)
	await get_tree().create_timer(0.7).timeout
	var image := get_viewport().get_texture().get_image()
	image.save_png(OS.get_environment("WYRD_SHOT_DUNGEON_LOADING_PATH"))
	get_tree().quit()
