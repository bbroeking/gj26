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

	# Carved compass seal — left of the panel title, embedded in the frame edge.
	# A stone-parchment ring with a four-point gold compass rose (the Wayfinding
	# star) marks the portal threshold without crowding the chart list below.
	var glyph := _WaystoneGlyph.new()
	glyph.position = Vector2(10, 20)
	glyph.size = Vector2(38, 38)
	_panel.add_child(glyph)

	# Flourish rule — ── ◆ ── separator below the subtitle before the chart list.
	var hrule := _HRule.new()
	hrule.anchor_right = 1.0
	hrule.offset_left = 52
	hrule.offset_right = -52
	hrule.offset_top = 83
	hrule.offset_bottom = 90
	_panel.add_child(hrule)

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


# ── Decorative helpers ──────────────────────────────────────────────────────

# Flourish rule: ── ◆ ── centred below the panel subtitle using the shared helper.
class _HRule extends Control:
	func _draw() -> void:
		WyrdUi.draw_flourish(self, size * 0.5, size.x * 0.85)


# Carved waystone compass seal drawn left of the panel title.
# A pale stone-parchment ring holds a four-point gold compass rose (the
# Wayfinding star) — marking the portal without cluttering the chart list.
# Pure vector, no texture loads (draw/load white-rect gotcha stays impossible).
class _WaystoneGlyph extends Control:
	func _draw() -> void:
		var cx := size.x * 0.5
		var cy := size.y * 0.5
		var r := minf(cx, cy) - 1.5
		# Parchment-stone ring face.
		draw_circle(Vector2(cx, cy), r, WyrdUi.KIT_PLATE.darkened(0.12))
		# Top highlight bevel — the stone badge catches warm light from above.
		# Arc PI*1.15→PI*1.85 sweeps counterclockwise through the upper half.
		draw_arc(Vector2(cx, cy), r - 3.5, PI * 1.15, PI * 1.85, 18,
				Color(1.0, 1.0, 0.92, 0.38), 2.5, true)
		# Ink border + carved inner ring for depth.
		draw_arc(Vector2(cx, cy), r, 0, TAU, 40, WyrdUi.KIT_EDGE, 2.0, true)
		draw_arc(Vector2(cx, cy), r * 0.70, 0, TAU, 32,
				Color(WyrdUi.KIT_EDGE, 0.32), 1.0, true)
		# Four-point compass rose in burnished gold (8-vert star alternating long/short).
		var sc := Vector2(cx, cy)
		var sr := r * 0.50
		var pts := PackedVector2Array()
		for i in 8:
			var a := TAU * float(i) / 8.0 - PI * 0.5
			var d := sr if i % 2 == 0 else sr * 0.36
			pts.append(sc + Vector2(cos(a), sin(a)) * d)
		draw_colored_polygon(pts, Color(WyrdUi.GOLD, 0.88))
		# Centre pearl — a cream dot so the star doesn't read as a starburst.
		draw_circle(sc, sr * 0.22, WyrdUi.KIT_PLATE)
		draw_arc(sc, sr * 0.22, 0, TAU, 16, Color(WyrdUi.KIT_EDGE, 0.50), 1.0, true)
