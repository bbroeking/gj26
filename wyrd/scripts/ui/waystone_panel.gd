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
	var rule := _FlourishRule.new()
	rule.position = Vector2(54, 84)
	rule.size = Vector2(260, 6)
	_panel.add_child(rule)

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
		card.setup(chart, i == _selected)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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


# ---- drawn chart scroll card (one row in the case list) ----
# draw_list_row plate (gold accent when selected), scroll-in-a-well on the
# left (sealed when affixes are inked), chart name in IM Fell SC, tier chip
# top-right, and sage/terracotta pip dots on the right for an instant risk
# read. Fully self-contained — callers hand it everything it draws.
class _ChartCard extends Control:
	const WELL_W := 34.0
	const WELL_H := 44.0

	var _chart: Dictionary = {}
	var _selected := false
	var _hover := false

	signal pressed

	func _init() -> void:
		custom_minimum_size = Vector2(0, 64.0)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func setup(chart: Dictionary, selected: bool) -> void:
		_chart = chart
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
		var accent: Color = WyrdUi.GOLD if _selected else WyrdUi.INK_MID
		WyrdUi.draw_list_row(self, r, accent)
		if _hover and not _selected:
			draw_rect(r.grow(-1.5), Color(1.0, 1.0, 0.90, 0.10))

		# --- scroll icon well on the left ---
		var wy := (size.y - WELL_H) * 0.5
		var ir := Rect2(Vector2(9.0, wy), Vector2(WELL_W, WELL_H))
		WyrdUi.draw_well(self, ir, Color(0.95, 0.91, 0.80))
		# sealed = chart has affixes (the wax seal reads "something inked in")
		var has_affixes := not (_chart.get("affixes", []) as Array).is_empty()
		WyrdUi.draw_scroll(self, ir.grow(-3.0), has_affixes)
		# gold ring when this chart is chosen
		if _selected:
			draw_rect(ir, WyrdUi.GOLD, false, 2.0)

		# --- chart name in IM Fell SC (storybook header language) ---
		var font: Font = WyrdUi.font_header()
		if font == null:
			font = get_theme_default_font()
		var tx := ir.end.x + 11.0
		var name_col: Color = WyrdUi.TERRACOTTA if _selected else WyrdUi.INK
		draw_string(font, Vector2(tx, 26.0), String(_chart.get("name", "Chart")),
			HORIZONTAL_ALIGNMENT_LEFT, size.x - tx - 44.0, 16, name_col)

		# --- tier chip (top-right corner) ---
		var chip := Rect2(Vector2(size.x - 36.0, 9.0), Vector2(28.0, 16.0))
		draw_rect(chip, WyrdUi.KIT_WELL)
		draw_rect(chip, Color(WyrdUi.KIT_EDGE, 0.55), false, 1.0)
		draw_string(font, Vector2(chip.position.x, chip.position.y + 12.0),
			"T%d" % int(_chart.get("tier", 1)),
			HORIZONTAL_ALIGNMENT_CENTER, chip.size.x, 11, WyrdUi.INK_MID)

		# --- affix pips: sage circles = good affixes, terracotta = bad ---
		# Two rows on the right; gives an instant risk read without text.
		var affixes: Array = _chart.get("affixes", [])
		var good_count := 0
		var bad_count := 0
		for a in affixes:
			if bool(a.get("good", false)):
				good_count += 1
			else:
				bad_count += 1
		_draw_pips(WyrdUi.SAGE, good_count, size.y * 0.32)
		_draw_pips(WyrdUi.TERRACOTTA, bad_count, size.y * 0.68)

	func _draw_pips(col: Color, count: int, py: float) -> void:
		if count == 0:
			return
		var pip_r := 4.5
		var gap := 11.0
		var total_w := float(count - 1) * gap + pip_r * 2.0
		var px_start := size.x - 14.0 - total_w + pip_r
		for i in count:
			var cx := px_start + float(i) * gap
			draw_circle(Vector2(cx, py), pip_r, col)
			draw_arc(Vector2(cx, py), pip_r, 0.0, TAU, 16, WyrdUi.KIT_EDGE, 1.0, true)


# ---- header flourish rule drawn under the Waystone subtitle ----
class _FlourishRule extends Control:
	func _draw() -> void:
		WyrdUi.draw_flourish(self, size * 0.5, size.x * 0.72)
