extends CanvasLayer

# B4 — the Options panel: master volume, mute, fullscreen. Backed by the
# Settings autoload (persists + applies). Opened from the title and the pause
# menu. Esc closes.

var _game: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 97
	_game = get_tree().root.get_node_or_null("Game")
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var panel := Panel.new()
	WyrdUi.style_panel(panel)
	panel.anchor_left = 0.5; panel.anchor_top = 0.5
	panel.anchor_right = 0.5; panel.anchor_bottom = 0.5
	panel.offset_left = -240; panel.offset_top = -190
	panel.offset_right = 240; panel.offset_bottom = 190
	add_child(panel)

	var title := Label.new()
	title.text = "Options"
	WyrdUi.style_title(title)
	title.position = Vector2(40, 28)
	panel.add_child(title)
	var hint := Label.new()
	hint.text = "Esc — close"
	WyrdUi.style_dim(hint)
	hint.anchor_left = 1.0; hint.anchor_right = 1.0
	hint.offset_left = -120; hint.offset_top = 30
	panel.add_child(hint)

	var col := VBoxContainer.new()
	col.anchor_right = 1.0
	col.offset_left = 40; col.offset_top = 84; col.offset_right = -40
	col.add_theme_constant_override("separation", 16)
	panel.add_child(col)

	# Master volume.
	var vlabel := Label.new()
	vlabel.text = "Master volume"
	WyrdUi.style_body(vlabel, 15)
	col.add_child(vlabel)
	var slider := HSlider.new()
	slider.min_value = 0.0; slider.max_value = 1.0; slider.step = 0.05
	slider.value = Settings.master_volume
	slider.custom_minimum_size = Vector2(0, 24)
	slider.value_changed.connect(func(v: float): Settings.set_master_volume(v))
	col.add_child(slider)

	# Mute — owned by game.gd (F10 + the save), so route through set_muted.
	var mute := CheckBox.new()
	mute.text = "  Mute all sound"
	_style_check(mute)
	mute.button_pressed = _game != null and bool(_game.muted)
	mute.toggled.connect(func(on: bool):
		if _game != null and _game.has_method("set_muted"):
			_game.set_muted(on)
			if _game.has_method("save_now"):
				_game.save_now())
	col.add_child(mute)

	# Fullscreen.
	var fs := CheckBox.new()
	fs.text = "  Fullscreen"
	_style_check(fs)
	fs.button_pressed = Settings.fullscreen
	fs.toggled.connect(func(on: bool): Settings.set_fullscreen(on))
	col.add_child(fs)

	var close := Button.new()
	WyrdUi.style_kit_button(close)
	close.text = "Close"
	close.custom_minimum_size = Vector2(0, 42)
	close.pressed.connect(_close)
	col.add_child(close)

func _style_check(c: CheckBox) -> void:
	var f := WyrdUi.font_body()
	if f != null:
		c.add_theme_font_override("font", f)
	c.add_theme_font_size_override("font_size", 15)
	c.add_theme_color_override("font_color", Color(0.20, 0.15, 0.11))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

func _close() -> void:
	queue_free()
