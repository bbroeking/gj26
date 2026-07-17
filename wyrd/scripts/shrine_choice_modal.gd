extends CanvasLayer

# Spec 29 — the 3-buff choice modal a Shrine opens. The whole UI is built in
# script so the .tscn stays a minimal CanvasLayer + script binding. Pauses
# the tree while open so the player can't escape with a movement key; emits
# `chosen(buff)` when the player picks one of the three cards.
#
# Art pass — the plain Panel + Button rows are replaced by the WyrdUi carved
# wood frame + three tall _BuffCard portrait cards (the "triptych" layout).
# Each card draws its own parchment face, a blessing-glyph well, the buff name
# in IM Fell SC, a flourish rule, and the description — the shrine now reads as
# a storybook altar, not a flat dialogue box.

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
	_panel.custom_minimum_size = Vector2(720, 380)
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -360
	_panel.offset_top = -190
	_panel.offset_right = 360
	_panel.offset_bottom = 190
	add_child(_panel)
	var title := Label.new()
	title.text = "An Old Altar Stirs"
	WyrdUi.style_title(title)
	title.anchor_right = 1.0
	title.offset_top = 36
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(title)
	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", 20)
	_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_hbox.anchor_left = 0.0
	_hbox.anchor_right = 1.0
	_hbox.anchor_bottom = 1.0
	_hbox.offset_left = 36
	_hbox.offset_top = 76
	_hbox.offset_right = -36
	_hbox.offset_bottom = -24
	_panel.add_child(_hbox)

# Populate the modal with the 3 offered buffs and pause the world.
func setup(buffs: Array) -> void:
	_buffs = buffs
	for c in _hbox.get_children():
		c.queue_free()
	for b in _buffs:
		var card := _BuffCard.new()
		card.setup(b)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var buff := b
		card.pressed.connect(func(): _on_pressed(buff))
		_hbox.add_child(card)
	get_node("/root/Game").modal_opened()

func _on_pressed(buff: Dictionary) -> void:
	get_node("/root/Game").modal_closed()
	chosen.emit(buff)
	queue_free()


# A tall portrait buff card — the "triptych" panel. Draws a parchment face with
# a blessing-glyph well, the buff name in IM Fell SC, a flourish rule, and the
# description. Follows the _ChartCard / _SkillCard drawn-card pattern.
class _BuffCard extends Control:
	var _name := ""
	var _desc := ""
	var _hover := false

	signal pressed

	func _init() -> void:
		custom_minimum_size = Vector2(180, 220)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func setup(buff: Dictionary) -> void:
		_name = String(buff.get("name", ""))
		_desc = String(buff.get("desc", ""))
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
		# Parchment face: warm plate, top-light bevel, ink border, gold inset.
		draw_rect(r, WyrdUi.KIT_PLATE)
		draw_rect(Rect2(r.position + Vector2(2.0, 2.0),
			Vector2(r.size.x - 4.0, 2.5)), Color(1.0, 0.97, 0.86, 0.55))
		if _hover:
			draw_rect(r.grow(-1.5), Color(WyrdUi.GOLD, 0.10))
		draw_rect(r, WyrdUi.KIT_EDGE, false, 2.0)
		draw_rect(r.grow(-4.0), Color(WyrdUi.GOLD, 0.40), false, 1.0)
		WyrdUi.draw_parchment_grain(self, r.grow(-6.0), _name.length() + 7)
		# Blessing-glyph in a round well near the top.
		var gc := Vector2(size.x * 0.5, 38.0)
		WyrdUi.draw_round_well(self, gc, 22.0, WyrdUi.KIT_WELL)
		var font := get_theme_default_font()
		draw_string(font, Vector2(0.0, gc.y + 8.5), "✦",
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, WyrdUi.GOLD)
		# Buff name in IM Fell SC, terracotta.
		var hf := WyrdUi.font_header()
		if hf == null:
			hf = font
		draw_string(hf, Vector2(8.0, 82.0), _name,
			HORIZONTAL_ALIGNMENT_CENTER, size.x - 16.0, 17, WyrdUi.TERRACOTTA)
		# Flourish rule below the name.
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, 94.0), size.x - 52.0)
		# Description in body text, wrapped.
		draw_multiline_string(font, Vector2(12.0, 114.0), _desc,
			HORIZONTAL_ALIGNMENT_LEFT, size.x - 24.0, 13, -1, WyrdUi.INK)
