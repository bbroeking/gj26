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

	_detail = _AffixDetail.new()
	_detail.anchor_right = 1.0
	_detail.anchor_top = 1.0
	_detail.anchor_bottom = 1.0
	_detail.offset_left = 52
	_detail.offset_right = -52
	_detail.offset_top = -156
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
		var entries: Array = []
		for a in chart.get("affixes", []):
			var aff: Dictionary = ChartsData.AFFIXES.get(String(a.get("id", "")), {})
			if aff.is_empty():
				continue
			if bool(a.get("good", false)):
				entries.append({"good": true,
					"name": String(aff.name), "desc": String(aff.good_desc)})
			else:
				entries.append({"good": false,
					"name": String(aff.bad_name), "desc": String(aff.bad_desc)})
		_detail.set_entries(entries)
		_go_btn.disabled = false
	else:
		_detail.set_entries([])
		_go_btn.disabled = true

func _on_go() -> void:
	if _game == null or _selected < 0 or _selected >= (_game.charts as Array).size():
		return
	var chart: Dictionary = _game.charts[_selected]
	get_node("/root/Game").modal_closed()
	_game.enter_dungeon(chart, player)
	queue_free()


# ---- drawn affix-detail strip ----
# Replaces the plain Label: each affix gets a small list-row card with a
# coloured left stripe (sage = boon, terracotta = bane) and a roundel glyph.
class _AffixDetail extends Control:
	const CARD_H := 36.0
	const CARD_GAP := 5.0
	const ROUNDEL_R := 9.0

	var _entries: Array = []

	func set_entries(entries: Array) -> void:
		_entries = entries
		var h := 0.0
		if not entries.is_empty():
			h = entries.size() * (CARD_H + CARD_GAP) - CARD_GAP
		custom_minimum_size = Vector2(0, max(h, 24.0))
		queue_redraw()

	func _draw() -> void:
		var font := get_theme_default_font()
		var w := size.x
		if _entries.is_empty():
			draw_string(font, Vector2(0.0, 16.0),
				"A clean chart. Nothing inked in but the way there and back.",
				HORIZONTAL_ALIGNMENT_LEFT, w, 13, WyrdUi.INK_MID)
			return
		var y := 0.0
		for entry in _entries:
			var good: bool = bool(entry.get("good", true))
			var accent: Color = WyrdUi.SAGE if good else WyrdUi.TERRACOTTA
			var glyph := "✓" if good else "✗"
			var name_str := String(entry.get("name", ""))
			var desc_str := String(entry.get("desc", ""))
			var r := Rect2(Vector2(0.0, y), Vector2(w, CARD_H))
			WyrdUi.draw_list_row(self, r, accent)
			# roundel with ✓/✗
			var cx := ROUNDEL_R + 9.0
			var cy := y + CARD_H * 0.5
			draw_circle(Vector2(cx, cy), ROUNDEL_R, accent.darkened(0.15))
			draw_arc(Vector2(cx, cy), ROUNDEL_R, 0, TAU, 20, accent.darkened(0.35), 1.2)
			draw_string(font, Vector2(cx - ROUNDEL_R + 2.0, cy + 5.0), glyph,
				HORIZONTAL_ALIGNMENT_CENTER, ROUNDEL_R * 2.0 - 4.0, 11,
				Color(1.0, 1.0, 1.0, 0.92))
			# name + desc
			var tx := cx + ROUNDEL_R + 10.0
			draw_string(font, Vector2(tx, y + 14.0), name_str,
				HORIZONTAL_ALIGNMENT_LEFT, w - tx - 6.0, 13, WyrdUi.INK)
			draw_string(font, Vector2(tx, y + 28.0), desc_str,
				HORIZONTAL_ALIGNMENT_LEFT, w - tx - 6.0, 11, WyrdUi.INK_MID)
			y += CARD_H + CARD_GAP
