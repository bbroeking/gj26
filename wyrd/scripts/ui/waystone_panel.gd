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
		var card := _ChartCard.new()
		card.setup(ChartsData.chart_label(chart),
			chart.get("affixes", []) as Array,
			i == _selected)
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


# ---- the drawn chart card (one row in the Waystone list) ----
# Replaces plain style_button text pills: each chart renders as a rolled
# parchment scroll (sealed when it has affixes) with polarity pips on the
# right (sage = good twin, terracotta = bad) and a gold accent when selected.
class _ChartCard extends Control:
	var _label := ""
	var _affixes: Array = []
	var _selected := false
	var _hover := false

	signal pressed

	func _init() -> void:
		custom_minimum_size = Vector2(0, 52.0)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func setup(chart_label: String, affixes: Array, selected: bool) -> void:
		_label = chart_label
		_affixes = affixes
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
		# Accent: gold = selected, sage/terracotta = affix polarity lean, neutral = clean.
		var good_ct := 0
		var bad_ct := 0
		for a in _affixes:
			if bool(a.get("good", false)):
				good_ct += 1
			else:
				bad_ct += 1
		var accent: Color
		if _selected:
			accent = WyrdUi.GOLD
		elif good_ct > bad_ct:
			accent = WyrdUi.SAGE
		elif bad_ct > good_ct:
			accent = WyrdUi.TERRACOTTA
		else:
			accent = WyrdUi.INK_MID
		WyrdUi.draw_list_row(self, r, accent)
		if _selected:
			draw_rect(r.grow(-1.5), Color(WyrdUi.GOLD, 0.08))
		elif _hover:
			draw_rect(r.grow(-1.5), Color(1.0, 1.0, 0.90, 0.10))
		# Rolled scroll icon on the left — wax-sealed when the chart has affixes.
		var scroll_h := size.y - 12.0
		var sr := Rect2(Vector2(10.0, 6.0), Vector2(scroll_h * 0.80, scroll_h))
		WyrdUi.draw_scroll(self, sr, not _affixes.is_empty())
		# Chart label in ink.
		var font := get_theme_default_font()
		var tx := sr.end.x + 10.0
		var pip_count := mini(_affixes.size(), 4)
		var pip_area := float(pip_count) * 14.0 + 8.0
		draw_string(font, Vector2(tx, size.y * 0.5 + 6.0), _label,
			HORIZONTAL_ALIGNMENT_LEFT, size.x - tx - pip_area, 15, WyrdUi.INK)
		# Polarity pips: coloured dots right-aligned — sage good, terracotta bad.
		if pip_count > 0:
			var pip_x := size.x - 12.0 - float(pip_count - 1) * 14.0
			var pip_y := size.y * 0.5
			for i in pip_count:
				var a: Dictionary = _affixes[i]
				var col: Color = WyrdUi.SAGE if bool(a.get("good", false)) \
					else WyrdUi.TERRACOTTA
				draw_circle(Vector2(pip_x, pip_y), 5.0, col)
				draw_arc(Vector2(pip_x, pip_y), 5.0, 0, TAU, 16,
					WyrdUi.KIT_EDGE, 1.0, true)
				pip_x += 14.0
