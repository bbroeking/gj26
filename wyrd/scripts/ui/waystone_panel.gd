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
var _detail_box: VBoxContainer   # drawn affix-row cards (replaces plain Label)
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

	# Drawn affix cards — sage stripe for good affixes, terracotta for bad,
	# so the risk/reward of each chart reads at a glance before stepping through.
	# A transparent ScrollContainer clips overflow on 3+-affix charts without
	# cluttering the panel with a scrollbar.
	var detail_scroll := ScrollContainer.new()
	detail_scroll.anchor_right = 1.0
	detail_scroll.anchor_top = 1.0
	detail_scroll.anchor_bottom = 1.0
	detail_scroll.offset_left = 52
	detail_scroll.offset_right = -52
	detail_scroll.offset_top = -150
	detail_scroll.offset_bottom = -64
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_panel.add_child(detail_scroll)
	_detail_box = VBoxContainer.new()
	_detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_box.add_theme_constant_override("separation", 4)
	detail_scroll.add_child(_detail_box)

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
	for c in _detail_box.get_children():
		c.queue_free()
	if _selected >= 0 and _selected < n:
		var chart: Dictionary = _game.charts[_selected]
		var had_affixes := false
		for a in chart.get("affixes", []):
			var aff: Dictionary = ChartsData.AFFIXES.get(String(a.get("id", "")), {})
			if aff.is_empty():
				continue
			had_affixes = true
			var row := _AffixRow.new()
			var is_good := bool(a.get("good", false))
			row.setup(
				String(aff.name if is_good else aff.bad_name),
				String(aff.good_desc if is_good else aff.bad_desc),
				is_good)
			_detail_box.add_child(row)
		if not had_affixes:
			var empty_lbl := Label.new()
			empty_lbl.text = "A clean chart. Nothing inked in but the way there and back."
			WyrdUi.style_dim(empty_lbl, 12)
			empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_detail_box.add_child(empty_lbl)
		_go_btn.disabled = false
	else:
		_go_btn.disabled = true

func _on_go() -> void:
	if _game == null or _selected < 0 or _selected >= (_game.charts as Array).size():
		return
	var chart: Dictionary = _game.charts[_selected]
	get_node("/root/Game").modal_closed()
	_game.enter_dungeon(chart, player)
	queue_free()


# A single drawn affix row: cream plate, left-edge accent stripe in the
# affix's good/bad colour, checkmark/cross glyph, name in ink, description
# in dim ink below. Matches the design language used by vendor and inventory
# item cards (draw_list_row + ink text = carved-shelf feel, not spreadsheet).
class _AffixRow extends Control:
	var _title := ""
	var _desc := ""
	var _good := true

	func setup(title: String, desc: String, good: bool) -> void:
		_title = title
		_desc = desc
		_good = good
		custom_minimum_size = Vector2(0, 40)
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var accent: Color = WyrdUi.SAGE if _good else WyrdUi.TERRACOTTA
		WyrdUi.draw_list_row(self, r, accent)
		var font := get_theme_default_font()
		# Checkmark / cross in the accent colour — the read-at-a-glance signal.
		var mark := "✓" if _good else "✗"
		var mc := WyrdUi.SAGE.darkened(0.2) if _good else WyrdUi.TERRACOTTA
		draw_string(font, Vector2(12.0, 15.0), mark,
			HORIZONTAL_ALIGNMENT_LEFT, 16, 13, mc)
		draw_string(font, Vector2(30.0, 15.0), _title,
			HORIZONTAL_ALIGNMENT_LEFT, size.x - 40.0, 14, WyrdUi.INK)
		draw_string(font, Vector2(30.0, 31.0), _desc,
			HORIZONTAL_ALIGNMENT_LEFT, size.x - 40.0, 11, WyrdUi.INK_MID)
