extends CanvasLayer

# Wyrd — the Waystone socket modal. Lists the chart case; picking one and
# pressing "Step through" consumes it and crosses into the dungeon it
# describes. Esc closes.
#
# Art pass: chart list rows are now drawn _ChartCard controls —
# scroll icon + name + affix-pip diamonds (SAGE good / TERRACOTTA bad).
# A gateway arch sigil sits in the top-right header area and a flourish
# rule runs under the subtitle.

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

	# gateway arch sigil — top-right header area
	var arch := _WaystoneArch.new()
	arch.position = Vector2(432, 8)
	arch.custom_minimum_size = Vector2(88, 88)
	arch.size = Vector2(88, 88)
	arch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(arch)

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

	# flourish rule under the subtitle
	var flr := _Flourish.new()
	flr.position = Vector2(52, 86)
	flr.custom_minimum_size = Vector2(420, 12)
	flr.size = Vector2(420, 12)
	flr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(flr)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = 52
	scroll.offset_top = 102
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
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.setup(chart, ChartsData.chart_label(chart), i == _selected)
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


# ---- drawn chart card (one list row) ----
# draw_list_row plate with a painted scroll on the left and affix-pip
# diamonds below the name (SAGE = good twin, TERRACOTTA = bad twin).
# Selected = gold accent stripe + gold outline ring.
class _ChartCard extends Control:
	const SCROLL_W := 42.0

	var _chart: Dictionary = {}
	var _label: String = ""
	var _picked: bool = false
	var _good_n: int = 0
	var _bad_n: int = 0
	var _hover: bool = false

	signal pressed

	func _init() -> void:
		custom_minimum_size = Vector2(0, 58.0)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func setup(chart: Dictionary, label: String, picked: bool) -> void:
		_chart = chart
		_label = label
		_picked = picked
		_good_n = 0
		_bad_n = 0
		for a in chart.get("affixes", []):
			if bool(a.get("good", false)):
				_good_n += 1
			else:
				_bad_n += 1
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
		var accent: Color = WyrdUi.GOLD if _picked else WyrdUi.INK_MID
		WyrdUi.draw_list_row(self, r, accent)
		if _hover and not _picked:
			draw_rect(r.grow(-1.5), Color(1.0, 1.0, 0.90, 0.10))
		if _picked:
			draw_rect(r.grow(-2.5), Color(WyrdUi.GOLD, 0.45), false, 1.5)
		# painted scroll icon on the left
		var ir := Rect2(Vector2(9.0, (size.y - SCROLL_W) * 0.5),
			Vector2(SCROLL_W, SCROLL_W))
		WyrdUi.draw_scroll(self, ir, true)
		# chart name
		var font := get_theme_default_font()
		var tx := ir.end.x + 12.0
		draw_string(font, Vector2(tx, 24.0), _label,
			HORIZONTAL_ALIGNMENT_LEFT, size.x - tx - 8.0, 15, WyrdUi.INK)
		# affix pip diamonds below the name
		var total := _good_n + _bad_n
		if total > 0:
			var px := tx
			var py := 42.0
			for _i in _good_n:
				_draw_pip(Vector2(px + 4.5, py), WyrdUi.SAGE)
				px += 12.0
			for _i in _bad_n:
				_draw_pip(Vector2(px + 4.5, py), WyrdUi.TERRACOTTA)
				px += 12.0
		else:
			draw_string(font, Vector2(tx, 43.0), "clean chart",
				HORIZONTAL_ALIGNMENT_LEFT, 90.0, 11,
				Color(WyrdUi.INK_MID, 0.65))

	func _draw_pip(center: Vector2, col: Color) -> void:
		var pts := PackedVector2Array([
			center + Vector2(0.0, -4.5), center + Vector2(4.5, 0.0),
			center + Vector2(0.0,  4.5), center + Vector2(-4.5, 0.0)])
		draw_colored_polygon(pts, Color(col, 0.80))
		draw_line(pts[0], pts[1], col.darkened(0.3), 1.0)
		draw_line(pts[1], pts[2], col.darkened(0.3), 1.0)
		draw_line(pts[2], pts[3], col.darkened(0.3), 1.0)
		draw_line(pts[3], pts[0], col.darkened(0.3), 1.0)


# ---- gateway arch sigil (header ornament) ----
class _WaystoneArch extends Control:
	func _draw() -> void:
		WyrdUi.draw_waystone_arch(self, size * 0.5, minf(size.x, size.y))


# ---- section flourish (rule under subtitle) ----
class _Flourish extends Control:
	func _draw() -> void:
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, size.y * 0.5),
			size.x * 0.92)
