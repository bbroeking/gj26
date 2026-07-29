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
var _detail_view: Control   # WaystoneAffixDetail — drawn polarity rows
var _go_btn: Button

# Drawn polarity-keyed affix rows for the chart detail block.
# Each row is a WyrdUi.draw_list_row card: SAGE for good affixes,
# TERRACOTTA for bad, INK_MID for a clean (no-affix) chart.
class WaystoneAffixDetail extends Control:
	var _rows: Array = []          # [{good:bool, name:str, desc:str}]
	var _has_selection: bool = false

	const ROW_H := 22.0
	const ROW_GAP := 3.0

	func set_data(rows: Array, has_selection: bool) -> void:
		_rows = rows
		_has_selection = has_selection
		queue_redraw()

	func _draw() -> void:
		if not _has_selection:
			return
		var font := get_theme_default_font()
		var w := size.x
		if _rows.is_empty():
			var r := Rect2(Vector2.ZERO, Vector2(w, ROW_H))
			WyrdUi.draw_list_row(self, r, WyrdUi.INK_MID)
			draw_string(font, Vector2(12.0, 15.0),
				"A clean chart — the way there and back, nothing more.",
				HORIZONTAL_ALIGNMENT_LEFT, w - 20.0, 12, WyrdUi.INK_MID)
			return
		var y := 0.0
		for aff in _rows:
			var r := Rect2(Vector2(0.0, y), Vector2(w, ROW_H))
			var accent := WyrdUi.SAGE if bool(aff.get("good", false)) \
				else WyrdUi.TERRACOTTA
			WyrdUi.draw_list_row(self, r, accent)
			var glyph := "✓ " if bool(aff.get("good", false)) else "✗ "
			draw_string(font,
				Vector2(12.0, y + 15.0),
				glyph + String(aff.get("name", "")) + " — " + String(aff.get("desc", "")),
				HORIZONTAL_ALIGNMENT_LEFT, w - 20.0, 12, WyrdUi.INK)
			y += ROW_H + ROW_GAP

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

	_detail_view = WaystoneAffixDetail.new()
	_detail_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_view.anchor_right = 1.0
	_detail_view.anchor_top = 1.0
	_detail_view.anchor_bottom = 1.0
	_detail_view.offset_left = 52
	_detail_view.offset_right = -52
	_detail_view.offset_top = -150
	_detail_view.offset_bottom = -64
	_panel.add_child(_detail_view)

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
		var aff_rows: Array = []
		for a in chart.get("affixes", []):
			var aff: Dictionary = ChartsData.AFFIXES.get(String(a.get("id", "")), {})
			if aff.is_empty():
				continue
			if bool(a.get("good", false)):
				aff_rows.append({"good": true,
					"name": String(aff.name), "desc": String(aff.good_desc)})
			else:
				aff_rows.append({"good": false,
					"name": String(aff.bad_name), "desc": String(aff.bad_desc)})
		_detail_view.set_data(aff_rows, true)
		_go_btn.disabled = false
	else:
		_detail_view.set_data([], false)
		_go_btn.disabled = true

func _on_go() -> void:
	if _game == null or _selected < 0 or _selected >= (_game.charts as Array).size():
		return
	var chart: Dictionary = _game.charts[_selected]
	get_node("/root/Game").modal_closed()
	_game.enter_dungeon(chart, player)
	queue_free()
