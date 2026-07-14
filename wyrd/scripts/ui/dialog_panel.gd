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


# Spec 41 — the round portrait well: a carved wooden frame ring with ivy-leaf
# trefoil ornaments at compass points, a gold inner pinstripe, and a hooded
# storybook silhouette on a warm parchment face. Placeholder until painted
# character portraits exist.
class PortraitWell extends Control:
	func _draw() -> void:
		var c := size * 0.5
		var r := minf(c.x, c.y) - 2.0

		# Carved wood frame ring: ink base disc → warm wood face → catch-light.
		draw_circle(c, r, Color(0.22, 0.16, 0.10))
		draw_circle(c, r - 2.5, Color(0.68, 0.54, 0.36))
		draw_arc(c, r - 5.0, PI * 1.05, PI * 1.55, 14,
			Color(1.0, 0.94, 0.76, 0.40), 4.0, true)

		# Warm parchment portrait face.
		draw_circle(c, r - 10.0, Color(0.90, 0.85, 0.71))

		# Ghosted storybook figure: hooded head + cloaked shoulders.
		var fr := r - 10.0
		var hood_c := c + Vector2(0.0, -fr * 0.15)
		draw_circle(hood_c, fr * 0.26, Color(0.50, 0.42, 0.31, 0.52))
		var sh := fr * 0.52
		var hy := hood_c.y + fr * 0.24
		var by_ := c.y + fr * 0.72
		draw_colored_polygon(PackedVector2Array([
			Vector2(c.x - sh * 0.45, hy), Vector2(c.x + sh * 0.45, hy),
			Vector2(c.x + sh, by_),       Vector2(c.x - sh, by_),
		]), Color(0.50, 0.42, 0.31, 0.44))

		# Gold inner pinstripe inside the frame ring.
		draw_arc(c, r - 12.0, 0, TAU, 48, Color(WyrdUi.GOLD, 0.55), 1.2, true)

		# Ivy-leaf trefoil ornaments at N / E / S / W on the frame ring.
		for i in 4:
			var ang := PI * 0.5 * float(i)
			_draw_leaf(c + Vector2(cos(ang), sin(ang)) * (r - 5.5), ang)

		# Outer ink edge.
		draw_arc(c, r, 0, TAU, 64, Color(0.22, 0.16, 0.10), 2.0, true)

	# Three-lobe sage trefoil + gold centre dot pressed into the carved frame
	# ring at each compass point — the illustrated-border language.
	func _draw_leaf(oc: Vector2, angle: float) -> void:
		var lr := 3.2
		for j in 3:
			var la := angle + TAU / 3.0 * float(j)
			draw_circle(oc + Vector2(cos(la), sin(la)) * lr, lr,
				Color(WyrdUi.SAGE, 0.72))
		draw_circle(oc, 1.4, Color(WyrdUi.GOLD, 0.85))
