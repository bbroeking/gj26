extends CanvasLayer

# B6 — credits, reachable from the title. Also satisfies attribution for the
# generative tools used to build the game (see docs/adr/0015-asset-attribution.md).

const LINES := [
	["Wayfinder", 30, Color(0.71, 0.29, 0.12)],
	["a cozy fairytale of Bramblewood", 15, Color(0.42, 0.34, 0.25)],
	["", 8, Color.WHITE],
	["Design & code", 16, Color(0.20, 0.15, 0.11)],
	["Brian Broeking · with Claude (Anthropic)", 14, Color(0.30, 0.24, 0.18)],
	["", 6, Color.WHITE],
	["3D models — Meshy", 14, Color(0.30, 0.24, 0.18)],
	["Concept art — Midjourney", 14, Color(0.30, 0.24, 0.18)],
	["Sound & music — ElevenLabs", 14, Color(0.30, 0.24, 0.18)],
	["Engine — Godot 4.6", 14, Color(0.30, 0.24, 0.18)],
	["", 8, Color.WHITE],
	["Thanks for wayfaring.", 14, Color(0.42, 0.34, 0.25)],
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 97
	var bg := ColorRect.new()
	bg.color = Color(0.91, 0.85, 0.69)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var col := VBoxContainer.new()
	col.anchor_left = 0.5; col.anchor_right = 0.5; col.anchor_top = 0.16
	col.offset_left = -300; col.offset_right = 300
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 4)
	add_child(col)
	for line in LINES:
		var l := Label.new()
		l.text = String(line[0])
		var f := WyrdUi.font_header() if int(line[1]) >= 20 else WyrdUi.font_body()
		if f != null:
			l.add_theme_font_override("font", f)
		l.add_theme_font_size_override("font_size", int(line[1]))
		l.add_theme_color_override("font_color", line[2])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(l)

	var close := Button.new()
	WyrdUi.style_kit_button(close)
	close.text = "Back"
	close.custom_minimum_size = Vector2(200, 42)
	close.anchor_left = 0.5; close.anchor_right = 0.5; close.anchor_top = 0.82
	close.offset_left = -100; close.offset_right = 100
	close.pressed.connect(_close)
	add_child(close)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

func _close() -> void:
	queue_free()
