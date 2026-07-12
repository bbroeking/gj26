extends CanvasLayer

# Spec 29 — the 3-buff choice modal a Shrine opens. The whole UI is built in
# script so the .tscn stays a minimal CanvasLayer + script binding. Pauses
# the tree while open so the player can't escape with a movement key; emits
# `chosen(buff)` when the player picks one of the three cards.
#
# Art pass — the outer panel now uses the carved WyrdUi frame, the title is
# set in IM Fell SC / TERRACOTTA, and a drawn _ShrineHeaderArt inner class
# adds parchment grain, an altar-crest medallion (concentric rune rings +
# 8-spoke sunburst + gold diamond), and a section flourish. The three boon
# card buttons are unchanged — they get their own art pass separately.

signal chosen(buff: Dictionary)

var _buffs: Array = []
var _panel: Panel
var _hbox: HBoxContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.6)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	_panel = Panel.new()
	WyrdUi.style_panel(_panel)
	_panel.custom_minimum_size = Vector2(660, 360)
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -330
	_panel.offset_top = -180
	_panel.offset_right = 330
	_panel.offset_bottom = 180
	add_child(_panel)
	var art := _ShrineHeaderArt.new()
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(art)
	var title := Label.new()
	title.text = "An Old Altar Stirs"
	WyrdUi.style_title(title)
	title.position = Vector2(106, 46)
	title.size = Vector2(480, 38)
	_panel.add_child(title)
	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", 20)
	_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_hbox.anchor_left = 0.0
	_hbox.anchor_right = 1.0
	_hbox.anchor_bottom = 1.0
	_hbox.offset_top = 100
	_hbox.offset_bottom = -20
	_hbox.offset_left = 16
	_hbox.offset_right = -16
	_panel.add_child(_hbox)

func setup(buffs: Array) -> void:
	_buffs = buffs
	for c in _hbox.get_children():
		c.queue_free()
	for b in _buffs:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(180, 200)
		btn.text = String(b.name) + "\n\n" + String(b.desc)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_on_pressed.bind(b))
		_hbox.add_child(btn)
	get_node("/root/Game").modal_opened()

func _on_pressed(buff: Dictionary) -> void:
	get_node("/root/Game").modal_closed()
	chosen.emit(buff)
	queue_free()


# Drawn altar-crest header: parchment grain across the header band, a
# circular medallion (concentric rune rings + 8-spoke sunburst + gold diamond)
# to the left of the title, and a full-width flourish below.
class _ShrineHeaderArt extends Control:
	func _ready() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		if size.x < 2.0 or size.y < 2.0:
			return
		var ml := WyrdUi.PANEL_MARGIN_L
		var mt := WyrdUi.PANEL_MARGIN_T
		# Parchment grain across the header band.
		WyrdUi.draw_parchment_grain(self,
			Rect2(Vector2(ml, mt),
				Vector2(size.x - ml - WyrdUi.PANEL_MARGIN_R, 54.0)), 41)
		# Medallion centred in the left margin zone beside the title.
		var mc := Vector2(68.0, mt + 26.0)
		var r_out := 22.0
		# Cream fill so the rings read on any panel background.
		draw_circle(mc, r_out, Color(0.94, 0.89, 0.75))
		# 8-spoke sunburst radiating outward from inner ring to outer ring.
		for i in 8:
			var a := float(i) / 8.0 * TAU
			draw_line(mc + Vector2(cos(a), sin(a)) * 9.5,
				mc + Vector2(cos(a), sin(a)) * 19.5,
				Color(WyrdUi.GOLD, 0.55), 1.0)
		# Three concentric rune rings.
		draw_arc(mc, r_out, 0.0, TAU, 64, Color(WyrdUi.KIT_EDGE, 0.72), 1.8, true)
		draw_arc(mc, 14.0, 0.0, TAU, 48, Color(WyrdUi.GOLD, 0.62), 1.4, true)
		draw_arc(mc, 8.5, 0.0, TAU, 32, Color(WyrdUi.KIT_EDGE, 0.48), 1.0, true)
		# Gold diamond pip at the centre.
		var d := 4.5
		var pts := PackedVector2Array([
			mc + Vector2(0.0, -d), mc + Vector2(d, 0.0),
			mc + Vector2(0.0,  d), mc + Vector2(-d, 0.0),
		])
		draw_colored_polygon(pts, Color(WyrdUi.GOLD, 0.88))
		# Section flourish beneath the title.
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, mt + 52.0),
			size.x * 0.50)
