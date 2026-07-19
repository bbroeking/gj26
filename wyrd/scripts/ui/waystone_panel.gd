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

	# Compass-rose crest disc — left of header, Wayfinding motif (spec: every
	# panel header carries a trade-specific crest, Waystone = cartographer's compass).
	var crest := WaystoneCrest.new()
	crest.position = Vector2(44, 18)
	crest.size = Vector2(56, 56)
	_panel.add_child(crest)

	var title := Label.new()
	title.text = "The Waystone"
	WyrdUi.style_title(title)
	title.position = Vector2(108, 32)
	_panel.add_child(title)

	var sub := Label.new()
	sub.text = "Socket a chart. The crossing spends it."
	WyrdUi.style_dim(sub, 13)
	sub.position = Vector2(108, 66)
	_panel.add_child(sub)

	# Flourish rule — ink ── ◆ ── divider under the header, matching all other
	# kit panels (vendor, bench, loadout, lantern all carry one).
	var fl := WaystoneFlourish.new()
	fl.position = Vector2(52, 84)
	fl.size = Vector2(496, 12)
	_panel.add_child(fl)

	# A full chart case outgrows the panel — the list scrolls now,
	# bounded above the detail block.
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = 52
	scroll.offset_top = 104
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


# A compass-rose disc for the Waystone header. Eight arms: four cardinal
# lozenges (N in terracotta, E/S/W in gold) + four diagonal short ticks.
# Carved parchment disc from WyrdUi.draw_round_well so it matches the
# kit language (bench quill, vendor smith, loadout arrows, etc.).
class WaystoneCrest extends Control:
	func _draw() -> void:
		var c := size * 0.5
		var r := minf(c.x, c.y) - 2.0

		# Carved parchment disc background
		WyrdUi.draw_round_well(self, c, r, WyrdUi.KIT_PLATE)

		# Soft gold inner accent ring
		draw_arc(c, r - 5.0, 0.0, TAU, 36, Color(WyrdUi.GOLD, 0.40), 1.2, true)

		# Compass rose arm dimensions
		var arm := r * 0.60     # cardinal arm reach
		var lobe := arm * 0.32  # lozenge half-width at midpoint
		var arm_s := r * 0.32   # diagonal tick reach

		# Four cardinal lozenges: N (terracotta) / E S W (gold)
		for i in 4:
			var a := float(i) * PI * 0.5 - PI * 0.5  # i=0 → North (-PI/2)
			var dir := Vector2(cos(a), sin(a))
			var perp := Vector2(-sin(a), cos(a))
			var ip := c + dir * (r * 0.10)        # inner base of lozenge
			var tp := c + dir * arm               # outer tip
			var mp := c + dir * (arm * 0.50)      # widest point
			var col := WyrdUi.TERRACOTTA if i == 0 else WyrdUi.GOLD
			var alpha := 0.88 if i == 0 else 0.72
			draw_colored_polygon(PackedVector2Array([
				ip, mp - perp * lobe, tp, mp + perp * lobe
			]), Color(col, alpha))
			draw_polyline(PackedVector2Array([
				ip, mp - perp * lobe, tp, mp + perp * lobe, ip
			]), Color(WyrdUi.INK, 0.22), 1.0)

		# Four diagonal short ticks (NE / SE / SW / NW)
		for i in 4:
			var a := float(i) * PI * 0.5 - PI * 0.25
			var dir := Vector2(cos(a), sin(a))
			draw_line(c + dir * (r * 0.15), c + dir * arm_s,
				Color(WyrdUi.GOLD, 0.35), 1.3)

		# Centre pivot pip
		draw_circle(c, 3.5, WyrdUi.GOLD)
		draw_circle(c, 1.8, WyrdUi.INK)


# Thin flourish rule drawn under the Waystone header, matching every other
# kit panel (draw_flourish draws  ── ◆ ──  centred on the control).
class WaystoneFlourish extends Control:
	func _draw() -> void:
		WyrdUi.draw_flourish(self, size * 0.5, size.x * 0.88)
