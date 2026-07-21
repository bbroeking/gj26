extends CanvasLayer

# Wyrd — the Waystone socket modal. Lists the chart case; picking one and
# pressing "Step through" consumes it and crosses into the dungeon it
# describes. Esc closes.

const ChartsData = preload("res://data/charts.gd")

var player: Node = null

var _game: Node
var _selected := -1
var _panel: Panel
var _list_box: VBoxContainer
var _detail: Label
var _go_btn: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	_game = get_tree().root.get_node_or_null("Game")
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.55)
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
	_panel.offset_left = -300
	_panel.offset_top = -230
	_panel.offset_right = 300
	_panel.offset_bottom = 230
	add_child(_panel)

	# Drawn compass-medallion header — replaces the bare title/sub labels so
	# the most-seen first impression reads as a carved waymarker object, not
	# an engine text widget.
	var hdr := _WaystoneHeader.new()
	hdr.anchor_right = 1.0
	hdr.offset_left = 42
	hdr.offset_top = 14
	hdr.offset_right = -42
	_panel.add_child(hdr)

	# A full chart case outgrows the panel — the list scrolls now,
	# bounded above the detail block.
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = 52
	scroll.offset_top = 92
	scroll.offset_right = -52
	scroll.offset_bottom = -160
	_panel.add_child(scroll)
	_list_box = VBoxContainer.new()
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_list_box)

	_detail = Label.new()
	WyrdUi.style_body(_detail, 13)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.anchor_right = 1.0
	_detail.anchor_top = 1.0
	_detail.anchor_bottom = 1.0
	_detail.offset_left = 52
	_detail.offset_right = -52
	_detail.offset_top = -150
	_detail.offset_bottom = -64
	_panel.add_child(_detail)

	_go_btn = Button.new()
	WyrdUi.style_button(_go_btn)
	_go_btn.text = "Step through"
	_go_btn.add_theme_font_size_override("font_size", 17)
	_go_btn.custom_minimum_size = Vector2(200, 40)
	_go_btn.anchor_left = 0.5
	_go_btn.anchor_top = 1.0
	_go_btn.anchor_right = 0.5
	_go_btn.anchor_bottom = 1.0
	_go_btn.offset_left = -100
	_go_btn.offset_top = -54
	_go_btn.offset_bottom = -14
	_go_btn.pressed.connect(_on_go)
	_panel.add_child(_go_btn)

	get_node("/root/Game").modal_opened()
	_render()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()

func _close() -> void:
	get_node("/root/Game").modal_closed()
	queue_free()

func _render() -> void:
	for c in _list_box.get_children():
		c.queue_free()
	var n := 0 if _game == null else (_game.charts as Array).size()
	if n == 0:
		var l := Label.new()
		l.text = "Your chart case is empty. Inscribe one at the table."
		WyrdUi.style_body(l, 14)
		_list_box.add_child(l)
	for i in n:
		var chart: Dictionary = _game.charts[i]
		var b := Button.new()
		WyrdUi.style_button(b)
		WyrdUi.mark_selected(b, i == _selected)
		b.toggle_mode = true
		b.button_pressed = i == _selected
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = ChartsData.chart_label(chart)
		var idx := i
		b.pressed.connect(func():
			_selected = idx
			_render())
		_list_box.add_child(b)
	# Detail + button state.
	if _selected >= 0 and _selected < n:
		var chart: Dictionary = _game.charts[_selected]
		var lines: Array = []
		for a in chart.get("affixes", []):
			var aff: Dictionary = ChartsData.AFFIXES.get(String(a.get("id", "")), {})
			if aff.is_empty():
				continue
			if bool(a.get("good", false)):
				lines.append("✓ %s — %s" % [String(aff.name), String(aff.good_desc)])
			else:
				lines.append("✗ %s — %s" % [String(aff.bad_name), String(aff.bad_desc)])
		if lines.is_empty():
			lines.append("A clean chart. Nothing inked in but the way there and back.")
		_detail.text = "\n".join(lines)
		_go_btn.disabled = false
	else:
		_detail.text = ""
		_go_btn.disabled = true

func _on_go() -> void:
	if _game == null or _selected < 0 or _selected >= (_game.charts as Array).size():
		return
	var chart: Dictionary = _game.charts[_selected]
	get_node("/root/Game").modal_closed()
	_game.enter_dungeon(chart, player)
	queue_free()


# A code-drawn header for the Waystone modal.
# Draws a carved stone compass medallion beside the title so the panel's
# most-seen first impression reads as a hand-crafted waymarker rather than
# an engine widget. The flourish at the bottom acts as a visual divider
# between the header and the scrolling chart list.
class _WaystoneHeader extends Control:
	func _ready() -> void:
		custom_minimum_size = Vector2(0, 72)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var hf := WyrdUi.font_header()
		var font := hf if hf != null else get_theme_default_font()
		# ── compass medallion ──────────────────────────────────────────────
		var cx := 40.0
		var cy := size.y * 0.5 - 4.0   # vertical centre of the header
		var r  := 26.0
		# Parchment-cream stone disc.
		draw_circle(Vector2(cx, cy), r, WyrdUi.KIT_PLATE)
		# Warm top-left gleam (the stone catches the page's light).
		draw_arc(Vector2(cx, cy), r - 4.0, PI * 1.05, PI * 1.80, 14,
			Color(1.0, 0.98, 0.88, 0.50), 3.0, true)
		# Cardinal arms (N / E / S / W).
		for i in 4:
			var ang := PI * 0.5 * float(i)
			var d := Vector2(cos(ang), sin(ang))
			draw_line(Vector2(cx, cy) + d * 7.0,
				Vector2(cx, cy) + d * (r - 4.5),
				WyrdUi.KIT_EDGE, 1.5)
		# Diagonal ticks (lighter, shorter — ordinal compass points).
		for i in 4:
			var ang := PI * 0.25 + PI * 0.5 * float(i)
			var d := Vector2(cos(ang), sin(ang))
			draw_line(Vector2(cx, cy) + d * 14.0,
				Vector2(cx, cy) + d * (r - 7.0),
				Color(WyrdUi.KIT_EDGE, 0.42), 1.0)
		# Gold waymark diamond at the centre — the "here / crossing" symbol.
		var s    := 6.5
		var cd   := Vector2(cx, cy)
		var pts  := PackedVector2Array([cd + Vector2(0, -s),
			cd + Vector2(s * 0.70, 0), cd + Vector2(0, s),
			cd + Vector2(-s * 0.70, 0)])
		draw_colored_polygon(pts, Color(WyrdUi.GOLD, 0.90))
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]),
			Color(WyrdUi.KIT_EDGE, 0.65), 1.0, true)
		# Outer ink ring.
		draw_arc(Vector2(cx, cy), r, 0.0, TAU, 48, WyrdUi.KIT_EDGE, 2.0, true)
		# ── title + subtitle to the right of the medallion ────────────────
		var tx := cx + r + 16.0
		draw_string(font, Vector2(tx, cy + 9.0), "The Waystone",
			HORIZONTAL_ALIGNMENT_LEFT, size.x - tx, 24, WyrdUi.TERRACOTTA)
		draw_string(get_theme_default_font(), Vector2(tx, cy + 27.0),
			"Socket a chart. The crossing spends it.",
			HORIZONTAL_ALIGNMENT_LEFT, size.x - tx, 13, WyrdUi.INK_MID)
		# ── flourish divider at the bottom of the header ──────────────────
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, size.y - 3.0),
			size.x - tx + 8.0)
