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
		var aff_count: int = (chart.get("affixes", []) as Array).size()
		var card := _ChartScrollCard.new()
		card.setup(ChartsData.chart_label(chart), aff_count, i == _selected)
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


# ---- drawn chart scroll card (one row) ----
# Replaces the flat style_button list entries. Each card draws:
#   • draw_list_row plate (gold accent when selected, neutral otherwise)
#   • a WyrdUi.draw_scroll icon on the left — sealed while waiting, broken
#     open (unsealed) when chosen — so selection reads as "you've picked it up"
#   • the chart label in ink (gold-darkened when selected)
#   • a small affix-count chip on the right in parchment / warm gold tint
# Template follows _VendorCard / _SkillCard to stay in kit language.
class _ChartScrollCard extends Control:
	const SCROLL_W := 44.0

	var _label := ""
	var _aff_count := 0
	var _selected := false
	var _hover := false

	signal pressed

	func _init() -> void:
		custom_minimum_size = Vector2(0, 56.0)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func setup(chart_label: String, aff_count: int, selected: bool) -> void:
		_label = chart_label
		_aff_count = aff_count
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
		if _selected:
			# warm golden wash over the selected card — it glows off the parchment
			draw_rect(r.grow(-1.5), Color(WyrdUi.GOLD, 0.08))
		elif _hover:
			draw_rect(r.grow(-1.5), Color(1.0, 1.0, 0.90, 0.10))
		# --- scroll icon: sealed = waiting in case; unsealed = chosen ---
		var sr_h := SCROLL_W * 0.72
		var sr := Rect2(Vector2(9.0, (size.y - sr_h) * 0.5),
			Vector2(SCROLL_W, sr_h))
		WyrdUi.draw_scroll(self, sr, not _selected)
		if _selected:
			draw_rect(sr, WyrdUi.GOLD.darkened(0.08), false, 2.0)
		# --- chart label (ink; gold when selected) ---
		var font := get_theme_default_font()
		var tx := sr.end.x + 12.0
		var chip_w := 0.0
		if _aff_count > 0:
			chip_w = 58.0
		var label_col: Color = WyrdUi.GOLD.darkened(0.15) if _selected else WyrdUi.INK
		draw_string(font, Vector2(tx, size.y * 0.5 + 5.0), _label,
			HORIZONTAL_ALIGNMENT_LEFT, size.x - tx - chip_w - 14.0, 15, label_col)
		# --- affix-count chip on the right ---
		if _aff_count > 0:
			var chip_h := 20.0
			var chip_r := Rect2(
				Vector2(size.x - chip_w - 10.0, (size.y - chip_h) * 0.5),
				Vector2(chip_w, chip_h))
			var chip_bg: Color = Color(WyrdUi.GOLD, 0.22) if _selected \
				else Color(0.86, 0.79, 0.66)
			draw_rect(chip_r, chip_bg)
			draw_rect(chip_r, Color(WyrdUi.KIT_EDGE, 0.5), false, 1.0)
			var aff_txt := "%d aff." % _aff_count
			draw_string(font, Vector2(chip_r.position.x, chip_r.position.y + 14.0),
				aff_txt, HORIZONTAL_ALIGNMENT_CENTER, chip_w, 11, WyrdUi.INK_MID)
