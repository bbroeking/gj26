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


# Spec 41 — the round portrait well: a carved wooden medallion ring (echoing
# the GlobeGauge ring aesthetic) surrounding a parchment portrait disc with a
# ghosted silhouette placeholder until painted portraits exist.
class PortraitWell extends Control:
	func _draw() -> void:
		var c := size * 0.5
		var r := minf(c.x, c.y)
		# Carved wooden ring — same honey-plank + ink-border language as GlobeGauge.
		# Ring center at r-6; 12px wide band covers r-12 (inner) to r (outer edge).
		draw_arc(c, r - 6.0, 0, TAU, 64, Color(0.85, 0.74, 0.52), 12.0, true)
		# Outer ink border.
		draw_arc(c, r - 0.8, 0, TAU, 48, Color(0.26, 0.19, 0.13), 1.8, true)
		# Inner ink border (gap between ring and portrait disc).
		draw_arc(c, r - 12.0, 0, TAU, 48, Color(0.26, 0.19, 0.13), 1.8, true)
		# Upper-left bevel: warm light catch gives the ring carved convexity.
		draw_arc(c, r - 6.0, PI * 0.85, PI * 1.95, 24,
				Color(1.0, 0.97, 0.86, 0.30), 5.0)
		# Four parchment knot-wells at N / E / S / W — the "bolt" motif on the ring.
		for i in 4:
			var a := float(i) * PI * 0.5
			WyrdUi.draw_round_well(self, c + Vector2(cos(a), sin(a)) * (r - 6.0),
					4.0, WyrdUi.KIT_PLATE)
		# Portrait disc face (inset inside the ring, radius r-14).
		var disc_r := r - 14.0
		draw_circle(c, disc_r, Color(0.88, 0.82, 0.67))
		# Ghosted silhouette scaled to the disc radius.
		draw_circle(c + Vector2(0, disc_r * 0.28), disc_r * 0.34,
				Color(0.55, 0.47, 0.36, 0.55))
		draw_circle(c - Vector2(0, disc_r * 0.18), disc_r * 0.22,
				Color(0.55, 0.47, 0.36, 0.55))
		# Disc ink ring.
		draw_arc(c, disc_r, 0, TAU, 48, Color(0.26, 0.19, 0.13), 2.0, true)
		draw_arc(c, disc_r - 3.5, 0, TAU, 48,
				Color(0.26, 0.19, 0.13, 0.30), 1.2, true)
