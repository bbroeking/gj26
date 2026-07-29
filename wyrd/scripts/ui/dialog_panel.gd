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
var _scroll_well: _ScrollWell
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
	# Parchment scroll well drawn BEHIND the body text — makes the speech area
	# read as a hand-rolled scroll rather than bare panel (must be added before
	# _body so it renders underneath).
	_scroll_well = _ScrollWell.new()
	_scroll_well.anchor_right = 1.0
	_scroll_well.anchor_bottom = 1.0
	_scroll_well.offset_left = 192
	_scroll_well.offset_top = 90
	_scroll_well.offset_right = -66
	_scroll_well.offset_bottom = -58
	_panel.add_child(_scroll_well)
	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.anchor_right = 1.0
	_body.anchor_bottom = 1.0
	_body.offset_left = 202
	_body.offset_top = 128
	_body.offset_right = -76
	_body.offset_bottom = -68
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
	_scroll_well.set_state(_idx, _pages.size())
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


# The parchment scroll well that frames the dialog body text. Sits behind the
# body Label so text stays sharp and auto-wraps normally; this control adds the
# storybook frame: cream fill, scroll rolls at top + bottom, an inner flourish
# rule where speech begins, a page counter, and a gold continue chevron.
class _ScrollWell extends Control:
	var _idx := 0
	var _total := 0

	func set_state(idx: int, total: int) -> void:
		_idx = idx
		_total = total
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var font := get_theme_default_font()
		# Parchment fill — warmer cream than the wood panel, so the speech area
		# reads as its own island, a page within the frame.
		draw_rect(r, Color(0.97, 0.93, 0.82, 0.60))
		# Sparse grain so it reads as aged paper, not flat UI.
		WyrdUi.draw_parchment_grain(self, r, 37)
		# Top scroll roll — a narrow parchment cylinder implying the scroll top.
		var roll_h := 11.0
		var roll_col := Color(0.87, 0.81, 0.65)
		draw_rect(Rect2(r.position + Vector2(6, 0),
			Vector2(r.size.x - 12, roll_h)), roll_col)
		# Light bevel on the roll top (catches the warm page-light).
		draw_rect(Rect2(r.position + Vector2(9, 1),
			Vector2(r.size.x - 18, 3)), Color(1.0, 0.98, 0.88, 0.55))
		# Bottom scroll roll.
		draw_rect(Rect2(r.position + Vector2(6, r.size.y - roll_h),
			Vector2(r.size.x - 12, roll_h)), roll_col)
		draw_rect(Rect2(r.position + Vector2(9, r.size.y - roll_h + 1),
			Vector2(r.size.x - 18, 3)), Color(1.0, 0.98, 0.88, 0.45))
		# Ink shadow lines at the inner edges of the rolls (depth read).
		draw_line(r.position + Vector2(8, roll_h),
			r.position + Vector2(r.size.x - 8, roll_h),
			Color(WyrdUi.KIT_EDGE, 0.28), 1.0)
		draw_line(r.position + Vector2(8, r.size.y - roll_h),
			r.position + Vector2(r.size.x - 8, r.size.y - roll_h),
			Color(WyrdUi.KIT_EDGE, 0.28), 1.0)
		# Ink border around the whole scroll well.
		draw_rect(r, WyrdUi.KIT_EDGE, false, 1.5)
		# Inner flourish rule just below the top roll — "here begins the speech".
		WyrdUi.draw_flourish(self,
			Vector2(r.size.x * 0.5, roll_h + 14.0), r.size.x * 0.42)
		# Page counter in the top-right corner (only for multi-page dialogs).
		if _total > 1:
			draw_string(font,
				Vector2(r.size.x - 48, roll_h + 12),
				"%d / %d" % [_idx + 1, _total],
				HORIZONTAL_ALIGNMENT_RIGHT, 42, 11,
				Color(WyrdUi.INK_MID, 0.60))
		# Gold continue chevron at the bottom-right when more pages follow.
		if _total > 0 and _idx < _total - 1:
			draw_string(font,
				Vector2(r.size.x - 26, r.size.y - roll_h - 4),
				"▾", HORIZONTAL_ALIGNMENT_CENTER, 22, 15,
				Color(WyrdUi.GOLD, 0.80))
