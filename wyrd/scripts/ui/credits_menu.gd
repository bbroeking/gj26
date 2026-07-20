extends CanvasLayer

# Credits remain exact attribution content, now presented as a bounded reader
# over the title art instead of replacing the whole viewport with flat cream.

const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")
const FocusPointer = preload("res://scripts/ui/components/focus_pointer.gd")
const SystemFolio = preload("res://scripts/ui/components/system_folio.gd")

var _folio: SystemFolio


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 97
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
	_folio.set_folio_size(Vector2(680.0, 610.0))
	_folio.setup("Credits", "The hands and tools behind the road.", "✦")
	_folio.close_requested.connect(_close)
	add_child(_folio)

	var scroll := ScrollContainer.new()
	scroll.name = "CreditsScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_folio.body.add_child(scroll)
	var reader := VBoxContainer.new()
	reader.name = "CreditsReader"
	reader.custom_minimum_size.x = 560.0
	reader.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reader.alignment = BoxContainer.ALIGNMENT_CENTER
	reader.add_theme_constant_override("separation", Tokens.SPACE_2)
	scroll.add_child(reader)

	_add_centered(reader, "Wayfinder", &"Display", Tokens.TERRACOTTA)
	_add_centered(reader, "a cozy fairytale of Bramblewood", &"Body")
	reader.add_child(HSeparator.new())
	_add_centered(reader, "Design & Code", &"SectionTitle")
	_add_centered(reader, "Brian Broeking · with Claude (Anthropic)", &"Body")
	reader.add_child(HSeparator.new())
	_add_centered(reader, "Tools & Craft", &"SectionTitle")
	_add_centered(reader, "3D models — Meshy", &"Body")
	_add_centered(reader, "Concept art — Midjourney", &"Body")
	_add_centered(reader, "Sound & music — ElevenLabs", &"Body")
	_add_centered(reader, "Engine — Godot 4.6", &"Body")
	reader.add_child(HSeparator.new())
	_add_centered(reader, "Thanks for wayfaring.", &"Body", Tokens.TEXT_ON_PAPER_DIM)

	var hint := _folio.add_footer_hint("Esc/B back")
	var back := Button.new()
	back.name = "BackButton"
	back.text = "Back"
	back.theme_type_variation = &"QuietButton"
	back.custom_minimum_size = Vector2(200.0, 52.0)
	back.pressed.connect(_close)
	_folio.footer.add_child(back)
	hint.size_flags_stretch_ratio = 1.0
	back.grab_focus.call_deferred()


func _add_centered(parent: Container, text: String, variation: StringName,
		color: Color = Color.TRANSPARENT) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if color != Color.TRANSPARENT:
		label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()


func _close() -> void:
	queue_free()
