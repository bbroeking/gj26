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
var _name_banner: Control
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
	_name_banner = _NameBanner.new()
	_name_banner.font = WyrdUi.font_header()  # set before add_child — no _ready ordering risk
	_name_banner.anchor_right = 1.0
	_name_banner.offset_left = WyrdUi.PANEL_MARGIN_L
	_name_banner.offset_right = -WyrdUi.PANEL_MARGIN_R
	_name_banner.offset_top = 28
	_name_banner.custom_minimum_size = Vector2(0, 44)
	_panel.add_child(_name_banner)
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
	_name_banner.set_label(_speaker)
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


# Ribbon nameplate for the dialog speaker — a terracotta pennant with V-notch
# tails at each end, warm cream text centred on the face, fold crease lines,
# and four gold diamond pips at the corners where the folds meet the face.
# Replaces the plain text Label so the name reads as a storybook announcement
# rather than floating ink (→ mj_dialog_ribbon reference).
class _NameBanner extends Control:
	var _label := ""
	var font: Font = null   # handed in by parent._ready() before add_child

	func set_label(text: String) -> void:
		_label = text
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w < 10.0 or h < 10.0:
			return
		var tail := h * 0.46   # depth of the V-notch at each end
		var tc := WyrdUi.TERRACOTTA

		# Ribbon main face — a hexagonal pennant: rectangle with V-notch tails.
		var pts := PackedVector2Array([
			Vector2(tail, 0.5),
			Vector2(w - tail, 0.5),
			Vector2(w, h * 0.5),
			Vector2(w - tail, h - 0.5),
			Vector2(tail, h - 0.5),
			Vector2(0.0, h * 0.5),
		])
		draw_colored_polygon(pts, tc)

		# Warm top highlight — parchment catches the light on the upper bevel.
		var hi := PackedVector2Array([
			Vector2(tail + 4, 1.5),
			Vector2(w - tail - 4, 1.5),
			Vector2(w - tail - 4, 5.5),
			Vector2(tail + 4, 5.5),
		])
		draw_colored_polygon(hi, Color(1.0, 0.84, 0.72, 0.28))

		# Soft bottom shadow for depth.
		var sh := PackedVector2Array([
			Vector2(tail + 4, h - 5.5),
			Vector2(w - tail - 4, h - 5.5),
			Vector2(w - tail - 4, h - 1.5),
			Vector2(tail + 4, h - 1.5),
		])
		draw_colored_polygon(sh, Color(0.18, 0.04, 0.01, 0.28))

		# Fold crease lines — thin sepia lines from each V-tip to the fold corners,
		# suggesting the ribbon is folded/pinched at each end.
		var crease := Color(tc.darkened(0.32), 0.75)
		draw_line(Vector2(0.0, h * 0.5), Vector2(tail, 0.5), crease, 1.0)
		draw_line(Vector2(0.0, h * 0.5), Vector2(tail, h - 0.5), crease, 1.0)
		draw_line(Vector2(w, h * 0.5), Vector2(w - tail, 0.5), crease, 1.0)
		draw_line(Vector2(w, h * 0.5), Vector2(w - tail, h - 0.5), crease, 1.0)

		# Gold diamond pips at the 4 fold corners (where face meets the fold).
		var ds := 4.5
		for p in [Vector2(tail, 0.5), Vector2(tail, h - 0.5),
				Vector2(w - tail, 0.5), Vector2(w - tail, h - 0.5)]:
			draw_colored_polygon(PackedVector2Array([
				p + Vector2(0, -ds), p + Vector2(ds, 0),
				p + Vector2(0, ds), p + Vector2(-ds, 0),
			]), WyrdUi.GOLD)

		# Name text centred on the ribbon face in warm parchment cream.
		var f := font if font != null else get_theme_default_font()
		draw_string(f, Vector2(tail + 10.0, h * 0.5 + 8.0), _label,
			HORIZONTAL_ALIGNMENT_CENTER, w - (tail + 10.0) * 2.0, 21,
			Color(0.98, 0.94, 0.84))


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
