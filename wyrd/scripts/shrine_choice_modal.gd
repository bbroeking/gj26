extends CanvasLayer

# Spec 29 — the 3-buff choice modal a Shrine opens. The whole UI is built in
# script so the .tscn stays a minimal CanvasLayer + script binding. Pauses
# the tree while open so the player can't escape with a movement key; emits
# `chosen(buff)` when the player picks one of the three cards.
# Slice — buff cards are now hand-painted parchment panels (WyrdUi kit):
# a round gold sigil socket at the top, IM Fell SC name, gold flourish rule,
# and body-font description. The modal itself joins the carved-wood language.

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
	# Panel centred on the viewport — now uses the carved-wood 9-patch frame.
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
	# Title in the WyrdUi kit voice (IM Fell SC, TERRACOTTA).
	var title := Label.new()
	title.text = "An Old Altar Stirs"
	WyrdUi.style_title(title)
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.offset_top = 32
	title.offset_bottom = 72
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(title)
	# HBox for the 3 boon cards — spaced to breathe inside the frame.
	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", 18)
	_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_hbox.anchor_left = 0.0
	_hbox.anchor_right = 1.0
	_hbox.anchor_bottom = 1.0
	_hbox.offset_top = 84
	_hbox.offset_bottom = -28
	_hbox.offset_left = 28
	_hbox.offset_right = -28
	_panel.add_child(_hbox)

# Populate the modal with the 3 offered buffs and pause the world.
func setup(buffs: Array) -> void:
	_buffs = buffs
	for c in _hbox.get_children():
		c.queue_free()
	for b in _buffs:
		var card := _BoonCard.new()
		card.setup(String(b.name), String(b.desc))
		card.pressed.connect(_on_pressed.bind(b))
		_hbox.add_child(card)
	get_node("/root/Game").modal_opened()

func _on_pressed(buff: Dictionary) -> void:
	get_node("/root/Game").modal_closed()
	chosen.emit(buff)
	queue_free()


# Hand-painted parchment card for each shrine boon choice. Uses the WyrdUi
# draw kit: carved list-row face, parchment grain, round gold sigil socket,
# IM Fell SC name, gold flourish rule, and body-font description.
# Hover brightens the face slightly; a left-click emits `pressed`.
class _BoonCard extends Control:
	var _name := ""
	var _desc := ""
	var _hover := false
	signal pressed

	func _init() -> void:
		custom_minimum_size = Vector2(184, 220)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_flags_vertical = Control.SIZE_EXPAND_FILL
		mouse_filter = Control.MOUSE_FILTER_STOP

	func setup(boon_name: String, boon_desc: String) -> void:
		_name = boon_name
		_desc = boon_desc
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		# Carved parchment face with a gold left-stripe accent.
		WyrdUi.draw_list_row(self, r, WyrdUi.GOLD)
		# Aged-vellum grain across the interior.
		WyrdUi.draw_parchment_grain(self, r.grow(-3), 11)
		# Subtle cream wash on hover.
		if _hover:
			draw_rect(r.grow(-2), Color(1.0, 1.0, 1.0, 0.07))
		# Round sigil socket at top-center — gold-tinted well.
		var wc := Vector2(size.x * 0.5, 38.0)
		WyrdUi.draw_round_well(self, wc, 24.0, Color(0.94, 0.87, 0.65))
		# Diamond pip inside the socket — the altar's seal.
		var s := 8.0
		draw_colored_polygon(PackedVector2Array([
			wc + Vector2(0, -s), wc + Vector2(s, 0),
			wc + Vector2(0, s), wc + Vector2(-s, 0)]), WyrdUi.GOLD)
		draw_polyline(PackedVector2Array([
			wc + Vector2(0, -s), wc + Vector2(s, 0),
			wc + Vector2(0, s), wc + Vector2(-s, 0),
			wc + Vector2(0, -s)]), WyrdUi.INK, 1.3)
		# Boon name in IM Fell SC with TERRACOTTA — matches the panel title weight.
		var hf := WyrdUi.font_header()
		var font := hf if hf != null else get_theme_default_font()
		draw_string(font, Vector2(0.0, 80.0), _name,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 17, WyrdUi.TERRACOTTA)
		# Gold flourish rule dividing name from the description text.
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, 94.0), size.x * 0.54)
		# Lore description in the default body font — readable, unhurried.
		draw_multiline_string(get_theme_default_font(),
			Vector2(14.0, 108.0), _desc,
			HORIZONTAL_ALIGNMENT_LEFT, size.x - 28.0, 13, -1,
			Color(0.24, 0.18, 0.13))

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_ENTER:
			_hover = true
			queue_redraw()
		elif what == NOTIFICATION_MOUSE_EXIT:
			_hover = false
			queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed \
				and event.button_index == MOUSE_BUTTON_LEFT:
			pressed.emit()
			accept_event()
