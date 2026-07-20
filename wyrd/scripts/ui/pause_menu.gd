extends CanvasLayer

# Offline pause authority remains here; SystemFolio owns only the shared Field
# Journal presentation. Nested Options closes back to this still-paused page.

const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")
const FocusPointer = preload("res://scripts/ui/components/focus_pointer.gd")
const SystemFolio = preload("res://scripts/ui/components/system_folio.gd")

var _game: Node
var _folio: SystemFolio


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 96
	_game = get_tree().root.get_node_or_null("Game")
	get_tree().paused = true
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
	_folio.set_folio_size(Vector2(440.0, 510.0 if _game != null and bool(_game.in_dungeon) else 460.0))
	_folio.setup("Paused", "The road waits.", "Ⅱ")
	_folio.close_requested.connect(_close)
	add_child(_folio)

	var prompt := Label.new()
	prompt.text = "What do you need?"
	prompt.theme_type_variation = &"SectionTitle"
	_folio.body.add_child(prompt)
	var rail := VBoxContainer.new()
	rail.name = "PauseActionRail"
	rail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rail.add_theme_constant_override("separation", 10)
	_folio.body.add_child(rail)
	var resume := _button(rail, "Resume", &"PrimaryButton", _close)
	_button(rail, "Options", &"QuietButton", func():
		var options: CanvasLayer = load("res://scripts/ui/options_menu.gd").new()
		add_child(options))
	_button(rail, "Share Feedback", &"QuietButton", func():
		var feedback: CanvasLayer = load("res://scripts/ui/feedback_menu.gd").new()
		add_child(feedback))
	if _game != null and bool(_game.in_dungeon):
		_button(rail, "Abandon Run", &"DestructiveButton", func():
			get_tree().paused = false
			if _game.has_method("return_to_town"):
				_game.return_to_town(_game.local_player(), true)
			queue_free())
	_button(rail, "Quit to Title", &"DestructiveButton", func():
		get_tree().paused = false
		get_tree().change_scene_to_file.call_deferred("res://scenes/Main.tscn")
		queue_free())
	_folio.add_footer_hint("↑↓ choose  ·  Enter/A  ·  Esc/B resume")
	resume.grab_focus.call_deferred()


func _button(parent: Container, text: String, variation: StringName,
		callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.theme_type_variation = variation
	button.custom_minimum_size = Vector2(0.0, 56.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()


func _close() -> void:
	get_tree().paused = false
	queue_free()
