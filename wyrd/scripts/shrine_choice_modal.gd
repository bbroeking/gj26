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
	# Panel centred on the viewport.
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
	add_child(_panel)
	WyrdUi.style_panel(_panel)
	# Candle-trio crest left of the title — a storybook altar icon.
	var crest := _CandleCrest.new()
	crest.custom_minimum_size = Vector2(60, 44)
	crest.position = Vector2(10, 14)
	_panel.add_child(crest)
	# Title — IM Fell SC, terracotta, left-aligned to clear the crest.
	var title := Label.new()
	title.text = "An Old Altar Stirs"
	WyrdUi.style_title(title)
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.offset_left = 74
	title.offset_top = 16
	title.offset_bottom = 56
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_panel.add_child(title)
	# HBox for the 3 buff cards.
	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", 20)
	_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_hbox.anchor_left = 0.0
	_hbox.anchor_right = 1.0
	_hbox.anchor_bottom = 1.0
	_hbox.offset_top = 70
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
		WyrdUi.style_kit_button(btn)
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


# ---- altar candle crest ----
# Three hand-drawn candles (side, centre, side) — the shrine modal's header icon.
# Pure vector; no textures are loaded inside _draw.
class _CandleCrest extends Control:
	func _draw() -> void:
		WyrdUi.draw_candle_trio(self, Rect2(Vector2.ZERO, size))
