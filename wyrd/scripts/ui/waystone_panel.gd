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
	# Header art — portal crest disc + flourish divider. Rendered first so
	# the text labels sit in front of it (Godot draws children in add order).
	var hdr_art := _WaystoneHeaderArt.new()
	hdr_art.anchor_right = 1.0
	hdr_art.custom_minimum_size = Vector2(0, 86)
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


# Header ornament — pure-vector, no textures (white-rect-in-_draw safe).
# Draws a portal-stone crest disc left of the title and a flourish rule
# dividing the header from the chart list, so the Waystone reads as a
# properly framed proclamation rather than a bare widget.
class _WaystoneHeaderArt extends Control:
	func _draw() -> void:
		# --- portal crest disc (centre left of title) ---
		# A round parchment seal bearing a stone arch — the mouth of the
		# dungeon portal, inked in the UI kit's sepia and burnished gold.
		var dc := Vector2(28.0, 50.0)
		var r := 20.0
		# Outer halo (echo ring) — a ghost of the ink ring, slightly larger.
		draw_arc(dc, r + 3.5, 0.0, TAU, 48, Color(WyrdUi.KIT_EDGE, 0.18), 2.0, true)
		# Parchment face.
		draw_circle(dc, r, WyrdUi.KIT_PLATE)
		# Warm bevel: top-left light arc, bottom-right shade.
		draw_arc(dc, r - 3.5, PI * 0.9, PI * 1.9, 22,
			Color(1.0, 1.0, 0.92, 0.40), 3.0, true)
		draw_arc(dc, r - 3.5, -PI * 0.1, PI * 0.9, 22,
			Color(WyrdUi.KIT_EDGE, 0.18), 3.0, true)
		# Ink border ring.
		draw_arc(dc, r, 0.0, TAU, 48, WyrdUi.KIT_EDGE, 2.0, true)
		# Stone arch inside the disc — two pillars + a semicircular vault.
		# All coords are offset from dc. Arch centre sits at (0, +3).
		var arch_c := dc + Vector2(0.0, 3.0)
		var arch_r := 9.0
		var pillar_half := 2.5
		# Left pillar.
		draw_rect(Rect2(arch_c + Vector2(-arch_r - pillar_half, 0.0),
			Vector2(pillar_half * 2.0, arch_r + 2.0)), WyrdUi.KIT_EDGE)
		# Right pillar.
		draw_rect(Rect2(arch_c + Vector2(arch_r - pillar_half, 0.0),
			Vector2(pillar_half * 2.0, arch_r + 2.0)), WyrdUi.KIT_EDGE)
		# Threshold sill spanning both pillars at the base.
		draw_rect(Rect2(arch_c + Vector2(-arch_r - pillar_half, arch_r),
			Vector2((arch_r + pillar_half) * 2.0, 2.5)), WyrdUi.KIT_EDGE)
		# Vault arch — thick sepia arc from left to right pillar top.
		draw_arc(arch_c, arch_r, PI, TAU, 32, WyrdUi.KIT_EDGE, 4.0, false)
		# Keystone disc at the apex — burnished gold, the portal's heartstone.
		var ks := arch_c + Vector2(0.0, -arch_r)
		draw_circle(ks, 3.5, WyrdUi.GOLD)
		draw_arc(ks, 3.5, 0.0, TAU, 16, Color(WyrdUi.KIT_EDGE, 0.65), 1.0, true)
		# Void passage inside the arch — dark parchment hollow.
		draw_arc(arch_c, arch_r - 4.5, PI, TAU, 28,
			Color(WyrdUi.KIT_WELL, 0.6), 3.0, false)
		# --- flourish rule below the subtitle, above the list ---
		# Centres on the panel width; the Control is anchored anchor_right=1 so
		# size.x equals the panel's content width.
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, 78.0), 280.0)
