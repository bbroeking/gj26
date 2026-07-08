extends CanvasLayer

# Wyrd — a storybook dialog modal. Pages of text, one at a time; E / Space /
# click advances. Built in code (shrine_choice_modal pattern); pauses the
# tree while open. Emits `finished` after the last page.

signal finished

var _pages: Array = []
var _idx := 0
var _done := false        # finished must fire exactly once (queue_free defers)
var _speaker := ""
var _panel: Panel
var _body: Label
var _name_banner          # _NameBanner instance
var _hint: Label
var _lockout := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.45)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	_panel = Panel.new()
	# Spec 39 — the dialog joins the carved-wood panel language. The old
	# Midjourney scroll art was atmospheric but buried the text (user:
	# "completely illegible"); a clean wood frame + cream interior wins.
	# 2026-06-12 — full-screen presentation (user): the conversation owns
	# the moment instead of strapping to the bottom edge.
	WyrdUi.style_panel(_panel)
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = 90
	_panel.offset_right = -90
	_panel.offset_top = 70
	_panel.offset_bottom = -70
	add_child(_panel)
	# Speaker name ribbon (storybook nameplate): parchment plate, gold
	# filigree inset, ink border, diamond end-ornaments, terracotta name.
	_name_banner = _NameBanner.new()
	_name_banner.anchor_right = 1.0
	_name_banner.offset_left = 46
	_name_banner.offset_right = -46
	_name_banner.offset_top = 26
	_name_banner.custom_minimum_size = Vector2(0, 48)
	_panel.add_child(_name_banner)
	# Portrait well (spec 41) — ghosted silhouette until painted portraits.
	var well := PortraitWell.new()
	well.position = Vector2(48, 104)
	well.size = Vector2(120, 120)
	_panel.add_child(well)
	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.anchor_right = 1.0
	_body.anchor_bottom = 1.0
	_body.offset_left = 200
	_body.offset_top = 104
	_body.offset_right = -72
	_body.offset_bottom = -64
	_body.add_theme_font_size_override("font_size", 21)
	_body.add_theme_color_override("font_color", Color(0.20, 0.15, 0.11))
	_body.add_theme_constant_override("line_spacing", 7)
	_panel.add_child(_body)
	_hint = Label.new()
	_hint.text = "E / Space — continue · Esc — close"
	WyrdUi.style_chip(_hint, 12)
	_hint.anchor_left = 1.0
	_hint.anchor_top = 1.0
	_hint.anchor_right = 1.0
	_hint.anchor_bottom = 1.0
	_hint.offset_left = -310
	_hint.offset_top = -48
	_panel.add_child(_hint)
	get_node("/root/Game").modal_opened()
	_render()

func open(speaker: String, pages: Array) -> void:
	_speaker = speaker
	_pages = pages
	_idx = 0

func _render() -> void:
	_name_banner.set_speaker(_speaker)
	if _idx < _pages.size():
		_body.text = String(_pages[_idx])

func _process(delta: float) -> void:
	_lockout += delta
	if _lockout < 0.25:
		return
	# 2026-06-12 — Esc closes the whole conversation (user: "I've always
	# dismissed them"). Still emits finished so tutorial beats advance.
	if Input.is_action_just_pressed("ui_cancel"):
		_finish()
		return
	if Input.is_action_just_pressed("interact") \
			or Input.is_action_just_pressed("roll") \
			or Input.is_action_just_pressed("ui_accept"):
		_advance()

func _input(event: InputEvent) -> void:
	if _lockout < 0.25:
		return
	# Left click only — wheel notches and right-drag (camera orbit) must not
	# chew through pages.
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()

func _advance() -> void:
	if _done:
		return
	_lockout = 0.0
	_idx += 1
	if _idx >= _pages.size():
		_finish()
	else:
		_render()

func _finish() -> void:
	if _done:
		return
	_done = true
	get_node("/root/Game").modal_closed()
	finished.emit()
	queue_free()


# Spec 41 — the round portrait well: parchment disc, ink ring, ghosted
# silhouette placeholder until painted portraits exist.
class PortraitWell extends Control:
	func _draw() -> void:
		var c := size * 0.5
		var r := minf(c.x, c.y)
		draw_circle(c, r, Color(0.88, 0.82, 0.67))
		draw_circle(c + Vector2(0, r * 0.28), r * 0.34, Color(0.55, 0.47, 0.36, 0.55))
		draw_circle(c - Vector2(0, r * 0.18), r * 0.22, Color(0.55, 0.47, 0.36, 0.55))
		draw_arc(c, r, 0, TAU, 48, Color(0.26, 0.19, 0.13), 2.5, true)
		draw_arc(c, r - 4.0, 0, TAU, 48, Color(0.26, 0.19, 0.13, 0.35), 1.2, true)


# Storybook speaker nameplate: a warm parchment ribbon with a gold filigree
# inset line, ink border, small gold diamond ornaments at each end, and the
# speaker's name drawn in terracotta header font centred across its face.
# Replaces the bare Label so the dialog header reads as a carved nameplate.
class _NameBanner extends Control:
	var _text := ""
	var _font: Font = null

	func _ready() -> void:
		_font = WyrdUi.font_header()

	func set_speaker(name: String) -> void:
		_text = name
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		# Warm parchment ribbon plate.
		draw_rect(r, WyrdUi.KIT_PLATE)
		# Top light bevel — catches the page's warm light.
		draw_rect(Rect2(r.position + Vector2(3, 3), Vector2(r.size.x - 6, 2)),
			Color(1.0, 1.0, 0.93, 0.45))
		# Soft bottom shadow — ribbon sits ON the panel face, not flat in it.
		draw_rect(Rect2(r.position + Vector2(3, r.size.y - 4), Vector2(r.size.x - 6, 2)),
			Color(WyrdUi.KIT_EDGE, 0.28))
		# Gold filigree inset line (the "burnished" read).
		draw_rect(r.grow(-4.0), Color(WyrdUi.GOLD, 0.60), false, 1.0)
		# Outer ink border.
		draw_rect(r, WyrdUi.KIT_EDGE, false, 1.5)
		# Small gold diamond ornaments at each end of the ribbon, matching the
		# draw_flourish language used elsewhere in the kit.
		var cy := r.size.y * 0.5
		for ex in [14.0, r.size.x - 14.0]:
			var pts := PackedVector2Array([
				Vector2(ex, cy - 5.5), Vector2(ex + 5.5, cy),
				Vector2(ex, cy + 5.5), Vector2(ex - 5.5, cy)])
			draw_colored_polygon(pts, Color(WyrdUi.GOLD, 0.80))
			draw_polyline(pts + PackedVector2Array([pts[0]]),
				Color(WyrdUi.GOLD.darkened(0.25), 0.90), 1.0, true)
		# Speaker name in terracotta header font, centred on the ribbon.
		if _text != "" and _font != null:
			draw_string(_font, Vector2(r.size.x * 0.5, r.size.y * 0.5 + 9.0),
				_text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 48.0,
				22, WyrdUi.TERRACOTTA)
