extends SceneTree

# Spec 59 compact system-family gate: shared journal shell, safe geometry,
# semantic controls, nested pause/options ownership, and readable settings.

const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append(message)
		push_error("FAIL: %s" % message)


func _frames(count := 4) -> void:
	for _index in count:
		await process_frame


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game := root.get_node_or_null("Game")
	if game != null:
		game.persistence_enabled = false
		game.reset_to_defaults()
		game.in_dungeon = false

	var pause: CanvasLayer = load("res://scripts/ui/pause_menu.gd").new()
	root.add_child(pause)
	await _frames()
	var pause_shell := pause.find_child("SystemShell", true, false) as Control
	_check(pause_shell != null, "Pause uses the shared SystemFolio shell")
	if pause_shell != null:
		var rect := pause_shell.get_global_rect()
		_check(rect.position.x >= Tokens.SAFE_GUTTER and rect.position.y >= Tokens.SAFE_GUTTER \
				and rect.end.x <= 1280.0 - Tokens.SAFE_GUTTER \
				and rect.end.y <= 720.0 - Tokens.SAFE_GUTTER,
			"Pause keeps the 24px safe gutter at the minimum resolution")
	var pause_buttons := pause.find_children("*", "Button", true, false)
	var pause_targets_ok := true
	for candidate in pause_buttons:
		var button := candidate as Button
		pause_targets_ok = pause_targets_ok and maxf(button.size.y,
			button.custom_minimum_size.y) >= Tokens.HIT_TARGET
	_check(pause_targets_ok, "every Pause action meets the 48px target floor")
	_check(root.gui_get_focus_owner() != null and pause.is_ancestor_of(root.gui_get_focus_owner()),
		"Pause assigns visible keyboard/controller focus")
	var options_button: Button = null
	for candidate in pause_buttons:
		if (candidate as Button).text == "Options":
			options_button = candidate as Button
			break
	_check(options_button != null, "Pause exposes Options as a semantic Button")
	if options_button != null:
		options_button.pressed.emit()
	await _frames()
	var options := pause.find_child("SystemShell", true, false)
	var option_layers: Array[CanvasLayer] = []
	for child in pause.get_children():
		if child is CanvasLayer:
			option_layers.append(child as CanvasLayer)
	_check(not option_layers.is_empty(), "Options opens as one nested modal layer")
	var options_layer := option_layers[0] if not option_layers.is_empty() else null
	var slider := options_layer.find_child("MasterVolumeSlider", true, false) as HSlider \
		if options_layer != null else null
	var mute := options_layer.find_child("MuteCheckBox", true, false) as CheckBox \
		if options_layer != null else null
	var fullscreen := options_layer.find_child("FullscreenCheckBox", true, false) as CheckBox \
		if options_layer != null else null
	_check(slider != null and slider.theme_type_variation == &"SystemSlider" \
			and slider.custom_minimum_size.y >= Tokens.HIT_TARGET,
		"Options uses the themed visible volume slider")
	_check(mute != null and fullscreen != null \
			and mute.theme_type_variation == &"SystemCheckBox" \
			and fullscreen.theme_type_variation == &"SystemCheckBox" \
			and mute.find_child("StateLabel", true, false) is Label \
			and fullscreen.find_child("StateLabel", true, false) is Label,
		"Options check rows expose written Muted/Playing and On/Off state")
	_check(paused, "opening Options from Pause keeps the world paused")
	if options_layer != null:
		options_layer.call("_close")
	await _frames()
	_check(paused and not pause.is_queued_for_deletion(),
		"closing Options unwinds one layer and preserves Pause")
	var feedback_button: Button = null
	for candidate in pause.find_children("*", "Button", true, false):
		if (candidate as Button).text == "Share Feedback":
			feedback_button = candidate as Button
			break
	_check(feedback_button != null, "Pause keeps player feedback one action away")
	if feedback_button != null:
		feedback_button.pressed.emit()
	await _frames()
	var feedback_layer: CanvasLayer = null
	for child in pause.get_children():
		if child is CanvasLayer:
			feedback_layer = child as CanvasLayer
			break
	var feedback_message := feedback_layer.find_child("FeedbackMessage", true, false) as TextEdit \
		if feedback_layer != null else null
	var feedback_category := feedback_layer.find_child("FeedbackCategory", true, false) as OptionButton \
		if feedback_layer != null else null
	var feedback_diagnostics := feedback_layer.find_child("IncludeDiagnostics", true, false) as CheckBox \
		if feedback_layer != null else null
	var feedback_send := feedback_layer.find_child("SendFeedbackButton", true, false) as Button \
		if feedback_layer != null else null
	var feedback_shell := feedback_layer.find_child("SystemShell", true, false) as Control \
		if feedback_layer != null else null
	if feedback_shell != null:
		var feedback_rect := feedback_shell.get_global_rect()
		_check(feedback_rect.position.x >= Tokens.SAFE_GUTTER \
				and feedback_rect.position.y >= Tokens.SAFE_GUTTER \
				and feedback_rect.end.x <= 1280.0 - Tokens.SAFE_GUTTER \
				and feedback_rect.end.y <= 720.0 - Tokens.SAFE_GUTTER,
			"Feedback composer keeps the 24px safe gutter at the minimum resolution")
	_check(feedback_message != null and feedback_category != null \
			and feedback_category.item_count == 4,
		"Feedback journal accepts a note and bug, confusion, idea, or highlight category")
	_check(feedback_diagnostics != null and feedback_diagnostics.button_pressed,
		"Feedback offers explicit, removable reproduction context")
	_check(feedback_send != null and feedback_send.disabled,
		"Feedback cannot hand off an empty report")
	if feedback_message != null:
		feedback_message.text = "The chart table did not open."
		feedback_message.text_changed.emit()
	_check(feedback_send != null and not feedback_send.disabled,
		"Writing a note enables the clear Review & Send action")
	var issue_url := String(feedback_layer.call("build_issue_url")) \
		if feedback_layer != null else ""
	_check(issue_url.begins_with("https://github.com/bbroeking/gj26/issues/new?") \
			and issue_url.contains("The%20chart%20table%20did%20not%20open") \
			and issue_url.contains("Version%3A"),
		"Feedback handoff pre-fills the note and non-save diagnostics")
	if feedback_diagnostics != null:
		feedback_diagnostics.button_pressed = false
	var private_issue_url := String(feedback_layer.call("build_issue_url")) \
		if feedback_layer != null else ""
	_check(not private_issue_url.contains("Game%20context") \
			and not private_issue_url.contains("Version%3A"),
		"Players can remove all automatic context before handoff")
	_check(paused, "opening Feedback from Pause keeps the world paused")
	if feedback_layer != null:
		feedback_layer.call("_close")
	await _frames()
	pause.call("_close")
	await _frames()
	_check(not paused, "closing Pause releases offline pause ownership")

	var credits: CanvasLayer = load("res://scripts/ui/credits_menu.gd").new()
	root.add_child(credits)
	await _frames()
	var credits_shell := credits.find_child("SystemShell", true, false) as Control
	var credits_scroll := credits.find_child("CreditsScroll", true, false) as ScrollContainer
	var credits_reader := credits.find_child("CreditsReader", true, false) as VBoxContainer
	var credits_back := credits.find_child("BackButton", true, false) as Button
	_check(credits_shell != null and credits_scroll != null and credits_reader != null,
		"Credits uses the shared bounded folio with a future-safe scrolling reader")
	if credits_shell != null:
		var credits_rect := credits_shell.get_global_rect()
		_check(credits_rect.position.x >= Tokens.SAFE_GUTTER \
				and credits_rect.position.y >= Tokens.SAFE_GUTTER \
				and credits_rect.end.x <= 1280.0 - Tokens.SAFE_GUTTER \
				and credits_rect.end.y <= 720.0 - Tokens.SAFE_GUTTER,
			"Credits keeps the 24px safe gutter at the minimum resolution")
	var credit_lines: Array[String] = []
	if credits_reader != null:
		for child in credits_reader.get_children():
			if child is Label:
				credit_lines.append((child as Label).text)
	_check(credit_lines.has("Brian Broeking · with Claude (Anthropic)") \
			and credit_lines.has("3D models — Meshy") \
			and credit_lines.has("Concept art — Midjourney") \
			and credit_lines.has("Sound & music — ElevenLabs") \
			and credit_lines.has("Engine — Godot 4.6"),
		"Credits preserves the exact authored attribution lines")
	_check(credits_back != null and credits_back.custom_minimum_size.y >= Tokens.HIT_TARGET \
			and root.gui_get_focus_owner() == credits_back,
		"Credits provides a 48px-plus focused Back action")
	if credits_back != null:
		credits_back.pressed.emit()
	await _frames()
	_check(not is_instance_valid(credits), "Credits Back closes the reader")

	if _failures.is_empty():
		print("UI SYSTEM CONTRACT: PASS")
		quit(0)
	else:
		print("UI SYSTEM CONTRACT: FAIL (%d failures)" % _failures.size())
		quit(1)
