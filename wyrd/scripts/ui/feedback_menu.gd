extends CanvasLayer

# A deliberately small, player-initiated feedback seam. The report is composed
# in-game, copied to the clipboard, then handed to GitHub in the browser. This
# avoids silently collecting player data while still delivering an actionable,
# context-rich report to the project's existing issue tracker.

const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")
const FocusPointer = preload("res://scripts/ui/components/focus_pointer.gd")
const SystemFolio = preload("res://scripts/ui/components/system_folio.gd")

const ISSUE_URL := "https://github.com/bbroeking/gj26/issues/new"
const MAX_MESSAGE_LENGTH := 700
const CATEGORIES := [
	{"label": "Something broke", "tag": "Bug"},
	{"label": "Something felt confusing", "tag": "Confusing"},
	{"label": "I have an idea", "tag": "Idea"},
	{"label": "Something felt great", "tag": "Highlight"},
]

var _folio: SystemFolio
var _category: OptionButton
var _message: TextEdit
var _diagnostics: CheckBox
var _send: Button
var _count: Label
var _status: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 98
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
	_folio.set_folio_size(Vector2(680.0, 600.0))
	_folio.setup("Share Feedback", "A short note can make the next journey better.", "✎")
	_folio.close_requested.connect(_close)
	add_child(_folio)
	_folio.body.add_theme_constant_override("separation", Tokens.SPACE_2)

	var intro := Label.new()
	intro.text = "What would you like us to know?"
	intro.theme_type_variation = &"SectionTitle"
	_folio.body.add_child(intro)

	_category = OptionButton.new()
	_category.name = "FeedbackCategory"
	_category.custom_minimum_size.y = Tokens.HIT_TARGET
	_category.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for item in CATEGORIES:
		_category.add_item(String(item.label))
	_category.select(0)
	_folio.body.add_child(_category)

	_message = TextEdit.new()
	_message.name = "FeedbackMessage"
	_message.theme_type_variation = &"SystemTextEdit"
	_message.custom_minimum_size = Vector2(0.0, 110.0)
	_message.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_message.placeholder_text = "Tell us what happened, what you expected, or what you would love to see."
	_message.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_message.text_changed.connect(_on_message_changed)
	_folio.body.add_child(_message)

	var detail_row := HBoxContainer.new()
	detail_row.add_theme_constant_override("separation", Tokens.SPACE_3)
	_folio.body.add_child(detail_row)
	var detail := Label.new()
	detail.text = "Specific moments help most. Please don't include personal information."
	detail.theme_type_variation = &"Caption"
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_row.add_child(detail)
	_count = Label.new()
	_count.name = "FeedbackCharacterCount"
	_count.theme_type_variation = &"Caption"
	_count.text = "0 / %d" % MAX_MESSAGE_LENGTH
	detail_row.add_child(_count)

	_diagnostics = CheckBox.new()
	_diagnostics.name = "IncludeDiagnostics"
	_diagnostics.theme_type_variation = &"SystemCheckBox"
	_diagnostics.custom_minimum_size.y = Tokens.HIT_TARGET
	_diagnostics.text = "Include game version, current scene, and platform"
	_diagnostics.tooltip_text = "Helps us reproduce issues. Your save and personal files are never included."
	_diagnostics.button_pressed = true
	_folio.body.add_child(_diagnostics)

	var privacy := Label.new()
	privacy.text = "Review & Send opens a prefilled GitHub issue. Your note is also copied in case the page cannot open."
	privacy.theme_type_variation = &"Caption"
	privacy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_folio.body.add_child(privacy)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", Tokens.SPACE_3)
	_folio.body.add_child(actions)
	var cancel := Button.new()
	cancel.name = "CancelButton"
	cancel.text = "Not Now"
	cancel.theme_type_variation = &"QuietButton"
	cancel.custom_minimum_size = Vector2(150.0, 52.0)
	cancel.pressed.connect(_close)
	actions.add_child(cancel)
	_send = Button.new()
	_send.name = "SendFeedbackButton"
	_send.text = "Review & Send"
	_send.theme_type_variation = &"PrimaryButton"
	_send.custom_minimum_size = Vector2(210.0, 52.0)
	_send.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_send.disabled = true
	_send.pressed.connect(_send_feedback)
	actions.add_child(_send)

	_status = Label.new()
	_status.name = "FeedbackStatus"
	_status.theme_type_variation = &"Caption"
	_status.visible = false
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_folio.body.add_child(_status)
	_folio.add_footer_hint("Tab move  ·  Enter/A choose  ·  Esc/B back")
	_category.grab_focus.call_deferred()


func _on_message_changed() -> void:
	if _message.text.length() > MAX_MESSAGE_LENGTH:
		var caret_line := _message.get_caret_line()
		var caret_column := _message.get_caret_column()
		_message.text = _message.text.left(MAX_MESSAGE_LENGTH)
		_message.set_caret_line(mini(caret_line, _message.get_line_count() - 1))
		_message.set_caret_column(caret_column)
	_count.text = "%d / %d" % [_message.text.length(), MAX_MESSAGE_LENGTH]
	_send.disabled = _message.text.strip_edges().is_empty()
	_status.visible = false


func build_issue_url() -> String:
	var message := _message.text.strip_edges() if _message != null else ""
	var category_index := _category.selected if _category != null else 0
	category_index = clampi(category_index, 0, CATEGORIES.size() - 1)
	var tag := String(CATEGORIES[category_index].tag)
	var first_line := message.split("\n", false)[0] if not message.is_empty() else "Player note"
	first_line = first_line.replace("\r", " ").replace("\t", " ").strip_edges()
	var title := "[%s] %s" % [tag, first_line.left(72)]
	var body := "## Player note\n\n%s" % message
	if _diagnostics != null and _diagnostics.button_pressed:
		body += "\n\n## Game context\n\n%s" % _diagnostic_block()
	body += "\n\n_This report was composed from Wayfinder's in-game feedback journal._"
	return "%s?title=%s&body=%s" % [ISSUE_URL, title.uri_encode(), body.uri_encode()]


func _diagnostic_block() -> String:
	var scene_name := "Unknown"
	if get_tree() != null and get_tree().current_scene != null:
		scene_name = get_tree().current_scene.name
	var game := get_tree().root.get_node_or_null("Game") if get_tree() != null else null
	var journey := "Dungeon" if game != null and bool(game.in_dungeon) else "Bramblewood"
	var viewport_size := get_viewport().get_visible_rect().size if get_viewport() != null else Vector2.ZERO
	return "- Version: %s\n- Scene: %s (%s)\n- Platform: %s\n- Display: %s\n- Window: %dx%d" % [
		String(ProjectSettings.get_setting("application/config/version", "unknown")),
		scene_name,
		journey,
		OS.get_name(),
		DisplayServer.get_name(),
		roundi(viewport_size.x),
		roundi(viewport_size.y),
	]


func _send_feedback() -> void:
	if _message.text.strip_edges().is_empty():
		return
	var url := build_issue_url()
	var report_copy := _message.text.strip_edges()
	if _diagnostics.button_pressed:
		report_copy += "\n\nGame context\n" + _diagnostic_block()
	DisplayServer.clipboard_set(report_copy)
	var error := OS.shell_open(url)
	_status.visible = true
	if error == OK:
		_status.text = "Your note is copied. Finish sending it in the browser window. Thank you."
		_status.add_theme_color_override("font_color", Tokens.MOSS)
	else:
		_status.text = "The page could not open, but your note is copied and ready to paste."
		_status.add_theme_color_override("font_color", Tokens.TERRACOTTA)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()


func _close() -> void:
	queue_free()
