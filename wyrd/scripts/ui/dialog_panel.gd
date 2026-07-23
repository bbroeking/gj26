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
	# Decorative header band — warm parchment wash, ink hairlines, a gold
	# flourish rule below the speaker name, and ivy leaf ornaments at each
	# end. Moves toward the ribbon treatment in mj_dialog_ribbon.png.
	var band := _DialogBand.new()
	band.anchor_right = 1.0
	band.offset_top = 28
	band.offset_bottom = 98
	_panel.add_child(band)
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


# Header band behind the speaker name label.
# Draws: warm cream wash, top/bottom ink hairlines with a honey bevel, a
# gold ── ◆ ── flourish rule below the name, and a sage ivy leaf at each end.
# Purely decorative — MOUSE_FILTER_IGNORE so it doesn't absorb clicks.
class _DialogBand extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		# Translucent cream wash — the wood frame behind still reads through.
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.97, 0.93, 0.82, 0.48))
		# Top ink hairline + honey bevel just inside it.
		draw_rect(Rect2(0.0, 0.0, size.x, 1.5), Color(WyrdUi.KIT_EDGE, 0.50))
		draw_rect(Rect2(0.0, 1.5, size.x, 1.5), Color(1.0, 0.97, 0.85, 0.28))
		# Bottom ink hairline — a ledge the flourish sits above.
		draw_rect(Rect2(0.0, size.y - 2.0, size.x, 1.5), Color(WyrdUi.KIT_EDGE, 0.42))
		# Gold flourish rule centred below the name, above the content zone.
		WyrdUi.draw_flourish(self,
			Vector2(size.x * 0.5, size.y - 14.0), size.x * 0.44)
		# Ivy leaf pair — sage green bookend ornaments at each end of the band.
		_draw_leaf(Vector2(28.0, size.y * 0.42), false)
		_draw_leaf(Vector2(size.x - 28.0, size.y * 0.42), true)

	# A small rounded ivy leaf: filled teardrop body + outline + midvein +
	# secondary vein. `flip=true` mirrors it so the right leaf faces left.
	func _draw_leaf(tip: Vector2, flip: bool) -> void:
		var d := -1.0 if flip else 1.0
		var pts := PackedVector2Array([
			tip,
			tip + Vector2(d * 7.0, -10.0),
			tip + Vector2(d * 16.0, -8.0),
			tip + Vector2(d * 18.0, 0.0),
			tip + Vector2(d * 16.0, 8.0),
			tip + Vector2(d * 7.0, 10.0),
		])
		draw_colored_polygon(pts, Color(WyrdUi.SAGE, 0.52))
		# Closed outline.
		var closed := PackedVector2Array(pts)
		closed.append(pts[0])
		draw_polyline(closed, Color(WyrdUi.SAGE.darkened(0.22), 0.68), 1.0)
		# Midvein.
		draw_line(tip, tip + Vector2(d * 17.0, 0.0),
			Color(WyrdUi.SAGE.darkened(0.30), 0.50), 1.0)
		# Diagonal secondary vein.
		draw_line(tip + Vector2(d * 6.0, -9.0),
			tip + Vector2(d * 12.0, 4.0),
			Color(WyrdUi.SAGE.darkened(0.30), 0.35), 0.8)
