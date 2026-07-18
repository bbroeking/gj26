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
	# Panel centred on the viewport. Styled as a warm parchment card so it reads
	# as Wayfinder kit (ink border, rounded corners, soft drop shadow) without
	# consuming the large margins the wooden-frame ninepatch needs at 320px height.
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
	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = WyrdUi.KIT_PLATE
	panel_sb.border_color = WyrdUi.KIT_EDGE
	panel_sb.set_border_width_all(3)
	panel_sb.set_corner_radius_all(6)
	panel_sb.shadow_color = Color(0.12, 0.09, 0.06, 0.35)
	panel_sb.shadow_size = 10
	panel_sb.shadow_offset = Vector2(0, 5)
	panel_sb.set_content_margin_all(12.0)
	_panel.add_theme_stylebox_override("panel", panel_sb)
	# Parchment grain over the face so the background reads hand-made.
	var grain := _ParchmentLayer.new()
	grain.anchor_right = 1.0
	grain.anchor_bottom = 1.0
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(grain)
	# Title — IM Fell SC in terracotta (matches every other Wayfinder panel).
	var title := Label.new()
	title.text = "An Old Altar Stirs"
	var hf := WyrdUi.font_header()
	if hf != null:
		title.add_theme_font_override("font", hf)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", WyrdUi.TERRACOTTA)
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.offset_top = 16
	title.offset_bottom = 52
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(title)
	# Flourish rule under the title — the kit's ── ◆ ── divider.
	var rule := _FlourishRule.new()
	rule.anchor_right = 1.0
	rule.offset_left = 40
	rule.offset_right = -40
	rule.offset_top = 52
	rule.offset_bottom = 64
	_panel.add_child(rule)
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
		btn.custom_minimum_size = Vector2(180, 200)
		btn.text = String(b.name) + "\n\n" + String(b.desc)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		# Kit button skin so the cards read as carved objects, not default engine.
		WyrdUi.style_kit_button(btn)
		btn.pressed.connect(_on_pressed.bind(b))
		_hbox.add_child(btn)
	get_node("/root/Game").modal_opened()

func _on_pressed(buff: Dictionary) -> void:
	get_node("/root/Game").modal_closed()
	chosen.emit(buff)
	queue_free()


# Sparse parchment grain drawn over the panel face — the same call as
# WyrdUi.draw_parchment_grain but as a self-contained Control child so it
# redraws on resize without touching the parent's _draw.
class _ParchmentLayer extends Control:
	func _draw() -> void:
		WyrdUi.draw_parchment_grain(self, Rect2(Vector2(4.0, 4.0),
			size - Vector2(8.0, 8.0)), 41)


# Flourish rule — the kit's  ── ◆ ──  divider, width-adaptive.
class _FlourishRule extends Control:
	func _draw() -> void:
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, size.y * 0.5),
			size.x * 0.55)
