extends CanvasLayer

# Spec 29 — the 3-buff choice modal a Shrine opens. The whole UI is built in
# script so the .tscn stays a minimal CanvasLayer + script binding. Pauses
# the tree while open so the player can't escape with a movement key; emits
# `chosen(buff)` when the player picks one of the three cards.

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
	# Carved parchment panel centred on the viewport.
	_panel = Panel.new()
	WyrdUi.style_panel(_panel)
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -380
	_panel.offset_top = -230
	_panel.offset_right = 380
	_panel.offset_bottom = 230
	add_child(_panel)
	var title := Label.new()
	title.text = "An Old Altar Stirs"
	WyrdUi.style_title(title)
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.offset_top = 26
	title.offset_bottom = 66
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(title)
	var sub := Label.new()
	sub.text = "Touch one. The blessing is yours alone."
	WyrdUi.style_dim(sub, 13)
	sub.anchor_left = 0.0
	sub.anchor_right = 1.0
	sub.offset_top = 68
	sub.offset_bottom = 90
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(sub)
	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", 18)
	_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_hbox.anchor_left = 0.0
	_hbox.anchor_right = 1.0
	_hbox.anchor_bottom = 1.0
	_hbox.offset_top = 96
	_hbox.offset_bottom = -48
	_hbox.offset_left = 48
	_hbox.offset_right = -48
	_panel.add_child(_hbox)


# Populate the modal with the 3 offered buffs and pause the world.
func setup(buffs: Array) -> void:
	_buffs = buffs
	for c in _hbox.get_children():
		c.queue_free()
	for b in _buffs:
		var card := _BoonCard.new()
		card.setup(String(b.get("name", "?")), String(b.get("desc", "")))
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var bref := b
		card.pressed.connect(func(): _on_boon_chosen(bref))
		_hbox.add_child(card)
	get_node("/root/Game").modal_opened()

func _on_boon_chosen(buff: Dictionary) -> void:
	get_node("/root/Game").modal_closed()
	chosen.emit(buff)
	queue_free()


# ---- drawn boon card (one choice) ----
# A tall clickable card: terracotta header band + a candle flame motif + boon
# name in cream, a draw_flourish divider below it, parchment grain on the
# body, and the blessing description in ink. Hover = gold ring; press =
# terracotta ring tightening in.
class _BoonCard extends Control:
	const HDR_H := 44.0

	var _name := ""
	var _desc := ""
	var _hover := false
	var _pressing := false

	signal pressed

	func _init() -> void:
		custom_minimum_size = Vector2(0, 220.0)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func setup(boon_name: String, desc: String) -> void:
		_name = boon_name
		_desc = desc
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_pressing = true
				queue_redraw()
				accept_event()
			else:
				if _pressing:
					_pressing = false
					queue_redraw()
					pressed.emit()
					accept_event()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_ENTER:
			_hover = true
			queue_redraw()
		elif what == NOTIFICATION_MOUSE_EXIT:
			_hover = false
			_pressing = false
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		# Card face — KIT_PLATE with terracotta left accent stripe.
		WyrdUi.draw_list_row(self, r, WyrdUi.TERRACOTTA)
		# Terracotta header band.
		var hdr := Rect2(r.position + Vector2(1.5, 1.5),
			Vector2(r.size.x - 3.0, HDR_H))
		draw_rect(hdr, WyrdUi.TERRACOTTA)
		# Light bevel across the top of the header.
		draw_rect(Rect2(hdr.position + Vector2(0.0, 1.0),
			Vector2(hdr.size.x, 1.5)), Color(1.0, 0.80, 0.65, 0.22))
		# Candle flame motif — centred in the header.
		var cx := size.x * 0.5
		var flame_pts := PackedVector2Array([
			Vector2(cx, 6.0),
			Vector2(cx - 6.5, 20.0),
			Vector2(cx + 6.5, 20.0),
		])
		draw_colored_polygon(flame_pts, Color(WyrdUi.GOLD, 0.92))
		var inner_pts := PackedVector2Array([
			Vector2(cx, 10.0),
			Vector2(cx - 3.5, 19.0),
			Vector2(cx + 3.5, 19.0),
		])
		draw_colored_polygon(inner_pts, Color(1.0, 0.96, 0.74, 0.78))
		# Candle body below the flame.
		draw_rect(Rect2(Vector2(cx - 4.5, 21.0), Vector2(9.0, 11.0)),
			Color(0.96, 0.90, 0.74))
		draw_rect(Rect2(Vector2(cx - 4.5, 21.0), Vector2(9.0, 11.0)),
			Color(WyrdUi.KIT_EDGE, 0.55), false, 1.0)
		# Boon name in cream across the header.
		var font_hdr := WyrdUi.font_header()
		var font_def := get_theme_default_font()
		var f: Font = font_hdr if font_hdr != null else font_def
		draw_string(f, Vector2(8.0, HDR_H - 7.0), _name,
			HORIZONTAL_ALIGNMENT_CENTER, size.x - 16.0, 15,
			Color(WyrdUi.CREAM, 0.97))
		# Flourish divider just below the header.
		WyrdUi.draw_flourish(self,
			Vector2(size.x * 0.5, HDR_H + 12.0), size.x * 0.58)
		# Parchment grain on the body area.
		var body_r := Rect2(Vector2(2.0, HDR_H + 2.0),
			Vector2(size.x - 4.0, size.y - HDR_H - 4.0))
		WyrdUi.draw_parchment_grain(self, body_r, 31)
		# Blessing description in ink, centred and word-wrapped.
		var font_body := WyrdUi.font_body()
		var fb: Font = font_body if font_body != null else font_def
		draw_multiline_string(fb,
			Vector2(12.0, HDR_H + 28.0), _desc,
			HORIZONTAL_ALIGNMENT_CENTER, size.x - 24.0, 14, -1, WyrdUi.INK)
		# Interaction ring — gold on hover, terracotta on press.
		if _pressing:
			draw_rect(r.grow(-2.0), WyrdUi.TERRACOTTA, false, 2.5)
		elif _hover:
			draw_rect(r.grow(-2.0), Color(WyrdUi.GOLD, 0.82), false, 2.0)
