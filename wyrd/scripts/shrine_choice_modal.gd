extends CanvasLayer

# Spec 29 — the 3-buff choice modal a Shrine opens. The whole UI is built in
# script so the .tscn stays a minimal CanvasLayer + script binding. Pauses
# the tree while open so the player can't escape with a movement key; emits
# `chosen(buff)` when the player picks one of the three cards.
#
# Artistic pass: bare Panel.new() promoted to the carved wood frame
# (WyrdUi.style_panel); title dressed with IM Fell Small Caps + terracotta;
# a _HeaderDecor flourish rule under the title, consistent with the waystone
# and vendor panels.

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
	_panel.custom_minimum_size = Vector2(660, 320)
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -330
	_panel.offset_top = -160
	_panel.offset_right = 330
	_panel.offset_bottom = 160
	add_child(_panel)
	var title := Label.new()
	title.text = "An Old Altar Stirs"
	WyrdUi.style_title(title)
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.offset_top = 34
	title.offset_bottom = 66
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(title)
	# Flourish rule below the title — dresses the header without ornament on
	# the body, consistent with the waystone and vendor panels.
	var hd := _HeaderDecor.new()
	hd.anchor_right = 1.0
	hd.offset_left = 54
	hd.offset_top = 66
	hd.offset_right = -54
	hd.offset_bottom = 80
	_panel.add_child(hd)
	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", 20)
	_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_hbox.anchor_left = 0.0
	_hbox.anchor_right = 1.0
	_hbox.anchor_bottom = 1.0
	_hbox.offset_top = 84
	_hbox.offset_bottom = -20
	_hbox.offset_left = 16
	_hbox.offset_right = -16
	_panel.add_child(_hbox)

# Populate the modal with the 3 offered buffs and pause the world.
func setup(buffs: Array) -> void:
	_buffs = buffs
	for c in _hbox.get_children():
		c.queue_free()
	for b in _buffs:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(180, 180)
		btn.text = String(b.name) + "\n\n" + String(b.desc)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_on_pressed.bind(b))
		_hbox.add_child(btn)
	get_node("/root/Game").modal_opened()

func _on_pressed(buff: Dictionary) -> void:
	get_node("/root/Game").modal_closed()
	chosen.emit(buff)
	queue_free()


# ---- Drawn header ornament ----
# Parchment grain + flourish rule below the panel title — the header reads
# as a sealed proclamation, not a flat label floating in grey space.
class _HeaderDecor extends Control:
	func _draw() -> void:
		WyrdUi.draw_parchment_grain(self, Rect2(Vector2.ZERO, size), 17)
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, size.y * 0.5),
			size.x * 0.65)
