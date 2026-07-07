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
		var card := _ChartCard.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.setup(String(chart.get("name", "Chart")),
			int(chart.get("tier", 0)),
			chart.get("affixes", []) as Array,
			i == _selected)
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


# ---- drawn chart-scroll card (one row in the list) ----
# Replaces the plain style_button rows. Each card shows a drawn scroll
# (sealed = has affixes, open = clean run) in a recessed parchment well on the
# left, the chart name in IM Fell, a tier badge, and a secondary affix-names
# line. Gold accent stripe + well ring = selected; warm overlay = hover.
class _ChartCard extends Control:
	var _name := ""
	var _tier := 0
	var _affixes: Array = []
	var _selected := false
	var _hover := false

	signal pressed

	func _init() -> void:
		custom_minimum_size = Vector2(0, 64.0)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func setup(chart_name: String, tier: int, affixes: Array,
			selected: bool) -> void:
		_name = chart_name
		_tier = tier
		_affixes = affixes
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
			# Warm parchment wash so the chosen chart reads as "in hand"
			draw_rect(r.grow(-1.5), Color(WyrdUi.GOLD, 0.07))
		elif _hover:
			draw_rect(r.grow(-1.5), Color(1.0, 1.0, 0.90, 0.10))
		var font := get_theme_default_font()
		var hdr := WyrdUi.font_header()
		if hdr == null:
			hdr = font
		# Drawn scroll in a recessed parchment well — sealed when it has affixes
		const WELL_SZ := 46.0
		var wr := Rect2(Vector2(10.0, (size.y - WELL_SZ) * 0.5),
			Vector2(WELL_SZ, WELL_SZ))
		WyrdUi.draw_well(self, wr, Color(0.95, 0.91, 0.80))
		WyrdUi.draw_scroll(self, wr.grow(-4.0), _affixes.size() > 0)
		if _selected:
			draw_rect(wr, Color(WyrdUi.GOLD, 0.75), false, 2.0)
		# Chart name in IM Fell header font
		var tx := wr.end.x + 12.0
		draw_string(hdr, Vector2(tx, size.y * 0.46),
			_name, HORIZONTAL_ALIGNMENT_LEFT,
			size.x - tx - 72.0, 17, WyrdUi.INK)
		# Tier badge right-aligned
		if _tier > 0:
			draw_string(font, Vector2(size.x - 66.0, size.y * 0.42),
				"Tier %d" % _tier,
				HORIZONTAL_ALIGNMENT_RIGHT, 58.0, 12, WyrdUi.INK_MID)
		# Secondary line: affix names in 11px dim, or "clean run" for slotless
		var aff_text := ""
		for aff in _affixes:
			var aff_data: Dictionary = ChartsData.AFFIXES.get(
				String(aff.get("id", "")), {})
			if aff_data.is_empty():
				continue
			if aff_text != "":
				aff_text += " · "
			aff_text += String(aff_data.name) if bool(aff.get("good", false)) \
				else String(aff_data.bad_name)
		if aff_text == "":
			aff_text = "clean run"
		draw_string(font, Vector2(tx, size.y * 0.80), aff_text,
			HORIZONTAL_ALIGNMENT_LEFT, size.x - tx - 72.0, 11, WyrdUi.INK_MID)
