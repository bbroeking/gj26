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


# Spec 41 — portrait well: warm vellum disc inside a gold filigree ring and
# ink border, with ivy leaf sprigs at the four compass points. The sepia
# silhouette is a placeholder until painted portraits land.
class PortraitWell extends Control:
	func _draw() -> void:
		var c := size * 0.5
		# Shrink from the well edge so the ivy sprigs fit without clipping.
		var r := minf(c.x, c.y) - 10.0

		# Background disc — warm aged vellum.
		draw_circle(c, r, Color(0.93, 0.87, 0.72))
		# Soft warm-light wash near center: parchment catching the page-light.
		draw_circle(c, r * 0.55, Color(0.97, 0.93, 0.80, 0.32))

		# Ghosted figure placeholder — sepia-warm, more illustrative than grey.
		var fig := Color(0.60, 0.48, 0.36, 0.38)
		draw_circle(c + Vector2(0.0, r * 0.30), r * 0.38, fig)
		draw_circle(c + Vector2(0.0, r * 0.06), r * 0.27, Color(0.60, 0.48, 0.36, 0.36))
		draw_circle(c - Vector2(0.0, r * 0.18), r * 0.23, fig)

		# Gold filigree band — locket-style richness just inside the ink ring.
		draw_arc(c, r - 5.5, 0.0, TAU, 48, Color(WyrdUi.GOLD, 0.45), 1.5, true)
		# Outer ink ring.
		draw_arc(c, r, 0.0, TAU, 64, WyrdUi.KIT_EDGE, 3.0, true)

		# Ivy leaf sprigs at N / E / S / W of the portrait ring.
		var dirs := PackedVector2Array([
				Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT])
		for d in dirs:
			_draw_leaf_sprig(c + d * r, d)

	# Three-leaf sprig: one central leaf along `dir`, two angled ±40°.
	func _draw_leaf_sprig(anchor: Vector2, dir: Vector2) -> void:
		var sage := Color(WyrdUi.SAGE, 0.72)
		var pull := dir * (-3.5)   # pull side leaves slightly inward along the ring
		_draw_leaf(anchor, dir, 9.0, sage)
		_draw_leaf(anchor + pull, dir.rotated(deg_to_rad(40.0)), 6.5, sage)
		_draw_leaf(anchor + pull, dir.rotated(deg_to_rad(-40.0)), 6.5, sage)

	# Pointed oval leaf blade with a midrib vein.
	func _draw_leaf(center: Vector2, dir: Vector2, half_len: float,
			col: Color) -> void:
		var perp := Vector2(-dir.y, dir.x)
		var w := half_len * 0.45
		var pts := PackedVector2Array([
			center + dir * half_len,
			center + perp * w + dir * half_len * 0.28,
			center + perp * w * 0.45 - dir * half_len * 0.18,
			center - dir * half_len * 0.35,
			center - perp * w * 0.45 - dir * half_len * 0.18,
			center - perp * w + dir * half_len * 0.28,
		])
		draw_colored_polygon(pts, col)
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3],
				pts[4], pts[5], pts[0]]), Color(WyrdUi.KIT_EDGE, 0.28), 1.0)
		draw_line(center + dir * half_len * 0.9, center - dir * half_len * 0.25,
				Color(WyrdUi.KIT_EDGE, 0.20), 0.8)
