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

	# Header ornament: portal-seal medallion + ivy-bracketed flourish rule.
	# Drawn first so it sits under the title/subtitle Labels.
	var ornam := _HeaderOrnam.new()
	ornam.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ornam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(ornam)

	var title := Label.new()
	title.text = "The Waystone"
	WyrdUi.style_title(title)
	title.position = Vector2(54, 34)
	_panel.add_child(title)

	var sub := Label.new()
	sub.text = "Socket a chart. The crossing spends it."
	WyrdUi.style_dim(sub, 13)
	sub.position = Vector2(54, 66)
	_panel.add_child(sub)

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


# Drawn behind the title/subtitle — a warm header band, a portal-seal
# medallion at top-centre, and an ivy-bracketed gold flourish rule that
# visually marks this panel as a THRESHOLD, not a generic list modal.
class _HeaderOrnam extends Control:
	func _draw() -> void:
		var w := size.x
		var cx := w * 0.5
		# Warm amber tint across the header strip — catches the page's light
		draw_rect(Rect2(36.0, 10.0, w - 72.0, 78.0),
			Color(0.95, 0.84, 0.60, 0.20))
		# Portal-seal medallion at top-centre: nested rings suggest a waystone
		_draw_seal(Vector2(cx, 22.0), 13.0)
		# Ivy leaf clusters bracket the rule at each end
		_draw_ivy(Vector2(48.0, 84.0), 1.0)
		_draw_ivy(Vector2(w - 48.0, 84.0), -1.0)
		# Gold ◆ flourish rule dividing header from chart list
		WyrdUi.draw_flourish(self, Vector2(cx, 84.0), w - 100.0)

	func _draw_seal(c: Vector2, r: float) -> void:
		# Cream face so the seal reads against the wooden frame
		draw_circle(c, r, Color(0.94, 0.88, 0.74, 0.70))
		# Outer ink ring
		draw_arc(c, r, 0.0, TAU, 40, Color(WyrdUi.KIT_EDGE, 0.55), 1.5, true)
		# Gold inner ring
		draw_arc(c, r - 4.0, 0.0, TAU, 32, Color(WyrdUi.GOLD, 0.78), 2.0, true)
		# Cardinal tick marks
		for i in 4:
			var a := TAU * float(i) * 0.25
			var from := c + Vector2(cos(a), sin(a)) * (r - 0.5)
			var to := c + Vector2(cos(a), sin(a)) * (r + 3.5)
			draw_line(from, to, Color(WyrdUi.KIT_EDGE, 0.55), 1.5)
		# Centre dot — the eye of the waystone
		draw_circle(c, 3.5, Color(WyrdUi.GOLD, 0.80))
		draw_circle(c, 1.5, Color(WyrdUi.KIT_EDGE, 0.90))

	func _draw_ivy(root: Vector2, sx: float) -> void:
		# Short curving stem + two leaf polygons — mirrors left/right via sx ±1.
		var tip := root + Vector2(sx * 12.0, -14.0)
		draw_line(root, tip, Color(WyrdUi.SAGE, 0.52), 1.5)
		# Leaf A — fans out from stem midpoint
		var ma := root + Vector2(sx * 6.0, -7.0)
		draw_colored_polygon(PackedVector2Array([
			ma,
			ma + Vector2(sx * 8.0, -5.0),
			ma + Vector2(sx * 11.0, 0.0),
			ma + Vector2(sx * 3.0, 4.0)]),
			Color(WyrdUi.SAGE, 0.38))
		# Leaf B — at tip, pointing up-outward
		draw_colored_polygon(PackedVector2Array([
			tip,
			tip + Vector2(sx * -3.0, -8.0),
			tip + Vector2(sx * 4.0, -9.0),
			tip + Vector2(sx * 6.0, -2.0)]),
			Color(WyrdUi.SAGE, 0.32))
