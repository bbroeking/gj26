extends CanvasLayer

# Spec 29 — the 3-buff choice modal a Shrine opens. The whole UI is built in
# script so the .tscn stays a minimal CanvasLayer + script binding. Pauses
# the tree while open so the player can't escape with a movement key; emits
# `chosen(buff)` when the player picks one of the three cards.

signal chosen(buff: Dictionary)

var _buffs: Array = []
var _panel: Panel
var _hbox: HBoxContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	# Dim backdrop — also swallows mouse clicks so the player can't click
	# through the modal into the world.
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.6)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	# Panel centred on the viewport — carved wood frame + cream interior.
	_panel = Panel.new()
	_panel.custom_minimum_size = Vector2(660, 320)
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -330
	_panel.offset_top = -160
	_panel.offset_right = 330
	_panel.offset_bottom = 160
	WyrdUi.style_panel(_panel)
	add_child(_panel)
	# Header art overlay — added FIRST so it draws behind the title label.
	var art := _ShrineHeaderArt.new()
	art.anchor_right = 1.0
	art.anchor_bottom = 1.0
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(art)
	# Title — IM Fell SC, terracotta, sits inside the jade header zone.
	var title := Label.new()
	title.text = "An Old Altar Stirs"
	WyrdUi.style_title(title)
	title.add_theme_font_size_override("font_size", 22)
	title.anchor_right = 1.0
	title.offset_left = int(WyrdUi.PANEL_MARGIN_L) + 8
	title.offset_right = -int(WyrdUi.PANEL_MARGIN_R) - 8
	title.offset_top = 42
	title.offset_bottom = 74
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(title)
	# HBox for the 3 blessing cards — starts below the header zone.
	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", 20)
	_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_hbox.anchor_right = 1.0
	_hbox.anchor_bottom = 1.0
	_hbox.offset_left = int(WyrdUi.PANEL_MARGIN_L)
	_hbox.offset_right = -int(WyrdUi.PANEL_MARGIN_R)
	_hbox.offset_top = 90
	_hbox.offset_bottom = -20
	_panel.add_child(_hbox)

# Populate the modal with the 3 offered buffs and pause the world.
func setup(buffs: Array) -> void:
	_buffs = buffs
	for c in _hbox.get_children():
		c.queue_free()
	var idx := 0
	for b in _buffs:
		var card := _ShrineCard.new()
		card.setup(String(b.name), String(b.desc), idx)
		card.pressed.connect(_on_pressed.bind(b))
		_hbox.add_child(card)
		idx += 1
	get_node("/root/Game").modal_opened()

func _on_pressed(buff: Dictionary) -> void:
	get_node("/root/Game").modal_closed()
	chosen.emit(buff)
	queue_free()


# Illustrated 180×200 blessing card: cream parchment face, sage accent stripe,
# jade well + gold gem in a tinted header zone, terracotta name, ink desc.
# Extends Button so keyboard/gamepad focus and the `pressed` signal work
# without any extra input wiring. All visuals in _draw; StyleBoxEmpty clears
# the engine-drawn button background.
class _ShrineCard extends Button:
	var _seed: int = 7

	func setup(bname: String, bdesc: String, idx: int) -> void:
		text = ""
		custom_minimum_size = Vector2(180, 200)
		focus_mode = Control.FOCUS_ALL
		_seed = (abs(bname.hash()) % 997) + 7 + idx * 31
		# Suppress the engine-drawn button styles; we paint everything in _draw.
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			add_theme_stylebox_override(state, StyleBoxEmpty.new())
		# Trigger a redraw when hover state changes so the gold ring appears.
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
		# Name — IM Fell SC, terracotta, 14 px, up to 3 lines.
		var nl := Label.new()
		WyrdUi.style_section(nl)
		nl.add_theme_font_size_override("font_size", 14)
		nl.text = bname
		nl.anchor_right = 1.0
		nl.offset_top = 46
		nl.offset_bottom = 92
		nl.offset_left = 10
		nl.offset_right = -10
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(nl)
		# Description — ink, 12 px, expands to fill the remaining card height.
		var dl := Label.new()
		WyrdUi.style_body(dl, 11)
		dl.text = bdesc
		dl.anchor_right = 1.0
		dl.anchor_bottom = 1.0
		dl.offset_top = 96
		dl.offset_bottom = -12
		dl.offset_left = 12
		dl.offset_right = -12
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dl)

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		# Card body: cream plate, sage left accent stripe, top bevel, ink border.
		WyrdUi.draw_list_row(self, r, WyrdUi.SAGE)
		WyrdUi.draw_parchment_grain(self, r, _seed)
		# Jade-tinted icon zone at the card top (above the name).
		draw_rect(Rect2(Vector2(1.5, 1.5), Vector2(size.x - 3.0, 38.0)),
			Color(WyrdUi.SAGE, 0.11))
		# Jade round well with a gold blessing-gem centred inside.
		var cx := size.x * 0.5
		WyrdUi.draw_round_well(self, Vector2(cx, 19.0), 11.0,
			Color(WyrdUi.SAGE, 0.22))
		var gem := PackedVector2Array([
			Vector2(cx, 12.0), Vector2(cx + 5.5, 19.0),
			Vector2(cx, 26.0), Vector2(cx - 5.5, 19.0),
		])
		draw_colored_polygon(gem, Color(WyrdUi.GOLD, 0.82))
		# Flourish divider between the icon zone and the name text.
		WyrdUi.draw_flourish(self, Vector2(cx, 40.5), size.x * 0.50)
		# Hover state: gold ring + brightened top bevel.
		if is_hovered():
			draw_rect(r.grow(-1.5), Color(WyrdUi.GOLD, 0.28), false, 2.0)
			draw_rect(Rect2(r.position + Vector2(2.0, 1.0),
				Vector2(r.size.x - 4.0, 2.0)), Color(1.0, 1.0, 0.93, 0.45))


# Jade blessing wash + eight-ray altar-rune glyph + flourish over the panel's
# header zone (below the carved wood frame, above the card row).
# Panel is 660×320; carved frame margins: L=34, T=37, R=32, B=40.
class _ShrineHeaderArt extends Control:
	func _draw() -> void:
		if size.x < 2.0 or size.y < 2.0:
			return
		var ml := WyrdUi.PANEL_MARGIN_L
		var mt := WyrdUi.PANEL_MARGIN_T
		var mr := WyrdUi.PANEL_MARGIN_R
		# Zone spans from the carved frame inward to just above the card row.
		var zone := Rect2(Vector2(ml, mt), Vector2(size.x - ml - mr, 52.0))
		# Soft jade wash — the altar's blessing light on the parchment.
		draw_rect(zone, Color(0.42, 0.65, 0.35, 0.14))
		WyrdUi.draw_parchment_grain(self, zone, 67)
		# Flourish divider at the bottom of the header zone.
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, mt + 50.0),
			zone.size.x * 0.68)
		# Altar-rune glyph in the right margin: jade glow halo, eight gold rays,
		# inner ink ring, and a central gold diamond gem.
		var cx := size.x - ml - 46.0
		var cy := mt + 26.0
		# Outer jade glow halo.
		draw_arc(Vector2(cx, cy), 22.0, 0, TAU, 36,
			Color(WyrdUi.SAGE, 0.18), 9.0, true)
		# Four cardinal rays (gold, 2 px — the primary blessing directions).
		for i in 4:
			var a := PI * 0.5 * float(i)
			draw_line(Vector2(cx + cos(a) * 9.0, cy + sin(a) * 9.0),
				Vector2(cx + cos(a) * 21.0, cy + sin(a) * 21.0),
				Color(WyrdUi.GOLD, 0.62), 2.0)
		# Four diagonal rays (gold, 1.2 px — the secondary shimmer).
		for i in 4:
			var a := PI * 0.5 * float(i) + PI * 0.25
			draw_line(Vector2(cx + cos(a) * 7.0, cy + sin(a) * 7.0),
				Vector2(cx + cos(a) * 15.0, cy + sin(a) * 15.0),
				Color(WyrdUi.GOLD, 0.35), 1.2)
		# Inner rune ring (the altar's carved eye).
		draw_arc(Vector2(cx, cy), 16.0, 0, TAU, 32,
			Color(WyrdUi.KIT_EDGE, 0.45), 1.5, true)
		# Central gold diamond gem — the altar's blessing focus.
		var gem := PackedVector2Array([
			Vector2(cx, cy - 5.5), Vector2(cx + 4.5, cy),
			Vector2(cx, cy + 5.5), Vector2(cx - 4.5, cy),
		])
		draw_colored_polygon(gem, Color(WyrdUi.GOLD, 0.88))
