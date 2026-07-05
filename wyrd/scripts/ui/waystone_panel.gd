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
		var row := _ChartRow.new()
		row.setup(ChartsData.chart_label(chart), int(chart.get("tier", 1)),
			i == _selected)
		var idx := i
		row.pressed.connect(func():
			_selected = idx
			_render())
		_list_box.add_child(row)
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


# ---- drawn chart row ----
# A clickable Control: draw_list_row plate (GOLD accent when selected), a
# sealed scroll icon on the left, chart name in ink, affix summary below,
# and a tier badge (T1/T2/T3) on the right. Charts ARE scrolls — this read
# makes that literal. Mirrors VendorCard/_SkillCard's self-contained pattern.
class _ChartRow extends Control:
	const SCROLL_W := 50.0
	const SCROLL_H := 38.0

	var _label := ""
	var _tier := 1
	var _selected := false
	var _hover := false

	signal pressed

	func _init() -> void:
		custom_minimum_size = Vector2(0, 54.0)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func setup(chart_label: String, tier: int, selected: bool) -> void:
		_label = chart_label
		_tier = tier
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
			# Warm gold wash on the selected row — chart is active.
			draw_rect(r.grow(-1.5), Color(WyrdUi.GOLD, 0.08))
		elif _hover:
			draw_rect(r.grow(-1.5), Color(1.0, 1.0, 0.90, 0.10))
		# Sealed scroll on the left — the chart IS a scroll.
		var scroll_rect := Rect2(
			Vector2(9.0, (size.y - SCROLL_H) * 0.5),
			Vector2(SCROLL_W, SCROLL_H))
		WyrdUi.draw_scroll(self, scroll_rect, true)
		if _selected:
			# Gold ring around the scroll when this chart is picked.
			draw_rect(scroll_rect, Color(WyrdUi.GOLD, 0.85), false, 2.0)
		# Text area starts after the scroll.
		var tx := scroll_rect.end.x + 10.0
		# Tier badge right-aligned — T1 in terracotta, T3 in gold.
		var tier_col := WyrdUi.GOLD.darkened(0.1) if _tier >= 3 else WyrdUi.TERRACOTTA
		var badge := Rect2(Vector2(size.x - 48.0, (size.y - 22.0) * 0.5),
			Vector2(38.0, 22.0))
		draw_rect(badge, Color(0.93, 0.89, 0.76))
		draw_rect(badge, tier_col, false, 1.5)
		var font := get_theme_default_font()
		draw_string(font, badge.position + Vector2(0.0, 16.0),
			"T%d" % _tier, HORIZONTAL_ALIGNMENT_CENTER, badge.size.x, 12, tier_col)
		# Split "Name — Affixes" so the name is prominent and affixes are dim.
		var sep_idx := _label.find(" — ")
		var name_text := _label.substr(0, sep_idx) if sep_idx >= 0 else _label
		var affix_text := _label.substr(sep_idx + 3) if sep_idx >= 0 else ""
		var text_width := badge.position.x - tx - 8.0
		var name_col := WyrdUi.GOLD.darkened(0.15) if _selected else WyrdUi.INK
		draw_string(font, Vector2(tx, size.y * 0.5 - (3.0 if affix_text != "" else 1.0)),
			name_text, HORIZONTAL_ALIGNMENT_LEFT, text_width, 15, name_col)
		if affix_text != "":
			draw_string(font, Vector2(tx, size.y * 0.5 + 14.0), affix_text,
				HORIZONTAL_ALIGNMENT_LEFT, text_width, 12, WyrdUi.INK_MID)
