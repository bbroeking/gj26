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
	# Panel centred on the viewport — carved wooden frame, parchment interior.
	_panel = Panel.new()
	_panel.custom_minimum_size = Vector2(720, 400)
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -360
	_panel.offset_top = -200
	_panel.offset_right = 360
	_panel.offset_bottom = 200
	WyrdUi.style_panel(_panel)
	add_child(_panel)
	# Title — terracotta IM Fell SC, centred in the frame header area.
	var title := Label.new()
	title.text = "An Old Altar Stirs"
	WyrdUi.style_title(title)
	title.add_theme_font_size_override("font_size", 26)
	title.anchor_right = 1.0
	title.offset_top = 24
	title.offset_left = 54
	title.offset_right = -54
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(title)
	# Section flourish under the title — the altar breathes before the choice.
	var div := _Divider.new()
	div.anchor_right = 1.0
	div.offset_top = 62
	div.offset_bottom = 78
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(div)
	# HBox for the three buff cards — fills the frame's content area.
	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", 20)
	_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_hbox.anchor_right = 1.0
	_hbox.anchor_bottom = 1.0
	_hbox.offset_left = 46
	_hbox.offset_top = 84
	_hbox.offset_right = -46
	_hbox.offset_bottom = -44
	_panel.add_child(_hbox)
	# Dim hint at the bottom — guidance without ceremony.
	var hint := Label.new()
	hint.text = "Click to claim a boon  ·  Esc does not close the altar"
	WyrdUi.style_dim(hint)
	hint.anchor_right = 1.0
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_left = 54
	hint.offset_right = -54
	hint.offset_top = -32
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(hint)

# Populate the modal with the 3 offered buffs and pause the world.
func setup(buffs: Array) -> void:
	_buffs = buffs
	for c in _hbox.get_children():
		c.queue_free()
	for b in _buffs:
		var card := _BuffCard.new()
		card.setup(String(b.name), String(b.desc))
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.pressed.connect(_on_pressed.bind(b))
		_hbox.add_child(card)
	get_node("/root/Game").modal_opened()

func _on_pressed(buff: Dictionary) -> void:
	get_node("/root/Game").modal_closed()
	chosen.emit(buff)
	queue_free()


# ---- Drawn buff card (one boon from the altar) ----
# A carved parchment boon card: terracotta header band with the boon name in
# cream, a section flourish, parchment grain, a gold rune mark in the body
# center, the stat line at 16px, and a closing bottom flourish.
# Gold rim on hover (the altar invites the hand); terracotta rim on press.
class _BuffCard extends Control:
	const HDR_H := 38.0

	var _name := ""
	var _desc := ""
	var _hover := false
	var _pressing := false

	signal pressed

	func _init() -> void:
		custom_minimum_size = Vector2(0, 240)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func setup(boon_name: String, desc: String) -> void:
		_name = boon_name
		_desc = desc
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton \
				and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_pressing = true
				queue_redraw()
			else:
				if _pressing:
					pressed.emit()
				_pressing = false
				queue_redraw()
			accept_event()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_ENTER:
			_hover = true
			queue_redraw()
		elif what == NOTIFICATION_MOUSE_EXIT:
			_hover = false
			_pressing = false
			queue_redraw()

	func _draw() -> void:
		if size.x < 2.0 or size.y < 2.0:
			return
		var r := Rect2(Vector2.ZERO, size)
		# Card face — warm parchment plate, sunken slightly when pressed.
		var face := WyrdUi.KIT_PLATE.lightened(0.03) if not _pressing \
			else WyrdUi.KIT_PLATE.darkened(0.04)
		draw_rect(r, face)
		# Top light bevel — the card catches the page's warm light.
		draw_rect(Rect2(r.position + Vector2(1.0, 1.0),
			Vector2(r.size.x - 2.0, 2.0)), Color(1.0, 0.98, 0.90, 0.55))
		# Bottom shade — the card sits ON the parchment.
		draw_rect(Rect2(r.position + Vector2(2.0, r.size.y - 3.0),
			Vector2(r.size.x - 4.0, 2.0)), Color(WyrdUi.KIT_EDGE, 0.30))
		# Ink border + inner pinstripe.
		draw_rect(r, WyrdUi.KIT_EDGE, false, 2.0)
		draw_rect(r.grow(-3.5), Color(WyrdUi.KIT_EDGE, 0.28), false, 1.0)

		# Terracotta header band — the boon's name at a glance.
		var hdr := Rect2(r.position + Vector2(2.0, 2.0),
			Vector2(r.size.x - 4.0, HDR_H))
		draw_rect(hdr, WyrdUi.TERRACOTTA.darkened(0.06))
		# Warm light sheen across the header top.
		draw_rect(Rect2(hdr.position, Vector2(hdr.size.x, 2.0)),
			Color(1.0, 0.85, 0.70, 0.22))
		# Shadow line separating band from body.
		draw_rect(Rect2(hdr.position + Vector2(0, hdr.size.y - 2.0),
			Vector2(hdr.size.x, 2.0)), Color(WyrdUi.KIT_EDGE, 0.45))
		# Boon name centred in the header — cream on terracotta.
		var f_hdr := WyrdUi.font_header()
		var f_body := get_theme_default_font()
		if f_hdr == null:
			f_hdr = f_body
		draw_string(f_hdr,
			Vector2(r.position.x + 6.0, r.position.y + HDR_H - 9.0),
			_name, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 12.0, 14,
			WyrdUi.CREAM)

		# Section flourish below the header band.
		WyrdUi.draw_flourish(self,
			Vector2(r.size.x * 0.5, HDR_H + 13.0), r.size.x * 0.65)

		# Parchment grain over the full body area.
		var body := Rect2(r.position + Vector2(4.0, HDR_H + 4.0),
			Vector2(r.size.x - 8.0, r.size.y - HDR_H - 8.0))
		WyrdUi.draw_parchment_grain(self, body, int(r.size.x) & 0x7f)

		# Gold rune mark — the boon made tangible: a diamond in burnished gold.
		var mc := Vector2(r.size.x * 0.5,
			HDR_H + (r.size.y - HDR_H) * 0.33)
		var dp := 15.0
		var dpts := PackedVector2Array([
			mc + Vector2(0.0, -dp * 1.3), mc + Vector2(dp, 0.0),
			mc + Vector2(0.0, dp * 1.3), mc + Vector2(-dp, 0.0)])
		draw_colored_polygon(dpts, Color(WyrdUi.GOLD, 0.16))
		draw_polyline(dpts + PackedVector2Array([dpts[0]]),
			Color(WyrdUi.GOLD, 0.65), 1.5, true)
		# Inner dot — the seal's heart.
		draw_circle(mc, 3.2, Color(WyrdUi.GOLD, 0.52))

		# Stat description — large, centred, the key information.
		var desc_y := HDR_H + (r.size.y - HDR_H) * 0.61
		draw_multiline_string(f_body,
			Vector2(r.position.x + 12.0, desc_y),
			_desc, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 24.0, 16, -1,
			WyrdUi.INK)

		# Closing bottom flourish — the card inscription ends with a seal.
		WyrdUi.draw_flourish(self,
			Vector2(r.size.x * 0.5, r.size.y - 38.0), r.size.x * 0.42)

		# Gold rim on hover (invite), terracotta rim when pressed (commit).
		if _hover and not _pressing:
			draw_rect(r.grow(-1.5), Color(WyrdUi.GOLD, 0.80), false, 2.5)
		elif _pressing:
			draw_rect(r.grow(-1.5), Color(WyrdUi.TERRACOTTA, 0.55), false, 2.0)


# A thin drawn divider — the section flourish centred on the band.
class _Divider extends Control:
	func _draw() -> void:
		if size.x < 2.0:
			return
		WyrdUi.draw_flourish(self,
			Vector2(size.x * 0.5, size.y * 0.5), size.x * 0.55)
