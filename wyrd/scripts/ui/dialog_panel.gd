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
	# Flourish rule under the speaker name — separates the header from content.
	var rule := HeaderRule.new()
	rule.anchor_right = 1.0
	rule.offset_left = 56
	rule.offset_right = -56
	rule.offset_top = 72
	rule.offset_bottom = 86
	_panel.add_child(rule)
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


# Spec 41 — portrait medallion: gilded ring with sage ornaments, parchment
# face, and ghosted silhouette. Replaces the bare disc placeholder.
class PortraitWell extends Control:
	func _draw() -> void:
		var c := size * 0.5
		var outer_r := minf(c.x, c.y) - 5.0   # outer ink edge, 5px breathing room
		var face_r  := outer_r - 8.0           # parchment disc radius
		var ring_r  := face_r + 4.0            # midpoint of the gold ring

		# --- parchment face ---
		draw_circle(c, face_r, Color(0.94, 0.88, 0.73))
		# warm ambient-light spot (top-left) — hand-painted feel
		draw_circle(c + Vector2(-face_r * 0.24, -face_r * 0.28),
				face_r * 0.55, Color(1.0, 0.97, 0.88, 0.16))
		# soft bottom vignette — depth
		draw_circle(c + Vector2(0.0, face_r * 0.28),
				face_r * 0.50, Color(0.42, 0.32, 0.20, 0.11))

		# --- gilded medallion ring ---
		# gold band fills the annulus (width = ring width)
		draw_arc(c, ring_r, 0, TAU, 64, Color(0.710, 0.525, 0.216), 8.0, true)
		# shadow on the lower-right quarter of the ring
		draw_arc(c, ring_r, PI * 0.22, PI * 1.12, 28,
				Color(0.28, 0.18, 0.08, 0.42), 8.0, true)
		# warm cream highlight on the upper-left of the ring
		draw_arc(c, face_r + 2.5, -PI * 0.85, PI * 0.02, 22,
				Color(1.0, 0.96, 0.82, 0.55), 5.0, true)
		# outer ink border
		draw_arc(c, outer_r, 0, TAU, 64, Color(0.26, 0.19, 0.13), 2.5, true)
		# inner ink border (face-side of ring)
		draw_arc(c, face_r, 0, TAU, 64, Color(0.26, 0.19, 0.13, 0.50), 1.5, true)

		# --- sage diamond ornaments at compass points ---
		# Four small diamonds sit on the gold ring at N/E/S/W, evoking
		# carved ivy studs on a storybook medallion frame.
		var sage  := Color(0.435, 0.541, 0.247, 0.90)
		var ink_d := Color(0.26, 0.19, 0.13, 0.45)
		for i in 4:
			var angle := PI * 0.5 * float(i) - PI * 0.5  # start from top
			var dir  := Vector2(cos(angle), sin(angle))
			var perp := Vector2(-sin(angle), cos(angle))
			var pos  := c + dir * ring_r
			var p_out := pos + dir   * 3.5
			var p_r   := pos + perp  * 2.8
			var p_in  := pos - dir   * 3.5
			var p_l   := pos - perp  * 2.8
			draw_colored_polygon(PackedVector2Array([p_out, p_r, p_in, p_l]), sage)
			draw_line(p_out, p_r,  ink_d, 1.0)
			draw_line(p_r,  p_in, ink_d, 1.0)
			draw_line(p_in, p_l,  ink_d, 1.0)
			draw_line(p_l,  p_out, ink_d, 1.0)

		# --- ghosted character silhouette ---
		var sil := Color(0.50, 0.42, 0.31, 0.50)
		# head — slightly more compact than the old blob
		draw_circle(c + Vector2(0.0, -face_r * 0.30), face_r * 0.21, sil)
		# shoulders / cloak — broader, suggesting a hooded adventurer
		draw_circle(c + Vector2(0.0,  face_r * 0.18), face_r * 0.35, sil)


# Decorative flourish rule drawn beneath the speaker name heading.
class HeaderRule extends Control:
	func _draw() -> void:
		var col  := Color(0.26, 0.19, 0.13, 0.40)
		var gold := Color(0.710, 0.525, 0.216, 0.88)
		var cx   := size.x * 0.5
		var cy   := size.y * 0.5
		var half := size.x * 0.28
		draw_line(Vector2(cx - half, cy), Vector2(cx - 7.0, cy), col, 1.0)
		draw_line(Vector2(cx + 7.0,  cy), Vector2(cx + half, cy), col, 1.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx,       cy - 3.5),
			Vector2(cx + 3.5, cy      ),
			Vector2(cx,       cy + 3.5),
			Vector2(cx - 3.5, cy      ),
		]), gold)
