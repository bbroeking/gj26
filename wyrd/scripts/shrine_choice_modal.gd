extends CanvasLayer

# Spec 29 — the 3-buff choice modal a Shrine opens. The whole UI is built in
# script so the .tscn stays a minimal CanvasLayer + script binding. Pauses
# the tree while open so the player can't escape with a movement key; emits
# `chosen(buff)` when the player picks one of the three cards.
#
# Phase 1 restyling — uses WyrdUi parchment kit (style_panel, style_title,
# draw_list_row) matching the Loadout panel's visual weight.

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
	# Panel centred on the viewport — styled with the WyrdUi parchment kit.
	_panel = Panel.new()
	WyrdUi.style_panel(_panel)
	_panel.custom_minimum_size = Vector2(700, 340)
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -350
	_panel.offset_top = -170
	_panel.offset_right = 350
	_panel.offset_bottom = 170
	add_child(_panel)
	# Title — WyrdUi terracotta header font (matches Loadout panel inset).
	var title := Label.new()
	title.text = "An Old Altar Stirs"
	WyrdUi.style_title(title)
	title.position = Vector2(54, 32)
	title.anchor_right = 1.0
	title.offset_right = -54
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(title)
	# Flourish under the title.
	var flourish := _FlourishBar.new()
	var flourish_w: float = _panel.custom_minimum_size.x - 108.0
	flourish.position = Vector2(54.0, 68.0)
	flourish.custom_minimum_size = Vector2(flourish_w, 10.0)
	flourish.size = Vector2(flourish_w, 10.0)
	_panel.add_child(flourish)
	# HBox for the 3 buff cards.
	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", 20)
	_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_hbox.anchor_left = 0.0
	_hbox.anchor_right = 1.0
	_hbox.anchor_bottom = 1.0
	_hbox.offset_top = 84
	_hbox.offset_bottom = -24
	_hbox.offset_left = 40
	_hbox.offset_right = -40
	_panel.add_child(_hbox)

# Populate the modal with the 3 offered buffs and pause the world.
func setup(buffs: Array) -> void:
	_buffs = buffs
	for c in _hbox.get_children():
		c.queue_free()
	for b in _buffs:
		var card := _BuffCard.new()
		card.setup(String(b.name), String(b.desc))
		card.pressed.connect(_on_pressed.bind(b))
		card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_hbox.add_child(card)
	get_node("/root/Game").modal_opened()

func _on_pressed(buff: Dictionary) -> void:
	get_node("/root/Game").modal_closed()
	chosen.emit(buff)
	queue_free()


# ---- thin flourish bar (drawn — avoids any texture load) ----
class _FlourishBar extends Control:
	func _draw() -> void:
		var cx := size.x * 0.5
		var cy := size.y * 0.5
		WyrdUi.draw_flourish(self, Vector2(cx, cy), size.x * 0.7)


# ---- drawn buff card (one choice column) ----
# A clickable Control that uses draw_list_row for the parchment plate,
# with GOLD accent on hover (shrine buffs are always blessings — no
# negative accent needed). Name in INK header font; desc in INK_MID body.
# No icon well: shrine buffs carry no painted icon.
class _BuffCard extends Control:

	var _name := ""
	var _desc := ""
	var _hover := false

	signal pressed

	func _init() -> void:
		custom_minimum_size = Vector2(186, 220)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func setup(buff_name: String, buff_desc: String) -> void:
		_name = buff_name
		_desc = buff_desc
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
		var accent: Color = WyrdUi.GOLD if _hover else WyrdUi.INK_MID
		WyrdUi.draw_list_row(self, r, accent)
		# Hover wash — warms the card so it reads as interactive.
		if _hover:
			draw_rect(r.grow(-1.5), Color(1.0, 1.0, 0.90, 0.09))
		# Divider line below the name row.
		draw_line(Vector2(12.0, 44.0), Vector2(size.x - 12.0, 44.0),
			Color(WyrdUi.KIT_EDGE, 0.30), 1.0)
		var font := get_theme_default_font()
		# Name — sepia ink, a little larger for readability.
		draw_string(font, Vector2(14.0, 30.0), _name,
			HORIZONTAL_ALIGNMENT_LEFT, size.x - 28.0, 16, WyrdUi.INK)
		# Description — secondary ink, wraps to multiple lines.
		draw_multiline_string(font, Vector2(14.0, 60.0), _desc,
			HORIZONTAL_ALIGNMENT_LEFT, size.x - 28.0, 13, 5, WyrdUi.INK_MID)
