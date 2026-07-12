extends CanvasLayer

# Spec 29 — the 3-buff choice modal a Shrine opens. The whole UI is built in
# script so the .tscn stays a minimal CanvasLayer + script binding. Pauses
# the tree while open so the player can't escape with a movement key; emits
# `chosen(buff)` when the player picks one of the three cards.
#
# Offering-card pass: WyrdUi panel skin + title, and three drawn _BlessCards —
# parchment-face cards with a runic well, name, and blessing desc.

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
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -345
	_panel.offset_top = -210
	_panel.offset_right = 345
	_panel.offset_bottom = 210
	add_child(_panel)
	var title := Label.new()
	title.text = "An Old Altar Stirs"
	WyrdUi.style_title(title)
	title.position = Vector2(54, 34)
	_panel.add_child(title)
	var hint := Label.new()
	hint.text = "Choose a blessing. The altar may only offer once."
	WyrdUi.style_dim(hint, 13)
	hint.position = Vector2(54, 72)
	hint.anchor_right = 1.0
	hint.offset_right = -54
	_panel.add_child(hint)
	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", 20)
	_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_hbox.anchor_left = 0.0
	_hbox.anchor_right = 1.0
	_hbox.anchor_bottom = 1.0
	_hbox.offset_top = 100
	_hbox.offset_bottom = -24
	_hbox.offset_left = 24
	_hbox.offset_right = -24
	_panel.add_child(_hbox)

# Populate the modal with the 3 offered buffs and pause the world.
func setup(buffs: Array) -> void:
	_buffs = buffs
	for c in _hbox.get_children():
		c.queue_free()
	var seed_v := 17
	for b in _buffs:
		var card := _BlessCard.new()
		card.setup(String(b.get("name", "")), String(b.get("desc", "")), seed_v)
		seed_v += 31
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.pressed.connect(_on_pressed.bind(b))
		_hbox.add_child(card)
	get_node("/root/Game").modal_opened()

func _on_pressed(buff: Dictionary) -> void:
	get_node("/root/Game").modal_closed()
	chosen.emit(buff)
	queue_free()


# A drawn parchment offering-card: carved face, runic well, flourish, name and
# desc. Lights up with a sage ring on hover so the choice reads as active.
class _BlessCard extends Control:
	var _name := ""
	var _desc := ""
	var _seed := 17
	var _hover := false

	signal pressed

	func _init() -> void:
		custom_minimum_size = Vector2(160, 240)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func setup(bless_name: String, desc: String, seed_v: int) -> void:
		_name = bless_name
		_desc = desc
		_seed = seed_v
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
		# Parchment plate face.
		draw_rect(r, WyrdUi.KIT_PLATE)
		# Top honey bevel catches the warm page light.
		draw_rect(Rect2(r.position + Vector2(3.0, 3.0),
			Vector2(r.size.x - 6.0, 3.0)), Color(1.0, 0.97, 0.86, 0.55))
		# Bottom ink shadow so the card sits on the panel.
		draw_rect(Rect2(r.position + Vector2(3.0, r.size.y - 5.0),
			Vector2(r.size.x - 6.0, 3.0)), Color(WyrdUi.KIT_EDGE, 0.28))
		WyrdUi.draw_parchment_grain(self, r, _seed)
		# Sage wash on hover — the card glows as you consider it.
		if _hover:
			draw_rect(r.grow(-2.0), Color(WyrdUi.SAGE, 0.10))
		# Ink border + inner sage ring on hover.
		draw_rect(r, WyrdUi.KIT_EDGE, false, 2.0)
		if _hover:
			draw_rect(r.grow(-3.5), Color(WyrdUi.SAGE, 0.60), false, 1.5)
		# Round runic well — the offering socket at the card's heart.
		var wc := Vector2(size.x * 0.5, 56.0)
		var wr := 36.0
		WyrdUi.draw_round_well(self, wc, wr, WyrdUi.KIT_PLATE.darkened(0.14))
		# Sage altar-glow ring just outside the well lip.
		draw_arc(wc, wr + 3.5, 0.0, TAU, 40,
			Color(WyrdUi.SAGE, 0.40 if not _hover else 0.70), 1.5, true)
		# ✦ rune glyph centred in the well.
		var font := get_theme_default_font()
		draw_string(font, Vector2(wc.x, wc.y + 10.0), "✦",
			HORIZONTAL_ALIGNMENT_CENTER, wr * 2.0, 24,
			WyrdUi.GOLD if not _hover else WyrdUi.GOLD.lightened(0.15))
		# Flourish — the kit's section rule, here dividing oracle from word.
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, 106.0),
			minf(size.x - 32.0, 96.0))
		# Blessing name — two lines max, 15pt.
		draw_multiline_string(font, Vector2(10.0, 126.0), _name,
			HORIZONTAL_ALIGNMENT_CENTER, size.x - 20.0, 15, 2, WyrdUi.INK)
		# Description — dim ink, smaller, wraps up to six lines.
		draw_multiline_string(font, Vector2(10.0, 158.0), _desc,
			HORIZONTAL_ALIGNMENT_CENTER, size.x - 20.0, 12, 6,
			WyrdUi.INK_MID if not _hover else WyrdUi.INK)
