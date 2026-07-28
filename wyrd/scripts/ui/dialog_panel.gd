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
var _header: _DialogHeader
var _page_dots: _PageDots

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
	# Header band — drawn behind the name label so the terracotta name text
	# sits on a warm wash rather than bare parchment.
	_header = _DialogHeader.new()
	_header.anchor_right = 1.0
	_header.offset_top = 24
	_header.offset_bottom = 82
	_panel.add_child(_header)
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
	# Page-progress dots centred above the hint chip.
	_page_dots = _PageDots.new()
	_page_dots.anchor_left = 0.0
	_page_dots.anchor_right = 1.0
	_page_dots.anchor_top = 1.0
	_page_dots.anchor_bottom = 1.0
	_page_dots.offset_top = -52
	_page_dots.offset_bottom = -10
	_panel.add_child(_page_dots)
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
	if _page_dots != null:
		_page_dots.update_state(_idx, _pages.size())

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


# Warm parchment wash behind the speaker name — gives the top of the dialog
# a chapter-plate feel. Ink rules top + bottom, centered flourish at the base.
class _DialogHeader extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		var h := size.y
		# Warm parchment wash — slightly richer than the panel face
		draw_rect(Rect2(0.0, 0.0, w, h), Color(0.97, 0.91, 0.76, 0.42))
		# Ink rules framing the band
		draw_line(Vector2(10.0, 0.5), Vector2(w - 10.0, 0.5),
			Color(WyrdUi.KIT_EDGE, 0.42), 1.5)
		draw_line(Vector2(10.0, h - 1.0), Vector2(w - 10.0, h - 1.0),
			Color(WyrdUi.KIT_EDGE, 0.42), 1.5)
		# Centred flourish rule at the foot of the band
		WyrdUi.draw_flourish(self, Vector2(w * 0.5, h - 7.0), w * 0.38)


# Ink-painted page-position dots centred at the bottom of the dialog.
# filled = already read, larger terracotta + gold ring = current, hollow = upcoming.
# Stays invisible (no draw) when the conversation has only one page.
class _PageDots extends Control:
	var _total := 1
	var _idx := 0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func update_state(idx: int, total: int) -> void:
		_idx = idx
		_total = total
		queue_redraw()

	func _draw() -> void:
		if _total <= 1:
			return
		var spacing := 18.0
		var start_x := size.x * 0.5 - (_total - 1) * spacing * 0.5
		var cy := size.y * 0.5
		for i in _total:
			var cx := start_x + float(i) * spacing
			if i < _idx:
				# already read — small filled ink dot
				draw_circle(Vector2(cx, cy), 4.0, Color(WyrdUi.INK, 0.65))
			elif i == _idx:
				# current page — larger terracotta fill + gold ring
				draw_circle(Vector2(cx, cy), 6.0, WyrdUi.TERRACOTTA)
				draw_arc(Vector2(cx, cy), 7.5, 0.0, TAU, 24,
					Color(WyrdUi.GOLD, 0.75), 1.5, true)
			else:
				# upcoming — hollow outlined circle
				draw_arc(Vector2(cx, cy), 4.0, 0.0, TAU, 16,
					Color(WyrdUi.INK_MID, 0.50), 1.5, true)


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
