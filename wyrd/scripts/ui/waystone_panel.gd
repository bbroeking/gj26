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
	_panel.offset_top = -268
	_panel.offset_right = 300
	_panel.offset_bottom = 268
	add_child(_panel)

	# Carved waystone portal disc — centred horizontally at the top of the panel.
	# Draws concentric stone rings with a warm amber void at the centre,
	# a compass cross, a gold lodestone diamond, and ivy buds at the crown —
	# the dungeon gateway made visible without a texture.
	var crest := _WaystoneCrest.new()
	crest.anchor_left = 0.5
	crest.anchor_right = 0.5
	crest.offset_left = -26.0
	crest.offset_right = 26.0
	crest.offset_top = 12.0
	crest.offset_bottom = 64.0
	_panel.add_child(crest)

	var title := Label.new()
	title.text = "The Waystone"
	WyrdUi.style_title(title)
	title.anchor_right = 1.0
	title.offset_top = 68
	title.offset_bottom = 102
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(title)

	var sub := Label.new()
	sub.text = "Socket a chart. The crossing spends it."
	WyrdUi.style_dim(sub, 13)
	sub.anchor_right = 1.0
	sub.offset_top = 104
	sub.offset_bottom = 124
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(sub)

	# Flourish rule separating the header from the chart list.
	var rule := _FlourishRule.new()
	rule.anchor_left = 0.5
	rule.anchor_right = 0.5
	rule.offset_left = -100.0
	rule.offset_right = 100.0
	rule.offset_top = 124.0
	rule.offset_bottom = 136.0
	_panel.add_child(rule)

	# A full chart case outgrows the panel — the list scrolls now,
	# bounded above the detail block.
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = 52
	scroll.offset_top = 140
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


# ---- Carved waystone portal disc ----
# Concentric stone rings in aged parchment-grey, a warm amber void at the
# centre (the opened passage glowing through), a faint compass cross, a gold
# diamond lodestone at the heart, and two ivy buds at the crown — all drawn
# with WyrdUi primitives so no texture is ever loaded inside _draw.
class _WaystoneCrest extends Control:
	func _draw() -> void:
		var c := size * 0.5
		var r := minf(c.x, c.y) - 1.5

		# Outer stone ring — two tones of aged carved stone
		draw_circle(c, r, Color(0.72, 0.65, 0.52))
		draw_circle(c, r - 5.0, Color(0.82, 0.76, 0.63))

		# Amber void — the opened portal glowing warm from within
		var inner_r := r - 13.0
		draw_circle(c, inner_r + 5.0, Color(0.92, 0.76, 0.38, 0.30))
		draw_circle(c, inner_r, Color(0.96, 0.88, 0.64))

		# Compass cross — faint ink lines showing the cardinal ways
		draw_line(c - Vector2(inner_r - 3.0, 0.0), c + Vector2(inner_r - 3.0, 0.0),
			Color(WyrdUi.KIT_EDGE, 0.32), 1.0)
		draw_line(c - Vector2(0.0, inner_r - 3.0), c + Vector2(0.0, inner_r - 3.0),
			Color(WyrdUi.KIT_EDGE, 0.32), 1.0)

		# Gold lodestone diamond at the heart
		var pts := PackedVector2Array([
			c + Vector2(0.0, -5.0),
			c + Vector2(5.0,  0.0),
			c + Vector2(0.0,  5.0),
			c + Vector2(-5.0, 0.0),
		])
		draw_colored_polygon(pts, Color(WyrdUi.GOLD, 0.92))
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]),
			Color(WyrdUi.KIT_EDGE, 0.55), 1.0)

		# Cardinal notch sockets — four shallow recesses carved into the ring
		for i in 4:
			var angle := PI * 0.5 * float(i)
			var np := c + Vector2(cos(angle), sin(angle)) * (r - 3.0)
			draw_circle(np, 4.0, Color(0.54, 0.47, 0.37))
			draw_circle(np, 2.5, Color(0.66, 0.59, 0.46))

		# Ink borders: outer ring, mid groove, inner void rim
		draw_arc(c, r, 0.0, TAU, 60, WyrdUi.KIT_EDGE, 2.0, true)
		draw_arc(c, r - 5.0, 0.0, TAU, 50, Color(WyrdUi.KIT_EDGE, 0.38), 1.0, true)
		draw_arc(c, inner_r, 0.0, TAU, 36, Color(WyrdUi.KIT_EDGE, 0.55), 1.5, true)

		# Top bevel on the outer stone face — catches the warm overhead light
		draw_arc(c, r - 2.5, -PI * 0.72, -PI * 0.28, 24,
			Color(1.0, 1.0, 0.90, 0.38), 2.5, true)

		# Ivy buds at the crown — two small sprigs grow from the top of the disc.
		# Offsets stay inside the 52×52 control boundary (r≈24.5, center.y≈26).
		for side in [-1.0, 1.0]:
			var base := c + Vector2(side * r * 0.46, -(r * 0.72))
			var tip  := base + Vector2(side * 3.0, -5.5)
			draw_line(base, tip, Color(WyrdUi.SAGE, 0.62), 1.0)
			draw_circle(tip, 2.8, Color(WyrdUi.SAGE, 0.82))
			draw_circle(base + Vector2(side * 5.0, -2.5), 2.0,
				Color(WyrdUi.SAGE, 0.65))


# ---- Flourish rule ----
# A simple ── ◆ ── divider drawn via the shared WyrdUi helper.
class _FlourishRule extends Control:
	func _draw() -> void:
		WyrdUi.draw_flourish(self, size * 0.5, size.x)
