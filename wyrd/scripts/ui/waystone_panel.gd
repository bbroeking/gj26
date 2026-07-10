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
var _detail_well: Control
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

	_detail_well = _AffixDetailWell.new()
	_detail_well.anchor_right = 1.0
	_detail_well.anchor_top = 1.0
	_detail_well.anchor_bottom = 1.0
	_detail_well.offset_left = 52
	_detail_well.offset_right = -52
	_detail_well.offset_top = -150
	_detail_well.offset_bottom = -64
	_panel.add_child(_detail_well)

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
		var rows: Array = []
		for a in chart.get("affixes", []):
			var aff: Dictionary = ChartsData.AFFIXES.get(String(a.get("id", "")), {})
			if aff.is_empty():
				continue
			var is_good := bool(a.get("good", false))
			rows.append({
				"text": "%s — %s" % [
					String(aff.name if is_good else aff.get("bad_name", aff.name)),
					String(aff.good_desc if is_good else aff.get("bad_desc", ""))],
				"good": is_good
			})
		if rows.is_empty():
			rows.append({"text": "A clean chart. Nothing inked in but the way there and back.",
				"good": true})
		_detail_well.set_affixes(rows)
		_go_btn.disabled = false
	else:
		_detail_well.set_affixes([])
		_go_btn.disabled = true

func _on_go() -> void:
	if _game == null or _selected < 0 or _selected >= (_game.charts as Array).size():
		return
	var chart: Dictionary = _game.charts[_selected]
	get_node("/root/Game").modal_closed()
	_game.enter_dungeon(chart, player)
	queue_free()


# Drawn affix-detail well. A recessed parchment well that shows each chart
# affix as a coloured chip row: sage for boons, terracotta for curses, with a
# gold flourish divider at the top. Replaces the bare _detail Label so the
# affix summary reads as a carved inset panel rather than a paragraph dump.
class _AffixDetailWell extends Control:
	var _rows: Array = []

	func set_affixes(rows: Array) -> void:
		_rows = rows
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		WyrdUi.draw_well(self, r)
		if _rows.is_empty():
			return
		var font := WyrdUi.font_body()
		if font == null:
			font = get_theme_default_font()
		# Gold flourish divider at the top of the well.
		WyrdUi.draw_flourish(self, Vector2(r.size.x * 0.5, 11.0), r.size.x * 0.55)
		var row_h := 20.0
		var gap := 3.0
		var y := 19.0
		for row in _rows:
			var is_good: bool = bool(row.get("good", true))
			if y + row_h > r.size.y - 5.0:
				break
			var rr := Rect2(Vector2(6.0, y), Vector2(r.size.x - 12.0, row_h))
			WyrdUi.draw_affix_chip(self, rr, is_good)
			var glyph := "✓" if is_good else "✗"
			var gcol: Color = WyrdUi.SAGE.darkened(0.10) if is_good \
				else WyrdUi.TERRACOTTA
			draw_string(font, Vector2(10.0, y + row_h * 0.76),
				glyph, HORIZONTAL_ALIGNMENT_LEFT, 16, 13, gcol)
			draw_string(font, Vector2(23.0, y + row_h * 0.76),
				String(row.get("text", "")),
				HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 30.0, 12, WyrdUi.INK)
			y += row_h + gap
