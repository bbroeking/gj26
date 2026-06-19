extends CanvasLayer

# B5 — the offline Pause menu. Esc opens it when playing solo (in co-op, Esc
# keeps the Lantern, since the world can't freeze for everyone). Pauses the tree
# while open. Resume / Options / Abandon run (dungeon only) / Quit to title.

var _game: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # stay live while the tree is paused
	layer = 96
	_game = get_tree().root.get_node_or_null("Game")
	get_tree().paused = true

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var panel := Panel.new()
	WyrdUi.style_panel(panel)
	panel.anchor_left = 0.5; panel.anchor_top = 0.5
	panel.anchor_right = 0.5; panel.anchor_bottom = 0.5
	panel.offset_left = -180; panel.offset_top = -170
	panel.offset_right = 180; panel.offset_bottom = 170
	add_child(panel)

	var title := Label.new()
	title.text = "Paused"
	WyrdUi.style_title(title)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_left = 0.0; title.anchor_right = 1.0
	title.offset_top = 26
	panel.add_child(title)

	var col := VBoxContainer.new()
	col.anchor_left = 0.0; col.anchor_right = 1.0
	col.offset_left = 36; col.offset_top = 80; col.offset_right = -36
	col.add_theme_constant_override("separation", 12)
	panel.add_child(col)

	_btn(col, "Resume", _close)
	_btn(col, "Options", func():
		var o: CanvasLayer = load("res://scripts/ui/options_menu.gd").new()
		add_child(o))
	if _game != null and bool(_game.in_dungeon):
		_btn(col, "Abandon run", func():
			get_tree().paused = false
			if _game.has_method("return_to_town"):
				_game.return_to_town(_game.local_player(), true)
			queue_free())
	_btn(col, "Quit to title", func():
		get_tree().paused = false
		get_tree().change_scene_to_file.call_deferred("res://scenes/Main.tscn")
		queue_free())

func _btn(col: VBoxContainer, label: String, cb: Callable) -> void:
	var b := Button.new()
	WyrdUi.style_kit_button(b)
	b.text = label
	b.custom_minimum_size = Vector2(0, 42)
	b.pressed.connect(cb)
	col.add_child(b)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

func _close() -> void:
	get_tree().paused = false
	queue_free()
