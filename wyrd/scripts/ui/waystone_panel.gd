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
var _arch  # _GatewayArch sits above the CTA

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

	# Drawn stone gateway arch — two pillar stubs + semicircle + gold rune.
	# Sits between the detail block and the CTA to frame dungeon entry as a
	# ritual crossing rather than just a button press.
	var arch := _GatewayArch.new()
	arch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arch.anchor_left = 0.5
	arch.anchor_top = 1.0
	arch.anchor_right = 0.5
	arch.anchor_bottom = 1.0
	arch.offset_left = -120
	arch.offset_top = -144
	arch.offset_right = 120
	arch.offset_bottom = -58
	_panel.add_child(arch)
	_arch = arch

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
	# Sync the arch rune: gold when a chart is slotted, stone-dim otherwise.
	if _arch != null:
		_arch.enabled = not _go_btn.disabled
		_arch.queue_redraw()

func _on_go() -> void:
	if _game == null or _selected < 0 or _selected >= (_game.charts as Array).size():
		return
	var chart: Dictionary = _game.charts[_selected]
	get_node("/root/Game").modal_closed()
	_game.enter_dungeon(chart, player)
	queue_free()


# ---- drawn gateway arch (pure vector, no textures — white-rect-safe) ----
# Two carved pillar stubs bracket a semicircular arch. A gold waypoint rune
# sits at the keystone: dim stone when the socket is empty, burnished gold
# once a chart is chosen. The arch is a visual threshold; the CTA lives
# directly below it.
class _GatewayArch extends Control:
	var enabled := false  # rune glows gold when a chart is slotted

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var cx := w * 0.5
		var feet_y := h - 6.0       # spring line: where arch meets pillar tops
		var arch_r := feet_y - 6.0  # semicircle radius → crown 6 px from top
		var pw := 18.0               # pillar stub width
		var ph := 9.0                # pillar stub height below spring line

		# Carved stone pillar stubs — one each side of the arch opening
		for i in 2:
			var side := 1.0 if i == 1 else -1.0
			var ix := cx + side * arch_r   # inner face of this pillar
			var lx := ix - side * pw        # outer edge
			var pr := Rect2(Vector2(minf(ix, lx), feet_y),
				Vector2(pw, ph + 2.0))
			draw_rect(pr, WyrdUi.KIT_PLATE.darkened(0.10))
			# Top bevel catch-light (stone catches the warm page light)
			draw_rect(Rect2(pr.position + Vector2(1.5, 1.5),
				Vector2(pw - 3.0, 2.0)), Color(1.0, 1.0, 0.93, 0.42))
			draw_rect(pr, WyrdUi.KIT_EDGE, false, 1.5)

		# Outer arch ring (ink edge) — PI → TAU traces left foot → crown → right foot
		draw_arc(Vector2(cx, feet_y), arch_r, PI, TAU, 40,
			Color(WyrdUi.KIT_EDGE, 0.62), 2.5, true)
		# Under-face of the arch (warm lit stone, slightly inset)
		draw_arc(Vector2(cx, feet_y), arch_r - 5.0, PI + 0.08, TAU - 0.08, 36,
			Color(WyrdUi.CREAM, 0.38), 3.0, true)

		# Waypoint rune at the keystone (crown of the arch)
		var kc := Vector2(cx, 6.0)
		var ks := 7.0
		# Warm gold halo when a chart is slotted — the portal is open
		if enabled:
			draw_circle(kc, ks * 2.8, Color(WyrdUi.GOLD, 0.14))
		var rune_col := Color(WyrdUi.GOLD, 0.84) if enabled \
			else Color(WyrdUi.KIT_EDGE, 0.42)
		var pts := PackedVector2Array([
			kc + Vector2(0.0, -ks), kc + Vector2(ks, 0.0),
			kc + Vector2(0.0, ks),  kc + Vector2(-ks, 0.0)])
		draw_colored_polygon(pts, rune_col)
		draw_polyline(pts + PackedVector2Array([pts[0]]),
			Color(WyrdUi.KIT_EDGE, 0.55), 1.0, true)
		# Specular catch-light on the rune (same gem-pip language as cursor)
		if enabled:
			draw_circle(kc + Vector2(-ks * 0.28, -ks * 0.32),
				ks * 0.22, Color(1.0, 1.0, 1.0, 0.50))
