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

	# Drawn header: compass glyph + cream wash + flourish rule.
	var header_draw := _HeaderDraw.new()
	header_draw.anchor_right = 1.0
	header_draw.custom_minimum_size = Vector2(0, 92.0)
	header_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(header_draw)

	var title := Label.new()
	title.text = "The Waystone"
	WyrdUi.style_title(title)
	title.position = Vector2(96, 34)
	_panel.add_child(title)

	var sub := Label.new()
	sub.text = "Socket a chart. The crossing spends it."
	WyrdUi.style_dim(sub, 13)
	sub.position = Vector2(96, 66)
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

# Drawn waystone header — compass glyph left of the title, cream wash,
# hairline separator, and flourish rule below the subtitle. No textures;
# pure CanvasItem draws so the load-inside-_draw white-rect trap is impossible.
class _HeaderDraw extends Control:
	func _draw() -> void:
		var lm := WyrdUi.PANEL_MARGIN_L
		var rm := WyrdUi.PANEL_MARGIN_R
		# Subtle cream wash in the header zone (inside the wooden frame).
		draw_rect(Rect2(Vector2(lm, 4.0), Vector2(size.x - lm - rm, 82.0)),
			Color(0.96, 0.91, 0.78, 0.28))
		# Hairline rule separating header from the chart list below.
		draw_line(Vector2(lm + 12.0, 90.0), Vector2(size.x - rm - 12.0, 90.0),
			Color(WyrdUi.KIT_EDGE, 0.28), 1.0)
		# ---- Waystone compass glyph ----
		# A concentric-ring portal mark: stone outer band, cream face,
		# 4 cardinal diamond nibs (N/S/E/W), gold diagonal compass star.
		var gc := Vector2(58.0, 46.0)
		var gr := 24.0
		# Stone outer band — warm tan fill, inner ring pinstripe, ink border.
		draw_arc(gc, gr, 0.0, TAU, 48, Color(0.74, 0.65, 0.50, 0.88), 8.0, true)
		draw_arc(gc, gr, 0.0, TAU, 48, WyrdUi.KIT_EDGE, 1.5, true)
		draw_arc(gc, gr - 8.0, 0.0, TAU, 40, Color(WyrdUi.KIT_EDGE, 0.45), 1.0, true)
		# Cream inner face — parchment showing through the carved stone.
		draw_circle(gc, gr - 9.5, Color(0.96, 0.91, 0.78))
		# Sparse sepia grain on the face (deterministic seed).
		var rng := RandomNumberGenerator.new()
		rng.seed = 42
		for _i in 6:
			var fa := rng.randf() * TAU
			var r0 := rng.randf() * (gr - 11.0)
			draw_line(gc + Vector2(cos(fa), sin(fa)) * r0,
				gc + Vector2(cos(fa), sin(fa)) * (r0 + 2.0 + rng.randf() * 4.0),
				Color(0.62, 0.52, 0.38, 0.07), 1.0)
		# 4 cardinal diamond nibs (N/S/E/W) — the four crossing directions.
		for i in 4:
			var ang := -PI * 0.5 + PI * 0.5 * float(i)
			var tip := gc + Vector2(cos(ang), sin(ang)) * gr
			var base_c := gc + Vector2(cos(ang), sin(ang)) * (gr - 8.5)
			var perp := ang + PI * 0.5
			var p1 := base_c + Vector2(cos(perp), sin(perp)) * 2.8
			var p2 := base_c - Vector2(cos(perp), sin(perp)) * 2.8
			draw_colored_polygon(PackedVector2Array([tip, p1, p2]),
				Color(WyrdUi.KIT_EDGE, 0.82))
		# Gold diagonal star (4 diamond petals at 45° offsets from cardinal).
		for i in 4:
			var ang := PI * 0.25 + PI * 0.5 * float(i)
			var tip := gc + Vector2(cos(ang), sin(ang)) * (gr - 10.0)
			var perp := ang + PI * 0.5
			var p1 := gc + Vector2(cos(perp), sin(perp)) * 2.5
			var p2 := gc - Vector2(cos(perp), sin(perp)) * 2.5
			draw_colored_polygon(PackedVector2Array([tip, p1, gc, p2]),
				Color(WyrdUi.GOLD, 0.88))
		# Gold centre pip — the crossing point.
		draw_circle(gc, 2.8, Color(WyrdUi.GOLD, 0.90))
		# Flourish rule just below the subtitle (── ◆ ──).
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, 90.0), size.x * 0.60)
