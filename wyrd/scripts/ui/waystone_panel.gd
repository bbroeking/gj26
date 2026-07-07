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

	# Header art — drawn behind the title labels so the crest and flourish rule
	# sit in the right layer order without an extra CanvasLayer.
	var hdr_art := _WaystoneHeaderArt.new()
	hdr_art.anchor_right = 1.0
	hdr_art.offset_top = 28
	hdr_art.offset_bottom = 84
	hdr_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(hdr_art)

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


# Header ornament for the Waystone panel: a portal-star crest left of the
# title (an 8-armed radiant star inside a gold ring — the crossing's seal)
# and a flourish rule just below the subtitle. Pure-vector _draw; no textures.
class _WaystoneHeaderArt extends Control:
	func _draw() -> void:
		if size.x < 2.0 or size.y < 2.0:
			return
		# Portal-star crest, left of "The Waystone".
		# 8-armed star: 4 long cardinal arms + 4 short diagonal arms, in a
		# gold ring with a soft cream halo — the waystone's navigational seal.
		var cx := Vector2(32.0, size.y * 0.5 + 1.0)
		# Soft cream halo so the star sits on the parchment, not punched into it.
		draw_circle(cx, 22.0, Color(0.96, 0.91, 0.78, 0.45))
		# Gold ring + inner ink ring.
		draw_arc(cx, 20.0, 0.0, TAU, 48, WyrdUi.GOLD.darkened(0.08), 2.5, true)
		draw_arc(cx, 13.0, 0.0, TAU, 40, Color(WyrdUi.KIT_EDGE, 0.35), 1.0, true)
		# 8-pointed star arms, clockwise from top.
		for k in 8:
			var angle := float(k) * TAU / 8.0 - PI * 0.5
			var long_arm := k % 2 == 0
			var arm_r := 17.0 if long_arm else 10.0
			var arm_w := 2.0 if long_arm else 1.2
			var arm_col := Color(WyrdUi.GOLD, 0.92) if long_arm \
				else Color(WyrdUi.GOLD, 0.55)
			draw_line(cx, cx + Vector2(cos(angle), sin(angle)) * arm_r,
				arm_col, arm_w)
		# Centre jewel — gold disc with a bright inner point.
		draw_circle(cx, 4.5, WyrdUi.GOLD)
		draw_circle(cx, 2.2, Color(0.97, 0.92, 0.72))
		draw_arc(cx, 4.5, 0.0, TAU, 20, WyrdUi.KIT_EDGE, 1.0, true)
		# Flourish rule centred below the subtitle (at the control's bottom edge).
		WyrdUi.draw_flourish(self,
			Vector2(size.x * 0.5 + 24.0, size.y - 3.0), size.x - 140.0)
