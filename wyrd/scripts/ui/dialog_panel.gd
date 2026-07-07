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
	# Spec 47 — a storybook reading well frames the body text: soft parchment
	# tint, top bevel, bottom shadow, quiet ink border, and a small ivy sprig
	# at the top-left corner so every page of dialog reads as illustrated text.
	var bf := BodyFrame.new()
	bf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bf.anchor_right = 1.0
	bf.anchor_bottom = 1.0
	bf.offset_left = 192
	bf.offset_top = 96
	bf.offset_right = -64
	bf.offset_bottom = -56
	_panel.add_child(bf)
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


# Spec 47 — a storybook reading well for the dialog body text.  Draws just
# behind the Label so the text is the hero; the well gives it a home on the
# page rather than floating on bare parchment.
class BodyFrame extends Control:
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		# Warm cream tint — barely perceptible depth against the main parchment.
		draw_rect(r, Color(WyrdUi.KIT_PLATE, 0.46))
		# Top catch-light bevel — warm light on the upper lip.
		draw_rect(Rect2(r.position + Vector2(2.0, 1.0),
			Vector2(r.size.x - 4.0, 1.5)), Color(1.0, 1.0, 0.93, 0.30))
		# Bottom shadow — the well reads as gently carved into the panel.
		draw_rect(Rect2(r.position + Vector2(2.0, r.size.y - 2.0),
			Vector2(r.size.x - 4.0, 1.5)), Color(WyrdUi.KIT_EDGE, 0.12))
		# Quiet ink outline — 1.2px, not dominant.
		draw_rect(r, Color(WyrdUi.KIT_EDGE, 0.33), false, 1.2)
		# Ivy sprig at the top-left corner — the storybook signature ornament.
		_draw_ivy_sprig(r.position + Vector2(5.0, 5.0))

	func _draw_ivy_sprig(o: Vector2) -> void:
		var g := WyrdUi.SAGE
		var e := Color(WyrdUi.KIT_EDGE, 0.55)
		# Diagonal stem growing from the corner inward.
		draw_line(o + Vector2(2.0, 2.0), o + Vector2(18.0, 18.0), e, 1.1)
		# Leaf A — fans right off the upper stem.
		var la := PackedVector2Array([
			o + Vector2(4.0, 1.0), o + Vector2(14.0, -1.0),
			o + Vector2(16.0, 7.0), o + Vector2(6.0, 8.0)])
		draw_colored_polygon(la, Color(g, 0.50))
		draw_polyline(PackedVector2Array([la[0], la[1], la[2], la[3], la[0]]),
			Color(g.darkened(0.28), 0.60), 0.8)
		# Leaf B — fans right off the lower stem, overlapping A slightly.
		var lb := PackedVector2Array([
			o + Vector2(9.0, 9.0), o + Vector2(20.0, 9.0),
			o + Vector2(18.0, 17.0), o + Vector2(8.0, 16.0)])
		draw_colored_polygon(lb, Color(g.darkened(0.06), 0.40))
		draw_polyline(PackedVector2Array([lb[0], lb[1], lb[2], lb[3], lb[0]]),
			Color(g.darkened(0.28), 0.50), 0.8)
		# Berry at the stem tip — an ink dot, the storybook full stop.
		draw_circle(o + Vector2(18.0, 18.0), 2.0, Color(e, 0.60))
