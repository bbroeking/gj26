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
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.6)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	_panel = Panel.new()
	WyrdUi.style_panel(_panel)
	_panel.custom_minimum_size = Vector2(660, 380)
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -330
	_panel.offset_top = -190
	_panel.offset_right = 330
	_panel.offset_bottom = 190
	add_child(_panel)
	var title := Label.new()
	title.text = "An Old Altar Stirs"
	WyrdUi.style_title(title)
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.offset_top = 36
	title.offset_bottom = 72
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(title)
	# Gold ── ◆ ── rule under the header — marks the altar moment as a
	# storybook beat before the boon cards unfold below it.
	var header_rule := _HeaderFlourish.new()
	header_rule.anchor_left = 0.0
	header_rule.anchor_right = 1.0
	header_rule.offset_top = 74
	header_rule.offset_bottom = 90
	header_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(header_rule)
	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", 16)
	_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_hbox.anchor_left = 0.0
	_hbox.anchor_right = 1.0
	_hbox.anchor_bottom = 1.0
	_hbox.offset_top = 96
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
		_hbox.add_child(_make_card(b))
	get_node("/root/Game").modal_opened()

# Each boon is a parchment card: KIT_PLATE face + grain layer + carved
# name header + sepia ── ◆ ── separator + description body + Choose button.
func _make_card(b: Dictionary) -> Panel:
	var card := Panel.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sb := WyrdUi.chip_stylebox(WyrdUi.KIT_PLATE)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(14)
	sb.shadow_size = 5
	sb.shadow_offset = Vector2(0, 3)
	card.add_theme_stylebox_override("panel", sb)
	# Parchment grain drawn over the card face, behind the text.
	var grain := _CardGrain.new()
	grain.anchor_right = 1.0
	grain.anchor_bottom = 1.0
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(grain)
	var inner := VBoxContainer.new()
	inner.anchor_right = 1.0
	inner.anchor_bottom = 1.0
	inner.offset_left = 14
	inner.offset_top = 14
	inner.offset_right = -14
	inner.offset_bottom = -14
	inner.add_theme_constant_override("separation", 8)
	card.add_child(inner)
	var name_lbl := Label.new()
	name_lbl.text = String(b.get("name", ""))
	WyrdUi.style_section(name_lbl)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(name_lbl)
	# Thin ── ◆ ── between boon name and description — the "boon scroll" read.
	var rule := _CardFlourish.new()
	rule.custom_minimum_size = Vector2(0, 16)
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(rule)
	var desc_lbl := Label.new()
	desc_lbl.text = String(b.get("desc", ""))
	WyrdUi.style_body(desc_lbl, 13)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(desc_lbl)
	var btn := Button.new()
	btn.text = "Choose"
	WyrdUi.style_kit_button(btn)
	btn.pressed.connect(_on_pressed.bind(b))
	inner.add_child(btn)
	return card

func _on_pressed(buff: Dictionary) -> void:
	get_node("/root/Game").modal_closed()
	chosen.emit(buff)
	queue_free()


# Gold ── ◆ ── rule spanning ~60 % of the panel width, centred below the
# "An Old Altar Stirs" header. Drawn pure-vector (no texture, gotcha-safe).
class _HeaderFlourish extends Control:
	func _draw() -> void:
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, size.y * 0.5),
				size.x * 0.6)


# Narrower ── ◆ ── inside each boon card, between name and description.
class _CardFlourish extends Control:
	func _draw() -> void:
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, size.y * 0.5),
				size.x * 0.85)


# Sparse sepia fibre strokes across the card face — makes each boon card
# read as aged parchment, not a flat rectangle.
class _CardGrain extends Control:
	func _draw() -> void:
		WyrdUi.draw_parchment_grain(self, Rect2(Vector2.ZERO, size), 42)
