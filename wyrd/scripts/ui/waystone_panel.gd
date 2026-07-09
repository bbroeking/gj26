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
		var good_c := 0
		var bad_c := 0
		for a in chart.get("affixes", []):
			if bool(a.get("good", false)):
				good_c += 1
			else:
				bad_c += 1
		var card := _ChartCard.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.setup(ChartsData.chart_label(chart), good_c, bad_c, i == _selected)
		var idx := i
		card.pressed.connect(func():
			_selected = idx
			_render())
		_list_box.add_child(card)
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


# ---- drawn chart row: scroll icon + name + polarity pips ----
# Each chart in the case deserves more than a plain button — it is a
# parameterised dungeon key, hand-inscribed on parchment. This card reads
# as a mini scroll: draw_list_row plate, a small rolled scroll on the left
# (sealed with wax when selected), the chart name, and one jade pip per
# good affix + one terracotta pip per bad affix on the right edge so the
# run's risk profile is legible at a glance without opening the detail pane.
class _ChartCard extends Control:
	var _chart_label := ""
	var _good_count := 0
	var _bad_count := 0
	var _selected := false
	var _hover := false

	signal pressed

	func _init() -> void:
		custom_minimum_size = Vector2(0, 50.0)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func setup(chart_label: String, good: int, bad: int, selected: bool) -> void:
		_chart_label = chart_label
		_good_count = good
		_bad_count = bad
		_selected = selected
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
		var accent := WyrdUi.GOLD if _selected else WyrdUi.INK_MID
		WyrdUi.draw_list_row(self, r, accent)
		if _selected:
			# Warm gold wash so the active chart reads clearly chosen.
			draw_rect(r.grow(-1.5), Color(WyrdUi.GOLD, 0.07))
		elif _hover:
			draw_rect(r.grow(-1.5), Color(1.0, 1.0, 0.90, 0.08))
		# Mini scroll icon — sealed with wax when selected (ready to socket).
		var scroll_r := Rect2(Vector2(9.0, (size.y - 32.0) * 0.5),
			Vector2(36.0, 32.0))
		WyrdUi.draw_scroll(self, scroll_r, _selected)
		# Chart name — gold when selected, ink otherwise.
		var font := get_theme_default_font()
		var pip_space := (_good_count + _bad_count) * 12.0 + 10.0
		var name_col: Color = WyrdUi.GOLD.darkened(0.08) if _selected else WyrdUi.INK
		draw_string(font,
			Vector2(scroll_r.end.x + 10.0, size.y * 0.5 + 5.0),
			_chart_label,
			HORIZONTAL_ALIGNMENT_LEFT,
			size.x - scroll_r.end.x - pip_space - 16.0,
			15, name_col)
		# Polarity pips right-aligned: terracotta = bad affix, jade = good.
		# Bad affixes drawn first (furthest right) so they catch the eye.
		var pip_x := size.x - 12.0
		for _i in _bad_count:
			draw_circle(Vector2(pip_x, size.y * 0.5), 4.0,
				Color(WyrdUi.TERRACOTTA, 0.80))
			pip_x -= 12.0
		for _i in _good_count:
			draw_circle(Vector2(pip_x, size.y * 0.5), 4.0,
				Color(WyrdUi.SAGE, 0.85))
			pip_x -= 12.0
