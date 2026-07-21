extends CanvasLayer

# Spec 29 — the 3-buff choice modal a Shrine opens. The whole UI is built in
# script so the .tscn stays a minimal CanvasLayer + script binding. Pauses
# the tree while open so the player can't escape with a movement key; emits
# `chosen(buff)` when the player picks one of the three cards.
#
# Slice A — boon cards are now drawn controls (carved button face, sage round
# well, parchment grain, IM Fell SC name, flourish divider, multiline desc).
# The panel uses the WyrdUi carved-wood frame language so it reads as a
# proper storybook moment, not a system dialog.

signal chosen(buff: Dictionary)

var _buffs: Array = []
var _panel: Panel
var _hbox: HBoxContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.6)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	_panel = Panel.new()
	WyrdUi.style_panel(_panel)
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -360
	_panel.offset_top = -210
	_panel.offset_right = 360
	_panel.offset_bottom = 210
	add_child(_panel)

	# Title — IM Fell SC, terracotta, centred.
	var title := Label.new()
	title.text = "An Old Altar Stirs"
	WyrdUi.style_title(title)
	title.anchor_right = 1.0
	title.offset_top = 22
	title.offset_bottom = 64
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(title)

	# Flourish divider below the title.
	var flourish := _Flourish.new()
	flourish.anchor_right = 1.0
	flourish.offset_top = 62
	flourish.offset_bottom = 78
	_panel.add_child(flourish)

	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", 22)
	_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_hbox.anchor_left = 0.0
	_hbox.anchor_right = 1.0
	_hbox.anchor_bottom = 1.0
	_hbox.offset_top = 82
	_hbox.offset_bottom = -22
	_hbox.offset_left = 22
	_hbox.offset_right = -22
	_panel.add_child(_hbox)

func setup(buffs: Array) -> void:
	_buffs = buffs
	for c in _hbox.get_children():
		c.queue_free()
	for b in _buffs:
		var card := _BoonCard.new()
		card.setup(String(b.get("name", "Boon")), String(b.get("desc", "")))
		card.custom_minimum_size = Vector2(196, 0)
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.pressed.connect(_on_pressed.bind(b))
		_hbox.add_child(card)
	get_node("/root/Game").modal_opened()

func _on_pressed(buff: Dictionary) -> void:
	get_node("/root/Game").modal_closed()
	chosen.emit(buff)
	queue_free()


# ---- thin flourish bar — a centred WyrdUi.draw_flourish ----
class _Flourish extends Control:
	func _draw() -> void:
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, size.y * 0.5), size.x * 0.55)


# ---- drawn boon card — the centrepiece of this slice ----
# Layout (top to bottom inside the card, 196 × ~240 px):
#   • Carved button face (WyrdUi.draw_carved_button) — the whole rect
#   • Parchment grain overlay (deterministic per boon name)
#   • Sage round-well at top (radius 28, y=50) with a ✦ glyph inside
#   • Boon name in IM Fell SC, terracotta, below the well
#   • Mini flourish divider
#   • Multiline description, plain ink, capped at 3 lines
#   • "Choose" tray at bottom — sage fill on hover, KIT_WELL otherwise
class _BoonCard extends Control:
	var _boon_name := ""
	var _desc := ""
	var _grain_seed := 7
	var _hover := false

	signal pressed

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func setup(boon_name: String, desc: String) -> void:
		_boon_name = boon_name
		_desc = desc
		_grain_seed = abs(boon_name.hash()) % 97 + 3
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed \
				and event.button_index == MOUSE_BUTTON_LEFT:
			pressed.emit()
			accept_event()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_ENTER:
			_hover = true
			queue_redraw()
		elif what == NOTIFICATION_MOUSE_EXIT:
			_hover = false
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)

		# --- card face ---
		WyrdUi.draw_carved_button(self, r, true)
		WyrdUi.draw_parchment_grain(self, r, _grain_seed)

		# Hover warmth — a faint cream wash, same language as vendor cards.
		if _hover:
			draw_rect(r.grow(-2.0), Color(1.0, 1.0, 0.90, 0.09))

		var cx := size.x * 0.5
		var font := get_theme_default_font()

		# --- sage round well (top emblem zone) ---
		var well_cy := 52.0
		var well_r := 28.0
		WyrdUi.draw_round_well(self, Vector2(cx, well_cy), well_r, WyrdUi.SAGE)
		# ✦ wayfinder star inside the well, small and centred.
		var glyph := "✦"
		draw_string(font, Vector2(cx - 9.0, well_cy + 7.0),
			glyph, HORIZONTAL_ALIGNMENT_CENTER, 18.0, 16,
			Color(WyrdUi.CREAM.r, WyrdUi.CREAM.g, WyrdUi.CREAM.b, 0.90))

		# --- boon name ---
		var hf := WyrdUi.font_header()
		var name_font := hf if hf != null else font
		draw_string(name_font,
			Vector2(14.0, well_cy + well_r + 20.0),
			_boon_name, HORIZONTAL_ALIGNMENT_CENTER,
			size.x - 28.0, 16, WyrdUi.TERRACOTTA)

		# --- mini flourish divider ---
		var fl_y := well_cy + well_r + 32.0
		WyrdUi.draw_flourish(self, Vector2(cx, fl_y), size.x * 0.42)

		# --- description text (multiline, ink, up to 3 lines) ---
		var desc_y := fl_y + 14.0
		var line_h := 19.0
		var lines := _wrap_lines(_desc, font, 13, size.x - 28.0)
		var max_lines := 5
		for i in min(lines.size(), max_lines):
			draw_string(font,
				Vector2(14.0, desc_y + i * line_h),
				lines[i], HORIZONTAL_ALIGNMENT_CENTER,
				size.x - 28.0, 13, WyrdUi.INK_MID)

		# --- "Choose" tray at the bottom ---
		var tray_h := 34.0
		var tray := Rect2(Vector2(6.0, size.y - tray_h - 6.0),
			Vector2(size.x - 12.0, tray_h))
		var tray_col := WyrdUi.SAGE if _hover else WyrdUi.KIT_WELL
		draw_rect(tray, tray_col)
		draw_rect(tray, WyrdUi.KIT_EDGE, false, 1.2)
		var choose_col := WyrdUi.CREAM if _hover else WyrdUi.INK_MID
		draw_string(font,
			Vector2(6.0, tray.position.y + tray_h * 0.5 + 6.0),
			"Choose", HORIZONTAL_ALIGNMENT_CENTER,
			size.x - 12.0, 14, choose_col)

	# Naive word-wrap: split on spaces and measure with font.get_string_size.
	static func _wrap_lines(text: String, font: Font, size_px: int, max_w: float) -> Array:
		var words := text.split(" ")
		var lines: Array = []
		var cur := ""
		for w in words:
			var test := (cur + " " + w).strip_edges()
			if font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x > max_w and cur != "":
				lines.append(cur)
				cur = w
			else:
				cur = test
		if cur != "":
			lines.append(cur)
		return lines
