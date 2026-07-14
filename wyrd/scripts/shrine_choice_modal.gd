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
	# Panel centred on the viewport — carved wood frame from the UI kit.
	_panel = Panel.new()
	WyrdUi.style_panel(_panel)
	_panel.custom_minimum_size = Vector2(680, 340)
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -340
	_panel.offset_top = -170
	_panel.offset_right = 340
	_panel.offset_bottom = 170
	add_child(_panel)
	# Title: IM Fell SC header in terracotta — the altar moment deserves the
	# storybook voice, not the engine default.
	var title := Label.new()
	title.text = "An Old Altar Stirs"
	WyrdUi.style_title(title)
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.offset_top = 18
	title.offset_bottom = 58
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(title)
	# Flourish rule between the title and the boon card row.
	var div := _FlourishRule.new()
	div.anchor_right = 1.0
	div.offset_left = 60
	div.offset_right = -60
	div.offset_top = 58
	div.offset_bottom = 70
	_panel.add_child(div)
	# HBox for the 3 boon cards.
	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", 20)
	_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_hbox.anchor_left = 0.0
	_hbox.anchor_right = 1.0
	_hbox.anchor_bottom = 1.0
	_hbox.offset_top = 76
	_hbox.offset_bottom = -20
	_hbox.offset_left = 20
	_hbox.offset_right = -20
	_panel.add_child(_hbox)

# Populate the modal with the 3 offered buffs and pause the world.
func setup(buffs: Array) -> void:
	_buffs = buffs
	for c in _hbox.get_children():
		c.queue_free()
	for b in _buffs:
		var card := _BoonCard.new()
		card.setup(b)
		card.pressed.connect(_on_pressed.bind(b))
		_hbox.add_child(card)
	get_node("/root/Game").modal_opened()

func _on_pressed(buff: Dictionary) -> void:
	get_node("/root/Game").modal_closed()
	chosen.emit(buff)
	queue_free()


# ---- drawn boon card ----

# Each of the three offering cards. A parchment panel face with a SAGE accent
# stripe (all blessings are good — the accent colour is never ambiguous here),
# the blessing name in terracotta IM Fell SC, a diamond flourish rule beneath
# it, the description in ink body text, and a soft sage leaf-stamp in the
# bottom corner. Hover lights the card; click commits the choice.
class _BoonCard extends Control:
	var _name := ""
	var _desc := ""
	var _buff: Dictionary = {}
	var _hover := false

	signal pressed

	func _init() -> void:
		custom_minimum_size = Vector2(184, 210)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func setup(b: Dictionary) -> void:
		_name = String(b.get("name", "Blessing"))
		_desc = String(b.get("desc", ""))
		_buff = b
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
		# Parchment card face with sage accent stripe (all offerings are blessings).
		WyrdUi.draw_list_row(self, r, WyrdUi.SAGE)
		if _hover:
			draw_rect(r.grow(-1.5), Color(1.0, 1.0, 0.90, 0.12))
		# Sage-tinted name-header band behind the title.
		var header_h := 38.0
		draw_rect(Rect2(r.position + Vector2(6.0, 2.0),
			Vector2(r.size.x - 8.0, header_h - 2.0)),
			Color(WyrdUi.SAGE, 0.11))
		# Blessing name — terracotta, centred. Use get_theme_default_font() for
		# all draw_string calls (the gotcha-safe pattern; Label overrides carry
		# IM Fell, custom draw_string uses whatever the theme provides).
		var font := get_theme_default_font()
		draw_string(font, Vector2(r.size.x * 0.5, 26.0), _name,
			HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 12.0, 17, WyrdUi.TERRACOTTA)
		# Diamond flourish rule under the name (shared WyrdUi language).
		WyrdUi.draw_flourish(self, Vector2(r.size.x * 0.5, header_h + 4.0),
			r.size.x * 0.55)
		# Description in ink colour, top-aligned below the rule.
		draw_multiline_string(font, Vector2(10.0, header_h + 18.0), _desc,
			HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 16.0, 13, 8, WyrdUi.INK)
		# Soft sage leaf-stamp in the bottom-right corner — a quiet visual full
		# stop that marks each card as a gift, not a weapon or a cost.
		var sc := Vector2(r.size.x - 14.0, r.size.y - 14.0)
		draw_circle(sc, 6.5, Color(WyrdUi.SAGE, 0.22))
		draw_arc(sc, 6.5, 0, TAU, 20, Color(WyrdUi.SAGE, 0.55), 1.2, true)
		draw_circle(sc, 2.2, Color(WyrdUi.SAGE, 0.60))


# A centred ── ◆ ── flourish rule, used to mark the threshold between the
# panel title and the boon cards below.
class _FlourishRule extends Control:
	func _draw() -> void:
		WyrdUi.draw_flourish(self, size * 0.5, size.x)
