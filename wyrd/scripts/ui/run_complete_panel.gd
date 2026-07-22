extends CanvasLayer

# Wyrd — storybook "chart complete" moment. Shown after stepping through the
# exit waystone on a completed (non-abandoned) run. The finished chart is
# rendered on a parchment scroll: name + tier in IM Fell, affix summary in
# good/bad ink, and a gold XP chip below. Player dismisses with E / click /
# "Return to the yard". Emits `finished`; game.gd fires the scene transition.

const ChartsData = preload("res://data/charts.gd")

signal finished

var _chart := {}
var _xp := 0
var _summit := false
var _done := false
var _lockout := 0.0

func setup(chart: Dictionary, xp: int, summit_clear: bool = false) -> void:
	_chart = chart
	_xp = xp
	_summit = summit_clear

func _ready() -> void:
	# Headless / test mode: emit finished on the spot so the test's
	# deferred scene change fires on schedule (no UI to dismiss).
	if DisplayServer.get_name() == "headless":
		finished.emit()
		queue_free()
		return

	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 95

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.65)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var panel := Panel.new()
	WyrdUi.style_panel(panel)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -268
	panel.offset_top = -230
	panel.offset_right = 268
	panel.offset_bottom = 230
	add_child(panel)

	# ---- parchment scroll art in the header ----
	var scroll := _ScrollArt.new()
	scroll.anchor_right = 1.0
	scroll.offset_top = 10
	scroll.offset_bottom = 152
	scroll.chart_name = String(_chart.get("name", "The Hollow"))
	var tier := int(_chart.get("tier", 1))
	var scope := String(_chart.get("scope", "hollow")).capitalize()
	scroll.tier_scope = "Tier %d · %s" % [tier, scope]
	panel.add_child(scroll)

	# ---- affix summary ----
	var aff_box := VBoxContainer.new()
	aff_box.anchor_right = 1.0
	aff_box.offset_left = 52
	aff_box.offset_right = -52
	aff_box.offset_top = 164
	aff_box.add_theme_constant_override("separation", 5)
	panel.add_child(aff_box)

	var affixes: Array = _chart.get("affixes", [])
	if affixes.is_empty():
		var plain := Label.new()
		plain.text = "A clean chart — nothing inked but the way there."
		WyrdUi.style_dim(plain, 13)
		plain.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		aff_box.add_child(plain)
	for a in affixes:
		var aff: Dictionary = ChartsData.AFFIXES.get(String(a.get("id", "")), {})
		if aff.is_empty():
			continue
		var row := Label.new()
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_theme_font_size_override("font_size", 13)
		if bool(a.get("good", false)):
			row.text = "✓ %s — %s" % [String(aff.name), String(aff.good_desc)]
			row.add_theme_color_override("font_color", WyrdUi.SAGE)
		else:
			row.text = "✗ %s — %s" % [String(aff.bad_name), String(aff.bad_desc)]
			row.add_theme_color_override("font_color", WyrdUi.TERRACOTTA)
		aff_box.add_child(row)

	# ---- XP chip ----
	var xp_lbl := Label.new()
	WyrdUi.style_chip(xp_lbl, 16)
	xp_lbl.add_theme_color_override("font_color", WyrdUi.GOLD)
	xp_lbl.text = "+%d Wayfinding XP" % _xp
	xp_lbl.anchor_left = 0.5
	xp_lbl.anchor_top = 1.0
	xp_lbl.anchor_right = 0.5
	xp_lbl.anchor_bottom = 1.0
	xp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_lbl.offset_left = -120
	xp_lbl.offset_right = 120
	xp_lbl.offset_top = -104
	xp_lbl.offset_bottom = -74
	panel.add_child(xp_lbl)

	if _summit:
		var summit_lbl := Label.new()
		summit_lbl.text = "★ The Summit is charted."
		WyrdUi.style_dim(summit_lbl, 12)
		summit_lbl.add_theme_color_override("font_color", WyrdUi.GOLD)
		summit_lbl.anchor_left = 0.5
		summit_lbl.anchor_right = 0.5
		summit_lbl.anchor_top = 1.0
		summit_lbl.anchor_bottom = 1.0
		summit_lbl.offset_left = -140
		summit_lbl.offset_right = 140
		summit_lbl.offset_top = -72
		summit_lbl.offset_bottom = -52
		summit_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(summit_lbl)

	# ---- dismiss button ----
	var btn := Button.new()
	WyrdUi.style_button(btn)
	btn.text = "Return to the yard"
	btn.add_theme_font_size_override("font_size", 16)
	btn.custom_minimum_size = Vector2(220, 40)
	btn.anchor_left = 0.5
	btn.anchor_top = 1.0
	btn.anchor_right = 0.5
	btn.anchor_bottom = 1.0
	btn.offset_left = -110
	btn.offset_top = -50
	btn.offset_bottom = -10
	btn.pressed.connect(_on_return)
	panel.add_child(btn)

	get_node("/root/Game").modal_opened()

func _process(delta: float) -> void:
	_lockout += delta
	if _lockout < 0.35:
		return
	if Input.is_action_just_pressed("interact") \
			or Input.is_action_just_pressed("ui_accept") \
			or Input.is_action_just_pressed("ui_cancel"):
		_on_return()

func _input(event: InputEvent) -> void:
	if _lockout < 0.35:
		return
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_on_return()

func _on_return() -> void:
	if _done:
		return
	_done = true
	get_node("/root/Game").modal_closed()
	finished.emit()
	queue_free()


# ---- parchment scroll header art ----
# Fills the upper section of the panel with a drawn horizontal scroll: rolled
# ends on left and right, warm parchment face, and the chart name + tier
# inscribed inside in IM Fell. A flourish rule closes the bottom of the art.
class _ScrollArt extends Control:
	var chart_name := ""
	var tier_scope := ""

	func _draw() -> void:
		# Scroll rect inset from the control edges — room for the rolled ends.
		var r := Rect2(Vector2(32.0, 8.0), Vector2(size.x - 64.0, size.y - 22.0))
		WyrdUi.draw_scroll(self, r, false)
		WyrdUi.draw_parchment_grain(self, r, 42)

		# The scroll face rect mirrors the math inside draw_scroll.
		var face := Rect2(r.position + Vector2(r.size.x * 0.08, r.size.y * 0.12),
			Vector2(r.size.x * 0.84, r.size.y * 0.76))

		var font := get_theme_default_font()
		var hf := WyrdUi.font_header()
		var head_font: Font = hf if hf != null else font

		# "Chart Complete" dim caption at the top of the face.
		draw_string(font,
			face.position + Vector2(0.0, face.size.y * 0.30),
			"Chart Complete",
			HORIZONTAL_ALIGNMENT_CENTER, face.size.x,
			11, Color(WyrdUi.INK_MID, 0.72))

		# Chart name in IM Fell header — the title of the moment.
		draw_string(head_font,
			face.position + Vector2(0.0, face.size.y * 0.62),
			chart_name,
			HORIZONTAL_ALIGNMENT_CENTER, face.size.x,
			24, WyrdUi.INK)

		# Tier and scope subtitle.
		draw_string(font,
			face.position + Vector2(0.0, face.size.y * 0.88),
			tier_scope,
			HORIZONTAL_ALIGNMENT_CENTER, face.size.x,
			12, WyrdUi.INK_MID)

		# Flourish rule below the scroll body — bridges scroll to affix list.
		var cx := r.position.x + r.size.x * 0.5
		WyrdUi.draw_flourish(self, Vector2(cx, r.end.y + 6.0), r.size.x * 0.42)
