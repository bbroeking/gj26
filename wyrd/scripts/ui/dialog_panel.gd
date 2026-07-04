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
	# NameBanner — terracotta ribbon behind the speaker's name; drawn first
	# so _name_lbl (added next) renders on top. The classic storybook pennant
	# shape reads immediately as "this is who's talking."
	var banner := NameBanner.new()
	banner.anchor_right = 1.0
	banner.offset_left = 16
	banner.offset_right = -16
	banner.offset_top = 22
	banner.offset_bottom = 70
	_panel.add_child(banner)
	_name_lbl = Label.new()
	var hf := WyrdUi.font_header()
	if hf != null:
		_name_lbl.add_theme_font_override("font", hf)
	_name_lbl.add_theme_font_size_override("font_size", 24)
	# Cream on terracotta ribbon — readable and warm.
	_name_lbl.add_theme_color_override("font_color", Color(0.97, 0.93, 0.82))
	_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_lbl.anchor_right = 1.0
	_name_lbl.offset_left = 56
	_name_lbl.offset_right = -56
	_name_lbl.offset_top = 22
	_name_lbl.offset_bottom = 70
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


# Drawn terracotta ribbon banner behind the speaker's name. Classic 6-point
# pennant: straight top/bottom with inward-pointed tips at each end, filled
# with the kit's TERRACOTTA, outlined in GOLD. A warm top-light bevel and
# two gold dot accents at each inner shoulder complete the storybook read.
# No textures — pure vector so the white-rect-in-_draw trap is impossible.
class NameBanner extends Control:
	func _draw() -> void:
		if size.x < 40.0 or size.y < 10.0:
			return
		var w := size.x
		var h := size.y
		var tip := h * 0.54   # horizontal reach of each pointed end
		# Drop shadow (offset 2-3px, low alpha so the panel shows through)
		draw_colored_polygon(PackedVector2Array([
			Vector2(tip + 2, 4), Vector2(w - tip + 2, 4),
			Vector2(w + 2, h * 0.5 + 1), Vector2(w - tip + 2, h + 3),
			Vector2(tip + 2, h + 3), Vector2(2, h * 0.5 + 1)
		]), Color(0.08, 0.05, 0.03, 0.26))
		# Main ribbon face
		draw_colored_polygon(PackedVector2Array([
			Vector2(tip, 0), Vector2(w - tip, 0),
			Vector2(w, h * 0.5), Vector2(w - tip, h),
			Vector2(tip, h), Vector2(0, h * 0.5)
		]), WyrdUi.TERRACOTTA)
		# Warm cream highlight — gives the banner a slight 3-D plumpness
		draw_colored_polygon(PackedVector2Array([
			Vector2(tip + 3, 3), Vector2(w - tip - 3, 3),
			Vector2(w - 5, h * 0.5), Vector2(w - tip - 3, h - 3),
			Vector2(tip + 3, h - 3), Vector2(5, h * 0.5)
		]), Color(1.0, 0.88, 0.72, 0.14))
		# Top-light bevel
		draw_line(Vector2(tip + 5, 2.5), Vector2(w - tip - 5, 2.5),
			Color(1.0, 0.80, 0.68, 0.42), 2.0)
		# Gold outline (closed polyline)
		draw_polyline(PackedVector2Array([
			Vector2(tip, 0), Vector2(w - tip, 0),
			Vector2(w, h * 0.5), Vector2(w - tip, h),
			Vector2(tip, h), Vector2(0, h * 0.5),
			Vector2(tip, 0)
		]), Color(WyrdUi.GOLD, 0.72), 1.5)
		# Gold dot accents at each inner shoulder
		var cy := h * 0.5
		for cx in [tip + 18.0, w - tip - 18.0]:
			draw_circle(Vector2(cx, cy), 3.2, Color(WyrdUi.GOLD, 0.84))
			draw_arc(Vector2(cx, cy), 3.2, 0, TAU, 14,
				Color(0.52, 0.30, 0.08, 0.65), 1.0, true)
