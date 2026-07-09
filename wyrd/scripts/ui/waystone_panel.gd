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
var _detail: Control
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

	_detail = _DetailPane.new()
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
		var affix_data: Array = []
		for a in chart.get("affixes", []):
			var aff: Dictionary = ChartsData.AFFIXES.get(String(a.get("id", "")), {})
			if aff.is_empty():
				continue
			var good: bool = bool(a.get("good", false))
			var text: String = "%s — %s" % [String(aff.name), String(aff.good_desc)] \
				if good else "%s — %s" % [String(aff.bad_name), String(aff.bad_desc)]
			affix_data.append({"text": text, "good": good})
		_detail.set_data(affix_data, true)
		_go_btn.disabled = false
	else:
		_detail.set_data([], false)
		_go_btn.disabled = true

func _on_go() -> void:
	if _game == null or _selected < 0 or _selected >= (_game.charts as Array).size():
		return
	var chart: Dictionary = _game.charts[_selected]
	get_node("/root/Game").modal_closed()
	_game.enter_dungeon(chart, player)
	queue_free()


# ---- the drawn affix detail pane ----
# Replaces the plain body Label. Draws a parchment well with a gold flourish
# divider, then each affix with a painted indicator: sage diamond ◆ for
# favourable twists, terracotta × for curses — so the "deal" reads at a glance.
class _DetailPane extends Control:
	var _affixes: Array = []   # [{text: String, good: bool}]
	var _selected := false

	func set_data(affixes: Array, selected: bool) -> void:
		_affixes = affixes
		_selected = selected
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		# Carved-well face so the affix card reads as inked onto aged parchment.
		WyrdUi.draw_well(self, r)
		WyrdUi.draw_parchment_grain(self, r, 31)
		# Gold flourish divider marks the top of the note-card.
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, 14.0), size.x * 0.65)
		var font := get_theme_default_font()
		if not _selected:
			draw_string(font,
				Vector2(0.0, size.y * 0.5 + 5.0),
				"Select a chart above to see its affixes.",
				HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, WyrdUi.INK_MID)
			return
		if _affixes.is_empty():
			draw_string(font,
				Vector2(0.0, size.y * 0.5 + 5.0),
				"A clean chart — nothing inked but the way there and back.",
				HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, WyrdUi.INK_MID)
			return
		var y := 28.0
		for a in _affixes:
			var good: bool = bool(a.get("good", false))
			var ix := 14.0
			var iy := y - 5.0
			if good:
				# Sage diamond ◆ — a favourable tide on the run
				var pts := PackedVector2Array([
					Vector2(ix, iy - 5.5),
					Vector2(ix + 5.5, iy),
					Vector2(ix, iy + 5.5),
					Vector2(ix - 5.5, iy)])
				draw_colored_polygon(pts, WyrdUi.SAGE)
				draw_polyline(pts + PackedVector2Array([pts[0]]),
					WyrdUi.SAGE.darkened(0.3), 1.0, true)
			else:
				# Terracotta × — the run's inscribed curse
				draw_line(Vector2(ix - 4.5, iy - 4.5),
					Vector2(ix + 4.5, iy + 4.5), WyrdUi.TERRACOTTA, 2.0, true)
				draw_line(Vector2(ix + 4.5, iy - 4.5),
					Vector2(ix - 4.5, iy + 4.5), WyrdUi.TERRACOTTA, 2.0, true)
			var col: Color = WyrdUi.SAGE.darkened(0.15) if good \
				else WyrdUi.TERRACOTTA.darkened(0.05)
			draw_string(font, Vector2(24.0, y),
				String(a.get("text", "")),
				HORIZONTAL_ALIGNMENT_LEFT, size.x - 30.0, 12, col)
			y += 17.0
