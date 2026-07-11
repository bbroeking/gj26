extends CanvasLayer

# Spec 29 — the 3-buff choice modal a Shrine opens. Emits `chosen(buff)` when
# the player picks one of the three cards. Pauses the tree while open.
#
# Art pass — raw Buttons replaced with drawn _BoonCard controls in the WyrdUi
# parchment language: carved plate, sage accent stripe, wax seal, IM Fell name
# header + flourish divider + body description. The panel gets the wooden-frame
# 9-patch so the shrine reads as a storybook moment.

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
	_panel.custom_minimum_size = Vector2(720, 380)
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -360
	_panel.offset_top = -190
	_panel.offset_right = 360
	_panel.offset_bottom = 190
	add_child(_panel)
	var title := Label.new()
	title.text = "An Old Altar Stirs"
	WyrdUi.style_title(title)
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.offset_top = 28
	title.offset_bottom = 62
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(title)
	var deco := _HeaderDeco.new()
	deco.anchor_left = 0.0
	deco.anchor_right = 1.0
	deco.offset_top = 62
	deco.offset_bottom = 78
	_panel.add_child(deco)
	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", 16)
	_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_hbox.anchor_left = 0.0
	_hbox.anchor_right = 1.0
	_hbox.anchor_bottom = 1.0
	_hbox.offset_top = 82
	_hbox.offset_bottom = -28
	_hbox.offset_left = 44
	_hbox.offset_right = -44
	_panel.add_child(_hbox)

func setup(buffs: Array) -> void:
	_buffs = buffs
	for c in _hbox.get_children():
		c.queue_free()
	for b in _buffs:
		var card := _BoonCard.new()
		card.setup(String(b.name), String(b.desc))
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var bd: Dictionary = b
		card.pressed.connect(func(): _on_pressed(bd))
		_hbox.add_child(card)
	get_node("/root/Game").modal_opened()

func _on_pressed(buff: Dictionary) -> void:
	get_node("/root/Game").modal_closed()
	chosen.emit(buff)
	queue_free()


class _HeaderDeco extends Control:
	func _draw() -> void:
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, size.y * 0.5),
				size.x - 88.0)


class _BoonCard extends Control:
	signal pressed

	var _boon_name := ""
	var _boon_desc := ""
	var _hover := false

	func _init() -> void:
		custom_minimum_size = Vector2(0, 200.0)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func setup(boon_name: String, boon_desc: String) -> void:
		_boon_name = boon_name
		_boon_desc = boon_desc
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
		WyrdUi.draw_list_row(self, r, WyrdUi.SAGE)
		if _hover:
			draw_rect(r.grow(-1.5), Color(1.0, 1.0, 0.90, 0.12))
		WyrdUi.draw_parchment_grain(self, r.grow(-4.0),
				int(abs(_boon_name.hash())) & 0xFFFF)
		# Wax seal — terracotta disc in the top-right corner.
		var sc := Vector2(size.x - 18.0, 18.0)
		draw_circle(sc, 9.0, Color(0.62, 0.20, 0.16))
		draw_circle(sc, 5.5, Color(0.72, 0.28, 0.22))
		draw_arc(sc, 9.0, 0, TAU, 20, Color(0.40, 0.12, 0.10), 1.5, true)
		var hf: Font = WyrdUi.font_header()
		var body_font: Font = get_theme_default_font()
		var name_font: Font = hf if hf != null else body_font
		draw_string(name_font, Vector2(16.0, 34.0), _boon_name,
				HORIZONTAL_ALIGNMENT_LEFT, size.x - 46.0, 17, WyrdUi.TERRACOTTA)
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, 48.0), size.x - 40.0)
		draw_multiline_string(body_font, Vector2(16.0, 68.0), _boon_desc,
				HORIZONTAL_ALIGNMENT_LEFT, size.x - 32.0, 13, 7, WyrdUi.INK)
		if _hover:
			draw_string(body_font, Vector2(0.0, size.y - 10.0), "Choose",
					HORIZONTAL_ALIGNMENT_CENTER, size.x, 12,
					Color(WyrdUi.SAGE.darkened(0.1), 0.9))
