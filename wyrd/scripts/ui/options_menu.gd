extends CanvasLayer

# Settings remain immediate and authoritative in Settings/Game. This page owns
# only their focused Field Journal presentation and closes one modal layer.

const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")
const FocusPointer = preload("res://scripts/ui/components/focus_pointer.gd")
const SystemFolio = preload("res://scripts/ui/components/system_folio.gd")

var _game: Node
var _folio: SystemFolio
var _volume_value: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 97
	_game = get_tree().root.get_node_or_null("Game")
	_build_backdrop()
	_build_folio()
	var pointer := FocusPointer.new()
	pointer.name = "MenuFocusPointer"
	add_child(pointer)


func _build_backdrop() -> void:
	var bg := ColorRect.new()
	bg.color = Tokens.SCRIM
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)


func _build_folio() -> void:
	_folio = SystemFolio.new()
	_folio.anchor_left = 0.5
	_folio.anchor_top = 0.5
	_folio.anchor_right = 0.5
	_folio.anchor_bottom = 0.5
	_folio.set_folio_size(Vector2(600.0, 500.0))
	_folio.setup("Options", "Sound and window.", "⚙")
	_folio.close_requested.connect(_close)
	add_child(_folio)

	var sound_heading := HBoxContainer.new()
	sound_heading.add_theme_constant_override("separation", Tokens.SPACE_3)
	_folio.body.add_child(sound_heading)
	var volume_title := Label.new()
	volume_title.text = "Master Volume"
	volume_title.theme_type_variation = &"SectionTitle"
	volume_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sound_heading.add_child(volume_title)
	_volume_value = Label.new()
	_volume_value.name = "VolumeValue"
	_volume_value.theme_type_variation = &"Numeric"
	_volume_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sound_heading.add_child(_volume_value)

	var slider := HSlider.new()
	slider.name = "MasterVolumeSlider"
	slider.theme_type_variation = &"SystemSlider"
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = Settings.master_volume
	slider.custom_minimum_size = Vector2(0.0, 56.0)
	slider.value_changed.connect(_set_volume)
	_folio.body.add_child(slider)
	_set_volume(slider.value)
	_folio.body.add_child(HSeparator.new())

	var mute := CheckBox.new()
	mute.name = "MuteCheckBox"
	mute.theme_type_variation = &"SystemCheckBox"
	mute.custom_minimum_size.y = 56.0
	mute.button_pressed = _game != null and bool(_game.muted)
	_set_check_copy(mute, "Mute all sound", "Muted", "Playing")
	mute.toggled.connect(func(on: bool) -> void:
		if _game != null and _game.has_method("set_muted"):
			_game.set_muted(on)
			if _game.has_method("save_now"):
				_game.save_now()
		_set_check_copy(mute, "Mute all sound", "Muted", "Playing"))
	_folio.body.add_child(mute)
	_folio.body.add_child(HSeparator.new())

	var fullscreen := CheckBox.new()
	fullscreen.name = "FullscreenCheckBox"
	fullscreen.theme_type_variation = &"SystemCheckBox"
	fullscreen.custom_minimum_size.y = 56.0
	fullscreen.button_pressed = Settings.fullscreen
	_set_check_copy(fullscreen, "Fullscreen", "On", "Off")
	fullscreen.toggled.connect(func(on: bool) -> void:
		Settings.set_fullscreen(on)
		_set_check_copy(fullscreen, "Fullscreen", "On", "Off"))
	_folio.body.add_child(fullscreen)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_folio.body.add_child(spacer)
	var back := Button.new()
	back.name = "BackButton"
	back.text = "Back"
	back.theme_type_variation = &"QuietButton"
	back.custom_minimum_size.y = 56.0
	back.pressed.connect(_close)
	_folio.body.add_child(back)
	_folio.add_footer_hint("←→ adjust  ·  Enter/A toggle  ·  Esc/B back")
	slider.grab_focus.call_deferred()


func _set_volume(value: float) -> void:
	Settings.set_master_volume(value)
	if _volume_value != null:
		_volume_value.text = "%d%%" % roundi(value * 100.0)


func _set_check_copy(check: CheckBox, label: String, on_text: String,
		off_text: String) -> void:
	check.text = label
	var state := check.get_node_or_null("StateLabel") as Label
	if state == null:
		state = Label.new()
		state.name = "StateLabel"
		state.theme_type_variation = &"Numeric"
		state.anchor_left = 0.7
		state.anchor_right = 1.0
		state.anchor_bottom = 1.0
		state.offset_right = -12.0
		state.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		state.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		state.mouse_filter = Control.MOUSE_FILTER_IGNORE
		check.add_child(state)
	state.text = on_text if check.button_pressed else off_text


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()


func _close() -> void:
	queue_free()
