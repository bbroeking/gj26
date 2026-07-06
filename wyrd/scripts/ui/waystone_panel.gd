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

	_detail = ChartDetailView.new()
	_detail.anchor_right = 1.0
	_detail.anchor_top = 1.0
	_detail.anchor_bottom = 1.0
	_detail.offset_left = 52
	_detail.offset_right = -52
	_detail.offset_top = -162
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
			var is_good := bool(a.get("good", false))
			affix_data.append({
				"name": String(aff.name) if is_good else String(aff.bad_name),
				"desc": String(aff.good_desc) if is_good else String(aff.bad_desc),
				"good": is_good,
			})
		if affix_data.is_empty():
			affix_data.append({"clean": true})
		(_detail as ChartDetailView).set_affixes(affix_data)
		_go_btn.disabled = false
	else:
		(_detail as ChartDetailView).set_affixes([])
		_go_btn.disabled = true

func _on_go() -> void:
	if _game == null or _selected < 0 or _selected >= (_game.charts as Array).size():
		return
	var chart: Dictionary = _game.charts[_selected]
	get_node("/root/Game").modal_closed()
	_game.enter_dungeon(chart, player)
	queue_free()


# Drawn affix cards for the chart detail section. Each affix becomes a
# draw_list_row card with a SAGE stripe for a boon or TERRACOTTA for a bane,
# so polarity reads at a glance without relying on ✓/✗ glyphs alone.
class ChartDetailView extends Control:
	var _affixes: Array = []

	func set_affixes(data: Array) -> void:
		_affixes = data
		queue_redraw()

	func _draw() -> void:
		if _affixes.is_empty():
			return
		var font := WyrdUi.font_body()
		if font == null:
			font = get_theme_default_font()
		var hdr := WyrdUi.font_header()
		if hdr == null:
			hdr = font
		const ROW_H := 22.0
		const GAP := 3.0
		var y := 0.0
		for a in _affixes:
			var r := Rect2(Vector2(0.0, y), Vector2(size.x, ROW_H))
			if a.has("clean"):
				# A clean chart — quiet neutral stripe, dim italic label.
				WyrdUi.draw_list_row(self, r, WyrdUi.INK_MID)
				draw_string(font, Vector2(10.0, y + ROW_H - 5.0),
					"A clean chart — nothing inked in but the way there and back.",
					HORIZONTAL_ALIGNMENT_LEFT, size.x - 14.0, 12, WyrdUi.INK_MID)
			else:
				var is_good: bool = bool(a.get("good", false))
				var accent: Color = WyrdUi.SAGE if is_good else WyrdUi.TERRACOTTA
				WyrdUi.draw_list_row(self, r, accent)
				# Glyph in accent colour so good/bad pops even before reading text.
				var glyph := "✓ " if is_good else "✗ "
				draw_string(hdr, Vector2(10.0, y + ROW_H - 5.0), glyph,
					HORIZONTAL_ALIGNMENT_LEFT, 18.0, 13, accent)
				draw_string(font,
					Vector2(24.0, y + ROW_H - 5.0),
					"%s  —  %s" % [String(a.get("name", "")), String(a.get("desc", ""))],
					HORIZONTAL_ALIGNMENT_LEFT, size.x - 28.0, 12, WyrdUi.INK)
			y += ROW_H + GAP
