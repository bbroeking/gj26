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
var _name_lbl: Label
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
	# Portrait well (spec 41) — ghosted silhouette until painted portraits.
	var well := PortraitWell.new()
	well.position = Vector2(48, 104)
	well.size = Vector2(120, 120)
	_panel.add_child(well)
	_name_lbl = Label.new()
	var hf := WyrdUi.font_header()
	if hf != null:
		_name_lbl.add_theme_font_override("font", hf)
	_name_lbl.add_theme_font_size_override("font_size", 24)
	_name_lbl.add_theme_color_override("font_color", WyrdUi.TERRACOTTA)
	_name_lbl.anchor_right = 1.0
	_name_lbl.offset_left = 56
	_name_lbl.offset_right = -56
	_name_lbl.offset_top = 38
	_panel.add_child(_name_lbl)
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
	_name_lbl.text = _speaker
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


# Spec 41 — the round portrait well: warm gold medallion ring with compass
# diamonds, parchment face disc with grain, and a proportioned ink silhouette.
# Reads as a carved locket rather than a plain placeholder circle.
class PortraitWell extends Control:
	func _draw() -> void:
		var c := size * 0.5
		var r := minf(c.x, c.y) - 1.0
		# Warm gold band (outer medallion frame)
		draw_arc(c, r - 5.0, 0.0, TAU, 64, Color(0.72, 0.54, 0.20), 10.0, true)
		# Carved top-left shadow for depth
		draw_arc(c, r - 5.0, PI * 0.75, PI * 1.65, 24,
			Color(0.18, 0.12, 0.07, 0.32), 10.0, true)
		# Outer + inner ink borders of the ring
		draw_arc(c, r, 0.0, TAU, 56, Color(0.24, 0.17, 0.11), 2.0, true)
		draw_arc(c, r - 10.0, 0.0, TAU, 56, Color(0.24, 0.17, 0.11), 1.5, true)
		# Cream parchment face disc
		var fr := r - 11.0
		draw_circle(c, fr, Color(0.89, 0.82, 0.66))
		# Subtle centre highlight
		draw_circle(c, fr * 0.5, Color(0.95, 0.89, 0.75, 0.22))
		# Parchment grain
		WyrdUi.draw_parchment_grain(self,
			Rect2(c - Vector2(fr, fr), Vector2(fr * 2.0, fr * 2.0)), 42)
		# Silhouette — proportioned head + cloaked body
		var sil := Color(0.38, 0.30, 0.23, 0.60)
		draw_circle(c - Vector2(0.0, fr * 0.20), fr * 0.23, sil)
		var by := c.y - fr * 0.02
		draw_rect(Rect2(c.x - fr * 0.34, by, fr * 0.68, fr * 0.54), sil)
		# Soft ambient shadow inside the disc
		draw_arc(c, fr * 0.78, PI * 1.08, PI * 1.92, 24,
			Color(0.0, 0.0, 0.0, 0.06), fr * 0.28, true)
		# Compass diamonds on the gold ring (N, E, S, W)
		for i in 4:
			var a := float(i) * PI * 0.5
			var np := c + Vector2(cos(a), sin(a)) * (r - 5.0)
			var pts := PackedVector2Array([
				np + Vector2(0.0, -4.0), np + Vector2(4.0, 0.0),
				np + Vector2(0.0, 4.0), np + Vector2(-4.0, 0.0)])
			draw_colored_polygon(pts, Color(0.93, 0.86, 0.68))
			draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2],
				pts[3], pts[0]]), Color(0.24, 0.17, 0.11), 1.0)
