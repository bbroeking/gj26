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
	# Flourish rule under the speaker name — the same ── ◆ ── ornament used on
	# craft bench / vendor column headers, now on the dialog header too.
	var name_rule := _NameRule.new()
	name_rule.anchor_right = 1.0
	name_rule.offset_left = 56
	name_rule.offset_right = -56
	name_rule.offset_top = 70
	name_rule.offset_bottom = 82
	_panel.add_child(name_rule)
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


# ── ◆ ── divider under the speaker name — 160 px centered, same ornament
# as the craft bench / vendor column headers.
class _NameRule extends Control:
	func _draw() -> void:
		WyrdUi.draw_flourish(self, size * 0.5, 160.0)


# Spec 41 — the round portrait well: parchment disc, ink ring, ghosted
# silhouette placeholder until painted portraits exist.
# Art pass — adds a burnished gold accent ring (portrait-medallion read) and
# four small gold diamond ornaments at the 12/3/6/9 o'clock positions.
class PortraitWell extends Control:
	func _draw() -> void:
		var c := size * 0.5
		var r := minf(c.x, c.y)
		# Warm parchment disc.
		draw_circle(c, r, Color(0.88, 0.82, 0.67))
		# Ghosted silhouette: torso (lower) + head (upper).
		draw_circle(c + Vector2(0, r * 0.28), r * 0.34, Color(0.55, 0.47, 0.36, 0.55))
		draw_circle(c - Vector2(0, r * 0.18), r * 0.22, Color(0.55, 0.47, 0.36, 0.55))
		# Burnished gold accent ring — the portrait-medallion read.
		draw_arc(c, r - 4.5, 0, TAU, 56, Color(WyrdUi.GOLD, 0.62), 2.0, true)
		# Four small gold diamond ornaments at 12 / 3 / 6 / 9 o'clock,
		# sitting on the gold ring like bezel-set stones in a storybook locket.
		var gd := Color(WyrdUi.GOLD, 0.90)
		var gd_ink := Color(WyrdUi.KIT_EDGE, 0.70)
		for i in 4:
			var a := -PI * 0.5 + PI * 0.5 * float(i)
			var dp := c + Vector2(cos(a), sin(a)) * (r - 4.5)
			var dpts := PackedVector2Array([
				dp + Vector2(0.0, -3.5),
				dp + Vector2(3.5, 0.0),
				dp + Vector2(0.0, 3.5),
				dp + Vector2(-3.5, 0.0),
			])
			draw_colored_polygon(dpts, gd)
			draw_polyline(PackedVector2Array([
				dpts[0], dpts[1], dpts[2], dpts[3], dpts[0],
			]), gd_ink, 1.0)
		# Outer ink ring (on top — the clean medallion border).
		draw_arc(c, r, 0, TAU, 48, Color(0.26, 0.19, 0.13), 2.5, true)
		# Inner ink ring (subtle recessed depth).
		draw_arc(c, r - 9.0, 0, TAU, 48, Color(0.26, 0.19, 0.13, 0.18), 1.0, true)
